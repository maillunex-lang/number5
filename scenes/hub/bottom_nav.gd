extends PanelContainer

const TABS := [
	{"id": ScreenRouter.TAB_HOME, "label": "Home"},
	{"id": ScreenRouter.TAB_HEROES, "label": "Heroes"},
	{"id": ScreenRouter.TAB_GUILD, "label": "Guild"},
	{"id": ScreenRouter.TAB_SHOP, "label": "Shop"},
	{"id": ScreenRouter.TAB_MORE, "label": "More"},
]

var _buttons: Dictionary = {}


func _ready() -> void:
	UIStyle.apply_panel(self, UIColors.BG_PANEL)
	var row: HBoxContainer = %NavRow
	for child in row.get_children():
		child.queue_free()
	for tab in TABS:
		var btn := Button.new()
		btn.text = tab.label
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 72)
		UIStyle.apply_button(btn, false)
		btn.pressed.connect(_on_tab.bind(tab.id))
		row.add_child(btn)
		_buttons[tab.id] = btn
	ScreenRouter.tab_changed.connect(_highlight)
	_highlight(ScreenRouter.current_tab)


func _on_tab(tab_id: String) -> void:
	ScreenRouter.close_overlay()
	ScreenRouter.go_tab(tab_id)


func _highlight(tab_id: String) -> void:
	for id in _buttons:
		var btn: Button = _buttons[id]
		UIStyle.apply_button(btn, id == tab_id)
