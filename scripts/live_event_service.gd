extends RefCounted

const EVENTS_PATH := "res://data/events/live_events.json"
const REMOTE_CONFIG_PATH := "res://data/events/remote_config.json"
const EVENT_UNLOCK_CONFIG_KEYS := {
	"daily_reward": "daily_reward_unlock_level",
	"starter_missions": "starter_missions_unlock_level",
	"collection_event": "collection_event_unlock_level",
	"season_pass": "season_pass_unlock_level",
}
const VALID_EVENT_TYPES := ["daily_reward", "starter_missions", "collection_event", "season_pass"]
const VALID_PLACEMENTS := ["home", "stage_select", "result_overlay", "collection"]


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


static func load_remote_config() -> Dictionary:
	if not FileAccess.file_exists(REMOTE_CONFIG_PATH):
		push_error("LiveEventService: missing remote config %s" % REMOTE_CONFIG_PATH)
		return {}
	var raw_text := FileAccess.get_file_as_string(REMOTE_CONFIG_PATH)
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_error("LiveEventService: remote config must be a dictionary.")
		return {}
	return Dictionary(parsed)


static func active_events_for(stage_id: int, placement: String) -> Array:
	var remote_config := load_remote_config()
	var active: Array = []
	for event in load_events():
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		if not bool(event_dict.get("enabled", false)):
			continue
		if stage_id < _event_unlock_stage(event_dict, remote_config):
			continue
		var placements: Array = event_dict.get("placements", [])
		if not placements.has(placement):
			continue
		active.append(event_dict)
	return active


static func validate_events() -> PackedStringArray:
	var errors := PackedStringArray()
	var remote_config := load_remote_config()
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

		var placements: Array = event_dict.get("placements", [])
		if placements.is_empty():
			errors.append("live event %s has no placements" % event_id)
		for placement_value in placements:
			var placement := String(placement_value)
			if not VALID_PLACEMENTS.has(placement):
				errors.append("live event %s has invalid placement %s" % [event_id, placement])
	return errors


static func _event_unlock_stage(event_dict: Dictionary, remote_config: Dictionary) -> int:
	var event_type := String(event_dict.get("type", ""))
	var config_key := String(EVENT_UNLOCK_CONFIG_KEYS.get(event_type, ""))
	if not config_key.is_empty() and remote_config.has(config_key):
		return int(remote_config.get(config_key, event_dict.get("unlock_stage", 1)))
	return int(event_dict.get("unlock_stage", 1))


static func _validate_remote_config(remote_config: Dictionary, errors: PackedStringArray) -> void:
	for key in ["heart_spend_start_level", "rewarded_ad_start_level", "iap_offer_start_level", "interstitial_min_level", "season_pass_unlock_level", "daily_reward_unlock_level", "starter_missions_unlock_level", "collection_event_unlock_level", "rewarded_continue_moves", "coin_continue_moves"]:
		if not remote_config.has(key):
			errors.append("remote config missing %s" % key)
		elif int(remote_config.get(key, 0)) <= 0:
			errors.append("remote config %s must be positive" % key)
	if int(remote_config.get("iap_offer_start_level", 0)) < int(remote_config.get("rewarded_ad_start_level", 0)):
		errors.append("remote config iap_offer_start_level must not precede rewarded_ad_start_level")
	if int(remote_config.get("interstitial_min_level", 0)) < 11:
		errors.append("remote config interstitial_min_level must respect FTUE monetization guardrail")
