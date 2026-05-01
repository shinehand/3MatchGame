extends Control

const MobileLayout = preload("res://scripts/mobile_layout.gd")

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const LOAD_DURATION := 1.55

@onready var background_texture: TextureRect = $BackgroundTexture
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var main_stack: VBoxContainer = $SafeMargin/MainStack
@onready var logo_label: Label = $SafeMargin/MainStack/Logo
@onready var subtitle_label: Label = $SafeMargin/MainStack/Subtitle
@onready var token_row: HBoxContainer = $SafeMargin/MainStack/TokenRow
@onready var progress_frame: PanelContainer = $SafeMargin/MainStack/ProgressFrame
@onready var progress_bar: ProgressBar = $SafeMargin/MainStack/ProgressFrame/ProgressMargin/ProgressBar
@onready var tip_label: Label = $SafeMargin/MainStack/TipLabel

var elapsed := 0.0
var scene_change_started := false
var loading_tweens: Array[Tween] = []


func _ready() -> void:
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	_apply_visual_style()
	_apply_responsive_layout()
	resized.connect(_queue_layout_refresh)
	get_window().size_changed.connect(_queue_layout_refresh)
	call_deferred("_start_loading_animations")


func _process(delta: float) -> void:
	if scene_change_started:
		return

	elapsed += delta
	var ratio := clampf(elapsed / LOAD_DURATION, 0.0, 1.0)
	var eased_ratio := 1.0 - pow(1.0 - ratio, 3.0)
	progress_bar.value = eased_ratio * 100.0

	if elapsed >= LOAD_DURATION:
		scene_change_started = true
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _apply_visual_style() -> void:
	logo_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.22, 1.0))
	logo_label.add_theme_color_override("font_shadow_color", Color(0.07, 0.18, 0.38, 0.78))
	logo_label.add_theme_constant_override("shadow_offset_y", 8)
	subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.08, 0.20, 0.36, 0.52))
	subtitle_label.add_theme_constant_override("shadow_offset_y", 4)
	tip_label.add_theme_color_override("font_color", Color(0.10, 0.22, 0.34, 1.0))
	progress_frame.add_theme_stylebox_override("panel", _make_style(Color(1, 1, 1, 0.72), Color(1.0, 0.72, 0.18, 1.0), 28, 5))
	progress_bar.add_theme_stylebox_override("background", _make_style(Color(0.12, 0.27, 0.42, 0.20), Color(1, 1, 1, 0.0), 18, 0))
	progress_bar.add_theme_stylebox_override("fill", _make_style(Color(1.0, 0.60, 0.12, 1.0), Color(1.0, 0.95, 0.42, 1.0), 18, 3))


func _make_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
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
	style.shadow_color = Color(0.06, 0.15, 0.24, 0.22)
	style.shadow_size = 12
	return style


func _start_loading_animations() -> void:
	for tween in loading_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	loading_tweens.clear()

	logo_label.pivot_offset = logo_label.size * 0.5
	var logo_tween := create_tween()
	logo_tween.set_loops()
	logo_tween.set_trans(Tween.TRANS_SINE)
	logo_tween.set_ease(Tween.EASE_IN_OUT)
	logo_tween.tween_property(logo_label, "scale", Vector2(1.035, 1.035), 0.62)
	logo_tween.tween_property(logo_label, "scale", Vector2.ONE, 0.62)
	loading_tweens.append(logo_tween)

	for index in range(token_row.get_child_count()):
		var token := token_row.get_child(index) as TextureRect
		if token == null:
			continue
		token.pivot_offset = token.size * 0.5
		token.position.y += float(index % 2) * 8.0
		var token_tween := create_tween()
		token_tween.set_loops()
		token_tween.set_trans(Tween.TRANS_SINE)
		token_tween.set_ease(Tween.EASE_IN_OUT)
		token_tween.tween_interval(float(index) * 0.06)
		token_tween.tween_property(token, "position:y", token.position.y - 16.0, 0.42)
		token_tween.parallel().tween_property(token, "rotation", deg_to_rad(5.0 if index % 2 == 0 else -5.0), 0.42)
		token_tween.tween_property(token, "position:y", token.position.y, 0.52)
		token_tween.parallel().tween_property(token, "rotation", 0.0, 0.52)
		loading_tweens.append(token_tween)

	var bg_tween := create_tween()
	bg_tween.set_loops()
	bg_tween.set_trans(Tween.TRANS_SINE)
	bg_tween.set_ease(Tween.EASE_IN_OUT)
	bg_tween.tween_property(background_texture, "modulate", Color(1.08, 1.08, 1.08, 0.98), 1.2)
	bg_tween.tween_property(background_texture, "modulate", Color(1, 1, 1, 0.92), 1.2)
	loading_tweens.append(bg_tween)


func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	var portrait := MobileLayout.is_portrait(self)
	var viewport_size := get_viewport_rect().size
	var safe_padding := 30 if portrait else 52
	MobileLayout.apply_safe_area(safe_margin, self, safe_padding)
	main_stack.add_theme_constant_override("separation", 18 if portrait else 24)
	logo_label.add_theme_font_size_override("font_size", 88 if portrait else 112)
	subtitle_label.add_theme_font_size_override("font_size", 24 if portrait else 30)
	tip_label.add_theme_font_size_override("font_size", 22 if portrait else 26)
	progress_frame.custom_minimum_size = Vector2(min(viewport_size.x - float(safe_padding * 2), 620.0), 58)
	for token in token_row.get_children():
		var texture_rect := token as TextureRect
		if texture_rect:
			texture_rect.custom_minimum_size = Vector2(88, 88) if portrait else Vector2(104, 104)
