extends Control

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const GameSession = preload("res://scripts/game_session.gd")
const LiveEventService = preload("res://scripts/live_event_service.gd")
const STAGE_CARD_SCENE = preload("res://scenes/stage_card.tscn")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const DEFAULT_BG = preload("res://assets/generated/candy/candy_world_bg.png")
const BG_BAND_02 = preload("res://assets/backgrounds/bands/bg_band_02_main.svg")
const BG_BAND_02_SUB = preload("res://assets/backgrounds/bands/bg_band_02_sub.svg")
const BG_BAND_03 = preload("res://assets/backgrounds/bands/bg_band_03_main.svg")
const BG_BAND_04 = preload("res://assets/backgrounds/bands/bg_band_04_forest_edge.svg")
const BG_BAND_05 = preload("res://assets/backgrounds/bands/bg_band_05_garden_1.svg")
const BG_BAND_06 = preload("res://assets/backgrounds/bands/bg_band_06_garden_2.svg")
const BG_BAND_07 = preload("res://assets/backgrounds/bands/bg_band_07_night_shade_1.svg")
const BG_BAND_08 = preload("res://assets/backgrounds/bands/bg_band_08_skyline_1.svg")
const BG_BAND_09 = preload("res://assets/backgrounds/bands/bg_band_09_skyline_2.svg")
const BG_BAND_10 = preload("res://assets/backgrounds/bands/bg_band_10_finale_1.svg")
const STORY_PATH_NODE_LOCKED = preload("res://assets/ui/meta/story_path_node_locked.svg")
const STORY_PATH_NODE_CURRENT = preload("res://assets/ui/meta/story_path_node_current.svg")
const STORY_PATH_NODE_CLEARED = preload("res://assets/ui/meta/story_path_node_cleared.svg")
const STORY_PATH_CONNECTOR = preload("res://assets/ui/meta/story_path_connector.svg")
const STAGE_LOCK_TEXTURE = preload("res://assets/ui/meta/stage_lock.svg")
const MAP_RABBIT_TEXTURE = preload("res://assets/generated/polish/home_mascot_rabbit_clean.png")
const MAP_CHICK_TEXTURE = preload("res://assets/generated/polish/home_mascot_chick_clean.png")
const BOOSTER_ICONS := {
	"rainbow_paw": preload("res://assets/ui/badge_rainbow.svg"),
	"striped": preload("res://assets/ui/badge_row.svg"),
	"bomb": preload("res://assets/ui/badge_bomb.svg"),
}
const WORLD_NODE_POSITIONS := [
	Vector2(0.18, 0.76),
	Vector2(0.34, 0.66),
	Vector2(0.24, 0.53),
	Vector2(0.42, 0.43),
	Vector2(0.60, 0.52),
	Vector2(0.73, 0.39),
	Vector2(0.58, 0.27),
	Vector2(0.40, 0.21),
	Vector2(0.25, 0.32),
	Vector2(0.78, 0.18),
]
const WORLD_CANDY_COLORS := [
	Color("ff6fae"),
	Color("ffd84f"),
	Color("57d4ff"),
	Color("7cf47b"),
	Color("b98cff"),
	Color("ff934f"),
]

const BAND_ORDER := ["1-10", "11-20", "21-30", "31-40", "41-50", "51-60", "61-70", "71-80", "81-90", "91-100"]
const BAND_META := {
	"1-10": {
		"title": "정글 입구",
		"tagline": "정글 입구에서 첫 구조를 시작합니다.",
		"story": "작은 동물 구조로 세계관을 소개하는 시작 구간입니다. 토끼와 병아리를 먼저 풀어 주며 구조 작전의 감각을 익힙니다.",
	},
	"11-20": {
		"title": "밀렵 흔적 발견",
		"tagline": "밀렵꾼의 흔적을 따라 덫과 우리를 해제합니다.",
		"story": "우리와 덫이 보이기 시작합니다. 구조가 우연이 아니라 작전이라는 사실을 플레이어가 처음 체감하는 구간입니다.",
	},
	"21-30": {
		"title": "야영지 외곽",
		"tagline": "야영지 외곽을 돌파하며 막힌 길을 엽니다.",
		"story": "덤불과 장애물이 본격적으로 밀도를 올립니다. 더 깊은 지역으로 들어가며 길을 여는 판단이 중요해집니다.",
	},
	"31-40": {
		"title": "복수 구조 작전",
		"tagline": "여러 동물을 동시에 구출하는 복합 작전에 들어갑니다.",
		"story": "곰과 개구리 같은 더 큰 구조 대상이 늘어납니다. 여러 목표를 동시에 읽는 감각을 요구하는 구간입니다.",
	},
	"41-50": {
		"title": "강가와 진흙 지대",
		"tagline": "강가와 진흙 지대를 지나 더 큰 흔적에 가까워집니다.",
		"story": "통로가 좁아지고 압박이 강해집니다. 대형 동물이 갇혀 있다는 암시가 본격적으로 보이기 시작합니다.",
	},
	"51-60": {
		"title": "야영지 내부",
		"tagline": "야영지 내부에서 운반 루트와 사냥 흔적을 끊어 냅니다.",
		"story": "밀렵꾼의 사냥 루트와 운반 경로가 드러납니다. 장애물 밀도가 높고 중심 제어가 중요한 밴드입니다.",
	},
	"61-70": {
		"title": "깊은 밀림",
		"tagline": "깊은 밀림에서 까다로운 구조 루트를 판독합니다.",
		"story": "전문가 구간입니다. 큰 우리와 방해물이 많아지고, 구조 루트를 읽는 능력이 핵심이 됩니다.",
	},
	"71-80": {
		"title": "탈출 준비",
		"tagline": "탈출 준비를 위해 구조 대상을 먼저 확보합니다.",
		"story": "여러 동물을 먼저 풀어야 다음 길이 열리는 준비 구간입니다. 코끼리 탈출 작전 전 단계로 긴장을 쌓습니다.",
	},
	"81-90": {
		"title": "수송 경로 추적",
		"tagline": "코끼리 수송 경로를 추적하며 마지막 봉쇄선에 접근합니다.",
		"story": "코끼리 수송 경로를 따라가며 마지막 봉쇄선을 해제하는 구간입니다. 후반 압박과 복합 목표가 강해집니다.",
	},
	"91-100": {
		"title": "최종 구출 작전",
		"tagline": "최종 구출 작전으로 코끼리 탈출을 완성합니다.",
		"story": "대형 우리 주변의 동물들을 먼저 구출하고, 마지막에 거대한 코끼리를 탈출시키는 피날레 구간입니다.",
	},
}

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var layout_root: VBoxContainer = $SafeMargin/LayoutRoot
@onready var header_panel: PanelContainer = $SafeMargin/LayoutRoot/HeaderPanel
@onready var header_summary_label: Label = $SafeMargin/LayoutRoot/HeaderPanel/HeaderMargin/HeaderRow/HeaderText/HeaderSummaryLabel
@onready var home_button: Button = $SafeMargin/LayoutRoot/HeaderPanel/HeaderMargin/HeaderRow/HomeButton
@onready var content_root: BoxContainer = $SafeMargin/LayoutRoot/ContentRoot
@onready var story_panel: PanelContainer = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel
@onready var story_title_label: Label = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel/StoryFrame/StoryMargin/StoryColumn/StoryTitleLabel
@onready var story_body_label: Label = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel/StoryFrame/StoryMargin/StoryColumn/StoryBodyLabel
@onready var selected_stage_label: Label = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel/StoryFrame/StoryMargin/StoryColumn/SelectedStageCard/SelectedStageMargin/SelectedStageColumn/SelectedStageLabel
@onready var selected_stage_body_label: Label = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel/StoryFrame/StoryMargin/StoryColumn/SelectedStageCard/SelectedStageMargin/SelectedStageColumn/SelectedStageBodyLabel
@onready var band_route_title_label: Label = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel/StoryFrame/StoryMargin/StoryColumn/BandRouteCard/BandRouteMargin/BandRouteColumn/BandRouteTitleLabel
@onready var band_route_row: HBoxContainer = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel/StoryFrame/StoryMargin/StoryColumn/BandRouteCard/BandRouteMargin/BandRouteColumn/BandRouteScroll/BandRouteRow
@onready var timeline_list: VBoxContainer = $SafeMargin/LayoutRoot/ContentRoot/StoryPanel/StoryFrame/StoryMargin/StoryColumn/TimelineScroll/TimelineList
@onready var stage_panel: PanelContainer = $SafeMargin/LayoutRoot/ContentRoot/StagePanel
@onready var stage_hint_label: Label = $SafeMargin/LayoutRoot/ContentRoot/StagePanel/StageFrame/StageMargin/StageColumn/StageHintLabel
@onready var stage_scroll: ScrollContainer = $SafeMargin/LayoutRoot/ContentRoot/StagePanel/StageFrame/StageMargin/StageColumn/StageScroll
@onready var stage_grid: GridContainer = $SafeMargin/LayoutRoot/ContentRoot/StagePanel/StageFrame/StageMargin/StageColumn/StageScroll/StageGrid

var stage_defs: Array = []
var selected_popup_stage_id := 1
var selected_pre_boosters: Array[String] = []
var map_juice_layer: Control
var map_rabbit: TextureRect
var map_chick: TextureRect
var map_tweens: Array[Tween] = []
var current_stage_node_tween: Tween
var stage_world_layer: Control
var world_decor_root: Control
var world_title_label: Label
var world_subtitle_label: Label
var world_status_label: Label
var world_path_root: Control
var world_event_strip: HBoxContainer
var world_play_button: Button
var world_selected_label: Label
var world_selected_chip_row: HBoxContainer
var world_selected_goal_chip: Button
var world_selected_moves_chip: Button
var world_selected_reward_chip: Button
var world_node_buttons: Array[Button] = []
var stage_popup_overlay: ColorRect
var stage_popup_panel: PanelContainer
var stage_popup_title_label: Label
var stage_popup_goal_label: Label
var stage_popup_meta_label: Label
var stage_popup_reward_label: Label
var stage_popup_buddy_label: Label
var stage_popup_margin: MarginContainer
var stage_popup_column: VBoxContainer
var stage_popup_booster_row: HBoxContainer
var stage_popup_start_button: Button
var stage_popup_close_button: Button
var stage_popup_booster_buttons: Dictionary = {}
var stage_select_event_impressions_sent := {}


func _ready() -> void:
	GameSession.load_state()
	GameSession.apply_feedback_preferences()
	stage_defs = StageCatalog.get_stages()
	if stage_defs.is_empty():
		return
	if GameSession.get_selected_stage_id() < 1:
		GameSession.set_selected_stage_id(1)
	resized.connect(_queue_layout_refresh)
	get_window().size_changed.connect(_queue_layout_refresh)
	_build_map_juice_layer()
	_build_stage_world_layer()
	_build_stage_popup()
	_rebuild_stage_grid()
	_refresh_story_panel()
	call_deferred("_focus_selected_stage_card")
	call_deferred("_apply_responsive_layout")
	call_deferred("_start_map_ambient_animations")


func _on_home_button_pressed() -> void:
	Feedback.play_ui_tap()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _rebuild_stage_grid() -> void:
	if current_stage_node_tween != null and current_stage_node_tween.is_valid():
		current_stage_node_tween.kill()
	current_stage_node_tween = null
	for child in stage_grid.get_children():
		child.queue_free()

	for stage_def in stage_defs:
		var node_button := _make_stage_map_node(stage_def)
		stage_grid.add_child(node_button)


func _make_stage_map_node(stage_def: Dictionary) -> Button:
	var stage_id := int(stage_def.get("id", 0))
	var unlocked := GameSession.is_stage_unlocked(stage_id)
	var best_stars := GameSession.get_best_stars(stage_id)
	var current := stage_id == GameSession.get_selected_stage_id()
	var finale := stage_id % 10 == 0

	var button := Button.new()
	button.name = "StageNode%d" % stage_id
	button.custom_minimum_size = Vector2(124, 124)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not unlocked
	button.text = _stage_node_text(stage_id, unlocked, best_stars, current)
	button.add_theme_font_size_override("font_size", 23 if unlocked else 21)
	button.add_theme_color_override("font_color", Color("1f415c") if unlocked else Color("7f8792"))
	button.add_theme_color_override("font_disabled_color", Color("7f8792"))
	button.add_theme_stylebox_override("normal", _stage_node_style(unlocked, current, finale, best_stars))
	button.add_theme_stylebox_override("hover", _stage_node_style(unlocked, true, finale, best_stars))
	button.add_theme_stylebox_override("pressed", _stage_node_style(unlocked, true, finale, best_stars, true))
	button.add_theme_stylebox_override("disabled", _stage_node_style(false, false, finale, best_stars))
	button.pressed.connect(_on_stage_card_pressed.bind(stage_id))

	if not unlocked:
		var lock_center := CenterContainer.new()
		lock_center.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lock_icon := TextureRect.new()
		lock_icon.texture = STAGE_LOCK_TEXTURE
		lock_icon.custom_minimum_size = Vector2(44, 44)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.modulate = Color(1, 1, 1, 0.76)
		lock_center.add_child(lock_icon)
		button.add_child(lock_center)

	return button


func _stage_node_text(stage_id: int, unlocked: bool, best_stars: int, current: bool) -> String:
	if not unlocked:
		return "\n%d" % stage_id
	if current:
		return "GO\n%d\n%s" % [stage_id, _stage_stars_text(best_stars)]
	if stage_id % 10 == 0:
		return "BOSS\n%d\n%s" % [stage_id, _stage_stars_text(best_stars)]
	return "%d\n%s" % [stage_id, _stage_stars_text(best_stars)]


func _stage_stars_text(best_stars: int) -> String:
	if best_stars <= 0:
		return "☆ ☆ ☆"
	var stars := ""
	for index in range(3):
		stars += "★" if index < best_stars else "☆"
		if index < 2:
			stars += " "
	return stars


func _stage_node_style(unlocked: bool, current: bool, finale: bool, best_stars: int, pressed: bool = false) -> StyleBoxFlat:
	var bg_color := Color("ffffff")
	var border_color := Color("64c5f4")
	if not unlocked:
		bg_color = Color(0.90, 0.91, 0.96, 0.80)
		border_color = Color(0.70, 0.75, 0.82, 0.92)
	elif current:
		bg_color = Color("ffe05a") if not pressed else Color("ffc445")
		border_color = Color("ff6fae")
	elif finale:
		bg_color = Color("f0dcff")
		border_color = Color("8d5cff")
	elif best_stars > 0:
		bg_color = Color("a7ffd4")
		border_color = Color("22bb86")
	else:
		bg_color = Color("ffffff")
		border_color = Color("4fcaff")

	var style := _rounded_style(bg_color, border_color, 72, 8 if current else 6)
	style.shadow_color = Color(0.08, 0.16, 0.30, 0.32 if unlocked else 0.10)
	style.shadow_size = 18 if unlocked else 7
	style.shadow_offset = Vector2(0, 8 if unlocked else 3)
	return style


func _start_current_stage_node_pulse(node_button: Button) -> void:
	if not is_instance_valid(node_button) or not node_button.is_inside_tree():
		return
	if current_stage_node_tween != null and current_stage_node_tween.is_valid():
		current_stage_node_tween.kill()
	node_button.pivot_offset = node_button.size * 0.5
	current_stage_node_tween = create_tween()
	current_stage_node_tween.set_loops()
	current_stage_node_tween.set_trans(Tween.TRANS_SINE)
	current_stage_node_tween.set_ease(Tween.EASE_IN_OUT)
	current_stage_node_tween.tween_property(node_button, "scale", Vector2(1.055, 1.055), 0.58)
	current_stage_node_tween.tween_property(node_button, "scale", Vector2.ONE, 0.58)


func _on_stage_card_pressed(stage_id: int) -> void:
	if not GameSession.is_stage_unlocked(stage_id):
		return
	Feedback.play_ui_tap()
	GameSession.set_selected_stage_id(stage_id)
	_refresh_story_panel()
	_rebuild_stage_grid()
	_show_stage_popup(stage_id)


func _build_map_juice_layer() -> void:
	if map_juice_layer:
		return

	map_juice_layer = Control.new()
	map_juice_layer.name = "StageMapJuiceLayer"
	map_juice_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_juice_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_juice_layer)
	move_child(map_juice_layer, safe_margin.get_index())

	map_rabbit = _make_map_mascot("MapRabbit", MAP_RABBIT_TEXTURE)
	map_juice_layer.add_child(map_rabbit)
	map_chick = _make_map_mascot("MapChick", MAP_CHICK_TEXTURE)
	map_juice_layer.add_child(map_chick)


func _make_map_mascot(node_name: String, texture: Texture2D) -> TextureRect:
	var mascot := TextureRect.new()
	mascot.name = node_name
	mascot.texture = texture
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascot.modulate = Color(1, 1, 1, 0.78)
	return mascot


func _build_stage_world_layer() -> void:
	if stage_world_layer:
		return

	stage_world_layer = Control.new()
	stage_world_layer.name = "StageWorldLayer"
	stage_world_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_world_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(stage_world_layer)
	move_child(stage_world_layer, safe_margin.get_index() + 1)

	var shade := ColorRect.new()
	shade.name = "WorldShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.05, 0.32, 0.62, 0.16)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_world_layer.add_child(shade)

	world_decor_root = Control.new()
	world_decor_root.name = "WorldDecorRoot"
	world_decor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_decor_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_world_layer.add_child(world_decor_root)

	var top_hud := HBoxContainer.new()
	top_hud.name = "WorldTopHud"
	top_hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_hud.offset_left = 24.0
	top_hud.offset_top = 22.0
	top_hud.offset_right = -24.0
	top_hud.offset_bottom = 96.0
	top_hud.add_theme_constant_override("separation", 12)
	stage_world_layer.add_child(top_hud)

	var home_nav := _make_world_button("홈", Vector2(112, 66), 22)
	home_nav.pressed.connect(_on_home_button_pressed)
	top_hud.add_child(home_nav)
	top_hud.add_child(_make_world_badge("♥", "5"))
	top_hud.add_child(_make_world_badge("●", str(120 + GameSession.get_total_stars() * 15)))
	top_hud.add_child(_make_world_badge("★", str(GameSession.get_total_stars())))
	var hud_spacer := Control.new()
	hud_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hud.add_child(hud_spacer)

	var title_stack := VBoxContainer.new()
	title_stack.name = "WorldTitleStack"
	title_stack.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_stack.offset_left = 36.0
	title_stack.offset_top = 116.0
	title_stack.offset_right = -36.0
	title_stack.offset_bottom = 230.0
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 2)
	stage_world_layer.add_child(title_stack)

	world_title_label = _make_world_label("정글 입구", 58, Color(1.0, 0.93, 0.18, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	world_title_label.add_theme_color_override("font_shadow_color", Color(0.06, 0.20, 0.34, 0.80))
	world_title_label.add_theme_constant_override("shadow_offset_y", 6)
	title_stack.add_child(world_title_label)

	world_subtitle_label = _make_world_label("동물 구조 월드맵", 24, Color(1, 1, 1, 0.98), HORIZONTAL_ALIGNMENT_CENTER)
	world_subtitle_label.add_theme_color_override("font_shadow_color", Color(0.06, 0.20, 0.34, 0.62))
	world_subtitle_label.add_theme_constant_override("shadow_offset_y", 3)
	title_stack.add_child(world_subtitle_label)

	world_path_root = Control.new()
	world_path_root.name = "WorldMapPathRoot"
	world_path_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_path_root.mouse_filter = Control.MOUSE_FILTER_PASS
	stage_world_layer.add_child(world_path_root)

	world_event_strip = HBoxContainer.new()
	world_event_strip.name = "LiveEventStrip"
	world_event_strip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	world_event_strip.alignment = BoxContainer.ALIGNMENT_END
	world_event_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_event_strip.add_theme_constant_override("separation", 8)
	stage_world_layer.add_child(world_event_strip)

	var cta_panel := PanelContainer.new()
	cta_panel.name = "WorldSelectedPanel"
	cta_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cta_panel.offset_left = 22.0
	cta_panel.offset_top = -166.0
	cta_panel.offset_right = -22.0
	cta_panel.offset_bottom = -22.0
	cta_panel.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.84), Color("ffbf32"), 30, 5))
	stage_world_layer.add_child(cta_panel)

	var cta_margin := MarginContainer.new()
	cta_margin.add_theme_constant_override("margin_left", 22)
	cta_margin.add_theme_constant_override("margin_top", 18)
	cta_margin.add_theme_constant_override("margin_right", 22)
	cta_margin.add_theme_constant_override("margin_bottom", 18)
	cta_panel.add_child(cta_margin)

	var cta_row := HBoxContainer.new()
	cta_row.name = "WorldSelectedContentRow"
	cta_row.add_theme_constant_override("separation", 16)
	cta_margin.add_child(cta_row)

	var selected_column := VBoxContainer.new()
	selected_column.name = "WorldSelectedInfoColumn"
	selected_column.alignment = BoxContainer.ALIGNMENT_CENTER
	selected_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_column.add_theme_constant_override("separation", 8)
	cta_row.add_child(selected_column)

	world_selected_label = _make_world_label("Stage", 24, Color("213a55"), HORIZONTAL_ALIGNMENT_LEFT)
	world_selected_label.name = "WorldSelectedTitleLabel"
	world_selected_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selected_column.add_child(world_selected_label)

	world_selected_chip_row = HBoxContainer.new()
	world_selected_chip_row.name = "WorldSelectedChipRow"
	world_selected_chip_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_selected_chip_row.add_theme_constant_override("separation", 8)
	selected_column.add_child(world_selected_chip_row)

	world_selected_goal_chip = _make_world_info_chip("WorldSelectedGoalChip", "목표")
	world_selected_moves_chip = _make_world_info_chip("WorldSelectedMovesChip", "이동")
	world_selected_reward_chip = _make_world_info_chip("WorldSelectedRewardChip", "보상")
	world_selected_chip_row.add_child(world_selected_goal_chip)
	world_selected_chip_row.add_child(world_selected_moves_chip)
	world_selected_chip_row.add_child(world_selected_reward_chip)

	world_play_button = _make_world_button("PLAY", Vector2(190, 88), 30)
	world_play_button.name = "WorldPlayButton"
	world_play_button.pressed.connect(_on_world_play_button_pressed)
	cta_row.add_child(world_play_button)


func _make_world_badge(label_text: String, value_text: String) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(112, 58)
	badge.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.88), Color("ffcf3f"), 22, 3))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	badge.add_child(margin)
	var label := _make_world_label("%s  %s" % [label_text, value_text], 20, Color("213a55"), HORIZONTAL_ALIGNMENT_CENTER)
	margin.add_child(label)
	return badge


func _make_world_button(text: String, min_size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("653b08"))
	button.add_theme_stylebox_override("normal", _rounded_style(Color("ffd450"), Color("f28c26"), 30, 5))
	button.add_theme_stylebox_override("hover", _rounded_style(Color("ffe978"), Color("f28c26"), 30, 5))
	button.add_theme_stylebox_override("pressed", _rounded_style(Color("ffbd3f"), Color("e86e18"), 30, 5))
	return button


func _make_world_info_chip(node_name: String, text: String) -> Button:
	var chip := Button.new()
	chip.name = node_name
	chip.text = text
	chip.disabled = true
	chip.focus_mode = Control.FOCUS_NONE
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.custom_minimum_size = Vector2(150, 46)
	chip.add_theme_font_size_override("font_size", 20)
	chip.add_theme_color_override("font_color", Color("213a55"))
	chip.add_theme_color_override("font_disabled_color", Color("213a55"))
	chip.add_theme_stylebox_override("normal", _world_info_chip_style(node_name))
	chip.add_theme_stylebox_override("disabled", _world_info_chip_style(node_name))
	return chip


func _world_info_chip_style(node_name: String) -> StyleBoxFlat:
	var bg_color := Color("e5f8ff")
	var border_color := Color("73c9ef")
	if node_name.contains("Goal"):
		bg_color = Color("e8ffd9")
		border_color = Color("63cf81")
	elif node_name.contains("Moves"):
		bg_color = Color("fff3bb")
		border_color = Color("ffbf32")
	elif node_name.contains("Reward"):
		bg_color = Color("ffe5f0")
		border_color = Color("ff77aa")
	var style := _rounded_style(bg_color, border_color, 18, 3)
	style.shadow_color = Color(0.10, 0.16, 0.24, 0.10)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _make_world_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_world_play_button_pressed() -> void:
	Feedback.play_ui_tap()
	_show_stage_popup(GameSession.get_selected_stage_id())


func _build_stage_popup() -> void:
	stage_popup_overlay = ColorRect.new()
	stage_popup_overlay.name = "StagePopupOverlay"
	stage_popup_overlay.visible = false
	stage_popup_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_popup_overlay.color = Color(0.11, 0.14, 0.20, 0.72)
	add_child(stage_popup_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_popup_overlay.add_child(center)

	stage_popup_panel = PanelContainer.new()
	stage_popup_panel.name = "StagePopupPanel"
	stage_popup_panel.custom_minimum_size = Vector2(680, 720)
	stage_popup_panel.add_theme_stylebox_override("panel", _rounded_style(Color(1.0, 0.98, 0.90, 0.99), Color(1.0, 0.68, 0.16, 1.0), 34, 8))
	center.add_child(stage_popup_panel)

	stage_popup_margin = MarginContainer.new()
	stage_popup_margin.add_theme_constant_override("margin_left", 28)
	stage_popup_margin.add_theme_constant_override("margin_top", 28)
	stage_popup_margin.add_theme_constant_override("margin_right", 28)
	stage_popup_margin.add_theme_constant_override("margin_bottom", 28)
	stage_popup_panel.add_child(stage_popup_margin)

	stage_popup_column = VBoxContainer.new()
	stage_popup_column.add_theme_constant_override("separation", 18)
	stage_popup_margin.add_child(stage_popup_column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	stage_popup_column.add_child(header)

	stage_popup_title_label = _make_popup_label("Level Ready", 38, Color("213a55"), HORIZONTAL_ALIGNMENT_LEFT)
	stage_popup_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_popup_title_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.86, 0.20, 0.62))
	stage_popup_title_label.add_theme_constant_override("shadow_offset_y", 3)
	header.add_child(stage_popup_title_label)

	stage_popup_close_button = Button.new()
	stage_popup_close_button.text = "×"
	stage_popup_close_button.custom_minimum_size = Vector2(72, 72)
	stage_popup_close_button.add_theme_font_size_override("font_size", 34)
	stage_popup_close_button.add_theme_color_override("font_color", Color("213a55"))
	stage_popup_close_button.add_theme_stylebox_override("normal", _rounded_style(Color(1, 1, 1, 0.66), Color("86c3e5"), 22, 3))
	stage_popup_close_button.add_theme_stylebox_override("hover", _rounded_style(Color("e9fbff"), Color("6ec6ff"), 22, 3))
	stage_popup_close_button.add_theme_stylebox_override("pressed", _rounded_style(Color("d8f6ff"), Color("6ec6ff"), 22, 3))
	stage_popup_close_button.pressed.connect(_on_stage_popup_close_pressed)
	header.add_child(stage_popup_close_button)

	stage_popup_goal_label = _make_popup_label("목표", 26, Color("513d30"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_goal_label.custom_minimum_size = Vector2(0, 104)
	stage_popup_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_popup_goal_label.add_theme_stylebox_override("normal", _rounded_style(Color(0.87, 1.0, 0.76, 0.76), Color("58c878"), 24, 3))
	stage_popup_column.add_child(stage_popup_goal_label)

	stage_popup_meta_label = _make_popup_label("이동 · 난이도", 24, Color("2f617d"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_popup_meta_label.add_theme_stylebox_override("normal", _rounded_style(Color(0.90, 0.97, 1.0, 0.72), Color("86c3e5"), 20, 3))
	stage_popup_column.add_child(stage_popup_meta_label)

	stage_popup_reward_label = _make_popup_label("보상", 24, Color("7a4d11"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_reward_label.custom_minimum_size = Vector2(0, 76)
	stage_popup_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_popup_reward_label.add_theme_stylebox_override("normal", _rounded_style(Color(1.0, 0.91, 0.54, 0.78), Color("ffbf32"), 20, 3))
	stage_popup_column.add_child(stage_popup_reward_label)

	stage_popup_buddy_label = _make_popup_label("", 23, Color("31506a"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_buddy_label.name = "StagePopupBuddyLabel"
	stage_popup_buddy_label.custom_minimum_size = Vector2(0, 92)
	stage_popup_buddy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_popup_buddy_label.add_theme_stylebox_override("normal", _rounded_style(Color(0.90, 0.97, 1.0, 0.72), Color("86c3e5"), 24, 3))
	stage_popup_column.add_child(stage_popup_buddy_label)

	var booster_title := _make_popup_label("시작 부스터", 28, Color("213a55"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_column.add_child(booster_title)

	stage_popup_booster_row = HBoxContainer.new()
	stage_popup_booster_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_popup_booster_row.add_theme_constant_override("separation", 12)
	stage_popup_column.add_child(stage_popup_booster_row)
	for booster_id in ["rainbow_paw", "striped", "bomb"]:
		var button := _make_booster_button(booster_id)
		stage_popup_booster_buttons[booster_id] = button
		stage_popup_booster_row.add_child(button)

	stage_popup_start_button = Button.new()
	stage_popup_start_button.text = "PLAY"
	stage_popup_start_button.custom_minimum_size = Vector2(0, 92)
	stage_popup_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_popup_start_button.add_theme_font_size_override("font_size", 36)
	stage_popup_start_button.add_theme_color_override("font_color", Color("6a3e07"))
	stage_popup_start_button.add_theme_stylebox_override("normal", _rounded_style(Color("ffd85a"), Color("f28c26"), 30, 6))
	stage_popup_start_button.add_theme_stylebox_override("hover", _rounded_style(Color("ffe67d"), Color("f28c26"), 30, 6))
	stage_popup_start_button.add_theme_stylebox_override("pressed", _rounded_style(Color("ffbf42"), Color("f28c26"), 30, 6))
	stage_popup_start_button.pressed.connect(_on_stage_popup_start_pressed)
	stage_popup_column.add_child(stage_popup_start_button)


func _make_popup_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_booster_button(booster_id: String) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(190, 118)
	button.icon = BOOSTER_ICONS.get(booster_id)
	button.expand_icon = true
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("213a55"))
	button.add_theme_stylebox_override("normal", _rounded_style(Color(1, 1, 1, 0.82), Color("86c3e5"), 26, 4))
	button.add_theme_stylebox_override("hover", _rounded_style(Color("e9fbff"), Color("6ec6ff"), 26, 4))
	button.add_theme_stylebox_override("pressed", _rounded_style(Color("fff0a8"), Color("ff74a8"), 26, 4))
	button.pressed.connect(_on_booster_button_pressed.bind(booster_id))
	return button


func _rounded_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.16, 0.22, 0.28, 0.16)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


func _show_stage_popup(stage_id: int) -> void:
	selected_popup_stage_id = stage_id
	selected_pre_boosters = []
	var stage_def := _stage_def_by_id(stage_id)
	stage_popup_title_label.text = "Level %d" % stage_id
	stage_popup_goal_label.text = _build_stage_popup_goal_text(stage_def)
	stage_popup_meta_label.text = "%s · 이동 %d · %s" % [
		String(stage_def.get("name", "Stage")),
		int(stage_def.get("moves", 0)),
		_theme_display_name(String(stage_def.get("theme_key", "meadow_1"))),
	]
	stage_popup_reward_label.text = "보상  골드 %d · ★★★ · 다음 노드 해금" % _stage_gold_reward(stage_def)
	var buddy_text := _build_stage_popup_buddy_text(stage_def)
	stage_popup_buddy_label.visible = not buddy_text.is_empty()
	stage_popup_buddy_label.text = buddy_text
	_refresh_booster_buttons()
	stage_popup_overlay.visible = true
	stage_popup_overlay.modulate = Color(1, 1, 1, 0)
	stage_popup_panel.scale = Vector2(0.84, 0.84)
	stage_popup_panel.pivot_offset = stage_popup_panel.size * 0.5
	var tween := create_tween()
	tween.tween_property(stage_popup_overlay, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.parallel().tween_property(stage_popup_panel, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _stage_def_by_id(stage_id: int) -> Dictionary:
	for stage_def in stage_defs:
		if int(stage_def.get("id", 0)) == stage_id:
			return stage_def
	return stage_defs[0]


func _build_stage_popup_goal_text(stage_def: Dictionary) -> String:
	var lines: Array[String] = ["목표"]
	var target_parts: Array[String] = []
	var targets: Dictionary = Dictionary(stage_def.get("target_collect", {}))
	for animal_id in targets.keys():
		target_parts.append("%s %d" % [_animal_name(String(animal_id)), int(targets[animal_id])])
	var target_score := int(stage_def.get("target_score", 0))
	if target_score > 0:
		target_parts.append("점수 %d" % target_score)
	var target_blockers := int(stage_def.get("target_blockers", 0))
	if target_blockers > 0:
		target_parts.append("덤불 %d" % target_blockers)
	lines.append(" · ".join(target_parts))
	return "\n".join(lines)


func _build_stage_popup_buddy_text(stage_def: Dictionary) -> String:
	var animal_id := String(stage_def.get("buddy_animal", ""))
	var skill_id := String(stage_def.get("buddy_skill_id", ""))
	if animal_id.is_empty() or skill_id.is_empty():
		return ""

	var charges_required := int(stage_def.get("buddy_charges_required", 0))
	var max_uses := int(stage_def.get("buddy_max_uses", 0))
	var summary := "Rescue Buddy %s · %s" % [_animal_name(animal_id), _buddy_skill_title(skill_id)]
	var detail := "%s · %s" % [
		_buddy_charge_rule_text(String(stage_def.get("buddy_charge_rule", "")), charges_required),
		_buddy_skill_description(skill_id),
	]
	if max_uses > 0:
		detail += " · 최대 %d회" % max_uses
	return "%s\n%s" % [summary, detail]


func _buddy_skill_title(skill_id: String) -> String:
	match skill_id:
		"quick_refill":
			return "Quick Refill"
		"soft_bomb_plus":
			return "Paw Bomb Plus"
		"smart_hint":
			return "Smart Hint"
		"combo_peep":
			return "Combo Peep"
		"leap_clear":
			return "Leap Clear"
		"loyal_fetch":
			return "Loyal Fetch"
		"calm_fever":
			return "Calm Fever"
		"coin_sniff":
			return "Coin Sniff"
		"cascade_slide":
			return "Cascade Slide"
		"sly_route":
			return "Sly Route"
		"brave_start":
			return "Brave Start"
		"mighty_push":
			return "Mighty Push"
	return skill_id.replace("_", " ").capitalize()


func _buddy_charge_rule_text(charge_rule: String, charges_required: int) -> String:
	match charge_rule:
		"match_goal_animal":
			return "목표 동물 매치 %d회 충전" % charges_required
		"combo_2_plus":
			return "콤보 2 이상에서 충전"
		"near_fail":
			return "실패 직전 자동 대기"
		"fever_start":
			return "Fever 시작 시 충전"
		"stage_clear":
			return "클리어 시 보상 강화"
		"cascade_step":
			return "연쇄 발생 시 충전"
		"low_moves":
			return "이동 수 3 이하에서 충전"
		"stage_start":
			return "스테이지 시작 시 안내"
		"clear_blocker":
			return "덤불 제거 시 충전"
	return "조건 충족 시 자동 발동"


func _buddy_skill_description(skill_id: String) -> String:
	match skill_id:
		"soft_bomb_plus":
			return "목표 동물 1개를 폭발 특수 블록으로 강화"
		"smart_hint":
			return "목표에 가까운 추천 수 강조"
		"sly_route":
			return "이동 수가 적을 때 추천 경로 강조"
		"leap_clear":
			return "남은 덤불 1개 추가 제거"
		"combo_peep":
			return "Combo Gauge 추가 충전"
		"loyal_fetch":
			return "실패 직전 목표 동물과 이동 1회 구조"
		"calm_fever":
			return "Fever 종료 후 Combo Gauge 2칸 보존"
		"coin_sniff":
			return "클리어 보상 골드 5% 증가"
		"cascade_slide":
			return "연쇄 점수 보너스"
		"brave_start":
			return "하드 시작 추천 부스터 안내"
		"mighty_push":
			return "남은 덤불 1개 추가 밀어내기"
	return "목표 동물 1개를 보드에 불러오기"


func _stage_gold_reward(stage_def: Dictionary) -> int:
	var stage_id := int(stage_def.get("id", 1))
	var difficulty := String(stage_def.get("difficulty", "Easy"))
	var difficulty_bonus := 10 if difficulty == "Easy" else 18
	if difficulty == "Hard":
		difficulty_bonus = 30
	return 40 + stage_id * 2 + difficulty_bonus


func _on_booster_button_pressed(booster_id: String) -> void:
	if selected_pre_boosters.has(booster_id):
		selected_pre_boosters.erase(booster_id)
	else:
		selected_pre_boosters.append(booster_id)
	Feedback.play_ui_tap()
	_refresh_booster_buttons()


func _refresh_booster_buttons() -> void:
	for booster_id in stage_popup_booster_buttons.keys():
		var button := stage_popup_booster_buttons[booster_id] as Button
		var selected := selected_pre_boosters.has(String(booster_id))
		button.button_pressed = selected
		button.text = "%s\n%s" % [_booster_title(String(booster_id)), "준비됨" if selected else "장착"]


func _booster_title(booster_id: String) -> String:
	match booster_id:
		"rainbow_paw":
			return "무지개"
		"striped":
			return "줄무늬"
		"bomb":
			return "폭탄"
	return "부스터"


func _on_stage_popup_close_pressed() -> void:
	Feedback.play_ui_tap()
	var tween := create_tween()
	tween.tween_property(stage_popup_overlay, "modulate", Color(1, 1, 1, 0), 0.10)
	tween.parallel().tween_property(stage_popup_panel, "scale", Vector2(0.92, 0.92), 0.10)
	tween.tween_callback(func() -> void:
		stage_popup_overlay.visible = false
		stage_popup_panel.scale = Vector2.ONE
	)


func _on_stage_popup_start_pressed() -> void:
	Feedback.play_ui_tap()
	_commit_stage_popup_selection()
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


func _commit_stage_popup_selection() -> void:
	GameSession.set_selected_stage_id(selected_popup_stage_id)
	GameSession.set_selected_pre_boosters(selected_pre_boosters)


func _refresh_stage_world_layer(stage_def: Dictionary, meta: Dictionary) -> void:
	if stage_world_layer == null:
		return
	var stage_id := int(stage_def.get("id", 1))
	world_title_label.text = "%s" % String(meta.get("title", "구조 작전"))
	world_subtitle_label.text = "Stage %d · %s · 해금 %d/%d · 별 %d" % [
		stage_id,
		String(stage_def.get("difficulty", "Easy")),
		min(GameSession.get_highest_unlocked_stage_id(), stage_defs.size()),
		stage_defs.size(),
		GameSession.get_total_stars(),
	]
	world_selected_label.text = "Level %d · %s" % [
		stage_id,
		String(stage_def.get("difficulty", "Easy")),
	]
	_refresh_world_selected_chips(stage_def)
	_refresh_stage_select_events()
	_rebuild_world_decorations()
	_rebuild_stage_world_nodes()


func _refresh_world_selected_chips(stage_def: Dictionary) -> void:
	if world_selected_goal_chip:
		world_selected_goal_chip.text = "목표  %s" % _build_goal_summary(stage_def).trim_prefix("목표: ")
	if world_selected_moves_chip:
		world_selected_moves_chip.text = "이동  %d" % int(stage_def.get("moves", 0))
	if world_selected_reward_chip:
		world_selected_reward_chip.text = "보상  %dG" % _stage_gold_reward(stage_def)


func _refresh_stage_select_events() -> void:
	if world_event_strip == null:
		return
	for child in world_event_strip.get_children():
		child.queue_free()
	var events := LiveEventService.display_events_for(GameSession.get_highest_unlocked_stage_id(), "stage_select")
	world_event_strip.visible = not events.is_empty()
	var max_visible_events := 1 if MobileLayout.is_portrait(self) else 2
	for index in range(mini(events.size(), max_visible_events)):
		var event := Dictionary(events[index])
		world_event_strip.add_child(_make_stage_select_event_chip(event))
		_track_stage_select_live_event_impression(event)


func _make_stage_select_event_chip(event: Dictionary) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "LiveEventChip_%s" % String(event.get("id", "event"))
	chip.custom_minimum_size = Vector2(218, 58)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _rounded_style(Color(1.0, 0.97, 0.74, 0.90), Color("ff934f"), 22, 3))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 7)
	chip.add_child(margin)

	var label := _make_world_label("%s\n%s · %s" % [String(event.get("title", "이벤트")), _event_status_label(_event_status(event)), _event_type_label(String(event.get("type", "")))], 16, Color("213a55"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(label)
	return chip


func _event_type_label(event_type: String) -> String:
	match event_type:
		"daily_reward":
			return "오늘 보급"
		"starter_missions":
			return "스타터 미션"
		"collection_event":
			return "도감 이벤트"
		"season_pass":
			return "시즌 패스"
	return "라이브 이벤트"


func _event_status(event: Dictionary) -> String:
	var status := String(event.get("status", "")).strip_edges()
	if status.is_empty():
		status = LiveEventService.event_status(event)
	return status


func _event_status_label(status: String) -> String:
	return LiveEventService.status_text({"status": status})


func _track_stage_select_live_event_impression(event: Dictionary) -> void:
	var event_id := String(event.get("id", ""))
	if event_id.is_empty():
		return
	var placement := "stage_select"
	var impression_key := "%s:%s" % [placement, event_id]
	if stage_select_event_impressions_sent.has(impression_key):
		return
	stage_select_event_impressions_sent[impression_key] = true
	GameSession.record_analytics_event("live_event_impression", {
		"session_id": GameSession.get_session_id(),
		"event_id": event_id,
		"event_type": String(event.get("type", "")),
		"placement": placement,
		"unlock_stage": int(event.get("unlock_stage", 0)),
		"enabled": bool(event.get("enabled", false)),
	})


func _rebuild_world_decorations() -> void:
	if world_decor_root == null:
		return
	for child in world_decor_root.get_children():
		child.queue_free()

	var viewport_size := get_viewport_rect().size
	var selected_id := GameSession.get_selected_stage_id()
	var color_shift := selected_id % WORLD_CANDY_COLORS.size()
	_add_world_blob("WorldHillBack", Vector2(-80, viewport_size.y * 0.62), Vector2(viewport_size.x + 180.0, viewport_size.y * 0.30), Color(0.54, 0.92, 0.82, 0.50), Color(0.54, 0.92, 0.82, 0.0), 180, -0.04)
	_add_world_blob("WorldHillFront", Vector2(-120, viewport_size.y * 0.74), Vector2(viewport_size.x + 240.0, viewport_size.y * 0.28), Color(0.86, 0.94, 1.0, 0.72), Color(0.86, 0.94, 1.0, 0.0), 190, 0.035)
	_add_world_blob("WorldCandyLake", Vector2(viewport_size.x * 0.58, viewport_size.y * 0.50), Vector2(viewport_size.x * 0.34, viewport_size.y * 0.17), Color(0.48, 0.70, 1.0, 0.30), Color(0.48, 0.70, 1.0, 0.0), 96, 0.18)

	for index in range(14):
		var color: Color = WORLD_CANDY_COLORS[(index + color_shift) % WORLD_CANDY_COLORS.size()]
		var x_ratio := 0.08 + float((index * 19) % 83) / 100.0
		var y_ratio := 0.16 + float((index * 29) % 70) / 100.0
		var size := 34.0 + float((index * 11) % 42)
		var alpha := 0.16 + float(index % 4) * 0.045
		_add_world_blob(
			"WorldCandyBlob%d" % index,
			Vector2(viewport_size.x * x_ratio, viewport_size.y * y_ratio),
			Vector2(size * 1.35, size),
			Color(color.r, color.g, color.b, alpha),
			Color(1, 1, 1, alpha * 0.72),
			int(size * 0.5),
			-0.42 + float(index % 5) * 0.19
		)

	for index in range(10):
		var sparkle := Label.new()
		sparkle.name = "WorldSparkle%d" % index
		sparkle.text = "✦" if index % 2 == 0 else "●"
		sparkle.position = Vector2(viewport_size.x * (0.06 + float((index * 23) % 88) / 100.0), viewport_size.y * (0.12 + float((index * 31) % 76) / 100.0))
		sparkle.add_theme_font_size_override("font_size", 22 + (index % 3) * 7)
		sparkle.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.35))
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_decor_root.add_child(sparkle)


func _add_world_blob(node_name: String, position: Vector2, size: Vector2, bg_color: Color, border_color: Color, radius: int, rotation_radians: float) -> void:
	var blob := PanelContainer.new()
	blob.name = node_name
	blob.position = position
	blob.size = size
	blob.custom_minimum_size = size
	blob.rotation = rotation_radians
	blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blob.add_theme_stylebox_override("panel", _rounded_style(bg_color, border_color, radius, 2 if border_color.a > 0.0 else 0))
	world_decor_root.add_child(blob)


func _rebuild_stage_world_nodes() -> void:
	if world_path_root == null:
		return
	if current_stage_node_tween != null and current_stage_node_tween.is_valid():
		current_stage_node_tween.kill()
	current_stage_node_tween = null
	world_node_buttons.clear()
	for child in world_path_root.get_children():
		child.queue_free()

	var selected_def := _selected_stage_def()
	var band := String(selected_def.get("band", "1-10"))
	var range_values := _band_stage_range(band)
	var start_id := int(range_values.x)
	var end_id := int(range_values.y)
	var positions := _world_node_positions()

	for index in range(mini(positions.size() - 1, end_id - start_id)):
		_add_world_connector(positions[index], positions[index + 1])

	for index in range(end_id - start_id + 1):
		var stage_id := start_id + index
		var stage_def := _stage_def_by_id(stage_id)
		var node_button := _make_stage_world_node(stage_def, positions[index])
		world_node_buttons.append(node_button)
		world_path_root.add_child(node_button)
		node_button.name = "WorldStageNode%d" % stage_id
		if stage_id == GameSession.get_selected_stage_id():
			call_deferred("_start_current_stage_node_pulse", node_button)


func _world_node_positions() -> Array[Vector2]:
	var viewport_size: Vector2 = get_viewport_rect().size
	var portrait: bool = MobileLayout.is_portrait(self)
	var left: float = 72.0 if portrait else viewport_size.x * 0.15
	var top: float = viewport_size.y * 0.25 if portrait else 246.0
	var width: float = viewport_size.x - left * 2.0
	var bottom_reserved: float = 198.0
	var available_height := viewport_size.y - top - bottom_reserved
	var height: float = viewport_size.y * 0.46 if portrait else clampf(available_height, 520.0, 820.0)
	var positions: Array[Vector2] = []
	for normalized: Vector2 in WORLD_NODE_POSITIONS:
		positions.append(Vector2(left + normalized.x * width, top + normalized.y * height))
	return positions


func _add_world_connector(from_position: Vector2, to_position: Vector2) -> void:
	var delta := to_position - from_position
	var length := delta.length()
	if length <= 0.0:
		return
	var shadow := PanelContainer.new()
	shadow.name = "WorldPathShadow"
	shadow.size = Vector2(length, 24)
	shadow.pivot_offset = Vector2(0, 12)
	shadow.position = from_position + Vector2(3, 7)
	shadow.rotation = delta.angle()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.add_theme_stylebox_override("panel", _rounded_style(Color(0.08, 0.18, 0.32, 0.22), Color(0, 0, 0, 0), 12, 0))
	world_path_root.add_child(shadow)

	var path := PanelContainer.new()
	path.name = "WorldPathConnector"
	path.size = Vector2(length, 15)
	path.pivot_offset = Vector2(0, 7.5)
	path.position = from_position
	path.rotation = delta.angle()
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path.add_theme_stylebox_override("panel", _rounded_style(Color("ffd949"), Color("ff9c24"), 8, 3))
	world_path_root.add_child(path)

	var dot_count := clampi(int(length / 48.0), 2, 7)
	for dot_index in range(dot_count):
		var t := float(dot_index + 1) / float(dot_count + 1)
		var dot := PanelContainer.new()
		dot.size = Vector2(22, 22)
		dot.position = from_position.lerp(to_position, t) - dot.size * 0.5
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_color: Color = WORLD_CANDY_COLORS[(dot_index + dot_count) % WORLD_CANDY_COLORS.size()]
		dot.add_theme_stylebox_override("panel", _rounded_style(dot_color, Color(1, 1, 1, 0.82), 14, 2))
		world_path_root.add_child(dot)
		dot.name = "WorldPathCandyDot%d_%d" % [dot_index, world_path_root.get_child_count()]


func _make_stage_world_node(stage_def: Dictionary, center_position: Vector2) -> Button:
	var stage_id := int(stage_def.get("id", 0))
	var unlocked := GameSession.is_stage_unlocked(stage_id)
	var best_stars := GameSession.get_best_stars(stage_id)
	var current := stage_id == GameSession.get_selected_stage_id()
	var finale := stage_id % 10 == 0
	var portrait := MobileLayout.is_portrait(self)
	var node_size := (112.0 if portrait else 150.0) if not finale else (124.0 if portrait else 166.0)
	if current:
		node_size = 132.0 if portrait else 180.0

	var button := Button.new()
	button.name = "WorldStageNode%d" % stage_id
	button.position = center_position - Vector2(node_size, node_size) * 0.5
	button.size = Vector2(node_size, node_size)
	button.custom_minimum_size = Vector2(node_size, node_size)
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not unlocked
	button.text = ""
	button.add_theme_font_size_override("font_size", 25 if current else 22)
	button.add_theme_color_override("font_color", Color("1f415c") if unlocked else Color("7f8792"))
	button.add_theme_color_override("font_disabled_color", Color("7f8792"))
	button.add_theme_stylebox_override("normal", _stage_node_style(unlocked, current, finale, best_stars))
	button.add_theme_stylebox_override("hover", _stage_node_style(unlocked, true, finale, best_stars))
	button.add_theme_stylebox_override("pressed", _stage_node_style(unlocked, true, finale, best_stars, true))
	button.add_theme_stylebox_override("disabled", _stage_node_style(false, false, finale, best_stars))
	button.pressed.connect(_on_stage_card_pressed.bind(stage_id))
	_add_world_node_content(button, stage_id, unlocked, best_stars, current, finale)

	if not unlocked:
		var lock_center := CenterContainer.new()
		lock_center.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lock_icon := TextureRect.new()
		lock_icon.texture = STAGE_LOCK_TEXTURE
		lock_icon.custom_minimum_size = Vector2(38, 38)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.modulate = Color(1, 1, 1, 0.76)
		lock_center.add_child(lock_icon)
		button.add_child(lock_center)

	return button


func _add_world_node_content(button: Button, stage_id: int, unlocked: bool, best_stars: int, current: bool, finale: bool) -> void:
	if current:
		_add_world_node_current_ring(button)
	if finale:
		_add_world_node_ribbon(button, "WorldNodeFinaleRibbon", "BOSS", Color("8d5cff"), Color("fff2a8"), -14.0)

	var shine := PanelContainer.new()
	shine.name = "WorldNodeShine"
	shine.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shine.offset_left = 14.0
	shine.offset_top = 10.0
	shine.offset_right = -14.0
	shine.offset_bottom = 36.0
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.35 if unlocked else 0.14), Color(1, 1, 1, 0.0), 20, 0))
	button.add_child(shine)

	var number := Label.new()
	number.name = "WorldStageNumber"
	number.set_anchors_preset(Control.PRESET_FULL_RECT)
	number.offset_top = 4.0 if not current else 12.0
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.text = str(stage_id)
	number.add_theme_font_size_override("font_size", int(clampf(button.size.x * (0.32 if current else 0.30), 32.0, 58.0)))
	number.add_theme_color_override("font_color", Color("24405d") if unlocked else Color("8d95a3"))
	number.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.55))
	number.add_theme_constant_override("shadow_offset_y", 2)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(number)

	if current:
		_add_world_node_ribbon(button, "WorldNodePlayRibbon", "PLAY", Color("ff6fae"), Color("ffffff"), -22.0)
	if unlocked and best_stars > 0:
		_add_world_node_star_tray(button, best_stars)
	elif not unlocked:
		_add_world_node_lock_badge(button)


func _add_world_node_current_ring(button: Button) -> void:
	var ui_scale := _world_node_ui_scale(button)
	var ring := PanelContainer.new()
	ring.name = "WorldNodeCurrentRing"
	ring.position = Vector2(-10, -10) * ui_scale
	ring.size = button.size + Vector2(20, 20) * ui_scale
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.0), Color("ff6fae"), int(82 * ui_scale), int(5 * ui_scale)))
	button.add_child(ring)


func _add_world_node_ribbon(button: Button, ribbon_name: String, text: String, bg_color: Color, border_color: Color, y_position: float) -> void:
	var ui_scale := _world_node_ui_scale(button)
	var ribbon := PanelContainer.new()
	ribbon.name = ribbon_name
	var ribbon_size := Vector2(86, 34) * ui_scale
	ribbon.position = Vector2(button.size.x * 0.5 - ribbon_size.x * 0.5, y_position * ui_scale)
	ribbon.size = ribbon_size
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_theme_stylebox_override("panel", _rounded_style(bg_color, border_color, int(18 * ui_scale), int(3 * ui_scale)))
	button.add_child(ribbon)

	var ribbon_label := Label.new()
	ribbon_label.name = "%sLabel" % ribbon_name
	ribbon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	ribbon_label.text = text
	ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ribbon_label.add_theme_font_size_override("font_size", int(15 * ui_scale))
	ribbon_label.add_theme_color_override("font_color", Color("ffffff"))
	ribbon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_child(ribbon_label)


func _add_world_node_star_tray(button: Button, best_stars: int) -> void:
	var ui_scale := _world_node_ui_scale(button)
	var tray := PanelContainer.new()
	tray.name = "WorldNodeStarTray"
	var tray_size := Vector2(86, 30) * ui_scale
	tray.position = Vector2(button.size.x * 0.5 - tray_size.x * 0.5, button.size.y - 23.0 * ui_scale)
	tray.size = tray_size
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_theme_stylebox_override("panel", _rounded_style(Color("fff4bf"), Color("ffbf32"), int(16 * ui_scale), int(3 * ui_scale)))
	button.add_child(tray)

	var tray_label := Label.new()
	tray_label.name = "WorldNodeStarTrayLabel"
	tray_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tray_label.text = _compact_stars_text(best_stars)
	tray_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tray_label.add_theme_font_size_override("font_size", int(16 * ui_scale))
	tray_label.add_theme_color_override("font_color", Color("9a5b00"))
	tray_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray.add_child(tray_label)


func _add_world_node_lock_badge(button: Button) -> void:
	var ui_scale := _world_node_ui_scale(button)
	var badge := PanelContainer.new()
	badge.name = "WorldNodeLockBadge"
	var badge_size := Vector2(78, 28) * ui_scale
	badge.position = Vector2(button.size.x * 0.5 - badge_size.x * 0.5, button.size.y - 24.0 * ui_scale)
	badge.size = badge_size
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _rounded_style(Color(0.84, 0.87, 0.92, 0.92), Color(1, 1, 1, 0.76), int(15 * ui_scale), int(2 * ui_scale)))
	button.add_child(badge)

	var badge_label := Label.new()
	badge_label.name = "WorldNodeLockBadgeLabel"
	badge_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge_label.text = "LOCK"
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", int(13 * ui_scale))
	badge_label.add_theme_color_override("font_color", Color("6c7482"))
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_label)


func _world_node_ui_scale(button: Button) -> float:
	return clampf(button.size.x / 132.0, 0.90, 1.36)


func _compact_stars_text(best_stars: int) -> String:
	if best_stars <= 0:
		return "☆ ☆ ☆"
	var stars := ""
	for index in range(3):
		stars += "★" if index < best_stars else "☆"
	return stars


func _stage_world_node_text(stage_id: int, unlocked: bool, best_stars: int, current: bool) -> String:
	if not unlocked:
		return "\n%d" % stage_id
	if current:
		return "GO\n%d\n%s" % [stage_id, _stage_stars_text(best_stars)]
	if stage_id % 10 == 0:
		return "BOSS\n%d" % stage_id
	return "%d\n%s" % [stage_id, _stage_stars_text(best_stars)]


func _refresh_story_panel() -> void:
	var stage_def := _selected_stage_def()
	var band := String(stage_def.get("band", "1-10"))
	var meta: Dictionary = BAND_META.get(band, {
		"title": "구조 작전",
		"tagline": "스테이지를 골라 구조를 이어가세요.",
		"story": "스테이지를 골라 구조를 이어가세요.",
	})
	story_title_label.text = "%s · %s" % [band, String(meta.get("title", "구조 작전"))]
	story_body_label.text = "%s\n%s\n\n이번 밴드의 10번째 스테이지는 미니 피날레처럼 다룹니다." % [String(meta.get("tagline", "")), String(meta.get("story", ""))]
	selected_stage_label.text = _build_selected_stage_title(stage_def, meta)
	selected_stage_body_label.text = _build_selected_stage_body(stage_def, meta)
	_update_background_for_stage(stage_def)
	header_summary_label.text = "현재 추천 Stage %d · 해금 %d / %d · 누적 별 %d\n카드를 누르면 목표와 부스터를 확인한 뒤 출동합니다." % [
		int(stage_def.get("id", 1)),
		min(GameSession.get_highest_unlocked_stage_id(), stage_defs.size()),
		stage_defs.size(),
		GameSession.get_total_stars(),
	]
	stage_hint_label.text = "월드맵 노드를 따라 구조 작전을 선택하세요.\n현재 강조 스테이지: Stage %d" % int(stage_def.get("id", 1))
	band_route_title_label.text = "%s 진행 노드" % String(meta.get("title", "현재 밴드"))
	_rebuild_band_route(band)
	_rebuild_timeline(band)
	_refresh_stage_world_layer(stage_def, meta)


func _rebuild_timeline(current_band: String) -> void:
	for child in timeline_list.get_children():
		child.queue_free()

	for band in BAND_ORDER:
		var meta: Dictionary = BAND_META.get(band, {})
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 88)
		card.add_theme_stylebox_override("panel", _timeline_stylebox(band == current_band))

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(margin)

		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 4)
		margin.add_child(column)

		var title := Label.new()
		title.text = "%s · %s" % [band, String(meta.get("title", "구조 작전"))]
		title.add_theme_font_size_override("font_size", 18)
		title.add_theme_color_override("font_color", Color("2d516e"))
		column.add_child(title)

		var body := Label.new()
		body.text = "%s\n%s" % [String(meta.get("tagline", "구조 작전을 이어갑니다.")), _band_progress_text(band)]
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 15)
		body.add_theme_color_override("font_color", Color("4f6678"))
		column.add_child(body)

		timeline_list.add_child(card)


func _timeline_stylebox(current: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff6db") if current else Color(1, 1, 1, 0.92)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color("f1ab42") if current else Color("86c3e5")
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	style.shadow_color = Color(0.2, 0.3, 0.4, 0.08)
	style.shadow_size = 6
	return style


func _band_progress_text(band: String) -> String:
	var parts := band.split("-")
	if parts.size() != 2:
		return "구조 작전을 이어갑니다."
	var start_id := int(parts[0])
	var end_id := int(parts[1])
	var cleared := 0
	for stage_id in range(start_id, end_id + 1):
		if GameSession.get_best_stars(stage_id) > 0:
			cleared += 1
	return "클리어 %d / %d" % [cleared, end_id - start_id + 1]


func _rebuild_band_route(current_band: String) -> void:
	for child in band_route_row.get_children():
		child.queue_free()

	var range_values := _band_stage_range(current_band)
	var start_id := int(range_values.x)
	var end_id := int(range_values.y)
	var selected_id := GameSession.get_selected_stage_id()

	for stage_id in range(start_id, end_id + 1):
		if stage_id > start_id:
			var connector := TextureRect.new()
			connector.texture = STORY_PATH_CONNECTOR
			connector.custom_minimum_size = Vector2(38, 22)
			connector.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			connector.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			connector.modulate = Color(1, 1, 1, 0.9)
			band_route_row.add_child(connector)

		var node_button := Button.new()
		node_button.flat = true
		node_button.focus_mode = Control.FOCUS_NONE
		node_button.custom_minimum_size = Vector2(44, 44)
		node_button.disabled = not GameSession.is_stage_unlocked(stage_id)
		node_button.set_meta("stage_id", stage_id)
		node_button.pressed.connect(_on_band_route_node_pressed.bind(stage_id))

		var icon := TextureRect.new()
		icon.texture = _band_route_texture(stage_id, selected_id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(44, 44)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node_button.add_child(icon)

		if stage_id != selected_id and GameSession.is_stage_unlocked(stage_id) and GameSession.get_best_stars(stage_id) <= 0:
			icon.modulate = Color(1, 1, 1, 0.7)
			icon.scale = Vector2(0.92, 0.92)

		var wrapper := VBoxContainer.new()
		wrapper.alignment = BoxContainer.ALIGNMENT_CENTER
		wrapper.add_theme_constant_override("separation", 4)
		wrapper.add_child(node_button)

		var label := Label.new()
		label.text = str(stage_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("4f6678"))
		wrapper.add_child(label)

		band_route_row.add_child(wrapper)


func _band_stage_range(band: String) -> Vector2i:
	var parts := band.split("-")
	if parts.size() != 2:
		return Vector2i(1, 10)
	return Vector2i(int(parts[0]), int(parts[1]))


func _band_route_texture(stage_id: int, selected_id: int) -> Texture2D:
	if not GameSession.is_stage_unlocked(stage_id):
		return STORY_PATH_NODE_LOCKED
	if stage_id == selected_id:
		return STORY_PATH_NODE_CURRENT
	if GameSession.get_best_stars(stage_id) > 0:
		return STORY_PATH_NODE_CLEARED
	return STORY_PATH_NODE_CURRENT


func _on_band_route_node_pressed(stage_id: int) -> void:
	if not GameSession.is_stage_unlocked(stage_id):
		return
	_on_stage_card_pressed(stage_id)


func _selected_stage_def() -> Dictionary:
	var selected_id := GameSession.get_selected_stage_id()
	for stage_def in stage_defs:
		if int(stage_def.get("id", 0)) == selected_id:
			return stage_def
	return stage_defs[0]


func _update_background_for_stage(stage_def: Dictionary) -> void:
	var theme_key := String(stage_def.get("theme_key", "meadow_1"))
	var stage_id := int(stage_def.get("id", 1))
	match theme_key:
		"meadow_1":
			background_texture.texture = DEFAULT_BG
		"meadow_2":
			background_texture.texture = BG_BAND_02_SUB if stage_id >= 19 else BG_BAND_02
		"meadow_3":
			background_texture.texture = BG_BAND_03
		"forest_edge_1":
			background_texture.texture = BG_BAND_04
		"garden_1":
			background_texture.texture = BG_BAND_05
		"garden_2":
			background_texture.texture = BG_BAND_06
		"night_shade_1":
			background_texture.texture = BG_BAND_07
		"skyline_1":
			background_texture.texture = BG_BAND_08
		"skyline_2":
			background_texture.texture = BG_BAND_09
		"finale_1":
			background_texture.texture = BG_BAND_10
		_:
			background_texture.texture = DEFAULT_BG


func _build_goal_summary(stage_def: Dictionary) -> String:
	var targets: Dictionary = Dictionary(stage_def.get("target_collect", {}))
	var parts: Array[String] = []
	for animal_id in targets.keys():
		parts.append("%s %d" % [_animal_name(String(animal_id)), int(targets[animal_id])])
	var target_score := int(stage_def.get("target_score", 0))
	if target_score > 0:
		parts.append("점수 %d" % target_score)
	var target_blockers := int(stage_def.get("target_blockers", 0))
	if target_blockers > 0:
		parts.append("덤불 %d" % target_blockers)
	if parts.is_empty():
		return "이번 구조 목표를 준비 중입니다."
	return "목표: %s" % ", ".join(parts)


func _build_selected_stage_title(stage_def: Dictionary, meta: Dictionary) -> String:
	var stage_id := int(stage_def.get("id", 0))
	var is_tutorial := not String(stage_def.get("tutorial", "")).is_empty()
	var tutorial_badge := " · [튜토리얼]" if is_tutorial else ""
	if stage_id == 100:
		return "Stage 100 · 거대한 코끼리 구출%s" % tutorial_badge
	if stage_id % 10 == 0:
		return "%s 피날레 · %s%s" % [String(meta.get("title", "피날레")), String(stage_def.get("name", "Stage")), tutorial_badge]
	return "%s · %s · 이동 %d%s" % [
		String(stage_def.get("name", "Stage")),
		String(stage_def.get("difficulty", "Easy")),
		int(stage_def.get("moves", 0)),
		tutorial_badge,
	]


func _build_selected_stage_body(stage_def: Dictionary, meta: Dictionary) -> String:
	var stage_id := int(stage_def.get("id", 0))
	var goal_summary := _build_goal_summary(stage_def).trim_prefix("목표: ")
	var best_stars := GameSession.get_best_stars(stage_id)
	var record_text := ""
	if best_stars > 0:
		var stars := ""
		for _i in range(best_stars):
			stars += "★"
		record_text = " · 최고 %s" % stars
	var theme_text := _theme_display_name(String(stage_def.get("theme_key", "meadow_1")))
	var recommended := GameSession.get_selected_stage_id() == stage_id
	var meta_parts: Array[String] = []
	if not theme_text.is_empty():
		meta_parts.append(theme_text)
	if recommended:
		meta_parts.append("추천")
	var meta_line := " · ".join(meta_parts)
	if stage_id == 100:
		return "마지막 구조 작전입니다.\n%s / 연쇄와 특수 블록을 계획적으로 사용하세요%s" % [goal_summary, record_text]
	if stage_id % 10 == 0:
		var body := "%s / 다음 구역을 여는 마지막 구조입니다%s" % [goal_summary, record_text]
		if not meta_line.is_empty():
			body += "\n%s" % meta_line
		return body
	var body := "%s / %s%s" % [goal_summary, _short_hint(String(stage_def.get("tutorial", ""))), record_text]
	if not meta_line.is_empty():
		body += "\n%s" % meta_line
	return body


func _short_hint(source_text: String) -> String:
	var text := source_text.strip_edges()
	if text.is_empty():
		return "카드를 누르면 바로 출동합니다"
	if text.length() <= 34:
		return text
	return "%s..." % text.substr(0, 31)


func _focus_selected_stage_card() -> void:
	if stage_grid.get_child_count() == 0:
		return
	var selected_index: int = clampi(GameSession.get_selected_stage_id() - 1, 0, maxi(stage_grid.get_child_count() - 1, 0))
	var card: Control = stage_grid.get_child(selected_index)
	await get_tree().process_frame
	stage_scroll.scroll_vertical = maxi(0, int(card.position.y) - 80)


func _animal_name(animal_id: String) -> String:
	match animal_id:
		"rabbit":
			return "토끼"
		"bear":
			return "곰"
		"cat":
			return "고양이"
		"chick":
			return "병아리"
		"frog":
			return "개구리"
		"dog":
			return "강아지"
		"panda":
			return "판다"
		"pig":
			return "돼지"
		"penguin":
			return "펭귄"
		"fox":
			return "여우"
		"lion":
			return "사자"
		"elephant":
			return "코끼리"
		_:
			return animal_id


func _theme_display_name(theme_key: String) -> String:
	match theme_key:
		"meadow_1":
			return "테마: 초원"
		"meadow_2":
			return "테마: 초원 심화"
		"meadow_3":
			return "테마: 초원 끝자락"
		"forest_edge_1":
			return "테마: 숲 경계"
		"garden_1":
			return "테마: 정원 1"
		"garden_2":
			return "테마: 정원 2"
		"night_shade_1":
			return "테마: 야간 그늘"
		"skyline_1":
			return "테마: 스카이라인 1"
		"skyline_2":
			return "테마: 스카이라인 2"
		"finale_1":
			return "테마: 피날레"
		_:
			return ""


func _start_map_ambient_animations() -> void:
	for tween in map_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	map_tweens.clear()
	_float_map_mascot(map_rabbit, 14.0, 1.35)
	_float_map_mascot(map_chick, 10.0, 1.08)


func _float_map_mascot(target: Control, distance: float, duration: float) -> void:
	if target == null or not is_inside_tree():
		return
	target.pivot_offset = target.size * 0.5
	var base_y := target.position.y
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "position:y", base_y - distance, duration)
	tween.tween_property(target, "position:y", base_y + distance * 0.34, duration)
	tween.tween_property(target, "position:y", base_y, duration * 0.7)
	map_tweens.append(tween)


func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	var portrait := MobileLayout.is_portrait(self)
	MobileLayout.apply_safe_area(safe_margin, self, 16 if portrait else 14)
	var viewport_size := get_viewport_rect().size
	layout_root.visible = false
	if stage_world_layer:
		stage_world_layer.visible = true
	layout_root.add_theme_constant_override("separation", 16 if portrait else 22)
	content_root.vertical = portrait
	content_root.add_theme_constant_override("separation", 16 if portrait else 20)
	stage_grid.columns = 4 if portrait else 7
	stage_grid.add_theme_constant_override("h_separation", 14 if portrait else 18)
	stage_grid.add_theme_constant_override("v_separation", 16 if portrait else 20)
	_layout_stage_popup(portrait, viewport_size)
	_layout_stage_world_layer(portrait)
	_refresh_stage_select_events()
	_layout_map_juice_layer(portrait)
	header_panel.custom_minimum_size = Vector2.ZERO if portrait else Vector2(0, 170)
	story_panel.custom_minimum_size = Vector2(0, 420) if portrait else Vector2(420, 0)
	stage_panel.custom_minimum_size = Vector2(0, 760) if portrait else Vector2(0, 0)
	home_button.custom_minimum_size = Vector2(180, 72) if portrait else Vector2(220, 78)


func _layout_stage_popup(portrait: bool, viewport_size: Vector2) -> void:
	if stage_popup_panel == null:
		return

	if portrait:
		stage_popup_panel.custom_minimum_size = Vector2(minf(viewport_size.x - 56.0, 760.0), minf(viewport_size.y - 130.0, 740.0))
		if stage_popup_margin:
			stage_popup_margin.add_theme_constant_override("margin_left", 28)
			stage_popup_margin.add_theme_constant_override("margin_top", 26)
			stage_popup_margin.add_theme_constant_override("margin_right", 28)
			stage_popup_margin.add_theme_constant_override("margin_bottom", 26)
		if stage_popup_column:
			stage_popup_column.add_theme_constant_override("separation", 12)
		stage_popup_title_label.add_theme_font_size_override("font_size", 40)
		stage_popup_goal_label.custom_minimum_size = Vector2(0, 104)
		stage_popup_goal_label.add_theme_font_size_override("font_size", 28)
		stage_popup_meta_label.add_theme_font_size_override("font_size", 24)
		stage_popup_reward_label.custom_minimum_size = Vector2(0, 66)
		stage_popup_reward_label.add_theme_font_size_override("font_size", 23)
		stage_popup_buddy_label.custom_minimum_size = Vector2(0, 84)
		stage_popup_buddy_label.add_theme_font_size_override("font_size", 22)
		if stage_popup_close_button:
			stage_popup_close_button.custom_minimum_size = Vector2(72, 72)
			stage_popup_close_button.add_theme_font_size_override("font_size", 34)
		if stage_popup_booster_row:
			stage_popup_booster_row.add_theme_constant_override("separation", 10)
		for booster_button_value in stage_popup_booster_buttons.values():
			var booster_button := booster_button_value as Button
			if booster_button:
				booster_button.custom_minimum_size = Vector2(156, 108)
				booster_button.add_theme_font_size_override("font_size", 20)
		if stage_popup_start_button:
			stage_popup_start_button.custom_minimum_size = Vector2(0, 96)
			stage_popup_start_button.add_theme_font_size_override("font_size", 40)
	else:
		stage_popup_panel.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.58, 1800.0, 2360.0), minf(viewport_size.y - 100.0, 1500.0))
		if stage_popup_margin:
			stage_popup_margin.add_theme_constant_override("margin_left", 72)
			stage_popup_margin.add_theme_constant_override("margin_top", 54)
			stage_popup_margin.add_theme_constant_override("margin_right", 72)
			stage_popup_margin.add_theme_constant_override("margin_bottom", 54)
		if stage_popup_column:
			stage_popup_column.add_theme_constant_override("separation", 24)
		stage_popup_title_label.add_theme_font_size_override("font_size", 82)
		stage_popup_goal_label.custom_minimum_size = Vector2(0, 154)
		stage_popup_goal_label.add_theme_font_size_override("font_size", 52)
		stage_popup_meta_label.add_theme_font_size_override("font_size", 44)
		stage_popup_reward_label.custom_minimum_size = Vector2(0, 106)
		stage_popup_reward_label.add_theme_font_size_override("font_size", 44)
		stage_popup_buddy_label.custom_minimum_size = Vector2(0, 144)
		stage_popup_buddy_label.add_theme_font_size_override("font_size", 40)
		if stage_popup_close_button:
			stage_popup_close_button.custom_minimum_size = Vector2(132, 132)
			stage_popup_close_button.add_theme_font_size_override("font_size", 58)
		if stage_popup_booster_row:
			stage_popup_booster_row.add_theme_constant_override("separation", 24)
		for booster_button_value in stage_popup_booster_buttons.values():
			var booster_button := booster_button_value as Button
			if booster_button:
				booster_button.custom_minimum_size = Vector2(420, 220)
				booster_button.add_theme_font_size_override("font_size", 40)
		if stage_popup_start_button:
			stage_popup_start_button.custom_minimum_size = Vector2(0, 220)
			stage_popup_start_button.add_theme_font_size_override("font_size", 72)


func _layout_stage_world_layer(portrait: bool) -> void:
	if stage_world_layer == null:
		return
	var viewport_size := get_viewport_rect().size
	if world_title_label:
		world_title_label.add_theme_font_size_override("font_size", 60 if portrait else 68)
	if world_subtitle_label:
		world_subtitle_label.add_theme_font_size_override("font_size", 24 if portrait else 28)
	if world_selected_label:
		world_selected_label.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * (0.014 if portrait else 0.022), 23.0 if portrait else 36.0, 30.0 if portrait else 48.0)))
	if world_selected_chip_row:
		world_selected_chip_row.add_theme_constant_override("separation", 6 if portrait else 14)
	for chip in [world_selected_goal_chip, world_selected_moves_chip, world_selected_reward_chip]:
		if chip == null:
			continue
		chip.custom_minimum_size = Vector2(0, clampf(viewport_size.y * (0.056 if portrait else 0.104), 52.0 if portrait else 112.0, 68.0 if portrait else 136.0))
		chip.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * (0.012 if portrait else 0.024), 18.0 if portrait else 34.0, 22.0 if portrait else 44.0)))
	if world_play_button:
		if portrait:
			world_play_button.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.24, 250.0, 320.0), clampf(viewport_size.y * 0.052, 112.0, 126.0))
			world_play_button.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.020, 34.0, 42.0)))
		else:
			world_play_button.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.24, 820.0, 1040.0), clampf(viewport_size.y * 0.132, 230.0, 286.0))
			world_play_button.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.040, 64.0, 82.0)))
	var selected_panel = stage_world_layer.find_child("WorldSelectedPanel", true, false) as PanelContainer
	if selected_panel != null:
		if portrait:
			selected_panel.offset_left = 22.0
			selected_panel.offset_top = -186.0
			selected_panel.offset_right = -22.0
			selected_panel.offset_bottom = -18.0
		else:
			selected_panel.offset_left = 72.0
			selected_panel.offset_top = -clampf(viewport_size.y * 0.28, 456.0, 540.0)
			selected_panel.offset_right = -72.0
			selected_panel.offset_bottom = -42.0
		var margin := selected_panel.get_child(0) as MarginContainer
		if margin != null:
			var horizontal := 22 if portrait else 56
			var vertical := 10 if portrait else 30
			margin.add_theme_constant_override("margin_left", horizontal)
			margin.add_theme_constant_override("margin_top", vertical)
			margin.add_theme_constant_override("margin_right", horizontal)
			margin.add_theme_constant_override("margin_bottom", vertical)
		var selected_column := selected_panel.find_child("WorldSelectedInfoColumn", true, false) as VBoxContainer
		if selected_column:
			selected_column.add_theme_constant_override("separation", 5 if portrait else 12)
	if world_event_strip:
		var strip_width := minf(viewport_size.x - 48.0, 226.0 if portrait else 460.0)
		world_event_strip.offset_left = -strip_width - (24.0 if portrait else 34.0)
		world_event_strip.offset_top = 104.0 if portrait else 112.0
		world_event_strip.offset_right = -24.0 if portrait else -34.0
		world_event_strip.offset_bottom = 170.0 if portrait else 178.0
	_rebuild_world_decorations()
	_rebuild_stage_world_nodes()


func _layout_map_juice_layer(portrait: bool) -> void:
	if map_juice_layer == null:
		return
	var viewport_size := get_viewport_rect().size
	var rabbit_height := viewport_size.y * (0.28 if portrait else 0.32)
	var chick_height := viewport_size.y * (0.20 if portrait else 0.26)
	if map_rabbit:
		map_rabbit.size = Vector2(rabbit_height * 0.78, rabbit_height)
		map_rabbit.position = Vector2(-map_rabbit.size.x * 0.28, viewport_size.y - map_rabbit.size.y - (120.0 if portrait else 70.0))
	if map_chick:
		map_chick.size = Vector2(chick_height * 0.84, chick_height)
		map_chick.position = Vector2(viewport_size.x - map_chick.size.x * 0.68, 98.0 if portrait else 132.0)
