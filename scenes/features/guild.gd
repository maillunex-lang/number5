extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Гильдия «Зал Плетения»",
	"status": "Демо",
	"subtitle": "Гибридный экран гильдии",
	"sections": [
		{
			"title": "Вкладки",
			"lines": [
				"Главная",
				"Участники",
				"Войны",
				"Активности",
				"Ещё",
			],
			"actions": [
				{
					"label": "Чат гильдии",
					"kind": "route",
					"route": "SOCIAL-02",
				},
				{
					"label": "Территории",
					"kind": "locked",
					"req": "Доступно с 3 уровня гильдии",
				},
				{
					"label": "Магазин гильдии",
					"kind": "toast",
					"msg": "Каталог гильдии (демо)",
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
