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
const FX_LAYER_SCENE_PATH: String = "res://scenes/fx_layer.tscn"
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
		FX_LAYER_SCENE_PATH:
			_validate_fx_layer_scene(node, errors)
		STAGE_SELECT_SCENE_PATH:
			_validate_stage_select_scene(node, errors)
		COLLECTION_SCENE_PATH:
			_validate_collection_scene(node, errors)

	return errors


func _validate_scene_runtime_specifics(scene_path: String, node: Node, errors: PackedStringArray) -> void:
	match scene_path:
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
	var live_event_placements_seen := {}
	var remote_config_keys_seen := {}
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
				live_event_placements_seen[String(params.get("placement", ""))] = true
			"remote_config_exposure":
				_validate_remote_config_exposure_payload(params, errors)
				remote_config_keys_seen[String(params.get("config_key", ""))] = true
	for required_event in ["rescue_book_open", "stage_start", "remote_config_exposure", "event_join", "event_progress", "event_reward_claim", "buddy_skill_charge", "buddy_skill_ready", "buddy_skill_trigger", "buddy_skill_blocked", "fail_offer_show", "fail_offer_select", "fail_offer_dismiss", "ad_reward_complete", "ad_reward_fail", "iap_purchase_start", "iap_purchase_cancel", "iap_purchase_fail", "extra_moves_grant"]:
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
	if node.has_method("_track_live_event_impression"):
		node.call("_track_live_event_impression", _live_event_by_id("daily_reward_v1"), "home")


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
	_validate_start_booster_runtime_rules(node, errors)


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
	if node.find_child("GoalRescueLabel", true, false) == null:
		errors.append("%s play_goal_rescue should spawn GoalRescueLabel." % FX_LAYER_SCENE_PATH)
	if node.find_child("BlockerClearRing", true, false) == null:
		errors.append("%s play_blocker_clear_at should spawn BlockerClearRing." % FX_LAYER_SCENE_PATH)
	if node.find_child("BlockerClearLabel", true, false) == null:
		errors.append("%s play_blocker_clear_at should spawn BlockerClearLabel." % FX_LAYER_SCENE_PATH)
	if node.find_child("RainbowFlash", true, false) == null:
		errors.append("%s play_rainbow_clear should spawn RainbowFlash." % FX_LAYER_SCENE_PATH)
	if board_root.get_child_count() > 12:
		errors.append("%s BoardFxRoot should keep simultaneous no-device VFX children <= 12, got %d." % [FX_LAYER_SCENE_PATH, board_root.get_child_count()])
	if hud_root.get_child_count() > 4:
		errors.append("%s HudFxRoot should keep simultaneous no-device VFX children <= 4, got %d." % [FX_LAYER_SCENE_PATH, hud_root.get_child_count()])
	if screen_root.get_child_count() > 6:
		errors.append("%s ScreenFxRoot should keep simultaneous no-device VFX children <= 6, got %d." % [FX_LAYER_SCENE_PATH, screen_root.get_child_count()])
	await create_timer(1.1).timeout
	if board_root.get_child_count() != 0 or hud_root.get_child_count() != 0 or screen_root.get_child_count() != 0:
		errors.append("%s VFX smoke should clean up transient child nodes, got board=%d hud=%d screen=%d." % [FX_LAYER_SCENE_PATH, board_root.get_child_count(), hud_root.get_child_count(), screen_root.get_child_count()])


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
	for method_name in ["_start_stage", "_charge_buddy_skill_for_match", "_charge_buddy_skill_for_combo", "_charge_buddy_skill_for_clear_blocker", "_charge_buddy_skill_for_cascade_step", "_charge_buddy_skill_for_near_fail", "_charge_buddy_skill_for_stage_clear", "_trigger_buddy_skill", "_try_loyal_fetch_before_failure", "_activate_fever", "_consume_fever_turn_after_player_move", "_stage_gold_reward", "_active_visible_tiles"]:
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


func _validate_special_combo_swap_runtime(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_resolve_swap", "_make_piece"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for special combo runtime smoke." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	var scenarios: Array = [
		{"label": "row+column", "from_special": "row", "to_special": "col", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(2, 4)},
		{"label": "row+row", "from_special": "row", "to_special": "row", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(3, 0)},
		{"label": "column+column", "from_special": "col", "to_special": "col", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(4, 3), "obstacle_cell": Vector2i(0, 3)},
		{"label": "row+bomb", "from_special": "row", "to_special": "bomb", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(2, 4)},
		{"label": "column+bomb", "from_special": "col", "to_special": "bomb", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(4, 3), "obstacle_cell": Vector2i(4, 4)},
		{"label": "bomb+bomb", "from_special": "bomb", "to_special": "bomb", "from_cell": Vector2i(3, 3), "to_cell": Vector2i(3, 4), "obstacle_cell": Vector2i(2, 3)},
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
	if String(node.get("stage_state")) != "playing":
		errors.append("%s %s runtime smoke should leave Stage 31 in playing state, got %s." % [GAMEPLAY_SCENE_PATH, label, String(node.get("stage_state"))])


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


func _validate_result_overlay_runtime(node: Node, errors: PackedStringArray) -> void:
	for method_name in ["_start_stage", "_check_stage_state", "_on_overlay_primary_button_pressed", "_on_overlay_secondary_button_pressed", "_resolve_fail_offer_continue_result", "_current_stage", "_current_stage_id", "_build_failure_focus_summary", "_build_failure_retry_hint", "_build_failure_offer"]:
		if not node.has_method(method_name):
			errors.append("%s should expose %s for result overlay runtime smoke." % [GAMEPLAY_SCENE_PATH, method_name])
			return

	_validate_failure_focus_hint_runtime(node, errors)
	node.call("_start_stage", 0)
	_complete_current_stage_goals(node)
	node.set("remaining_moves", 0)
	var complete_events_before := _analytics_event_count("stage_complete")
	await node.call("_check_stage_state")
	var overlay := node.get_node_or_null("Overlay") as CanvasItem
	var overlay_title := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayTitle") as Label
	var overlay_body := node.get_node_or_null("Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody") as Label
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
	if overlay_primary == null or overlay_primary.text != "다음 스테이지":
		errors.append("%s clear overlay primary CTA should be 다음 스테이지." % GAMEPLAY_SCENE_PATH)
	if overlay_secondary == null or not overlay_secondary.visible or overlay_secondary.text != "홈으로":
		errors.append("%s clear overlay secondary CTA should be visible 홈으로." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("stage_complete") <= complete_events_before:
		errors.append("%s clear overlay runtime smoke should emit stage_complete analytics." % GAMEPLAY_SCENE_PATH)

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
	if _analytics_event_count("iap_purchase_start") < iap_start_events_before + 2:
		errors.append("%s IAP cancel/fail smoke should emit iap_purchase_start for each purchase attempt." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_cancel") <= iap_cancel_events_before:
		errors.append("%s IAP cancel smoke should emit iap_purchase_cancel analytics." % GAMEPLAY_SCENE_PATH)
	if _analytics_event_count("iap_purchase_fail") <= iap_fail_events_before:
		errors.append("%s IAP failure smoke should emit iap_purchase_fail analytics." % GAMEPLAY_SCENE_PATH)
	if String(node.get("stage_state")) != "failed" or int(node.get("remaining_moves")) != failed_continue_moves or int(GameSession.get_wallet().get("gold", 0)) != int(wallet_before_failed_continue.get("gold", 0)):
		errors.append("%s IAP cancel/fail should preserve failed state, moves, and wallet." % GAMEPLAY_SCENE_PATH)

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

	for animal_id in collection_ids:
		if node.find_child("AnimalCard_%s" % animal_id, true, false) == null:
			errors.append("%s missing AnimalCard_%s." % [COLLECTION_SCENE_PATH, animal_id])
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


func _validate_collection_card_label_state(node: Node, errors: PackedStringArray) -> void:
	if not node.has_method("_refresh_cards"):
		errors.append("%s should expose _refresh_cards for Rescue Book card state smoke." % COLLECTION_SCENE_PATH)
		return
	var grid := node.find_child("CollectionGrid", true, false)
	if grid == null:
		errors.append("%s is missing CollectionGrid for Rescue Book card state smoke." % COLLECTION_SCENE_PATH)
		return
	var previous_card_count := grid.get_child_count()

	GameSession.add_rescue_book_tokens("rabbit", 40)
	GameSession.mark_rescue_book_seen("bear")
	node.call("_refresh_cards")

	var refreshed_card_texts := _collection_card_label_texts_after(grid, previous_card_count)
	var rabbit_text := _first_text_containing(refreshed_card_texts, "토끼")
	if not rabbit_text.contains("Lv.3") or not rabbit_text.contains("토큰 40") or not rabbit_text.contains("NEW"):
		errors.append("%s AnimalCard_rabbit should show Lv.3, token count, and NEW state after token fixture, got: %s." % [COLLECTION_SCENE_PATH, rabbit_text])

	var bear_text := _first_text_containing(refreshed_card_texts, "곰")
	if bear_text.contains("NEW"):
		errors.append("%s AnimalCard_bear should hide NEW after mark_rescue_book_seen, got: %s." % [COLLECTION_SCENE_PATH, bear_text])

	var frog_text := _first_text_containing(refreshed_card_texts, "개구리")
	if not frog_text.contains("Stage 4 해금"):
		errors.append("%s AnimalCard_frog should show locked unlock-stage copy before Stage 4, got: %s." % [COLLECTION_SCENE_PATH, frog_text])


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
	var start_button := _find_button_with_text(panel, "START")
	if start_button == null:
		errors.append("%s Stage Popup should expose a START button." % STAGE_SELECT_SCENE_PATH)

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
		errors.append("%s Stage Popup START bridge should commit selected stage id 1." % STAGE_SELECT_SCENE_PATH)
	if committed_boosters.size() != 1 or not committed_boosters.has("rainbow_paw"):
		errors.append("%s Stage Popup START bridge should commit selected booster rainbow_paw, got %s." % [STAGE_SELECT_SCENE_PATH, str(committed_boosters)])

	node.call("_on_stage_popup_close_pressed")
	await create_timer(0.14).timeout
	if overlay != null and overlay.visible:
		errors.append("%s Stage Popup close should hide StagePopupOverlay after tween." % STAGE_SELECT_SCENE_PATH)
	var panel := node.get("stage_popup_panel") as Control
	if panel != null and panel.scale.distance_to(Vector2.ONE) > 0.01:
		errors.append("%s Stage Popup close should restore panel scale to Vector2.ONE." % STAGE_SELECT_SCENE_PATH)
	GameSession.set_selected_pre_boosters([])


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
