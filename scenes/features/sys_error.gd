extends Control
## SYS-08 error: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Восстановление"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Состояние",
			"lines": [
				"Сервер недоступен (ожидаемо для локального прототипа)",
			],
			"actions": [
				{"label": "Повторить", "kind": "toast", "msg": "Повтор (демо)"},
				{"label": "Назад", "kind": "toast", "msg": "Используйте кнопку Назад"},
			],
		},
	])
