extends SceneTree

const GameSession = preload("res://scripts/game_session.gd")

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const STAGE_SELECT_SCENE_PATH := "res://scenes/stage_select.tscn"
const GAMEPLAY_SCENE_PATH := "res://scenes/gameplay.tscn"
const COLLECTION_SCENE_PATH := "res://scenes/collection_screen.tscn"
const VALIDATION_SAVE_PATH := "user://render_snapshot_save_game.json"
const SNAPSHOT_VIEWPORTS := [
	Vector2i(390, 844),
	Vector2i(844, 390),
]
const SCENARIOS := [
	{"id": "home", "scene": MAIN_SCENE_PATH, "setup": "home"},
	{"id": "stage_popup", "scene": STAGE_SELECT_SCENE_PATH, "setup": "stage_popup"},
	{"id": "gameplay_stage4", "scene": GAMEPLAY_SCENE_PATH, "setup": "gameplay_stage4"},
	{"id": "gameplay_stage1_success", "scene": GAMEPLAY_SCENE_PATH, "setup": "gameplay_stage1_success"},
	{"id": "gameplay_stage25_failure", "scene": GAMEPLAY_SCENE_PATH, "setup": "gameplay_stage25_failure"},
	{
		"id": "gameplay_stage31_special_combo_row_col",
		"scene": GAMEPLAY_SCENE_PATH,
		"setup": "gameplay_stage31_special_combo",
		"combo_type": "row_col",
		"label_text": "크로스!",
		"from_special": "row",
		"to_special": "col",
		"from_cell": Vector2i(3, 1),
		"to_cell": Vector2i(3, 2),
		"obstacle_cell": Vector2i(2, 2),
		"cleared_count": 15,
		"requires_echo": false,
	},
	{
		"id": "gameplay_stage31_special_combo_row_row",
		"scene": GAMEPLAY_SCENE_PATH,
		"setup": "gameplay_stage31_special_combo",
		"combo_type": "row_row",
		"label_text": "가로 러시!",
		"from_special": "row",
		"to_special": "row",
		"from_cell": Vector2i(3, 1),
		"to_cell": Vector2i(3, 2),
		"obstacle_cell": Vector2i(3, 0),
		"cleared_count": 8,
		"requires_echo": false,
	},
	{
		"id": "gameplay_stage31_special_combo_col_col",
		"scene": GAMEPLAY_SCENE_PATH,
		"setup": "gameplay_stage31_special_combo",
		"combo_type": "col_col",
		"label_text": "세로 러시!",
		"from_special": "col",
		"to_special": "col",
		"from_cell": Vector2i(3, 1),
		"to_cell": Vector2i(4, 1),
		"obstacle_cell": Vector2i(0, 1),
		"cleared_count": 8,
		"requires_echo": false,
	},
	{
		"id": "gameplay_stage31_special_combo_row_bomb",
		"scene": GAMEPLAY_SCENE_PATH,
		"setup": "gameplay_stage31_special_combo",
		"combo_type": "row_bomb",
		"label_text": "가로 폭탄!",
		"from_special": "row",
		"to_special": "bomb",
		"from_cell": Vector2i(3, 1),
		"to_cell": Vector2i(3, 2),
		"obstacle_cell": Vector2i(2, 2),
		"cleared_count": 14,
		"requires_echo": true,
	},
	{
		"id": "gameplay_stage31_special_combo_col_bomb",
		"scene": GAMEPLAY_SCENE_PATH,
		"setup": "gameplay_stage31_special_combo",
		"combo_type": "col_bomb",
		"label_text": "세로 폭탄!",
		"from_special": "col",
		"to_special": "bomb",
		"from_cell": Vector2i(3, 1),
		"to_cell": Vector2i(4, 1),
		"obstacle_cell": Vector2i(4, 2),
		"cleared_count": 14,
		"requires_echo": true,
	},
	{
		"id": "gameplay_stage31_special_combo_bomb_bomb",
		"scene": GAMEPLAY_SCENE_PATH,
		"setup": "gameplay_stage31_special_combo",
		"combo_type": "bomb_bomb",
		"label_text": "더블 폭탄!",
		"from_special": "bomb",
		"to_special": "bomb",
		"from_cell": Vector2i(3, 1),
		"to_cell": Vector2i(3, 2),
		"obstacle_cell": Vector2i(2, 1),
		"cleared_count": 12,
		"requires_echo": true,
	},
	{"id": "collection", "scene": COLLECTION_SCENE_PATH, "setup": "collection"},
]
const SPECIAL_COMBO_TRANSIENT_NODE_NAMES := [
	"SpecialComboFlash",
	"SpecialComboBeam",
	"SpecialComboRing",
	"SpecialComboEchoRing",
	"SpecialComboLabel",
]

var output_dir := ""
var saved_snapshot_paths := PackedStringArray()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var errors := PackedStringArray()
	output_dir = _snapshot_output_dir()
	_prepare_output_dir(output_dir, errors)
	GameSession.use_save_path_for_testing(VALIDATION_SAVE_PATH)

	for viewport_size: Vector2i in SNAPSHOT_VIEWPORTS:
		for scenario in SCENARIOS:
			await _capture_scenario(Dictionary(scenario), viewport_size, errors)

	if not errors.is_empty():
		for error_text in errors:
			push_error("Render snapshot validation error: %s" % error_text)
		quit(1)
		return

	_write_snapshot_manifest(output_dir, saved_snapshot_paths, errors)
	if not errors.is_empty():
		for error_text in errors:
			push_error("Render snapshot validation error: %s" % error_text)
		quit(1)
		return

	print("Render snapshot validation passed: %d PNGs in %s." % [SNAPSHOT_VIEWPORTS.size() * SCENARIOS.size(), output_dir])
	quit()


func _snapshot_output_dir() -> String:
	var configured_dir := OS.get_environment("PAM_RENDER_SNAPSHOT_DIR").strip_edges()
	if not configured_dir.is_empty():
		return configured_dir
	var tmp_dir := OS.get_environment("TMPDIR").strip_edges()
	if tmp_dir.is_empty():
		tmp_dir = "/tmp"
	return tmp_dir.path_join("puzzle-render-snapshots")


func _prepare_output_dir(target_dir: String, errors: PackedStringArray) -> void:
	var make_error := DirAccess.make_dir_recursive_absolute(target_dir)
	if make_error != OK:
		errors.append("could not create render snapshot directory %s: %s" % [target_dir, error_string(make_error)])
		return
	var dir := DirAccess.open(target_dir)
	if dir == null:
		errors.append("could not open render snapshot directory %s" % target_dir)
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".png") or file_name.ends_with(".txt"):
			dir.remove(file_name)


func _capture_scenario(scenario: Dictionary, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	_reset_validation_state()
	var setup_id := str(scenario.get("setup", ""))
	if setup_id == "collection":
		_prepare_collection_state()

	root.size = viewport_size
	var scene_path := str(scenario.get("scene", ""))
	var scene_resource := load(scene_path)
	if not (scene_resource is PackedScene):
		errors.append("%s did not load as a PackedScene." % scene_path)
		return

	var node := (scene_resource as PackedScene).instantiate()
	if node == null:
		errors.append("%s could not be instantiated." % scene_path)
		return

	root.add_child(node)
	await _settle_scene(node)
	await _apply_scenario_setup(node, scenario, errors)
	await _settle_scene(node)

	var snapshot_id := "%s_%dx%d" % [str(scenario.get("id", "snapshot")), viewport_size.x, viewport_size.y]
	await _save_and_validate_snapshot(snapshot_id, node, scenario, setup_id, viewport_size, errors)
	await _validate_post_snapshot_cleanup(snapshot_id, node, scenario, errors)

	if is_instance_valid(node):
		node.queue_free()
	await process_frame
	await process_frame


func _reset_validation_state() -> void:
	GameSession.reset_progress_for_testing_preserving_analytics()
	GameSession.clear_analytics_events()


func _prepare_collection_state() -> void:
	for stage_id in range(1, 6):
		GameSession.record_stage_result(stage_id, 12000, 3)
	GameSession.add_rescue_book_tokens("frog", 3)
	GameSession.add_rescue_book_tokens("koala", 2)
	GameSession.add_rescue_book_tokens("hamster", 2)


func _settle_scene(node: Node, frame_count: int = 5) -> void:
	for _index in range(frame_count):
		if node != null and node.has_method("_apply_responsive_layout"):
			node.call("_apply_responsive_layout")
		await process_frame


func _apply_scenario_setup(node: Node, scenario: Dictionary, errors: PackedStringArray) -> void:
	var setup_id := str(scenario.get("setup", ""))
	match setup_id:
		"stage_popup":
			if not node.has_method("_show_stage_popup"):
				errors.append("%s should expose _show_stage_popup for render snapshot smoke." % STAGE_SELECT_SCENE_PATH)
				return
			node.call("_show_stage_popup", 4)
			await create_timer(0.28).timeout
		"gameplay_stage4":
			await _start_gameplay_stage(node, 3, errors)
		"gameplay_stage1_success":
			await _prepare_stage_1_success(node, errors)
		"gameplay_stage25_failure":
			await _prepare_stage_25_failure(node, errors)
		"gameplay_stage31_special_combo":
			await _prepare_stage_31_special_combo(node, scenario, errors)
		_:
			await process_frame


func _start_gameplay_stage(node: Node, stage_index: int, errors: PackedStringArray) -> void:
	if not node.has_method("_start_stage"):
		errors.append("%s should expose _start_stage for render snapshot smoke." % GAMEPLAY_SCENE_PATH)
		return
	node.call("_start_stage", stage_index)
	await create_timer(0.18).timeout


func _prepare_stage_25_failure(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_stage_collect_targets", "_target_blockers", "_target_score", "_check_stage_state"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Stage 25 failure render snapshot." % [GAMEPLAY_SCENE_PATH, method_name])
			return
	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	var target_collect := Dictionary(node.call("_stage_collect_targets"))
	var near_miss_counts := {}
	for animal_id in target_collect.keys():
		near_miss_counts[str(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	await create_timer(0.24).timeout


func _prepare_stage_1_success(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_stage_collect_targets", "_target_blockers", "_target_score", "_check_stage_state"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Stage 1 success render snapshot." % [GAMEPLAY_SCENE_PATH, method_name])
			return
	node.call("_start_stage", 0)
	_complete_gameplay_stage_goals(node)
	node.set("remaining_moves", 2)
	var complete_events_before := _analytics_event_count("stage_complete")
	await node.call("_check_stage_state")
	if _analytics_event_count("stage_complete") <= complete_events_before:
		errors.append("%s Stage 1 success render snapshot should emit stage_complete analytics." % GAMEPLAY_SCENE_PATH)
	await create_timer(0.24).timeout


func _complete_gameplay_stage_goals(node: Node) -> void:
	var collected := {}
	var target_collect := Dictionary(node.call("_stage_collect_targets"))
	for animal_id in target_collect.keys():
		collected[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", collected)
	node.set("cleared_blockers", int(node.call("_target_blockers")))
	node.set("score", int(node.call("_target_score")))


func _prepare_stage_31_special_combo(node: Node, scenario: Dictionary, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_make_piece", "_refresh_all_tiles", "_resolve_swap"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Stage 31 special combo render snapshot." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	await _start_gameplay_stage(node, 30, errors)
	var board_data := _seed_special_combo_render_board(node, errors)
	if board_data.is_empty():
		return

	var from_cell: Vector2i = scenario.get("from_cell", Vector2i(3, 1))
	var to_cell: Vector2i = scenario.get("to_cell", Vector2i(3, 2))
	var obstacle_cell: Vector2i = scenario.get("obstacle_cell", Vector2i(2, 2))
	var from_special := String(scenario.get("from_special", "row"))
	var to_special := String(scenario.get("to_special", "col"))

	board_data[from_cell.x][from_cell.y] = node.call("_make_piece", "rabbit", from_special)
	board_data[to_cell.x][to_cell.y] = node.call("_make_piece", "bear", to_special)
	node.set("board_data", board_data)

	var obstacle_data: Array = node.get("obstacle_data")
	obstacle_data[obstacle_cell.x][obstacle_cell.y] = 1
	node.set("obstacle_data", obstacle_data)
	node.call("_refresh_all_tiles")
	await _settle_scene(node, 2)

	node.call("_resolve_swap", from_cell, to_cell)
	await create_timer(0.12).timeout


func _seed_special_combo_render_board(node: Node, errors: PackedStringArray) -> Array:
	var board_data_value = node.get("board_data")
	var obstacle_data_value = node.get("obstacle_data")
	var active_mask_value = node.get("active_mask")
	if not (board_data_value is Array) or not (obstacle_data_value is Array) or not (active_mask_value is Array):
		errors.append("%s special combo render snapshot could not inspect board arrays." % GAMEPLAY_SCENE_PATH)
		return []

	var animals := ["rabbit", "bear", "cat", "chick", "frog"]
	var board_data: Array = board_data_value
	var obstacle_data: Array = obstacle_data_value
	var active_mask: Array = active_mask_value
	if board_data.size() < 8 or obstacle_data.size() < 8 or active_mask.size() < 8:
		errors.append("%s special combo render snapshot expected 8x8 board arrays." % GAMEPLAY_SCENE_PATH)
		return []

	for row in range(8):
		if not (board_data[row] is Array) or not (obstacle_data[row] is Array) or not (active_mask[row] is Array):
			errors.append("%s special combo render snapshot expected row %d arrays." % [GAMEPLAY_SCENE_PATH, row])
			return []
		for col in range(8):
			active_mask[row][col] = true
			obstacle_data[row][col] = 0
			board_data[row][col] = node.call("_make_piece", String(animals[(row * 2 + col) % animals.size()]))

	node.set("active_mask", active_mask)
	node.set("obstacle_data", obstacle_data)
	node.set("board_data", board_data)
	return board_data


func _save_and_validate_snapshot(snapshot_id: String, node: Node, scenario: Dictionary, setup_id: String, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var texture := root.get_texture()
	if texture == null:
		errors.append("%s did not expose a viewport texture." % snapshot_id)
		return
	var image := texture.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		errors.append("%s produced an empty viewport image." % snapshot_id)
		return
	if image.get_width() != viewport_size.x or image.get_height() != viewport_size.y:
		errors.append("%s image size should be %s, got %dx%d." % [snapshot_id, viewport_size, image.get_width(), image.get_height()])

	var output_path := output_dir.path_join("%s.png" % snapshot_id)
	var save_error := image.save_png(output_path)
	if save_error != OK:
		errors.append("%s could not save PNG %s: %s" % [snapshot_id, output_path, error_string(save_error)])
		return
	saved_snapshot_paths.append(output_path)
	_validate_saved_png(output_path, snapshot_id, errors)
	_validate_image_pixels(image, Rect2i(Vector2i.ZERO, Vector2i(image.get_width(), image.get_height())), "%s full frame" % snapshot_id, 0.08, 10, errors)
	_validate_scenario_regions(image, node, scenario, setup_id, snapshot_id, errors)
	print("Render snapshot saved: %s" % output_path)


func _validate_post_snapshot_cleanup(snapshot_id: String, node: Node, scenario: Dictionary, errors: PackedStringArray) -> void:
	if str(scenario.get("setup", "")) != "gameplay_stage31_special_combo":
		return

	await create_timer(0.72).timeout
	for _index in range(4):
		await process_frame

	for transient_name in SPECIAL_COMBO_TRANSIENT_NODE_NAMES:
		if node.find_child(transient_name, true, false) != null:
			errors.append("%s should clean up transient %s after the special combo render snapshot." % [snapshot_id, transient_name])


func _write_snapshot_manifest(target_dir: String, snapshot_paths: PackedStringArray, errors: PackedStringArray) -> void:
	var manifest_path := target_dir.path_join("manifest.txt")
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		errors.append("could not write render snapshot manifest: %s" % manifest_path)
		return
	file.store_line("Render snapshot output dir: %s" % target_dir)
	file.store_line("Render snapshot count: %d" % snapshot_paths.size())
	for snapshot_path in snapshot_paths:
		file.store_line(snapshot_path)


func _validate_saved_png(output_path: String, snapshot_id: String, errors: PackedStringArray) -> void:
	if not FileAccess.file_exists(output_path):
		errors.append("%s PNG was not created: %s" % [snapshot_id, output_path])
		return
	var file := FileAccess.open(output_path, FileAccess.READ)
	if file == null:
		errors.append("%s PNG could not be opened after save: %s" % [snapshot_id, output_path])
		return
	if file.get_length() <= 0:
		errors.append("%s PNG should not be empty: %s" % [snapshot_id, output_path])


func _validate_scenario_regions(image: Image, node: Node, scenario: Dictionary, setup_id: String, snapshot_id: String, errors: PackedStringArray) -> void:
	match setup_id:
		"home":
			_validate_control_pixels(image, node.find_child("GameHomeLayer", true, false), snapshot_id, "GameHomeLayer", errors)
			_validate_control_pixels(image, node.find_child("HomePlayButton", true, false), snapshot_id, "HomePlayButton", errors)
			_validate_control_pixels(image, node.find_child("BottomNav", true, false), snapshot_id, "BottomNav", errors)
		"stage_popup":
			_validate_control_pixels(image, node.get("stage_popup_panel") as Control, snapshot_id, "StagePopupPanel", errors)
			_validate_control_pixels(image, _find_button_with_text(node, "START"), snapshot_id, "StagePopupStartButton", errors)
			_validate_control_pixels(image, node.get("stage_popup_buddy_label") as Control, snapshot_id, "StagePopupBuddyLabel", errors)
		"gameplay_stage4":
			_validate_control_pixels(image, node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control, snapshot_id, "BoardFrame", errors)
			if image.get_height() >= image.get_width():
				_validate_control_pixels(image, node.find_child("HudGoalDock", true, false) as Control, snapshot_id, "HudGoalDock", errors)
				_validate_control_pixels(image, node.find_child("HudBoosterDock", true, false) as Control, snapshot_id, "HudBoosterDock", errors)
				_validate_control_pixels(image, node.find_child("HudBuddyGauge", true, false) as Control, snapshot_id, "HudBuddyGauge", errors)
			else:
				_validate_control_pixels(image, node.find_child("StatsCard", true, false) as Control, snapshot_id, "StatsCard", errors)
				_validate_control_pixels(image, node.find_child("GoalCard", true, false) as Control, snapshot_id, "GoalCard", errors)
		"gameplay_stage1_success":
			_validate_result_overlay_snapshot_regions(image, node, snapshot_id, errors)
		"gameplay_stage25_failure":
			_validate_control_pixels(image, node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel") as Control, snapshot_id, "OverlayPanel", errors)
			_validate_control_pixels(image, node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Control, snapshot_id, "OverlayPrimaryButton", errors)
			_validate_control_pixels(image, node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Control, snapshot_id, "OverlaySecondaryButton", errors)
		"gameplay_stage31_special_combo":
			_validate_control_pixels(image, node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control, snapshot_id, "BoardFrame", errors)
			_validate_special_combo_snapshot_regions(image, node, scenario, snapshot_id, errors)
		"collection":
			_validate_control_pixels(image, node.find_child("CollectionGrid", true, false) as Control, snapshot_id, "CollectionGrid", errors)
			_validate_control_pixels(image, node.find_child("SummaryLabel", true, false) as Control, snapshot_id, "SummaryLabel", errors)


func _validate_result_overlay_snapshot_regions(image: Image, node: Node, snapshot_id: String, errors: PackedStringArray) -> void:
	var overlay := node.get_node_or_null("Overlay") as CanvasItem
	if overlay == null or not overlay.visible:
		errors.append("%s should show the success result overlay." % snapshot_id)
	if String(node.get("stage_state")) != "cleared":
		errors.append("%s should leave Stage 1 cleared, got %s." % [snapshot_id, String(node.get("stage_state"))])
	if String(node.get("overlay_action")) != "clear_stage":
		errors.append("%s should use clear_stage overlay action, got %s." % [snapshot_id, String(node.get("overlay_action"))])
	if GameSession.get_highest_unlocked_stage_id() < 2:
		errors.append("%s should unlock Stage 2 after Stage 1 success." % snapshot_id)

	var panel := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel") as Control
	var title := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayTitle") as Label
	var body := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Label
	var mascot := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayMascot") as TextureRect
	var primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Button
	var secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Button

	for control_info in [[panel, "OverlayPanel"], [title, "OverlayTitle"], [body, "OverlayBody"], [mascot, "OverlayMascot"], [primary, "OverlayPrimaryButton"], [secondary, "OverlaySecondaryButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_pixels(image, control, snapshot_id, label, errors)
		_validate_control_within_image_bounds(control, snapshot_id, label, errors)

	if title == null or not title.text.contains("구조 완료"):
		errors.append("%s success overlay title should contain 구조 완료." % snapshot_id)
	if body == null or not body.text.contains("보상") or not body.text.contains("별") or not body.text.contains("다음"):
		errors.append("%s success overlay body should show reward, stars, and next action text." % snapshot_id)
	elif not body.text.contains("Zoo-Zoo Time"):
		errors.append("%s success overlay body should include Zoo-Zoo Time bonus text." % snapshot_id)
	if mascot == null or mascot.texture == null:
		errors.append("%s success overlay should show a non-null mascot texture." % snapshot_id)
	if primary == null or primary.text != "다음 스테이지":
		errors.append("%s success overlay primary CTA should be 다음 스테이지." % snapshot_id)
	if secondary == null or not secondary.visible or secondary.text != "홈으로":
		errors.append("%s success overlay secondary CTA should be visible 홈으로." % snapshot_id)
	var stage_complete_params := _last_analytics_event_params("stage_complete")
	if stage_complete_params.is_empty():
		errors.append("%s should preserve stage_complete analytics payload." % snapshot_id)
	else:
		if int(stage_complete_params.get("stage_id", 0)) != 1:
			errors.append("%s stage_complete analytics should identify Stage 1, got %d." % [snapshot_id, int(stage_complete_params.get("stage_id", 0))])
		if int(stage_complete_params.get("moves_left", 0)) != 2:
			errors.append("%s stage_complete analytics should preserve 2 Zoo-Zoo Time moves, got %d." % [snapshot_id, int(stage_complete_params.get("moves_left", 0))])
		if int(stage_complete_params.get("zoo_zoo_time_bonus", 0)) <= 0:
			errors.append("%s stage_complete analytics should include a positive Zoo-Zoo Time bonus." % snapshot_id)


func _validate_special_combo_snapshot_regions(image: Image, node: Node, scenario: Dictionary, snapshot_id: String, errors: PackedStringArray) -> void:
	var combo_type := String(scenario.get("combo_type", ""))
	if combo_type.is_empty():
		errors.append("%s special combo snapshot is missing combo_type metadata." % snapshot_id)
	elif not snapshot_id.contains(combo_type):
		errors.append("%s snapshot filename should include combo type %s." % [snapshot_id, combo_type])

	var label := node.find_child("SpecialComboLabel", true, false) as Label
	_validate_control_pixels(image, label, snapshot_id, "SpecialComboLabel", errors)
	_validate_control_within_image_bounds(label, snapshot_id, "SpecialComboLabel", errors)
	if label != null:
		var expected_label := String(scenario.get("label_text", ""))
		if label.text != expected_label:
			errors.append("%s special combo label should be %s for %s, got %s." % [snapshot_id, expected_label, combo_type, label.text])
		_validate_canvas_item_alpha(label, snapshot_id, "SpecialComboLabel", 0.20, errors)

	var flash := node.find_child("SpecialComboFlash", true, false) as Control
	var ring := node.find_child("SpecialComboRing", true, false) as Control
	_validate_control_pixels(image, flash, snapshot_id, "SpecialComboFlash", errors)
	_validate_control_pixels(image, ring, snapshot_id, "SpecialComboRing", errors)
	_validate_canvas_item_alpha(flash, snapshot_id, "SpecialComboFlash", 0.08, errors)
	_validate_canvas_item_alpha(ring, snapshot_id, "SpecialComboRing", 0.08, errors)

	if flash is ColorRect and (flash as ColorRect).color.a < 0.08:
		errors.append("%s SpecialComboFlash color alpha should remain visible during snapshot, got %.3f." % [snapshot_id, (flash as ColorRect).color.a])
	if bool(scenario.get("requires_echo", false)):
		var echo_ring := node.find_child("SpecialComboEchoRing", true, false) as Control
		_validate_control_pixels(image, echo_ring, snapshot_id, "SpecialComboEchoRing", errors)
		_validate_canvas_item_alpha(echo_ring, snapshot_id, "SpecialComboEchoRing", 0.06, errors)

	var board_root := node.get_node_or_null("FxLayer/BoardFxRoot")
	if board_root == null:
		errors.append("%s is missing FxLayer/BoardFxRoot for special combo render snapshot." % snapshot_id)
	else:
		var board_fx_children := board_root.get_child_count()
		if board_fx_children < 3:
			errors.append("%s should have transient special combo VFX children, got %d." % [snapshot_id, board_fx_children])
		if board_fx_children > 40:
			errors.append("%s should keep no-device special combo VFX children <= 40, got %d." % [snapshot_id, board_fx_children])

	var params := _analytics_event_params_by_name_and_key("special_combo_trigger", "combo_type", combo_type)
	if params.is_empty():
		errors.append("%s should emit special_combo_trigger analytics for combo_type %s." % [snapshot_id, combo_type])
		return
	if int(params.get("stage_id", 0)) != 31:
		errors.append("%s special_combo_trigger should identify Stage 31, got %d." % [snapshot_id, int(params.get("stage_id", 0))])
	if String(params.get("from_special", "")) != String(scenario.get("from_special", "")) or String(params.get("to_special", "")) != String(scenario.get("to_special", "")):
		errors.append("%s special_combo_trigger should preserve from/to specials for %s." % [snapshot_id, combo_type])
	if int(params.get("cleared_count", 0)) != int(scenario.get("cleared_count", 0)):
		errors.append("%s special_combo_trigger should record %d cleared cells for %s, got %d." % [snapshot_id, int(scenario.get("cleared_count", 0)), combo_type, int(params.get("cleared_count", 0))])
	if int(params.get("obstacles_cleared", 0)) != 1:
		errors.append("%s special_combo_trigger should record one obstacle cleared for %s, got %d." % [snapshot_id, combo_type, int(params.get("obstacles_cleared", 0))])


func _validate_control_pixels(image: Image, control: Control, snapshot_id: String, label: String, errors: PackedStringArray) -> void:
	if control == null:
		errors.append("%s missing control region %s." % [snapshot_id, label])
		return
	if not control.is_visible_in_tree():
		errors.append("%s control region %s should be visible." % [snapshot_id, label])
		return
	var rect := _control_rect_to_image_bounds(control.get_global_rect(), image.get_width(), image.get_height())
	if rect.size.x <= 0 or rect.size.y <= 0:
		errors.append("%s control region %s has no visible pixels in image bounds." % [snapshot_id, label])
		return
	_validate_image_pixels(image, rect, "%s %s" % [snapshot_id, label], 0.04, 3, errors)


func _validate_control_within_image_bounds(control: Control, snapshot_id: String, label: String, errors: PackedStringArray) -> void:
	if control == null:
		return
	var rect := control.get_global_rect()
	var viewport_size := root.get_visible_rect().size
	if rect.position.x < -1.0 or rect.position.y < -1.0 or rect.position.x + rect.size.x > viewport_size.x + 1.0 or rect.position.y + rect.size.y > viewport_size.y + 1.0:
		errors.append("%s control region %s should fit inside viewport bounds, got %s in %s." % [snapshot_id, label, rect, viewport_size])


func _validate_canvas_item_alpha(node: CanvasItem, snapshot_id: String, label: String, min_alpha: float, errors: PackedStringArray) -> void:
	if node == null:
		return
	if node.modulate.a < min_alpha:
		errors.append("%s %s alpha %.3f should be >= %.3f during render snapshot." % [snapshot_id, label, node.modulate.a, min_alpha])


func _control_rect_to_image_bounds(rect: Rect2, image_width: int, image_height: int) -> Rect2i:
	var viewport_size := root.get_visible_rect().size
	var scale := Vector2(
		float(image_width) / maxf(1.0, viewport_size.x),
		float(image_height) / maxf(1.0, viewport_size.y)
	)
	var scaled_rect := Rect2(rect.position * scale, rect.size * scale)
	var left := clampi(int(floor(scaled_rect.position.x)), 0, image_width)
	var top := clampi(int(floor(scaled_rect.position.y)), 0, image_height)
	var right := clampi(int(ceil(scaled_rect.position.x + scaled_rect.size.x)), 0, image_width)
	var bottom := clampi(int(ceil(scaled_rect.position.y + scaled_rect.size.y)), 0, image_height)
	return Rect2i(Vector2i(left, top), Vector2i(maxi(0, right - left), maxi(0, bottom - top)))


func _validate_image_pixels(image: Image, rect: Rect2i, label: String, min_non_dark_ratio: float, min_unique_buckets: int, errors: PackedStringArray) -> void:
	var stats := _image_region_stats(image, rect)
	var samples := int(stats.get("samples", 0))
	if samples <= 0:
		errors.append("%s has no sampled pixels." % label)
		return
	var visible_ratio := float(stats.get("visible", 0)) / float(samples)
	var non_dark_ratio := float(stats.get("non_dark", 0)) / float(samples)
	var unique_buckets := int(stats.get("unique_buckets", 0))
	if visible_ratio < 0.60:
		errors.append("%s should be mostly visible pixels, got %.3f." % [label, visible_ratio])
	if non_dark_ratio < min_non_dark_ratio:
		errors.append("%s should not be blank/dark, non-dark ratio %.3f < %.3f." % [label, non_dark_ratio, min_non_dark_ratio])
	if unique_buckets < min_unique_buckets:
		errors.append("%s should contain varied rendered pixels, got %d color buckets." % [label, unique_buckets])


func _image_region_stats(image: Image, rect: Rect2i) -> Dictionary:
	var buckets := {}
	var samples := 0
	var visible := 0
	var non_dark := 0
	var step_x := maxi(1, int(ceil(float(rect.size.x) / 96.0)))
	var step_y := maxi(1, int(ceil(float(rect.size.y) / 96.0)))
	for y in range(rect.position.y, rect.position.y + rect.size.y, step_y):
		for x in range(rect.position.x, rect.position.x + rect.size.x, step_x):
			var color := image.get_pixel(x, y)
			samples += 1
			if color.a > 0.03:
				visible += 1
			var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			if color.a > 0.03 and luminance > 0.05:
				non_dark += 1
			var bucket := "%02d-%02d-%02d-%02d" % [
				int(clampf(color.r, 0.0, 1.0) * 15.0),
				int(clampf(color.g, 0.0, 1.0) * 15.0),
				int(clampf(color.b, 0.0, 1.0) * 15.0),
				int(clampf(color.a, 0.0, 1.0) * 15.0),
			]
			buckets[bucket] = true
	return {
		"samples": samples,
		"visible": visible,
		"non_dark": non_dark,
		"unique_buckets": buckets.size(),
	}


func _find_button_with_text(parent: Node, text: String) -> Button:
	if parent == null:
		return null
	for candidate in parent.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.text == text:
			return button
	return null


func _analytics_event_params_by_name_and_key(event_name: String, key: String, value: String) -> Dictionary:
	var events := GameSession.get_analytics_events()
	for index in range(events.size() - 1, -1, -1):
		var event = events[index]
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		if String(event_dict.get("name", "")) != event_name:
			continue
		var params: Dictionary = Dictionary(event_dict.get("params", {}))
		if String(params.get(key, "")) == value:
			return params
	return {}


func _analytics_event_count(event_name: String) -> int:
	var count := 0
	for event in GameSession.get_analytics_events():
		if event is Dictionary and String(Dictionary(event).get("name", "")) == event_name:
			count += 1
	return count


func _last_analytics_event_params(event_name: String) -> Dictionary:
	var events := GameSession.get_analytics_events()
	for index in range(events.size() - 1, -1, -1):
		var event = events[index]
		if event is Dictionary and String(Dictionary(event).get("name", "")) == event_name:
			return Dictionary(Dictionary(event).get("params", {}))
	return {}
