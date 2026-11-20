extends Node
## Единый маршрутизатор. NAV-FINAL-001 C: модалка -> вложенный -> вкладка -> выход.

signal route_changed(route_id: String)
signal tab_changed(tab: String)
signal overlay_changed(route_id: String)

const TABS := ["map", "heroes", "hub", "battle"]

## route_id -> scene path (packed or built)
var _registry: Dictionary = {}
var _history: Array[String] = []
var _current: String = ""
var _shell: Node = null
var _transition_busy: bool = false

func _ready() -> void:
	_register_routes()

func bind_shell(shell: Node) -> void:
	_shell = shell

func _register_routes() -> void:
	_registry = {
		"SYS-01": "res://scenes/bootstrap/splash.tscn",
		"SYS-02": "res://scenes/bootstrap/version_check.tscn",
		"SYS-03": "res://scenes/bootstrap/asset_bootstrap.tscn",
		"SYS-04": "res://scenes/bootstrap/auth.tscn",
		"SYS-05": "res://scenes/bootstrap/auth.tscn",
		"SYS-06": "res://scenes/bootstrap/world_select.tscn",
		"SYS-07": "res://scenes/features/sys_download.tscn",
		"SYS-08": "res://scenes/features/sys_error.tscn",
		"SYS-09": "", # modal layer
		"ROOT-01": "tab:map",
		"ROOT-02": "tab:heroes",
		"ROOT-03": "tab:hub",
		"ROOT-04": "tab:battle",
		"MAP-01": "res://scenes/map/chapter_map.tscn",
		"MAP-02": "res://scenes/map/stage_card.tscn",
		"HERO-01": "res://scenes/heroes/hero_details.tscn",
		"HERO-02": "res://scenes/heroes/squad_manager.tscn",
		"HUB-01": "res://scenes/features/summon.tscn",
		"HUB-02": "res://scenes/features/afk_rewards.tscn",
		"HUB-03": "res://scenes/features/quests.tscn",
		"HUB-04": "res://scenes/features/events.tscn",
		"HUB-05": "res://scenes/features/guild.tscn",
		"HUB-06": "res://scenes/features/shop.tscn",
		"HUB-07": "res://scenes/features/vip.tscn",
		"HUB-08": "res://scenes/features/battle_pass.tscn",
		"SOCIAL-01": "res://scenes/features/social_hub.tscn",
		"SOCIAL-02": "res://scenes/features/chat.tscn",
		"SOCIAL-03": "res://scenes/features/friends.tscn",
		"SOCIAL-04": "res://scenes/features/mail.tscn",
		"PROFILE-01": "res://scenes/features/profile.tscn",
		"PROFILE-02": "res://scenes/features/profile_public.tscn",
		"PROFILE-03": "res://scenes/features/achievements.tscn",
		"SETTINGS-01": "res://scenes/features/settings.tscn",
		"PVE-01": "res://scenes/features/pve_mode.tscn",
		"PVP-01": "res://scenes/features/pvp_center.tscn",
		"PVP-02": "res://scenes/features/pvp_defense.tscn",
		"RANK-01": "res://scenes/features/rankings.tscn",
		"COMBAT-01": "res://scenes/battle/formation.tscn",
		"COMBAT-02": "res://scenes/battle/battle_playback.tscn",
		"COMBAT-03": "res://scenes/battle/battle_result.tscn",
		"GLOBAL-01": "res://scenes/features/rewards_panel.tscn",
		"WORKSHOP": "res://scenes/features/workshop.tscn",
		"EXPEDITIONS": "res://scenes/features/expeditions.tscn",
		"TOWER": "res://scenes/features/pve_mode.tscn",
	}

func go(route_id: String, payload: Dictionary = {}, push_history: bool = true) -> void:
	if _transition_busy:
		return
	var target: String = _registry.get(route_id, "")
	if target.begins_with("tab:"):
		var tab := target.substr(4)
		switch_tab(tab)
		_current = route_id
		if push_history:
			_push_hist(route_id)
		route_changed.emit(route_id)
		return
	if route_id == "SYS-09":
		return
	if target == "" and not route_id.begins_with("SYS"):
		NotificationManager.warn("Маршрут %s не найден" % route_id)
		return
	if _shell and _shell.has_method("open_overlay"):
		_transition_busy = true
		await _shell.open_overlay(route_id, target, payload)
		_transition_busy = false
		_current = route_id
		if push_history:
			_push_hist(route_id)
		route_changed.emit(route_id)
		overlay_changed.emit(route_id)
	elif target != "":
		get_tree().change_scene_to_file(target)

func switch_tab(tab: String) -> void:
	if tab not in TABS:
		return
	UIStateManager.remember_tab(tab)
	if _shell and _shell.has_method("show_tab"):
		_shell.show_tab(tab)
	tab_changed.emit(tab)
	_current = "ROOT-%02d" % [["map", "heroes", "hub", "battle"].find(tab) + 1]
	# Reset nested history to tab root
	_history.clear()
	_history.append(_current)

func _push_hist(route_id: String) -> void:
	if _history.is_empty() or _history.back() != route_id:
		_history.append(route_id)

func current_route() -> String:
	return _current

func history_depth() -> int:
	return _history.size()

## NAV-FINAL-001 C
func handle_back() -> void:
	if ModalManager.is_open():
		ModalManager.close_top()
		return
	if _shell and _shell.has_method("has_overlay") and _shell.has_overlay():
		if _history.size() > 1:
			_history.pop_back()
			var prev: String = _history.back()
			var prev_target: String = _registry.get(prev, "")
			if prev_target.begins_with("tab:"):
				if _shell.has_method("close_overlay"):
					await _shell.close_overlay()
				switch_tab(prev_target.substr(4))
			else:
				# reopen previous overlay without growing history
				if _shell.has_method("open_overlay"):
					await _shell.open_overlay(prev, prev_target, {})
				_current = prev
				route_changed.emit(prev)
		else:
			if _shell.has_method("close_overlay"):
				await _shell.close_overlay()
			switch_tab(UIStateManager.current_tab)
		return
	# On root tab — confirm exit
	ModalManager.push_confirm(
		"Выход",
		"Закрыть Lunex AFK?\n(локальный прототип)",
		func(): get_tree().quit(),
		Callable(),
		"exit_game"
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_back()
		get_viewport().set_input_as_handled()

func enter_game_shell() -> void:
	get_tree().change_scene_to_file("res://scenes/shell/game_shell.tscn")
