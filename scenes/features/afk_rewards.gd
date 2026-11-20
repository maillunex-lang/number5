extends Control
## HUB-02: chrome в .tscn; статус/claim API без изменений.

var _payload: Dictionary = {}
var _busy: bool = false
var _online_status: Dictionary = {}
var _nav_bound: bool = false
var _can_claim: bool = false
var _gold_amt: int = 0
var _xp_amt: int = 0
var _ess_amt: int = 0

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _subtitle: Label = $Safe/Scroll/VBox/Subtitle
@onready var _accum: Label = $Safe/Scroll/VBox/AccumLabel
@onready var _rates: Label = $Safe/Scroll/VBox/RatesLabel
@onready var _chest: Panel = $Safe/Scroll/VBox/Chest
@onready var _summary: Label = $Safe/Scroll/VBox/SummaryLabel
@onready var _collect: Button = $Safe/Scroll/VBox/CollectBtn
@onready var _back: Button = $Safe/Scroll/VBox/BackBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_bind_nav()
	_style_chest()
	if ApiClient.online:
		var res := await ApiClient.afk_status()
		if res.get("ok", false):
			_online_status = res.get("data", {})
	_rebuild()

func _bind_nav() -> void:
	if _nav_bound:
		return
	_nav_bound = true
	_collect.pressed.connect(_on_collect)
	_back.pressed.connect(func(): ScreenRouter.handle_back())

func _style_chest() -> void:
	if _chest:
		_chest.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("3A2A10"), LunexColors.GOLD_BRIGHT, 20, 3))

func _afk_cfg() -> Dictionary:
	var live: Dictionary = ContentPackageLoader.liveops.get("afk", {})
	if not live.is_empty():
		return live
	return ContentPackageLoader.features.get("afk", {})

func _rebuild() -> void:
	var afk := _afk_cfg()
	var unlock := str(afk.get("unlock_stage", "CH01-03"))
	var mode := "ONLINE · CORE-01" if ApiClient.online and not _online_status.is_empty() else "DEMO"
	_title.text = ContentPackageLoader.tr_key("afk.title", "AFK-сокровищница")
	_subtitle.text = "%s · %s · открытие после %s" % [ContentPackageLoader.package_label(), mode, unlock]

	_gold_amt = 0
	_xp_amt = 0
	_ess_amt = 0
	var h := 0
	var m := 0
	var cap_h := int(afk.get("cap_hours", 12))
	_can_claim = false
	_rates.visible = false
	_rates.text = ""

	if ApiClient.online and not _online_status.is_empty():
		var sec := int(_online_status.get("accumulated_sec", 0))
		var cap := int(_online_status.get("cap_sec", cap_h * 3600))
		h = sec / 3600
		m = (sec % 3600) / 60
		cap_h = maxi(1, cap / 3600)
		var preview: Dictionary = _online_status.get("preview", {})
		_gold_amt = int(preview.get("gold", 0))
		_xp_amt = int(preview.get("hero_xp", 0))
		_ess_amt = int(preview.get("essence", 0))
		_can_claim = bool(_online_status.get("can_claim", false))
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
		_gold_amt = int(floor(gold_h * hours))
		_xp_amt = int(floor(xp_h * hours))
		_ess_amt = int(floor(ess_h * hours))
		_can_claim = sec > 0
		_rates.visible = true
		_rates.text = "Ставка гл.1: %d зол/ч · %d XP/ч · %d эсс/ч" % [gold_h, xp_h, ess_h]

	_accum.text = "Накоплено: %dч %dм / кап %dч" % [h, m, cap_h]
	_summary.text = "К сбору: золото %d · XP %d · эссенция %d" % [_gold_amt, _xp_amt, _ess_amt]

func _on_collect() -> void:
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
	if not _can_claim:
		NotificationManager.info("Пока нечего собирать")
		_busy = false
		return
	AppState.add_demo_rewards(_gold_amt, 0)
	DemoData.afk_seconds_accumulated = 0
	ModalManager.push_rewards("AFK-награды (DEMO)", [
		"Золото ×%d" % _gold_amt,
		"Опыт героя ×%d" % _xp_amt,
		"Эссенция ×%d" % _ess_amt,
	])
	_rebuild()
	_busy = false
