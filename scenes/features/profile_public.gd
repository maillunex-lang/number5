extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Публичный профиль",
	"status": "Демо",
	"subtitle": "Витрина другого игрока",
	"sections": [
		{
			"title": "Лира Ветров",
			"lines": [
				"Lv.18 · сила 42000",
				"Гильдия: Зал Плетения",
			],
			"actions": [
				{
					"label": "Добавить в друзья",
					"kind": "toast",
					"msg": "Заявка (демо)",
				},
				{
					"label": "Сообщение",
					"kind": "route",
					"route": "SOCIAL-02",
				},
				{
					"label": "Достижения",
					"kind": "route",
					"route": "PROFILE-03",
				},
			],
		},
	],
}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var cfg := CONFIG.duplicate(true)
	if _payload.has("title_override"):
		cfg["title"] = _payload["title_override"]
	DemoScreenBuilder.build($Safe/Scroll/VBox, cfg)
