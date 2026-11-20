extends PanelContainer

var _shell: Node
@onready var _profile_btn: Button = $Pad/Row/ProfileBtn
@onready var _gold: Label = $Pad/Row/Gold
@onready var _dia: Label = $Pad/Row/Dia
@onready var _vip: Label = $Pad/Row/Vip
@onready var _shop: Button = $Pad/Row/ShopBtn
@onready var _settings: Button = $Pad/Row/SettingsBtn

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

func _apply_shell_chrome() -> void:
	var tb: Dictionary = ContentPackageLoader.shell.get("top_bar", {})
	custom_minimum_size.y = float(tb.get("height", 96))
	var bg := Color(str(tb.get("bg", "#132038")))
	var border := Color(str(tb.get("border", "#3A4A68")))
	add_theme_stylebox_override("panel", UIFactory.panel_style(bg, border, ThemeManager.radius("md"), 2))
	_profile_btn.visible = bool(tb.get("show_profile", true))
	_gold.visible = bool(tb.get("show_gold", true))
	_dia.visible = bool(tb.get("show_diamonds", true))
	_vip.visible = bool(tb.get("show_vip", true))
	_shop.visible = bool(tb.get("show_shop", true))
	_settings.visible = bool(tb.get("show_settings", true))
	_shop.text = ContentPackageLoader.tr_key("shell.shop", str(tb.get("shop_label", "Магазин")))

func refresh() -> void:
	if _profile_btn == null:
		return
	var online_mark := " · online" if ApiClient.online else ""
	_profile_btn.text = "%s  Lv.%d%s" % [AppState.display_name, AppState.level, online_mark]
	_gold.text = "◈ %s" % _fmt(AppState.gold)
	_dia.text = "◆ %s" % _fmt(AppState.diamonds)
	_vip.text = "VIP %d" % AppState.vip_level

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
