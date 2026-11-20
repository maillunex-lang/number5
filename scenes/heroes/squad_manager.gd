extends Control
## HERO-02 / часть PREBATTLE — менеджер отрядов, 5 слотов, пресеты

var _payload: Dictionary = {}
var _selected_slot: int = 0

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()
	DemoData.squad_changed.connect(_rebuild)

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header("Менеджер отрядов"))
	root.add_child(UIFactory.label("Сила отряда: %d" % DemoData.squad_power(), 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Выберите слот, затем героя. Демо-пресеты локальные.", 22))
	var slots := UIFactory.hbox(8)
	root.add_child(slots)
	for i in 5:
		var hid: String = DemoData.squad_slots[i]
		var h := DemoData.get_hero(hid)
		var b := Button.new()
		b.custom_minimum_size = Vector2(160, 180)
		b.text = ("#%d\n%s" % [i + 1, h.name]) if not h.is_empty() else ("#%d\nПусто" % [i + 1])
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if i == _selected_slot:
			b.modulate = Color(1.2, 1.1, 0.9)
		var idx := i
		b.pressed.connect(func():
			_selected_slot = idx
			_rebuild()
		)
		slots.add_child(b)
	root.add_child(UIFactory.title("Пресеты", 28))
	var prow := UIFactory.hbox(8)
	root.add_child(prow)
	for p in DemoData.squad_presets:
		var pb := UIFactory.fantasy_button(str(p.name), 52)
		var pid: String = p.id
		pb.pressed.connect(func():
			DemoData.apply_preset(pid)
			NotificationManager.success("Пресет «%s» применён" % p.name)
		)
		prow.add_child(pb)
	root.add_child(UIFactory.title("Герои", 28))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)
	for h in DemoData.heroes:
		var b := Button.new()
		b.custom_minimum_size = Vector2(200, 100)
		b.text = "%s\n%d" % [h.name, h.power]
		var hid: String = h.id
		b.pressed.connect(func():
			DemoData.set_squad_slot(_selected_slot, hid)
			NotificationManager.info("%s → слот %d" % [h.name, _selected_slot + 1])
		)
		grid.add_child(b)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
