extends PanelContainer

const GOAL_COMPLETE_TEXTURE = preload("res://assets/ui/hud/goal_complete_badge.svg")
const GOAL_NEAR_COMPLETE_TEXTURE = preload("res://assets/ui/hud/goal_near_complete_badge.svg")

@onready var icon: TextureRect = $Padding/Row/IconPanel/IconCenter/Icon
@onready var badge: Label = $Padding/Row/IconPanel/IconCenter/Badge
@onready var state_badge: TextureRect = $Padding/Row/IconPanel/StateBadge
@onready var title_label: Label = $Padding/Row/Content/Title
@onready var progress_label: Label = $Padding/Row/Content/ProgressLabel
@onready var progress_bar: ProgressBar = $Padding/Row/Content/ProgressBar

var _state_badge_mode := ""


func set_collect_goal(texture: Texture2D, title: String, current: int, target: int) -> void:
	icon.visible = true
	icon.texture = texture
	badge.visible = false
	title_label.text = title
	progress_label.text = "%d / %d" % [current, target]
	progress_bar.max_value = max(target, 1)
	progress_bar.value = min(current, target)
	_update_state_badge(current, target)


func set_icon_goal(texture: Texture2D, title: String, current: int, target: int) -> void:
	icon.visible = true
	icon.texture = texture
	badge.visible = false
	title_label.text = title
	progress_label.text = "%d / %d" % [current, target]
	progress_bar.max_value = max(target, 1)
	progress_bar.value = min(current, target)
	_update_state_badge(current, target)


func set_score_goal(title: String, current: int, target: int) -> void:
	icon.visible = false
	badge.visible = true
	title_label.text = title
	progress_label.text = "%d / %d" % [current, target]
	progress_bar.max_value = max(target, 1)
	progress_bar.value = min(current, target)
	_update_state_badge(current, target)


func _update_state_badge(current: int, target: int) -> void:
	var next_mode := ""
	if target <= 0:
		_state_badge_mode = ""
		state_badge.visible = false
		return
	if current >= target:
		next_mode = "complete"
	elif target - current <= 2:
		next_mode = "near"

	if next_mode.is_empty():
		_state_badge_mode = ""
		state_badge.visible = false
		return

	state_badge.texture = GOAL_COMPLETE_TEXTURE if next_mode == "complete" else GOAL_NEAR_COMPLETE_TEXTURE
	state_badge.visible = true
	if _state_badge_mode != next_mode:
		_animate_state_badge(next_mode)
	_state_badge_mode = next_mode


func _animate_state_badge(mode: String) -> void:
	state_badge.scale = Vector2(0.72, 0.72)
	state_badge.modulate = Color(1, 1, 1, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(state_badge, "scale", Vector2.ONE, 0.18)
	tween.tween_property(state_badge, "modulate", Color(1, 1, 1, 1), 0.14)
	if mode == "complete":
		await tween.finished
		var pulse := create_tween()
		pulse.set_parallel(true)
		pulse.tween_property(state_badge, "scale", Vector2(1.08, 1.08), 0.12)
		pulse.tween_property(state_badge, "modulate", Color(1, 1, 1, 0.96), 0.12)
		await pulse.finished
		var settle := create_tween()
		settle.set_parallel(true)
		settle.tween_property(state_badge, "scale", Vector2.ONE, 0.12)
		settle.tween_property(state_badge, "modulate", Color(1, 1, 1, 1), 0.12)
