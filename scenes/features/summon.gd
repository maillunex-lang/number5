extends Control
## HUB-01: алтарь призыва. Online → CORE-01 summon/roll; иначе локальный DEMO.

var _payload: Dictionary = {}
var _busy: bool = false
var _banner_id: String = "standard"

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _banner() -> Dictionary:
	var banners: Array = ContentPackageLoader.gacha.get("banners", [])
	for b in banners:
		if str(b.get("id", "")) == _banner_id:
			return b
	if banners.size() > 0:
		return banners[0]
	return {}

func _mode_label() -> String:
	return "ONLINE · CORE-01" if ApiClient.online else "DEMO · локальный RNG"

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var banner := _banner()
	var name := str(banner.get("name", ContentPackageLoader.features.get("summon", {}).get("banner", "Баннер")))
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("summon.altar", "Алтарь призыва")))
	root.add_child(UIFactory.label("Баннер: %s" % name, 26, LunexColors.GOLD))
	root.add_child(UIFactory.muted("%s · %s" % [ContentPackageLoader.package_label(), _mode_label()], 18))

	var row_b := UIFactory.hbox(8)
	root.add_child(row_b)
	for b in ContentPackageLoader.gacha.get("banners", []):
		var id := str(b.get("id", ""))
		var btn := UIFactory.fantasy_button(str(b.get("name", id)))
		btn.custom_minimum_size = Vector2(160, 44)
		var bid := id
		btn.pressed.connect(func():
			_banner_id = bid
			_rebuild()
		)
		row_b.add_child(btn)

	var art := Panel.new()
	art.custom_minimum_size = Vector2(0, 180)
	art.add_theme_stylebox_override("panel", UIFactory.panel_style(Color("1A2840"), LunexColors.CYAN, 18, 2))
	root.add_child(art)

	var rates: Dictionary = banner.get("rates_bp", {})
	var cost1: Array = banner.get("cost_x1", [])
	var cost10: Array = banner.get("cost_x10", [])
	var c1 := "1 свиток"
	var c10 := "8 свитков"
	if cost1.size() > 0:
		c1 = "%s ×%s" % [str(cost1[0].get("resource_id", "")), str(cost1[0].get("amount", 1))]
	if cost10.size() > 0:
		c10 = "%s ×%s" % [str(cost10[0].get("resource_id", "")), str(cost10[0].get("amount", 8))]
	root.add_child(UIFactory.muted("×1: %s · ×10: %s" % [c1, c10], 20))

	var row := UIFactory.hbox(12)
	root.add_child(row)
	var info := UIFactory.fantasy_button("Шансы и pity")
	info.pressed.connect(_show_pity)
	row.add_child(info)
	var x1 := UIFactory.gold_button("Призыв ×1")
	x1.pressed.connect(func(): _do_summon(1))
	row.add_child(x1)
	var x10 := UIFactory.gold_button("Призыв ×10")
	x10.pressed.connect(func(): _do_summon(10))
	root.add_child(x10)

	var to_heroes := UIFactory.fantasy_button("В коллекцию")
	to_heroes.pressed.connect(func():
		ScreenRouter.switch_tab("heroes")
	)
	root.add_child(to_heroes)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _show_pity() -> void:
	var banner := _banner()
	var rates: Dictionary = banner.get("rates_bp", {})
	var pity_txt := str(banner.get("pity", {}))
	if ApiClient.online:
		var res := await ApiClient.summon_pity()
		if res.get("ok", false):
			pity_txt = str(res.get("data", {}).get("pity", pity_txt))
	ModalManager.push_info(
		"Правила · %s" % str(banner.get("name", "")),
		"N %s%% · R %s%% · SR %s%% · SSR %s%% · UR %s%%\nPity: %s\nРежим: %s" % [
			str((rates.get("N", 0) as int) / 100.0),
			str((rates.get("R", 0) as int) / 100.0),
			str((rates.get("SR", 0) as int) / 100.0),
			str((rates.get("SSR", 0) as int) / 100.0),
			str((rates.get("UR", 0) as int) / 100.0),
			pity_txt,
			_mode_label(),
		]
	)

func _do_summon(count: int) -> void:
	if _busy:
		return
	_busy = true
	if ApiClient.online:
		await _do_summon_online(count)
	else:
		await _do_summon_demo(count)
	_busy = false

func _do_summon_online(count: int) -> void:
	NotificationManager.info("Призыв… (сервер)")
	var res := await ApiClient.summon_roll(_banner_id, count)
	if res.get("ok", false) != true:
		NotificationManager.warn("Призыв недоступен · %s" % str(res.get("error", "")))
		await _do_summon_demo(count)
		return
	var data: Dictionary = res.get("data", {})
	var results: Array = []
	for r in data.get("results", []):
		if typeof(r) != TYPE_DICTIONARY:
			continue
		var hid := str(r.get("hero_id", ""))
		var rarity := str(r.get("rarity", ""))
		var h := DemoData.get_hero(hid)
		var nm := str(h.get("name", hid)) if not h.is_empty() else hid
		var tag := "новый" if bool(r.get("is_new", false)) else ("осколки ×%s" % str(r.get("shards_gained", 0)))
		results.append("%s (%s) · %s" % [nm, rarity, tag])
	await ApiClient.sync_wallet()
	ModalManager.push_rewards("Результаты ×%d · ONLINE" % count, results)

func _do_summon_demo(count: int) -> void:
	var banner := _banner()
	var rates: Dictionary = banner.get("rates_bp", {"N": 5000, "R": 3500, "SR": 1200, "SSR": 300, "UR": 0})
	NotificationManager.info("Призыв… (демо)")
	await get_tree().create_timer(0.35).timeout
	var results: Array = []
	var got_sr_plus := false
	for i in count:
		var rarity := _roll_rarity(rates)
		if count == 10 and i == 9 and not got_sr_plus:
			rarity = _force_sr_plus(rates)
		if rarity in ["SR", "SSR", "UR"]:
			got_sr_plus = true
		var hero := _pick_hero(banner, rarity)
		results.append("%s (%s)" % [hero, rarity])
	ModalManager.push_rewards("Результаты ×%d · DEMO" % count, results)

func _roll_rarity(rates: Dictionary) -> String:
	var order := ["N", "R", "SR", "SSR", "UR"]
	var total := 0
	for k in order:
		total += int(rates.get(k, 0))
	if total <= 0:
		return "N"
	var roll := randi() % total
	var acc := 0
	for k in order:
		acc += int(rates.get(k, 0))
		if roll < acc:
			return k
	return "N"

func _force_sr_plus(rates: Dictionary) -> String:
	var pool := ["SR", "SSR", "UR"]
	var weights: Array[int] = []
	var sum := 0
	for k in pool:
		var w := int(rates.get(k, 0))
		weights.append(w)
		sum += w
	if sum <= 0:
		return "SR"
	var roll := randi() % sum
	var acc := 0
	for i in pool.size():
		acc += weights[i]
		if roll < acc:
			return pool[i]
	return "SR"

func _pick_hero(banner: Dictionary, rarity: String) -> String:
	var pools: Dictionary = banner.get("pools", {})
	if banner.get("faction_select", false):
		var by_f: Dictionary = banner.get("pools_by_faction", {})
		if by_f.has("F01"):
			pools = by_f["F01"]
	var ids: Array = pools.get(rarity, [])
	if ids.is_empty():
		for k in pools.keys():
			if (pools[k] as Array).size() > 0:
				ids = pools[k]
				break
	if ids.is_empty():
		return "Новичок"
	var hid := str(ids[randi() % ids.size()])
	var h := DemoData.get_hero(hid)
	if h.is_empty():
		return hid
	return str(h.get("name", hid))
