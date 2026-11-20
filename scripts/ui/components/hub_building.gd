@tool
class_name HubBuilding
extends Button
## Шаблон здания хаба. Позиция/данные — из hub.json через set_building().

signal activated(building_id: String)

@export_category("Lunex Hub Building")
@export var preview_title: String = "Здание":
	set(v):
		preview_title = v
		if _title:
			_title.text = v
@export var preview_tint: Color = Color("E8C56A"):
	set(v):
		preview_tint = v
		_apply_style(preview_tint, false)
@export var building_size: Vector2 = Vector2(240, 210):
	set(v):
		building_size = v
		custom_minimum_size = v

var building_id: String = ""
var route: String = ""
var payload: Dictionary = {}
var locked: bool = false
var req_text: String = ""

@onready var _panel: Panel = $Panel
@onready var _title: Label = $Title
@onready var _symbol: TextureRect = $Symbol
@onready var _lock: Label = $Lock

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = building_size
	text = ""
	if Engine.is_editor_hint():
		if _title:
			_title.text = preview_title
		_apply_style(preview_tint, false)
		if _lock:
			_lock.visible = false
		return
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func pulse_target() -> Control:
	return _panel

func set_building(def: Dictionary, glow_strength: float = 0.45) -> void:
	building_id = str(def.get("id", ""))
	route = str(def.get("route", ""))
	payload = def.get("payload", {})
	locked = bool(def.get("locked", false))
	req_text = str(def.get("req", ""))
	var bw: float = maxf(float(def.get("w", building_size.x)) * 1.30, 240.0)
	var bh: float = maxf(float(def.get("h", building_size.y)) * 1.25, 210.0)
	building_size = Vector2(bw, bh)
	custom_minimum_size = building_size
	position = Vector2(float(def.get("x", 0)) - bw * 0.5, float(def.get("y", 0)) - bh * 0.5)
	if _title:
		_title.text = str(def.get("name", preview_title))
		_title.add_theme_color_override("font_color", LunexColors.TEXT_PRIMARY if not locked else LunexColors.TEXT_MUTED)
	var c: Color = def.get("color", preview_tint)
	if typeof(c) != TYPE_COLOR:
		c = Color(str(c))
	_apply_style(c, locked, glow_strength)
	var symbols: Dictionary = {
		"summon": "events", "guild": "social", "shop": "shop", "tower": "tower",
		"quests": "quests", "afk": "rewards", "workshop": "tools", "portal": "expeditions",
	}
	var icon_key: String = str(symbols.get(building_id, "map"))
	var icon_path: String = "res://assets/ui/navigation/%s.svg" % icon_key
	if _symbol and ResourceLoader.exists(icon_path):
		_symbol.texture = load(icon_path)
	if _lock:
		_lock.visible = locked

func _apply_style(c: Color, is_locked: bool, glow_str: float = 0.45) -> void:
	if _panel == null:
		return
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.055, 0.087, 0.14, 0.92)
	st.border_color = LunexColors.TEXT_MUTED if is_locked else c
	st.set_border_width_all(2)
	st.set_corner_radius_all(18)
	st.shadow_color = Color(c.r, c.g, c.b, 0.25 + glow_str * 0.35)
	st.shadow_size = int(3 + glow_str * 4)
	_panel.add_theme_stylebox_override("panel", st)

func _on_pressed() -> void:
	activated.emit(building_id)
