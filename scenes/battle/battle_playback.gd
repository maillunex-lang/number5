extends Control
## COMBAT-02: локальная демо-симуляция автобоя 5v5 (не серверная система)

var _payload: Dictionary = {}
var _allies: Array[Dictionary] = []
var _enemies: Array[Dictionary] = []
var _units_ui: Dictionary = {} # id -> {root, hp_bar, energy_bar, label}
var _speed: float = 1.0
var _paused: bool = false
var _finished: bool = false
var _tick_accum: float = 0.0
var _time_s: float = 0.0
var _fx_count: int = 0

@onready var _field: Control = $Field
@onready var _hud_top: Label = $HUD/Top
@onready var _portraits: HBoxContainer = $HUD/Portraits
@onready var _speed_btn: Button = $HUD/Controls/SpeedBtn
@onready var _pause_btn: Button = $HUD/Controls/PauseBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var stage_id: String = str(_payload.get("stage_id", UIStateManager.last_combat_context.get("stage_id", "s1_3")))
	_allies = []
	for u in DemoData.ally_battle_units():
		var d := u.duplicate(true)
		d["side"] = "ally"
		d["max_hp"] = float(d.hp)
		d["hp"] = float(d.hp)
		d["energy"] = 0.0
		d["alive"] = true
		_allies.append(d)
	_enemies = []
	for u in DemoData.enemy_squad_for_stage(stage_id):
		var d := u.duplicate(true)
		d["side"] = "enemy"
		d["max_hp"] = float(d.hp)
		d["hp"] = float(d.hp)
		d["energy"] = 0.0
		d["alive"] = true
		d["skills"] = ["strike", "skill"]
		_enemies.append(d)
	_spawn_units()
	_build_portraits()
	_speed_btn.pressed.connect(_cycle_speed)
	_pause_btn.pressed.connect(func():
		_paused = not _paused
		_pause_btn.text = "▶" if _paused else "⏸"
	)
	$HUD/Controls/ExitBtn.pressed.connect(func():
		ModalManager.push_confirm("Выйти из боя?", "Демо-бой будет прерван.", func():
			_finished = true
			ScreenRouter.go("COMBAT-03", {"victory": false, "aborted": true})
		)
	)
	_hud_top.text = "Демо-бой · %s · x%.0f" % [stage_id, _speed]

func _spawn_units() -> void:
	for c in _field.get_children():
		c.queue_free()
	_units_ui.clear()
	var ally_y := [200.0, 380.0, 560.0, 740.0, 920.0]
	for i in _allies.size():
		_create_unit_visual(_allies[i], Vector2(180, ally_y[i] if i < ally_y.size() else 200 + i * 160))
	var enemy_y := ally_y
	for i in _enemies.size():
		_create_unit_visual(_enemies[i], Vector2(780, enemy_y[i] if i < enemy_y.size() else 200 + i * 160))

func _create_unit_visual(unit: Dictionary, pos: Vector2) -> void:
	var root := Control.new()
	root.position = pos
	root.custom_minimum_size = Vector2(140, 160)
	var body := UIFactory.hero_portrait(unit.tint if unit.has("tint") else Color("888888"), Vector2(120, 140))
	root.add_child(body)
	var name_l := UIFactory.label(str(unit.name), 16)
	name_l.position = Vector2(0, 130)
	root.add_child(name_l)
	var hp := ProgressBar.new()
	hp.max_value = unit.max_hp
	hp.value = unit.hp
	hp.size = Vector2(120, 12)
	hp.position = Vector2(0, -8)
	hp.show_percentage = false
	root.add_child(hp)
	var en := ProgressBar.new()
	en.max_value = 100
	en.value = 0
	en.size = Vector2(120, 8)
	en.position = Vector2(0, 6)
	en.show_percentage = false
	en.modulate = LunexColors.ENERGY
	root.add_child(en)
	_field.add_child(root)
	_units_ui[unit.id] = {"root": root, "hp": hp, "energy": en, "body": body}

func _build_portraits() -> void:
	for c in _portraits.get_children():
		c.queue_free()
	for u in _allies:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(160, 90)
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label(str(u.name), 18))
		var hp := ProgressBar.new()
		hp.name = "HP"
		hp.max_value = u.max_hp
		hp.value = u.hp
		hp.custom_minimum_size = Vector2(140, 10)
		hp.show_percentage = false
		v.add_child(hp)
		var en := ProgressBar.new()
		en.name = "EN"
		en.max_value = 100
		en.custom_minimum_size = Vector2(140, 8)
		en.show_percentage = false
		v.add_child(en)
		_portraits.add_child(p)
		_units_ui[u.id]["portrait_hp"] = hp
		_units_ui[u.id]["portrait_en"] = en

func _cycle_speed() -> void:
	if _speed < 1.5:
		_speed = 2.0
	elif _speed < 2.5:
		_speed = 3.0
	else:
		_speed = 1.0
	_speed_btn.text = "x%.0f" % _speed
	_hud_top.text = "Демо-бой · x%.0f" % _speed

func _process(delta: float) -> void:
	if _finished or _paused:
		return
	_time_s += delta * _speed
	_tick_accum += delta * _speed
	if _tick_accum < 0.35:
		return
	_tick_accum = 0.0
	_sim_tick()
	_refresh_ui()
	_check_end()

func _sim_tick() -> void:
	var attackers: Array[Dictionary] = []
	for u in _allies:
		if u.alive:
			attackers.append(u)
	for u in _enemies:
		if u.alive:
			attackers.append(u)
	attackers.shuffle()
	for u in attackers:
		if not u.alive:
			continue
		u.energy = minf(100.0, float(u.energy) + 18.0 + randf() * 10.0)
		var targets := _enemies if u.side == "ally" else _allies
		var living: Array[Dictionary] = []
		for t in targets:
			if t.alive:
				living.append(t)
		if living.is_empty():
			continue
		var target: Dictionary = living[randi() % living.size()]
		var dmg := float(u.atk) * (0.85 + randf() * 0.3)
		var is_skill := float(u.energy) >= 100.0
		if is_skill:
			dmg *= 1.85
			u.energy = 0.0
			_spawn_fx(target.id, true)
			# hide portraits briefly on ult (BATTLE-UI-002)
			if ThemeManager.preset != "low":
				_portraits.modulate.a = 0.15
				var tw := create_tween()
				tw.tween_interval(0.45 / _speed)
				tw.tween_property(_portraits, "modulate:a", 1.0, 0.2)
		else:
			_spawn_fx(target.id, false)
		target.hp = maxf(0.0, float(target.hp) - dmg)
		if target.hp <= 0.0:
			target.alive = false
			if _units_ui.has(target.id):
				_units_ui[target.id].root.modulate = Color(0.3, 0.3, 0.3, 0.5)
		AudioManager.play_battle_hit()

func _spawn_fx(unit_id: String, big: bool) -> void:
	if not _units_ui.has(unit_id):
		return
	if _fx_count >= ThemeManager.max_active_fx:
		return
	_fx_count += 1
	var root: Control = _units_ui[unit_id].root
	var flash := ColorRect.new()
	flash.size = Vector2(120, 140) if big else Vector2(80, 80)
	flash.position = Vector2(0, 0) if big else Vector2(20, 30)
	flash.color = Color(1, 0.9, 0.4, 0.55) if big else Color(1, 0.4, 0.3, 0.4)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.25 / _speed)
	tw.tween_callback(func():
		flash.queue_free()
		_fx_count = maxi(0, _fx_count - 1)
	)
	if big and ThemeManager.preset in ["high", "ultra"]:
		var shake := create_tween()
		shake.tween_property(_field, "position:x", 6, 0.04)
		shake.tween_property(_field, "position:x", -6, 0.04)
		shake.tween_property(_field, "position:x", 0, 0.04)

func _refresh_ui() -> void:
	for u in _allies + _enemies:
		if not _units_ui.has(u.id):
			continue
		var ui: Dictionary = _units_ui[u.id]
		ui.hp.value = u.hp
		ui.energy.value = u.energy
		if ui.has("portrait_hp"):
			ui.portrait_hp.value = u.hp
			ui.portrait_en.value = u.energy

func _check_end() -> void:
	var allies_alive := false
	var enemies_alive := false
	for u in _allies:
		if u.alive:
			allies_alive = true
	for u in _enemies:
		if u.alive:
			enemies_alive = true
	if allies_alive and enemies_alive:
		if _time_s > 90.0:
			# timeout — higher power wins
			var ap := DemoData.squad_power()
			var stage := DemoData.get_stage(str(_payload.get("stage_id", "")))
			_finish(ap >= int(stage.get("power", 0)))
		return
	_finish(allies_alive)

func _finish(victory: bool) -> void:
	if _finished:
		return
	_finished = true
	await get_tree().create_timer(0.6 / _speed).timeout
	ScreenRouter.go("COMBAT-03", {
		"victory": victory,
		"stage_id": _payload.get("stage_id", ""),
		"mode": _payload.get("mode", "campaign"),
	})
