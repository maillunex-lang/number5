extends Control
## PVP-01 center: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "PvP-центр"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Сезон арены",
			"lines": [
				"Лига: Бронза",
				"Рейтинг: 1020",
				"Соперников: 3 (демо)",
			],
			"actions": [
				{"label": "Выбрать соперника", "kind": "route", "route": "COMBAT-01"},
				{"label": "Отряд защиты", "kind": "route", "route": "PVP-02"},
				{"label": "Рейтинги", "kind": "route", "route": "RANK-01"},
				{"label": "История", "kind": "info", "msg": "История боёв пуста (демо)"},
			],
		},
	])
