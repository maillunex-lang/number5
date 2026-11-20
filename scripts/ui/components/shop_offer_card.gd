@tool
class_name ShopOfferCard
extends PanelContainer
## Карточка оффера магазина. Покупка — сигнал buy_pressed.

signal buy_pressed(sku: String)

@export_category("Lunex Shop Offer")
@export var title_text: String = "Набор":
	set(v):
		title_text = v
		if _title:
			_title.text = v
@export var price_text: String = "0 ₽ (тест)":
	set(v):
		price_text = v
		if _price:
			_price.text = v

var sku: String = ""

@onready var _title: Label = $Pad/Col/Title
@onready var _desc: Label = $Pad/Col/Desc
@onready var _price: Label = $Pad/Col/Price
@onready var _buy: Button = $Pad/Col/BuyBtn

func _ready() -> void:
	theme_type_variation = &"GamePanel"
	# PASS: жест прокрутки списка не съедается карточкой (только BuyBtn ловит тап).
	mouse_filter = Control.MOUSE_FILTER_PASS
	if Engine.is_editor_hint():
		if _title:
			_title.text = title_text
		if _price:
			_price.text = price_text
		return
	if _buy and not _buy.pressed.is_connected(_on_buy):
		_buy.pressed.connect(_on_buy)

func set_offer(offer: Dictionary) -> void:
	sku = str(offer.get("sku", offer.get("id", "")))
	if _title:
		_title.text = str(offer.get("title", offer.get("name", title_text)))
	if _desc:
		var grants: Array = offer.get("grants", []) as Array
		if grants.is_empty():
			_desc.text = str(offer.get("description", offer.get("cta", "")))
		else:
			var parts: PackedStringArray = []
			for g in grants:
				if typeof(g) != TYPE_DICTIONARY:
					continue
				parts.append("%s×%s" % [str(g.get("resource_id", g.get("id", ""))), str(g.get("amount", 0))])
			_desc.text = ", ".join(parts)
	var payable: int = int(offer.get("payable_price_rub", offer.get("price_rub", 0)))
	var nominal: int = int(offer.get("nominal_price_rub", payable))
	if _price:
		_price.text = "%s ₽ · к оплате %s ₽" % [str(nominal), str(payable)]
	if _buy:
		_buy.text = str(offer.get("cta", "Получить"))

func _on_buy() -> void:
	buy_pressed.emit(sku)
