extends Control
## HUB-07 VIP: chrome в .tscn; DynamicHost — секции (без DemoScreenBuilder).

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _subtitle: Label = $Safe/Scroll/VBox/Subtitle
@onready var _status: Label = $Safe/Scroll/VBox/StatusLabel
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	var vip: Dictionary = ContentPackageLoader.features.get("vip", {})
	var level := int(vip.get("level", 0))
	var progress := int(vip.get("progress", 0))
	var next_at := int(vip.get("next", 100))
	_title.text = str(_payload.get("title_override", "VIP-центр"))
	_subtitle.text = "Зал привилегий"
	_status.text = "Статус: %s" % ContentPackageLoader.package_label()
	_fill_host([
		{
			"title": "Уровень VIP %d" % level,
			"lines": [
				"Прогресс: %d / %d" % [progress, next_at],
				"Сравнение уровней доступно в демо",
			],
			"actions": [
				{"label": "История бонусов", "kind": "info", "msg": "История пуста (демо)"},
				{"label": "VIP-награды", "kind": "reward", "rewards": ["Сундук VIP (демо)"]},
			],
		},
	])

func _fill_host(sections: Array) -> void:
	for c in _host.get_children():
		c.queue_free()
	var panel_scene: PackedScene = load("res://scenes/ui/components/game_panel.tscn")
	for section in sections:
		var panel: GamePanel = panel_scene.instantiate()
		panel.panel_kind = "GamePanel"
		_host.add_child(panel)
		var content: VBoxContainer = panel.get_node("Pad/Content")
		var head := Label.new()
		head.text = str(section.get("title", ""))
		head.add_theme_font_size_override("font_size", 28)
		content.add_child(head)
		for line in section.get("lines", []):
			var l := Label.new()
			l.text = "• %s" % str(line)
			l.add_theme_font_size_override("font_size", 22)
			l.add_theme_color_override("font_color", LunexColors.TEXT_SECONDARY)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(l)
		for action in section.get("actions", []):
			var b := Button.new()
			b.text = str(action.get("label", "Действие"))
			b.custom_minimum_size = Vector2(0, 56)
			b.theme_type_variation = &"GameButton"
			var kind: String = str(action.get("kind", "info"))
			var msg: String = str(action.get("msg", "Демо-действие"))
			b.pressed.connect(func():
				match kind:
					"reward":
						ModalManager.push_rewards("Награда (демо)", action.get("rewards", ["Золото ×100"]))
						AppState.add_demo_rewards(100, 0)
					_:
						ModalManager.push_info(str(action.get("label", "Инфо")), msg)
			)
			content.add_child(b)
