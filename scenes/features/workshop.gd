extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Мастерская",
	"status": "Демо / закрыто",
	"subtitle": "Крафт и улучшения",
	"sections": [
		{
			"title": "Условие",
			"lines": [
				"Требуется 20 уровень командира",
			],
			"actions": [
				{
					"label": "Понятно",
					"kind": "info",
					"msg": "Мастерская откроется позже",
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
