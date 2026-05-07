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
		animals[animal_id] = {
			"unlocked": int(Dictionary(animal).get("unlock_stage", 1)) <= 1,
			"tokens": 0,
			"friendship_level": 1,
			"equipped_cosmetic": String(Dictionary(animal).get("default_cosmetic", "none")),
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
		base_entry["friendship_level"] = max(1, int(raw_entry.get("friendship_level", base_entry.get("friendship_level", 1))))
		base_entry["equipped_cosmetic"] = String(raw_entry.get("equipped_cosmetic", base_entry.get("equipped_cosmetic", "none")))
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
	animals[animal_id] = entry
	state["animals"] = animals
	return state


static func _friendship_level_for_tokens(token_count: int) -> int:
	return clampi(1 + int(max(0, token_count) / FRIENDSHIP_TOKEN_STEP), 1, FRIENDSHIP_MAX_LEVEL)
