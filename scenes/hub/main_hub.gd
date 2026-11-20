extends Control

const TAB_SCENES := {
	ScreenRouter.TAB_HOME: "res://scenes/home/home_tab.tscn",
	ScreenRouter.TAB_HEROES: "res://scenes/heroes/heroes_screen.tscn",
	ScreenRouter.TAB_GUILD: "res://scenes/guild/guild_screen.tscn",
	ScreenRouter.TAB_SHOP: "res://scenes/shop/shop_screen.tscn",
	ScreenRouter.TAB_MORE: "res://scenes/hub/more_menu.tscn",
}

@onready var _content: Control = %ContentHost
@onready var _overlay: Control = %OverlayHost


func _ready() -> void:
	if not AppState.logged_in:
		get_tree().change_scene_to_file("res://scenes/auth/auth_screen.tscn")
		return
	ScreenRouter.tab_changed.connect(_on_tab)
	ScreenRouter.overlay_requested.connect(_on_overlay)
	ScreenRouter.overlay_closed.connect(_clear_overlay)
	ScreenRouter.navigate_to_auth.connect(_to_auth)
	_on_tab(ScreenRouter.current_tab)


func _on_tab(tab_id: String) -> void:
	_clear_overlay()
	for child in _content.get_children():
		child.queue_free()
	var path: String = TAB_SCENES.get(tab_id, TAB_SCENES[ScreenRouter.TAB_HOME])
	var packed: PackedScene = load(path)
	if packed:
		var node: Control = packed.instantiate()
		_content.add_child(node)
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_overlay(scene_path: String) -> void:
	_clear_overlay()
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return
	var node: Control = packed.instantiate()
	_overlay.visible = true
	_overlay.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _clear_overlay() -> void:
	for child in _overlay.get_children():
		child.queue_free()
	_overlay.visible = false
	ScreenRouter.overlay_open = false


func _to_auth() -> void:
	get_tree().change_scene_to_file("res://scenes/auth/auth_screen.tscn")
