extends Control
## SOCIAL-01: chrome в .tscn; маршруты чат/друзья/почта/рейтинги в DynamicHost.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

const ROUTES := [
	{"label": "Чаты", "route": "SOCIAL-02"},
	{"label": "Друзья", "route": "SOCIAL-03"},
	{"label": "Почта", "route": "SOCIAL-04"},
	{"label": "Рейтинги", "route": "RANK-01"},
]

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_title.text = str(_payload.get("title_override", "Социальный центр"))
	for c in _host.get_children():
		c.queue_free()
	var panel_scene: PackedScene = load("res://scenes/ui/components/game_panel.tscn")
	var panel: GamePanel = panel_scene.instantiate()
	panel.panel_kind = "GamePanel"
	_host.add_child(panel)
	var content: VBoxContainer = panel.get_node("Pad/Content")
	var head := Label.new()
	head.text = "Разделы"
	head.add_theme_font_size_override("font_size", 28)
	content.add_child(head)
	for item in ROUTES:
		var b := Button.new()
		b.text = str(item["label"])
		b.custom_minimum_size = Vector2(0, 56)
		b.theme_type_variation = &"GameButton"
		var route: String = str(item["route"])
		b.pressed.connect(func(): ScreenRouter.go(route))
		content.add_child(b)
