extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")


func _init() -> void:
	var stages: Array = StageCatalog.get_stages()
	if stages.is_empty():
		push_error("Stage validation failed: no stages loaded.")
		quit(1)
		return

	print("Stage validation passed: loaded %d stages." % stages.size())
	quit()
