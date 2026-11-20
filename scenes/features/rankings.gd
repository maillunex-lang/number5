extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Рейтинги",
	"status": "Демо",
	"subtitle": "Пьедестал топ-3",
	"sections": [
		{
			"title": "Топ",
			"lines": [
				"1. Астра · 56000",
				"2. Лира · 42000",
				"3. Боро · 31000",
			],
			"actions": [
				{
					"label": "Профиль #2",
					"kind": "route",
					"route": "PROFILE-02",
				},
				{
					"label": "Фильтр: сила",
					"kind": "toast",
					"msg": "Фильтр (демо)",
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
