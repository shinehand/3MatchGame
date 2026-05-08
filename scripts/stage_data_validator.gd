extends RefCounted

const BOARD_ROWS := 8
const BOARD_COLS := 8
const BOARD_NEIGHBOR_OFFSETS := [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]
const VALID_ANIMALS := ["rabbit", "bear", "cat", "chick", "frog", "dog", "panda", "pig", "penguin", "fox", "lion", "elephant"]
const COLLECTION_BOARD_EXPANSION_ORDER := {
	"koala": {"order": 1, "min_stage": 101, "stage_band": "101-110"},
	"hamster": {"order": 2, "min_stage": 111, "stage_band": "111-120"},
	"deer": {"order": 3, "min_stage": 121, "stage_band": "121-130"},
	"seal": {"order": 4, "min_stage": 131, "stage_band": "131-140"},
	"sheep": {"order": 5, "min_stage": 141, "stage_band": "141-150"},
	"turtle": {"order": 6, "min_stage": 151, "stage_band": "151-160"},
}
const VALID_ROSTER_GROUPS := [
	"forest_early",
	"trap_trail",
	"camp_outer",
	"rescue_route",
	"river_crossing",
	"camp_inner",
	"deep_jungle",
	"escape_prep",
	"elephant_route",
	"final_rescue",
]
const ANIMAL_UNLOCK_STAGE := {
	"lion": 51,
	"elephant": 81,
}
const VALID_STAGE_TAGS := [
	"recovery",
	"score_focus",
	"blocker_focus",
	"combo_focus",
	"mixed_goal",
	"finale",
	"master",
]
const VALID_DIFFICULTY_TAGS := [
	"standard",
	"recovery",
	"score_focus",
	"blocker_focus",
	"combo_focus",
	"mixed_goal",
	"finale",
	"master",
]
const VALID_LEARNING_KEYS := [
	"basic_match",
	"collect_goal",
	"multi_collect_goal",
	"line_special",
	"rescue_buddy",
	"blocker_bush",
	"buddy_soft_bomb_plus",
	"rainbow_special",
	"combo_gauge",
	"buddy_combo_peep",
	"ftue_mastery_check",
	"buddy_smart_hint",
	"buddy_leap_clear",
	"near_fail_rescue_buddy",
	"buddy_calm_fever",
	"buddy_coin_sniff",
	"buddy_cascade_slide",
	"buddy_sly_route",
	"buddy_brave_start",
	"buddy_mighty_push",
	"lion_unlock",
	"elephant_unlock",
	"finale_mastery",
]
const VALID_PREVIEW_KEYS := [
	"rescue_buddy",
	"chick_buddy",
	"dog",
	"rainbow_special",
	"combo_gauge",
	"cascade_slide",
	"sly_route",
	"brave_start",
	"mighty_push",
	"trap_trail",
	"camp_outer",
	"lion",
	"elephant",
	"final_rescue",
]
const VALID_BUDDY_SKILLS := [
	"quick_refill",
	"soft_bomb_plus",
	"smart_hint",
	"combo_peep",
	"leap_clear",
	"loyal_fetch",
	"calm_fever",
	"coin_sniff",
	"cascade_slide",
	"sly_route",
	"brave_start",
	"mighty_push",
]
const VALID_BUDDY_CHARGE_RULES := [
	"match_goal_animal",
	"create_special",
	"trigger_special",
	"clear_blocker",
	"cascade_step",
	"near_fail",
	"stage_clear",
	"combo_2_plus",
	"fever_start",
	"stage_start",
]
const BUDDY_REPEATABLE_MAX_USE_RULES := [
	"match_goal_animal",
	"clear_blocker",
	"cascade_step",
	"near_fail",
	"combo_2_plus",
]
const BUDDY_SKILL_TUNING := {
	"quick_refill": {"animal": "rabbit", "charge_rule": "match_goal_animal", "charges_required": 3, "max_uses": 1, "min_stage": 4},
	"soft_bomb_plus": {"animal": "chick", "charge_rule": "match_goal_animal", "charges_required": 4, "max_uses": 1, "min_stage": 5},
	"smart_hint": {"animal": "cat", "charge_rule": "match_goal_animal", "charges_required": 3, "max_uses": 1, "min_stage": 16},
	"combo_peep": {"animal": "chick", "charge_rule": "combo_2_plus", "charges_required": 2, "max_uses": 1, "min_stage": 8},
	"leap_clear": {"animal": "frog", "charge_rule": "match_goal_animal", "charges_required": 3, "max_uses": 1, "min_stage": 18},
	"loyal_fetch": {"animal": "dog", "charge_rule": "near_fail", "charges_required": 1, "max_uses": 1, "min_stage": 20},
	"calm_fever": {"animal": "panda", "charge_rule": "fever_start", "charges_required": 1, "max_uses": 1, "min_stage": 24},
	"coin_sniff": {"animal": "pig", "charge_rule": "stage_clear", "charges_required": 1, "max_uses": 1, "min_stage": 25},
	"cascade_slide": {"animal": "penguin", "charge_rule": "cascade_step", "charges_required": 1, "max_uses": 1, "min_stage": 31},
	"sly_route": {"animal": "fox", "charge_rule": "near_fail", "charges_required": 1, "max_uses": 1, "min_stage": 41},
	"brave_start": {"animal": "lion", "charge_rule": "stage_start", "charges_required": 1, "max_uses": 1, "min_stage": 51},
	"mighty_push": {"animal": "elephant", "charge_rule": "clear_blocker", "charges_required": 1, "max_uses": 1, "min_stage": 81},
}


static func validate_stages(stages: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids := {}

	if stages.is_empty():
		errors.append("no stages loaded")
		return errors

	for index in range(stages.size()):
		var stage = stages[index]
		if not stage is Dictionary:
			errors.append("stage at index %d is not a dictionary" % index)
			continue

		var stage_id := int(stage.get("id", 0))
		if stage_id <= 0:
			errors.append("stage at index %d has invalid id %d" % [index, stage_id])
		elif seen_ids.has(stage_id):
			errors.append("duplicate stage id %d" % stage_id)
		else:
			seen_ids[stage_id] = true

		var stage_name := String(stage.get("name", ""))
		if stage_name.is_empty():
			errors.append("stage %d has empty name" % stage_id)

		var roster_group := String(stage.get("roster_group", ""))
		if not VALID_ROSTER_GROUPS.has(roster_group):
			errors.append("stage %d has invalid roster_group %s" % [stage_id, roster_group])

		var stage_tags: Array = stage.get("tags", [])
		for tag_value in stage_tags:
			var tag := String(tag_value)
			if not VALID_STAGE_TAGS.has(tag):
				errors.append("stage %d has unknown tag %s" % [stage_id, tag])
		_validate_progression_metadata(stage, stage_id, stage_tags, errors)

		var moves := int(stage.get("moves", 0))
		if moves <= 0:
			errors.append("stage %d has invalid moves %d" % [stage_id, moves])

		var board_mask: Array = stage.get("board_mask", [])
		if board_mask.size() != BOARD_ROWS:
			errors.append("stage %d board_mask must have %d rows" % [stage_id, BOARD_ROWS])
			continue

		var active_cells := 0
		var board_mask_shape_valid := true
		for row in range(BOARD_ROWS):
			var mask_row := String(board_mask[row])
			if mask_row.length() != BOARD_COLS:
				errors.append("stage %d board_mask row %d must have %d columns" % [stage_id, row, BOARD_COLS])
				board_mask_shape_valid = false
				continue
			for col in range(BOARD_COLS):
				var cell_text := mask_row[col]
				if cell_text != "0" and cell_text != "1":
					errors.append("stage %d board_mask row %d col %d must be 0 or 1" % [stage_id, row, col])
					board_mask_shape_valid = false
				if cell_text == "1":
					active_cells += 1

		if active_cells <= 0:
			errors.append("stage %d has no active cells in board_mask" % stage_id)
		elif board_mask_shape_valid:
			_validate_board_mask_topology(board_mask, stage_id, errors)

		var collect_targets: Dictionary = stage.get("target_collect", {})
		for animal_id in collect_targets.keys():
			var target_animal_id := String(animal_id)
			if COLLECTION_BOARD_EXPANSION_ORDER.has(target_animal_id):
				errors.append(_collection_board_disabled_error(stage_id, target_animal_id, "target_collect"))
			elif not VALID_ANIMALS.has(target_animal_id):
				errors.append("stage %d has unknown collect target %s" % [stage_id, target_animal_id])
			if int(collect_targets[animal_id]) < 0:
				errors.append("stage %d has negative collect target for %s" % [stage_id, target_animal_id])

		var target_score := int(stage.get("target_score", 0))
		if target_score < 0:
			errors.append("stage %d has negative target_score" % stage_id)

		var target_blockers := int(stage.get("target_blockers", 0))
		if target_blockers < 0:
			errors.append("stage %d has negative target_blockers" % stage_id)

		var mechanics: Dictionary = stage.get("mechanics", {})
		var enabled_mechanics: Array = mechanics.get("enabled", [])
		_validate_mechanics_unlocks(stage_id, enabled_mechanics, errors)
		_validate_tutorial_text_alignment(stage_id, String(stage.get("tutorial", "")), enabled_mechanics, errors)

		var animal_pool: Array = stage.get("animal_pool", [])
		if animal_pool.is_empty():
			errors.append("stage %d has empty animal_pool (source spawn_profile.pool)" % stage_id)
		var min_pool_size := 4
		var max_pool_size := 6
		if animal_pool.size() < min_pool_size or animal_pool.size() > max_pool_size:
			errors.append("stage %d animal_pool size %d must be %d-%d (source spawn_profile.pool)" % [stage_id, animal_pool.size(), min_pool_size, max_pool_size])
		for animal_id in animal_pool:
			var pool_animal_id := String(animal_id)
			if COLLECTION_BOARD_EXPANSION_ORDER.has(pool_animal_id):
				errors.append(_collection_board_disabled_error(stage_id, pool_animal_id, "animal_pool (source spawn_profile.pool)"))
			elif not VALID_ANIMALS.has(pool_animal_id):
				errors.append("stage %d has unknown animal_pool entry %s (source spawn_profile.pool)" % [stage_id, pool_animal_id])

		var spawn_weights: Dictionary = stage.get("spawn_weights", {})
		for animal_id in animal_pool:
			var animal_key := String(animal_id)
			var weight := int(spawn_weights.get(animal_key, 0))
			if weight <= 0:
				errors.append("stage %d has invalid spawn weight for %s (source spawn_profile.weights)" % [stage_id, animal_key])
			var unlock_stage := int(ANIMAL_UNLOCK_STAGE.get(animal_key, 1))
			if stage_id < unlock_stage:
				errors.append("stage %d uses %s before unlock stage %d" % [stage_id, animal_key, unlock_stage])
		for weighted_animal_id in spawn_weights.keys():
			var weighted_animal_key := String(weighted_animal_id)
			if COLLECTION_BOARD_EXPANSION_ORDER.has(weighted_animal_key):
				errors.append(_collection_board_disabled_error(stage_id, weighted_animal_key, "spawn_weights (source spawn_profile.weights)"))
			if not animal_pool.has(weighted_animal_key):
				errors.append("stage %d spawn weight %s is outside animal_pool (source spawn_profile.weights)" % [stage_id, weighted_animal_key])
		for animal_id in collect_targets.keys():
			if not animal_pool.has(String(animal_id)):
				errors.append("stage %d collect target %s must be included in animal_pool (source spawn_profile.pool)" % [stage_id, String(animal_id)])

		_validate_buddy_config(stage, stage_id, errors)

		var blockers: Array = stage.get("blockers", [])
		for blocker in blockers:
			if not blocker is Dictionary:
				errors.append("stage %d has non-dictionary blocker entry" % stage_id)
				continue
			var row := int(blocker.get("row", -1))
			var col := int(blocker.get("col", -1))
			if row < 0 or row >= BOARD_ROWS or col < 0 or col >= BOARD_COLS:
				errors.append("stage %d blocker out of bounds at (%d, %d)" % [stage_id, row, col])
				continue
			if not _mask_cell_is_active(board_mask, row, col):
				errors.append("stage %d blocker placed on inactive cell (%d, %d)" % [stage_id, row, col])

		if blockers.size() < target_blockers:
			errors.append("stage %d target_blockers %d exceeds placed blockers %d" % [stage_id, target_blockers, blockers.size()])

	for expected_id in range(1, stages.size() + 1):
		if not seen_ids.has(expected_id):
			errors.append("missing stage id %d in loaded stage range" % expected_id)

	return errors


static func _validate_progression_metadata(stage: Dictionary, stage_id: int, stage_tags: Array, errors: PackedStringArray) -> void:
	var difficulty_tags: Array = stage.get("difficulty_tag", [])
	if stage_id <= 10 and difficulty_tags.is_empty():
		errors.append("stage %d must define difficulty_tag for FTUE/content-bible alignment" % stage_id)
	for tag_value in difficulty_tags:
		var tag := String(tag_value)
		if not VALID_DIFFICULTY_TAGS.has(tag):
			errors.append("stage %d has unknown difficulty_tag %s" % [stage_id, tag])
		if tag != "standard" and not stage_tags.has(tag):
			errors.append("stage %d difficulty_tag %s must mirror a gameplay tag or use standard" % [stage_id, tag])

	for teach_value in Array(stage.get("teaches", [])):
		var teach_key := String(teach_value)
		if not VALID_LEARNING_KEYS.has(teach_key):
			errors.append("stage %d has unknown teaches key %s" % [stage_id, teach_key])
	for preview_value in Array(stage.get("previews", [])):
		var preview_key := String(preview_value)
		if not VALID_PREVIEW_KEYS.has(preview_key):
			errors.append("stage %d has unknown previews key %s" % [stage_id, preview_key])

	if stage_id <= 10 and not bool(stage.get("forbidden_monetization", false)):
		errors.append("stage %d must set forbidden_monetization for Level 1-10" % stage_id)
	if stage_id == 1 and not Array(stage.get("teaches", [])).has("basic_match"):
		errors.append("stage 1 must teach basic_match")
	if stage_id == 3 and not Array(stage.get("teaches", [])).has("line_special"):
		errors.append("stage 3 must teach line_special")
	if stage_id == 7 and not Array(stage.get("teaches", [])).has("rainbow_special"):
		errors.append("stage 7 must teach rainbow_special")
	if stage_id == 8 and not Array(stage.get("teaches", [])).has("combo_gauge"):
		errors.append("stage 8 must teach combo_gauge")


static func _validate_tutorial_text_alignment(stage_id: int, tutorial_text: String, enabled_mechanics: Array, errors: PackedStringArray) -> void:
	var text := tutorial_text.strip_edges()
	if stage_id <= 10 and text.is_empty():
		errors.append("stage %d tutorial text is required for FTUE alignment" % stage_id)
	if stage_id <= 2:
		for advanced_keyword in ["특수", "무지개", "Combo", "콤보"]:
			if text.contains(advanced_keyword):
				errors.append("stage %d tutorial mentions %s before mechanic unlock" % [stage_id, advanced_keyword])
	if stage_id == 3 and not (text.contains("4개") or text.contains("줄 제거")):
		errors.append("stage 3 tutorial should introduce 4-match line special")
	if stage_id == 7 and enabled_mechanics.has("rainbow_special") and not text.contains("무지개"):
		errors.append("stage 7 tutorial should introduce rainbow special")
	if stage_id >= 8 and stage_id <= 10 and enabled_mechanics.has("combo_gauge") and not (text.contains("Combo") or text.contains("콤보")):
		errors.append("stage %d tutorial should mention Combo Gauge after unlock" % stage_id)


static func _validate_buddy_config(stage: Dictionary, stage_id: int, errors: PackedStringArray) -> void:
	var buddy_animal := String(stage.get("buddy_animal", ""))
	var buddy_skill_id := String(stage.get("buddy_skill_id", ""))
	var buddy_charge_rule := String(stage.get("buddy_charge_rule", ""))
	var charges_required := int(stage.get("buddy_charges_required", 0))
	var max_uses := int(stage.get("buddy_max_uses", 0))

	if buddy_animal.is_empty() and buddy_skill_id.is_empty() and buddy_charge_rule.is_empty() and charges_required == 0 and max_uses == 0:
		return
	if COLLECTION_BOARD_EXPANSION_ORDER.has(buddy_animal):
		errors.append(_collection_board_disabled_error(stage_id, buddy_animal, "buddy_animal"))
	elif not VALID_ANIMALS.has(buddy_animal):
		errors.append("stage %d has invalid buddy_animal %s" % [stage_id, buddy_animal])
	if not VALID_BUDDY_SKILLS.has(buddy_skill_id):
		errors.append("stage %d has invalid buddy_skill_id %s" % [stage_id, buddy_skill_id])
	if not VALID_BUDDY_CHARGE_RULES.has(buddy_charge_rule):
		errors.append("stage %d has invalid buddy_charge_rule %s" % [stage_id, buddy_charge_rule])
	if charges_required <= 0:
		errors.append("stage %d buddy_charges_required must be positive" % stage_id)
	if max_uses <= 0 or max_uses > 2:
		errors.append("stage %d buddy_max_uses must be 1-2" % stage_id)
	var unlock_stage := int(ANIMAL_UNLOCK_STAGE.get(buddy_animal, 1))
	if stage_id < unlock_stage:
		errors.append("stage %d uses buddy %s before unlock stage %d" % [stage_id, buddy_animal, unlock_stage])
	if BUDDY_SKILL_TUNING.has(buddy_skill_id):
		var tuning: Dictionary = Dictionary(BUDDY_SKILL_TUNING[buddy_skill_id])
		if buddy_animal != String(tuning.get("animal", "")):
			errors.append("stage %d buddy skill %s must use animal %s, got %s" % [stage_id, buddy_skill_id, String(tuning.get("animal", "")), buddy_animal])
		if buddy_charge_rule != String(tuning.get("charge_rule", "")):
			errors.append("stage %d buddy skill %s must use charge_rule %s, got %s" % [stage_id, buddy_skill_id, String(tuning.get("charge_rule", "")), buddy_charge_rule])
		if charges_required != int(tuning.get("charges_required", 0)):
			errors.append("stage %d buddy skill %s must require %d charges, got %d" % [stage_id, buddy_skill_id, int(tuning.get("charges_required", 0)), charges_required])
		var min_max_uses := int(tuning.get("max_uses", 1))
		var allowed_max_uses := _buddy_allowed_max_uses(stage, tuning)
		if max_uses < min_max_uses or max_uses > allowed_max_uses:
			var allowed_text := str(min_max_uses) if min_max_uses == allowed_max_uses else "%d-%d" % [min_max_uses, allowed_max_uses]
			errors.append("stage %d buddy skill %s must allow %s max uses for this difficulty, got %d" % [stage_id, buddy_skill_id, allowed_text, max_uses])
		if stage_id < int(tuning.get("min_stage", 1)):
			errors.append("stage %d uses buddy skill %s before minimum stage %d" % [stage_id, buddy_skill_id, int(tuning.get("min_stage", 1))])


static func _collection_board_disabled_error(stage_id: int, animal_id: String, field_name: String) -> String:
	var expansion: Dictionary = Dictionary(COLLECTION_BOARD_EXPANSION_ORDER.get(animal_id, {}))
	return "stage %d uses board_enabled=false collection animal %s in %s; enable it only after expansion order %d (%s, min stage %d)" % [
		stage_id,
		animal_id,
		field_name,
		int(expansion.get("order", 0)),
		String(expansion.get("stage_band", "")),
		int(expansion.get("min_stage", 0)),
	]


static func _buddy_allowed_max_uses(stage: Dictionary, tuning: Dictionary) -> int:
	var default_max_uses := int(tuning.get("max_uses", 1))
	if not BUDDY_REPEATABLE_MAX_USE_RULES.has(String(tuning.get("charge_rule", ""))):
		return default_max_uses
	if not _is_hard_or_finale_stage(stage):
		return default_max_uses
	return 2


static func _is_hard_or_finale_stage(stage: Dictionary) -> bool:
	if String(stage.get("difficulty", "")).to_lower() == "hard":
		return true
	for tag_value in Array(stage.get("tags", [])):
		if String(tag_value) == "finale":
			return true
	for tag_value in Array(stage.get("difficulty_tag", [])):
		if String(tag_value) == "finale":
			return true
	return false


static func _validate_mechanics_unlocks(stage_id: int, enabled_mechanics: Array, errors: PackedStringArray) -> void:
	if stage_id <= 2:
		for locked_mechanic in ["row_special", "col_special", "bomb_special", "rainbow_special", "combo_gauge"]:
			if enabled_mechanics.has(locked_mechanic):
				errors.append("stage %d enables %s before tutorial unlock" % [stage_id, locked_mechanic])
	elif stage_id < 7:
		for line_mechanic in ["row_special", "col_special"]:
			if not enabled_mechanics.has(line_mechanic):
				errors.append("stage %d must include %s after line-special tutorial unlock" % [stage_id, line_mechanic])
		for locked_mechanic in ["rainbow_special", "combo_gauge"]:
			if enabled_mechanics.has(locked_mechanic):
				errors.append("stage %d enables %s before tutorial unlock" % [stage_id, locked_mechanic])
	elif stage_id <= 10:
		if not enabled_mechanics.has("rainbow_special"):
			errors.append("stage %d must include rainbow_special after stage 7 unlock" % stage_id)
		if stage_id >= 8 and not enabled_mechanics.has("combo_gauge"):
			errors.append("stage %d must include combo_gauge after stage 8 unlock" % stage_id)


static func _mask_cell_is_active(board_mask: Array, row: int, col: int) -> bool:
	if row < 0 or row >= board_mask.size():
		return false
	var mask_row := String(board_mask[row])
	if col < 0 or col >= mask_row.length():
		return false
	return mask_row[col] == "1"


static func _validate_board_mask_topology(board_mask: Array, stage_id: int, errors: PackedStringArray) -> void:
	var visited := {}
	var component_sizes: Array[int] = []
	for row in range(BOARD_ROWS):
		for col in range(BOARD_COLS):
			if not _mask_cell_is_active(board_mask, row, col):
				continue
			var key := _board_cell_key(row, col)
			if visited.has(key):
				continue
			component_sizes.append(_flood_fill_board_mask_component(board_mask, Vector2i(row, col), visited))

	if component_sizes.size() > 1:
		errors.append("stage %d board_mask active cells must be 4-way connected; found %d components with sizes [%s]" % [stage_id, component_sizes.size(), _component_sizes_text(component_sizes)])
	for component_size in component_sizes:
		if component_size < 3:
			errors.append("stage %d board_mask component size %d is too small for match-3 play" % [stage_id, component_size])


static func _flood_fill_board_mask_component(board_mask: Array, start: Vector2i, visited: Dictionary) -> int:
	var queue: Array[Vector2i] = [start]
	visited[_board_cell_key(start.x, start.y)] = true
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for offset_value in BOARD_NEIGHBOR_OFFSETS:
			var offset: Vector2i = offset_value
			var next: Vector2i = cell + offset
			if not _mask_cell_is_active(board_mask, next.x, next.y):
				continue
			var key := _board_cell_key(next.x, next.y)
			if visited.has(key):
				continue
			visited[key] = true
			queue.append(next)
	return queue.size()


static func _board_cell_key(row: int, col: int) -> String:
	return "%d:%d" % [row, col]


static func _component_sizes_text(component_sizes: Array[int]) -> String:
	var parts := PackedStringArray()
	for component_size in component_sizes:
		parts.append(str(component_size))
	return ", ".join(parts)
