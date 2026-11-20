extends Node
## Игровые данные прототипа из контент-пакета.
## Локальный прогресс сессии (отряд, AFK-таймер) — не серверный источник истины.

signal heroes_changed
signal squad_changed
signal content_reloaded

var heroes: Array[Dictionary] = []
var equipment_pool: Array[Dictionary] = []
var squad_slots: Array[String] = ["", "", "", "", ""]
var squad_presets: Array[Dictionary] = []
var selected_hero_id: String = ""
var campaign_progress: Dictionary = {}
var afk_seconds_accumulated: int = 3600 * 3 + 420
var mail_unread: int = 2
var quest_ready: int = 3

func _ready() -> void:
	_apply_from_package()
	ContentPackageLoader.package_loaded.connect(func(_v):
		_apply_from_package()
		content_reloaded.emit()
	)

func reload_from_package() -> void:
	ContentPackageLoader.reload()
	_apply_from_package()
	content_reloaded.emit()

func _apply_from_package() -> void:
	_load_heroes()
	_load_equipment()
	_load_presets()
	_load_campaign()
	_load_features_defaults()
	if heroes.size() > 0 and selected_hero_id == "":
		selected_hero_id = str(heroes[0]["id"])
	if squad_slots[0] == "" and heroes.size() > 0:
		var defaults: Array = ContentPackageLoader.heroes_pack.get("default_squad", [])
		for i in 5:
			if i < defaults.size():
				squad_slots[i] = str(defaults[i])
			elif i < heroes.size():
				squad_slots[i] = str(heroes[i]["id"])
			else:
				squad_slots[i] = ""
	heroes_changed.emit()
	squad_changed.emit()

func _load_heroes() -> void:
	heroes.clear()
	var raw: Array = ContentPackageLoader.heroes_pack.get("heroes", [])
	for item in raw:
		var h: Dictionary = item
		var level := int(h.get("level", 1))
		var stars := int(h.get("stars", 1))
		var tint := Color(str(h.get("tint", "#888888")))
		var base: Dictionary = h.get("base_stats", {})
		var hp := int(base.get("hp", 1000 + level * 80 + stars * 200))
		var atk := int(base.get("atk", 120 + level * 12 + stars * 30))
		var defense := int(base.get("def", 80 + level * 8))
		# Масштаб L1 → текущий уровень (формулы канона, предварительные).
		if base.has("hp"):
			hp = int(round(float(base["hp"]) * (1.0 + 0.075 * float(level - 1))))
			atk = int(round(float(base["atk"]) * (1.0 + 0.060 * float(level - 1))))
			defense = int(round(float(base["def"]) * (1.0 + 0.055 * float(level - 1))))
		heroes.append({
			"id": str(h.get("id", "")),
			"name": str(h.get("name", "")),
			"class": str(h.get("class", "")),
			"role": str(h.get("role", "")),
			"faction": str(h.get("faction", "")),
			"faction_id": str(h.get("faction_id", "")),
			"rarity": str(h.get("rarity", "common")),
			"tint": tint,
			"level": level,
			"stars": stars,
			"power": int(h.get("power", 1000)),
			"hp": hp,
			"atk": atk,
			"def": defense,
			"spd": int(base.get("spd", 80)),
			"energy": int(base.get("energy", 0)),
			"favorite": bool(h.get("favorite", false)),
			"skills": h.get("skills", []),
			"equip": {"weapon": "", "armor": "", "acc": ""},
		})

func _load_equipment() -> void:
	equipment_pool.clear()
	for e in ContentPackageLoader.heroes_pack.get("equipment", []):
		equipment_pool.append(e)

func _load_presets() -> void:
	squad_presets.clear()
	for p in ContentPackageLoader.heroes_pack.get("squad_presets", []):
		squad_presets.append(p)

func _load_campaign() -> void:
	campaign_progress = ContentPackageLoader.campaign.duplicate(true)

func _load_features_defaults() -> void:
	var afk: Dictionary = ContentPackageLoader.features.get("afk", {})
	if afk.has("seconds_default"):
		afk_seconds_accumulated = int(afk["seconds_default"])
	mail_unread = 0
	var mail_pack: Dictionary = ContentPackageLoader.mail_pack
	if not mail_pack.is_empty():
		for m_raw in mail_pack.get("demo_inbox", []):
			var m: Dictionary = m_raw
			if str(m.get("status", "")) == "unread":
				mail_unread += 1
	else:
		var mail_feat = ContentPackageLoader.features.get("mail", [])
		if typeof(mail_feat) == TYPE_ARRAY:
			for m in mail_feat:
				if bool(m.get("unread", false)):
					mail_unread += 1
		elif typeof(mail_feat) == TYPE_DICTIONARY:
			mail_unread = int(mail_feat.get("unread_demo", 0))
	quest_ready = 0
	var quests: Dictionary = ContentPackageLoader.features.get("quests", {})
	for key in quests.keys():
		var list: Array = quests[key]
		for q in list:
			var prog := str(q.get("progress", ""))
			if "/" in prog:
				var parts := prog.split("/")
				if parts.size() == 2 and parts[0] == parts[1]:
					quest_ready += 1
			elif prog == "готово":
				quest_ready += 1

func get_hero(id: String) -> Dictionary:
	for h in heroes:
		if h["id"] == id:
			return h
	return {}

func get_filtered_heroes(faction: String = "", rarity: String = "", hero_class: String = "", query: String = "", sort_by: String = "power") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var q := query.to_lower()
	for h in heroes:
		if faction != "" and h["faction"] != faction:
			continue
		if rarity != "" and h["rarity"] != rarity:
			continue
		if hero_class != "" and h["class"] != hero_class:
			continue
		if q != "" and q not in String(h["name"]).to_lower():
			continue
		out.append(h)
	out.sort_custom(func(a, b):
		match sort_by:
			"level":
				return a["level"] > b["level"]
			"name":
				return String(a["name"]) < String(b["name"])
			"rarity":
				return _rarity_rank(a["rarity"]) > _rarity_rank(b["rarity"])
			_:
				return a["power"] > b["power"]
	)
	return out

func _rarity_rank(r: String) -> int:
	match r:
		"mythic": return 5
		"legendary": return 4
		"epic": return 3
		"rare": return 2
		_: return 1

func squad_power() -> int:
	var p := 0
	for id in squad_slots:
		if id == "":
			continue
		var h := get_hero(id)
		if not h.is_empty():
			p += int(h["power"])
	return p

func set_squad_slot(index: int, hero_id: String) -> void:
	if index < 0 or index >= 5:
		return
	for i in squad_slots.size():
		if squad_slots[i] == hero_id:
			squad_slots[i] = ""
	squad_slots[index] = hero_id
	squad_changed.emit()

func apply_preset(preset_id: String) -> void:
	for p in squad_presets:
		if p["id"] == preset_id:
			for i in 5:
				squad_slots[i] = p["slots"][i] if i < p["slots"].size() else ""
			squad_changed.emit()
			return

func auto_equip(hero_id: String) -> void:
	var h := get_hero(hero_id)
	if h.is_empty():
		return
	var best := {"weapon": null, "armor": null, "acc": null}
	for e in equipment_pool:
		var slot: String = e["slot"]
		if best[slot] == null or int(e["power"]) > int(best[slot]["power"]):
			best[slot] = e
	for slot in ["weapon", "armor", "acc"]:
		if best[slot] != null:
			h["equip"][slot] = best[slot]["id"]
			h["power"] = int(h["power"]) + 50
	heroes_changed.emit()

func get_stage(stage_id: String) -> Dictionary:
	for s in campaign_progress.get("stages", []):
		if s["id"] == stage_id:
			return s
	return {}

func enemy_squad_for_stage(stage_id: String) -> Array[Dictionary]:
	var stage := get_stage(stage_id)
	var base_power := int(stage.get("power", 10000))
	var out: Array[Dictionary] = []
	var enc := _encounter_for_stage(stage_id)
	var slots: Array = enc.get("slots", [])
	var tint_by_rig := {
		"RIG-GUARD": Color("5A7A8A"),
		"RIG-STRIKER": Color("8A4A5A"),
		"RIG-CASTER": Color("6A5A8A"),
		"RIG-CONSTRUCT": Color("7A6A4A"),
		"RIG-BEAST": Color("4A7A5A"),
		"RIG-WISP": Color("4A6A7A"),
	}
	if slots.is_empty():
		for i in 5:
			out.append({
				"id": "e_%s_%d" % [stage_id, i],
				"name": "Враг разлома",
				"tint": Color("6A5A50"),
				"hp": 800 + base_power / 12 + i * 40,
				"atk": 90 + base_power / 100 + i * 8,
				"power": base_power / 5 + i * 200,
			})
		return out
	for i in slots.size():
		var slot: Dictionary = slots[i]
		var eid := str(slot.get("enemy_id", ""))
		var meta := _enemy_meta(eid)
		var level := int(slot.get("level", 5))
		var tier := str(slot.get("tier", "normal"))
		var mult := 1.0
		match tier:
			"elite":
				mult = 1.35
			"boss":
				mult = 2.2
		var tint: Color = tint_by_rig.get(str(meta.get("rig_id", "")), Color("6A5A50"))
		out.append({
			"id": "%s_%d" % [eid, i],
			"enemy_id": eid,
			"name": str(meta.get("name", eid)),
			"tint": tint,
			"rig_id": str(meta.get("rig_id", "")),
			"tier": tier,
			"hp": int((900 + base_power / 14 + level * 35) * mult),
			"atk": int((95 + base_power / 110 + level * 6) * mult),
			"power": int((base_power / 5 + level * 40) * mult),
		})
	return out

func _encounter_for_stage(stage_id: String) -> Dictionary:
	for enc in ContentPackageLoader.enemies_pack.get("encounters", []):
		if str(enc.get("stage_id", "")) == stage_id:
			return enc
	return {}

func _enemy_meta(enemy_id: String) -> Dictionary:
	for e in ContentPackageLoader.enemies_pack.get("enemies", []):
		if str(e.get("id", "")) == enemy_id:
			return e
	for b in ContentPackageLoader.enemies_pack.get("bosses", []):
		if str(b.get("id", "")) == enemy_id:
			return b
	return {"id": enemy_id, "name": enemy_id, "rig_id": "RIG-GUARD"}

func ally_battle_units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in squad_slots:
		var h := get_hero(id)
		if h.is_empty():
			continue
		out.append({
			"id": h["id"],
			"name": h["name"],
			"tint": h["tint"],
			"hp": h["hp"],
			"atk": h["atk"],
			"power": h["power"],
			"skills": h["skills"],
		})
	return out
