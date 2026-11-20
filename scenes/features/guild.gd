extends Control
## HUB-05: гильдия / рейды / магазин жетонов из guilds.json (DEMO).

var _payload: Dictionary = {}
var _tab: String = "hub"

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _g() -> Dictionary:
	return ContentPackageLoader.guilds

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var g := _g()
	var demo: Dictionary = g.get("demo", {}).get("guild", {})
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("guild.title", "Гильдия")))
	root.add_child(UIFactory.muted("%s · %s" % [
		ContentPackageLoader.package_label(),
		str(g.get("disclaimer", ContentPackageLoader.tr_key("guild.demo", "DEMO"))),
	], 18))
	root.add_child(UIFactory.label("%s [%s] · ур.%s · %s/%s" % [
		str(demo.get("name", "—")),
		str(demo.get("tag", "")),
		str(demo.get("level", 1)),
		str(demo.get("members", 0)),
		str(g.get("starting_capacity", 20)),
	], 26, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Открытие после %s · жетоны: %s (демо)" % [
		str(g.get("unlock_stage", "CH01-20")),
		str(g.get("demo", {}).get("wallet_guild_token", 0)),
	], 18))
	if demo.has("announcement"):
		root.add_child(UIFactory.label(str(demo["announcement"]), 20))

	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["hub", "Штаб"], ["quests", "Задания"], ["raids", "Рейды"], ["shop", "Магазин"]]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(150, 44)
		var key: String = t[0]
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)

	match _tab:
		"quests":
			_build_quests(root, g)
		"raids":
			_build_raids(root, g)
		"shop":
			_build_shop(root, g)
		_:
			_build_hub(root, g)

	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _build_hub(root: VBoxContainer, g: Dictionary) -> void:
	root.add_child(UIFactory.label("Зоны штаба", 24, LunexColors.GOLD))
	for zone in [
		["Доска поручений", "quests"],
		["Врата Разлома", "raids"],
		["Склад знаков", "shop"],
		["Участники", "hub"],
	]:
		var p := UIFactory.panel()
		var v := UIFactory.vbox(6)
		p.add_child(v)
		v.add_child(UIFactory.label(zone[0], 22))
		var go := UIFactory.gold_button("Открыть")
		var key: String = zone[1]
		go.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		v.add_child(go)
		root.add_child(p)
	root.add_child(UIFactory.muted("Чат / рейтинг сезона — после сервера (CORE-01). Рейтинг: «Скоро».", 18))

func _build_quests(root: VBoxContainer, g: Dictionary) -> void:
	root.add_child(UIFactory.label(ContentPackageLoader.tr_key("guild.quests", "Доска поручений"), 26, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Ежедневно %d из %d шаблонов (одинаковый набор для гильдии)" % [
		int(g.get("daily_quest_board_size", 5)),
		(g.get("daily_quests", []) as Array).size(),
	], 18))
	var board: Array = g.get("daily_quests", [])
	var n := mini(int(g.get("daily_quest_board_size", 5)), board.size())
	for i in n:
		var q: Dictionary = board[i]
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(q.get("id", "")), str(q.get("name", ""))], 20, LunexColors.GOLD))
		var parts: PackedStringArray = []
		for r in q.get("rewards", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		v.add_child(UIFactory.muted("%s · guild XP +%s" % [", ".join(parts), str(q.get("guild_xp", 0))], 16))
		var claim := UIFactory.fantasy_button("Забрать (демо)")
		claim.pressed.connect(func():
			ModalManager.push_rewards("Задание гильдии (демо)", parts)
		)
		v.add_child(claim)
		root.add_child(p)

func _build_raids(root: VBoxContainer, g: Dictionary) -> void:
	var raids: Dictionary = g.get("raids", {})
	root.add_child(UIFactory.label(ContentPackageLoader.tr_key("guild.raids", "Врата Разлома"), 26, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Асинхронно: общий HP · %dч · %d попытки/сутки · без realtime 30 героев" % [
		int(raids.get("duration_hours", 72)),
		int(raids.get("daily_attempts_per_member", 2)),
	], 18))
	for t in raids.get("tiers", []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(6)
		p.add_child(v)
		v.add_child(UIFactory.label("Tier %s · %s" % [str(t.get("tier", "")), str(t.get("name", ""))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted("Guild L%s · HP %s · босс %s · активных ~%s" % [
			str(t.get("guild_level_required", 1)),
			str(t.get("shared_hp", 0)),
			str(t.get("boss_id", "")),
			str(t.get("recommended_active_members", 0)),
		], 16))
		var go := UIFactory.gold_button("Попытка (демо бой)")
		var boss_id := str(t.get("boss_id", ""))
		var tier := str(t.get("tier", "I"))
		go.pressed.connect(func():
			UIStateManager.set_combat_context({"mode": "guild_raid", "stage_id": "RAID-%s" % tier, "return_route": "HUB-05"})
			ScreenRouter.go("COMBAT-01", {"mode": "guild_raid", "stage_id": "RAID-%s" % tier, "enemy_hint": boss_id})
		)
		v.add_child(go)
		root.add_child(p)
	root.add_child(UIFactory.muted("Пороги 25/50/75/100%% · claim на сервере", 16))

func _build_shop(root: VBoxContainer, g: Dictionary) -> void:
	var shop: Dictionary = g.get("shop", {})
	root.add_child(UIFactory.label(ContentPackageLoader.tr_key("guild.shop", "Склад знаков"), 26, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Валюта: %s · реальные деньги: выкл." % str(shop.get("currency_id", "guild_token")), 18))
	for o in shop.get("offers", []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label(str(o.get("sku", "")), 22, LunexColors.GOLD))
		var parts: PackedStringArray = []
		for r in o.get("grants", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		var lim: Variant = o.get("weekly_limit", o.get("lifetime_limit", "—"))
		v.add_child(UIFactory.muted("%s · цена %s жетонов · лимит %s" % [
			", ".join(parts),
			str(o.get("price_guild_token", 0)),
			str(lim),
		], 16))
		var buy := UIFactory.fantasy_button("Обменять (демо)")
		buy.pressed.connect(func():
			ModalManager.push_rewards("Гильдейский магазин (демо)", parts)
		)
		v.add_child(buy)
		root.add_child(p)
