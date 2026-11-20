extends Control
## SOCIAL-04: chrome в .tscn; ListHost — MailItem; claim API без изменений.

var _payload: Dictionary = {}
var _filter: String = "all"
var _busy: bool = false
var _messages: Array = []
var _from_server: bool = false
var _nav_bound: bool = false

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _subtitle: Label = $Safe/Scroll/VBox/Subtitle
@onready var _tabs: HBoxContainer = $Safe/Scroll/VBox/TabsHost
@onready var _list: VBoxContainer = $Safe/Scroll/VBox/ListHost
@onready var _claim_all: Button = $Safe/Scroll/VBox/ClaimAllBtn
@onready var _back: Button = $Safe/Scroll/VBox/BackBtn

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_bind_nav()
	await _load_inbox()
	_rebuild()

func _bind_nav() -> void:
	if _nav_bound:
		return
	_nav_bound = true
	_claim_all.pressed.connect(_claim_all_pressed)
	_back.pressed.connect(func(): ScreenRouter.handle_back())

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
	var pack := _pack()
	var mode := "ONLINE" if _from_server else "DEMO"
	_title.text = ContentPackageLoader.tr_key("mail.title", "Почта")
	_subtitle.text = "%s · %s · %s" % [
		ContentPackageLoader.package_label(),
		mode,
		str(pack.get("disclaimer", ContentPackageLoader.tr_key("meta.demo", "DEMO"))),
	]
	for c in _tabs.get_children():
		c.queue_free()
	for t in [["all", "Все"], ["reward", "Награды"], ["system", "Система"]]:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(140, 44)
		b.theme_type_variation = &"GameButton"
		var key: String = t[0]
		b.pressed.connect(func():
			_filter = key
			_rebuild()
		)
		_tabs.add_child(b)

	for c in _list.get_children():
		c.queue_free()
	var shown := 0
	var item_scene: PackedScene = load("res://scenes/ui/components/mail_item.tscn")
	for m_raw in _messages:
		var m: Dictionary = m_raw
		var cat := str(m.get("category", ""))
		if _filter == "reward" and cat not in ["reward", "daily_rollover", "calendar_rollover", "compensation", "guild", "season"]:
			continue
		if _filter == "system" and cat != "system":
			continue
		shown += 1
		var item: MailItem = item_scene.instantiate()
		item.set_mail(m)
		var atts: Array = m.get("attachments", [])
		var parts: PackedStringArray = []
		for a in atts:
			parts.append("%s×%s" % [str(a.get("resource_id", "")), str(a.get("amount", 0))])
		var mid := str(m.get("id", ""))
		item.claim_pressed.connect(func(_id): _claim_one(mid, parts))
		_list.add_child(item)

	if shown == 0:
		var empty := Label.new()
		empty.text = "Пусто"
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)

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

func _claim_all_pressed() -> void:
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
