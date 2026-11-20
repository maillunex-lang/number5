extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Галерея достижений",
	"status": "Демо",
	"subtitle": "Медали и секретные награды",
	"sections": [
		{
			"title": "Открытые",
			"lines": [
				"Первый шаг — обычная",
				"Пять героев — редкая",
			],
			"actions": [
				{
					"label": "Секретные",
					"kind": "info",
					"msg": "??? — условие скрыто",
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
