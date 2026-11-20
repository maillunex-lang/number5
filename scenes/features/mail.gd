extends Control
## SOCIAL-04: почта. Online → CORE-01 /mail; иначе demo_inbox.

var _payload: Dictionary = {}
var _filter: String = "all"
var _busy: bool = false
var _messages: Array = []
var _from_server: bool = false

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	await _load_inbox()
	_rebuild()

func _pack() -> Dictionary:
	return ContentPackageLoader.mail_pack

func _load_inbox() -> void:
	_from_server = false
	_messages = []
	if ApiClient.online:
		var res := await ApiClient.mail_list()
		if res.get("ok", false):
			var data: Dictionary = res.get("data", {})
			_messages = data.get("messages", [])
			_from_server = true
			return
	for m_raw in _pack().get("demo_inbox", []):
		_messages.append(m_raw)

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var pack := _pack()
	var mode := "ONLINE" if _from_server else "DEMO"
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("mail.title", "Почта")))
	root.add_child(UIFactory.muted("%s · %s · %s" % [
		ContentPackageLoader.package_label(),
		mode,
		str(pack.get("disclaimer", ContentPackageLoader.tr_key("meta.demo", "DEMO"))),
	], 18))
	root.add_child(UIFactory.muted("Не переписка игроков · чтение ≠ claim", 16))

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

	var shown := 0
	for m_raw in _messages:
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
		var status := str(m.get("status", "unread"))
		var subject := str(m.get("subject", m.get("title", "")))
		var mark := "●" if status == "unread" else ("✓" if status == "claimed" else "○")
		v.add_child(UIFactory.label("%s [%s] %s" % [mark, cat, subject], 22, LunexColors.GOLD))
		v.add_child(UIFactory.muted(str(m.get("body", "")), 16))
		var atts: Array = m.get("attachments", [])
		if atts.size() > 0:
			var parts: PackedStringArray = []
			for a in atts:
				parts.append("%s×%s" % [str(a.get("resource_id", "")), str(a.get("amount", 0))])
			v.add_child(UIFactory.label(", ".join(parts), 18))
			if status != "claimed":
				var mid := str(m.get("id", ""))
				var claim := UIFactory.gold_button("Забрать")
				claim.pressed.connect(func(): _claim_one(mid, parts))
				v.add_child(claim)
			else:
				v.add_child(UIFactory.muted("Уже получено", 16))
		else:
			v.add_child(UIFactory.muted("Без вложений", 16))
		root.add_child(p)

	if shown == 0:
		root.add_child(UIFactory.muted("Пусто", 20))

	var claim_all := UIFactory.fantasy_button("Забрать всё")
	claim_all.pressed.connect(_claim_all)
	root.add_child(claim_all)

	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _claim_one(mail_id: String, parts: PackedStringArray) -> void:
	if _busy:
		return
	_busy = true
	if _from_server and mail_id != "":
		var res := await ApiClient.mail_claim(mail_id)
		if res.get("ok", false):
			var rewards: Dictionary = res.get("data", {}).get("rewards", {})
			var lines: Array = []
			for k in rewards.keys():
				lines.append("%s ×%s" % [str(k), str(rewards[k])])
			if lines.is_empty():
				lines.append_array(parts)
			await ApiClient.sync_wallet()
			await _load_inbox()
			ModalManager.push_rewards("Почта (ONLINE)", lines)
			_rebuild()
			_busy = false
			return
		NotificationManager.warn("Claim online не удался · демо")
	ModalManager.push_rewards("Почта (DEMO)", parts)
	_busy = false

func _claim_all() -> void:
	if _busy:
		return
	_busy = true
	if _from_server:
		var res := await ApiClient.mail_claim_all()
		if res.get("ok", false):
			var claimed: Array = res.get("data", {}).get("claimed", [])
			var lines: Array = []
			for c in claimed:
				if typeof(c) != TYPE_DICTIONARY:
					continue
				var rewards: Dictionary = c.get("rewards", {})
				for k in rewards.keys():
					lines.append("%s ×%s" % [str(k), str(rewards[k])])
			if lines.is_empty():
				lines.append("Нечего забирать")
			await ApiClient.sync_wallet()
			await _load_inbox()
			ModalManager.push_rewards("Забрать всё (ONLINE)", lines)
			_rebuild()
			_busy = false
			return
	var parts: PackedStringArray = []
	for m_raw in _messages:
		var m: Dictionary = m_raw
		for a in m.get("attachments", []):
			parts.append("%s×%s" % [str(a.get("resource_id", "")), str(a.get("amount", 0))])
	if parts.is_empty():
		ModalManager.push_info("Почта", "Нет доступных вложений")
	else:
		ModalManager.push_rewards("Забрать всё (DEMO)", parts)
	_busy = false
