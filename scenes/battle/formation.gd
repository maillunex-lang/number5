extends Control
## COMBAT-01: единая тактическая подготовка

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload
	if not payload.is_empty():
		UIStateManager.set_combat_context(payload)

func _ready() -> void:
	_rebuild()
	DemoData.squad_changed.connect(_rebuild)

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var ctx := UIStateManager.last_combat_context
	var stage_id: String = str(_payload.get("stage_id", ctx.get("stage_id", DemoData.campaign_progress["current_stage"])))
	var mode: String = str(_payload.get("mode", ctx.get("mode", "campaign")))
	var stage := DemoData.get_stage(stage_id)
	root.add_child(UIFactory.section_header("Подготовка к бою"))
	root.add_child(UIFactory.label("Режим: %s" % mode, 24, LunexColors.CYAN))
	if not stage.is_empty():
		root.add_child(UIFactory.label("Этап: %s · рек. сила %d" % [stage.name, int(stage.power)], 24))
	var sp := DemoData.squad_power()
	var ep := int(stage.get("power", 10000))
	root.add_child(UIFactory.label("Сила отряда: %d" % sp, 28, LunexColors.GOLD))
	var cmp_color := LunexColors.EMERALD if sp >= ep else LunexColors.AMBER
	root.add_child(UIFactory.label("Сравнение: %d vs %d" % [sp, ep], 24, cmp_color))
	root.add_child(UIFactory.muted("Результат и награды определяются сервером", 20))
	var row := UIFactory.hbox(8)
	root.add_child(row)
	for i in 5:
		var hid: String = DemoData.squad_slots[i]
		var h := DemoData.get_hero(hid)
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(160, 200)
		slot.add_theme_stylebox_override("panel", UIFactory.panel_style())
		var v := UIFactory.vbox(6)
		slot.add_child(v)
		if h.is_empty():
			v.add_child(UIFactory.muted("Пусто", 22))
		else:
			v.add_child(UIFactory.hero_portrait(h.tint, Vector2(120, 140)))
			v.add_child(UIFactory.label(str(h.name), 18))
		row.add_child(slot)
	var presets := UIFactory.hbox(8)
	root.add_child(presets)
	for p in DemoData.squad_presets:
		var b := UIFactory.fantasy_button(str(p.name), 48)
		var pid: String = p.id
		b.pressed.connect(func(): DemoData.apply_preset(pid))
		presets.add_child(b)
	var edit := UIFactory.fantasy_button("Изменить отряд")
	edit.pressed.connect(func(): ScreenRouter.go("HERO-02"))
	root.add_child(edit)
	var start := UIFactory.gold_button("Начать бой")
	start.pressed.connect(func():
		if start.disabled:
			return
		if not ApiClient.online or not DemoData.server_player_loaded:
			NotificationManager.warn("Нет подключения к игровому серверу")
			return
		start.disabled = true
		start.text = "Сервер рассчитывает бой..."
		var response: Dictionary = await ApiClient.battle_start(stage_id)
		if not is_instance_valid(start):
			return
		if not response.get("ok", false):
			start.disabled = false
			start.text = "Начать бой"
			NotificationManager.warn("Сервер не начал бой. Проверь доступность этапа и отряд.")
			return
		var data: Dictionary = response.get("data", {})
		var battle_id := str(data.get("battle_id", ""))
		if battle_id == "":
			start.disabled = false
			start.text = "Начать бой"
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
	)
	root.add_child(start)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
