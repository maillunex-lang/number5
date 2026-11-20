extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var events: Array = ContentPackageLoader.features.get("events", [])
	var lines: Array = []
	for e_raw in events:
		var e: Dictionary = e_raw
		lines.append("%s — %s (%s)" % [str(e.get("name", "")), str(e.get("timer", "")), str(e.get("state", ""))])
	var cfg := {
		"title": "Центр событий",
		"status": ContentPackageLoader.package_label(),
		"subtitle": "Календарь и баннеры сезона",
		"sections": [
			{
				"title": "Активные",
				"lines": lines if lines.size() > 0 else ["Нет событий"],
				"actions": [{"label": "Открыть событие", "kind": "info", "msg": "Страница события (демо)"}],
			},
			{
				"title": "Навигация",
				"actions": [
					{"label": "Сезонный пропуск", "kind": "route", "route": "HUB-08"},
					{"label": "Магазин акций", "kind": "route", "route": "HUB-06"},
				],
			},
		],
	}
	if _payload.has("title_override"):
		cfg["title"] = _payload["title_override"]
	DemoScreenBuilder.build($Safe/Scroll/VBox, cfg)
