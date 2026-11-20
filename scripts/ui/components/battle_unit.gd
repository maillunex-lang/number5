@tool
class_name BattleUnit
extends Control
## Визуальный юнит боя. Спавн из timeline/squad; HP/energy обновляет playback.

@export_category("Lunex Battle Unit")
@export var unit_size: Vector2 = Vector2(140, 160):
	set(v):
		unit_size = v
		custom_minimum_size = v
@export var preview_name: String = "Юнит":
	set(v):
		preview_name = v
		if _name:
			_name.text = v
@export var preview_tint: Color = Color("5EC8E8"):
	set(v):
		preview_tint = v
		_paint_body(v)

var unit_id: String = ""
var side: String = "ally"

@onready var _body: ColorRect = $Body
@onready var _name: Label = $Name
@onready var _hp: ProgressBar = $HP
@onready var _energy: ProgressBar = $Energy

func _ready() -> void:
	custom_minimum_size = unit_size
	if Engine.is_editor_hint():
		if _name:
			_name.text = preview_name
		_paint_body(preview_tint)
		if _hp:
			_hp.max_value = 100
			_hp.value = 80
		if _energy:
			_energy.max_value = 100
			_energy.value = 30
			_energy.modulate = LunexColors.ENERGY

func set_unit(data: Dictionary) -> void:
	unit_id = str(data.get("id", ""))
	side = str(data.get("side", "ally"))
	if _name:
		_name.text = str(data.get("name", preview_name))
	var tint_raw: Variant = data.get("tint", preview_tint)
	var tint: Color = preview_tint
	if typeof(tint_raw) == TYPE_COLOR:
		tint = tint_raw
	elif str(tint_raw).begins_with("#"):
		tint = Color(str(tint_raw))
	_paint_body(tint)
	var max_hp: float = float(data.get("max_hp", data.get("hp", 1000)))
	if _hp:
		_hp.max_value = max_hp
		_hp.value = float(data.get("hp", max_hp))
	if _energy:
		_energy.max_value = 100
		_energy.value = float(data.get("energy", 0))
		_energy.modulate = LunexColors.ENERGY

func set_hp(v: float) -> void:
	if _hp:
		_hp.value = v

func set_energy(v: float) -> void:
	if _energy:
		_energy.value = v

func set_dead(dead: bool = true) -> void:
	modulate = Color(0.3, 0.3, 0.3, 0.5) if dead else Color.WHITE

func hp_bar() -> ProgressBar:
	return _hp

func energy_bar() -> ProgressBar:
	return _energy

func body_node() -> Control:
	return _body

func _paint_body(tint: Color) -> void:
	if _body:
		_body.color = Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1)
