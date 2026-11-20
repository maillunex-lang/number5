extends Control
## COMBAT-03: итоги серверного боя, серверный claim по battle_id.

var _payload: Dictionary = {}
var _busy: bool = false

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	await _build()

func _build() -> void:
	var victory: bool = bool(_payload.get("victory", false))
	var aborted: bool = bool(_payload.get("aborted", false))
	var sid: String = str(_payload.get("stage_id", ""))
	var root := $Safe/VBox
	for c in root.get_children():
		c.queue_free()

	if aborted:
		root.add_child(UIFactory.title("Бой прерван", 42))
		root.add_child(UIFactory.muted("Награды не выданы.", 22))
		_add_nav(root)
		return

	if not victory:
		root.add_child(UIFactory.title("Поражение", 48))
		root.add_child(UIFactory.label("Усильте отряд и попробуйте снова.", 26, LunexColors.TEXT_DANGER))
		root.add_child(UIFactory.muted("Серверный claim только при победе.", 20))
		_add_nav(root)
		return

	root.add_child(UIFactory.title("Победа!", 48))

	var bid := str(_payload.get("battle_id", ""))
	if ApiClient.online and bid != "":
		root.add_child(UIFactory.label("Подтверждение наград на сервере…", 24, LunexColors.EMERALD))
		var ok := await _claim_online(bid, sid, root)
		if ok:
			_add_nav(root)
			return
		root.add_child(UIFactory.muted("Не удалось подтвердить результат на сервере. Награды не выданы.", 22))
	else:
		root.add_child(UIFactory.muted("Нет онлайн-сессии. Награды не выданы.", 22))
	_add_nav(root)

func _claim_online(bid: String, sid: String, root: VBoxContainer) -> bool:
	if _busy:
		return false
	_busy = true
	var claim := await ApiClient.battle_claim(bid)
	if not claim.get("ok", false):
		_busy = false
		return false
	var crewards: Dictionary = claim.get("data", {}).get("rewards", {})
	var lines: Array = []
	for k in crewards.keys():
		lines.append("%s ×%s" % [str(k), str(crewards[k])])
	if lines.is_empty():
		lines.append("Повторное прохождение")
	await ApiClient.sync_wallet()
	var campaign := await ApiClient.get_campaign()
	if campaign.get("ok", false):
		var prog: Dictionary = campaign.get("data", {})
		DemoData.campaign_progress["current_stage"] = str(prog.get("current_stage", ""))
		var cleared: Dictionary = {}
		for st in prog.get("cleared", []):
			cleared[str(st.get("StageID", st.get("stage_id", "")))] = true
		for st in DemoData.campaign_progress.get("stages", []):
			var stage_key := str(st.get("id", ""))
			st["state"] = "cleared" if cleared.has(stage_key) else ("current" if stage_key == DemoData.campaign_progress["current_stage"] else "locked")
	root.add_child(UIFactory.label("Награды подтверждены сервером.", 26, LunexColors.EMERALD))
	ModalManager.push_rewards("Награды (ONLINE)", lines)
	root.add_child(UIFactory.muted("battle_id %s · CORE-01" % bid, 18))
	_busy = false
	return true

func _add_nav(root: VBoxContainer) -> void:
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
		while ScreenRouter._shell and ScreenRouter._shell.has_overlay():
			await ScreenRouter._shell.close_overlay()
		ScreenRouter.switch_tab("hub")
	)
	root.add_child(hub)
