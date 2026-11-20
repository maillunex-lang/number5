extends Control
## PROFILE-03: 48 достижений + 6 секретов из achievements.json (DEMO).

var _payload: Dictionary = {}
var _cat: String = "story"

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _pack() -> Dictionary:
	return ContentPackageLoader.achievements_pack

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var pack := _pack()
	var demo: Dictionary = pack.get("demo_progress", {})
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("achievements.title", "Достижения")))
	root.add_child(UIFactory.muted("%s · %s" % [
		ContentPackageLoader.package_label(),
		str(pack.get("disclaimer", "DEMO")),
	], 18))
	root.add_child(UIFactory.muted("Без боевых бонусов · незабранное → почта", 16))

	var tabs := UIFactory.hbox(6)
	root.add_child(tabs)
	for t in [["story", "Сюжет"], ["heroes", "Герои"], ["summon", "Призыв"], ["pve", "PvE"], ["afk", "AFK"], ["guild", "Гильдия"], ["secret", "Секреты"]]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(110, 40)
		var key: String = t[0]
		b.pressed.connect(func():
			_cat = key
			_rebuild()
		)
		tabs.add_child(b)

	if _cat == "secret":
		for s in pack.get("secrets", []):
			var p := UIFactory.panel()
			var v := UIFactory.vbox(4)
			p.add_child(v)
			var done := demo.has(str(s.get("id", "")))
			var title := str(s.get("reveal_name", s.get("name", "???"))) if done else "???"
			v.add_child(UIFactory.label("%s · %s" % [str(s.get("id", "")), title], 20, LunexColors.GOLD))
			v.add_child(UIFactory.muted("Скрыто до выполнения" if not done else "Раскрыто (демо)", 16))
			root.add_child(p)
	else:
		for a in pack.get("achievements", []):
			if str(a.get("category", "")) != _cat:
				continue
			var id := str(a.get("id", ""))
			var st: Dictionary = demo.get(id, {})
			var status := str(st.get("status", "locked"))
			var prog := int(st.get("progress", 0))
			var p := UIFactory.panel()
			var v := UIFactory.vbox(4)
			p.add_child(v)
			v.add_child(UIFactory.label("%s · %s" % [id, str(a.get("name", ""))], 20, LunexColors.GOLD))
			v.add_child(UIFactory.muted("%s ≥ %s · прогресс %s · %s" % [
				str(a.get("metric", "")),
				str(a.get("threshold", 0)),
				str(prog),
				status,
			], 16))
			var parts: PackedStringArray = []
			for r in a.get("rewards", []):
				parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
			v.add_child(UIFactory.label(", ".join(parts), 18))
			if status == "completed_unclaimed":
				var claim := UIFactory.gold_button("Забрать (демо)")
				claim.pressed.connect(func():
					ModalManager.push_rewards("Достижение (демо)", parts)
				)
				v.add_child(claim)
			root.add_child(p)

	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
