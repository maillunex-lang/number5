extends Control
## SOCIAL-01: chrome в .tscn; маршруты чат/друзья/почта/рейтинги в DynamicHost.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Социальный центр"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Разделы",
			"actions": [
				{"label": "Чаты", "kind": "route", "route": "SOCIAL-02"},
				{"label": "Друзья", "kind": "route", "route": "SOCIAL-03"},
				{"label": "Почта", "kind": "route", "route": "SOCIAL-04"},
				{"label": "Рейтинги", "kind": "route", "route": "RANK-01"},
			],
		},
	])
