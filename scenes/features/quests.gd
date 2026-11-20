extends Control

var _payload: Dictionary = {}
var _tab: String = "daily"

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header("Журнал заданий"))
	root.add_child(UIFactory.muted(ContentPackageLoader.package_label(), 18))
	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["daily", "Ежедневные"], ["weekly", "Недельные"], ["story", "Сюжет"], ["special", "Особые"]]:
		var b := UIFactory.fantasy_button(t[1], 48)
		var key: String = t[0]
		if key == _tab:
			b.modulate = Color(1.2, 1.1, 0.9)
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)
	root.add_child(UIFactory.label("Активность: 60/100 · сундуки за пороги", 22, LunexColors.CYAN))
	var quests_doc: Dictionary = ContentPackageLoader.features.get("quests", {})
	var list: Array = quests_doc.get(_tab, [])
	for q_raw in list:
		var q: Dictionary = q_raw
		var p := UIFactory.panel()
		var v := UIFactory.vbox(6)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(q.get("title", "")), str(q.get("progress", ""))], 24))
		var goto_route: String = str(q.get("goto", ""))
		if goto_route != "":
			var go := UIFactory.fantasy_button("Перейти")
			go.pressed.connect(func(): ScreenRouter.go(goto_route))
			v.add_child(go)
		root.add_child(p)
	var exp := UIFactory.fantasy_button("Экспедиции")
	exp.pressed.connect(func(): ScreenRouter.go("EXPEDITIONS"))
	root.add_child(exp)
	var claim := UIFactory.gold_button("Собрать готовые награды")
	claim.pressed.connect(func():
		ModalManager.push_rewards("Задания", ["Золото ×400", "Опыт активности"])
		AppState.add_demo_rewards(400, 0)
		DemoData.quest_ready = 0
	)
	root.add_child(claim)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
