extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const CollectionState = preload("res://scripts/collection_state.gd")
const GameSession = preload("res://scripts/game_session.gd")
const FailOfferPolicy = preload("res://scripts/fail_offer_policy.gd")
const LiveEventService = preload("res://scripts/live_event_service.gd")
const AnalyticsGateway = preload("res://scripts/analytics_gateway.gd")
const MonetizationGateway = preload("res://scripts/monetization_gateway.gd")

const LOADING_SCENE_PATH: String = "res://scenes/loading.tscn"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const STAGE_SELECT_SCENE_PATH: String = "res://scenes/stage_select.tscn"
const COLLECTION_SCENE_PATH: String = "res://scenes/collection_screen.tscn"
const GAMEPLAY_SCENE_PATH: String = "res://scenes/gameplay.tscn"
const FX_LAYER_SCENE_PATH: String = "res://scenes/fx_layer.tscn"
const STAGE_CARD_SCENE_PATH: String = "res://scenes/stage_card.tscn"
const BLOCK_TILE_SCENE_PATH: String = "res://scenes/block_tile.tscn"
const GOAL_CHIP_SCENE_PATH: String = "res://scenes/goal_chip.tscn"
const ALPHA_QA_TEMPLATE_PATH := "res://docs/qa/templates/alpha-lock-pass-manual-qa-template.md"
const SESSION_VALIDATION_SAVE_PATH := "user://scene_validation_save_game.json"
const SESSION_VALIDATION_SAVE_FILE_NAME := "scene_validation_save_game.json"
const SESSION_VALIDATION_ANALYTICS_QUEUE_PATH := "user://scene_validation_analytics_gateway_queue.json"
const ANIMAL_IDS := ["rabbit", "bear", "cat", "chick", "frog", "dog", "panda", "pig", "penguin", "fox", "lion", "elephant"]
const FIRST_SESSION_COLLECTION_UNLOCK_IDS := ["frog", "koala", "hamster"]
const FIRST_SESSION_COLLECTION_UNLOCK_STAGES := {"frog": 4, "koala": 5, "hamster": 6}
const ANIMAL_TEXTURE_FALLBACKS := {
	"lion": "fox",
	"elephant": "panda",
	"koala": "panda",
	"hamster": "pig",
	"deer": "fox",
	"seal": "penguin",
	"sheep": "bear",
	"turtle": "frog",
}
const ANIMAL_PROFILE_PATH := "res://data/animal_animation_profiles.json"
const IMPLEMENTED_LIVE_EVENT_PLACEMENTS := ["home", "stage_select", "result_overlay", "collection"]
const MVP_BOARD_TEXTURE_SIZE := Vector2i(256, 256)
const SPECIAL_COMBO_MANUAL_ROWS := ["row+column", "row+row", "column+column", "row+bomb", "column+bomb", "bomb+bomb"]
const CRITICAL_TEXT_STRESS_TITLE := "[長文QA] Rescue Ready SuperLongLocalizationToken"
const CRITICAL_TEXT_STRESS_BODY := "[長文QA] 구조 목표가 길어져도 버튼과 본문이 겹치지 않아야 합니다 SuperLongUnbrokenLocalizationToken"
const CRITICAL_TEXT_STRESS_CTA := "PLAY 구조 시작"
const MOBILE_VIEWPORT_MATRIX := [
	Vector2i(1080, 1920),
	Vector2i(720, 1280),
	Vector2i(390, 844),
	Vector2i(1920, 1080),
	Vector2i(1280, 720),
	Vector2i(844, 390),
]

var representative_stage_ids: Array[int] = [1, 11, 25, 50, 75, 100]
var tutorial_stage_ids: Array[int] = [1, 11, 25, 45, 65, 85, 95]
var analytics_flush_adapter_requests: Array = []
var monetization_adapter_requests: Array = []
var validation_analytics_queue_path := SESSION_VALIDATION_ANALYTICS_QUEUE_PATH


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	validation_analytics_queue_path = "user://scene_validation_analytics_gateway_queue_%d.json" % Time.get_ticks_usec()
	GameSession.use_save_path_for_testing(SESSION_VALIDATION_SAVE_PATH)
	AnalyticsGateway.use_queue_path_for_testing(validation_analytics_queue_path)
	AnalyticsGateway.reset_for_testing()
	AnalyticsGateway.clear_persisted_queue_for_testing()
	MonetizationGateway.reset_for_testing()
	LiveEventService.reset_remote_config_exposures_for_testing()
	_remove_validation_save()
	var errors: PackedStringArray = PackedStringArray()
	GameSession.clear_analytics_events()
	_validate_alpha_gate_data(errors)
	_reset_validation_save_only()
	_validate_first_session_collection_unlock_flow(errors)
	_reset_validation_save_only()
	var scene_paths: PackedStringArray = PackedStringArray([
		LOADING_SCENE_PATH,
		MAIN_SCENE_PATH,
		STAGE_SELECT_SCENE_PATH,
		COLLECTION_SCENE_PATH,
		GAMEPLAY_SCENE_PATH,
		FX_LAYER_SCENE_PATH,
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
		await _validate_viewport_resilience(scene_path, node, errors)
		await _validate_scene_runtime_specifics(scene_path, node, errors)
		await create_timer(0.2).timeout
		if is_instance_valid(node):
			node.queue_free()
		await process_frame
		await process_frame

	_validate_runtime_analytics_events(errors)
	_validate_analytics_gateway_contract_gate(errors)
	if not errors.is_empty():
		for error_text in errors:
			push_error("Scene load validation error: %s" % error_text)
		_remove_validation_save()
		AnalyticsGateway.clear_persisted_queue_for_testing()
		AnalyticsGateway.reset_for_testing()
		quit(1)
		return

	print("Scene load validation passed: %d scenes parsed and instantiated." % scene_paths.size())
	_remove_validation_save()
	AnalyticsGateway.clear_persisted_queue_for_testing()
	AnalyticsGateway.reset_for_testing()
	quit()


func _reset_validation_save_only() -> void:
	_remove_validation_save()
	GameSession.reset_progress_for_testing_preserving_analytics()


func _remove_validation_save() -> void:
	if FileAccess.file_exists(SESSION_VALIDATION_SAVE_PATH):
		var user_dir := DirAccess.open("user://")
		if user_dir == null:
			push_warning("Scene validation could not open user:// to remove temporary validation save.")
			return
		var remove_error := user_dir.remove(SESSION_VALIDATION_SAVE_FILE_NAME)
		if remove_error != OK:
			var file := FileAccess.open(SESSION_VALIDATION_SAVE_PATH, FileAccess.WRITE)
			if file != null:
				file.store_string("{}")
				return
			push_warning("Scene validation could not reset temporary %s." % SESSION_VALIDATION_SAVE_PATH)


func _validate_scene_specifics(scene_path: String, node: Node) -> PackedStringArray:
	var errors := PackedStringArray()

	match scene_path:
		LOADING_SCENE_PATH:
			_validate_loading_scene(node, errors)
		MAIN_SCENE_PATH:
			_validate_main_scene(node, errors)
		GAMEPLAY_SCENE_PATH:
			_validate_gameplay_scene(node, errors)
		FX_LAYER_SCENE_PATH:
			_validate_fx_layer_scene(node, errors)
		STAGE_SELECT_SCENE_PATH:
			_validate_stage_select_scene(node, errors)
		COLLECTION_SCENE_PATH:
			_validate_collection_scene(node, errors)

	return errors


func _validate_scene_runtime_specifics(scene_path: String, node: Node, errors: PackedStringArray) -> void:
	match scene_path:
		MAIN_SCENE_PATH:
			_validate_main_settings_runtime(node, errors)
		COLLECTION_SCENE_PATH:
			await _validate_collection_preview_motion_runtime(node, errors)
		GAMEPLAY_SCENE_PATH:
			await _validate_special_combo_swap_runtime(node, errors)
			await _validate_result_overlay_runtime(node, errors)
		STAGE_SELECT_SCENE_PATH:
			await _validate_stage_popup_runtime(node, errors)
		FX_LAYER_SCENE_PATH:
			await _validate_fx_layer_runtime(node, errors)


func _validate_viewport_resilience(scene_path: String, node: Node, errors: PackedStringArray) -> void:
	if not [MAIN_SCENE_PATH, STAGE_SELECT_SCENE_PATH, GAMEPLAY_SCENE_PATH, COLLECTION_SCENE_PATH].has(scene_path):
		return

	var original_size := root.size
	for viewport_size_target: Vector2i in MOBILE_VIEWPORT_MATRIX:
		root.size = viewport_size_target
		await _refresh_node_layout_for_viewport(node)
		var viewport_size := Vector2i(root.get_visible_rect().size)
		await _validate_viewport_layout_for_scene(scene_path, node, viewport_size, errors)
		await _validate_critical_runtime_viewport_state(scene_path, node, viewport_size, errors)
	root.size = original_size
	await _refresh_node_layout_for_viewport(node)


func _refresh_node_layout_for_viewport(node: Node) -> void:
	await process_frame
	if node != null and node.has_method("_apply_responsive_layout"):
		node.call("_apply_responsive_layout")
	await process_frame
	await process_frame


func _validate_viewport_layout_for_scene(scene_path: String, node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	match scene_path:
		MAIN_SCENE_PATH:
			_validate_main_viewport_layout(node, viewport_size, errors)
			await _validate_main_viewport_text_stress(node, viewport_size, errors)
		STAGE_SELECT_SCENE_PATH:
			_validate_stage_select_viewport_layout(node, viewport_size, errors)
		GAMEPLAY_SCENE_PATH:
			_validate_gameplay_viewport_layout(node, viewport_size, errors)
		COLLECTION_SCENE_PATH:
			_validate_collection_viewport_layout(node, viewport_size, errors)
			await _validate_collection_viewport_text_stress(node, viewport_size, errors)


func _validate_critical_runtime_viewport_state(scene_path: String, node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	match scene_path:
		GAMEPLAY_SCENE_PATH:
			await _validate_gameplay_mobile_viewport_matrix(node, viewport_size, errors)
		STAGE_SELECT_SCENE_PATH:
			await _validate_stage_popup_mobile_viewport_matrix(node, viewport_size, errors)


func _validate_main_viewport_layout(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var game_home_layer := node.get_node_or_null("GameHomeLayer") as CanvasItem
	if game_home_layer != null and not game_home_layer.visible:
		errors.append("%s GameHomeLayer should remain visible at %s." % [MAIN_SCENE_PATH, viewport_size])
	_validate_control_in_viewport(node.find_child("HomePlayButton", true, false), viewport_size, MAIN_SCENE_PATH, "HomePlayButton", errors)
	_validate_control_in_viewport(node.find_child("BottomNav", true, false), viewport_size, MAIN_SCENE_PATH, "BottomNav", errors)
	_validate_control_in_viewport(node.find_child("HomeMapButton", true, false), viewport_size, MAIN_SCENE_PATH, "HomeMapButton", errors)
	_validate_control_in_viewport(node.find_child("HomeCollectionButton", true, false), viewport_size, MAIN_SCENE_PATH, "HomeCollectionButton", errors)
	_validate_control_in_viewport(node.find_child("HomeSettingsButton", true, false), viewport_size, MAIN_SCENE_PATH, "HomeSettingsButton", errors)


func _validate_main_viewport_text_stress(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var hero_stack := node.get_node_or_null("GameHomeLayer/HeroStack") as Control
	var status_label := _get_control_property_or_child(node, "home_status_label", "HomeStatusLabel") as Label
	var subtitle_label := _get_control_property_or_child(node, "home_subtitle_label", "HomeSubtitleLabel") as Label
	var play_button := _get_control_property_or_child(node, "home_play_button", "HomePlayButton") as Button
	var map_button := node.find_child("HomeMapButton", true, false) as Button
	var collection_button := node.find_child("HomeCollectionButton", true, false) as Button
	var settings_button := node.find_child("HomeSettingsButton", true, false) as Button
	var original_status := "" if status_label == null else status_label.text
	var original_subtitle := "" if subtitle_label == null else subtitle_label.text
	var original_play := "" if play_button == null else play_button.text
	var original_map := "" if map_button == null else map_button.text
	var original_collection := "" if collection_button == null else collection_button.text
	var original_settings := "" if settings_button == null else settings_button.text
	if status_label != null:
		status_label.text = "%s · Lv.999 해금 100/100 별 999" % CRITICAL_TEXT_STRESS_BODY
	if subtitle_label != null:
		subtitle_label.text = "%s · HOME" % CRITICAL_TEXT_STRESS_TITLE
	if play_button != null:
		play_button.text = "PLAY"
	if map_button != null:
		map_button.text = "월드맵"
	if collection_button != null:
		collection_button.text = "구조도감"
	if settings_button != null:
		settings_button.text = "설정"
	await process_frame
	for control_info in [[status_label, "HomeStatusLabel"], [subtitle_label, "HomeSubtitleLabel"], [play_button, "HomePlayButton"], [map_button, "HomeMapButton"], [collection_button, "HomeCollectionButton"], [settings_button, "HomeSettingsButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		if control != null and control.is_visible_in_tree():
			_validate_control_in_viewport(control, viewport_size, MAIN_SCENE_PATH, "%s text stress" % label, errors)
			if hero_stack != null and [status_label, subtitle_label, play_button].has(control):
				_validate_control_inside_container(control, hero_stack, MAIN_SCENE_PATH, "%s text stress" % label, errors)
	if status_label != null and play_button != null:
		_validate_no_vertical_overlap(play_button, status_label, MAIN_SCENE_PATH, "HomePlayButton to HomeStatusLabel text stress", errors)
	if subtitle_label != null and play_button != null:
		_validate_no_vertical_overlap(subtitle_label, play_button, MAIN_SCENE_PATH, "HomeSubtitleLabel to HomePlayButton text stress", errors)
	if status_label != null:
		status_label.text = original_status
	if subtitle_label != null:
		subtitle_label.text = original_subtitle
	if play_button != null:
		play_button.text = original_play
	if map_button != null:
		map_button.text = original_map
	if collection_button != null:
		collection_button.text = original_collection
	if settings_button != null:
		settings_button.text = original_settings
	await _validate_main_event_detail_text_stress(node, viewport_size, errors)


func _validate_main_event_detail_text_stress(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var overlay := node.get_node_or_null("EventDetailOverlay") as Control
	if overlay == null:
		return
	var panel := overlay.find_child("OverlayPanel", true, false) as Control
	var header := overlay.find_child("EventDetailHeader", true, false) as Control
	var title_label := overlay.find_child("EventDetailTitleLabel", true, false) as Label
	var body_label := overlay.find_child("EventDetailBodyLabel", true, false) as Label
	var close_button := overlay.find_child("EventDetailCloseButton", true, false) as Button
	var claim_button := overlay.find_child("EventClaimButton", true, false) as Button
	var original_visible := overlay.visible
	var original_title := "" if title_label == null else title_label.text
	var original_body := "" if body_label == null else body_label.text
	var original_close := "" if close_button == null else close_button.text
	var original_claim := "" if claim_button == null else claim_button.text
	overlay.visible = true
	if title_label != null:
		title_label.text = "%s · 홈 이벤트 보상" % CRITICAL_TEXT_STRESS_TITLE
	if body_label != null:
		body_label.text = "%s\n%s\n%s" % [CRITICAL_TEXT_STRESS_BODY, "남은 시간 99:59:59 · 보상 골드 999 · 토큰 99", "SuperLongRewardDescriptionToken"]
	if close_button != null:
		close_button.text = "닫기"
	if claim_button != null:
		claim_button.text = "보상 받기"
	await process_frame
	_validate_control_in_viewport(panel, viewport_size, MAIN_SCENE_PATH, "EventDetailPanel text stress", errors)
	for control_info in [[title_label, "EventDetailTitleLabel"], [body_label, "EventDetailBodyLabel"], [close_button, "EventDetailCloseButton"], [claim_button, "EventClaimButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		if control != null and control.is_visible_in_tree():
			_validate_control_in_viewport(control, viewport_size, MAIN_SCENE_PATH, "%s text stress" % label, errors)
			if panel != null:
				_validate_control_inside_container(control, panel, MAIN_SCENE_PATH, "%s text stress" % label, errors)
	if header != null:
		_validate_control_inside_container(title_label, header, MAIN_SCENE_PATH, "EventDetailTitleLabel header text stress", errors)
		_validate_control_inside_container(close_button, header, MAIN_SCENE_PATH, "EventDetailCloseButton header text stress", errors)
	_validate_no_rect_overlap(title_label, close_button, MAIN_SCENE_PATH, "EventDetailTitleLabel to close text stress", errors)
	_validate_no_vertical_overlap(body_label, claim_button, MAIN_SCENE_PATH, "EventDetailBodyLabel to claim CTA text stress", errors)
	if title_label != null:
		title_label.text = original_title
	if body_label != null:
		body_label.text = original_body
	if close_button != null:
		close_button.text = original_close
	if claim_button != null:
		claim_button.text = original_claim
	overlay.visible = original_visible


func _get_control_property_or_child(node: Node, property_name: String, child_name: String) -> Control:
	var property_value: Variant = node.get(property_name)
	if property_value is Control:
		return property_value
	return node.find_child(child_name, true, false) as Control


func _validate_stage_select_viewport_layout(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var stage_world_layer := node.get_node_or_null("StageWorldLayer") as CanvasItem
	if stage_world_layer != null and not stage_world_layer.visible:
		errors.append("%s StageWorldLayer should remain visible at %s." % [STAGE_SELECT_SCENE_PATH, viewport_size])
	_validate_control_in_viewport(node.find_child("WorldPlayButton", true, false), viewport_size, STAGE_SELECT_SCENE_PATH, "WorldPlayButton", errors)
	var world_path_root := node.get_node_or_null("StageWorldLayer/WorldMapPathRoot")
	if world_path_root != null:
		var visible_world_nodes := 0
		for world_node in world_path_root.find_children("WorldStageNode*", "Button", true, false):
			var world_control := world_node as Control
			if world_control != null and world_control.visible:
				visible_world_nodes += 1
				_validate_control_in_viewport(world_control, viewport_size, STAGE_SELECT_SCENE_PATH, String(world_control.name), errors)
		if visible_world_nodes != 10:
			errors.append("%s expected 10 visible world stage nodes at %s, got %d." % [STAGE_SELECT_SCENE_PATH, viewport_size, visible_world_nodes])


func _validate_stage_popup_mobile_viewport_matrix(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	if not node.has_method("_show_stage_popup"):
		return
	node.call("_show_stage_popup", 4)
	await create_timer(0.22).timeout
	await _refresh_node_layout_for_viewport(node)
	var panel := node.get("stage_popup_panel") as Control
	var title_label := node.get("stage_popup_title_label") as Control
	var goal_label := node.get("stage_popup_goal_label") as Control
	var meta_label := node.get("stage_popup_meta_label") as Control
	var reward_label := node.get("stage_popup_reward_label") as Control
	var buddy_label := node.get("stage_popup_buddy_label") as Control
	var start_button := _find_button_with_text(panel, "PLAY")
	var close_button := _find_button_with_text(node, "×")
	_validate_control_in_viewport(panel, viewport_size, STAGE_SELECT_SCENE_PATH, "Stage 4 mobile matrix StagePopupPanel", errors)
	for control_info in [
		[title_label, "StagePopupTitle"],
		[goal_label, "StagePopupGoal"],
		[meta_label, "StagePopupMeta"],
		[reward_label, "StagePopupReward"],
		[buddy_label, "StagePopupBuddy"],
		[start_button, "StagePopupStartButton"],
		[close_button, "StagePopupCloseButton"],
	]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_in_viewport(control, viewport_size, STAGE_SELECT_SCENE_PATH, "Stage 4 mobile matrix %s" % label, errors)
		if panel != null and control != null and control != panel:
			_validate_control_inside_container(control, panel, STAGE_SELECT_SCENE_PATH, "Stage 4 mobile matrix %s" % label, errors)
	_validate_no_vertical_overlap(buddy_label, start_button, STAGE_SELECT_SCENE_PATH, "Stage 4 mobile matrix Buddy to PLAY", errors)
	var booster_buttons: Dictionary = Dictionary(node.get("stage_popup_booster_buttons"))
	for booster_id in ["rainbow_paw", "striped", "bomb"]:
		var booster_button := booster_buttons.get(booster_id) as Control
		_validate_control_in_viewport(booster_button, viewport_size, STAGE_SELECT_SCENE_PATH, "Stage 4 mobile matrix booster %s" % booster_id, errors)
		if panel != null and booster_button != null:
			_validate_control_inside_container(booster_button, panel, STAGE_SELECT_SCENE_PATH, "Stage 4 mobile matrix booster %s" % booster_id, errors)


func _validate_gameplay_viewport_layout(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var portrait := viewport_size.y >= viewport_size.x
	var board_frame := node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control
	_validate_control_in_viewport(board_frame, viewport_size, GAMEPLAY_SCENE_PATH, "BoardFrame", errors)
	if board_frame != null:
		var board_rect := board_frame.get_global_rect()
		var min_expected_board_side: float = min(float(viewport_size.x), float(viewport_size.y)) * 0.46
		if board_rect.size.x < min_expected_board_side or board_rect.size.y < min_expected_board_side:
			errors.append("%s BoardFrame is too small at %s: %s, expected each side >= %.1f." % [GAMEPLAY_SCENE_PATH, viewport_size, board_rect.size, min_expected_board_side])
	if portrait:
		_validate_control_in_viewport(node.find_child("HudGoalDock", true, false), viewport_size, GAMEPLAY_SCENE_PATH, "HudGoalDock", errors)
		_validate_control_in_viewport(node.find_child("HudBoosterDock", true, false), viewport_size, GAMEPLAY_SCENE_PATH, "HudBoosterDock", errors)
	else:
		_validate_control_in_viewport(node.find_child("StatsCard", true, false), viewport_size, GAMEPLAY_SCENE_PATH, "StatsCard landscape", errors)
		_validate_control_in_viewport(node.find_child("GoalCard", true, false), viewport_size, GAMEPLAY_SCENE_PATH, "GoalCard landscape", errors)
	if node.find_child("HudBuddyGauge", true, false) == null:
		errors.append("%s missing responsive layout target HudBuddyGauge at %s." % [GAMEPLAY_SCENE_PATH, viewport_size])


func _validate_gameplay_mobile_viewport_matrix(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	if not node.has_method("_start_stage") or not node.has_method("_check_stage_state"):
		return
	var portrait := viewport_size.y >= viewport_size.x
	if portrait:
		node.call("_start_stage", 3)
		await _refresh_node_layout_for_viewport(node)
		_validate_gameplay_hud_clearance(node, viewport_size, "Stage 4 mobile matrix", errors)

	_prepare_stage_25_near_miss_failure(node)
	await node.call("_check_stage_state")
	await _refresh_node_layout_for_viewport(node)
	_validate_failure_overlay_viewport_clearance(node, viewport_size, "Stage 25 mobile matrix", errors)

	node.call("_start_stage", 0)
	await _refresh_node_layout_for_viewport(node)


func _validate_gameplay_hud_clearance(node: Node, viewport_size: Vector2i, context: String, errors: PackedStringArray) -> void:
	var board_frame := node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control
	var goal_dock := node.find_child("HudGoalDock", true, false) as Control
	var booster_dock := node.find_child("HudBoosterDock", true, false) as Control
	var buddy_gauge := node.find_child("HudBuddyGauge", true, false) as Control
	var portrait_summary := node.find_child("PortraitGoalSummary", true, false) as Control
	for control_info in [[board_frame, "BoardFrame"], [goal_dock, "HudGoalDock"], [booster_dock, "HudBoosterDock"], [buddy_gauge, "HudBuddyGauge"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_in_viewport(control, viewport_size, GAMEPLAY_SCENE_PATH, "%s %s" % [context, label], errors)
	if portrait_summary != null and portrait_summary.is_visible_in_tree():
		_validate_control_in_viewport(portrait_summary, viewport_size, GAMEPLAY_SCENE_PATH, "%s PortraitGoalSummary" % context, errors)
	if goal_dock == null or booster_dock == null or board_frame == null:
		return
	if goal_dock.is_visible_in_tree() and board_frame.is_visible_in_tree() and goal_dock.get_global_rect().intersects(board_frame.get_global_rect()):
		errors.append("%s %s should keep HudGoalDock clear of BoardFrame at %s." % [GAMEPLAY_SCENE_PATH, context, viewport_size])
	if booster_dock.is_visible_in_tree() and board_frame.is_visible_in_tree() and booster_dock.get_global_rect().intersects(board_frame.get_global_rect()):
		errors.append("%s %s should keep HudBoosterDock clear of BoardFrame at %s." % [GAMEPLAY_SCENE_PATH, context, viewport_size])


func _validate_failure_overlay_viewport_clearance(node: Node, viewport_size: Vector2i, context: String, errors: PackedStringArray) -> void:
	var panel := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel") as Control
	var title := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayTitle") as Control
	var body := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Control
	var primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Control
	var secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Control
	for control_info in [[panel, "OverlayPanel"], [title, "OverlayTitle"], [body, "OverlayBody"], [primary, "OverlayPrimaryButton"], [secondary, "OverlaySecondaryButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		_validate_control_in_viewport(control, viewport_size, GAMEPLAY_SCENE_PATH, "%s %s" % [context, label], errors)
		if panel != null and control != null and control != panel:
			_validate_control_inside_container(control, panel, GAMEPLAY_SCENE_PATH, "%s %s" % [context, label], errors)
	_validate_no_vertical_overlap(body, primary, GAMEPLAY_SCENE_PATH, "%s OverlayBody to primary CTA" % context, errors)
	_validate_no_vertical_overlap(body, secondary, GAMEPLAY_SCENE_PATH, "%s OverlayBody to secondary CTA" % context, errors)


func _validate_collection_viewport_layout(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	_validate_control_in_viewport(node.find_child("SummaryLabel", true, false), viewport_size, COLLECTION_SCENE_PATH, "SummaryLabel", errors)
	var collection_grid := node.find_child("CollectionGrid", true, false) as GridContainer
	if collection_grid == null:
		errors.append("%s missing responsive layout target CollectionGrid at %s." % [COLLECTION_SCENE_PATH, viewport_size])


func _validate_collection_viewport_text_stress(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var header := node.find_child("HeaderRow", true, false) as Control
	var summary := node.find_child("SummaryLabel", true, false) as Label
	var detail := node.find_child("DetailLabel", true, false) as Label
	var back_button := node.find_child("BackButton", true, false) as Button
	var grid := node.find_child("CollectionGrid", true, false) as GridContainer
	var original_summary := "" if summary == null else summary.text
	var original_detail := "" if detail == null else detail.text
	var original_back := "" if back_button == null else back_button.text
	if summary != null:
		summary.text = "해금 100 / 100 · 최고 Stage 100 · %s" % CRITICAL_TEXT_STRESS_TITLE
	if detail != null:
		detail.text = "%s · Rescue Book detail line" % CRITICAL_TEXT_STRESS_BODY
	if back_button != null:
		back_button.text = "홈"
	await process_frame
	for control_info in [[header, "HeaderRow"], [summary, "SummaryLabel"], [detail, "DetailLabel"], [back_button, "BackButton"], [grid, "CollectionGrid"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		if control != null and control.is_visible_in_tree():
			_validate_control_in_viewport(control, viewport_size, COLLECTION_SCENE_PATH, "%s text stress" % label, errors)
	if header != null:
		for control_info in [[summary, "SummaryLabel"], [back_button, "BackButton"]]:
			var child_control := control_info[0] as Control
			var child_label := String(control_info[1])
			if child_control != null and child_control.is_visible_in_tree():
				_validate_control_inside_container(child_control, header, COLLECTION_SCENE_PATH, "%s text stress" % child_label, errors)
	if summary != null and detail != null:
		_validate_no_vertical_overlap(summary, detail, COLLECTION_SCENE_PATH, "SummaryLabel to DetailLabel text stress", errors)
	if detail != null and grid != null:
		_validate_no_vertical_overlap(detail, grid, COLLECTION_SCENE_PATH, "DetailLabel to CollectionGrid text stress", errors)
	await _validate_collection_card_text_stress(node, viewport_size, errors)
	if summary != null:
		summary.text = original_summary
	if detail != null:
		detail.text = original_detail
	if back_button != null:
		back_button.text = original_back


func _validate_collection_card_text_stress(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var card := _first_collection_card(node)
	if card == null and node.has_method("_refresh_cards"):
		node.call("_refresh_cards")
		await process_frame
		card = _first_collection_card(node)
	if card == null:
		return
	var preview := card.find_child("AnimalPreview", true, false) as Control
	var name_label := card.find_child("AnimalNameLabel", true, false) as Label
	var status_label := card.find_child("AnimalStatusLabel", true, false) as Label
	var cosmetic_label := card.find_child("AnimalCosmeticLabel", true, false) as Label
	var original_name := "" if name_label == null else name_label.text
	var original_status := "" if status_label == null else status_label.text
	var original_cosmetic := "" if cosmetic_label == null else cosmetic_label.text
	if name_label != null:
		name_label.text = "%s · Friend" % CRITICAL_TEXT_STRESS_TITLE
	if status_label != null:
		status_label.text = "Lv.99 · 토큰 999 · NEW · %s" % CRITICAL_TEXT_STRESS_BODY
	if cosmetic_label != null:
		cosmetic_label.text = "코스메틱: SuperLongCosmeticToken · rescue_hat_gold_variant"
	await process_frame
	_validate_control_in_viewport(card, viewport_size, COLLECTION_SCENE_PATH, "AnimalCard text stress", errors)
	for control_info in [[preview, "AnimalPreview"], [name_label, "AnimalNameLabel"], [status_label, "AnimalStatusLabel"], [cosmetic_label, "AnimalCosmeticLabel"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		if control != null and control.is_visible_in_tree():
			_validate_control_inside_container(control, card, COLLECTION_SCENE_PATH, "%s text stress" % label, errors)
	_validate_no_vertical_overlap(preview, name_label, COLLECTION_SCENE_PATH, "AnimalPreview to AnimalNameLabel text stress", errors)
	_validate_no_vertical_overlap(name_label, status_label, COLLECTION_SCENE_PATH, "AnimalNameLabel to AnimalStatusLabel text stress", errors)
	_validate_no_vertical_overlap(status_label, cosmetic_label, COLLECTION_SCENE_PATH, "AnimalStatusLabel to AnimalCosmeticLabel text stress", errors)
	if name_label != null:
		name_label.text = original_name
	if status_label != null:
		status_label.text = original_status
	if cosmetic_label != null:
		cosmetic_label.text = original_cosmetic


func _first_collection_card(node: Node) -> PanelContainer:
	var grid := node.find_child("CollectionGrid", true, false) as GridContainer
	if grid == null:
		return null
	for candidate in grid.get_children():
		var card := candidate as PanelContainer
		if card != null and String(card.name).begins_with("AnimalCard_"):
			return card
	return null


func _validate_control_in_viewport(candidate: Node, viewport_size: Vector2i, scene_path: String, label: String, errors: PackedStringArray) -> void:
	if not (candidate is Control):
		errors.append("%s missing responsive layout target %s at %s." % [scene_path, label, viewport_size])
		return
	var control := candidate as Control
	if not control.is_visible_in_tree():
		errors.append("%s %s should be visible at %s." % [scene_path, label, viewport_size])
		return
	var rect := control.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		errors.append("%s %s has empty layout rect at %s." % [scene_path, label, viewport_size])
		return
	var relaxed_rect := viewport_rect.grow(8.0)
	if not relaxed_rect.encloses(rect):
		errors.append("%s %s is clipped at %s: %s outside %s." % [scene_path, label, viewport_size, rect, viewport_rect])


func _validate_control_inside_container(control: Control, container: Control, scene_path: String, label: String, errors: PackedStringArray) -> void:
	if control == null or container == null:
		return
	if not control.is_visible_in_tree() or not container.is_visible_in_tree():
		return
	var control_rect := control.get_global_rect()
	var container_rect := container.get_global_rect().grow(8.0)
	if not container_rect.encloses(control_rect):
		errors.append("%s critical text stress clipped/overflowed: %s rect %s outside parent %s." % [scene_path, label, control_rect, container_rect])


func _validate_no_vertical_overlap(upper: Control, lower: Control, scene_path: String, label: String, errors: PackedStringArray) -> void:
	if upper == null or lower == null:
		return
	if not upper.is_visible_in_tree() or not lower.is_visible_in_tree():
		return
	var upper_rect := upper.get_global_rect()
	var lower_rect := lower.get_global_rect()
	if upper_rect.end.y > lower_rect.position.y + 2.0:
		errors.append("%s critical text stress overlapped: %s upper %s lower %s." % [scene_path, label, upper_rect, lower_rect])


func _validate_no_rect_overlap(first: Control, second: Control, scene_path: String, label: String, errors: PackedStringArray) -> void:
	if first == null or second == null:
		return
	if not first.is_visible_in_tree() or not second.is_visible_in_tree():
		return
	var first_rect := first.get_global_rect()
	var second_rect := second.get_global_rect()
	if first_rect.intersects(second_rect):
		errors.append("%s critical text stress overlapped: %s first %s second %s." % [scene_path, label, first_rect, second_rect])


func _validate_button_pressed_connection(candidate: Node, receiver: Object, method_name: String, scene_path: String, label: String, errors: PackedStringArray) -> void:
	if not (candidate is Button):
		errors.append("%s missing CTA button %s for pressed signal wiring." % [scene_path, label])
		return
	var button := candidate as Button
	if not _button_pressed_connects_to_method(button, receiver, method_name):
		errors.append("%s CTA button %s pressed signal should connect to %s, got [%s]." % [scene_path, label, method_name, _button_pressed_connection_summary(button)])


func _button_pressed_connects_to_method(button: Button, receiver: Object, method_name: String) -> bool:
	if button == null or receiver == null:
		return false
	var exact_callable := Callable(receiver, method_name)
	if button.pressed.is_connected(exact_callable):
		return true
	for connection in button.get_signal_connection_list(&"pressed"):
		if not (connection is Dictionary):
			continue
		var callable_value = Dictionary(connection).get("callable", Callable())
		if callable_value is Callable:
			var connected_callable: Callable = callable_value
			if connected_callable.get_object() == receiver and String(connected_callable.get_method()) == method_name:
				return true
	return false


func _button_pressed_connection_summary(button: Button) -> String:
	if button == null:
		return "missing"
	var parts: Array[String] = []
	for connection in button.get_signal_connection_list(&"pressed"):
		if not (connection is Dictionary):
			continue
		var callable_value = Dictionary(connection).get("callable", Callable())
		if callable_value is Callable:
			var connected_callable: Callable = callable_value
			parts.append(String(connected_callable.get_method()))
	if parts.is_empty():
		return "none"
	return ", ".join(parts)


func _validate_runtime_analytics_events(errors: PackedStringArray) -> void:
	var events := GameSession.get_analytics_events()
	var gateway_events := AnalyticsGateway.get_dispatched_events_for_testing()
	if gateway_events.size() < events.size():
		errors.append("AnalyticsGateway should receive each saved analytics event, got %d dispatched for %d saved." % [gateway_events.size(), events.size()])
	var seen_names := {}
	var live_event_placements_seen := {}
	var remote_config_keys_seen := {}
	var validated_gateway_signatures := {}
	var live_events_by_id := _live_events_by_id()
	for event in events:
		if not (event is Dictionary):
			errors.append("runtime analytics event should be a dictionary")
			continue
		var event_dict: Dictionary = event
		var event_name := String(event_dict.get("name", ""))
		var params := Dictionary(event_dict.get("params", {}))
		seen_names[event_name] = true
		_validate_analytics_gateway_dispatch_for_event(event_dict, events, gateway_events, validated_gateway_signatures, errors)
		var missing_params := GameSession.analytics_event_missing_required_params(event_name, params)
		if not missing_params.is_empty():
			errors.append("runtime analytics event %s missing required params: %s" % [event_name, ", ".join(Array(missing_params))])
		match event_name:
			"live_event_impression":
				_validate_live_event_impression_payload(params, live_events_by_id, errors)
				live_event_placements_seen[String(params.get("placement", ""))] = true
			"remote_config_exposure":
				_validate_remote_config_exposure_payload(params, errors)
				remote_config_keys_seen[String(params.get("config_key", ""))] = true
	for required_event in ["rescue_book_open", "animal_unlock", "animal_token_gain", "animal_friendship_level_up", "animal_cosmetic_equip", "stage_start", "special_combo_trigger", "remote_config_exposure", "event_join", "event_progress", "event_reward_claim", "buddy_skill_charge", "buddy_skill_ready", "buddy_skill_trigger", "buddy_skill_blocked", "fail_offer_show", "fail_offer_select", "fail_offer_dismiss", "ad_reward_complete", "ad_reward_fail", "iap_purchase_start", "iap_purchase_complete", "iap_purchase_restore", "iap_purchase_cancel", "iap_purchase_fail", "extra_moves_grant"]:
		if not seen_names.has(required_event):
			errors.append("runtime analytics should emit %s during scene smoke." % required_event)
	for placement in IMPLEMENTED_LIVE_EVENT_PLACEMENTS:
		if not live_event_placements_seen.has(placement):
			errors.append("runtime analytics should emit live_event_impression for %s placement." % placement)
	for config_key in LiveEventService.REMOTE_CONFIG_EXPOSURE_KEYS:
		if not remote_config_keys_seen.has(config_key):
			errors.append("runtime analytics should emit remote_config_exposure for %s." % config_key)
	var active_current_live_events := false
	for placement in ["home", "collection", "stage_select"]:
		if not LiveEventService.active_events_for(GameSession.get_highest_unlocked_stage_id(), placement).is_empty():
			active_current_live_events = true
	if active_current_live_events and not seen_names.has("live_event_impression"):
		errors.append("runtime analytics should emit live_event_impression when active live events are visible.")


func _validate_analytics_gateway_dispatch_for_event(event_dict: Dictionary, saved_events: Array, gateway_events: Array, validated_signatures: Dictionary, errors: PackedStringArray) -> void:
	var event_name := String(event_dict.get("name", ""))
	var params := Dictionary(event_dict.get("params", {}))
	var session_id := String(params.get("session_id", ""))
	var event_timestamp := int(event_dict.get("timestamp", -1))
	var signature_key := "%s|%d|%s" % [event_name, event_timestamp, JSON.stringify(params)]
	if validated_signatures.has(signature_key):
		return
	validated_signatures[signature_key] = true

	var matching_gateway_events: Array = []
	for gateway_event_value in gateway_events:
		if not (gateway_event_value is Dictionary):
			continue
		var gateway_event: Dictionary = gateway_event_value
		var gateway_params: Dictionary = Dictionary(gateway_event.get("params", {}))
		if String(gateway_event.get("name", "")) != event_name:
			continue
		if String(gateway_params.get("session_id", "")) != session_id:
			continue
		if int(gateway_event.get("timestamp", -2)) != event_timestamp:
			continue
		if gateway_params != params:
			continue
		matching_gateway_events.append(gateway_event)
	var saved_signature_count := _analytics_event_signature_count(saved_events, event_name, event_timestamp, params)
	if matching_gateway_events.is_empty():
		errors.append("AnalyticsGateway should dispatch runtime analytics event %s for session %s." % [event_name, session_id])
		return
	if matching_gateway_events.size() != saved_signature_count:
		errors.append("AnalyticsGateway should mirror runtime analytics event %s signature count, got %d queued for %d saved." % [event_name, matching_gateway_events.size(), saved_signature_count])
	var gateway_event: Dictionary = matching_gateway_events[0]
	if String(gateway_event.get("provider_id", "")) != AnalyticsGateway.DEFAULT_PROVIDER_ID:
		errors.append("AnalyticsGateway dispatch for %s should use default provider id before SDK selection." % event_name)
	if String(gateway_event.get("dispatch_status", "")) != "queued":
		errors.append("AnalyticsGateway dispatch for %s should remain queued for provider adapter." % event_name)


func _analytics_event_signature_count(events: Array, event_name: String, event_timestamp: int, params: Dictionary) -> int:
	var count := 0
	for event_value in events:
		if not (event_value is Dictionary):
			continue
		var event_dict: Dictionary = event_value
		if String(event_dict.get("name", "")) != event_name:
			continue
		if int(event_dict.get("timestamp", -2)) != event_timestamp:
			continue
		if Dictionary(event_dict.get("params", {})) != params:
			continue
		count += 1
	return count


func _validate_analytics_gateway_contract_gate(errors: PackedStringArray) -> void:
	# The runtime analytics smoke above intentionally fills the local-buffer queue.
	# Isolate the contract/flush checks so provider persistence assertions are not
	# coupled to unrelated scene-smoke event volume or aborted prior runs.
	AnalyticsGateway.reset_for_testing()
	AnalyticsGateway.clear_persisted_queue_for_testing()
	var saved_before := GameSession.get_analytics_events().size()
	var dispatched_before := AnalyticsGateway.get_dispatched_events_for_testing().size()
	var rejected_before := AnalyticsGateway.get_rejected_events_for_testing().size()

	AnalyticsGateway.set_provider_id_for_testing("validation_sdk")
	AnalyticsGateway.set_dispatch_enabled_for_testing(true)
	GameSession.record_analytics_event("stage_start", {
		"stage_id": 999,
		"band": "validation",
		"roster_group": "validation",
		"moves": 1,
	})
	var saved_after_provider := GameSession.get_analytics_events()
	var dispatched_after_provider := AnalyticsGateway.get_dispatched_events_for_testing()
	if saved_after_provider.size() != saved_before + 1:
		errors.append("AnalyticsGateway validation should keep local save when provider override is active.")
	if dispatched_after_provider.size() != dispatched_before + 1:
		errors.append("AnalyticsGateway validation provider override should queue exactly one event.")
	elif not saved_after_provider.is_empty():
		_validate_gateway_event_matches_saved_event(
			Dictionary(saved_after_provider[saved_after_provider.size() - 1]),
			Dictionary(dispatched_after_provider[dispatched_after_provider.size() - 1]),
			"validation_sdk",
			"queued",
			"provider override",
			errors
		)
	if AnalyticsGateway.get_rejected_events_for_testing().size() != rejected_before:
		errors.append("AnalyticsGateway provider override should not reject a valid event.")
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	var reloaded_after_provider := AnalyticsGateway.get_dispatched_events_for_testing()
	if reloaded_after_provider.size() != dispatched_after_provider.size():
		errors.append("AnalyticsGateway local_buffer queue should survive a disk reload.")
	elif not saved_after_provider.is_empty():
		_validate_gateway_event_matches_saved_event(
			Dictionary(saved_after_provider[saved_after_provider.size() - 1]),
			Dictionary(reloaded_after_provider[reloaded_after_provider.size() - 1]),
			"validation_sdk",
			"queued",
			"persistent local queue",
			errors
		)
	var dispatched_after_reload := AnalyticsGateway.get_dispatched_events_for_testing()

	AnalyticsGateway.set_dispatch_enabled_for_testing(false)
	GameSession.record_analytics_event("stage_start", {
		"stage_id": 1000,
		"band": "validation",
		"roster_group": "validation",
		"moves": 1,
	})
	var saved_after_disabled := GameSession.get_analytics_events()
	var dispatched_after_disabled := AnalyticsGateway.get_dispatched_events_for_testing()
	if saved_after_disabled.size() != saved_after_provider.size() + 1:
		errors.append("AnalyticsGateway disabled dispatch should still preserve local analytics save.")
	if dispatched_after_disabled.size() != dispatched_after_reload.size():
		errors.append("AnalyticsGateway disabled dispatch should not queue provider events.")
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	var reloaded_after_disabled := AnalyticsGateway.get_dispatched_events_for_testing()
	if reloaded_after_disabled.size() != dispatched_after_reload.size():
		errors.append("AnalyticsGateway disabled dispatch should not persist provider events.")

	AnalyticsGateway.set_dispatch_enabled_for_testing(true)
	var rejected_before_invalid := AnalyticsGateway.get_rejected_events_for_testing().size()
	var dispatched_before_invalid := AnalyticsGateway.get_dispatched_events_for_testing().size()
	GameSession.record_analytics_event("stage_start", {"stage_id": 1001})
	var saved_after_invalid := GameSession.get_analytics_events()
	var rejected_after_invalid := AnalyticsGateway.get_rejected_events_for_testing()
	if saved_after_invalid.size() != saved_after_disabled.size() + 1:
		errors.append("AnalyticsGateway contract rejection should still preserve invalid local analytics save for debugging.")
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != dispatched_before_invalid:
		errors.append("AnalyticsGateway contract rejection should not queue missing-param events.")
	if rejected_after_invalid.size() != rejected_before_invalid + 1:
		errors.append("AnalyticsGateway contract rejection should record missing-param rejection.")
	elif not saved_after_invalid.is_empty():
		var rejection_event := Dictionary(rejected_after_invalid[rejected_after_invalid.size() - 1])
		_validate_gateway_event_matches_saved_event(
			Dictionary(saved_after_invalid[saved_after_invalid.size() - 1]),
			rejection_event,
			"validation_sdk",
			"rejected_contract",
			"missing-param rejection",
			errors
		)
		_validate_gateway_rejection_reasons(rejection_event, PackedStringArray(["band", "roster_group", "moves"]), "missing-param rejection", errors)
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != dispatched_before_invalid:
		errors.append("AnalyticsGateway contract rejection should not persist missing-param events.")

	var rejected_before_unknown := AnalyticsGateway.get_rejected_events_for_testing().size()
	var dispatched_before_unknown := AnalyticsGateway.get_dispatched_events_for_testing().size()
	GameSession.record_analytics_event("__unknown_validation_event", {"foo": "bar"})
	var saved_after_unknown := GameSession.get_analytics_events()
	var rejected_after_unknown := AnalyticsGateway.get_rejected_events_for_testing()
	if saved_after_unknown.size() != saved_after_invalid.size() + 1:
		errors.append("AnalyticsGateway unknown-event rejection should still preserve local analytics save for debugging.")
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != dispatched_before_unknown:
		errors.append("AnalyticsGateway contract rejection should not queue unknown events.")
	if rejected_after_unknown.size() != rejected_before_unknown + 1:
		errors.append("AnalyticsGateway contract rejection should record unknown-event rejection.")
	elif not saved_after_unknown.is_empty():
		var rejection_event := Dictionary(rejected_after_unknown[rejected_after_unknown.size() - 1])
		_validate_gateway_event_matches_saved_event(
			Dictionary(saved_after_unknown[saved_after_unknown.size() - 1]),
			rejection_event,
			"validation_sdk",
			"rejected_contract",
			"unknown-event rejection",
			errors
		)
		_validate_gateway_rejection_reasons(rejection_event, PackedStringArray(["__unknown_event__"]), "unknown-event rejection", errors)
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != dispatched_before_unknown:
		errors.append("AnalyticsGateway contract rejection should not persist unknown events.")

	GameSession.record_analytics_event("stage_start", {
		"stage_id": 1002,
		"band": "validation",
		"roster_group": "validation",
		"moves": 1,
	})
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	var queued_before_flush := AnalyticsGateway.get_dispatched_events_for_testing()
	var rejected_before_flush := AnalyticsGateway.get_rejected_events_for_testing().size()
	var failed_flush_events := AnalyticsGateway.flush_queued_events(Callable(self, "_mutate_and_reject_gateway_flush_event"), 1)
	if not failed_flush_events.is_empty():
		errors.append("AnalyticsGateway failed provider callback should not report sent events.")
	_validate_gateway_queue_matches(queued_before_flush, AnalyticsGateway.get_dispatched_events_for_testing(), "failed flush memory", errors)
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	_validate_gateway_queue_matches(queued_before_flush, AnalyticsGateway.get_dispatched_events_for_testing(), "failed flush disk reload", errors)

	var first_flushed_events := AnalyticsGateway.flush_queued_events(Callable(), 1)
	if first_flushed_events.size() != min(1, queued_before_flush.size()):
		errors.append("AnalyticsGateway partial flush should send exactly one pending event.")
	var pending_after_partial_flush := AnalyticsGateway.get_dispatched_events_for_testing()
	if pending_after_partial_flush.size() != max(queued_before_flush.size() - 1, 0):
		errors.append("AnalyticsGateway partial flush should remove only the sent event from pending queue.")
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != pending_after_partial_flush.size():
		errors.append("AnalyticsGateway partial flush result should persist after disk reload.")
	var remaining_flushed_events := AnalyticsGateway.flush_queued_events()
	var flushed_events := first_flushed_events.duplicate(true)
	flushed_events.append_array(remaining_flushed_events)
	if flushed_events.size() != queued_before_flush.size():
		errors.append("AnalyticsGateway flush should send every pending local_buffer event once, got %d for %d queued." % [flushed_events.size(), queued_before_flush.size()])
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != 0:
		errors.append("AnalyticsGateway flush should remove sent events from the pending local_buffer queue.")
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != 0:
		errors.append("AnalyticsGateway flushed local_buffer queue should stay empty after disk reload.")
	if AnalyticsGateway.flush_queued_events().size() != 0:
		errors.append("AnalyticsGateway second flush should not resend already flushed events.")
	if AnalyticsGateway.get_rejected_events_for_testing().size() != rejected_before_flush:
		errors.append("AnalyticsGateway flush should not mutate rejected contract events.")
	_validate_gateway_flush_order(queued_before_flush, flushed_events, errors)
	_validate_analytics_gateway_corrupt_queue_tolerance(errors)
	_validate_analytics_gateway_bounded_queue(errors)
	_validate_analytics_gateway_flush_adapter(errors)

	AnalyticsGateway.set_provider_id_for_testing(AnalyticsGateway.DEFAULT_PROVIDER_ID)
	AnalyticsGateway.set_dispatch_enabled_for_testing(true)


func _validate_gateway_event_matches_saved_event(saved_event: Dictionary, gateway_event: Dictionary, expected_provider_id: String, expected_status: String, context: String, errors: PackedStringArray) -> void:
	var saved_name := String(saved_event.get("name", ""))
	var gateway_name := String(gateway_event.get("name", ""))
	if gateway_name != saved_name:
		errors.append("AnalyticsGateway %s should preserve event name %s, got %s." % [context, saved_name, gateway_name])
	if int(gateway_event.get("timestamp", -2)) != int(saved_event.get("timestamp", -1)):
		errors.append("AnalyticsGateway %s should preserve event timestamp for %s." % [context, saved_name])
	var saved_params := Dictionary(saved_event.get("params", {}))
	var gateway_params := Dictionary(gateway_event.get("params", {}))
	if not _analytics_values_equivalent(gateway_params, saved_params):
		errors.append("AnalyticsGateway %s should preserve params for %s." % [context, saved_name])
	if String(gateway_event.get("provider_id", "")) != expected_provider_id:
		errors.append("AnalyticsGateway %s should use provider %s for %s." % [context, expected_provider_id, saved_name])
	if String(gateway_event.get("dispatch_status", "")) != expected_status:
		errors.append("AnalyticsGateway %s should mark %s as %s." % [context, saved_name, expected_status])


func _validate_gateway_rejection_reasons(gateway_event: Dictionary, expected_reasons: PackedStringArray, context: String, errors: PackedStringArray) -> void:
	var reasons := Array(gateway_event.get("rejection_reasons", []))
	for expected_reason in expected_reasons:
		if not reasons.has(expected_reason):
			errors.append("AnalyticsGateway %s should include rejection reason %s." % [context, expected_reason])


func _validate_gateway_flush_order(queued_events: Array, flushed_events: Array, errors: PackedStringArray) -> void:
	if queued_events.size() != flushed_events.size():
		return
	for index in range(queued_events.size()):
		var queued_event := Dictionary(queued_events[index])
		var flushed_event := Dictionary(flushed_events[index])
		if String(flushed_event.get("dispatch_status", "")) != "sent":
			errors.append("AnalyticsGateway flushed event %d should be marked sent." % index)
		var queued_snapshot := queued_event.duplicate(true)
		var flushed_snapshot := flushed_event.duplicate(true)
		queued_snapshot.erase("dispatch_status")
		flushed_snapshot.erase("dispatch_status")
		if not _analytics_values_equivalent(flushed_snapshot, queued_snapshot):
			errors.append("AnalyticsGateway flush should preserve queued event order and payload at index %d." % index)


func _validate_gateway_queue_matches(expected_events: Array, actual_events: Array, context: String, errors: PackedStringArray) -> void:
	if actual_events.size() != expected_events.size():
		errors.append("AnalyticsGateway %s should preserve pending queue size, got %d for %d." % [context, actual_events.size(), expected_events.size()])
		return
	for index in range(expected_events.size()):
		if not _analytics_values_equivalent(Dictionary(actual_events[index]), Dictionary(expected_events[index])):
			errors.append("AnalyticsGateway %s should preserve pending event at index %d." % [context, index])


func _mutate_and_reject_gateway_flush_event(event: Dictionary) -> bool:
	event["name"] = "__mutated_gateway_validation_event"
	var params := Dictionary(event.get("params", {}))
	params["stage_id"] = -999
	event["params"] = params
	return false


func _analytics_flush_adapter_accept_first(event: Dictionary) -> Dictionary:
	analytics_flush_adapter_requests.append(event.duplicate(true))
	var params := Dictionary(event.get("params", {}))
	params["stage_id"] = -999
	event["params"] = params
	return {"accepted": analytics_flush_adapter_requests.size() == 1}


func _validate_analytics_gateway_corrupt_queue_tolerance(errors: PackedStringArray) -> void:
	AnalyticsGateway.clear_persisted_queue_for_testing()
	_write_validation_analytics_queue("{not valid json")
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != 0:
		errors.append("AnalyticsGateway should ignore corrupt local_buffer queue files without replaying stale events.")
	AnalyticsGateway.clear_persisted_queue_for_testing()


func _validate_analytics_gateway_bounded_queue(errors: PackedStringArray) -> void:
	AnalyticsGateway.clear_persisted_queue_for_testing()
	AnalyticsGateway.set_provider_id_for_testing("bounded_validation_sdk")
	for index in range(AnalyticsGateway.MAX_DISPATCHED_EVENTS + 1):
		var event_entry := {
			"name": "stage_start",
			"timestamp": 1700000000 + index,
			"params": {
				"session_id": "bounded_validation",
				"stage_id": index,
				"band": "validation",
				"roster_group": "validation",
				"moves": 1,
			},
		}
		AnalyticsGateway.dispatch_event(event_entry)
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	var bounded_events := AnalyticsGateway.get_dispatched_events_for_testing()
	if bounded_events.size() != AnalyticsGateway.MAX_DISPATCHED_EVENTS:
		errors.append("AnalyticsGateway persisted local_buffer queue should stay bounded at %d events." % AnalyticsGateway.MAX_DISPATCHED_EVENTS)
	elif not bounded_events.is_empty():
		var first_event := Dictionary(bounded_events[0])
		var first_params := Dictionary(first_event.get("params", {}))
		if int(first_params.get("stage_id", -1)) != 1:
			errors.append("AnalyticsGateway bounded local_buffer queue should evict the oldest event first.")
		var last_event := Dictionary(bounded_events[bounded_events.size() - 1])
		var last_params := Dictionary(last_event.get("params", {}))
		if int(last_params.get("stage_id", -1)) != AnalyticsGateway.MAX_DISPATCHED_EVENTS:
			errors.append("AnalyticsGateway bounded local_buffer queue should preserve the newest event.")
	AnalyticsGateway.clear_persisted_queue_for_testing()
	AnalyticsGateway.set_provider_id_for_testing("validation_sdk")


func _validate_analytics_gateway_flush_adapter(errors: PackedStringArray) -> void:
	AnalyticsGateway.reset_for_testing()
	AnalyticsGateway.clear_persisted_queue_for_testing()
	analytics_flush_adapter_requests.clear()
	AnalyticsGateway.configure_flush_adapter("adapter_validation_sdk", Callable(self, "_analytics_flush_adapter_accept_first"))
	var rejected_before_adapter := AnalyticsGateway.get_rejected_events_for_testing().size()
	for index in range(3):
		AnalyticsGateway.dispatch_event({
			"name": "stage_start",
			"timestamp": 1800000000 + index,
			"params": {
				"session_id": "adapter_validation",
				"stage_id": 2000 + index,
				"band": "validation",
				"roster_group": "validation",
				"moves": 1,
			},
		})
	var queued_before_adapter := AnalyticsGateway.get_dispatched_events_for_testing()
	var adapter_sent_events := AnalyticsGateway.flush_queued_events()
	if analytics_flush_adapter_requests.size() != 2:
		errors.append("AnalyticsGateway flush adapter should stop after the first rejected provider event, got %d adapter calls." % analytics_flush_adapter_requests.size())
	if adapter_sent_events.size() != 1:
		errors.append("AnalyticsGateway flush adapter should report exactly one accepted sent event.")
	elif String(Dictionary(adapter_sent_events[0]).get("dispatch_status", "")) != "sent":
		errors.append("AnalyticsGateway flush adapter should return accepted events with sent status.")
	var pending_after_adapter := AnalyticsGateway.get_dispatched_events_for_testing()
	if pending_after_adapter.size() != 2:
		errors.append("AnalyticsGateway flush adapter should leave rejected and unattempted events pending, got %d." % pending_after_adapter.size())
	elif queued_before_adapter.size() >= 3:
		if not _analytics_values_equivalent(Dictionary(pending_after_adapter[0]), Dictionary(queued_before_adapter[1])):
			errors.append("AnalyticsGateway flush adapter should preserve the rejected event payload after adapter mutation.")
		if not _analytics_values_equivalent(Dictionary(pending_after_adapter[1]), Dictionary(queued_before_adapter[2])):
			errors.append("AnalyticsGateway flush adapter should preserve the unattempted event payload after adapter mutation.")
	if not analytics_flush_adapter_requests.is_empty():
		var first_request := Dictionary(analytics_flush_adapter_requests[0])
		if String(first_request.get("provider_id", "")) != "adapter_validation_sdk" or String(first_request.get("dispatch_status", "")) != "sent":
			errors.append("AnalyticsGateway flush adapter should receive deep-copied sent event payload with adapter provider metadata.")
		var first_request_params := Dictionary(first_request.get("params", {}))
		if int(first_request_params.get("stage_id", 0)) != 2000:
			errors.append("AnalyticsGateway flush adapter should receive FIFO event params before mutation.")
	if AnalyticsGateway.get_rejected_events_for_testing().size() != rejected_before_adapter:
		errors.append("AnalyticsGateway flush adapter should not mutate rejected_contract events.")
	AnalyticsGateway.reload_queue_from_disk_for_testing()
	if AnalyticsGateway.get_dispatched_events_for_testing().size() != pending_after_adapter.size():
		errors.append("AnalyticsGateway flush adapter pending queue should persist after disk reload.")
	AnalyticsGateway.clear_flush_adapter_for_testing()
	var remaining_sent := AnalyticsGateway.flush_queued_events()
	if remaining_sent.size() != pending_after_adapter.size() or AnalyticsGateway.get_dispatched_events_for_testing().size() != 0:
		errors.append("AnalyticsGateway flush adapter cleanup should allow remaining local_buffer events to flush once.")
	AnalyticsGateway.clear_persisted_queue_for_testing()
	AnalyticsGateway.reset_for_testing()


func _write_validation_analytics_queue(raw_json: String) -> void:
	DirAccess.make_dir_recursive_absolute("user://")
	var file := FileAccess.open(validation_analytics_queue_path, FileAccess.WRITE)
	if file != null:
		file.store_string(raw_json)


func _analytics_values_equivalent(left, right) -> bool:
	if _analytics_value_is_number(left) and _analytics_value_is_number(right):
		return is_equal_approx(float(left), float(right))
	if left is Dictionary and right is Dictionary:
		var left_dict: Dictionary = left
		var right_dict: Dictionary = right
		if left_dict.size() != right_dict.size():
			return false
		for key in left_dict.keys():
			if not right_dict.has(key):
				return false
			if not _analytics_values_equivalent(left_dict[key], right_dict[key]):
				return false
		return true
	if left is Array and right is Array:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return false
		for index in range(left_array.size()):
			if not _analytics_values_equivalent(left_array[index], right_array[index]):
				return false
		return true
	return left == right


func _analytics_value_is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _last_analytics_event_by_name(event_name: String) -> Dictionary:
	var events := GameSession.get_analytics_events()
	for index in range(events.size() - 1, -1, -1):
		var event = events[index]
		if event is Dictionary and String(Dictionary(event).get("name", "")) == event_name:
			return Dictionary(event)
	return {}


func _analytics_event_count(event_name: String) -> int:
	var count := 0
	for event in GameSession.get_analytics_events():
		if event is Dictionary and String(Dictionary(event).get("name", "")) == event_name:
			count += 1
	return count


func _rescue_book_token_count(animal_id: String) -> int:
	var animals := Dictionary(GameSession.get_rescue_book_state().get("animals", {}))
	return int(Dictionary(animals.get(animal_id, {})).get("tokens", 0))


func _validation_save_data() -> Dictionary:
	if not FileAccess.file_exists(SESSION_VALIDATION_SAVE_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SESSION_VALIDATION_SAVE_PATH))
	if parsed is Dictionary:
		return Dictionary(parsed)
	return {}


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


func _last_monetization_request_log() -> Dictionary:
	var logs := MonetizationGateway.get_request_log_for_testing()
	if logs.is_empty():
		return {}
	var last_log = logs[logs.size() - 1]
	return Dictionary(last_log) if last_log is Dictionary else {}


func _validate_monetization_request_log(log_entry: Dictionary, expected_source: String, expected_stage_id: int, expected_fail_type: String, expected_result: String, expected_status: String, expected_provider_id: String, errors: PackedStringArray) -> void:
	if log_entry.is_empty():
		errors.append("MonetizationGateway should record provider-neutral request logs.")
		return
	if String(log_entry.get("source", "")) != expected_source:
		errors.append("MonetizationGateway request log should preserve source %s." % expected_source)
	if int(log_entry.get("stage_id", 0)) != expected_stage_id:
		errors.append("MonetizationGateway request log should preserve stage_id %d." % expected_stage_id)
	if String(log_entry.get("fail_type", "")) != expected_fail_type:
		errors.append("MonetizationGateway request log should preserve fail_type %s." % expected_fail_type)
	if String(log_entry.get("result", "")) != expected_result:
		errors.append("MonetizationGateway request log should preserve result %s." % expected_result)
	if String(log_entry.get("request_status", "")) != expected_status:
		errors.append("MonetizationGateway request log should preserve request_status %s." % expected_status)
	if String(log_entry.get("provider_id", "")) != expected_provider_id:
		errors.append("MonetizationGateway request log should preserve provider_id %s." % expected_provider_id)


func _monetization_adapter_pending_response(request: Dictionary) -> Dictionary:
	monetization_adapter_requests.append(request.duplicate(true))
	var details_value = request.get("details", {})
	if details_value is Dictionary:
		var request_details: Dictionary = details_value
		request_details["transaction_id"] = "mutated-request-transaction"
	request["fail_offer"] = {"type": "mutated_by_adapter"}
	return {
		"result": MonetizationGateway.RESULT_PENDING,
		"details": {
			"ad_network": "adapter_validation",
			"transaction_id": "adapter-pending-validation",
		},
	}


func _monetization_adapter_success_alias_response(request: Dictionary) -> Dictionary:
	monetization_adapter_requests.append(request.duplicate(true))
	return {
		"result": "success",
		"details": {
			"ad_network": "adapter_success_alias",
			"transaction_id": "adapter-success-alias-validation",
		},
	}


func _monetization_adapter_cancelled_alias_response(request: Dictionary) -> Dictionary:
	monetization_adapter_requests.append(request.duplicate(true))
	return {
		"result": "cancelled",
		"details": {
			"ad_network": "adapter_cancelled_alias",
			"error_code": "user_cancelled",
			"transaction_id": "adapter-cancelled-alias-validation",
		},
	}


func _monetization_adapter_in_progress_alias_response(request: Dictionary) -> Dictionary:
	monetization_adapter_requests.append(request.duplicate(true))
	return {
		"result": "in_progress",
		"details": {
			"ad_network": "adapter_pending_alias",
			"transaction_id": "adapter-in-progress-alias-validation",
		},
	}


func _monetization_adapter_unknown_response(request: Dictionary) -> Dictionary:
	monetization_adapter_requests.append(request.duplicate(true))
	return {
		"result": "sdk_weird_state",
		"details": {
			"ad_network": "adapter_unknown_alias",
			"error_code": "sdk_weird_state",
			"transaction_id": "adapter-unknown-alias-validation",
		},
	}


func _validate_monetization_adapter_alias_result(fail_offer: Dictionary, provider_id: String, adapter: Callable, expected_result: String, expected_details: Dictionary, context: String, errors: PackedStringArray) -> void:
	MonetizationGateway.reset_for_testing()
	monetization_adapter_requests.clear()
	MonetizationGateway.configure_continue_adapter(provider_id, adapter)
	var gateway_result := MonetizationGateway.request_continue("rewarded_ad", 25, fail_offer, {"transaction_id": "%s-request-detail" % context})
	if monetization_adapter_requests.size() != 1:
		errors.append("MonetizationGateway %s should invoke the continue adapter exactly once." % context)
	if String(gateway_result.get("result", "")) != expected_result:
		errors.append("MonetizationGateway %s should canonicalize provider result to %s, got %s." % [context, expected_result, String(gateway_result.get("result", ""))])
	var details := Dictionary(gateway_result.get("details", {}))
	for key in expected_details.keys():
		if not _analytics_values_equivalent(details.get(key), expected_details[key]):
			errors.append("MonetizationGateway %s should preserve detail %s=%s." % [context, String(key), str(expected_details[key])])
	var gateway_log := _last_monetization_request_log()
	_validate_monetization_request_log(gateway_log, "rewarded_ad", 25, "near_miss", expected_result, "resolved", provider_id, errors)
	MonetizationGateway.reset_for_testing()


func _live_events_by_id() -> Dictionary:
	var by_id := {}
	for event in LiveEventService.load_events():
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		var event_id := String(event_dict.get("id", ""))
		if not event_id.is_empty():
			by_id[event_id] = event_dict
	return by_id


func _live_event_by_id(event_id: String) -> Dictionary:
	return Dictionary(_live_events_by_id().get(event_id, {}))


func _validate_live_event_impression_payload(params: Dictionary, live_events_by_id: Dictionary, errors: PackedStringArray) -> void:
	var event_id := String(params.get("event_id", ""))
	var event_type := String(params.get("event_type", ""))
	var placement := String(params.get("placement", ""))
	if event_id.is_empty():
		errors.append("live_event_impression should not have an empty event_id.")
	if event_type.is_empty():
		errors.append("live_event_impression should not have an empty event_type.")
	if not IMPLEMENTED_LIVE_EVENT_PLACEMENTS.has(placement):
		errors.append("live_event_impression has unsupported placement %s." % placement)
	if not live_events_by_id.has(event_id):
		errors.append("live_event_impression references unknown event_id %s." % event_id)
		return
	var config_event: Dictionary = live_events_by_id[event_id]
	if String(config_event.get("type", "")) != event_type:
		errors.append("live_event_impression %s type mismatch: %s vs %s." % [event_id, event_type, String(config_event.get("type", ""))])
	if not Array(config_event.get("placements", [])).has(placement):
		errors.append("live_event_impression %s placement %s is not in event config." % [event_id, placement])


func _validate_remote_config_exposure_payload(params: Dictionary, errors: PackedStringArray) -> void:
	var config_key := String(params.get("config_key", ""))
	var variant_id := String(params.get("variant_id", ""))
	var config_value_hash := String(params.get("config_value_hash", ""))
	if config_key.is_empty():
		errors.append("remote_config_exposure should not have an empty config_key.")
	if variant_id.is_empty():
		errors.append("remote_config_exposure should not have an empty variant_id.")
	if config_value_hash.is_empty():
		errors.append("remote_config_exposure should not have an empty config_value_hash.")
	if not LiveEventService.REMOTE_CONFIG_EXPOSURE_KEYS.has(config_key):
		errors.append("remote_config_exposure has unsupported config_key %s." % config_key)


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

	var animal_strip := node.find_child("AnimalStrip", true, false) as HBoxContainer
	if animal_strip == null:
		errors.append("%s is missing the 12-animal home preview strip." % MAIN_SCENE_PATH)
	elif animal_strip.get_child_count() < ANIMAL_IDS.size():
		errors.append("%s AnimalStrip should show all %d board animals, got %d." % [MAIN_SCENE_PATH, ANIMAL_IDS.size(), animal_strip.get_child_count()])
	if node.find_child("LiveEventStrip", true, false) == null:
		errors.append("%s is missing LiveEventStrip for live ops surface checks." % MAIN_SCENE_PATH)
	_validate_main_cta_signal_wiring(node, errors)
	_validate_main_event_detail_overlay(node, errors)


func _validate_main_cta_signal_wiring(node: Node, errors: PackedStringArray) -> void:
	_validate_button_pressed_connection(_get_control_property_or_child(node, "home_play_button", "HomePlayButton"), node, "_on_play_button_pressed", MAIN_SCENE_PATH, "HomePlayButton", errors)
	_validate_button_pressed_connection(node.find_child("HomeMapButton", true, false), node, "_on_stage_button_pressed", MAIN_SCENE_PATH, "HomeMapButton", errors)
	_validate_button_pressed_connection(node.find_child("HomeCollectionButton", true, false), node, "_on_ranking_button_pressed", MAIN_SCENE_PATH, "HomeCollectionButton", errors)
	_validate_button_pressed_connection(node.find_child("HomeSettingsButton", true, false), node, "_on_settings_button_pressed", MAIN_SCENE_PATH, "HomeSettingsButton", errors)
	_validate_button_pressed_connection(node.find_child("EventDetailCloseButton", true, false), node, "_on_event_detail_close_button_pressed", MAIN_SCENE_PATH, "EventDetailCloseButton", errors)
	_validate_button_pressed_connection(node.find_child("EventClaimButton", true, false), node, "_on_event_claim_button_pressed", MAIN_SCENE_PATH, "EventClaimButton", errors)


func _validate_main_event_detail_overlay(node: Node, errors: PackedStringArray) -> void:
	var overlay := node.get_node_or_null("EventDetailOverlay") as ColorRect
	if overlay == null:
		errors.append("%s is missing EventDetailOverlay for home live event details." % MAIN_SCENE_PATH)
		return
	if overlay.visible:
		errors.append("%s EventDetailOverlay should start hidden." % MAIN_SCENE_PATH)

	var title_label := overlay.find_child("EventDetailTitleLabel", true, false) as Label
	if title_label == null:
		errors.append("%s EventDetailOverlay is missing EventDetailTitleLabel." % MAIN_SCENE_PATH)
	var body_label := overlay.find_child("EventDetailBodyLabel", true, false) as Label
	if body_label == null:
		errors.append("%s EventDetailOverlay is missing EventDetailBodyLabel." % MAIN_SCENE_PATH)
	var claim_button := overlay.find_child("EventClaimButton", true, false) as Button
	if claim_button == null:
		errors.append("%s EventDetailOverlay is missing EventClaimButton." % MAIN_SCENE_PATH)

	if not node.has_method("_show_event_detail") or not node.has_method("_on_event_claim_button_pressed"):
		errors.append("%s should expose home live event detail and claim handlers." % MAIN_SCENE_PATH)
		return

	var validation_event_id := "__validation_home_event"
	node.call("_show_event_detail", {
		"id": validation_event_id,
		"type": "daily_reward",
		"title": "검증 라이브 이벤트",
		"enabled": true,
		"unlock_stage": 1,
		"placements": ["home"],
		"reward": {
			"gold": 5,
		},
	})
	if not overlay.visible:
		errors.append("%s EventDetailOverlay should become visible after a home event chip is opened." % MAIN_SCENE_PATH)
	if title_label != null and title_label.text != "검증 라이브 이벤트":
		errors.append("%s EventDetailTitleLabel should reflect the selected event title." % MAIN_SCENE_PATH)
	if body_label != null and body_label.text.is_empty():
		errors.append("%s EventDetailBodyLabel should describe the selected event." % MAIN_SCENE_PATH)
	if claim_button != null and claim_button.disabled:
		errors.append("%s EventClaimButton should be enabled for a claimable reward." % MAIN_SCENE_PATH)

	node.call("_on_event_claim_button_pressed")
	if claim_button != null:
		if not claim_button.disabled:
			errors.append("%s EventClaimButton should disable after successful reward claim." % MAIN_SCENE_PATH)
		if claim_button.text != "수령 완료":
			errors.append("%s EventClaimButton should show claimed state after reward claim." % MAIN_SCENE_PATH)

	node.call("_show_event_detail", {
		"id": "__validation_ended_event",
		"type": "daily_reward",
		"title": "종료 검증 이벤트",
		"enabled": true,
		"status": "ended",
		"unlock_stage": 1,
		"placements": ["home"],
		"reward": {
			"gold": 5,
		},
	})
	if body_label != null:
		if not body_label.text.contains("종료됨"):
			errors.append("%s EventDetailBodyLabel should expose ended live event status." % MAIN_SCENE_PATH)
		if body_label.text.contains("참여 가능"):
			errors.append("%s EventDetailBodyLabel should not describe ended live events as claimable." % MAIN_SCENE_PATH)
	if claim_button != null:
		if not claim_button.disabled:
			errors.append("%s EventClaimButton should disable ended live event rewards." % MAIN_SCENE_PATH)
		if claim_button.text != "종료됨":
			errors.append("%s EventClaimButton should explain ended live event rewards." % MAIN_SCENE_PATH)

	if node.has_method("_make_home_event_chip"):
		var offline_chip = node.call("_make_home_event_chip", {
			"id": "__validation_offline_event",
			"type": "daily_reward",
			"title": "오프라인 검증",
			"enabled": true,
			"status": "offline",
			"unlock_stage": 1,
			"placements": ["home"],
		}) as Button
		if offline_chip == null or not offline_chip.text.contains("오프라인"):
			errors.append("%s home live event chip should expose offline status text." % MAIN_SCENE_PATH)
		if offline_chip != null:
			offline_chip.queue_free()
	if node.has_method("_track_live_event_impression"):
		node.call("_track_live_event_impression", _live_event_by_id("daily_reward_v1"), "home")


func _validate_main_settings_runtime(node: Node, errors: PackedStringArray) -> void:
	_validate_main_home_preview_expression_runtime(node, errors)

	for method_name in ["_on_settings_button_pressed", "_on_sound_toggle_button_pressed", "_on_haptics_toggle_button_pressed", "_on_settings_overlay_close_button_pressed"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for settings smoke validation." % [MAIN_SCENE_PATH, method_name])
			return

	var original_sound := GameSession.get_sound_enabled()
	var original_haptics := GameSession.get_haptics_enabled()
	GameSession.set_sound_enabled(true)
	GameSession.set_haptics_enabled(true)
	GameSession.apply_feedback_preferences()
	var feedback := root.get_node_or_null("Feedback")
	if feedback == null:
		errors.append("%s settings smoke should find the Feedback autoload." % MAIN_SCENE_PATH)
		return
	if not bool(feedback.get("sound_enabled")) or not bool(feedback.get("haptics_enabled")):
		errors.append("%s settings smoke should apply initial sound/haptics ON state to Feedback." % MAIN_SCENE_PATH)

	node.call("_on_settings_button_pressed")
	var settings_overlay := node.get_node_or_null("SettingsOverlay") as CanvasItem
	if settings_overlay == null or not settings_overlay.visible:
		errors.append("%s settings smoke should open SettingsOverlay." % MAIN_SCENE_PATH)

	node.call("_on_sound_toggle_button_pressed")
	var sound_toggle_button := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsButtons/SoundToggleButton") as Button
	if GameSession.get_sound_enabled() or bool(feedback.get("sound_enabled")):
		errors.append("%s sound toggle should persist OFF and apply it to Feedback." % MAIN_SCENE_PATH)
	if sound_toggle_button == null or sound_toggle_button.text != "사운드: OFF":
		errors.append("%s sound toggle button should show 사운드: OFF after disabling." % MAIN_SCENE_PATH)

	node.call("_on_haptics_toggle_button_pressed")
	var haptics_toggle_button := node.get_node_or_null("SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsButtons/HapticsToggleButton") as Button
	if GameSession.get_haptics_enabled() or bool(feedback.get("haptics_enabled")):
		errors.append("%s haptics toggle should persist OFF and apply it to Feedback." % MAIN_SCENE_PATH)
	if haptics_toggle_button == null or haptics_toggle_button.text != "햅틱: OFF":
		errors.append("%s haptics toggle button should show 햅틱: OFF after disabling." % MAIN_SCENE_PATH)

	node.call("_on_settings_overlay_close_button_pressed")
	if settings_overlay != null and settings_overlay.visible:
		errors.append("%s settings close should hide SettingsOverlay." % MAIN_SCENE_PATH)

	GameSession.set_sound_enabled(original_sound)
	GameSession.set_haptics_enabled(original_haptics)
	GameSession.apply_feedback_preferences()


func _validate_main_home_preview_expression_runtime(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_home_animations", "_home_preview_expression_count_for_testing", "_home_preview_expression_ids_for_testing", "_home_preview_expression_states_for_testing", "_home_mascot_expression_states_for_testing"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for home preview expression smoke validation." % [MAIN_SCENE_PATH, method_name])
			return

	node.call("_start_home_animations")
	var mascot_states: Dictionary = Dictionary(node.call("_home_mascot_expression_states_for_testing"))
	if String(mascot_states.get("rabbit", "")) != "smile":
		errors.append("%s RabbitHero should expose smile fallback expression after home animation start." % MAIN_SCENE_PATH)
	if String(mascot_states.get("chick", "")) != "blink":
		errors.append("%s ChickHero should expose blink fallback expression after home animation start." % MAIN_SCENE_PATH)
	var active_count := int(node.call("_home_preview_expression_count_for_testing"))
	if active_count <= 0:
		errors.append("%s home preview expression smoke should animate at least one animal token." % MAIN_SCENE_PATH)
	elif active_count > 4:
		errors.append("%s home preview expression smoke should cap active animal token tweens at 4, got %d." % [MAIN_SCENE_PATH, active_count])
	var active_ids: Array = Array(node.call("_home_preview_expression_ids_for_testing"))
	if active_ids.size() != active_count:
		errors.append("%s home preview expression smoke should track active ids for every active tween." % MAIN_SCENE_PATH)
	var states: Dictionary = Dictionary(node.call("_home_preview_expression_states_for_testing"))
	for animal_id_value in active_ids:
		var animal_id := String(animal_id_value)
		var expression_state := String(states.get(animal_id, ""))
		if not ["idle", "blink", "smile"].has(expression_state):
			errors.append("%s home preview %s should expose idle/blink/smile fallback state, got %s." % [MAIN_SCENE_PATH, animal_id, expression_state])


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
	if node.has_method("_result_overlay_live_event_line_for_event"):
		var result_line := String(node.call("_result_overlay_live_event_line_for_event", {
			"id": "__validation_result_event",
			"type": "daily_reward",
			"title": "결과 검증",
			"enabled": true,
			"status": "offline",
			"unlock_stage": 1,
			"placements": ["result_overlay"],
		}))
		if not result_line.contains("오프라인"):
			errors.append("%s result overlay live event line should expose offline status text." % GAMEPLAY_SCENE_PATH)

	var juice_layer := node.get_node_or_null("GameplayJuiceLayer") as CanvasItem
	if juice_layer == null:
		errors.append("%s is missing the top-level gameplay juice layer." % GAMEPLAY_SCENE_PATH)
	var intro_label := node.get_node_or_null("GameplayJuiceLayer/StageIntroLabel") as Label
	if intro_label == null:
		errors.append("%s is missing the READY/GO stage intro label." % GAMEPLAY_SCENE_PATH)

	var gameplay_hud_layer := node.get_node_or_null("GameplayHudLayer") as CanvasItem
	if gameplay_hud_layer == null:
		errors.append("%s is missing the compact GameplayHudLayer." % GAMEPLAY_SCENE_PATH)
	elif node.find_child("HudGoalDock", true, false) == null:
		errors.append("%s GameplayHudLayer is missing the goal dock." % GAMEPLAY_SCENE_PATH)
	elif node.find_child("HudBoosterDock", true, false) == null:
		errors.append("%s GameplayHudLayer is missing the bottom booster dock." % GAMEPLAY_SCENE_PATH)
	elif node.find_child("HudBuddyGauge", true, false) == null:
		errors.append("%s GameplayHudLayer is missing the Rescue Buddy charge gauge." % GAMEPLAY_SCENE_PATH)

	_validate_gameplay_cta_signal_wiring(node, errors)
	_validate_special_effect_rules(node, errors)
	_validate_expression_animation_rules(node, errors)
	_validate_rescue_buddy_runtime_rules(node, errors)
	_validate_start_booster_runtime_rules(node, errors)


func _validate_gameplay_cta_signal_wiring(node: Node, errors: PackedStringArray) -> void:
	_validate_button_pressed_connection(node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton"), node, "_on_overlay_primary_button_pressed", GAMEPLAY_SCENE_PATH, "OverlayPrimaryButton", errors)
	_validate_button_pressed_connection(node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton"), node, "_on_overlay_secondary_button_pressed", GAMEPLAY_SCENE_PATH, "OverlaySecondaryButton", errors)
	_validate_button_pressed_connection(node.get("hud_home_button") as Button, node, "_on_quit_button_pressed", GAMEPLAY_SCENE_PATH, "HudHomeButton", errors)
	_validate_button_pressed_connection(node.get("hud_retry_button") as Button, node, "_on_retry_button_pressed", GAMEPLAY_SCENE_PATH, "HudRetryButton", errors)
	_validate_button_pressed_connection(node.get("hud_pause_button") as Button, node, "_on_pause_button_pressed", GAMEPLAY_SCENE_PATH, "HudPauseButton", errors)
	_validate_button_pressed_connection(node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/TopBar/PauseButton"), node, "_on_pause_button_pressed", GAMEPLAY_SCENE_PATH, "TopBarPauseButton", errors)


func _validate_fx_layer_scene(node: Node, errors: PackedStringArray) -> void:
	for root_name in ["BoardFxRoot", "HudFxRoot", "ScreenFxRoot"]:
		if node.get_node_or_null(root_name) == null:
			errors.append("%s is missing %s." % [FX_LAYER_SCENE_PATH, root_name])
	for method_name in ["play_match_burst_at", "play_special_created", "play_special_combo", "play_combo_banner", "play_goal_rescue", "play_blocker_clear_at", "play_last_moves_warning", "play_bonus_score", "play_rainbow_clear"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for gameplay VFX calls." % [FX_LAYER_SCENE_PATH, method_name])


func _validate_fx_layer_runtime(node: Node, errors: PackedStringArray) -> void:
	if not node.has_method("play_special_combo"):
		return
	var board_root := node.get_node_or_null("BoardFxRoot")
	var hud_root := node.get_node_or_null("HudFxRoot")
	var screen_root := node.get_node_or_null("ScreenFxRoot")
	if board_root == null or hud_root == null or screen_root == null:
		return

	await _validate_fx_special_combo_variant_labels(node, board_root, errors)

	node.call("play_special_combo", Vector2(180, 180), Vector2(280, 180), "row", "col")
	node.call("play_match_burst_at", Vector2(220, 260), 2)
	node.call("play_special_created", Vector2(340, 220), "bomb")
	node.call("play_combo_banner", 3)
	node.call("play_goal_rescue", Vector2(500, 180), "목표 완료!")
	node.call("play_blocker_clear_at", Vector2(560, 260), 2)
	node.call("play_last_moves_warning", 2)
	node.call("play_bonus_score", Vector2(460, 300), 750)
	node.call("play_rainbow_clear", [Vector2(160, 360), Vector2(220, 360), Vector2(280, 360), Vector2(340, 360), Vector2(400, 360)])
	await process_frame
	await create_timer(0.04).timeout
	if node.find_child("SpecialComboFlash", true, false) == null:
		errors.append("%s play_special_combo should spawn SpecialComboFlash." % FX_LAYER_SCENE_PATH)
	if node.find_child("SpecialComboRing", true, false) == null:
		errors.append("%s play_special_combo should spawn SpecialComboRing." % FX_LAYER_SCENE_PATH)
	if node.find_child("SpecialComboLabel", true, false) == null:
		errors.append("%s play_special_combo should spawn SpecialComboLabel." % FX_LAYER_SCENE_PATH)
	else:
		var special_combo_label := node.find_child("SpecialComboLabel", true, false) as Label
		if special_combo_label == null or special_combo_label.text != "크로스!":
			errors.append("%s play_special_combo should label row+column as 크로스!, got %s." % [FX_LAYER_SCENE_PATH, special_combo_label.text if special_combo_label != null else "<missing>"])
	if node.find_child("GoalRescueLabel", true, false) == null:
		errors.append("%s play_goal_rescue should spawn GoalRescueLabel." % FX_LAYER_SCENE_PATH)
	if node.find_child("BlockerClearRing", true, false) == null:
		errors.append("%s play_blocker_clear_at should spawn BlockerClearRing." % FX_LAYER_SCENE_PATH)
	if node.find_child("BlockerClearLabel", true, false) == null:
		errors.append("%s play_blocker_clear_at should spawn BlockerClearLabel." % FX_LAYER_SCENE_PATH)
	if node.find_child("RainbowFlash", true, false) == null:
		errors.append("%s play_rainbow_clear should spawn RainbowFlash." % FX_LAYER_SCENE_PATH)
	if board_root.get_child_count() > 14:
		errors.append("%s BoardFxRoot should keep simultaneous no-device VFX children <= 14, got %d." % [FX_LAYER_SCENE_PATH, board_root.get_child_count()])
	if hud_root.get_child_count() > 4:
		errors.append("%s HudFxRoot should keep simultaneous no-device VFX children <= 4, got %d." % [FX_LAYER_SCENE_PATH, hud_root.get_child_count()])
	if screen_root.get_child_count() > 6:
		errors.append("%s ScreenFxRoot should keep simultaneous no-device VFX children <= 6, got %d." % [FX_LAYER_SCENE_PATH, screen_root.get_child_count()])
	await create_timer(1.1).timeout
	if board_root.get_child_count() != 0 or hud_root.get_child_count() != 0 or screen_root.get_child_count() != 0:
		errors.append("%s VFX smoke should clean up transient child nodes, got board=%d hud=%d screen=%d." % [FX_LAYER_SCENE_PATH, board_root.get_child_count(), hud_root.get_child_count(), screen_root.get_child_count()])


func _validate_fx_special_combo_variant_labels(node: Node, board_root: Node, errors: PackedStringArray) -> void:
	var variants: Array = [
		{"from": "row", "to": "col", "text": "크로스!", "echo": false},
		{"from": "row", "to": "row", "text": "가로 러시!", "echo": false},
		{"from": "col", "to": "col", "text": "세로 러시!", "echo": false},
		{"from": "row", "to": "bomb", "text": "가로 폭탄!", "echo": true},
		{"from": "col", "to": "bomb", "text": "세로 폭탄!", "echo": true},
		{"from": "bomb", "to": "bomb", "text": "더블 폭탄!", "echo": true},
	]
	for index in range(variants.size()):
		var variant: Dictionary = variants[index]
		node.call("play_special_combo", Vector2(180, 180 + index * 8), Vector2(280, 180 + index * 8), String(variant.get("from", "")), String(variant.get("to", "")))
		await process_frame
		await create_timer(0.04).timeout
		var special_combo_label := node.find_child("SpecialComboLabel", true, false) as Label
		if special_combo_label == null or special_combo_label.text != String(variant.get("text", "")):
			errors.append("%s play_special_combo should label %s+%s as %s, got %s." % [FX_LAYER_SCENE_PATH, String(variant.get("from", "")), String(variant.get("to", "")), String(variant.get("text", "")), special_combo_label.text if special_combo_label != null else "<missing>"])
		if node.find_child("SpecialComboFlash", true, false) == null:
			errors.append("%s play_special_combo should spawn a primary shaped flash for %s+%s." % [FX_LAYER_SCENE_PATH, String(variant.get("from", "")), String(variant.get("to", ""))])
		if bool(variant.get("echo", false)) and node.find_child("SpecialComboEchoRing", true, false) == null:
			errors.append("%s explosive special combos should spawn SpecialComboEchoRing for %s+%s." % [FX_LAYER_SCENE_PATH, String(variant.get("from", "")), String(variant.get("to", ""))])
		if board_root.get_child_count() > 6:
			errors.append("%s one play_special_combo call should keep BoardFxRoot children <= 6, got %d for %s+%s." % [FX_LAYER_SCENE_PATH, board_root.get_child_count(), String(variant.get("from", "")), String(variant.get("to", ""))])
		await create_timer(0.58).timeout
		if board_root.get_child_count() != 0:
			errors.append("%s play_special_combo %s+%s should clean up all board VFX children, got %d." % [FX_LAYER_SCENE_PATH, String(variant.get("from", "")), String(variant.get("to", "")), board_root.get_child_count()])


func _validate_expression_animation_rules(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_play_random_idle_blinks", "_active_visible_tiles", "_select_cell", "_clear_selection", "_set_tile_expression", "_update_hud", "_stage_collect_targets", "_piece_animal"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for expression QA smoke validation." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	var candidates: Array = node.call("_active_visible_tiles")
	if candidates.size() < 4:
		errors.append("%s expression QA expected at least four active visible tiles, got %d." % [GAMEPLAY_SCENE_PATH, candidates.size()])
		return

	var previous_busy := bool(node.get("is_busy"))
	var previous_stage_state := String(node.get("stage_state"))
	var previous_remaining_moves := int(node.get("remaining_moves"))
	var previous_moves_warning := int(node.get("_last_moves_warning"))
	var previous_worried_moves := int(node.get("_last_worried_moves"))
	var previous_collected_counts: Dictionary = Dictionary(node.get("collected_counts"))
	var overlay := node.get_node_or_null("Overlay") as CanvasItem
	var previous_overlay_visible := false
	if overlay != null:
		previous_overlay_visible = overlay.visible

	node.set("stage_state", "playing")
	node.set("is_busy", true)
	_clear_expression_states(candidates)
	node.call("_play_random_idle_blinks")
	if _count_tile_expression(candidates, "blink") > 0:
		errors.append("%s idle expression smoke should not start blinks while is_busy is true." % GAMEPLAY_SCENE_PATH)
	node.set("is_busy", false)

	if overlay != null:
		overlay.visible = true
		_clear_expression_states(candidates)
		node.call("_play_random_idle_blinks")
		if _count_tile_expression(candidates, "blink") > 0:
			errors.append("%s idle expression smoke should not start blinks while the result overlay is visible." % GAMEPLAY_SCENE_PATH)
		overlay.visible = false

	_clear_expression_states(candidates)
	node.call("_play_random_idle_blinks")
	var active_idle_expressions := _count_tile_expression(candidates, "blink")
	if active_idle_expressions <= 0:
		errors.append("%s idle expression smoke should start at least one blink." % GAMEPLAY_SCENE_PATH)
	elif active_idle_expressions > 4:
		errors.append("%s idle expression smoke should cap concurrent blink tiles at 4, got %d." % [GAMEPLAY_SCENE_PATH, active_idle_expressions])

	var smile_tile = candidates[0]
	var smile_cell := _cell_for_tile(node, smile_tile)
	if smile_cell == Vector2i(-1, -1):
		errors.append("%s expression QA could not map an active tile back to its board cell." % GAMEPLAY_SCENE_PATH)
	else:
		_clear_expression_states(candidates)
		node.call("_select_cell", smile_cell)
		if String(smile_tile.get("expression_state")) != "smile":
			errors.append("%s tile selection expression smoke should route smile through _select_cell." % GAMEPLAY_SCENE_PATH)
		node.call("_clear_selection")

	var priority_tile = candidates[1]
	var priority_cell := _cell_for_tile(node, priority_tile)
	if priority_cell == Vector2i(-1, -1):
		errors.append("%s expression QA could not map priority tile back to its board cell." % GAMEPLAY_SCENE_PATH)
	else:
		_clear_expression_states(candidates)
		node.call("_set_tile_expression", priority_cell, "match", true)
		for lower_priority_expression in ["blink", "smile", "worried"]:
			priority_tile.set_expression(lower_priority_expression)
			if String(priority_tile.get("expression_state")) != "match" or int(priority_tile.get("expression_priority")) != 3 or not bool(priority_tile.get("is_expression_locked")):
				errors.append("%s match expression priority should not be overwritten by %s." % [GAMEPLAY_SCENE_PATH, lower_priority_expression])

	_clear_expression_states(candidates)
	node.set("stage_state", "playing")
	var validation_collected_counts := Dictionary(previous_collected_counts)
	for animal_id in Dictionary(node.call("_stage_collect_targets")).keys():
		validation_collected_counts[String(animal_id)] = 0
	node.set("collected_counts", validation_collected_counts)
	node.set("remaining_moves", 3)
	node.set("_last_worried_moves", -1)
	node.call("_update_hud")
	var worried_expressions := _count_tile_expression(candidates, "worried")
	var worried_target_expressions := _count_worried_target_expressions(node, candidates)
	if worried_expressions <= 0:
		errors.append("%s low-move worried expression smoke should mark at least one goal tile." % GAMEPLAY_SCENE_PATH)
	elif worried_expressions > 4:
		errors.append("%s low-move worried expression smoke should cap worried tiles at 4, got %d." % [GAMEPLAY_SCENE_PATH, worried_expressions])
	elif worried_target_expressions != worried_expressions:
		errors.append("%s low-move worried expression smoke should only mark uncollected goal animals, got %d target worried tiles out of %d." % [GAMEPLAY_SCENE_PATH, worried_target_expressions, worried_expressions])

	node.set("is_busy", previous_busy)
	node.set("stage_state", previous_stage_state)
	node.set("remaining_moves", previous_remaining_moves)
	node.set("_last_moves_warning", previous_moves_warning)
	node.set("_last_worried_moves", previous_worried_moves)
	node.set("collected_counts", previous_collected_counts)
	if overlay != null:
		overlay.visible = previous_overlay_visible


func _clear_expression_states(tiles: Array) -> void:
	for tile in tiles:
		if tile != null and tile.has_method("clear_expression"):
			tile.clear_expression(false)


func _count_tile_expression(tiles: Array, expression_id: String) -> int:
	var count := 0
	for tile in tiles:
		if tile != null and String(tile.get("expression_state")) == expression_id:
			count += 1
	return count


func _count_selected_tiles(node: Node) -> int:
	var count := 0
	var tile_rows: Array = node.get("tile_nodes")
	for row_tiles in tile_rows:
		for tile in Array(row_tiles):
			if tile == null:
				continue
			var selection_glow := tile.find_child("SelectionGlow", true, false) as CanvasItem
			if selection_glow != null and selection_glow.visible:
				count += 1
	return count


func _count_worried_target_expressions(node: Node, tiles: Array) -> int:
	var target_animals: Dictionary = Dictionary(node.call("_stage_collect_targets"))
	var board_data: Array = node.get("board_data")
	var count := 0
	for tile in tiles:
		if tile == null or String(tile.get("expression_state")) != "worried":
			continue
		var cell := _cell_for_tile(node, tile)
		if cell == Vector2i(-1, -1) or cell.x >= board_data.size():
			continue
		var row_data: Array = board_data[cell.x]
		if cell.y >= row_data.size():
			continue
		var animal_id := String(node.call("_piece_animal", row_data[cell.y]))
		if target_animals.has(animal_id):
			count += 1
	return count


func _clear_tile_selection_states(node: Node) -> void:
	var tile_rows: Array = node.get("tile_nodes")
	for row_tiles in tile_rows:
		for tile in Array(row_tiles):
			if tile != null and tile.has_method("set_selected"):
				tile.set_selected(false)


func _cell_for_tile(node: Node, target_tile) -> Vector2i:
	var tile_rows: Array = node.get("tile_nodes")
	for row in range(tile_rows.size()):
		var row_tiles: Array = tile_rows[row]
		for col in range(row_tiles.size()):
			if row_tiles[col] == target_tile:
				return Vector2i(row, col)
	return Vector2i(-1, -1)


func _validate_rescue_buddy_runtime_rules(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_update_hud", "_apply_match_rewards", "_charge_buddy_skill_for_match", "_charge_buddy_skill_for_combo", "_charge_buddy_skill_for_clear_blocker", "_charge_buddy_skill_for_cascade_step", "_charge_buddy_skill_for_near_fail", "_charge_buddy_skill_for_stage_clear", "_trigger_buddy_skill", "_try_loyal_fetch_before_failure", "_activate_fever", "_consume_fever_turn_after_player_move", "_stage_gold_reward", "_active_visible_tiles", "_is_stage_complete"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Rescue Buddy runtime smoke." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	_validate_rescue_buddy_hud_runtime(node, errors)
	_validate_rescue_buddy_match_charge_runtime(node, errors)
	_validate_buddy_blocker_auto_complete_guard(node, errors)

	node.call("_start_stage", 3)
	node.set("board_data", _seed_plain_gameplay_board(node))
	var charge_events_before := _analytics_event_count("buddy_skill_charge")
	var ready_events_before := _analytics_event_count("buddy_skill_ready")
	var trigger_events_before := _analytics_event_count("buddy_skill_trigger")
	var blocked_events_before := _analytics_event_count("buddy_skill_blocked")

	for _index in range(3):
		node.call("_charge_buddy_skill_for_match", "rabbit")
	if _analytics_event_count("buddy_skill_charge") <= charge_events_before:
		errors.append("%s Rescue Buddy smoke should emit buddy_skill_charge for Stage 4 quick_refill." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_ready") <= ready_events_before:
		errors.append("%s Rescue Buddy smoke should emit buddy_skill_ready when quick_refill reaches full charge." % GAMEPLAY_SCENE_PATH)
	if not bool(node.get("buddy_trigger_pending")):
		errors.append("%s Rescue Buddy smoke should leave quick_refill pending after full charge." % GAMEPLAY_SCENE_PATH)
	var quick_refill_charge_event := _last_analytics_event_by_name("buddy_skill_charge")
	var quick_refill_charge_params: Dictionary = Dictionary(quick_refill_charge_event.get("params", {}))
	if int(quick_refill_charge_params.get("stage_id", 0)) != 4 or String(quick_refill_charge_params.get("animal_id", "")) != "rabbit" or String(quick_refill_charge_params.get("skill_id", "")) != "quick_refill" or int(quick_refill_charge_params.get("charge_count", 0)) != 3:
		errors.append("%s quick_refill charge analytics should identify Stage 4 rabbit quick_refill at full charge." % GAMEPLAY_SCENE_PATH)
	var quick_refill_ready_event := _last_analytics_event_by_name("buddy_skill_ready")
	var quick_refill_ready_params: Dictionary = Dictionary(quick_refill_ready_event.get("params", {}))
	if int(quick_refill_ready_params.get("stage_id", 0)) != 4 or String(quick_refill_ready_params.get("animal_id", "")) != "rabbit" or String(quick_refill_ready_params.get("skill_id", "")) != "quick_refill" or int(quick_refill_ready_params.get("turn_index", -1)) < 0:
		errors.append("%s quick_refill ready analytics should identify Stage 4 rabbit quick_refill." % GAMEPLAY_SCENE_PATH)
	var quick_refill_pending_charge_events := _analytics_event_count("buddy_skill_charge")
	var quick_refill_pending_ready_events := _analytics_event_count("buddy_skill_ready")
	var quick_refill_pending_blocked_events := _analytics_event_count("buddy_skill_blocked")
	node.call("_charge_buddy_skill_for_match", "rabbit")
	node.call("_charge_buddy_skill_for_match", "rabbit")
	if _analytics_event_count("buddy_skill_charge") != quick_refill_pending_charge_events:
		errors.append("%s quick_refill should not emit extra charge analytics while already ready." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_ready") != quick_refill_pending_ready_events:
		errors.append("%s quick_refill should not emit duplicate ready analytics while already ready." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_blocked") != quick_refill_pending_blocked_events + 1:
		errors.append("%s quick_refill should record one already_ready charge block while pending." % GAMEPLAY_SCENE_PATH)
	var quick_refill_pending_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var quick_refill_pending_blocked_params: Dictionary = Dictionary(quick_refill_pending_blocked_event.get("params", {}))
	if int(quick_refill_pending_blocked_params.get("stage_id", 0)) != 4 or String(quick_refill_pending_blocked_params.get("animal_id", "")) != "rabbit" or String(quick_refill_pending_blocked_params.get("skill_id", "")) != "quick_refill" or String(quick_refill_pending_blocked_params.get("reason", "")) != "already_ready":
		errors.append("%s quick_refill pending charge block should identify already_ready." % GAMEPLAY_SCENE_PATH)

	node.call("_trigger_buddy_skill")
	if _analytics_event_count("buddy_skill_trigger") <= trigger_events_before:
		errors.append("%s Rescue Buddy smoke should emit buddy_skill_trigger when quick_refill fires." % GAMEPLAY_SCENE_PATH)
	var quick_refill_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var quick_refill_params: Dictionary = Dictionary(quick_refill_event.get("params", {}))
	if int(quick_refill_params.get("stage_id", 0)) != 4 or String(quick_refill_params.get("animal_id", "")) != "rabbit" or String(quick_refill_params.get("effect_type", "")) != "quick_refill":
		errors.append("%s quick_refill trigger analytics should identify Stage 4 rabbit quick_refill." % GAMEPLAY_SCENE_PATH)

	node.call("_trigger_buddy_skill")
	if _analytics_event_count("buddy_skill_blocked") <= blocked_events_before:
		errors.append("%s Rescue Buddy smoke should emit buddy_skill_blocked after quick_refill max uses." % GAMEPLAY_SCENE_PATH)
	var quick_refill_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var quick_refill_blocked_params: Dictionary = Dictionary(quick_refill_blocked_event.get("params", {}))
	if int(quick_refill_blocked_params.get("stage_id", 0)) != 4 or String(quick_refill_blocked_params.get("animal_id", "")) != "rabbit" or String(quick_refill_blocked_params.get("skill_id", "")) != "quick_refill" or String(quick_refill_blocked_params.get("reason", "")) != "max_uses":
		errors.append("%s quick_refill blocked analytics should identify max_uses for Stage 4 rabbit quick_refill." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 4)
	node.set("board_data", _seed_plain_gameplay_board(node))
	var bombs_before := _count_board_special(node, "bomb")
	var soft_bomb_triggers_before := _analytics_event_count("buddy_skill_trigger")
	for _index in range(4):
		node.call("_charge_buddy_skill_for_match", "chick")
	if not bool(node.get("buddy_trigger_pending")):
		errors.append("%s soft_bomb_plus should become pending after four chick match charges." % GAMEPLAY_SCENE_PATH)
	node.call("_trigger_buddy_skill")
	if _count_board_special(node, "bomb") <= bombs_before:
		errors.append("%s soft_bomb_plus should convert a board animal into a bomb special." % GAMEPLAY_SCENE_PATH)
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s soft_bomb_plus should consume exactly one Buddy use." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= soft_bomb_triggers_before:
		errors.append("%s soft_bomb_plus should emit buddy_skill_trigger analytics." % GAMEPLAY_SCENE_PATH)
	var soft_bomb_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var soft_bomb_params: Dictionary = Dictionary(soft_bomb_event.get("params", {}))
	if int(soft_bomb_params.get("stage_id", 0)) != 5 or String(soft_bomb_params.get("animal_id", "")) != "chick" or String(soft_bomb_params.get("effect_type", "")) != "soft_bomb_plus":
		errors.append("%s soft_bomb_plus trigger analytics should identify Stage 5 chick soft_bomb_plus." % GAMEPLAY_SCENE_PATH)
	var soft_bomb_post_use_charge_events := _analytics_event_count("buddy_skill_charge")
	var soft_bomb_post_use_ready_events := _analytics_event_count("buddy_skill_ready")
	var soft_bomb_post_use_blocked_events := _analytics_event_count("buddy_skill_blocked")
	node.call("_charge_buddy_skill_for_match", "chick")
	node.call("_charge_buddy_skill_for_match", "chick")
	if _analytics_event_count("buddy_skill_charge") != soft_bomb_post_use_charge_events:
		errors.append("%s soft_bomb_plus should not emit post-use charge analytics at max uses." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_ready") != soft_bomb_post_use_ready_events:
		errors.append("%s soft_bomb_plus should not emit post-use ready analytics at max uses." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_blocked") != soft_bomb_post_use_blocked_events + 1:
		errors.append("%s soft_bomb_plus should record one max_uses charge block after use." % GAMEPLAY_SCENE_PATH)
	var soft_bomb_post_use_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var soft_bomb_post_use_blocked_params: Dictionary = Dictionary(soft_bomb_post_use_blocked_event.get("params", {}))
	if int(soft_bomb_post_use_blocked_params.get("stage_id", 0)) != 5 or String(soft_bomb_post_use_blocked_params.get("animal_id", "")) != "chick" or String(soft_bomb_post_use_blocked_params.get("skill_id", "")) != "soft_bomb_plus" or String(soft_bomb_post_use_blocked_params.get("reason", "")) != "max_uses":
		errors.append("%s soft_bomb_plus post-use charge block should identify max_uses." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 7)
	node.set("board_data", _seed_plain_gameplay_board(node))
	node.set("combo_gauge_points", 3)
	var combo_peep_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_charge_buddy_skill_for_combo", 2)
	if not bool(node.get("buddy_trigger_pending")):
		errors.append("%s combo_peep should become pending from a combo 2 charge." % GAMEPLAY_SCENE_PATH)
	node.call("_trigger_buddy_skill")
	if int(node.get("combo_gauge_points")) != 5:
		errors.append("%s combo_peep should add 2 Combo Gauge points, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("combo_gauge_points"))])
	if bool(node.get("combo_gauge_ready")):
		errors.append("%s combo_peep should not mark Combo Gauge ready before the gauge is full." % GAMEPLAY_SCENE_PATH)
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s combo_peep should consume exactly one Buddy use." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= combo_peep_triggers_before:
		errors.append("%s combo_peep should emit buddy_skill_trigger analytics." % GAMEPLAY_SCENE_PATH)
	var combo_peep_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var combo_peep_params: Dictionary = Dictionary(combo_peep_event.get("params", {}))
	if int(combo_peep_params.get("stage_id", 0)) != 8 or String(combo_peep_params.get("animal_id", "")) != "chick" or String(combo_peep_params.get("effect_type", "")) != "combo_peep":
		errors.append("%s combo_peep trigger analytics should identify Stage 8 chick combo_peep." % GAMEPLAY_SCENE_PATH)
	var combo_peep_post_use_charge_events := _analytics_event_count("buddy_skill_charge")
	var combo_peep_post_use_ready_events := _analytics_event_count("buddy_skill_ready")
	var combo_peep_post_use_trigger_events := _analytics_event_count("buddy_skill_trigger")
	var combo_peep_post_use_blocked_events := _analytics_event_count("buddy_skill_blocked")
	node.call("_charge_buddy_skill_for_combo", 2)
	node.call("_charge_buddy_skill_for_combo", 2)
	if int(node.get("buddy_uses")) != 1 or bool(node.get("buddy_trigger_pending")) or int(node.get("buddy_charge_count")) != 0:
		errors.append("%s combo_peep post-use combo charge should leave uses/pending/charge stable." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_charge") != combo_peep_post_use_charge_events:
		errors.append("%s combo_peep should not emit post-use charge analytics at max uses." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_ready") != combo_peep_post_use_ready_events:
		errors.append("%s combo_peep should not emit post-use ready analytics at max uses." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") != combo_peep_post_use_trigger_events:
		errors.append("%s combo_peep should not emit post-use trigger analytics at max uses." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_blocked") != combo_peep_post_use_blocked_events + 1:
		errors.append("%s combo_peep should record one max_uses combo charge block after use." % GAMEPLAY_SCENE_PATH)
	var combo_peep_post_use_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var combo_peep_post_use_blocked_params: Dictionary = Dictionary(combo_peep_post_use_blocked_event.get("params", {}))
	if int(combo_peep_post_use_blocked_params.get("stage_id", 0)) != 8 or String(combo_peep_post_use_blocked_params.get("animal_id", "")) != "chick" or String(combo_peep_post_use_blocked_params.get("skill_id", "")) != "combo_peep" or String(combo_peep_post_use_blocked_params.get("reason", "")) != "max_uses" or int(combo_peep_post_use_blocked_params.get("uses_left", -1)) != 0 or int(combo_peep_post_use_blocked_params.get("charge_count", -1)) != 0:
		errors.append("%s combo_peep post-use charge block should identify max_uses with no uses left." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 7)
	node.set("board_data", _seed_plain_gameplay_board(node))
	node.call("_activate_fever")
	var combo_peep_blocked_before := _analytics_event_count("buddy_skill_blocked")
	var combo_peep_ready_before := _analytics_event_count("buddy_skill_ready")
	node.call("_charge_buddy_skill_for_combo", 2)
	if int(node.get("buddy_charge_count")) != 0:
		errors.append("%s combo_peep should not charge while Fever is already active, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("buddy_charge_count"))])
	if bool(node.get("buddy_trigger_pending")):
		errors.append("%s combo_peep should not become pending while Fever is active." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_ready") != combo_peep_ready_before:
		errors.append("%s combo_peep should not emit ready while Fever is active." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_blocked") <= combo_peep_blocked_before:
		errors.append("%s combo_peep should emit buddy_skill_blocked with fever_active while Fever is active." % GAMEPLAY_SCENE_PATH)
	var combo_peep_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var combo_peep_blocked_params: Dictionary = Dictionary(combo_peep_blocked_event.get("params", {}))
	if int(combo_peep_blocked_params.get("stage_id", 0)) != 8 or String(combo_peep_blocked_params.get("animal_id", "")) != "chick" or String(combo_peep_blocked_params.get("skill_id", "")) != "combo_peep" or String(combo_peep_blocked_params.get("reason", "")) != "fever_active":
		errors.append("%s combo_peep fever guard analytics should identify Stage 8 fever_active." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 15)
	node.set("board_data", _seed_smart_hint_gameplay_board(node, "cat"))
	_clear_tile_selection_states(node)
	_clear_expression_states(node.call("_active_visible_tiles"))
	var smart_hint_triggers_before := _analytics_event_count("buddy_skill_trigger")
	for _index in range(3):
		node.call("_charge_buddy_skill_for_match", "cat")
	if not bool(node.get("buddy_trigger_pending")):
		errors.append("%s smart_hint should become pending after three cat match charges." % GAMEPLAY_SCENE_PATH)
	node.call("_trigger_buddy_skill")
	if _count_tile_expression(node.call("_active_visible_tiles"), "smile") < 2:
		errors.append("%s smart_hint should mark a two-tile recommended move with smile expressions." % GAMEPLAY_SCENE_PATH)
	if _count_selected_tiles(node) < 2:
		errors.append("%s smart_hint should highlight a two-tile recommended move." % GAMEPLAY_SCENE_PATH)
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s smart_hint should consume exactly one Buddy use." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= smart_hint_triggers_before:
		errors.append("%s smart_hint should emit buddy_skill_trigger analytics." % GAMEPLAY_SCENE_PATH)
	var smart_hint_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var smart_hint_params: Dictionary = Dictionary(smart_hint_event.get("params", {}))
	if int(smart_hint_params.get("stage_id", 0)) != 16 or String(smart_hint_params.get("animal_id", "")) != "cat" or String(smart_hint_params.get("effect_type", "")) != "smart_hint":
		errors.append("%s smart_hint trigger analytics should identify Stage 16 cat smart_hint." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 17)
	node.set("board_data", _seed_plain_gameplay_board(node))
	var leap_obstacle_data: Array = node.get("obstacle_data")
	leap_obstacle_data[2][2] = 1
	node.set("obstacle_data", leap_obstacle_data)
	var leap_clear_triggers_before := _analytics_event_count("buddy_skill_trigger")
	for _index in range(3):
		node.call("_charge_buddy_skill_for_match", "frog")
	if not bool(node.get("buddy_trigger_pending")):
		errors.append("%s leap_clear should become pending after three frog match charges." % GAMEPLAY_SCENE_PATH)
	node.call("_trigger_buddy_skill")
	leap_obstacle_data = node.get("obstacle_data")
	if int(leap_obstacle_data[2][2]) != 0:
		errors.append("%s leap_clear should clear the deterministic test blocker." % GAMEPLAY_SCENE_PATH)
	if int(node.get("cleared_blockers")) <= 0:
		errors.append("%s leap_clear should increase cleared_blockers." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= leap_clear_triggers_before:
		errors.append("%s leap_clear should emit buddy_skill_trigger analytics." % GAMEPLAY_SCENE_PATH)
	var leap_clear_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var leap_clear_params: Dictionary = Dictionary(leap_clear_event.get("params", {}))
	if int(leap_clear_params.get("stage_id", 0)) != 18 or String(leap_clear_params.get("animal_id", "")) != "frog" or String(leap_clear_params.get("effect_type", "")) != "leap_clear":
		errors.append("%s leap_clear trigger analytics should identify Stage 18 frog leap_clear." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 19)
	node.set("board_data", _seed_plain_gameplay_board(node))
	var collected_counts: Dictionary = Dictionary(node.get("collected_counts"))
	collected_counts["bear"] = 9
	collected_counts["rabbit"] = 4
	node.set("collected_counts", collected_counts)
	node.set("remaining_moves", 0)
	var loyal_fetch_events_before := _analytics_event_count("buddy_skill_trigger")
	if not bool(node.call("_try_loyal_fetch_before_failure")):
		errors.append("%s loyal_fetch should rescue a near-fail Stage 20 state before failure." % GAMEPLAY_SCENE_PATH)
	if int(node.get("remaining_moves")) != 1:
		errors.append("%s loyal_fetch should restore one rescue move before failure." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= loyal_fetch_events_before:
		errors.append("%s loyal_fetch should emit buddy_skill_trigger analytics on near-fail rescue." % GAMEPLAY_SCENE_PATH)
	var loyal_fetch_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var loyal_fetch_params: Dictionary = Dictionary(loyal_fetch_event.get("params", {}))
	if int(loyal_fetch_params.get("stage_id", 0)) != 20 or String(loyal_fetch_params.get("animal_id", "")) != "dog" or String(loyal_fetch_params.get("effect_type", "")) != "loyal_fetch":
		errors.append("%s loyal_fetch trigger analytics should identify Stage 20 dog loyal_fetch." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 23)
	node.set("board_data", _seed_plain_gameplay_board(node))
	node.set("combo_gauge_points", 0)
	var calm_fever_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_activate_fever")
	if not bool(node.get("buddy_trigger_pending")):
		errors.append("%s calm_fever should become pending when Fever starts." % GAMEPLAY_SCENE_PATH)
	for _index in range(4):
		node.call("_consume_fever_turn_after_player_move")
	if int(node.get("fever_turns_remaining")) != 0:
		errors.append("%s calm_fever smoke should expire Fever turns before triggering, got %d turns." % [GAMEPLAY_SCENE_PATH, int(node.get("fever_turns_remaining"))])
	if int(node.get("combo_gauge_points")) != 2:
		errors.append("%s calm_fever should preserve Combo Gauge by 2 points after Fever ends, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("combo_gauge_points"))])
	if _analytics_event_count("buddy_skill_trigger") <= calm_fever_triggers_before:
		errors.append("%s calm_fever should emit buddy_skill_trigger analytics after Fever ends." % GAMEPLAY_SCENE_PATH)
	var calm_fever_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var calm_fever_params: Dictionary = Dictionary(calm_fever_event.get("params", {}))
	if int(calm_fever_params.get("stage_id", 0)) != 24 or String(calm_fever_params.get("animal_id", "")) != "panda" or String(calm_fever_params.get("effect_type", "")) != "calm_fever":
		errors.append("%s calm_fever trigger analytics should identify Stage 24 panda calm_fever." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	node.set("stage_state", "cleared")
	var coin_sniff_base_reward := int(node.call("_stage_gold_reward", 3))
	var coin_sniff_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_charge_buddy_skill_for_stage_clear")
	var coin_sniff_reward := int(node.call("_stage_gold_reward", 3))
	var expected_coin_sniff_reward := int(ceil(float(coin_sniff_base_reward) * 1.05))
	if coin_sniff_reward != expected_coin_sniff_reward:
		errors.append("%s coin_sniff should boost stage gold reward by 5 percent, got %d expected %d." % [GAMEPLAY_SCENE_PATH, coin_sniff_reward, expected_coin_sniff_reward])
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s coin_sniff should consume exactly one Buddy use." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= coin_sniff_triggers_before:
		errors.append("%s coin_sniff should emit buddy_skill_trigger analytics on stage clear." % GAMEPLAY_SCENE_PATH)
	var coin_sniff_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var coin_sniff_params: Dictionary = Dictionary(coin_sniff_event.get("params", {}))
	if int(coin_sniff_params.get("stage_id", 0)) != 25 or String(coin_sniff_params.get("animal_id", "")) != "pig" or String(coin_sniff_params.get("effect_type", "")) != "coin_sniff":
		errors.append("%s coin_sniff trigger analytics should identify Stage 25 pig coin_sniff." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 30)
	node.set("board_data", _seed_plain_gameplay_board(node))
	node.set("score", 1000)
	var cascade_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_charge_buddy_skill_for_cascade_step", 2, 1000)
	if not bool(node.get("buddy_trigger_pending")):
		errors.append("%s cascade_slide should become pending from a combo 2 cascade score gain." % GAMEPLAY_SCENE_PATH)
	node.call("_trigger_buddy_skill")
	if int(node.get("score")) != 1100:
		errors.append("%s cascade_slide should add a 10 percent score bonus, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("score"))])
	if int(node.get("buddy_cascade_bonus_pending")) != 0:
		errors.append("%s cascade_slide should consume the pending cascade bonus." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= cascade_triggers_before:
		errors.append("%s cascade_slide should emit buddy_skill_trigger analytics." % GAMEPLAY_SCENE_PATH)
	var cascade_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var cascade_params: Dictionary = Dictionary(cascade_event.get("params", {}))
	if int(cascade_params.get("stage_id", 0)) != 31 or String(cascade_params.get("animal_id", "")) != "penguin" or String(cascade_params.get("effect_type", "")) != "cascade_slide":
		errors.append("%s cascade_slide trigger analytics should identify Stage 31 penguin cascade_slide." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 40)
	node.set("board_data", _seed_smart_hint_gameplay_board(node, "fox"))
	node.set("remaining_moves", 3)
	_clear_tile_selection_states(node)
	_clear_expression_states(node.call("_active_visible_tiles"))
	var sly_route_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_charge_buddy_skill_for_near_fail")
	if _count_selected_tiles(node) < 2:
		errors.append("%s sly_route should highlight a two-tile near-fail route." % GAMEPLAY_SCENE_PATH)
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s sly_route should consume exactly one Buddy use." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= sly_route_triggers_before:
		errors.append("%s sly_route should emit buddy_skill_trigger analytics on near-fail route." % GAMEPLAY_SCENE_PATH)
	var sly_route_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var sly_route_params: Dictionary = Dictionary(sly_route_event.get("params", {}))
	if int(sly_route_params.get("stage_id", 0)) != 41 or String(sly_route_params.get("animal_id", "")) != "fox" or String(sly_route_params.get("effect_type", "")) != "sly_route":
		errors.append("%s sly_route trigger analytics should identify Stage 41 fox sly_route." % GAMEPLAY_SCENE_PATH)
	_clear_tile_selection_states(node)
	_clear_expression_states(node.call("_active_visible_tiles"))
	var sly_route_second_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_charge_buddy_skill_for_near_fail")
	if int(node.get("buddy_uses")) != 2:
		errors.append("%s hard-stage sly_route should allow a second tuned Buddy use." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= sly_route_second_triggers_before:
		errors.append("%s hard-stage sly_route should emit a second trigger analytics event." % GAMEPLAY_SCENE_PATH)
	var sly_route_second_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var sly_route_second_params: Dictionary = Dictionary(sly_route_second_event.get("params", {}))
	if int(sly_route_second_params.get("stage_id", 0)) != 41 or String(sly_route_second_params.get("effect_type", "")) != "sly_route" or int(sly_route_second_params.get("uses_left", -1)) != 0:
		errors.append("%s hard-stage sly_route second trigger should report uses_left 0." % GAMEPLAY_SCENE_PATH)

	GameSession.set_selected_pre_boosters([])
	var brave_start_triggers_before := _analytics_event_count("buddy_skill_trigger")
	var brave_start_boosters_before := _analytics_event_count("booster_used")
	node.call("_start_stage", 50)
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s brave_start should consume exactly one Buddy use at Hard stage start." % GAMEPLAY_SCENE_PATH)
	if bool(node.get("buddy_trigger_pending")):
		errors.append("%s brave_start should not remain pending after immediate stage-start trigger." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= brave_start_triggers_before:
		errors.append("%s brave_start should emit buddy_skill_trigger analytics at stage start." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("booster_used") != brave_start_boosters_before:
		errors.append("%s brave_start should not grant or consume a free start booster." % GAMEPLAY_SCENE_PATH)
	var brave_start_stage_event := _last_analytics_event_by_name("stage_start")
	var brave_start_stage_params: Dictionary = Dictionary(brave_start_stage_event.get("params", {}))
	if int(brave_start_stage_params.get("start_boosters_applied", -1)) != 0:
		errors.append("%s brave_start should leave start_boosters_applied at 0 when none are selected." % GAMEPLAY_SCENE_PATH)
	if _count_board_special(node, "row") + _count_board_special(node, "col") + _count_board_special(node, "bomb") + _count_board_special(node, "rainbow") != 0:
		errors.append("%s brave_start should not place a free special block on the board." % GAMEPLAY_SCENE_PATH)
	var brave_start_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var brave_start_params: Dictionary = Dictionary(brave_start_event.get("params", {}))
	if int(brave_start_params.get("stage_id", 0)) != 51 or String(brave_start_params.get("animal_id", "")) != "lion" or String(brave_start_params.get("effect_type", "")) != "brave_start":
		errors.append("%s brave_start trigger analytics should identify Stage 51 lion brave_start." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 80)
	node.set("board_data", _seed_plain_gameplay_board(node))
	var mighty_obstacle_data: Array = node.get("obstacle_data")
	mighty_obstacle_data[3][3] = 1
	node.set("obstacle_data", mighty_obstacle_data)
	node.set("cleared_blockers", 0)
	var mighty_push_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_charge_buddy_skill_for_clear_blocker", 1)
	mighty_obstacle_data = node.get("obstacle_data")
	if int(mighty_obstacle_data[3][3]) != 0:
		errors.append("%s mighty_push should clear the deterministic test blocker." % GAMEPLAY_SCENE_PATH)
	if int(node.get("cleared_blockers")) != 1:
		errors.append("%s mighty_push should count exactly one extra cleared blocker, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("cleared_blockers"))])
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s mighty_push should consume exactly one Buddy use." % GAMEPLAY_SCENE_PATH)
	if bool(node.get("buddy_trigger_pending")):
		errors.append("%s mighty_push should not remain pending after immediate trigger." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= mighty_push_triggers_before:
		errors.append("%s mighty_push should emit buddy_skill_trigger analytics." % GAMEPLAY_SCENE_PATH)
	var mighty_push_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var mighty_push_params: Dictionary = Dictionary(mighty_push_event.get("params", {}))
	if int(mighty_push_params.get("stage_id", 0)) != 81 or String(mighty_push_params.get("animal_id", "")) != "elephant" or String(mighty_push_params.get("effect_type", "")) != "mighty_push":
		errors.append("%s mighty_push trigger analytics should identify Stage 81 elephant mighty_push." % GAMEPLAY_SCENE_PATH)
	mighty_obstacle_data = node.get("obstacle_data")
	mighty_obstacle_data[4][4] = 1
	node.set("obstacle_data", mighty_obstacle_data)
	var mighty_push_second_triggers_before := _analytics_event_count("buddy_skill_trigger")
	node.call("_charge_buddy_skill_for_clear_blocker", 1)
	mighty_obstacle_data = node.get("obstacle_data")
	if int(mighty_obstacle_data[4][4]) != 0:
		errors.append("%s hard-stage mighty_push should clear a second deterministic blocker." % GAMEPLAY_SCENE_PATH)
	if int(node.get("buddy_uses")) != 2:
		errors.append("%s hard-stage mighty_push should allow a second tuned Buddy use." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= mighty_push_second_triggers_before:
		errors.append("%s hard-stage mighty_push should emit a second trigger analytics event." % GAMEPLAY_SCENE_PATH)
	var mighty_push_second_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var mighty_push_second_params: Dictionary = Dictionary(mighty_push_second_event.get("params", {}))
	if int(mighty_push_second_params.get("stage_id", 0)) != 81 or String(mighty_push_second_params.get("effect_type", "")) != "mighty_push" or int(mighty_push_second_params.get("uses_left", -1)) != 0:
		errors.append("%s hard-stage mighty_push second trigger should report uses_left 0." % GAMEPLAY_SCENE_PATH)
	mighty_obstacle_data = node.get("obstacle_data")
	mighty_obstacle_data[5][5] = 1
	node.set("obstacle_data", mighty_obstacle_data)
	var mighty_push_post_max_charge_events := _analytics_event_count("buddy_skill_charge")
	var mighty_push_post_max_ready_events := _analytics_event_count("buddy_skill_ready")
	var mighty_push_post_max_trigger_events := _analytics_event_count("buddy_skill_trigger")
	var mighty_push_post_max_blocked_events := _analytics_event_count("buddy_skill_blocked")
	var mighty_push_post_max_cleared_blockers := int(node.get("cleared_blockers"))
	node.call("_charge_buddy_skill_for_clear_blocker", 1)
	node.call("_charge_buddy_skill_for_clear_blocker", 1)
	mighty_obstacle_data = node.get("obstacle_data")
	if int(mighty_obstacle_data[5][5]) != 1 or int(node.get("cleared_blockers")) != mighty_push_post_max_cleared_blockers:
		errors.append("%s mighty_push post-max clear_blocker charge should not clear another blocker." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_charge") != mighty_push_post_max_charge_events:
		errors.append("%s mighty_push should not emit post-max charge analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_ready") != mighty_push_post_max_ready_events:
		errors.append("%s mighty_push should not emit post-max ready analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") != mighty_push_post_max_trigger_events:
		errors.append("%s mighty_push should not emit post-max trigger analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_blocked") != mighty_push_post_max_blocked_events + 1:
		errors.append("%s mighty_push should record one max_uses clear_blocker charge block after tuned uses." % GAMEPLAY_SCENE_PATH)
	var mighty_push_post_max_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var mighty_push_post_max_blocked_params: Dictionary = Dictionary(mighty_push_post_max_blocked_event.get("params", {}))
	if int(mighty_push_post_max_blocked_params.get("stage_id", 0)) != 81 or String(mighty_push_post_max_blocked_params.get("animal_id", "")) != "elephant" or String(mighty_push_post_max_blocked_params.get("skill_id", "")) != "mighty_push" or String(mighty_push_post_max_blocked_params.get("reason", "")) != "max_uses" or int(mighty_push_post_max_blocked_params.get("uses_left", -1)) != 0 or int(mighty_push_post_max_blocked_params.get("charge_count", -1)) != 0:
		errors.append("%s mighty_push post-max charge block should identify max_uses with no uses left." % GAMEPLAY_SCENE_PATH)


func _validate_rescue_buddy_hud_runtime(node: Node, errors: PackedStringArray) -> void:
	var buddy_label := node.get("hud_buddy_label") as Label
	var buddy_gauge := node.get("hud_buddy_gauge") as ProgressBar
	if buddy_label == null or buddy_gauge == null:
		errors.append("%s Rescue Buddy HUD smoke should access hud_buddy_label and hud_buddy_gauge." % GAMEPLAY_SCENE_PATH)
		return

	node.call("_start_stage", 0)
	node.call("_update_hud")
	if buddy_label.visible or buddy_gauge.visible:
		errors.append("%s Rescue Buddy HUD should stay hidden on stages without a Buddy." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 3)
	node.call("_update_hud")
	if not buddy_label.visible or not buddy_gauge.visible:
		errors.append("%s Rescue Buddy HUD should be visible on Stage 4." % GAMEPLAY_SCENE_PATH)
	if not buddy_label.text.contains("토끼") or not buddy_label.text.contains("0/3"):
		errors.append("%s Rescue Buddy HUD should show Stage 4 rabbit 0/3 charge state, got %s." % [GAMEPLAY_SCENE_PATH, buddy_label.text])
	if int(buddy_gauge.max_value) != 3 or int(buddy_gauge.value) != 0:
		errors.append("%s Rescue Buddy gauge should start at 0/3 on Stage 4, got %d/%d." % [GAMEPLAY_SCENE_PATH, int(buddy_gauge.value), int(buddy_gauge.max_value)])

	for _index in range(2):
		node.call("_charge_buddy_skill_for_match", "rabbit")
	node.call("_update_hud")
	if not buddy_label.text.contains("2/3") or buddy_label.text.contains("출동"):
		errors.append("%s Rescue Buddy HUD should show non-ready 2/3 charge before full charge, got %s." % [GAMEPLAY_SCENE_PATH, buddy_label.text])
	if int(buddy_gauge.value) != 2:
		errors.append("%s Rescue Buddy gauge should show 2 charges before ready, got %d." % [GAMEPLAY_SCENE_PATH, int(buddy_gauge.value)])

	node.call("_charge_buddy_skill_for_match", "rabbit")
	node.call("_update_hud")
	if not buddy_label.text.contains("출동"):
		errors.append("%s Rescue Buddy HUD should show 출동 when quick_refill is ready, got %s." % [GAMEPLAY_SCENE_PATH, buddy_label.text])
	if int(buddy_gauge.value) != 3:
		errors.append("%s Rescue Buddy gauge should fill at quick_refill ready, got %d." % [GAMEPLAY_SCENE_PATH, int(buddy_gauge.value)])

	node.call("_trigger_buddy_skill")
	if not buddy_label.text.contains("완료"):
		errors.append("%s Rescue Buddy HUD should show 완료 after max-use trigger, got %s." % [GAMEPLAY_SCENE_PATH, buddy_label.text])
	if int(buddy_gauge.value) != 3:
		errors.append("%s Rescue Buddy gauge should remain filled after Buddy completes, got %d." % [GAMEPLAY_SCENE_PATH, int(buddy_gauge.value)])


func _validate_rescue_buddy_match_charge_runtime(node: Node, errors: PackedStringArray) -> void:
	node.call("_start_stage", 3)
	var board_data: Array = _seed_plain_gameplay_board(node)
	for cell in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]:
		board_data[cell.x][cell.y] = node.call("_make_piece", "rabbit")
	node.set("board_data", board_data)
	var ready_events_before := _analytics_event_count("buddy_skill_ready")
	node.call("_apply_match_rewards", [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], 1)
	if int(node.get("buddy_charge_count")) != 1:
		errors.append("%s one goal-animal 3-match should count as one Buddy charge, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("buddy_charge_count"))])
	if bool(node.get("buddy_trigger_pending")):
		errors.append("%s one goal-animal 3-match should not make quick_refill ready by itself." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_ready") != ready_events_before:
		errors.append("%s one goal-animal 3-match should not emit buddy_skill_ready before three match events." % GAMEPLAY_SCENE_PATH)


func _validate_buddy_blocker_auto_complete_guard(node: Node, errors: PackedStringArray) -> void:
	node.call("_start_stage", 17)
	node.set("board_data", _seed_plain_gameplay_board(node))
	_complete_current_stage_goals(node)
	var leap_target_blockers := int(node.call("_target_blockers"))
	node.set("cleared_blockers", leap_target_blockers - 1)
	var leap_obstacle_data: Array = node.get("obstacle_data")
	for row in range(8):
		for col in range(8):
			leap_obstacle_data[row][col] = 0
	leap_obstacle_data[2][2] = 1
	node.set("obstacle_data", leap_obstacle_data)
	var leap_clear_triggers_before := _analytics_event_count("buddy_skill_trigger")
	var leap_clear_blocked_before := _analytics_event_count("buddy_skill_blocked")
	for _index in range(3):
		node.call("_charge_buddy_skill_for_match", "frog")
	node.call("_trigger_buddy_skill")
	leap_obstacle_data = node.get("obstacle_data")
	if int(leap_obstacle_data[2][2]) != 1:
		errors.append("%s leap_clear should not clear the final blocker when it would complete the stage by itself." % GAMEPLAY_SCENE_PATH)
	if int(node.get("cleared_blockers")) != leap_target_blockers - 1:
		errors.append("%s leap_clear guard should preserve cleared_blockers at one short of target, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("cleared_blockers"))])
	if int(node.get("buddy_uses")) != 0:
		errors.append("%s leap_clear guard should not consume a Buddy use when blocked, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("buddy_uses"))])
	if _analytics_event_count("buddy_skill_trigger") != leap_clear_triggers_before:
		errors.append("%s leap_clear guard should not emit buddy_skill_trigger when blocking auto-complete." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_blocked") <= leap_clear_blocked_before:
		errors.append("%s leap_clear guard should emit buddy_skill_blocked when blocking auto-complete." % GAMEPLAY_SCENE_PATH)
	var leap_clear_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var leap_clear_blocked_params: Dictionary = Dictionary(leap_clear_blocked_event.get("params", {}))
	if int(leap_clear_blocked_params.get("stage_id", 0)) != 18 or String(leap_clear_blocked_params.get("animal_id", "")) != "frog" or String(leap_clear_blocked_params.get("skill_id", "")) != "leap_clear" or String(leap_clear_blocked_params.get("reason", "")) != "effect_unavailable":
		errors.append("%s leap_clear guard blocked analytics should identify Stage 18 effect_unavailable." % GAMEPLAY_SCENE_PATH)
	if bool(node.call("_is_stage_complete")):
		errors.append("%s leap_clear guard should leave Stage 18 incomplete until the player clears the final blocker." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 80)
	node.set("board_data", _seed_plain_gameplay_board(node))
	_complete_current_stage_goals(node)
	var mighty_target_blockers := int(node.call("_target_blockers"))
	node.set("cleared_blockers", mighty_target_blockers - 1)
	var mighty_obstacle_data: Array = node.get("obstacle_data")
	for row in range(8):
		for col in range(8):
			mighty_obstacle_data[row][col] = 0
	mighty_obstacle_data[3][3] = 1
	node.set("obstacle_data", mighty_obstacle_data)
	var mighty_push_triggers_before := _analytics_event_count("buddy_skill_trigger")
	var mighty_push_blocked_before := _analytics_event_count("buddy_skill_blocked")
	node.call("_charge_buddy_skill_for_clear_blocker", 1)
	mighty_obstacle_data = node.get("obstacle_data")
	if int(mighty_obstacle_data[3][3]) != 1:
		errors.append("%s mighty_push should not clear the final blocker when it would complete the stage by itself." % GAMEPLAY_SCENE_PATH)
	if int(node.get("cleared_blockers")) != mighty_target_blockers - 1:
		errors.append("%s mighty_push guard should preserve cleared_blockers at one short of target, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("cleared_blockers"))])
	if int(node.get("buddy_uses")) != 0:
		errors.append("%s mighty_push guard should not consume a Buddy use when blocked, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("buddy_uses"))])
	if _analytics_event_count("buddy_skill_trigger") != mighty_push_triggers_before:
		errors.append("%s mighty_push guard should not emit buddy_skill_trigger when blocking auto-complete." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_blocked") <= mighty_push_blocked_before:
		errors.append("%s mighty_push guard should emit buddy_skill_blocked when blocking auto-complete." % GAMEPLAY_SCENE_PATH)
	var mighty_push_blocked_event := _last_analytics_event_by_name("buddy_skill_blocked")
	var mighty_push_blocked_params: Dictionary = Dictionary(mighty_push_blocked_event.get("params", {}))
	if int(mighty_push_blocked_params.get("stage_id", 0)) != 81 or String(mighty_push_blocked_params.get("animal_id", "")) != "elephant" or String(mighty_push_blocked_params.get("skill_id", "")) != "mighty_push" or String(mighty_push_blocked_params.get("reason", "")) != "effect_unavailable":
		errors.append("%s mighty_push guard blocked analytics should identify Stage 81 effect_unavailable." % GAMEPLAY_SCENE_PATH)
	if bool(node.call("_is_stage_complete")):
		errors.append("%s mighty_push guard should leave Stage 81 incomplete until the player clears the final blocker." % GAMEPLAY_SCENE_PATH)


func _validate_special_effect_rules(node: Node, errors: PackedStringArray) -> void:
	var from_cell := Vector2i(3, 3)
	var to_cell := Vector2i(3, 4)
	var board_data_value = node.get("board_data")
	if not (board_data_value is Array) or board_data_value.size() < 8:
		errors.append("%s special combo smoke could not inspect board data." % GAMEPLAY_SCENE_PATH)
		return

	var board_data: Array = _seed_plain_gameplay_board(node)
	board_data[from_cell.x][from_cell.y] = node.call("_make_piece", "rabbit", "row")
	board_data[to_cell.x][to_cell.y] = node.call("_make_piece", "bear", "col")
	node.set("board_data", board_data)

	if not bool(node.call("_is_special_combo_swap", from_cell, to_cell)):
		errors.append("%s should treat adjacent non-rainbow special blocks as a valid special combo swap." % GAMEPLAY_SCENE_PATH)

	var clear_cells: Array = node.call("_special_combo_clear_cells", from_cell, to_cell)
	if clear_cells.size() != 15:
		errors.append("%s row+column special combo should clear 15 unique cells, got %d." % [GAMEPLAY_SCENE_PATH, clear_cells.size()])
	if not clear_cells.has(from_cell) or not clear_cells.has(to_cell):
		errors.append("%s special combo clear set should include both swapped special blocks." % GAMEPLAY_SCENE_PATH)

	var chained_bomb_cell := Vector2i(3, 6)
	board_data[chained_bomb_cell.x][chained_bomb_cell.y] = node.call("_make_piece", "pig", "bomb")
	node.set("board_data", board_data)
	var chained_clear_cells: Array = node.call("_special_combo_clear_cells", from_cell, to_cell)
	if chained_clear_cells.size() != 21:
		errors.append("%s row+column special combo should trigger chained bomb effects once, got %d cells." % [GAMEPLAY_SCENE_PATH, chained_clear_cells.size()])
	if not chained_clear_cells.has(Vector2i(2, 5)) or not chained_clear_cells.has(Vector2i(4, 7)):
		errors.append("%s chained bomb should add its 3x3 splash to the special combo queue." % GAMEPLAY_SCENE_PATH)

	var adjacent_obstacle_cell := Vector2i(2, 4)
	var obstacle_data: Array = node.get("obstacle_data")
	obstacle_data[adjacent_obstacle_cell.x][adjacent_obstacle_cell.y] = 1
	node.set("obstacle_data", obstacle_data)
	var damaged_obstacles: Array = node.call("_damage_obstacles", chained_clear_cells)
	if not damaged_obstacles.has(adjacent_obstacle_cell):
		errors.append("%s special combo queue should damage obstacles adjacent to cleared cells." % GAMEPLAY_SCENE_PATH)
	obstacle_data = node.get("obstacle_data")
	if int(obstacle_data[adjacent_obstacle_cell.x][adjacent_obstacle_cell.y]) != 0:
		errors.append("%s special combo obstacle damage should clear the tested obstacle cell." % GAMEPLAY_SCENE_PATH)

	var rainbow_cell := Vector2i(4, 3)
	var rainbow_target_cell := Vector2i(4, 4)
	board_data = node.get("board_data")
	board_data[rainbow_cell.x][rainbow_cell.y] = node.call("_make_piece", "rabbit", "rainbow")
	board_data[rainbow_target_cell.x][rainbow_target_cell.y] = node.call("_make_piece", "fox", "row")
	node.set("board_data", board_data)
	var rainbow_outcome: Dictionary = node.call("_rainbow_swap_outcome", rainbow_cell, rainbow_target_cell)
	if rainbow_outcome.is_empty():
		errors.append("%s rainbow+special swap should route through the rainbow resolution path first." % GAMEPLAY_SCENE_PATH)
	elif String(rainbow_outcome.get("target_animal", "")) != "fox":
		errors.append("%s rainbow+special swap should target the non-rainbow animal, got %s." % [GAMEPLAY_SCENE_PATH, String(rainbow_outcome.get("target_animal", ""))])

	board_data = _seed_plain_gameplay_board(node)
	var row_combo_a := Vector2i(1, 2)
	var row_combo_b := Vector2i(1, 3)
	board_data[row_combo_a.x][row_combo_a.y] = node.call("_make_piece", "rabbit", "row")
	board_data[row_combo_b.x][row_combo_b.y] = node.call("_make_piece", "bear", "row")
	node.set("board_data", board_data)
	if not bool(node.call("_is_special_combo_swap", row_combo_a, row_combo_b)):
		errors.append("%s should treat adjacent row+row special blocks as a valid special combo swap." % GAMEPLAY_SCENE_PATH)
	var row_combo_cells: Array = node.call("_special_combo_clear_cells", row_combo_a, row_combo_b)
	if row_combo_cells.size() != 8:
		errors.append("%s row+row special combo should clear one full row without duplicates, got %d cells." % [GAMEPLAY_SCENE_PATH, row_combo_cells.size()])
	if not row_combo_cells.has(Vector2i(1, 0)) or not row_combo_cells.has(Vector2i(1, 7)):
		errors.append("%s row+row special combo should include both ends of the target row." % GAMEPLAY_SCENE_PATH)

	board_data = _seed_plain_gameplay_board(node)
	var bomb_combo_a := Vector2i(5, 4)
	var bomb_combo_b := Vector2i(5, 5)
	board_data[bomb_combo_a.x][bomb_combo_a.y] = node.call("_make_piece", "rabbit", "bomb")
	board_data[bomb_combo_b.x][bomb_combo_b.y] = node.call("_make_piece", "bear", "bomb")
	node.set("board_data", board_data)
	if not bool(node.call("_is_special_combo_swap", bomb_combo_a, bomb_combo_b)):
		errors.append("%s should treat adjacent bomb+bomb special blocks as a valid special combo swap." % GAMEPLAY_SCENE_PATH)
	var bomb_combo_cells: Array = node.call("_special_combo_clear_cells", bomb_combo_a, bomb_combo_b)
	if bomb_combo_cells.size() != 12:
		errors.append("%s bomb+bomb special combo should clear the two 3x3 blasts as a unique 12-cell union, got %d cells." % [GAMEPLAY_SCENE_PATH, bomb_combo_cells.size()])
	if not bomb_combo_cells.has(Vector2i(4, 3)) or not bomb_combo_cells.has(Vector2i(6, 6)):
		errors.append("%s bomb+bomb special combo should include the far corners of both blast areas." % GAMEPLAY_SCENE_PATH)

	board_data = _seed_plain_gameplay_board(node)
	var col_combo_a := Vector2i(2, 6)
	var col_combo_b := Vector2i(3, 6)
	board_data[col_combo_a.x][col_combo_a.y] = node.call("_make_piece", "rabbit", "col")
	board_data[col_combo_b.x][col_combo_b.y] = node.call("_make_piece", "bear", "col")
	node.set("board_data", board_data)
	if not bool(node.call("_is_special_combo_swap", col_combo_a, col_combo_b)):
		errors.append("%s should treat adjacent column+column special blocks as a valid special combo swap." % GAMEPLAY_SCENE_PATH)
	var col_combo_cells: Array = node.call("_special_combo_clear_cells", col_combo_a, col_combo_b)
	if col_combo_cells.size() != 8:
		errors.append("%s column+column special combo should clear one full column without duplicates, got %d." % [GAMEPLAY_SCENE_PATH, col_combo_cells.size()])
	if not col_combo_cells.has(Vector2i(0, 6)) or not col_combo_cells.has(Vector2i(7, 6)):
		errors.append("%s column+column special combo should include both ends of the target column." % GAMEPLAY_SCENE_PATH)

	board_data = _seed_plain_gameplay_board(node)
	var row_bomb_a := Vector2i(2, 3)
	var row_bomb_b := Vector2i(2, 4)
	board_data[row_bomb_a.x][row_bomb_a.y] = node.call("_make_piece", "rabbit", "row")
	board_data[row_bomb_b.x][row_bomb_b.y] = node.call("_make_piece", "bear", "bomb")
	node.set("board_data", board_data)
	if not bool(node.call("_is_special_combo_swap", row_bomb_a, row_bomb_b)):
		errors.append("%s should treat adjacent row+bomb special blocks as a valid special combo swap." % GAMEPLAY_SCENE_PATH)
	var row_bomb_cells: Array = node.call("_special_combo_clear_cells", row_bomb_a, row_bomb_b)
	if row_bomb_cells.size() != 14:
		errors.append("%s row+bomb special combo should clear a row plus one 3x3 splash without duplicates, got %d." % [GAMEPLAY_SCENE_PATH, row_bomb_cells.size()])
	if not row_bomb_cells.has(Vector2i(2, 0)) or not row_bomb_cells.has(Vector2i(2, 7)) or not row_bomb_cells.has(Vector2i(1, 3)) or not row_bomb_cells.has(Vector2i(3, 5)):
		errors.append("%s row+bomb special combo should include row ends and bomb splash fringe." % GAMEPLAY_SCENE_PATH)

	board_data = _seed_plain_gameplay_board(node)
	var col_bomb_a := Vector2i(4, 1)
	var col_bomb_b := Vector2i(4, 2)
	board_data[col_bomb_a.x][col_bomb_a.y] = node.call("_make_piece", "rabbit", "col")
	board_data[col_bomb_b.x][col_bomb_b.y] = node.call("_make_piece", "bear", "bomb")
	node.set("board_data", board_data)
	if not bool(node.call("_is_special_combo_swap", col_bomb_a, col_bomb_b)):
		errors.append("%s should treat adjacent column+bomb special blocks as a valid special combo swap." % GAMEPLAY_SCENE_PATH)
	var col_bomb_cells: Array = node.call("_special_combo_clear_cells", col_bomb_a, col_bomb_b)
	if col_bomb_cells.size() != 14:
		errors.append("%s column+bomb special combo should clear a column plus one 3x3 splash without duplicates, got %d." % [GAMEPLAY_SCENE_PATH, col_bomb_cells.size()])
	if not col_bomb_cells.has(Vector2i(0, 1)) or not col_bomb_cells.has(Vector2i(7, 1)) or not col_bomb_cells.has(Vector2i(3, 3)) or not col_bomb_cells.has(Vector2i(5, 3)):
		errors.append("%s column+bomb special combo should include column ends and bomb splash fringe." % GAMEPLAY_SCENE_PATH)

	board_data = _seed_plain_gameplay_board(node)
	var intersection := Vector2i(5, 5)
	for cell in [Vector2i(5, 4), intersection, Vector2i(5, 6), Vector2i(3, 5), Vector2i(4, 5)]:
		board_data[cell.x][cell.y] = node.call("_make_piece", "rabbit")
	node.set("board_data", board_data)
	var match_outcome: Dictionary = node.call("_analyze_match_outcome", [intersection])
	var special_spawns: Dictionary = Dictionary(match_outcome.get("special_spawns", {}))
	if String(special_spawns.get(intersection, "")) != "bomb":
		errors.append("%s T/L intersection match should spawn a bomb at the preferred intersection, got %s." % [GAMEPLAY_SCENE_PATH, String(special_spawns.get(intersection, ""))])

	board_data = _seed_plain_gameplay_board(node)
	var row_four_spawn := Vector2i(0, 2)
	for cell in [Vector2i(0, 1), row_four_spawn, Vector2i(0, 3), Vector2i(0, 4)]:
		board_data[cell.x][cell.y] = node.call("_make_piece", "frog")
	node.set("board_data", board_data)
	var row_four_outcome: Dictionary = node.call("_analyze_match_outcome", [row_four_spawn])
	var row_four_spawns: Dictionary = Dictionary(row_four_outcome.get("special_spawns", {}))
	if String(row_four_spawns.get(row_four_spawn, "")) != "row":
		errors.append("%s 4-match row run should spawn a row special at the preferred cell, got %s." % [GAMEPLAY_SCENE_PATH, String(row_four_spawns.get(row_four_spawn, ""))])

	board_data = _seed_plain_gameplay_board(node)
	var col_four_spawn := Vector2i(2, 6)
	for cell in [Vector2i(1, 6), col_four_spawn, Vector2i(3, 6), Vector2i(4, 6)]:
		board_data[cell.x][cell.y] = node.call("_make_piece", "dog")
	node.set("board_data", board_data)
	var col_four_outcome: Dictionary = node.call("_analyze_match_outcome", [col_four_spawn])
	var col_four_spawns: Dictionary = Dictionary(col_four_outcome.get("special_spawns", {}))
	if String(col_four_spawns.get(col_four_spawn, "")) != "col":
		errors.append("%s 4-match column run should spawn a column special at the preferred cell, got %s." % [GAMEPLAY_SCENE_PATH, String(col_four_spawns.get(col_four_spawn, ""))])

	board_data = _seed_plain_gameplay_board(node)
	var rainbow_spawn := Vector2i(6, 3)
	for cell in [Vector2i(6, 1), Vector2i(6, 2), rainbow_spawn, Vector2i(6, 4), Vector2i(6, 5)]:
		board_data[cell.x][cell.y] = node.call("_make_piece", "panda")
	node.set("board_data", board_data)
	var rainbow_outcome_spawn: Dictionary = node.call("_analyze_match_outcome", [rainbow_spawn])
	var rainbow_spawns: Dictionary = Dictionary(rainbow_outcome_spawn.get("special_spawns", {}))
	if String(rainbow_spawns.get(rainbow_spawn, "")) != "rainbow":
		errors.append("%s 5-match run should spawn a rainbow special at the preferred cell, got %s." % [GAMEPLAY_SCENE_PATH, String(rainbow_spawns.get(rainbow_spawn, ""))])


func _validate_special_combo_swap_runtime(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_resolve_swap", "_make_piece"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for special combo runtime smoke." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	var scenarios: Array = [
		{"label": "row+column", "combo_type": "row_col", "cleared_count": 15, "from_special": "row", "to_special": "col", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(2, 4)},
		{"label": "row+row", "combo_type": "row_row", "cleared_count": 8, "from_special": "row", "to_special": "row", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(3, 0)},
		{"label": "column+column", "combo_type": "col_col", "cleared_count": 8, "from_special": "col", "to_special": "col", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(4, 3), "obstacle_cell": Vector2i(0, 3)},
		{"label": "row+bomb", "combo_type": "row_bomb", "cleared_count": 14, "from_special": "row", "to_special": "bomb", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(2, 4)},
		{"label": "column+bomb", "combo_type": "col_bomb", "cleared_count": 14, "from_special": "col", "to_special": "bomb", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(4, 3), "obstacle_cell": Vector2i(4, 4)},
		{"label": "bomb+bomb", "combo_type": "bomb_bomb", "cleared_count": 12, "from_special": "bomb", "to_special": "bomb", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(2, 3)},
	]
	for scenario in scenarios:
		await _run_special_combo_swap_runtime_scenario(node, Dictionary(scenario), errors)


func _run_special_combo_swap_runtime_scenario(node: Node, scenario: Dictionary, errors: PackedStringArray) -> void:
	var label := String(scenario.get("label", "special combo"))
	var from_cell: Vector2i = scenario.get("from_cell", Vector2i.ZERO)
	var to_cell: Vector2i = scenario.get("to_cell", Vector2i.ZERO)
	var obstacle_cell: Vector2i = scenario.get("obstacle_cell", Vector2i.ZERO)
	node.call("_start_stage", 30)
	var board_data: Array = _seed_plain_gameplay_board(node)
	board_data[from_cell.x][from_cell.y] = node.call("_make_piece", "rabbit", String(scenario.get("from_special", "")))
	board_data[to_cell.x][to_cell.y] = node.call("_make_piece", "bear", String(scenario.get("to_special", "")))
	node.set("board_data", board_data)
	var obstacle_data: Array = node.get("obstacle_data")
	obstacle_data[obstacle_cell.x][obstacle_cell.y] = 1
	node.set("obstacle_data", obstacle_data)

	var moves_before := int(node.get("remaining_moves"))
	var score_before := int(node.get("score"))
	var special_combo_events_before := _analytics_event_count("special_combo_trigger")
	var feedback := root.get_node_or_null("Feedback")
	if feedback != null and feedback.has_method("clear_feedback_history_for_testing"):
		feedback.set("sound_enabled", true)
		feedback.set("haptics_enabled", true)
		feedback.call("clear_feedback_history_for_testing")
	await node.call("_resolve_swap", from_cell, to_cell)

	if bool(node.get("is_busy")):
		errors.append("%s %s runtime smoke should release is_busy after _resolve_swap." % [GAMEPLAY_SCENE_PATH, label])
	if int(node.get("remaining_moves")) != moves_before - 1:
		errors.append("%s %s runtime smoke should consume exactly one move, got %d from %d." % [GAMEPLAY_SCENE_PATH, label, int(node.get("remaining_moves")), moves_before])
	if int(node.get("score")) <= score_before:
		errors.append("%s %s runtime smoke should increase score through _resolve_swap." % [GAMEPLAY_SCENE_PATH, label])
	obstacle_data = node.get("obstacle_data")
	if int(obstacle_data[obstacle_cell.x][obstacle_cell.y]) != 0:
		errors.append("%s %s runtime smoke should clear an obstacle on the combo path." % [GAMEPLAY_SCENE_PATH, label])
	if feedback != null and feedback.has_method("feedback_stream_keys_for_testing"):
		var feedback_keys: Array = feedback.call("feedback_stream_keys_for_testing")
		if not feedback_keys.has("special_combo"):
			errors.append("%s %s runtime smoke should trigger dedicated special_combo feedback, got %s." % [GAMEPLAY_SCENE_PATH, label, str(feedback_keys)])
	if feedback != null and feedback.has_method("vibration_ms_history_for_testing"):
		var has_strong_special_haptic := false
		for vibration_value in Array(feedback.call("vibration_ms_history_for_testing")):
			if int(vibration_value) >= 58:
				has_strong_special_haptic = true
				break
		if not has_strong_special_haptic:
			errors.append("%s %s runtime smoke should request a strong special combo haptic." % [GAMEPLAY_SCENE_PATH, label])
	if String(node.get("stage_state")) != "playing":
		errors.append("%s %s runtime smoke should leave Stage 31 in playing state, got %s." % [GAMEPLAY_SCENE_PATH, label, String(node.get("stage_state"))])
	if _analytics_event_count("special_combo_trigger") <= special_combo_events_before:
		errors.append("%s %s runtime smoke should emit special_combo_trigger analytics." % [GAMEPLAY_SCENE_PATH, label])
	var special_combo_params := _analytics_event_params_by_name_and_key("special_combo_trigger", "combo_type", String(scenario.get("combo_type", "")))
	if special_combo_params.is_empty():
		errors.append("%s %s runtime smoke should find special_combo_trigger payload for combo_type %s." % [GAMEPLAY_SCENE_PATH, label, String(scenario.get("combo_type", ""))])
	if int(special_combo_params.get("stage_id", 0)) != 31:
		errors.append("%s %s special_combo_trigger should identify Stage 31." % [GAMEPLAY_SCENE_PATH, label])
	if String(special_combo_params.get("combo_type", "")) != String(scenario.get("combo_type", "")):
		errors.append("%s %s special_combo_trigger should record combo_type %s, got %s." % [GAMEPLAY_SCENE_PATH, label, String(scenario.get("combo_type", "")), String(special_combo_params.get("combo_type", ""))])
	if String(special_combo_params.get("from_special", "")) != String(scenario.get("from_special", "")) or String(special_combo_params.get("to_special", "")) != String(scenario.get("to_special", "")):
		errors.append("%s %s special_combo_trigger should preserve from/to special ids." % [GAMEPLAY_SCENE_PATH, label])
	if int(special_combo_params.get("cleared_count", 0)) != int(scenario.get("cleared_count", 0)):
		errors.append("%s %s special_combo_trigger should record cleared_count %d, got %d." % [GAMEPLAY_SCENE_PATH, label, int(scenario.get("cleared_count", 0)), int(special_combo_params.get("cleared_count", 0))])
	if int(special_combo_params.get("obstacles_cleared", 0)) != 1:
		errors.append("%s %s special_combo_trigger should record one obstacle cleared, got %d." % [GAMEPLAY_SCENE_PATH, label, int(special_combo_params.get("obstacles_cleared", 0))])


func _validate_start_booster_runtime_rules(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for start booster runtime smoke." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	var selected_boosters := ["rainbow_paw", "striped", "bomb"]
	var booster_events_before := _analytics_event_count("booster_used")
	GameSession.set_selected_pre_boosters(selected_boosters)
	node.call("_start_stage", 0)

	var stage_boosters: Array = node.get("stage_selected_boosters")
	for booster_id in selected_boosters:
		if not stage_boosters.has(booster_id):
			errors.append("%s start booster smoke should preserve selected booster %s on stage_start state." % [GAMEPLAY_SCENE_PATH, booster_id])

	if not GameSession.get_selected_pre_boosters().is_empty():
		errors.append("%s start booster smoke should consume selected_pre_boosters after _start_stage." % GAMEPLAY_SCENE_PATH)

	var rainbow_count := _count_board_special(node, "rainbow")
	var striped_count := _count_board_special(node, "row") + _count_board_special(node, "col")
	var bomb_count := _count_board_special(node, "bomb")
	if rainbow_count != 1:
		errors.append("%s start booster smoke should place one rainbow special, got %d." % [GAMEPLAY_SCENE_PATH, rainbow_count])
	if striped_count != 1:
		errors.append("%s start booster smoke should place one striped row/column special, got %d." % [GAMEPLAY_SCENE_PATH, striped_count])
	if bomb_count != 1:
		errors.append("%s start booster smoke should place one bomb special, got %d." % [GAMEPLAY_SCENE_PATH, bomb_count])
	if String(node.get("stage_state")) != "playing":
		errors.append("%s start booster smoke should keep Stage 1 in playing state, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("stage_state"))])

	var stage_start_event := _last_analytics_event_by_name("stage_start")
	var stage_start_params: Dictionary = Dictionary(stage_start_event.get("params", {}))
	if int(stage_start_params.get("stage_id", 0)) != 1:
		errors.append("%s start booster smoke should emit stage_start for Stage 1." % GAMEPLAY_SCENE_PATH)
	var analytics_boosters: Array = Array(stage_start_params.get("selected_boosters", []))
	for booster_id in selected_boosters:
		if not analytics_boosters.has(booster_id):
			errors.append("%s stage_start analytics should include selected booster %s." % [GAMEPLAY_SCENE_PATH, booster_id])
	if int(stage_start_params.get("start_boosters_applied", -1)) != selected_boosters.size():
		errors.append("%s stage_start analytics should report %d applied start boosters, got %d." % [GAMEPLAY_SCENE_PATH, selected_boosters.size(), int(stage_start_params.get("start_boosters_applied", -1))])
	if _analytics_event_count("booster_used") - booster_events_before != selected_boosters.size():
		errors.append("%s start booster smoke should emit one booster_used event per selected booster." % GAMEPLAY_SCENE_PATH)

	var seen_pre_stage_boosters := {}
	for event in GameSession.get_analytics_events():
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		if String(event_dict.get("name", "")) != "booster_used":
			continue
		var params: Dictionary = Dictionary(event_dict.get("params", {}))
		if int(params.get("stage_id", 0)) == 1 and String(params.get("source", "")) == "pre_stage":
			seen_pre_stage_boosters[String(params.get("booster_id", ""))] = true
	for booster_id in selected_boosters:
		if not seen_pre_stage_boosters.has(booster_id):
			errors.append("%s booster_used analytics should include %s from pre_stage." % [GAMEPLAY_SCENE_PATH, booster_id])

	GameSession.set_selected_pre_boosters([])


func _validate_result_overlay_mascot_texture_fallbacks(node: Node, errors: PackedStringArray) -> void:
	var overlay_mascot := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayMascot") as TextureRect
	if overlay_mascot == null:
		errors.append("%s result overlay mascot fallback smoke is missing OverlayMascot." % GAMEPLAY_SCENE_PATH)
		return
	var original_textures: Dictionary = Dictionary(node.get("animal_textures")).duplicate(true)
	var missing_textures := original_textures.duplicate(true)
	missing_textures["rabbit"] = null
	missing_textures["bear"] = null
	node.set("animal_textures", missing_textures)
	node.call("_update_overlay_mascot", "일시정지", "resume_stage")
	if overlay_mascot.texture == null:
		errors.append("%s resume overlay mascot should fall back when bear texture is missing." % GAMEPLAY_SCENE_PATH)
	node.call("_update_overlay_mascot", "시작", "start_stage")
	if overlay_mascot.texture == null:
		errors.append("%s default overlay mascot should fall back when rabbit texture is missing." % GAMEPLAY_SCENE_PATH)
	node.set("animal_textures", original_textures)


func _validate_result_overlay_runtime(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_check_stage_state", "_on_overlay_primary_button_pressed", "_on_overlay_secondary_button_pressed", "_resolve_fail_offer_continue_result", "_request_fail_offer_continue", "_current_stage", "_current_stage_id", "_build_failure_focus_summary", "_build_failure_retry_hint", "_build_failure_offer", "_update_overlay_mascot", "_overlay_expression_state_for_testing", "_overlay_expression_tween_active_for_testing"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for result overlay runtime smoke." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	_validate_failure_focus_hint_runtime(node, errors)
	await _validate_loyal_fetch_failure_gate_runtime(node, errors)
	node.call("_start_stage", 0)
	_validate_result_overlay_mascot_texture_fallbacks(node, errors)
	await _validate_gameplay_hud_text_stress(node, errors)
	_complete_current_stage_goals(node)
	node.set("remaining_moves", 0)
	var complete_events_before := _analytics_event_count("stage_complete")
	var token_events_before := _analytics_event_count("animal_token_gain")
	var rabbit_tokens_before := _rescue_book_token_count("rabbit")
	await node.call("_check_stage_state")
	var overlay := node.get_node_or_null("Overlay") as CanvasItem
	var overlay_title := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayTitle") as Label
	var overlay_body := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Label
	var overlay_mascot := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayMascot") as TextureRect
	var overlay_primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Button
	var overlay_secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Button
	if overlay == null or not overlay.visible:
		errors.append("%s clear overlay runtime smoke should show the result overlay." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "cleared":
		errors.append("%s clear overlay runtime smoke should leave Stage 1 cleared, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("stage_state"))])
	if String(node.get("overlay_action")) != "clear_stage":
		errors.append("%s clear overlay runtime smoke should use clear_stage overlay action." % GAMEPLAY_SCENE_PATH)
	if overlay_title == null or not overlay_title.text.contains("구조 완료"):
		errors.append("%s clear overlay should show a clear title." % GAMEPLAY_SCENE_PATH)
	if overlay_body == null or not overlay_body.text.contains("보상") or not overlay_body.text.contains("별") or not overlay_body.text.contains("다음"):
		errors.append("%s clear overlay body should show reward, stars, and next action text." % GAMEPLAY_SCENE_PATH)
	if overlay_body == null or not overlay_body.text.contains("도감") or not overlay_body.text.contains("토큰 +3"):
		errors.append("%s clear overlay body should show the Rescue Book token reward." % GAMEPLAY_SCENE_PATH)
	if overlay_mascot == null or overlay_mascot.texture == null:
		errors.append("%s clear overlay should show a non-null success mascot texture." % GAMEPLAY_SCENE_PATH)
	if overlay_primary == null or overlay_primary.text != "다음 스테이지":
		errors.append("%s clear overlay primary CTA should be 다음 스테이지." % GAMEPLAY_SCENE_PATH)
	if overlay_secondary == null or not overlay_secondary.visible or overlay_secondary.text != "홈으로":
		errors.append("%s clear overlay secondary CTA should be visible 홈으로." % GAMEPLAY_SCENE_PATH)
	if String(node.call("_overlay_expression_state_for_testing")) != "smile":
		errors.append("%s clear overlay mascot should use smile expression fallback." % GAMEPLAY_SCENE_PATH)
	if not bool(node.call("_overlay_expression_tween_active_for_testing")):
		errors.append("%s clear overlay mascot should run a fallback expression tween." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("stage_complete") <= complete_events_before:
		errors.append("%s clear overlay runtime smoke should emit stage_complete analytics." % GAMEPLAY_SCENE_PATH)
	var token_reward := Dictionary(node.get("last_rescue_book_token_reward"))
	if not bool(token_reward.get("granted", false)) or String(token_reward.get("animal_id", "")) != "rabbit" or int(token_reward.get("amount", 0)) != 3:
		errors.append("%s Stage 1 clear should grant rabbit Rescue Book tokens once." % GAMEPLAY_SCENE_PATH)
	if _rescue_book_token_count("rabbit") != rabbit_tokens_before + 3:
		errors.append("%s Stage 1 clear should add exactly 3 rabbit tokens." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("animal_token_gain") != token_events_before + 1:
		errors.append("%s Stage 1 clear should emit one animal_token_gain event." % GAMEPLAY_SCENE_PATH)
	var stage_clear_token_event := _last_analytics_event_by_name("animal_token_gain")
	var stage_clear_token_params: Dictionary = Dictionary(stage_clear_token_event.get("params", {}))
	if String(stage_clear_token_params.get("animal_id", "")) != "rabbit" or String(stage_clear_token_params.get("source", "")) != "stage_clear" or int(stage_clear_token_params.get("stage_id", 0)) != 1 or int(stage_clear_token_params.get("amount", 0)) != 3:
		errors.append("%s Stage 1 token analytics should identify stage_clear rabbit +3." % GAMEPLAY_SCENE_PATH)
	await node.call("_check_stage_state")
	if _rescue_book_token_count("rabbit") != rabbit_tokens_before + 3 or _analytics_event_count("animal_token_gain") != token_events_before + 1:
		errors.append("%s repeated Stage 1 clear state check should not duplicate Rescue Book tokens or analytics." % GAMEPLAY_SCENE_PATH)
	var persisted_save := _validation_save_data()
	var persisted_animals := Dictionary(Dictionary(persisted_save.get("rescue_book", {})).get("animals", {}))
	var persisted_rabbit := Dictionary(persisted_animals.get("rabbit", {}))
	var persisted_claim_ids := Array(persisted_save.get("claimed_stage_token_reward_ids", []))
	if int(persisted_rabbit.get("tokens", -1)) != rabbit_tokens_before + 3 or not persisted_claim_ids.has("1:rabbit"):
		errors.append("%s Stage 1 Rescue Book token reward and claim key should persist in the same save." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 0)
	GameSession.set_stage_fail_count_for_testing(1, 0)
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	if overlay == null or not overlay.visible:
		errors.append("%s FTUE failure runtime smoke should show the failure overlay." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed":
		errors.append("%s FTUE failure runtime smoke should leave Stage 1 failed, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("stage_state"))])
	if String(node.get("overlay_action")) != "restart_stage":
		errors.append("%s FTUE failure overlay should use restart_stage action, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("overlay_action"))])
	if overlay_primary == null or overlay_primary.text != "무료 재도전":
		errors.append("%s FTUE failure primary CTA should be 무료 재도전." % GAMEPLAY_SCENE_PATH)
	if overlay_body == null or overlay_body.text.contains("보상형 +3 이동") or overlay_body.text.contains("부스터 팩"):
		errors.append("%s FTUE failure overlay should not expose rewarded ad or IAP copy." % GAMEPLAY_SCENE_PATH)
	if overlay_mascot == null or overlay_mascot.texture == null:
		errors.append("%s failure overlay should show a non-null failure mascot texture." % GAMEPLAY_SCENE_PATH)
	if String(node.call("_overlay_expression_state_for_testing")) != "worried":
		errors.append("%s failure overlay mascot should use worried expression fallback." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	var target_collect: Dictionary = Dictionary(node.call("_stage_collect_targets"))
	var near_miss_counts := {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	var fail_events_before := _analytics_event_count("stage_fail")
	var offer_events_before := _analytics_event_count("offer_impression")
	var offer_show_events_before := _analytics_event_count("fail_offer_show")
	var offer_select_events_before := _analytics_event_count("fail_offer_select")
	var offer_dismiss_events_before := _analytics_event_count("fail_offer_dismiss")
	var ad_complete_events_before := _analytics_event_count("ad_reward_complete")
	var ad_fail_events_before := _analytics_event_count("ad_reward_fail")
	var iap_start_events_before := _analytics_event_count("iap_purchase_start")
	var iap_complete_events_before := _analytics_event_count("iap_purchase_complete")
	var iap_restore_events_before := _analytics_event_count("iap_purchase_restore")
	var iap_cancel_events_before := _analytics_event_count("iap_purchase_cancel")
	var iap_fail_events_before := _analytics_event_count("iap_purchase_fail")
	var extra_moves_events_before := _analytics_event_count("extra_moves_grant")
	await node.call("_check_stage_state")
	if overlay == null or not overlay.visible:
		errors.append("%s near-miss failure runtime smoke should show the result overlay." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed":
		errors.append("%s near-miss failure runtime smoke should leave Stage 25 failed, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("stage_state"))])
	if String(node.get("overlay_action")) != "continue_stage":
		errors.append("%s near-miss failure overlay should use continue_stage action for +3 move CTA." % GAMEPLAY_SCENE_PATH)
	if overlay_primary == null or overlay_primary.text != "+3 이동 받고 계속":
		errors.append("%s near-miss failure primary CTA should offer +3 move continue." % GAMEPLAY_SCENE_PATH)
	if overlay_secondary == null or not overlay_secondary.visible or overlay_secondary.text != "재도전":
		errors.append("%s near-miss failure secondary CTA should offer retry." % GAMEPLAY_SCENE_PATH)
	if overlay_body == null or not overlay_body.text.contains("near_miss") or not overlay_body.text.contains("보상형 +3 이동") or not overlay_body.text.contains("추천 부스터 rainbow_paw"):
		errors.append("%s near-miss failure body should show fail type, rewarded move offer, and booster recommendation." % GAMEPLAY_SCENE_PATH)
	if overlay_body == null or not overlay_body.text.contains("놓친 핵심  덤불 1개 정리") or not overlay_body.text.contains("다음 한 수  덤불 옆에서 폭탄이나 줄무늬 특수 블록"):
		errors.append("%s near-miss failure body should isolate missed goal and one actionable retry hint." % GAMEPLAY_SCENE_PATH)
	await _validate_failure_overlay_text_stress(node, errors)
	if _analytics_event_count("stage_fail") <= fail_events_before:
		errors.append("%s near-miss failure runtime smoke should emit stage_fail analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("offer_impression") <= offer_events_before:
		errors.append("%s near-miss failure runtime smoke should emit offer_impression analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("fail_offer_show") <= offer_show_events_before:
		errors.append("%s near-miss failure runtime smoke should emit fail_offer_show analytics." % GAMEPLAY_SCENE_PATH)
	var stage_fail_event := _last_analytics_event_by_name("stage_fail")
	var stage_fail_params: Dictionary = Dictionary(stage_fail_event.get("params", {}))
	if int(stage_fail_params.get("stage_id", 0)) != 25 or String(stage_fail_params.get("fail_type", "")) != "near_miss" or String(stage_fail_params.get("offer_type", "")) != "rewarded_continue":
		errors.append("%s stage_fail analytics should identify Stage 25 near_miss rewarded_continue." % GAMEPLAY_SCENE_PATH)
	var offer_event := _last_analytics_event_by_name("offer_impression")
	var offer_params: Dictionary = Dictionary(offer_event.get("params", {}))
	if int(offer_params.get("stage_id", 0)) != 25 or String(offer_params.get("fail_type", "")) != "near_miss" or String(offer_params.get("primary_cta", "")) != "+3 이동 받고 계속" or not bool(offer_params.get("show_rewarded_ad", false)):
		errors.append("%s offer_impression analytics should identify Stage 25 near_miss +3 CTA." % GAMEPLAY_SCENE_PATH)
	var offer_show_event := _last_analytics_event_by_name("fail_offer_show")
	var offer_show_params: Dictionary = Dictionary(offer_show_event.get("params", {}))
	if int(offer_show_params.get("stage_id", 0)) != 25 or String(offer_show_params.get("fail_type", "")) != "near_miss" or int(offer_show_params.get("attempt_count", 0)) <= 0 or String(offer_show_params.get("offer_type", "")) != "rewarded_continue" or float(offer_show_params.get("progress_ratio", -1.0)) < 0.0:
		errors.append("%s fail_offer_show analytics should identify Stage 25 near_miss rewarded offer exposure." % GAMEPLAY_SCENE_PATH)

	var invalid_source_extra_before := _analytics_event_count("extra_moves_grant")
	MonetizationGateway.clear_request_log_for_testing()
	var invalid_gateway_result := MonetizationGateway.request_continue("mystery_sdk", 25, Dictionary(node.get("active_fail_offer")), {"transaction_id": "invalid-source-gateway"})
	if String(invalid_gateway_result.get("result", "")) != "failed" or String(invalid_gateway_result.get("request_status", "")) != "rejected_invalid_source":
		errors.append("%s MonetizationGateway should reject invalid continue sources before provider dispatch." % GAMEPLAY_SCENE_PATH)
	var invalid_gateway_log := _last_monetization_request_log()
	if String(invalid_gateway_log.get("source", "")) != "mystery_sdk" or String(invalid_gateway_log.get("request_status", "")) != "rejected_invalid_source":
		errors.append("%s MonetizationGateway should log rejected invalid continue source requests." % GAMEPLAY_SCENE_PATH)
	var invalid_gateway_details := Dictionary(invalid_gateway_log.get("details", {}))
	if String(invalid_gateway_details.get("error_code", "")) != "invalid_source":
		errors.append("%s MonetizationGateway invalid source rejection should carry invalid_source error metadata." % GAMEPLAY_SCENE_PATH)
	if bool(node.call("_resolve_fail_offer_continue_result", "mystery_sdk", "completed", {"transaction_id": "invalid-source-continue"})):
		errors.append("%s invalid fail offer continue source should not grant extra moves." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != 0:
		errors.append("%s invalid fail offer continue source should preserve failed state and moves." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != invalid_source_extra_before:
		errors.append("%s invalid fail offer continue source should not emit extra_moves_grant." % GAMEPLAY_SCENE_PATH)

	MonetizationGateway.reset_for_testing()
	monetization_adapter_requests.clear()
	MonetizationGateway.configure_continue_adapter("adapter_validation_provider", Callable(self, "_monetization_adapter_pending_response"))
	var adapter_invalid_result := MonetizationGateway.request_continue("mystery_sdk", 25, Dictionary(node.get("active_fail_offer")), {"transaction_id": "adapter-invalid-source"})
	if String(adapter_invalid_result.get("request_status", "")) != "rejected_invalid_source":
		errors.append("%s MonetizationGateway adapter should still reject invalid sources before provider dispatch." % GAMEPLAY_SCENE_PATH)
	if not monetization_adapter_requests.is_empty():
		errors.append("%s MonetizationGateway should not invoke continue adapter for unsupported sources." % GAMEPLAY_SCENE_PATH)

	MonetizationGateway.clear_request_log_for_testing()
	MonetizationGateway.queue_continue_result_for_testing("rewarded_ad", "completed", {"transaction_id": "queued-adapter-priority", "ad_network": "queued_priority"})
	var queued_adapter_result := MonetizationGateway.request_continue("rewarded_ad", 25, Dictionary(node.get("active_fail_offer")), {"transaction_id": "request-detail-should-not-win"})
	if not monetization_adapter_requests.is_empty():
		errors.append("%s MonetizationGateway queued result should take priority over continue adapter." % GAMEPLAY_SCENE_PATH)
	if String(queued_adapter_result.get("result", "")) != "completed":
		errors.append("%s MonetizationGateway queued result should preserve queued result precedence." % GAMEPLAY_SCENE_PATH)

	MonetizationGateway.clear_request_log_for_testing()
	var adapter_gateway_result := MonetizationGateway.request_continue("rewarded_ad", 25, Dictionary(node.get("active_fail_offer")), {"transaction_id": "request-detail-transaction", "ad_network": "request_detail_network"})
	if monetization_adapter_requests.size() != 1:
		errors.append("%s MonetizationGateway should invoke continue adapter exactly once for supported unqueued requests." % GAMEPLAY_SCENE_PATH)
	if String(adapter_gateway_result.get("result", "")) != MonetizationGateway.RESULT_PENDING:
		errors.append("%s MonetizationGateway continue adapter should normalize pending provider results." % GAMEPLAY_SCENE_PATH)
	var adapter_gateway_details := Dictionary(adapter_gateway_result.get("details", {}))
	if String(adapter_gateway_details.get("transaction_id", "")) != "adapter-pending-validation" or String(adapter_gateway_details.get("ad_network", "")) != "adapter_validation":
		errors.append("%s MonetizationGateway continue adapter result details should win over request payload mutations." % GAMEPLAY_SCENE_PATH)
	var adapter_gateway_log := _last_monetization_request_log()
	_validate_monetization_request_log(adapter_gateway_log, "rewarded_ad", 25, "near_miss", MonetizationGateway.RESULT_PENDING, "resolved", "adapter_validation_provider", errors)
	if not monetization_adapter_requests.is_empty():
		var adapter_request: Dictionary = Dictionary(monetization_adapter_requests[0])
		var adapter_request_details := Dictionary(adapter_request.get("details", {}))
		if String(adapter_request.get("source", "")) != "rewarded_ad" or int(adapter_request.get("stage_id", 0)) != 25 or String(adapter_request.get("provider_id", "")) != "adapter_validation_provider":
			errors.append("%s MonetizationGateway continue adapter request should include normalized source, stage, and provider metadata." % GAMEPLAY_SCENE_PATH)
		if String(adapter_request.get("fail_type", "")) != "near_miss" or String(adapter_request_details.get("transaction_id", "")) != "request-detail-transaction":
			errors.append("%s MonetizationGateway continue adapter request should include fail offer and request details." % GAMEPLAY_SCENE_PATH)

	_validate_monetization_adapter_alias_result(Dictionary(node.get("active_fail_offer")), "adapter_success_alias_provider", Callable(self, "_monetization_adapter_success_alias_response"), MonetizationGateway.RESULT_COMPLETED, {"transaction_id": "adapter-success-alias-validation", "ad_network": "adapter_success_alias", "provider_result": "success"}, "%s adapter success alias" % GAMEPLAY_SCENE_PATH, errors)
	_validate_monetization_adapter_alias_result(Dictionary(node.get("active_fail_offer")), "adapter_cancelled_alias_provider", Callable(self, "_monetization_adapter_cancelled_alias_response"), MonetizationGateway.RESULT_FAILED, {"transaction_id": "adapter-cancelled-alias-validation", "error_code": "user_cancelled", "provider_result": "cancelled"}, "%s adapter cancelled alias" % GAMEPLAY_SCENE_PATH, errors)
	_validate_monetization_adapter_alias_result(Dictionary(node.get("active_fail_offer")), "adapter_in_progress_alias_provider", Callable(self, "_monetization_adapter_in_progress_alias_response"), MonetizationGateway.RESULT_PENDING, {"transaction_id": "adapter-in-progress-alias-validation", "ad_network": "adapter_pending_alias", "provider_result": "in_progress"}, "%s adapter in_progress alias" % GAMEPLAY_SCENE_PATH, errors)
	_validate_monetization_adapter_alias_result(Dictionary(node.get("active_fail_offer")), "adapter_unknown_alias_provider", Callable(self, "_monetization_adapter_unknown_response"), MonetizationGateway.RESULT_FAILED, {"transaction_id": "adapter-unknown-alias-validation", "error_code": "sdk_weird_state", "provider_result": "sdk_weird_state"}, "%s adapter unknown result" % GAMEPLAY_SCENE_PATH, errors)
	MonetizationGateway.reset_for_testing()

	var wallet_before_failed_continue := GameSession.get_wallet()
	var failed_continue_score := int(node.get("score"))
	var failed_continue_blockers := int(node.get("cleared_blockers"))
	var failed_continue_moves := int(node.get("remaining_moves"))
	var failed_continue_result := bool(node.call("_resolve_fail_offer_continue_result", "rewarded_ad", "failed", {"ad_network": "validation", "error_code": "load_failed"}))
	if failed_continue_result:
		errors.append("%s rewarded ad failure should not grant fail offer continue." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != failed_continue_moves or int(node.get("score")) != failed_continue_score or int(node.get("cleared_blockers")) != failed_continue_blockers:
		errors.append("%s rewarded ad failure should preserve failed stage state, moves, score, and blockers." % GAMEPLAY_SCENE_PATH)
	if overlay == null or not overlay.visible or String(node.get("overlay_action")) != "continue_stage":
		errors.append("%s rewarded ad failure should keep the continue offer overlay visible." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != extra_moves_events_before:
		errors.append("%s rewarded ad failure should not emit extra_moves_grant." % GAMEPLAY_SCENE_PATH)
	if int(GameSession.get_wallet().get("gold", 0)) != int(wallet_before_failed_continue.get("gold", 0)):
		errors.append("%s rewarded ad failure should not change wallet gold." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("ad_reward_fail") <= ad_fail_events_before:
		errors.append("%s rewarded ad failure should emit ad_reward_fail analytics." % GAMEPLAY_SCENE_PATH)
	var ad_fail_event := _last_analytics_event_by_name("ad_reward_fail")
	var ad_fail_params: Dictionary = Dictionary(ad_fail_event.get("params", {}))
	if int(ad_fail_params.get("stage_id", 0)) != 25 or String(ad_fail_params.get("placement", "")) != "fail_offer" or String(ad_fail_params.get("reward_type", "")) != "extra_moves" or String(ad_fail_params.get("error_code", "")) != "load_failed":
		errors.append("%s ad_reward_fail should identify Stage 25 fail offer extra move failure." % GAMEPLAY_SCENE_PATH)

	node.call("_resolve_fail_offer_continue_result", "iap", "cancelled", {"product_id": "validation_pack", "price": 1.99, "currency": "USD"})
	node.call("_resolve_fail_offer_continue_result", "iap", "failed", {"product_id": "validation_pack", "price": 1.99, "currency": "USD", "error_code": "billing_failed"})
	var iap_restore_result := bool(node.call("_resolve_fail_offer_continue_result", "iap", "restored", {"product_id": "validation_pack", "price": 1.99, "currency": "USD", "restored_transaction_id": "old-validation-transaction"}))
	if iap_restore_result:
		errors.append("%s IAP restore smoke should not grant current fail offer continue." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_start") < iap_start_events_before + 3:
		errors.append("%s IAP cancel/fail/restore smoke should emit iap_purchase_start for each purchase attempt." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_cancel") <= iap_cancel_events_before:
		errors.append("%s IAP cancel smoke should emit iap_purchase_cancel analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_fail") <= iap_fail_events_before:
		errors.append("%s IAP failure smoke should emit iap_purchase_fail analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_restore") <= iap_restore_events_before:
		errors.append("%s IAP restore smoke should emit iap_purchase_restore analytics." % GAMEPLAY_SCENE_PATH)
	var iap_restore_event := _last_analytics_event_by_name("iap_purchase_restore")
	var iap_restore_params: Dictionary = Dictionary(iap_restore_event.get("params", {}))
	if String(iap_restore_params.get("product_id", "")) != "validation_pack" or String(iap_restore_params.get("placement", "")) != "fail_offer" or String(iap_restore_params.get("restore_result", "")) != "restored" or String(iap_restore_params.get("restored_transaction_id", "")) != "old-validation-transaction":
		errors.append("%s iap_purchase_restore should identify restored fail offer purchase metadata." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != failed_continue_moves or int(GameSession.get_wallet().get("gold", 0)) != int(wallet_before_failed_continue.get("gold", 0)):
		errors.append("%s IAP cancel/fail/restore should preserve failed state, moves, and wallet." % GAMEPLAY_SCENE_PATH)
	if overlay == null or not overlay.visible or String(node.get("overlay_action")) != "continue_stage":
		errors.append("%s IAP cancel/fail/restore should keep the continue offer overlay visible." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != extra_moves_events_before:
		errors.append("%s IAP cancel/fail/restore should not emit extra_moves_grant." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_complete") != iap_complete_events_before:
		errors.append("%s IAP cancel/fail/restore should not emit iap_purchase_complete." % GAMEPLAY_SCENE_PATH)

	await _prepare_stage_25_near_miss_failure(node)
	failed_continue_moves = int(node.get("remaining_moves"))
	var iap_provider_cancel_start_before := _analytics_event_count("iap_purchase_start")
	var iap_provider_cancel_before := _analytics_event_count("iap_purchase_cancel")
	var iap_provider_cancel_fail_before := _analytics_event_count("iap_purchase_fail")
	var iap_provider_cancel_extra_before := _analytics_event_count("extra_moves_grant")
	var iap_provider_cancel_result := bool(node.call("_resolve_fail_offer_continue_result", "iap", MonetizationGateway.RESULT_FAILED, {"provider_result": "cancelled", "product_id": "validation_pack", "price": 1.99, "currency": "USD", "transaction_id": "iap-provider-cancel-alias"}))
	if iap_provider_cancel_result:
		errors.append("%s canonical failed IAP with provider_result=cancelled should not grant continue." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_start") != iap_provider_cancel_start_before + 1:
		errors.append("%s canonical failed IAP cancel alias should emit one iap_purchase_start." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_cancel") != iap_provider_cancel_before + 1:
		errors.append("%s canonical failed IAP cancel alias should emit iap_purchase_cancel, not generic failure." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_fail") != iap_provider_cancel_fail_before:
		errors.append("%s canonical failed IAP cancel alias should not emit iap_purchase_fail." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != iap_provider_cancel_extra_before:
		errors.append("%s canonical failed IAP cancel alias should not emit extra_moves_grant." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != failed_continue_moves or overlay == null or not overlay.visible:
		errors.append("%s canonical failed IAP cancel alias should preserve failed overlay state." % GAMEPLAY_SCENE_PATH)

	MonetizationGateway.reset_for_testing()
	monetization_adapter_requests.clear()
	MonetizationGateway.configure_continue_adapter("adapter_pending_provider", Callable(self, "_monetization_adapter_pending_response"))
	var adapter_pending_extra_before := _analytics_event_count("extra_moves_grant")
	var adapter_pending_ad_fail_before := _analytics_event_count("ad_reward_fail")
	var adapter_pending_ad_complete_before := _analytics_event_count("ad_reward_complete")
	node.call("_on_overlay_primary_button_pressed")
	if monetization_adapter_requests.size() != 1:
		errors.append("%s pending rewarded ad adapter request should invoke one provider request." % GAMEPLAY_SCENE_PATH)
	if not bool(node.get("active_fail_offer_continue_pending")) or String(node.get("active_fail_offer_continue_pending_source")) != "rewarded_ad":
		errors.append("%s pending rewarded ad adapter request should set pending state." % GAMEPLAY_SCENE_PATH)
	var adapter_pending_log := _last_monetization_request_log()
	_validate_monetization_request_log(adapter_pending_log, "rewarded_ad", 25, "near_miss", MonetizationGateway.RESULT_PENDING, "resolved", "adapter_pending_provider", errors)
	node.call("_on_overlay_primary_button_pressed")
	if monetization_adapter_requests.size() != 1:
		errors.append("%s duplicate pending rewarded ad adapter primary tap should not create a second provider request." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != adapter_pending_extra_before or _analytics_event_count("ad_reward_fail") != adapter_pending_ad_fail_before or _analytics_event_count("ad_reward_complete") != adapter_pending_ad_complete_before:
		errors.append("%s pending rewarded ad adapter request should not emit grant, failure, or completion analytics before callback." % GAMEPLAY_SCENE_PATH)
	node.call("_resolve_fail_offer_continue_result", "rewarded_ad", "failed", {"ad_network": "adapter_validation", "error_code": "adapter_pending_failed"})
	MonetizationGateway.reset_for_testing()
	await _prepare_stage_25_near_miss_failure(node)
	failed_continue_moves = int(node.get("remaining_moves"))

	MonetizationGateway.clear_request_log_for_testing()
	MonetizationGateway.set_provider_id_for_testing("gateway_pending_provider")
	MonetizationGateway.queue_continue_result_for_testing("rewarded_ad", MonetizationGateway.RESULT_PENDING, {"ad_network": "gateway_pending", "transaction_id": "gateway-pending-continue"})
	var pending_extra_before := _analytics_event_count("extra_moves_grant")
	var pending_ad_fail_before := _analytics_event_count("ad_reward_fail")
	var pending_ad_complete_before := _analytics_event_count("ad_reward_complete")
	var pending_iap_complete_before := _analytics_event_count("iap_purchase_complete")
	var pending_offer_select_before := _analytics_event_count("fail_offer_select")
	node.call("_on_overlay_primary_button_pressed")
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != failed_continue_moves:
		errors.append("%s pending rewarded ad gateway request should preserve failed stage state and moves." % GAMEPLAY_SCENE_PATH)
	if overlay == null or not overlay.visible or String(node.get("overlay_action")) != "continue_stage":
		errors.append("%s pending rewarded ad gateway request should keep continue overlay visible." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != pending_extra_before or _analytics_event_count("ad_reward_fail") != pending_ad_fail_before or _analytics_event_count("ad_reward_complete") != pending_ad_complete_before:
		errors.append("%s pending rewarded ad gateway request should not emit grant, failure, or completion analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("fail_offer_select") != pending_offer_select_before + 1:
		errors.append("%s pending rewarded ad first primary tap should emit one fail_offer_select analytics event." % GAMEPLAY_SCENE_PATH)
	if not bool(node.get("active_fail_offer_continue_pending")) or String(node.get("active_fail_offer_continue_pending_source")) != "rewarded_ad":
		errors.append("%s pending rewarded ad request should set pending source state." % GAMEPLAY_SCENE_PATH)
	var pending_log := _last_monetization_request_log()
	_validate_monetization_request_log(pending_log, "rewarded_ad", 25, "near_miss", MonetizationGateway.RESULT_PENDING, "resolved", "gateway_pending_provider", errors)
	var pending_log_count := MonetizationGateway.get_request_log_for_testing().size()
	node.call("_on_overlay_primary_button_pressed")
	if MonetizationGateway.get_request_log_for_testing().size() != pending_log_count:
		errors.append("%s pending rewarded ad gateway request should block duplicate primary CTA SDK requests." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != pending_extra_before or _analytics_event_count("ad_reward_fail") != pending_ad_fail_before or _analytics_event_count("ad_reward_complete") != pending_ad_complete_before:
		errors.append("%s duplicate pending rewarded ad primary tap should not emit grant, failure, or completion analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("fail_offer_select") != pending_offer_select_before + 1:
		errors.append("%s duplicate pending rewarded ad primary tap should not emit another fail_offer_select analytics event." % GAMEPLAY_SCENE_PATH)
	if bool(node.call("_resolve_fail_offer_continue_result", "purchase", "completed", {"transaction_id": "wrong-source-pending"})):
		errors.append("%s pending rewarded ad should reject completed callbacks from a different continue source." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_complete") != pending_iap_complete_before or _analytics_event_count("extra_moves_grant") != pending_extra_before:
		errors.append("%s pending rewarded ad should not emit IAP completion or grant analytics for wrong-source callbacks." % GAMEPLAY_SCENE_PATH)
	if not bool(node.get("active_fail_offer_continue_pending")) or String(node.get("active_fail_offer_continue_pending_source")) != "rewarded_ad":
		errors.append("%s wrong-source pending callback should keep rewarded_ad pending state." % GAMEPLAY_SCENE_PATH)
	var pending_failure_result := bool(node.call("_resolve_fail_offer_continue_result", "rewarded", "failed", {"ad_network": "gateway_pending", "error_code": "pending_failed"}))
	if pending_failure_result:
		errors.append("%s pending rewarded ad failure callback should not grant continue." % GAMEPLAY_SCENE_PATH)
	if bool(node.get("active_fail_offer_continue_pending")) or not String(node.get("active_fail_offer_continue_pending_source")).is_empty():
		errors.append("%s pending rewarded ad failure callback should clear pending state." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("ad_reward_fail") != pending_ad_fail_before + 1:
		errors.append("%s pending rewarded ad failure callback should emit ad_reward_fail once." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != pending_extra_before or _analytics_event_count("ad_reward_complete") != pending_ad_complete_before:
		errors.append("%s pending rewarded ad failure callback should not emit grant or completion analytics." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != failed_continue_moves or overlay == null or not overlay.visible:
		errors.append("%s pending rewarded ad failure callback should preserve failed overlay state." % GAMEPLAY_SCENE_PATH)

	MonetizationGateway.queue_continue_result_for_testing("rewarded_ad", MonetizationGateway.RESULT_PENDING, {"ad_network": "gateway_pending", "transaction_id": "gateway-pending-continue"})
	node.call("_on_overlay_primary_button_pressed")
	var pending_completion_result := bool(node.call("_resolve_fail_offer_continue_result", "rewarded_ad", "completed", {"ad_network": "gateway_pending", "transaction_id": "gateway-pending-continue"}))
	if not pending_completion_result:
		errors.append("%s pending rewarded ad callback should grant continue when completed." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "playing" or int(node.get("remaining_moves")) != 3:
		errors.append("%s pending rewarded ad completion should resume play with 3 moves." % GAMEPLAY_SCENE_PATH)
	if bool(node.get("active_fail_offer_continue_pending")) or not String(node.get("active_fail_offer_continue_pending_source")).is_empty():
		errors.append("%s pending rewarded ad completion should clear pending state." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("ad_reward_complete") <= pending_ad_complete_before or _analytics_event_count("extra_moves_grant") <= pending_extra_before:
		errors.append("%s pending rewarded ad completion should emit completion and grant analytics." % GAMEPLAY_SCENE_PATH)

	await _prepare_stage_25_near_miss_failure(node)
	failed_continue_moves = int(node.get("remaining_moves"))
	var iap_pending_start_before := _analytics_event_count("iap_purchase_start")
	var iap_pending_complete_before := _analytics_event_count("iap_purchase_complete")
	var iap_pending_fail_before := _analytics_event_count("iap_purchase_fail")
	var iap_pending_cancel_before := _analytics_event_count("iap_purchase_cancel")
	var iap_pending_restore_before := _analytics_event_count("iap_purchase_restore")
	var iap_pending_extra_before := _analytics_event_count("extra_moves_grant")
	if bool(node.call("_resolve_fail_offer_continue_result", "purchase", MonetizationGateway.RESULT_PENDING, {"product_id": "pending_pack", "price": 1.99, "currency": "USD", "transaction_id": "iap-pending-validation"})):
		errors.append("%s pending IAP request should not grant continue before provider completion." % GAMEPLAY_SCENE_PATH)
	if not bool(node.get("active_fail_offer_continue_pending")) or String(node.get("active_fail_offer_continue_pending_source")) != "iap":
		errors.append("%s pending IAP request should set pending source state." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_start") != iap_pending_start_before + 1:
		errors.append("%s pending IAP request should emit exactly one iap_purchase_start." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_complete") != iap_pending_complete_before or _analytics_event_count("iap_purchase_fail") != iap_pending_fail_before or _analytics_event_count("iap_purchase_cancel") != iap_pending_cancel_before or _analytics_event_count("iap_purchase_restore") != iap_pending_restore_before or _analytics_event_count("extra_moves_grant") != iap_pending_extra_before:
		errors.append("%s pending IAP request should not emit final purchase or grant analytics." % GAMEPLAY_SCENE_PATH)
	node.call("_resolve_fail_offer_continue_result", "iap", MonetizationGateway.RESULT_PENDING, {"product_id": "pending_pack", "price": 1.99, "currency": "USD", "transaction_id": "iap-pending-validation"})
	if _analytics_event_count("iap_purchase_start") != iap_pending_start_before + 1:
		errors.append("%s duplicate pending IAP callback should not emit another iap_purchase_start." % GAMEPLAY_SCENE_PATH)
	var iap_pending_complete_result := bool(node.call("_resolve_fail_offer_continue_result", "iap", "completed", {"product_id": "pending_pack", "price": 1.99, "currency": "USD", "transaction_id": "iap-pending-validation"}))
	if not iap_pending_complete_result:
		errors.append("%s pending IAP completion callback should grant continue." % GAMEPLAY_SCENE_PATH)
	if bool(node.get("active_fail_offer_continue_pending")) or not String(node.get("active_fail_offer_continue_pending_source")).is_empty():
		errors.append("%s pending IAP completion callback should clear pending state." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_start") != iap_pending_start_before + 1:
		errors.append("%s pending IAP completion callback should not emit a duplicate purchase start." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_complete") <= iap_pending_complete_before or _analytics_event_count("extra_moves_grant") <= iap_pending_extra_before:
		errors.append("%s pending IAP completion callback should emit purchase complete and grant analytics." % GAMEPLAY_SCENE_PATH)

	await _prepare_stage_25_near_miss_failure(node)
	failed_continue_moves = int(node.get("remaining_moves"))

	MonetizationGateway.clear_request_log_for_testing()
	MonetizationGateway.set_provider_id_for_testing("gateway_validation_provider")
	MonetizationGateway.queue_continue_result_for_testing("rewarded_ad", "failed", {"ad_network": "gateway_validation", "error_code": "gateway_load_failed"})
	var gateway_fail_extra_before := _analytics_event_count("extra_moves_grant")
	var gateway_fail_ad_fail_before := _analytics_event_count("ad_reward_fail")
	node.call("_on_overlay_primary_button_pressed")
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != failed_continue_moves:
		errors.append("%s queued rewarded ad gateway failure should preserve failed stage state and moves." % GAMEPLAY_SCENE_PATH)
	if overlay == null or not overlay.visible or String(node.get("overlay_action")) != "continue_stage":
		errors.append("%s queued rewarded ad gateway failure should keep continue overlay visible." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != gateway_fail_extra_before:
		errors.append("%s queued rewarded ad gateway failure should not grant extra moves." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("ad_reward_fail") <= gateway_fail_ad_fail_before:
		errors.append("%s queued rewarded ad gateway failure should emit ad_reward_fail." % GAMEPLAY_SCENE_PATH)
	var gateway_fail_event := _last_analytics_event_by_name("ad_reward_fail")
	var gateway_fail_params: Dictionary = Dictionary(gateway_fail_event.get("params", {}))
	if String(gateway_fail_params.get("ad_network", "")) != "gateway_validation" or String(gateway_fail_params.get("error_code", "")) != "gateway_load_failed":
		errors.append("%s queued rewarded ad gateway failure should pass provider error details." % GAMEPLAY_SCENE_PATH)
	var gateway_fail_log := _last_monetization_request_log()
	_validate_monetization_request_log(gateway_fail_log, "rewarded_ad", 25, "near_miss", "failed", "resolved", "gateway_validation_provider", errors)
	var gateway_fail_log_details := Dictionary(gateway_fail_log.get("details", {}))
	if String(gateway_fail_log_details.get("error_code", "")) != "gateway_load_failed":
		errors.append("%s MonetizationGateway failure request log should preserve provider error metadata." % GAMEPLAY_SCENE_PATH)

	MonetizationGateway.queue_continue_result_for_testing("rewarded_ad", "completed", {"ad_network": "gateway_validation", "transaction_id": "gateway-validation-continue"})
	node.call("_on_overlay_primary_button_pressed")
	if String(node.get("stage_state")) != "playing" or int(node.get("remaining_moves")) != 3:
		errors.append("%s continue_stage primary action should resume play with exactly 3 moves." % GAMEPLAY_SCENE_PATH)
	if overlay != null and overlay.visible:
		errors.append("%s continue_stage primary action should hide the failure overlay." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("fail_offer_select") <= offer_select_events_before:
		errors.append("%s continue_stage primary action should emit fail_offer_select analytics." % GAMEPLAY_SCENE_PATH)
	var select_event := _last_analytics_event_by_name("fail_offer_select")
	var select_params: Dictionary = Dictionary(select_event.get("params", {}))
	if int(select_params.get("stage_id", 0)) != 25 or String(select_params.get("fail_type", "")) != "near_miss" or String(select_params.get("offer_type", "")) != "rewarded_continue" or String(select_params.get("cost_type", "")) != "rewarded_ad" or int(select_params.get("cost_amount", -1)) != 1:
		errors.append("%s fail_offer_select should identify Stage 25 rewarded continue selection." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") <= extra_moves_events_before:
		errors.append("%s continue_stage primary action should emit extra_moves_grant analytics." % GAMEPLAY_SCENE_PATH)
	var extra_moves_event := _last_analytics_event_by_name("extra_moves_grant")
	var extra_moves_params: Dictionary = Dictionary(extra_moves_event.get("params", {}))
	if int(extra_moves_params.get("stage_id", 0)) != 25 or String(extra_moves_params.get("source", "")) != "fail_offer_continue" or int(extra_moves_params.get("moves_amount", 0)) != 3 or String(extra_moves_params.get("transaction_id", "")).is_empty():
		errors.append("%s extra_moves_grant should identify Stage 25 +3 rewarded continue grant." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("ad_reward_complete") <= ad_complete_events_before:
		errors.append("%s rewarded continue should emit ad_reward_complete analytics." % GAMEPLAY_SCENE_PATH)
	var ad_complete_event := _last_analytics_event_by_name("ad_reward_complete")
	var ad_complete_params: Dictionary = Dictionary(ad_complete_event.get("params", {}))
	if String(ad_complete_params.get("transaction_id", "")) != String(extra_moves_params.get("transaction_id", "")) or int(ad_complete_params.get("reward_amount", 0)) != 3:
		errors.append("%s ad_reward_complete should share transaction_id and move amount with extra_moves_grant." % GAMEPLAY_SCENE_PATH)
	if String(ad_complete_params.get("transaction_id", "")) != "gateway-validation-continue" or String(ad_complete_params.get("ad_network", "")) != "gateway_validation":
		errors.append("%s rewarded continue primary action should route through MonetizationGateway metadata." % GAMEPLAY_SCENE_PATH)
	var gateway_success_log := _last_monetization_request_log()
	_validate_monetization_request_log(gateway_success_log, "rewarded_ad", 25, "near_miss", "completed", "resolved", "gateway_validation_provider", errors)
	var gateway_success_log_details := Dictionary(gateway_success_log.get("details", {}))
	if String(gateway_success_log_details.get("transaction_id", "")) != "gateway-validation-continue":
		errors.append("%s MonetizationGateway success request log should preserve provider transaction metadata." % GAMEPLAY_SCENE_PATH)
	var extra_moves_after_primary := _analytics_event_count("extra_moves_grant")
	var moves_after_primary := int(node.get("remaining_moves"))
	if bool(node.call("_resolve_fail_offer_continue_result", "rewarded_ad", "completed")):
		errors.append("%s duplicate rewarded continue callback after overlay close should be ignored." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != extra_moves_after_primary or int(node.get("remaining_moves")) != moves_after_primary:
		errors.append("%s duplicate rewarded continue callback should not grant moves twice." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	target_collect = Dictionary(node.call("_stage_collect_targets"))
	near_miss_counts = {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	var ad_stable_transaction_extra_before := _analytics_event_count("extra_moves_grant")
	var ad_stable_transaction_complete_before := _analytics_event_count("ad_reward_complete")
	var ad_stable_transaction_result := bool(node.call("_resolve_fail_offer_continue_result", "rewarded_ad", "completed", {"ad_network": "validation", "transaction_id": "ad-validation-continue"}))
	if not ad_stable_transaction_result:
		errors.append("%s stable rewarded ad transaction should grant extra moves once." % GAMEPLAY_SCENE_PATH)
	var ad_stable_transaction_moves := int(node.get("remaining_moves"))
	if String(node.get("stage_state")) != "playing" or ad_stable_transaction_moves != 3:
		errors.append("%s stable rewarded ad transaction should resume play with 3 moves." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("ad_reward_complete") <= ad_stable_transaction_complete_before or _analytics_event_count("extra_moves_grant") <= ad_stable_transaction_extra_before:
		errors.append("%s stable rewarded ad transaction should emit completion and grant analytics once." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	target_collect = Dictionary(node.call("_stage_collect_targets"))
	near_miss_counts = {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	var duplicate_ad_extra_before := _analytics_event_count("extra_moves_grant")
	var duplicate_ad_complete_before := _analytics_event_count("ad_reward_complete")
	var duplicate_ad_result := bool(node.call("_resolve_fail_offer_continue_result", "rewarded_ad", "completed", {"ad_network": "validation", "transaction_id": "ad-validation-continue"}))
	if duplicate_ad_result:
		errors.append("%s duplicate rewarded ad transaction should be rejected across stage restarts." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != 0:
		errors.append("%s duplicate rewarded ad transaction should preserve failed state and moves." % GAMEPLAY_SCENE_PATH)
	if overlay == null or not overlay.visible or String(node.get("overlay_action")) != "continue_stage":
		errors.append("%s duplicate rewarded ad transaction should keep the continue offer overlay visible." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != duplicate_ad_extra_before or _analytics_event_count("ad_reward_complete") != duplicate_ad_complete_before:
		errors.append("%s duplicate rewarded ad transaction should not emit completion or grant analytics again." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	target_collect = Dictionary(node.call("_stage_collect_targets"))
	near_miss_counts = {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	var iap_success_extra_moves_before := _analytics_event_count("extra_moves_grant")
	var iap_success_complete_before := _analytics_event_count("iap_purchase_complete")
	await node.call("_check_stage_state")
	var iap_success_result := bool(node.call("_resolve_fail_offer_continue_result", "iap", "completed", {"product_id": "validation_pack", "price": 1.99, "currency": "USD", "transaction_id": "iap-validation-continue"}))
	if not iap_success_result:
		errors.append("%s IAP completed continue should grant extra moves." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "playing" or int(node.get("remaining_moves")) != 3:
		errors.append("%s IAP completed continue should resume play with exactly 3 moves." % GAMEPLAY_SCENE_PATH)
	if overlay != null and overlay.visible:
		errors.append("%s IAP completed continue should hide the failure overlay after success." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_complete") <= iap_success_complete_before:
		errors.append("%s IAP completed continue should emit iap_purchase_complete analytics." % GAMEPLAY_SCENE_PATH)
	var iap_complete_event := _last_analytics_event_by_name("iap_purchase_complete")
	var iap_complete_params: Dictionary = Dictionary(iap_complete_event.get("params", {}))
	if String(iap_complete_params.get("product_id", "")) != "validation_pack" or String(iap_complete_params.get("transaction_id", "")) != "iap-validation-continue" or String(iap_complete_params.get("currency", "")) != "USD":
		errors.append("%s iap_purchase_complete should identify the completed fail offer purchase." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") <= iap_success_extra_moves_before:
		errors.append("%s IAP completed continue should emit extra_moves_grant analytics." % GAMEPLAY_SCENE_PATH)
	var iap_extra_event := _last_analytics_event_by_name("extra_moves_grant")
	var iap_extra_params: Dictionary = Dictionary(iap_extra_event.get("params", {}))
	if String(iap_extra_params.get("source", "")) != "iap_continue" or int(iap_extra_params.get("moves_amount", 0)) != 3 or String(iap_extra_params.get("transaction_id", "")) != "iap-validation-continue":
		errors.append("%s IAP extra_moves_grant should share transaction_id and identify iap_continue." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	target_collect = Dictionary(node.call("_stage_collect_targets"))
	near_miss_counts = {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	var duplicate_iap_extra_before := _analytics_event_count("extra_moves_grant")
	var duplicate_iap_start_before := _analytics_event_count("iap_purchase_start")
	var duplicate_iap_complete_before := _analytics_event_count("iap_purchase_complete")
	var duplicate_iap_result := bool(node.call("_resolve_fail_offer_continue_result", "iap", "completed", {"product_id": "validation_pack", "price": 1.99, "currency": "USD", "transaction_id": "iap-validation-continue"}))
	if duplicate_iap_result:
		errors.append("%s duplicate IAP transaction should be rejected across stage restarts." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != 0:
		errors.append("%s duplicate IAP transaction should preserve failed state and moves." % GAMEPLAY_SCENE_PATH)
	if overlay == null or not overlay.visible or String(node.get("overlay_action")) != "continue_stage":
		errors.append("%s duplicate IAP transaction should keep the continue offer overlay visible." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_start") != duplicate_iap_start_before:
		errors.append("%s duplicate IAP transaction should not emit another iap_purchase_start callback." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != duplicate_iap_extra_before or _analytics_event_count("iap_purchase_complete") != duplicate_iap_complete_before:
		errors.append("%s duplicate IAP transaction should not emit purchase complete or grant analytics again." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	target_collect = Dictionary(node.call("_stage_collect_targets"))
	near_miss_counts = {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	node.call("_on_overlay_secondary_button_pressed")
	if _analytics_event_count("fail_offer_dismiss") <= offer_dismiss_events_before:
		errors.append("%s continue_stage secondary action should emit fail_offer_dismiss analytics." % GAMEPLAY_SCENE_PATH)
	var dismiss_event := _last_analytics_event_by_name("fail_offer_dismiss")
	var dismiss_params: Dictionary = Dictionary(dismiss_event.get("params", {}))
	if int(dismiss_params.get("stage_id", 0)) != 25 or String(dismiss_params.get("fail_type", "")) != "near_miss" or String(dismiss_params.get("dismiss_action", "")) != "retry" or int(dismiss_params.get("elapsed_ms", -1)) < 0:
		errors.append("%s fail_offer_dismiss should identify Stage 25 retry dismissal." % GAMEPLAY_SCENE_PATH)
	var current_stage: Dictionary = Dictionary(node.call("_current_stage"))
	if int(node.call("_current_stage_id")) != 25 or String(node.get("stage_state")) != "playing":
		errors.append("%s continue_stage secondary retry should restart Stage 25 in playing state." % GAMEPLAY_SCENE_PATH)
	if int(node.get("remaining_moves")) != int(current_stage.get("moves", 0)):
		errors.append("%s continue_stage secondary retry should restore Stage 25 moves, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("remaining_moves"))])
	if int(node.get("score")) != 0 or int(node.get("cleared_blockers")) != 0:
		errors.append("%s continue_stage secondary retry should reset score and cleared blockers." % GAMEPLAY_SCENE_PATH)
	if overlay != null and overlay.visible:
		errors.append("%s continue_stage secondary retry should leave overlay hidden after restart." % GAMEPLAY_SCENE_PATH)
	if not Dictionary(node.get("active_fail_offer")).is_empty():
		errors.append("%s continue_stage secondary retry should clear active_fail_offer." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	GameSession.set_wallet_for_testing({"gold": 200, "tokens": 0, "boosters": {}})
	target_collect = Dictionary(node.call("_stage_collect_targets"))
	near_miss_counts = {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	var coin_extra_moves_before := _analytics_event_count("extra_moves_grant")
	await node.call("_check_stage_state")
	if not bool(node.call("_resolve_fail_offer_continue_result", "coins", "completed", {"cost_amount": 120})):
		errors.append("%s coin continue should grant extra moves when wallet has enough gold." % GAMEPLAY_SCENE_PATH)
	var coin_wallet := GameSession.get_wallet()
	if int(coin_wallet.get("gold", 0)) != 80:
		errors.append("%s coin continue should spend exactly 120 gold, got wallet %s." % [GAMEPLAY_SCENE_PATH, str(coin_wallet)])
	if String(node.get("stage_state")) != "playing" or int(node.get("remaining_moves")) != 5:
		errors.append("%s coin continue should resume Stage 25 with configured 5 moves." % GAMEPLAY_SCENE_PATH)
	if overlay != null and overlay.visible:
		errors.append("%s coin continue should hide the failure overlay after success." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") <= coin_extra_moves_before:
		errors.append("%s coin continue should emit extra_moves_grant analytics." % GAMEPLAY_SCENE_PATH)
	var coin_extra_event := _last_analytics_event_by_name("extra_moves_grant")
	var coin_extra_params: Dictionary = Dictionary(coin_extra_event.get("params", {}))
	if String(coin_extra_params.get("source", "")) != "coin_continue" or int(coin_extra_params.get("moves_amount", 0)) != 5:
		errors.append("%s coin continue extra_moves_grant should identify source and configured moves." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	GameSession.set_wallet_for_testing({"gold": 40, "tokens": 0, "boosters": {}})
	target_collect = Dictionary(node.call("_stage_collect_targets"))
	near_miss_counts = {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	var coin_insufficient_extra_before := _analytics_event_count("extra_moves_grant")
	await node.call("_check_stage_state")
	if bool(node.call("_resolve_fail_offer_continue_result", "coins", "completed", {"cost_amount": 120})):
		errors.append("%s coin continue should not grant when wallet lacks gold." % GAMEPLAY_SCENE_PATH)
	if int(GameSession.get_wallet().get("gold", 0)) != 40 or int(node.get("remaining_moves")) != 0 or String(node.get("stage_state")) != "failed":
		errors.append("%s coin continue insufficient funds should preserve wallet, moves, and failed state." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("extra_moves_grant") != coin_insufficient_extra_before:
		errors.append("%s coin continue insufficient funds should not emit extra_moves_grant." % GAMEPLAY_SCENE_PATH)

	await _validate_failure_overlay_focus_hint_variants(node, errors)


func _validate_gameplay_hud_text_stress(node: Node, errors: PackedStringArray) -> void:
	var restore_stage_index := int(node.get("current_stage_index"))
	node.call("_start_stage", 3)
	await process_frame
	await process_frame
	var viewport_size := Vector2i(root.get_visible_rect().size)
	var goal_dock := node.find_child("HudGoalDock", true, false) as Control
	var board_frame := node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control
	var booster_dock := node.find_child("HudBoosterDock", true, false) as Control
	var hud_goal_label := node.get("hud_goal_label") as Label
	var hud_buddy_label := node.get("hud_buddy_label") as Label
	var hud_buddy_gauge := node.find_child("HudBuddyGauge", true, false) as Control
	var portrait_summary := node.get("portrait_goal_summary") as Label
	var original_goal := "" if hud_goal_label == null else hud_goal_label.text
	var original_buddy := "" if hud_buddy_label == null else hud_buddy_label.text
	var original_summary := "" if portrait_summary == null else portrait_summary.text
	if hud_goal_label != null:
		hud_goal_label.text = "%s · 목표 토끼 99 / 덤불 12" % CRITICAL_TEXT_STRESS_BODY
	if hud_buddy_label != null:
		hud_buddy_label.text = "%s · Buddy Ready" % CRITICAL_TEXT_STRESS_TITLE
	if portrait_summary != null:
		portrait_summary.text = "%s · portrait HUD summary" % CRITICAL_TEXT_STRESS_BODY
	await process_frame
	_validate_control_in_viewport(goal_dock, viewport_size, GAMEPLAY_SCENE_PATH, "HudGoalDock text stress", errors)
	if hud_goal_label != null:
		_validate_control_inside_container(hud_goal_label, goal_dock, GAMEPLAY_SCENE_PATH, "HudGoalLabel text stress", errors)
	if hud_buddy_label == null or not hud_buddy_label.is_visible_in_tree():
		errors.append("%s critical text stress should run with Stage 4 Rescue Buddy HUD visible." % GAMEPLAY_SCENE_PATH)
	if hud_buddy_label != null:
		_validate_control_inside_container(hud_buddy_label, goal_dock, GAMEPLAY_SCENE_PATH, "HudBuddyLabel text stress", errors)
	if hud_buddy_gauge != null:
		_validate_control_inside_container(hud_buddy_gauge, goal_dock, GAMEPLAY_SCENE_PATH, "HudBuddyGauge text stress", errors)
	if portrait_summary != null and portrait_summary.is_visible_in_tree():
		_validate_control_inside_container(portrait_summary, goal_dock, GAMEPLAY_SCENE_PATH, "PortraitGoalSummary text stress", errors)
	if goal_dock != null and board_frame != null and goal_dock.is_visible_in_tree() and board_frame.is_visible_in_tree():
		var goal_rect := goal_dock.get_global_rect()
		var board_rect := board_frame.get_global_rect()
		if goal_rect.intersects(board_rect):
			errors.append("%s critical text stress overlapped: HudGoalDock %s board %s." % [GAMEPLAY_SCENE_PATH, goal_rect, board_rect])
	if booster_dock != null and board_frame != null and booster_dock.is_visible_in_tree() and board_frame.is_visible_in_tree():
		var booster_rect := booster_dock.get_global_rect()
		var booster_board_rect := board_frame.get_global_rect()
		if booster_rect.intersects(booster_board_rect):
			errors.append("%s critical text stress overlapped: HudBoosterDock %s board %s." % [GAMEPLAY_SCENE_PATH, booster_rect, booster_board_rect])
	if hud_goal_label != null:
		hud_goal_label.text = original_goal
	if hud_buddy_label != null:
		hud_buddy_label.text = original_buddy
	if portrait_summary != null:
		portrait_summary.text = original_summary
	if int(node.get("current_stage_index")) != restore_stage_index:
		node.call("_start_stage", restore_stage_index)
		await process_frame


func _validate_failure_overlay_text_stress(node: Node, errors: PackedStringArray) -> void:
	var viewport_size := Vector2i(root.get_visible_rect().size)
	var panel := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel") as Control
	var title := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayTitle") as Label
	var body := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Label
	var primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Button
	var secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Button
	var original_title := "" if title == null else title.text
	var original_body := "" if body == null else body.text
	var original_primary := "" if primary == null else primary.text
	var original_secondary := "" if secondary == null else secondary.text
	if title != null:
		title.text = CRITICAL_TEXT_STRESS_TITLE
	if body != null:
		body.text = "%s\n%s" % [CRITICAL_TEXT_STRESS_BODY, "놓친 핵심 · 다음 한 수 · SuperLongHintToken"]
	if primary != null:
		primary.text = "+3 이동 받고 계속"
	if secondary != null:
		secondary.text = "재도전"
	await process_frame
	_validate_control_in_viewport(panel, viewport_size, GAMEPLAY_SCENE_PATH, "OverlayPanel text stress", errors)
	for control_info in [[title, "OverlayTitle"], [body, "OverlayBody"], [primary, "OverlayPrimaryButton"], [secondary, "OverlaySecondaryButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		if control != null and control.is_visible_in_tree():
			_validate_control_inside_container(control, panel, GAMEPLAY_SCENE_PATH, "%s text stress" % label, errors)
	_validate_no_vertical_overlap(body, primary, GAMEPLAY_SCENE_PATH, "OverlayBody to primary CTA", errors)
	if title != null:
		title.text = original_title
	if body != null:
		body.text = original_body
	if primary != null:
		primary.text = original_primary
	if secondary != null:
		secondary.text = original_secondary


func _prepare_stage_25_near_miss_failure(node: Node) -> void:
	node.call("_start_stage", 24)
	GameSession.set_stage_fail_count_for_testing(25, 0)
	var target_collect := Dictionary(node.call("_stage_collect_targets"))
	var near_miss_counts := {}
	for animal_id in target_collect.keys():
		near_miss_counts[String(animal_id)] = int(target_collect[animal_id])
	node.set("collected_counts", near_miss_counts)
	node.set("cleared_blockers", maxi(0, int(node.call("_target_blockers")) - 1))
	node.set("score", int(node.call("_target_score")))
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")


func _validate_failure_overlay_focus_hint_variants(node: Node, errors: PackedStringArray) -> void:
	node.call("_start_stage", 11)
	GameSession.set_stage_fail_count_for_testing(12, 0)
	_complete_current_stage_goals(node)
	var missing_collect_counts := Dictionary(node.get("collected_counts"))
	missing_collect_counts["bear"] = 5
	node.set("collected_counts", missing_collect_counts)
	node.set("score", int(node.call("_target_score")))
	node.set("cleared_blockers", int(node.call("_target_blockers")))
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	var overlay := node.get_node_or_null("Overlay") as CanvasItem
	var overlay_body := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Label
	var overlay_primary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Button
	var overlay_secondary := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Button
	if overlay == null or not overlay.visible:
		errors.append("%s collection failure hint smoke should show the result overlay." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed":
		errors.append("%s collection failure hint smoke should leave Stage 12 failed, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("stage_state"))])
	if int(node.call("_current_stage_id")) != 12 or String(node.get("overlay_action")) != "restart_stage":
		errors.append("%s collection failure hint smoke should keep Stage 12 on restart_stage action." % GAMEPLAY_SCENE_PATH)
	if overlay_primary == null or overlay_primary.text != "재도전":
		errors.append("%s collection failure hint smoke should expose 재도전 primary CTA." % GAMEPLAY_SCENE_PATH)
	if overlay_secondary == null or not overlay_secondary.visible or overlay_secondary.text != "홈으로":
		errors.append("%s collection failure hint smoke should expose 홈으로 secondary CTA." % GAMEPLAY_SCENE_PATH)
	if overlay_body == null or not overlay_body.text.contains("실패 유형  strategic_miss") or not overlay_body.text.contains("남은 목표  곰 3개") or not overlay_body.text.contains("놓친 핵심  곰 3개 더 구조") or not overlay_body.text.contains("다음 한 수  곰 주변 매치부터 만들고 무지개 발바닥은 마지막 목표에 쓰세요."):
		errors.append("%s collection failure overlay should show the missed collection focus and retry hint." % GAMEPLAY_SCENE_PATH)

	node.call("_start_stage", 11)
	GameSession.set_stage_fail_count_for_testing(12, 0)
	_complete_current_stage_goals(node)
	node.set("score", int(node.call("_target_score")) - 300)
	node.set("remaining_moves", 0)
	await node.call("_check_stage_state")
	overlay = node.get_node_or_null("Overlay") as CanvasItem
	overlay_body = node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Label
	overlay_primary = node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton") as Button
	overlay_secondary = node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton") as Button
	if overlay == null or not overlay.visible:
		errors.append("%s score failure hint smoke should show the result overlay." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed":
		errors.append("%s score failure hint smoke should leave Stage 12 failed, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("stage_state"))])
	if int(node.call("_current_stage_id")) != 12 or String(node.get("overlay_action")) != "restart_stage":
		errors.append("%s score failure hint smoke should keep Stage 12 on restart_stage action." % GAMEPLAY_SCENE_PATH)
	if overlay_primary == null or overlay_primary.text != "재도전":
		errors.append("%s score failure hint smoke should expose 재도전 primary CTA." % GAMEPLAY_SCENE_PATH)
	if overlay_secondary == null or not overlay_secondary.visible or overlay_secondary.text != "홈으로":
		errors.append("%s score failure hint smoke should expose 홈으로 secondary CTA." % GAMEPLAY_SCENE_PATH)
	if overlay_body == null or not overlay_body.text.contains("실패 유형  strategic_miss") or not overlay_body.text.contains("남은 목표  점수 300점") or not overlay_body.text.contains("놓친 핵심  점수 300점 더 획득") or not overlay_body.text.contains("다음 한 수  4매치 이상과 연쇄를 노려 점수 배수를 먼저 키우세요."):
		errors.append("%s score failure overlay should show the missed score focus and retry hint." % GAMEPLAY_SCENE_PATH)


func _validate_loyal_fetch_failure_gate_runtime(node: Node, errors: PackedStringArray) -> void:
	node.call("_start_stage", 19)
	node.set("board_data", _seed_plain_gameplay_board(node))
	var collected_counts: Dictionary = Dictionary(node.get("collected_counts"))
	collected_counts["bear"] = 9
	collected_counts["rabbit"] = 4
	node.set("collected_counts", collected_counts)
	node.set("remaining_moves", 0)
	var overlay := node.get_node_or_null("Overlay") as CanvasItem
	if overlay != null:
		overlay.visible = false
	var stage_fail_events_before := _analytics_event_count("stage_fail")
	var fail_offer_show_events_before := _analytics_event_count("fail_offer_show")
	var loyal_fetch_events_before := _analytics_event_count("buddy_skill_trigger")

	await node.call("_check_stage_state")
	if String(node.get("stage_state")) != "playing":
		errors.append("%s loyal_fetch failure gate should keep Stage 20 playing, got %s." % [GAMEPLAY_SCENE_PATH, String(node.get("stage_state"))])
	if int(node.get("remaining_moves")) != 1:
		errors.append("%s loyal_fetch failure gate should restore exactly one rescue move, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("remaining_moves"))])
	if int(node.get("buddy_uses")) != 1:
		errors.append("%s loyal_fetch failure gate should consume exactly one Buddy use, got %d." % [GAMEPLAY_SCENE_PATH, int(node.get("buddy_uses"))])
	if overlay != null and overlay.visible:
		errors.append("%s loyal_fetch failure gate should not show the failure overlay." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("stage_fail") != stage_fail_events_before:
		errors.append("%s loyal_fetch failure gate should not emit stage_fail before rescue move." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("fail_offer_show") != fail_offer_show_events_before:
		errors.append("%s loyal_fetch failure gate should not emit fail_offer_show before rescue move." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("buddy_skill_trigger") <= loyal_fetch_events_before:
		errors.append("%s loyal_fetch failure gate should emit buddy_skill_trigger through _check_stage_state." % GAMEPLAY_SCENE_PATH)
	var loyal_fetch_event := _last_analytics_event_by_name("buddy_skill_trigger")
	var loyal_fetch_params: Dictionary = Dictionary(loyal_fetch_event.get("params", {}))
	if int(loyal_fetch_params.get("stage_id", 0)) != 20 or String(loyal_fetch_params.get("animal_id", "")) != "dog" or String(loyal_fetch_params.get("effect_type", "")) != "loyal_fetch" or String(loyal_fetch_params.get("trigger_source", "")) != "near_fail_rescue":
		errors.append("%s loyal_fetch failure gate analytics should identify Stage 20 near_fail_rescue." % GAMEPLAY_SCENE_PATH)


func _validate_failure_focus_hint_runtime(node: Node, errors: PackedStringArray) -> void:
	node.call("_start_stage", 0)
	node.set("score", 0)
	var collect_offer: Dictionary = Dictionary(node.call("_build_failure_offer", 1))
	var collect_focus := String(node.call("_build_failure_focus_summary"))
	var collect_hint := String(node.call("_build_failure_retry_hint", collect_offer))
	if collect_focus != "토끼 10개 더 구조":
		errors.append("%s collection failure focus should identify the missing animal count, got %s." % [GAMEPLAY_SCENE_PATH, collect_focus])
	if not collect_hint.contains("토끼 주변 매치"):
		errors.append("%s collection failure hint should suggest matching around the missing animal, got %s." % [GAMEPLAY_SCENE_PATH, collect_hint])

	node.call("_start_stage", 2)
	var complete_counts := {}
	for animal_id in Dictionary(node.call("_stage_collect_targets")).keys():
		complete_counts[String(animal_id)] = int(Dictionary(node.call("_stage_collect_targets"))[animal_id])
	node.set("collected_counts", complete_counts)
	node.set("score", 0)
	var score_offer: Dictionary = Dictionary(node.call("_build_failure_offer", 1))
	var score_focus := String(node.call("_build_failure_focus_summary"))
	var score_hint := String(node.call("_build_failure_retry_hint", score_offer))
	if score_focus != "점수 800점 더 획득":
		errors.append("%s score failure focus should identify the missing score, got %s." % [GAMEPLAY_SCENE_PATH, score_focus])
	if not score_hint.contains("4매치 이상") or not score_hint.contains("연쇄"):
		errors.append("%s score failure hint should suggest bigger matches and cascades, got %s." % [GAMEPLAY_SCENE_PATH, score_hint])


func _complete_current_stage_goals(node: Node) -> void:
	var collected := {}
	for animal_id in Dictionary(node.call("_stage_collect_targets")).keys():
		collected[String(animal_id)] = int(Dictionary(node.call("_stage_collect_targets"))[animal_id])
	node.set("collected_counts", collected)
	node.set("cleared_blockers", int(node.call("_target_blockers")))
	node.set("score", int(node.call("_target_score")))


func _seed_plain_gameplay_board(node: Node) -> Array:
	var animals := ["rabbit", "bear", "cat", "chick", "frog"]
	var board_data: Array = node.get("board_data")
	var obstacle_data: Array = node.get("obstacle_data")
	var active_mask: Array = node.get("active_mask")
	for row in range(8):
		for col in range(8):
			active_mask[row][col] = true
			obstacle_data[row][col] = 0
			board_data[row][col] = node.call("_make_piece", String(animals[(row * 2 + col) % animals.size()]))
	node.set("active_mask", active_mask)
	node.set("obstacle_data", obstacle_data)
	node.set("board_data", board_data)
	return board_data


func _seed_smart_hint_gameplay_board(node: Node, target_animal: String) -> Array:
	var board_data: Array = _seed_plain_gameplay_board(node)
	var blocker_animal := "bear" if target_animal != "bear" else "rabbit"
	board_data[0][0] = node.call("_make_piece", target_animal)
	board_data[0][1] = node.call("_make_piece", blocker_animal)
	board_data[0][2] = node.call("_make_piece", target_animal)
	board_data[1][1] = node.call("_make_piece", target_animal)
	node.set("board_data", board_data)
	return board_data


func _count_board_special(node: Node, special_type: String) -> int:
	var count := 0
	for row in Array(node.get("board_data")):
		for piece in Array(row):
			if String(piece).ends_with("|%s" % special_type):
				count += 1
	return count


func _validate_collection_scene(node: Node, errors: PackedStringArray) -> void:
	var animals := CollectionState.load_animal_definitions()
	var collection_ids: Array[String] = []
	for animal in animals:
		if animal is Dictionary and bool(Dictionary(animal).get("collection_enabled", false)):
			collection_ids.append(String(Dictionary(animal).get("id", "")))

	var grid := node.find_child("CollectionGrid", true, false) as GridContainer
	if grid == null:
		errors.append("%s is missing CollectionGrid." % COLLECTION_SCENE_PATH)
	elif grid.get_child_count() != collection_ids.size():
		errors.append("%s expected %d animal cards, got %d." % [COLLECTION_SCENE_PATH, collection_ids.size(), grid.get_child_count()])

	var summary := node.find_child("SummaryLabel", true, false) as Label
	if summary == null:
		errors.append("%s is missing SummaryLabel." % COLLECTION_SCENE_PATH)
	elif not summary.text.contains("해금"):
		errors.append("%s SummaryLabel should show unlock progress." % COLLECTION_SCENE_PATH)
	_validate_collection_cta_signal_wiring(node, errors)

	for animal_id in collection_ids:
		if node.find_child("AnimalCard_%s" % animal_id, true, false) == null:
			errors.append("%s missing AnimalCard_%s." % [COLLECTION_SCENE_PATH, animal_id])
	if node.has_method("_load_animal_texture"):
		var fallback_texture = node.call("_load_animal_texture", "koala")
		if not (fallback_texture is Texture2D):
			errors.append("%s should return a fallback Texture2D for koala collection preview." % COLLECTION_SCENE_PATH)
	_validate_collection_card_label_state(node, errors)
	if node.has_method("_collection_live_event_line_for_event"):
		var ended_line := String(node.call("_collection_live_event_line_for_event", {
			"id": "__validation_collection_event",
			"type": "collection_event",
			"title": "도감 검증",
			"enabled": true,
			"status": "ended",
			"unlock_stage": 1,
			"placements": ["collection"],
		}))
		if not ended_line.contains("종료됨"):
			errors.append("%s collection live event line should expose ended status text." % COLLECTION_SCENE_PATH)
	if node.has_method("_track_collection_event_impressions"):
		var selected_stage_before := GameSession.get_selected_stage_id()
		GameSession.record_stage_result(9, 0, 1)
		node.call("_track_collection_event_impressions")
		GameSession.set_selected_stage_id(selected_stage_before)


func _validate_collection_cta_signal_wiring(node: Node, errors: PackedStringArray) -> void:
	_validate_button_pressed_connection(node.find_child("BackButton", true, false), node, "_on_back_pressed", COLLECTION_SCENE_PATH, "BackButton", errors)


func _validate_collection_card_label_state(node: Node, errors: PackedStringArray) -> void:
	if not node.has_method("_refresh_cards"):
		errors.append("%s should expose _refresh_cards for Rescue Book card state smoke." % COLLECTION_SCENE_PATH)
		return
	var grid := node.find_child("CollectionGrid", true, false)
	if grid == null:
		errors.append("%s is missing CollectionGrid for Rescue Book card state smoke." % COLLECTION_SCENE_PATH)
		return

	var token_gain_events_before := _analytics_event_count("animal_token_gain")
	var friendship_events_before := _analytics_event_count("animal_friendship_level_up")
	GameSession.add_rescue_book_tokens("rabbit", 40, "scene_smoke", 4)
	GameSession.mark_rescue_book_seen("bear")
	node.call("_refresh_cards")

	var refreshed_card_texts := _collection_card_label_texts_after(grid, 0)
	var rabbit_text := _first_text_containing(refreshed_card_texts, "토끼")
	if not rabbit_text.contains("Lv.3") or not rabbit_text.contains("토큰 40") or not rabbit_text.contains("NEW") or not rabbit_text.contains("보상 3/5"):
		errors.append("%s AnimalCard_rabbit should show Lv.3, token count, NEW, and 3/5 reward state after token fixture, got: %s." % [COLLECTION_SCENE_PATH, rabbit_text])
	var rabbit_state := Dictionary(Dictionary(GameSession.get_rescue_book_state().get("animals", {})).get("rabbit", {}))
	var rabbit_rewards := Array(rabbit_state.get("earned_rewards", []))
	for reward_id in ["rabbit_icon_basic", "rabbit_smile_plus", "rabbit_sprout_frame"]:
		if not rabbit_rewards.has(reward_id):
			errors.append("%s rabbit reward track should auto-earn %s at 40 tokens." % [COLLECTION_SCENE_PATH, reward_id])
	if _analytics_event_count("animal_token_gain") <= token_gain_events_before:
		errors.append("%s Rescue Book token fixture should emit animal_token_gain." % COLLECTION_SCENE_PATH)
	if _analytics_event_count("animal_friendship_level_up") <= friendship_events_before:
		errors.append("%s Rescue Book token fixture should emit animal_friendship_level_up." % COLLECTION_SCENE_PATH)
	var token_gain_event := _last_analytics_event_by_name("animal_token_gain")
	var token_gain_params: Dictionary = Dictionary(token_gain_event.get("params", {}))
	if String(token_gain_params.get("animal_id", "")) != "rabbit" or int(token_gain_params.get("amount", 0)) != 40 or String(token_gain_params.get("source", "")) != "scene_smoke" or int(token_gain_params.get("stage_id", 0)) != 4 or int(token_gain_params.get("token_balance", 0)) != 40:
		errors.append("%s animal_token_gain should identify the rabbit scene smoke grant." % COLLECTION_SCENE_PATH)
	var friendship_event := _last_analytics_event_by_name("animal_friendship_level_up")
	var friendship_params: Dictionary = Dictionary(friendship_event.get("params", {}))
	if String(friendship_params.get("animal_id", "")) != "rabbit" or int(friendship_params.get("level_after", 0)) < 2 or String(friendship_params.get("reward_id", "")).is_empty():
		errors.append("%s animal_friendship_level_up should identify the rabbit reward unlock." % COLLECTION_SCENE_PATH)

	var bear_text := _first_text_containing(refreshed_card_texts, "곰")
	if bear_text.contains("NEW"):
		errors.append("%s AnimalCard_bear should hide NEW after mark_rescue_book_seen, got: %s." % [COLLECTION_SCENE_PATH, bear_text])

	var frog_text := _first_text_containing(refreshed_card_texts, "개구리")
	if not frog_text.contains("Stage 4 해금"):
		errors.append("%s AnimalCard_frog should show locked unlock-stage copy before Stage 4, got: %s." % [COLLECTION_SCENE_PATH, frog_text])
	_validate_collection_card_input_runtime(node, grid, errors)


func _validate_collection_card_input_runtime(node: Node, grid: Node, errors: PackedStringArray) -> void:
	if not node.has_method("_on_animal_card_input"):
		errors.append("%s should expose _on_animal_card_input for Rescue Book card input smoke." % COLLECTION_SCENE_PATH)
		return
	var animals := CollectionState.load_animal_definitions()
	var rabbit_animal := {}
	for animal in animals:
		if animal is Dictionary and String(Dictionary(animal).get("id", "")) == "rabbit":
			rabbit_animal = Dictionary(animal)
			break
	if rabbit_animal.is_empty():
		errors.append("%s Rescue Book input smoke could not find rabbit animal definition." % COLLECTION_SCENE_PATH)
		return

	var state_animals: Dictionary = Dictionary(GameSession.get_rescue_book_state().get("animals", {}))
	var rabbit_entry := Dictionary(state_animals.get("rabbit", {}))
	var press_event := InputEventMouseButton.new()
	press_event.pressed = true
	press_event.button_index = MOUSE_BUTTON_LEFT
	node.call("_on_animal_card_input", press_event, rabbit_animal, rabbit_entry)
	if String(node.get("selected_animal_id")) != "rabbit":
		errors.append("%s Rescue Book card input should select rabbit, got %s." % [COLLECTION_SCENE_PATH, String(node.get("selected_animal_id"))])

	var detail_label := node.find_child("DetailLabel", true, false) as Label
	if detail_label == null or not detail_label.text.contains("토끼") or not detail_label.text.contains("Lv.3") or not detail_label.text.contains("토큰 40") or not detail_label.text.contains("우정 보상") or not detail_label.text.contains("획득") or not detail_label.text.contains("대기"):
		errors.append("%s Rescue Book card input should refresh DetailLabel with selected rabbit reward track." % COLLECTION_SCENE_PATH)

	var after_input_texts := _collection_card_label_texts_after(grid, 0)
	var rabbit_after_input_text := _first_text_containing(after_input_texts, "토끼")
	if rabbit_after_input_text.contains("NEW"):
		errors.append("%s AnimalCard_rabbit should clear NEW after card input, got: %s." % [COLLECTION_SCENE_PATH, rabbit_after_input_text])
	var rabbit_state_after_input := Dictionary(Dictionary(GameSession.get_rescue_book_state().get("animals", {})).get("rabbit", {}))
	if bool(rabbit_state_after_input.get("is_new", true)) or int(rabbit_state_after_input.get("tokens", 0)) != 40 or int(rabbit_state_after_input.get("friendship_level", 1)) < 3 or not Array(rabbit_state_after_input.get("earned_rewards", [])).has("rabbit_sprout_frame"):
		errors.append("%s Rescue Book card input should persist rabbit seen state without losing tokens, friendship level, or rewards." % COLLECTION_SCENE_PATH)

	var cosmetic_grid := node.find_child("CosmeticEquipGrid", true, false) as GridContainer
	if cosmetic_grid == null or not cosmetic_grid.visible:
		errors.append("%s Rescue Book detail should show cosmetic equip actions for earned reward tracks." % COLLECTION_SCENE_PATH)
	var equip_events_before := _analytics_event_count("animal_cosmetic_equip")
	if node.has_method("_on_cosmetic_reward_pressed"):
		node.call("_on_cosmetic_reward_pressed", "rabbit", "rabbit_sprout_frame")
	else:
		errors.append("%s should expose _on_cosmetic_reward_pressed for cosmetic equip smoke." % COLLECTION_SCENE_PATH)
	var rabbit_state_after_equip := Dictionary(Dictionary(GameSession.get_rescue_book_state().get("animals", {})).get("rabbit", {}))
	if String(rabbit_state_after_equip.get("equipped_cosmetic", "")) != "rabbit_sprout_frame":
		errors.append("%s earned rabbit cosmetic should equip and persist in rescue_book state." % COLLECTION_SCENE_PATH)
	var save_after_equip := _validation_save_data()
	var saved_rabbit := Dictionary(Dictionary(Dictionary(save_after_equip.get("rescue_book", {})).get("animals", {})).get("rabbit", {}))
	if String(saved_rabbit.get("equipped_cosmetic", "")) != "rabbit_sprout_frame":
		errors.append("%s earned rabbit cosmetic should persist to save data." % COLLECTION_SCENE_PATH)
	if _analytics_event_count("animal_cosmetic_equip") != equip_events_before + 1:
		errors.append("%s cosmetic equip should emit exactly one animal_cosmetic_equip event." % COLLECTION_SCENE_PATH)
	var equip_event := _last_analytics_event_by_name("animal_cosmetic_equip")
	var equip_params: Dictionary = Dictionary(equip_event.get("params", {}))
	if String(equip_params.get("animal_id", "")) != "rabbit" or String(equip_params.get("cosmetic_id", "")) != "rabbit_sprout_frame" or String(equip_params.get("cosmetic_type", "")) != "card_frame" or String(equip_params.get("entry_point", "")) != "collection_detail" or String(equip_params.get("source", "")) != "rescue_book" or int(equip_params.get("friendship_level", 0)) != 3 or int(equip_params.get("token_balance", 0)) != 40:
		errors.append("%s animal_cosmetic_equip should identify rabbit_sprout_frame collection equip payload." % COLLECTION_SCENE_PATH)
	if node.has_method("_on_cosmetic_reward_pressed"):
		node.call("_on_cosmetic_reward_pressed", "rabbit", "rabbit_sprout_frame")
		node.call("_on_cosmetic_reward_pressed", "rabbit", "rabbit_rescuer_badge")
	var rabbit_state_after_blocked_equips := Dictionary(Dictionary(GameSession.get_rescue_book_state().get("animals", {})).get("rabbit", {}))
	if String(rabbit_state_after_blocked_equips.get("equipped_cosmetic", "")) != "rabbit_sprout_frame" or _analytics_event_count("animal_cosmetic_equip") != equip_events_before + 1:
		errors.append("%s duplicate or unearned cosmetic equip should not mutate state or emit analytics." % COLLECTION_SCENE_PATH)
	var equip_button := node.find_child("CosmeticButton_rabbit_sprout_frame", true, false) as Button
	if equip_button == null or not equip_button.disabled or not equip_button.text.contains("장착중"):
		errors.append("%s equipped cosmetic button should show disabled 장착중 state." % COLLECTION_SCENE_PATH)
	var rabbit_card_after_equip := grid.find_child("AnimalCard_rabbit", true, false) as PanelContainer
	var equipped_badge: PanelContainer = null
	var equipped_badge_label: Label = null
	if rabbit_card_after_equip != null:
		equipped_badge = rabbit_card_after_equip.find_child("EquippedCosmeticBadge_rabbit_sprout_frame", true, false) as PanelContainer
		if equipped_badge != null:
			equipped_badge_label = equipped_badge.find_child("EquippedCosmeticBadgeLabel", true, false) as Label
	if rabbit_card_after_equip == null or String(rabbit_card_after_equip.get_meta("equipped_cosmetic", "")) != "rabbit_sprout_frame" or String(rabbit_card_after_equip.get_meta("equipped_cosmetic_type", "")) != "card_frame":
		errors.append("%s equipped cosmetic should refresh AnimalCard_rabbit frame metadata." % COLLECTION_SCENE_PATH)
	if equipped_badge_label == null or not equipped_badge_label.text.contains("장착 프레임"):
		errors.append("%s equipped cosmetic should render a 장착 프레임 badge on AnimalCard_rabbit." % COLLECTION_SCENE_PATH)


func _validate_collection_preview_motion_runtime(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_sync_preview_motion", "_active_preview_count_for_testing", "_active_preview_ids_for_testing", "_preview_expression_states_for_testing", "_preview_id_is_visible_for_testing"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Rescue Book preview motion smoke." % [COLLECTION_SCENE_PATH, method_name])
			return

	node.call("_sync_preview_motion")
	await process_frame
	var active_count := int(node.call("_active_preview_count_for_testing"))
	if active_count <= 0:
		errors.append("%s Rescue Book preview smoke should animate at least one visible unlocked card." % COLLECTION_SCENE_PATH)
	elif active_count > 4:
		errors.append("%s Rescue Book preview smoke should cap active preview tweens at 4, got %d." % [COLLECTION_SCENE_PATH, active_count])
	_validate_active_collection_preview_visibility(node, errors)
	_validate_active_collection_preview_expressions(node, errors)

	var collection_scroll := node.find_child("CollectionScroll", true, false) as ScrollContainer
	if collection_scroll != null:
		var v_scroll_bar := collection_scroll.get_v_scroll_bar()
		if v_scroll_bar != null and v_scroll_bar.max_value > v_scroll_bar.page:
			v_scroll_bar.value = v_scroll_bar.max_value
			await process_frame
			await process_frame
			_validate_active_collection_preview_visibility(node, errors)
			_validate_active_collection_preview_expressions(node, errors)

	(node as CanvasItem).visible = false
	await process_frame
	await process_frame
	if int(node.call("_active_preview_count_for_testing")) != 0:
		errors.append("%s Rescue Book preview smoke should stop all preview tweens when visibility changes to hidden." % COLLECTION_SCENE_PATH)
	(node as CanvasItem).visible = true
	await process_frame
	await process_frame


func _validate_active_collection_preview_visibility(node: Node, errors: PackedStringArray) -> void:
	for animal_id_value in Array(node.call("_active_preview_ids_for_testing")):
		var animal_id := String(animal_id_value)
		if animal_id.is_empty():
			continue
		if not bool(node.call("_preview_id_is_visible_for_testing", animal_id)):
			errors.append("%s Rescue Book preview tween should only run for visible cards, got offscreen %s." % [COLLECTION_SCENE_PATH, animal_id])


func _validate_active_collection_preview_expressions(node: Node, errors: PackedStringArray) -> void:
	var states: Dictionary = Dictionary(node.call("_preview_expression_states_for_testing"))
	for animal_id_value in Array(node.call("_active_preview_ids_for_testing")):
		var animal_id := String(animal_id_value)
		if animal_id.is_empty():
			continue
		var expression_state := String(states.get(animal_id, ""))
		if not ["idle", "blink", "smile"].has(expression_state):
			errors.append("%s Rescue Book preview %s should expose idle/blink/smile fallback state, got %s." % [COLLECTION_SCENE_PATH, animal_id, expression_state])


func _collection_card_label_texts_after(grid: Node, start_index: int) -> Array[String]:
	var texts: Array[String] = []
	for index in range(start_index, grid.get_child_count()):
		texts.append(_label_text_blob(grid.get_child(index)))
	return texts


func _first_text_containing(texts: Array[String], needle: String) -> String:
	for text in texts:
		if text.contains(needle):
			return text
	return ""


func _label_text_blob(node: Node) -> String:
	if node == null:
		return ""
	var texts: Array[String] = []
	if node is Label:
		texts.append(String((node as Label).text))
	for label_node in node.find_children("*", "Label", true, false):
		var label := label_node as Label
		if label != null and not label.text.is_empty():
			texts.append(label.text)
	return " ".join(texts)


func _validate_stage_select_scene(node: Node, errors: PackedStringArray) -> void:
	var legacy_layout := node.get_node_or_null("SafeMargin/LayoutRoot") as CanvasItem
	if legacy_layout == null:
		errors.append("%s is missing legacy LayoutRoot." % STAGE_SELECT_SCENE_PATH)
	elif legacy_layout.visible:
		errors.append("%s should hide the old panel-heavy LayoutRoot behind StageWorldLayer." % STAGE_SELECT_SCENE_PATH)

	var stage_world_layer := node.get_node_or_null("StageWorldLayer") as CanvasItem
	if stage_world_layer == null:
		errors.append("%s is missing the full-screen StageWorldLayer." % STAGE_SELECT_SCENE_PATH)
	elif not stage_world_layer.visible:
		errors.append("%s StageWorldLayer should be visible on first launch." % STAGE_SELECT_SCENE_PATH)

	var world_path_root := node.get_node_or_null("StageWorldLayer/WorldMapPathRoot")
	if world_path_root == null:
		errors.append("%s is missing WorldMapPathRoot." % STAGE_SELECT_SCENE_PATH)
	else:
		var world_node_count := world_path_root.find_children("WorldStageNode*", "Button", true, false).size()
		if world_node_count != 10:
			errors.append("%s WorldMapPathRoot expected 10 visible band nodes, got %d." % [STAGE_SELECT_SCENE_PATH, world_node_count])
		var route_dressing_count := 0
		for child in world_path_root.get_children():
			if child is PanelContainer:
				route_dressing_count += 1
		if route_dressing_count < 20:
			errors.append("%s world path should include candy-dot route dressing, got %d route panels." % [STAGE_SELECT_SCENE_PATH, route_dressing_count])

	var world_decor_root := node.get_node_or_null("StageWorldLayer/WorldDecorRoot")
	if world_decor_root == null:
		errors.append("%s is missing WorldDecorRoot candy-map dressing." % STAGE_SELECT_SCENE_PATH)

	if node.get_node_or_null("StageWorldLayer/LiveEventStrip") == null:
		errors.append("%s is missing LiveEventStrip for stage_select live ops surface checks." % STAGE_SELECT_SCENE_PATH)
	elif node.has_method("_make_stage_select_event_chip"):
		var upcoming_chip = node.call("_make_stage_select_event_chip", {
			"id": "__validation_upcoming_event",
			"type": "starter_missions",
			"title": "예정 검증",
			"enabled": true,
			"status": "upcoming",
			"unlock_stage": 1,
			"placements": ["stage_select"],
		}) as PanelContainer
		var labels := upcoming_chip.find_children("*", "Label", true, false) if upcoming_chip != null else []
		var label := labels[0] as Label if not labels.is_empty() else null
		if label == null or not label.text.contains("시작 전"):
			errors.append("%s stage select live event chip should expose upcoming status text." % STAGE_SELECT_SCENE_PATH)
		if upcoming_chip != null:
			upcoming_chip.queue_free()
	if node.has_method("_track_stage_select_live_event_impression"):
		node.call("_track_stage_select_live_event_impression", _live_event_by_id("starter_missions_v1"))

	var world_play_button := node.find_child("WorldPlayButton", true, false) as Button
	if world_play_button == null:
		errors.append("%s is missing the world-map action button." % STAGE_SELECT_SCENE_PATH)
	_validate_stage_select_cta_signal_wiring(node, errors)

	var stage_grid := node.get_node_or_null("SafeMargin/LayoutRoot/ContentRoot/StagePanel/StageFrame/StageMargin/StageColumn/StageScroll/StageGrid")
	if stage_grid == null:
		errors.append("%s is missing StageGrid." % STAGE_SELECT_SCENE_PATH)
	elif stage_grid.get_child_count() != 100:
		errors.append("%s StageGrid expected 100 stage cards, got %d." % [STAGE_SELECT_SCENE_PATH, stage_grid.get_child_count()])
	elif not String(stage_grid.get_child(0).name).begins_with("StageNode"):
		errors.append("%s StageGrid should render world-map stage nodes, not plain list cards." % STAGE_SELECT_SCENE_PATH)

	var stage_popup := node.get_node_or_null("StagePopupOverlay") as CanvasItem
	if stage_popup == null:
		errors.append("%s is missing StagePopupOverlay." % STAGE_SELECT_SCENE_PATH)
	elif stage_popup.visible:
		errors.append("%s StagePopupOverlay should start hidden until a stage node is pressed." % STAGE_SELECT_SCENE_PATH)
	else:
		_validate_stage_popup_flow(node, errors)

	var map_juice_layer := node.get_node_or_null("StageMapJuiceLayer") as CanvasItem
	if map_juice_layer == null:
		errors.append("%s is missing StageMapJuiceLayer ambient mascots." % STAGE_SELECT_SCENE_PATH)


func _validate_stage_select_cta_signal_wiring(node: Node, errors: PackedStringArray) -> void:
	_validate_button_pressed_connection(node.find_child("WorldPlayButton", true, false), node, "_on_world_play_button_pressed", STAGE_SELECT_SCENE_PATH, "WorldPlayButton", errors)
	var stage_node := node.find_child("WorldStageNode1", true, false) as Button
	if stage_node != null:
		_validate_button_pressed_connection(stage_node, node, "_on_band_route_node_pressed", STAGE_SELECT_SCENE_PATH, "WorldStageNode1", errors)
	var panel := node.get("stage_popup_panel") as Control
	_validate_button_pressed_connection(_find_button_with_text(panel, "×"), node, "_on_stage_popup_close_pressed", STAGE_SELECT_SCENE_PATH, "StagePopupCloseButton", errors)
	_validate_button_pressed_connection(_find_button_with_text(panel, "PLAY"), node, "_on_stage_popup_start_pressed", STAGE_SELECT_SCENE_PATH, "StagePopupStartButton", errors)
	var booster_buttons: Dictionary = Dictionary(node.get("stage_popup_booster_buttons"))
	for booster_id in ["rainbow_paw", "striped", "bomb"]:
		_validate_button_pressed_connection(booster_buttons.get(booster_id) as Button, node, "_on_booster_button_pressed", STAGE_SELECT_SCENE_PATH, "StagePopupBoosterButton %s" % booster_id, errors)


func _validate_stage_popup_flow(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_show_stage_popup", "_on_booster_button_pressed"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Stage Popup smoke." % [STAGE_SELECT_SCENE_PATH, method_name])
			return

	GameSession.set_selected_stage_id(1)
	GameSession.set_selected_pre_boosters([])
	var first_stage_node := node.find_child("WorldStageNode1", true, false) as Button
	if first_stage_node == null:
		for candidate in node.find_children("WorldStageNode*", "Button", true, false):
			var candidate_button := candidate as Button
			if candidate_button != null and not candidate_button.disabled:
				first_stage_node = candidate_button
				break
	if first_stage_node == null:
		errors.append("%s Stage Popup smoke could not find an unlocked WorldStageNode button." % STAGE_SELECT_SCENE_PATH)
		return
	first_stage_node.emit_signal("pressed")

	var overlay := node.get_node_or_null("StagePopupOverlay") as CanvasItem
	if overlay == null or not overlay.visible:
		errors.append("%s Stage Popup smoke should make StagePopupOverlay visible after pressing a WorldStageNode." % STAGE_SELECT_SCENE_PATH)
	node.call("_show_stage_popup", 1)

	var title_label := node.get("stage_popup_title_label") as Label
	if title_label == null or not title_label.text.contains("Level 1"):
		errors.append("%s Stage Popup title should identify Level 1." % STAGE_SELECT_SCENE_PATH)
	var goal_label := node.get("stage_popup_goal_label") as Label
	if goal_label == null or not goal_label.text.contains("목표"):
		errors.append("%s Stage Popup should show goal text." % STAGE_SELECT_SCENE_PATH)
	var meta_label := node.get("stage_popup_meta_label") as Label
	if meta_label == null or not meta_label.text.contains("이동"):
		errors.append("%s Stage Popup should show move/meta text." % STAGE_SELECT_SCENE_PATH)
	var reward_label := node.get("stage_popup_reward_label") as Label
	if reward_label == null or not reward_label.text.contains("보상"):
		errors.append("%s Stage Popup should show reward text." % STAGE_SELECT_SCENE_PATH)
	var buddy_label := node.get("stage_popup_buddy_label") as Label
	if buddy_label == null:
		errors.append("%s Stage Popup should expose StagePopupBuddyLabel for Rescue Buddy preview." % STAGE_SELECT_SCENE_PATH)
	elif buddy_label.visible:
		errors.append("%s Stage Popup should hide Rescue Buddy preview on Stage 1 without a Buddy." % STAGE_SELECT_SCENE_PATH)

	node.call("_show_stage_popup", 4)
	buddy_label = node.get("stage_popup_buddy_label") as Label
	if buddy_label == null or not buddy_label.visible:
		errors.append("%s Stage 4 Stage Popup should show Rescue Buddy preview." % STAGE_SELECT_SCENE_PATH)
	else:
		for required_text in ["Rescue Buddy", "토끼", "Quick Refill", "목표 동물 매치 3회", "목표 동물 1개"]:
			if not buddy_label.text.contains(required_text):
				errors.append("%s Stage 4 Rescue Buddy preview should include '%s'." % [STAGE_SELECT_SCENE_PATH, required_text])

	node.call("_show_stage_popup", 51)
	buddy_label = node.get("stage_popup_buddy_label") as Label
	if buddy_label == null or not buddy_label.visible or not buddy_label.text.contains("사자") or not buddy_label.text.contains("Brave Start"):
		errors.append("%s Stage 51 Rescue Buddy preview should localize lion Brave Start." % STAGE_SELECT_SCENE_PATH)

	node.call("_show_stage_popup", 81)
	buddy_label = node.get("stage_popup_buddy_label") as Label
	if buddy_label == null or not buddy_label.visible or not buddy_label.text.contains("코끼리") or not buddy_label.text.contains("Mighty Push"):
		errors.append("%s Stage 81 Rescue Buddy preview should localize elephant Mighty Push." % STAGE_SELECT_SCENE_PATH)
	node.call("_show_stage_popup", 1)

	var panel := node.get("stage_popup_panel") as PanelContainer
	var start_button := _find_button_with_text(panel, "PLAY")
	if start_button == null:
		errors.append("%s Stage Popup should expose a PLAY button." % STAGE_SELECT_SCENE_PATH)

	var booster_buttons: Dictionary = Dictionary(node.get("stage_popup_booster_buttons"))
	for booster_id in ["rainbow_paw", "striped", "bomb"]:
		if not booster_buttons.has(booster_id):
			errors.append("%s Stage Popup should expose booster button %s." % [STAGE_SELECT_SCENE_PATH, booster_id])
			continue
		var booster_button := booster_buttons[booster_id] as Button
		if booster_button == null:
			errors.append("%s Stage Popup booster %s should be a Button." % [STAGE_SELECT_SCENE_PATH, booster_id])
			continue
		if booster_button.icon == null:
			errors.append("%s Stage Popup booster %s should include an icon." % [STAGE_SELECT_SCENE_PATH, booster_id])
		if booster_button.text.is_empty():
			errors.append("%s Stage Popup booster %s should expose selection text." % [STAGE_SELECT_SCENE_PATH, booster_id])

	var rainbow_button := booster_buttons.get("rainbow_paw") as Button
	if rainbow_button != null:
		rainbow_button.emit_signal("pressed")
		var selected_pre_boosters: Array = node.get("selected_pre_boosters")
		if not selected_pre_boosters.has("rainbow_paw"):
			errors.append("%s Stage Popup should mirror selected booster into selected_pre_boosters." % STAGE_SELECT_SCENE_PATH)
		if not rainbow_button.button_pressed:
			errors.append("%s Stage Popup selected booster button should stay pressed." % STAGE_SELECT_SCENE_PATH)

	GameSession.set_selected_pre_boosters([])


func _validate_stage_popup_runtime(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_show_stage_popup", "_on_booster_button_pressed", "_on_stage_popup_close_pressed", "_commit_stage_popup_selection"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Stage Popup runtime smoke." % [STAGE_SELECT_SCENE_PATH, method_name])
			return

	GameSession.set_selected_stage_id(1)
	GameSession.set_selected_pre_boosters([])
	node.call("_show_stage_popup", 1)
	var overlay := node.get_node_or_null("StagePopupOverlay") as CanvasItem
	if overlay == null or not overlay.visible:
		errors.append("%s Stage Popup runtime smoke should show StagePopupOverlay before close/start checks." % STAGE_SELECT_SCENE_PATH)

	node.call("_on_booster_button_pressed", "rainbow_paw")
	node.call("_commit_stage_popup_selection")
	var committed_boosters := GameSession.get_selected_pre_boosters()
	if GameSession.get_selected_stage_id() != 1:
		errors.append("%s Stage Popup PLAY bridge should commit selected stage id 1." % STAGE_SELECT_SCENE_PATH)
	if committed_boosters.size() != 1 or not committed_boosters.has("rainbow_paw"):
		errors.append("%s Stage Popup PLAY bridge should commit selected booster rainbow_paw, got %s." % [STAGE_SELECT_SCENE_PATH, str(committed_boosters)])

	await _validate_stage_popup_text_stress(node, errors)

	node.call("_on_stage_popup_close_pressed")
	await create_timer(0.25).timeout
	await process_frame
	if overlay != null and overlay.visible:
		errors.append("%s Stage Popup close should hide StagePopupOverlay after tween." % STAGE_SELECT_SCENE_PATH)
	var panel := node.get("stage_popup_panel") as Control
	if panel != null and panel.scale.distance_to(Vector2.ONE) > 0.01:
		errors.append("%s Stage Popup close should restore panel scale to Vector2.ONE." % STAGE_SELECT_SCENE_PATH)
	GameSession.set_selected_pre_boosters([])


func _validate_stage_popup_text_stress(node: Node, errors: PackedStringArray) -> void:
	node.call("_show_stage_popup", 4)
	await create_timer(0.22).timeout
	await process_frame
	var viewport_size := Vector2i(root.get_visible_rect().size)
	var panel := node.get("stage_popup_panel") as Control
	var title_label := node.get("stage_popup_title_label") as Label
	var goal_label := node.get("stage_popup_goal_label") as Label
	var meta_label := node.get("stage_popup_meta_label") as Label
	var reward_label := node.get("stage_popup_reward_label") as Label
	var buddy_label := node.get("stage_popup_buddy_label") as Label
	var start_button := _find_button_with_text(panel, "PLAY")
	var original_title := "" if title_label == null else title_label.text
	var original_goal := "" if goal_label == null else goal_label.text
	var original_meta := "" if meta_label == null else meta_label.text
	var original_reward := "" if reward_label == null else reward_label.text
	var original_buddy := "" if buddy_label == null else buddy_label.text
	var original_buddy_visible := false if buddy_label == null else buddy_label.visible
	var original_start := "" if start_button == null else start_button.text
	if title_label != null:
		title_label.text = CRITICAL_TEXT_STRESS_TITLE
	if goal_label != null:
		goal_label.text = "%s · collect rabbit 99 / blockers 12" % CRITICAL_TEXT_STRESS_BODY
	if meta_label != null:
		meta_label.text = "이동 99회 · 난이도 SuperLongDifficultyToken · [疑似]"
	if reward_label != null:
		reward_label.text = "%s · reward breakdown gold tokens boosters" % CRITICAL_TEXT_STRESS_BODY
	if buddy_label != null:
		buddy_label.visible = true
		buddy_label.text = "%s · rabbit quick_refill ready" % CRITICAL_TEXT_STRESS_BODY
	if start_button != null:
		start_button.text = CRITICAL_TEXT_STRESS_CTA
	await process_frame
	_validate_control_in_viewport(panel, viewport_size, STAGE_SELECT_SCENE_PATH, "StagePopupPanel text stress", errors)
	for control_info in [[title_label, "StagePopupTitle"], [goal_label, "StagePopupGoal"], [meta_label, "StagePopupMeta"], [reward_label, "StagePopupReward"], [buddy_label, "StagePopupBuddy"], [start_button, "StagePopupStartButton"]]:
		var control := control_info[0] as Control
		var label := String(control_info[1])
		if control != null and control.is_visible_in_tree():
			_validate_control_inside_container(control, panel, STAGE_SELECT_SCENE_PATH, "%s text stress" % label, errors)
	_validate_no_vertical_overlap(buddy_label, start_button, STAGE_SELECT_SCENE_PATH, "StagePopup buddy to PLAY", errors)
	if title_label != null:
		title_label.text = original_title
	if goal_label != null:
		goal_label.text = original_goal
	if meta_label != null:
		meta_label.text = original_meta
	if reward_label != null:
		reward_label.text = original_reward
	if buddy_label != null:
		buddy_label.text = original_buddy
		buddy_label.visible = original_buddy_visible
	if start_button != null:
		start_button.text = original_start


func _find_button_with_text(parent: Node, text: String) -> Button:
	if parent == null:
		return null
	for candidate in parent.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.text == text:
			return button
	return null


func _validate_alpha_gate_data(errors: PackedStringArray) -> void:
	_validate_animal_texture_manifest(errors)
	_validate_rescue_book_model(errors)
	_validate_fail_offer_policy(errors)
	_validate_live_event_config(errors)
	_validate_live_event_state_model(errors)

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

	_validate_rescue_buddy_stage_config(stage_by_id, errors)
	_validate_alpha_manual_qa_template_coverage(stages, errors)


func _validate_alpha_manual_qa_template_coverage(stages: Array, errors: PackedStringArray) -> void:
	if not FileAccess.file_exists(ALPHA_QA_TEMPLATE_PATH):
		errors.append("Alpha QA template missing at %s." % ALPHA_QA_TEMPLATE_PATH)
		return
	var template_text := FileAccess.get_file_as_string(ALPHA_QA_TEMPLATE_PATH)
	if template_text.strip_edges().is_empty():
		errors.append("Alpha QA template is empty at %s." % ALPHA_QA_TEMPLATE_PATH)
		return

	for stage_entry in stages:
		if not (stage_entry is Dictionary):
			continue
		var stage: Dictionary = stage_entry
		var stage_id := int(stage.get("id", 0))
		if bool(stage.get("recommended_smoke", false)):
			var smoke_id := "STAGE_SMOKE_%03d" % stage_id
			_require_alpha_template_text(
				template_text,
				smoke_id,
				"Alpha QA template missing stage-data-driven manual coverage: Stage %d recommended_smoke row %s." % [stage_id, smoke_id],
				errors
			)

		var buddy_skill_id := String(stage.get("buddy_skill_id", "")).strip_edges()
		if not buddy_skill_id.is_empty():
			var buddy_id := "BUDDY_STAGE_%03d" % stage_id
			_require_alpha_template_text(
				template_text,
				buddy_id,
				"Alpha QA template missing stage-data-driven manual coverage: Stage %d / %s row %s." % [stage_id, buddy_skill_id, buddy_id],
				errors
			)
			_require_alpha_template_text(
				template_text,
				buddy_skill_id,
				"Alpha QA template missing stage-data-driven Buddy skill evidence: Stage %d / %s." % [stage_id, buddy_skill_id],
				errors
			)
			var buddy_animal := String(stage.get("buddy_animal", "")).strip_edges()
			if not buddy_animal.is_empty():
				_require_alpha_template_text(
					template_text,
					buddy_animal,
					"Alpha QA template missing stage-data-driven Buddy animal evidence: Stage %d / %s." % [stage_id, buddy_animal],
					errors
				)

	for combo_row in SPECIAL_COMBO_MANUAL_ROWS:
		_require_alpha_template_text(
			template_text,
			combo_row,
			"Alpha QA template missing Stage 31 special combo evidence row: %s." % combo_row,
			errors
		)

	for scenario_id in ["Mobile viewport matrix", "390x844", "844x390", "Android debug APK export", "zsh scripts/export_android_debug.sh", "android-debug-export.txt", "Android release APK export/install", "zsh scripts/export_android_release.sh", "android-release-export.txt", "release-install-log.txt", "release-run-log.txt", "GODOT_ANDROID_KEYSTORE_RELEASE_PATH", "Android device evidence capture", "zsh scripts/capture_android_device_evidence.sh", "--allow-orientation-change", "android-device-evidence.txt", "device-info.txt", "Manual device checks", "zsh scripts/record_manual_device_checks.sh", "manual-device-checks.txt", "sound-toggle-notes.md", "haptics-toggle-notes.md", "touch-latency-notes.md", "Alpha QA report validation", "validate_alpha_qa_report.sh", "RESCUE_BOOK_COSMETIC_EQUIP", "rescue-book-cosmetic-equip", "SPECIAL_COMBO_6", "MONETIZATION_GATEWAY_PENDING", "ANALYTICS_GATEWAY_LOCAL_BUFFER"]:
		_require_alpha_template_text(
			template_text,
			scenario_id,
			"Alpha QA template missing focused evidence scenario: %s." % scenario_id,
			errors
		)


func _require_alpha_template_text(template_text: String, required_text: String, error_text: String, errors: PackedStringArray) -> void:
	if not template_text.contains(required_text):
		errors.append(error_text)


func _validate_first_session_collection_unlock_flow(errors: PackedStringArray) -> void:
	var animal_unlock_events_before := _analytics_event_count("animal_unlock")
	for stage_id in range(1, 6):
		GameSession.record_stage_result(stage_id, stage_id * 1000, 3)

	if GameSession.get_highest_unlocked_stage_id() < 6:
		errors.append("First session smoke should unlock Stage 6 after clearing Level 5, got highest stage %d." % GameSession.get_highest_unlocked_stage_id())

	var state_animals: Dictionary = Dictionary(GameSession.get_rescue_book_state().get("animals", {}))
	for animal_id in FIRST_SESSION_COLLECTION_UNLOCK_IDS:
		var entry := Dictionary(state_animals.get(animal_id, {}))
		if not bool(entry.get("unlocked", false)):
			errors.append("First session smoke should unlock Rescue Book card %s by Level 5." % animal_id)
		if not bool(entry.get("is_new", false)):
			errors.append("First session smoke should leave newly unlocked %s marked NEW for collection motivation." % animal_id)

	var unlocked_animals_from_events := {}
	for event in GameSession.get_analytics_events():
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		if String(event_dict.get("name", "")) != "animal_unlock":
			continue
		var params: Dictionary = Dictionary(event_dict.get("params", {}))
		if String(params.get("source", "")) == "stage_clear" and int(params.get("stage_id", 0)) <= 5:
			var animal_id := String(params.get("animal_id", ""))
			unlocked_animals_from_events[animal_id] = params
			if not params.has("token_balance"):
				errors.append("animal_unlock should include token_balance for %s." % animal_id)
			var expected_unlock_stage := int(FIRST_SESSION_COLLECTION_UNLOCK_STAGES.get(animal_id, 0))
			if expected_unlock_stage > 0:
				if int(params.get("unlock_stage", 0)) != expected_unlock_stage:
					errors.append("animal_unlock for %s should include unlock_stage %d." % [animal_id, expected_unlock_stage])
				var expected_trigger_stage := expected_unlock_stage - 1
				if int(params.get("stage_id", 0)) != expected_trigger_stage:
					errors.append("animal_unlock for %s should be triggered by clearing Level %d, got Level %d." % [animal_id, expected_trigger_stage, int(params.get("stage_id", 0))])
	if _analytics_event_count("animal_unlock") <= animal_unlock_events_before:
		errors.append("First session smoke should emit animal_unlock analytics while clearing Levels 1-5.")
	for animal_id in FIRST_SESSION_COLLECTION_UNLOCK_IDS:
		if not unlocked_animals_from_events.has(animal_id):
			errors.append("First session smoke should emit animal_unlock for %s by Level 5." % animal_id)


func _validate_rescue_buddy_stage_config(stage_by_id: Dictionary, errors: PackedStringArray) -> void:
	if not stage_by_id.has(4):
		errors.append("Rescue Buddy smoke expected Stage 4 to exist.")
		return
	var stage_four: Dictionary = Dictionary(stage_by_id[4])
	if String(stage_four.get("buddy_animal", "")) != "rabbit":
		errors.append("Stage 4 should normalize rabbit as its Rescue Buddy animal.")
	if String(stage_four.get("buddy_skill_id", "")) != "quick_refill":
		errors.append("Stage 4 should normalize quick_refill as its Rescue Buddy skill.")
	if String(stage_four.get("buddy_charge_rule", "")) != "match_goal_animal":
		errors.append("Stage 4 should charge Rescue Buddy from goal animal matches.")
	if int(stage_four.get("buddy_charges_required", 0)) != 3:
		errors.append("Stage 4 Rescue Buddy should require exactly 3 charges for MVP tuning.")
	if int(stage_four.get("buddy_max_uses", 0)) != 1:
		errors.append("Stage 4 Rescue Buddy should be capped at one use.")

	if not stage_by_id.has(5):
		errors.append("Rescue Buddy smoke expected Stage 5 to exist.")
		return
	var stage_five: Dictionary = Dictionary(stage_by_id[5])
	if String(stage_five.get("buddy_animal", "")) != "chick":
		errors.append("Stage 5 should normalize chick as its Rescue Buddy animal.")
	if String(stage_five.get("buddy_skill_id", "")) != "soft_bomb_plus":
		errors.append("Stage 5 should normalize soft_bomb_plus as its Rescue Buddy skill.")
	if int(stage_five.get("buddy_charges_required", 0)) != 4:
		errors.append("Stage 5 Rescue Buddy should require 4 charges for soft bomb tuning.")

	if not stage_by_id.has(8):
		errors.append("Rescue Buddy smoke expected Stage 8 to exist.")
		return
	var stage_eight: Dictionary = Dictionary(stage_by_id[8])
	if String(stage_eight.get("buddy_skill_id", "")) != "combo_peep":
		errors.append("Stage 8 should normalize combo_peep as its Rescue Buddy skill.")
	if String(stage_eight.get("buddy_charge_rule", "")) != "combo_2_plus":
		errors.append("Stage 8 combo_peep should charge from combo_2_plus.")

	if not stage_by_id.has(16):
		errors.append("Rescue Buddy smoke expected Stage 16 to exist.")
		return
	var stage_sixteen: Dictionary = Dictionary(stage_by_id[16])
	if String(stage_sixteen.get("buddy_animal", "")) != "cat":
		errors.append("Stage 16 should normalize cat as its Rescue Buddy animal.")
	if String(stage_sixteen.get("buddy_skill_id", "")) != "smart_hint":
		errors.append("Stage 16 should normalize smart_hint as its Rescue Buddy skill.")
	if int(stage_sixteen.get("buddy_charges_required", 0)) != 3:
		errors.append("Stage 16 Rescue Buddy should require 3 charges for smart hint tuning.")

	if not stage_by_id.has(18):
		errors.append("Rescue Buddy smoke expected Stage 18 to exist.")
		return
	var stage_eighteen: Dictionary = Dictionary(stage_by_id[18])
	if String(stage_eighteen.get("buddy_animal", "")) != "frog":
		errors.append("Stage 18 should normalize frog as its Rescue Buddy animal.")
	if String(stage_eighteen.get("buddy_skill_id", "")) != "leap_clear":
		errors.append("Stage 18 should normalize leap_clear as its Rescue Buddy skill.")
	if int(stage_eighteen.get("buddy_charges_required", 0)) != 3:
		errors.append("Stage 18 Rescue Buddy should require 3 charges for leap clear tuning.")

	if not stage_by_id.has(20):
		errors.append("Rescue Buddy smoke expected Stage 20 to exist.")
		return
	var stage_twenty: Dictionary = Dictionary(stage_by_id[20])
	if String(stage_twenty.get("buddy_animal", "")) != "dog":
		errors.append("Stage 20 should normalize dog as its Rescue Buddy animal.")
	if String(stage_twenty.get("buddy_skill_id", "")) != "loyal_fetch":
		errors.append("Stage 20 should normalize loyal_fetch as its Rescue Buddy skill.")
	if String(stage_twenty.get("buddy_charge_rule", "")) != "near_fail":
		errors.append("Stage 20 loyal_fetch should use near_fail charge rule.")

	if not stage_by_id.has(24):
		errors.append("Rescue Buddy smoke expected Stage 24 to exist.")
		return
	var stage_twenty_four: Dictionary = Dictionary(stage_by_id[24])
	if String(stage_twenty_four.get("buddy_animal", "")) != "panda":
		errors.append("Stage 24 should normalize panda as its Rescue Buddy animal.")
	if String(stage_twenty_four.get("buddy_skill_id", "")) != "calm_fever":
		errors.append("Stage 24 should normalize calm_fever as its Rescue Buddy skill.")
	if String(stage_twenty_four.get("buddy_charge_rule", "")) != "fever_start":
		errors.append("Stage 24 calm_fever should use fever_start charge rule.")

	if not stage_by_id.has(25):
		errors.append("Rescue Buddy smoke expected Stage 25 to exist.")
		return
	var stage_twenty_five: Dictionary = Dictionary(stage_by_id[25])
	if String(stage_twenty_five.get("buddy_animal", "")) != "pig":
		errors.append("Stage 25 should normalize pig as its Rescue Buddy animal.")
	if String(stage_twenty_five.get("buddy_skill_id", "")) != "coin_sniff":
		errors.append("Stage 25 should normalize coin_sniff as its Rescue Buddy skill.")
	if String(stage_twenty_five.get("buddy_charge_rule", "")) != "stage_clear":
		errors.append("Stage 25 coin_sniff should use stage_clear charge rule.")

	if not stage_by_id.has(31):
		errors.append("Rescue Buddy smoke expected Stage 31 to exist.")
		return
	var stage_thirty_one: Dictionary = Dictionary(stage_by_id[31])
	if String(stage_thirty_one.get("buddy_animal", "")) != "penguin":
		errors.append("Stage 31 should normalize penguin as its Rescue Buddy animal.")
	if String(stage_thirty_one.get("buddy_skill_id", "")) != "cascade_slide":
		errors.append("Stage 31 should normalize cascade_slide as its Rescue Buddy skill.")
	if String(stage_thirty_one.get("buddy_charge_rule", "")) != "cascade_step":
		errors.append("Stage 31 cascade_slide should use cascade_step charge rule.")

	if not stage_by_id.has(41):
		errors.append("Rescue Buddy smoke expected Stage 41 to exist.")
		return
	var stage_forty_one: Dictionary = Dictionary(stage_by_id[41])
	if String(stage_forty_one.get("buddy_animal", "")) != "fox":
		errors.append("Stage 41 should normalize fox as its Rescue Buddy animal.")
	if String(stage_forty_one.get("buddy_skill_id", "")) != "sly_route":
		errors.append("Stage 41 should normalize sly_route as its Rescue Buddy skill.")
	if String(stage_forty_one.get("buddy_charge_rule", "")) != "near_fail":
		errors.append("Stage 41 sly_route should use near_fail charge rule.")
	if int(stage_forty_one.get("buddy_max_uses", 0)) != 2:
		errors.append("Stage 41 hard near-fail Buddy should allow two uses for tuning.")

	if not stage_by_id.has(51):
		errors.append("Rescue Buddy smoke expected Stage 51 to exist.")
		return
	var stage_fifty_one: Dictionary = Dictionary(stage_by_id[51])
	if String(stage_fifty_one.get("buddy_animal", "")) != "lion":
		errors.append("Stage 51 should normalize lion as its Rescue Buddy animal.")
	if String(stage_fifty_one.get("buddy_skill_id", "")) != "brave_start":
		errors.append("Stage 51 should normalize brave_start as its Rescue Buddy skill.")
	if String(stage_fifty_one.get("buddy_charge_rule", "")) != "stage_start":
		errors.append("Stage 51 brave_start should use stage_start charge rule.")
	if int(stage_fifty_one.get("buddy_max_uses", 0)) != 1:
		errors.append("Stage 51 stage-start Buddy should remain one-shot even on hard stages.")

	if not stage_by_id.has(81):
		errors.append("Rescue Buddy smoke expected Stage 81 to exist.")
		return
	var stage_eighty_one: Dictionary = Dictionary(stage_by_id[81])
	if String(stage_eighty_one.get("buddy_animal", "")) != "elephant":
		errors.append("Stage 81 should normalize elephant as its Rescue Buddy animal.")
	if String(stage_eighty_one.get("buddy_skill_id", "")) != "mighty_push":
		errors.append("Stage 81 should normalize mighty_push as its Rescue Buddy skill.")
	if String(stage_eighty_one.get("buddy_charge_rule", "")) != "clear_blocker":
		errors.append("Stage 81 mighty_push should use clear_blocker charge rule.")
	if int(stage_eighty_one.get("buddy_max_uses", 0)) != 2:
		errors.append("Stage 81 hard blocker Buddy should allow two uses for tuning.")


func _validate_live_event_config(errors: PackedStringArray) -> void:
	for event_error in LiveEventService.validate_events():
		errors.append(event_error)
	_validate_live_event_status_model(errors)
	var smoke_stages_by_placement := {
		"home": 9,
		"collection": 9,
		"stage_select": 3,
		"result_overlay": 2,
	}
	for placement in smoke_stages_by_placement.keys():
		var smoke_stage := int(smoke_stages_by_placement[placement])
		if LiveEventService.active_events_for(smoke_stage, String(placement), -1, false).is_empty():
			errors.append("LiveEventService should expose %s event by stage %d." % [String(placement), smoke_stage])
	for event in LiveEventService.load_events():
		if not (event is Dictionary):
			continue
		var event_dict: Dictionary = event
		if not bool(event_dict.get("enabled", false)):
			continue
		for placement_value in Array(event_dict.get("placements", [])):
			var placement := String(placement_value)
			if not IMPLEMENTED_LIVE_EVENT_PLACEMENTS.has(placement):
				errors.append("enabled live event %s uses placement %s without an implemented surface." % [String(event_dict.get("id", "")), placement])


func _validate_live_event_status_model(errors: PackedStringArray) -> void:
	var active_fixture := {
		"enabled": true,
		"starts_at_unix": 1767225600,
		"ends_at_unix": 4102444799,
	}
	if LiveEventService.event_status(active_fixture, 1778198400) != "active":
		errors.append("LiveEventService should classify in-window events as active.")
	if LiveEventService.event_status(active_fixture, 1767225599) != "upcoming":
		errors.append("LiveEventService should classify pre-window events as upcoming.")
	if LiveEventService.event_status(active_fixture, 4102444800) != "ended":
		errors.append("LiveEventService should classify post-window events as ended.")
	if LiveEventService.event_status({"enabled": false}, 1778198400) != "disabled":
		errors.append("LiveEventService should classify disabled events as disabled.")
	var expected_status_text := {
		"active": "진행 중",
		"offline": "오프라인",
		"upcoming": "시작 전",
		"ended": "종료됨",
		"disabled": "중지됨",
	}
	for status in expected_status_text.keys():
		var actual_text := LiveEventService.status_text({"status": String(status)})
		if actual_text != String(expected_status_text[status]):
			errors.append("LiveEventService.status_text(%s) expected %s, got %s." % [String(status), String(expected_status_text[status]), actual_text])

	var inactive_home_events := LiveEventService.events_for(21, "home", 4102444800, true, false)
	var saw_ended_event := false
	for event in inactive_home_events:
		if event is Dictionary and String(Dictionary(event).get("status", "")) == "ended":
			saw_ended_event = true
	if not saw_ended_event:
		errors.append("LiveEventService.events_for(include_inactive=true) should expose ended event state.")

	var offline_events := LiveEventService.offline_events_for(9, "home", 1778198400)
	if offline_events.is_empty():
		errors.append("LiveEventService should expose offline fallback events for eligible home placement.")
	else:
		for event in offline_events:
			if String(Dictionary(event).get("status", "")) != "offline":
				errors.append("LiveEventService offline fallback events should be marked offline.")
	var forced_offline_display_events := LiveEventService.display_events_for(9, "home", 1778198400, false, true)
	if forced_offline_display_events.is_empty():
		errors.append("LiveEventService.display_events_for should expose offline fallback display events.")
	else:
		for event in forced_offline_display_events:
			var event_dict := Dictionary(event)
			if bool(event_dict.get("offline_fallback", false)) and String(event_dict.get("status", "")) != "offline":
				errors.append("LiveEventService.display_events_for should mark offline fallback display events as offline.")

	var exposure_count_before := _analytics_event_count("remote_config_exposure")
	LiveEventService.active_events_for(9, "home", 1778198400, false)
	if _analytics_event_count("remote_config_exposure") != exposure_count_before:
		errors.append("LiveEventService status/config validation should not record remote_config_exposure.")


func _validate_live_event_state_model(errors: PackedStringArray) -> void:
	var event_id := "__validation_live_event"
	var event_type := "validation"
	var placement := "validator"
	var wallet_before := GameSession.get_wallet()
	if not GameSession.join_live_event(event_id, event_type, placement):
		errors.append("GameSession should join a new live event once.")
	if GameSession.join_live_event(event_id, event_type, placement):
		errors.append("GameSession should not emit duplicate live event joins.")

	var progress_value := GameSession.increment_live_event_progress(event_id, "checks", 2, event_type, placement)
	if progress_value != 2:
		errors.append("GameSession live event progress increment expected 2, got %d." % progress_value)
	GameSession.set_live_event_progress(event_id, "checks", 5, event_type, placement)
	var state := GameSession.get_live_event_state(event_id)
	if not bool(state.get("joined", false)):
		errors.append("GameSession live event state should persist joined=true.")
	var progress: Dictionary = Dictionary(state.get("progress", {}))
	if int(progress.get("checks", 0)) != 5:
		errors.append("GameSession live event state should persist latest progress value.")

	var reward_id := "%s:reward" % event_id
	var reward := {
		"gold": 25,
		"tokens": 3,
		"boosters": {
			"striped": 1,
		},
	}
	if not GameSession.claim_live_event_reward(event_id, reward_id, event_type, placement, reward):
		errors.append("GameSession should claim a new live event reward once.")
	if GameSession.claim_live_event_reward(event_id, reward_id, event_type, placement, reward):
		errors.append("GameSession should not claim the same live event reward twice.")
	if not GameSession.is_live_event_reward_claimed(event_id, reward_id):
		errors.append("GameSession should report claimed live event rewards.")

	var wallet_after := GameSession.get_wallet()
	if int(wallet_after.get("gold", 0)) != int(wallet_before.get("gold", 0)) + 25:
		errors.append("GameSession live event reward should add gold once.")
	if int(wallet_after.get("tokens", 0)) != int(wallet_before.get("tokens", 0)) + 3:
		errors.append("GameSession live event reward should add event tokens once.")
	var boosters_before: Dictionary = Dictionary(wallet_before.get("boosters", {}))
	var boosters_after: Dictionary = Dictionary(wallet_after.get("boosters", {}))
	if int(boosters_after.get("striped", 0)) != int(boosters_before.get("striped", 0)) + 1:
		errors.append("GameSession live event reward should add booster inventory once.")
	var reward_claim_event := _last_analytics_event_by_name("event_reward_claim")
	var reward_params: Dictionary = Dictionary(reward_claim_event.get("params", {}))
	if String(reward_params.get("reward_type", "")) != "mixed":
		errors.append("GameSession mixed live event rewards should emit reward_type=mixed.")
	var reward_breakdown: Dictionary = Dictionary(reward_params.get("reward_breakdown", {}))
	if int(reward_breakdown.get("gold", 0)) != 25 or int(reward_breakdown.get("tokens", 0)) != 3:
		errors.append("GameSession mixed live event rewards should include gold and token breakdown.")
	var booster_breakdown: Dictionary = Dictionary(reward_breakdown.get("boosters", {}))
	if int(booster_breakdown.get("striped", 0)) != 1:
		errors.append("GameSession mixed live event rewards should include booster breakdown.")


func _validate_fail_offer_policy(errors: PackedStringArray) -> void:
	var near_miss_offer := FailOfferPolicy.build_offer({"id": 25, "target_collect": {"rabbit": 10}}, {"collected_counts": {"rabbit": 9}, "fail_count": 1})
	if near_miss_offer.get("type") != FailOfferPolicy.TYPE_NEAR_MISS:
		errors.append("FailOfferPolicy should classify 1-2 remaining goals as near_miss.")
	if not bool(near_miss_offer.get("show_rewarded_ad", false)) or not bool(near_miss_offer.get("show_iap", false)):
		errors.append("FailOfferPolicy should enable ad/iap offers for eligible midgame near miss failure.")
	var tuned_near_miss_offer := FailOfferPolicy.build_offer({"id": 25, "target_collect": {"rabbit": 10}}, {"collected_counts": {"rabbit": 7}, "fail_count": 1, "near_miss_goal_threshold": 3, "near_miss_progress_threshold": 0.95})
	if tuned_near_miss_offer.get("type") != FailOfferPolicy.TYPE_NEAR_MISS:
		errors.append("FailOfferPolicy should respect remote-config near_miss_goal_threshold tuning.")
	var strict_progress_offer := FailOfferPolicy.build_offer({"id": 25, "target_collect": {"rabbit": 10}}, {"collected_counts": {"rabbit": 8}, "fail_count": 1, "near_miss_goal_threshold": 1, "near_miss_progress_threshold": 0.95})
	if strict_progress_offer.get("type") == FailOfferPolicy.TYPE_NEAR_MISS:
		errors.append("FailOfferPolicy should respect strict remote-config near_miss_progress_threshold tuning.")

	var repeat_offer := FailOfferPolicy.build_offer({"id": 25, "target_blockers": 4}, {"cleared_blockers": 1, "score": 0, "fail_count": 2})
	if repeat_offer.get("type") != FailOfferPolicy.TYPE_REPEAT_FAIL:
		errors.append("FailOfferPolicy should classify repeated failures before strategic shortfall.")

	var strategic_offer := FailOfferPolicy.build_offer({"id": 25, "target_collect": {"rabbit": 10}, "target_blockers": 4}, {"collected_counts": {"rabbit": 1}, "cleared_blockers": 0, "fail_count": 1})
	if strategic_offer.get("type") != FailOfferPolicy.TYPE_STRATEGIC:
		errors.append("FailOfferPolicy should classify a severe midgame first failure as strategic_miss.")
	if String(strategic_offer.get("primary_cta", "")) != "재도전" or String(strategic_offer.get("secondary_cta", "")) != "홈으로":
		errors.append("FailOfferPolicy strategic_miss should keep non-purchase retry/home CTAs.")
	if bool(strategic_offer.get("show_rewarded_ad", false)) or bool(strategic_offer.get("show_iap", false)):
		errors.append("FailOfferPolicy strategic_miss should not offer ad/iap monetization by default.")

	var hard_offer := FailOfferPolicy.build_offer({"id": 51, "difficulty": "Hard", "target_blockers": 9}, {"cleared_blockers": 0, "fail_count": 1})
	if hard_offer.get("type") != FailOfferPolicy.TYPE_HARD_FAIL:
		errors.append("FailOfferPolicy should classify hard midgame failures as hard_level_fail.")
	if String(hard_offer.get("primary_cta", "")) != "+3 이동 받고 계속" or String(hard_offer.get("secondary_cta", "")) != "재도전":
		errors.append("FailOfferPolicy hard_level_fail should expose continue/retry CTAs.")
	if not bool(hard_offer.get("show_rewarded_ad", false)) or not bool(hard_offer.get("show_iap", false)):
		errors.append("FailOfferPolicy hard_level_fail should allow eligible ad/iap offers after Stage 16.")

	var early_offer := FailOfferPolicy.build_offer({"id": 3, "target_score": 1000}, {"score": 300, "fail_count": 1})
	if early_offer.get("type") != FailOfferPolicy.TYPE_FIRST_FAIL:
		errors.append("FailOfferPolicy should preserve first_fail classification for early tutorial stages.")
	if bool(early_offer.get("show_rewarded_ad", false)) or bool(early_offer.get("show_iap", false)):
		errors.append("FailOfferPolicy should suppress monetization offers in early tutorial stages.")


func _validate_rescue_book_model(errors: PackedStringArray) -> void:
	var animals := CollectionState.load_animal_definitions()
	if animals.size() != 18:
		errors.append("Rescue Book expected 18 launch animal definitions, got %d." % animals.size())
	var seen_ids := {}
	var board_ids: Array[String] = []
	for animal in animals:
		if not (animal is Dictionary):
			errors.append("Rescue Book animal definition must be a dictionary.")
			continue
		var animal_dict: Dictionary = animal
		var animal_id := String(animal_dict.get("id", ""))
		if seen_ids.has(animal_id):
			errors.append("Rescue Book has duplicate animal id %s." % animal_id)
		seen_ids[animal_id] = true
		if int(animal_dict.get("unlock_stage", 0)) <= 0:
			errors.append("Rescue Book animal %s has invalid unlock_stage." % animal_id)
		if bool(animal_dict.get("board_enabled", false)):
			board_ids.append(animal_id)
		if not bool(animal_dict.get("collection_enabled", false)):
			errors.append("Rescue Book animal %s must be collection_enabled." % animal_id)
		if String(animal_dict.get("animation_profile", "")).is_empty():
			errors.append("Rescue Book animal %s missing animation_profile." % animal_id)
		if ["rabbit", "frog", "koala"].has(animal_id):
			var rewards := Array(animal_dict.get("friendship_rewards", []))
			if rewards.size() != 5:
				errors.append("Rescue Book animal %s should define five MVP friendship rewards." % animal_id)
			for reward in rewards:
				if not (reward is Dictionary):
					errors.append("Rescue Book animal %s friendship reward must be a dictionary." % animal_id)
					continue
				var reward_dict: Dictionary = reward
				if int(reward_dict.get("level", 0)) < 1 or int(reward_dict.get("level", 0)) > 5:
					errors.append("Rescue Book animal %s friendship reward has invalid level." % animal_id)
				if String(reward_dict.get("reward_id", "")).is_empty() or String(reward_dict.get("reward_type", "")).is_empty():
					errors.append("Rescue Book animal %s friendship reward must include reward_id and reward_type." % animal_id)

	if board_ids.size() != ANIMAL_IDS.size():
		errors.append("Board roster expected %d board_enabled animals, got %d." % [ANIMAL_IDS.size(), board_ids.size()])
	for animal_id in ANIMAL_IDS:
		if not board_ids.has(animal_id):
			errors.append("Board roster missing board_enabled animal %s." % animal_id)

	_validate_animation_profiles(animals, errors)

	var default_state := CollectionState.make_default_state()
	var state_animals: Dictionary = Dictionary(default_state.get("animals", {}))
	for animal_id in seen_ids.keys():
		if not state_animals.has(animal_id):
			errors.append("Rescue Book default state missing %s." % animal_id)

	var rabbit_token_state := CollectionState.add_tokens(default_state, "rabbit", 40)
	var rabbit_entry: Dictionary = Dictionary(Dictionary(rabbit_token_state.get("animals", {})).get("rabbit", {}))
	if int(rabbit_entry.get("tokens", 0)) != 40:
		errors.append("Rescue Book token grant should persist token balance.")
	if int(rabbit_entry.get("friendship_level", 1)) < 3:
		errors.append("Rescue Book friendship level should advance from token balance.")
	var earned_rewards := Array(rabbit_entry.get("earned_rewards", []))
	for reward_id in ["rabbit_icon_basic", "rabbit_smile_plus", "rabbit_sprout_frame"]:
		if not earned_rewards.has(reward_id):
			errors.append("Rescue Book friendship reward %s should be earned by Lv.3." % reward_id)
	if CollectionState.reward_entries_earned_between("rabbit", 1, 3).size() != 2:
		errors.append("Rescue Book reward diff should return the Lv.2 and Lv.3 rabbit rewards.")


func _validate_animation_profiles(animals: Array, errors: PackedStringArray) -> void:
	if not FileAccess.file_exists(ANIMAL_PROFILE_PATH):
		errors.append("missing %s" % ANIMAL_PROFILE_PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(ANIMAL_PROFILE_PATH))
	if not (parsed is Array):
		errors.append("animal animation profiles must be an array")
		return
	var profiles_by_id := {}
	for profile in Array(parsed):
		if not (profile is Dictionary):
			errors.append("animal animation profile entry must be a dictionary")
			continue
		var profile_dict: Dictionary = profile
		var profile_id := String(profile_dict.get("profile_id", ""))
		profiles_by_id[profile_id] = profile_dict
		if int(profile_dict.get("max_frame_count", 0)) > 13:
			errors.append("animation profile %s exceeds 13 frame MVP limit" % profile_id)
		var states: Dictionary = Dictionary(profile_dict.get("states", {}))
		for expression_id in ["idle", "blink", "smile", "match", "fever", "worried"]:
			if not states.has(expression_id):
				errors.append("animation profile %s missing %s" % [profile_id, expression_id])

	for animal in animals:
		if not (animal is Dictionary):
			continue
		var animal_dict: Dictionary = animal
		var profile_id := String(animal_dict.get("animation_profile", ""))
		if not profiles_by_id.has(profile_id):
			errors.append("animal %s references missing animation profile %s" % [String(animal_dict.get("id", "")), profile_id])


func _validate_animal_texture_manifest(errors: PackedStringArray) -> void:
	for animal_id in ANIMAL_IDS:
		var texture_path := "res://assets/generated/candy/%s_candy_block.png" % animal_id
		var texture := load(texture_path)
		if not (texture is Texture2D):
			errors.append("Animal direct texture did not load as Texture2D: %s." % texture_path)
			continue
		var texture_2d := texture as Texture2D
		if texture_2d.get_width() != MVP_BOARD_TEXTURE_SIZE.x or texture_2d.get_height() != MVP_BOARD_TEXTURE_SIZE.y:
			errors.append("Animal direct texture should be %dx%d: %s is %dx%d." % [MVP_BOARD_TEXTURE_SIZE.x, MVP_BOARD_TEXTURE_SIZE.y, texture_path, texture_2d.get_width(), texture_2d.get_height()])
