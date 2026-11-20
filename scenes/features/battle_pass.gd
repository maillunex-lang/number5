extends Control
## HUB battle pass: chrome в .tscn; DynamicHost — без DemoScreenBuilder.

var _payload: Dictionary = {}

@onready var _title: Label = $Safe/Scroll/VBox/Title
@onready var _status: Label = $Safe/Scroll/VBox/StatusLabel
@onready var _host: VBoxContainer = $Safe/Scroll/VBox/DynamicHost

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	var bp: Dictionary = ContentPackageLoader.features.get("battle_pass", {})
	var season := str(bp.get("season", "Сезон"))
	var level := int(bp.get("level", 1))
	var free_ready := int(bp.get("free_ready", 0))
	var premium_ready := int(bp.get("premium_ready", 0))
	_title.text = str(_payload.get("title_override", "Сезонный пропуск"))
	_status.text = "Статус: %s" % ContentPackageLoader.package_label()
	FeatureSectionHost.fill(_host, [
		{
			"title": "Сезон «%s»" % season,
			"lines": [
				"Уровень пропуска: %d" % level,
				"Готово free/premium: %d / %d" % [free_ready, premium_ready],
			],
			"actions": [
				{"label": "Забрать доступные", "kind": "reward", "rewards": ["Золото ×500", "Ключ ×1"]},
				{"label": "Задания сезона", "kind": "route", "route": "HUB-03"},
			],
		},
	])
