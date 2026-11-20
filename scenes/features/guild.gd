extends Control
## HUB-05: chrome в .tscn; ListHost — штаб/задания/рейды/магазин (DEMO).

var _payload: Dictionary = {}
var _tab: String = "hub"
var _nav_bound: bool = false

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _subtitle: Label = $Safe/Scroll/VBox/Subtitle
@onready var _guild: Label = $Safe/Scroll/VBox/GuildLabel
@onready var _meta: Label = $Safe/Scroll/VBox/MetaLabel
@onready var _announce: Label = $Safe/Scroll/VBox/AnnounceLabel
@onready var _tabs: HBoxContainer = $Safe/Scroll/VBox/TabsHost
@onready var _list: VBoxContainer = $Safe/Scroll/VBox/ListHost
@onready var _back: Button = $Safe/Scroll/VBox/BackBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_bind_nav()
	_rebuild()

func _bind_nav() -> void:
	if _nav_bound:
		return
	_nav_bound = true
	_back.pressed.connect(func(): ScreenRouter.handle_back())

func _g() -> Dictionary:
	return ContentPackageLoader.guilds

func _panel() -> GamePanel:
	var panel_scene: PackedScene = load("res://scenes/ui/components/game_panel.tscn")
	var p: GamePanel = panel_scene.instantiate()
	p.panel_kind = "GamePanel"
	return p

func _rebuild() -> void:
	var g := _g()
	var demo: Dictionary = g.get("demo", {}).get("guild", {})
	_title.text = ContentPackageLoader.tr_key("guild.title", "Гильдия")
	_subtitle.text = "%s · %s" % [
		ContentPackageLoader.package_label(),
		str(g.get("disclaimer", ContentPackageLoader.tr_key("guild.demo", "DEMO"))),
	]
	_guild.text = "%s [%s] · ур.%s · %s/%s" % [
		str(demo.get("name", "—")),
		str(demo.get("tag", "")),
		str(demo.get("level", 1)),
		str(demo.get("members", 0)),
		str(g.get("starting_capacity", 20)),
	]
	_meta.text = "Открытие после %s · жетоны: %s (демо)" % [
		str(g.get("unlock_stage", "CH01-20")),
		str(g.get("demo", {}).get("wallet_guild_token", 0)),
	]
	if demo.has("announcement"):
		_announce.visible = true
		_announce.text = str(demo["announcement"])
	else:
		_announce.visible = false
		_announce.text = ""

	for c in _tabs.get_children():
		c.queue_free()
	for t in [["hub", "Штаб"], ["quests", "Задания"], ["raids", "Рейды"], ["shop", "Магазин"]]:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(150, 44)
		b.theme_type_variation = &"GameButton"
		var key: String = t[0]
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		_tabs.add_child(b)

	for c in _list.get_children():
		c.queue_free()
	match _tab:
		"quests":
			_build_quests(g)
		"raids":
			_build_raids(g)
		"shop":
			_build_shop(g)
		_:
			_build_hub(g)

func _build_hub(g: Dictionary) -> void:
	var head := Label.new()
	head.text = "Зоны штаба"
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", LunexColors.GOLD)
	_list.add_child(head)
	for zone in [
		["Доска поручений", "quests"],
		["Врата Разлома", "raids"],
		["Склад знаков", "shop"],
		["Участники", "hub"],
	]:
		var p := _panel()
		_list.add_child(p)
		var content: VBoxContainer = p.get_node("Pad/Content")
		var label := Label.new()
		label.text = zone[0]
		label.add_theme_font_size_override("font_size", 22)
		content.add_child(label)
		var go := Button.new()
		go.text = "Открыть"
		go.custom_minimum_size = Vector2(0, 56)
		go.theme_type_variation = &"GoldButton"
		var key: String = zone[1]
		go.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		content.add_child(go)
	var note := Label.new()
	note.text = "Чат / рейтинг сезона — после сервера (CORE-01). Рейтинг: «Скоро»."
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(note)

func _build_quests(g: Dictionary) -> void:
	var head := Label.new()
	head.text = ContentPackageLoader.tr_key("guild.quests", "Доска поручений")
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", LunexColors.GOLD)
	_list.add_child(head)
	var meta := Label.new()
	meta.text = "Ежедневно %d из %d шаблонов (одинаковый набор для гильдии)" % [
		int(g.get("daily_quest_board_size", 5)),
		(g.get("daily_quests", []) as Array).size(),
	]
	meta.add_theme_font_size_override("font_size", 18)
	meta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(meta)
	var board: Array = g.get("daily_quests", [])
	var n := mini(int(g.get("daily_quest_board_size", 5)), board.size())
	for i in n:
		var q: Dictionary = board[i]
		var p := _panel()
		_list.add_child(p)
		var content: VBoxContainer = p.get_node("Pad/Content")
		var title := Label.new()
		title.text = "%s · %s" % [str(q.get("id", "")), str(q.get("name", ""))]
		title.add_theme_font_size_override("font_size", 20)
		title.add_theme_color_override("font_color", LunexColors.GOLD)
		content.add_child(title)
		var parts: PackedStringArray = []
		for r in q.get("rewards", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		var rewards := Label.new()
		rewards.text = "%s · guild XP +%s" % [", ".join(parts), str(q.get("guild_xp", 0))]
		rewards.add_theme_font_size_override("font_size", 16)
		rewards.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(rewards)
		var claim := Button.new()
		claim.text = "Забрать (демо)"
		claim.custom_minimum_size = Vector2(0, 48)
		claim.theme_type_variation = &"GameButton"
		claim.pressed.connect(func():
			ModalManager.push_rewards("Задание гильдии (демо)", parts)
		)
		content.add_child(claim)

func _build_raids(g: Dictionary) -> void:
	var raids: Dictionary = g.get("raids", {})
	var head := Label.new()
	head.text = ContentPackageLoader.tr_key("guild.raids", "Врата Разлома")
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", LunexColors.GOLD)
	_list.add_child(head)
	var meta := Label.new()
	meta.text = "Асинхронно: общий HP · %dч · %d попытки/сутки · без realtime 30 героев" % [
		int(raids.get("duration_hours", 72)),
		int(raids.get("daily_attempts_per_member", 2)),
	]
	meta.add_theme_font_size_override("font_size", 18)
	meta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(meta)
	for t in raids.get("tiers", []):
		var p := _panel()
		_list.add_child(p)
		var content: VBoxContainer = p.get_node("Pad/Content")
		var title := Label.new()
		title.text = "Tier %s · %s" % [str(t.get("tier", "")), str(t.get("name", ""))]
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", LunexColors.GOLD)
		content.add_child(title)
		var info := Label.new()
		info.text = "Guild L%s · HP %s · босс %s · активных ~%s" % [
			str(t.get("guild_level_required", 1)),
			str(t.get("shared_hp", 0)),
			str(t.get("boss_id", "")),
			str(t.get("recommended_active_members", 0)),
		]
		info.add_theme_font_size_override("font_size", 16)
		info.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(info)
		var go := Button.new()
		go.text = "Попытка (демо бой)"
		go.custom_minimum_size = Vector2(0, 56)
		go.theme_type_variation = &"GoldButton"
		var boss_id := str(t.get("boss_id", ""))
		var tier := str(t.get("tier", "I"))
		go.pressed.connect(func():
			UIStateManager.set_combat_context({"mode": "guild_raid", "stage_id": "RAID-%s" % tier, "return_route": "HUB-05"})
			ScreenRouter.go("COMBAT-01", {"mode": "guild_raid", "stage_id": "RAID-%s" % tier, "enemy_hint": boss_id})
		)
		content.add_child(go)
	var note := Label.new()
	note.text = "Пороги 25/50/75/100%% · claim на сервере"
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	_list.add_child(note)

func _build_shop(g: Dictionary) -> void:
	var shop: Dictionary = g.get("shop", {})
	var head := Label.new()
	head.text = ContentPackageLoader.tr_key("guild.shop", "Склад знаков")
	head.add_theme_font_size_override("font_size", 26)
	head.add_theme_color_override("font_color", LunexColors.GOLD)
	_list.add_child(head)
	var meta := Label.new()
	meta.text = "Валюта: %s · реальные деньги: выкл." % str(shop.get("currency_id", "guild_token"))
	meta.add_theme_font_size_override("font_size", 18)
	meta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	_list.add_child(meta)
	for o in shop.get("offers", []):
		var p := _panel()
		_list.add_child(p)
		var content: VBoxContainer = p.get_node("Pad/Content")
		var title := Label.new()
		title.text = str(o.get("sku", ""))
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", LunexColors.GOLD)
		content.add_child(title)
		var parts: PackedStringArray = []
		for r in o.get("grants", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		var lim: Variant = o.get("weekly_limit", o.get("lifetime_limit", "—"))
		var info := Label.new()
		info.text = "%s · цена %s жетонов · лимит %s" % [
			", ".join(parts),
			str(o.get("price_guild_token", 0)),
			str(lim),
		]
		info.add_theme_font_size_override("font_size", 16)
		info.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(info)
		var buy := Button.new()
		buy.text = "Обменять (демо)"
		buy.custom_minimum_size = Vector2(0, 48)
		buy.theme_type_variation = &"GameButton"
		buy.pressed.connect(func():
			ModalManager.push_rewards("Гильдейский магазин (демо)", parts)
		)
		content.add_child(buy)
