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
var _face: TextureRect = null

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	custom_minimum_size = Vector2(160, 200)
	_ensure_face()
	if Engine.is_editor_hint():
		clear_slot()
		if _empty:
			_empty.text = empty_label

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
	_ensure_face()
	var has := not data.is_empty()
	if _empty:
		_empty.visible = not has
	if _portrait:
		_portrait.visible = has
	if _name:
		_name.visible = has
	if not has:
		if _face:
			_face.texture = null
		return
	if _name:
		_name.text = str(data.get("name", ""))
	var hid := str(data.get("id", ""))
	var tex: Texture2D = null
	if not Engine.is_editor_hint() and hid != "":
		tex = AssetLoader.hero_portrait(hid)
	if _face:
		_face.texture = tex
	if _portrait:
		var t: Variant = data.get("tint", Color("5EC8E8"))
		var tint: Color = t if typeof(t) == TYPE_COLOR else Color(str(t))
		_portrait.color = Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1) if tex == null else Color(0.08, 0.1, 0.14, 1)

func clear_slot() -> void:
	set_hero({})
