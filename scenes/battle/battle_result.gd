extends Control
## COMBAT-03: итоги демо-боя

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var victory: bool = bool(_payload.get("victory", false))
	var aborted: bool = bool(_payload.get("aborted", false))
	var root := $Safe/VBox
	for c in root.get_children():
		c.queue_free()
	if aborted:
		root.add_child(UIFactory.title("Бой прерван", 42))
	elif victory:
		root.add_child(UIFactory.title("Победа!", 48))
		root.add_child(UIFactory.label("Отряд одержал победу в локальной симуляции.", 26, LunexColors.EMERALD))
		var rewards := ["Золото ×1200", "Опыт героев", "Осколок ×5"]
		AppState.add_demo_rewards(1200, 5)
		DemoData.afk_seconds_accumulated = maxi(0, DemoData.afk_seconds_accumulated)
		# mark stage cleared demo
		var sid: String = str(_payload.get("stage_id", ""))
		for s in DemoData.campaign_progress["stages"]:
			if s.id == sid:
				s.state = "cleared"
		ModalManager.push_rewards("Награды (демо)", rewards)
	else:
		root.add_child(UIFactory.title("Поражение", 48))
		root.add_child(UIFactory.label("Усильте отряд и попробуйте снова.", 26, LunexColors.TEXT_DANGER))
	root.add_child(UIFactory.muted("Это UI-прототип. Онлайн-бой и серверные награды не реализованы.", 22))
	var again := UIFactory.gold_button("Повторить")
	again.pressed.connect(func():
		ScreenRouter.go("COMBAT-01", {
			"stage_id": _payload.get("stage_id", ""),
			"mode": _payload.get("mode", "campaign"),
		})
	)
	root.add_child(again)
	var next := UIFactory.fantasy_button("К карте главы")
	next.pressed.connect(func():
		ScreenRouter.go("MAP-01")
	)
	root.add_child(next)
	var hub := UIFactory.fantasy_button("В хаб")
	hub.pressed.connect(func():
		# Close overlays back to hub tab
		while ScreenRouter._shell and ScreenRouter._shell.has_overlay():
			await ScreenRouter._shell.close_overlay()
		ScreenRouter.switch_tab("hub")
	)
	root.add_child(hub)
