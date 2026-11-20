extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "PvP-центр",
	"status": "Демо",
	"subtitle": "Асинхронная арена",
	"sections": [
		{
			"title": "Сезон арены",
			"lines": [
				"Лига: Бронза",
				"Рейтинг: 1020",
				"Соперников: 3 (демо)",
			],
			"actions": [
				{
					"label": "Выбрать соперника",
					"kind": "route",
					"route": "COMBAT-01",
				},
				{
					"label": "Отряд защиты",
					"kind": "route",
					"route": "PVP-02",
				},
				{
					"label": "Рейтинги",
					"kind": "route",
					"route": "RANK-01",
				},
				{
					"label": "История",
					"kind": "info",
					"msg": "История боёв пуста (демо)",
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
