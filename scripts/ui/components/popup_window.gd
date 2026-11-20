@tool
class_name PopupWindow
extends PanelContainer
## Каркас всплывающего окна. Кнопки OK/Cancel опциональны.

signal confirmed
signal cancelled

@export_category("Lunex Popup")
@export var title_text: String = "Окно":
	set(v):
		title_text = v
		if _title:
			_title.text = v
@export var body_text: String = "":
	set(v):
		body_text = v
		if _body:
			_body.text = v
@export var show_cancel: bool = true:
	set(v):
		show_cancel = v
		if _cancel:
			_cancel.visible = v

@onready var _title: Label = $Pad/Col/Title
@onready var _body: Label = $Pad/Col/Body
@onready var _ok: Button = $Pad/Col/Buttons/Ok
@onready var _cancel: Button = $Pad/Col/Buttons/Cancel
@onready var dynamic_host: VBoxContainer = $Pad/Col/DynamicHost

func _ready() -> void:
	theme_type_variation = &"PopupPanel"
	if _title:
		_title.text = title_text
	if _body:
		_body.text = body_text
	if _cancel:
		_cancel.visible = show_cancel
	if not Engine.is_editor_hint():
		_ok.pressed.connect(func(): confirmed.emit())
		_cancel.pressed.connect(func(): cancelled.emit())
