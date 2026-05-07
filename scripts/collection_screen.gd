extends Control

const CollectionState = preload("res://scripts/collection_state.gd")
const GameSession = preload("res://scripts/game_session.gd")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const LiveEventService = preload("res://scripts/live_event_service.gd")
const ANIMAL_TEXTURE_FALLBACKS := {
	"lion": "fox",
	"elephant": "panda",
	"koala": "panda",
	"hamster": "pig",
	"deer": "fox",
	"seal": "penguin",
	"sheep": "bear",
	"turtle": "frog",
}
const MAX_ACTIVE_PREVIEWS := 4

var safe_margin: MarginContainer
var collection_scroll: ScrollContainer
var card_grid: GridContainer
var summary_label: Label
var detail_label: Label
var preview_nodes: Dictionary = {}
var _preview_tweens: Array[Tween] = []
var _active_preview_ids: Array[String] = []
var _preview_sync_queued := false
var selected_animal_id := ""


func _ready() -> void:
	GameSession.load_state()
	_build_layout()
	_refresh_cards()
	_track_rescue_book_open_analytics()
	_track_collection_event_impressions()
	resized.connect(_apply_responsive_layout)
	visibility_changed.connect(_queue_preview_motion_sync)
	get_window().size_changed.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")


func _exit_tree() -> void:
	for tween in _preview_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_preview_tweens.clear()
	preview_nodes.clear()
	_active_preview_ids.clear()


func _build_layout() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color("f3fbff")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	safe_margin = MarginContainer.new()
	safe_margin.name = "SafeMargin"
	safe_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(safe_margin)

	var root := VBoxContainer.new()
	root.name = "LayoutRoot"
	root.add_theme_constant_override("separation", 14)
	safe_margin.add_child(root)

	var header := HBoxContainer.new()
	header.name = "HeaderRow"
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "← 홈"
	back_button.custom_minimum_size = Vector2(108, 48)
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Rescue Book"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("24445f"))
	title_stack.add_child(title)

	summary_label = Label.new()
	summary_label.name = "SummaryLabel"
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 17)
	summary_label.add_theme_color_override("font_color", Color("58708a"))
	title_stack.add_child(summary_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(108, 1)
	header.add_child(spacer)

	detail_label = Label.new()
	detail_label.name = "DetailLabel"
	detail_label.text = "구조한 친구들의 해금 상태와 토큰, 우정 레벨을 확인합니다."
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 18)
	detail_label.add_theme_color_override("font_color", Color("416076"))
	root.add_child(detail_label)

	collection_scroll = ScrollContainer.new()
	collection_scroll.name = "CollectionScroll"
	collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(collection_scroll)

	card_grid = GridContainer.new()
	card_grid.name = "CollectionGrid"
	card_grid.columns = 3
	card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_grid.add_theme_constant_override("h_separation", 12)
	card_grid.add_theme_constant_override("v_separation", 12)
	collection_scroll.add_child(card_grid)
	collection_scroll.get_v_scroll_bar().value_changed.connect(_queue_preview_motion_sync)


func _refresh_cards() -> void:
	for child in card_grid.get_children():
		child.queue_free()
	preview_nodes.clear()

	var animals := CollectionState.load_animal_definitions()
	var rescue_book := GameSession.get_rescue_book_state()
	var state_animals: Dictionary = Dictionary(rescue_book.get("animals", {}))
	var unlocked_count := 0
	for animal in animals:
		if not (animal is Dictionary):
			continue
		var animal_id := String(Dictionary(animal).get("id", ""))
		var entry: Dictionary = Dictionary(state_animals.get(animal_id, {}))
		if bool(entry.get("unlocked", false)):
			unlocked_count += 1
		card_grid.add_child(_make_animal_card(Dictionary(animal), entry))

	summary_label.text = "해금 %d / %d · 최고 Stage %d" % [unlocked_count, animals.size(), GameSession.get_highest_unlocked_stage_id()]
	_update_detail_for_selected(animals, state_animals)
	_sync_preview_motion()


func _track_rescue_book_open_analytics() -> void:
	var state := GameSession.get_rescue_book_state()
	var animals: Dictionary = Dictionary(state.get("animals", {}))
	var unlocked_count := 0
	for entry in animals.values():
		if entry is Dictionary and bool(Dictionary(entry).get("unlocked", false)):
			unlocked_count += 1
	GameSession.record_analytics_event("rescue_book_open", {
		"session_id": GameSession.get_session_id(),
		"highest_unlocked_stage": GameSession.get_highest_unlocked_stage_id(),
		"unlocked_animal_count": unlocked_count,
		"entry_point": "collection_screen",
	})


func _track_collection_event_impressions() -> void:
	for event in LiveEventService.display_events_for(GameSession.get_highest_unlocked_stage_id(), "collection"):
		var event_dict := Dictionary(event)
		GameSession.record_analytics_event("live_event_impression", {
			"session_id": GameSession.get_session_id(),
			"event_id": String(event_dict.get("id", "")),
			"event_type": String(event_dict.get("type", "")),
			"placement": "collection",
			"unlock_stage": int(event_dict.get("unlock_stage", 0)),
			"enabled": bool(event_dict.get("enabled", false)),
			"status": String(event_dict.get("status", "")),
		})


func _make_animal_card(animal: Dictionary, entry: Dictionary) -> PanelContainer:
	var animal_id := String(animal.get("id", ""))
	var unlocked := bool(entry.get("unlocked", false))
	var is_new := bool(entry.get("is_new", false))
	var panel := PanelContainer.new()
	panel.name = "AnimalCard_%s" % animal_id
	panel.gui_input.connect(_on_animal_card_input.bind(animal, entry))
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.custom_minimum_size = Vector2(170, 210)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _card_style(unlocked, is_new))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 7)
	margin.add_child(stack)

	var preview := TextureRect.new()
	preview.name = "AnimalPreview"
	preview.texture = _load_animal_texture(animal_id)
	preview.custom_minimum_size = Vector2(84, 84)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.24, 0.28, 0.32, 0.44)
	stack.add_child(preview)
	if unlocked:
		preview_nodes[animal_id] = preview

	var name_label := Label.new()
	name_label.text = String(animal.get("display_name", animal_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color("213d55") if unlocked else Color("7f8792"))
	stack.add_child(name_label)

	var status_label := Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("3f6f5b") if unlocked else Color("8b93a0"))
	if unlocked:
		status_label.text = "Lv.%d · 토큰 %d%s" % [int(entry.get("friendship_level", 1)), int(entry.get("tokens", 0)), " · NEW" if is_new else ""]
	else:
		status_label.text = "Stage %d 해금" % int(animal.get("unlock_stage", 1))
	stack.add_child(status_label)

	var cosmetic_label := Label.new()
	cosmetic_label.text = "코스메틱: %s" % String(entry.get("equipped_cosmetic", animal.get("default_cosmetic", "none")))
	cosmetic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cosmetic_label.add_theme_font_size_override("font_size", 13)
	cosmetic_label.add_theme_color_override("font_color", Color("6c7890"))
	stack.add_child(cosmetic_label)

	return panel


func _on_animal_card_input(event: InputEvent, animal: Dictionary, entry: Dictionary) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		pressed = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		pressed = touch_event.pressed
	if not pressed:
		return
	selected_animal_id = String(animal.get("id", ""))
	if bool(entry.get("unlocked", false)):
		GameSession.mark_rescue_book_seen(selected_animal_id)
	_refresh_cards()


func _update_detail_for_selected(animals: Array, state_animals: Dictionary) -> void:
	if selected_animal_id.is_empty() and not animals.is_empty():
		selected_animal_id = String(Dictionary(animals[0]).get("id", ""))
	for animal in animals:
		if not (animal is Dictionary):
			continue
		var animal_dict: Dictionary = animal
		var animal_id := String(animal_dict.get("id", ""))
		if animal_id != selected_animal_id:
			continue
		var entry: Dictionary = Dictionary(state_animals.get(animal_id, {}))
		var unlocked := bool(entry.get("unlocked", false))
		if unlocked:
			detail_label.text = _detail_with_event_line("%s · Lv.%d · 토큰 %d · %s" % [
				String(animal_dict.get("display_name", animal_id)),
				int(entry.get("friendship_level", 1)),
				int(entry.get("tokens", 0)),
				String(animal_dict.get("personality", "구조 완료")),
			])
		else:
			detail_label.text = _detail_with_event_line("%s · Stage %d에서 해금 예정 · %s" % [
				String(animal_dict.get("display_name", animal_id)),
				int(animal_dict.get("unlock_stage", 1)),
				String(animal_dict.get("personality", "아직 구조 전")),
			])
		return
	detail_label.text = _detail_with_event_line("구조한 친구들의 해금 상태와 토큰, 우정 레벨을 확인합니다.")


func _detail_with_event_line(base_text: String) -> String:
	var event_line := _collection_live_event_line()
	if event_line.is_empty():
		return base_text
	return "%s\n%s" % [base_text, event_line]


func _collection_live_event_line() -> String:
	var events := LiveEventService.display_events_for(GameSession.get_highest_unlocked_stage_id(), "collection")
	if events.is_empty():
		return ""
	return _collection_live_event_line_for_event(Dictionary(events[0]))


func _collection_live_event_line_for_event(event: Dictionary) -> String:
	var title := String(event.get("title", "이벤트")).strip_edges()
	if title.length() > 14:
		title = "%s..." % title.substr(0, 14)
	return "이벤트  %s · %s · %s" % [title, LiveEventService.status_text(event), _event_type_label(String(event.get("type", "")))]


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


func _sync_preview_motion() -> void:
	_preview_sync_queued = false
	for tween in _preview_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_preview_tweens.clear()
	_active_preview_ids.clear()
	for preview in preview_nodes.values():
		if preview is TextureRect:
			(preview as TextureRect).scale = Vector2.ONE
	if not is_visible_in_tree():
		return

	var animated := 0
	for animal_id_value in preview_nodes.keys():
		if animated >= MAX_ACTIVE_PREVIEWS:
			break
		var animal_id := String(animal_id_value)
		var preview = preview_nodes[animal_id_value]
		if not (preview is TextureRect):
			continue
		var preview_rect := Rect2((preview as TextureRect).global_position, (preview as TextureRect).size)
		if not _preview_rect_is_visible(preview_rect):
			continue
		var tween := create_tween()
		tween.set_loops()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(preview, "scale", Vector2(1.06, 1.06), 0.65)
		tween.tween_property(preview, "scale", Vector2.ONE, 0.75)
		_preview_tweens.append(tween)
		_active_preview_ids.append(animal_id)
		animated += 1


func _preview_rect_is_visible(rect: Rect2) -> bool:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return false
	var viewport_rect := Rect2(Vector2.ZERO, get_viewport_rect().size)
	var visible_rect := viewport_rect
	if collection_scroll != null:
		visible_rect = visible_rect.intersection(collection_scroll.get_global_rect())
	return visible_rect.intersects(rect)


func _queue_preview_motion_sync(_value: float = 0.0) -> void:
	if _preview_sync_queued:
		return
	_preview_sync_queued = true
	call_deferred("_sync_preview_motion")


func _active_preview_count_for_testing() -> int:
	return _preview_tweens.size()


func _active_preview_ids_for_testing() -> Array:
	return _active_preview_ids.duplicate()


func _preview_id_is_visible_for_testing(animal_id: String) -> bool:
	if not preview_nodes.has(animal_id):
		return false
	var preview = preview_nodes[animal_id]
	if not (preview is TextureRect):
		return false
	return _preview_rect_is_visible(Rect2((preview as TextureRect).global_position, (preview as TextureRect).size))


func _load_animal_texture(animal_id: String) -> Texture2D:
	var texture_path := "res://assets/generated/candy/%s_candy_block.png" % animal_id
	if ResourceLoader.exists(texture_path):
		var texture := load(texture_path)
		if texture is Texture2D:
			return texture
	var fallback_id := String(ANIMAL_TEXTURE_FALLBACKS.get(animal_id, ""))
	if not fallback_id.is_empty():
		var fallback_path := "res://assets/generated/candy/%s_candy_block.png" % fallback_id
		if ResourceLoader.exists(fallback_path):
			var fallback_texture := load(fallback_path)
			if fallback_texture is Texture2D:
				return fallback_texture
	return null


func _card_style(unlocked: bool, is_new: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ffffff") if unlocked else Color("e3e8ef")
	style.border_color = Color("ffd15f") if is_new else (Color("8ee5c5") if unlocked else Color("b7c1cf"))
	style.set_border_width_all(3 if is_new else 2)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.15, 0.22, 0.32, 0.18)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style


func _apply_responsive_layout() -> void:
	if safe_margin == null or card_grid == null:
		return
	MobileLayout.apply_safe_area(safe_margin, self, 18)
	var viewport_size := get_viewport_rect().size
	card_grid.columns = 2 if viewport_size.x < 720 else 3
	_queue_preview_motion_sync()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
