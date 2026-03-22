extends Control

signal tile_pressed(row: int, col: int)
signal tile_swiped(row: int, col: int, direction: Vector2i)

const DRAG_THRESHOLD := 24.0
const DRAG_PREVIEW_RATIO := 0.34
const SPECIAL_BADGE_TEXTURES := {
	"row": preload("res://assets/ui/badge_row.svg"),
	"col": preload("res://assets/ui/badge_col.svg"),
	"bomb": preload("res://assets/ui/badge_bomb.svg"),
}

@onready var content: Control = $Content
@onready var inactive_slot: ColorRect = $Content/InactiveSlot
@onready var icon: TextureRect = $Content/Icon
@onready var match_burst: TextureRect = $Content/MatchBurst
@onready var selection_glow: TextureRect = $Content/SelectionGlow
@onready var obstacle_overlay: TextureRect = $Content/ObstacleOverlay
@onready var special_badge: TextureRect = $Content/SpecialBadge
@onready var match_pop: TextureRect = $Content/MatchPop

var row: int = -1
var col: int = -1
var animal_id: String = ""
var drag_start_position := Vector2.ZERO
var is_dragging := false
var suppress_next_press := false
var match_effect_texture: Texture2D
var is_inactive := false


func _ready() -> void:
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
	inactive_slot.visible = false
	icon.visible = not inactive and icon.texture != null
	match_burst.visible = false
	selection_glow.visible = false
	obstacle_overlay.visible = false
	special_badge.visible = false
	match_pop.visible = false
	content.position = Vector2.ZERO
	content.scale = Vector2.ONE
	content.rotation = 0.0
	content.modulate = Color(1, 1, 1, 1)
	$Button.disabled = inactive


func set_tile(texture: Texture2D, new_animal_id: String, special_type: String = "") -> void:
	icon.texture = texture
	icon.visible = texture != null
	animal_id = new_animal_id
	inactive_slot.visible = false
	is_inactive = false
	content.scale = Vector2.ONE
	content.rotation = 0.0
	content.position = Vector2.ZERO
	content.modulate = Color(1, 1, 1, 1)
	$Button.disabled = texture == null
	selection_glow.visible = false
	match_burst.visible = false
	match_burst.modulate = Color(1, 1, 1, 0)
	match_burst.scale = Vector2.ONE
	obstacle_overlay.visible = false
	special_badge.visible = false
	match_pop.visible = false
	match_pop.modulate = Color(1, 1, 1, 0)
	_update_special_badge(special_type)


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
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(content, "position:x", -8.0, 0.05)
	tween.tween_property(content, "position:x", 8.0, 0.08)
	tween.tween_property(content, "position:x", 0.0, 0.05)


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
	selection_glow.pivot_offset = selection_glow.size * 0.5
	match_burst.pivot_offset = match_burst.size * 0.5
	match_pop.pivot_offset = match_pop.size * 0.5
	special_badge.pivot_offset = special_badge.size * 0.5
