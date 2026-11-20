extends Node

func _ready() -> void:
	await _run()

func _run() -> void:
	print("SMOKE: start")
	AppState.enter_as_guest("SmokeTester")
	get_tree().change_scene_to_file("res://scenes/shell/game_shell.tscn")
	await get_tree().create_timer(1.0).timeout
	print("SMOKE: shell loaded, tab=", UIStateManager.current_tab)
	ScreenRouter.switch_tab("map")
	await get_tree().create_timer(0.35).timeout
	ScreenRouter.switch_tab("heroes")
	await get_tree().create_timer(0.35).timeout
	ScreenRouter.switch_tab("battle")
	await get_tree().create_timer(0.35).timeout
	ScreenRouter.switch_tab("hub")
	await get_tree().create_timer(0.35).timeout
	await ScreenRouter.go("HUB-02")
	await get_tree().create_timer(0.5).timeout
	ScreenRouter.handle_back()
	await get_tree().create_timer(0.5).timeout
	await ScreenRouter.go("MAP-01")
	await get_tree().create_timer(0.5).timeout
	await ScreenRouter.go("MAP-02", {"stage_id": "s1_3"})
	await get_tree().create_timer(0.5).timeout
	await ScreenRouter.go("COMBAT-01", {"stage_id": "s1_3", "mode": "campaign"})
	await get_tree().create_timer(0.5).timeout
	await ScreenRouter.go("COMBAT-02", {"stage_id": "s1_3", "mode": "campaign"})
	await get_tree().create_timer(3.0).timeout
	print("SMOKE: after battle window")
	await ScreenRouter.go("SETTINGS-01")
	await get_tree().create_timer(0.4).timeout
	ThemeManager.apply_preset("low")
	ThemeManager.apply_preset("high")
	print("SMOKE: PASS")
	get_tree().quit(0)
