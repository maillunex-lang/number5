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
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
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
	var sky_top := Color(str(_look.get("sky_top", "#101a2c")))
	var sky_mid := Color(str(_look.get("sky_mid", "#132038")))
	var sky_bottom := Color(str(_look.get("sky_bottom", "#0b1220")))
	var mid_color := Color(str(_look.get("mid_color", "#1f332e")))
	var path_color := Color(str(_look.get("path_color", "#382e1f8c")))
	var bands := int(_parallax.get("far_bands", 4))
	var hills := int(_parallax.get("mid_hills", 6))
	var path_w := float(_parallax.get("path_width", 160))

	# Base sky gradient as stacked bands
	for i in maxi(bands, 1):
		var band := ColorRect.new()
		band.size = Vector2(ww, wh / float(maxi(bands, 1)) + 40.0)
		band.position = Vector2(0, i * (wh / float(maxi(bands, 1))))
		var t := float(i) / float(maxi(bands - 1, 1))
		band.color = sky_top.lerp(sky_mid, clamp(t * 1.2, 0.0, 1.0)).lerp(sky_bottom, clamp(t, 0.0, 1.0))
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_far.add_child(band)

	for i in hills:
		var hill := Panel.new()
		hill.size = Vector2(420 + (i % 3) * 80, 180)
		hill.position = Vector2((i * 190) % 900 - 40, 400 + i * 280)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(mid_color.r, mid_color.g, mid_color.b, 0.85)
		st.set_corner_radius_all(80)
		hill.add_theme_stylebox_override("panel", st)
		hill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mid.add_child(hill)

	var path := ColorRect.new()
	path.size = Vector2(path_w, wh)
	path.position = Vector2(ww * 0.5 - path_w * 0.5, 0)
	path.color = path_color
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_near.add_child(path)

	var vig_a := float(_look.get("vignette", 0.28))
	if vig_a > 0.01:
		_vignette = ColorRect.new()
		_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_vignette.color = Color(0, 0, 0, vig_a * 0.55)
		_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fx.add_child(_vignette)

func _build_buildings() -> void:
	_clear(_buildings)
	_pulse_nodes.clear()
	var glow_str := float(_look.get("glow", 0.45))
	for def in _building_defs:
		var bw: float = def.w
		var bh: float = def.h
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(bw, bh)
		btn.position = Vector2(float(def.x) - bw * 0.5, float(def.y) - bh * 0.5)
		btn.text = ""
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		var panel := Panel.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var st := StyleBoxFlat.new()
		var c: Color = def.color
		st.bg_color = Color(c.r * 0.25, c.g * 0.25, c.b * 0.25, 0.92)
		st.border_color = c if not def.locked else LunexColors.TEXT_MUTED
		st.set_border_width_all(3)
		st.set_corner_radius_all(18)
		st.shadow_color = Color(c.r, c.g, c.b, 0.25 + glow_str * 0.35)
		st.shadow_size = int(6 + glow_str * 14)
		panel.add_theme_stylebox_override("panel", st)
		btn.add_child(panel)
		var title := Label.new()
		title.text = str(def.name)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		title.offset_top = -70
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", LunexColors.TEXT_PRIMARY if not def.locked else LunexColors.TEXT_MUTED)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(title)
		if def.locked:
			var lock := Label.new()
			lock.text = "🔒"
			lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			lock.offset_left = -20
			lock.offset_right = 20
			lock.offset_top = -30
			lock.offset_bottom = 10
			lock.add_theme_font_size_override("font_size", 36)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(lock)
		else:
			_pulse_nodes.append(panel)
		var captured := def
		btn.pressed.connect(func(): _on_building(captured))
		_buildings.add_child(btn)
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
	var off_r := float(_rail_layout.get("offset_right", 12))
	var off_t := float(_rail_layout.get("offset_top", 12))
	var btn_size := float(_rail_layout.get("button_size", 64))
	var gap := int(_rail_layout.get("gap", 10))
	_side_rail_panel.offset_right = -off_r
	_side_rail_panel.offset_top = off_t
	_side_rail_panel.offset_left = -(off_r + btn_size + 28)
	_side_rail_panel.offset_bottom = off_t + 5.0 * (btn_size + gap) + 36.0
	_side_rail.add_theme_constant_override("separation", gap)
	$SideRail.add_theme_stylebox_override(
		"panel",
		UIFactory.panel_style(Color(0.07, 0.1, 0.16, 0.82), LunexColors.FRAME_OUTER, 18, 1)
	)
	var items: Array = ContentPackageLoader.get_side_rail()
	for it_raw in items:
		var it: Dictionary = it_raw
		var b := Button.new()
		var sz := float(it.get("size", btn_size))
		b.custom_minimum_size = Vector2(sz, sz)
		b.text = str(it.get("icon", "•"))
		b.tooltip_text = str(it.get("tip", ""))
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", int(sz * 0.47))
		var st := UIFactory.button_styles()
		var accent := Color(str(it.get("color", "#E8C56A")))
		var normal: StyleBoxFlat = (st["normal"] as StyleBoxFlat).duplicate()
		normal.border_color = accent
		normal.set_corner_radius_all(16)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", st["hover"])
		b.add_theme_stylebox_override("pressed", st["pressed"])
		b.add_theme_color_override("font_color", accent)
		b.add_theme_color_override("font_hover_color", LunexColors.GOLD_BRIGHT)
		var route: String = str(it.get("route", ""))
		var tip: String = str(it.get("tip", ""))
		b.pressed.connect(func():
			AudioManager.play_ui_tap()
			NotificationManager.info(tip)
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
