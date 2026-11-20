extends Control
## COMBAT-02: воспроизведение серверной timeline (H6). Локальный DEMO — только без battle_id.

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
var _timeline: Array = []
var _event_i: int = 0
var _server_mode: bool = false
var _server_victory: bool = false
var _bootstrapping: bool = true

@onready var _field: Control = $Field
@onready var _hud_top: Label = $HUD/Top
@onready var _portraits: HBoxContainer = $HUD/Portraits
@onready var _speed_btn: Button = $HUD/Controls/SpeedBtn
@onready var _pause_btn: Button = $HUD/Controls/PauseBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_speed_btn.pressed.connect(_cycle_speed)
	_pause_btn.pressed.connect(func():
		_paused = not _paused
		_pause_btn.text = "▶" if _paused else "⏸"
	)
	$HUD/Controls/ExitBtn.pressed.connect(func():
		ModalManager.push_confirm("Выйти из боя?", "Награды не будут получены.", func():
			_finished = true
			ScreenRouter.go("COMBAT-03", {"victory": false, "aborted": true})
		)
	)
	await _bootstrap()

func _bootstrap() -> void:
	var stage_id: String = str(_payload.get("stage_id", UIStateManager.last_combat_context.get("stage_id", "s1_3")))
	var battle_id: String = str(_payload.get("battle_id", UIStateManager.last_combat_context.get("battle_id", "")))
	_timeline = _payload.get("timeline", []) as Array
	_server_victory = bool(_payload.get("server_victory", false))

	if battle_id != "" and ApiClient.online:
		_server_mode = true
		if _timeline.is_empty():
			_hud_top.text = "Восстановление боя…"
			var fetched: Dictionary = await ApiClient.battle_get(battle_id)
			if not fetched.get("ok", false):
				NotificationManager.warn("Не удалось восстановить бой с сервера")
				_finished = true
				ScreenRouter.go("COMBAT-03", {"victory": false, "aborted": true, "battle_id": battle_id, "stage_id": stage_id})
				return
			var data: Dictionary = fetched.get("data", {}) as Dictionary
			_timeline = data.get("timeline", []) as Array
			_server_victory = bool(data.get("victory", false))
			_payload["server_victory"] = _server_victory
			_payload["battle_id"] = battle_id
			_payload["stage_id"] = str(data.get("stage_id", stage_id))
			stage_id = str(_payload["stage_id"])
		if not _apply_server_start(stage_id):
			NotificationManager.warn("Серверная timeline повреждена")
			_finished = true
			ScreenRouter.go("COMBAT-03", {
				"victory": _server_victory,
				"battle_id": battle_id,
				"stage_id": stage_id,
				"mode": _payload.get("mode", "campaign"),
			})
			return
		_hud_top.text = "Бой · %s · сервер · x%.0f" % [stage_id, _speed]
	else:
		_server_mode = false
		_boot_demo_units(stage_id)
		_hud_top.text = "Бой · %s · DEMO · x%.0f" % [stage_id, _speed]

	_spawn_units()
	_build_portraits()
	_bootstrapping = false

func _apply_server_start(stage_id: String) -> bool:
	if _timeline.is_empty():
		return false
	var start_ev: Dictionary = {}
	for ev in _timeline:
		if str(ev.get("type", "")) == "start":
			start_ev = ev
			break
	if start_ev.is_empty():
		return false
	_allies = []
	for u in start_ev.get("allies", []):
		_allies.append(_unit_from_snapshot(u, "ally"))
	_enemies = []
	for u in start_ev.get("enemies", []):
		_enemies.append(_unit_from_snapshot(u, "enemy"))
	if _allies.is_empty() or _enemies.is_empty():
		return false
	# Skip start event; playback continues from next.
	_event_i = 1
	for i in range(_timeline.size()):
		if str(_timeline[i].get("type", "")) == "start":
			_event_i = i + 1
			break
	var end_raw: Variant = _timeline[_timeline.size() - 1]
	var end_ev: Dictionary = end_raw if typeof(end_raw) == TYPE_DICTIONARY else {}
	if str(end_ev.get("type", "")) == "end":
		_server_victory = bool(end_ev.get("victory", _server_victory))
	return true

func _unit_from_snapshot(raw: Variant, side: String) -> Dictionary:
	var u: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	var max_hp: float = float(u.get("max_hp", u.get("hp", 1000)))
	return {
		"id": str(u.get("id", "")),
		"name": str(u.get("name", u.get("id", "?"))),
		"side": side,
		"enemy_id": str(u.get("enemy_id", "")),
		"max_hp": max_hp,
		"hp": max_hp,
		"atk": float(u.get("atk", 100)),
		"energy": 0.0,
		"alive": true,
		"tint": _parse_tint(u.get("tint", "#888888")),
	}

func _parse_tint(v: Variant) -> Color:
	if typeof(v) == TYPE_COLOR:
		return v
	var s: String = str(v)
	if s.begins_with("#"):
		return Color(s)
	return Color("888888")

func _boot_demo_units(stage_id: String) -> void:
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

const BATTLE_UNIT_SCENE := "res://scenes/ui/components/battle_unit.tscn"

func _create_unit_visual(unit: Dictionary, pos: Vector2) -> void:
	var root: BattleUnit = (load(BATTLE_UNIT_SCENE) as PackedScene).instantiate()
	root.position = pos
	root.set_unit(unit)
	_field.add_child(root)
	_units_ui[unit.id] = {
		"root": root,
		"hp": root.hp_bar(),
		"energy": root.energy_bar(),
		"body": root.body_node(),
		"unit_view": root,
	}

func _build_portraits() -> void:
	for c in _portraits.get_children():
		c.queue_free()
	for u in _allies:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(160, 110)
		p.theme_type_variation = &"GamePanel"
		var v := UIFactory.vbox(4)
		p.add_child(v)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		v.add_child(row)
		var face := TextureRect.new()
		face.custom_minimum_size = Vector2(48, 48)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var tex: Texture2D = AssetLoader.hero_portrait(str(u.id))
		if tex != null:
			face.texture = tex
		else:
			face.modulate = u.get("tint", Color.GRAY)
		row.add_child(face)
		row.add_child(UIFactory.label(str(u.name), 18))
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
	var mode := "сервер" if _server_mode else "DEMO"
	_hud_top.text = "Бой · %s · x%.0f" % [mode, _speed]

func _process(delta: float) -> void:
	if _bootstrapping or _finished or _paused:
		return
	_time_s += delta * _speed
	if _server_mode:
		_playback_tick()
	else:
		_tick_accum += delta * _speed
		if _tick_accum < 0.35:
			return
		_tick_accum = 0.0
		_sim_tick_demo()
		_refresh_ui()
		_check_end_demo()

func _playback_tick() -> void:
	while _event_i < _timeline.size():
		var ev_raw: Variant = _timeline[_event_i]
		var ev: Dictionary = ev_raw if typeof(ev_raw) == TYPE_DICTIONARY else {}
		var t: float = float(ev.get("t", 0))
		if t > _time_s:
			break
		_apply_event(ev)
		_event_i += 1
	_refresh_ui()

func _apply_event(ev: Dictionary) -> void:
	var typ: String = str(ev.get("type", ""))
	match typ:
		"hit":
			var target_id: String = str(ev.get("target", ""))
			var actor_id: String = str(ev.get("actor", ""))
			var dmg: float = float(ev.get("damage", 0))
			var is_skill: bool = bool(ev.get("skill", false))
			_play_unit_clip(actor_id, "attack")
			_play_unit_clip(target_id, "hit")
			var unit: Dictionary = _find_unit(target_id)
			if not unit.is_empty():
				if ev.has("hp"):
					unit.hp = float(ev.get("hp"))
				else:
					unit.hp = maxf(0.0, float(unit.hp) - dmg)
				if unit.hp <= 0.0:
					unit.alive = false
					if _units_ui.has(target_id):
						var view: Variant = (_units_ui[target_id] as Dictionary).get("unit_view")
						if view is BattleUnit:
							(view as BattleUnit).set_dead(true)
						else:
							(_units_ui[target_id] as Dictionary).root.modulate = Color(0.3, 0.3, 0.3, 0.5)
			var actor: Dictionary = _find_unit(actor_id)
			if not actor.is_empty() and ev.has("energy"):
				actor.energy = float(ev.get("energy"))
			elif not actor.is_empty() and is_skill:
				actor.energy = 0.0
			_spawn_fx(target_id, is_skill)
			if is_skill and ThemeManager.preset != "low":
				_portraits.modulate.a = 0.15
				var tw := create_tween()
				tw.tween_interval(0.45 / _speed)
				tw.tween_property(_portraits, "modulate:a", 1.0, 0.2)
			AudioManager.play_battle_hit()
		"death":
			var uid: String = str(ev.get("unit", ""))
			var unit2: Dictionary = _find_unit(uid)
			if not unit2.is_empty():
				unit2.hp = 0.0
				unit2.alive = false
				if _units_ui.has(uid):
					var view2: Variant = (_units_ui[uid] as Dictionary).get("unit_view")
					if view2 is BattleUnit:
						(view2 as BattleUnit).set_dead(true)
					else:
						(_units_ui[uid] as Dictionary).root.modulate = Color(0.3, 0.3, 0.3, 0.5)
		"end":
			_server_victory = bool(ev.get("victory", _server_victory))
			_finish(_server_victory)
		_:
			pass

func _find_unit(uid: String) -> Dictionary:
	for u in _allies:
		if str(u.id) == uid:
			return u
	for u in _enemies:
		if str(u.id) == uid:
			return u
	return {}

func _play_unit_clip(uid: String, clip: String) -> void:
	if uid == "" or not _units_ui.has(uid):
		return
	var view: Variant = (_units_ui[uid] as Dictionary).get("unit_view")
	if view is BattleUnit:
		(view as BattleUnit).play_clip(clip)

func _sim_tick_demo() -> void:
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
				var dv = _units_ui[target.id].get("unit_view")
				if dv is BattleUnit:
					(dv as BattleUnit).set_dead(true)
				else:
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

func _check_end_demo() -> void:
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
			var ap: int = DemoData.squad_power()
			var stage: Dictionary = DemoData.get_stage(str(_payload.get("stage_id", "")))
			_finish(ap >= int(stage.get("power", 0)))
		return
	_finish(allies_alive)

func _finish(victory: bool) -> void:
	if _finished:
		return
	_finished = true
	var final_victory: bool = victory
	if _server_mode:
		final_victory = _server_victory
	await get_tree().create_timer(0.6 / _speed).timeout
	ScreenRouter.go("COMBAT-03", {
		"victory": final_victory,
		"battle_id": str(_payload.get("battle_id", "")),
		"stage_id": _payload.get("stage_id", ""),
		"mode": _payload.get("mode", "campaign"),
	})
