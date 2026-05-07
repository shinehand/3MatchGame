extends RefCounted

const EVENTS_PATH := "res://data/events/live_events.json"
const REMOTE_CONFIG_PATH := "res://data/events/remote_config.json"
const GameSession = preload("res://scripts/game_session.gd")
const REMOTE_CONFIG_FALLBACK_REASON_KEY := "_remote_config_fallback_reason"
const EVENT_UNLOCK_CONFIG_KEYS := {
	"daily_reward": "daily_reward_unlock_level",
	"starter_missions": "starter_missions_unlock_level",
	"collection_event": "collection_event_unlock_level",
	"season_pass": "season_pass_unlock_level",
}
const DEFAULT_REMOTE_CONFIG := {
	"remote_config_version": "local-default-2026.05",
	"variant_id": "local_default",
	"heart_spend_start_level": 11,
	"rewarded_ad_start_level": 11,
	"iap_offer_start_level": 16,
	"interstitial_min_level": 16,
	"season_pass_unlock_level": 21,
	"daily_reward_unlock_level": 2,
	"starter_missions_unlock_level": 3,
	"collection_event_unlock_level": 9,
	"rewarded_continue_moves": 3,
	"coin_continue_moves": 5,
}
const REMOTE_CONFIG_EXPOSURE_KEYS := [
	"heart_spend_start_level",
	"rewarded_ad_start_level",
	"iap_offer_start_level",
	"interstitial_min_level",
	"season_pass_unlock_level",
	"daily_reward_unlock_level",
	"starter_missions_unlock_level",
	"collection_event_unlock_level",
	"rewarded_continue_moves",
	"coin_continue_moves",
]
const VALID_EVENT_TYPES := ["daily_reward", "starter_missions", "collection_event", "season_pass"]
const VALID_PLACEMENTS := ["home", "stage_select", "result_overlay", "collection"]

static var _remote_config_exposures_sent := {}


static func load_events() -> Array:
	if not FileAccess.file_exists(EVENTS_PATH):
		push_error("LiveEventService: missing event config %s" % EVENTS_PATH)
		return []
	var raw_text := FileAccess.get_file_as_string(EVENTS_PATH)
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Array):
		push_error("LiveEventService: event config must be an array.")
		return []
	return Array(parsed)


static func load_remote_config(record_exposure: bool = true) -> Dictionary:
	var remote_config := _default_remote_config()
	if not FileAccess.file_exists(REMOTE_CONFIG_PATH):
		push_warning("LiveEventService: missing remote config %s; using local defaults." % REMOTE_CONFIG_PATH)
		remote_config[REMOTE_CONFIG_FALLBACK_REASON_KEY] = "missing"
		if record_exposure:
			_record_remote_config_exposures(remote_config)
		return remote_config
	var raw_text := FileAccess.get_file_as_string(REMOTE_CONFIG_PATH)
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_warning("LiveEventService: remote config must be a dictionary; using local defaults.")
		remote_config[REMOTE_CONFIG_FALLBACK_REASON_KEY] = "invalid"
		if record_exposure:
			_record_remote_config_exposures(remote_config)
		return remote_config
	for key in Dictionary(parsed).keys():
		remote_config[key] = Dictionary(parsed)[key]
	if record_exposure:
		_record_remote_config_exposures(remote_config)
	return remote_config


static func active_events_for(stage_id: int, placement: String, now_unix: int = -1, record_exposure: bool = true) -> Array:
	return events_for(stage_id, placement, now_unix, false, record_exposure)


static func display_events_for(stage_id: int, placement: String, now_unix: int = -1, record_exposure: bool = true, force_offline_fallback: bool = false) -> Array:
	var events := events_for(stage_id, placement, now_unix, true, record_exposure, force_offline_fallback)
	var display_events: Array = []
	for event in events:
		var event_dict := Dictionary(event)
		if String(event_dict.get("status", "")) == "disabled":
			continue
		display_events.append(event_dict)
	if display_events.is_empty():
		display_events = offline_events_for(stage_id, placement, now_unix)
	display_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rank_a := _status_rank(String(a.get("status", "")))
		var rank_b := _status_rank(String(b.get("status", "")))
		if rank_a == rank_b:
			return int(a.get("unlock_stage", 0)) < int(b.get("unlock_stage", 0))
		return rank_a < rank_b
	)
	return display_events


static func events_for(stage_id: int, placement: String, now_unix: int = -1, include_inactive: bool = false, record_exposure: bool = true, force_offline_fallback: bool = false) -> Array:
	var remote_config := load_remote_config(record_exposure)
	var events: Array = []
	for event in load_events():
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		var status := event_status(event_dict, now_unix)
		if _should_show_offline_fallback(event_dict, status, remote_config, force_offline_fallback):
			status = "offline"
		if status != "active" and not include_inactive:
			continue
		if stage_id < _event_unlock_stage(event_dict, remote_config):
			continue
		var placements: Array = event_dict.get("placements", [])
		if not placements.has(placement):
			continue
		var event_result := event_dict.duplicate(true)
		event_result["status"] = status
		events.append(event_result)
	return events


static func offline_events_for(stage_id: int, placement: String, now_unix: int = -1) -> Array:
	var events: Array = []
	var remote_config := DEFAULT_REMOTE_CONFIG.duplicate(true)
	for event in load_events():
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		if not bool(event_dict.get("offline_fallback", false)):
			continue
		if event_status(event_dict, now_unix) != "active":
			continue
		if stage_id < _event_unlock_stage(event_dict, remote_config):
			continue
		var placements: Array = event_dict.get("placements", [])
		if not placements.has(placement):
			continue
		var event_result := event_dict.duplicate(true)
		event_result["status"] = "offline"
		events.append(event_result)
	return events


static func validate_events() -> PackedStringArray:
	var errors := PackedStringArray()
	var remote_config := load_remote_config(false)
	_validate_remote_config(remote_config, errors)
	var seen_ids := {}
	for event in load_events():
		if not (event is Dictionary):
			errors.append("live event entry must be a dictionary")
			continue
		var event_dict: Dictionary = event
		var event_id := String(event_dict.get("id", ""))
		if event_id.is_empty():
			errors.append("live event missing id")
		elif seen_ids.has(event_id):
			errors.append("duplicate live event id %s" % event_id)
		seen_ids[event_id] = true

		var event_type := String(event_dict.get("type", ""))
		if not VALID_EVENT_TYPES.has(event_type):
			errors.append("live event %s has invalid type %s" % [event_id, event_type])
		if String(event_dict.get("title", "")).strip_edges().is_empty():
			errors.append("live event %s missing title" % event_id)
		if int(event_dict.get("unlock_stage", 0)) <= 0:
			errors.append("live event %s has invalid unlock_stage" % event_id)
		if _event_unlock_stage(event_dict, remote_config) <= 0:
			errors.append("live event %s has invalid remote-configured unlock stage" % event_id)
		var starts_at_unix := int(event_dict.get("starts_at_unix", 0))
		var ends_at_unix := int(event_dict.get("ends_at_unix", 0))
		if starts_at_unix > 0 and ends_at_unix > 0 and starts_at_unix > ends_at_unix:
			errors.append("live event %s starts after it ends" % event_id)
		if not event_dict.has("offline_fallback"):
			errors.append("live event %s missing offline_fallback" % event_id)

		var placements: Array = event_dict.get("placements", [])
		if placements.is_empty():
			errors.append("live event %s has no placements" % event_id)
		for placement_value in placements:
			var placement := String(placement_value)
			if not VALID_PLACEMENTS.has(placement):
				errors.append("live event %s has invalid placement %s" % [event_id, placement])
	return errors


static func event_status(event_dict: Dictionary, now_unix: int = -1) -> String:
	if not bool(event_dict.get("enabled", false)):
		return "disabled"
	var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
	var starts_at_unix := int(event_dict.get("starts_at_unix", 0))
	var ends_at_unix := int(event_dict.get("ends_at_unix", 0))
	if starts_at_unix > 0 and now < starts_at_unix:
		return "upcoming"
	if ends_at_unix > 0 and now > ends_at_unix:
		return "ended"
	return "active"


static func status_text(event_dict: Dictionary) -> String:
	var status := String(event_dict.get("status", "")).strip_edges()
	if status.is_empty():
		status = event_status(event_dict)
	match status:
		"active":
			return "진행 중"
		"offline":
			return "오프라인"
		"upcoming":
			return "시작 전"
		"ended":
			return "종료됨"
		"disabled":
			return "중지됨"
	return "상태 확인 중"


static func reset_remote_config_exposures_for_testing() -> void:
	_remote_config_exposures_sent.clear()


static func _event_unlock_stage(event_dict: Dictionary, remote_config: Dictionary) -> int:
	var event_type := String(event_dict.get("type", ""))
	var config_key := String(EVENT_UNLOCK_CONFIG_KEYS.get(event_type, ""))
	if not config_key.is_empty() and remote_config.has(config_key):
		return int(remote_config.get(config_key, event_dict.get("unlock_stage", 1)))
	return int(event_dict.get("unlock_stage", 1))


static func _validate_remote_config(remote_config: Dictionary, errors: PackedStringArray) -> void:
	if String(remote_config.get("variant_id", "")).strip_edges().is_empty():
		errors.append("remote config missing variant_id")
	for key in ["heart_spend_start_level", "rewarded_ad_start_level", "iap_offer_start_level", "interstitial_min_level", "season_pass_unlock_level", "daily_reward_unlock_level", "starter_missions_unlock_level", "collection_event_unlock_level", "rewarded_continue_moves", "coin_continue_moves"]:
		if not remote_config.has(key):
			errors.append("remote config missing %s" % key)
		elif int(remote_config.get(key, 0)) <= 0:
			errors.append("remote config %s must be positive" % key)
	if int(remote_config.get("iap_offer_start_level", 0)) < int(remote_config.get("rewarded_ad_start_level", 0)):
		errors.append("remote config iap_offer_start_level must not precede rewarded_ad_start_level")
	if int(remote_config.get("interstitial_min_level", 0)) < 11:
		errors.append("remote config interstitial_min_level must respect FTUE monetization guardrail")


static func _default_remote_config() -> Dictionary:
	return DEFAULT_REMOTE_CONFIG.duplicate(true)


static func _should_show_offline_fallback(event_dict: Dictionary, status: String, remote_config: Dictionary, force_offline_fallback: bool) -> bool:
	if status != "active":
		return false
	if not bool(event_dict.get("offline_fallback", false)):
		return false
	return force_offline_fallback or not String(remote_config.get(REMOTE_CONFIG_FALLBACK_REASON_KEY, "")).is_empty()


static func _status_rank(status: String) -> int:
	match status:
		"active":
			return 0
		"offline":
			return 1
		"upcoming":
			return 2
		"ended":
			return 3
		"disabled":
			return 4
	return 5


static func _record_remote_config_exposures(remote_config: Dictionary) -> void:
	var session_id := GameSession.get_session_id()
	var variant_id := String(remote_config.get("variant_id", "local_default")).strip_edges()
	var version := String(remote_config.get("remote_config_version", "local-default-2026.05")).strip_edges()
	if variant_id.is_empty():
		variant_id = "local_default"
	if version.is_empty():
		version = "local-default-2026.05"
	for config_key in REMOTE_CONFIG_EXPOSURE_KEYS:
		if not remote_config.has(config_key):
			continue
		var exposure_key := "%s:%s:%s" % [session_id, variant_id, config_key]
		if _remote_config_exposures_sent.has(exposure_key):
			continue
		_remote_config_exposures_sent[exposure_key] = true
		GameSession.record_analytics_event("remote_config_exposure", {
			"session_id": session_id,
			"config_key": config_key,
			"variant_id": variant_id,
			"config_value_hash": _config_value_hash(remote_config.get(config_key)),
			"remote_config_version": version,
			"source": "local_json",
		})


static func _config_value_hash(value) -> String:
	return str(JSON.stringify(value).hash())
