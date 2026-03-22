extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")

const BAND_RULES := {
	"1-10": {"min_id": 1, "max_id": 10, "moves_min": 12, "moves_max": 13, "blockers_min": 0, "blockers_max": 2},
	"11-20": {"min_id": 11, "max_id": 20, "moves_min": 13, "moves_max": 14, "blockers_min": 1, "blockers_max": 4},
	"21-30": {"min_id": 21, "max_id": 30, "moves_min": 14, "moves_max": 15, "blockers_min": 4, "blockers_max": 6},
	"31-40": {"min_id": 31, "max_id": 40, "moves_min": 15, "moves_max": 16, "blockers_min": 6, "blockers_max": 7},
	"41-50": {"min_id": 41, "max_id": 50, "moves_min": 16, "moves_max": 17, "blockers_min": 8, "blockers_max": 9},
	"51-60": {"min_id": 51, "max_id": 60, "moves_min": 16, "moves_max": 17, "blockers_min": 9, "blockers_max": 10},
	"61-70": {"min_id": 61, "max_id": 70, "moves_min": 17, "moves_max": 18, "blockers_min": 10, "blockers_max": 11},
	"71-80": {"min_id": 71, "max_id": 80, "moves_min": 18, "moves_max": 18, "blockers_min": 11, "blockers_max": 12},
	"81-90": {"min_id": 81, "max_id": 90, "moves_min": 18, "moves_max": 18, "blockers_min": 12, "blockers_max": 13},
	"91-100": {"min_id": 91, "max_id": 100, "moves_min": 18, "moves_max": 19, "blockers_min": 13, "blockers_max": 14},
}


func _init() -> void:
	var stages: Array = StageCatalog.get_stages()
	if stages.size() != 100:
		push_error("Stage balance validation failed: expected 100 stages, got %d." % stages.size())
		quit(1)
		return

	var errors := PackedStringArray()
	var band_summaries: Array[String] = []

	for band_name in BAND_RULES.keys():
		var rule: Dictionary = BAND_RULES[band_name]
		var band_stages := _filter_band_stages(stages, band_name)
		if band_stages.size() != 10:
			errors.append("%s band must contain 10 stages, got %d" % [band_name, band_stages.size()])
			continue

		var min_moves := 999
		var max_moves := -1
		var min_blockers := 999
		var max_blockers := -1
		var min_active_cells := 999
		var max_active_cells := -1

		for stage in band_stages:
			var stage_id := int(stage.get("id", 0))
			if stage_id < int(rule["min_id"]) or stage_id > int(rule["max_id"]):
				errors.append("stage %d claims band %s but id is outside the expected range" % [stage_id, band_name])

			var moves := int(stage.get("moves", 0))
			if moves < int(rule["moves_min"]) or moves > int(rule["moves_max"]):
				errors.append("stage %d moves %d is outside %s band range %d-%d" % [
					stage_id,
					moves,
					band_name,
					int(rule["moves_min"]),
					int(rule["moves_max"]),
				])

			var blocker_count := Array(stage.get("blockers", [])).size()
			if blocker_count < int(rule["blockers_min"]) or blocker_count > int(rule["blockers_max"]):
				errors.append("stage %d blocker count %d is outside %s band range %d-%d" % [
					stage_id,
					blocker_count,
					band_name,
					int(rule["blockers_min"]),
					int(rule["blockers_max"]),
				])

			var active_cells := _count_active_cells(Array(stage.get("board_mask", [])))
			min_moves = mini(min_moves, moves)
			max_moves = maxi(max_moves, moves)
			min_blockers = mini(min_blockers, blocker_count)
			max_blockers = maxi(max_blockers, blocker_count)
			min_active_cells = mini(min_active_cells, active_cells)
			max_active_cells = maxi(max_active_cells, active_cells)
		band_summaries.append(
			"%s: moves %d-%d, blockers %d-%d, active_cells %d-%d" % [
				band_name,
				min_moves,
				max_moves,
				min_blockers,
				max_blockers,
				min_active_cells,
				max_active_cells,
			]
		)

	if not errors.is_empty():
		for error_text in errors:
			push_error("Stage balance validation error: %s" % error_text)
		quit(1)
		return

	print("Stage balance validation passed.")
	for summary in band_summaries:
		print(summary)
	quit()


func _filter_band_stages(stages: Array, band_name: String) -> Array:
	var band_stages: Array = []
	for stage in stages:
		if String(stage.get("band", "")) == band_name:
			band_stages.append(stage)
	return band_stages


func _count_active_cells(board_mask: Array) -> int:
	var active_cells := 0
	for mask_row_value in board_mask:
		var mask_row := String(mask_row_value)
		for col in range(mask_row.length()):
			if mask_row[col] == "1":
				active_cells += 1
	return active_cells
