@tool
class_name ProgressMeter
extends VBoxContainer
## Подписанный ProgressBar для HP/XP/VIP.

@export_category("Lunex Progress")
@export var title: String = "Прогресс":
	set(v):
		title = v
		if _title:
			_title.text = v
@export var max_value: float = 100.0:
	set(v):
		max_value = maxf(v, 1.0)
		if _bar:
			_bar.max_value = max_value
@export var value: float = 40.0:
	set(v):
		value = v
		if _bar:
			_bar.value = value
@export var bar_color: Color = Color("E8C56A"):
	set(v):
		bar_color = v
		_apply_fill()
@export var show_percent: bool = false:
	set(v):
		show_percent = v
		if _bar:
			_bar.show_percentage = v

@onready var _title: Label = $Title
@onready var _bar: ProgressBar = $Bar

func _ready() -> void:
	if _title:
		_title.text = title
	if _bar:
		_bar.max_value = max_value
		_bar.value = value
		_bar.show_percentage = show_percent
	_apply_fill()

func set_progress(current: float, maximum: float) -> void:
	max_value = maximum
	value = current

func _apply_fill() -> void:
	if _bar == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = bar_color
	sb.set_corner_radius_all(8)
	_bar.add_theme_stylebox_override("fill", sb)
