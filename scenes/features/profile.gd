extends Control

func setup(_payload: Dictionary = {}) -> void:
	pass

func _ready() -> void:
	var root := $Safe/Scroll/VBox
	root.add_child(UIFactory.section_header(AppState.display_name))
	root.add_child(UIFactory.hero_portrait(Color("E8C56A"), Vector2(200, 240)))
	root.add_child(UIFactory.label("Уровень %d · сила %d · VIP %d" % [AppState.level, AppState.power, AppState.vip_level], 24))
	root.add_child(UIFactory.label("Мир: %s" % AppState.world_name, 22, LunexColors.CYAN))
	root.add_child(UIFactory.muted("Гость" if AppState.is_guest else "Локальный аккаунт: %s" % AppState.email_hint, 20))
	root.add_child(UIFactory.title("Витрина отряда", 28))
	var row := UIFactory.hbox(8)
	root.add_child(row)
	for id in DemoData.squad_slots:
		var h := DemoData.get_hero(id)
		if h.is_empty():
			continue
		row.add_child(UIFactory.hero_portrait(h.tint, Vector2(100, 120)))
	var ach := UIFactory.fantasy_button("Достижения")
	ach.pressed.connect(func(): ScreenRouter.go("PROFILE-03"))
	root.add_child(ach)
	var edit := UIFactory.fantasy_button("Оформление профиля")
	edit.pressed.connect(func():
		ModalManager.push_info("Оформление", "Аватары, рамки, титулы и фоны — демо.\nЭффекты зависят от графического пресета.")
	)
	root.add_child(edit)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
