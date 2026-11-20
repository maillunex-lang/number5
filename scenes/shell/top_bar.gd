extends PanelContainer

var _shell: Node
@onready var _profile_btn: Button = $Pad/Row/ProfileBtn
@onready var _gold: Label = $Pad/Row/Gold
@onready var _dia: Label = $Pad/Row/Dia
@onready var _vip: Label = $Pad/Row/Vip

func setup(shell: Node) -> void:
	_shell = shell
	_profile_btn.pressed.connect(func(): ScreenRouter.go("PROFILE-01"))
	$Pad/Row/ShopBtn.pressed.connect(func(): ScreenRouter.go("HUB-06"))
	$Pad/Row/MailBtn.pressed.connect(func(): ScreenRouter.go("SOCIAL-04"))
	$Pad/Row/SettingsBtn.pressed.connect(func(): ScreenRouter.go("SETTINGS-01"))
	$Pad/Row/RewardsBtn.pressed.connect(func(): ScreenRouter.go("GLOBAL-01"))
	AppState.currencies_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if _profile_btn == null:
		return
	_profile_btn.text = "%s  Lv.%d" % [AppState.display_name, AppState.level]
	_gold.text = "◈ %s" % _fmt(AppState.gold)
	_dia.text = "◆ %s" % _fmt(AppState.diamonds)
	_vip.text = "VIP %d" % AppState.vip_level

func _fmt(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	if n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
