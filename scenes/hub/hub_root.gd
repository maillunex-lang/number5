extends Control
## Живой вертикальный 2.5D-хаб. Данные и атмосфера — из контент-пакета.

@onready var _scroll: ScrollContainer = $Scroll
@onready var _world: Control = $Scroll/World
@onready var _far: Control = $Scroll/World/Far
@onready var _mid: Control = $Scroll/World/Mid
@onready var _near: Control = $Scroll/World/Near
@onready var _buildings: Control = $Scroll/World/Buildings
@onready var _fx: Control = $Scroll/World/FX
@onready var _side_rail: VBoxContainer = $SideRail/Col
@onready var _side_rail_panel: PanelContainer = $SideRail

const WORLD_H := 2400.0
const WORLD_W := 1080.0

var _building_defs: Array[Dictionary] = []
var _pulse_nodes: Array[Control] = []
var _ambient_tweens: Array[Tween] = []
var _look: Dictionary = {}
var _parallax: Dictionary = {}
var _rail_layout: Dictionary = {}
var _vignette: ColorRect

func _ready() -> void:
	_load_layout_from_package()
	_build_parallax()
	_build_buildings()
	_build_quick()
	_apply_look_modulate()
	_scroll.scroll_vertical = int(UIStateManager.hub_scroll_y)
	_scroll.gui_input.connect(_on_scroll_input)
	await get_tree().process_frame
	_scroll.scroll_vertical = int(UIStateManager.hub_scroll_y)
	ThemeManager.preset_changed.connect(func(_p): _apply_quality())
	DemoData.content_reloaded.connect(_on_content_reloaded)
	_apply_quality()
	_start_ambient()

func _load_layout_from_package() -> void:
	var world: Dictionary = ContentPackageLoader.get_hub_world()
	var ww := float(world.get("width", WORLD_W))
	var wh := float(world.get("height", WORLD_H))
	_world.custom_minimum_size = Vector2(ww, wh)
	_look = ContentPackageLoader.hub.get("look", {})
	_parallax = ContentPackageLoader.hub.get("parallax", {})
	_rail_layout = ContentPackageLoader.hub.get("side_rail_layout", {})
	_building_defs.clear()
	for raw in ContentPackageLoader.get_hub_buildings():
		var b: Dictionary = raw
		var size: Dictionary = b.get("size", {"w": 200, "h": 160})
		_building_defs.append({
			"id": str(b.get("id", "")),
			"name": str(b.get("name", "")),
			"x": float(b.get("x", 0)),
			"y": float(b.get("y", 0)),
			"route": str(b.get("route", "")),
			"locked": bool(b.get("locked", false)),
			"req": str(b.get("req", "")),
			"color": Color(str(b.get("color", "#E8C56A"))),
			"payload": b.get("payload", {}),
			"w": float(size.get("w", 200)),
			"h": float(size.get("h", 160)),
		})

func _on_content_reloaded() -> void:
	_load_layout_from_package()
	_clear(_buildings)
	_clear(_fx)
	_build_parallax()
	_build_buildings()
	_build_quick()
	_apply_look_modulate()
	_start_ambient()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible and _scroll != null:
		_scroll.scroll_vertical = int(UIStateManager.hub_scroll_y)

func _process(_dt: float) -> void:
	if not visible:
		return
	UIStateManager.hub_scroll_y = float(_scroll.scroll_vertical)
	if ThemeManager.parallax_enabled:
		var y := float(_scroll.scroll_vertical)
		var far_f := float(_parallax.get("far_factor", 0.35))
		var mid_f := float(_parallax.get("mid_factor", 0.18))
		_far.position.y = y * far_f
		_mid.position.y = y * mid_f

func _on_scroll_input(_ev: InputEvent) -> void:
	pass

func _apply_look_modulate() -> void:
	var ambient := float(_look.get("ambient", 0.92))
	_world.modulate = Color(ambient, ambient, ambient, 1.0)

func _build_parallax() -> void:
	_clear(_far)
	_clear(_mid)
	_clear(_near)
	if _vignette and is_instance_valid(_vignette):
		_vignette.queue_free()
		_vignette = null
	var ww := _world.custom_minimum_size.x
	var wh := _world.custom_minimum_size.y
	var panorama := TextureRect.new()
	panorama.texture = preload("res://assets/login/background.webp")
	panorama.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panorama.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panorama.size = Vector2(ww, wh)
	panorama.modulate = Color(0.68, 0.72, 0.82)
	panorama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_near.add_child(panorama)

	var vig_a := float(_look.get("vignette", 0.28))
	if vig_a > 0.01:
		_vignette = ColorRect.new()
		_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_vignette.color = Color(0, 0, 0, vig_a * 0.55)
		_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx.add_child(_vignette)

const HUB_BUILDING_SCENE := "res://scenes/ui/components/hub_building.tscn"

func _build_buildings() -> void:
	_clear(_buildings)
	_pulse_nodes.clear()
	var glow_str := float(_look.get("glow", 0.45))
	var packed: PackedScene = load(HUB_BUILDING_SCENE)
	for def in _building_defs:
		var btn: HubBuilding = packed.instantiate()
		btn.set_building(def, glow_str)
		var captured := def
		btn.activated.connect(func(_id): _on_building(captured))
		_buildings.add_child(btn)
		if not def.locked:
			_pulse_nodes.append(btn.pulse_target())
		var c: Color = def.color
		var glow := TextureRect.new()
		glow.texture = AssetLoader.make_radial_glow(c, 96)
		glow.position = Vector2(float(def.x) - 90, float(def.y) - 90)
		glow.size = Vector2(180, 180)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.modulate.a = (0.2 + glow_str * 0.55) if not def.locked else 0.12
		_fx.add_child(glow)

func _build_quick() -> void:
	for c in _side_rail.get_children():
		c.queue_free()
	# Quick actions stay vertically centered, clear of the top profile/settings bar.
	# Use the actual number of actions, not a fixed five-button height.
	var off_r := maxf(float(_rail_layout.get("offset_right", 12)), 12.0)
	var items: Array = ContentPackageLoader.get_side_rail().duplicate(true)
	# Keep settings as the last full-size quick action, independent of content packages.
	items = items.filter(func(item): return str(item.get("route", "")) != "SETTINGS-01")
	items.append({"id": "settings", "icon": "⚙", "tip": "Настройки", "route": "SETTINGS-01", "color": "#E8C56A"})
	var btn_size := 76.0
	var gap := 9
	var rail_height := float(items.size()) * btn_size + float(maxi(items.size() - 1, 0)) * gap + 20.0
	_side_rail_panel.anchor_top = 0.5
	_side_rail_panel.anchor_bottom = 0.5
	_side_rail_panel.offset_left = -(off_r + btn_size + 20.0)
	_side_rail_panel.offset_right = -off_r
	_side_rail_panel.offset_top = -rail_height * 0.5
	_side_rail_panel.offset_bottom = rail_height * 0.5
	_side_rail.add_theme_constant_override("separation", gap)
	$SideRail.add_theme_stylebox_override(
		"panel",
		UIFactory.panel_style(Color(0.07, 0.1, 0.16, 0.82), LunexColors.FRAME_OUTER, 18, 1)
	)
	for it_raw in items:
		var it: Dictionary = it_raw
		var b := Button.new()
		var sz := btn_size
		b.custom_minimum_size = Vector2(sz, sz)
		var icon_path := "res://assets/ui/navigation/%s.svg" % str(it.get("id", ""))
		if ResourceLoader.exists(icon_path):
			b.icon = load(icon_path)
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			b.text = str(it.get("tip", it.get("label", "")))
		b.tooltip_text = str(it.get("tip", it.get("label", "")))
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", int(sz * 0.47))
		var st := UIFactory.button_styles()
		var accent := Color(str(it.get("color", "#E8C56A")))
		var normal: StyleBoxFlat = (st["normal"] as StyleBoxFlat).duplicate()
		normal.border_color = LunexColors.FRAME_OUTER
		normal.set_corner_radius_all(16)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", st["hover"])
		b.add_theme_stylebox_override("pressed", st["pressed"])
		b.add_theme_color_override("font_color", accent)
		b.add_theme_color_override("font_hover_color", LunexColors.GOLD_BRIGHT)
		var route: String = str(it.get("route", ""))
		var tip: String = str(it.get("tip", it.get("label", "")))
		b.pressed.connect(func():
			AudioManager.play_ui_tap()
			ScreenRouter.go(route)
		)
		_side_rail.add_child(b)

func _on_building(def: Dictionary) -> void:
	if def.locked:
		ModalManager.push_locked(str(def.name), str(def.req))
		return
	AudioManager.play_ui_tap()
	var route: String = def.route
	if route == "ROOT-01":
		ScreenRouter.switch_tab("map")
		return
	var payload: Dictionary = def.get("payload", {})
	ScreenRouter.go(route, payload)

func _start_ambient() -> void:
	for tw in _ambient_tweens:
		if tw != null and is_instance_valid(tw):
			tw.kill()
	_ambient_tweens.clear()
	if DisplayServer.get_name() == "headless":
		return
	if ThemeManager.max_active_fx <= 0 or not ThemeManager.hub_pulse:
		return
	var sec := ThemeManager.hub_pulse_sec
	for p in _pulse_nodes:
		if p == null or not is_instance_valid(p):
			continue
		var tw := create_tween().set_loops()
		tw.tween_property(p, "modulate", Color(1.15, 1.1, 1.0, 1), sec)
		tw.tween_property(p, "modulate", Color(1, 1, 1, 1), sec)
		_ambient_tweens.append(tw)

func _apply_quality() -> void:
	_fx.visible = ThemeManager.hub_decor_layers >= 2
	_mid.visible = ThemeManager.hub_decor_layers >= 2
	_far.visible = ThemeManager.hub_decor_layers >= 1

func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()
