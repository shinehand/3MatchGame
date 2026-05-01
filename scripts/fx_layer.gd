extends CanvasLayer

const MATCH_BURST_TEXTURE := preload("res://assets/generated/polish/fx_match_burst_clean.png")
const COMBO_POP_TEXTURE := preload("res://assets/generated/polish/fx_combo_pop_clean.png")
const COMBO_GREAT_TEXTURE := preload("res://assets/generated/polish/fx_combo_great_clean.png")
const GOAL_RING_TEXTURE := preload("res://assets/generated/polish/fx_goal_complete_ring_clean.png")

@onready var board_fx_root: Control = $BoardFxRoot
@onready var hud_fx_root: Control = $HudFxRoot
@onready var screen_fx_root: Control = $ScreenFxRoot


func _ready() -> void:
	_configure_root(board_fx_root)
	_configure_root(hud_fx_root)
	_configure_root(screen_fx_root)


func play_match_burst_at(global_position: Vector2, combo: int = 1) -> void:
	var size := clampf(78.0 + float(combo - 1) * 10.0, 78.0, 122.0)
	var burst := _spawn_texture(board_fx_root, MATCH_BURST_TEXTURE, global_position, Vector2(size, size))
	burst.modulate = Color(1.0, 0.95, 0.58, 0.94)
	burst.scale = Vector2(0.62, 0.62)
	burst.rotation = randf_range(-0.16, 0.16)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(burst, "scale", Vector2(1.18, 1.18), 0.18)
	tween.tween_property(burst, "rotation", burst.rotation + randf_range(-0.35, 0.35), 0.22)
	tween.tween_property(burst, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.24)
	await tween.finished
	burst.queue_free()


func play_special_created(global_position: Vector2, special_type: String) -> void:
	var ring := _spawn_texture(board_fx_root, GOAL_RING_TEXTURE, global_position, Vector2(138, 138))
	ring.modulate = _special_color(special_type)
	ring.scale = Vector2(0.44, 0.44)
	var label := _spawn_label(board_fx_root, _special_text(special_type), global_position + Vector2(0, -58), 28, _special_color(special_type))

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2(1.08, 1.08), 0.22)
	tween.tween_property(ring, "modulate:a", 0.0, 0.36)
	tween.tween_property(label, "position:y", label.position.y - 30.0, 0.32)
	tween.tween_property(label, "modulate:a", 0.0, 0.34).set_delay(0.08)
	await tween.finished
	ring.queue_free()
	label.queue_free()


func play_combo_banner(combo: int) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var texture := COMBO_POP_TEXTURE if combo <= 1 else COMBO_GREAT_TEXTURE
	var banner := _spawn_texture(screen_fx_root, texture, Vector2(viewport_size.x * 0.5, viewport_size.y * 0.23), Vector2(330, 136))
	banner.modulate = Color(1, 1, 1, 0)
	banner.scale = Vector2(0.72, 0.72)

	var label_text := "POP!" if combo <= 1 else "COMBO x%d" % combo
	var label := _spawn_label(screen_fx_root, label_text, banner.global_position + Vector2(0, 10), 38 if combo <= 1 else 42, Color(1.0, 0.95, 0.35, 1.0))
	label.modulate = Color(1, 1, 1, 0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.18)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.12)
	tween.tween_property(label, "position:y", label.position.y - 8.0, 0.18)
	await get_tree().create_timer(0.38).timeout

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(banner, "modulate:a", 0.0, 0.16)
	fade.tween_property(banner, "position:y", banner.position.y - 22.0, 0.16)
	fade.tween_property(label, "modulate:a", 0.0, 0.16)
	fade.tween_property(label, "position:y", label.position.y - 22.0, 0.16)
	await fade.finished
	banner.queue_free()
	label.queue_free()


func play_goal_rescue(global_position: Vector2, label_text: String = "목표 완료!") -> void:
	var ring := _spawn_texture(hud_fx_root, GOAL_RING_TEXTURE, global_position, Vector2(168, 168))
	ring.modulate = Color(0.38, 1.0, 0.55, 0.94)
	ring.scale = Vector2(0.52, 0.52)
	var label := _spawn_label(hud_fx_root, label_text, global_position + Vector2(0, -70), 32, Color(0.25, 0.92, 0.42, 1.0))

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "scale", Vector2(1.15, 1.15), 0.22)
	tween.tween_property(ring, "modulate:a", 0.0, 0.42)
	tween.tween_property(label, "position:y", label.position.y - 34.0, 0.36)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.1)
	await tween.finished
	ring.queue_free()
	label.queue_free()


func play_last_moves_warning(moves: int) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var warning := _spawn_label(screen_fx_root, "이동 %d회 남음" % moves, Vector2(viewport_size.x * 0.5, 86.0), 34, Color(1.0, 0.36, 0.26, 1.0))
	warning.modulate = Color(1, 1, 1, 0)
	warning.scale = Vector2(0.84, 0.84)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(warning, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(warning, "scale", Vector2(1.0, 1.0), 0.14)
	await get_tree().create_timer(0.42).timeout

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(warning, "modulate:a", 0.0, 0.16)
	fade.tween_property(warning, "position:y", warning.position.y - 18.0, 0.16)
	await fade.finished
	warning.queue_free()


func play_star_reveal(star_count: int) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var center := Vector2(viewport_size.x * 0.5, viewport_size.y * 0.34)
	for index in range(3):
		var color := Color(1.0, 0.83, 0.18, 1.0) if index < star_count else Color(0.76, 0.76, 0.76, 0.62)
		var star := _spawn_label(screen_fx_root, "★", center + Vector2(float(index - 1) * 86.0, 0), 86, color)
		star.modulate.a = 0.0
		star.scale = Vector2(0.35, 0.35)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "modulate:a", 1.0, 0.12)
		tween.tween_property(star, "scale", Vector2(1.0, 1.0), 0.2)
		tween.tween_property(star, "position:y", star.position.y - 18.0, 0.22)
		await get_tree().create_timer(0.12).timeout
		_fade_and_free(star, 1.15, 0.24)


func play_zoo_zoo_time_banner(moves: int) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var label := _spawn_label(screen_fx_root, "ZOO-ZOO TIME!", Vector2(viewport_size.x * 0.5, viewport_size.y * 0.22), 48, Color(1.0, 0.86, 0.16, 1.0))
	var sub_label := _spawn_label(screen_fx_root, "남은 이동 %d회 보너스 폭발" % moves, Vector2(viewport_size.x * 0.5, viewport_size.y * 0.30), 28, Color(1.0, 1.0, 1.0, 0.96))
	label.modulate.a = 0.0
	sub_label.modulate.a = 0.0
	label.scale = Vector2(0.72, 0.72)
	sub_label.scale = Vector2(0.82, 0.82)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(sub_label, "modulate:a", 1.0, 0.16)
	tween.tween_property(sub_label, "scale", Vector2(1.0, 1.0), 0.22)
	await get_tree().create_timer(0.62).timeout

	var fade := create_tween()
	fade.set_parallel(true)
	fade.tween_property(label, "modulate:a", 0.0, 0.18)
	fade.tween_property(label, "position:y", label.position.y - 24.0, 0.18)
	fade.tween_property(sub_label, "modulate:a", 0.0, 0.18)
	fade.tween_property(sub_label, "position:y", sub_label.position.y - 18.0, 0.18)
	await fade.finished
	label.queue_free()
	sub_label.queue_free()


func play_bonus_score(global_position: Vector2, amount: int) -> void:
	var label := _spawn_label(board_fx_root, "+%d" % amount, global_position + Vector2(0, -52), 28, Color(1.0, 0.85, 0.18, 1.0))
	label.scale = Vector2(0.72, 0.72)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.14)
	tween.tween_property(label, "position:y", label.position.y - 34.0, 0.34)
	tween.tween_property(label, "modulate:a", 0.0, 0.36).set_delay(0.1)
	await tween.finished
	label.queue_free()


func play_rainbow_clear(global_positions: Array) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var flash := ColorRect.new()
	flash.name = "RainbowFlash"
	_configure_root(flash)
	flash.color = Color(1.0, 0.85, 0.35, 0.0)
	screen_fx_root.add_child(flash)

	var flash_tween := create_tween()
	flash_tween.tween_property(flash, "color:a", 0.22, 0.08)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.18)
	flash_tween.tween_callback(flash.queue_free)

	var banner := _spawn_label(screen_fx_root, "RAINBOW!", Vector2(viewport_size.x * 0.5, viewport_size.y * 0.24), 44, Color(1.0, 0.98, 0.35, 1.0))
	banner.scale = Vector2(0.72, 0.72)
	var banner_tween := create_tween()
	banner_tween.set_parallel(true)
	banner_tween.set_trans(Tween.TRANS_BACK)
	banner_tween.set_ease(Tween.EASE_OUT)
	banner_tween.tween_property(banner, "scale", Vector2(1.0, 1.0), 0.18)
	banner_tween.tween_property(banner, "position:y", banner.position.y - 18.0, 0.3)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.22).set_delay(0.36)
	banner_tween.tween_callback(banner.queue_free).set_delay(0.58)

	var limit := mini(global_positions.size(), 18)
	for index in range(limit):
		var position: Vector2 = global_positions[index]
		var burst := _spawn_texture(board_fx_root, MATCH_BURST_TEXTURE, position, Vector2(104, 104))
		burst.modulate = Color.from_hsv(float(index % 6) / 6.0, 0.72, 1.0, 0.92)
		burst.scale = Vector2(0.52, 0.52)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(burst, "scale", Vector2(1.16, 1.16), 0.2)
		tween.tween_property(burst, "modulate:a", 0.0, 0.26)
		tween.tween_callback(burst.queue_free).set_delay(0.28)
		await get_tree().create_timer(0.018).timeout


func _spawn_texture(parent: Control, texture: Texture2D, global_position: Vector2, effect_size: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = "FxTexture"
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.size = effect_size
	texture_rect.pivot_offset = effect_size * 0.5
	texture_rect.global_position = global_position - effect_size * 0.5
	parent.add_child(texture_rect)
	return texture_rect


func _spawn_label(parent: Control, text: String, global_position: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = "FxLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.13, 0.08, 0.08, 0.42))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.size = Vector2(320, maxf(80.0, float(font_size) * 1.8))
	label.pivot_offset = label.size * 0.5
	label.global_position = global_position - label.size * 0.5
	parent.add_child(label)
	return label


func _fade_and_free(node: CanvasItem, hold_seconds: float, fade_seconds: float) -> void:
	await get_tree().create_timer(hold_seconds).timeout
	if not is_instance_valid(node):
		return
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, fade_seconds)
	await tween.finished
	if is_instance_valid(node):
		node.queue_free()


func _configure_root(root: Control) -> void:
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 0.0
	root.offset_top = 0.0
	root.offset_right = 0.0
	root.offset_bottom = 0.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _special_text(special_type: String) -> String:
	match special_type:
		"row":
			return "가로!"
		"col":
			return "세로!"
		"bomb":
			return "폭탄!"
		"rainbow":
			return "무지개!"
	return "특수!"


func _special_color(special_type: String) -> Color:
	match special_type:
		"row":
			return Color(0.35, 0.78, 1.0, 0.95)
		"col":
			return Color(0.52, 0.91, 0.45, 0.95)
		"bomb":
			return Color(1.0, 0.52, 0.25, 0.95)
		"rainbow":
			return Color(1.0, 0.9, 0.25, 0.95)
	return Color(1.0, 1.0, 1.0, 0.95)
