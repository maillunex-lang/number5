extends Control
## SOCIAL-03 friends: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Друзья"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Список",
			"lines": [
				"Лира Ветров · Lv.18 · сила 42000",
				"Боро Камень · Lv.15 · сила 31000",
			],
			"actions": [
				{"label": "Подарок (демо)", "kind": "toast", "msg": "Подарок отмечен локально"},
				{"label": "Заявки", "kind": "info", "msg": "Нет новых заявок"},
			],
		},
	])
