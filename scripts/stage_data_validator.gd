extends RefCounted

const BOARD_ROWS := 8
const BOARD_COLS := 8
const VALID_ANIMALS := ["rabbit", "bear", "cat", "chick", "frog"]


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

		var moves := int(stage.get("moves", 0))
		if moves <= 0:
			errors.append("stage %d has invalid moves %d" % [stage_id, moves])

		var board_mask: Array = stage.get("board_mask", [])
		if board_mask.size() != BOARD_ROWS:
			errors.append("stage %d board_mask must have %d rows" % [stage_id, BOARD_ROWS])
			continue

		var active_cells := 0
		for row in range(BOARD_ROWS):
			var mask_row := String(board_mask[row])
			if mask_row.length() != BOARD_COLS:
				errors.append("stage %d board_mask row %d must have %d columns" % [stage_id, row, BOARD_COLS])
				continue
			for col in range(BOARD_COLS):
				var cell_text := mask_row[col]
				if cell_text != "0" and cell_text != "1":
					errors.append("stage %d board_mask row %d col %d must be 0 or 1" % [stage_id, row, col])
				if cell_text == "1":
					active_cells += 1

		if active_cells <= 0:
			errors.append("stage %d has no active cells in board_mask" % stage_id)

		var collect_targets: Dictionary = stage.get("target_collect", {})
		for animal_id in collect_targets.keys():
			if not VALID_ANIMALS.has(String(animal_id)):
				errors.append("stage %d has unknown collect target %s" % [stage_id, String(animal_id)])
			if int(collect_targets[animal_id]) < 0:
				errors.append("stage %d has negative collect target for %s" % [stage_id, String(animal_id)])

		var target_score := int(stage.get("target_score", 0))
		if target_score < 0:
			errors.append("stage %d has negative target_score" % stage_id)

		var target_blockers := int(stage.get("target_blockers", 0))
		if target_blockers < 0:
			errors.append("stage %d has negative target_blockers" % stage_id)

		var animal_pool: Array = stage.get("animal_pool", [])
		if animal_pool.is_empty():
			errors.append("stage %d has empty animal_pool" % stage_id)
		for animal_id in animal_pool:
			if not VALID_ANIMALS.has(String(animal_id)):
				errors.append("stage %d has unknown animal_pool entry %s" % [stage_id, String(animal_id)])

		var spawn_weights: Dictionary = stage.get("spawn_weights", {})
		for animal_id in animal_pool:
			var weight := int(spawn_weights.get(animal_id, 0))
			if weight <= 0:
				errors.append("stage %d has invalid spawn weight for %s" % [stage_id, String(animal_id)])

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


static func _mask_cell_is_active(board_mask: Array, row: int, col: int) -> bool:
	if row < 0 or row >= board_mask.size():
		return false
	var mask_row := String(board_mask[row])
	if col < 0 or col >= mask_row.length():
		return false
	return mask_row[col] == "1"
