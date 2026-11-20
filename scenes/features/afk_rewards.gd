extends Control

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var afk: Dictionary = ContentPackageLoader.features.get("afk", {})
	var gold_per_10s := int(afk.get("gold_per_10s", 5))
	var cap_gold := int(afk.get("cap_gold", 5000))
	root.add_child(UIFactory.section_header("AFK-сокровищница"))
	root.add_child(UIFactory.muted(ContentPackageLoader.package_label(), 18))
	var sec := DemoData.afk_seconds_accumulated
	var h := sec / 3600
	var m := (sec % 3600) / 60
	root.add_child(UIFactory.label("Накоплено: %dч %dм" % [h, m], 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Состав: золото, опыт, материалы (демо-расчёт из пакета)", 22))
	var chest := Panel.new()
	chest.custom_minimum_size = Vector2(0, 200)
	chest.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("3A2A10"), LunexColors.GOLD_BRIGHT, 20, 3))
	root.add_child(chest)
	if ThemeManager.parallax_enabled:
		var tw := create_tween().set_loops()
		tw.tween_property(chest, "scale", Vector2(1.02, 1.02), 0.8)
		tw.tween_property(chest, "scale", Vector2.ONE, 0.8)
	var gold_amt := mini(cap_gold, gold_per_10s * 10 + sec / 10)
	root.add_child(UIFactory.label("К сбору ≈ %d золота" % gold_amt, 24))
	var collect := UIFactory.gold_button("Собрать")
	collect.pressed.connect(func():
		if DemoData.afk_seconds_accumulated <= 0:
			NotificationManager.info("Пока нечего собирать")
			return
		AppState.add_demo_rewards(gold_amt, 0)
		DemoData.afk_seconds_accumulated = 0
		ModalManager.push_rewards("AFK-награды", ["Золото ×%d" % gold_amt, "Опыт отряда"])
		_rebuild()
	)
	root.add_child(collect)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
