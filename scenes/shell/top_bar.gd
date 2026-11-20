@tool
extends PanelContainer
## Верхняя панель. Layout/ResourceCounter в .tscn; валюты обновляет runtime.

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
@export var primary_separation: int = 12:
	set(v):
		primary_separation = v
		_apply_separations()
@export var secondary_separation: int = 16:
	set(v):
		secondary_separation = v
		_apply_separations()
@export var show_settings_button: bool = false:
	set(v):
		show_settings_button = v
		if _settings:
			_settings.visible = v

@export_group("Preview (editor only)")
@export var preview_profile: String = "Командир":
	set(v):
		preview_profile = v
		if Engine.is_editor_hint():
			_apply_preview()
@export var preview_gold: String = "12.4K":
	set(v):
		preview_gold = v
		if Engine.is_editor_hint():
			_apply_preview()
@export var preview_dia: String = "320":
	set(v):
		preview_dia = v
		if Engine.is_editor_hint():
			_apply_preview()
@export var preview_vip: String = "1":
	set(v):
		preview_vip = v
		if Engine.is_editor_hint():
			_apply_preview()

var _shell: Node
@onready var _pad: MarginContainer = $Pad
@onready var _primary: HBoxContainer = $Pad/Rows/Primary
@onready var _secondary: HBoxContainer = $Pad/Rows/Secondary
@onready var _profile_btn: Button = $Pad/Rows/Primary/ProfileBtn
@onready var _gold: ResourceCounter = $Pad/Rows/Secondary/Gold
@onready var _dia: ResourceCounter = $Pad/Rows/Secondary/Dia
@onready var _vip: ResourceCounter = $Pad/Rows/Secondary/Vip
@onready var _shop: Button = $Pad/Rows/Secondary/ShopBtn
@onready var _settings: Button = $Pad/Rows/Primary/SettingsBtn

func _ready() -> void:
	custom_minimum_size.y = bar_min_height
	_apply_pad()
	_apply_separations()
	if _settings:
		_settings.visible = show_settings_button
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

func _apply_separations() -> void:
	if _primary:
		_primary.add_theme_constant_override("separation", primary_separation)
	if _secondary:
		_secondary.add_theme_constant_override("separation", secondary_separation)

func _apply_preview() -> void:
	if _profile_btn:
		_profile_btn.text = preview_profile
	if _gold:
		_gold.value_text = preview_gold
	if _dia:
		_dia.value_text = preview_dia
	if _vip:
		_vip.value_text = preview_vip

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
	_settings.visible = show_settings_button
	_shop.text = ContentPackageLoader.tr_key("shell.shop", str(tb.get("shop_label", "Магазин")))
	_settings.tooltip_text = "Настройки"

func refresh() -> void:
	if _profile_btn == null:
		return
	var online_mark := " · online" if ApiClient.online else ""
	_profile_btn.text = "%s%s" % [AppState.display_name, online_mark]
	_gold.value_text = _fmt(AppState.gold)
	_dia.value_text = _fmt(AppState.diamonds)
	_vip.value_text = str(AppState.vip_level)

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
