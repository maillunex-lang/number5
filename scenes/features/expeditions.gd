extends Control
## EXPEDITIONS: chrome в .tscn; ListHost — миссии из liveops.json (DEMO).

var _payload: Dictionary = {}
var _nav_bound: bool = false

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _subtitle: Label = $Safe/Scroll/VBox/Subtitle
@onready var _meta: Label = $Safe/Scroll/VBox/MetaLabel
@onready var _list: VBoxContainer = $Safe/Scroll/VBox/ListHost
@onready var _inv: Button = $Safe/Scroll/VBox/InventoryBtn
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
	_inv.pressed.connect(func(): ScreenRouter.go("WORKSHOP"))
	_back.pressed.connect(func(): ScreenRouter.handle_back())

func _pack() -> Dictionary:
	return ContentPackageLoader.liveops.get("expeditions", {})

func _rebuild() -> void:
	var pack := _pack()
	_title.text = ContentPackageLoader.tr_key("expeditions.title", "Экспедиции")
	_subtitle.text = "%s · DEMO" % ContentPackageLoader.package_label()
	_meta.text = "Открытие %s · слоты %s (+moon %s) · доска %s" % [
		str(pack.get("unlock_stage", "CH01-10")),
		str(pack.get("base_slots", 2)),
		str(pack.get("sub_moon_extra_slot", 1)),
		str(pack.get("board_size", 6)),
	]
	for c in _list.get_children():
		c.queue_free()
	var panel_scene: PackedScene = load("res://scenes/ui/components/game_panel.tscn")
	var missions: Array = pack.get("missions", [])
	var board_n := mini(int(pack.get("board_size", 6)), missions.size())
	for i in board_n:
		var m: Dictionary = missions[i]
		var p: GamePanel = panel_scene.instantiate()
		p.panel_kind = "GamePanel"
		_list.add_child(p)
		var content: VBoxContainer = p.get_node("Pad/Content")
		var head := Label.new()
		head.text = "%s · %s" % [str(m.get("id", "")), str(m.get("name", ""))]
		head.add_theme_font_size_override("font_size", 22)
		head.add_theme_color_override("font_color", LunexColors.GOLD)
		content.add_child(head)
		var meta := Label.new()
		meta.text = "гл.%s · %s · %sс · сила ≥%s · %s" % [
			str(m.get("chapter", "")),
			str(m.get("tier", "")),
			str(m.get("duration_sec", 0)),
			str(m.get("min_power", 0)),
			str(m.get("faction_id", "")),
		]
		meta.add_theme_font_size_override("font_size", 16)
		meta.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(meta)
		var parts: PackedStringArray = []
		for r in m.get("rewards_success", []):
			parts.append("%s×%s" % [str(r.get("resource_id", "")), str(r.get("amount", 0))])
		var rewards := Label.new()
		rewards.text = ", ".join(parts)
		rewards.add_theme_font_size_override("font_size", 18)
		content.add_child(rewards)
		var go := Button.new()
		go.text = "Отправить (демо)"
		go.custom_minimum_size = Vector2(0, 56)
		go.theme_type_variation = &"GoldButton"
		go.pressed.connect(func():
			ModalManager.push_rewards("Экспедиция (демо)", parts if parts.size() > 0 else PackedStringArray(["Ожидание…"]))
		)
		content.add_child(go)

	if board_n == 0:
		var empty := Label.new()
		empty.text = "Нет миссий в пакете"
		empty.add_theme_font_size_override("font_size", 20)
		empty.add_theme_color_override("font_color", LunexColors.TEXT_MUTED)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
