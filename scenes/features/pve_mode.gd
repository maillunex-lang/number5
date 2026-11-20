extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var mode: String = str(_payload.get("mode", "tower"))
	var titles := {
		"tower": "Башня испытаний",
		"boss": "Боссы",
		"dungeon": "Подземелья",
		"expedition": "Экспедиции",
		"faction": "Испытания фракций",
	}
	var root := $Safe/Scroll/VBox
	root.add_child(UIFactory.section_header(titles.get(mode, "PvE")))
	root.add_child(UIFactory.label("Интерактивный вход с карты битвы", 24, LunexColors.TEXT_SECONDARY))
	root.add_child(UIFactory.muted("Демо-режим. Использует общую подготовку и локальный автобой.", 22))
	match mode:
		"expedition":
			root.add_child(UIFactory.label("Экспедиция идёт офлайн по таймеру (демо).", 24))
			var send := UIFactory.gold_button("Отправить отряд")
			send.pressed.connect(func():
				ModalManager.push_info("Экспедиция", "Отряд отправлен. Вернитесь позже за результатом.\n(локальная имитация, без сервера)")
			)
			root.add_child(send)
		_:
			root.add_child(UIFactory.label("Этап демо-содержимого готов к подготовке.", 24))
			var prep := UIFactory.gold_button("К подготовке")
			prep.pressed.connect(func():
				UIStateManager.set_combat_context({"mode": mode, "stage_id": "s1_3", "return_route": "ROOT-04"})
				ScreenRouter.go("COMBAT-01", {"mode": mode, "stage_id": "s1_3"})
			)
			root.add_child(prep)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
