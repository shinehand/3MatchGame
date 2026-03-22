extends RefCounted

const StageDataValidator = preload("res://scripts/stage_data_validator.gd")
const STAGE_FILES := [
	"res://data/stages/stages_001_010.json",
	"res://data/stages/stages_011_020.json",
	"res://data/stages/stages_021_030.json",
	"res://data/stages/stages_031_040.json",
	"res://data/stages/stages_041_050.json",
	"res://data/stages/stages_051_060.json",
	"res://data/stages/stages_061_070.json",
	"res://data/stages/stages_071_080.json",
	"res://data/stages/stages_081_090.json",
	"res://data/stages/stages_091_100.json",
]


static func get_stages() -> Array:
	var stages := _load_stage_files()
	if stages.is_empty():
		push_warning("StageCatalog: JSON stage data could not be loaded, using fallback stages.")
		return _fallback_stages()

	var errors: PackedStringArray = StageDataValidator.validate_stages(stages)
	if not errors.is_empty():
		for error_text in errors:
			push_error("StageCatalog validation error: %s" % error_text)
		push_warning("StageCatalog: invalid JSON stage data, using fallback stages.")
		return _fallback_stages()

	stages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("id", 0)) < int(b.get("id", 0)))
	return stages


static func _load_stage_files() -> Array:
	var stages: Array = []

	for stage_file in STAGE_FILES:
		if not FileAccess.file_exists(stage_file):
			push_error("StageCatalog: missing stage file %s" % stage_file)
			return []

		var raw_text := FileAccess.get_file_as_string(stage_file)
		var parsed = JSON.parse_string(raw_text)
		if not (parsed is Array):
			push_error("StageCatalog: failed to parse stage file %s" % stage_file)
			return []

		for raw_stage in parsed:
			if not (raw_stage is Dictionary):
				push_error("StageCatalog: stage entry must be a dictionary in %s" % stage_file)
				return []
			stages.append(_normalize_stage(raw_stage))

	return stages


static func _normalize_stage(raw_stage: Dictionary) -> Dictionary:
	var targets: Dictionary = raw_stage.get("targets", {})
	var spawn_profile: Dictionary = raw_stage.get("spawn_profile", {})
	var blockers_input: Array = raw_stage.get("blockers", [])
	var blockers: Array = []

	for blocker in blockers_input:
		if blocker is Dictionary:
			blockers.append({
				"row": int(blocker.get("row", -1)),
				"col": int(blocker.get("col", -1)),
				"kind": String(blocker.get("kind", "bush")),
				"hp": int(blocker.get("hp", 1)),
			})

	return {
		"id": int(raw_stage.get("id", 0)),
		"name": String(raw_stage.get("name", "")),
		"band": String(raw_stage.get("band", "")),
		"difficulty": String(raw_stage.get("difficulty", "Easy")),
		"theme_key": String(raw_stage.get("theme_key", "meadow_1")),
		"moves": int(raw_stage.get("moves", 0)),
		"target_collect": Dictionary(targets.get("collect", {})),
		"target_score": int(targets.get("score", 0)),
		"target_blockers": int(targets.get("blockers", 0)),
		"board_mask": Array(raw_stage.get("board_mask", [])),
		"animal_pool": Array(spawn_profile.get("pool", [])),
		"spawn_weights": Dictionary(spawn_profile.get("weights", {})),
		"blockers": blockers,
		"tutorial": String(raw_stage.get("tutorial", "")),
		"mechanics": Dictionary(raw_stage.get("mechanics", {})),
		"tags": Array(raw_stage.get("tags", [])),
	}


static func _fallback_stages() -> Array:
	return [
		{
			"id": 1,
			"name": "Stage 1",
			"difficulty": "Easy",
			"moves": 12,
			"target_collect": {"rabbit": 10},
			"target_score": 0,
			"target_blockers": 0,
			"board_mask": [
				"11111111",
				"11111111",
				"11111111",
				"11111111",
				"11111111",
				"11111111",
				"11111111",
				"11111111",
			],
			"animal_pool": ["rabbit", "bear", "cat", "chick"],
			"spawn_weights": {"rabbit": 5, "bear": 2, "cat": 2, "chick": 2},
			"blockers": [],
			"tutorial": "토끼를 10개 모으세요. 가장 쉬운 난이도라 토끼가 더 자주 등장합니다.",
		},
		{
			"id": 2,
			"name": "Stage 2",
			"difficulty": "Easy",
			"moves": 13,
			"target_collect": {"chick": 10, "rabbit": 6},
			"target_score": 0,
			"target_blockers": 0,
			"board_mask": [
				"00111100",
				"01111110",
				"11111111",
				"11111111",
				"11111111",
				"11111111",
				"01111110",
				"00111100",
			],
			"animal_pool": ["rabbit", "bear", "cat", "chick", "frog"],
			"spawn_weights": {"rabbit": 4, "bear": 2, "cat": 2, "chick": 4, "frog": 1},
			"blockers": [],
			"tutorial": "두 가지 목표를 같이 확인하세요. 목표 칩을 보며 필요한 동물을 먼저 모으는 연습 구간입니다.",
		},
	]
