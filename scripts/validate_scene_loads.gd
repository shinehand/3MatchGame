extends SceneTree

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const CollectionState = preload("res://scripts/collection_state.gd")
const GameSession = preload("res://scripts/game_session.gd")
const FailOfferPolicy = preload("res://scripts/fail_offer_policy.gd")
const LiveEventService = preload("res://scripts/live_event_service.gd")

const LOADING_SCENE_PATH: String = "res://scenes/loading.tscn"
const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"
const STAGE_SELECT_SCENE_PATH: String = "res://scenes/stage_select.tscn"
const COLLECTION_SCENE_PATH: String = "res://scenes/collection_screen.tscn"
const GAMEPLAY_SCENE_PATH: String = "res://scenes/gameplay.tscn"
const STAGE_CARD_SCENE_PATH: String = "res://scenes/stage_card.tscn"
const BLOCK_TILE_SCENE_PATH: String = "res://scenes/block_tile.tscn"
const GOAL_CHIP_SCENE_PATH: String = "res://scenes/goal_chip.tscn"
const SESSION_VALIDATION_SAVE_PATH := "user://scene_validation_save_game.json"
const SESSION_VALIDATION_SAVE_FILE_NAME := "scene_validation_save_game.json"
const ANIMAL_IDS := ["rabbit", "bear", "cat", "chick", "frog", "dog", "panda", "pig", "penguin", "fox", "lion", "elephant"]
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

var representative_stage_ids: Array[int] = [1, 11, 25, 50, 75, 100]
var tutorial_stage_ids: Array[int] = [1, 11, 25, 45, 65, 85, 95]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	GameSession.use_save_path_for_testing(SESSION_VALIDATION_SAVE_PATH)
	LiveEventService.reset_remote_config_exposures_for_testing()
	_remove_validation_save()
	var errors: PackedStringArray = PackedStringArray()
	GameSession.clear_analytics_events()
	_validate_alpha_gate_data(errors)
	var scene_paths: PackedStringArray = PackedStringArray([
		LOADING_SCENE_PATH,
		MAIN_SCENE_PATH,
		STAGE_SELECT_SCENE_PATH,
		COLLECTION_SCENE_PATH,
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
		await _validate_viewport_resilience(scene_path, node, errors)
		await create_timer(0.2).timeout
		if is_instance_valid(node):
			node.queue_free()
		await process_frame
		await process_frame

	_validate_runtime_analytics_events(errors)
	if not errors.is_empty():
		for error_text in errors:
			push_error("Scene load validation error: %s" % error_text)
		_remove_validation_save()
		quit(1)
		return

	print("Scene load validation passed: %d scenes parsed and instantiated." % scene_paths.size())
	_remove_validation_save()
	quit()


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
		STAGE_SELECT_SCENE_PATH:
			_validate_stage_select_scene(node, errors)
		COLLECTION_SCENE_PATH:
			_validate_collection_scene(node, errors)

	return errors


func _validate_viewport_resilience(scene_path: String, node: Node, errors: PackedStringArray) -> void:
	if not [MAIN_SCENE_PATH, STAGE_SELECT_SCENE_PATH, GAMEPLAY_SCENE_PATH, COLLECTION_SCENE_PATH].has(scene_path):
		return

	# The project uses Godot stretch/canvas_items with a 1080x1920 logical canvas.
	# Headless validation should therefore inspect the logical safe area instead of
	# forcing physical window sizes, which would bypass the runtime stretch contract.
	await process_frame
	var viewport_size := Vector2i(root.get_visible_rect().size)
	match scene_path:
		MAIN_SCENE_PATH:
			_validate_main_viewport_layout(node, viewport_size, errors)
		STAGE_SELECT_SCENE_PATH:
			_validate_stage_select_viewport_layout(node, viewport_size, errors)
		GAMEPLAY_SCENE_PATH:
			_validate_gameplay_viewport_layout(node, viewport_size, errors)
		COLLECTION_SCENE_PATH:
			_validate_collection_viewport_layout(node, viewport_size, errors)


func _validate_main_viewport_layout(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var game_home_layer := node.get_node_or_null("GameHomeLayer") as CanvasItem
	if game_home_layer != null and not game_home_layer.visible:
		errors.append("%s GameHomeLayer should remain visible at %s." % [MAIN_SCENE_PATH, viewport_size])
	_validate_control_in_viewport(node.find_child("PlayButton", true, false), viewport_size, MAIN_SCENE_PATH, "PlayButton", errors)
	_validate_control_in_viewport(node.find_child("StageButton", true, false), viewport_size, MAIN_SCENE_PATH, "StageButton", errors)


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


func _validate_gameplay_viewport_layout(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	var board_frame := node.get_node_or_null("SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame") as Control
	_validate_control_in_viewport(board_frame, viewport_size, GAMEPLAY_SCENE_PATH, "BoardFrame", errors)
	if board_frame != null:
		var board_rect := board_frame.get_global_rect()
		var min_expected_board_side: float = min(float(viewport_size.x), float(viewport_size.y)) * 0.46
		if board_rect.size.x < min_expected_board_side or board_rect.size.y < min_expected_board_side:
			errors.append("%s BoardFrame is too small at %s: %s, expected each side >= %.1f." % [GAMEPLAY_SCENE_PATH, viewport_size, board_rect.size, min_expected_board_side])
	_validate_control_in_viewport(node.find_child("HudGoalDock", true, false), viewport_size, GAMEPLAY_SCENE_PATH, "HudGoalDock", errors)
	_validate_control_in_viewport(node.find_child("HudBoosterDock", true, false), viewport_size, GAMEPLAY_SCENE_PATH, "HudBoosterDock", errors)
	if node.find_child("HudBuddyGauge", true, false) == null:
		errors.append("%s missing responsive layout target HudBuddyGauge at %s." % [GAMEPLAY_SCENE_PATH, viewport_size])


func _validate_collection_viewport_layout(node: Node, viewport_size: Vector2i, errors: PackedStringArray) -> void:
	_validate_control_in_viewport(node.find_child("SummaryLabel", true, false), viewport_size, COLLECTION_SCENE_PATH, "SummaryLabel", errors)
	var collection_grid := node.find_child("CollectionGrid", true, false) as GridContainer
	if collection_grid == null:
		errors.append("%s missing responsive layout target CollectionGrid at %s." % [COLLECTION_SCENE_PATH, viewport_size])


func _validate_control_in_viewport(candidate: Node, viewport_size: Vector2i, scene_path: String, label: String, errors: PackedStringArray) -> void:
	if not (candidate is Control):
		errors.append("%s missing responsive layout target %s at %s." % [scene_path, label, viewport_size])
		return
	var control := candidate as Control
	if not control.visible:
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


func _validate_runtime_analytics_events(errors: PackedStringArray) -> void:
	var events := GameSession.get_analytics_events()
	var seen_names := {}
	var live_events_by_id := _live_events_by_id()
	for event in events:
		if not (event is Dictionary):
			errors.append("runtime analytics event should be a dictionary")
			continue
		var event_dict: Dictionary = event
		var event_name := String(event_dict.get("name", ""))
		var params := Dictionary(event_dict.get("params", {}))
		seen_names[event_name] = true
		var missing_params := GameSession.analytics_event_missing_required_params(event_name, params)
		if not missing_params.is_empty():
			errors.append("runtime analytics event %s missing required params: %s" % [event_name, ", ".join(Array(missing_params))])
		match event_name:
			"live_event_impression":
				_validate_live_event_impression_payload(params, live_events_by_id, errors)
			"remote_config_exposure":
				_validate_remote_config_exposure_payload(params, errors)
	for required_event in ["rescue_book_open", "stage_start", "remote_config_exposure", "event_join", "event_progress", "event_reward_claim", "buddy_skill_charge", "buddy_skill_ready", "buddy_skill_trigger", "buddy_skill_blocked"]:
		if not seen_names.has(required_event):
			errors.append("runtime analytics should emit %s during scene smoke." % required_event)
	var active_current_live_events := false
	for placement in ["home", "collection", "stage_select"]:
		if not LiveEventService.active_events_for(GameSession.get_highest_unlocked_stage_id(), placement).is_empty():
			active_current_live_events = true
	if active_current_live_events and not seen_names.has("live_event_impression"):
		errors.append("runtime analytics should emit live_event_impression when active live events are visible.")


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

	var animal_strip := node.get_node_or_null("GameHomeLayer/HeroStack/AnimalStrip") as HBoxContainer
	if animal_strip == null:
		errors.append("%s is missing the 12-animal home preview strip." % MAIN_SCENE_PATH)
	elif animal_strip.get_child_count() < ANIMAL_IDS.size():
		errors.append("%s AnimalStrip should show all %d board animals, got %d." % [MAIN_SCENE_PATH, ANIMAL_IDS.size(), animal_strip.get_child_count()])
	if node.get_node_or_null("GameHomeLayer/HeroStack/LiveEventStrip") == null:
		errors.append("%s is missing LiveEventStrip for live ops surface checks." % MAIN_SCENE_PATH)
	_validate_main_event_detail_overlay(node, errors)


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

	_validate_special_effect_rules(node, errors)
	_validate_expression_animation_rules(node, errors)
	_validate_rescue_buddy_runtime_rules(node, errors)


func _validate_expression_animation_rules(node: Node, errors: PackedStringArray) -> void:
	if not node.has_method("_play_random_idle_blinks") or not node.has_method("_active_visible_tiles"):
		errors.append("%s should expose idle expression scheduler helpers for QA smoke validation." % GAMEPLAY_SCENE_PATH)
		return

	var candidates: Array = node.call("_active_visible_tiles")
	if candidates.size() < 4:
		errors.append("%s expression QA expected at least four active visible tiles, got %d." % [GAMEPLAY_SCENE_PATH, candidates.size()])
		return

	node.call("_play_random_idle_blinks")
	var active_idle_expressions := 0
	for tile in candidates:
		if tile != null and String(tile.get("expression_state")) == "blink":
			active_idle_expressions += 1
	if active_idle_expressions <= 0:
		errors.append("%s idle expression smoke should start at least one blink." % GAMEPLAY_SCENE_PATH)
	elif active_idle_expressions > 4:
		errors.append("%s idle expression smoke should cap concurrent blink tiles at 4, got %d." % [GAMEPLAY_SCENE_PATH, active_idle_expressions])

	var priority_tile = candidates[0]
	if priority_tile != null and priority_tile.has_method("set_expression"):
		priority_tile.set_expression("match", true)
		priority_tile.set_expression("blink")
		if String(priority_tile.get("expression_state")) != "match":
			errors.append("%s match expression priority should not be overwritten by blink." % GAMEPLAY_SCENE_PATH)


func _validate_rescue_buddy_runtime_rules(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_charge_buddy_skill_for_match", "_trigger_buddy_skill", "_try_loyal_fetch_before_failure"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for Rescue Buddy runtime smoke." % [GAMEPLAY_SCENE_PATH, method_name])
			return

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


func _validate_special_effect_rules(node: Node, errors: PackedStringArray) -> void:
	var from_cell := Vector2i(3, 3)
	var to_cell := Vector2i(3, 4)
	if Array(node.get("board_data")).size() < 8:
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

	for animal_id in collection_ids:
		if node.find_child("AnimalCard_%s" % animal_id, true, false) == null:
			errors.append("%s missing AnimalCard_%s." % [COLLECTION_SCENE_PATH, animal_id])
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

	var world_play_button := node.find_child("WorldPlayButton", true, false) as Button
	if world_play_button == null:
		errors.append("%s is missing the world-map action button." % STAGE_SELECT_SCENE_PATH)

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

	var map_juice_layer := node.get_node_or_null("StageMapJuiceLayer") as CanvasItem
	if map_juice_layer == null:
		errors.append("%s is missing StageMapJuiceLayer ambient mascots." % STAGE_SELECT_SCENE_PATH)


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

	var repeat_offer := FailOfferPolicy.build_offer({"id": 25, "target_blockers": 4}, {"cleared_blockers": 1, "score": 0, "fail_count": 2})
	if repeat_offer.get("type") != FailOfferPolicy.TYPE_REPEAT_FAIL:
		errors.append("FailOfferPolicy should classify repeated failures before strategic shortfall.")

	var early_offer := FailOfferPolicy.build_offer({"id": 3, "target_score": 1000}, {"score": 300, "fail_count": 1})
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
