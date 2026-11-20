@tool
class_name StageListItem
extends PanelContainer
## Строка этапа на карте главы. Кнопки — open_pressed / fight_pressed.

signal open_pressed(stage_id: String)
signal fight_pressed(stage_id: String)

@export_category("Lunex Stage List Item")
@export var title_text: String = "Этап":
	set(v):
		title_text = v
		if _title:
			_title.text = v
@export var meta_text: String = "Сила · награды":
	set(v):
		meta_text = v
		if _meta:
			_meta.text = v

var stage_id: String = ""
var _locked: bool = false
var _pending: Dictionary = {}

@onready var _title: Label = $Pad/Col/Title
@onready var _meta: Label = $Pad/Col/Meta
@onready var _hint: Label = $Pad/Col/Hint
@onready var _open: Button = $Pad/Col/Row/OpenBtn
@onready var _fight: Button = $Pad/Col/Row/FightBtn

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	# Let ScrollContainer receive vertical drag on the row chrome; only buttons capture taps.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad := get_node_or_null("Pad") as Control
	if pad:
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := get_node_or_null("Pad/Col") as Control
	if col:
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := get_node_or_null("Pad/Col/Row") as Control
	if row:
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Engine.is_editor_hint():
		if _title:
			_title.text = title_text
		if _meta:
			_meta.text = meta_text
		return
	if _open and not _open.pressed.is_connected(_on_open):
		_open.pressed.connect(_on_open)
	if _fight and not _fight.pressed.is_connected(_on_fight):
		_fight.pressed.connect(_on_fight)
	if not _pending.is_empty():
		_apply_stage(_pending)
		_pending = {}

func set_stage(data: Dictionary) -> void:
	stage_id = str(data.get("id", ""))
	if _title == null:
		_pending = data.duplicate(true)
		return
	_apply_stage(data)

func _apply_stage(data: Dictionary) -> void:
	stage_id = str(data.get("id", ""))
	var state: String = str(data.get("state", "locked"))
	_locked = state == "locked"
	var type_map := {
		"main": "Основной",
		"story": "Сюжет",
		"side": "Доп.",
		"secret": "Секрет",
		"elite": "Элита",
		"boss": "Босс",
		"final_boss": "Финал",
	}
	var type_key := str(data.get("type", "main"))
	var type_label: String = str(type_map.get(type_key, type_key))
	var title: String = "%s · %s" % [type_label, str(data.get("name", ""))]
	if state == "locked":
		title = "🔒 " + title
	elif state == "cleared":
		title = "✓ " + title
	elif state == "current":
		title = "▶ " + title
	title_text = title
	if _title:
		_title.text = title
		var accent := state == "available" or state == "current"
		_title.add_theme_color_override("font_color", LunexColors.GOLD if accent else LunexColors.TEXT_SECONDARY)
	var rewards: Array = data.get("rewards", [])
	var reward_bits: PackedStringArray = PackedStringArray()
	for r in rewards:
		if typeof(r) == TYPE_DICTIONARY:
			reward_bits.append(str(r.get("name", r.get("id", r))))
		else:
			reward_bits.append(str(r))
	meta_text = "Сила: %d · Награды: %s" % [int(data.get("power", 0)), ", ".join(reward_bits)]
	if _meta:
		_meta.text = meta_text
	var hint := str(data.get("reveal_hint", ""))
	if _hint:
		_hint.visible = _locked and hint != ""
		_hint.text = hint
	if _open:
		_open.disabled = _locked and type_key != "secret"
		if type_key == "secret" and _locked and state != "available" and state != "current":
			_open.disabled = true
	if _fight:
		_fight.visible = state == "available" or state == "current"

func _on_open() -> void:
	open_pressed.emit(stage_id)

func _on_fight() -> void:
	fight_pressed.emit(stage_id)
