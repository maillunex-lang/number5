extends Control
## SOCIAL-02 chat: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Fantasy Messenger"))
	FeatureSectionHost.fill(_host, [
		{
			"title": "Каналы",
			"lines": [
				"[Мир] Странник: ищем в башню",
				"[Система] Демо-чат без сервера",
			],
			"actions": [
				{"label": "Отправить (демо)", "kind": "toast", "msg": "Сообщение не отправлено на сервер"},
				{"label": "Открыть профиль", "kind": "route", "route": "PROFILE-02"},
			],
		},
	])
