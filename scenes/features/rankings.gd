extends Control
## RANK-01 rankings: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Рейтинги"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Топ",
			"lines": [
				"1. Астра · 56000",
				"2. Лира · 42000",
				"3. Боро · 31000",
			],
			"actions": [
				{"label": "Профиль #2", "kind": "route", "route": "PROFILE-02"},
				{"label": "Фильтр: сила", "kind": "toast", "msg": "Фильтр (демо)"},
			],
		},
	])
