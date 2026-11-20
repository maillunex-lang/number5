@tool
class_name SettingsSection
extends VBoxContainer
## Секция настроек: заголовок + host для контролов.

@export_category("Lunex Settings Section")
@export var section_title: String = "Раздел":
	set(v):
		section_title = v
		if _title:
			_title.text = v

@onready var _title: Label = $Title
@onready var content: VBoxContainer = $Content

func _ready() -> void:
	if _title:
		_title.text = section_title

func clear_content() -> void:
	if content == null:
		return
	for c in content.get_children():
		c.queue_free()
