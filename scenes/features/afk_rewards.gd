extends Control
## HUB-02: AFK по liveops.json (локальный демо-расчёт).

var _payload: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
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
	var rates: Array = afk.get("rates_by_chapter", [])
	var ch1: Dictionary = rates[0] if rates.size() > 0 else {}
	var gold_h := int(ch1.get("gold_per_hour", afk.get("gold_per_hour", 1800)))
	var xp_h := int(ch1.get("hero_xp_per_hour", afk.get("hero_xp_per_hour", 700)))
	var ess_h := int(ch1.get("essence_per_hour", 30))
	var cap_h := int(afk.get("cap_hours", 12))
	var unlock := str(afk.get("unlock_stage", "CH01-03"))

	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("afk.title", "AFK-сокровищница")))
	root.add_child(UIFactory.muted("%s · DEMO · открытие после %s" % [ContentPackageLoader.package_label(), unlock], 18))
	var sec := mini(DemoData.afk_seconds_accumulated, cap_h * 3600)
	var h := sec / 3600
	var m := (sec % 3600) / 60
	root.add_child(UIFactory.label("Накоплено: %dч %dм / кап %dч" % [h, m, cap_h], 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Ставка гл.1: %d зол/ч · %d XP/ч · %d эсс/ч" % [gold_h, xp_h, ess_h], 20))
	root.add_child(UIFactory.muted("Без алмазов и SSR/UR из AFK (канон)", 18))

	var chest := Panel.new()
	chest.custom_minimum_size = Vector2(0, 180)
	chest.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("3A2A10"), LunexColors.GOLD_BRIGHT, 20, 3))
	root.add_child(chest)

	var hours := float(sec) / 3600.0
	var gold_amt := int(floor(gold_h * hours))
	var xp_amt := int(floor(xp_h * hours))
	var ess_amt := int(floor(ess_h * hours))
	root.add_child(UIFactory.label("К сбору: золото %d · XP %d · эссенция %d" % [gold_amt, xp_amt, ess_amt], 22))

	var collect := UIFactory.gold_button("Собрать")
	collect.pressed.connect(func():
		if DemoData.afk_seconds_accumulated <= 0:
			NotificationManager.info("Пока нечего собирать")
			return
		AppState.add_demo_rewards(gold_amt, 0)
		DemoData.afk_seconds_accumulated = 0
		ModalManager.push_rewards("AFK-награды (демо)", [
			"Золото ×%d" % gold_amt,
			"Опыт героя ×%d" % xp_amt,
			"Эссенция ×%d" % ess_amt,
		])
		_rebuild()
	)
	root.add_child(collect)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
