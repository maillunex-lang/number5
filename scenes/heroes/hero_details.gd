extends Control
## HERO-01: chrome в .tscn; TabContentHost — skills/art/equip.

var _payload: Dictionary = {}
var _hero: Dictionary = {}
var _tab: String = "info"

@onready var _vbox: VBoxContainer = $Safe/Scroll/VBox
@onready var _missing: VBoxContainer = $Safe/Scroll/MissingPanel
@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _portrait: ColorRect = $Safe/Scroll/VBox/PortraitFrame/Portrait
@onready var _face: TextureRect = $Safe/Scroll/VBox/PortraitFrame/Portrait/Face
@onready var _class_lbl: Label = $Safe/Scroll/VBox/ClassLabel
@onready var _power_lbl: Label = $Safe/Scroll/VBox/PowerLabel
@onready var _stats_lbl: Label = $Safe/Scroll/VBox/StatsLabel
@onready var _quote_lbl: Label = $Safe/Scroll/VBox/QuoteLabel
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/TabContentHost
@onready var _tab_btns: Dictionary = {
	"info": $Safe/Scroll/VBox/Tabs/TabInfo,
	"skills": $Safe/Scroll/VBox/Tabs/TabSkills,
	"art": $Safe/Scroll/VBox/Tabs/TabArt,
	"equip": $Safe/Scroll/VBox/Tabs/TabEquip,
}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	$Safe/Scroll/MissingPanel/MissingBack.pressed.connect(func(): ScreenRouter.handle_back())
	for key in _tab_btns.keys():
		var k: String = key
		_tab_btns[k].pressed.connect(func():
			_tab = k
			_style_tabs()
			_rebuild_tab()
		)
	var hid: String = str(_payload.get("hero_id", UIStateManager.selected_hero_id))
	_hero = DemoData.get_hero(hid)
	if _hero.is_empty():
		_vbox.visible = false
		_missing.visible = true
		return
	_missing.visible = false
	_vbox.visible = true
	_bind_header()
	_style_tabs()
	_rebuild_tab()

func _bind_header() -> void:
	_title.text = str(_hero.name)
	_class_lbl.text = "Класс: %s · Фракция: %s" % [_hero.class, _hero.faction]
	_power_lbl.text = "Уровень %d · Звёзды %d · Сила %d" % [_hero.level, _hero.stars, _hero.power]
	_stats_lbl.text = "HP %d · ATK %d · DEF %d" % [_hero.hp, _hero.atk, _hero.def]
	var quote := str(_hero.get("quote", ""))
	if quote == "":
		var sk_hero: Dictionary = ContentPackageLoader.skills_pack.get("heroes", {}).get(str(_hero.id), {})
		quote = str(sk_hero.get("quote", ""))
	_quote_lbl.visible = quote != ""
	_quote_lbl.text = "«%s»" % quote
	var tint_raw: Variant = _hero.get("tint", Color("5EC8E8"))
	var tint: Color = tint_raw if typeof(tint_raw) == TYPE_COLOR else Color(str(tint_raw))
	var tex: Texture2D = AssetLoader.hero_portrait(str(_hero.id))
	_face.texture = tex
	_portrait.color = Color(0.08, 0.1, 0.14, 1) if tex != null else Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1)

func _style_tabs() -> void:
	for key in _tab_btns.keys():
		_tab_btns[key].theme_type_variation = &"GoldButton" if key == _tab else &"GameButton"

func _rebuild_tab() -> void:
	for c in _host.get_children():
		c.queue_free()
	match _tab:
		"skills":
			_build_skills()
		"art":
			_build_art()
		"equip":
			_build_equip()
		_:
			_build_info()

func _build_info() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_host.add_child(row)
	var lvl := Button.new()
	lvl.text = "Уровень +"
	lvl.custom_minimum_size = Vector2(0, 56)
	lvl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvl.theme_type_variation = &"GameButton"
	lvl.disabled = true
	lvl.tooltip_text = "Повышение уровня будет доступно после подключения серверной операции"
	row.add_child(lvl)
	var auto := Button.new()
	auto.text = "Автоэкипировка"
	auto.custom_minimum_size = Vector2(0, 56)
	auto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto.theme_type_variation = &"GoldButton"
	auto.disabled = true
	auto.tooltip_text = "Экипировка будет доступна после подключения серверной операции"
	row.add_child(auto)
	for panel_name in [["Таланты", "talents"], ["Артефакт", "artifact"], ["Связи", "bonds"]]:
		var b := Button.new()
		b.text = panel_name[0]
		b.custom_minimum_size = Vector2(0, 56)
		b.theme_type_variation = &"GameButton"
		var title: String = panel_name[0]
		var key: String = panel_name[1]
		b.pressed.connect(func():
			ModalManager.push_info(title, "Раздел «%s» для %s.\nСтатус: Демо · полный функционал позже." % [key, _hero.name])
		)
		_host.add_child(b)

func _build_skills() -> void:
	_host.add_child(_section(ContentPackageLoader.tr_key("skills.title", "Навыки"), LunexColors.GOLD, 28))
	_host.add_child(_muted(ContentPackageLoader.tr_key("c5.demo", "C5 DEMO"), 16))
	var cards_by_id: Dictionary = {}
	for c in ContentPackageLoader.skills_pack.get("cards", []):
		cards_by_id[str(c.get("id", ""))] = c
	var skill_ids: Array = _hero.get("skills", [])
	for sid_v in skill_ids:
		var sid := str(sid_v)
		var card: Dictionary = cards_by_id.get(sid, {})
		var p := PanelContainer.new()
		p.theme_type_variation = &"GamePanel"
		var pad := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			pad.add_theme_constant_override("margin_" + side, 12)
		p.add_child(pad)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		pad.add_child(v)
		if card.is_empty():
			v.add_child(_section(sid, LunexColors.GOLD, 20))
			v.add_child(_muted("Карточка не найдена в skills.json", 16))
		else:
			v.add_child(_section("%s · %s" % [str(card.get("slot", "")), str(card.get("name", ""))], LunexColors.GOLD, 22))
			v.add_child(_label(str(card.get("description", "")), 18))
			var meta_parts: PackedStringArray = []
			if card.has("cooldown_sec") and card["cooldown_sec"] != null:
				meta_parts.append("КД %sс" % str(card["cooldown_sec"]))
			if card.has("energy_cost"):
				meta_parts.append("энергия %s" % str(card["energy_cost"]))
			if card.has("cast"):
				meta_parts.append(str(card["cast"]))
			if meta_parts.size() > 0:
				v.add_child(_muted(", ".join(meta_parts), 16))
		_host.add_child(p)

func _build_art() -> void:
	_host.add_child(_section(ContentPackageLoader.tr_key("art.title", "Реестр арта"), LunexColors.GOLD, 28))
	_host.add_child(_muted(ContentPackageLoader.tr_key("c6.demo", "C6 DEMO"), 16))
	var art: Dictionary = ContentPackageLoader.hero_art(str(_hero.id))
	if art.is_empty():
		_host.add_child(_muted("Нет art-блока в heroes.json", 18))
		return
	_host.add_child(_muted("status · %s" % str(art.get("status", "placeholder")), 18))
	for slot in ["portrait", "atlas", "animations", "ultimate_vfx"]:
		var key := str(art.get(slot, ""))
		var item := ContentPackageLoader.resolve_asset(key)
		var p := PanelContainer.new()
		p.theme_type_variation = &"GamePanel"
		var pad := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			pad.add_theme_constant_override("margin_" + side, 12)
		p.add_child(pad)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		pad.add_child(v)
		v.add_child(_section(slot, LunexColors.GOLD, 20))
		v.add_child(_muted("%s → %s" % [key, str(item.get("id", "—"))], 16))
		v.add_child(_muted("%s · %s" % [str(item.get("path", "")), str(item.get("status", ""))], 14))
		_host.add_child(p)
	var clips: Array = art.get("clips", [])
	if not clips.is_empty():
		_host.add_child(_muted("clips: %s" % ", ".join(clips), 16))
	var open := Button.new()
	open.text = "Весь реестр"
	open.custom_minimum_size = Vector2(0, 56)
	open.theme_type_variation = &"GameButton"
	open.pressed.connect(func(): ScreenRouter.go("ART-01"))
	_host.add_child(open)

func _build_equip() -> void:
	_host.add_child(_section("Экипировка", Color.WHITE, 28))
	for slot in ["weapon", "armor", "acc"]:
		var eid: String = str(_hero.equip.get(slot, ""))
		var ename := "Пусто"
		for e in DemoData.equipment_pool:
			if e.id == eid:
				ename = e.name
				break
		_host.add_child(_label("%s: %s" % [slot, ename], 22))

func _section(text: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _muted(text: String, size: int) -> Label:
	var l := _label(text, size)
	l.add_theme_color_override("font_color", LunexColors.TEXT_SECONDARY)
	return l
