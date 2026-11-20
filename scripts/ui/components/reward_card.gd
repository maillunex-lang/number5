@tool
class_name RewardCard
extends PanelContainer
## Строка/карточка награды для модалок и списков.

@export_category("Lunex Reward")
@export var line_text: String = "Золото ×1000":
	set(v):
		line_text = v
		if _label:
			_label.text = v
@export var accent: Color = Color("E8C56A"):
	set(v):
		accent = v
		if _dot:
			_dot.color = v

@onready var _label: Label = $Pad/Row/Text
@onready var _dot: ColorRect = $Pad/Row/Dot

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	if _label:
		_label.text = line_text
	if _dot:
		_dot.color = accent

func set_line(text: String) -> void:
	line_text = text
