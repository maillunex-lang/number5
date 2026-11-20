extends Control
## MAP-02: компактная карточка этапа. Chrome в .tscn; DialogHost — опциональный сюжет.

var _payload: Dictionary = {}
var _stage: Dictionary = {}

@onready var _box: VBoxContainer = $Safe/Card/Pad/VBox
@onready var _dialog_host: VBoxContainer = $Safe/Card/Pad/VBox/DialogHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var sid: String = str(_payload.get("stage_id", DemoData.campaign_progress["current_stage"]))
	_stage = DemoData.get_stage(sid)
	if _stage.is_empty():
		NotificationManager.error("Этап не найден")
		ScreenRouter.handle_back()
		return
	_box.get_node("Name").text = str(_stage.name)
	_box.get_node("Power").text = "Рекомендуемая сила: %d" % int(_stage.power)
	_box.get_node("Rewards").text = "Награды: %s" % ", ".join(PackedStringArray(_stage.rewards))
	_box.get_node("Meta").text = "Локальные демо-данные · не серверный прогресс"
	_box.get_node("PrepBtn").pressed.connect(_to_prep)
	_box.get_node("BackBtn").pressed.connect(func(): ScreenRouter.handle_back())
	var squad_p := DemoData.squad_power()
	var rec := int(_stage.power)
	var cmp := _box.get_node("Compare")
	if squad_p >= rec:
		cmp.text = "Сила отряда %d ≥ %d — преимущество" % [squad_p, rec]
		cmp.add_theme_color_override("font_color", LunexColors.EMERALD)
	else:
		cmp.text = "Сила отряда %d < %d — будет сложно" % [squad_p, rec]
		cmp.add_theme_color_override("font_color", LunexColors.AMBER)
	for c in _dialog_host.get_children():
		c.queue_free()
	var before := _dialog_for(str(_stage.id), "before")
	if not before.is_empty():
		var dlg := UIFactory.fantasy_button("Сюжет до боя")
		dlg.pressed.connect(func():
			ScreenRouter.go("DIALOG-01", {
				"dialog_id": str(before.get("id", "")),
				"stage_id": str(_stage.id),
				"timing": "before",
				"next_route": "MAP-02",
				"next_payload": {"stage_id": str(_stage.id)},
			})
		)
		_dialog_host.add_child(dlg)

func _dialog_for(stage_id: String, timing: String) -> Dictionary:
	for d in ContentPackageLoader.dialogs_pack.get("dialogs", []):
		if str(d.get("stage_id", "")) == stage_id and str(d.get("timing", "")) == timing:
			return d
	return {}

func _to_prep() -> void:
	var before := _dialog_for(str(_stage.id), "before")
	var combat_payload := {"stage_id": _stage.id, "mode": "campaign"}
	UIStateManager.set_combat_context({
		"mode": "campaign",
		"stage_id": _stage.id,
		"return_route": "MAP-01",
	})
	if not before.is_empty() and not bool(_payload.get("skip_dialog", false)):
		ScreenRouter.go("DIALOG-01", {
			"dialog_id": str(before.get("id", "")),
			"stage_id": str(_stage.id),
			"timing": "before",
			"next_route": "COMBAT-01",
			"next_payload": combat_payload,
		})
		return
	ScreenRouter.go("COMBAT-01", combat_payload)
