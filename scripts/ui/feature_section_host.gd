class_name FeatureSectionHost
extends RefCounted
## Секции GamePanel в DynamicHost (chrome экрана — в .tscn).

static func fill(host: VBoxContainer, sections: Array) -> void:
	for c in host.get_children():
		c.queue_free()
	var panel_scene: PackedScene = load("res://scenes/ui/components/game_panel.tscn")
	for section in sections:
		var panel: GamePanel = panel_scene.instantiate()
		panel.panel_kind = "GamePanel"
		host.add_child(panel)
		var content: VBoxContainer = panel.get_node("Pad/Content")
		var head := Label.new()
		head.text = str(section.get("title", ""))
		head.add_theme_font_size_override("font_size", 28)
		content.add_child(head)
		for line in section.get("lines", []):
			var l := Label.new()
			l.text = "• %s" % str(line)
			l.add_theme_font_size_override("font_size", 22)
			l.add_theme_color_override("font_color", LunexColors.TEXT_SECONDARY)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(l)
		for action in section.get("actions", []):
			var b := Button.new()
			b.text = str(action.get("label", "Действие"))
			b.custom_minimum_size = Vector2(0, 56)
			b.theme_type_variation = &"GameButton"
			var kind: String = str(action.get("kind", "info"))
			var route: String = str(action.get("route", ""))
			var msg: String = str(action.get("msg", "Демо-действие"))
			b.pressed.connect(func():
				match kind:
					"route":
						if route != "":
							ScreenRouter.go(route)
					"reward":
						ModalManager.push_rewards("Награда (демо)", action.get("rewards", ["Золото ×100"]))
						AppState.add_demo_rewards(100, 0)
					"locked":
						ModalManager.push_locked(str(action.get("label", "")), str(action.get("req", "Недоступно в демо")))
					"toast":
						NotificationManager.info(msg)
					_:
						ModalManager.push_info(str(action.get("label", "Инфо")), msg)
			)
			content.add_child(b)
