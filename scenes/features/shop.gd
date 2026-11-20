extends Control
## HUB-06: chrome/banner в .tscn; ListHost — ShopOfferCard; buy API без изменений.

var _payload: Dictionary = {}
var _busy: bool = false
var _offers: Array = []
var _nav_bound: bool = false

const CATEGORIES: Array[String] = ["Рекомендуем", "Алмазы", "Наборы", "Подписки", "VIP", "Пропуск", "Косметика", "История"]
var _selected_category: String = "Рекомендуем"

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _subtitle: Label = $Safe/Scroll/VBox/Subtitle
@onready var _tabs: HBoxContainer = $Safe/Scroll/VBox/TabsScroll/TabsHost
@onready var _category: Label = $Safe/Scroll/VBox/CategoryLabel
@onready var _list: VBoxContainer = $Safe/Scroll/VBox/ListHost
@onready var _links: HBoxContainer = $Safe/Scroll/VBox/LinksHost
@onready var _back: Button = $Safe/Scroll/VBox/BackBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_bind_nav()
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

func _bind_nav() -> void:
	if _nav_bound:
		return
	_nav_bound = true
	_back.pressed.connect(func(): ScreenRouter.handle_back())
	for entry in [{"label": "VIP-центр", "route": "HUB-07"}, {"label": "Пропуск", "route": "HUB-08"}]:
		var action := Button.new()
		action.text = str(entry["label"])
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.custom_minimum_size.y = 78
		action.theme_type_variation = &"GameButton"
		var route := str(entry["route"])
		action.pressed.connect(func(): ScreenRouter.go(route))
		_links.add_child(action)

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
	var mode := "ONLINE" if ApiClient.online else "DEMO"
	_title.text = "✦ ТОРГОВАЯ ПЛОЩАДЬ"
	_subtitle.text = "Фэнтезийная лавка · %s · %s" % [ContentPackageLoader.package_label(), mode]
	_category.text = _selected_category

	for child in _tabs.get_children():
		child.queue_free()
	for category in CATEGORIES:
		var tab := Button.new()
		tab.text = category
		tab.custom_minimum_size = Vector2(160, 70)
		tab.theme_type_variation = &"GameButton"
		tab.add_theme_font_size_override("font_size", 22)
		tab.pressed.connect(func():
			_selected_category = category
			_rebuild()
		)
		_tabs.add_child(tab)

	for child in _list.get_children():
		child.queue_free()
	if _selected_category == "История":
		var hist := Label.new()
		hist.text = "История покупок: раздел оформления пока заглушка."
		hist.add_theme_font_size_override("font_size", 23)
		hist.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(hist)
	else:
		var shown := 0
		for raw in _offers:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var offer: Dictionary = raw
			if _selected_category != "Рекомендуем" and _category_of(offer) != _selected_category:
				continue
			_add_offer(offer)
			shown += 1
		if shown == 0:
			var empty := Label.new()
			empty.text = "В этой категории пока нет предложений."
			empty.add_theme_font_size_override("font_size", 23)
			empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_list.add_child(empty)

func _add_offer(offer: Dictionary) -> void:
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
	_list.add_child(card)

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
