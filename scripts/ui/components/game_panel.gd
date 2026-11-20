@tool
class_name GamePanel
extends PanelContainer
## Панель с Theme type GamePanel / PopupPanel.

@export_category("Lunex Panel")
@export_enum("GamePanel", "PopupPanel") var panel_kind: String = "GamePanel":
	set(v):
		panel_kind = v
		theme_type_variation = StringName(v)
@export var content_min_size: Vector2 = Vector2(0, 0):
	set(v):
		content_min_size = v
		if content_min_size != Vector2.ZERO:
			custom_minimum_size = content_min_size

func _ready() -> void:
	theme_type_variation = StringName(panel_kind)
	if content_min_size != Vector2.ZERO:
		custom_minimum_size = content_min_size
