@tool
extends PanelContainer
## Верхняя панель. Layout в .tscn; валюты обновляет runtime.

@export_category("Lunex Top Bar")
@export_group("Layout")
@export var bar_min_height: float = 158.0:
	set(v):
		bar_min_height = v
		custom_minimum_size.y = v
@export var pad_left: int = 18:
	set(v):
		pad_left = v
		_apply_pad()
@export var pad_right: int = 18:
	set(v):
		pad_right = v
		_apply_pad()
@export var pad_top: int = 8:
	set(v):
		pad_top = v
		_apply_pad()
@export var pad_bottom: int = 8:
	set(v):
		pad_bottom = v
		_apply_pad()

@export_group("Preview (editor only)")
@export var preview_profile: String = "Командир"
@export var preview_gold: String = "Золото 12.4K"
@export var preview_dia: String = "Алмазы 320"
@export var preview_vip: String = "VIP 1"

var _shell: Node
@onready var _pad: MarginContainer = $Pad
@onready var _profile_btn: Button = $Pad/Rows/Primary/ProfileBtn
@onready var _gold: Label = $Pad/Rows/Secondary/Gold
@onready var _dia: Label = $Pad/Rows/Secondary/Dia
@onready var _vip: Label = $Pad/Rows/Secondary/Vip
@onready var _shop: Button = $Pad/Rows/Secondary/ShopBtn
@onready var _settings: Button = $Pad/Rows/Primary/SettingsBtn

func _ready() -> void:
	custom_minimum_size.y = bar_min_height
	_apply_pad()
	if Engine.is_editor_hint():
		_apply_preview()
		return

func setup(shell: Node) -> void:
	_shell = shell
	_apply_shell_chrome()
	_profile_btn.pressed.connect(func(): ScreenRouter.go("PROFILE-01"))
	_shop.pressed.connect(func(): ScreenRouter.go("HUB-06"))
	_settings.pressed.connect(func(): ScreenRouter.go("SETTINGS-01"))
	AppState.currencies_changed.connect(refresh)
	ApiClient.wallet_synced.connect(refresh)
	ContentPackageLoader.package_loaded.connect(func(_v):
		_apply_shell_chrome()
		refresh()
	)
	refresh()

func _apply_pad() -> void:
	if _pad == null:
		return
	_pad.add_theme_constant_override("margin_left", pad_left)
	_pad.add_theme_constant_override("margin_right", pad_right)
	_pad.add_theme_constant_override("margin_top", pad_top)
	_pad.add_theme_constant_override("margin_bottom", pad_bottom)

func _apply_preview() -> void:
	if _profile_btn:
		_profile_btn.text = preview_profile
	if _gold:
		_gold.text = preview_gold
	if _dia:
		_dia.text = preview_dia
	if _vip:
		_vip.text = preview_vip

func _apply_shell_chrome() -> void:
	var tb: Dictionary = ContentPackageLoader.shell.get("top_bar", {})
	custom_minimum_size.y = maxf(float(tb.get("height", 96)), bar_min_height)
	var bg := Color(str(tb.get("bg", "#132038")))
	var border := Color(str(tb.get("border", "#3A4A68")))
	add_theme_stylebox_override("panel", UIFactory.panel_style(bg, border, ThemeManager.radius("md"), 2))
	_profile_btn.visible = bool(tb.get("show_profile", true))
	_gold.visible = bool(tb.get("show_gold", true))
	_dia.visible = bool(tb.get("show_diamonds", true))
	_vip.visible = bool(tb.get("show_vip", true))
	_shop.visible = bool(tb.get("show_shop", true))
	_settings.visible = false # Settings is now a hub side-rail action
	_shop.text = ContentPackageLoader.tr_key("shell.shop", str(tb.get("shop_label", "Магазин")))
	_settings.text = "⚙"
	_settings.tooltip_text = "Настройки"
	_settings.custom_minimum_size = Vector2(86.0, 78.0)
	_settings.add_theme_font_size_override("font_size", 34)
	_profile_btn.add_theme_font_size_override("font_size", 28)
	_shop.add_theme_font_size_override("font_size", 26)

func refresh() -> void:
	if _profile_btn == null:
		return
	var online_mark := " · online" if ApiClient.online else ""
	_profile_btn.text = "%s%s" % [AppState.display_name, online_mark]
	_gold.text = "Золото %s" % _fmt(AppState.gold)
	_dia.text = "Алмазы %s" % _fmt(AppState.diamonds)
	_vip.text = "VIP %d" % AppState.vip_level

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
