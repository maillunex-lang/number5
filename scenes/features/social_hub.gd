extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Социальный центр",
	"status": "Демо",
	"subtitle": "Друзья · чат · почта · рейтинги",
	"sections": [
		{
			"title": "Разделы",
			"actions": [
				{
					"label": "Чаты",
					"kind": "route",
					"route": "SOCIAL-02",
				},
				{
					"label": "Друзья",
					"kind": "route",
					"route": "SOCIAL-03",
				},
				{
					"label": "Почта",
					"kind": "route",
					"route": "SOCIAL-04",
				},
				{
					"label": "Рейтинги",
					"kind": "route",
					"route": "RANK-01",
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
