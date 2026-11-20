extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Сезонный пропуск",
	"status": "Демо",
	"subtitle": "Двойная лента наград",
	"sections": [
		{
			"title": "Сезон «Пепел и шёлк»",
			"lines": [
				"Уровень пропуска: 5",
				"Бесплатная и премиальная ленты",
			],
			"actions": [
				{
					"label": "Забрать доступные",
					"kind": "reward",
					"rewards": [
						"Золото ×500",
						"Ключ ×1",
					],
				},
				{
					"label": "Задания сезона",
					"kind": "route",
					"route": "HUB-03",
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
