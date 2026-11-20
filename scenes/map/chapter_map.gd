extends Control
## MAP-01: разветвлённая карта главы. Список — StageListItem template.

var _payload: Dictionary = {}
@onready var _list: VBoxContainer = $Safe/Col/Scroll/List
@onready var _title: Label = $Safe/Col/Header/Title
@onready var _subtitle: Label = $Safe/Col/Header/Subtitle

const STAGE_ITEM := "res://scenes/ui/components/stage_list_item.tscn"

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
	_subtitle.text = "%s · основной путь · доп. · секреты" % region
	$Safe/Col/Header/ContinueBtn.pressed.connect(_continue)
	$Safe/Col/Header/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_rebuild()

func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var region := str(_payload.get("region_id", DemoData.campaign_progress.get("chapter_id", "CH01")))
	var stages: Array = DemoData.campaign_progress["stages"]
	var item_scene: PackedScene = load(STAGE_ITEM)
	for s_variant in stages:
		var s: Dictionary = s_variant
		var cid := str(s.get("chapter_id", ""))
		if cid != "" and cid != region and not str(s.get("id", "")).begins_with(region):
			continue
		var item: StageListItem = item_scene.instantiate()
		item.set_stage(s)
		var sid: String = str(s.id)
		var state: String = str(s.state)
		item.open_pressed.connect(func(id):
			if state == "locked":
				ModalManager.push_locked(str(s.name), str(s.get("reveal_hint", "Пройдите предыдущие этапы")))
				return
			ScreenRouter.go("MAP-02", {"stage_id": id if id != "" else sid})
		)
		item.fight_pressed.connect(func(id):
			ScreenRouter.go("MAP-02", {"stage_id": id if id != "" else sid})
		)
		_list.add_child(item)

func _continue() -> void:
	var cur: String = DemoData.campaign_progress["current_stage"]
	ScreenRouter.go("MAP-02", {"stage_id": cur})
