extends Control
## ROOT-02: коллекция героев HERO-UI-001 B

@onready var _portrait_host: Control = $Col/Top/PortraitHost
@onready var _info: VBoxContainer = $Col/Top/Info
@onready var _grid: GridContainer = $Col/Scroll/Grid
@onready var _filters: HBoxContainer = $Col/Filters

func _ready() -> void:
	$Col/Top/Actions/DetailsBtn.pressed.connect(func(): ScreenRouter.go("HERO-01", {"hero_id": UIStateManager.selected_hero_id}))
	$Col/Top/Actions/SquadBtn.pressed.connect(func(): ScreenRouter.go("HERO-02"))
	_build_filters()
	_refresh()
	DemoData.heroes_changed.connect(_refresh)
	await get_tree().process_frame
	$Col/Scroll.scroll_vertical = int(UIStateManager.heroes_scroll_y)
	$Col/Scroll.gui_input.connect(func(_e): UIStateManager.heroes_scroll_y = float($Col/Scroll.scroll_vertical))

func _build_filters() -> void:
	for c in _filters.get_children():
		c.queue_free()
	var sorts := [["power", "Сила"], ["level", "Ур."], ["rarity", "Редк."], ["name", "Имя"]]
	for s in sorts:
		var b := UIFactory.fantasy_button(s[1], 44)
		b.custom_minimum_size = Vector2(120, 44)
		var key: String = s[0]
		b.pressed.connect(func():
			UIStateManager.hero_sort = key
			_refresh()
		)
		_filters.add_child(b)
	var factions := ["", "Империя Порядка", "Сумрачные", "Лесные", "Клановые кузнецы", "Арканисты", "Вольные города"]
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(260, 44)
	for f in factions:
		opt.add_item("Все фракции" if f == "" else f)
	opt.item_selected.connect(func(i):
		UIStateManager.hero_filter_faction = factions[i]
		_refresh()
	)
	_filters.add_child(opt)

func _refresh() -> void:
	var selected_id := UIStateManager.selected_hero_id
	if selected_id == "":
		selected_id = DemoData.selected_hero_id
		UIStateManager.selected_hero_id = selected_id
	var hero := DemoData.get_hero(selected_id)
	for c in _portrait_host.get_children():
		c.queue_free()
	if not hero.is_empty():
		var port := UIFactory.hero_portrait(hero.tint, Vector2(220, 280))
		port.set_anchors_preset(Control.PRESET_CENTER)
		port.position = Vector2(40, 10)
		_portrait_host.add_child(port)
		# gentle idle bob
		if ThemeManager.parallax_enabled:
			var tw := create_tween().set_loops()
			tw.tween_property(port, "position:y", port.position.y - 6, 1.0)
			tw.tween_property(port, "position:y", port.position.y, 1.0)
		for c in _info.get_children():
			c.queue_free()
		_info.add_child(UIFactory.title(str(hero.name), 34))
		_info.add_child(UIFactory.label("%s · %s · %s" % [hero.class, hero.faction, hero.rarity], 22, LunexColors.rarity(hero.rarity)))
		_info.add_child(UIFactory.label("Ур.%d  ★%d  Сила %d" % [hero.level, hero.stars, hero.power], 24, LunexColors.GOLD))
	for c in _grid.get_children():
		c.queue_free()
	var list := DemoData.get_filtered_heroes(UIStateManager.hero_filter_faction, UIStateManager.hero_filter_rarity, UIStateManager.hero_filter_class, UIStateManager.hero_search, UIStateManager.hero_sort)
	for h in list:
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(200, 220)
		cell.toggle_mode = true
		cell.button_pressed = h.id == selected_id
		var v := UIFactory.vbox(6)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(v)
		var mini := UIFactory.hero_portrait(h.tint, Vector2(120, 140))
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(mini)
		var nm := UIFactory.label(str(h.name), 20, LunexColors.TEXT_PRIMARY)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var pw := UIFactory.muted(str(h.power), 18)
		pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(pw)
		var hid: String = h.id
		cell.pressed.connect(func():
			UIStateManager.set_hero_selection(hid)
			_refresh()
		)
		_grid.add_child(cell)
