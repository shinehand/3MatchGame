extends Control

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const GameSession = preload("res://scripts/game_session.gd")
const STAGE_CARD_SCENE = preload("res://scenes/stage_card.tscn")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const DEFAULT_BG = preload("res://assets/backgrounds/stage_meadow_bg_v1.png")
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
	_rebuild_stage_grid()
	_refresh_story_panel()
	call_deferred("_focus_selected_stage_card")
	call_deferred("_apply_responsive_layout")


func _on_home_button_pressed() -> void:
	Feedback.play_ui_tap()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _rebuild_stage_grid() -> void:
	for child in stage_grid.get_children():
		child.queue_free()

	for stage_def in stage_defs:
		var stage_id := int(stage_def.get("id", 0))
		var card = STAGE_CARD_SCENE.instantiate()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup(stage_def, GameSession.is_stage_unlocked(stage_id), GameSession.get_best_stars(stage_id))
		card.stage_selected.connect(_on_stage_card_pressed)
		stage_grid.add_child(card)


func _on_stage_card_pressed(stage_id: int) -> void:
	if not GameSession.is_stage_unlocked(stage_id):
		return
	Feedback.play_ui_tap()
	GameSession.set_selected_stage_id(stage_id)
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
	header_summary_label.text = "현재 추천 Stage %d · 해금 %d / %d · 누적 별 %d\n카드를 누르면 바로 해당 스테이지로 출동합니다." % [
		int(stage_def.get("id", 1)),
		min(GameSession.get_highest_unlocked_stage_id(), stage_defs.size()),
		stage_defs.size(),
		GameSession.get_total_stars(),
	]
	stage_hint_label.text = "스토리 라인을 따라 스테이지를 선택하세요.\n현재 강조 스테이지: Stage %d" % int(stage_def.get("id", 1))
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
		wrapper.theme_override_constants.separation = 4
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
	if stage_id == 100:
		return "Stage 100 · 거대한 코끼리 구출"
	if stage_id % 10 == 0:
		return "%s 피날레 · %s" % [String(meta.get("title", "피날레")), String(stage_def.get("name", "Stage"))]
	return "%s · %s · 이동 %d" % [
		String(stage_def.get("name", "Stage")),
		String(stage_def.get("difficulty", "Easy")),
		int(stage_def.get("moves", 0)),
	]


func _build_selected_stage_body(stage_def: Dictionary, meta: Dictionary) -> String:
	var stage_id := int(stage_def.get("id", 0))
	var goal_summary := _build_goal_summary(stage_def).trim_prefix("목표: ")
	if stage_id == 100:
		return "마지막 구조 작전입니다.\n%s / 연쇄와 특수 블록을 계획적으로 사용하세요" % goal_summary
	if stage_id % 10 == 0:
		return "%s / 다음 구역을 여는 마지막 구조입니다" % goal_summary
	return "%s / %s" % [goal_summary, _short_hint(String(stage_def.get("tutorial", "")))]


func _short_hint(source_text: String) -> String:
	var text := source_text.strip_edges()
	if text.is_empty():
		return "카드를 누르면 바로 출동합니다"
	if text.length() <= 34:
		return text
	return "%s..." % text.substr(0, 31)


func _focus_selected_stage_card() -> void:
	var selected_index := clamp(GameSession.get_selected_stage_id() - 1, 0, max(stage_grid.get_child_count() - 1, 0))
	if stage_grid.get_child_count() == 0:
		return
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
		_:
			return animal_id


func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	var portrait := MobileLayout.is_portrait(self)
	MobileLayout.apply_safe_area(safe_margin, self, 16 if portrait else 14)
	layout_root.add_theme_constant_override("separation", 16 if portrait else 22)
	content_root.vertical = portrait
	content_root.add_theme_constant_override("separation", 16 if portrait else 20)
	stage_grid.columns = 2 if portrait else 4
	header_panel.custom_minimum_size = Vector2.ZERO if portrait else Vector2(0, 170)
	story_panel.custom_minimum_size = Vector2(0, 420) if portrait else Vector2(420, 0)
	stage_panel.custom_minimum_size = Vector2(0, 760) if portrait else Vector2(0, 0)
	home_button.custom_minimum_size = Vector2(180, 72) if portrait else Vector2(220, 78)
