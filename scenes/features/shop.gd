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
		var res: Dictionary = await ApiClient.store_catalog()
		if res.get("ok", false):
			var data: Dictionary = res.get("data", {}) as Dictionary
			var remote: Array = data.get("offers", []) as Array
			if not remote.is_empty():
				_offers = remote
	_rebuild()

func _shop_text(value: String, size: int = 23, color: Color = LunexColors.TEXT_PRIMARY) -> Label:
	var node: Label = UIFactory.label(value, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.custom_minimum_size.x = 0
	return node

const CATEGORIES: Array[String] = ["Рекомендуем", "Алмазы", "Наборы", "Подписки", "VIP", "Пропуск", "Косметика", "История"]
var _selected_category: String = "Рекомендуем"

func _category_of(offer: Dictionary) -> String:
	var key: String = ("%s %s %s" % [str(offer.get("sku", offer.get("id", ""))), str(offer.get("title", offer.get("name", ""))), str(offer.get("category", ""))]).to_lower()
	if "vip" in key or "вип" in key:
		return "VIP"
	if "pass" in key or "пропуск" in key:
		return "Пропуск"
	if "subscr" in key or "подпис" in key:
		return "Подписки"
	if "cosmetic" in key or "облик" in key:
		return "Косметика"
	if "diamond" in key or "алмаз" in key:
		return "Алмазы"
	return "Наборы"

func _rebuild() -> void:
	var root: VBoxContainer = $Safe/Scroll/VBox
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	root.add_child(_shop_text("✦ ТОРГОВАЯ ПЛОЩАДЬ", 35, LunexColors.GOLD))
	var mode := "ONLINE" if ApiClient.online else "DEMO"
	root.add_child(_shop_text("Фэнтезийная лавка · %s · %s" % [ContentPackageLoader.package_label(), mode], 19, LunexColors.TEXT_MUTED))
	var banner := UIFactory.panel(Color(0.15, 0.12, 0.22))
	root.add_child(banner)
	var banner_box := UIFactory.vbox(10)
	banner.add_child(banner_box)
	banner_box.add_child(_shop_text("✧ МАГИЧЕСКАЯ ВИТРИНА ✧", 31, LunexColors.GOLD))
	banner_box.add_child(_shop_text("[ МЕСТО ДЛЯ ТЕМАТИЧЕСКОГО АРТА ]", 23))
	banner_box.add_child(_shop_text("Все покупки бесплатны · Без списаний", 23, LunexColors.GOLD))
	var tabs_scroll := ScrollContainer.new()
	tabs_scroll.custom_minimum_size.y = 86
	tabs_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tabs_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(tabs_scroll)
	var tabs := UIFactory.hbox(10)
	tabs_scroll.add_child(tabs)
	for category in CATEGORIES:
		var tab := UIFactory.fantasy_button(category)
		tab.custom_minimum_size = Vector2(160, 70)
		tab.add_theme_font_size_override("font_size", 22)
		tab.pressed.connect(func(): _selected_category = category; _rebuild())
		tabs.add_child(tab)
	root.add_child(_shop_text(_selected_category, 30, LunexColors.GOLD))
	if _selected_category == "История":
		root.add_child(_shop_text("История покупок: раздел оформления пока заглушка.", 23))
	else:
		var shown := 0
		for raw in _offers:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var offer: Dictionary = raw
			if _selected_category != "Рекомендуем" and _category_of(offer) != _selected_category:
				continue
			_add_offer(root, offer)
			shown += 1
		if shown == 0:
			root.add_child(_shop_text("В этой категории пока нет предложений.", 23))
	var links := UIFactory.hbox(10)
	root.add_child(links)
	for entry in [{"label":"VIP-центр", "route":"HUB-07"}, {"label":"Пропуск", "route":"HUB-08"}]:
		var action := UIFactory.fantasy_button(str(entry["label"]))
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.custom_minimum_size.y = 78
		var route := str(entry["route"])
		action.pressed.connect(func(): ScreenRouter.go(route))
		links.add_child(action)
	var back := UIFactory.fantasy_button("← Назад")
	back.custom_minimum_size.y = 80
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _add_offer(root: VBoxContainer, offer: Dictionary) -> void:
	var title: String = str(offer.get("title", offer.get("name", "Предложение")))
	var sku: String = str(offer.get("sku", offer.get("id", title)))
	var grants: Array = offer.get("grants", []) as Array
	var card: ShopOfferCard = (load("res://scenes/ui/components/shop_offer_card.tscn") as PackedScene).instantiate()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_offer(offer)
	var disclaimer: String = str(ContentPackageLoader.economy.get("disclaimer", "Тестовый магазин · Без списаний"))
	card.buy_pressed.connect(func(_sku: String) -> void:
		_buy(sku, title, disclaimer, grants)
	)
	root.add_child(card)

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
		var ord: Dictionary = await ApiClient.store_order(sku)
		if ord.get("ok", false):
			var order_wrap: Dictionary = ord.get("data", {}) as Dictionary
			var order: Dictionary = order_wrap.get("order", {}) as Dictionary
			var oid: String = str(order.get("id", ""))
			var conf: Dictionary = await ApiClient.store_confirm(oid)
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
