class_name UIStyle
extends RefCounted
## Builds StyleBox / Theme helpers used by shell screens.


static func panel(bg: Color = UIColors.BG_PANEL, radius: float = 12.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius))
	s.set_content_margin_all(12)
	s.border_color = UIColors.BORDER
	s.set_border_width_all(1)
	return s


static func button_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = UIColors.BG_PANEL_ALT
	s.set_corner_radius_all(10)
	s.set_content_margin_all(10)
	s.border_color = UIColors.BORDER
	s.set_border_width_all(1)
	return s


static func button_hover() -> StyleBoxFlat:
	var s := button_normal()
	s.bg_color = UIColors.BG_SLOT
	s.border_color = UIColors.ACCENT_DIM
	return s


static func button_pressed() -> StyleBoxFlat:
	var s := button_normal()
	s.bg_color = UIColors.ACCENT_DIM
	return s


static func button_accent() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = UIColors.ACCENT
	s.set_corner_radius_all(10)
	s.set_content_margin_all(12)
	s.border_color = Color("e0c45a")
	s.set_border_width_all(1)
	return s


static func apply_button(btn: Button, accent: bool = false) -> void:
	if accent:
		btn.add_theme_stylebox_override("normal", button_accent())
		btn.add_theme_stylebox_override("hover", button_accent())
		btn.add_theme_stylebox_override("pressed", button_pressed())
		btn.add_theme_color_override("font_color", UIColors.BG_DEEP)
		btn.add_theme_color_override("font_hover_color", UIColors.BG_DEEP)
		btn.add_theme_color_override("font_pressed_color", UIColors.TEXT)
	else:
		btn.add_theme_stylebox_override("normal", button_normal())
		btn.add_theme_stylebox_override("hover", button_hover())
		btn.add_theme_stylebox_override("pressed", button_pressed())
		btn.add_theme_color_override("font_color", UIColors.TEXT)
		btn.add_theme_color_override("font_hover_color", UIColors.TEXT)
		btn.add_theme_color_override("font_pressed_color", UIColors.TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 22)


static func apply_panel(target: PanelContainer, bg: Color = UIColors.BG_PANEL) -> void:
	target.add_theme_stylebox_override("panel", panel(bg))


static func label_title(lbl: Label, size: int = 36) -> void:
	lbl.add_theme_color_override("font_color", UIColors.TEXT)
	lbl.add_theme_font_size_override("font_size", size)


static func label_dim(lbl: Label, size: int = 18) -> void:
	lbl.add_theme_color_override("font_color", UIColors.TEXT_DIM)
	lbl.add_theme_font_size_override("font_size", size)
