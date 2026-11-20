@tool
class_name GameButton
extends Button
## Визуальная кнопка Lunex. Стили — Theme type GameButton / GoldButton.

@export_category("Lunex Button")
@export_group("Layout")
@export var min_height: int = 64:
	set(v):
		min_height = maxi(v, 40)
		custom_minimum_size.y = float(min_height)
@export var expand_horizontal: bool = true:
	set(v):
		expand_horizontal = v
		size_flags_horizontal = SIZE_EXPAND_FILL if v else SIZE_SHRINK_BEGIN

@export_group("Style")
@export var gold_style: bool = false:
	set(v):
		gold_style = v
		_apply_type()

@export_group("Preview")
@export var preview_label: String = "":
	set(v):
		preview_label = v
		if Engine.is_editor_hint() and preview_label != "":
			text = preview_label

func _ready() -> void:
	custom_minimum_size.y = float(min_height)
	if expand_horizontal:
		size_flags_horizontal = SIZE_EXPAND_FILL
	_apply_type()
	if not Engine.is_editor_hint():
		if not pressed.is_connected(_on_pressed_sfx):
			pressed.connect(_on_pressed_sfx)

func _apply_type() -> void:
	theme_type_variation = &"GoldButton" if gold_style else &"GameButton"

func _on_pressed_sfx() -> void:
	if AudioManager:
		AudioManager.play_ui_tap()
