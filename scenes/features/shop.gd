extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var root := $Safe/Scroll/VBox
	root.add_child(UIFactory.section_header("Торговая площадь"))
	root.add_child(UIFactory.muted("Фэнтезийная лавка · без реальных платежей", 22))
	var offers := [
		{"name": "Набор странника", "desc": "Золото ×5000, ключи ×3", "limit": "1/1", "demo": true},
		{"name": "Сундук осколков", "desc": "Осколки героев ×10", "limit": "3/день", "demo": true},
		{"name": "Ежедневная скидка", "desc": "Таймер 12:00", "limit": "таймер", "demo": true},
	]
	for o in offers:
		var p := UIFactory.panel()
		var v := UIFactory.vbox(8)
		p.add_child(v)
		v.add_child(UIFactory.label(str(o.name), 28, LunexColors.GOLD))
		v.add_child(UIFactory.label(str(o.desc), 22))
		v.add_child(UIFactory.muted("Лимит: %s" % o.limit, 20))
		var buy := UIFactory.fantasy_button("Подробнее")
		var name: String = o.name
		buy.pressed.connect(func():
			ModalManager.push_confirm(
				"Покупка (демо)",
				"%s\n\nРеальные платежи отключены.\nПоказать демо-результат?" % name,
				func(): ModalManager.push_rewards("Получено (демо)", [name, "Без списания средств"])
			)
		)
		v.add_child(buy)
		root.add_child(p)
	var row := UIFactory.hbox(10)
	root.add_child(row)
	var vip := UIFactory.fantasy_button("VIP")
	vip.pressed.connect(func(): ScreenRouter.go("HUB-07"))
	row.add_child(vip)
	var bp := UIFactory.fantasy_button("Пропуск")
	bp.pressed.connect(func(): ScreenRouter.go("HUB-08"))
	row.add_child(bp)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
