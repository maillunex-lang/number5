extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var bp: Dictionary = ContentPackageLoader.features.get("battle_pass", {})
	var season := str(bp.get("season", "Сезон"))
	var level := int(bp.get("level", 1))
	var free_ready := int(bp.get("free_ready", 0))
	var premium_ready := int(bp.get("premium_ready", 0))
	var cfg := {
		"title": "Сезонный пропуск",
		"status": ContentPackageLoader.package_label(),
		"subtitle": "Двойная лента наград",
		"sections": [
			{
				"title": "Сезон «%s»" % season,
				"lines": [
					"Уровень пропуска: %d" % level,
					"Готово free/premium: %d / %d" % [free_ready, premium_ready],
				],
				"actions": [
					{"label": "Забрать доступные", "kind": "reward", "rewards": ["Золото ×500", "Ключ ×1"]},
					{"label": "Задания сезона", "kind": "route", "route": "HUB-03"},
				],
			},
		],
	}
	if _payload.has("title_override"):
		cfg["title"] = _payload["title_override"]
	DemoScreenBuilder.build($Safe/Scroll/VBox, cfg)
