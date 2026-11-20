extends Control
## PVP-02 defense: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Отряд защиты"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Защита",
			"lines": [
				"Использует текущий пресет отряда",
			],
			"actions": [
				{"label": "Открыть менеджер", "kind": "route", "route": "HERO-02"},
				{"label": "Сохранить защиту", "kind": "toast", "msg": "Защита сохранена локально (демо)"},
			],
		},
	])
