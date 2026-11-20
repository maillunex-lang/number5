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
var _face: TextureRect = null

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	custom_minimum_size = card_size
	_ensure_face()
	_apply_preview()
	gui_input.connect(_on_gui)
	if not Engine.is_editor_hint():
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _ensure_face() -> void:
	if _face != null or _portrait == null:
		return
	_face = TextureRect.new()
	_face.name = "Face"
	_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.add_child(_face)

func set_hero(data: Dictionary) -> void:
	hero_id = str(data.get("id", hero_id))
	display_name = str(data.get("name", display_name))
	power_text = str(data.get("power", power_text))
	if data.has("tint"):
		var t = data["tint"]
		tint = t if typeof(t) == TYPE_COLOR else Color(str(t))
	_apply_preview()

func _apply_preview() -> void:
	_ensure_face()
	if _name:
		_name.text = display_name
	if _power:
		_power.text = "Сила %s" % power_text
	var tex: Texture2D = null
	if not Engine.is_editor_hint() and hero_id != "":
		tex = AssetLoader.hero_portrait(hero_id)
	if _face:
		_face.texture = tex
	if _portrait:
		_portrait.color = Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1) if tex == null else Color(0.08, 0.1, 0.14, 1)

func _on_gui(ev: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(hero_id)
