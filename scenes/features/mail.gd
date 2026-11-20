extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Почта",
	"status": "Демо",
	"subtitle": "Категории и вложения",
	"sections": [
		{
			"title": "Письма",
			"lines": [
				"Система: комплект новичка",
				"Событие: вход в сезон",
			],
			"actions": [
				{
					"label": "Забрать все доступные",
					"kind": "reward",
					"rewards": [
						"Золото ×300",
						"Энергия ×10",
					],
				},
				{
					"label": "Фильтр: награды",
					"kind": "toast",
					"msg": "Фильтр применён (демо)",
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
