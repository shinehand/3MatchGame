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
	{"id": "home_settings_overlay", "scene": MAIN_SCENE_PATH, "setup": "home_settings_overlay"},
	{"id": "home_settings_overlay_off", "scene": MAIN_SCENE_PATH, "setup": "home_settings_overlay_off"},
	{"id": "home_live_event_ended_detail", "scene": MAIN_SCENE_PATH, "setup": "home_event_detail_ended"},
	{"id": "stage_select_world_map", "scene": STAGE_SELECT_SCENE_PATH, "setup": "stage_select_world_map"},
	{"id": "stage_select_world_progress", "scene": STAGE_SELECT_SCENE_PATH, "setup": "stage_select_world_progress"},
	{"id": "stage_popup", "scene": STAGE_SELECT_SCENE_PATH, "setup": "stage_popup"},
	{"id": "gameplay_stage4_buddy_initial", "scene": GAMEPLAY_SCENE_PATH, "setup": "gameplay_stage4", "buddy_state": "initial", "buddy_charges": 0},
	{"id": "gameplay_stage4_buddy_charged", "scene": GAMEPLAY_SCENE_PATH, "setup": "gameplay_stage4", "buddy_state": "charged", "buddy_charges": 2},
	{"id": "gameplay_stage4_buddy_ready", "scene": GAMEPLAY_SCENE_PATH, "setup": "gameplay_stage4", "buddy_state": "ready", "buddy_charges": 3},
	{"id": "gameplay_stage4_buddy_complete", "scene": GAMEPLAY_SCENE_PATH, "setup": "gameplay_stage4", "buddy_state": "complete", "buddy_charges": 3, "trigger_buddy": true},
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
	elif setup_id == "stage_select_world_progress":
		_prepare_stage_select_progress_state()

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
	GameSession.add_rescue_book_tokens("rabbit", 40, "render_snapshot", 4)
	GameSession.equip_rescue_book_cosmetic("rabbit", "rabbit_sprout_frame", "render_snapshot")
	GameSession.add_rescue_book_tokens("frog", 3)
	GameSession.add_rescue_book_tokens("koala", 2)
	GameSession.add_rescue_book_tokens("hamster", 2)


func _prepare_stage_select_progress_state() -> void:
	GameSession.record_stage_result(1, 14000, 3)
	GameSession.record_stage_result(2, 12000, 2)
	GameSession.record_stage_result(3, 9000, 1)
	GameSession.set_selected_stage_id(4)


func _settle_scene(node: Node, frame_count: int = 5) -> void:
	for _index in range(frame_count):
		if node != null and node.has_method("_apply_responsive_layout"):
			node.call("_apply_responsive_layout")
		await process_frame


func _apply_scenario_setup(node: Node, scenario: Dictionary, errors: PackedStringArray) -> void:
	var setup_id := str(scenario.get("setup", ""))
	match setup_id:
		"home_settings_overlay":
			await _prepare_home_settings_overlay(node, errors, true)
		"home_settings_overlay_off":
			await _prepare_home_settings_overlay(node, errors, false)
		"home_event_detail_ended":
			await _prepare_home_ended_event_detail(node, errors)
		"stage_popup":
			if not node.has_method("_show_stage_popup"):
				errors.append("%s should expose _show_stage_popup for render snapshot smoke." % STAGE_SELECT_SCENE_PATH)
				return
			node.call("_show_stage_popup", 4)
			await create_timer(0.28).timeout
		"gameplay_stage4":
			await _prepare_stage_4_buddy_state(node, scenario, errors)
		"gameplay_stage1_success":
			await _prepare_stage_1_success(node, errors)
		"gameplay_stage25_failure":
			await _prepare_stage_25_failure(node, errors)
		"gameplay_stage31_special_combo":
			await _prepare_stage_31_special_combo(node, scenario, errors)
		_:
			await process_frame


func _prepare_home_settings_overlay(node: Node, errors: PackedStringArray, enabled: bool) -> void:
	if not node.has_method("_on_settings_button_pressed"):
		errors.append("%s should expose _on_settings_button_pressed for home settings render snapshot." % MAIN_SCENE_PATH)
		return
	GameSession.set_sound_enabled(enabled)
	GameSession.set_haptics_enabled(enabled)
	node.call("_on_settings_button_pressed")
	await process_frame


func _prepare_home_ended_event_detail(node: Node, errors: PackedStringArray) -> void:
	if not node.has_method("_show_event_detail"):
		errors.append("%s should expose _show_event_detail for home live event detail render snapshot." % MAIN_SCENE_PATH)
		return
	await _validate_home_event_detail_state_contracts(node, errors)
	node.call("_show_event_detail", _home_event_detail_snapshot_fixture("ended"))
	await process_frame


func _home_event_detail_snapshot_fixture(status: String) -> Dictionary:
	var title_by_status := {
		"active": "진행 중 보급 이벤트",
		"offline": "오프라인 보급 이벤트",
		"upcoming": "예정된 보급 이벤트",
		"ended": "종료된 보급 이벤트",
	}
	var event := {
		"id": "__snapshot_%s_home_event" % status,
		"type": "daily_reward",
		"title": String(title_by_status.get(status, "보급 이벤트")),
		"enabled": true,
		"status": status,
		"unlock_stage": 1,
		"placements": ["home"],
		"start_at": "2026-05-01",
		"end_at": "2026-05-31" if status != "ended" else "2026-05-07",
		"reward": {"gold": 120, "booster": "rainbow_paw", "booster_count": 1},
	}
	return event


func _validate_home_event_detail_state_contracts(node: Node, errors: PackedStringArray) -> void:
	var state_cases := [
		{"status": "active", "status_label": "진행 중", "button_text": "보상 받기", "button_disabled": false},
		{"status": "offline", "status_label": "오프라인", "button_text": "보상 받기", "button_disabled": false},
		{"status": "upcoming", "status_label": "시작 전", "button_text": "시작 전", "button_disabled": true},
		{"status": "ended", "status_label": "종료됨", "button_text": "종료됨", "button_disabled": true},
	]
	for state_case in state_cases:
		var status := String(state_case.get("status", ""))
		node.call("_show_event_detail", _home_event_detail_snapshot_fixture(status))
		await process_frame
		var overlay := node.find_child("EventDetailOverlay", true, false) as Control
		var status_label: Label = null
		var claim_button: Button = null
		if overlay != null:
			status_label = overlay.find_child("EventDetailStatusLabel", true, false) as Label
			claim_button = overlay.find_child("EventClaimButton", true, false) as Button
		if status_label == null or status_label.text != String(state_case.get("status_label", "")):
			errors.append("Home event detail %s badge expected %s, got %s." % [status, String(state_case.get("status_label", "")), "" if status_label == null else status_label.text])
		if claim_button == null:
			errors.append("Home event detail %s should expose EventClaimButton." % status)
			continue
		if claim_button.text != String(state_case.get("button_text", "")):
			errors.append("Home event detail %s button expected %s, got %s." % [status, String(state_case.get("button_text", "")), claim_button.text])
		if claim_button.disabled != bool(state_case.get("button_disabled", true)):
			errors.append("Home event detail %s button disabled expected %s, got %s." % [status, bool(state_case.get("button_disabled", true)), claim_button.disabled])


func _start_gameplay_stage(node: Node, stage_index: int, errors: PackedStringArray) -> void:
	if not node.has_method("_start_stage"):
		errors.append("%s should expose _start_stage for render snapshot smoke." % GAMEPLAY_SCENE_PATH)
		return
	node.call("_start_stage", stage_index)
	await create_timer(0.18).timeout


func _prepare_stage_4_buddy_state(node: Node, scenario: Dictionary, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_charge_buddy_skill_for_match", "_trigger_buddy_skill", "_update_hud"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Stage 4 Buddy HUD render snapshot." % [GAMEPLAY_SCENE_PATH, method_name])
			return
	await _start_gameplay_stage(node, 3, errors)

	var charge_count := int(scenario.get("buddy_charges", 0))
	for _index in range(charge_count):
		node.call("_charge_buddy_skill_for_match", "rabbit")

	if bool(scenario.get("trigger_buddy", false)):
		_ensure_stage_4_quick_refill_candidate(node, errors)
		node.call("_trigger_buddy_skill")

	node.call("_update_hud")
	await _settle_scene(node, 3)


func _ensure_stage_4_quick_refill_candidate(node: Node, errors: PackedStringArray) -> void:
	if not node.has_method("_make_piece") or not node.has_method("_refresh_tile"):
		errors.append("%s should expose board helpers for Stage 4 Buddy complete render snapshot." % GAMEPLAY_SCENE_PATH)
		return
	var board_data_value = node.get("board_data")
	var active_mask_value = node.get("active_mask")
	if not (board_data_value is Array) or not (active_mask_value is Array):
		errors.append("%s Stage 4 Buddy render snapshot could not inspect board arrays." % GAMEPLAY_SCENE_PATH)
		return

	var board_data: Array = board_data_value
	var active_mask: Array = active_mask_value
	var replacement_cell := Vector2i(-1, -1)
	for row in range(board_data.size()):
		if not (board_data[row] is Array) or not (active_mask[row] is Array):
			continue
		for col in range((board_data[row] as Array).size()):
			if col >= (active_mask[row] as Array).size() or not bool(active_mask[row][col]):
				continue
			var piece := String(board_data[row][col])
			if piece.is_empty() or piece.contains("|"):
				continue
			if piece != "rabbit":
				return
			if replacement_cell.x < 0:
				replacement_cell = Vector2i(row, col)
	if replacement_cell.x < 0:
		errors.append("%s Stage 4 Buddy render snapshot could not find an active cell for quick_refill." % GAMEPLAY_SCENE_PATH)
		return
	board_data[replacement_cell.x][replacement_cell.y] = node.call("_make_piece", "bear")
	node.set("board_data", board_data)
	node.call("_refresh_tile", replacement_cell.x, replacement_cell.y)


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
	for method_name in ["_start_stage", "_make_piece", "_refresh_all_tiles", "_resolve_special_combo_swap"]:
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

	node.call("_resolve_special_combo_swap", from_cell, to_cell, from_special, to_special)
	await create_timer(0.03).timeout


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
	file.store_line("Collection cosmetic fixture: animal_id=rabbit tokens=40 equipped_cosmetic=rabbit_sprout_frame")
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
			var home_play_button := node.find_child("HomePlayButton", true, false) as Control
			_validate_control_pixels(image, node.find_child("GameHomeLayer", true, false), snapshot_id, "GameHomeLayer", errors)
			_validate_control_pixels(image, node.find_child("HomeActionPanel", true, false), snapshot_id, "HomeActionPanel", errors)
			_validate_control_pixels(image, home_play_button, snapshot_id, "HomePlayButton", errors)
			_validate_control_image_minimum_size(image, home_play_button, snapshot_id, "HomePlayButton", Vector2(210, 48) if image.get_height() >= image.get_width() else Vector2(220, 48), errors)
			_validate_control_pixels(image, node.find_child("BottomNav", true, false), snapshot_id, "BottomNav", errors)
		"home_settings_overlay":
			_validate_home_settings_overlay_snapshot_regions(image, node, snapshot_id, errors, true)
		"home_settings_overlay_off":
			_validate_home_settings_overlay_snapshot_regions(image, node, snapshot_id, errors, false)
		"home_event_detail_ended":
			_validate_home_event_detail_snapshot_regions(image, node, snapshot_id, errors)
		"stage_select_world_map":
			_validate_stage_select_world_map_snapshot_regions(image, node, snapshot_id, errors)
		"stage_select_world_progress":
			_validate_stage_select_world_map_snapshot_regions(image, node, snapshot_id, errors)
			_validate_stage_select_world_progress_snapshot_regions(image, node, snapshot_id, errors)
		"stage_popup":
			var popup_panel := node.get("stage_popup_panel") as Control
			_validate_control_pixels(image, popup_panel, snapshot_id, "StagePopupPanel", errors)
			_validate_control_within_image_bounds(popup_panel, snapshot_id, "StagePopupPanel", errors)
			_validate_control_pixels(image, _find_button_with_text(popup_panel, "PLAY"), snapshot_id, "StagePopupStartButton", errors)
			_validate_control_pixels(image, node.get("stage_popup_buddy_label") as Control, snapshot_id, "StagePopupBuddyLabel", errors)
		"gameplay_stage4":
			_validate_stage_4_buddy_snapshot_regions(image, node, scenario, snapshot_id, errors)
		"gameplay_stage1_success":
			_validate_result_overlay_snapshot_regions(image, node, snapshot_id, errors)
		"gameplay_stage25_failure":
			_validate_failure_overlay_snapshot_regions(image, node, snapshot_id, errors)
		"gameplay_stage31_special_combo":
			_validate_control_pixels(image, node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control, snapshot_id, "BoardFrame", errors)
			_validate_special_combo_snapshot_regions(image, node, scenario, snapshot_id, errors)
		"collection":
			_validate_control_pixels(image, node.find_child("CollectionGrid", true, false) as Control, snapshot_id, "CollectionGrid", errors)
			_validate_control_pixels(image, node.find_child("SummaryLabel", true, false) as Control, snapshot_id, "SummaryLabel", errors)
			_validate_collection_snapshot_regions(image, node, snapshot_id, errors)


func _validate_home_event_detail_snapshot_regions(image: Image, node: Node, snapshot_id: String, errors: PackedStringArray) -> void:
	var overlay := node.find_child("EventDetailOverlay", true, false) as Control
	var panel: Control = null
	var status_badge: Control = null
	var status_label: Label = null
	var meta_label: Label = null
	var progress_card: Control = null
	var progress_label: Label = null
	var reward_row: Control = null
	var body_label: Label = null
	var claim_button: Button = null
	if overlay != null:
		panel = overlay.find_child("OverlayPanel", true, false) as Control
		status_badge = overlay.find_child("EventDetailStatusBadge", true, false) as Control
		status_label = overlay.find_child("EventDetailStatusLabel", true, false) as Label
		meta_label = overlay.find_child("EventDetailMetaLabel", true, false) as Label
		progress_card = overlay.find_child("EventDetailProgressCard", true, false) as Control
		progress_label = overlay.find_child("EventDetailProgressLabel", true, false) as Label
		reward_row = overlay.find_child("EventRewardChipRow", true, false) as Control
		body_label = overlay.find_child("EventDetailBodyLabel", true, false) as Label
		claim_button = overlay.find_child("EventClaimButton", true, false) as Button
	for control_info in [[overlay, "EventDetailOverlay"], [panel, "EventDetailPanel"], [status_badge, "EventDetailStatusBadge"], [status_label, "EventDetailStatusLabel"], [meta_label, "EventDetailMetaLabel"], [progress_card, "EventDetailProgressCard"], [progress_label, "EventDetailProgressLabel"], [reward_row, "EventRewardChipRow"], [body_label, "EventDetailBodyLabel"], [claim_button, "EventClaimButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_pixels(image, control, snapshot_id, label, errors)
		_validate_control_within_image_bounds(control, snapshot_id, label, errors)
	var portrait := image.get_height() >= image.get_width()
	_validate_control_image_minimum_size(image, panel, snapshot_id, "EventDetailPanel", Vector2(image.get_width() * (0.62 if portrait else 0.40), image.get_height() * (0.32 if portrait else 0.54)), errors)
	_validate_control_image_minimum_size(image, progress_card, snapshot_id, "EventDetailProgressCard", Vector2(image.get_width() * (0.54 if portrait else 0.35), image.get_height() * (0.045 if portrait else 0.085)), errors)
	_validate_control_image_minimum_size(image, claim_button, snapshot_id, "EventClaimButton", Vector2(image.get_width() * (0.54 if portrait else 0.34), image.get_height() * (0.040 if portrait else 0.070)), errors)
	if reward_row != null:
		for child in reward_row.get_children():
			_validate_control_image_minimum_size(image, child as Control, snapshot_id, "EventRewardChip", Vector2(image.get_width() * (0.13 if portrait else 0.070), image.get_height() * (0.026 if portrait else 0.048)), errors)
	if overlay == null or not overlay.visible:
		errors.append("%s should render EventDetailOverlay visible." % snapshot_id)
	if status_label == null or status_label.text != "종료됨":
		errors.append("%s ended event detail status badge should read 종료됨, got %s." % [snapshot_id, "" if status_label == null else status_label.text])
	if meta_label == null or not meta_label.text.contains("오늘 보급") or not meta_label.text.contains("2026-05-01") or not meta_label.text.contains("2026-05-07"):
		errors.append("%s ended event detail meta should include event type and window, got %s." % [snapshot_id, "" if meta_label == null else meta_label.text])
	if progress_label == null or not progress_label.text.contains("이벤트 종료"):
		errors.append("%s ended event detail progress should show 이벤트 종료, got %s." % [snapshot_id, "" if progress_label == null else progress_label.text])
	var reward_texts := _label_texts_under(reward_row)
	for expected_reward in ["골드 120", "rainbow_paw x1"]:
		if not reward_texts.has(expected_reward):
			errors.append("%s ended event detail reward chips should include %s, got %s." % [snapshot_id, expected_reward, ", ".join(reward_texts)])
	if body_label == null or not body_label.text.contains("종료됨"):
		errors.append("%s ended event detail body should include 종료됨, got %s." % [snapshot_id, "" if body_label == null else body_label.text])
	if claim_button == null:
		return
	if not claim_button.disabled:
		errors.append("%s ended event detail claim button should be disabled." % snapshot_id)
	if claim_button.text != "종료됨":
		errors.append("%s ended event detail claim button should read 종료됨, got %s." % [snapshot_id, claim_button.text])


func _validate_home_settings_overlay_snapshot_regions(image: Image, node: Node, snapshot_id: String, errors: PackedStringArray, expected_enabled: bool) -> void:
	var overlay := node.get_node_or_null("SettingsOverlay") as Control
	var panel := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel") as Control
	var title_label := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsTitle") as Label
	var summary_label := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsSummaryLabel") as Label
	var sound_button := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsButtons/SoundToggleButton") as Button
	var haptics_button := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsButtons/HapticsToggleButton") as Button
	var close_button := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsCloseButton") as Button
	for control_info in [[overlay, "SettingsOverlay"], [panel, "SettingsPanel"], [title_label, "SettingsTitle"], [summary_label, "SettingsSummaryLabel"], [sound_button, "SoundToggleButton"], [haptics_button, "HapticsToggleButton"], [close_button, "SettingsCloseButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_pixels(image, control, snapshot_id, label, errors)
		_validate_control_within_image_bounds(control, snapshot_id, label, errors)
	for button_info in [[sound_button, "SoundToggleButton"], [haptics_button, "HapticsToggleButton"], [close_button, "SettingsCloseButton"]]:
		_validate_control_image_minimum_size(image, button_info[0] as Control, snapshot_id, String(button_info[1]), Vector2(88, 44), errors)
	if overlay == null or not overlay.visible:
		errors.append("%s should render SettingsOverlay visible." % snapshot_id)
	if title_label == null or title_label.text != "설정":
		errors.append("%s settings title should read 설정, got %s." % [snapshot_id, "" if title_label == null else title_label.text])
	if summary_label == null or not summary_label.text.contains("자동 저장") or not summary_label.text.contains("사운드") or not summary_label.text.contains("햅틱"):
		errors.append("%s settings summary should explain auto-save sound/haptics, got %s." % [snapshot_id, "" if summary_label == null else summary_label.text])
	var expected_sound_text := "사운드: %s" % ("ON" if expected_enabled else "OFF")
	var expected_haptics_text := "햅틱: %s" % ("ON" if expected_enabled else "OFF")
	if sound_button == null or sound_button.text != expected_sound_text:
		errors.append("%s sound toggle should read %s, got %s." % [snapshot_id, expected_sound_text, "" if sound_button == null else sound_button.text])
	if haptics_button == null or haptics_button.text != expected_haptics_text:
		errors.append("%s haptics toggle should read %s, got %s." % [snapshot_id, expected_haptics_text, "" if haptics_button == null else haptics_button.text])
	if close_button == null or close_button.text != "닫기":
		errors.append("%s settings close button should read 닫기, got %s." % [snapshot_id, "" if close_button == null else close_button.text])


func _label_texts_under(root: Node) -> Array[String]:
	var texts: Array[String] = []
	if root == null:
		return texts
	for candidate in root.find_children("*", "Label", true, false):
		var label := candidate as Label
		if label != null:
			texts.append(label.text)
	return texts


func _validate_stage_select_world_map_snapshot_regions(image: Image, node: Node, snapshot_id: String, errors: PackedStringArray) -> void:
	var world_layer := node.find_child("StageWorldLayer", true, false) as Control
	var path_root := node.find_child("WorldMapPathRoot", true, false) as Control
	var selected_panel := node.find_child("WorldSelectedPanel", true, false) as Control
	var selected_info := node.find_child("WorldSelectedInfoColumn", true, false) as Control
	var selected_title := node.find_child("WorldSelectedTitleLabel", true, false) as Label
	var selected_chip_row := node.find_child("WorldSelectedChipRow", true, false) as Control
	var goal_chip := node.find_child("WorldSelectedGoalChip", true, false) as Button
	var moves_chip := node.find_child("WorldSelectedMovesChip", true, false) as Button
	var reward_chip := node.find_child("WorldSelectedRewardChip", true, false) as Button
	var play_button := node.find_child("WorldPlayButton", true, false) as Control
	var popup_overlay := node.find_child("StagePopupOverlay", true, false) as CanvasItem
	_validate_control_pixels(image, world_layer, snapshot_id, "StageWorldLayer", errors)
	_validate_control_pixels(image, path_root, snapshot_id, "WorldMapPathRoot", errors)
	_validate_control_pixels(image, selected_panel, snapshot_id, "WorldSelectedPanel", errors)
	_validate_control_pixels(image, selected_info, snapshot_id, "WorldSelectedInfoColumn", errors)
	_validate_control_pixels(image, selected_chip_row, snapshot_id, "WorldSelectedChipRow", errors)
	for chip_info in [[goal_chip, "WorldSelectedGoalChip"], [moves_chip, "WorldSelectedMovesChip"], [reward_chip, "WorldSelectedRewardChip"]]:
		var chip := chip_info[0] as Control
		var label := String(chip_info[1])
		_validate_control_pixels(image, chip, snapshot_id, label, errors)
		_validate_control_within_image_bounds(chip, snapshot_id, label, errors)
	_validate_control_pixels(image, play_button, snapshot_id, "WorldPlayButton", errors)
	_validate_control_within_image_bounds(selected_panel, snapshot_id, "WorldSelectedPanel", errors)
	_validate_control_within_image_bounds(selected_info, snapshot_id, "WorldSelectedInfoColumn", errors)
	_validate_control_within_image_bounds(selected_chip_row, snapshot_id, "WorldSelectedChipRow", errors)
	_validate_control_within_image_bounds(play_button, snapshot_id, "WorldPlayButton", errors)
	_validate_control_image_minimum_size(image, play_button, snapshot_id, "WorldPlayButton", Vector2(92, 44) if image.get_height() >= image.get_width() else Vector2(190, 48), errors)
	var portrait := image.get_height() >= image.get_width()
	var chip_min := Vector2(50, 18) if portrait else Vector2(78, 22)
	_validate_control_image_minimum_size(image, goal_chip, snapshot_id, "WorldSelectedGoalChip", chip_min, errors)
	_validate_control_image_minimum_size(image, moves_chip, snapshot_id, "WorldSelectedMovesChip", chip_min, errors)
	_validate_control_image_minimum_size(image, reward_chip, snapshot_id, "WorldSelectedRewardChip", chip_min, errors)
	_validate_controls_do_not_overlap(selected_info, play_button, snapshot_id, "WorldSelectedInfoColumn", "WorldPlayButton", errors)
	var chip_text := _button_text(goal_chip) + " " + _button_text(moves_chip) + " " + _button_text(reward_chip)
	if selected_title == null or not selected_title.text.contains("Level"):
		errors.append("%s WorldSelectedTitleLabel should show the selected Level." % snapshot_id)
	if not chip_text.contains("목표") or not chip_text.contains("이동") or not chip_text.contains("보상"):
		errors.append("%s WorldSelectedPanel should expose selected-stage goal, moves, and reward chips." % snapshot_id)
	if popup_overlay != null and popup_overlay.visible:
		errors.append("%s should capture the default world map without StagePopupOverlay visible." % snapshot_id)
	if path_root == null:
		return
	var visible_stage_nodes := 0
	for candidate in path_root.find_children("WorldStageNode*", "Button", true, false):
		var button := candidate as Control
		if button == null or not button.is_visible_in_tree():
			continue
		visible_stage_nodes += 1
		_validate_control_pixels(image, button, snapshot_id, String(button.name), errors)
		_validate_control_within_image_bounds(button, snapshot_id, String(button.name), errors)
	if visible_stage_nodes != 10:
		errors.append("%s should render 10 visible world stage nodes, got %d." % [snapshot_id, visible_stage_nodes])


func _validate_stage_select_world_progress_snapshot_regions(image: Image, node: Node, snapshot_id: String, errors: PackedStringArray) -> void:
	var current_node := node.find_child("WorldStageNode4", true, false) as Button
	var cleared_node := node.find_child("WorldStageNode1", true, false) as Button
	var locked_node := node.find_child("WorldStageNode5", true, false) as Button
	var finale_node := node.find_child("WorldStageNode10", true, false) as Button
	var selected_panel := node.find_child("WorldSelectedPanel", true, false) as Control
	_validate_world_node_child_region(image, current_node, "WorldNodeCurrentRing", snapshot_id, "WorldStageNode4 current ring", errors)
	_validate_world_node_child_region(image, current_node, "WorldNodePlayRibbon", snapshot_id, "WorldStageNode4 PLAY ribbon", errors)
	_validate_world_node_child_region(image, cleared_node, "WorldNodeStarTray", snapshot_id, "WorldStageNode1 cleared star tray", errors)
	_validate_world_node_child_region(image, locked_node, "WorldNodeLockBadge", snapshot_id, "WorldStageNode5 lock badge", errors)
	_validate_world_node_child_region(image, finale_node, "WorldNodeFinaleRibbon", snapshot_id, "WorldStageNode10 finale ribbon", errors)
	_validate_controls_do_not_overlap(current_node, selected_panel, snapshot_id, "WorldStageNode4", "WorldSelectedPanel", errors)
	_validate_controls_do_not_overlap(cleared_node, selected_panel, snapshot_id, "WorldStageNode1", "WorldSelectedPanel", errors)
	if current_node == null or current_node.disabled:
		errors.append("%s WorldStageNode4 should be the unlocked current node." % snapshot_id)
	if locked_node == null or not locked_node.disabled:
		errors.append("%s WorldStageNode5 should remain locked in the progress fixture." % snapshot_id)
	var play_ribbon_label := _first_label_text_under(current_node, "WorldNodePlayRibbonLabel")
	if play_ribbon_label != "PLAY":
		errors.append("%s WorldStageNode4 PLAY ribbon expected PLAY, got %s." % [snapshot_id, play_ribbon_label])
	var star_text := _first_label_text_under(cleared_node, "WorldNodeStarTrayLabel")
	if not star_text.contains("★"):
		errors.append("%s WorldStageNode1 cleared star tray should show earned stars, got %s." % [snapshot_id, star_text])
	var lock_text := _first_label_text_under(locked_node, "WorldNodeLockBadgeLabel")
	if lock_text != "LOCK":
		errors.append("%s WorldStageNode5 lock badge expected LOCK, got %s." % [snapshot_id, lock_text])
	var finale_text := _first_label_text_under(finale_node, "WorldNodeFinaleRibbonLabel")
	if finale_text != "BOSS":
		errors.append("%s WorldStageNode10 finale ribbon expected BOSS, got %s." % [snapshot_id, finale_text])


func _validate_world_node_child_region(image: Image, world_node: Node, child_name: String, snapshot_id: String, label: String, errors: PackedStringArray) -> void:
	var child: Control = null
	if world_node != null:
		child = world_node.find_child(child_name, true, false) as Control
	_validate_control_pixels(image, child, snapshot_id, label, errors)
	_validate_control_within_image_bounds(child, snapshot_id, label, errors)


func _first_label_text_under(root: Node, label_name: String) -> String:
	if root == null:
		return ""
	var label := root.find_child(label_name, true, false) as Label
	return "" if label == null else label.text


func _validate_collection_snapshot_regions(image: Image, node: Node, snapshot_id: String, errors: PackedStringArray) -> void:
	var header_panel := node.find_child("CollectionHeaderPanel", true, false) as Control
	var detail_label := node.find_child("DetailLabel", true, false) as Label
	var cosmetic_grid := node.find_child("CosmeticEquipGrid", true, false) as Control
	var earned_button := node.find_child("CosmeticButton_rabbit_smile_plus", true, false) as Button
	var equipped_button := node.find_child("CosmeticButton_rabbit_sprout_frame", true, false) as Button
	var unearned_button := node.find_child("CosmeticButton_rabbit_rescuer_badge", true, false) as Button
	var rabbit_card := node.find_child("AnimalCard_rabbit", true, false) as Control
	var locked_card := node.find_child("AnimalCard_dog", true, false) as Control
	var rabbit_preview: Control = null
	if rabbit_card != null:
		rabbit_preview = rabbit_card.find_child("AnimalPreview", true, false) as Control
	var locked_preview: Control = null
	var locked_status_visual: Control = null
	var locked_status_label: Label = null
	if locked_card != null:
		locked_preview = locked_card.find_child("AnimalPreview", true, false) as Control
		locked_status_visual = locked_card.find_child("AnimalStatusVisual", true, false) as Control
		locked_status_label = locked_card.find_child("AnimalStatusLabel", true, false) as Label
	var equipped_badge: Control = null
	var equipped_badge_label: Label = null
	if rabbit_card != null:
		equipped_badge = rabbit_card.find_child("EquippedCosmeticBadge_rabbit_sprout_frame", true, false) as Control
		if equipped_badge != null:
			equipped_badge_label = equipped_badge.find_child("EquippedCosmeticBadgeLabel", true, false) as Label
	_validate_control_pixels(image, header_panel, snapshot_id, "CollectionHeaderPanel", errors)
	_validate_control_pixels(image, detail_label, snapshot_id, "CollectionDetailLabel", errors)
	_validate_control_pixels(image, cosmetic_grid, snapshot_id, "CosmeticEquipGrid", errors)
	_validate_control_pixels(image, rabbit_card, snapshot_id, "AnimalCardRabbit", errors)
	_validate_control_pixels(image, rabbit_preview, snapshot_id, "AnimalPreviewRabbit", errors)
	_validate_control_pixels(image, locked_card, snapshot_id, "AnimalCardLockedDog", errors)
	_validate_control_pixels(image, locked_preview, snapshot_id, "AnimalPreviewLockedDog", errors)
	_validate_control_pixels(image, locked_status_visual, snapshot_id, "AnimalStatusLockedDog", errors)
	_validate_control_pixels(image, earned_button, snapshot_id, "CosmeticButtonRabbitSmilePlus", errors)
	_validate_control_pixels(image, equipped_button, snapshot_id, "CosmeticButtonRabbitSproutFrame", errors)
	_validate_control_pixels(image, unearned_button, snapshot_id, "CosmeticButtonRabbitRescuerBadge", errors)
	_validate_control_pixels(image, equipped_badge, snapshot_id, "EquippedRabbitFrameBadge", errors)
	_validate_control_within_image_bounds(header_panel, snapshot_id, "CollectionHeaderPanel", errors)
	_validate_control_within_image_bounds(cosmetic_grid, snapshot_id, "CosmeticEquipGrid", errors)
	_validate_control_within_image_bounds(rabbit_card, snapshot_id, "AnimalCardRabbit", errors)
	_validate_control_within_image_bounds(rabbit_preview, snapshot_id, "AnimalPreviewRabbit", errors)
	_validate_control_within_image_bounds(locked_card, snapshot_id, "AnimalCardLockedDog", errors)
	_validate_control_within_image_bounds(locked_preview, snapshot_id, "AnimalPreviewLockedDog", errors)
	_validate_control_within_image_bounds(locked_status_visual, snapshot_id, "AnimalStatusLockedDog", errors)
	_validate_control_within_image_bounds(earned_button, snapshot_id, "CosmeticButtonRabbitSmilePlus", errors)
	_validate_control_within_image_bounds(equipped_button, snapshot_id, "CosmeticButtonRabbitSproutFrame", errors)
	_validate_control_within_image_bounds(unearned_button, snapshot_id, "CosmeticButtonRabbitRescuerBadge", errors)
	_validate_control_within_image_bounds(equipped_badge, snapshot_id, "EquippedRabbitFrameBadge", errors)
	_validate_control_image_minimum_size(image, rabbit_card, snapshot_id, "AnimalCardRabbit", Vector2(float(image.get_width()) * (0.42 if image.get_height() >= image.get_width() else 0.13), float(image.get_height()) * (0.16 if image.get_height() >= image.get_width() else 0.20)), errors)
	_validate_control_image_minimum_size(image, rabbit_preview, snapshot_id, "AnimalPreviewRabbit", Vector2(float(image.get_width()) * (0.18 if image.get_height() >= image.get_width() else 0.055), float(image.get_width()) * (0.18 if image.get_height() >= image.get_width() else 0.055)), errors)
	_validate_control_image_minimum_size(image, locked_card, snapshot_id, "AnimalCardLockedDog", Vector2(float(image.get_width()) * (0.42 if image.get_height() >= image.get_width() else 0.13), float(image.get_height()) * (0.16 if image.get_height() >= image.get_width() else 0.20)), errors)
	_validate_control_image_minimum_size(image, locked_preview, snapshot_id, "AnimalPreviewLockedDog", Vector2(float(image.get_width()) * (0.14 if image.get_height() >= image.get_width() else 0.045), float(image.get_width()) * (0.14 if image.get_height() >= image.get_width() else 0.045)), errors)
	if image.get_height() >= image.get_width():
		_validate_control_image_maximum_height(image, header_panel, snapshot_id, "CollectionHeaderPanel", float(image.get_height()) * 0.13, errors)
		_validate_control_image_maximum_height(image, cosmetic_grid, snapshot_id, "CosmeticEquipGrid", float(image.get_height()) * 0.058, errors)
	if detail_label == null or not detail_label.text.contains("토끼") or not detail_label.text.contains("Lv.3") or not detail_label.text.contains("토큰 40") or not detail_label.text.contains("우정 보상"):
		errors.append("%s collection snapshot detail should show selected rabbit Lv.3 token reward track." % snapshot_id)
	if earned_button == null or earned_button.disabled or not earned_button.text.contains("장착"):
		errors.append("%s collection snapshot should show an enabled 장착 button for earned unequipped rabbit cosmetic." % snapshot_id)
	if equipped_button == null or not equipped_button.disabled or not equipped_button.text.contains("장착중"):
		errors.append("%s collection snapshot should show disabled 장착중 state for rabbit_sprout_frame." % snapshot_id)
	elif equipped_button.tooltip_text != "rabbit_sprout_frame":
		errors.append("%s collection snapshot equipped button should preserve rabbit_sprout_frame tooltip metadata." % snapshot_id)
	if unearned_button == null or not unearned_button.disabled or not unearned_button.text.contains("대기"):
		errors.append("%s collection snapshot should show a disabled 대기 button for unearned rabbit cosmetic." % snapshot_id)
	if locked_status_label == null or not locked_status_label.text.contains("Stage 7 해금"):
		errors.append("%s collection snapshot should keep locked dog card unlock-stage copy." % snapshot_id)
	if equipped_badge_label == null or not equipped_badge_label.text.contains("장착 프레임"):
		errors.append("%s collection snapshot should show an equipped rabbit frame badge on the animal card." % snapshot_id)
	if rabbit_card == null or String(rabbit_card.get_meta("equipped_cosmetic", "")) != "rabbit_sprout_frame" or String(rabbit_card.get_meta("equipped_cosmetic_type", "")) != "card_frame":
		errors.append("%s collection snapshot rabbit card should expose equipped cosmetic metadata." % snapshot_id)
	var state_animals := Dictionary(GameSession.get_rescue_book_state().get("animals", {}))
	var rabbit_entry := Dictionary(state_animals.get("rabbit", {}))
	if int(rabbit_entry.get("tokens", 0)) != 40 or String(rabbit_entry.get("equipped_cosmetic", "")) != "rabbit_sprout_frame":
		errors.append("%s collection snapshot fixture should preserve rabbit tokens=40 and equipped rabbit_sprout_frame." % snapshot_id)


func _validate_stage_4_buddy_snapshot_regions(image: Image, node: Node, scenario: Dictionary, snapshot_id: String, errors: PackedStringArray) -> void:
	var board_frame := node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control
	var intro_card := node.find_child("StageIntroCard", true, false) as Control
	var intro_label := node.find_child("StageIntroLabel", true, false) as Label
	var intro_status := node.find_child("StageIntroStatusChip", true, false) as Button
	_validate_control_pixels(image, board_frame, snapshot_id, "BoardFrame", errors)
	_validate_control_within_image_bounds(board_frame, snapshot_id, "BoardFrame", errors)
	_validate_control_pixels(image, intro_card, snapshot_id, "StageIntroCard", errors)
	_validate_control_pixels(image, intro_label, snapshot_id, "StageIntroLabel", errors)
	_validate_control_pixels(image, intro_status, snapshot_id, "StageIntroStatusChip", errors)
	_validate_control_within_image_bounds(intro_card, snapshot_id, "StageIntroCard", errors)
	_validate_control_within_image_bounds(intro_status, snapshot_id, "StageIntroStatusChip", errors)
	_validate_control_image_minimum_size(image, intro_card, snapshot_id, "StageIntroCard", Vector2(float(image.get_width()) * (0.34 if image.get_height() >= image.get_width() else 0.15), float(image.get_height()) * (0.070 if image.get_height() >= image.get_width() else 0.070)), errors)
	_validate_control_image_maximum_height(image, intro_card, snapshot_id, "StageIntroCard", float(image.get_height()) * 0.18, errors)
	if intro_label == null or not intro_label.text.contains("Level"):
		errors.append("%s StageIntroLabel should show a Level title instead of raw all-caps overlay copy." % snapshot_id)
	if intro_status == null or not ["READY", "GO!"].has(intro_status.text):
		errors.append("%s StageIntroStatusChip should show READY or GO!, got %s." % [snapshot_id, "" if intro_status == null else intro_status.text])

	if image.get_height() >= image.get_width():
		var goal_dock := node.find_child("HudGoalDock", true, false) as Control
		var booster_dock := node.find_child("HudBoosterDock", true, false) as Control
		var buddy_row := node.find_child("HudBuddyRow", true, false) as Control
		var buddy_label := node.get("hud_buddy_label") as Label
		var buddy_gauge := node.get("hud_buddy_gauge") as ProgressBar
		for control_info in [[goal_dock, "HudGoalDock"], [booster_dock, "HudBoosterDock"], [buddy_row, "HudBuddyRow"], [buddy_label, "HudBuddyLabel"], [buddy_gauge, "HudBuddyGauge"]]:
			var control := control_info[0] as Control
			var label := String(control_info[1])
			_validate_control_pixels(image, control, snapshot_id, label, errors)
			_validate_control_within_image_bounds(control, snapshot_id, label, errors)
		_validate_controls_do_not_overlap(goal_dock, board_frame, snapshot_id, "HudGoalDock", "BoardFrame", errors)
		_validate_controls_do_not_overlap(booster_dock, board_frame, snapshot_id, "HudBoosterDock", "BoardFrame", errors)
	else:
		var landscape_shell := node.find_child("LandscapeHudShell", true, false) as Control
		var stats_card := node.find_child("StatsCard", true, false) as Control
		var goal_card := node.find_child("GoalCard", true, false) as Control
		var support_card := node.find_child("TipsCard", true, false) as Control
		var retry_button := node.find_child("RetryButton", true, false) as Control
		var next_button := node.find_child("NextStageButton", true, false) as Control
		var quit_button := node.find_child("QuitButton", true, false) as Control
		var combo_value := node.get("combo_value") as Label
		var combo_gauge := node.get("combo_gauge") as ProgressBar
		for control_info in [[landscape_shell, "LandscapeHudShell"], [stats_card, "StatsCard"], [goal_card, "GoalCard"], [support_card, "LandscapeSupportCard"], [retry_button, "RetryButton"], [next_button, "NextStageButton"], [quit_button, "QuitButton"], [combo_value, "ComboValue"], [combo_gauge, "ComboGauge"]]:
			var control := control_info[0] as Control
			var label := String(control_info[1])
			_validate_control_pixels(image, control, snapshot_id, label, errors)
			_validate_control_within_image_bounds(control, snapshot_id, label, errors)
		_validate_control_image_minimum_size(image, landscape_shell, snapshot_id, "LandscapeHudShell", Vector2(float(image.get_width()) * 0.20, float(image.get_height()) * 0.84), errors)
		_validate_control_image_minimum_size(image, stats_card, snapshot_id, "StatsCard", Vector2(float(image.get_width()) * 0.17, 58.0), errors)
		_validate_control_image_minimum_size(image, goal_card, snapshot_id, "GoalCard", Vector2(float(image.get_width()) * 0.17, 108.0), errors)
		_validate_control_image_minimum_size(image, support_card, snapshot_id, "LandscapeSupportCard", Vector2(float(image.get_width()) * 0.17, float(image.get_height()) * 0.12), errors)
		_validate_control_image_horizontal_gap(image, board_frame, landscape_shell, snapshot_id, "BoardFrame", "LandscapeHudShell", float(image.get_width()) * 0.14, errors)
		_validate_controls_do_not_overlap(landscape_shell, board_frame, snapshot_id, "LandscapeHudShell", "BoardFrame", errors)
		_validate_controls_do_not_overlap(stats_card, board_frame, snapshot_id, "StatsCard", "BoardFrame", errors)
		_validate_controls_do_not_overlap(goal_card, board_frame, snapshot_id, "GoalCard", "BoardFrame", errors)
		_validate_controls_do_not_overlap(support_card, board_frame, snapshot_id, "LandscapeSupportCard", "BoardFrame", errors)

	_validate_stage_4_buddy_state(node, scenario, snapshot_id, errors)
	_validate_stage_4_buddy_analytics(scenario, snapshot_id, errors)


func _validate_stage_4_buddy_state(node: Node, scenario: Dictionary, snapshot_id: String, errors: PackedStringArray) -> void:
	var buddy_state := String(scenario.get("buddy_state", "initial"))
	var buddy_label := node.get("hud_buddy_label") as Label
	var buddy_gauge := node.get("hud_buddy_gauge") as ProgressBar
	var combo_value := node.get("combo_value") as Label
	if buddy_label == null or buddy_gauge == null:
		errors.append("%s should expose Stage 4 Buddy HUD label and gauge." % snapshot_id)
		return
	if String(node.get("stage_state")) != "playing":
		errors.append("%s Stage 4 Buddy HUD snapshot should stay in playing state, got %s." % [snapshot_id, String(node.get("stage_state"))])
	if not buddy_label.visible or not buddy_gauge.visible:
		errors.append("%s Stage 4 Buddy HUD label and gauge should be visible." % snapshot_id)
	if not buddy_label.text.contains("토끼"):
		errors.append("%s Stage 4 Buddy HUD should identify rabbit as 토끼, got %s." % [snapshot_id, buddy_label.text])

	var expected_label_text := ""
	var expected_combo_text := ""
	var expected_gauge_value := 0
	var expected_charge_count := 0
	var expected_pending := false
	var expected_uses := 0
	match buddy_state:
		"charged":
			expected_label_text = "2/3"
			expected_combo_text = "Buddy 2/3"
			expected_gauge_value = 2
			expected_charge_count = 2
		"ready":
			expected_label_text = "출동"
			expected_combo_text = "Buddy 3/3"
			expected_gauge_value = 3
			expected_charge_count = 3
			expected_pending = true
		"complete":
			expected_label_text = "완료"
			expected_combo_text = "Buddy 완료"
			expected_gauge_value = 3
			expected_uses = 1
		_:
			expected_label_text = "0/3"
			expected_combo_text = "Buddy 0/3"

	if not buddy_label.text.contains(expected_label_text):
		errors.append("%s Stage 4 Buddy HUD state %s should show %s, got %s." % [snapshot_id, buddy_state, expected_label_text, buddy_label.text])
	if int(buddy_gauge.max_value) != 3 or int(buddy_gauge.value) != expected_gauge_value:
		errors.append("%s Stage 4 Buddy gauge state %s should be %d/3, got %d/%d." % [snapshot_id, buddy_state, expected_gauge_value, int(buddy_gauge.value), int(buddy_gauge.max_value)])
	if combo_value == null or not combo_value.text.contains(expected_combo_text):
		errors.append("%s Stage 4 landscape combo text should preserve %s, got %s." % [snapshot_id, expected_combo_text, "" if combo_value == null else combo_value.text])
	if int(node.get("buddy_charge_count")) != expected_charge_count:
		errors.append("%s Stage 4 Buddy internal charge for %s should be %d, got %d." % [snapshot_id, buddy_state, expected_charge_count, int(node.get("buddy_charge_count"))])
	if bool(node.get("buddy_trigger_pending")) != expected_pending:
		errors.append("%s Stage 4 Buddy pending flag for %s should be %s." % [snapshot_id, buddy_state, str(expected_pending)])
	if int(node.get("buddy_uses")) != expected_uses:
		errors.append("%s Stage 4 Buddy uses for %s should be %d, got %d." % [snapshot_id, buddy_state, expected_uses, int(node.get("buddy_uses"))])


func _validate_stage_4_buddy_analytics(scenario: Dictionary, snapshot_id: String, errors: PackedStringArray) -> void:
	var buddy_state := String(scenario.get("buddy_state", "initial"))
	var expected_charge_events := 0
	var expected_ready_events := 0
	var expected_trigger_events := 0
	var expected_last_charge := 0
	match buddy_state:
		"charged":
			expected_charge_events = 2
			expected_last_charge = 2
		"ready":
			expected_charge_events = 3
			expected_ready_events = 1
			expected_last_charge = 3
		"complete":
			expected_charge_events = 3
			expected_ready_events = 1
			expected_trigger_events = 1
			expected_last_charge = 3

	if _analytics_event_count("buddy_skill_charge") != expected_charge_events:
		errors.append("%s Stage 4 Buddy state %s should emit %d charge events, got %d." % [snapshot_id, buddy_state, expected_charge_events, _analytics_event_count("buddy_skill_charge")])
	if _analytics_event_count("buddy_skill_ready") != expected_ready_events:
		errors.append("%s Stage 4 Buddy state %s should emit %d ready events, got %d." % [snapshot_id, buddy_state, expected_ready_events, _analytics_event_count("buddy_skill_ready")])
	if _analytics_event_count("buddy_skill_trigger") != expected_trigger_events:
		errors.append("%s Stage 4 Buddy state %s should emit %d trigger events, got %d." % [snapshot_id, buddy_state, expected_trigger_events, _analytics_event_count("buddy_skill_trigger")])

	if expected_last_charge > 0:
		var charge_params := _last_analytics_event_params("buddy_skill_charge")
		if int(charge_params.get("stage_id", 0)) != 4 or String(charge_params.get("animal_id", "")) != "rabbit" or String(charge_params.get("skill_id", "")) != "quick_refill":
			errors.append("%s Stage 4 Buddy charge analytics should identify rabbit quick_refill." % snapshot_id)
		if int(charge_params.get("charge_count", 0)) != expected_last_charge:
			errors.append("%s Stage 4 Buddy charge analytics should end at %d, got %d." % [snapshot_id, expected_last_charge, int(charge_params.get("charge_count", 0))])
	if expected_ready_events > 0:
		var ready_params := _last_analytics_event_params("buddy_skill_ready")
		if int(ready_params.get("stage_id", 0)) != 4 or String(ready_params.get("animal_id", "")) != "rabbit" or String(ready_params.get("skill_id", "")) != "quick_refill":
			errors.append("%s Stage 4 Buddy ready analytics should identify rabbit quick_refill." % snapshot_id)
	if expected_trigger_events > 0:
		var trigger_params := _last_analytics_event_params("buddy_skill_trigger")
		if int(trigger_params.get("stage_id", 0)) != 4 or String(trigger_params.get("animal_id", "")) != "rabbit" or String(trigger_params.get("effect_type", "")) != "quick_refill":
			errors.append("%s Stage 4 Buddy trigger analytics should identify rabbit quick_refill." % snapshot_id)


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
	var chip_grid := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid") as Control
	var chip_primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid/OverlayResultChipPrimary") as Button
	var chip_secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid/OverlayResultChipSecondary") as Button
	var chip_tertiary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid/OverlayResultChipTertiary") as Button
	var primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Button
	var secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Button

	for control_info in [[panel, "OverlayPanel"], [title, "OverlayTitle"], [body, "OverlayBody"], [mascot, "OverlayMascot"], [chip_grid, "OverlayChipGrid"], [chip_primary, "OverlayResultChipPrimary"], [chip_secondary, "OverlayResultChipSecondary"], [chip_tertiary, "OverlayResultChipTertiary"], [primary, "OverlayPrimaryButton"], [secondary, "OverlaySecondaryButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_pixels(image, control, snapshot_id, label, errors)
		_validate_control_within_image_bounds(control, snapshot_id, label, errors)
	_validate_result_overlay_commercial_sizes(image, panel, mascot, chip_grid, primary, snapshot_id, errors)

	if title == null or not title.text.contains("구조 완료"):
		errors.append("%s success overlay title should contain 구조 완료." % snapshot_id)
	if body == null or not body.text.contains("보상") or not body.text.contains("별") or not body.text.contains("다음"):
		errors.append("%s success overlay body should show reward, stars, and next action text." % snapshot_id)
	elif not body.text.contains("Zoo-Zoo Time"):
		errors.append("%s success overlay body should include Zoo-Zoo Time bonus text." % snapshot_id)
	var success_chip_text := _button_text(chip_primary) + " " + _button_text(chip_secondary) + " " + _button_text(chip_tertiary)
	if chip_grid == null or not chip_grid.visible or not success_chip_text.contains("골드") or not success_chip_text.contains("도감") or not success_chip_text.contains("Zoo-Zoo Time"):
		errors.append("%s success overlay should expose reward chips for gold, Rescue Book tokens, and Zoo-Zoo Time." % snapshot_id)
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


func _validate_failure_overlay_snapshot_regions(image: Image, node: Node, snapshot_id: String, errors: PackedStringArray) -> void:
	var panel := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel") as Control
	var title := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayTitle") as Label
	var body := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Label
	var mascot := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayMascot") as TextureRect
	var chip_grid := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid") as Control
	var chip_primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid/OverlayResultChipPrimary") as Button
	var chip_secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid/OverlayResultChipSecondary") as Button
	var chip_tertiary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayChipGrid/OverlayResultChipTertiary") as Button
	var primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Button
	var secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Button
	for control_info in [[panel, "OverlayPanel"], [title, "OverlayTitle"], [body, "OverlayBody"], [mascot, "OverlayMascot"], [chip_grid, "OverlayChipGrid"], [chip_primary, "OverlayResultChipPrimary"], [chip_secondary, "OverlayResultChipSecondary"], [chip_tertiary, "OverlayResultChipTertiary"], [primary, "OverlayPrimaryButton"], [secondary, "OverlaySecondaryButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_pixels(image, control, snapshot_id, label, errors)
		_validate_control_within_image_bounds(control, snapshot_id, label, errors)
	_validate_result_overlay_commercial_sizes(image, panel, mascot, chip_grid, primary, snapshot_id, errors)
	if title == null or not title.text.contains("재도전 필요"):
		errors.append("%s failure overlay title should show retry-needed copy." % snapshot_id)
	if body == null or not body.text.contains("거의 다 왔어요") or not body.text.contains("놓친 핵심") or not body.text.contains("다음 한 수"):
		errors.append("%s failure overlay body should preserve near-miss reason and next-step copy." % snapshot_id)
	var failure_chip_text := _button_text(chip_primary) + " " + _button_text(chip_secondary) + " " + _button_text(chip_tertiary)
	if chip_grid == null or not chip_grid.visible or not failure_chip_text.contains("목표") or not failure_chip_text.contains("핵심") or not failure_chip_text.contains("다음"):
		errors.append("%s failure overlay should expose action chips for goal, missed focus, and next move." % snapshot_id)
	if primary == null or primary.text != "+3 이동 받고 계속":
		errors.append("%s failure overlay primary CTA should remain +3 이동 받고 계속." % snapshot_id)
	if secondary == null or not secondary.visible or secondary.text != "재도전":
		errors.append("%s failure overlay secondary CTA should remain 재도전." % snapshot_id)


func _button_text(button: Button) -> String:
	return "" if button == null else button.text


func _validate_result_overlay_commercial_sizes(image: Image, panel: Control, mascot: Control, chip_grid: Control, primary: Control, snapshot_id: String, errors: PackedStringArray) -> void:
	var portrait := image.get_height() >= image.get_width()
	_validate_control_image_minimum_size(image, panel, snapshot_id, "OverlayPanel", Vector2(float(image.get_width()) * (0.70 if portrait else 0.23), float(image.get_height()) * (0.26 if portrait else 0.30)), errors)
	_validate_control_image_minimum_size(image, mascot, snapshot_id, "OverlayMascot", Vector2(float(image.get_width()) * (0.09 if portrait else 0.035), float(image.get_width()) * (0.09 if portrait else 0.035)), errors)
	_validate_control_image_minimum_size(image, chip_grid, snapshot_id, "OverlayChipGrid", Vector2(float(image.get_width()) * (0.62 if portrait else 0.18), float(image.get_height()) * (0.065 if portrait else 0.045)), errors)
	_validate_control_image_minimum_size(image, primary, snapshot_id, "OverlayPrimaryButton", Vector2(float(image.get_width()) * (0.24 if portrait else 0.065), float(image.get_height()) * (0.035 if portrait else 0.035)), errors)


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
	_validate_special_combo_texture_fx(ring, snapshot_id, "SpecialComboRing", 0.04, errors)

	if bool(scenario.get("requires_echo", false)):
		var echo_ring := node.find_child("SpecialComboEchoRing", true, false) as Control
		_validate_control_pixels(image, echo_ring, snapshot_id, "SpecialComboEchoRing", errors)
		_validate_special_combo_texture_fx(echo_ring, snapshot_id, "SpecialComboEchoRing", 0.03, errors)

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


func _validate_control_image_minimum_size(image: Image, control: Control, snapshot_id: String, label: String, minimum_size: Vector2, errors: PackedStringArray) -> void:
	if control == null:
		return
	var rect := _control_rect_to_image_bounds(control.get_global_rect(), image.get_width(), image.get_height())
	if float(rect.size.x) < minimum_size.x or float(rect.size.y) < minimum_size.y:
		errors.append("%s %s should remain commercially readable in the PNG at least %s, got %s." % [snapshot_id, label, minimum_size, rect.size])


func _validate_control_image_maximum_height(image: Image, control: Control, snapshot_id: String, label: String, maximum_height: float, errors: PackedStringArray) -> void:
	if control == null:
		return
	var rect := _control_rect_to_image_bounds(control.get_global_rect(), image.get_width(), image.get_height())
	if float(rect.size.y) > maximum_height:
		errors.append("%s %s should remain a compact commercial ribbon in the PNG, got height %.1f above %.1f." % [snapshot_id, label, float(rect.size.y), maximum_height])


func _validate_control_image_horizontal_gap(image: Image, left_control: Control, right_control: Control, snapshot_id: String, left_label: String, right_label: String, max_gap: float, errors: PackedStringArray) -> void:
	if left_control == null or right_control == null:
		return
	var left_rect := _control_rect_to_image_bounds(left_control.get_global_rect(), image.get_width(), image.get_height())
	var right_rect := _control_rect_to_image_bounds(right_control.get_global_rect(), image.get_width(), image.get_height())
	var gap := float(right_rect.position.x - (left_rect.position.x + left_rect.size.x))
	if gap > max_gap:
		errors.append("%s %s and %s should read as one gameplay cluster in the PNG, got horizontal gap %.1f above %.1f." % [snapshot_id, left_label, right_label, gap, max_gap])


func _validate_controls_do_not_overlap(a: Control, b: Control, snapshot_id: String, a_label: String, b_label: String, errors: PackedStringArray) -> void:
	if a == null or b == null:
		return
	if not a.is_visible_in_tree() or not b.is_visible_in_tree():
		return
	var a_rect := a.get_global_rect()
	var b_rect := b.get_global_rect()
	var overlap_width := minf(a_rect.position.x + a_rect.size.x, b_rect.position.x + b_rect.size.x) - maxf(a_rect.position.x, b_rect.position.x)
	var overlap_height := minf(a_rect.position.y + a_rect.size.y, b_rect.position.y + b_rect.size.y) - maxf(a_rect.position.y, b_rect.position.y)
	if overlap_width > 1.0 and overlap_height > 1.0:
		errors.append("%s control regions %s and %s should not overlap, overlap %.1fx%.1f." % [snapshot_id, a_label, b_label, overlap_width, overlap_height])


func _validate_canvas_item_alpha(node: CanvasItem, snapshot_id: String, label: String, min_alpha: float, errors: PackedStringArray) -> void:
	if node == null:
		return
	if node.modulate.a < min_alpha:
		errors.append("%s %s alpha %.3f should be >= %.3f during render snapshot." % [snapshot_id, label, node.modulate.a, min_alpha])


func _validate_special_combo_texture_fx(control: Control, snapshot_id: String, label: String, min_effective_alpha: float, errors: PackedStringArray) -> void:
	if control == null:
		return
	var texture_rect := control as TextureRect
	if texture_rect == null:
		errors.append("%s %s should be a TextureRect special combo VFX node." % [snapshot_id, label])
		return
	if texture_rect.texture == null:
		errors.append("%s %s should keep a non-null ring texture." % [snapshot_id, label])
	var effective_alpha := _canvas_item_effective_alpha(texture_rect)
	if effective_alpha < min_effective_alpha:
		errors.append("%s %s effective alpha %.3f should be >= %.3f during render snapshot." % [snapshot_id, label, effective_alpha, min_effective_alpha])
	if minf(absf(texture_rect.scale.x), absf(texture_rect.scale.y)) < 0.35:
		errors.append("%s %s scale %s should show the ring animation after trigger." % [snapshot_id, label, texture_rect.scale])


func _canvas_item_effective_alpha(node: CanvasItem) -> float:
	var alpha := node.modulate.a
	var current := node.get_parent()
	while current != null:
		var canvas_parent := current as CanvasItem
		if canvas_parent != null:
			alpha *= canvas_parent.modulate.a
		current = current.get_parent()
	return alpha


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
