extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const StageDataValidator = preload("res://scripts/stage_data_validator.gd")

const EXPECTED_STAGE_COUNT := 100


func _init() -> void:
	var stages: Array = StageCatalog.get_stages()
	if stages.is_empty():
		push_error("Stage validation failed: no stages loaded.")
		quit(1)
		return
	if stages.size() != EXPECTED_STAGE_COUNT:
		push_error("Stage validation failed: expected %d production stages, got %d. JSON loading may have fallen back to starter data." % [EXPECTED_STAGE_COUNT, stages.size()])
		quit(1)
		return

	for index in range(stages.size()):
		var stage_id := int(Dictionary(stages[index]).get("id", 0))
		var expected_id := index + 1
		if stage_id != expected_id:
			push_error("Stage validation failed: expected sorted stage id %d at index %d, got %d." % [expected_id, index, stage_id])
			quit(1)
			return

	if not _validate_buddy_tuning_policy(stages):
		quit(1)
		return

	print("Stage validation passed: loaded %d stages." % stages.size())
	quit()


func _validate_buddy_tuning_policy(stages: Array) -> bool:
	if not _expect_validator_accepts("Hard near-fail Buddy max_uses 2", _stage_variant(stages, 41, {"buddy_max_uses": 2})):
		return false
	if not _expect_validator_accepts("Hard blocker Buddy max_uses 2", _stage_variant(stages, 81, {"buddy_max_uses": 2})):
		return false
	if not _expect_validator_rejects("Easy Buddy max_uses 2", _stage_variant(stages, 4, {"buddy_max_uses": 2}), "must allow 1 max uses"):
		return false
	if not _expect_validator_rejects("Hard one-shot Buddy max_uses 2", _stage_variant(stages, 51, {"buddy_max_uses": 2}), "must allow 1 max uses"):
		return false
	return true


func _stage_variant(stages: Array, stage_id: int, changes: Dictionary) -> Array:
	var variant := stages.duplicate(true)
	var stage_index := stage_id - 1
	var stage: Dictionary = Dictionary(variant[stage_index])
	for key in changes.keys():
		stage[key] = changes[key]
	variant[stage_index] = stage
	return variant


func _expect_validator_accepts(case_name: String, stages: Array) -> bool:
	var errors := StageDataValidator.validate_stages(stages)
	if errors.is_empty():
		return true
	push_error("%s should pass StageDataValidator, got: %s" % [case_name, "; ".join(errors)])
	return false


func _expect_validator_rejects(case_name: String, stages: Array, expected_error_text: String) -> bool:
	var errors := StageDataValidator.validate_stages(stages)
	for error_text in errors:
		if String(error_text).contains(expected_error_text):
			return true
	push_error("%s should fail StageDataValidator with '%s', got: %s" % [case_name, expected_error_text, "; ".join(errors)])
	return false
