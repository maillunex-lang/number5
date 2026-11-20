extends Control
## PVE-01: Испытания из pve_modes.json (DEMO sandbox).

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var mode := str(_payload.get("mode", "tower"))
	var pve: Dictionary = ContentPackageLoader.pve_modes
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("pve.title", "Испытания")))
	root.add_child(UIFactory.muted("%s · %s" % [
		ContentPackageLoader.package_label(),
		str(pve.get("disclaimer", "DEMO")),
	], 18))

	# Mode switcher (4 cards)
	var row := UIFactory.hbox(8)
	root.add_child(row)
	for m in [
		["tower", "Башня"],
		["anomaly_hunt", "Охота"],
		["faction_gates", "Врата"],
		["rift_dungeons", "Подземелья"],
	]:
		var b := UIFactory.fantasy_button(m[1])
		b.custom_minimum_size = Vector2(150, 44)
		var mid: String = m[0]
		b.pressed.connect(func():
			_payload["mode"] = mid
			_rebuild()
		)
		row.add_child(b)

	match mode:
		"anomaly_hunt", "boss":
			_build_hunt(root)
		"faction_gates", "faction":
			_build_gates(root)
		"rift_dungeons", "dungeon":
			_build_dungeons(root)
		"expedition":
			root.add_child(UIFactory.label("Экспедиции — в liveops / AFK-хаб", 24))
			var go := UIFactory.gold_button("К AFK / экспедициям")
			go.pressed.connect(func(): ScreenRouter.go("HUB-02"))
			root.add_child(go)
		_:
			_build_tower(root)

	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _build_tower(root: VBoxContainer) -> void:
	var tower: Dictionary = ContentPackageLoader.pve_modes.get("tower", {})
	root.add_child(UIFactory.label(str(tower.get("name", "Башня Времени")), 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Открытие после %s · %d этажей · награда только first clear" % [
		str(tower.get("unlock_stage", "CH01-15")),
		int(tower.get("floor_count", 120)),
	], 20))
	var floors: Array = tower.get("floors", [])
	var show_n := mini(12, floors.size())
	for i in show_n:
		var f: Dictionary = floors[i]
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		var title := "%s · %s · %s" % [str(f.get("id", "")), str(f.get("kind", "")), str(f.get("modifier", ""))]
		v.add_child(UIFactory.label(title, 22, LunexColors.GOLD))
		var squad: Array = f.get("enemy_squad", [])
		var names: PackedStringArray = []
		for s in squad:
			names.append(str(s.get("enemy_id", "")))
		v.add_child(UIFactory.muted("Враги: %s" % ", ".join(names), 16))
		var rewards: Array = f.get("first_clear_rewards", [])
		var rtxt: PackedStringArray = []
		for r in rewards:
			rtxt.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		v.add_child(UIFactory.muted("First clear: %s" % ", ".join(rtxt), 16))
		var go := UIFactory.gold_button("К подготовке")
		var floor_id := str(f.get("id", "TWR-001"))
		var enemy0 := str(squad[0].get("enemy_id", "")) if squad.size() > 0 else ""
		go.pressed.connect(func():
			UIStateManager.set_combat_context({"mode": "tower", "stage_id": floor_id, "return_route": "ROOT-04"})
			ScreenRouter.go("COMBAT-01", {"mode": "tower", "stage_id": floor_id, "enemy_hint": enemy0})
		)
		v.add_child(go)
		root.add_child(p)
	if floors.size() > show_n:
		root.add_child(UIFactory.muted("… ещё %d этажей в пакете (лента виртуализируется на серверном UI)" % (floors.size() - show_n), 18))

func _build_hunt(root: VBoxContainer) -> void:
	var hunt: Dictionary = ContentPackageLoader.pve_modes.get("anomaly_hunt", {})
	root.add_child(UIFactory.label(str(hunt.get("name", "Охота на Аномалии")), 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Открытие %s · %d попытки/день · урон за 90с" % [
		str(hunt.get("unlock_stage", "CH02-10")),
		int(hunt.get("daily_completed_attempts", 3)),
	], 20))
	var sched: Dictionary = hunt.get("schedule", {})
	var today: Array = sched.get("mon", [])
	root.add_child(UIFactory.label("Сегодня (пример Пн):", 22))
	for bid in today:
		var meta := DemoData._enemy_meta(str(bid))
		var p := UIFactory.panel()
		var v := UIFactory.vbox(6)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(bid), str(meta.get("name", ""))], 24, LunexColors.GOLD))
		v.add_child(UIFactory.muted("Пороги 25/60/100% target → boss_core / essence / set_pattern", 16))
		var go := UIFactory.gold_button("Сразиться (демо)")
		var boss_id := str(bid)
		go.pressed.connect(func():
			UIStateManager.set_combat_context({"mode": "anomaly_hunt", "stage_id": boss_id, "return_route": "ROOT-04"})
			ScreenRouter.go("COMBAT-01", {"mode": "anomaly_hunt", "stage_id": boss_id})
		)
		v.add_child(go)
		root.add_child(p)

func _build_gates(root: VBoxContainer) -> void:
	var gates: Dictionary = ContentPackageLoader.pve_modes.get("faction_gates", {})
	root.add_child(UIFactory.label(str(gates.get("name", "Фракционные врата")), 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Открытие %s · %d наградных побед/день" % [
		str(gates.get("unlock_stage", "CH02-20")),
		int(gates.get("daily_rewarded_wins", 3)),
	], 20))
	for f in gates.get("factions", []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		var fid := str(f.get("faction_id", ""))
		v.add_child(UIFactory.label("%s · нужно ≥%d героев фракции" % [fid, int(f.get("min_faction_heroes", 3))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted("5 ступеней × novice/veteran/master", 16))
		var go := UIFactory.gold_button("Вход (демо)")
		go.pressed.connect(func():
			UIStateManager.set_combat_context({"mode": "faction_gates", "stage_id": "GATE-%s-01" % fid, "return_route": "ROOT-04"})
			ScreenRouter.go("COMBAT-01", {"mode": "faction_gates", "stage_id": "GATE-%s-01" % fid})
		)
		v.add_child(go)
		root.add_child(p)

func _build_dungeons(root: VBoxContainer) -> void:
	var duns: Dictionary = ContentPackageLoader.pve_modes.get("rift_dungeons", {})
	root.add_child(UIFactory.label(str(duns.get("name", "Подземелья Разлома")), 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Открытие %s · %d наградных входов/день · quick clear после 3★" % [
		str(duns.get("unlock_stage", "CH01-20")),
		int(duns.get("daily_rewarded_entries", 6)),
	], 20))
	for d in duns.get("dungeons", []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(d.get("id", "")), str(d.get("name", ""))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted("Unlock %s" % str(d.get("unlock_stage", "")), 16))
		var rewards: Dictionary = d.get("rewards_by_difficulty", {})
		var easy: Array = rewards.get("easy", [])
		var parts: PackedStringArray = []
		for r in easy:
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		v.add_child(UIFactory.muted("I: %s" % ", ".join(parts), 16))
		var go := UIFactory.gold_button("Бой · сложность I (демо)")
		var did := str(d.get("id", ""))
		go.pressed.connect(func():
			UIStateManager.set_combat_context({"mode": "rift_dungeons", "stage_id": did, "return_route": "ROOT-04"})
			ScreenRouter.go("COMBAT-01", {"mode": "rift_dungeons", "stage_id": did})
		)
		v.add_child(go)
		root.add_child(p)
