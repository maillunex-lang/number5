extends Control
## WORKSHOP: инвентарь экипировки из equipment.json (DEMO).

var _tab: String = "sets"

func setup(_payload: Dictionary = {}) -> void:
	pass

func _ready() -> void:
	_rebuild()

func _eq() -> Dictionary:
	return ContentPackageLoader.equipment

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var eq := _eq()
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("inventory.title", "Инвентарь экипировки")))
	root.add_child(UIFactory.muted("%s · DEMO · без серверного крафта" % ContentPackageLoader.package_label(), 18))

	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["sets", "Сеты"], ["slots", "Слоты"], ["demo", "Надето"]]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(140, 44)
		var key: String = t[0]
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)

	match _tab:
		"slots":
			root.add_child(UIFactory.label("Слоты", 24, LunexColors.GOLD))
			for slot in eq.get("slots", []):
				root.add_child(UIFactory.muted(str(slot), 18))
		"demo":
			_build_demo_loadout(root, eq)
		_:
			_build_sets(root, eq)

	var exp := UIFactory.fantasy_button("Экспедиции")
	exp.pressed.connect(func(): ScreenRouter.go("EXPEDITIONS"))
	root.add_child(exp)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _build_sets(root: VBoxContainer, eq: Dictionary) -> void:
	root.add_child(UIFactory.label("12 сетов (по главам)", 24, LunexColors.GOLD))
	for s in eq.get("sets", []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s · гл.%s" % [
			str(s.get("id", "")),
			str(s.get("name", "")),
			str(s.get("chapter", "")),
		], 20, LunexColors.GOLD))
		v.add_child(UIFactory.muted("фракция %s" % str(s.get("theme_faction", "")), 16))
		for b in s.get("bonuses", []):
			v.add_child(UIFactory.muted("%s шт → %s" % [str(b.get("pieces", "")), str(b.get("effect_id", ""))], 16))
		root.add_child(p)

func _build_demo_loadout(root: VBoxContainer, eq: Dictionary) -> void:
	root.add_child(UIFactory.label("Демо-набор (H01)", 24, LunexColors.GOLD))
	var templates: Array = eq.get("templates", [])
	if templates.is_empty():
		for slot in eq.get("slots", []):
			root.add_child(UIFactory.label("%s · — пусто —" % str(slot), 20))
		return
	var shown := 0
	for t in templates:
		if shown >= 10:
			break
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(t.get("id", "")), str(t.get("name", t.get("slot", "")))], 20, LunexColors.GOLD))
		v.add_child(UIFactory.muted("слот %s · сет %s · редкость %s" % [
			str(t.get("slot", "")),
			str(t.get("set_id", "")),
			str(t.get("rarity", "")),
		], 16))
		root.add_child(p)
		shown += 1
