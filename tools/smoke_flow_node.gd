extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	print("SMOKE: start")
	AppState.enter_as_guest("SmokeTester")
	var shell := preload("res://scenes/shell/game_shell.tscn").instantiate()
	get_tree().root.add_child(shell)
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
	var stage_id := "CH01-01"
	await ScreenRouter.go("MAP-02", {"stage_id": stage_id})
	await get_tree().create_timer(0.5).timeout
	await ScreenRouter.go("COMBAT-01", {"stage_id": stage_id, "mode": "campaign"})
	await get_tree().create_timer(0.5).timeout
	await ScreenRouter.go("COMBAT-02", {"stage_id": stage_id, "mode": "campaign"})
	await get_tree().create_timer(3.0).timeout
	print("SMOKE: after battle window stage=", stage_id)
	await ScreenRouter.go("SETTINGS-01")
	await get_tree().create_timer(0.4).timeout
	ThemeManager.apply_preset("low")
	ThemeManager.apply_preset("high")
	print("SMOKE: PASS")
	get_tree().quit(0)
