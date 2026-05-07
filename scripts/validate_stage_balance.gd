extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")

const REQUIRED_SMOKE_STAGES := [1, 5, 10, 20, 31, 51, 81, 100]

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
	var warnings := PackedStringArray()
	var band_summaries: Array[String] = []

	_validate_difficulty_tag_streaks(stages, warnings)
	_validate_roster_rotation(stages, warnings)
	_validate_recommended_smoke_coverage(stages, errors)

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
		var tag_counts := {}

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
			for tag_value in Array(stage.get("tags", [])):
				var tag := String(tag_value)
				tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
			min_moves = mini(min_moves, moves)
			max_moves = maxi(max_moves, moves)
			min_blockers = mini(min_blockers, blocker_count)
			max_blockers = maxi(max_blockers, blocker_count)
			min_active_cells = mini(min_active_cells, active_cells)
			max_active_cells = maxi(max_active_cells, active_cells)
		_validate_band_tag_wave(band_name, tag_counts, errors, warnings)
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
	for warning_text in warnings:
		push_warning("Stage balance validation warning: %s" % warning_text)
	for summary in band_summaries:
		print(summary)
	quit()


func _validate_band_tag_wave(band_name: String, tag_counts: Dictionary, errors: PackedStringArray, warnings: PackedStringArray) -> void:
	if int(tag_counts.get("recovery", 0)) <= 0:
		errors.append("%s band must include at least one recovery stage" % band_name)
	if int(tag_counts.get("blocker_focus", 0)) <= 0:
		errors.append("%s band must include blocker_focus stages" % band_name)
	if int(tag_counts.get("score_focus", 0)) <= 0:
		warnings.append("%s band has no score_focus stages" % band_name)
	if band_name == "31-40" and int(tag_counts.get("combo_focus", 0)) <= 0:
		errors.append("31-40 band must include combo_focus stages for special-combo QA coverage")
	if band_name == "91-100" and int(tag_counts.get("finale", 0)) <= 0:
		errors.append("91-100 band must include finale tags")
	if band_name != "91-100" and int(tag_counts.get("finale", 0)) > 0:
		errors.append("%s band should not use finale tags before final band" % band_name)


func _validate_difficulty_tag_streaks(stages: Array, warnings: PackedStringArray) -> void:
	var sorted_stages := stages.duplicate()
	sorted_stages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("id", 0)) < int(b.get("id", 0)))

	var streak_start := -1
	var streak_count := 0
	for stage in sorted_stages:
		var stage_id := int(stage.get("id", 0))
		var tags: Array = stage.get("tags", [])
		var is_pressure_stage := String(stage.get("difficulty", "")) == "Hard" or tags.has("master") or tags.has("finale")
		var is_recovery := tags.has("recovery")
		if is_pressure_stage and not is_recovery:
			if streak_count == 0:
				streak_start = stage_id
			streak_count += 1
		elif streak_count > 0:
			if streak_count >= 4:
				warnings.append("pressure stage streak %d-%d has %d stages without recovery" % [streak_start, stage_id - 1, streak_count])
			streak_count = 0
			streak_start = -1

	if streak_count >= 4:
		var last_stage_id := int(Dictionary(sorted_stages.back()).get("id", 0))
		warnings.append("pressure stage streak %d-%d has %d stages without recovery" % [streak_start, last_stage_id, streak_count])


func _validate_recommended_smoke_coverage(stages: Array, errors: PackedStringArray) -> void:
	var stages_by_id := {}
	for stage in stages:
		stages_by_id[int(stage.get("id", 0))] = stage
	for stage_id in REQUIRED_SMOKE_STAGES:
		if not stages_by_id.has(stage_id):
			errors.append("required smoke stage %d is missing" % stage_id)
			continue
		var stage: Dictionary = stages_by_id[stage_id]
		if not bool(stage.get("recommended_smoke", false)):
			errors.append("stage %d must set recommended_smoke for QA smoke coverage" % stage_id)
		if stage_id == 31 and not Array(stage.get("tags", [])).has("combo_focus"):
			errors.append("stage 31 must keep combo_focus for special-combo smoke coverage")


func _validate_roster_rotation(stages: Array, warnings: PackedStringArray) -> void:
	var sorted_stages := stages.duplicate()
	sorted_stages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("id", 0)) < int(b.get("id", 0)))

	var pool_counts_by_band := {}
	var post_unlock_presence := {
		"lion": {"unlock": 51, "count": 0},
		"elephant": {"unlock": 81, "count": 0},
	}

	for stage in sorted_stages:
		var stage_id := int(stage.get("id", 0))
		var band := String(stage.get("band", ""))
		var pool: Array = stage.get("animal_pool", [])
		var pool_key := _animal_pool_key(pool)
		if not pool_counts_by_band.has(band):
			pool_counts_by_band[band] = {}
		var band_counts: Dictionary = pool_counts_by_band[band]
		band_counts[pool_key] = int(band_counts.get(pool_key, 0)) + 1

		for animal_id in post_unlock_presence.keys():
			var presence: Dictionary = post_unlock_presence[animal_id]
			if stage_id >= int(presence["unlock"]) and pool.has(animal_id):
				presence["count"] = int(presence["count"]) + 1

	for band in pool_counts_by_band.keys():
		var band_counts: Dictionary = pool_counts_by_band[band]
		for pool_key in band_counts.keys():
			var repeat_count := int(band_counts[pool_key])
			if repeat_count >= 4:
				warnings.append("%s band repeats animal pool [%s] %d times; rotate pools before this becomes stale" % [band, pool_key, repeat_count])

	for animal_id in post_unlock_presence.keys():
		var presence: Dictionary = post_unlock_presence[animal_id]
		var count := int(presence["count"])
		if count < 3:
			warnings.append("%s appears only %d times after unlock stage %d; increase roster rotation coverage" % [animal_id, count, int(presence["unlock"])])


func _animal_pool_key(pool: Array) -> String:
	var ids: Array[String] = []
	for animal_id in pool:
		ids.append(String(animal_id))
	ids.sort()
	return ",".join(ids)


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
