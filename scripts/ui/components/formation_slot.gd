@tool
class_name FormationSlot
extends PanelContainer
## Слот отряда на экране подготовки. Данные — set_hero / clear_slot.

@export_category("Lunex Formation Slot")
@export var empty_label: String = "Пусто":
	set(v):
		empty_label = v
		if Engine.is_editor_hint() and _empty:
			_empty.text = v

@onready var _portrait: ColorRect = $Pad/Col/Portrait
@onready var _name: Label = $Pad/Col/Name
@onready var _empty: Label = $Pad/Col/Empty

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	custom_minimum_size = Vector2(160, 200)
	if Engine.is_editor_hint():
		clear_slot()
		if _empty:
			_empty.text = empty_label

func set_hero(data: Dictionary) -> void:
	var has := not data.is_empty()
	if _empty:
		_empty.visible = not has
	if _portrait:
		_portrait.visible = has
	if _name:
		_name.visible = has
	if not has:
		return
	if _name:
		_name.text = str(data.get("name", ""))
	if _portrait:
		var t: Variant = data.get("tint", Color("5EC8E8"))
		var tint: Color = t if typeof(t) == TYPE_COLOR else Color(str(t))
		_portrait.color = Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1)

func clear_slot() -> void:
	set_hero({})
