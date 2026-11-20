extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var vip: Dictionary = ContentPackageLoader.features.get("vip", {})
	var level := int(vip.get("level", 0))
	var progress := int(vip.get("progress", 0))
	var next_at := int(vip.get("next", 100))
	var cfg := {
		"title": "VIP-центр",
		"status": ContentPackageLoader.package_label(),
		"subtitle": "Зал привилегий",
		"sections": [
			{
				"title": "Уровень VIP %d" % level,
				"lines": [
					"Прогресс: %d / %d" % [progress, next_at],
					"Сравнение уровней доступно в демо",
				],
				"actions": [
					{"label": "История бонусов", "kind": "info", "msg": "История пуста (демо)"},
					{"label": "VIP-награды", "kind": "reward", "rewards": ["Сундук VIP (демо)"]},
				],
			},
		],
	}
	if _payload.has("title_override"):
		cfg["title"] = _payload["title_override"]
	DemoScreenBuilder.build($Safe/Scroll/VBox, cfg)
