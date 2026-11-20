extends Control
## HUB-02: AFK. Online → CORE-01 /afk; иначе локальный демо-расчёт.

var _payload: Dictionary = {}
var _busy: bool = false
var _online_status: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	if ApiClient.online:
		var res := await ApiClient.afk_status()
		if res.get("ok", false):
			_online_status = res.get("data", {})
	_rebuild()

func _afk_cfg() -> Dictionary:
	var live: Dictionary = ContentPackageLoader.liveops.get("afk", {})
	if not live.is_empty():
		return live
	return ContentPackageLoader.features.get("afk", {})

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var afk := _afk_cfg()
	var unlock := str(afk.get("unlock_stage", "CH01-03"))
	var mode := "ONLINE · CORE-01" if ApiClient.online and not _online_status.is_empty() else "DEMO"

	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("afk.title", "AFK-сокровищница")))
	root.add_child(UIFactory.muted("%s · %s · открытие после %s" % [ContentPackageLoader.package_label(), mode, unlock], 18))

	var gold_amt := 0
	var xp_amt := 0
	var ess_amt := 0
	var h := 0
	var m := 0
	var cap_h := int(afk.get("cap_hours", 12))
	var can_claim := false

	if ApiClient.online and not _online_status.is_empty():
		var sec := int(_online_status.get("accumulated_sec", 0))
		var cap := int(_online_status.get("cap_sec", cap_h * 3600))
		h = sec / 3600
		m = (sec % 3600) / 60
		cap_h = maxi(1, cap / 3600)
		var preview: Dictionary = _online_status.get("preview", {})
		gold_amt = int(preview.get("gold", 0))
		xp_amt = int(preview.get("hero_xp", 0))
		ess_amt = int(preview.get("essence", 0))
		can_claim = bool(_online_status.get("can_claim", false))
		root.add_child(UIFactory.label("Накоплено: %dч %dм / кап %dч" % [h, m, cap_h], 28, LunexColors.GOLD))
	else:
		var rates: Array = afk.get("rates_by_chapter", [])
		var ch1: Dictionary = rates[0] if rates.size() > 0 else {}
		var gold_h := int(ch1.get("gold_per_hour", afk.get("gold_per_hour", 1800)))
		var xp_h := int(ch1.get("hero_xp_per_hour", afk.get("hero_xp_per_hour", 700)))
		var ess_h := int(ch1.get("essence_per_hour", 30))
		var sec := mini(DemoData.afk_seconds_accumulated, cap_h * 3600)
		h = sec / 3600
		m = (sec % 3600) / 60
		var hours := float(sec) / 3600.0
		gold_amt = int(floor(gold_h * hours))
		xp_amt = int(floor(xp_h * hours))
		ess_amt = int(floor(ess_h * hours))
		can_claim = sec > 0
		root.add_child(UIFactory.label("Накоплено: %dч %dм / кап %dч" % [h, m, cap_h], 28, LunexColors.GOLD))
		root.add_child(UIFactory.muted("Ставка гл.1: %d зол/ч · %d XP/ч · %d эсс/ч" % [gold_h, xp_h, ess_h], 20))

	root.add_child(UIFactory.muted("Без алмазов и SSR/UR из AFK (канон)", 18))
	var chest := Panel.new()
	chest.custom_minimum_size = Vector2(0, 180)
	chest.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("3A2A10"), LunexColors.GOLD_BRIGHT, 20, 3))
	root.add_child(chest)
	root.add_child(UIFactory.label("К сбору: золото %d · XP %d · эссенция %d" % [gold_amt, xp_amt, ess_amt], 22))

	var collect := UIFactory.gold_button("Собрать")
	collect.pressed.connect(func(): _collect(can_claim, gold_amt, xp_amt, ess_amt))
	root.add_child(collect)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _collect(can_claim: bool, gold_amt: int, xp_amt: int, ess_amt: int) -> void:
	if _busy:
		return
	_busy = true
	if ApiClient.online:
		var res := await ApiClient.afk_claim()
		if res.get("ok", false):
			var data: Dictionary = res.get("data", {})
			var rewards: Dictionary = data.get("rewards", {})
			var lines: Array = []
			for k in rewards.keys():
				lines.append("%s ×%s" % [str(k), str(rewards[k])])
			if lines.is_empty():
				lines.append("Пусто / ниже минимума")
			await ApiClient.sync_wallet()
			_online_status = data.get("status", {})
			ModalManager.push_rewards("AFK-награды (ONLINE)", lines)
			_rebuild()
			_busy = false
			return
		NotificationManager.warn("AFK online недоступен · демо")
	if not can_claim:
		NotificationManager.info("Пока нечего собирать")
		_busy = false
		return
	AppState.add_demo_rewards(gold_amt, 0)
	DemoData.afk_seconds_accumulated = 0
	ModalManager.push_rewards("AFK-награды (DEMO)", [
		"Золото ×%d" % gold_amt,
		"Опыт героя ×%d" % xp_amt,
		"Эссенция ×%d" % ess_amt,
	])
	_rebuild()
	_busy = false
