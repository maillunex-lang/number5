extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "VIP-центр",
	"status": "Демо",
	"subtitle": "Зал привилегий",
	"sections": [
		{
			"title": "Уровень VIP 0",
			"lines": [
				"Прогресс: 0 / 100",
				"Сравнение уровней доступно в демо",
			],
			"actions": [
				{
					"label": "История бонусов",
					"kind": "info",
					"msg": "История пуста (демо)",
				},
				{
					"label": "VIP-награды",
					"kind": "reward",
					"rewards": [
						"Сундук VIP (демо)",
					],
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
