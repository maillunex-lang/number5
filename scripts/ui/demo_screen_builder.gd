class_name DemoScreenBuilder
extends RefCounted
## Собирает оформленные демо-экраны. Кнопки — из visual GameButton.tscn через UIFactory.

static func build(root: VBoxContainer, config: Dictionary) -> void:
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header(str(config.get("title", "Раздел"))))
	root.add_child(UIFactory.label(str(config.get("subtitle", "")), 24, LunexColors.TEXT_SECONDARY))
	var status := str(config.get("status", "Демо"))
	root.add_child(UIFactory.label("Статус: %s" % status, 22, LunexColors.AMBER))
	root.add_child(UIFactory.muted(str(config.get("blurb", "Интерактивная демонстрация интерфейса. Серверные операции не выполняются.")), 22))
	root.add_child(UIFactory.spacer(8))
	for section in config.get("sections", []):
		root.add_child(UIFactory.title(str(section.get("title", "")), 28))
		for line in section.get("lines", []):
			root.add_child(UIFactory.label("• %s" % str(line), 22, LunexColors.TEXT_SECONDARY))
		for action in section.get("actions", []):
			var b := UIFactory.fantasy_button(str(action.get("label", "Действие")))
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
			root.add_child(b)
		root.add_child(UIFactory.spacer(6))
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
