@tool
class_name MapRegionButton
extends Button
## Кнопка региона на мировой карте. Позиция и текст — set_region().

signal region_pressed(region_id: String)

@export_category("Lunex Map Region")
@export var region_id: String = "CH01"
@export var region_title: String = "Регион":
	set(v):
		region_title = v
		_refresh_text()
@export var unlocked: bool = true:
	set(v):
		unlocked = v
		_refresh_text()

var _req: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(420, 200)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_refresh_text()
	if Engine.is_editor_hint():
		return
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func set_region(data: Dictionary) -> void:
	region_id = str(data.get("id", region_id))
	region_title = str(data.get("name", region_title))
	unlocked = bool(data.get("unlocked", true))
	_req = str(data.get("req", ""))
	var px := float(data.get("x", position.x))
	var py := float(data.get("y", position.y))
	position = Vector2(px, py)
	_refresh_text()

func _refresh_text() -> void:
	var status := "Открыт" if unlocked else "Закрыто · %s" % _req
	text = "%s\n%s" % [region_title, status]

func _on_pressed() -> void:
	region_pressed.emit(region_id)
