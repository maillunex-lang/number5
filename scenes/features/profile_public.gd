extends Control
## PROFILE-02 public: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Публичный профиль"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Лира Ветров",
			"lines": [
				"Lv.18 · сила 42000",
				"Гильдия: Зал Плетения",
			],
			"actions": [
				{"label": "Добавить в друзья", "kind": "toast", "msg": "Заявка (демо)"},
				{"label": "Сообщение", "kind": "route", "route": "SOCIAL-02"},
				{"label": "Достижения", "kind": "route", "route": "PROFILE-03"},
			],
		},
	])
