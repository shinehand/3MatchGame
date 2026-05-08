extends RefCounted

const ANIMAL_DATA_PATH := "res://data/animals.json"
const FRIENDSHIP_TOKEN_STEP := 20
const FRIENDSHIP_MAX_LEVEL := 5


static func load_animal_definitions() -> Array:
	if not FileAccess.file_exists(ANIMAL_DATA_PATH):
		push_error("CollectionState: missing animal data %s" % ANIMAL_DATA_PATH)
		return []
	var raw_text := FileAccess.get_file_as_string(ANIMAL_DATA_PATH)
	var parsed = JSON.parse_string(raw_text)
	if not (parsed is Array):
		push_error("CollectionState: animal data must be an array.")
		return []
	return Array(parsed)


static func make_default_state() -> Dictionary:
	var animals := {}
	for animal in load_animal_definitions():
		if not (animal is Dictionary):
			continue
		var animal_id := String(Dictionary(animal).get("id", ""))
		if animal_id.is_empty():
			continue
		var friendship_level := 1
		animals[animal_id] = {
			"unlocked": int(Dictionary(animal).get("unlock_stage", 1)) <= 1,
			"tokens": 0,
			"friendship_level": friendship_level,
			"equipped_cosmetic": String(Dictionary(animal).get("default_cosmetic", "none")),
			"earned_rewards": _earned_reward_ids_for_definition(Dictionary(animal), friendship_level),
			"is_new": int(Dictionary(animal).get("unlock_stage", 1)) <= 1,
		}
	return {"animals": animals}


static func normalize_state(raw_state: Dictionary) -> Dictionary:
	var normalized := make_default_state()
	var normalized_animals: Dictionary = normalized.get("animals", {})
	var raw_animals: Dictionary = Dictionary(raw_state.get("animals", {}))

	for animal_id in normalized_animals.keys():
		var base_entry: Dictionary = normalized_animals[animal_id]
		var raw_entry: Dictionary = Dictionary(raw_animals.get(animal_id, {}))
		base_entry["unlocked"] = bool(raw_entry.get("unlocked", base_entry.get("unlocked", false)))
		base_entry["tokens"] = max(0, int(raw_entry.get("tokens", base_entry.get("tokens", 0))))
		base_entry["friendship_level"] = clampi(max(1, int(raw_entry.get("friendship_level", base_entry.get("friendship_level", 1)))), 1, FRIENDSHIP_MAX_LEVEL)
		base_entry["equipped_cosmetic"] = String(raw_entry.get("equipped_cosmetic", base_entry.get("equipped_cosmetic", "none")))
		base_entry["earned_rewards"] = _merge_reward_ids(
			Array(raw_entry.get("earned_rewards", base_entry.get("earned_rewards", []))),
			_earned_reward_ids_for_animal(animal_id, int(base_entry.get("friendship_level", 1)))
		)
		base_entry["is_new"] = bool(raw_entry.get("is_new", base_entry.get("is_new", false)))
		normalized_animals[animal_id] = base_entry
	normalized["animals"] = normalized_animals
	return normalized


static func unlock_by_stage(raw_state: Dictionary, stage_id: int) -> Dictionary:
	var state := normalize_state(raw_state)
	var animals: Dictionary = state.get("animals", {})
	for animal in load_animal_definitions():
		if not (animal is Dictionary):
			continue
		var animal_id := String(Dictionary(animal).get("id", ""))
		var unlock_stage := int(Dictionary(animal).get("unlock_stage", 1))
		if animal_id.is_empty() or stage_id < unlock_stage:
			continue
		var entry: Dictionary = Dictionary(animals.get(animal_id, {}))
		if not bool(entry.get("unlocked", false)):
			entry["unlocked"] = true
			entry["is_new"] = true
		animals[animal_id] = entry
	state["animals"] = animals
	return state


static func add_tokens(raw_state: Dictionary, animal_id: String, token_count: int) -> Dictionary:
	var state := normalize_state(raw_state)
	var animals: Dictionary = state.get("animals", {})
	if not animals.has(animal_id):
		return state
	var entry: Dictionary = Dictionary(animals[animal_id])
	entry["tokens"] = max(0, int(entry.get("tokens", 0)) + token_count)
	entry["friendship_level"] = _friendship_level_for_tokens(int(entry.get("tokens", 0)))
	entry["earned_rewards"] = _merge_reward_ids(
		Array(entry.get("earned_rewards", [])),
		_earned_reward_ids_for_animal(animal_id, int(entry.get("friendship_level", 1)))
	)
	animals[animal_id] = entry
	state["animals"] = animals
	return state


static func _friendship_level_for_tokens(token_count: int) -> int:
	return clampi(1 + int(max(0, token_count) / FRIENDSHIP_TOKEN_STEP), 1, FRIENDSHIP_MAX_LEVEL)


static func animal_definition_by_id(animal_id: String) -> Dictionary:
	for animal in load_animal_definitions():
		if animal is Dictionary and String(Dictionary(animal).get("id", "")) == animal_id:
			return Dictionary(animal).duplicate(true)
	return {}


static func reward_track_for_animal(animal_id: String) -> Array:
	return Array(animal_definition_by_id(animal_id).get("friendship_rewards", [])).duplicate(true)


static func reward_entries_earned_between(animal_id: String, level_before: int, level_after: int) -> Array:
	var earned := []
	for reward in reward_track_for_animal(animal_id):
		if not (reward is Dictionary):
			continue
		var reward_dict: Dictionary = reward
		var reward_level := int(reward_dict.get("level", 0))
		if reward_level > level_before and reward_level <= level_after:
			earned.append(reward_dict.duplicate(true))
	return earned


static func _earned_reward_ids_for_animal(animal_id: String, friendship_level: int) -> Array:
	return _earned_reward_ids_for_definition(animal_definition_by_id(animal_id), friendship_level)


static func _earned_reward_ids_for_definition(animal: Dictionary, friendship_level: int) -> Array:
	var earned := []
	for reward in Array(animal.get("friendship_rewards", [])):
		if not (reward is Dictionary):
			continue
		var reward_dict: Dictionary = reward
		var reward_id := String(reward_dict.get("reward_id", "")).strip_edges()
		if reward_id.is_empty() or int(reward_dict.get("level", 0)) > friendship_level:
			continue
		if not earned.has(reward_id):
			earned.append(reward_id)
	return earned


static func _merge_reward_ids(existing_ids: Array, required_ids: Array) -> Array:
	var merged := []
	for reward_id_value in existing_ids + required_ids:
		var reward_id := String(reward_id_value).strip_edges()
		if reward_id.is_empty() or merged.has(reward_id):
			continue
		merged.append(reward_id)
	return merged
