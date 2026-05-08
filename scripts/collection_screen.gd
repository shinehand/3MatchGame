extends Control

const CollectionState = preload("res://scripts/collection_state.gd")
const GameSession = preload("res://scripts/game_session.gd")
const MobileLayout = preload("res://scripts/mobile_layout.gd")
const LiveEventService = preload("res://scripts/live_event_service.gd")
const COLLECTION_BG = preload("res://assets/generated/candy/candy_world_bg.png")
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
var header_panel: PanelContainer
var header_margin: MarginContainer
var back_button: Button
var collection_scroll: ScrollContainer
var card_grid: GridContainer
var summary_label: Label
var detail_label: Label
var cosmetic_grid: GridContainer
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
	background.color = Color("dcf7ff")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var background_texture := TextureRect.new()
	background_texture.name = "CollectionBackgroundTexture"
	background_texture.texture = COLLECTION_BG
	background_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_texture.modulate = Color(1, 1, 1, 0.42)
	background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background_texture)

	safe_margin = MarginContainer.new()
	safe_margin.name = "SafeMargin"
	safe_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(safe_margin)

	var root := VBoxContainer.new()
	root.name = "LayoutRoot"
	root.add_theme_constant_override("separation", 12)
	safe_margin.add_child(root)

	header_panel = PanelContainer.new()
	header_panel.name = "CollectionHeaderPanel"
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_panel.add_theme_stylebox_override("panel", _collection_style(Color(1, 1, 1, 0.84), Color("ffcf3f"), 28, 4))
	root.add_child(header_panel)

	header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 18)
	header_margin.add_theme_constant_override("margin_top", 14)
	header_margin.add_theme_constant_override("margin_right", 18)
	header_margin.add_theme_constant_override("margin_bottom", 14)
	header_panel.add_child(header_margin)

	var header_column := VBoxContainer.new()
	header_column.name = "HeaderColumn"
	header_column.add_theme_constant_override("separation", 8)
	header_margin.add_child(header_column)

	var header := HBoxContainer.new()
	header.name = "HeaderRow"
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	header_column.add_child(header)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "홈"
	back_button.custom_minimum_size = Vector2(96, 52)
	back_button.add_theme_font_size_override("font_size", 20)
	back_button.add_theme_color_override("font_color", Color("213a55"))
	back_button.add_theme_stylebox_override("normal", _collection_style(Color("ffffff"), Color("86c3e5"), 18, 3))
	back_button.add_theme_stylebox_override("hover", _collection_style(Color("e9fbff"), Color("6ec6ff"), 18, 3))
	back_button.add_theme_stylebox_override("pressed", _collection_style(Color("fff0a8"), Color("ff74a8"), 18, 3))
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "구조 도감"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("24445f"))
	title.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.60))
	title.add_theme_constant_override("shadow_offset_y", 2)
	title_stack.add_child(title)

	summary_label = Label.new()
	summary_label.name = "SummaryLabel"
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 17)
	summary_label.add_theme_color_override("font_color", Color("58708a"))
	title_stack.add_child(summary_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(96, 1)
	header.add_child(spacer)

	detail_label = Label.new()
	detail_label.name = "DetailLabel"
	detail_label.text = "구조한 친구들의 해금 상태와 토큰, 우정 레벨을 확인합니다."
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 18)
	detail_label.add_theme_color_override("font_color", Color("416076"))
	header_column.add_child(detail_label)

	cosmetic_grid = GridContainer.new()
	cosmetic_grid.name = "CosmeticEquipGrid"
	cosmetic_grid.columns = 3
	cosmetic_grid.visible = false
	cosmetic_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cosmetic_grid.add_theme_constant_override("h_separation", 8)
	cosmetic_grid.add_theme_constant_override("v_separation", 8)
	header_column.add_child(cosmetic_grid)

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
		card_grid.remove_child(child)
		child.queue_free()
	preview_nodes.clear()

	var animals := CollectionState.load_animal_definitions()
	var rescue_book := GameSession.get_rescue_book_state()
	var state_animals: Dictionary = Dictionary(rescue_book.get("animals", {}))
	if selected_animal_id.is_empty() and not animals.is_empty():
		selected_animal_id = String(Dictionary(animals[0]).get("id", ""))
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
	var is_selected := animal_id == selected_animal_id
	var equipped_reward := _equipped_reward_entry(animal, entry)
	var equipped_reward_type := String(equipped_reward.get("reward_type", ""))
	var equipped_cosmetic := String(entry.get("equipped_cosmetic", animal.get("default_cosmetic", "none")))
	var has_equipped_visual := unlocked and not equipped_reward.is_empty()
	var panel := PanelContainer.new()
	panel.name = "AnimalCard_%s" % animal_id
	panel.set_meta("animal_id", animal_id)
	panel.set_meta("equipped_cosmetic", equipped_cosmetic)
	panel.set_meta("equipped_cosmetic_type", equipped_reward_type)
	panel.gui_input.connect(_on_animal_card_input.bind(animal, entry))
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.custom_minimum_size = _collection_card_minimum_size(get_viewport_rect().size)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _card_style(unlocked, is_new, is_selected, equipped_reward_type if has_equipped_visual else ""))

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
	preview.custom_minimum_size = _collection_preview_size(get_viewport_rect().size)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.24, 0.28, 0.32, 0.44)
	preview.set_meta("animal_id", animal_id)
	preview.set_meta("expression_source", "collection")
	preview.set_meta("expression_state", "idle")
	stack.add_child(preview)
	if unlocked:
		preview_nodes[animal_id] = preview

	var name_label := Label.new()
	name_label.name = "AnimalNameLabel"
	name_label.text = String(animal.get("display_name", animal_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", _collection_name_font_size(get_viewport_rect().size))
	name_label.add_theme_color_override("font_color", Color("213d55") if unlocked else Color("7f8792"))
	name_label.visible = false
	stack.add_child(name_label)
	stack.add_child(_make_card_text_button(
		"AnimalNameVisual",
		name_label.text,
		_collection_name_label_minimum_size(get_viewport_rect().size),
		_collection_name_font_size(get_viewport_rect().size),
		Color("213d55") if unlocked else Color("7f8792"),
		Color("fffdf7") if unlocked else Color("eef3f8"),
	))

	var status_label := Label.new()
	status_label.name = "AnimalStatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_font_size_override("font_size", _collection_status_font_size(get_viewport_rect().size))
	status_label.add_theme_color_override("font_color", Color("3f6f5b") if unlocked else Color("8b93a0"))
	if unlocked:
		status_label.text = "Lv.%d · 토큰 %d%s" % [int(entry.get("friendship_level", 1)), int(entry.get("tokens", 0)), " · NEW" if is_new else ""]
	else:
		status_label.text = "Stage %d 해금" % int(animal.get("unlock_stage", 1))
	status_label.visible = false
	stack.add_child(status_label)
	stack.add_child(_make_card_text_button(
		"AnimalStatusVisual",
		status_label.text,
		_collection_status_label_minimum_size(get_viewport_rect().size),
		_collection_status_font_size(get_viewport_rect().size),
		Color("3f6f5b") if unlocked else Color("8b93a0"),
		Color("ddf8e9") if unlocked else Color("edf2f8"),
	))

	if has_equipped_visual:
		stack.add_child(_make_equipped_cosmetic_badge(equipped_cosmetic, equipped_reward_type))

	var cosmetic_label := Label.new()
	cosmetic_label.name = "AnimalCosmeticLabel"
	var earned_reward_count := _earned_reward_count(animal, entry)
	var total_reward_count := Array(animal.get("friendship_rewards", [])).size()
	cosmetic_label.text = "코스메틱: %s" % _equipped_cosmetic_copy(animal, entry, equipped_reward)
	if total_reward_count > 0:
		cosmetic_label.text += " · 보상 %d/%d" % [earned_reward_count, total_reward_count]
	cosmetic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cosmetic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cosmetic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cosmetic_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cosmetic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cosmetic_label.custom_minimum_size = _collection_cosmetic_label_minimum_size(get_viewport_rect().size)
	cosmetic_label.add_theme_font_size_override("font_size", _collection_cosmetic_font_size(get_viewport_rect().size))
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
			var base_detail := "%s · Lv.%d · 토큰 %d · %s" % [
				String(animal_dict.get("display_name", animal_id)),
				int(entry.get("friendship_level", 1)),
				int(entry.get("tokens", 0)),
				String(animal_dict.get("personality", "구조 완료")),
			]
			detail_label.text = _detail_with_event_line("%s\n%s" % [base_detail, _friendship_reward_track_text(animal_dict, entry)])
			_refresh_cosmetic_actions(animal_dict, entry, true)
		else:
			detail_label.text = _detail_with_event_line("%s · Stage %d에서 해금 예정 · %s" % [
				String(animal_dict.get("display_name", animal_id)),
				int(animal_dict.get("unlock_stage", 1)),
				String(animal_dict.get("personality", "아직 구조 전")),
			])
			_refresh_cosmetic_actions(animal_dict, entry, false)
		return
	detail_label.text = _detail_with_event_line("구조한 친구들의 해금 상태와 토큰, 우정 레벨을 확인합니다.")
	_clear_cosmetic_actions()


func _earned_reward_count(animal: Dictionary, entry: Dictionary) -> int:
	var earned_rewards := Array(entry.get("earned_rewards", []))
	var count := 0
	for reward in Array(animal.get("friendship_rewards", [])):
		if not (reward is Dictionary):
			continue
		var reward_id := String(Dictionary(reward).get("reward_id", ""))
		if earned_rewards.has(reward_id):
			count += 1
	return count


func _friendship_reward_track_text(animal: Dictionary, entry: Dictionary) -> String:
	var rewards := Array(animal.get("friendship_rewards", []))
	if rewards.is_empty():
		return "우정 보상  준비 중"
	var earned_rewards := Array(entry.get("earned_rewards", []))
	var pieces := PackedStringArray()
	for reward in rewards:
		if not (reward is Dictionary):
			continue
		var reward_dict: Dictionary = reward
		var reward_id := String(reward_dict.get("reward_id", ""))
		var reward_state := "획득" if earned_rewards.has(reward_id) else "대기"
		pieces.append("Lv.%d %s %s" % [
			int(reward_dict.get("level", 0)),
			reward_state,
			_reward_type_label(String(reward_dict.get("reward_type", ""))),
		])
	return "우정 보상  %s" % " · ".join(pieces)


func _reward_type_label(reward_type: String) -> String:
	match reward_type:
		"profile_icon":
			return "아이콘"
		"expression":
			return "표정"
		"card_frame":
			return "프레임"
		"title_badge":
			return "배지"
	return "코스메틱"


func _equipped_reward_entry(animal: Dictionary, entry: Dictionary) -> Dictionary:
	var equipped_cosmetic := String(entry.get("equipped_cosmetic", animal.get("default_cosmetic", "none"))).strip_edges()
	if equipped_cosmetic.is_empty() or equipped_cosmetic == "none":
		return {}
	var earned_rewards := Array(entry.get("earned_rewards", []))
	if not earned_rewards.has(equipped_cosmetic):
		return {}
	for reward in Array(animal.get("friendship_rewards", [])):
		if not (reward is Dictionary):
			continue
		var reward_dict: Dictionary = reward
		if String(reward_dict.get("reward_id", "")).strip_edges() == equipped_cosmetic:
			return reward_dict
	return {}


func _equipped_cosmetic_copy(animal: Dictionary, entry: Dictionary, equipped_reward: Dictionary) -> String:
	var equipped_cosmetic := String(entry.get("equipped_cosmetic", animal.get("default_cosmetic", "none"))).strip_edges()
	if equipped_cosmetic.is_empty():
		return "none"
	if equipped_reward.is_empty():
		return equipped_cosmetic
	return "장착 %s · %s" % [_reward_type_label(String(equipped_reward.get("reward_type", ""))), equipped_cosmetic]


func _make_equipped_cosmetic_badge(reward_id: String, reward_type: String) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "EquippedCosmeticBadge_%s" % _safe_node_suffix(reward_id)
	badge.custom_minimum_size = _equipped_badge_minimum_size(get_viewport_rect().size)
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge.add_theme_stylebox_override("panel", _collection_style(Color("fff0a8"), Color("ff74a8"), 15, 2))
	badge.set_meta("reward_id", reward_id)
	badge.set_meta("reward_type", reward_type)

	var label := Label.new()
	label.name = "EquippedCosmeticBadgeLabel"
	label.text = "장착 %s" % _reward_type_label(reward_type)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", _equipped_badge_font_size(get_viewport_rect().size))
	label.add_theme_color_override("font_color", Color("7a3150"))
	badge.add_child(label)
	return badge


func _make_card_text_button(button_name: String, text: String, minimum_size: Vector2, font_size: int, font_color: Color, bg_color: Color) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.disabled = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.custom_minimum_size = minimum_size
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_disabled_color", font_color)
	button.add_theme_stylebox_override("disabled", _collection_style(bg_color, Color(1, 1, 1, 0.0), 12, 0))
	return button


func _refresh_cosmetic_actions(animal: Dictionary, entry: Dictionary, unlocked: bool) -> void:
	_clear_cosmetic_actions()
	if cosmetic_grid == null or not unlocked:
		return
	var rewards := Array(animal.get("friendship_rewards", []))
	if rewards.is_empty():
		return
	var animal_id := String(animal.get("id", ""))
	var earned_rewards := Array(entry.get("earned_rewards", []))
	var equipped_cosmetic := String(entry.get("equipped_cosmetic", animal.get("default_cosmetic", "none")))
	cosmetic_grid.visible = true
	for reward in rewards:
		if not (reward is Dictionary):
			continue
		var reward_dict: Dictionary = reward
		var reward_id := String(reward_dict.get("reward_id", "")).strip_edges()
		if reward_id.is_empty():
			continue
		var reward_type := String(reward_dict.get("reward_type", "cosmetic"))
		var earned := earned_rewards.has(reward_id)
		var is_equipped := equipped_cosmetic == reward_id
		var button := Button.new()
		button.name = "CosmeticButton_%s" % _safe_node_suffix(reward_id)
		button.custom_minimum_size = _cosmetic_action_button_minimum_size(get_viewport_rect().size)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = reward_id
		if is_equipped:
			button.text = "장착중 %s" % _reward_type_label(reward_type)
			button.disabled = true
		elif earned:
			button.text = "장착 %s" % _reward_type_label(reward_type)
			button.pressed.connect(_on_cosmetic_reward_pressed.bind(animal_id, reward_id))
		else:
			button.text = "Lv.%d 대기" % int(reward_dict.get("level", 0))
			button.disabled = true
		button.add_theme_font_size_override("font_size", _cosmetic_action_button_font_size(get_viewport_rect().size))
		_style_cosmetic_button(button, earned, is_equipped)
		cosmetic_grid.add_child(button)


func _clear_cosmetic_actions() -> void:
	if cosmetic_grid == null:
		return
	for child in cosmetic_grid.get_children():
		cosmetic_grid.remove_child(child)
		child.queue_free()
	cosmetic_grid.visible = false


func _safe_node_suffix(value: String) -> String:
	return value.strip_edges().replace(" ", "_").replace("/", "_").replace(":", "_").replace(".", "_")


func _on_cosmetic_reward_pressed(animal_id: String, reward_id: String) -> void:
	var result := GameSession.equip_rescue_book_cosmetic(animal_id, reward_id, "collection_detail")
	if bool(result.get("equipped", false)):
		selected_animal_id = animal_id
		_refresh_cards()


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
			(preview as TextureRect).modulate = Color(1, 1, 1, 1)
			(preview as TextureRect).set_meta("expression_state", "idle")
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
		var tween := _start_preview_expression_loop(preview as TextureRect, animated)
		_preview_tweens.append(tween)
		_active_preview_ids.append(animal_id)
		animated += 1


func _start_preview_expression_loop(preview: TextureRect, stagger_index: int) -> Tween:
	preview.pivot_offset = preview.size * 0.5
	_set_preview_expression_state(preview, "blink")
	var base_modulate := Color(1, 1, 1, 1)
	var smile_modulate := Color(1.10, 1.08, 1.03, 1)
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.10 * float(stagger_index))
	tween.tween_callback(_set_preview_expression_state.bind(preview, "blink"))
	tween.tween_property(preview, "scale", Vector2(1.02, 0.86), 0.08)
	tween.tween_property(preview, "scale", Vector2.ONE, 0.10)
	tween.tween_callback(_set_preview_expression_state.bind(preview, "smile"))
	tween.tween_property(preview, "scale", Vector2(1.06, 1.06), 0.36)
	tween.parallel().tween_property(preview, "modulate", smile_modulate, 0.18)
	tween.tween_property(preview, "scale", Vector2.ONE, 0.44)
	tween.parallel().tween_property(preview, "modulate", base_modulate, 0.44)
	tween.tween_callback(_set_preview_expression_state.bind(preview, "idle"))
	tween.tween_interval(0.75)
	return tween


func _set_preview_expression_state(preview: TextureRect, expression_id: String) -> void:
	if preview == null:
		return
	preview.set_meta("expression_state", expression_id)


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


func _preview_expression_states_for_testing() -> Dictionary:
	var states := {}
	for animal_id_value in preview_nodes.keys():
		var animal_id := String(animal_id_value)
		var preview = preview_nodes[animal_id_value]
		if preview is TextureRect:
			states[animal_id] = String((preview as TextureRect).get_meta("expression_state", ""))
	return states


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


func _collection_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.10, 0.18, 0.28, 0.18)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 5)
	return style


func _card_style(unlocked: bool, is_new: bool, is_selected: bool, equipped_reward_type: String = "") -> StyleBoxFlat:
	var bg_color := Color("ffffff") if unlocked else Color("e3e8ef")
	var border_color := Color("8ee5c5") if unlocked else Color("b7c1cf")
	var border_width := 2
	var has_equipped_frame := unlocked and equipped_reward_type == "card_frame"
	if is_new:
		bg_color = Color("fff8d9")
		border_color = Color("ffd15f")
		border_width = 3
	if has_equipped_frame:
		if not is_new:
			bg_color = Color("fffdfa")
		border_color = Color("ff74a8")
		border_width = maxi(border_width, 4)
	if is_selected:
		bg_color = Color("fff7fb") if unlocked else Color("edf1f6")
		border_color = Color("ff6fae")
		border_width = 5 if has_equipped_frame else 4
	var style := _collection_style(bg_color, border_color, 20, border_width)
	style.shadow_color = Color(0.12, 0.18, 0.28, 0.24 if is_selected else (0.18 if has_equipped_frame else 0.14))
	style.shadow_size = 13 if is_selected else (9 if has_equipped_frame else 7)
	return style


func _style_cosmetic_button(button: Button, earned: bool, equipped: bool) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("213a55"))
	button.add_theme_color_override("font_disabled_color", Color("6f7a88"))
	if equipped:
		button.add_theme_stylebox_override("disabled", _collection_style(Color("fff0a8"), Color("ff74a8"), 16, 3))
	elif earned:
		button.add_theme_stylebox_override("normal", _collection_style(Color("ffffff"), Color("70cfff"), 16, 3))
		button.add_theme_stylebox_override("hover", _collection_style(Color("e9fbff"), Color("6ec6ff"), 16, 3))
		button.add_theme_stylebox_override("pressed", _collection_style(Color("d8f6ff"), Color("6ec6ff"), 16, 3))
	else:
		button.add_theme_stylebox_override("disabled", _collection_style(Color("e8edf4"), Color("b7c1cf"), 16, 2))


func _apply_responsive_layout() -> void:
	if safe_margin == null or card_grid == null:
		return
	MobileLayout.apply_safe_area(safe_margin, self, 18)
	var viewport_size := get_viewport_rect().size
	var portrait := viewport_size.y >= viewport_size.x
	card_grid.columns = 2 if portrait else 6
	card_grid.add_theme_constant_override("h_separation", 14 if portrait else 10)
	card_grid.add_theme_constant_override("v_separation", 14 if portrait else 10)
	if header_panel != null:
		header_panel.custom_minimum_size = Vector2(0, 0)
	if header_margin != null:
		header_margin.add_theme_constant_override("margin_left", 14 if portrait else 30)
		header_margin.add_theme_constant_override("margin_top", 12 if portrait else 20)
		header_margin.add_theme_constant_override("margin_right", 14 if portrait else 30)
		header_margin.add_theme_constant_override("margin_bottom", 12 if portrait else 20)
	if back_button != null:
		back_button.custom_minimum_size = Vector2(96, 50) if portrait else Vector2(128, 78)
		back_button.add_theme_font_size_override("font_size", 20 if portrait else 34)
	var title_label := find_child("TitleLabel", true, false) as Label
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 32 if portrait else 46)
	if summary_label != null:
		summary_label.add_theme_font_size_override("font_size", 17 if portrait else 24)
	if detail_label != null:
		detail_label.add_theme_font_size_override("font_size", 16 if portrait else 24)
	if cosmetic_grid != null:
		cosmetic_grid.columns = 2 if portrait else 3
		cosmetic_grid.add_theme_constant_override("h_separation", 7 if portrait else 14)
		cosmetic_grid.add_theme_constant_override("v_separation", 7 if portrait else 12)
		for child in cosmetic_grid.get_children():
			var button := child as Button
			if button != null:
				button.custom_minimum_size = _cosmetic_action_button_minimum_size(viewport_size)
				button.add_theme_font_size_override("font_size", _cosmetic_action_button_font_size(viewport_size))
	_apply_collection_card_responsive_layout(viewport_size)
	_queue_preview_motion_sync()


func _apply_collection_card_responsive_layout(viewport_size: Vector2) -> void:
	if card_grid == null:
		return
	var card_min := _collection_card_minimum_size(viewport_size)
	var preview_size := _collection_preview_size(viewport_size)
	var name_font := _collection_name_font_size(viewport_size)
	var status_font := _collection_status_font_size(viewport_size)
	var cosmetic_font := _collection_cosmetic_font_size(viewport_size)
	for candidate in card_grid.get_children():
		var card := candidate as PanelContainer
		if card == null or not String(card.name).begins_with("AnimalCard_"):
			continue
		card.custom_minimum_size = card_min
		var preview := card.find_child("AnimalPreview", true, false) as Control
		if preview != null:
			preview.custom_minimum_size = preview_size
		var name_label := card.find_child("AnimalNameLabel", true, false) as Label
		if name_label != null:
			name_label.add_theme_font_size_override("font_size", name_font)
		var name_visual := card.find_child("AnimalNameVisual", true, false) as Button
		if name_visual != null:
			if name_label != null:
				name_visual.text = name_label.text
			name_visual.custom_minimum_size = _collection_name_label_minimum_size(viewport_size)
			name_visual.add_theme_font_size_override("font_size", name_font)
		var status_label := card.find_child("AnimalStatusLabel", true, false) as Label
		if status_label != null:
			status_label.add_theme_font_size_override("font_size", status_font)
		var status_visual := card.find_child("AnimalStatusVisual", true, false) as Button
		if status_visual != null:
			if status_label != null:
				status_visual.text = status_label.text
			status_visual.custom_minimum_size = _collection_status_label_minimum_size(viewport_size)
			status_visual.add_theme_font_size_override("font_size", status_font)
		var cosmetic_label := card.find_child("AnimalCosmeticLabel", true, false) as Label
		if cosmetic_label != null:
			cosmetic_label.visible = false
			cosmetic_label.custom_minimum_size = _collection_cosmetic_label_minimum_size(viewport_size)
			cosmetic_label.add_theme_font_size_override("font_size", cosmetic_font)
		var badge := card.find_child("EquippedCosmeticBadge*", true, false) as Control
		if badge != null:
			badge.custom_minimum_size = _equipped_badge_minimum_size(viewport_size)
			var badge_label := badge.find_child("EquippedCosmeticBadgeLabel", true, false) as Label
			if badge_label != null:
				badge_label.add_theme_font_size_override("font_size", _equipped_badge_font_size(viewport_size))


func _collection_card_minimum_size(viewport_size: Vector2) -> Vector2:
	var portrait := viewport_size.y >= viewport_size.x
	if portrait:
		return Vector2(0, maxf(420.0, viewport_size.y * 0.185))
	return Vector2(0, maxf(450.0, viewport_size.y * 0.26))


func _collection_preview_size(viewport_size: Vector2) -> Vector2:
	var portrait := viewport_size.y >= viewport_size.x
	var side := maxf(204.0, viewport_size.y * (0.086 if portrait else 0.125))
	return Vector2(side, side)


func _collection_name_font_size(viewport_size: Vector2) -> int:
	return 36 if viewport_size.y >= viewport_size.x else 42


func _collection_name_label_minimum_size(viewport_size: Vector2) -> Vector2:
	return Vector2(0, 54 if viewport_size.y >= viewport_size.x else 54)


func _collection_status_font_size(viewport_size: Vector2) -> int:
	return 26 if viewport_size.y >= viewport_size.x else 32


func _collection_status_label_minimum_size(viewport_size: Vector2) -> Vector2:
	return Vector2(0, 42 if viewport_size.y >= viewport_size.x else 44)


func _collection_cosmetic_font_size(viewport_size: Vector2) -> int:
	return 24 if viewport_size.y >= viewport_size.x else 30


func _collection_cosmetic_label_minimum_size(viewport_size: Vector2) -> Vector2:
	return Vector2(0, 36 if viewport_size.y >= viewport_size.x else 42)


func _equipped_badge_minimum_size(viewport_size: Vector2) -> Vector2:
	return Vector2(0, 48 if viewport_size.y >= viewport_size.x else 58)


func _equipped_badge_font_size(viewport_size: Vector2) -> int:
	return 22 if viewport_size.y >= viewport_size.x else 28


func _cosmetic_action_button_minimum_size(viewport_size: Vector2) -> Vector2:
	return Vector2(132, 44) if viewport_size.y >= viewport_size.x else Vector2(280, 88)


func _cosmetic_action_button_font_size(viewport_size: Vector2) -> int:
	return 16 if viewport_size.y >= viewport_size.x else 32


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
