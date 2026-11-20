extends PanelContainer

var _shell: Node
var _buttons: Dictionary = {}

func setup(shell: Node) -> void:
	_shell = shell
	_apply_shell_chrome()
	_buttons = {
		"map": $Pad/Row/Map,
		"heroes": $Pad/Row/Heroes,
		"hub": $Pad/Row/Hub,
		"battle": $Pad/Row/Battle,
	}
	_apply_tab_labels()
	_buttons["map"].pressed.connect(func(): _shell.on_nav("map"))
	_buttons["heroes"].pressed.connect(func(): _shell.on_nav("heroes"))
	_buttons["hub"].pressed.connect(func(): _shell.on_nav("hub"))
	_buttons["battle"].pressed.connect(func(): _shell.on_nav("battle"))
	set_active("hub")
	ContentPackageLoader.package_loaded.connect(func(_v):
		_apply_shell_chrome()
		_apply_tab_labels()
	)

func _apply_shell_chrome() -> void:
	var bn: Dictionary = ContentPackageLoader.shell.get("bottom_nav", {})
	var h := float(bn.get("height", 110))
	custom_minimum_size.y = maxf(h, 156.0)
	var bg := Color(str(bn.get("bg", "#101A2C")))
	var border := Color(str(bn.get("border", "#3A4A68")))
	add_theme_stylebox_override("panel", UIFactory.panel_style(bg, border, ThemeManager.radius("lg"), 2))

func _apply_tab_labels() -> void:
	var tabs: Array = ContentPackageLoader.get_shell_tabs()
	var by_id := {}
	for t in tabs:
		by_id[str(t.get("id", ""))] = t
	for id in _buttons.keys():
		var b: Button = _buttons[id]
		var conf: Dictionary = by_id.get(id, {})
		var label := ContentPackageLoader.tr_key("nav.%s" % id, str(conf.get("label", id)))
		b.icon = load("res://assets/ui/navigation/%s.svg" % id)
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.text = label
		b.add_theme_font_size_override("font_size", 31)
		b.visible = bool(conf.get("enabled", true)) if not conf.is_empty() else true

func set_active(tab: String) -> void:
	var active_c := ThemeManager.color("nav_active", LunexColors.NAV_ACTIVE)
	var idle_c := ThemeManager.color("nav_idle", LunexColors.NAV_IDLE)
	for k in _buttons:
		var b: Button = _buttons[k]
		var on: bool = (str(k) == tab)
		b.modulate = active_c if on else idle_c
		b.disabled = false
