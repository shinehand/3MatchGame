extends Control

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const GameSession = preload("res://scripts/game_session.gd")
const STAGE_CARD_SCENE = preload("res://scenes/stage_card.tscn")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const LiveEventService = preload("res://scripts/live_event_service.gd")
const HOME_RABBIT_TEXTURE := preload("res://assets/generated/polish/home_mascot_rabbit_clean.png")
const HOME_CHICK_TEXTURE := preload("res://assets/generated/polish/home_mascot_chick_clean.png")
const HOME_MAX_ACTIVE_PREVIEW_EXPRESSIONS := 4
const HOME_ANIMAL_PREVIEW_IDS := [
	"rabbit",
	"bear",
	"cat",
	"chick",
	"frog",
	"dog",
	"panda",
	"pig",
	"penguin",
	"fox",
	"lion",
	"elephant",
]
const ANIMAL_PREVIEW_TEXTURES := [
	preload("res://assets/generated/candy/rabbit_candy_block.png"),
	preload("res://assets/generated/candy/bear_candy_block.png"),
	preload("res://assets/generated/candy/cat_candy_block.png"),
	preload("res://assets/generated/candy/chick_candy_block.png"),
	preload("res://assets/generated/candy/frog_candy_block.png"),
	preload("res://assets/generated/candy/dog_candy_block.png"),
	preload("res://assets/generated/candy/panda_candy_block.png"),
	preload("res://assets/generated/candy/pig_candy_block.png"),
	preload("res://assets/generated/candy/penguin_candy_block.png"),
	preload("res://assets/generated/candy/fox_candy_block.png"),
	preload("res://assets/generated/candy/lion_candy_block.png"),
	preload("res://assets/generated/candy/elephant_candy_block.png"),
]

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var layout_root: BoxContainer = $SafeMargin/LayoutRoot
@onready var left_mascots: VBoxContainer = $SafeMargin/LayoutRoot/LeftMascots
@onready var right_mascots: VBoxContainer = $SafeMargin/LayoutRoot/RightMascots
@onready var center_column: VBoxContainer = $SafeMargin/LayoutRoot/CenterColumn
@onready var logo_card: PanelContainer = $SafeMargin/LayoutRoot/CenterColumn/LogoCard
@onready var logo_frame: TextureRect = $SafeMargin/LayoutRoot/CenterColumn/LogoCard/LogoFrame
@onready var title_label: Label = $SafeMargin/LayoutRoot/CenterColumn/LogoCard/LogoMargin/LogoColumn/Title
@onready var subtitle_label: Label = $SafeMargin/LayoutRoot/CenterColumn/LogoCard/LogoMargin/LogoColumn/Subtitle
@onready var preview_strip: HBoxContainer = $SafeMargin/LayoutRoot/CenterColumn/PreviewStrip
@onready var buttons_column: VBoxContainer = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn
@onready var play_button: Button = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/PlayButton
@onready var secondary_buttons: BoxContainer = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/SecondaryButtons
@onready var stage_button: Button = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/SecondaryButtons/StageButton
@onready var ranking_button: Button = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/SecondaryButtons/RankingButton
@onready var exit_button: Button = $SafeMargin/LayoutRoot/CenterColumn/ExitButton
@onready var info_card: PanelContainer = $SafeMargin/LayoutRoot/CenterColumn/InfoCard
@onready var info_label: Label = $SafeMargin/LayoutRoot/CenterColumn/InfoCard/InfoMargin/InfoLabel
@onready var stage_overlay: ColorRect = $StageOverlay
@onready var stage_overlay_panel: PanelContainer = $StageOverlay/OverlayCenter/OverlayPanel
@onready var stage_summary_label: Label = $StageOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/StageSummaryLabel
@onready var stage_grid: GridContainer = $StageOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/StageScroll/StageGrid
@onready var settings_overlay: ColorRect = $SettingsOverlay
@onready var settings_overlay_panel: PanelContainer = $SettingsOverlay/OverlayCenter/OverlayPanel
@onready var settings_summary_label: Label = $SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsSummaryLabel
@onready var sound_toggle_button: Button = $SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsButtons/SoundToggleButton
@onready var haptics_toggle_button: Button = $SettingsOverlay/OverlayCenter/OverlayPanel/OverlayMargin/OverlayColumn/SettingsButtons/HapticsToggleButton

var stage_defs: Array = []
var _home_tweens: Array[Tween] = []
var _home_preview_tweens: Array[Tween] = []
var _home_active_preview_ids: Array[String] = []
var game_home_layer: Control
var home_play_button: Button
var home_status_label: Label
var home_title_label: Label
var home_subtitle_label: Label
var home_action_panel: PanelContainer
var home_rabbit: TextureRect
var home_chick: TextureRect
var home_animal_strip: HBoxContainer
var home_event_strip: HBoxContainer
var home_nav_row: HBoxContainer
var home_path_root: Control
var event_detail_overlay: ColorRect
var event_detail_panel: PanelContainer
var event_detail_title_label: Label
var event_detail_body_label: Label
var event_claim_button: Button
var _home_event_impressions_sent := {}
var _selected_event: Dictionary = {}


func _ready() -> void:
	GameSession.load_state()
	GameSession.apply_feedback_preferences()
	stage_defs = StageCatalog.get_stages()
	resized.connect(_queue_layout_refresh)
	get_window().size_changed.connect(_queue_layout_refresh)
	_build_game_home_layer()
	_build_event_detail_overlay()
	_apply_home_art_direction()
	_update_home_status()
	call_deferred("_start_home_animations")
	call_deferred("_apply_responsive_layout")


func _on_play_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
	settings_overlay.visible = false
	if event_detail_overlay:
		event_detail_overlay.visible = false
	GameSession.set_selected_stage_id(GameSession.get_continue_stage_id())
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _on_stage_button_pressed() -> void:
	Feedback.play_ui_tap()
	settings_overlay.visible = false
	stage_overlay.visible = false
	if event_detail_overlay:
		event_detail_overlay.visible = false
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _on_ranking_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
	settings_overlay.visible = false
	if event_detail_overlay:
		event_detail_overlay.visible = false
	get_tree().change_scene_to_file("res://scenes/collection_screen.tscn")


func _on_stage_overlay_close_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
	_update_home_status()


func _on_settings_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
	if event_detail_overlay:
		event_detail_overlay.visible = false
	_refresh_settings_overlay()
	settings_overlay.visible = true


func _on_settings_overlay_close_button_pressed() -> void:
	Feedback.play_ui_tap()
	settings_overlay.visible = false
	_update_home_status()


func _on_sound_toggle_button_pressed() -> void:
	Feedback.play_ui_tap()
	GameSession.set_sound_enabled(not GameSession.get_sound_enabled())
	GameSession.apply_feedback_preferences()
	_refresh_settings_overlay()
	_update_home_status()


func _on_haptics_toggle_button_pressed() -> void:
	Feedback.play_ui_tap()
	GameSession.set_haptics_enabled(not GameSession.get_haptics_enabled())
	GameSession.apply_feedback_preferences()
	_refresh_settings_overlay()
	_update_home_status()


func _on_exit_button_pressed() -> void:
	Feedback.play_ui_tap()
	if OS.has_feature("editor"):
		info_label.text = "에디터 실행 중이라 종료 대신 홈 화면 상태를 유지합니다."
		return
	get_tree().quit()


func _update_home_status() -> void:
	var continue_stage_id: int = GameSession.get_continue_stage_id()
	var unlocked: int = min(GameSession.get_highest_unlocked_stage_id(), stage_defs.size())
	play_button.text = "PLAY"
	stage_button.text = "맵"
	ranking_button.text = "도감"
	if home_play_button:
		home_play_button.text = "PLAY"
	info_card.visible = false
	info_label.text = "Stage %d 준비 완료 · 해금 %d / %d · 클리어 %d · 별 %d · 사운드 %s · 햅틱 %s" % [
		continue_stage_id,
		unlocked,
		stage_defs.size(),
		GameSession.get_cleared_count(),
		GameSession.get_total_stars(),
		"ON" if GameSession.get_sound_enabled() else "OFF",
		"ON" if GameSession.get_haptics_enabled() else "OFF",
	]
	if home_status_label:
		home_status_label.text = "Lv.%d 준비 완료   해금 %d/%d   클리어 %d   별 %d" % [
			continue_stage_id,
			unlocked,
			stage_defs.size(),
			GameSession.get_cleared_count(),
			GameSession.get_total_stars(),
		]
	_refresh_home_events()


func _best_score_stage_id() -> int:
	var best_stage_id := 1
	var best_score := -1
	for stage_def in stage_defs:
		var stage_id := int(stage_def.get("id", 1))
		var stage_score := GameSession.get_best_score(stage_id)
		if stage_score > best_score:
			best_score = stage_score
			best_stage_id = stage_id
	return best_stage_id


func _best_score_value() -> int:
	return GameSession.get_best_score(_best_score_stage_id())


func _rebuild_stage_grid() -> void:
	for child in stage_grid.get_children():
		child.queue_free()

	var unlocked: int = min(GameSession.get_highest_unlocked_stage_id(), stage_defs.size())
	stage_summary_label.text = "해금 %d / %d\n클리어 %d, 누적 별 %d" % [
		unlocked,
		stage_defs.size(),
		GameSession.get_cleared_count(),
		GameSession.get_total_stars(),
	]

	for stage_def in stage_defs:
		var stage_id := int(stage_def.get("id", 0))
		var button = STAGE_CARD_SCENE.instantiate()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var is_unlocked := GameSession.is_stage_unlocked(stage_id)
		var best_stars: int = GameSession.get_best_stars(stage_id)
		button.setup(stage_def, is_unlocked, best_stars)
		button.stage_selected.connect(_on_stage_card_pressed)
		stage_grid.add_child(button)
	_apply_responsive_layout()


func _on_stage_card_pressed(stage_id: int) -> void:
	if not GameSession.is_stage_unlocked(stage_id):
		return
	Feedback.play_ui_tap()
	GameSession.set_selected_stage_id(stage_id)
	stage_overlay.visible = false
	get_tree().change_scene_to_file("res://scenes/gameplay.tscn")


func _refresh_settings_overlay() -> void:
	settings_summary_label.text = "사운드와 햅틱은 홈에서 바로 조정하고 저장됩니다.\n현재 값은 다음 플레이부터 그대로 유지됩니다."
	sound_toggle_button.text = "사운드: %s" % ("ON" if GameSession.get_sound_enabled() else "OFF")
	haptics_toggle_button.text = "햅틱: %s" % ("ON" if GameSession.get_haptics_enabled() else "OFF")


func _build_game_home_layer() -> void:
	if game_home_layer:
		return

	game_home_layer = Control.new()
	game_home_layer.name = "GameHomeLayer"
	game_home_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_home_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(game_home_layer)
	move_child(game_home_layer, stage_overlay.get_index())

	var sky_shade := ColorRect.new()
	sky_shade.name = "SkyShade"
	sky_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_shade.color = Color(0.05, 0.28, 0.50, 0.08)
	sky_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_home_layer.add_child(sky_shade)

	var bottom_glow := ColorRect.new()
	bottom_glow.name = "CandyStageGlow"
	bottom_glow.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_glow.offset_top = -260.0
	bottom_glow.color = Color(1.0, 0.58, 0.34, 0.20)
	bottom_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_home_layer.add_child(bottom_glow)

	home_rabbit = _make_mascot("RabbitHero", HOME_RABBIT_TEXTURE)
	game_home_layer.add_child(home_rabbit)
	home_chick = _make_mascot("ChickHero", HOME_CHICK_TEXTURE)
	game_home_layer.add_child(home_chick)

	home_path_root = Control.new()
	home_path_root.name = "LevelPathPreview"
	home_path_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	home_path_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_home_layer.add_child(home_path_root)
	for index in range(6):
		home_path_root.add_child(_make_path_node(index))

	var top_hud := HBoxContainer.new()
	top_hud.name = "TopHud"
	top_hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_hud.offset_left = 24.0
	top_hud.offset_top = 18.0
	top_hud.offset_right = -24.0
	top_hud.offset_bottom = 94.0
	top_hud.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hud.add_theme_constant_override("separation", 12)
	game_home_layer.add_child(top_hud)
	top_hud.add_child(_make_home_badge("♥", "5"))
	top_hud.add_child(_make_home_badge("●", str(120 + GameSession.get_total_stars() * 15)))
	top_hud.add_child(_make_home_badge("★", str(GameSession.get_total_stars())))
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hud.add_child(top_spacer)
	var settings_button := _make_home_icon_button("⚙")
	settings_button.name = "HomeTopSettingsButton"
	settings_button.tooltip_text = "설정"
	settings_button.pressed.connect(_on_settings_button_pressed)
	top_hud.add_child(settings_button)

	var hero_stack := VBoxContainer.new()
	hero_stack.name = "HeroStack"
	hero_stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_stack.offset_left = 28.0
	hero_stack.offset_top = 110.0
	hero_stack.offset_right = -28.0
	hero_stack.offset_bottom = -138.0
	hero_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_stack.add_theme_constant_override("separation", 12)
	game_home_layer.add_child(hero_stack)

	var title_stack := VBoxContainer.new()
	title_stack.name = "TitleStack"
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 2)
	hero_stack.add_child(title_stack)

	home_title_label = _make_home_label("Zoo-Zoo\nPOP", 94, Color(1.0, 0.93, 0.22, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	home_title_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.20, 0.42, 0.78))
	home_title_label.add_theme_constant_override("shadow_offset_y", 8)
	title_stack.add_child(home_title_label)

	home_subtitle_label = _make_home_label("ANIMAL CANDY PUZZLE", 24, Color(1, 1, 1, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	home_subtitle_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.20, 0.42, 0.55))
	home_subtitle_label.add_theme_constant_override("shadow_offset_y", 4)
	title_stack.add_child(home_subtitle_label)

	var hero_spacer := Control.new()
	hero_spacer.custom_minimum_size = Vector2(0, 62)
	hero_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_stack.add_child(hero_spacer)

	home_action_panel = PanelContainer.new()
	home_action_panel.name = "HomeActionPanel"
	home_action_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home_action_panel.add_theme_stylebox_override("panel", _home_style(Color(1, 1, 1, 0.76), Color(1.0, 0.86, 0.28, 0.96), 32, 4))
	hero_stack.add_child(home_action_panel)

	var action_margin := MarginContainer.new()
	action_margin.name = "HomeActionMargin"
	action_margin.add_theme_constant_override("margin_left", 20)
	action_margin.add_theme_constant_override("margin_top", 16)
	action_margin.add_theme_constant_override("margin_right", 20)
	action_margin.add_theme_constant_override("margin_bottom", 16)
	home_action_panel.add_child(action_margin)

	var action_column := VBoxContainer.new()
	action_column.name = "HomeActionColumn"
	action_column.alignment = BoxContainer.ALIGNMENT_CENTER
	action_column.add_theme_constant_override("separation", 8)
	action_margin.add_child(action_column)

	home_play_button = _make_home_play_button()
	home_play_button.pressed.connect(_on_play_button_pressed)
	action_column.add_child(home_play_button)

	home_status_label = _make_home_label("Lv.1 준비 완료", 22, Color(1.0, 1.0, 1.0, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	home_status_label.add_theme_color_override("font_color", Color(0.12, 0.24, 0.34, 1))
	action_column.add_child(home_status_label)

	home_animal_strip = HBoxContainer.new()
	home_animal_strip.name = "AnimalStrip"
	home_animal_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	home_animal_strip.add_theme_constant_override("separation", 8)
	action_column.add_child(home_animal_strip)
	for index in range(ANIMAL_PREVIEW_TEXTURES.size()):
		home_animal_strip.add_child(_make_animal_token(ANIMAL_PREVIEW_TEXTURES[index], HOME_ANIMAL_PREVIEW_IDS[index]))

	home_event_strip = HBoxContainer.new()
	home_event_strip.name = "LiveEventStrip"
	home_event_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	home_event_strip.add_theme_constant_override("separation", 8)
	action_column.add_child(home_event_strip)

	home_nav_row = HBoxContainer.new()
	home_nav_row.name = "BottomNav"
	home_nav_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	home_nav_row.offset_left = 22.0
	home_nav_row.offset_top = -112.0
	home_nav_row.offset_right = -22.0
	home_nav_row.offset_bottom = -22.0
	home_nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	home_nav_row.add_theme_constant_override("separation", 12)
	game_home_layer.add_child(home_nav_row)
	var map_button := _make_home_icon_button("맵")
	map_button.name = "HomeMapButton"
	map_button.pressed.connect(_on_stage_button_pressed)
	home_nav_row.add_child(map_button)
	var ranking_nav_button := _make_home_icon_button("도감")
	ranking_nav_button.name = "HomeCollectionButton"
	ranking_nav_button.pressed.connect(_on_ranking_button_pressed)
	home_nav_row.add_child(ranking_nav_button)
	var settings_nav_button := _make_home_icon_button("설정")
	settings_nav_button.name = "HomeSettingsButton"
	settings_nav_button.pressed.connect(_on_settings_button_pressed)
	home_nav_row.add_child(settings_nav_button)


func _build_event_detail_overlay() -> void:
	if event_detail_overlay:
		return

	event_detail_overlay = ColorRect.new()
	event_detail_overlay.name = "EventDetailOverlay"
	event_detail_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	event_detail_overlay.color = Color(0.05, 0.13, 0.24, 0.70)
	event_detail_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	event_detail_overlay.visible = false
	add_child(event_detail_overlay)

	var overlay_center := CenterContainer.new()
	overlay_center.name = "OverlayCenter"
	overlay_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_center.mouse_filter = Control.MOUSE_FILTER_STOP
	event_detail_overlay.add_child(overlay_center)

	event_detail_panel = PanelContainer.new()
	event_detail_panel.name = "OverlayPanel"
	event_detail_panel.custom_minimum_size = Vector2(760, 640)
	event_detail_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	event_detail_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	event_detail_panel.add_theme_stylebox_override("panel", _home_style(Color(1.0, 0.98, 0.90, 0.98), Color(1.0, 0.63, 0.18, 1), 30, 5))
	overlay_center.add_child(event_detail_panel)

	var margin := MarginContainer.new()
	margin.name = "OverlayMargin"
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	event_detail_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.name = "OverlayColumn"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var top_row := HBoxContainer.new()
	top_row.name = "EventDetailHeader"
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 12)
	column.add_child(top_row)

	event_detail_title_label = _make_home_label("라이브 이벤트", 36, Color(0.12, 0.23, 0.34, 1), HORIZONTAL_ALIGNMENT_LEFT)
	event_detail_title_label.name = "EventDetailTitleLabel"
	event_detail_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(event_detail_title_label)

	var close_button := _make_home_icon_button("닫기")
	close_button.name = "EventDetailCloseButton"
	close_button.custom_minimum_size = Vector2(122, 64)
	close_button.pressed.connect(_on_event_detail_close_button_pressed)
	top_row.add_child(close_button)

	event_detail_body_label = _make_home_label("", 24, Color(0.22, 0.26, 0.30, 1), HORIZONTAL_ALIGNMENT_LEFT)
	event_detail_body_label.name = "EventDetailBodyLabel"
	event_detail_body_label.custom_minimum_size = Vector2(0, 340)
	event_detail_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_detail_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	event_detail_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	column.add_child(event_detail_body_label)

	event_claim_button = Button.new()
	event_claim_button.name = "EventClaimButton"
	event_claim_button.text = "보상 받기"
	event_claim_button.custom_minimum_size = Vector2(0, 88)
	event_claim_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_claim_button.add_theme_font_size_override("font_size", 30)
	event_claim_button.add_theme_color_override("font_color", Color(0.40, 0.22, 0.02, 1))
	event_claim_button.add_theme_color_override("font_disabled_color", Color(0.36, 0.39, 0.42, 0.74))
	event_claim_button.add_theme_stylebox_override("normal", _home_style(Color(1.0, 0.84, 0.22, 1), Color(0.98, 0.46, 0.10, 1), 26, 5))
	event_claim_button.add_theme_stylebox_override("hover", _home_style(Color(1.0, 0.91, 0.34, 1), Color(0.98, 0.46, 0.10, 1), 26, 5))
	event_claim_button.add_theme_stylebox_override("pressed", _home_style(Color(1.0, 0.65, 0.18, 1), Color(0.86, 0.30, 0.08, 1), 26, 5))
	event_claim_button.add_theme_stylebox_override("disabled", _home_style(Color(0.82, 0.85, 0.86, 0.92), Color(0.62, 0.68, 0.72, 0.9), 26, 4))
	event_claim_button.pressed.connect(_on_event_claim_button_pressed)
	column.add_child(event_claim_button)


func _make_mascot(node_name: String, texture: Texture2D) -> TextureRect:
	var mascot := TextureRect.new()
	mascot.name = node_name
	mascot.texture = texture
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascot.modulate = Color(1, 1, 1, 0.98)
	mascot.set_meta("expression_source", "home")
	mascot.set_meta("expression_state", "idle")
	return mascot


func _make_home_badge(label_text: String, value_text: String) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(112, 56)
	badge.add_theme_stylebox_override("panel", _home_style(Color(1, 1, 1, 0.84), Color(1, 0.86, 0.28, 0.92), 22, 3))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	badge.add_child(margin)
	var label := _make_home_label("%s  %s" % [label_text, value_text], 20, Color(0.13, 0.23, 0.34, 1), HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(label)
	return badge


func _make_home_play_button() -> Button:
	var button := Button.new()
	button.name = "HomePlayButton"
	button.text = "PLAY"
	button.custom_minimum_size = Vector2(420, 126)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 46)
	button.add_theme_color_override("font_color", Color(0.42, 0.23, 0.02, 1))
	button.add_theme_stylebox_override("normal", _home_style(Color(1.0, 0.84, 0.22, 1), Color(0.98, 0.46, 0.10, 1), 36, 6))
	button.add_theme_stylebox_override("hover", _home_style(Color(1.0, 0.91, 0.34, 1), Color(0.98, 0.46, 0.10, 1), 36, 6))
	button.add_theme_stylebox_override("pressed", _home_style(Color(1.0, 0.65, 0.18, 1), Color(0.86, 0.30, 0.08, 1), 36, 6))
	return button


func _make_path_node(index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "PathNode%d" % (index + 1)
	panel.custom_minimum_size = Vector2(72, 72)
	var current := index == 0
	var cleared := index < 3
	var bg_color := Color(1.0, 0.86, 0.24, 0.94) if current else Color(1, 1, 1, 0.74)
	var border_color := Color(1.0, 0.45, 0.10, 1.0) if current else Color(0.42, 0.78, 1.0, 0.92)
	if cleared and not current:
		bg_color = Color(0.42, 0.94, 0.62, 0.84)
		border_color = Color(0.21, 0.72, 0.42, 0.94)
	panel.add_theme_stylebox_override("panel", _home_style(bg_color, border_color, 36, 4))

	var center := CenterContainer.new()
	panel.add_child(center)
	var label_text := "GO" if current else str(index + 1)
	var label := _make_home_label(label_text, 24, Color(0.10, 0.23, 0.34, 1), HORIZONTAL_ALIGNMENT_CENTER)
	label.name = "PathNodeLabel"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.add_child(label)
	return panel


func _make_home_icon_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(134, 70)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color(0.08, 0.22, 0.34, 1))
	button.add_theme_stylebox_override("normal", _home_style(Color(1, 1, 1, 0.84), Color(0.50, 0.78, 0.94, 1), 24, 4))
	button.add_theme_stylebox_override("hover", _home_style(Color(0.91, 0.98, 1.0, 0.94), Color(0.36, 0.76, 0.97, 1), 24, 4))
	button.add_theme_stylebox_override("pressed", _home_style(Color(1.0, 0.78, 0.90, 0.96), Color(0.96, 0.38, 0.61, 1), 24, 4))
	return button


func _refresh_home_events() -> void:
	if home_event_strip == null:
		return
	for child in home_event_strip.get_children():
		child.queue_free()
	var events := LiveEventService.display_events_for(GameSession.get_highest_unlocked_stage_id(), "home")
	home_event_strip.visible = not events.is_empty()
	var max_visible_events := 1 if MobileLayout.is_portrait(self) else 2
	for index in range(mini(events.size(), max_visible_events)):
		var event := Dictionary(events[index])
		home_event_strip.add_child(_make_home_event_chip(event))
		_track_live_event_impression(event, "home")


func _make_home_event_chip(event: Dictionary) -> Button:
	var chip := Button.new()
	chip.name = "LiveEventChip_%s" % String(event.get("id", "event"))
	chip.text = "%s\n%s · %s" % [String(event.get("title", "이벤트")), _event_status_label(_event_status(event)), _event_type_label(String(event.get("type", "")))]
	chip.custom_minimum_size = Vector2(236, 60)
	chip.add_theme_font_size_override("font_size", 16)
	chip.add_theme_color_override("font_color", Color(0.14, 0.22, 0.31, 1))
	chip.add_theme_stylebox_override("normal", _home_style(Color(1.0, 0.97, 0.72, 0.86), Color(0.96, 0.48, 0.16, 0.94), 22, 3))
	chip.add_theme_stylebox_override("hover", _home_style(Color(1.0, 0.99, 0.82, 0.96), Color(1.0, 0.55, 0.19, 1), 22, 3))
	chip.add_theme_stylebox_override("pressed", _home_style(Color(1.0, 0.86, 0.48, 0.96), Color(0.92, 0.38, 0.11, 1), 22, 3))
	chip.pressed.connect(_show_event_detail.bind(event))
	return chip


func _show_event_detail(event: Dictionary) -> void:
	_selected_event = Dictionary(event)
	var event_id := String(_selected_event.get("id", ""))
	var event_type := String(_selected_event.get("type", ""))
	if not event_id.is_empty() and _is_event_claimable(_selected_event) and _game_session_has_method("join_live_event"):
		GameSession.join_live_event(event_id, event_type, "home")

	stage_overlay.visible = false
	settings_overlay.visible = false
	event_detail_title_label.text = String(_selected_event.get("title", "라이브 이벤트"))
	event_detail_body_label.text = _build_event_detail_body(_selected_event)
	_refresh_event_claim_button()
	event_detail_overlay.visible = true
	Feedback.play_ui_tap()


func _on_event_claim_button_pressed() -> void:
	if _selected_event.is_empty():
		return
	Feedback.play_ui_tap()
	var event_id := String(_selected_event.get("id", ""))
	var event_type := String(_selected_event.get("type", ""))
	if event_id.is_empty() or not _is_event_claimable(_selected_event):
		_refresh_event_claim_button()
		return
	var reward_id := "%s:main" % event_id
	var claimed := false
	var reward := _event_claim_reward(_selected_event)
	if reward.is_empty():
		_refresh_event_claim_button()
		return
	if _game_session_has_method("claim_live_event_reward"):
		claimed = GameSession.claim_live_event_reward(event_id, reward_id, event_type, "home", reward)
	if claimed:
		_refresh_event_claim_button()


func _on_event_detail_close_button_pressed() -> void:
	Feedback.play_ui_tap()
	event_detail_overlay.visible = false
	_update_home_status()


func _refresh_event_claim_button() -> void:
	var event_id := String(_selected_event.get("id", ""))
	var reward_id := "%s:main" % event_id
	var status := _event_status(_selected_event)
	if not _is_event_claimable(_selected_event):
		event_claim_button.text = _event_unavailable_button_text(status)
		event_claim_button.disabled = true
		return
	var reward := _event_claim_reward(_selected_event)
	if reward.is_empty():
		event_claim_button.text = "진행 보상 준비"
		event_claim_button.disabled = true
		return
	var claimed := false
	if not event_id.is_empty() and _game_session_has_method("is_live_event_reward_claimed"):
		claimed = GameSession.is_live_event_reward_claimed(event_id, reward_id)
	if not _game_session_has_method("claim_live_event_reward"):
		event_claim_button.text = "보상 준비 중"
		event_claim_button.disabled = true
		return
	event_claim_button.text = "수령 완료" if claimed else "보상 받기"
	event_claim_button.disabled = claimed


func _build_event_detail_body(event: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("종류  %s" % _event_type_label(String(event.get("type", ""))))
	lines.append("상태  %s" % _event_status_label(_event_status(event)))
	lines.append("기간  %s" % _event_window_text(event))
	lines.append("진행  %s" % _event_progress_text(event))
	lines.append("보상  %s" % _event_reward_summary(event))
	lines.append("")
	lines.append(_event_status_body_line(_event_status(event)))
	return "\n".join(lines)


func _event_window_text(event: Dictionary) -> String:
	var start_text := String(event.get("start_at", event.get("start", "")))
	var end_text := String(event.get("end_at", event.get("end", "")))
	if start_text.is_empty() and int(event.get("starts_at_unix", 0)) > 0:
		start_text = _event_unix_date_text(int(event.get("starts_at_unix", 0)))
	if end_text.is_empty() and int(event.get("ends_at_unix", 0)) > 0:
		end_text = _event_unix_date_text(int(event.get("ends_at_unix", 0)))
	if not start_text.is_empty() and not end_text.is_empty():
		return "%s ~ %s" % [start_text, end_text]
	if not end_text.is_empty():
		return "%s까지" % end_text
	return "상시 진행"


func _event_progress_text(event: Dictionary) -> String:
	match _event_status(event):
		"offline":
			return "저장된 정보로 확인 가능"
		"upcoming":
			return "시작 후 진행 가능"
		"ended":
			return "이벤트 종료"
		"disabled":
			return "운영 중지"
	var event_type := String(event.get("type", ""))
	if event.has("missions"):
		var missions: Array = event.get("missions", [])
		return "미션 %d개 준비" % missions.size()
	if event.has("featured_animals"):
		var animals: Array = event.get("featured_animals", [])
		return "추천 동물 %d종 구조 보너스" % animals.size()
	if event_type == "season_pass":
		return "무료/프리미엄 트랙 진행"
	return "참여 가능"


func _event_reward_summary(event: Dictionary) -> String:
	if event.has("reward"):
		return _reward_dictionary_summary(Dictionary(event.get("reward", {})))
	if event.has("missions"):
		var rewards: Array[String] = []
		for mission_value in Array(event.get("missions", [])):
			if not (mission_value is Dictionary):
				continue
			var mission := Dictionary(mission_value)
			if mission.has("reward_gold"):
				rewards.append("골드 %d" % int(mission.get("reward_gold", 0)))
			if mission.has("reward_booster"):
				rewards.append("%s x%d" % [String(mission.get("reward_booster", "부스터")), int(mission.get("reward_booster_count", 1))])
		if not rewards.is_empty():
			return " · ".join(rewards)
	if event.has("free_track_rewards"):
		return "무료 트랙 %d개 · 프리미엄 트랙 %d개" % [
			Array(event.get("free_track_rewards", [])).size(),
			Array(event.get("premium_track_rewards", [])).size(),
		]
	return "이벤트 보상 준비 중"


func _event_status(event: Dictionary) -> String:
	var status := String(event.get("status", "")).strip_edges()
	if status.is_empty():
		status = LiveEventService.event_status(event)
	return status


func _event_status_label(status: String) -> String:
	return LiveEventService.status_text({"status": status})


func _event_status_body_line(status: String) -> String:
	match status:
		"active":
			return "홈에서 참여 중인 구조 이벤트입니다. 조건을 달성하면 보상을 받을 수 있습니다."
		"offline":
			return "네트워크가 불안정해도 저장된 보상 정보로 이어서 확인할 수 있습니다."
		"upcoming":
			return "아직 시작 전인 이벤트입니다. 시작 후 참여와 보상 수령이 열립니다."
		"ended":
			return "종료된 이벤트입니다. 다음 구조 이벤트를 기다려 주세요."
		"disabled":
			return "현재 운영에서 잠시 내려간 이벤트입니다."
	return "이벤트 상태를 확인하는 중입니다."


func _event_unavailable_button_text(status: String) -> String:
	match status:
		"upcoming":
			return "시작 전"
		"ended":
			return "종료됨"
		"disabled":
			return "운영 중지"
	return "보상 대기"


func _is_event_claimable(event: Dictionary) -> bool:
	return ["active", "offline"].has(_event_status(event))


func _event_unix_date_text(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	var date := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d" % [int(date.get("year", 0)), int(date.get("month", 0)), int(date.get("day", 0))]


func _event_claim_reward(event: Dictionary) -> Dictionary:
	if event.has("reward"):
		return Dictionary(event.get("reward", {}))
	if not event.has("missions"):
		return {}

	var reward := {}
	var boosters := {}
	for mission_value in Array(event.get("missions", [])):
		if not (mission_value is Dictionary):
			continue
		var mission := Dictionary(mission_value)
		if mission.has("reward_gold"):
			reward["gold"] = int(reward.get("gold", 0)) + int(mission.get("reward_gold", 0))
		var booster_id := String(mission.get("reward_booster", ""))
		if not booster_id.is_empty():
			boosters[booster_id] = int(boosters.get(booster_id, 0)) + max(1, int(mission.get("reward_booster_count", 1)))
	if not boosters.is_empty():
		reward["boosters"] = boosters
	return reward


func _reward_dictionary_summary(reward: Dictionary) -> String:
	var parts: Array[String] = []
	if reward.has("gold"):
		parts.append("골드 %d" % int(reward.get("gold", 0)))
	if reward.has("tokens"):
		parts.append("토큰 %d" % int(reward.get("tokens", 0)))
	if reward.has("booster"):
		parts.append("%s x%d" % [String(reward.get("booster", "부스터")), int(reward.get("booster_count", 1))])
	if parts.is_empty():
		return "이벤트 보상"
	return " · ".join(parts)


func _game_session_has_method(method_name: String) -> bool:
	return GameSession.new().has_method(method_name)


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


func _track_live_event_impression(event: Dictionary, placement: String) -> void:
	var event_id := String(event.get("id", ""))
	if event_id.is_empty():
		return
	var impression_key := "%s:%s" % [placement, event_id]
	if _home_event_impressions_sent.has(impression_key):
		return
	_home_event_impressions_sent[impression_key] = true
	GameSession.record_analytics_event("live_event_impression", {
		"session_id": GameSession.get_session_id(),
		"event_id": event_id,
		"event_type": String(event.get("type", "")),
		"placement": placement,
		"unlock_stage": int(event.get("unlock_stage", 0)),
		"enabled": bool(event.get("enabled", false)),
	})


func _make_home_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_animal_token(texture: Texture2D, animal_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "HomeAnimalToken_%s" % animal_id
	panel.custom_minimum_size = Vector2(62, 62)
	panel.add_theme_stylebox_override("panel", _home_style(Color(1, 1, 1, 0.66), Color(1, 0.86, 0.26, 0.88), 18, 3))
	var center := CenterContainer.new()
	panel.add_child(center)
	var icon := TextureRect.new()
	icon.name = "HomeAnimalPreview"
	icon.texture = texture
	icon.custom_minimum_size = Vector2(50, 50)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_meta("animal_id", animal_id)
	icon.set_meta("expression_state", "idle")
	icon.set_meta("expression_source", "home")
	center.add_child(icon)
	return panel


func _home_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
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
	style.shadow_color = Color(0.08, 0.16, 0.24, 0.22)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


func _apply_home_art_direction() -> void:
	layout_root.visible = false
	_make_panel_float(logo_card)
	logo_frame.visible = false
	title_label.text = "Zoo-Zoo Pop"
	title_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.38, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.25, 0.42, 0.72))
	title_label.add_theme_constant_override("shadow_offset_x", 0)
	title_label.add_theme_constant_override("shadow_offset_y", 6)
	subtitle_label.text = "동물 캔디를 팡팡 터뜨려 구조 작전을 완성하세요"
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.94))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.25, 0.42, 0.48))
	subtitle_label.add_theme_constant_override("shadow_offset_y", 3)

	for panel_path in [
		"SafeMargin/LayoutRoot/LeftMascots/RabbitCard",
		"SafeMargin/LayoutRoot/LeftMascots/ChickCard",
		"SafeMargin/LayoutRoot/RightMascots/BearCard",
		"SafeMargin/LayoutRoot/RightMascots/CatCard",
	]:
		var panel := get_node_or_null(panel_path) as PanelContainer
		if panel:
			_make_panel_float(panel)

	for frame_path in [
		"SafeMargin/LayoutRoot/LeftMascots/RabbitCard/RabbitFrame",
		"SafeMargin/LayoutRoot/LeftMascots/ChickCard/ChickFrame",
		"SafeMargin/LayoutRoot/RightMascots/BearCard/BearFrame",
		"SafeMargin/LayoutRoot/RightMascots/CatCard/CatFrame",
	]:
		var frame := get_node_or_null(frame_path) as CanvasItem
		if frame:
			frame.visible = false


func _make_panel_float(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)


func _start_home_animations() -> void:
	for tween in _home_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_home_tweens.clear()
	_stop_home_preview_expressions()

	if home_play_button:
		_pulse_control(home_play_button, Vector2(1.0, 1.0), Vector2(1.055, 1.055), 0.78)
	else:
		_pulse_control(play_button, Vector2(1.0, 1.0), Vector2(1.055, 1.055), 0.78)
	if home_rabbit:
		_set_preview_expression_state(home_rabbit, "smile")
	if home_chick:
		_set_preview_expression_state(home_chick, "blink")
	var float_targets := [
		home_rabbit,
		home_chick,
		get_node_or_null("SafeMargin/LayoutRoot/LeftMascots/RabbitCard/RabbitCenter/RabbitIcon"),
		get_node_or_null("SafeMargin/LayoutRoot/LeftMascots/ChickCard/ChickCenter/ChickIcon"),
		get_node_or_null("SafeMargin/LayoutRoot/RightMascots/BearCard/BearCenter/BearIcon"),
		get_node_or_null("SafeMargin/LayoutRoot/RightMascots/CatCard/CatCenter/CatIcon"),
	]
	for index in range(float_targets.size()):
		var target := float_targets[index] as Control
		if target:
			_float_control(target, 10.0 + float(index % 2) * 4.0, 1.15 + float(index) * 0.08)
	_start_home_preview_expressions()


func _stop_home_preview_expressions() -> void:
	for tween in _home_preview_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_home_preview_tweens.clear()
	_home_active_preview_ids.clear()
	if home_animal_strip == null:
		return
	for child in home_animal_strip.get_children():
		var preview := child.find_child("HomeAnimalPreview", true, false) as TextureRect
		if preview != null:
			preview.scale = Vector2.ONE
			preview.modulate = Color(1, 1, 1, 1)
			preview.set_meta("expression_state", "idle")


func _start_home_preview_expressions() -> void:
	if home_animal_strip == null or not home_animal_strip.visible:
		return
	var animated := 0
	for child in home_animal_strip.get_children():
		if animated >= HOME_MAX_ACTIVE_PREVIEW_EXPRESSIONS:
			break
		var child_control := child as Control
		if child_control != null and not child_control.visible:
			continue
		var preview := child.find_child("HomeAnimalPreview", true, false) as TextureRect
		if preview == null:
			continue
		var animal_id := String(preview.get_meta("animal_id", ""))
		_set_preview_expression_state(preview, "blink")
		_home_preview_tweens.append(_start_preview_expression_loop(preview, animated))
		_home_active_preview_ids.append(animal_id)
		animated += 1


func _start_preview_expression_loop(preview: TextureRect, stagger_index: int) -> Tween:
	preview.pivot_offset = preview.size * 0.5
	var base_modulate := Color(1, 1, 1, 1)
	var smile_modulate := Color(1.10, 1.08, 1.03, 1)
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.12 * float(stagger_index))
	tween.tween_callback(_set_preview_expression_state.bind(preview, "blink"))
	tween.tween_property(preview, "scale", Vector2(1.02, 0.86), 0.08)
	tween.tween_property(preview, "scale", Vector2.ONE, 0.10)
	tween.tween_callback(_set_preview_expression_state.bind(preview, "smile"))
	tween.tween_property(preview, "scale", Vector2(1.07, 1.07), 0.34)
	tween.parallel().tween_property(preview, "modulate", smile_modulate, 0.18)
	tween.tween_property(preview, "scale", Vector2.ONE, 0.42)
	tween.parallel().tween_property(preview, "modulate", base_modulate, 0.42)
	tween.tween_callback(_set_preview_expression_state.bind(preview, "idle"))
	tween.tween_interval(0.75)
	return tween


func _set_preview_expression_state(preview: TextureRect, expression_id: String) -> void:
	if preview == null:
		return
	preview.set_meta("expression_state", expression_id)


func _home_preview_expression_count_for_testing() -> int:
	return _home_preview_tweens.size()


func _home_preview_expression_ids_for_testing() -> Array:
	return _home_active_preview_ids.duplicate()


func _home_preview_expression_states_for_testing() -> Dictionary:
	var states := {}
	if home_animal_strip == null:
		return states
	for child in home_animal_strip.get_children():
		var child_control := child as Control
		if child_control != null and not child_control.visible:
			continue
		var preview := child.find_child("HomeAnimalPreview", true, false) as TextureRect
		if preview == null:
			continue
		var animal_id := String(preview.get_meta("animal_id", ""))
		if not animal_id.is_empty():
			states[animal_id] = String(preview.get_meta("expression_state", ""))
	return states


func _home_mascot_expression_states_for_testing() -> Dictionary:
	return {
		"rabbit": String(home_rabbit.get_meta("expression_state", "")) if home_rabbit != null else "",
		"chick": String(home_chick.get_meta("expression_state", "")) if home_chick != null else "",
	}


func _pulse_control(control: Control, base_scale: Vector2, peak_scale: Vector2, duration: float) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "scale", peak_scale, duration)
	tween.tween_property(control, "scale", base_scale, duration)
	_home_tweens.append(tween)


func _float_control(control: Control, distance: float, duration: float) -> void:
	control.pivot_offset = control.size * 0.5
	var base_y := control.position.y
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(control, "position:y", base_y - distance, duration)
	tween.tween_property(control, "position:y", base_y + distance * 0.38, duration)
	tween.tween_property(control, "position:y", base_y, duration * 0.65)
	_home_tweens.append(tween)


func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	var portrait := MobileLayout.is_portrait(self)
	MobileLayout.apply_safe_area(safe_margin, self, 18 if portrait else 14)
	_layout_game_home(portrait)

	layout_root.vertical = portrait
	layout_root.add_theme_constant_override("separation", 18 if portrait else 24)
	secondary_buttons.visible = true
	exit_button.visible = false
	secondary_buttons.vertical = false
	secondary_buttons.alignment = BoxContainer.ALIGNMENT_CENTER

	left_mascots.visible = not portrait
	right_mascots.visible = not portrait
	preview_strip.visible = portrait
	preview_strip.custom_minimum_size = Vector2(0, 100) if portrait else Vector2.ZERO
	center_column.alignment = BoxContainer.ALIGNMENT_CENTER
	center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons_column.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo_card.custom_minimum_size = Vector2(0, 250 if portrait else 280)
	title_label.add_theme_font_size_override("font_size", 76 if portrait else 92)
	subtitle_label.add_theme_font_size_override("font_size", 24 if portrait else 30)
	play_button.custom_minimum_size = Vector2(460, 138) if portrait else Vector2(580, 148)
	exit_button.custom_minimum_size = Vector2(0 if portrait else 220, 82)

	stage_grid.columns = 2 if portrait else 3
	stage_overlay_panel.custom_minimum_size = Vector2(760, 1040) if portrait else Vector2(1120, 760)
	settings_overlay_panel.custom_minimum_size = Vector2(760, 780) if portrait else Vector2(920, 620)
	if event_detail_panel:
		event_detail_panel.custom_minimum_size = Vector2(700, 760) if portrait else Vector2(820, 620)
	if event_detail_body_label:
		event_detail_body_label.custom_minimum_size = Vector2(0, 400) if portrait else Vector2(0, 320)


func _layout_game_home(portrait: bool) -> void:
	if game_home_layer == null:
		return
	var viewport_size := get_viewport_rect().size
	var mascot_height := viewport_size.y * (0.38 if portrait else 0.52)
	var mascot_width := mascot_height * 0.76
	var action_margin := home_action_panel.find_child("HomeActionMargin", true, false) as MarginContainer
	var action_column := home_action_panel.find_child("HomeActionColumn", true, false) as VBoxContainer
	if portrait:
		home_rabbit.size = Vector2(mascot_width, mascot_height)
		home_rabbit.position = Vector2(-mascot_width * 0.22, viewport_size.y - mascot_height - 128.0)
		home_chick.size = Vector2(mascot_width * 0.86, mascot_height * 0.86)
		home_chick.position = Vector2(viewport_size.x - mascot_width * 0.64, viewport_size.y - mascot_height * 0.76 - 150.0)
		home_title_label.add_theme_font_size_override("font_size", 76)
		home_subtitle_label.add_theme_font_size_override("font_size", 19)
		home_play_button.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.62, 318.0, 680.0), clampf(viewport_size.y * 0.074, 96.0, 148.0))
		home_play_button.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.030, 34.0, 56.0)))
		home_status_label.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.014, 18.0, 28.0)))
		home_action_panel.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.72, minf(viewport_size.x - 38.0, 358.0), 760.0), 0)
		_layout_home_action_margin(action_margin, 20, 16)
		if action_column:
			action_column.add_theme_constant_override("separation", 8)
		home_nav_row.offset_top = -108.0
		home_animal_strip.visible = true
		home_animal_strip.scale = Vector2.ONE
		_layout_home_animal_tokens(62.0, 50.0, 8)
		_layout_home_animal_strip(5)
		_layout_home_nav_buttons(true)
		_layout_path_nodes([
			Vector2(viewport_size.x * 0.58, viewport_size.y * 0.42),
			Vector2(viewport_size.x * 0.46, viewport_size.y * 0.47),
			Vector2(viewport_size.x * 0.60, viewport_size.y * 0.52),
			Vector2(viewport_size.x * 0.48, viewport_size.y * 0.57),
			Vector2(viewport_size.x * 0.62, viewport_size.y * 0.62),
			Vector2(viewport_size.x * 0.50, viewport_size.y * 0.67),
		])
	else:
		home_rabbit.size = Vector2(mascot_width, mascot_height)
		home_rabbit.position = Vector2(viewport_size.x * 0.06, viewport_size.y - mascot_height - 86.0)
		home_chick.size = Vector2(mascot_width * 0.86, mascot_height * 0.86)
		home_chick.position = Vector2(viewport_size.x - mascot_width * 0.92 - viewport_size.x * 0.06, viewport_size.y - mascot_height * 0.86 - 88.0)
		home_title_label.add_theme_font_size_override("font_size", 96)
		home_subtitle_label.add_theme_font_size_override("font_size", 26)
		home_play_button.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.28, 880.0, 1160.0), clampf(viewport_size.y * 0.135, 240.0, 300.0))
		home_play_button.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.044, 70.0, 88.0)))
		home_status_label.add_theme_font_size_override("font_size", int(clampf(viewport_size.y * 0.018, 28.0, 36.0)))
		home_action_panel.custom_minimum_size = Vector2(clampf(viewport_size.x * 0.36, 1040.0, 1320.0), 0)
		_layout_home_action_margin(action_margin, 46, 30)
		if action_column:
			action_column.add_theme_constant_override("separation", 18)
		home_nav_row.offset_top = -110.0
		home_animal_strip.visible = true
		home_animal_strip.scale = Vector2.ONE
		_layout_home_animal_tokens(clampf(viewport_size.y * 0.090, 136.0, 176.0), clampf(viewport_size.y * 0.068, 102.0, 134.0), 18)
		_layout_home_animal_strip(8)
		_layout_home_nav_buttons(false)
		_layout_path_nodes([
			Vector2(viewport_size.x * 0.40, viewport_size.y * 0.58),
			Vector2(viewport_size.x * 0.46, viewport_size.y * 0.52),
			Vector2(viewport_size.x * 0.52, viewport_size.y * 0.58),
			Vector2(viewport_size.x * 0.58, viewport_size.y * 0.52),
			Vector2(viewport_size.x * 0.64, viewport_size.y * 0.58),
			Vector2(viewport_size.x * 0.70, viewport_size.y * 0.52),
		])


func _layout_home_action_margin(margin: MarginContainer, horizontal: int, vertical: int) -> void:
	if margin == null:
		return
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_bottom", vertical)


func _layout_home_animal_tokens(token_side: float, icon_side: float, separation: int) -> void:
	if home_animal_strip == null:
		return
	home_animal_strip.add_theme_constant_override("separation", separation)
	for child in home_animal_strip.get_children():
		var panel := child as PanelContainer
		if panel == null:
			continue
		panel.custom_minimum_size = Vector2(token_side, token_side)
		var icon := panel.find_child("HomeAnimalPreview", true, false) as TextureRect
		if icon != null:
			icon.custom_minimum_size = Vector2(icon_side, icon_side)


func _layout_home_animal_strip(max_visible: int) -> void:
	if home_animal_strip == null:
		return
	for index in range(home_animal_strip.get_child_count()):
		home_animal_strip.get_child(index).visible = index < max_visible


func _layout_home_nav_buttons(portrait: bool) -> void:
	if home_nav_row == null:
		return
	for child in home_nav_row.get_children():
		var button := child as Button
		if button == null:
			continue
		button.custom_minimum_size = Vector2(112, 66) if portrait else Vector2(140, 72)
		button.add_theme_font_size_override("font_size", 22 if portrait else 25)


func _layout_path_nodes(positions: Array[Vector2]) -> void:
	if home_path_root == null:
		return
	var viewport_size := get_viewport_rect().size
	var portrait := viewport_size.y >= viewport_size.x
	var node_side := 72.0 if portrait else clampf(viewport_size.y * 0.075, 112.0, 148.0)
	var node_font := 24 if portrait else int(clampf(viewport_size.y * 0.030, 44.0, 60.0))
	for index in range(mini(home_path_root.get_child_count(), positions.size())):
		var node := home_path_root.get_child(index) as Control
		var target_position: Vector2 = positions[index]
		node.size = Vector2(node_side, node_side)
		node.custom_minimum_size = node.size
		node.position = target_position - node.size * 0.5
		var label := node.find_child("PathNodeLabel", true, false) as Label
		if label != null:
			label.add_theme_font_size_override("font_size", node_font)
