extends Control

const BOARD_ROWS := 8
const BOARD_COLS := 8
const BLOCK_TILE_SCENE := preload("res://scenes/block_tile.tscn")
const GOAL_CHIP_SCENE := preload("res://scenes/goal_chip.tscn")
const StageCatalog = preload("res://scripts/stage_catalog.gd")
const GameSession = preload("res://scripts/game_session.gd")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const OVERLAY_SUCCESS_TEXTURE = preload("res://assets/generated/redesign/overlay_success_cat_v1_flat.png")
const OVERLAY_FAIL_TEXTURE = preload("res://assets/generated/redesign/overlay_fail_bear_v1_flat.png")
const COMBO_POP_TEXTURE = preload("res://assets/ui/effects/combo_pop.svg")
const COMBO_GREAT_TEXTURE = preload("res://assets/ui/effects/combo_great.svg")
const SOFT_TUTORIAL_STAGE_HINTS := {
	1: "첫 구조 안내",
	3: "4매치 학습",
	7: "5매치 학습",
	11: "점수 목표 도입",
	15: "덤불 압박 도입",
	25: "비대칭 보드 도입",
	45: "게이트 보드 도입",
	65: "전문가 루트 판독",
	85: "최종권 압박",
	95: "피날레 압박",
}
const ANIMAL_IDS := ["rabbit", "bear", "cat", "chick", "frog"]
const ANIMAL_NAMES := {
	"rabbit": "토끼",
	"bear": "곰",
	"cat": "고양이",
	"chick": "병아리",
	"frog": "개구리",
}
const SPECIAL_PRIORITY := {
	"": 0,
	"row": 1,
	"col": 1,
	"bomb": 2,
}

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var layout_root: BoxContainer = $SafeMargin/LayoutRoot
@onready var board_panel: PanelContainer = $SafeMargin/LayoutRoot/BoardPanel
@onready var board_column: VBoxContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn
@onready var board_margin: MarginContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin
@onready var top_bar: HBoxContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/TopBar
@onready var board_frame: PanelContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame
@onready var board_shine: ColorRect = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/BoardShine
@onready var combo_banner: TextureRect = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/ComboBanner
@onready var combo_label: Label = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/ComboBanner/ComboLabel
@onready var board_surface_margin: MarginContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/BoardSurfaceMargin
@onready var board_scroll: ScrollContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/BoardSurfaceMargin/BoardScroll
@onready var board_grid: GridContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/BoardFrame/BoardSurfaceMargin/BoardScroll/BoardGrid
@onready var sidebar_scroll: ScrollContainer = $SafeMargin/LayoutRoot/SidebarScroll
@onready var sidebar: VBoxContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar
@onready var stats_card: PanelContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard
@onready var stats_padding: MarginContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard/StatsPadding
@onready var stats_column: VBoxContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard/StatsPadding/StatsColumn
@onready var tutorial_banner: PanelContainer = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/TutorialBanner
@onready var tutorial_label: Label = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/TutorialBanner/TutorialMargin/TutorialLabel
@onready var pause_button: Button = $SafeMargin/LayoutRoot/BoardPanel/BoardMargin/BoardColumn/TopBar/PauseButton
@onready var stage_value: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard/StatsPadding/StatsColumn/StageValue
@onready var difficulty_value: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard/StatsPadding/StatsColumn/DifficultyValue
@onready var moves_value: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard/StatsPadding/StatsColumn/MovesValue
@onready var score_value: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard/StatsPadding/StatsColumn/ScoreValue
@onready var combo_value: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatsCard/StatsPadding/StatsColumn/ComboValue
@onready var goal_card: PanelContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/GoalCard
@onready var goal_padding: MarginContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/GoalCard/GoalPadding
@onready var goal_column: VBoxContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/GoalCard/GoalPadding/GoalColumn
@onready var goal_header: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/GoalCard/GoalPadding/GoalColumn/GoalHeader
@onready var goal_list: VBoxContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/GoalCard/GoalPadding/GoalColumn/GoalList
@onready var status_card: PanelContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatusCard
@onready var status_label: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/StatusCard/StatusPadding/StatusLabel
@onready var tips_card: PanelContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/TipsCard
@onready var tips_label: Label = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/TipsCard/TipsPadding/TipsLabel
@onready var primary_buttons: BoxContainer = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/PrimaryButtons
@onready var retry_button: Button = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/PrimaryButtons/RetryButton
@onready var next_stage_button: Button = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/PrimaryButtons/NextStageButton
@onready var quit_button: Button = $SafeMargin/LayoutRoot/SidebarScroll/Sidebar/QuitButton
@onready var overlay: ColorRect = $Overlay
@onready var overlay_panel: PanelContainer = $Overlay/OverlayCenter/OverlayPanel
@onready var overlay_ribbon: TextureRect = $Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayRibbon
@onready var overlay_mascot: TextureRect = $Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayMascot
@onready var overlay_title: Label = $Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayTitle
@onready var overlay_body: Label = $Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayBody
@onready var overlay_primary_button: Button = $Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlayPrimaryButton
@onready var overlay_secondary_button: Button = $Overlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/OverlayButtons/OverlaySecondaryButton

var rng := RandomNumberGenerator.new()
var animal_textures: Dictionary = {}
var ui_textures: Dictionary = {}
var board_data: Array = []
var obstacle_data: Array = []
var active_mask: Array = []
var tile_nodes: Array = []
var selected_cell := Vector2i(-1, -1)
var is_busy := false
var current_stage_index := 0
var stage_defs: Array = []
var remaining_moves := 0
var score := 0
var current_combo := 1
var stage_state := "playing"
var collected_counts: Dictionary = {}
var cleared_blockers := 0
var overlay_action := ""
var tutorial_enabled := false
var tutorial_step := -1
var portrait_goal_summary: Label
var _prev_complete_set: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	GameSession.load_state()
	GameSession.apply_feedback_preferences()
	stage_defs = StageCatalog.get_stages()
	resized.connect(_queue_layout_refresh)
	get_window().size_changed.connect(_queue_layout_refresh)
	_load_animal_textures()
	_load_ui_textures()
	_ensure_portrait_goal_summary()
	_build_board_nodes()
	_reset_collected_counts()
	_start_stage(GameSession.get_selected_stage_id() - 1)
	call_deferred("_apply_responsive_layout")


func _build_board_nodes() -> void:
	board_data.clear()
	obstacle_data.clear()
	active_mask.clear()
	tile_nodes.clear()

	for child in board_grid.get_children():
		child.queue_free()

	for row in range(BOARD_ROWS):
		var row_data: Array = []
		var row_obstacles: Array = []
		var row_mask: Array = []
		var row_tiles: Array = []

		for col in range(BOARD_COLS):
			var tile = BLOCK_TILE_SCENE.instantiate()
			tile.set_tile_visual_size(_current_tile_extent())
			tile.set_position_in_grid(row, col)
			tile.tile_pressed.connect(_on_tile_pressed)
			tile.tile_swiped.connect(_on_tile_swiped)
			board_grid.add_child(tile)
			tile.set_match_effect_texture(ui_textures.get("match_burst"))
			row_data.append("")
			row_obstacles.append(0)
			row_mask.append(true)
			row_tiles.append(tile)

		board_data.append(row_data)
		obstacle_data.append(row_obstacles)
		active_mask.append(row_mask)
		tile_nodes.append(row_tiles)

	_update_board_surface_size()


func _update_board_surface_size() -> void:
	var tile_extent := _current_tile_extent()
	for row_tiles in tile_nodes:
		for tile in row_tiles:
			tile.set_tile_visual_size(tile_extent)

	var tile_size := Vector2(tile_extent, tile_extent)
	if not tile_nodes.is_empty() and not tile_nodes[0].is_empty():
		tile_size = tile_nodes[0][0].get_combined_minimum_size()

	var h_separation: int = board_grid.get_theme_constant("h_separation")
	var v_separation: int = board_grid.get_theme_constant("v_separation")
	var board_width: float = float(BOARD_COLS) * tile_size.x + float(max(BOARD_COLS - 1, 0) * h_separation)
	var board_height: float = float(BOARD_ROWS) * tile_size.y + float(max(BOARD_ROWS - 1, 0) * v_separation)
	var portrait: bool = MobileLayout.is_portrait(self)
	var viewport_size: Vector2 = get_viewport_rect().size
	var max_visible_width: float = max(320.0, viewport_size.x - 88.0) if portrait else min(1240.0, max(720.0, viewport_size.x - 480.0))
	var max_visible_height: float = max(520.0, viewport_size.y * 0.76) if portrait else min(980.0, max(520.0, viewport_size.y - 200.0))

	board_grid.custom_minimum_size = Vector2(board_width, board_height)
	board_scroll.custom_minimum_size = Vector2(min(board_width, max_visible_width), min(board_height, max_visible_height))
	board_scroll.size_flags_vertical = 0 if portrait else Control.SIZE_EXPAND_FILL


func _current_tile_extent() -> float:
	var portrait: bool = MobileLayout.is_portrait(self)
	if not portrait:
		return 116.0

	var viewport_width: float = get_viewport_rect().size.x
	var h_separation: int = board_grid.get_theme_constant("h_separation")
	var horizontal_padding: float = 88.0
	var usable_width: float = max(720.0, viewport_width - horizontal_padding)
	var tile_extent: float = floor((usable_width - float(max(BOARD_COLS - 1, 0) * h_separation)) / float(BOARD_COLS))
	return clamp(tile_extent, 94.0, 112.0)


func _start_stage(stage_index: int) -> void:
	current_stage_index = clamp(stage_index, 0, stage_defs.size() - 1)
	GameSession.set_selected_stage_id(_current_stage_id())
	remaining_moves = int(_current_stage()["moves"])
	score = 0
	current_combo = 1
	stage_state = "playing"
	cleared_blockers = 0
	_clear_selection()
	_reset_collected_counts()
	_setup_board_mask()
	_setup_stage_blockers()
	_setup_tutorial()
	_generate_fresh_board()
	_update_stage_background()
	_rebuild_goal_chips()
	_update_hud()
	_update_tips()
	_set_status("%s 시작. 목표를 달성하기 전까지 유효 스왑만 이동 수를 소모합니다." % _current_stage()["name"])
	_show_overlay(
		"%s  %s" % [_current_stage()["name"], _current_stage()["difficulty"]],
		_build_stage_overlay_text(),
		"start_stage",
		"시작",
		"",
		false
	)
	Feedback.play_ui_tap()
	_apply_responsive_layout()


func _generate_fresh_board() -> void:
	while true:
		for row in range(BOARD_ROWS):
			for col in range(BOARD_COLS):
				if not _is_cell_active_xy(row, col):
					board_data[row][col] = ""
					continue
				board_data[row][col] = _pick_kind_without_match(row, col)

		if _board_has_valid_moves():
			break

	_refresh_all_tiles()


func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	var portrait := MobileLayout.is_portrait(self)
	MobileLayout.apply_safe_area(safe_margin, self, 14 if portrait else 12)
	var viewport_size := get_viewport_rect().size

	layout_root.vertical = portrait
	layout_root.add_theme_constant_override("separation", 0 if portrait else 28)
	primary_buttons.vertical = false
	primary_buttons.alignment = BoxContainer.ALIGNMENT_CENTER

	if portrait:
		if sidebar_scroll.get_parent() != board_column:
			var old_parent := sidebar_scroll.get_parent()
			if old_parent:
				old_parent.remove_child(sidebar_scroll)
			board_column.add_child(sidebar_scroll)
		board_column.move_child(sidebar_scroll, 2)
	else:
		if sidebar_scroll.get_parent() != layout_root:
			var old_parent := sidebar_scroll.get_parent()
			if old_parent:
				old_parent.remove_child(sidebar_scroll)
			layout_root.add_child(sidebar_scroll)
		layout_root.move_child(board_panel, 0)
		layout_root.move_child(sidebar_scroll, 1)

	board_panel.custom_minimum_size = Vector2(0, 0) if portrait else Vector2(1000, 0)
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_vertical = 0 if portrait else Control.SIZE_EXPAND_FILL
	board_frame.size_flags_vertical = 0 if portrait else Control.SIZE_EXPAND_FILL
	board_margin.add_theme_constant_override("margin_left", 14 if portrait else 24)
	board_margin.add_theme_constant_override("margin_top", 14 if portrait else 24)
	board_margin.add_theme_constant_override("margin_right", 14 if portrait else 24)
	board_margin.add_theme_constant_override("margin_bottom", 14 if portrait else 24)
	board_column.add_theme_constant_override("separation", 10 if portrait else 18)
	board_surface_margin.add_theme_constant_override("margin_left", 10 if portrait else 18)
	board_surface_margin.add_theme_constant_override("margin_top", 10 if portrait else 20)
	board_surface_margin.add_theme_constant_override("margin_right", 10 if portrait else 18)
	board_surface_margin.add_theme_constant_override("margin_bottom", 10 if portrait else 18)
	board_shine.visible = not portrait

	var portrait_hud_height := clampf(viewport_size.y * 0.18, 170.0, 250.0)
	sidebar_scroll.custom_minimum_size = Vector2(0, portrait_hud_height) if portrait else Vector2(352, 0)
	sidebar_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar_scroll.size_flags_vertical = Control.SIZE_FILL if portrait else Control.SIZE_EXPAND_FILL
	sidebar.custom_minimum_size = Vector2(0, 0) if portrait else Vector2(352, 0)
	sidebar.add_theme_constant_override("separation", 12 if portrait else 16)
	sidebar_scroll.scroll_horizontal = 0
	sidebar_scroll.scroll_vertical = 0
	stats_padding.add_theme_constant_override("margin_left", 14 if portrait else 18)
	stats_padding.add_theme_constant_override("margin_top", 12 if portrait else 18)
	stats_padding.add_theme_constant_override("margin_right", 14 if portrait else 18)
	stats_padding.add_theme_constant_override("margin_bottom", 12 if portrait else 18)
	stats_column.add_theme_constant_override("separation", 4 if portrait else 8)
	goal_padding.add_theme_constant_override("margin_left", 14 if portrait else 18)
	goal_padding.add_theme_constant_override("margin_top", 12 if portrait else 18)
	goal_padding.add_theme_constant_override("margin_right", 14 if portrait else 18)
	goal_padding.add_theme_constant_override("margin_bottom", 12 if portrait else 18)
	goal_column.add_theme_constant_override("separation", 6 if portrait else 10)
	goal_list.add_theme_constant_override("separation", 4 if portrait else 8)
	portrait_goal_summary.add_theme_font_size_override("font_size", 17 if portrait else 18)
	portrait_goal_summary.add_theme_constant_override("line_spacing", 4 if portrait else 2)

	top_bar.visible = not portrait
	pause_button.visible = not portrait
	pause_button.custom_minimum_size = Vector2(156, 72) if portrait else Vector2(176, 76)
	quit_button.custom_minimum_size = Vector2(110, 74) if portrait else Vector2(0, 82)
	retry_button.custom_minimum_size = Vector2(110, 74) if portrait else Vector2(0, 86)
	next_stage_button.custom_minimum_size = Vector2(110, 74) if portrait else Vector2(0, 86)
	quit_button.add_theme_font_size_override("font_size", 30 if portrait else 26)
	retry_button.add_theme_font_size_override("font_size", 30 if portrait else 26)
	next_stage_button.add_theme_font_size_override("font_size", 30 if portrait else 26)
	overlay_panel.custom_minimum_size = Vector2(560, 0) if portrait else Vector2(520, 0)
	overlay_mascot.custom_minimum_size = Vector2(156, 156) if portrait else Vector2(132, 132)
	overlay_ribbon.custom_minimum_size = Vector2(184, 66) if portrait else Vector2(176, 60)
	overlay_title.add_theme_font_size_override("font_size", 34 if portrait else 40)
	overlay_body.add_theme_font_size_override("font_size", 20 if portrait else 24)
	overlay_body.add_theme_constant_override("line_spacing", 8 if portrait else 10)
	status_card.visible = not portrait
	tips_card.visible = false
	combo_value.visible = not portrait
	difficulty_value.visible = not portrait
	score_value.visible = false
	moves_value.visible = not portrait
	goal_card.visible = true
	goal_header.visible = not portrait
	goal_list.visible = not portrait
	if portrait_goal_summary:
		portrait_goal_summary.visible = portrait
	stage_value.add_theme_font_size_override("font_size", 20 if portrait else 24)
	score_value.add_theme_font_size_override("font_size", 18 if portrait else 22)
	goal_card.custom_minimum_size = Vector2(0, 92) if portrait else Vector2.ZERO
	_configure_action_buttons(portrait)

	_update_board_surface_size()


func _configure_action_buttons(portrait: bool) -> void:
	if portrait:
		if quit_button.get_parent() != primary_buttons:
			var current_parent := quit_button.get_parent()
			if current_parent:
				current_parent.remove_child(quit_button)
			primary_buttons.add_child(quit_button)
		primary_buttons.move_child(quit_button, 0)
		primary_buttons.move_child(retry_button, 1)
		primary_buttons.move_child(next_stage_button, 2)
		primary_buttons.add_theme_constant_override("separation", 12)
		quit_button.size_flags_horizontal = 0
		retry_button.size_flags_horizontal = 0
		next_stage_button.size_flags_horizontal = 0

		quit_button.text = "⌂"
		retry_button.text = "↺"
		if stage_state == "playing":
			next_stage_button.text = "⏸"
			next_stage_button.disabled = false
		else:
			next_stage_button.text = "▶"
	else:
		if quit_button.get_parent() != sidebar:
			var current_parent := quit_button.get_parent()
			if current_parent:
				current_parent.remove_child(quit_button)
			sidebar.add_child(quit_button)
			sidebar.move_child(quit_button, sidebar.get_child_count() - 1)
		primary_buttons.add_theme_constant_override("separation", 10)
		quit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		next_stage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		quit_button.text = "홈으로"
		retry_button.text = "재시작"
		next_stage_button.text = "다음 스테이지"


func _pick_kind_without_match(row: int, col: int) -> String:
	while true:
		var animal_id: String = _pick_stage_animal()
		var creates_horizontal := col >= 2 and _piece_animal(board_data[row][col - 1]) == animal_id and _piece_animal(board_data[row][col - 2]) == animal_id
		var creates_vertical := row >= 2 and _piece_animal(board_data[row - 1][col]) == animal_id and _piece_animal(board_data[row - 2][col]) == animal_id
		if creates_horizontal or creates_vertical:
			continue
		return _make_piece(animal_id)
	return _make_piece(ANIMAL_IDS[0])


func _refresh_all_tiles() -> void:
	for row in range(BOARD_ROWS):
		for col in range(BOARD_COLS):
			_refresh_tile(row, col)


func _refresh_tile(row: int, col: int) -> void:
	if not _is_cell_active_xy(row, col):
		tile_nodes[row][col].set_inactive(true)
		return

	var piece_data: String = String(board_data[row][col])
	var animal_id: String = _piece_animal(piece_data)
	if animal_id.is_empty():
		tile_nodes[row][col].set_inactive(false)
		tile_nodes[row][col].set_tile(null, "", "")
		tile_nodes[row][col].set_obstacle(ui_textures.get("bush"), int(obstacle_data[row][col]))
		return
	tile_nodes[row][col].set_inactive(false)
	tile_nodes[row][col].set_tile(animal_textures[animal_id], animal_id, _piece_special(piece_data))
	tile_nodes[row][col].set_obstacle(ui_textures.get("bush"), int(obstacle_data[row][col]))


func _on_tile_pressed(row: int, col: int) -> void:
	if is_busy or overlay.visible:
		return
	if stage_state != "playing":
		if stage_state == "cleared":
			_set_status("스테이지를 클리어했습니다. 다음 스테이지 또는 재시작을 선택하세요.")
		else:
			_set_status("이동 수가 모두 소진됐습니다. 재시작으로 다시 도전하세요.")
		return
	if not _is_cell_active_xy(row, col):
		return

	var cell := Vector2i(row, col)
	if selected_cell.x == -1:
		_maybe_advance_tutorial(2)
		_select_cell(cell)
		return
	if selected_cell == cell:
		_clear_selection()
		_set_status("선택을 해제했습니다.")
		return
	if not _is_adjacent(selected_cell, cell):
		_maybe_advance_tutorial(2)
		_select_cell(cell)
		return

	_resolve_swap(selected_cell, cell)


func _on_tile_swiped(row: int, col: int, direction: Vector2i) -> void:
	if is_busy or overlay.visible or stage_state != "playing":
		tile_nodes[row][col].snap_back_drag_preview()
		return
	if not _is_cell_active_xy(row, col):
		tile_nodes[row][col].snap_back_drag_preview()
		return
	_maybe_advance_tutorial(2)

	var from_cell := Vector2i(row, col)
	var to_cell := from_cell + direction
	if to_cell.x < 0 or to_cell.x >= BOARD_ROWS or to_cell.y < 0 or to_cell.y >= BOARD_COLS:
		tile_nodes[row][col].snap_back_drag_preview()
		return
	if not _is_cell_active(to_cell):
		tile_nodes[row][col].snap_back_drag_preview()
		return

	_resolve_swap(from_cell, to_cell)


func _select_cell(cell: Vector2i) -> void:
	_clear_selection()
	selected_cell = cell
	tile_nodes[cell.x][cell.y].set_selected(true)
	var animal_id: String = _piece_animal(board_data[cell.x][cell.y])
	if animal_id.is_empty():
		return
	_set_status("%s 블록을 선택했습니다." % ANIMAL_NAMES[animal_id])


func _clear_selection() -> void:
	if selected_cell.x != -1:
		tile_nodes[selected_cell.x][selected_cell.y].set_selected(false)
	selected_cell = Vector2i(-1, -1)


func _resolve_swap(from_cell: Vector2i, to_cell: Vector2i) -> void:
	is_busy = true
	_clear_selection()
	var travel_offset: Vector2 = tile_nodes[to_cell.x][to_cell.y].position - tile_nodes[from_cell.x][from_cell.y].position

	tile_nodes[from_cell.x][from_cell.y].play_drag_commit_feedback(travel_offset)
	tile_nodes[to_cell.x][to_cell.y].play_drag_commit_feedback(-travel_offset)
	await get_tree().create_timer(0.08).timeout

	_swap_cells(from_cell, to_cell)
	_refresh_tile(from_cell.x, from_cell.y)
	_refresh_tile(to_cell.x, to_cell.y)
	tile_nodes[from_cell.x][from_cell.y].finalize_swap_feedback()
	tile_nodes[to_cell.x][to_cell.y].finalize_swap_feedback()

	if _find_matches().is_empty():
		await get_tree().create_timer(0.1).timeout
		_swap_cells(from_cell, to_cell)
		_refresh_tile(from_cell.x, from_cell.y)
		_refresh_tile(to_cell.x, to_cell.y)
		tile_nodes[from_cell.x][from_cell.y].play_invalid_feedback()
		tile_nodes[to_cell.x][to_cell.y].play_invalid_feedback()
		Feedback.play_swap_invalid()
		_set_status("매치가 없어 원래 위치로 되돌렸습니다.")
		is_busy = false
		return

	Feedback.play_swap_valid()
	remaining_moves -= 1
	_update_hud()
	await _resolve_matches([from_cell, to_cell])
	_maybe_advance_tutorial(3)
	_check_stage_state()
	is_busy = false


func _resolve_matches(preferred_cells: Array) -> void:
	var combo := 1
	var next_preferred: Array = preferred_cells.duplicate()

	while true:
		var outcome: Dictionary = _analyze_match_outcome(next_preferred)
		var base_cells: Array = outcome["base_cells"]
		if base_cells.is_empty():
			break

		var special_spawns: Dictionary = outcome["special_spawns"]
		var clear_cells: Array = _expand_special_clears(base_cells, special_spawns)
		var cleared_obstacle_cells: Array = _damage_obstacles(clear_cells)
		var removed_cells: Array = []
		for cell in clear_cells:
			if not special_spawns.has(cell):
				removed_cells.append(cell)

		current_combo = combo
		_apply_match_rewards(removed_cells, combo)
		score += cleared_obstacle_cells.size() * 150 * combo
		Feedback.play_match(combo, special_spawns.size(), cleared_obstacle_cells.size())
		_update_hud()
		_set_status(_build_resolution_status(combo, removed_cells.size(), special_spawns, cleared_obstacle_cells.size()))
		_show_combo_banner(combo)

		for cell in clear_cells:
			tile_nodes[cell.x][cell.y].set_selected(true)
			tile_nodes[cell.x][cell.y].play_match_effect()

		await get_tree().create_timer(0.22).timeout

		for cell in clear_cells:
			tile_nodes[cell.x][cell.y].set_selected(false)
			if special_spawns.has(cell):
				var animal_id: String = _piece_animal(board_data[cell.x][cell.y])
				board_data[cell.x][cell.y] = _make_piece(animal_id, String(special_spawns[cell]))
				_refresh_tile(cell.x, cell.y)
				tile_nodes[cell.x][cell.y].play_special_ready_effect()
			else:
				board_data[cell.x][cell.y] = ""
				_refresh_tile(cell.x, cell.y)

		await get_tree().create_timer(0.08).timeout

		var fall_events: Array = _collapse_and_refill_board()
		_refresh_tiles_from_events(fall_events)
		_play_fall_events(fall_events)
		await get_tree().create_timer(0.24).timeout

		if not _board_has_valid_moves():
			_generate_fresh_board()
			_set_status("가능한 매치가 없어 보드를 자동 셔플했습니다.")
			await get_tree().create_timer(0.18).timeout

		next_preferred.clear()
		combo += 1

	current_combo = 1
	_update_hud()
	_set_status("연쇄 처리와 리필이 끝났습니다. 다음 스왑을 진행할 수 있습니다.")


func _collapse_and_refill_board() -> Array:
	var fall_events: Array = []

	for col in range(BOARD_COLS):
		var active_rows: Array = []
		for row in range(BOARD_ROWS - 1, -1, -1):
			if _is_cell_active_xy(row, col):
				active_rows.append(row)
			else:
				board_data[row][col] = ""

		var falling_pieces: Array = []
		for row in active_rows:
			var piece_data: String = String(board_data[row][col])
			if piece_data.is_empty():
				continue
			falling_pieces.append({
				"piece": piece_data,
				"from_row": row,
			})

		for row in active_rows:
			board_data[row][col] = ""

		for index in range(falling_pieces.size()):
			var dest_row: int = int(active_rows[index])
			var piece_entry: Dictionary = falling_pieces[index]
			var from_row: int = int(piece_entry["from_row"])
			board_data[dest_row][col] = String(piece_entry["piece"])
			if dest_row != from_row:
				fall_events.append({
					"from_row": from_row,
					"row": dest_row,
					"col": col,
					"distance": abs(dest_row - from_row),
				})

		for index in range(falling_pieces.size(), active_rows.size()):
			var spawn_row: int = int(active_rows[index])
			board_data[spawn_row][col] = _make_piece(_pick_stage_animal())
			fall_events.append({
				"row": spawn_row,
				"col": col,
				"distance": index + 2,
			})

	return fall_events


func _play_fall_events(fall_events: Array) -> void:
	for event in fall_events:
		var row: int = int(event["row"])
		var col: int = int(event["col"])
		var distance: int = int(event["distance"])
		tile_nodes[row][col].play_drop_in(distance)


func _refresh_tiles_from_events(fall_events: Array) -> void:
	var refreshed := {}
	for event in fall_events:
		var row: int = int(event["row"])
		var col: int = int(event["col"])
		var key := Vector2i(row, col)
		if refreshed.has(key):
			pass
		else:
			refreshed[key] = true
			_refresh_tile(row, col)

		if event.has("from_row"):
			var from_row: int = int(event["from_row"])
			var from_key := Vector2i(from_row, col)
			if refreshed.has(from_key):
				continue
			refreshed[from_key] = true
			_refresh_tile(from_row, col)


func _apply_match_rewards(matches: Array, combo: int) -> void:
	score += matches.size() * 100 * combo

	for cell in matches:
		var animal_id: String = _piece_animal(board_data[cell.x][cell.y])
		if collected_counts.has(animal_id):
			collected_counts[animal_id] = int(collected_counts[animal_id]) + 1


func _find_matches() -> Array:
	var result: Array = []
	var found := {}
	for run in _find_match_runs():
		for cell in run["cells"]:
			found[cell] = true
	for cell in found.keys():
		result.append(cell)
	return result


func _find_match_runs() -> Array:
	var runs: Array = []

	for row in range(BOARD_ROWS):
		var run_start := 0
		var current_id: String = _piece_animal(board_data[row][0])
		for col in range(1, BOARD_COLS + 1):
			var next_id: String = "" if col == BOARD_COLS else _piece_animal(board_data[row][col])
			if next_id != current_id:
				if not current_id.is_empty() and col - run_start >= 3:
					var run_cells: Array = []
					for match_col in range(run_start, col):
						run_cells.append(Vector2i(row, match_col))
					runs.append({"cells": run_cells, "orientation": "row"})
				run_start = col
				current_id = next_id

	for col in range(BOARD_COLS):
		var run_start := 0
		var current_id: String = _piece_animal(board_data[0][col])
		for row in range(1, BOARD_ROWS + 1):
			var next_id: String = "" if row == BOARD_ROWS else _piece_animal(board_data[row][col])
			if next_id != current_id:
				if not current_id.is_empty() and row - run_start >= 3:
					var run_cells: Array = []
					for match_row in range(run_start, row):
						run_cells.append(Vector2i(match_row, col))
					runs.append({"cells": run_cells, "orientation": "col"})
				run_start = row
				current_id = next_id

	return runs


func _analyze_match_outcome(preferred_cells: Array) -> Dictionary:
	var base_found := {}
	var special_spawns := {}

	for run in _find_match_runs():
		var cells: Array = run["cells"]
		var orientation: String = String(run["orientation"])
		for cell in cells:
			base_found[cell] = true

		var special_type: String = _special_from_run(cells.size(), orientation)
		if special_type.is_empty():
			continue

		var spawn_cell: Vector2i = _pick_special_spawn_cell(cells, preferred_cells)
		var current_special: String = String(special_spawns.get(spawn_cell, ""))
		if int(SPECIAL_PRIORITY.get(special_type, 0)) > int(SPECIAL_PRIORITY.get(current_special, 0)):
			special_spawns[spawn_cell] = special_type

	var base_cells: Array = []
	for cell in base_found.keys():
		base_cells.append(cell)

	return {
		"base_cells": base_cells,
		"special_spawns": special_spawns,
	}


func _expand_special_clears(base_cells: Array, special_spawns: Dictionary) -> Array:
	var clear_set := {}
	var queue: Array = base_cells.duplicate()
	var processed := {}

	for cell in base_cells:
		clear_set[cell] = true

	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if processed.has(cell):
			continue
		processed[cell] = true

		if special_spawns.has(cell):
			continue

		var special_type: String = _piece_special(board_data[cell.x][cell.y])
		if special_type.is_empty():
			continue

		for extra_cell in _special_clear_cells(cell, special_type):
			if not clear_set.has(extra_cell):
				clear_set[extra_cell] = true
				queue.append(extra_cell)

	return clear_set.keys()


func _damage_obstacles(clear_cells: Array) -> Array:
	var affected := {}
	var cleared_cells: Array = []

	for cell in clear_cells:
		affected[cell] = true
		for neighbor in _adjacent_cells(cell):
			affected[neighbor] = true

	for cell in affected.keys():
		if not _is_cell_active(cell):
			continue
		if int(obstacle_data[cell.x][cell.y]) <= 0:
			continue
		obstacle_data[cell.x][cell.y] = 0
		cleared_cells.append(cell)
		cleared_blockers += 1
		_refresh_tile(cell.x, cell.y)

	return cleared_cells


func _special_clear_cells(cell: Vector2i, special_type: String) -> Array:
	var cells: Array = []

	match special_type:
		"row":
			for col in range(BOARD_COLS):
				var next_cell := Vector2i(cell.x, col)
				if _is_cell_active(next_cell):
					cells.append(next_cell)
		"col":
			for row in range(BOARD_ROWS):
				var next_cell := Vector2i(row, cell.y)
				if _is_cell_active(next_cell):
					cells.append(next_cell)
		"bomb":
			for row in range(max(cell.x - 1, 0), min(cell.x + 2, BOARD_ROWS)):
				for col in range(max(cell.y - 1, 0), min(cell.y + 2, BOARD_COLS)):
					var next_cell := Vector2i(row, col)
					if _is_cell_active(next_cell):
						cells.append(next_cell)

	return cells


func _special_from_run(run_length: int, orientation: String) -> String:
	if run_length >= 5:
		return "bomb"
	if run_length == 4:
		return orientation
	return ""


func _pick_special_spawn_cell(cells: Array, preferred_cells: Array) -> Vector2i:
	for preferred in preferred_cells:
		if cells.has(preferred):
			return preferred
	return cells[int(cells.size() / 2)]


func _build_resolution_status(combo: int, cleared_count: int, special_spawns: Dictionary, cleared_obstacles: int) -> String:
	var obstacle_text := ""
	if cleared_obstacles > 0:
		obstacle_text = ", 덤불 %d개 제거" % cleared_obstacles

	if special_spawns.is_empty():
		return "%d 콤보, %d개 블록 매치%s. 제거 후 낙하와 리필을 진행합니다." % [combo, cleared_count, obstacle_text]

	var labels: Array = []
	for special_type in special_spawns.values():
		labels.append(_special_label(String(special_type)))
	return "%d 콤보, %d개 제거%s, 특수 블록 생성: %s" % [combo, cleared_count, obstacle_text, ", ".join(labels)]


func _special_label(special_type: String) -> String:
	match special_type:
		"row":
			return "가로 줄"
		"col":
			return "세로 줄"
		"bomb":
			return "폭발"
	return "일반"


func _swap_cells(a: Vector2i, b: Vector2i) -> void:
	var temp: String = String(board_data[a.x][a.y])
	board_data[a.x][a.y] = board_data[b.x][b.y]
	board_data[b.x][b.y] = temp


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1


func _set_status(message: String) -> void:
	status_label.text = message


func _on_retry_button_pressed() -> void:
	if is_busy:
		return
	Feedback.play_ui_tap()
	_start_stage(current_stage_index)


func _on_next_stage_button_pressed() -> void:
	if is_busy:
		return
	if MobileLayout.is_portrait(self) and stage_state == "playing":
		_on_pause_button_pressed()
		return
	Feedback.play_ui_tap()
	if stage_state != "cleared":
		_set_status("먼저 현재 스테이지 목표를 달성해야 합니다.")
		return
	if current_stage_index >= stage_defs.size() - 1:
		_set_status("마지막 스테이지까지 클리어했습니다. 재시작으로 다시 플레이할 수 있습니다.")
		return
	GameSession.set_selected_stage_id(_current_stage_id() + 1)
	_start_stage(current_stage_index + 1)


func _on_pause_button_pressed() -> void:
	if is_busy:
		return
	Feedback.play_ui_tap()
	_show_overlay(
		"일시정지",
		"%s\n\n현재 목표\n%s" % [_current_stage()["name"], _build_goal_text()],
		"resume_stage",
		"계속",
		"홈으로",
		true
	)


func _on_quit_button_pressed() -> void:
	Feedback.play_ui_tap()
	GameSession.save_state()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _check_stage_state() -> void:
	if _is_stage_complete():
		stage_state = "cleared"
		Feedback.play_stage_clear()
		var star_count := _stage_star_rating()
		var prev_best := GameSession.get_best_stars(_current_stage_id())
		GameSession.record_stage_result(_current_stage_id(), score, star_count)
		var unlock_text := _build_unlock_text(star_count, prev_best)
		if current_stage_index == stage_defs.size() - 1:
			_set_status("최종 스테이지 클리어. 홈으로 돌아가거나 다시 플레이할 수 있습니다.")
			_show_overlay("모든 스테이지 구조 완료", _build_clear_overlay_body(star_count, unlock_text, true), "all_clear", "홈으로", "다시 플레이", true)
		else:
			_set_status("%s 클리어. 홈으로 돌아가거나 다음 스테이지로 이어서 진행할 수 있습니다." % _current_stage()["name"])
			_show_overlay("%s 구조 완료" % _current_stage()["name"], _build_clear_overlay_body(star_count, unlock_text, false), "clear_stage", "다음 스테이지", "홈으로", true)
	elif remaining_moves <= 0:
		stage_state = "failed"
		Feedback.play_stage_fail()
		_set_status("이동 수를 모두 사용했습니다. 재시작으로 다시 도전하세요.")
		_show_overlay("%s 재도전 필요" % _current_stage()["name"], _build_failure_overlay_body(), "restart_stage", "재도전", "홈으로", true)
	_update_hud()


func _is_stage_complete() -> bool:
	var targets: Dictionary = _stage_collect_targets()
	for animal_id in targets.keys():
		if int(collected_counts.get(animal_id, 0)) < int(targets[animal_id]):
			return false

	var target_score: int = _target_score()
	if target_score > 0 and score < target_score:
		return false
	var target_blockers: int = _target_blockers()
	if target_blockers > 0 and cleared_blockers < target_blockers:
		return false

	return true


func _update_hud() -> void:
	var portrait := MobileLayout.is_portrait(self)
	var moves_color := _moves_warning_color()
	if portrait:
		stage_value.text = "%s · 이동 %d · 점수 %d" % [_current_stage()["name"], remaining_moves, score]
		stage_value.add_theme_color_override("font_color", moves_color)
		score_value.text = "점수 %d" % score
	else:
		stage_value.text = "%s  (%d / %d)" % [_current_stage()["name"], current_stage_index + 1, stage_defs.size()]
		difficulty_value.text = "난이도 %s" % _current_stage()["difficulty"]
		moves_value.text = "남은 이동 %d" % remaining_moves
		moves_value.add_theme_color_override("font_color", moves_color)
		score_value.text = "점수 %d" % score
	combo_value.text = "현재 콤보 x%d" % current_combo
	_refresh_goal_chips()
	if MobileLayout.is_portrait(self) and stage_state == "playing":
		next_stage_button.disabled = false
	else:
		next_stage_button.disabled = stage_state != "cleared" or current_stage_index >= stage_defs.size() - 1
	_configure_action_buttons(MobileLayout.is_portrait(self))
	_refresh_portrait_goal_summary()


func _moves_warning_color() -> Color:
	if remaining_moves <= 3:
		return Color(0.75, 0.19, 0.19, 1)
	if remaining_moves <= 5:
		return Color(0.88, 0.50, 0.13, 1)
	return Color(0.32, 0.24, 0.19, 1)


func _notify_goal_complete_if_new(key: String, is_complete: bool) -> void:
	if is_complete and not _prev_complete_set.get(key, false):
		Feedback.play_goal_complete()
	_prev_complete_set[key] = is_complete


func _refresh_goal_chips() -> void:
	var chip_index := 0
	var collect_targets: Dictionary = _stage_collect_targets()

	for animal_id in collect_targets.keys():
		var chip = goal_list.get_child(chip_index)
		chip.visible = true
		chip.set_collect_goal(
			animal_textures[String(animal_id)],
			"%s 수집" % ANIMAL_NAMES[String(animal_id)],
			int(collected_counts.get(animal_id, 0)),
			int(collect_targets[animal_id])
		)
		_notify_goal_complete_if_new(
			"collect_%s" % animal_id,
			int(collected_counts.get(animal_id, 0)) >= int(collect_targets[animal_id])
		)
		chip_index += 1

	var target_score: int = _target_score()
	if target_score > 0:
		var score_chip = goal_list.get_child(chip_index)
		score_chip.visible = true
		score_chip.set_score_goal("점수 달성", score, target_score)
		_notify_goal_complete_if_new("score", score >= target_score)
		chip_index += 1

	var target_blockers: int = _target_blockers()
	if target_blockers > 0:
		var blocker_chip = goal_list.get_child(chip_index)
		blocker_chip.visible = true
		blocker_chip.set_icon_goal(ui_textures.get("bush"), "덤불 제거", cleared_blockers, target_blockers)
		_notify_goal_complete_if_new("blockers", cleared_blockers >= target_blockers)
		chip_index += 1

	for index in range(chip_index, goal_list.get_child_count()):
		goal_list.get_child(index).visible = false


func _rebuild_goal_chips() -> void:
	for child in goal_list.get_children():
		child.queue_free()

	var collect_targets: Dictionary = _stage_collect_targets()
	for _animal_id in collect_targets.keys():
		var chip = GOAL_CHIP_SCENE.instantiate()
		goal_list.add_child(chip)

	if _target_score() > 0:
		var score_chip = GOAL_CHIP_SCENE.instantiate()
		goal_list.add_child(score_chip)

	if _target_blockers() > 0:
		var blocker_chip = GOAL_CHIP_SCENE.instantiate()
		goal_list.add_child(blocker_chip)

	_refresh_goal_chips()


func _pick_stage_animal() -> String:
	var pool: Array = _current_stage()["animal_pool"]
	var weights: Dictionary = _current_stage()["spawn_weights"]
	var total_weight := 0
	for animal_id in pool:
		total_weight += int(weights.get(animal_id, 1))

	var roll := rng.randi_range(1, max(total_weight, 1))
	var cumulative := 0
	for animal_id in pool:
		cumulative += int(weights.get(animal_id, 1))
		if roll <= cumulative:
			return String(animal_id)

	return String(pool[0])


func _current_stage() -> Dictionary:
	return stage_defs[current_stage_index]


func _current_stage_id() -> int:
	return int(_current_stage().get("id", current_stage_index + 1))


func _stage_collect_targets() -> Dictionary:
	return _current_stage()["target_collect"]


func _target_score() -> int:
	return int(_current_stage()["target_score"])


func _target_blockers() -> int:
	return int(_current_stage().get("target_blockers", 0))


func _build_goal_text() -> String:
	var lines := ["목표"]
	lines.append_array(_build_goal_progress_lines())
	return "\n".join(lines)


func _build_goal_progress_lines() -> Array[String]:
	var lines: Array[String] = []
	var targets: Dictionary = _stage_collect_targets()
	for animal_id in targets.keys():
		lines.append("%s %d / %d" % [
			ANIMAL_NAMES[String(animal_id)],
			int(collected_counts.get(animal_id, 0)),
			int(targets[animal_id]),
		])

	var target_score: int = _target_score()
	if target_score > 0:
		lines.append("점수 %d / %d" % [score, target_score])
	var target_blockers: int = _target_blockers()
	if target_blockers > 0:
		lines.append("덤불 %d / %d" % [cleared_blockers, target_blockers])

	return lines


func _build_goal_result_summary() -> String:
	return " · ".join(_build_goal_progress_lines())


func _build_goal_remaining_summary() -> String:
	var parts: Array[String] = []
	var targets: Dictionary = _stage_collect_targets()

	for animal_id in targets.keys():
		var remaining_count: int = int(targets[animal_id]) - int(collected_counts.get(animal_id, 0))
		if remaining_count > 0:
			parts.append("%s %d개" % [ANIMAL_NAMES[String(animal_id)], remaining_count])

	var score_remaining: int = _target_score() - score
	if score_remaining > 0:
		parts.append("점수 %d점" % score_remaining)

	var blocker_remaining: int = _target_blockers() - cleared_blockers
	if blocker_remaining > 0:
		parts.append("덤불 %d개" % blocker_remaining)

	if parts.is_empty():
		return "마지막 판정 확인 중"
	return " · ".join(parts)


func _build_portrait_goal_summary() -> String:
	var progress_parts: Array[String] = []
	var targets: Dictionary = _stage_collect_targets()

	for animal_id in targets.keys():
		var current_count := int(collected_counts.get(animal_id, 0))
		var target_count := int(targets[animal_id])
		var marker := "✓" if current_count >= target_count else "•"
		progress_parts.append("%s %s %d/%d" % [marker, ANIMAL_NAMES[String(animal_id)], current_count, target_count])

	var target_score: int = _target_score()
	if target_score > 0:
		var score_marker := "✓" if score >= target_score else "•"
		progress_parts.append("%s 점수 %d/%d" % [score_marker, score, target_score])
	var target_blockers: int = _target_blockers()
	if target_blockers > 0:
		var blocker_marker := "✓" if cleared_blockers >= target_blockers else "•"
		progress_parts.append("%s 덤불 %d/%d" % [blocker_marker, cleared_blockers, target_blockers])

	var remaining_text := _build_goal_remaining_summary()
	if remaining_text == "마지막 판정 확인 중":
		remaining_text = "모든 목표 완료"
	return "목표  %s\n남은 것  %s" % [" · ".join(progress_parts), remaining_text]


func _build_stage_overlay_text() -> String:
	var lines: Array[String] = []
	if tutorial_enabled:
		lines.append("[%s]" % _soft_tutorial_label())
		lines.append(_tutorial_message())
		lines.append("")
	lines.append("목표  %s" % _build_goal_result_summary())
	lines.append("이동  %d회" % remaining_moves)
	return "\n".join(lines)


func _ensure_portrait_goal_summary() -> void:
	if portrait_goal_summary != null:
		if portrait_goal_summary.get_parent() != goal_column:
			var parent := portrait_goal_summary.get_parent()
			if parent:
				parent.remove_child(portrait_goal_summary)
			goal_column.add_child(portrait_goal_summary)
			goal_column.move_child(portrait_goal_summary, 0)
		return

	portrait_goal_summary = Label.new()
	portrait_goal_summary.name = "PortraitGoalSummary"
	portrait_goal_summary.visible = false
	portrait_goal_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	portrait_goal_summary.add_theme_color_override("font_color", Color(0.321569, 0.239216, 0.188235, 1))
	portrait_goal_summary.add_theme_font_size_override("font_size", 18)
	goal_column.add_child(portrait_goal_summary)
	goal_column.move_child(portrait_goal_summary, 0)


func _refresh_portrait_goal_summary() -> void:
	if portrait_goal_summary == null:
		return
	portrait_goal_summary.text = _build_portrait_goal_summary()


func _reset_collected_counts() -> void:
	collected_counts.clear()
	for animal_id in ANIMAL_IDS:
		collected_counts[animal_id] = 0
	_prev_complete_set.clear()


func _board_has_valid_moves() -> bool:
	for row in range(BOARD_ROWS):
		for col in range(BOARD_COLS):
			var from_cell := Vector2i(row, col)
			if not _is_cell_active(from_cell):
				continue
			var right_cell := Vector2i(row, col + 1)
			var down_cell := Vector2i(row + 1, col)

			if right_cell.y < BOARD_COLS and _is_cell_active(right_cell) and _swap_creates_match(from_cell, right_cell):
				return true
			if down_cell.x < BOARD_ROWS and _is_cell_active(down_cell) and _swap_creates_match(from_cell, down_cell):
				return true

	return false


func _swap_creates_match(a: Vector2i, b: Vector2i) -> bool:
	if not _is_cell_active(a) or not _is_cell_active(b):
		return false
	if String(board_data[a.x][a.y]).is_empty() or String(board_data[b.x][b.y]).is_empty():
		return false
	_swap_cells(a, b)
	var has_match: bool = not _find_matches().is_empty()
	_swap_cells(a, b)
	return has_match


func _show_overlay(title: String, body: String, action: String, primary_text: String, secondary_text: String, show_secondary: bool) -> void:
	overlay.visible = true
	overlay.modulate = Color(1, 1, 1, 0)
	overlay_title.text = title
	overlay_body.text = body
	overlay_action = action
	overlay_primary_button.text = primary_text
	overlay_secondary_button.visible = show_secondary
	overlay_secondary_button.text = secondary_text
	_update_overlay_mascot(title, action)
	_update_overlay_ribbon(action)
	var tween := create_tween()
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 0.14)


func _hide_overlay() -> void:
	overlay.visible = false
	overlay.modulate = Color(1, 1, 1, 1)
	overlay_action = ""


func _show_combo_banner(combo: int) -> void:
	if combo_banner == null:
		return
	combo_banner.texture = COMBO_POP_TEXTURE if combo <= 1 else COMBO_GREAT_TEXTURE
	combo_banner.visible = true
	combo_banner.modulate = Color(1, 1, 1, 0.0)
	combo_banner.scale = Vector2(0.78, 0.78)
	combo_banner.position = Vector2(combo_banner.position.x, 34.0)
	combo_label.text = "×%d" % combo if combo >= 2 else ""

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_banner, "scale", Vector2.ONE, 0.18)
	tween.tween_property(combo_banner, "modulate", Color(1, 1, 1, 1), 0.14)
	tween.tween_property(combo_banner, "position:y", 24.0, 0.18)
	await get_tree().create_timer(0.36).timeout

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(combo_banner, "modulate", Color(1, 1, 1, 0), 0.16)
	fade.tween_property(combo_banner, "position:y", 18.0, 0.16)
	await fade.finished
	combo_banner.visible = false


func _update_overlay_ribbon(action: String) -> void:
	if overlay_ribbon == null:
		return
	overlay_ribbon.visible = action in ["start_stage", "next_stage", "restart_stage", "clear_stage", "all_clear"]


func _on_overlay_primary_button_pressed() -> void:
	Feedback.play_ui_tap()
	var action: String = overlay_action
	_hide_overlay()

	match action:
		"start_stage":
			_set_status("%s 시작. 스와이프로 토끼를 모아 보세요." % _current_stage()["name"] if current_stage_index == 0 else "%s 진행 중입니다." % _current_stage()["name"])
			_maybe_advance_tutorial(1)
		"resume_stage":
			_set_status("%s 진행 중입니다." % _current_stage()["name"])
		"next_stage":
			GameSession.set_selected_stage_id(_current_stage_id() + 1)
			_start_stage(current_stage_index + 1)
		"clear_stage":
			GameSession.set_selected_stage_id(_current_stage_id() + 1)
			_start_stage(current_stage_index + 1)
		"all_clear":
			GameSession.save_state()
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"restart_stage":
			_start_stage(current_stage_index)


func _on_overlay_secondary_button_pressed() -> void:
	Feedback.play_ui_tap()
	var action: String = overlay_action
	_hide_overlay()

	if action == "clear_stage":
		GameSession.save_state()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	elif action == "all_clear":
		_start_stage(current_stage_index)
	elif action == "resume_stage":
		GameSession.save_state()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	elif action == "restart_stage":
		GameSession.save_state()
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _load_animal_textures() -> void:
	for animal_id in ANIMAL_IDS:
		animal_textures[animal_id] = _load_texture_from_png("res://assets/animals/%s_block.png" % animal_id)


func _load_ui_textures() -> void:
	ui_textures["background"] = _load_texture_from_png("res://assets/backgrounds/stage_meadow_bg_v1.png")
	ui_textures["background_band_02"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_02_main.svg")
	ui_textures["background_band_02_sub"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_02_sub.svg")
	ui_textures["background_band_03"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_03_main.svg")
	ui_textures["background_band_04"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_04_forest_edge.svg")
	ui_textures["background_band_05"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_05_garden_1.svg")
	ui_textures["background_band_06"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_06_garden_2.svg")
	ui_textures["background_band_07"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_07_night_shade_1.svg")
	ui_textures["background_band_08"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_08_skyline_1.svg")
	ui_textures["background_band_09"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_09_skyline_2.svg")
	ui_textures["background_band_10"] = _load_texture_from_png("res://assets/backgrounds/bands/bg_band_10_finale_1.svg")
	ui_textures["match_burst"] = _load_texture_from_png("res://assets/effects/match_burst_v1.png")
	ui_textures["bush"] = _load_texture_from_png("res://assets/effects/bush_obstacle_v1.png")
	background_texture.texture = ui_textures["background"]


func _load_texture_from_png(resource_path: String) -> Texture2D:
	var texture := load(resource_path)
	if texture is Texture2D:
		return texture
	push_warning("Texture load failed: %s" % resource_path)
	return null


func _update_stage_background() -> void:
	var background_key := _background_texture_key_for_stage()
	background_texture.texture = ui_textures.get(background_key, ui_textures.get("background"))


func _background_texture_key_for_stage() -> String:
	var stage_id := _current_stage_id()
	var theme_key := String(_current_stage().get("theme_key", "meadow_1"))

	match theme_key:
		"meadow_1":
			return "background"
		"meadow_2":
			if stage_id >= 19 and ui_textures.has("background_band_02_sub"):
				return "background_band_02_sub"
			return "background_band_02"
		"meadow_3":
			return "background_band_03"
		"forest_edge_1":
			return "background_band_04"
		"garden_1":
			return "background_band_05"
		"garden_2":
			return "background_band_06"
		"night_shade_1":
			return "background_band_07"
		"skyline_1":
			return "background_band_08"
		"skyline_2":
			return "background_band_09"
		"finale_1":
			return "background_band_10"
		_:
			return "background"


func _update_overlay_mascot(title: String, action: String) -> void:
	if overlay_mascot == null:
		return
	overlay_mascot.visible = true
	if action in ["next_stage", "clear_stage", "all_clear"]:
		overlay_mascot.texture = OVERLAY_SUCCESS_TEXTURE
		return
	if title.contains("실패") or stage_state == "failed":
		overlay_mascot.texture = OVERLAY_FAIL_TEXTURE
		return
	if action == "resume_stage":
		overlay_mascot.texture = animal_textures.get("bear")
		return
	overlay_mascot.texture = animal_textures.get("rabbit")


func _make_piece(animal_id: String, special_type: String = "") -> String:
	if special_type.is_empty():
		return animal_id
	return "%s|%s" % [animal_id, special_type]


func _piece_animal(piece_data: Variant) -> String:
	var piece_text: String = String(piece_data)
	if piece_text.is_empty():
		return ""
	return piece_text.split("|")[0]


func _piece_special(piece_data: Variant) -> String:
	var piece_text: String = String(piece_data)
	if piece_text.is_empty() or not piece_text.contains("|"):
		return ""
	return piece_text.split("|")[1]


func _setup_stage_blockers() -> void:
	for row in range(BOARD_ROWS):
		for col in range(BOARD_COLS):
			obstacle_data[row][col] = 0

	for blocker in _current_stage().get("blockers", []):
		var row: int = int(blocker["row"])
		var col: int = int(blocker["col"])
		if row >= 0 and row < BOARD_ROWS and col >= 0 and col < BOARD_COLS and _is_cell_active_xy(row, col):
			obstacle_data[row][col] = 1


func _adjacent_cells(cell: Vector2i) -> Array:
	var cells: Array = []
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next_cell: Vector2i = cell + direction
		if next_cell.x < 0 or next_cell.x >= BOARD_ROWS or next_cell.y < 0 or next_cell.y >= BOARD_COLS:
			continue
		if not _is_cell_active(next_cell):
			continue
		cells.append(next_cell)
	return cells


func _setup_board_mask() -> void:
	var raw_mask: Array = _current_stage().get("board_mask", [])

	for row in range(BOARD_ROWS):
		for col in range(BOARD_COLS):
			var is_active := true
			if row < raw_mask.size():
				var mask_row: String = String(raw_mask[row])
				if col < mask_row.length():
					is_active = mask_row[col] == "1"
			active_mask[row][col] = is_active
			if not is_active:
				board_data[row][col] = ""
				obstacle_data[row][col] = 0


func _is_cell_active(cell: Vector2i) -> bool:
	return _is_cell_active_xy(cell.x, cell.y)


func _is_cell_active_xy(row: int, col: int) -> bool:
	if row < 0 or row >= BOARD_ROWS or col < 0 or col >= BOARD_COLS:
		return false
	return bool(active_mask[row][col])


func _update_tips() -> void:
	if tutorial_enabled:
		tips_label.text = "%s\n%s" % [_soft_tutorial_label(), _tutorial_message()]
		return
	var lines := [
		"핵심 팁",
		"1. 4매치: 줄 제거 특수 블록",
		"2. 5매치: 3x3 폭발 블록",
		"3. 덤불은 매치된 칸과 인접 칸의 충격으로 제거",
	]
	tips_label.text = "\n".join(lines)


func _stage_star_rating() -> int:
	var total_moves := int(_current_stage().get("moves", 12))
	var three_star_threshold := maxi(3, int(round(total_moves * 0.35)))
	var two_star_threshold := maxi(1, int(round(total_moves * 0.15)))
	if remaining_moves >= three_star_threshold:
		return 3
	if remaining_moves >= two_star_threshold:
		return 2
	return 1


func _build_star_text(star_count: int) -> String:
	return "클리어 등급 %s" % _format_star_rating(star_count)


func _format_star_rating(star_count: int) -> String:
	var stars := ""
	for _i in range(star_count):
		stars += "★"
	for _i in range(maxi(0, 3 - star_count)):
		stars += "☆"
	return "%s  %d/3" % [stars, star_count]


func _build_clear_overlay_body(star_count: int, unlock_text: String, campaign_complete: bool) -> String:
	var lines: Array[String] = [
		"등급  %s" % _format_star_rating(star_count),
		"결과  점수 %d · 남은 이동 %d" % [score, remaining_moves],
		"완료  %s" % _build_goal_result_summary(),
	]
	if campaign_complete:
		lines.append("진행  100개 스테이지 완료")
		lines.append("다음 행동  홈으로 / 다시 플레이")
		lines.append("")
		lines.append("전체 구조 작전을 마쳤습니다. 홈에서 진행도를 확인할 수 있습니다.")
	else:
		lines.append("해금  %s" % unlock_text)
		lines.append("다음 행동  다음 스테이지 / 홈으로")
		lines.append("")
		lines.append("바로 다음 구조 작전으로 이어가거나 홈에서 진행도를 확인할 수 있습니다.")
	return "\n".join(lines)


func _build_failure_overlay_body() -> String:
	return "\n".join([
		"목표를 아직 달성하지 못했습니다.",
		"부족  %s" % _build_goal_remaining_summary(),
		"진행  %s" % _build_goal_result_summary(),
		"결과  점수 %d · 남은 이동 %d" % [score, remaining_moves],
		"다음 행동  재도전 / 홈으로",
		"",
		"다음 시도  %s" % _build_failure_hint(),
	])


func _build_unlock_text(star_count: int, prev_best: int) -> String:
	var next_id := _current_stage_id() + 1
	if current_stage_index >= stage_defs.size() - 1:
		return "모든 스테이지를 완료했습니다."
	if prev_best == 0:
		return "Stage %d 해금" % next_id
	var prev_stars := ""
	for _i in range(prev_best):
		prev_stars += "★"
	if star_count > prev_best:
		return "최고 등급 갱신 · Stage %d 해금" % next_id
	return "이전 기록 %s · Stage %d 해금" % [prev_stars, next_id]


func _build_failure_hint() -> String:
	if _target_blockers() > 0 and cleared_blockers < _target_blockers():
		return "특수 블록으로 덤불 구역을 함께 정리해 보세요."
	if _target_score() > 0 and score < _target_score():
		return "큰 매치와 연쇄를 더 노리면 점수를 끌어올릴 수 있습니다."
	return "목표 칩을 보고 필요한 동물부터 우선적으로 모아 보세요."


func _setup_tutorial() -> void:
	var is_tutorial_stage := _is_soft_tutorial_stage(_current_stage_id())
	tutorial_enabled = is_tutorial_stage and not GameSession.is_tutorial_seen(_current_stage_id())
	tutorial_step = 0 if tutorial_enabled else -1
	tutorial_banner.visible = tutorial_enabled
	if tutorial_enabled:
		GameSession.mark_tutorial_seen(_current_stage_id())
		_update_tutorial_banner()


func _maybe_advance_tutorial(target_step: int) -> void:
	if not tutorial_enabled:
		return
	if target_step <= tutorial_step:
		return
	tutorial_step = target_step
	_update_tutorial_banner()
	_update_tips()


func _update_tutorial_banner() -> void:
	if not tutorial_enabled:
		tutorial_banner.visible = false
		return
	tutorial_banner.visible = true
	tutorial_label.text = _tutorial_message()


func _tutorial_message() -> String:
	if _current_stage_id() != 1:
		return _current_stage_tutorial()
	match tutorial_step:
		0:
			return "Stage 1에서는 토끼 10개를 모으면 됩니다."
		1:
			return "오른쪽 목표 칩에서 토끼 목표를 먼저 확인하세요."
		2:
			return "좋아요. 이제 인접 블록을 스와이프해서 첫 매치를 만들어 보세요."
		3:
			return "잘 했어요. 매치 후 위 블록이 아래로 떨어지고 새 블록이 채워집니다."
		_:
			return "목표 칩을 보며 토끼를 계속 모아 보세요."


func _is_soft_tutorial_stage(stage_id: int) -> bool:
	return SOFT_TUTORIAL_STAGE_HINTS.has(stage_id)


func _soft_tutorial_label() -> String:
	return "튜토리얼 · %s" % String(SOFT_TUTORIAL_STAGE_HINTS.get(_current_stage_id(), "핵심 학습"))


func _current_stage_tutorial() -> String:
	var text := String(_current_stage().get("tutorial", ""))
	if text.is_empty():
		return "이번 구간의 핵심 규칙을 짧게 확인하고 시작하세요."
	return text
