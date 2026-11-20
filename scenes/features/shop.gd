extends Control
## HUB-06: VIRTUAL_FREE магазин из economy.json (демо, без реальных платежей).

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var root := $Safe/Scroll/VBox
	root.add_child(UIFactory.section_header("Торговая площадь"))
	var disclaimer := str(ContentPackageLoader.economy.get("disclaimer", "Тестовый магазин · 0 ₽"))
	root.add_child(UIFactory.muted("%s · %s" % [ContentPackageLoader.package_label(), disclaimer], 20))
	root.add_child(UIFactory.label("Реальные деньги не списываются", 22, LunexColors.GOLD))

	var offers: Array = ContentPackageLoader.economy.get("offers", [])
	if offers.is_empty():
		offers = ContentPackageLoader.features.get("shop_offers", [])
	for o_raw in offers:
		var o: Dictionary = o_raw
		var p := UIFactory.panel()
		var v := UIFactory.vbox(8)
		p.add_child(v)
		var title := str(o.get("title", o.get("name", "")))
		v.add_child(UIFactory.label(title, 28, LunexColors.GOLD))
		var grants: Array = o.get("grants", [])
		if grants.is_empty():
			v.add_child(UIFactory.label(str(o.get("desc", "")), 22))
		else:
			var parts: PackedStringArray = []
			for g in grants:
				parts.append("%s ×%s" % [str(g.get("resource_id", "")), str(g.get("amount", 0))])
			v.add_child(UIFactory.label(", ".join(parts), 22))
		var nominal := int(o.get("nominal_price_rub", 0))
		if nominal > 0:
			v.add_child(UIFactory.muted("Номинал %d ₽ · к оплате 0 ₽" % nominal, 18))
		v.add_child(UIFactory.muted("Лимит: %s · VIP XP +%s" % [str(o.get("limits", o.get("limit", ""))), str(o.get("vip_xp", 0))], 18))
		var buy := UIFactory.gold_button(str(o.get("cta", "Получить бесплатно (тест)")))
		var sku := str(o.get("sku", o.get("id", title)))
		buy.pressed.connect(func():
			ModalManager.push_confirm(
				"Тестовая выдача",
				"%s\n\n%s\nSKU: %s\nРеальные платежи отключены." % [title, disclaimer, sku],
				func():
					var lines: Array = ["Источник: virtual_free", "SKU %s" % sku]
					for g in grants:
						lines.append("%s ×%s" % [str(g.get("resource_id", "")), str(g.get("amount", 0))])
					if lines.size() == 2:
						lines.append(title)
					ModalManager.push_rewards("Получено бесплатно (тест)", lines)
			)
		)
		v.add_child(buy)
		root.add_child(p)

	var row := UIFactory.hbox(10)
	root.add_child(row)
	var vip := UIFactory.fantasy_button("VIP 0–11")
	vip.pressed.connect(func(): ScreenRouter.go("HUB-07"))
	row.add_child(vip)
	var bp := UIFactory.fantasy_button("Пропуск")
	bp.pressed.connect(func(): ScreenRouter.go("HUB-08"))
	row.add_child(bp)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
