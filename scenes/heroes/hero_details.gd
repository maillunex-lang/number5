extends Control

var _payload: Dictionary = {}
var _hero: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var hid: String = str(_payload.get("hero_id", UIStateManager.selected_hero_id))
	_hero = DemoData.get_hero(hid)
	if _hero.is_empty():
		ScreenRouter.handle_back()
		return
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header(str(_hero.name)))
	root.add_child(UIFactory.hero_portrait(_hero.tint, Vector2(240, 300)))
	root.add_child(UIFactory.label("Класс: %s · Фракция: %s" % [_hero.class, _hero.faction], 24))
	root.add_child(UIFactory.label("Уровень %d · Звёзды %d · Сила %d" % [_hero.level, _hero.stars, _hero.power], 26, LunexColors.GOLD))
	root.add_child(UIFactory.label("HP %d · ATK %d · DEF %d" % [_hero.hp, _hero.atk, _hero.def], 24))
	root.add_child(UIFactory.muted("Навыки: %s" % ", ".join(PackedStringArray(_hero.skills)), 22))
	root.add_child(UIFactory.spacer(8))
	root.add_child(UIFactory.title("Экипировка", 28))
	for slot in ["weapon", "armor", "acc"]:
		var eid: String = str(_hero.equip.get(slot, ""))
		var ename := "Пусто"
		for e in DemoData.equipment_pool:
			if e.id == eid:
				ename = e.name
				break
		root.add_child(UIFactory.label("%s: %s" % [slot, ename], 22))
	var row := UIFactory.hbox(10)
	root.add_child(row)
	var lvl := UIFactory.fantasy_button("Уровень +")
	lvl.pressed.connect(func():
		_hero.level += 1
		_hero.power += 150
		_hero.hp += 80
		DemoData.heroes_changed.emit()
		NotificationManager.success("Уровень повышен (локальное демо)")
		_rebuild()
	)
	row.add_child(lvl)
	var auto := UIFactory.gold_button("Автоэкипировка")
	auto.pressed.connect(func():
		DemoData.auto_equip(_hero.id)
		_hero = DemoData.get_hero(_hero.id)
		NotificationManager.success("Экипированы лучшие предметы (демо)")
		_rebuild()
	)
	row.add_child(auto)
	for panel_name in [["Навыки", "skills"], ["Таланты", "talents"], ["Артефакт", "artifact"], ["Связи", "bonds"]]:
		var b := UIFactory.fantasy_button(panel_name[0])
		var title: String = panel_name[0]
		var key: String = panel_name[1]
		b.pressed.connect(func():
			ModalManager.push_info(title, "Раздел «%s» для %s.\nСтатус: Демо · полный функционал позже." % [key, _hero.name])
		)
		root.add_child(b)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
