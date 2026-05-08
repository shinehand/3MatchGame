extends RefCounted

const SAVE_PATH := "user://save_game.json"
const ANALYTICS_CONTRACT_PATH := "res://data/analytics_events.json"
const MAX_ANALYTICS_EVENTS := 320
const MAX_REWARD_TRANSACTION_IDS := 240
const MAX_STAGE_TOKEN_REWARD_IDS := 240
const CollectionState = preload("res://scripts/collection_state.gd")
const AnalyticsGateway = preload("res://scripts/analytics_gateway.gd")

static var _loaded := false
static var _save_path := SAVE_PATH
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
	"live_events": {},
	"wallet": {
		"gold": 0,
		"tokens": 0,
		"boosters": {},
	},
	"granted_reward_transaction_ids": [],
	"claimed_stage_token_reward_ids": [],
	"analytics_events": [],
	"session_id": "",
}


static func load_state() -> void:
	if _loaded:
		return
	_loaded = true

	if not FileAccess.file_exists(_save_path):
		return

	var raw_text := FileAccess.get_file_as_string(_save_path)
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
	_save_data["live_events"] = _normalize_live_events(Dictionary(parsed.get("live_events", {})))
	_save_data["wallet"] = _normalize_wallet(Dictionary(parsed.get("wallet", {})))
	_save_data["granted_reward_transaction_ids"] = _normalize_reward_transaction_ids(Array(parsed.get("granted_reward_transaction_ids", [])))
	_save_data["claimed_stage_token_reward_ids"] = _normalize_stage_token_reward_ids(Array(parsed.get("claimed_stage_token_reward_ids", [])))
	_save_data["analytics_events"] = Array(parsed.get("analytics_events", []))
	_save_data["session_id"] = String(parsed.get("session_id", ""))
	if String(_save_data["session_id"]).is_empty():
		_save_data["session_id"] = _make_session_id()


static func _make_session_id() -> String:
	return "session-%d" % int(Time.get_unix_time_from_system())


static func use_save_path_for_testing(save_path: String) -> void:
	_save_path = SAVE_PATH if save_path.is_empty() else save_path
	_loaded = false
	_reset_save_data_to_defaults()


static func reset_progress_for_testing_preserving_analytics() -> void:
	load_state()
	var analytics_events := Array(_save_data.get("analytics_events", [])).duplicate(true)
	var session_id := String(_save_data.get("session_id", ""))
	_reset_save_data_to_defaults()
	_save_data["analytics_events"] = analytics_events
	_save_data["session_id"] = session_id
	_loaded = true


static func _reset_save_data_to_defaults() -> void:
	_save_data = {
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
		"live_events": {},
		"wallet": {
			"gold": 0,
			"tokens": 0,
			"boosters": {},
		},
		"granted_reward_transaction_ids": [],
		"claimed_stage_token_reward_ids": [],
		"analytics_events": [],
		"session_id": "",
	}


static func _normalize_live_events(live_events: Dictionary) -> Dictionary:
	var normalized := {}
	for event_id_value in live_events.keys():
		var event_id := String(event_id_value)
		if event_id.is_empty():
			continue
		normalized[event_id] = _normalize_live_event_state(Dictionary(live_events[event_id_value]))
	return normalized


static func _normalize_live_event_state(state: Dictionary) -> Dictionary:
	var claimed_reward_ids := []
	for reward_id_value in Array(state.get("claimed_reward_ids", [])):
		var reward_id := String(reward_id_value)
		if not reward_id.is_empty() and not claimed_reward_ids.has(reward_id):
			claimed_reward_ids.append(reward_id)
	return {
		"joined": bool(state.get("joined", false)),
		"joined_at": int(state.get("joined_at", 0)),
		"progress": Dictionary(state.get("progress", {})),
		"claimed_reward_ids": claimed_reward_ids,
	}


static func _normalize_wallet(wallet: Dictionary) -> Dictionary:
	var boosters := {}
	for booster_id_value in Dictionary(wallet.get("boosters", {})).keys():
		var booster_id := String(booster_id_value)
		if booster_id.is_empty():
			continue
		boosters[booster_id] = max(0, int(Dictionary(wallet.get("boosters", {}))[booster_id_value]))
	return {
		"gold": max(0, int(wallet.get("gold", 0))),
		"tokens": max(0, int(wallet.get("tokens", 0))),
		"boosters": boosters,
	}


static func _normalize_reward_transaction_ids(transaction_ids: Array) -> Array:
	var normalized := []
	for value in transaction_ids:
		var transaction_id := String(value).strip_edges()
		if transaction_id.is_empty() or normalized.has(transaction_id):
			continue
		normalized.append(transaction_id)
	while normalized.size() > MAX_REWARD_TRANSACTION_IDS:
		normalized.pop_front()
	return normalized


static func _normalize_stage_token_reward_ids(reward_ids: Array) -> Array:
	var normalized := []
	for value in reward_ids:
		var reward_id := String(value).strip_edges()
		if reward_id.is_empty() or normalized.has(reward_id):
			continue
		normalized.append(reward_id)
	while normalized.size() > MAX_STAGE_TOKEN_REWARD_IDS:
		normalized.pop_front()
	return normalized


static func save_state() -> void:
	DirAccess.make_dir_recursive_absolute("user://")
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
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
	while events.size() > MAX_ANALYTICS_EVENTS:
		events.pop_front()
	_save_data["analytics_events"] = events
	save_state()
	AnalyticsGateway.dispatch_event(entry, missing_params.is_empty(), missing_params)


static func get_analytics_events() -> Array:
	load_state()
	return Array(_save_data.get("analytics_events", [])).duplicate(true)


static func clear_analytics_events() -> void:
	load_state()
	_save_data["analytics_events"] = []
	save_state()
	AnalyticsGateway.clear_dispatched_events_for_testing()
	AnalyticsGateway.clear_rejected_events_for_testing()


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
		elif params[param] is String and String(params[param]).strip_edges().is_empty():
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
	var previous_rescue_book := CollectionState.normalize_state(Dictionary(_save_data.get("rescue_book", {})))

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
	_track_rescue_book_unlocks(previous_rescue_book, Dictionary(_save_data.get("rescue_book", {})), stage_id)


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


static func _track_rescue_book_unlocks(previous_state: Dictionary, next_state: Dictionary, stage_id: int) -> void:
	var previous_animals: Dictionary = Dictionary(previous_state.get("animals", {}))
	var next_animals: Dictionary = Dictionary(next_state.get("animals", {}))
	var unlock_stage_by_animal_id := _collection_unlock_stages_by_animal_id()
	for animal_id_value in next_animals.keys():
		var animal_id := String(animal_id_value)
		if animal_id.is_empty():
			continue
		var previous_entry := Dictionary(previous_animals.get(animal_id, {}))
		var next_entry := Dictionary(next_animals.get(animal_id, {}))
		if bool(previous_entry.get("unlocked", false)) or not bool(next_entry.get("unlocked", false)):
			continue
		var event_params := {
			"animal_id": animal_id,
			"source": "stage_clear",
			"stage_id": stage_id,
			"token_balance": int(next_entry.get("tokens", 0)),
		}
		if unlock_stage_by_animal_id.has(animal_id):
			event_params["unlock_stage"] = int(unlock_stage_by_animal_id[animal_id])
		record_analytics_event("animal_unlock", event_params)


static func _collection_unlock_stages_by_animal_id() -> Dictionary:
	var unlock_stages := {}
	for animal in CollectionState.load_animal_definitions():
		if not (animal is Dictionary):
			continue
		var animal_dict: Dictionary = animal
		var animal_id := String(animal_dict.get("id", ""))
		if animal_id.is_empty():
			continue
		unlock_stages[animal_id] = int(animal_dict.get("unlock_stage", 1))
	return unlock_stages


static func set_stage_fail_count_for_testing(stage_id: int, fail_count: int) -> void:
	load_state()
	var key := str(stage_id)
	var fail_counts: Dictionary = _save_data.get("fail_count_by_stage_id", {})
	if fail_count <= 0:
		fail_counts.erase(key)
	else:
		fail_counts[key] = fail_count
	_save_data["fail_count_by_stage_id"] = fail_counts
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
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var feedback := tree.root.get_node_or_null("Feedback")
	if feedback == null:
		return
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


static func add_rescue_book_tokens(animal_id: String, token_count: int, source: String = "debug_grant", stage_id: int = 0, event_id: String = "") -> void:
	load_state()
	var before_state := CollectionState.normalize_state(Dictionary(_save_data.get("rescue_book", {})))
	var before_entry := Dictionary(Dictionary(before_state.get("animals", {})).get(animal_id, {}))
	_save_data["rescue_book"] = CollectionState.add_tokens(before_state, animal_id, token_count)
	var after_state := CollectionState.normalize_state(Dictionary(_save_data.get("rescue_book", {})))
	_save_data["rescue_book"] = after_state
	var after_entry := Dictionary(Dictionary(after_state.get("animals", {})).get(animal_id, {}))
	save_state()
	if token_count > 0 and not after_entry.is_empty():
		_track_rescue_book_token_gain(animal_id, token_count, source, stage_id, event_id, before_entry, after_entry)


static func _track_rescue_book_token_gain(animal_id: String, token_count: int, source: String, stage_id: int, event_id: String, before_entry: Dictionary, after_entry: Dictionary) -> void:
	var token_params := {
		"animal_id": animal_id,
		"amount": token_count,
		"source": source,
		"stage_id": stage_id,
		"token_balance": int(after_entry.get("tokens", 0)),
		"level_before": int(before_entry.get("friendship_level", 1)),
		"level_after": int(after_entry.get("friendship_level", 1)),
	}
	if not event_id.is_empty():
		token_params["event_id"] = event_id
	record_analytics_event("animal_token_gain", token_params)

	var level_before := int(before_entry.get("friendship_level", 1))
	var level_after := int(after_entry.get("friendship_level", 1))
	for reward in CollectionState.reward_entries_earned_between(animal_id, level_before, level_after):
		if not (reward is Dictionary):
			continue
		var reward_dict: Dictionary = reward
		var level_params := {
			"animal_id": animal_id,
			"level_before": level_before,
			"level_after": int(reward_dict.get("level", level_after)),
			"reward_id": String(reward_dict.get("reward_id", "")),
			"reward_type": String(reward_dict.get("reward_type", "")),
			"source": source,
			"stage_id": stage_id,
			"token_balance": int(after_entry.get("tokens", 0)),
		}
		if not event_id.is_empty():
			level_params["event_id"] = event_id
		record_analytics_event("animal_friendship_level_up", level_params)


static func grant_stage_clear_rescue_book_tokens(stage_id: int, target_animals: Array, token_amount: int = 3) -> Dictionary:
	load_state()
	if stage_id <= 0 or token_amount <= 0:
		return {"granted": false, "reason": "invalid_request"}
	var animal_id := _first_stage_token_reward_animal(target_animals)
	if animal_id.is_empty():
		return {"granted": false, "reason": "missing_target_animal"}
	if not Dictionary(get_rescue_book_state().get("animals", {})).has(animal_id):
		return {"granted": false, "reason": "unknown_animal", "animal_id": animal_id}

	var claim_key := "%d:%s" % [stage_id, animal_id]
	var claimed_ids := _normalize_stage_token_reward_ids(Array(_save_data.get("claimed_stage_token_reward_ids", [])))
	if claimed_ids.has(claim_key):
		return {"granted": false, "reason": "already_claimed", "animal_id": animal_id, "amount": token_amount, "claim_key": claim_key}
	claimed_ids.append(claim_key)

	var before_state := CollectionState.normalize_state(Dictionary(_save_data.get("rescue_book", {})))
	var before_entry := Dictionary(Dictionary(before_state.get("animals", {})).get(animal_id, {}))
	var after_state := CollectionState.add_tokens(before_state, animal_id, token_amount)
	var after_entry := Dictionary(Dictionary(after_state.get("animals", {})).get(animal_id, {}))
	_save_data["claimed_stage_token_reward_ids"] = _normalize_stage_token_reward_ids(claimed_ids)
	_save_data["rescue_book"] = after_state
	save_state()
	if token_amount > 0 and not after_entry.is_empty():
		_track_rescue_book_token_gain(animal_id, token_amount, "stage_clear", stage_id, claim_key, before_entry, after_entry)
	return {"granted": true, "animal_id": animal_id, "amount": token_amount, "claim_key": claim_key}


static func _first_stage_token_reward_animal(target_animals: Array) -> String:
	for value in target_animals:
		var animal_id := String(value).strip_edges()
		if not animal_id.is_empty():
			return animal_id
	return ""


static func equip_rescue_book_cosmetic(animal_id: String, cosmetic_id: String, entry_point: String = "collection_detail") -> Dictionary:
	load_state()
	var normalized_animal_id := animal_id.strip_edges()
	var normalized_cosmetic_id := cosmetic_id.strip_edges()
	if normalized_animal_id.is_empty() or normalized_cosmetic_id.is_empty():
		return {"equipped": false, "reason": "invalid_request"}

	var state := CollectionState.normalize_state(Dictionary(_save_data.get("rescue_book", {})))
	var animals: Dictionary = Dictionary(state.get("animals", {}))
	if not animals.has(normalized_animal_id):
		return {"equipped": false, "reason": "unknown_animal", "animal_id": normalized_animal_id, "cosmetic_id": normalized_cosmetic_id}
	var entry := Dictionary(animals[normalized_animal_id])
	if not bool(entry.get("unlocked", false)):
		return {"equipped": false, "reason": "locked_animal", "animal_id": normalized_animal_id, "cosmetic_id": normalized_cosmetic_id}

	var reward_entry := CollectionState.reward_entry_by_id(normalized_animal_id, normalized_cosmetic_id)
	if reward_entry.is_empty():
		return {"equipped": false, "reason": "unknown_cosmetic", "animal_id": normalized_animal_id, "cosmetic_id": normalized_cosmetic_id}
	if not Array(entry.get("earned_rewards", [])).has(normalized_cosmetic_id):
		return {"equipped": false, "reason": "unearned_cosmetic", "animal_id": normalized_animal_id, "cosmetic_id": normalized_cosmetic_id}

	var previous_cosmetic_id := String(entry.get("equipped_cosmetic", "none"))
	if previous_cosmetic_id == normalized_cosmetic_id:
		return {"equipped": false, "reason": "already_equipped", "animal_id": normalized_animal_id, "cosmetic_id": normalized_cosmetic_id}

	entry["equipped_cosmetic"] = normalized_cosmetic_id
	animals[normalized_animal_id] = entry
	state["animals"] = animals
	_save_data["rescue_book"] = state
	save_state()
	record_analytics_event("animal_cosmetic_equip", {
		"animal_id": normalized_animal_id,
		"cosmetic_id": normalized_cosmetic_id,
		"cosmetic_type": String(reward_entry.get("reward_type", "cosmetic")),
		"entry_point": entry_point,
		"source": "rescue_book",
		"friendship_level": int(entry.get("friendship_level", 1)),
		"token_balance": int(entry.get("tokens", 0)),
		"previous_cosmetic_id": previous_cosmetic_id,
	})
	return {
		"equipped": true,
		"animal_id": normalized_animal_id,
		"cosmetic_id": normalized_cosmetic_id,
		"cosmetic_type": String(reward_entry.get("reward_type", "cosmetic")),
		"previous_cosmetic_id": previous_cosmetic_id,
	}


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


static func get_live_event_state(event_id: String) -> Dictionary:
	load_state()
	var live_events := _normalized_live_events_from_save()
	if not live_events.has(event_id):
		return _normalize_live_event_state({})
	return Dictionary(live_events[event_id]).duplicate(true)


static func join_live_event(event_id: String, event_type: String, placement: String) -> bool:
	load_state()
	if event_id.is_empty():
		return false
	var normalized_event_type := _analytics_dimension(event_type)
	var normalized_placement := _analytics_dimension(placement)
	var live_events := _normalized_live_events_from_save()
	var state := _live_event_state_for_write(live_events, event_id)
	if bool(state.get("joined", false)):
		return false

	var joined_at := int(Time.get_unix_time_from_system())
	state["joined"] = true
	state["joined_at"] = joined_at
	live_events[event_id] = state
	_save_data["live_events"] = live_events
	save_state()
	record_analytics_event("event_join", {
		"session_id": get_session_id(),
		"event_id": event_id,
		"event_type": normalized_event_type,
		"placement": normalized_placement,
		"joined_at": joined_at,
	})
	return true


static func set_live_event_progress(event_id: String, progress_key: String, value: int, event_type: String = "", placement: String = "") -> void:
	load_state()
	if event_id.is_empty() or progress_key.is_empty():
		return
	var live_events := _normalized_live_events_from_save()
	var state := _live_event_state_for_write(live_events, event_id)
	var progress: Dictionary = state.get("progress", {})
	var previous_value := int(progress.get(progress_key, 0))
	if previous_value == value:
		return

	progress[progress_key] = value
	state["progress"] = progress
	live_events[event_id] = state
	_save_data["live_events"] = live_events
	save_state()
	_record_live_event_progress(event_id, progress_key, value, event_type, placement)


static func increment_live_event_progress(event_id: String, progress_key: String, delta: int = 1, event_type: String = "", placement: String = "") -> int:
	load_state()
	if event_id.is_empty() or progress_key.is_empty():
		return 0
	var live_events := _normalized_live_events_from_save()
	var state := _live_event_state_for_write(live_events, event_id)
	var progress: Dictionary = state.get("progress", {})
	var next_value := int(progress.get(progress_key, 0)) + delta
	if delta == 0:
		return next_value

	progress[progress_key] = next_value
	state["progress"] = progress
	live_events[event_id] = state
	_save_data["live_events"] = live_events
	save_state()
	_record_live_event_progress(event_id, progress_key, next_value, event_type, placement)
	return next_value


static func is_live_event_reward_claimed(event_id: String, reward_id: String) -> bool:
	load_state()
	if event_id.is_empty() or reward_id.is_empty():
		return false
	var state := get_live_event_state(event_id)
	return Array(state.get("claimed_reward_ids", [])).has(reward_id)


static func claim_live_event_reward(event_id: String, reward_id: String, event_type: String, placement: String, reward: Dictionary) -> bool:
	load_state()
	if event_id.is_empty() or reward_id.is_empty():
		return false
	var normalized_event_type := _analytics_dimension(event_type)
	var normalized_placement := _analytics_dimension(placement)
	var live_events := _normalized_live_events_from_save()
	var state := _live_event_state_for_write(live_events, event_id)
	var claimed_reward_ids: Array = state.get("claimed_reward_ids", [])
	if claimed_reward_ids.has(reward_id):
		return false

	claimed_reward_ids.append(reward_id)
	state["claimed_reward_ids"] = claimed_reward_ids
	live_events[event_id] = state
	_save_data["live_events"] = live_events
	_save_data["wallet"] = _apply_live_event_reward_to_wallet(Dictionary(_save_data.get("wallet", {})), reward)
	save_state()

	record_analytics_event("event_reward_claim", {
		"session_id": get_session_id(),
		"event_id": event_id,
		"event_type": normalized_event_type,
		"placement": normalized_placement,
		"reward_id": reward_id,
		"reward_type": _reward_type(reward),
		"reward_amount": _reward_amount(reward),
		"reward_breakdown": _reward_breakdown(reward),
	})
	return true


static func get_wallet() -> Dictionary:
	load_state()
	var wallet := _normalize_wallet(Dictionary(_save_data.get("wallet", {})))
	_save_data["wallet"] = wallet
	return wallet.duplicate(true)


static func set_wallet_for_testing(wallet: Dictionary) -> void:
	load_state()
	_save_data["wallet"] = _normalize_wallet(wallet)
	save_state()


static func spend_gold(amount: int) -> bool:
	load_state()
	var spend_amount: int = max(0, amount)
	var wallet := _normalize_wallet(Dictionary(_save_data.get("wallet", {})))
	var current_gold := int(wallet.get("gold", 0))
	if current_gold < spend_amount:
		_save_data["wallet"] = wallet
		save_state()
		return false
	wallet["gold"] = current_gold - spend_amount
	_save_data["wallet"] = wallet
	save_state()
	return true


static func has_reward_transaction_granted(transaction_id: String) -> bool:
	load_state()
	var normalized_id := transaction_id.strip_edges()
	if normalized_id.is_empty():
		return false
	var transaction_ids := _normalize_reward_transaction_ids(Array(_save_data.get("granted_reward_transaction_ids", [])))
	_save_data["granted_reward_transaction_ids"] = transaction_ids
	return transaction_ids.has(normalized_id)


static func mark_reward_transaction_granted(transaction_id: String) -> bool:
	load_state()
	var normalized_id := transaction_id.strip_edges()
	if normalized_id.is_empty():
		return true
	var transaction_ids := _normalize_reward_transaction_ids(Array(_save_data.get("granted_reward_transaction_ids", [])))
	if transaction_ids.has(normalized_id):
		_save_data["granted_reward_transaction_ids"] = transaction_ids
		save_state()
		return false
	transaction_ids.append(normalized_id)
	_save_data["granted_reward_transaction_ids"] = _normalize_reward_transaction_ids(transaction_ids)
	save_state()
	return true


static func clear_reward_transactions_for_testing() -> void:
	load_state()
	_save_data["granted_reward_transaction_ids"] = []
	save_state()


static func _normalized_live_events_from_save() -> Dictionary:
	var live_events := _normalize_live_events(Dictionary(_save_data.get("live_events", {})))
	_save_data["live_events"] = live_events
	return live_events


static func _live_event_state_for_write(live_events: Dictionary, event_id: String) -> Dictionary:
	if live_events.has(event_id):
		return Dictionary(live_events[event_id])
	return _normalize_live_event_state({})


static func _record_live_event_progress(event_id: String, progress_key: String, progress_value: int, event_type: String, placement: String) -> void:
	record_analytics_event("event_progress", {
		"session_id": get_session_id(),
		"event_id": event_id,
		"event_type": _analytics_dimension(event_type),
		"placement": _analytics_dimension(placement),
		"progress_key": progress_key,
		"progress_value": progress_value,
	})


static func _analytics_dimension(value: String, fallback: String = "unknown") -> String:
	var normalized := value.strip_edges()
	if normalized.is_empty():
		return fallback
	return normalized


static func _apply_live_event_reward_to_wallet(wallet_data: Dictionary, reward: Dictionary) -> Dictionary:
	var wallet := _normalize_wallet(wallet_data)
	var gold_delta := int(reward.get("gold", 0))
	if String(reward.get("reward_type", "")) == "gold":
		gold_delta = max(gold_delta, int(reward.get("reward_amount", reward.get("amount", 0))))
	wallet["gold"] = max(0, int(wallet.get("gold", 0)) + gold_delta)
	wallet["tokens"] = max(0, int(wallet.get("tokens", 0)) + int(reward.get("tokens", 0)))

	var boosters: Dictionary = wallet.get("boosters", {})
	var single_booster_id := String(reward.get("booster", reward.get("booster_id", "")))
	if String(reward.get("reward_type", "")) == "booster" and single_booster_id.is_empty():
		single_booster_id = String(reward.get("reward_id", ""))
	if not single_booster_id.is_empty():
		var booster_count: int = max(1, int(reward.get("booster_count", reward.get("reward_amount", reward.get("amount", 1)))))
		boosters[single_booster_id] = max(0, int(boosters.get(single_booster_id, 0)) + booster_count)

	for booster_id_value in Dictionary(reward.get("boosters", {})).keys():
		var booster_id := String(booster_id_value)
		if booster_id.is_empty():
			continue
		boosters[booster_id] = max(0, int(boosters.get(booster_id, 0)) + int(Dictionary(reward.get("boosters", {}))[booster_id_value]))
	wallet["boosters"] = boosters
	return wallet


static func _reward_type(reward: Dictionary) -> String:
	var explicit_type := String(reward.get("reward_type", ""))
	if not explicit_type.is_empty():
		return explicit_type
	var types: Array[String] = []
	if int(reward.get("gold", 0)) > 0:
		types.append("gold")
	if int(reward.get("tokens", 0)) > 0:
		types.append("tokens")
	if reward.has("booster") or reward.has("booster_id") or reward.has("boosters"):
		types.append("booster")
	if types.size() > 1:
		return "mixed"
	if types.size() == 1:
		return types[0]
	return "unknown"


static func _reward_amount(reward: Dictionary) -> int:
	if reward.has("reward_amount"):
		return int(reward.get("reward_amount", 0))
	if reward.has("amount"):
		return int(reward.get("amount", 0))
	var total := 0
	var breakdown := _reward_breakdown(reward)
	for value in breakdown.values():
		if value is Dictionary:
			for nested_value in Dictionary(value).values():
				total += int(nested_value)
		else:
			total += int(value)
	return total


static func _reward_breakdown(reward: Dictionary) -> Dictionary:
	var breakdown := {}
	if int(reward.get("gold", 0)) > 0:
		breakdown["gold"] = int(reward.get("gold", 0))
	if int(reward.get("tokens", 0)) > 0:
		breakdown["tokens"] = int(reward.get("tokens", 0))

	var boosters := {}
	var single_booster_id := String(reward.get("booster", reward.get("booster_id", "")))
	if String(reward.get("reward_type", "")) == "booster" and single_booster_id.is_empty():
		single_booster_id = String(reward.get("reward_id", ""))
	if not single_booster_id.is_empty():
		boosters[single_booster_id] = max(1, int(reward.get("booster_count", reward.get("reward_amount", reward.get("amount", 1)))))
	for booster_id_value in Dictionary(reward.get("boosters", {})).keys():
		var booster_id := String(booster_id_value)
		if booster_id.is_empty():
			continue
		boosters[booster_id] = int(boosters.get(booster_id, 0)) + int(Dictionary(reward.get("boosters", {}))[booster_id_value])
	if not boosters.is_empty():
		breakdown["boosters"] = boosters

	if breakdown.is_empty() and not String(reward.get("reward_type", "")).is_empty():
		breakdown[String(reward.get("reward_type", ""))] = int(reward.get("reward_amount", reward.get("amount", 0)))
	return breakdown
