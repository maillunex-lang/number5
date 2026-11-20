extends Control
## EXPEDITIONS: доска миссий из liveops.json (DEMO).

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _pack() -> Dictionary:
	return ContentPackageLoader.liveops.get("expeditions", {})

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var pack := _pack()
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("expeditions.title", "Экспедиции")))
	root.add_child(UIFactory.muted("%s · DEMO" % ContentPackageLoader.package_label(), 18))
	root.add_child(UIFactory.muted("Открытие %s · слоты %s (+moon %s) · доска %s" % [
		str(pack.get("unlock_stage", "CH01-10")),
		str(pack.get("base_slots", 2)),
		str(pack.get("sub_moon_extra_slot", 1)),
		str(pack.get("board_size", 6)),
	], 16))

	var missions: Array = pack.get("missions", [])
	var board_n := mini(int(pack.get("board_size", 6)), missions.size())
	for i in board_n:
		var m: Dictionary = missions[i]
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(m.get("id", "")), str(m.get("name", ""))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted("гл.%s · %s · %sс · сила ≥%s · %s" % [
			str(m.get("chapter", "")),
			str(m.get("tier", "")),
			str(m.get("duration_sec", 0)),
			str(m.get("min_power", 0)),
			str(m.get("faction_id", "")),
		], 16))
		var parts: PackedStringArray = []
		for r in m.get("rewards_success", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		v.add_child(UIFactory.label(", ".join(parts), 18))
		var go := UIFactory.gold_button("Отправить (демо)")
		go.pressed.connect(func():
			ModalManager.push_rewards("Экспедиция (демо)", parts if parts.size() > 0 else PackedStringArray(["Ожидание…"]))
		)
		v.add_child(go)
		root.add_child(p)

	if board_n == 0:
		root.add_child(UIFactory.muted("Нет миссий в пакете", 20))

	var inv := UIFactory.fantasy_button("Инвентарь")
	inv.pressed.connect(func(): ScreenRouter.go("WORKSHOP"))
	root.add_child(inv)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
