extends RefCounted


static func is_portrait(root: Control) -> bool:
	var viewport_size: Vector2 = root.get_viewport_rect().size
	return viewport_size.y >= viewport_size.x


static func apply_safe_area(target: MarginContainer, root: Control, extra_margin: int = 0) -> void:
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = root.get_window().size

	var left_margin := extra_margin
	var top_margin := extra_margin
	var right_margin := extra_margin
	var bottom_margin := extra_margin

	if safe_rect.size != Vector2i.ZERO:
		left_margin += max(safe_rect.position.x, 0)
		top_margin += max(safe_rect.position.y, 0)
		right_margin += max(window_size.x - (safe_rect.position.x + safe_rect.size.x), 0)
		bottom_margin += max(window_size.y - (safe_rect.position.y + safe_rect.size.y), 0)

	target.add_theme_constant_override("margin_left", left_margin)
	target.add_theme_constant_override("margin_top", top_margin)
	target.add_theme_constant_override("margin_right", right_margin)
	target.add_theme_constant_override("margin_bottom", bottom_margin)
