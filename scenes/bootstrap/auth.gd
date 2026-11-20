extends Control
## AUTH: chrome + form в .tscn (Theme GamePanel/GoldButton/GameButton); parallax + API в скрипте.

@onready var _status: Label = $Safe/Layout/Card/CardMargin/VBox/Status
@onready var _guest_btn: Button = $Safe/Layout/Card/CardMargin/VBox/GuestBtn
@onready var _bg_texture: TextureRect = $ParallaxBackground
@onready var _email: LineEdit = $Safe/Layout/Card/CardMargin/VBox/EmailEdit
@onready var _password: LineEdit = $Safe/Layout/Card/CardMargin/VBox/PasswordEdit
@onready var _login: Button = $Safe/Layout/Card/CardMargin/VBox/LoginBtn
@onready var _register: Button = $Safe/Layout/Card/CardMargin/VBox/RegisterBtn
@onready var _remember: CheckBox = $Safe/Layout/Card/CardMargin/VBox/RememberCheck
@onready var _tab_login: Button = $Safe/Layout/Card/CardMargin/VBox/Tabs/TabLogin
@onready var _tab_signup: Button = $Safe/Layout/Card/CardMargin/VBox/Tabs/TabSignup
@onready var _server_chip: Label = $Safe/Layout/ServerChip

var _checking: HTTPRequest
var _restore_checked := false
var _bg_offset := Vector2.ZERO
var _tab_register := false

func _ready() -> void:
	_guest_btn.disabled = true
	_guest_btn.pressed.connect(_on_guest)
	$TopActions/TopSettingsBtn.pressed.connect(_on_settings)
	_tab_login.pressed.connect(func(): _switch_tab(false))
	_tab_signup.pressed.connect(func(): _switch_tab(true))
	_login.pressed.connect(func(): _credentials(false))
	_register.pressed.connect(func(): _credentials(true))
	_checking = HTTPRequest.new()
	_checking.timeout = 6.0
	add_child(_checking)
	$Safe/Layout/Legal.text = "v%s · Онлайн-игра · Без реальных платежей" % AppState.VERSION
	_switch_tab(false)
	resized.connect(_adapt_layout)
	_adapt_layout()
	set_process(true)
	_try_restore()
	_check_server()

func _adapt_layout() -> void:
	if not is_inside_tree():
		return
	var w := size.x
	var h := size.y
	var compact := h < 1650.0
	var scale_factor := clampf(h / 1900.0, 0.68, 1.0)
	var padding := maxi(14, int(24 * scale_factor))
	for side in ["left", "right", "top", "bottom"]:
		$Safe/Layout/Card/CardMargin.add_theme_constant_override("margin_" + side, padding)
	$Safe/Layout/Card/CardMargin/VBox.add_theme_constant_override("separation", maxi(6, int(13 * scale_factor)))
	var min_h := 64.0 if compact else 72.0
	for control in [_tab_login, _tab_signup, _email, _password]:
		if control != null:
			control.custom_minimum_size.y = min_h
	_login.custom_minimum_size.y = 72.0 if compact else 90.0
	_register.custom_minimum_size.y = 72.0 if compact else 90.0
	_guest_btn.custom_minimum_size.y = 72.0 if compact else 88.0
	$Safe/Layout/Brand.add_theme_font_size_override("font_size", int(clampf(w * 0.10, 44, 76)))
	$Safe/Layout/GapOne.custom_minimum_size.y = 20 if compact else 42
	$Safe/Layout/GapTwo.custom_minimum_size.y = 10 if compact else 24
	$Safe.add_theme_constant_override("margin_top", 94 if compact else 120)
	$Safe.add_theme_constant_override("margin_bottom", 20 if compact else 48)

func _switch_tab(registration: bool) -> void:
	_tab_register = registration
	_register.visible = registration
	_login.visible = not registration
	_tab_login.disabled = not registration
	_tab_signup.disabled = registration
	_tab_login.theme_type_variation = &"GoldButton" if not registration else &"GameButton"
	_tab_signup.theme_type_variation = &"GoldButton" if registration else &"GameButton"
	_password.placeholder_text = "🔒  Придумай пароль (от 10 символов)" if registration else "🔒  Пароль"
	_remember.visible = not registration

func _process(delta: float) -> void:
	if _bg_texture == null:
		return
	var sensor := Input.get_gravity()
	if sensor.length() < 0.2:
		sensor = Input.get_accelerometer()
	var target := Vector2(clampf(sensor.x / 9.8, -1, 1), clampf(sensor.y / 9.8, -1, 1)) * 24.0
	_bg_offset = _bg_offset.lerp(target, minf(delta * 3.0, 1.0))
	var overscan := 48.0
	_bg_texture.offset_left = -overscan + _bg_offset.x
	_bg_texture.offset_top = -overscan + _bg_offset.y
	_bg_texture.offset_right = overscan + _bg_offset.x
	_bg_texture.offset_bottom = overscan + _bg_offset.y

func _try_restore() -> void:
	_status.text = "Восстанавливаем игровую сессию..."
	var ok := await ApiClient.restore_session()
	if not is_inside_tree():
		return
	_restore_checked = true
	_guest_btn.disabled = false
	if not ok:
		_status.text = "Выбери способ входа. Сервер проверяется..."
	if ok:
		AppState.session_active = true
		ScreenRouter.enter_game_shell()

func _credentials(register_new: bool) -> void:
	if not _restore_checked:
		return
	_login.disabled = true
	_register.disabled = true
	_status.text = "Подключаемся к игровому серверу..."
	var ok := await ApiClient.credentials_login(_email.text.strip_edges(), _password.text, register_new)
	if not is_inside_tree():
		return
	_login.disabled = false
	_register.disabled = false
	_password.clear()
	if not ok:
		_status.text = "Ошибка входа или регистрации. Проверь email и пароль."
		return
	if not _remember.button_pressed:
		ApiClient.forget_saved_session()
	AppState.session_active = true
	AppState.is_guest = false
	ScreenRouter.enter_game_shell()

func _check_server() -> void:
	_status.text = "Проверяем подключение к серверу..."
	var err := _checking.request(ApiClient.base_url + "/api/v1/health")
	if err != OK:
		_status.text = "Сервер недоступен · повтори подключение"
		return
	var response: Array = await _checking.request_completed
	if not is_inside_tree():
		return
	var valid: bool = response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200
	if valid:
		var data: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
		valid = typeof(data) == TYPE_DICTIONARY and data.get("ok", false) == true and data.get("db", false) == true
	if not _restore_checked:
		return
	_server_chip.text = "● Сервер онлайн" if valid else "● Сервер недоступен"
	_server_chip.add_theme_color_override("font_color", Color(0.35, 1, 0.55) if valid else Color(1, 0.5, 0.43))
	_status.text = "Подключение доступно" if valid else "Проверь соединение и повтори вход"

func _on_guest() -> void:
	if not _restore_checked:
		return
	_guest_btn.disabled = true
	_status.text = "Создаём игровую сессию..."
	var ok := await ApiClient.guest_login()
	if not is_inside_tree():
		return
	_guest_btn.disabled = false
	if not ok:
		_status.text = "Не удалось подключиться · попробуй снова"
		NotificationManager.warn("Онлайн-вход недоступен")
		return
	AppState.enter_as_guest(AppState.display_name)
	NotificationManager.success("Подключено к игровому серверу")
	ScreenRouter.enter_game_shell()

func _on_settings() -> void:
	ModalManager.push_info("Настройки", "Полные настройки доступны после входа в игру.\nПресеты графики: Низкая / Средняя / Высокая / Ультра.")
