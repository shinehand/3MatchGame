extends Control

const StageCatalog = preload("res://scripts/stage_catalog.gd")
const GameSession = preload("res://scripts/game_session.gd")
const STAGE_CARD_SCENE = preload("res://scenes/stage_card.tscn")
const MobileLayout = preload("res://scripts/mobile_layout.gd")

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var layout_root: BoxContainer = $SafeMargin/LayoutRoot
@onready var left_mascots: VBoxContainer = $SafeMargin/LayoutRoot/LeftMascots
@onready var right_mascots: VBoxContainer = $SafeMargin/LayoutRoot/RightMascots
@onready var center_column: VBoxContainer = $SafeMargin/LayoutRoot/CenterColumn
@onready var buttons_column: VBoxContainer = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn
@onready var play_button: Button = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/PlayButton
@onready var secondary_buttons: BoxContainer = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/SecondaryButtons
@onready var stage_button: Button = $SafeMargin/LayoutRoot/CenterColumn/ButtonsColumn/SecondaryButtons/StageButton
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


func _ready() -> void:
	GameSession.load_state()
	GameSession.apply_feedback_preferences()
	stage_defs = StageCatalog.get_stages()
	resized.connect(_queue_layout_refresh)
	get_window().size_changed.connect(_queue_layout_refresh)
	_update_home_status()
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
	play_button.text = "시작"
	stage_button.text = "스테이지 라인"
	info_label.text = "시작을 누르면 Stage %d이 강조된 스테이지 라인으로 이동합니다.\n해금 %d / %d, 클리어 %d, 누적 별 %d\n사운드 %s · 햅틱 %s" % [
		continue_stage_id,
		unlocked,
		stage_defs.size(),
		GameSession.get_cleared_count(),
		GameSession.get_total_stars(),
		"ON" if GameSession.get_sound_enabled() else "OFF",
		"ON" if GameSession.get_haptics_enabled() else "OFF",
	]


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


func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	var portrait := MobileLayout.is_portrait(self)
	MobileLayout.apply_safe_area(safe_margin, self, 18 if portrait else 14)

	layout_root.vertical = portrait
	layout_root.add_theme_constant_override("separation", 18 if portrait else 24)
	secondary_buttons.visible = true
	exit_button.visible = false
	info_card.visible = true
	secondary_buttons.vertical = false
	secondary_buttons.alignment = BoxContainer.ALIGNMENT_CENTER

	left_mascots.visible = not portrait
	right_mascots.visible = not portrait
	center_column.alignment = BoxContainer.ALIGNMENT_CENTER
	center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons_column.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play_button.custom_minimum_size = Vector2(420, 124) if portrait else Vector2(520, 132)
	exit_button.custom_minimum_size = Vector2(0 if portrait else 220, 82)

	stage_grid.columns = 2 if portrait else 3
	stage_overlay_panel.custom_minimum_size = Vector2(760, 1040) if portrait else Vector2(1120, 760)
	settings_overlay_panel.custom_minimum_size = Vector2(760, 780) if portrait else Vector2(920, 620)
