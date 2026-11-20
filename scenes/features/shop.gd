extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var root := $Safe/Scroll/VBox
	root.add_child(UIFactory.section_header("Торговая площадь"))
	root.add_child(UIFactory.muted("%s · без реальных платежей" % ContentPackageLoader.package_label(), 22))
	var offers: Array = ContentPackageLoader.features.get("shop_offers", [])
	for o_raw in offers:
		var o: Dictionary = o_raw
		var p := UIFactory.panel()
		var v := UIFactory.vbox(8)
		p.add_child(v)
		v.add_child(UIFactory.label(str(o.get("name", "")), 28, LunexColors.GOLD))
		v.add_child(UIFactory.label(str(o.get("desc", "")), 22))
		v.add_child(UIFactory.muted("Лимит: %s" % str(o.get("limit", "")), 20))
		var buy := UIFactory.fantasy_button("Подробнее")
		var offer_name: String = str(o.get("name", ""))
		buy.pressed.connect(func():
			ModalManager.push_confirm(
				"Покупка (демо)",
				"%s\n\nРеальные платежи отключены.\nПоказать демо-результат?" % offer_name,
				func(): ModalManager.push_rewards("Получено (демо)", [offer_name, "Без списания средств"])
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
