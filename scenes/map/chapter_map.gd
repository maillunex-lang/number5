extends Control
## MAP-01: разветвлённая карта главы

var _payload: Dictionary = {}
@onready var _list: VBoxContainer = $Safe/Col/Scroll/List
@onready var _title: Label = $Safe/Col/Header/Title

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var region := str(_payload.get("region_id", DemoData.campaign_progress.get("chapter_id", "CH01")))
	var chapters: Array = DemoData.campaign_progress.get("chapters", [])
	var title := str(DemoData.campaign_progress.get("chapter_name", "Глава"))
	for ch in chapters:
		if str(ch.get("id", "")) == region:
			title = str(ch.get("name", title))
			break
	_title.text = title
	$Safe/Col/Header/ContinueBtn.pressed.connect(_continue)
	$Safe/Col/Header/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_rebuild()

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var region := str(_payload.get("region_id", DemoData.campaign_progress.get("chapter_id", "CH01")))
	_list.add_child(UIFactory.muted("%s · основной путь · доп. · секреты" % region, 22))
	var stages: Array = DemoData.campaign_progress["stages"]
	for s_variant in stages:
		var s: Dictionary = s_variant
		var cid := str(s.get("chapter_id", ""))
		if cid != "" and cid != region and not str(s.get("id", "")).begins_with(region):
			continue
		var card: PanelContainer = _stage_row(s)
		_list.add_child(card)

func _stage_row(s: Dictionary) -> PanelContainer:
	var p := UIFactory.panel()
	var v := UIFactory.vbox(8)
	p.add_child(v)
	var type_map := {"main": "Основной", "side": "Доп.", "secret": "Секрет"}
	var type_key := str(s.type)
	var type_label: String = str(type_map.get(type_key, type_key))
	var state: String = str(s.state)
	var title: String = "%s · %s" % [type_label, str(s.name)]
	if state == "locked":
		title = "🔒 " + title
	elif state == "cleared":
		title = "✓ " + title
	v.add_child(UIFactory.label(title, 28, LunexColors.GOLD if state == "available" else LunexColors.TEXT_SECONDARY, true))
	v.add_child(UIFactory.muted("Сила: %d · Награды: %s" % [int(s.power), ", ".join(PackedStringArray(s.rewards))], 22))
	if state == "locked" and s.get("reveal_hint", "") != "":
		v.add_child(UIFactory.muted(str(s.reveal_hint), 20))
	var row := UIFactory.hbox(10)
	v.add_child(row)
	var open := UIFactory.fantasy_button("Карточка", 52)
	open.disabled = state == "locked" and s.type == "secret" and state != "available"
	if state == "locked" and s.type != "secret":
		open.disabled = true
	var sid: String = s.id
	open.pressed.connect(func():
		if state == "locked":
			ModalManager.push_locked(str(s.name), str(s.get("reveal_hint", "Пройдите предыдущие этапы")))
			return
		ScreenRouter.go("MAP-02", {"stage_id": sid})
	)
	row.add_child(open)
	if state == "available":
		var go := UIFactory.gold_button("В бой", 52)
		go.pressed.connect(func(): ScreenRouter.go("MAP-02", {"stage_id": sid}))
		row.add_child(go)
	return p

func _continue() -> void:
	var cur: String = DemoData.campaign_progress["current_stage"]
	ScreenRouter.go("MAP-02", {"stage_id": cur})
