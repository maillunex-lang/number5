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
	var quests := {
		"daily": [["Победить 3 боя", "2/3", true], ["Собрать AFK", "0/1", true], ["Зайти в гильдию", "1/1", false]],
		"weekly": [["Башня 10 этажей", "3/10", true], ["Призыв ×20", "0/20", true]],
		"story": [["Глава 1-3", "в процессе", true]],
		"special": [["Событие: осколки", "скоро", false]],
	}
	for q in quests.get(_tab, []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(6)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [q[0], q[1]], 24))
		if q[2]:
			var go := UIFactory.fantasy_button("Перейти")
			go.pressed.connect(func():
				if "AFK" in str(q[0]):
					ScreenRouter.go("HUB-02")
				elif "гильд" in str(q[0]).to_lower():
					ScreenRouter.go("HUB-05")
				else:
					ScreenRouter.go("ROOT-04")
			)
			v.add_child(go)
		root.add_child(p)
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
