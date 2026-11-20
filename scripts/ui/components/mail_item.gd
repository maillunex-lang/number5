@tool
class_name MailItem
extends PanelContainer
## Карточка письма. Claim-кнопка опциональна.

signal claim_pressed(mail_id: String)

@export_category("Lunex Mail Item")
@export var subject_text: String = "Тема":
	set(v):
		subject_text = v
		if _subject:
			_subject.text = v
@export var body_text: String = "":
	set(v):
		body_text = v
		if _body:
			_body.text = v

var mail_id: String = ""

@onready var _subject: Label = $Pad/Col/Subject
@onready var _body: Label = $Pad/Col/Body
@onready var _atts: Label = $Pad/Col/Attachments
@onready var _claim: Button = $Pad/Col/ClaimBtn
@onready var _status: Label = $Pad/Col/Status

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	if Engine.is_editor_hint():
		if _subject:
			_subject.text = subject_text
		if _body:
			_body.text = body_text
		if _claim:
			_claim.visible = true
		return
	if _claim and not _claim.pressed.is_connected(_on_claim):
		_claim.pressed.connect(_on_claim)

func set_mail(data: Dictionary) -> void:
	mail_id = str(data.get("id", ""))
	var status: String = str(data.get("status", "unread"))
	var cat: String = str(data.get("category", ""))
	var subject: String = str(data.get("subject", data.get("title", "")))
	var mark: String = "●" if status == "unread" else ("✓" if status == "claimed" else "○")
	if _subject:
		_subject.text = "%s [%s] %s" % [mark, cat, subject]
	if _body:
		_body.text = str(data.get("body", ""))
	var atts: Array = data.get("attachments", []) as Array
	if _atts:
		if atts.is_empty():
			_atts.text = "Без вложений"
		else:
			var parts: PackedStringArray = []
			for a in atts:
				if typeof(a) != TYPE_DICTIONARY:
					continue
				parts.append("%s×%s" % [str(a.get("resource_id", "")), str(a.get("amount", 0))])
			_atts.text = ", ".join(parts)
	var can_claim: bool = (not atts.is_empty()) and status != "claimed"
	if _claim:
		_claim.visible = can_claim
	if _status:
		_status.visible = (not atts.is_empty()) and status == "claimed"
		_status.text = "Уже получено"

func _on_claim() -> void:
	claim_pressed.emit(mail_id)
