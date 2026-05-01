extends Control

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const GameSession = preload("res://scripts/game_session.gd")
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
var stage_popup_overlay: ColorRect
var stage_popup_panel: PanelContainer
var stage_popup_title_label: Label
var stage_popup_goal_label: Label
var stage_popup_meta_label: Label
var stage_popup_reward_label: Label
var stage_popup_booster_buttons: Dictionary = {}


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
		if int(stage_def.get("id", 0)) == GameSession.get_selected_stage_id():
			call_deferred("_start_current_stage_node_pulse", node_button)


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
		bg_color = Color(0.92, 0.93, 0.96, 0.78)
		border_color = Color(0.70, 0.75, 0.82, 0.92)
	elif current:
		bg_color = Color("fff0a6") if not pressed else Color("ffd45a")
		border_color = Color("ff8f26")
	elif finale:
		bg_color = Color("ffe4f0")
		border_color = Color("ff74a8")
	elif best_stars > 0:
		bg_color = Color("d9fff0")
		border_color = Color("2dc78b")
	else:
		bg_color = Color("f4fbff")
		border_color = Color("54c7ff")

	var style := _rounded_style(bg_color, border_color, 62, 5 if current else 4)
	style.shadow_color = Color(0.09, 0.22, 0.32, 0.20 if unlocked else 0.08)
	style.shadow_size = 12 if unlocked else 5
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
	stage_popup_panel.add_theme_stylebox_override("panel", _rounded_style(Color(1.0, 0.98, 0.90, 0.98), Color(1.0, 0.77, 0.18, 1.0), 34, 8))
	center.add_child(stage_popup_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	stage_popup_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	stage_popup_title_label = _make_popup_label("Level Ready", 38, Color("213a55"), HORIZONTAL_ALIGNMENT_LEFT)
	stage_popup_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(stage_popup_title_label)

	var close_button := Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(72, 72)
	close_button.add_theme_font_size_override("font_size", 34)
	close_button.add_theme_color_override("font_color", Color("213a55"))
	close_button.add_theme_stylebox_override("normal", _rounded_style(Color(1, 1, 1, 0.66), Color("86c3e5"), 22, 3))
	close_button.add_theme_stylebox_override("hover", _rounded_style(Color("e9fbff"), Color("6ec6ff"), 22, 3))
	close_button.add_theme_stylebox_override("pressed", _rounded_style(Color("d8f6ff"), Color("6ec6ff"), 22, 3))
	close_button.pressed.connect(_on_stage_popup_close_pressed)
	header.add_child(close_button)

	stage_popup_goal_label = _make_popup_label("목표", 26, Color("513d30"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_goal_label.custom_minimum_size = Vector2(0, 104)
	stage_popup_goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stage_popup_goal_label)

	stage_popup_meta_label = _make_popup_label("이동 · 난이도", 24, Color("2f617d"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stage_popup_meta_label)

	stage_popup_reward_label = _make_popup_label("보상", 24, Color("7a4d11"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_popup_reward_label.custom_minimum_size = Vector2(0, 76)
	stage_popup_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(stage_popup_reward_label)

	var booster_title := _make_popup_label("시작 부스터", 28, Color("213a55"), HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(booster_title)

	var booster_row := HBoxContainer.new()
	booster_row.alignment = BoxContainer.ALIGNMENT_CENTER
	booster_row.add_theme_constant_override("separation", 12)
	column.add_child(booster_row)
	for booster_id in ["rainbow_paw", "striped", "bomb"]:
		var button := _make_booster_button(booster_id)
		stage_popup_booster_buttons[booster_id] = button
		booster_row.add_child(button)

	var start_button := Button.new()
	start_button.text = "START"
	start_button.custom_minimum_size = Vector2(0, 92)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.add_theme_font_size_override("font_size", 36)
	start_button.add_theme_color_override("font_color", Color("6a3e07"))
	start_button.add_theme_stylebox_override("normal", _rounded_style(Color("ffd85a"), Color("f28c26"), 28, 5))
	start_button.add_theme_stylebox_override("hover", _rounded_style(Color("ffe67d"), Color("f28c26"), 28, 5))
	start_button.add_theme_stylebox_override("pressed", _rounded_style(Color("ffbf42"), Color("f28c26"), 28, 5))
	start_button.pressed.connect(_on_stage_popup_start_pressed)
	column.add_child(start_button)


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
	return style


func _show_stage_popup(stage_id: int) -> void:
	selected_popup_stage_id = stage_id
	selected_pre_boosters = []
	var stage_def := _stage_def_by_id(stage_id)
	stage_popup_title_label.text = "Level %d · %s" % [stage_id, String(stage_def.get("name", "Stage"))]
	stage_popup_goal_label.text = _build_stage_popup_goal_text(stage_def)
	stage_popup_meta_label.text = "이동 %d회 · 난이도 %s · %s" % [
		int(stage_def.get("moves", 0)),
		String(stage_def.get("difficulty", "Easy")),
		_theme_display_name(String(stage_def.get("theme_key", "meadow_1"))),
	]
	stage_popup_reward_label.text = "클리어 보상  골드 %d · 별 최대 3개 · 다음 구조 노드 해금" % _stage_gold_reward(stage_def)
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
	var targets: Dictionary = Dictionary(stage_def.get("target_collect", {}))
	for animal_id in targets.keys():
		lines.append("%s %d마리 구조" % [_animal_name(String(animal_id)), int(targets[animal_id])])
	var target_score := int(stage_def.get("target_score", 0))
	if target_score > 0:
		lines.append("점수 %d 달성" % target_score)
	var target_blockers := int(stage_def.get("target_blockers", 0))
	if target_blockers > 0:
		lines.append("덤불 %d개 제거" % target_blockers)
	return "\n".join(lines)


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
		button.text = "%s\n%s" % [_booster_title(String(booster_id)), "장착됨" if selected else "탭해서 장착"]


func _booster_title(booster_id: String) -> String:
	match booster_id:
		"rainbow_paw":
			return "무지개 발바닥"
		"striped":
			return "줄무늬 동물"
		"bomb":
			return "폭탄 동물"
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
	GameSession.set_selected_stage_id(selected_popup_stage_id)
	GameSession.set_selected_pre_boosters(selected_pre_boosters)
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


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
	layout_root.add_theme_constant_override("separation", 16 if portrait else 22)
	content_root.vertical = portrait
	content_root.add_theme_constant_override("separation", 16 if portrait else 20)
	stage_grid.columns = 4 if portrait else 7
	stage_grid.add_theme_constant_override("h_separation", 14 if portrait else 18)
	stage_grid.add_theme_constant_override("v_separation", 16 if portrait else 20)
	if stage_popup_panel:
		stage_popup_panel.custom_minimum_size = Vector2(700, 760) if portrait else Vector2(720, 720)
	_layout_map_juice_layer(portrait)
	header_panel.custom_minimum_size = Vector2.ZERO if portrait else Vector2(0, 170)
	story_panel.custom_minimum_size = Vector2(0, 420) if portrait else Vector2(420, 0)
	stage_panel.custom_minimum_size = Vector2(0, 760) if portrait else Vector2(0, 0)
	home_button.custom_minimum_size = Vector2(180, 72) if portrait else Vector2(220, 78)


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
