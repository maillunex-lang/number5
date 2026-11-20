extends Control
## SOCIAL-04: игровая почта из mail.json (DEMO).

var _payload: Dictionary = {}
var _filter: String = "all"

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_rebuild()

func _pack() -> Dictionary:
	return ContentPackageLoader.mail_pack

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var pack := _pack()
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("mail.title", "Почта")))
	root.add_child(UIFactory.muted("%s · %s" % [
		ContentPackageLoader.package_label(),
		str(pack.get("disclaimer", ContentPackageLoader.tr_key("meta.demo", "DEMO"))),
	], 18))
	root.add_child(UIFactory.muted("Не переписка игроков · чтение ≠ claim · DEMO", 16))

	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["all", "Все"], ["reward", "Награды"], ["system", "Система"]]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(140, 44)
		var key: String = t[0]
		b.pressed.connect(func():
			_filter = key
			_rebuild()
		)
		tabs.add_child(b)

	var inbox: Array = pack.get("demo_inbox", [])
	var shown := 0
	for m_raw in inbox:
		var m: Dictionary = m_raw
		var cat := str(m.get("category", ""))
		if _filter == "reward" and cat not in ["reward", "daily_rollover", "calendar_rollover", "compensation", "guild", "season"]:
			continue
		if _filter == "system" and cat != "system":
			continue
		shown += 1
		var p := UIFactory.panel()
		var v := UIFactory.vbox(4)
		p.add_child(v)
		var mark := "●" if str(m.get("status", "")) == "unread" else "○"
		v.add_child(UIFactory.label("%s [%s] %s" % [mark, cat, str(m.get("subject", ""))], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted(str(m.get("body", "")), 16))
		var atts: Array = m.get("attachments", [])
		if atts.size() > 0:
			var parts: PackedStringArray = []
			for a in atts:
				parts.append("%s×%s" % [str(a.get("resource_id", "")), str(a.get("amount", 0))])
			v.add_child(UIFactory.label(", ".join(parts), 18))
			var claim := UIFactory.gold_button("Забрать (демо)")
			claim.pressed.connect(func():
				ModalManager.push_rewards("Почта (демо)", parts)
			)
			v.add_child(claim)
		else:
			v.add_child(UIFactory.muted("Без вложений · TTL %s дн." % str(m.get("expires_in_days", 30)), 16))
		root.add_child(p)

	if shown == 0:
		root.add_child(UIFactory.muted("Пусто", 20))

	var claim_all := UIFactory.fantasy_button("Забрать всё")
	claim_all.pressed.connect(func():
		var parts: PackedStringArray = []
		for m_raw in inbox:
			var m: Dictionary = m_raw
			for a in m.get("attachments", []):
				parts.append("%s×%s" % [str(a.get("resource_id", "")), str(a.get("amount", 0))])
		if parts.is_empty():
			ModalManager.push_info("Почта", "Нет доступных вложений (демо)")
		else:
			ModalManager.push_rewards("Забрать всё (демо)", parts)
	)
	root.add_child(claim_all)

	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
