@tool
class_name HeroCard
extends PanelContainer
## Карточка героя для списков. Данные — set_hero() / preview exports.

signal selected(hero_id: String)

@export_category("Lunex Hero Card")
@export var hero_id: String = "H01"
@export var display_name: String = "Герой":
	set(v):
		display_name = v
		_apply_preview()
@export var tint: Color = Color("5EC8E8"):
	set(v):
		tint = v
		_apply_preview()
@export var power_text: String = "2866":
	set(v):
		power_text = v
		_apply_preview()
@export var card_size: Vector2 = Vector2(200, 280):
	set(v):
		card_size = v
		custom_minimum_size = v

@onready var _name: Label = $Pad/Col/Name
@onready var _power: Label = $Pad/Col/Power
@onready var _portrait: ColorRect = $Pad/Col/Portrait

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	custom_minimum_size = card_size
	_apply_preview()
	gui_input.connect(_on_gui)
	if not Engine.is_editor_hint():
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_hero(data: Dictionary) -> void:
	hero_id = str(data.get("id", hero_id))
	display_name = str(data.get("name", display_name))
	power_text = str(data.get("power", power_text))
	if data.has("tint"):
		var t = data["tint"]
		tint = t if typeof(t) == TYPE_COLOR else Color(str(t))
	_apply_preview()

func _apply_preview() -> void:
	if _name:
		_name.text = display_name
	if _power:
		_power.text = "Сила %s" % power_text
	if _portrait:
		_portrait.color = Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1)

func _on_gui(ev: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(hero_id)
