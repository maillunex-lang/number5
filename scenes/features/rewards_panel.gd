extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Доступные награды",
	"status": "Демо",
	"subtitle": "Красные точки и переходы",
	"sections": [
		{
			"title": "Готово к получению",
			"lines": [
				"AFK-сокровищница",
				"Ежедневные задания ×3",
				"Почта ×2",
			],
			"actions": [
				{
					"label": "К AFK",
					"kind": "route",
					"route": "HUB-02",
				},
				{
					"label": "К заданиям",
					"kind": "route",
					"route": "HUB-03",
				},
				{
					"label": "К почте",
					"kind": "route",
					"route": "SOCIAL-04",
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
