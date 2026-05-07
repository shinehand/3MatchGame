extends Control

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const GameSession = preload("res://scripts/game_session.gd")
const STAGE_CARD_SCENE = preload("res://scenes/stage_card.tscn")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const HOME_RABBIT_TEXTURE := preload("res://assets/generated/polish/home_mascot_rabbit_clean.png")
const HOME_CHICK_TEXTURE := preload("res://assets/generated/polish/home_mascot_chick_clean.png")
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
var game_home_layer: Control
var home_play_button: Button
var home_status_label: Label
var home_title_label: Label
var home_subtitle_label: Label
var home_rabbit: TextureRect
var home_chick: TextureRect
var home_animal_strip: HBoxContainer
var home_nav_row: HBoxContainer
var home_path_root: Control


func _ready() -> void:
	GameSession.load_state()
	GameSession.apply_feedback_preferences()
	stage_defs = StageCatalog.get_stages()
	resized.connect(_queue_layout_refresh)
	get_window().size_changed.connect(_queue_layout_refresh)
	_build_game_home_layer()
	_apply_home_art_direction()
	_update_home_status()
	call_deferred("_start_home_animations")
	call_deferred("_apply_responsive_layout")


func _on_play_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
	settings_overlay.visible = false
	GameSession.set_selected_stage_id(GameSession.get_continue_stage_id())
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _on_stage_button_pressed() -> void:
	Feedback.play_ui_tap()
	settings_overlay.visible = false
	stage_overlay.visible = false
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")


func _on_ranking_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
	settings_overlay.visible = false
	get_tree().change_scene_to_file("res://scenes/collection_screen.tscn")


func _on_stage_overlay_close_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
	_update_home_status()


func _on_settings_button_pressed() -> void:
	Feedback.play_ui_tap()
	stage_overlay.visible = false
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
	sky_shade.color = Color(0.03, 0.28, 0.56, 0.12)
	sky_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_home_layer.add_child(sky_shade)

	var bottom_glow := ColorRect.new()
	bottom_glow.name = "CandyStageGlow"
	bottom_glow.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_glow.offset_top = -260.0
	bottom_glow.color = Color(1.0, 0.75, 0.26, 0.24)
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
	top_hud.add_child(_make_home_badge("하트", "5"))
	top_hud.add_child(_make_home_badge("골드", str(120 + GameSession.get_total_stars() * 15)))
	top_hud.add_child(_make_home_badge("별", str(GameSession.get_total_stars())))
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hud.add_child(top_spacer)
	var settings_button := _make_home_icon_button("설정")
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

	home_title_label = _make_home_label("Zoo-Zoo\nPop", 94, Color(1.0, 0.92, 0.20, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
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

	home_play_button = _make_home_play_button()
	home_play_button.pressed.connect(_on_play_button_pressed)
	hero_stack.add_child(home_play_button)

	home_status_label = _make_home_label("Lv.1 준비 완료", 22, Color(1.0, 1.0, 1.0, 0.96), HORIZONTAL_ALIGNMENT_CENTER)
	home_status_label.add_theme_color_override("font_shadow_color", Color(0.10, 0.20, 0.36, 0.52))
	home_status_label.add_theme_constant_override("shadow_offset_y", 3)
	hero_stack.add_child(home_status_label)

	home_animal_strip = HBoxContainer.new()
	home_animal_strip.name = "AnimalStrip"
	home_animal_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	home_animal_strip.add_theme_constant_override("separation", 8)
	hero_stack.add_child(home_animal_strip)
	for texture in ANIMAL_PREVIEW_TEXTURES:
		home_animal_strip.add_child(_make_animal_token(texture))

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
	map_button.pressed.connect(_on_stage_button_pressed)
	home_nav_row.add_child(map_button)
	var ranking_nav_button := _make_home_icon_button("도감")
	ranking_nav_button.pressed.connect(_on_ranking_button_pressed)
	home_nav_row.add_child(ranking_nav_button)
	var settings_nav_button := _make_home_icon_button("설정")
	settings_nav_button.pressed.connect(_on_settings_button_pressed)
	home_nav_row.add_child(settings_nav_button)


func _make_mascot(node_name: String, texture: Texture2D) -> TextureRect:
	var mascot := TextureRect.new()
	mascot.name = node_name
	mascot.texture = texture
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascot.modulate = Color(1, 1, 1, 0.98)
	return mascot


func _make_home_badge(label_text: String, value_text: String) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(124, 58)
	badge.add_theme_stylebox_override("panel", _home_style(Color(1, 1, 1, 0.78), Color(1, 0.86, 0.26, 0.92), 24, 3))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	badge.add_child(margin)
	var label := _make_home_label("%s %s" % [label_text, value_text], 22, Color(0.13, 0.23, 0.34, 1), HORIZONTAL_ALIGNMENT_CENTER)
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
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.add_child(label)
	return panel


func _make_home_icon_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(146, 72)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color(0.08, 0.22, 0.34, 1))
	button.add_theme_stylebox_override("normal", _home_style(Color(1, 1, 1, 0.78), Color(0.50, 0.78, 0.94, 1), 26, 4))
	button.add_theme_stylebox_override("hover", _home_style(Color(0.91, 0.98, 1.0, 0.92), Color(0.36, 0.76, 0.97, 1), 26, 4))
	button.add_theme_stylebox_override("pressed", _home_style(Color(1.0, 0.78, 0.90, 0.95), Color(0.96, 0.38, 0.61, 1), 26, 4))
	return button


func _make_home_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_animal_token(texture: Texture2D) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(62, 62)
	panel.add_theme_stylebox_override("panel", _home_style(Color(1, 1, 1, 0.66), Color(1, 0.86, 0.26, 0.88), 18, 3))
	var center := CenterContainer.new()
	panel.add_child(center)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(50, 50)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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

	if home_play_button:
		_pulse_control(home_play_button, Vector2(1.0, 1.0), Vector2(1.055, 1.055), 0.78)
	else:
		_pulse_control(play_button, Vector2(1.0, 1.0), Vector2(1.055, 1.055), 0.78)
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


func _layout_game_home(portrait: bool) -> void:
	if game_home_layer == null:
		return
	var viewport_size := get_viewport_rect().size
	var mascot_height := viewport_size.y * (0.38 if portrait else 0.52)
	var mascot_width := mascot_height * 0.76
	if portrait:
		home_rabbit.size = Vector2(mascot_width, mascot_height)
		home_rabbit.position = Vector2(-mascot_width * 0.22, viewport_size.y - mascot_height - 128.0)
		home_chick.size = Vector2(mascot_width * 0.86, mascot_height * 0.86)
		home_chick.position = Vector2(viewport_size.x - mascot_width * 0.64, viewport_size.y - mascot_height * 0.76 - 150.0)
		home_title_label.add_theme_font_size_override("font_size", 82)
		home_subtitle_label.add_theme_font_size_override("font_size", 22)
		home_play_button.custom_minimum_size = Vector2(350, 108)
		home_nav_row.offset_top = -108.0
		home_animal_strip.visible = true
		home_animal_strip.scale = Vector2(0.74, 0.74)
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
		home_title_label.add_theme_font_size_override("font_size", 104)
		home_subtitle_label.add_theme_font_size_override("font_size", 26)
		home_play_button.custom_minimum_size = Vector2(480, 128)
		home_nav_row.offset_top = -110.0
		home_animal_strip.visible = true
		home_animal_strip.scale = Vector2.ONE
		_layout_path_nodes([
			Vector2(viewport_size.x * 0.40, viewport_size.y * 0.58),
			Vector2(viewport_size.x * 0.46, viewport_size.y * 0.52),
			Vector2(viewport_size.x * 0.52, viewport_size.y * 0.58),
			Vector2(viewport_size.x * 0.58, viewport_size.y * 0.52),
			Vector2(viewport_size.x * 0.64, viewport_size.y * 0.58),
			Vector2(viewport_size.x * 0.70, viewport_size.y * 0.52),
		])


func _layout_path_nodes(positions: Array[Vector2]) -> void:
	if home_path_root == null:
		return
	for index in range(mini(home_path_root.get_child_count(), positions.size())):
		var node := home_path_root.get_child(index) as Control
		var target_position: Vector2 = positions[index]
		node.size = Vector2(72, 72)
		node.position = target_position - node.size * 0.5
