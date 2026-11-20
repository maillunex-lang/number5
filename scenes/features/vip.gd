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
	FeatureSectionHost.fill(_host, [
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
