extends Control
## SYS-07 download: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Загрузка пакета"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Пакет эффектов боя",
			"lines": [
				"Размер: 12 МБ",
				"Прогресс: демо",
			],
			"actions": [
				{"label": "Повтор", "kind": "toast", "msg": "Повтор загрузки (демо)"},
				{"label": "Ошибка сети", "kind": "route", "route": "SYS-08"},
			],
		},
	])
