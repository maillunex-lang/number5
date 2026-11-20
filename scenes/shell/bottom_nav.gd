@tool
extends PanelContainer
## Нижняя навигация (4 вкладки). Кнопки и отступы — в .tscn.

@export_category("Lunex Bottom Nav")
@export_group("Layout")
@export var bar_min_height: float = 156.0:
	set(v):
		bar_min_height = v
		custom_minimum_size.y = v
@export var pad_left: int = 8:
	set(v):
		pad_left = v
		_apply_pad()
@export var pad_right: int = 8:
	set(v):
		pad_right = v
		_apply_pad()
@export var pad_top: int = 10:
	set(v):
		pad_top = v
		_apply_pad()
@export var pad_bottom: int = 18:
	set(v):
		pad_bottom = v
		_apply_pad()
@export var row_separation: int = 6:
	set(v):
		row_separation = v
		_apply_row()
@export var tab_btn_min_height: float = 126.0:
	set(v):
		tab_btn_min_height = v
		_apply_tab_metrics()
@export var tab_font_size: int = 31:
	set(v):
		tab_font_size = v
		_apply_tab_metrics()

@export_group("Preview (editor only)")
@export_enum("map", "heroes", "hub", "battle") var preview_active_tab: String = "hub":
	set(v):
		preview_active_tab = v
		if Engine.is_editor_hint() and not _buttons.is_empty():
			set_active(preview_active_tab)

var _shell: Node
var _buttons: Dictionary = {}
@onready var _pad: MarginContainer = $Pad
@onready var _row: HBoxContainer = $Pad/Row

func _ready() -> void:
	custom_minimum_size.y = bar_min_height
	_apply_pad()
	_apply_row()
	_buttons = {
		"map": $Pad/Row/Map,
		"heroes": $Pad/Row/Heroes,
		"hub": $Pad/Row/Hub,
		"battle": $Pad/Row/Battle,
	}
	_apply_tab_metrics()
	if Engine.is_editor_hint():
		set_active(preview_active_tab)
		return

func setup(shell: Node) -> void:
	_shell = shell
	_apply_shell_chrome()
	_buttons = {
		"map": $Pad/Row/Map,
		"heroes": $Pad/Row/Heroes,
		"hub": $Pad/Row/Hub,
		"battle": $Pad/Row/Battle,
	}
	_apply_tab_metrics()
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

func _apply_pad() -> void:
	if _pad == null:
		return
	_pad.add_theme_constant_override("margin_left", pad_left)
	_pad.add_theme_constant_override("margin_right", pad_right)
	_pad.add_theme_constant_override("margin_top", pad_top)
	_pad.add_theme_constant_override("margin_bottom", pad_bottom)

func _apply_row() -> void:
	if _row == null:
		return
	_row.add_theme_constant_override("separation", row_separation)

func _apply_tab_metrics() -> void:
	if _buttons.is_empty():
		return
	for id in _buttons.keys():
		var b: Button = _buttons[id]
		if b == null:
			continue
		b.custom_minimum_size.y = tab_btn_min_height
		b.add_theme_font_size_override("font_size", tab_font_size)

func _apply_shell_chrome() -> void:
	var bn: Dictionary = ContentPackageLoader.shell.get("bottom_nav", {})
	var h := float(bn.get("height", 110))
	custom_minimum_size.y = maxf(h, bar_min_height)
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
		b.add_theme_font_size_override("font_size", tab_font_size)
		b.visible = bool(conf.get("enabled", true)) if not conf.is_empty() else true

func set_active(tab: String) -> void:
	var active_c := ThemeManager.color("nav_active", LunexColors.NAV_ACTIVE) if ThemeManager else LunexColors.NAV_ACTIVE
	var idle_c := ThemeManager.color("nav_idle", LunexColors.NAV_IDLE) if ThemeManager else LunexColors.NAV_IDLE
	for k in _buttons:
		var b: Button = _buttons[k]
		var on: bool = (str(k) == tab)
		b.modulate = active_c if on else idle_c
		b.disabled = false
