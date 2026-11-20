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
		heroes.append({
			"id": str(h.get("id", "")),
			"name": str(h.get("name", "")),
			"class": str(h.get("class", "")),
			"faction": str(h.get("faction", "")),
			"rarity": str(h.get("rarity", "common")),
			"tint": tint,
			"level": level,
			"stars": stars,
			"power": int(h.get("power", 1000)),
			"hp": 1000 + level * 80 + stars * 200,
			"atk": 120 + level * 12 + stars * 30,
			"def": 80 + level * 8,
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
	var mail: Array = ContentPackageLoader.features.get("mail", [])
	mail_unread = 0
	for m in mail:
		if bool(m.get("unread", false)):
			mail_unread += 1
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
	var names := ["Страж осколка", "Тень разлома", "Голем пепла", "Стрелок руин", "Аколит"]
	var tints := [Color("8A7060"), Color("5A4A70"), Color("706050"), Color("4A6050"), Color("604050")]
	var out: Array[Dictionary] = []
	for i in 5:
		out.append({
			"id": "e_%s_%d" % [stage_id, i],
			"name": names[i],
			"tint": tints[i],
			"hp": 800 + base_power / 12 + i * 40,
			"atk": 90 + base_power / 100 + i * 8,
			"power": base_power / 5 + i * 200,
		})
	return out

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
