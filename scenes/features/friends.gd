extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Друзья",
	"status": "Демо",
	"subtitle": "Карточки игроков и заявки",
	"sections": [
		{
			"title": "Список",
			"lines": [
				"Лира Ветров · Lv.18 · сила 42000",
				"Боро Камень · Lv.15 · сила 31000",
			],
			"actions": [
				{
					"label": "Подарок (демо)",
					"kind": "toast",
					"msg": "Подарок отмечен локально",
				},
				{
					"label": "Заявки",
					"kind": "info",
					"msg": "Нет новых заявок",
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
