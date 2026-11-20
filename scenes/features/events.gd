extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Центр событий",
	"status": "Демо",
	"subtitle": "Календарь и баннеры сезона",
	"sections": [
		{
			"title": "Активные",
			"lines": [
				"Фестиваль осколков — 2д 4ч",
				"Ночной марш — скоро",
			],
			"actions": [
				{
					"label": "Открыть событие",
					"kind": "info",
					"msg": "Страница события (демо)",
				},
			],
		},
		{
			"title": "Навигация",
			"actions": [
				{
					"label": "Сезонный пропуск",
					"kind": "route",
					"route": "HUB-08",
				},
				{
					"label": "Магазин акций",
					"kind": "route",
					"route": "HUB-06",
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
