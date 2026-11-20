extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Загрузка пакета",
	"status": "Демо",
	"subtitle": "SYS-07",
	"sections": [
		{
			"title": "Пакет эффектов боя",
			"lines": [
				"Размер: 12 МБ",
				"Прогресс: демо",
			],
			"actions": [
				{
					"label": "Повтор",
					"kind": "toast",
					"msg": "Повтор загрузки (демо)",
				},
				{
					"label": "Ошибка сети",
					"kind": "route",
					"route": "SYS-08",
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
