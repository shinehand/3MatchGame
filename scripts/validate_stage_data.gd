extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")

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

	print("Stage validation passed: loaded %d stages." % stages.size())
	quit()
