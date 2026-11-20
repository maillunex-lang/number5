@tool
class_name IconButton
extends Button
## Квадратная кнопка с иконкой (магазин, настройки, назад).

@export_category("Lunex Icon Button")
@export var icon_texture: Texture2D:
	set(v):
		icon_texture = v
		icon = v
@export var box_size: Vector2 = Vector2(96, 78):
	set(v):
		box_size = v
		custom_minimum_size = v
@export var label_text: String = "":
	set(v):
		label_text = v
		text = v

func _ready() -> void:
	custom_minimum_size = box_size
	theme_type_variation = &"GameButton"
	if icon_texture:
		icon = icon_texture
	if label_text != "":
		text = label_text
	if not Engine.is_editor_hint() and not pressed.is_connected(_sfx):
		pressed.connect(_sfx)

func _sfx() -> void:
	if AudioManager:
		AudioManager.play_ui_tap()
