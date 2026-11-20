extends Control
## ROOT-04: интерактивная карта PvE + вход в PvP

@onready var _world: Control = $Scroll/World

func _ready() -> void:
	_build()

func _build() -> void:
	for c in _world.get_children():
		c.queue_free()
	# Background portals field
	for i in 8:
		var deco := ColorRect.new()
		deco.size = Vector2(300, 180)
		deco.position = Vector2(80 + (i % 3) * 300, 100 + i * 160)
		deco.color = Color(0.12, 0.1, 0.18, 0.55)
		deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_world.add_child(deco)
	var portals := [
		{"name": "Кампания", "route": "MAP-01", "pos": Vector2(200, 180), "color": Color("E8C56A")},
		{"name": "Башня", "route": "PVE-01", "payload": {"mode": "tower"}, "pos": Vector2(620, 160), "color": Color("C4454A")},
		{"name": "Боссы", "route": "PVE-01", "payload": {"mode": "boss"}, "pos": Vector2(180, 480), "color": Color("E05A5A")},
		{"name": "Подземелья", "route": "PVE-01", "payload": {"mode": "dungeon"}, "pos": Vector2(640, 460), "color": Color("5A7AD8")},
		{"name": "Экспедиции", "route": "PVE-01", "payload": {"mode": "expedition"}, "pos": Vector2(200, 780), "color": Color("3DBE7A")},
		{"name": "Испытания фракций", "route": "PVE-01", "payload": {"mode": "faction"}, "pos": Vector2(600, 760), "color": Color("B06AE8")},
		{"name": "PvP-арена", "route": "PVP-01", "pos": Vector2(400, 1080), "color": Color("E09A3E")},
	]
	for p in portals:
		var b := Button.new()
		b.custom_minimum_size = Vector2(280, 150)
		b.position = p.pos
		b.text = str(p.name)
		var st := StyleBoxFlat.new()
		var c: Color = p.color
		st.bg_color = Color(c.r * 0.22, c.g * 0.22, c.b * 0.22, 0.95)
		st.border_color = c
		st.set_border_width_all(3)
		st.set_corner_radius_all(16)
		b.add_theme_stylebox_override("normal", st)
		var route: String = p.route
		var payload: Dictionary = p.get("payload", {})
		b.pressed.connect(func(): ScreenRouter.go(route, payload))
		_world.add_child(b)
		if ThemeManager.parallax_enabled:
			var tw := create_tween().set_loops()
			tw.tween_property(b, "modulate", Color(1.1, 1.05, 1.0), 1.0)
			tw.tween_property(b, "modulate", Color.WHITE, 1.0)
	$Header/Title.text = "Битва · режимы PvE / PvP"
	$Header/Hint.text = "Все режимы ведут к общей подготовке"
