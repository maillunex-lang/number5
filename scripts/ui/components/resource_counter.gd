@tool
class_name ResourceCounter
extends PanelContainer
## Счётчик ресурса (золото/алмазы/VIP). Текст значения задаёт код или preview.

@export_category("Lunex Resource")
@export var icon_glyph: String = "◈":
	set(v):
		icon_glyph = v
		_refresh_labels()
@export var value_text: String = "0":
	set(v):
		value_text = v
		_refresh_labels()
@export var accent: Color = Color("E8C56A"):
	set(v):
		accent = v
		_refresh_labels()
@export var caption: String = "":
	set(v):
		caption = v
		_refresh_labels()

@onready var _icon: Label = $Pad/Row/Icon
@onready var _value: Label = $Pad/Row/Value

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	_refresh_labels()

func set_value(v: Variant) -> void:
	value_text = str(v)

func _refresh_labels() -> void:
	if _icon == null or _value == null:
		return
	_icon.text = icon_glyph if caption == "" else caption
	_icon.add_theme_color_override("font_color", accent)
	_value.text = value_text
