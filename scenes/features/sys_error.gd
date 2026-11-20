extends Control
## Auto-generated demo feature screen

var _payload: Dictionary = {}
const CONFIG := {
	"title": "Восстановление",
	"status": "Демо",
	"subtitle": "Сеть / обновление",
	"sections": [
		{
			"title": "Состояние",
			"lines": [
				"Сервер недоступен (ожидаемо для локального прототипа)",
			],
			"actions": [
				{
					"label": "Повторить",
					"kind": "toast",
					"msg": "Повтор (демо)",
				},
				{
					"label": "Назад",
					"kind": "toast",
					"msg": "Используйте кнопку Назад",
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
