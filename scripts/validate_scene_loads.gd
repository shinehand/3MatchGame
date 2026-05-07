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
		if event_name == "live_event_impression":
			_validate_live_event_impression_payload(params, live_events_by_id, errors)
	for required_event in ["rescue_book_open", "stage_start"]:
		if not seen_names.has(required_event):
			errors.append("runtime analytics should emit %s during scene smoke." % required_event)
	var active_current_live_events := false
	for placement in ["home", "collection", "stage_select"]:
		if not LiveEventService.active_events_for(GameSession.get_highest_unlocked_stage_id(), placement).is_empty():
			active_current_live_events = true
	if active_current_live_events and not seen_names.has("live_event_impression"):
		errors.append("runtime analytics should emit live_event_impression when active live events are visible.")


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
	var intersection := Vector2i(5, 5)
	for cell in [Vector2i(5, 4), intersection, Vector2i(5, 6), Vector2i(3, 5), Vector2i(4, 5)]:
		board_data[cell.x][cell.y] = node.call("_make_piece", "rabbit")
	node.set("board_data", board_data)
	var match_outcome: Dictionary = node.call("_analyze_match_outcome", [intersection])
	var special_spawns: Dictionary = Dictionary(match_outcome.get("special_spawns", {}))
	if String(special_spawns.get(intersection, "")) != "bomb":
		errors.append("%s T/L intersection match should spawn a bomb at the preferred intersection, got %s." % [GAMEPLAY_SCENE_PATH, String(special_spawns.get(intersection, ""))])


func _seed_plain_gameplay_board(node: Node) -> Array:
	var animals := ["rabbit", "bear", "cat", "chick", "frog"]
	var board_data: Array = node.get("board_data")
	for row in range(8):
		for col in range(8):
			board_data[row][col] = node.call("_make_piece", String(animals[(row * 2 + col) % animals.size()]))
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
	var smoke_stages_by_placement := {
		"home": 9,
		"collection": 9,
		"stage_select": 3,
		"result_overlay": 2,
	}
	for placement in smoke_stages_by_placement.keys():
		var smoke_stage := int(smoke_stages_by_placement[placement])
		if LiveEventService.active_events_for(smoke_stage, String(placement)).is_empty():
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
