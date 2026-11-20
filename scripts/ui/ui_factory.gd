class_name UIFactory
extends RefCounted
## Lunex UI Kit helpers — fantasy panels, buttons, labels (Anime Fantasy).

static func label(text: String, size: int = 28, color: Color = LunexColors.TEXT_PRIMARY, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		var font := load("res://fonts/Cinzel-Bold.ttf")
		if font:
			l.add_theme_font_override("font", font)
	else:
		var font2 := load("res://fonts/OpenSans-SemiBold.ttf") if size >= 26 else load("res://fonts/OpenSans-Regular.ttf")
		if font2:
			l.add_theme_font_override("font", font2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func title(text: String, size: int = 40) -> Label:
	return label(text, size, LunexColors.GOLD_BRIGHT, true)

static func muted(text: String, size: int = 22) -> Label:
	return label(text, size, LunexColors.TEXT_MUTED, false)

static func _c(key: String, fallback: Color) -> Color:
	if Engine.is_editor_hint():
		return fallback
	if ThemeManager and ThemeManager.palette.size() > 0:
		return ThemeManager.color(key, fallback)
	return fallback

static func _r(key: String, fallback: int) -> int:
	if Engine.is_editor_hint():
		return fallback
	if ThemeManager and ThemeManager.radius_map.size() > 0:
		return ThemeManager.radius(key)
	return fallback

static func panel_style(bg: Color = LunexColors.BG_PANEL, border: Color = LunexColors.FRAME_INNER, radius: int = 16, border_w: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius if radius > 0 else _r("md", 16))
	var spacing_md := 16
	if not Engine.is_editor_hint() and ContentPackageLoader.theme.has("spacing"):
		spacing_md = int(ContentPackageLoader.theme["spacing"].get("md", 16))
	s.content_margin_left = spacing_md
	s.content_margin_right = spacing_md
	s.content_margin_top = int(spacing_md * 0.75)
	s.content_margin_bottom = int(spacing_md * 0.75)
	s.shadow_color = Color(0, 0, 0, 0.35)
	var shadow := 6
	if not Engine.is_editor_hint() and ThemeManager.components.has("shadow_size"):
		shadow = int(ThemeManager.components["shadow_size"])
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, 3)
	return s

static func button_styles() -> Dictionary:
	var rad := _r("md", 14)
	var n := panel_style(_c("button_normal", LunexColors.BUTTON_NORMAL), _c("gold_dim", LunexColors.GOLD_DIM), rad, 2)
	var h := panel_style(_c("button_hover", LunexColors.BUTTON_HOVER), _c("gold", LunexColors.GOLD), rad, 2)
	var p := panel_style(_c("button_pressed", LunexColors.BUTTON_PRESSED), _c("gold_bright", LunexColors.GOLD_BRIGHT), rad, 2)
	var d := panel_style(LunexColors.BUTTON_DISABLED, _c("frame_outer", LunexColors.FRAME_OUTER), rad, 1)
	return {"normal": n, "hover": h, "pressed": p, "disabled": d}

static func fantasy_button(text: String, min_h: int = 64) -> Button:
	var h := min_h
	if not Engine.is_editor_hint() and ThemeManager.components.has("button_height"):
		h = int(ThemeManager.components["button_height"]) if min_h == 64 else min_h
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, h)
	var st := button_styles()
	b.add_theme_stylebox_override("normal", st.normal)
	b.add_theme_stylebox_override("hover", st.hover)
	b.add_theme_stylebox_override("pressed", st.pressed)
	b.add_theme_stylebox_override("disabled", st.disabled)
	b.add_theme_color_override("font_color", _c("text_primary", LunexColors.TEXT_PRIMARY))
	b.add_theme_color_override("font_hover_color", _c("gold_bright", LunexColors.GOLD_BRIGHT))
	b.add_theme_color_override("font_pressed_color", _c("gold", LunexColors.GOLD))
	b.add_theme_font_size_override("font_size", 28)
	var font := load("res://fonts/OpenSans-SemiBold.ttf")
	if font:
		b.add_theme_font_override("font", font)
	b.focus_mode = Control.FOCUS_NONE
	return b

static func gold_button(text: String, min_h: int = 72) -> Button:
	var hh := min_h
	if not Engine.is_editor_hint() and ThemeManager.components.has("gold_button_height"):
		hh = int(ThemeManager.components["gold_button_height"]) if min_h == 72 else min_h
	var b := fantasy_button(text, hh)
	var rad := _r("lg", 16)
	var n := panel_style(Color("5A4318"), _c("gold_bright", LunexColors.GOLD_BRIGHT), rad, 2)
	var h := panel_style(Color("6E5420"), Color("FFF0C0"), rad, 2)
	var p := panel_style(Color("3E2E10"), _c("gold", LunexColors.GOLD), rad, 2)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_color_override("font_color", _c("gold_bright", LunexColors.GOLD_BRIGHT))
	return b

static func panel(bg: Color = LunexColors.BG_PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	var use_bg := bg
	if bg == LunexColors.BG_PANEL:
		use_bg = _c("bg_panel", LunexColors.BG_PANEL)
	p.add_theme_stylebox_override("panel", panel_style(use_bg, _c("frame_inner", LunexColors.FRAME_INNER), _r("lg", 16), 2))
	return p

static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func spacer(h: int = 16) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func demo_badge() -> Label:
	var l := label("ДЕМО", 18, LunexColors.AMBER, true)
	return l

static func safe_margins(ctrl: Control, top: int = 24, bottom: int = 24, left: int = 20, right: int = 20) -> void:
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ctrl.offset_top = top
	ctrl.offset_bottom = -bottom
	ctrl.offset_left = left
	ctrl.offset_right = -right

static func make_bg(parent: Control, top: Color, bottom: Color) -> TextureRect:
	var tr := TextureRect.new()
	tr.name = "BG"
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture = AssetLoader.make_gradient_texture(top, bottom, 16, 256)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	parent.move_child(tr, 0)
	return tr

static func hero_portrait(tint: Color, size: Vector2 = Vector2(160, 200)) -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = size
	var glow := TextureRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.texture = AssetLoader.make_radial_glow(tint, 128)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(glow)
	var body := Panel.new()
	body.set_anchors_preset(Control.PRESET_CENTER)
	body.custom_minimum_size = Vector2(size.x * 0.55, size.y * 0.7)
	body.offset_left = -size.x * 0.275
	body.offset_top = -size.y * 0.28
	body.offset_right = size.x * 0.275
	body.offset_bottom = size.y * 0.42
	var st := StyleBoxFlat.new()
	st.bg_color = Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1)
	st.border_color = tint
	st.set_border_width_all(3)
	st.set_corner_radius_all(18)
	body.add_theme_stylebox_override("panel", st)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(body)
	var head := Panel.new()
	head.custom_minimum_size = Vector2(size.x * 0.32, size.x * 0.32)
	head.set_anchors_preset(Control.PRESET_CENTER_TOP)
	head.offset_left = -size.x * 0.16
	head.offset_right = size.x * 0.16
	head.offset_top = size.y * 0.08
	head.offset_bottom = size.y * 0.08 + size.x * 0.32
	var hs := StyleBoxFlat.new()
	hs.bg_color = Color(tint.r * 0.75, tint.g * 0.75, tint.b * 0.75, 1)
	hs.set_corner_radius_all(99)
	hs.border_color = LunexColors.GOLD_DIM
	hs.set_border_width_all(2)
	head.add_theme_stylebox_override("panel", hs)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(head)
	return wrap

static func currency_chip(icon_text: String, value: String, color: Color) -> PanelContainer:
	var p := panel(Color(0.08, 0.1, 0.16, 0.85))
	p.add_theme_stylebox_override("panel", panel_style(Color(0.08, 0.1, 0.16, 0.85), color, 20, 1))
	var h := hbox(8)
	p.add_child(h)
	h.add_child(label(icon_text, 22, color, true))
	h.add_child(label(value, 24, LunexColors.TEXT_PRIMARY, false))
	return p

static func section_header(text: String) -> HBoxContainer:
	var h := hbox(10)
	h.add_child(title(text, 32))
	h.add_child(demo_badge())
	return h
