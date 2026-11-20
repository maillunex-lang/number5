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

@onready var _title: Label = $Pad/Col/Title
@onready var _meta: Label = $Pad/Col/Meta
@onready var _hint: Label = $Pad/Col/Hint
@onready var _open: Button = $Pad/Col/Row/OpenBtn
@onready var _fight: Button = $Pad/Col/Row/FightBtn

func _ready() -> void:
	theme_type_variation = &"GamePanel"
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

func set_stage(data: Dictionary) -> void:
	stage_id = str(data.get("id", ""))
	var state: String = str(data.get("state", "locked"))
	_locked = state == "locked"
	var type_map := {"main": "Основной", "side": "Доп.", "secret": "Секрет"}
	var type_key := str(data.get("type", "main"))
	var type_label: String = str(type_map.get(type_key, type_key))
	var title: String = "%s · %s" % [type_label, str(data.get("name", ""))]
	if state == "locked":
		title = "🔒 " + title
	elif state == "cleared":
		title = "✓ " + title
	if _title:
		_title.text = title
		_title.add_theme_color_override("font_color", LunexColors.GOLD if state == "available" else LunexColors.TEXT_SECONDARY)
	var rewards: Array = data.get("rewards", [])
	if _meta:
		_meta.text = "Сила: %d · Награды: %s" % [int(data.get("power", 0)), ", ".join(PackedStringArray(rewards))]
	var hint := str(data.get("reveal_hint", ""))
	if _hint:
		_hint.visible = _locked and hint != ""
		_hint.text = hint
	if _open:
		_open.disabled = _locked and type_key != "secret"
		if type_key == "secret" and _locked and state != "available":
			_open.disabled = true
	if _fight:
		_fight.visible = state == "available"

func _on_open() -> void:
	open_pressed.emit(stage_id)

func _on_fight() -> void:
	fight_pressed.emit(stage_id)
