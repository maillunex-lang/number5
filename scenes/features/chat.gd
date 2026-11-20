extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Fantasy Messenger",
	"status": "Демо",
	"subtitle": "Мировой / гильдейский / личный",
	"sections": [
		{
			"title": "Каналы",
			"lines": [
				"[Мир] Странник: ищем в башню",
				"[Система] Демо-чат без сервера",
			],
			"actions": [
				{
					"label": "Отправить (демо)",
					"kind": "toast",
					"msg": "Сообщение не отправлено на сервер",
				},
				{
					"label": "Открыть профиль",
					"kind": "route",
					"route": "PROFILE-02",
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
