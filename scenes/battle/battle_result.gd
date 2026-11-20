extends Control
## COMBAT-03: итоги серверного боя. Chrome в .tscn; claim и тексты — здесь.

@export_category("Lunex Battle Result")
@export var bg_color: Color = Color(0.03, 0.04, 0.08, 1):
	set(v):
		bg_color = v
		if _bg:
			_bg.color = v

var _payload: Dictionary = {}
var _busy: bool = false
var _nav_bound: bool = false

@onready var _bg: ColorRect = $BG
@onready var _title: Label = $Safe/VBox/Title
@onready var _subtitle: Label = $Safe/VBox/Subtitle
@onready var _dynamic: VBoxContainer = $Safe/VBox/DynamicHost
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

func _clear_dynamic() -> void:
	for c in _dynamic.get_children():
		c.queue_free()

func _build() -> void:
	var victory: bool = bool(_payload.get("victory", false))
	var aborted: bool = bool(_payload.get("aborted", false))
	var sid: String = str(_payload.get("stage_id", ""))
	_clear_dynamic()
	_again.visible = true
	_map_btn.visible = true
	_hub.visible = true

	if aborted:
		_title.text = "Бой прерван"
		_subtitle.text = "Награды не выданы."
		_subtitle.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		return

	if not victory:
		_title.text = "Поражение"
		_subtitle.text = "Усильте отряд и попробуйте снова."
		_subtitle.add_theme_color_override("font_color", LunexColors.TEXT_DANGER)
		_dynamic.add_child(UIFactory.muted("Серверный claim только при победе.", 20))
		return

	_title.text = "Победа!"
	_subtitle.text = ""
	var bid := str(_payload.get("battle_id", ""))
	if ApiClient.online and bid != "":
		_dynamic.add_child(UIFactory.label("Подтверждение наград на сервере…", 24, LunexColors.EMERALD))
		var ok := await _claim_online(bid, sid)
		if ok:
			return
		_dynamic.add_child(UIFactory.muted("Не удалось подтвердить результат на сервере. Награды не выданы.", 22))
	else:
		_dynamic.add_child(UIFactory.muted("Нет онлайн-сессии. Награды не выданы.", 22))

func _claim_online(bid: String, _sid: String) -> bool:
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
	_clear_dynamic()
	_dynamic.add_child(UIFactory.label("Награды подтверждены сервером.", 26, LunexColors.EMERALD))
	ModalManager.push_rewards("Награды (ONLINE)", lines)
	_dynamic.add_child(UIFactory.muted("battle_id %s · CORE-01" % bid, 18))
	_busy = false
	return true
