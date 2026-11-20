extends Control
## HUB-04: live events + календарь входа + сюжет дня (DEMO).
## Порядок контента: mail → calendars → profile → achievements → stories → events.

var _payload: Dictionary = {}
var _tab: String = "events"

func setup(payload: Dictionary = {}) -> void:
	_payload = payload
	if _payload.has("tab"):
		_tab = str(_payload["tab"])

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("live_events.title", "События")))
	root.add_child(UIFactory.muted("%s · %s" % [
		ContentPackageLoader.package_label(),
		ContentPackageLoader.tr_key("meta.demo", "DEMO"),
	], 18))

	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["events", "Ивенты"], ["calendar", "Календарь"], ["story", "Сюжет дня"]]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(150, 44)
		var key: String = t[0]
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)

	match _tab:
		"calendar":
			_build_calendar(root)
		"story":
			_build_story(root)
		_:
			_build_events(root)

	var mail := UIFactory.fantasy_button("Почта")
	mail.pressed.connect(func(): ScreenRouter.go("SOCIAL-04"))
	root.add_child(mail)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _build_events(root: VBoxContainer) -> void:
	var pack: Dictionary = ContentPackageLoader.live_events
	root.add_child(UIFactory.muted(str(pack.get("disclaimer", "")), 16))
	var demo: Dictionary = pack.get("demo", {}).get("active_instance", {})
	if not demo.is_empty():
		root.add_child(UIFactory.label("Активно: %s · жетоны %s" % [
			str(demo.get("definition_id", "")),
			str(demo.get("tokens", 0)),
		], 24, LunexColors.GOLD))
		root.add_child(UIFactory.muted("до %s · обмен до %s" % [
			str(demo.get("ends_at", "")),
			str(demo.get("claim_deadline", "")),
		], 16))
	for e in pack.get("events", []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [str(e.get("id", "")), str(e.get("name", ""))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted("%s · %s дн. · unlock %s" % [
			str(e.get("format", "")),
			str(e.get("duration_days", 0)),
			str(e.get("unlock_stage", "")),
		], 16))
		root.add_child(p)
	root.add_child(UIFactory.label("Магазин event_token", 24, LunexColors.GOLD))
	for o in pack.get("shop", {}).get("offers", []):
		var parts: PackedStringArray = []
		for g in o.get("grants", []):
			parts.append("%s×%s" % [str(g.get("resource_id", "")), str(g.get("amount", 0))])
		var row := UIFactory.panel()
		var vv := UIFactory.vbox(4)
		row.add_child(vv)
		vv.add_child(UIFactory.label("%s · %s жетонов · лимит %s" % [
			str(o.get("sku", "")),
			str(o.get("price_event_token", 0)),
			str(o.get("limit_per_event", 0)),
		], 18))
		vv.add_child(UIFactory.muted(", ".join(parts), 16))
		var buy := UIFactory.fantasy_button("Обменять (демо)")
		buy.pressed.connect(func():
			ModalManager.push_rewards("Магазин события (демо)", parts)
		)
		vv.add_child(buy)
		root.add_child(row)

func _build_calendar(root: VBoxContainer) -> void:
	var pack: Dictionary = ContentPackageLoader.login_calendars
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("calendar.title", "Календарь входа")))
	root.add_child(UIFactory.muted(str(pack.get("disclaimer", "")), 16))
	root.add_child(UIFactory.muted("Открытие %s · сброс %s · без автоclaim" % [
		str(pack.get("unlock_stage", "")),
		str(pack.get("daily_reset", "")),
	], 16))
	var demo: Dictionary = pack.get("demo", {})
	for cal in pack.get("calendars", []):
		var cid := str(cal.get("id", ""))
		var st: Dictionary = demo.get(cid, {})
		var p := UIFactory.panel()
		var v := UIFactory.vbox(6)
		p.add_child(v)
		v.add_child(UIFactory.label("%s · %s" % [cid, str(cal.get("name", ""))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted("день %s / %s · цикл %s · %s" % [
			str(st.get("next_day", 1)),
			str(cal.get("days", 0)),
			str(st.get("cycle_no", 1)),
			str(st.get("status", "locked")),
		], 16))
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
			v.add_child(UIFactory.label("Сегодня: " + ", ".join(parts), 18))
			var claim := UIFactory.gold_button("Забрать (демо)")
			claim.pressed.connect(func():
				ModalManager.push_rewards("Календарь %s (демо)" % cid, parts)
			)
			v.add_child(claim)
		root.add_child(p)
	root.add_child(UIFactory.muted("Незабранное при сбросе → MAIL_LOGIN_UNCLAIMED (7 дн.)", 16))

func _build_story(root: VBoxContainer) -> void:
	var pack: Dictionary = ContentPackageLoader.daily_stories
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("daily_story.title", "Событие дня")))
	root.add_child(UIFactory.muted(str(pack.get("disclaimer", "")), 16))
	var demo: Dictionary = pack.get("demo", {})
	var sid := str(demo.get("story_id", ""))
	var story: Dictionary = {}
	for s in pack.get("stories", []):
		if str(s.get("id", "")) == sid:
			story = s
			break
	if story.is_empty() and (pack.get("stories", []) as Array).size() > 0:
		story = pack["stories"][0]
	root.add_child(UIFactory.label("%s · %s" % [str(story.get("id", "")), str(story.get("title", ""))], 26, LunexColors.GOLD))
	root.add_child(UIFactory.muted("Глава %s · %s · unlock %s" % [
		str(story.get("chapter", "")),
		str(story.get("territory", "")),
		str(story.get("unlock_stage", "")),
	], 16))
	for line in story.get("intro_lines", []):
		root.add_child(UIFactory.label(str(line), 20))
	for ch in story.get("choices", []):
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		var parts: PackedStringArray = []
		for r in ch.get("rewards", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		v.add_child(UIFactory.label("%s · %s" % [str(ch.get("id", "")), str(ch.get("label", ""))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted(", ".join(parts) + (" · бой" if bool(ch.get("battle", false)) else ""), 16))
		var go := UIFactory.gold_button("Выбрать (демо)")
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
		root.add_child(p)
	root.add_child(UIFactory.muted("Пул 30 карточек · анти-повтор 7 дней · не меняет канон", 16))
