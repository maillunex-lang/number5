extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Отряд защиты",
	"status": "Демо",
	"subtitle": "Сохранённый состав для асинхронного PvP",
	"sections": [
		{
			"title": "Защита",
			"lines": [
				"Использует текущий пресет отряда",
			],
			"actions": [
				{
					"label": "Открыть менеджер",
					"kind": "route",
					"route": "HERO-02",
				},
				{
					"label": "Сохранить защиту",
					"kind": "toast",
					"msg": "Защита сохранена локально (демо)",
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
