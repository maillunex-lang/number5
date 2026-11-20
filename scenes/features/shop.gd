extends Control
## HUB-06: VIRTUAL_FREE магазин. Online → store orders/confirm-test; иначе демо.

var _payload: Dictionary = {}
var _busy: bool = false
var _offers: Array = []

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_offers = ContentPackageLoader.economy.get("offers", [])
	if _offers.is_empty():
		_offers = ContentPackageLoader.features.get("shop_offers", [])
	if ApiClient.online:
		var res := await ApiClient.store_catalog()
		if res.get("ok", false):
			var data: Dictionary = res.get("data", {})
			var remote: Array = data.get("offers", [])
			if not remote.is_empty():
				_offers = remote
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header("Торговая площадь"))
	var disclaimer := str(ContentPackageLoader.economy.get("disclaimer", "Тестовый магазин · 0 ₽"))
	var mode := "ONLINE · VIRTUAL_FREE" if ApiClient.online else "DEMO"
	root.add_child(UIFactory.muted("%s · %s · %s" % [ContentPackageLoader.package_label(), mode, disclaimer], 20))
	root.add_child(UIFactory.label("Реальные деньги не списываются", 22, LunexColors.GOLD))

	for o_raw in _offers:
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
		buy.pressed.connect(func(): _buy(sku, title, disclaimer, grants))
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

func _buy(sku: String, title: String, disclaimer: String, grants: Array) -> void:
	if _busy:
		return
	ModalManager.push_confirm(
		"Тестовая выдача",
		"%s\n\n%s\nSKU: %s\nРеальные платежи отключены." % [title, disclaimer, sku],
		func(): _confirm_buy(sku, title, grants)
	)

func _confirm_buy(sku: String, title: String, grants: Array) -> void:
	_busy = true
	if ApiClient.online:
		var ord := await ApiClient.store_order(sku)
		if ord.get("ok", false):
			var order: Dictionary = ord.get("data", {}).get("order", {})
			var oid := str(order.get("id", ""))
			var conf := await ApiClient.store_confirm(oid)
			if conf.get("ok", false):
				var lines: Array = ["Источник: store VIRTUAL_FREE", "SKU %s" % sku]
				for g in order.get("grants", grants):
					if typeof(g) == TYPE_DICTIONARY:
						lines.append("%s ×%s" % [str(g.get("resource_id", "")), str(g.get("amount", 0))])
				await ApiClient.sync_wallet()
				ModalManager.push_rewards("Получено (ONLINE)", lines)
				_busy = false
				return
		NotificationManager.warn("Магазин online недоступен · демо")
	var lines2: Array = ["Источник: virtual_free DEMO", "SKU %s" % sku]
	for g in grants:
		lines2.append("%s ×%s" % [str(g.get("resource_id", "")), str(g.get("amount", 0))])
	if lines2.size() == 2:
		lines2.append(title)
	ModalManager.push_rewards("Получено бесплатно (тест)", lines2)
	_busy = false
