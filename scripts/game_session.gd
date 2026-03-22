extends RefCounted

const SAVE_PATH := "user://save_game.json"

static var _loaded := false
static var _save_data := {
	"highest_unlocked_stage_id": 1,
	"last_selected_stage_id": 1,
	"cleared_stage_ids": [],
	"best_score_by_stage_id": {},
	"best_star_by_stage_id": {},
	"sound_enabled": true,
	"haptics_enabled": true,
	"seen_tutorial_stage_ids": [],
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
	_save_data["sound_enabled"] = bool(parsed.get("sound_enabled", true))
	_save_data["haptics_enabled"] = bool(parsed.get("haptics_enabled", true))
	_save_data["seen_tutorial_stage_ids"] = Array(parsed.get("seen_tutorial_stage_ids", []))


static func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameSession: failed to open save file.")
		return
	file.store_string(JSON.stringify(_save_data, "\t"))


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
	save_state()


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
	if Engine.has_singleton("Feedback") or typeof(Feedback) != TYPE_NIL:
		Feedback.sound_enabled = get_sound_enabled()
		Feedback.haptics_enabled = get_haptics_enabled()


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
