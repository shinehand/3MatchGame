extends SceneTree

const LiveEventService = preload("res://scripts/live_event_service.gd")
const GameSession = preload("res://scripts/game_session.gd")
const AnalyticsGateway = preload("res://scripts/analytics_gateway.gd")

const SMOKE_NOW_UNIX := 1778198400
const REQUIRED_EVENT_TYPES := ["daily_reward", "starter_missions", "collection_event", "season_pass"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors := _validate_liveops_config()
	if not errors.is_empty():
		for error_text in errors:
			push_error("LiveOps config validation error: %s" % error_text)
		quit(1)
		return
	print("LiveOps config validation passed.")
	quit()


func _validate_liveops_config() -> PackedStringArray:
	var errors := PackedStringArray()
	for service_error in LiveEventService.validate_events():
		errors.append(service_error)

	var remote_config := _load_json_dictionary(LiveEventService.REMOTE_CONFIG_PATH, "remote config", errors)
	var live_events := _load_json_array(LiveEventService.EVENTS_PATH, "live events", errors)
	if remote_config.is_empty():
		errors.append("remote config must not be empty")
	if live_events.is_empty():
		errors.append("live events must not be empty")
	if remote_config.is_empty() or live_events.is_empty():
		return errors

	_validate_remote_config_contract(remote_config, errors)
	_validate_event_contract(live_events, remote_config, errors)
	_validate_runtime_queries(live_events, remote_config, errors)
	_validate_remote_config_exposures(remote_config, errors)
	return errors


func _load_json_dictionary(path: String, label: String, errors: PackedStringArray) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("missing %s file at %s" % [label, path])
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		errors.append("%s file must be a dictionary" % label)
		return {}
	return Dictionary(parsed)


func _load_json_array(path: String, label: String, errors: PackedStringArray) -> Array:
	if not FileAccess.file_exists(path):
		errors.append("missing %s file at %s" % [label, path])
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Array):
		errors.append("%s file must be an array" % label)
		return []
	return Array(parsed)


func _validate_remote_config_contract(remote_config: Dictionary, errors: PackedStringArray) -> void:
	_require_non_empty_string(remote_config, "remote_config_version", "remote config", errors)
	_require_non_empty_string(remote_config, "variant_id", "remote config", errors)
	if remote_config.has(LiveEventService.REMOTE_CONFIG_FALLBACK_REASON_KEY):
		errors.append("remote config fixture must not contain fallback reason key")

	for config_key in LiveEventService.DEFAULT_REMOTE_CONFIG.keys():
		if not remote_config.has(config_key):
			errors.append("remote config missing baseline key %s" % String(config_key))
	for config_key in remote_config.keys():
		if not LiveEventService.DEFAULT_REMOTE_CONFIG.has(config_key):
			errors.append("remote config contains unknown key %s" % String(config_key))
	for exposure_key in LiveEventService.REMOTE_CONFIG_EXPOSURE_KEYS:
		if not remote_config.has(exposure_key):
			errors.append("remote config exposure key %s is missing from remote_config.json" % exposure_key)

	for event_type in LiveEventService.EVENT_UNLOCK_CONFIG_KEYS.keys():
		var unlock_key := String(LiveEventService.EVENT_UNLOCK_CONFIG_KEYS[event_type])
		if not remote_config.has(unlock_key):
			errors.append("remote config missing unlock key %s for event type %s" % [unlock_key, String(event_type)])
		elif not _is_positive_integer(remote_config[unlock_key]):
			errors.append("remote config %s must be a positive integer" % unlock_key)
		if not LiveEventService.REMOTE_CONFIG_EXPOSURE_KEYS.has(unlock_key):
			errors.append("remote config unlock key %s must be included in exposure keys" % unlock_key)

	_require_integer_range(remote_config, "rewarded_continue_moves", 1, 10, errors)
	_require_integer_range(remote_config, "coin_continue_moves", 1, 10, errors)
	_require_integer_range(remote_config, "near_miss_goal_threshold", 1, 5, errors)
	_require_float_range(remote_config, "near_miss_progress_threshold", 0.5, 0.98, errors)
	if int(remote_config.get("rewarded_ad_start_level", 0)) < 11:
		errors.append("remote config rewarded_ad_start_level must respect FTUE monetization guardrail")
	if int(remote_config.get("iap_offer_start_level", 0)) < int(remote_config.get("rewarded_ad_start_level", 0)):
		errors.append("remote config iap_offer_start_level must not precede rewarded_ad_start_level")
	if int(remote_config.get("interstitial_min_level", 0)) < 11:
		errors.append("remote config interstitial_min_level must respect FTUE monetization guardrail")


func _validate_event_contract(live_events: Array, remote_config: Dictionary, errors: PackedStringArray) -> void:
	var event_types_seen := {}
	var enabled_placements_seen := {}
	var season_pass_count := 0
	for event_value in live_events:
		if not (event_value is Dictionary):
			continue
		var event := Dictionary(event_value)
		var event_id := String(event.get("id", ""))
		var event_type := String(event.get("type", ""))
		event_types_seen[event_type] = true
		if not event.has("enabled") or not (event.get("enabled") is bool):
			errors.append("live event %s enabled must be an explicit boolean" % event_id)
		if not event.has("starts_at_unix") or int(event.get("starts_at_unix", 0)) <= 0:
			errors.append("live event %s must define positive starts_at_unix" % event_id)
		if not event.has("ends_at_unix") or int(event.get("ends_at_unix", 0)) <= 0:
			errors.append("live event %s must define positive ends_at_unix" % event_id)

		var unlock_key := String(LiveEventService.EVENT_UNLOCK_CONFIG_KEYS.get(event_type, ""))
		if unlock_key.is_empty():
			errors.append("live event %s type %s has no remote unlock key mapping" % [event_id, event_type])
		else:
			var configured_unlock := int(remote_config.get(unlock_key, 0))
			if int(event.get("unlock_stage", 0)) != configured_unlock:
				errors.append("live event %s unlock_stage must match remote config %s=%d" % [event_id, unlock_key, configured_unlock])

		if bool(event.get("enabled", false)):
			for placement_value in Array(event.get("placements", [])):
				enabled_placements_seen[String(placement_value)] = true
		_validate_event_type_payload(event, errors)

		if event_type == "season_pass":
			season_pass_count += 1
			if bool(event.get("enabled", false)):
				errors.append("season_pass must remain disabled until store products and SDK evidence are ready")
			if bool(event.get("offline_fallback", false)):
				errors.append("disabled season_pass must not use offline_fallback")

	for required_type in REQUIRED_EVENT_TYPES:
		if not event_types_seen.has(required_type):
			errors.append("live events missing required event type %s" % required_type)
	if season_pass_count != 1:
		errors.append("live events should contain exactly one season_pass fixture, got %d" % season_pass_count)
	for placement in LiveEventService.VALID_PLACEMENTS:
		if not enabled_placements_seen.has(placement):
			errors.append("enabled live events should cover placement %s" % placement)


func _validate_event_type_payload(event: Dictionary, errors: PackedStringArray) -> void:
	var event_id := String(event.get("id", ""))
	var event_type := String(event.get("type", ""))
	match event_type:
		"daily_reward":
			if not (event.get("reward", {}) is Dictionary) or Dictionary(event.get("reward", {})).is_empty():
				errors.append("daily_reward event %s must define reward" % event_id)
		"starter_missions":
			var missions := Array(event.get("missions", []))
			if missions.is_empty():
				errors.append("starter_missions event %s must define missions" % event_id)
			for mission_value in missions:
				if not (mission_value is Dictionary):
					errors.append("starter_missions event %s mission entry must be a dictionary" % event_id)
					continue
				var mission := Dictionary(mission_value)
				if String(mission.get("id", "")).strip_edges().is_empty():
					errors.append("starter_missions event %s mission missing id" % event_id)
				if int(mission.get("target", 0)) <= 0:
					errors.append("starter_missions event %s mission target must be positive" % event_id)
				if not mission.has("reward_gold") and not mission.has("reward_booster"):
					errors.append("starter_missions event %s mission must define a reward" % event_id)
		"collection_event":
			var featured_animals := Array(event.get("featured_animals", []))
			if featured_animals.is_empty():
				errors.append("collection_event %s must define featured_animals" % event_id)
			if not (event.get("reward", {}) is Dictionary) or Dictionary(event.get("reward", {})).is_empty():
				errors.append("collection_event %s must define reward" % event_id)
		"season_pass":
			if Array(event.get("free_track_rewards", [])).is_empty():
				errors.append("season_pass %s must define free_track_rewards" % event_id)
			if Array(event.get("premium_track_rewards", [])).is_empty():
				errors.append("season_pass %s must define premium_track_rewards" % event_id)


func _validate_runtime_queries(live_events: Array, remote_config: Dictionary, errors: PackedStringArray) -> void:
	var season_pass_id := ""
	var season_pass_unlock := int(remote_config.get("season_pass_unlock_level", 0))
	var season_pass_placements: Array[String] = []
	for event_value in live_events:
		if not (event_value is Dictionary):
			continue
		var event := Dictionary(event_value)
		var event_id := String(event.get("id", ""))
		var event_type := String(event.get("type", ""))
		var unlock_key := String(LiveEventService.EVENT_UNLOCK_CONFIG_KEYS.get(event_type, ""))
		var configured_unlock := int(remote_config.get(unlock_key, event.get("unlock_stage", 1)))
		var starts_at_unix := int(event.get("starts_at_unix", SMOKE_NOW_UNIX))
		var smoke_now: int = max(SMOKE_NOW_UNIX, starts_at_unix + 1)
		for placement_value in Array(event.get("placements", [])):
			var placement := String(placement_value)
			if bool(event.get("enabled", false)):
				_assert_event_visible(event_id, configured_unlock, placement, smoke_now, errors)
				if configured_unlock > 1:
					_assert_event_not_visible_before_unlock(event_id, configured_unlock - 1, placement, smoke_now, errors)
				if bool(event.get("offline_fallback", false)):
					_assert_offline_fallback_visible(event_id, configured_unlock, placement, smoke_now, errors)
			elif event_type == "season_pass":
				season_pass_id = event_id
				if not season_pass_placements.has(placement):
					season_pass_placements.append(placement)

	if not season_pass_id.is_empty():
		if season_pass_placements.is_empty():
			errors.append("disabled season_pass must define at least one placement")
		for placement in season_pass_placements:
			for event in LiveEventService.active_events_for(season_pass_unlock, placement, SMOKE_NOW_UNIX, false):
				if event is Dictionary and String(Dictionary(event).get("id", "")) == season_pass_id:
					errors.append("disabled season_pass should not appear in active %s events" % placement)
			for event in LiveEventService.display_events_for(season_pass_unlock, placement, SMOKE_NOW_UNIX, false):
				if event is Dictionary and String(Dictionary(event).get("id", "")) == season_pass_id:
					errors.append("disabled season_pass should not appear in display %s events" % placement)
			var inactive_events := LiveEventService.events_for(season_pass_unlock, placement, SMOKE_NOW_UNIX, true, false)
			var saw_disabled_fixture := false
			for event in inactive_events:
				if event is Dictionary:
					var event_dict := Dictionary(event)
					if String(event_dict.get("id", "")) == season_pass_id and String(event_dict.get("status", "")) == "disabled":
						saw_disabled_fixture = true
			if not saw_disabled_fixture:
				errors.append("disabled season_pass should remain inspectable as disabled via include_inactive for %s" % placement)


func _validate_remote_config_exposures(remote_config: Dictionary, errors: PackedStringArray) -> void:
	GameSession.clear_analytics_events()
	AnalyticsGateway.reset_for_testing()
	LiveEventService.reset_remote_config_exposures_for_testing()
	LiveEventService.load_remote_config(true)
	var seen_keys := {}
	for event in GameSession.get_analytics_events():
		if not (event is Dictionary):
			continue
		var event_dict := Dictionary(event)
		if String(event_dict.get("name", "")) != "remote_config_exposure":
			continue
		var params := Dictionary(event_dict.get("params", {}))
		var config_key := String(params.get("config_key", ""))
		seen_keys[config_key] = true
		if String(params.get("variant_id", "")).strip_edges().is_empty():
			errors.append("remote_config_exposure for %s missing variant_id" % config_key)
		if String(params.get("config_value_hash", "")).strip_edges().is_empty():
			errors.append("remote_config_exposure for %s missing config_value_hash" % config_key)
		if String(params.get("remote_config_version", "")).strip_edges().is_empty():
			errors.append("remote_config_exposure for %s missing remote_config_version" % config_key)
		if String(params.get("source", "")) != "local_json":
			errors.append("remote_config_exposure for %s must use local_json source" % config_key)
	for config_key in LiveEventService.REMOTE_CONFIG_EXPOSURE_KEYS:
		if not seen_keys.has(config_key):
			errors.append("remote_config_exposure missing key %s" % config_key)
	for config_key in seen_keys.keys():
		if not remote_config.has(config_key):
			errors.append("remote_config_exposure emitted unknown key %s" % String(config_key))
	LiveEventService.load_remote_config(true)
	var exposure_count := 0
	for event in GameSession.get_analytics_events():
		if event is Dictionary and String(Dictionary(event).get("name", "")) == "remote_config_exposure":
			exposure_count += 1
	if exposure_count != LiveEventService.REMOTE_CONFIG_EXPOSURE_KEYS.size():
		errors.append("remote_config_exposure should emit once per key per session, got %d" % exposure_count)


func _assert_event_visible(event_id: String, stage_id: int, placement: String, now_unix: int, errors: PackedStringArray) -> void:
	for event in LiveEventService.active_events_for(stage_id, placement, now_unix, false):
		if event is Dictionary and String(Dictionary(event).get("id", "")) == event_id:
			return
	errors.append("live event %s should be active for placement %s at stage %d" % [event_id, placement, stage_id])


func _assert_event_not_visible_before_unlock(event_id: String, stage_id: int, placement: String, now_unix: int, errors: PackedStringArray) -> void:
	for event in LiveEventService.active_events_for(stage_id, placement, now_unix, false):
		if event is Dictionary and String(Dictionary(event).get("id", "")) == event_id:
			errors.append("live event %s should not be active before unlock stage for placement %s" % [event_id, placement])


func _assert_offline_fallback_visible(event_id: String, stage_id: int, placement: String, now_unix: int, errors: PackedStringArray) -> void:
	for event in LiveEventService.display_events_for(stage_id, placement, now_unix, false, true):
		if event is Dictionary:
			var event_dict := Dictionary(event)
			if String(event_dict.get("id", "")) == event_id:
				if String(event_dict.get("status", "")) != "offline":
					errors.append("offline fallback event %s should be marked offline" % event_id)
				return
	errors.append("offline fallback event %s should display for placement %s" % [event_id, placement])


func _require_non_empty_string(source: Dictionary, key: String, label: String, errors: PackedStringArray) -> void:
	if String(source.get(key, "")).strip_edges().is_empty():
		errors.append("%s missing %s" % [label, key])


func _require_integer_range(source: Dictionary, key: String, min_value: int, max_value: int, errors: PackedStringArray) -> void:
	if not source.has(key):
		errors.append("remote config missing %s" % key)
		return
	if not _is_integer(source[key]):
		errors.append("remote config %s must be an integer" % key)
		return
	var value := int(source[key])
	if value < min_value or value > max_value:
		errors.append("remote config %s must be between %d and %d" % [key, min_value, max_value])


func _require_float_range(source: Dictionary, key: String, min_value: float, max_value: float, errors: PackedStringArray) -> void:
	if not source.has(key):
		errors.append("remote config missing %s" % key)
		return
	var value := float(source[key])
	if value < min_value or value > max_value:
		errors.append("remote config %s must be between %.2f and %.2f" % [key, min_value, max_value])


func _is_positive_integer(value) -> bool:
	return _is_integer(value) and int(value) > 0


func _is_integer(value) -> bool:
	if value is int:
		return true
	if value is float:
		return is_equal_approx(float(int(value)), float(value))
	return false
