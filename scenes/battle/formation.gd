extends Control
## COMBAT-01: единая тактическая подготовка. Chrome в .tscn; слоты — FormationSlot.

var _payload: Dictionary = {}
@onready var _mode: Label = $Safe/Scroll/VBox/ModeLabel
@onready var _stage_lbl: Label = $Safe/Scroll/VBox/StageLabel
@onready var _power: Label = $Safe/Scroll/VBox/PowerLabel
@onready var _compare: Label = $Safe/Scroll/VBox/CompareLabel
@onready var _presets: HBoxContainer = $Safe/Scroll/VBox/PresetsHost
@onready var _start: Button = $Safe/Scroll/VBox/StartBtn
@onready var _slots_row: HBoxContainer = $Safe/Scroll/VBox/SlotsRow
var _slots: Array[FormationSlot] = []

func setup(payload: Dictionary = {}) -> void:
	_payload = payload
	if not payload.is_empty():
		UIStateManager.set_combat_context(payload)

func _ready() -> void:
	_slots.clear()
	for c in _slots_row.get_children():
		if c is FormationSlot:
			_slots.append(c)
	$Safe/Scroll/VBox/EditBtn.pressed.connect(func(): ScreenRouter.go("HERO-02"))
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_start.pressed.connect(_on_start)
	_rebuild()
	DemoData.squad_changed.connect(_rebuild)

func _rebuild() -> void:
	var ctx := UIStateManager.last_combat_context
	var stage_id: String = str(_payload.get("stage_id", ctx.get("stage_id", DemoData.campaign_progress["current_stage"])))
	var mode: String = str(_payload.get("mode", ctx.get("mode", "campaign")))
	var stage := DemoData.get_stage(stage_id)
	_mode.text = "Режим: %s" % mode
	if stage.is_empty():
		_stage_lbl.text = "Этап: %s" % stage_id
	else:
		_stage_lbl.text = "Этап: %s · рек. сила %d" % [stage.name, int(stage.power)]
	var sp := DemoData.squad_power()
	var ep := int(stage.get("power", 10000))
	_power.text = "Сила отряда: %d" % sp
	_compare.text = "Сравнение: %d vs %d" % [sp, ep]
	_compare.add_theme_color_override("font_color", LunexColors.EMERALD if sp >= ep else LunexColors.AMBER)
	for i in 5:
		var hid: String = DemoData.squad_slots[i] if i < DemoData.squad_slots.size() else ""
		var h := DemoData.get_hero(hid)
		if h.is_empty():
			_slots[i].clear_slot()
		else:
			_slots[i].set_hero(h)
	for c in _presets.get_children():
		c.queue_free()
	for p in DemoData.squad_presets:
		var b := UIFactory.fantasy_button(str(p.name), 48)
		var pid: String = p.id
		b.pressed.connect(func(): DemoData.apply_preset(pid))
		_presets.add_child(b)
	_start.disabled = false
	_start.text = "Начать бой"

func _on_start() -> void:
	if _start.disabled:
		return
	var ctx := UIStateManager.last_combat_context
	var stage_id: String = str(_payload.get("stage_id", ctx.get("stage_id", DemoData.campaign_progress["current_stage"])))
	var mode: String = str(_payload.get("mode", ctx.get("mode", "campaign")))
	if not ApiClient.online or not DemoData.server_player_loaded:
		NotificationManager.warn("Нет подключения к игровому серверу")
		return
	_start.disabled = true
	_start.text = "Сервер рассчитывает бой..."
	var response: Dictionary = await ApiClient.battle_start(stage_id)
	if not is_instance_valid(_start):
		return
	if not response.get("ok", false):
		_start.disabled = false
		_start.text = "Начать бой"
		NotificationManager.warn("Сервер не начал бой. Проверь доступность этапа и отряд.")
		return
	var data: Dictionary = response.get("data", {})
	var battle_id := str(data.get("battle_id", ""))
	if battle_id == "":
		_start.disabled = false
		_start.text = "Начать бой"
		NotificationManager.warn("Сервер не вернул идентификатор боя")
		return
	var timeline: Array = data.get("timeline", [])
	UIStateManager.set_combat_context({
		"mode": mode,
		"stage_id": stage_id,
		"return_route": ctx.get("return_route", "ROOT-04"),
		"battle_id": battle_id,
	})
	ScreenRouter.go("COMBAT-02", {
		"stage_id": stage_id,
		"mode": mode,
		"battle_id": battle_id,
		"server_victory": bool(data.get("victory", false)),
		"timeline": timeline,
		"seed": data.get("seed", 0),
		"config_version": str(data.get("config_version", "")),
	})
