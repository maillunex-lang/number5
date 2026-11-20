extends Control
## HUB-03 quests: chrome в .tscn; ListHost — карточки заданий.

var _payload: Dictionary = {}
var _tab: String = "daily"
var _nav_bound: bool = false

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _subtitle: Label = $Safe/Scroll/VBox/Subtitle
@onready var _tabs: HBoxContainer = $Safe/Scroll/VBox/TabsHost
@onready var _list: VBoxContainer = $Safe/Scroll/VBox/ListHost
@onready var _exp: Button = $Safe/Scroll/VBox/ExpeditionsBtn
@onready var _claim: Button = $Safe/Scroll/VBox/ClaimBtn
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
	_exp.pressed.connect(func(): ScreenRouter.go("EXPEDITIONS"))
	_claim.pressed.connect(func():
		ModalManager.push_rewards("Задания", ["Золото ×400", "Опыт активности"])
		AppState.add_demo_rewards(400, 0)
		DemoData.quest_ready = 0
	)
	_back.pressed.connect(func(): ScreenRouter.handle_back())

func _rebuild() -> void:
	_title.text = "Журнал заданий"
	_subtitle.text = ContentPackageLoader.package_label()
	for c in _tabs.get_children():
		c.queue_free()
	for t in [["daily", "Ежедневные"], ["weekly", "Недельные"], ["story", "Сюжет"], ["special", "Особые"]]:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(0, 48)
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
	var panel_scene: PackedScene = load("res://scenes/ui/components/game_panel.tscn")
	var quests_doc: Dictionary = ContentPackageLoader.features.get("quests", {})
	var list: Array = quests_doc.get(_tab, [])
	for q_raw in list:
		var q: Dictionary = q_raw
		var p: GamePanel = panel_scene.instantiate()
		p.panel_kind = "GamePanel"
		_list.add_child(p)
		var content: VBoxContainer = p.get_node("Pad/Content")
		var head := Label.new()
		head.text = "%s · %s" % [str(q.get("title", "")), str(q.get("progress", ""))]
		head.add_theme_font_size_override("font_size", 24)
		content.add_child(head)
		var goto_route: String = str(q.get("goto", ""))
		if goto_route != "":
			var go := Button.new()
			go.text = "Перейти"
			go.custom_minimum_size = Vector2(0, 48)
			go.theme_type_variation = &"GameButton"
			go.pressed.connect(func(): ScreenRouter.go(goto_route))
			content.add_child(go)
