extends Button

signal stage_selected(stage_id: int)

const GameSession = preload("res://scripts/game_session.gd")
const FRAME_DEFAULT_PATH := "res://assets/ui/meta/stage_card_frame.svg"
const FRAME_CURRENT_PATH := "res://assets/ui/meta/stage_card_frame_current.svg"
const FRAME_CLEARED_PATH := "res://assets/ui/meta/stage_card_frame_cleared.svg"
const FRAME_FINALE_PATH := "res://assets/ui/meta/stage_card_frame_finale.svg"
const FRAME_LOCKED_PATH := "res://assets/ui/meta/stage_card_frame_locked.svg"

@onready var card_frame: TextureRect = $CardFrame
@onready var stage_label: Label = $CardMargin/CardColumn/StageLabel
@onready var difficulty_label: Label = $CardMargin/CardColumn/HeaderRow/DifficultyPill/DifficultyLabel
@onready var star_row: HBoxContainer = $CardMargin/CardColumn/StarRow
@onready var status_label: Label = $CardMargin/CardColumn/StatusLabel
@onready var lock_overlay: ColorRect = $LockOverlay
@onready var current_badge: TextureRect = $CurrentBadge
@onready var finale_badge: TextureRect = $FinaleBadge

var stage_id := 0


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(stage_def: Dictionary, unlocked: bool, best_stars: int) -> void:
	_ensure_refs()
	stage_id = int(stage_def.get("id", 0))
	disabled = not unlocked
	stage_label.text = "Stage %d" % stage_id
	difficulty_label.text = String(stage_def.get("difficulty", "Easy"))
	lock_overlay.visible = not unlocked
	_update_status_badges(unlocked)
	_apply_frame_variant(unlocked, best_stars)
	status_label.text = _status_text(unlocked, best_stars)
	_rebuild_stars(best_stars)


func _rebuild_stars(best_stars: int) -> void:
	_ensure_refs()
	for child in star_row.get_children():
		child.queue_free()

	if best_stars <= 0:
		var empty_label := Label.new()
		empty_label.text = "첫 클리어 도전"
		empty_label.add_theme_color_override("font_color", Color("6d7a8a"))
		empty_label.add_theme_font_size_override("font_size", 18)
		star_row.add_child(empty_label)
		return

	for _i in range(best_stars):
		var star := Label.new()
		star.text = "★"
		star.add_theme_color_override("font_color", Color("ffd95a"))
		star.add_theme_font_size_override("font_size", 22)
		star_row.add_child(star)


func _on_pressed() -> void:
	stage_selected.emit(stage_id)


func _ensure_refs() -> void:
	if card_frame == null:
		card_frame = get_node("CardFrame")
	if stage_label == null:
		stage_label = get_node("CardMargin/CardColumn/StageLabel")
	if difficulty_label == null:
		difficulty_label = get_node("CardMargin/CardColumn/HeaderRow/DifficultyPill/DifficultyLabel")
	if star_row == null:
		star_row = get_node("CardMargin/CardColumn/StarRow")
	if status_label == null:
		status_label = get_node("CardMargin/CardColumn/StatusLabel")
	if lock_overlay == null:
		lock_overlay = get_node("LockOverlay")
	if current_badge == null:
		current_badge = get_node("CurrentBadge")
	if finale_badge == null:
		finale_badge = get_node("FinaleBadge")


func _update_status_badges(unlocked: bool) -> void:
	_ensure_refs()
	current_badge.visible = unlocked and stage_id == GameSession.get_selected_stage_id()
	finale_badge.visible = unlocked and stage_id % 10 == 0


func _apply_frame_variant(unlocked: bool, best_stars: int) -> void:
	_ensure_refs()
	if not unlocked:
		card_frame.texture = _load_frame_texture(FRAME_LOCKED_PATH)
		return
	if stage_id % 10 == 0:
		card_frame.texture = _load_frame_texture(FRAME_FINALE_PATH)
		return
	if stage_id == GameSession.get_selected_stage_id():
		card_frame.texture = _load_frame_texture(FRAME_CURRENT_PATH)
		return
	if best_stars > 0:
		card_frame.texture = _load_frame_texture(FRAME_CLEARED_PATH)
		return
	card_frame.texture = _load_frame_texture(FRAME_DEFAULT_PATH)


func _load_frame_texture(resource_path: String) -> Texture2D:
	var texture := load(resource_path)
	if texture is Texture2D:
		return texture
	return null


func _status_text(unlocked: bool, best_stars: int) -> String:
	if not unlocked:
		return "잠김"
	if stage_id == GameSession.get_selected_stage_id():
		return "현재 진행"
	if best_stars > 0:
		return "클리어"
	if stage_id % 10 == 0:
		return "피날레"
	return "도전 가능"
