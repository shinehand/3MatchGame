extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")

const LOADING_SCENE_PATH: String = "res://scenes/loading.tscn"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const STAGE_SELECT_SCENE_PATH: String = "res://scenes/stage_select.tscn"
const GAMEPLAY_SCENE_PATH: String = "res://scenes/gameplay.tscn"
const STAGE_CARD_SCENE_PATH: String = "res://scenes/stage_card.tscn"
const BLOCK_TILE_SCENE_PATH: String = "res://scenes/block_tile.tscn"
const GOAL_CHIP_SCENE_PATH: String = "res://scenes/goal_chip.tscn"

var representative_stage_ids: Array[int] = [1, 11, 25, 50, 75, 100]
var tutorial_stage_ids: Array[int] = [1, 11, 25, 45, 65, 85, 95]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors: PackedStringArray = PackedStringArray()
	_validate_alpha_gate_data(errors)
	var scene_paths: PackedStringArray = PackedStringArray([
		LOADING_SCENE_PATH,
		MAIN_SCENE_PATH,
		STAGE_SELECT_SCENE_PATH,
		GAMEPLAY_SCENE_PATH,
		STAGE_CARD_SCENE_PATH,
		BLOCK_TILE_SCENE_PATH,
		GOAL_CHIP_SCENE_PATH,
	])

	for scene_path: String in scene_paths:
		var scene_resource: Resource = load(scene_path)
		if not (scene_resource is PackedScene):
			errors.append("%s did not load as a PackedScene." % scene_path)
			continue

		var packed_scene: PackedScene = scene_resource as PackedScene
		var node: Node = packed_scene.instantiate()
		if node == null:
			errors.append("%s could not be instantiated." % scene_path)
			continue

		root.add_child(node)
		await process_frame
		for scene_error in _validate_scene_specifics(scene_path, node):
			errors.append(scene_error)
		await create_timer(0.2).timeout
		if is_instance_valid(node):
			node.queue_free()
		await process_frame
		await process_frame

	if not errors.is_empty():
		for error_text in errors:
			push_error("Scene load validation error: %s" % error_text)
		quit(1)
		return

	print("Scene load validation passed: %d scenes parsed and instantiated." % scene_paths.size())
	quit()


func _validate_scene_specifics(scene_path: String, node: Node) -> PackedStringArray:
	var errors := PackedStringArray()

	match scene_path:
		LOADING_SCENE_PATH:
			_validate_loading_scene(node, errors)
		MAIN_SCENE_PATH:
			_validate_main_scene(node, errors)
		GAMEPLAY_SCENE_PATH:
			_validate_gameplay_scene(node, errors)
		STAGE_SELECT_SCENE_PATH:
			_validate_stage_select_scene(node, errors)

	return errors


func _validate_loading_scene(node: Node, errors: PackedStringArray) -> void:
	var logo := node.get_node_or_null("SafeMargin/MainStack/Logo") as Label
	if logo == null:
		errors.append("%s is missing the animated game logo." % LOADING_SCENE_PATH)
	elif not logo.text.contains("Zoo-Zoo"):
		errors.append("%s logo should present the game brand immediately." % LOADING_SCENE_PATH)

	var progress_bar := node.get_node_or_null("SafeMargin/MainStack/ProgressFrame/ProgressMargin/ProgressBar") as ProgressBar
	if progress_bar == null:
		errors.append("%s is missing the visible loading progress bar." % LOADING_SCENE_PATH)

	var token_row := node.get_node_or_null("SafeMargin/MainStack/TokenRow") as HBoxContainer
	if token_row == null:
		errors.append("%s is missing the animated animal candy row." % LOADING_SCENE_PATH)
	elif token_row.get_child_count() < 5:
		errors.append("%s should show at least five candy tokens while loading." % LOADING_SCENE_PATH)


func _validate_main_scene(node: Node, errors: PackedStringArray) -> void:
	var play_button := node.get_node_or_null("SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/PlayButton") as Button
	if play_button == null:
		errors.append("%s is missing PlayButton." % MAIN_SCENE_PATH)
	elif play_button.text != "PLAY":
		errors.append("%s PlayButton should use the game-first PLAY label." % MAIN_SCENE_PATH)

	var game_home_layer := node.get_node_or_null("GameHomeLayer") as CanvasItem
	if game_home_layer == null:
		errors.append("%s is missing the game-first GameHomeLayer." % MAIN_SCENE_PATH)
	elif not game_home_layer.visible:
		errors.append("%s GameHomeLayer should be visible on first launch." % MAIN_SCENE_PATH)

	var legacy_layout := node.get_node_or_null("SafeMargin/LayoutRoot") as CanvasItem
	if legacy_layout == null:
		errors.append("%s is missing legacy layout root." % MAIN_SCENE_PATH)
	elif legacy_layout.visible:
		errors.append("%s should hide the legacy card layout behind GameHomeLayer." % MAIN_SCENE_PATH)

	var info_card := node.get_node_or_null("SafeMargin/LayoutRoot/CenterColumn/InfoCard") as CanvasItem
	if info_card == null:
		errors.append("%s is missing InfoCard." % MAIN_SCENE_PATH)
	elif info_card.visible:
		errors.append("%s should not show a developer-style info card by default." % MAIN_SCENE_PATH)


func _validate_gameplay_scene(node: Node, errors: PackedStringArray) -> void:
	var board_grid := node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/BoardSurfaceMargin/BoardScroll/BoardGrid")
	if board_grid == null:
		errors.append("%s is missing BoardGrid." % GAMEPLAY_SCENE_PATH)
	elif board_grid.get_child_count() != 64:
		errors.append("%s BoardGrid expected 64 tile nodes, got %d." % [GAMEPLAY_SCENE_PATH, board_grid.get_child_count()])

	var goal_list := node.find_child("GoalList", true, false)
	if goal_list == null:
		errors.append("%s is missing GoalList." % GAMEPLAY_SCENE_PATH)
	elif goal_list.get_child_count() <= 0:
		errors.append("%s GoalList did not build any goal chips." % GAMEPLAY_SCENE_PATH)

	var overlay := node.get_node_or_null("Overlay") as CanvasItem
	if overlay == null:
		errors.append("%s is missing result overlay." % GAMEPLAY_SCENE_PATH)
	elif overlay.visible:
		errors.append("%s should start with the board immediately playable, not blocked by an overlay." % GAMEPLAY_SCENE_PATH)


func _validate_stage_select_scene(node: Node, errors: PackedStringArray) -> void:
	var stage_grid := node.get_node_or_null("SafeMargin/LayoutRoot/ContentRoot/StagePanel/StageFrame/StageMargin/StageColumn/StageScroll/StageGrid")
	if stage_grid == null:
		errors.append("%s is missing StageGrid." % STAGE_SELECT_SCENE_PATH)
	elif stage_grid.get_child_count() != 100:
		errors.append("%s StageGrid expected 100 stage cards, got %d." % [STAGE_SELECT_SCENE_PATH, stage_grid.get_child_count()])

	var stage_popup := node.get_node_or_null("StagePopupOverlay") as CanvasItem
	if stage_popup == null:
		errors.append("%s is missing StagePopupOverlay." % STAGE_SELECT_SCENE_PATH)
	elif stage_popup.visible:
		errors.append("%s StagePopupOverlay should start hidden until a stage node is pressed." % STAGE_SELECT_SCENE_PATH)


func _validate_alpha_gate_data(errors: PackedStringArray) -> void:
	var stages: Array = StageCatalog.get_stages()
	if stages.size() < 100:
		errors.append("Alpha gate expected 100 stages, got %d." % stages.size())
		return

	var stage_by_id: Dictionary = {}
	for stage_entry in stages:
		if stage_entry is Dictionary:
			var stage_dict: Dictionary = stage_entry
			stage_by_id[int(stage_dict.get("id", 0))] = stage_dict

	for stage_id in representative_stage_ids:
		if not stage_by_id.has(stage_id):
			errors.append("Alpha gate missing representative stage %d." % stage_id)

	for stage_id in tutorial_stage_ids:
		if not stage_by_id.has(stage_id):
			errors.append("Alpha gate missing tutorial checkpoint stage %d." % stage_id)
			continue
		var tutorial_text := String(Dictionary(stage_by_id[stage_id]).get("tutorial", "")).strip_edges()
		if tutorial_text.is_empty():
			errors.append("Alpha gate tutorial checkpoint stage %d is missing tutorial text." % stage_id)
