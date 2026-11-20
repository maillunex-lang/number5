extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var mail: Array = ContentPackageLoader.features.get("mail", [])
	var lines: Array = []
	for m_raw in mail:
		var m: Dictionary = m_raw
		var mark := "● " if bool(m.get("unread", false)) else "○ "
		lines.append("%s[%s] %s" % [mark, str(m.get("category", "")), str(m.get("title", ""))])
	var cfg := {
		"title": "Почта",
		"status": ContentPackageLoader.package_label(),
		"subtitle": "Категории и вложения",
		"sections": [
			{
				"title": "Входящие",
				"lines": lines if lines.size() > 0 else ["Пусто"],
				"actions": [
					{"label": "Забрать все доступные", "kind": "reward", "rewards": ["Золото ×300", "Энергия ×10"]},
					{"label": "Фильтр: награды", "kind": "toast", "msg": "Фильтр применён (демо)"},
				],
			},
		],
	}
	if _payload.has("title_override"):
		cfg["title"] = _payload["title_override"]
	DemoScreenBuilder.build($Safe/Scroll/VBox, cfg)
