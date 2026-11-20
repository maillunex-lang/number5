extends PanelContainer

@onready var _name: Label = %PlayerName
@onready var _level: Label = %PlayerLevel
@onready var _gold: Label = %GoldLabel
@onready var _gems: Label = %GemLabel


func _ready() -> void:
	UIStyle.apply_panel(self, UIColors.BG_PANEL)
	UIStyle.apply_button(%ChatButton, false)
	%ChatButton.pressed.connect(func(): ScreenRouter.open_chat())
	AppState.player_changed.connect(_refresh)
	AppState.currencies_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_name.text = AppState.player_name
	_level.text = "Lv.%d" % AppState.player_level
	_gold.text = _format_num(AppState.gold)
	_gems.text = _format_num(AppState.diamonds)


func _format_num(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
