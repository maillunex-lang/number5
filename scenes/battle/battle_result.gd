extends Control
## COMBAT-03: итоги. Online → CORE-01 battle start/claim за награды; иначе демо.

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

	if ApiClient.online and sid != "":
		root.add_child(UIFactory.label("Синхронизация наград с CORE-01…", 24, LunexColors.EMERALD))
		var ok := await _claim_online(sid, root)
		if ok:
			_add_nav(root)
			return
		root.add_child(UIFactory.muted("Сервер недоступен · локальные демо-награды.", 20))

	root.add_child(UIFactory.label("Отряд одержал победу в локальной симуляции.", 26, LunexColors.EMERALD))
	var rewards := ["Золото ×1200", "Опыт героев", "Осколок ×5"]
	AppState.add_demo_rewards(1200, 5)
	for s in DemoData.campaign_progress["stages"]:
		if s.id == sid:
			s.state = "cleared"
	ModalManager.push_rewards("Награды (DEMO)", rewards)
	root.add_child(UIFactory.muted("Онлайн-награды — при сессии CORE-01.", 22))
	_add_nav(root)

func _claim_online(sid: String, root: VBoxContainer) -> bool:
	if _busy:
		return false
	_busy = true
	var start := await ApiClient.battle_start(sid)
	if start.get("ok", false) != true:
		_busy = false
		return false
	var data: Dictionary = start.get("data", {})
	if not bool(data.get("victory", false)):
		root.add_child(UIFactory.label("Сервер зафиксировал поражение — награды не выданы.", 22, LunexColors.TEXT_DANGER))
		_busy = false
		return true
	var bid := str(data.get("battle_id", ""))
	var claim := await ApiClient.battle_claim(bid)
	if claim.get("ok", false) != true:
		_busy = false
		return false
	var crewards: Dictionary = claim.get("data", {}).get("rewards", {})
	var lines: Array = []
	for k in crewards.keys():
		lines.append("%s ×%s" % [str(k), str(crewards[k])])
	if lines.is_empty():
		lines.append("Повторная зачистка · без first-clear")
	await ApiClient.sync_wallet()
	var prog: Dictionary = claim.get("data", {}).get("progress", {})
	if prog.has("current_stage"):
		DemoData.campaign_progress["current_stage"] = str(prog["current_stage"])
	for s in DemoData.campaign_progress["stages"]:
		if s.id == sid:
			s.state = "cleared"
	root.add_child(UIFactory.label("Награды с сервера (first-clear / claim).", 26, LunexColors.EMERALD))
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
