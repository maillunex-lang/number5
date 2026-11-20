extends Node
## Автосъёмка экранов: создайте user://run_screenshots.flag

const OUT_DIR := "user://screenshots"
const ARTIFACT_DIR := "/opt/cursor/artifacts/lunex_screens"

var _busy := false

func _ready() -> void:
	if not FileAccess.file_exists("user://run_screenshots.flag"):
		return
	DirAccess.remove_absolute("user://run_screenshots.flag")
	call_deferred("_run")

func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)

func _shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_error("SHOT FAIL empty image: " + name)
		return
	# Portrait window may be scaled; keep as-is
	var path_user := "%s/%s.png" % [OUT_DIR, name]
	var path_art := "%s/%s.png" % [ARTIFACT_DIR, name]
	img.save_png(path_user)
	img.save_png(path_art)
	print("SHOT OK ", name, " -> ", path_art)

func _run() -> void:
	if _busy:
		return
	_busy = true
	_ensure_dirs()
	print("SHOTS: start")
	# --- Bootstrap screens ---
	await _shot("01_splash")
	# Jump through auth visuals
	get_tree().change_scene_to_file("res://scenes/bootstrap/auth.tscn")
	await get_tree().create_timer(0.6).timeout
	await _shot("02_auth")
	AppState.enter_as_guest("СкринКомандир")
	get_tree().change_scene_to_file("res://scenes/bootstrap/world_select.tscn")
	await get_tree().create_timer(0.5).timeout
	await _shot("03_world_select")
	get_tree().change_scene_to_file("res://scenes/shell/game_shell.tscn")
	await get_tree().create_timer(1.0).timeout
	await _shot("04_hub_home")

	# Tabs
	ScreenRouter.switch_tab("map")
	await get_tree().create_timer(0.45).timeout
	await _shot("05_tab_map")
	ScreenRouter.switch_tab("heroes")
	await get_tree().create_timer(0.55).timeout
	await _shot("06_tab_heroes")
	ScreenRouter.switch_tab("battle")
	await get_tree().create_timer(0.55).timeout
	await _shot("07_tab_battle")
	ScreenRouter.switch_tab("hub")
	await get_tree().create_timer(0.4).timeout

	# Nested / feature screens
	var routes := [
		["08_map_chapter", "MAP-01", {}],
		["09_stage_card", "MAP-02", {"stage_id": "s1_3"}],
		["10_formation", "COMBAT-01", {"stage_id": "s1_3", "mode": "campaign"}],
		["11_hero_details", "HERO-01", {"hero_id": "h_aria"}],
		["12_squad_manager", "HERO-02", {}],
		["13_summon", "HUB-01", {}],
		["14_afk", "HUB-02", {}],
		["15_quests", "HUB-03", {}],
		["16_events", "HUB-04", {}],
		["17_guild", "HUB-05", {}],
		["18_shop", "HUB-06", {}],
		["19_vip", "HUB-07", {}],
		["20_battle_pass", "HUB-08", {}],
		["21_social", "SOCIAL-01", {}],
		["22_chat", "SOCIAL-02", {}],
		["23_friends", "SOCIAL-03", {}],
		["24_mail", "SOCIAL-04", {}],
		["25_profile", "PROFILE-01", {}],
		["26_profile_public", "PROFILE-02", {}],
		["27_achievements", "PROFILE-03", {}],
		["28_settings", "SETTINGS-01", {}],
		["29_pve_tower", "PVE-01", {"mode": "tower"}],
		["30_pvp", "PVP-01", {}],
		["31_pvp_defense", "PVP-02", {}],
		["32_rankings", "RANK-01", {}],
		["33_rewards_panel", "GLOBAL-01", {}],
		["34_workshop", "WORKSHOP", {}],
		["35_sys_download", "SYS-07", {}],
		["36_sys_error", "SYS-08", {}],
	]
	for item in routes:
		var fname: String = item[0]
		var route: String = item[1]
		var payload: Dictionary = item[2]
		# Close overlays back to hub first for cleaner shots
		while ScreenRouter._shell != null and ScreenRouter._shell.has_method("has_overlay") and ScreenRouter._shell.has_overlay():
			await ScreenRouter._shell.close_overlay()
		ScreenRouter.switch_tab("hub")
		await get_tree().create_timer(0.25).timeout
		await ScreenRouter.go(route, payload)
		await get_tree().create_timer(0.55).timeout
		await _shot(fname)

	# Battle playback + result
	while ScreenRouter._shell != null and ScreenRouter._shell.has_overlay():
		await ScreenRouter._shell.close_overlay()
	UIStateManager.set_combat_context({"mode": "campaign", "stage_id": "s1_3", "return_route": "MAP-01"})
	await ScreenRouter.go("COMBAT-02", {"stage_id": "s1_3", "mode": "campaign"})
	await get_tree().create_timer(1.2).timeout
	await _shot("37_battle_playback")
	# Wait for battle end or force result
	await get_tree().create_timer(5.0).timeout
	await _shot("38_battle_result_or_playback")

	# Modal demo
	ModalManager.push_rewards("Демо-награды", ["Золото ×1000", "Осколок ×3", "Ключ ×1"])
	await get_tree().create_timer(0.5).timeout
	await _shot("39_modal_rewards")
	ModalManager.close_top()

	# Settings graphics tab already covered; show locked building modal from hub
	while ScreenRouter._shell != null and ScreenRouter._shell.has_overlay():
		await ScreenRouter._shell.close_overlay()
	ScreenRouter.switch_tab("hub")
	await get_tree().create_timer(0.3).timeout
	ModalManager.push_locked("Мастерская", "Откроется на 20 уровне командира")
	await get_tree().create_timer(0.4).timeout
	await _shot("40_modal_locked")
	ModalManager.close_top()

	# Asset bootstrap / version for completeness
	get_tree().change_scene_to_file("res://scenes/bootstrap/version_check.tscn")
	await get_tree().create_timer(0.35).timeout
	await _shot("41_version_check")
	get_tree().change_scene_to_file("res://scenes/bootstrap/asset_bootstrap.tscn")
	await get_tree().create_timer(0.45).timeout
	await _shot("42_asset_bootstrap")

	print("SHOTS: DONE")
	# Write manifest
	var mf := FileAccess.open("%s/manifest.txt" % ARTIFACT_DIR, FileAccess.WRITE)
	if mf:
		mf.store_string("Lunex AFK UI Prototype v0.1 screenshots\n")
		mf.close()
	get_tree().quit(0)
