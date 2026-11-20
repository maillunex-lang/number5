extends Control
## HUB-01: интерфейс призыва (локальная демо-симуляция)

var _payload: Dictionary = {}
var _busy: bool = false

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _summon_cfg() -> Dictionary:
	return ContentPackageLoader.features.get("summon", {})

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var cfg := _summon_cfg()
	var banner := str(cfg.get("banner", "Баннер"))
	var w: Dictionary = cfg.get("weights", {"common": 70, "rare": 22, "epic": 7, "legendary": 1})
	root.add_child(UIFactory.section_header("Алтарь призыва"))
	root.add_child(UIFactory.label("Баннер: %s" % banner, 26, LunexColors.GOLD))
	root.add_child(UIFactory.muted("%s · локальная демо-симуляция" % ContentPackageLoader.package_label(), 20))
	var art := Panel.new()
	art.custom_minimum_size = Vector2(0, 220)
	art.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("1A2840"), LunexColors.CYAN, 18, 2))
	root.add_child(art)
	var row := UIFactory.hbox(12)
	root.add_child(row)
	var info := UIFactory.fantasy_button("Шансы и правила")
	info.pressed.connect(func():
		ModalManager.push_info(
			"Правила призыва",
			"Обычный %s%%\nРедкий %s%%\nЭпический %s%%\nЛегендарный %s%%\n\nГарантии и история — на сервере (здесь демо)." % [
				str(w.get("common", 70)), str(w.get("rare", 22)), str(w.get("epic", 7)), str(w.get("legendary", 1))
			]
		)
	)
	row.add_child(info)
	var x1 := UIFactory.gold_button("Призыв ×1")
	x1.pressed.connect(func(): _do_summon(1))
	row.add_child(x1)
	var x10 := UIFactory.gold_button("Призыв ×10")
	x10.pressed.connect(func(): _do_summon(10))
	root.add_child(x10)
	var to_heroes := UIFactory.fantasy_button("В коллекцию")
	to_heroes.pressed.connect(func():
		while ScreenRouter._shell and ScreenRouter._shell.has_overlay():
			await ScreenRouter._shell.close_overlay()
		ScreenRouter.switch_tab("heroes")
	)
	root.add_child(to_heroes)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _do_summon(count: int) -> void:
	if _busy:
		return
	_busy = true
	var cfg := _summon_cfg()
	var cost := int(cfg.get("cost_x1", 300)) * count
	if not AppState.spend_demo_gold(cost):
		NotificationManager.warn("Недостаточно золота (демо)")
		_busy = false
		return
	NotificationManager.info("Призыв…")
	await get_tree().create_timer(0.45).timeout
	var results: Array = []
	var rarities := ["common", "rare", "epic", "legendary"]
	var w: Dictionary = cfg.get("weights", {})
	var weights := [int(w.get("common", 70)), int(w.get("rare", 22)), int(w.get("epic", 7)), int(w.get("legendary", 1))]
	for i in count:
		var roll := randi() % 100
		var acc := 0
		var r := "common"
		for j in rarities.size():
			acc += weights[j]
			if roll < acc:
				r = rarities[j]
				break
		var pool := DemoData.get_filtered_heroes("", r if r != "common" else "", "", "", "name")
		var hero_name := "Новичок"
		if pool.size() > 0:
			hero_name = str(pool[randi() % pool.size()]["name"])
		elif DemoData.heroes.size() > 0:
			hero_name = str(DemoData.heroes[randi() % DemoData.heroes.size()]["name"])
		results.append("%s (%s)" % [hero_name, r])
	ModalManager.push_rewards("Результаты призыва ×%d" % count, results)
	_busy = false
