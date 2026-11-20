extends Control

var _payload: Dictionary = {}
var _hero: Dictionary = {}
var _tab: String = "info"

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var hid: String = str(_payload.get("hero_id", UIStateManager.selected_hero_id))
	_hero = DemoData.get_hero(hid)
	if _hero.is_empty():
		var box = $Safe/Scroll/VBox
		box.add_child(UIFactory.section_header("Герой недоступен"))
		var back := UIFactory.fantasy_button("Назад")
		back.pressed.connect(ScreenRouter.handle_back)
		box.add_child(back)
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
	var quote := str(_hero.get("quote", ""))
	if quote == "":
		var sk_hero: Dictionary = ContentPackageLoader.skills_pack.get("heroes", {}).get(str(_hero.id), {})
		quote = str(sk_hero.get("quote", ""))
	if quote != "":
		root.add_child(UIFactory.muted("«%s»" % quote, 18))

	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["info", "Обзор"], ["skills", "Навыки"], ["art", "Арт"], ["equip", "Экип"]]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(140, 44)
		var key: String = t[0]
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)

	match _tab:
		"skills":
			_build_skills(root)
		"art":
			_build_art(root)
		"equip":
			_build_equip(root)
		_:
			_build_info(root)

	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _build_info(root: VBoxContainer) -> void:
	var row := UIFactory.hbox(10)
	root.add_child(row)
	var lvl := UIFactory.fantasy_button("Уровень +")
	lvl.disabled = true
	lvl.tooltip_text = "Повышение уровня будет доступно после подключения серверной операции"
	row.add_child(lvl)
	var auto := UIFactory.gold_button("Автоэкипировка")
	auto.disabled = true
	auto.tooltip_text = "Экипировка будет доступна после подключения серверной операции"
	row.add_child(auto)
	for panel_name in [["Таланты", "talents"], ["Артефакт", "artifact"], ["Связи", "bonds"]]:
		var b := UIFactory.fantasy_button(panel_name[0])
		var title: String = panel_name[0]
		var key: String = panel_name[1]
		b.pressed.connect(func():
			ModalManager.push_info(title, "Раздел «%s» для %s.\nСтатус: Демо · полный функционал позже." % [key, _hero.name])
		)
		root.add_child(b)

func _build_skills(root: VBoxContainer) -> void:
	root.add_child(UIFactory.label(ContentPackageLoader.tr_key("skills.title", "Навыки"), 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted(ContentPackageLoader.tr_key("c5.demo", "C5 DEMO"), 16))
	var cards_by_id: Dictionary = {}
	for c in ContentPackageLoader.skills_pack.get("cards", []):
		cards_by_id[str(c.get("id", ""))] = c
	var skill_ids: Array = _hero.get("skills", [])
	for sid_v in skill_ids:
		var sid := str(sid_v)
		var card: Dictionary = cards_by_id.get(sid, {})
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		if card.is_empty():
			v.add_child(UIFactory.label(sid, 20, LunexColors.GOLD))
			v.add_child(UIFactory.muted("Карточка не найдена в skills.json", 16))
		else:
			v.add_child(UIFactory.label("%s · %s" % [str(card.get("slot", "")), str(card.get("name", ""))], 22, LunexColors.GOLD))
			v.add_child(UIFactory.label(str(card.get("description", "")), 18))
			var meta_parts: PackedStringArray = []
			if card.has("cooldown_sec") and card["cooldown_sec"] != null:
				meta_parts.append("КД %sс" % str(card["cooldown_sec"]))
			if card.has("energy_cost"):
				meta_parts.append("энергия %s" % str(card["energy_cost"]))
			if card.has("cast"):
				meta_parts.append(str(card["cast"]))
			if meta_parts.size() > 0:
				v.add_child(UIFactory.muted(", ".join(meta_parts), 16))
		root.add_child(p)

func _build_art(root: VBoxContainer) -> void:
	root.add_child(UIFactory.label(ContentPackageLoader.tr_key("art.title", "Реестр арта"), 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted(ContentPackageLoader.tr_key("c6.demo", "C6 DEMO"), 16))
	var art: Dictionary = ContentPackageLoader.hero_art(str(_hero.id))
	if art.is_empty():
		root.add_child(UIFactory.muted("Нет art-блока в heroes.json", 18))
		return
	root.add_child(UIFactory.muted("status · %s" % str(art.get("status", "placeholder")), 18))
	for slot in ["portrait", "atlas", "animations", "ultimate_vfx"]:
		var key := str(art.get(slot, ""))
		var item := ContentPackageLoader.resolve_asset(key)
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s" % slot, 20, LunexColors.GOLD))
		v.add_child(UIFactory.muted("%s → %s" % [key, str(item.get("id", "—"))], 16))
		v.add_child(UIFactory.muted("%s · %s" % [
			str(item.get("path", "")),
			str(item.get("status", "")),
		], 14))
		root.add_child(p)
	var clips: Array = art.get("clips", [])
	if not clips.is_empty():
		root.add_child(UIFactory.muted("clips: %s" % ", ".join(clips), 16))
	var open := UIFactory.fantasy_button("Весь реестр")
	open.pressed.connect(func(): ScreenRouter.go("ART-01"))
	root.add_child(open)

func _build_equip(root: VBoxContainer) -> void:
	root.add_child(UIFactory.title("Экипировка", 28))
	for slot in ["weapon", "armor", "acc"]:
		var eid: String = str(_hero.equip.get(slot, ""))
		var ename := "Пусто"
		for e in DemoData.equipment_pool:
			if e.id == eid:
				ename = e.name
				break
		root.add_child(UIFactory.label("%s: %s" % [slot, ename], 22))
