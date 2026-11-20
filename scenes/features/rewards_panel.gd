extends Control
## Rewards hub: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Доступные награды"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Готово к получению",
			"lines": [
				"AFK-сокровищница",
				"Ежедневные задания ×3",
				"Почта ×2",
			],
			"actions": [
				{"label": "К AFK", "kind": "route", "route": "HUB-02"},
				{"label": "К заданиям", "kind": "route", "route": "HUB-03"},
				{"label": "К почте", "kind": "route", "route": "SOCIAL-04"},
			],
		},
	])
