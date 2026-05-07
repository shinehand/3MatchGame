extends RefCounted

const SAVE_PATH := "user://save_game.json"
const ANALYTICS_CONTRACT_PATH := "res://data/analytics_events.json"
const CollectionState = preload("res://scripts/collection_state.gd")

static var _loaded := false
static var _analytics_contract_cache: Dictionary = {}
static var _save_data := {
	"highest_unlocked_stage_id": 1,
	"last_selected_stage_id": 1,
	"cleared_stage_ids": [],
	"best_score_by_stage_id": {},
	"best_star_by_stage_id": {},
	"fail_count_by_stage_id": {},
	"sound_enabled": true,
	"haptics_enabled": true,
	"seen_tutorial_stage_ids": [],
	"selected_pre_boosters": [],
	"rescue_book": {},
	"analytics_events": [],
	"session_id": "",
}


static func load_state() -> void:
	if _loaded:
		return
	_loaded = true

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var raw_text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return

	_save_data["highest_unlocked_stage_id"] = int(parsed.get("highest_unlocked_stage_id", 1))
	_save_data["last_selected_stage_id"] = int(parsed.get("last_selected_stage_id", 1))
	_save_data["cleared_stage_ids"] = Array(parsed.get("cleared_stage_ids", []))
	_save_data["best_score_by_stage_id"] = Dictionary(parsed.get("best_score_by_stage_id", {}))
	_save_data["best_star_by_stage_id"] = Dictionary(parsed.get("best_star_by_stage_id", {}))
	_save_data["fail_count_by_stage_id"] = Dictionary(parsed.get("fail_count_by_stage_id", {}))
	_save_data["sound_enabled"] = bool(parsed.get("sound_enabled", true))
	_save_data["haptics_enabled"] = bool(parsed.get("haptics_enabled", true))
	_save_data["seen_tutorial_stage_ids"] = Array(parsed.get("seen_tutorial_stage_ids", []))
	_save_data["selected_pre_boosters"] = Array(parsed.get("selected_pre_boosters", []))
	_save_data["rescue_book"] = CollectionState.normalize_state(Dictionary(parsed.get("rescue_book", {})))
	_save_data["analytics_events"] = Array(parsed.get("analytics_events", []))
	_save_data["session_id"] = String(parsed.get("session_id", ""))
	if String(_save_data["session_id"]).is_empty():
		_save_data["session_id"] = _make_session_id()


static func _make_session_id() -> String:
	return "session-%d" % int(Time.get_unix_time_from_system())


static func save_state() -> void:
	DirAccess.make_dir_recursive_absolute("user://")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameSession: failed to open save file.")
		return
	file.store_string(JSON.stringify(_save_data, "\t"))


static func get_session_id() -> String:
	load_state()
	if String(_save_data.get("session_id", "")).is_empty():
		_save_data["session_id"] = _make_session_id()
		save_state()
	return String(_save_data["session_id"])


static func record_analytics_event(event_name: String, params: Dictionary) -> void:
	load_state()
	var event_params := params.duplicate(true)
	if not event_params.has("session_id"):
		event_params["session_id"] = get_session_id()
	var missing_params := analytics_event_missing_required_params(event_name, event_params)
	if not missing_params.is_empty():
		push_warning("Analytics event %s missing required params: %s" % [event_name, ", ".join(Array(missing_params))])
	var events: Array = Array(_save_data.get("analytics_events", []))
	var entry := {
		"name": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"params": event_params,
	}
	events.append(entry)
	while events.size() > 100:
		events.pop_front()
	_save_data["analytics_events"] = events
	save_state()


static func get_analytics_events() -> Array:
	load_state()
	return Array(_save_data.get("analytics_events", [])).duplicate(true)


static func clear_analytics_events() -> void:
	load_state()
	_save_data["analytics_events"] = []
	save_state()


static func analytics_event_missing_required_params(event_name: String, params: Dictionary) -> PackedStringArray:
	var missing := PackedStringArray()
	var contract := _analytics_contract_by_name()
	if not contract.has(event_name):
		missing.append("__unknown_event__")
		return missing
	var required_params: Array = Dictionary(contract[event_name]).get("required_params", [])
	for param_value in required_params:
		var param := String(param_value)
		if param.is_empty():
			continue
		if not params.has(param):
			missing.append(param)
	return missing


static func _analytics_contract_by_name() -> Dictionary:
	if not _analytics_contract_cache.is_empty():
		return _analytics_contract_cache
	if not FileAccess.file_exists(ANALYTICS_CONTRACT_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ANALYTICS_CONTRACT_PATH))
	if not (parsed is Array):
		return {}
	for entry in Array(parsed):
		if not (entry is Dictionary):
			continue
		var event: Dictionary = entry
		var event_name := String(event.get("name", ""))
		if event_name.is_empty():
			continue
		_analytics_contract_cache[event_name] = event
	return _analytics_contract_cache


static func get_highest_unlocked_stage_id() -> int:
	load_state()
	return max(1, int(_save_data["highest_unlocked_stage_id"]))


static func get_selected_stage_id() -> int:
	load_state()
	return clamp(int(_save_data["last_selected_stage_id"]), 1, get_highest_unlocked_stage_id())


static func get_continue_stage_id() -> int:
	load_state()
	return get_selected_stage_id()


static func set_selected_stage_id(stage_id: int) -> void:
	load_state()
	_save_data["last_selected_stage_id"] = max(1, stage_id)
	save_state()


static func is_stage_unlocked(stage_id: int) -> bool:
	return stage_id <= get_highest_unlocked_stage_id()


static func record_stage_result(stage_id: int, final_score: int, star_count: int) -> void:
	load_state()

	var cleared_stage_ids: Array = _save_data["cleared_stage_ids"]
	if not cleared_stage_ids.has(stage_id):
		cleared_stage_ids.append(stage_id)
		_save_data["cleared_stage_ids"] = cleared_stage_ids

	var score_key := str(stage_id)
	var best_scores: Dictionary = _save_data["best_score_by_stage_id"]
	best_scores[score_key] = max(int(best_scores.get(score_key, 0)), final_score)
	_save_data["best_score_by_stage_id"] = best_scores

	var best_stars: Dictionary = _save_data["best_star_by_stage_id"]
	best_stars[score_key] = max(int(best_stars.get(score_key, 0)), star_count)
	_save_data["best_star_by_stage_id"] = best_stars

	_save_data["highest_unlocked_stage_id"] = max(int(_save_data["highest_unlocked_stage_id"]), stage_id + 1)
	_save_data["last_selected_stage_id"] = stage_id
	_save_data["rescue_book"] = CollectionState.unlock_by_stage(Dictionary(_save_data.get("rescue_book", {})), get_highest_unlocked_stage_id())
	save_state()


static func record_stage_failure(stage_id: int) -> int:
	load_state()
	var key := str(stage_id)
	var fail_counts: Dictionary = _save_data.get("fail_count_by_stage_id", {})
	var next_count := int(fail_counts.get(key, 0)) + 1
	fail_counts[key] = next_count
	_save_data["fail_count_by_stage_id"] = fail_counts
	save_state()
	return next_count


static func get_stage_fail_count(stage_id: int) -> int:
	load_state()
	return int(Dictionary(_save_data.get("fail_count_by_stage_id", {})).get(str(stage_id), 0))


static func get_best_score(stage_id: int) -> int:
	load_state()
	return int(Dictionary(_save_data["best_score_by_stage_id"]).get(str(stage_id), 0))


static func get_best_stars(stage_id: int) -> int:
	load_state()
	return int(Dictionary(_save_data["best_star_by_stage_id"]).get(str(stage_id), 0))


static func get_cleared_count() -> int:
	load_state()
	return Array(_save_data["cleared_stage_ids"]).size()


static func get_total_stars() -> int:
	load_state()
	var total := 0
	for value in Dictionary(_save_data["best_star_by_stage_id"]).values():
		total += int(value)
	return total


static func get_sound_enabled() -> bool:
	load_state()
	return bool(_save_data.get("sound_enabled", true))


static func set_sound_enabled(enabled: bool) -> void:
	load_state()
	_save_data["sound_enabled"] = enabled
	save_state()


static func get_haptics_enabled() -> bool:
	load_state()
	return bool(_save_data.get("haptics_enabled", true))


static func set_haptics_enabled(enabled: bool) -> void:
	load_state()
	_save_data["haptics_enabled"] = enabled
	save_state()


static func apply_feedback_preferences() -> void:
	load_state()
	if Engine.has_singleton("Feedback"):
		var feedback := Engine.get_singleton("Feedback")
		feedback.set("sound_enabled", get_sound_enabled())
		feedback.set("haptics_enabled", get_haptics_enabled())


static func is_tutorial_seen(stage_id: int) -> bool:
	load_state()
	return Array(_save_data.get("seen_tutorial_stage_ids", [])).has(stage_id)


static func mark_tutorial_seen(stage_id: int) -> void:
	load_state()
	var seen: Array = Array(_save_data.get("seen_tutorial_stage_ids", []))
	if not seen.has(stage_id):
		seen.append(stage_id)
		_save_data["seen_tutorial_stage_ids"] = seen
		save_state()


static func set_selected_pre_boosters(boosters: Array) -> void:
	load_state()
	_save_data["selected_pre_boosters"] = boosters.duplicate()
	save_state()


static func get_selected_pre_boosters() -> Array:
	load_state()
	return Array(_save_data.get("selected_pre_boosters", [])).duplicate()


static func consume_selected_pre_boosters() -> Array:
	var boosters := get_selected_pre_boosters()
	_save_data["selected_pre_boosters"] = []
	save_state()
	return boosters


static func get_rescue_book_state() -> Dictionary:
	load_state()
	var state := CollectionState.normalize_state(Dictionary(_save_data.get("rescue_book", {})))
	_save_data["rescue_book"] = state
	return state.duplicate(true)


static func add_rescue_book_tokens(animal_id: String, token_count: int) -> void:
	load_state()
	_save_data["rescue_book"] = CollectionState.add_tokens(Dictionary(_save_data.get("rescue_book", {})), animal_id, token_count)
	save_state()


static func mark_rescue_book_seen(animal_id: String) -> void:
	load_state()
	var state := CollectionState.normalize_state(Dictionary(_save_data.get("rescue_book", {})))
	var animals: Dictionary = state.get("animals", {})
	if animals.has(animal_id):
		var entry: Dictionary = Dictionary(animals[animal_id])
		entry["is_new"] = false
		animals[animal_id] = entry
		state["animals"] = animals
		_save_data["rescue_book"] = state
		save_state()
