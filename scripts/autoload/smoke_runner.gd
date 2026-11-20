extends Node
## Включается только если существует user://run_smoke.flag

func _ready() -> void:
	if not FileAccess.file_exists("user://run_smoke.flag"):
		return
	DirAccess.remove_absolute("user://run_smoke.flag")
	call_deferred("_run")

func _run() -> void:
	print("SMOKE: flag detected, waiting splash pipeline…")
	# Skip bootstrap: jump after a short wait if still on splash
	await get_tree().create_timer(0.1).timeout
	if not ContentPackageLoader.loaded:
		push_error("SMOKE: ContentPackage not loaded")
		get_tree().quit(2)
		return
	print("SMOKE: package ", ContentPackageLoader.version, " heroes=", DemoData.heroes.size())
	if DemoData.heroes.is_empty() or DemoData.campaign_progress.get("stages", []).is_empty():
		push_error("SMOKE: package data empty")
		get_tree().quit(2)
		return
	AppState.enter_as_guest("SmokeTester")
	get_tree().change_scene_to_file("res://scenes/shell/game_shell.tscn")
	await get_tree().create_timer(1.2).timeout
	print("SMOKE: shell")
	ScreenRouter.switch_tab("map")
	await get_tree().create_timer(0.3).timeout
	ScreenRouter.switch_tab("heroes")
	await get_tree().create_timer(0.3).timeout
	ScreenRouter.switch_tab("battle")
	await get_tree().create_timer(0.3).timeout
	ScreenRouter.switch_tab("hub")
	await get_tree().create_timer(0.3).timeout
	await ScreenRouter.go("HUB-02")
	await get_tree().create_timer(0.45).timeout
	ScreenRouter.handle_back()
	await get_tree().create_timer(0.45).timeout
	await ScreenRouter.go("HERO-02")
	await get_tree().create_timer(0.4).timeout
	ScreenRouter.handle_back()
	await get_tree().create_timer(0.4).timeout
	var stage_id := str(DemoData.campaign_progress.get("current_stage", "CH01-03"))
	var foes := DemoData.enemy_squad_for_stage(stage_id)
	print("SMOKE: stage ", stage_id, " foes=", foes.size(), " first=", (foes[0]["name"] if foes.size() else "?"))
	await ScreenRouter.go("COMBAT-01", {"stage_id": stage_id, "mode": "campaign"})
	await get_tree().create_timer(0.4).timeout
	await ScreenRouter.go("COMBAT-02", {"stage_id": stage_id, "mode": "campaign"})
	await get_tree().create_timer(4.0).timeout
	ThemeManager.apply_preset("low")
	ThemeManager.apply_preset("high")
	print("SMOKE: PASS package=", ContentPackageLoader.version, " heroes=", DemoData.heroes.size())
	get_tree().quit(0)
