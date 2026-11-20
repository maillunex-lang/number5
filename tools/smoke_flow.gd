extends SceneTree
## Автотест навигации прототипа (headless).

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("SMOKE: start")
	await create_timer(0.2).timeout
	# Jump into shell as guest
	AppState.enter_as_guest("SmokeTester")
	change_scene_to_file("res://scenes/shell/game_shell.tscn")
	await create_timer(0.8).timeout
	print("SMOKE: shell loaded")
	ScreenRouter.switch_tab("map")
	await create_timer(0.3).timeout
	ScreenRouter.switch_tab("heroes")
	await create_timer(0.3).timeout
	ScreenRouter.switch_tab("battle")
	await create_timer(0.3).timeout
	ScreenRouter.switch_tab("hub")
	await create_timer(0.3).timeout
	ScreenRouter.go("HUB-01")
	await create_timer(0.5).timeout
	ScreenRouter.handle_back()
	await create_timer(0.4).timeout
	ScreenRouter.go("MAP-01")
	await create_timer(0.4).timeout
	ScreenRouter.go("MAP-02", {"stage_id": "s1_3"})
	await create_timer(0.4).timeout
	ScreenRouter.go("COMBAT-01", {"stage_id": "s1_3", "mode": "campaign"})
	await create_timer(0.4).timeout
	ScreenRouter.go("COMBAT-02", {"stage_id": "s1_3", "mode": "campaign"})
	await create_timer(2.5).timeout
	print("SMOKE: battle running/finished")
	ScreenRouter.go("SETTINGS-01")
	await create_timer(0.3).timeout
	ThemeManager.apply_preset("low")
	ThemeManager.apply_preset("ultra")
	ThemeManager.apply_preset("high")
	print("SMOKE: presets ok")
	print("SMOKE: PASS")
	quit(0)
