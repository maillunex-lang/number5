extends Control
## COMBAT-03: chrome в .tscn (Title/ClaimProgress/Status/Meta/Nav); claim — здесь.

@export_category("Lunex Battle Result")
@export var bg_color: Color = Color(0.03, 0.04, 0.08, 1):
	set(v):
		bg_color = v
		if _bg:
			_bg.color = v

var _payload: Dictionary = {}
var _busy: bool = false
var _nav_bound: bool = false
var _claim_tween: Tween = null

@onready var _bg: ColorRect = $BG
@onready var _title: Label = $Safe/VBox/Title
@onready var _subtitle: Label = $Safe/VBox/Subtitle
@onready var _claim_bar: ProgressBar = $Safe/VBox/ClaimProgress
@onready var _status: Label = $Safe/VBox/StatusLabel
@onready var _meta: Label = $Safe/VBox/MetaLabel
@onready var _again: Button = $Safe/VBox/Nav/AgainBtn
@onready var _map_btn: Button = $Safe/VBox/Nav/MapBtn
@onready var _hub: Button = $Safe/VBox/Nav/HubBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	if _bg:
		_bg.color = bg_color
	_bind_nav()
	await _build()

func _bind_nav() -> void:
	if _nav_bound:
		return
	_nav_bound = true
	_again.pressed.connect(func():
		ScreenRouter.go("COMBAT-01", {
			"stage_id": _payload.get("stage_id", ""),
			"mode": _payload.get("mode", "campaign"),
		})
	)
	_map_btn.pressed.connect(func():
		ScreenRouter.go("MAP-01")
	)
	_hub.pressed.connect(func():
		ScreenRouter.switch_tab("hub")
	)

func _set_status(text: String, color: Color = LunexColors.TEXT_PRIMARY) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)

func _show_claim_busy(on: bool) -> void:
	_claim_bar.visible = on
	if _claim_tween != null and is_instance_valid(_claim_tween):
		_claim_tween.kill()
		_claim_tween = null
	if on:
		_claim_bar.value = 0.35
		_claim_tween = create_tween().set_loops()
		_claim_tween.tween_property(_claim_bar, "value", 0.9, 1.2)
		_claim_tween.tween_property(_claim_bar, "value", 0.35, 1.2)

func _build() -> void:
	var victory: bool = bool(_payload.get("victory", false))
	var aborted: bool = bool(_payload.get("aborted", false))
	var sid: String = str(_payload.get("stage_id", ""))
	_again.visible = true
	_map_btn.visible = true
	_hub.visible = true
	_meta.text = ""
	_show_claim_busy(false)

	if aborted:
		_title.text = "Бой прерван"
		_subtitle.text = "Награды не выданы."
		_subtitle.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		_set_status("")
		return

	if not victory:
		_title.text = "Поражение"
		_subtitle.text = "Усильте отряд и попробуйте снова."
		_subtitle.add_theme_color_override("font_color", LunexColors.TEXT_DANGER)
		_set_status("Серверный claim только при победе.", LunexColors.TEXT_MUTED)
		return

	_title.text = "Победа!"
	_subtitle.text = ""
	var bid := str(_payload.get("battle_id", ""))
	if ApiClient.online and bid != "":
		_subtitle.text = "Подтверждение наград на сервере…"
		_subtitle.add_theme_color_override("font_color", LunexColors.EMERALD)
		_set_status("")
		_show_claim_busy(true)
		var ok := await _claim_online(bid, sid)
		_show_claim_busy(false)
		if ok:
			return
		_subtitle.text = ""
		_set_status("Не удалось подтвердить результат на сервере. Награды не выданы.", LunexColors.TEXT_MUTED)
	else:
		_set_status("Нет онлайн-сессии. Награды не выданы.", LunexColors.TEXT_MUTED)

func _claim_online(bid: String, sid: String) -> bool:
	if _busy:
		return false
	_busy = true
	var claim := await ApiClient.battle_claim(bid)
	if not claim.get("ok", false):
		_busy = false
		return false
	var cdata: Dictionary = claim.get("data", {})
	var crewards: Dictionary = cdata.get("rewards", {})
	var first_clear := bool(cdata.get("first_clear", crewards.size() > 0))
	var lines: Array = []
	for k in crewards.keys():
		lines.append("%s ×%s" % [str(k), str(crewards[k])])
	if lines.is_empty():
		lines.append("Тренировка — без наград")
	_apply_claim_progress(cdata, sid)
	_subtitle.text = ""
	if first_clear and not crewards.is_empty():
		_set_status("Награды подтверждены сервером.", LunexColors.EMERALD)
		ModalManager.push_rewards("Награды (ONLINE)", lines)
	else:
		_set_status("Повтор: тренировка без наград.", LunexColors.GOLD)
		ModalManager.push_info("Повтор этапа", "Этот бой уже был пройден.\nНаграды за first clear не выдаются повторно.")
	_meta.text = "battle_id %s · CORE-01" % bid
	_busy = false
	_refresh_economy_bg()
	return true

func _apply_claim_progress(cdata: Dictionary, sid: String) -> void:
	var prog: Dictionary = cdata.get("progress", {})
	var next_stage := str(prog.get("current_stage", ""))
	if next_stage != "":
		DemoData.campaign_progress["current_stage"] = next_stage
	for st in DemoData.campaign_progress.get("stages", []):
		var stage_key := str(st.get("id", ""))
		if stage_key == sid:
			st["state"] = "cleared"
		elif next_stage != "" and stage_key == next_stage:
			st["state"] = "current"
		elif str(st.get("state", "")) == "current" and stage_key != next_stage:
			st["state"] = "cleared"

func _refresh_economy_bg() -> void:
	await ApiClient.sync_wallet()
	var campaign := await ApiClient.get_campaign()
	if not campaign.get("ok", false):
		return
	var prog: Dictionary = campaign.get("data", {})
	DemoData.campaign_progress["current_stage"] = str(prog.get("current_stage", DemoData.campaign_progress.get("current_stage", "")))
	var cleared: Dictionary = {}
	for st in prog.get("cleared", []):
		cleared[str(st.get("StageID", st.get("stage_id", "")))] = true
	for st in DemoData.campaign_progress.get("stages", []):
		var stage_key := str(st.get("id", ""))
		st["state"] = "cleared" if cleared.has(stage_key) else ("current" if stage_key == DemoData.campaign_progress["current_stage"] else "locked")
