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
		b.custom_minimum_size = Vector2(130, 72)
		var key: String = s[0]
		b.pressed.connect(func():
			UIStateManager.hero_sort = key
			_refresh()
		)
		_filters.add_child(b)
	var factions: Array = [""]
	for f in ContentPackageLoader.heroes_pack.get("factions", []):
		factions.append(str(f.get("name", "")))
	if factions.size() == 1:
		factions.append_array(["Стражи Клятвы", "Вольные Тропы", "Архив Предела", "Каменные Кузни", "Межвременные Тени", "Расколотые Хранители"])
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(250, 72)
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
		var port := UIFactory.hero_portrait(hero.tint, Vector2(180, 240))
		port.set_anchors_preset(Control.PRESET_CENTER)
		port.position = Vector2(22, 10)
		_portrait_host.add_child(port)
		# gentle idle bob
		if ThemeManager.parallax_enabled:
			var tw := port.create_tween().set_loops()
			tw.tween_property(port, "position:y", port.position.y - 6, 1.0)
			tw.tween_property(port, "position:y", port.position.y, 1.0)
		for c in _info.get_children():
			c.queue_free()
		_info.add_child(UIFactory.title(str(hero.name), 34))
		_info.add_child(UIFactory.label("%s · %s · %s" % [hero.class, hero.faction, hero.rarity], 22, LunexColors.rarity(hero.rarity)))
		_info.add_child(UIFactory.label("Ур.%d  ★%d  Сила %d" % [hero.level, hero.stars, hero.power], 24, LunexColors.GOLD))
	for c in _grid.get_children():
		c.queue_free()
	var available_width: float = maxf(_grid.size.x, get_viewport_rect().size.x - 24.0)
	var cell_width: float = floorf((available_width - 24.0) / 3.0)
	var list := DemoData.get_filtered_heroes(UIStateManager.hero_filter_faction, UIStateManager.hero_filter_rarity, UIStateManager.hero_filter_class, UIStateManager.hero_search, UIStateManager.hero_sort)
	var card_scene: PackedScene = load("res://scenes/ui/components/hero_card.tscn")
	for h in list:
		var card: HeroCard = card_scene.instantiate()
		card.card_size = Vector2(cell_width, 286)
		card.set_hero(h)
		if h.id == selected_id:
			card.modulate = Color(1.15, 1.1, 0.95, 1)
		var hid: String = h.id
		card.selected.connect(func(_id):
			UIStateManager.set_hero_selection(hid)
			_refresh()
		)
		_grid.add_child(card)
