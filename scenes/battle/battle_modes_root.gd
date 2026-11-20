extends Control
## ROOT-04: интерактивная карта PvE + вход в PvP (из контент-пакета)

@onready var _world: Control = $Scroll/World

func _ready() -> void:
	_build()
	DemoData.content_reloaded.connect(_build)

func _build() -> void:
	for c in _world.get_children():
		c.queue_free()
	var world: Dictionary = ContentPackageLoader.battle_modes.get("world", {"width": 1080, "height": 1400})
	_world.custom_minimum_size = Vector2(float(world.get("width", 1080)), float(world.get("height", 1400)))
	for i in 8:
		var deco := ColorRect.new()
		deco.size = Vector2(300, 180)
		deco.position = Vector2(80 + (i % 3) * 300, 100 + i * 160)
		deco.color = Color(0.12, 0.1, 0.18, 0.55)
		deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_world.add_child(deco)
	for raw in ContentPackageLoader.get_battle_portals():
		var p: Dictionary = raw
		var size: Dictionary = p.get("size", {"w": 280, "h": 150})
		var b := Button.new()
		b.custom_minimum_size = Vector2(float(size.get("w", 280)), float(size.get("h", 150)))
		b.position = Vector2(float(p.get("x", 0)), float(p.get("y", 0)))
		b.text = str(p.get("name", ""))
		var st := StyleBoxFlat.new()
		var c := Color(str(p.get("color", "#E8C56A")))
		st.bg_color = Color(c.r * 0.22, c.g * 0.22, c.b * 0.22, 0.95)
		st.border_color = c
		st.set_border_width_all(3)
		st.set_corner_radius_all(16)
		b.add_theme_stylebox_override("normal", st)
		var route: String = str(p.get("route", ""))
		var payload: Dictionary = p.get("payload", {})
		b.pressed.connect(func(): ScreenRouter.go(route, payload))
		_world.add_child(b)
		if ThemeManager.parallax_enabled:
			var tw := create_tween().set_loops()
			tw.tween_property(b, "modulate", Color(1.1, 1.05, 1.0), 1.0)
			tw.tween_property(b, "modulate", Color.WHITE, 1.0)
	$Header/Title.text = "Битва · режимы PvE / PvP"
	$Header/Hint.text = "%s · все режимы → общая подготовка" % ContentPackageLoader.package_label()
