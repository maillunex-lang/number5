extends Node
## Демонстрационные данные прототипа. Помечены как локальные, не серверные.

signal heroes_changed
signal squad_changed

var heroes: Array[Dictionary] = []
var equipment_pool: Array[Dictionary] = []
var squad_slots: Array[String] = ["", "", "", "", ""] # hero ids
var squad_presets: Array[Dictionary] = []
var selected_hero_id: String = ""
var campaign_progress: Dictionary = {}
var afk_seconds_accumulated: int = 3600 * 3 + 420
var mail_unread: int = 2
var quest_ready: int = 3

func _ready() -> void:
	_seed_heroes()
	_seed_equipment()
	_seed_presets()
	_seed_campaign()
	selected_hero_id = heroes[0]["id"]
	for i in mini(5, heroes.size()):
		squad_slots[i] = heroes[i]["id"]

func _seed_heroes() -> void:
	heroes = [
		_hero("h_aria", "Ария Света", "Страж", "Империя Порядка", "legendary", Color("F2D48A"), 42, 5, 12800, ["heal", "shield", "smite"]),
		_hero("h_kael", "Каэль Тень", "Убийца", "Сумрачные", "epic", Color("7A6AD8"), 38, 4, 11200, ["bleed", "dash", "execute"]),
		_hero("h_mira", "Мира Лист", "Стрелок", "Лесные", "epic", Color("5FBF7A"), 36, 4, 10500, ["volley", "trap", "mark"]),
		_hero("h_tor", "Тор Камень", "Танк", "Клановые кузнецы", "rare", Color("C47A4A"), 40, 3, 9800, ["taunt", "slam", "fortify"]),
		_hero("h_nyx", "Никс Искра", "Маг", "Арканисты", "legendary", Color("5EC8E8"), 35, 5, 13100, ["nova", "freeze", "rift"]),
		_hero("h_rena", "Рена Ветер", "Поддержка", "Вольные города", "rare", Color("E8A0C0"), 30, 3, 8600, ["haste", "cleanse", "song"]),
		_hero("h_drak", "Драк Пепел", "Воин", "Сумрачные", "epic", Color("C4454A"), 33, 4, 10100, ["cleave", "rage", "burn"]),
	]

func _hero(id: String, name: String, cls: String, faction: String, rarity: String, tint: Color, level: int, stars: int, power: int, skills: Array) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"class": cls,
		"faction": faction,
		"rarity": rarity,
		"tint": tint,
		"level": level,
		"stars": stars,
		"power": power,
		"hp": 1000 + level * 80 + stars * 200,
		"atk": 120 + level * 12 + stars * 30,
		"def": 80 + level * 8,
		"favorite": id in ["h_aria", "h_nyx"],
		"skills": skills,
		"equip": {"weapon": "", "armor": "", "acc": ""},
	}

func _seed_equipment() -> void:
	equipment_pool = [
		{"id": "w1", "slot": "weapon", "name": "Клинок Рассвета", "power": 420, "rarity": "epic"},
		{"id": "w2", "slot": "weapon", "name": "Жезл Искры", "power": 510, "rarity": "legendary"},
		{"id": "a1", "slot": "armor", "name": "Латы Стража", "power": 380, "rarity": "rare"},
		{"id": "a2", "slot": "armor", "name": "Мантия Разлома", "power": 450, "rarity": "epic"},
		{"id": "c1", "slot": "acc", "name": "Амулет Плетения", "power": 260, "rarity": "rare"},
		{"id": "c2", "slot": "acc", "name": "Кольцо Сердца", "power": 340, "rarity": "epic"},
	]

func _seed_presets() -> void:
	squad_presets = [
		{"id": "p1", "name": "Баланс", "slots": ["h_aria", "h_tor", "h_mira", "h_kael", "h_nyx"]},
		{"id": "p2", "name": "Магия", "slots": ["h_nyx", "h_aria", "h_rena", "h_mira", "h_kael"]},
		{"id": "p3", "name": "Фронт", "slots": ["h_tor", "h_drak", "h_aria", "h_kael", "h_mira"]},
	]

func _seed_campaign() -> void:
	campaign_progress = {
		"chapter_id": "ch1",
		"chapter_name": "Сумерки Святилища",
		"current_stage": "s1_3",
		"stages": [
			{"id": "s1_1", "name": "Тропа осколков", "power": 8000, "type": "main", "state": "cleared", "rewards": ["Золото", "Опыт"]},
			{"id": "s1_2", "name": "Сломанный алтарь", "power": 9500, "type": "main", "state": "cleared", "rewards": ["Золото", "Пыль"]},
			{"id": "s1_3", "name": "Стражи врат", "power": 11000, "type": "main", "state": "available", "rewards": ["Золото", "Свиток"]},
			{"id": "s1_4", "name": "Эхо Раскола", "power": 12500, "type": "main", "state": "locked", "rewards": ["Алмазы", "Осколок"]},
			{"id": "s1_5", "name": "Сердце пепла", "power": 14000, "type": "main", "state": "locked", "rewards": ["Герой?", "Золото"]},
			{"id": "s1_2b", "name": "Скрытая роща", "power": 10000, "type": "side", "state": "available", "rewards": ["Материалы"]},
			{"id": "s1_3s", "name": "Тайный разлом", "power": 13000, "type": "secret", "state": "locked", "rewards": ["Артефакт?"], "reveal_hint": "Откроется после этапа 1-4"},
		],
		"regions": [
			{"id": "r1", "name": "Земли Плетения", "unlocked": true},
			{"id": "r2", "name": "Пепельные Степи", "unlocked": false, "req": "Глава 2"},
			{"id": "r3", "name": "Кристальный Берег", "unlocked": false, "req": "Глава 3"},
		],
	}

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
	# Remove duplicates
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
			h["power"] = int(h["power"]) + 50 # demo bump
	heroes_changed.emit()

func get_stage(stage_id: String) -> Dictionary:
	for s in campaign_progress["stages"]:
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
