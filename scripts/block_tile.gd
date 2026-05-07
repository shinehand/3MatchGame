extends Control

signal tile_pressed(row: int, col: int)
signal tile_swiped(row: int, col: int, direction: Vector2i)

const DRAG_THRESHOLD := 24.0
const DRAG_PREVIEW_RATIO := 0.34
const SPECIAL_BADGE_TEXTURES := {
	"row": preload("res://assets/ui/badge_row.svg"),
	"col": preload("res://assets/ui/badge_col.svg"),
	"bomb": preload("res://assets/ui/badge_bomb.svg"),
	"rainbow": preload("res://assets/ui/badge_rainbow.svg"),
}
const INVALID_PUFF_TEXTURE := preload("res://assets/generated/chatgpt/fx_invalid_puff_chatgpt.png")
const OBSTACLE_BURST_TEXTURE := preload("res://assets/generated/chatgpt/fx_blocker_leaf_burst_chatgpt.png")
const EXPRESSION_PRIORITIES := {
	"idle": 0,
	"blink": 1,
	"smile": 2,
	"fever": 2,
	"worried": 2,
	"match": 3,
}

@onready var content: Control = $Content
@onready var inactive_slot: ColorRect = $Content/InactiveSlot
@onready var icon: TextureRect = $Content/Icon
@onready var match_burst: TextureRect = $Content/MatchBurst
@onready var selection_glow: TextureRect = $Content/SelectionGlow
@onready var obstacle_overlay: TextureRect = $Content/ObstacleOverlay
@onready var special_badge: TextureRect = $Content/SpecialBadge
@onready var match_pop: TextureRect = $Content/MatchPop
@onready var invalid_puff: TextureRect = $Content/InvalidPuff
@onready var obstacle_burst: TextureRect = $Content/ObstacleBurst

var row: int = -1
var col: int = -1
var animal_id: String = ""
var drag_start_position := Vector2.ZERO
var is_dragging := false
var suppress_next_press := false
var match_effect_texture: Texture2D
var is_inactive := false
var idle_tween: Tween
var expression_state := "idle"
var expression_tween: Tween
var expression_priority := 0
var is_expression_locked := false
var slot_frame: PanelContainer
var slot_highlight: PanelContainer


func _ready() -> void:
	_build_candy_slot_frame()
	invalid_puff.texture = INVALID_PUFF_TEXTURE
	obstacle_burst.texture = OBSTACLE_BURST_TEXTURE
	_update_visual_pivots()
	resized.connect(_update_visual_pivots)


func set_position_in_grid(new_row: int, new_col: int) -> void:
	row = new_row
	col = new_col


func set_tile_visual_size(tile_extent: float) -> void:
	custom_minimum_size = Vector2(tile_extent, tile_extent)


func set_match_effect_texture(texture: Texture2D) -> void:
	match_effect_texture = texture
	match_burst.texture = texture


func set_inactive(inactive: bool) -> void:
	is_inactive = inactive
	_stop_idle_motion()
	clear_expression(false)
	if slot_frame:
		slot_frame.visible = true
		slot_frame.add_theme_stylebox_override("panel", _slot_style(Color(0.57, 0.74, 0.95, 0.36), Color(1, 1, 1, 0.26), 16, 2))
	if slot_highlight:
		slot_highlight.visible = false
	inactive_slot.visible = inactive
	icon.visible = not inactive and icon.texture != null
	match_burst.visible = false
	selection_glow.visible = false
	obstacle_overlay.visible = false
	special_badge.visible = false
	match_pop.visible = false
	invalid_puff.visible = false
	obstacle_burst.visible = false
	content.position = Vector2.ZERO
	content.scale = Vector2.ONE
	content.rotation = 0.0
	content.modulate = Color(1, 1, 1, 1)
	$Button.disabled = inactive


func set_tile(texture: Texture2D, new_animal_id: String, special_type: String = "") -> void:
	clear_expression(false)
	icon.texture = texture
	icon.visible = texture != null
	icon.scale = Vector2.ONE
	icon.position = Vector2.ZERO
	animal_id = new_animal_id
	inactive_slot.visible = false
	is_inactive = false
	content.scale = Vector2.ONE
	content.rotation = 0.0
	content.position = Vector2.ZERO
	content.modulate = Color(1, 1, 1, 1)
	$Button.disabled = texture == null
	if slot_frame:
		slot_frame.visible = texture != null
		slot_frame.add_theme_stylebox_override("panel", _slot_style(_slot_color(new_animal_id), Color(1, 1, 1, 0.72), 20, 3))
	if slot_highlight:
		slot_highlight.visible = texture != null
	selection_glow.visible = false
	match_burst.visible = false
	match_burst.modulate = Color(1, 1, 1, 0)
	match_burst.scale = Vector2.ONE
	obstacle_overlay.visible = false
	special_badge.visible = false
	match_pop.visible = false
	match_pop.modulate = Color(1, 1, 1, 0)
	invalid_puff.visible = false
	invalid_puff.modulate = Color(1, 1, 1, 0)
	obstacle_burst.visible = false
	obstacle_burst.modulate = Color(1, 1, 1, 0)
	_update_special_badge(special_type)
	if texture != null:
		call_deferred("_start_idle_motion")
	else:
		_stop_idle_motion()


func set_expression(new_expression_id: String, force: bool = false) -> void:
	if not is_inside_tree() or not can_play_idle_expression():
		return
	var next_expression := String(new_expression_id).strip_edges().to_lower()
	if not EXPRESSION_PRIORITIES.has(next_expression):
		next_expression = "idle"
	var next_priority := int(EXPRESSION_PRIORITIES.get(next_expression, 0))
	if not force and is_expression_locked and next_priority < expression_priority:
		return
	if next_expression == "idle":
		clear_expression()
		return

	_stop_idle_motion()
	_clear_expression_tween(false)
	expression_state = next_expression
	expression_priority = next_priority
	is_expression_locked = next_priority >= 3
	_update_visual_pivots()

	match next_expression:
		"blink":
			_play_blink_expression()
		"smile":
			_play_smile_expression()
		"match":
			_play_match_expression()
		"fever":
			_play_fever_expression()
		"worried":
			_play_worried_expression()
		_:
			clear_expression()


func clear_expression(restart_idle_motion: bool = true) -> void:
	_clear_expression_tween(true)
	expression_state = "idle"
	expression_priority = 0
	is_expression_locked = false
	if restart_idle_motion and can_play_idle_expression():
		_start_idle_motion()


func can_play_idle_expression() -> bool:
	return not is_inactive and icon != null and icon.visible and icon.texture != null


func _build_candy_slot_frame() -> void:
	if slot_frame != null:
		return
	slot_frame = PanelContainer.new()
	slot_frame.name = "CandySlotFrame"
	slot_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_frame.offset_left = 4.0
	slot_frame.offset_top = 4.0
	slot_frame.offset_right = -4.0
	slot_frame.offset_bottom = -4.0
	slot_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_frame.add_theme_stylebox_override("panel", _slot_style(Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.72), 20, 3))
	content.add_child(slot_frame)
	content.move_child(slot_frame, 0)

	slot_highlight = PanelContainer.new()
	slot_highlight.name = "CandySlotHighlight"
	slot_highlight.set_anchors_preset(Control.PRESET_TOP_WIDE)
	slot_highlight.offset_left = 16.0
	slot_highlight.offset_top = 10.0
	slot_highlight.offset_right = -16.0
	slot_highlight.offset_bottom = 34.0
	slot_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_highlight.add_theme_stylebox_override("panel", _slot_style(Color(1, 1, 1, 0.34), Color(1, 1, 1, 0.0), 14, 0))
	content.add_child(slot_highlight)
	content.move_child(slot_highlight, 1)


func _slot_color(new_animal_id: String) -> Color:
	match new_animal_id:
		"rabbit":
			return Color("ff9bd0")
		"bear":
			return Color("ffb76a")
		"cat":
			return Color("7cc4ff")
		"chick":
			return Color("ffe052")
		"frog":
			return Color("77ee82")
		"dog":
			return Color("d7b4ff")
		"panda":
			return Color("f1f5ff")
		"pig":
			return Color("ff9bb5")
		"penguin":
			return Color("91ddff")
		"fox":
			return Color("ff945f")
		"lion":
			return Color("f5c04d")
		"elephant":
			return Color("a9b7d6")
		_:
			return Color("ffffff")


func _slot_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
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
	style.shadow_color = Color(0.05, 0.12, 0.22, 0.22)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style


func set_obstacle(texture: Texture2D, hp: int) -> void:
	obstacle_overlay.texture = texture
	obstacle_overlay.visible = not is_inactive and texture != null and hp > 0


func set_selected(is_selected: bool) -> void:
	_update_visual_pivots()
	if not is_inside_tree():
		return
	selection_glow.visible = is_selected
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	if is_selected:
		selection_glow.scale = Vector2(0.88, 0.88)
		selection_glow.modulate = Color(1, 1, 1, 0.0)
		tween.tween_property(selection_glow, "scale", Vector2.ONE, 0.14)
		tween.parallel().tween_property(selection_glow, "modulate", Color(1, 1, 1, 0.95), 0.12)
		tween.tween_property(content, "scale", Vector2(1.06, 1.06), 0.12)
	else:
		tween.tween_property(selection_glow, "modulate", Color(1, 1, 1, 0.0), 0.08)
		tween.tween_property(content, "scale", Vector2.ONE, 0.12)


func play_swap_feedback(travel_offset: Vector2 = Vector2.ZERO) -> void:
	_update_visual_pivots()
	if not is_inside_tree():
		return
	var clamped_offset := travel_offset
	if clamped_offset.length() > size.x * 0.34:
		clamped_offset = clamped_offset.normalized() * size.x * 0.34
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "position", clamped_offset, 0.06)
	tween.parallel().tween_property(content, "scale", Vector2(1.05, 1.05), 0.06)
	tween.parallel().tween_property(content, "rotation", 0.045 if clamped_offset.x >= 0.0 else -0.045, 0.06)
	tween.tween_property(content, "position", Vector2.ZERO, 0.1)
	tween.parallel().tween_property(content, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(content, "rotation", 0.0, 0.1)


func play_drag_commit_feedback(travel_offset: Vector2 = Vector2.ZERO, duration: float = 0.08) -> void:
	_update_visual_pivots()
	if not is_inside_tree():
		return
	var clamped_offset := travel_offset
	if clamped_offset.length() > size.x * 0.42:
		clamped_offset = clamped_offset.normalized() * size.x * 0.42

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "position", clamped_offset, duration)
	tween.tween_property(content, "scale", Vector2(1.08, 1.08), duration)
	tween.tween_property(content, "rotation", 0.05 if clamped_offset.x >= 0.0 else -0.05, duration * 0.9)


func finalize_swap_feedback(duration: float = 0.08) -> void:
	_update_visual_pivots()
	if not is_inside_tree():
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "position", Vector2.ZERO, duration)
	tween.tween_property(content, "scale", Vector2.ONE, duration)
	tween.tween_property(content, "rotation", 0.0, duration)


func play_invalid_feedback() -> void:
	_update_visual_pivots()
	if not is_inside_tree():
		return

	invalid_puff.visible = true
	invalid_puff.scale = Vector2(0.58, 0.58)
	invalid_puff.modulate = Color(1, 1, 1, 0.9)
	var puff_tween := create_tween()
	puff_tween.set_parallel(true)
	puff_tween.set_trans(Tween.TRANS_BACK)
	puff_tween.set_ease(Tween.EASE_OUT)
	puff_tween.tween_property(invalid_puff, "scale", Vector2(1.18, 1.18), 0.18)
	puff_tween.tween_property(invalid_puff, "modulate", Color(1, 1, 1, 0), 0.2)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(content, "position:x", -8.0, 0.05)
	tween.tween_property(content, "position:x", 8.0, 0.08)
	tween.tween_property(content, "position:x", 0.0, 0.05)
	await puff_tween.finished
	invalid_puff.visible = false
	invalid_puff.scale = Vector2.ONE


func play_obstacle_clear_effect() -> void:
	_update_visual_pivots()
	if not is_inside_tree():
		return

	obstacle_burst.visible = true
	obstacle_burst.scale = Vector2(0.5, 0.5)
	obstacle_burst.modulate = Color(1, 1, 1, 0.92)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(obstacle_burst, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(obstacle_burst, "modulate", Color(1, 1, 1, 0), 0.24)
	await tween.finished
	obstacle_burst.visible = false
	obstacle_burst.scale = Vector2.ONE


func snap_back_drag_preview(duration: float = 0.12) -> void:
	if is_inactive:
		return
	_update_visual_pivots()
	if not is_inside_tree():
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "position", Vector2.ZERO, duration)
	tween.tween_property(content, "scale", Vector2.ONE, duration)
	tween.tween_property(content, "rotation", 0.0, duration)
	if selection_glow.visible:
		tween.tween_property(selection_glow, "modulate", Color(1, 1, 1, 0.0), duration * 0.85)


func play_match_effect() -> void:
	if not icon.visible:
		return

	_update_visual_pivots()
	if not is_inside_tree():
		return
	if match_effect_texture != null:
		match_burst.visible = true
		match_burst.scale = Vector2(0.45, 0.45)
		match_burst.modulate = Color(1, 1, 1, 0.9)

	match_pop.visible = true
	match_pop.scale = Vector2(0.45, 0.45)
	match_pop.modulate = Color(1, 1, 1, 1)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(content, "scale", Vector2(1.16, 1.16), 0.12)
	if match_effect_texture != null:
		tween.tween_property(match_burst, "scale", Vector2(1.24, 1.24), 0.18)
		tween.tween_property(match_burst, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(match_pop, "scale", Vector2(1.35, 1.35), 0.18)
	tween.tween_property(match_pop, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished

	content.scale = Vector2.ONE
	match_burst.visible = false
	match_burst.scale = Vector2.ONE
	match_pop.visible = false
	match_pop.scale = Vector2.ONE


func play_drop_in(distance: int) -> void:
	if not icon.visible:
		return

	_update_visual_pivots()
	if not is_inside_tree():
		return
	var travel: float = max(distance, 1) * 22.0
	content.position = Vector2(0, -travel)
	content.modulate = Color(1, 1, 1, 0.35)
	content.scale = Vector2(0.9, 0.9)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "position", Vector2.ZERO, 0.22)
	tween.tween_property(content, "scale", Vector2.ONE, 0.22)
	tween.tween_property(content, "modulate", Color(1, 1, 1, 1), 0.18)


func play_special_ready_effect() -> void:
	_update_visual_pivots()
	if not is_inside_tree():
		return
	special_badge.scale = Vector2(0.6, 0.6)
	special_badge.modulate = Color(1, 1, 1, 0.35)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(special_badge, "scale", Vector2.ONE, 0.16)
	tween.tween_property(special_badge, "modulate", Color(1, 1, 1, 1), 0.16)


func _clear_expression_tween(reset_visuals: bool) -> void:
	if expression_tween != null and expression_tween.is_valid():
		expression_tween.kill()
	expression_tween = null
	if reset_visuals and icon != null:
		icon.scale = Vector2.ONE
		icon.position = Vector2.ZERO
		icon.modulate = Color(1, 1, 1, 1)
		if content != null:
			content.position = Vector2.ZERO
			content.rotation = 0.0


func _finish_expression() -> void:
	expression_state = "idle"
	expression_priority = 0
	is_expression_locked = false
	if icon != null:
		icon.scale = Vector2.ONE
		icon.position = Vector2.ZERO
		icon.modulate = Color(1, 1, 1, 1)
	if content != null:
		content.position = Vector2.ZERO
		content.rotation = 0.0
	if can_play_idle_expression():
		_start_idle_motion()


func _play_blink_expression() -> void:
	expression_tween = create_tween()
	expression_tween.set_trans(Tween.TRANS_SINE)
	expression_tween.set_ease(Tween.EASE_IN_OUT)
	expression_tween.tween_property(icon, "scale", Vector2(1.03, 0.82), 0.07)
	expression_tween.tween_property(icon, "scale", Vector2.ONE, 0.09)
	expression_tween.finished.connect(_finish_expression)


func _play_smile_expression() -> void:
	expression_tween = create_tween()
	expression_tween.set_parallel(true)
	expression_tween.set_trans(Tween.TRANS_BACK)
	expression_tween.set_ease(Tween.EASE_OUT)
	expression_tween.tween_property(icon, "scale", Vector2(1.08, 1.08), 0.12)
	expression_tween.tween_property(icon, "modulate", Color(1.12, 1.12, 1.06, 1), 0.1)
	expression_tween.chain().tween_property(icon, "scale", Vector2.ONE, 0.16)
	expression_tween.parallel().tween_property(icon, "modulate", Color(1, 1, 1, 1), 0.16)
	expression_tween.finished.connect(_finish_expression)


func _play_match_expression() -> void:
	expression_tween = create_tween()
	expression_tween.set_parallel(true)
	expression_tween.set_trans(Tween.TRANS_BACK)
	expression_tween.set_ease(Tween.EASE_OUT)
	expression_tween.tween_property(icon, "scale", Vector2(1.13, 1.13), 0.08)
	expression_tween.tween_property(icon, "modulate", Color(1.18, 1.14, 1.06, 1), 0.08)
	expression_tween.chain().tween_property(icon, "scale", Vector2.ONE, 0.08)
	expression_tween.parallel().tween_property(icon, "modulate", Color(1, 1, 1, 1), 0.08)
	expression_tween.finished.connect(_finish_expression)


func _play_fever_expression() -> void:
	expression_tween = create_tween()
	expression_tween.set_loops(3)
	expression_tween.set_parallel(true)
	expression_tween.set_trans(Tween.TRANS_SINE)
	expression_tween.set_ease(Tween.EASE_IN_OUT)
	expression_tween.tween_property(icon, "scale", Vector2(1.08, 1.08), 0.12)
	expression_tween.tween_property(icon, "modulate", Color(1.2, 1.18, 1.02, 1), 0.12)
	expression_tween.chain().tween_property(icon, "scale", Vector2.ONE, 0.12)
	expression_tween.parallel().tween_property(icon, "modulate", Color(1, 1, 1, 1), 0.12)
	expression_tween.finished.connect(_finish_expression)


func _play_worried_expression() -> void:
	expression_tween = create_tween()
	expression_tween.set_trans(Tween.TRANS_SINE)
	expression_tween.set_ease(Tween.EASE_IN_OUT)
	expression_tween.tween_property(icon, "modulate", Color(0.86, 0.9, 1.0, 1), 0.08)
	expression_tween.parallel().tween_property(content, "position:x", -2.0, 0.06)
	expression_tween.tween_property(content, "position:x", 2.0, 0.08)
	expression_tween.tween_property(content, "position:x", -1.0, 0.08)
	expression_tween.tween_property(content, "position:x", 0.0, 0.06)
	expression_tween.parallel().tween_property(icon, "modulate", Color(1, 1, 1, 1), 0.12)
	expression_tween.finished.connect(_finish_expression)


func _on_button_pressed() -> void:
	if suppress_next_press:
		suppress_next_press = false
		return
	tile_pressed.emit(row, col)


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		if touch_event.pressed:
			drag_start_position = touch_event.position
			is_dragging = true
		elif is_dragging:
			if not _emit_swipe_direction(touch_event.position):
				snap_back_drag_preview()
			is_dragging = false
	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event
		if is_dragging:
			_update_drag_preview(drag_event.position)
	elif event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button_event.pressed:
			drag_start_position = mouse_button_event.position
			is_dragging = true
		elif is_dragging:
			if not _emit_swipe_direction(mouse_button_event.position):
				snap_back_drag_preview()
			is_dragging = false
	elif event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event
		if is_dragging:
			_update_drag_preview(mouse_motion_event.position)


func _emit_swipe_direction(end_position: Vector2) -> bool:
	var delta: Vector2 = end_position - drag_start_position
	if delta.length() < DRAG_THRESHOLD:
		return false

	var direction := Vector2i.ZERO
	if abs(delta.x) > abs(delta.y):
		direction.y = 1 if delta.x > 0.0 else -1
	else:
		direction.x = 1 if delta.y > 0.0 else -1

	suppress_next_press = true
	tile_swiped.emit(row, col, direction)
	return true


func _update_drag_preview(current_position: Vector2) -> void:
	if is_inactive or not icon.visible:
		return

	_update_visual_pivots()
	var delta: Vector2 = current_position - drag_start_position
	var preview_offset := Vector2.ZERO
	var preview_limit_x := size.x * DRAG_PREVIEW_RATIO
	var preview_limit_y := size.y * DRAG_PREVIEW_RATIO
	if abs(delta.x) > abs(delta.y):
		preview_offset.x = clamp(delta.x, -preview_limit_x, preview_limit_x)
	else:
		preview_offset.y = clamp(delta.y, -preview_limit_y, preview_limit_y)

	content.position = preview_offset
	content.scale = Vector2(1.08, 1.08)
	selection_glow.visible = true
	selection_glow.modulate = Color(1, 1, 1, 0.92)


func _update_special_badge(special_type: String) -> void:
	special_badge.texture = SPECIAL_BADGE_TEXTURES.get(special_type)
	special_badge.visible = special_badge.texture != null


func _update_visual_pivots() -> void:
	var tile_center := size * 0.5
	content.pivot_offset = tile_center
	icon.pivot_offset = icon.size * 0.5
	selection_glow.pivot_offset = selection_glow.size * 0.5
	match_burst.pivot_offset = match_burst.size * 0.5
	match_pop.pivot_offset = match_pop.size * 0.5
	invalid_puff.pivot_offset = invalid_puff.size * 0.5
	obstacle_burst.pivot_offset = obstacle_burst.size * 0.5
	special_badge.pivot_offset = special_badge.size * 0.5


func _start_idle_motion() -> void:
	if not is_inside_tree() or is_inactive or not icon.visible:
		return
	_stop_idle_motion()
	_update_visual_pivots()
	var delay := fmod(float(row * 7 + col * 5) * 0.037, 0.62)
	idle_tween = create_tween()
	idle_tween.set_loops()
	idle_tween.set_trans(Tween.TRANS_SINE)
	idle_tween.set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_interval(delay)
	idle_tween.tween_property(icon, "scale", Vector2(1.025, 1.025), 0.84)
	idle_tween.tween_property(icon, "scale", Vector2.ONE, 0.84)


func _stop_idle_motion() -> void:
	if idle_tween != null and idle_tween.is_valid():
		idle_tween.kill()
	idle_tween = null
	if icon:
		icon.scale = Vector2.ONE
		icon.position = Vector2.ZERO
