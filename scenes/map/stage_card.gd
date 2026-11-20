extends Control
## MAP-02: компактная карточка этапа (STAGE-UI-001 A)

var _payload: Dictionary = {}
var _stage: Dictionary = {}

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var sid: String = str(_payload.get("stage_id", DemoData.campaign_progress["current_stage"]))
	_stage = DemoData.get_stage(sid)
	if _stage.is_empty():
		NotificationManager.error("Этап не найден")
		ScreenRouter.handle_back()
		return
	var box := $Safe/Card/VBox
	box.get_node("Name").text = str(_stage.name)
	box.get_node("Power").text = "Рекомендуемая сила: %d" % int(_stage.power)
	box.get_node("Rewards").text = "Награды: %s" % ", ".join(PackedStringArray(_stage.rewards))
	box.get_node("Meta").text = "Локальные демо-данные · не серверный прогресс"
	box.get_node("PrepBtn").pressed.connect(_to_prep)
	box.get_node("BackBtn").pressed.connect(func(): ScreenRouter.handle_back())
	var squad_p := DemoData.squad_power()
	var rec := int(_stage.power)
	var cmp := box.get_node("Compare")
	if squad_p >= rec:
		cmp.text = "Сила отряда %d ≥ %d — преимущество" % [squad_p, rec]
		cmp.add_theme_color_override("font_color", LunexColors.EMERALD)
	else:
		cmp.text = "Сила отряда %d < %d — будет сложно" % [squad_p, rec]
		cmp.add_theme_color_override("font_color", LunexColors.AMBER)

func _to_prep() -> void:
	UIStateManager.set_combat_context({
		"mode": "campaign",
		"stage_id": _stage.id,
		"return_route": "MAP-01",
	})
	ScreenRouter.go("COMBAT-01", {"stage_id": _stage.id, "mode": "campaign"})
