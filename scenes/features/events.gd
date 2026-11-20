extends Control
## HUB-04: chrome в .tscn; ListHost — ивенты / календарь / сюжет дня (DEMO).
## Порядок контента: mail → calendars → profile → achievements → stories → events.

var _payload: Dictionary = {}
var _tab: String = "events"
var _nav_bound: bool = false

@onready var _title: Label = $Safe/Col/Header/Title
@onready var _subtitle: Label = $Safe/Col/Header/Subtitle
@onready var _tabs: HBoxContainer = $Safe/Col/Header/TabsHost
@onready var _list: VBoxContainer = $Safe/Col/Scroll/ListHost
@onready var _mail: Button = $Safe/Col/Footer/MailBtn
@onready var _back: Button = $Safe/Col/Footer/BackBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload
	if _payload.has("tab"):
		_tab = str(_payload["tab"])

func _ready() -> void:
	_bind_nav()
	_rebuild()

func _bind_nav() -> void:
	if _nav_bound:
		return
	_nav_bound = true
	_mail.pressed.connect(func(): ScreenRouter.go("SOCIAL-04"))
	_back.pressed.connect(func(): ScreenRouter.handle_back())

func _panel() -> GamePanel:
	var panel_scene: PackedScene = load("res://scenes/ui/components/game_panel.tscn")
	var p: GamePanel = panel_scene.instantiate()
	p.panel_kind = "GamePanel"
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p

func _rebuild() -> void:
	_title.text = ContentPackageLoader.tr_key("live_events.title", "События")
	_subtitle.text = "%s · %s" % [
		ContentPackageLoader.package_label(),
		ContentPackageLoader.tr_key("meta.demo", "DEMO"),
	]
	for c in _tabs.get_children():
		c.queue_free()
	for t in [["events", "Ивенты"], ["calendar", "Календарь"], ["story", "Сюжет дня"]]:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(150, 44)
		b.theme_type_variation = &"GameButton"
		var key: String = t[0]
		if key == _tab:
			b.modulate = Color(1.2, 1.1, 0.9)
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		_tabs.add_child(b)

	for c in _list.get_children():
		c.queue_free()
	match _tab:
		"calendar":
			_build_calendar()
		"story":
			_build_story()
		_:
			_build_events()

func _build_events() -> void:
	var pack: Dictionary = ContentPackageLoader.live_events
	var disc := Label.new()
	disc.text = str(pack.get("disclaimer", ""))
	disc.add_theme_font_size_override("font_size", 16)
	disc.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	disc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(disc)
	var demo: Dictionary = pack.get("demo", {}).get("active_instance", {})
	if not demo.is_empty():
		var active := Label.new()
		active.text = "Активно: %s · жетоны %s" % [
			str(demo.get("definition_id", "")),
			str(demo.get("tokens", 0)),
		]
		active.add_theme_font_size_override("font_size", 24)
		active.add_theme_color_override("font_color", LunexColors.GOLD)
		active.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list.add_child(active)
		var until := Label.new()
		until.text = "до %s · обмен до %s" % [
			str(demo.get("ends_at", "")),
			str(demo.get("claim_deadline", "")),
		]
		until.add_theme_font_size_override("font_size", 16)
		until.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		until.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list.add_child(until)
	for e in pack.get("events", []):
		var p := _panel()
		_list.add_child(p)
		var content: VBoxContainer = p.get_node("Pad/Content")
		var head := Label.new()
		head.text = "%s · %s" % [str(e.get("id", "")), str(e.get("name", ""))]
		head.add_theme_font_size_override("font_size", 22)
		head.add_theme_color_override("font_color", LunexColors.GOLD)
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(head)
		var meta := Label.new()
		meta.text = "%s · %s дн. · unlock %s" % [
			str(e.get("format", "")),
			str(e.get("duration_days", 0)),
			str(e.get("unlock_stage", "")),
		]
		meta.add_theme_font_size_override("font_size", 16)
		meta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(meta)
	var shop_h := Label.new()
	shop_h.text = "Магазин event_token"
	shop_h.add_theme_font_size_override("font_size", 24)
	shop_h.add_theme_color_override("font_color", LunexColors.GOLD)
	shop_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(shop_h)
	for o in pack.get("shop", {}).get("offers", []):
		var parts: PackedStringArray = []
		for g in o.get("grants", []):
			parts.append("%s×%s" % [str(g.get("resource_id", "")), str(g.get("amount", 0))])
		var row := _panel()
		_list.add_child(row)
		var vv: VBoxContainer = row.get_node("Pad/Content")
		var sku := Label.new()
		sku.text = "%s · %s жетонов · лимит %s" % [
			str(o.get("sku", "")),
			str(o.get("price_event_token", 0)),
			str(o.get("limit_per_event", 0)),
		]
		sku.add_theme_font_size_override("font_size", 18)
		sku.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv.add_child(sku)
		var grants := Label.new()
		grants.text = ", ".join(parts)
		grants.add_theme_font_size_override("font_size", 16)
		grants.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		grants.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vv.add_child(grants)
		var buy := Button.new()
		buy.text = "Обменять (демо)"
		buy.custom_minimum_size = Vector2(0, 48)
		buy.theme_type_variation = &"GameButton"
		buy.pressed.connect(func():
			ModalManager.push_rewards("Магазин события (демо)", parts)
		)
		vv.add_child(buy)

func _build_calendar() -> void:
	var pack: Dictionary = ContentPackageLoader.login_calendars
	var head := Label.new()
	head.text = ContentPackageLoader.tr_key("calendar.title", "Календарь входа")
	head.add_theme_font_size_override("font_size", 28)
	head.add_theme_color_override("font_color", LunexColors.GOLD)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(head)
	var disc := Label.new()
	disc.text = str(pack.get("disclaimer", ""))
	disc.add_theme_font_size_override("font_size", 16)
	disc.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	disc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(disc)
	var unlock := Label.new()
	unlock.text = "Открытие %s · сброс %s · без автоclaim" % [
		str(pack.get("unlock_stage", "")),
		str(pack.get("daily_reset", "")),
	]
	unlock.add_theme_font_size_override("font_size", 16)
	unlock.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	unlock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(unlock)
	var demo: Dictionary = pack.get("demo", {})
	for cal in pack.get("calendars", []):
		var cid := str(cal.get("id", ""))
		var st: Dictionary = demo.get(cid, {})
		var p := _panel()
		_list.add_child(p)
		var v: VBoxContainer = p.get_node("Pad/Content")
		var title := Label.new()
		title.text = "%s · %s" % [cid, str(cal.get("name", ""))]
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", LunexColors.GOLD)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(title)
		var meta := Label.new()
		meta.text = "день %s / %s · цикл %s · %s" % [
			str(st.get("next_day", 1)),
			str(cal.get("days", 0)),
			str(st.get("cycle_no", 1)),
			str(st.get("status", "locked")),
		]
		meta.add_theme_font_size_override("font_size", 16)
		meta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(meta)
		var day_no := int(st.get("next_day", 1))
		var entry: Dictionary = {}
		for e in cal.get("entries", []):
			if int(e.get("day", 0)) == day_no:
				entry = e
				break
		var parts: PackedStringArray = []
		for r in entry.get("rewards", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		if parts.size() > 0:
			var today := Label.new()
			today.text = "Сегодня: " + ", ".join(parts)
			today.add_theme_font_size_override("font_size", 18)
			today.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(today)
			var claim := Button.new()
			claim.text = "Забрать (демо)"
			claim.custom_minimum_size = Vector2(0, 56)
			claim.theme_type_variation = &"GoldButton"
			claim.pressed.connect(func():
				ModalManager.push_rewards("Календарь %s (демо)" % cid, parts)
			)
			v.add_child(claim)
	var note := Label.new()
	note.text = "Незабранное при сбросе → MAIL_LOGIN_UNCLAIMED (7 дн.)"
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(note)

func _build_story() -> void:
	var pack: Dictionary = ContentPackageLoader.daily_stories
	var head := Label.new()
	head.text = ContentPackageLoader.tr_key("daily_story.title", "Событие дня")
	head.add_theme_font_size_override("font_size", 28)
	head.add_theme_color_override("font_color", LunexColors.GOLD)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(head)
	var disc := Label.new()
	disc.text = str(pack.get("disclaimer", ""))
	disc.add_theme_font_size_override("font_size", 16)
	disc.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	disc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(disc)
	var demo: Dictionary = pack.get("demo", {})
	var sid := str(demo.get("story_id", ""))
	var story: Dictionary = {}
	for s in pack.get("stories", []):
		if str(s.get("id", "")) == sid:
			story = s
			break
	if story.is_empty() and (pack.get("stories", []) as Array).size() > 0:
		story = pack["stories"][0]
	var stitle := Label.new()
	stitle.text = "%s · %s" % [str(story.get("id", "")), str(story.get("title", ""))]
	stitle.add_theme_font_size_override("font_size", 26)
	stitle.add_theme_color_override("font_color", LunexColors.GOLD)
	stitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(stitle)
	var meta := Label.new()
	meta.text = "Глава %s · %s · unlock %s" % [
		str(story.get("chapter", "")),
		str(story.get("territory", "")),
		str(story.get("unlock_stage", "")),
	]
	meta.add_theme_font_size_override("font_size", 16)
	meta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(meta)
	for line in story.get("intro_lines", []):
		var l := Label.new()
		l.text = str(line)
		l.add_theme_font_size_override("font_size", 20)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list.add_child(l)
	for ch in story.get("choices", []):
		var p := _panel()
		_list.add_child(p)
		var v: VBoxContainer = p.get_node("Pad/Content")
		var parts: PackedStringArray = []
		for r in ch.get("rewards", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		var clabel := Label.new()
		clabel.text = "%s · %s" % [str(ch.get("id", "")), str(ch.get("label", ""))]
		clabel.add_theme_font_size_override("font_size", 22)
		clabel.add_theme_color_override("font_color", LunexColors.GOLD)
		clabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(clabel)
		var cmeta := Label.new()
		cmeta.text = ", ".join(parts) + (" · бой" if bool(ch.get("battle", false)) else "")
		cmeta.add_theme_font_size_override("font_size", 16)
		cmeta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		cmeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(cmeta)
		var go := Button.new()
		go.text = "Выбрать (демо)"
		go.custom_minimum_size = Vector2(0, 56)
		go.theme_type_variation = &"GoldButton"
		var choice: Dictionary = ch
		go.pressed.connect(func():
			if bool(choice.get("battle", false)):
				UIStateManager.set_combat_context({"mode": "daily_story", "stage_id": str(story.get("id", "")), "return_route": "HUB-04"})
				ScreenRouter.go("COMBAT-01", {
					"mode": "daily_story",
					"stage_id": str(story.get("id", "")),
					"enemy_hint": str(choice.get("enemy_hint", "")),
				})
			else:
				ModalManager.push_rewards("Сюжет дня (демо)", parts)
		)
		v.add_child(go)
	var note := Label.new()
	note.text = "Пул 30 карточек · анти-повтор 7 дней · не меняет канон"
	note.add_theme_font_size_override("font_size", 16)
	note.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_child(note)
