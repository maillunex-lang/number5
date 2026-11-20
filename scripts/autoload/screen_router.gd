extends Node
## Lightweight screen navigation. MainHub listens and swaps content.

signal tab_changed(tab_id: String)
signal overlay_requested(scene_path: String)
signal overlay_closed
signal navigate_to_auth

const TAB_HOME := "home"
const TAB_HEROES := "heroes"
const TAB_GUILD := "guild"
const TAB_SHOP := "shop"
const TAB_MORE := "more"

var current_tab: String = TAB_HOME
var overlay_open: bool = false


func go_tab(tab_id: String) -> void:
	if current_tab == tab_id and not overlay_open:
		return
	current_tab = tab_id
	tab_changed.emit(tab_id)


func open_overlay(scene_path: String) -> void:
	overlay_open = true
	overlay_requested.emit(scene_path)


func close_overlay() -> void:
	if not overlay_open:
		return
	overlay_open = false
	overlay_closed.emit()


func open_battle() -> void:
	open_overlay("res://scenes/battle/battle_screen.tscn")


func open_chat() -> void:
	open_overlay("res://scenes/chat/chat_screen.tscn")


func request_logout() -> void:
	AppState.logout()
	navigate_to_auth.emit()
