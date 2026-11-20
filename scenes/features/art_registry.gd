extends Control
## ART-01: реестр арта из assets.json (C6 + ART-05 placeholder webp в media/).

var _tab: String = "budget"

func setup(_payload: Dictionary = {}) -> void:
	pass

func _ready() -> void:
	_rebuild()

func _assets() -> Dictionary:
	return ContentPackageLoader.assets

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("art.title", "Реестр арта")))
	root.add_child(UIFactory.muted("%s · %s" % [
		ContentPackageLoader.package_label(),
		ContentPackageLoader.tr_key("c6.demo", "ART-05 · placeholder webp в media/heroes|rigs"),
	], 18))

	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [
		["budget", ContentPackageLoader.tr_key("art.budget", "Бюджет")],
		["rigs", ContentPackageLoader.tr_key("art.rigs", "Риги")],
		["heroes", ContentPackageLoader.tr_key("art.heroes", "Герои")],
		["chapters", ContentPackageLoader.tr_key("art.chapters", "Главы")],
	]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(140, 44)
		var key: String = t[0]
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)

	match _tab:
		"rigs":
			_build_rigs(root)
		"heroes":
			_build_heroes(root)
		"chapters":
			_build_chapters(root)
		_:
			_build_budget(root)

	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _build_budget(root: VBoxContainer) -> void:
	var a := _assets()
	var budget: Dictionary = a.get("production_budget", {})
	var summary: Dictionary = a.get("summary", {})
	root.add_child(UIFactory.label("Производственный бюджет (BESTIARY)", 24, LunexColors.GOLD))
	for k in ["rigs", "enemy_skins", "story_bosses", "common_vfx", "boss_arenas", "common_sfx", "hero_sets_planned"]:
		if budget.has(k):
			root.add_child(UIFactory.muted("%s · %s" % [str(k), str(budget[k])], 18))
	if budget.has("note"):
		root.add_child(UIFactory.muted(str(budget["note"]), 16))
	root.add_child(UIFactory.label("Сводка реестра", 24, LunexColors.GOLD))
	for k in ["items_total", "bindings_total", "heroes", "rigs", "rig_skins", "boss_portraits", "chapter_packs"]:
		if summary.has(k):
			root.add_child(UIFactory.muted("%s · %s" % [str(k), str(summary[k])], 18))
	var slots: Dictionary = a.get("animation_slots", {})
	if not slots.is_empty():
		root.add_child(UIFactory.label("Слоты анимаций", 24, LunexColors.GOLD))
		root.add_child(UIFactory.muted("hero: %s" % ", ".join(slots.get("hero", [])), 16))
		root.add_child(UIFactory.muted("rig: %s" % ", ".join(slots.get("rig_default", [])), 16))

func _build_rigs(root: VBoxContainer) -> void:
	root.add_child(UIFactory.label("6 базовых ригов", 24, LunexColors.GOLD))
	var rigs: Array = ContentPackageLoader.enemies_pack.get("rigs", [])
	for r in rigs:
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		var rid := str(r.get("id", ""))
		v.add_child(UIFactory.label("%s · %s" % [rid, str(r.get("name", ""))], 20, LunexColors.GOLD))
		v.add_child(UIFactory.muted("role %s · spd %s · status %s" % [
			str(r.get("role", "")),
			str(r.get("spd", "")),
			str(r.get("art_status", "—")),
		], 16))
		var clips: Array = r.get("animations", [])
		if not clips.is_empty():
			v.add_child(UIFactory.muted("clips: %s" % ", ".join(clips), 16))
		var atlas := ContentPackageLoader.get_asset_binding("rig.%s.atlas" % rid)
		var skin_a := ContentPackageLoader.get_asset_binding("rig.%s.skin_a" % rid)
		v.add_child(UIFactory.muted("atlas → %s · skin_a → %s" % [atlas, skin_a], 14))
		root.add_child(p)

func _build_heroes(root: VBoxContainer) -> void:
	root.add_child(UIFactory.label("45 героев · слоты portrait/atlas/anim/vfx", 24, LunexColors.GOLD))
	var shown := 0
	for h in ContentPackageLoader.heroes_pack.get("heroes", []):
		if shown >= 12:
			root.add_child(UIFactory.muted("… и ещё %d (см. assets.json)" % (
				ContentPackageLoader.heroes_pack.get("heroes", []).size() - shown
			), 16))
			break
		var art: Dictionary = h.get("art", {})
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(h.get("id", "")), str(h.get("name", ""))], 20, LunexColors.GOLD))
		v.add_child(UIFactory.muted("status %s · asset %s" % [
			str(art.get("status", h.get("placeholder", true))),
			str(h.get("asset_id", "")),
		], 16))
		var portrait_key := str(art.get("portrait", ""))
		if portrait_key != "":
			var aid := ContentPackageLoader.get_asset_binding(portrait_key)
			var item := ContentPackageLoader.get_asset_item(aid)
			v.add_child(UIFactory.muted("portrait → %s · %s" % [
				aid,
				str(item.get("path", "")),
			], 14))
		root.add_child(p)
		shown += 1

func _build_chapters(root: VBoxContainer) -> void:
	root.add_child(UIFactory.label("6 арт-пакетов глав", 24, LunexColors.GOLD))
	for ch in range(1, 7):
		var cid := "CH%02d" % ch
		var map_id := ContentPackageLoader.get_asset_binding("chapter.%s.map" % cid)
		var item := ContentPackageLoader.get_asset_item(map_id)
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [
			cid,
			str(item.get("meta", {}).get("name", "")),
		], 20, LunexColors.GOLD))
		v.add_child(UIFactory.muted("map → %s" % str(item.get("path", map_id)), 16))
		v.add_child(UIFactory.muted("зоны 6×(bg/mid/fg) · арены 3 · status placeholder", 14))
		root.add_child(p)
