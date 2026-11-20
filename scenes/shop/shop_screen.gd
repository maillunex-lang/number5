extends Control

@onready var _list: VBoxContainer = %PackList


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for pack in AppState.shop_packs:
		var card := PanelContainer.new()
		UIStyle.apply_panel(card, UIColors.BG_PANEL_ALT)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 16)
		card.add_child(margin)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		margin.add_child(col)
		var title := Label.new()
		title.text = pack.title
		title.add_theme_font_size_override("font_size", 24)
		title.add_theme_color_override("font_color", UIColors.ACCENT)
		col.add_child(title)
		var desc := Label.new()
		desc.text = pack.desc
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", UIColors.TEXT_DIM)
		col.add_child(desc)
		var buy := Button.new()
		buy.text = "Buy · %s" % pack.price
		buy.custom_minimum_size = Vector2(0, 52)
		UIStyle.apply_button(buy, true)
		buy.pressed.connect(_on_buy.bind(pack))
		col.add_child(buy)
		_list.add_child(card)


func _on_buy(pack: Dictionary) -> void:
	# Stub purchase — grant fake gems for feedback.
	AppState.add_diamonds(10)
	%StatusLabel.text = "Purchased '%s' (stub — no payment)." % pack.title
