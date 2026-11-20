extends Control

@onready var _status: Label = $Safe/Layout/Card/CardMargin/VBox/Status
@onready var _guest_btn: Button = $Safe/Layout/Card/CardMargin/VBox/GuestBtn
var _checking: HTTPRequest
var _email: LineEdit
var _password: LineEdit
var _login: Button
var _register: Button
var _restore_checked := false

func _ready() -> void:
    _guest_btn.pressed.connect(_on_guest)
    _guest_btn.disabled = true
    $Safe/Layout/Card/CardMargin/VBox/SettingsBtn.pressed.connect(_on_settings)
    _checking = HTTPRequest.new()
    _checking.timeout = 6.0
    add_child(_checking)
    _build_account_form()
    _try_restore()
    _check_server()

var _bg_texture: TextureRect
var _bg_offset := Vector2.ZERO
var _tab_register := false
var _remember: CheckBox
var _tab_login: Button
var _tab_signup: Button
var _visual_card: PanelContainer
var _server_chip: Label
var _top_actions: HBoxContainer
var _ui_scroll: ScrollContainer

func _make_panel(bg: Color, border: Color, radius: int = 20) -> StyleBoxFlat:
    var st := StyleBoxFlat.new()
    st.bg_color = bg
    st.border_color = border
    st.set_border_width_all(2)
    st.set_corner_radius_all(radius)
    return st

func _style_button(btn: Button, base: Color, edge: Color) -> void:
    btn.add_theme_stylebox_override("normal", _make_panel(base, edge, 18))
    btn.add_theme_stylebox_override("hover", _make_panel(base.lightened(0.14), edge, 18))
    btn.add_theme_stylebox_override("pressed", _make_panel(base.darkened(0.18), edge, 18))
    btn.add_theme_stylebox_override("disabled", _make_panel(base.darkened(0.3), edge.darkened(0.5), 18))
    btn.add_theme_color_override("font_color", Color(1, 0.95, 0.84))
    btn.add_theme_font_size_override("font_size", 25)

func _build_account_form() -> void:
    # Image fills the entire screen; UI remains a separate static layer.
    _bg_texture = TextureRect.new()
    _bg_texture.name = "ParallaxBackground"
    _bg_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bg_texture.texture = load("res://assets/login/background.webp")
    add_child(_bg_texture)
    move_child(_bg_texture, 0)
    $Background.visible = false
    $TopGlow.visible = false

    var shade := ColorRect.new()
    shade.name = "ReadabilityShade"
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.025, 0.035, 0.08, 0.18)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    move_child(shade, 1)

    # Top controls and a real server status label.
    _top_actions = HBoxContainer.new()
    _top_actions.name = "TopActions"
    _top_actions.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _top_actions.anchor_left = 1.0
    _top_actions.anchor_right = 1.0
    _top_actions.offset_left = -400
    _top_actions.offset_right = -30
    _top_actions.offset_top = 36
    _top_actions.offset_bottom = 112
    _top_actions.add_theme_constant_override("separation", 12)
    add_child(_top_actions)
    var settings := Button.new()
    settings.text = "Настройки"
    settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_button(settings, Color(0.055, 0.09, 0.17, 0.92), Color(0.92, 0.69, 0.3))
    settings.pressed.connect(_on_settings)
    _top_actions.add_child(settings)

    $Safe.add_theme_constant_override("margin_left", 28)
    $Safe.add_theme_constant_override("margin_right", 28)
    $Safe.add_theme_constant_override("margin_top", 120)
    $Safe.add_theme_constant_override("margin_bottom", 48)
    var layout: VBoxContainer = $Safe/Layout
    layout.add_theme_constant_override("separation", 0)
    $Safe/Layout/TopSpace.size_flags_vertical = Control.SIZE_EXPAND_FILL
    $Safe/Layout/BottomSpace.size_flags_vertical = Control.SIZE_EXPAND_FILL
    $Safe/Layout/Brand.add_theme_font_size_override("font_size", 76)
    $Safe/Layout/Brand.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
    $Safe/Layout/Brand.add_theme_constant_override("shadow_offset_x", 3)
    $Safe/Layout/Brand.add_theme_constant_override("shadow_offset_y", 4)
    $Safe/Layout/Subtitle.add_theme_font_size_override("font_size", 22)
    $Safe/Layout/Subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
    $Safe/Layout/GapOne.custom_minimum_size.y = 42
    $Safe/Layout/GapTwo.custom_minimum_size.y = 24
    $Safe/Layout/Legal.add_theme_font_size_override("font_size", 18)
    $Safe/Layout/Legal.add_theme_color_override("font_color", Color(1, 0.93, 0.78))
    $Safe/Layout/Legal.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
    $Safe/Layout/Legal.text = "v%s · Онлайн-игра · Без реальных платежей" % AppState.VERSION

    var card: PanelContainer = $Safe/Layout/Card
    card.add_theme_stylebox_override("panel", _make_panel(Color(0.025, 0.045, 0.095, 0.94), Color(0.97, 0.72, 0.27), 30))
    var margins: MarginContainer = $Safe/Layout/Card/CardMargin
    for side in ["left", "right", "top", "bottom"]:
        margins.add_theme_constant_override("margin_" + side, 24)
    var parent: VBoxContainer = $Safe/Layout/Card/CardMargin/VBox
    parent.add_theme_constant_override("separation", 13)
    $Safe/Layout/Card/CardMargin/VBox/Title.visible = false
    $Safe/Layout/Card/CardMargin/VBox/Hint.visible = false
    $Safe/Layout/Card/CardMargin/VBox/SettingsBtn.visible = false

    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 12)
    parent.add_child(tabs)
    parent.move_child(tabs, 0)
    _tab_login = Button.new()
    _tab_login.text = "ВХОД"
    _tab_login.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tab_login.custom_minimum_size.y = 72
    tabs.add_child(_tab_login)
    _tab_signup = Button.new()
    _tab_signup.text = "РЕГИСТРАЦИЯ"
    _tab_signup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tab_signup.custom_minimum_size.y = 72
    tabs.add_child(_tab_signup)
    _tab_login.pressed.connect(func(): _switch_tab(false))
    _tab_signup.pressed.connect(func(): _switch_tab(true))

    _email = LineEdit.new()
    _email.placeholder_text = "Email"
    _email.custom_minimum_size.y = 72
    _email.add_theme_font_size_override("font_size", 25)
    _email.add_theme_stylebox_override("normal", _make_panel(Color(0.09, 0.15, 0.24, 0.96), Color(0.36, 0.49, 0.65)))
    parent.add_child(_email)
    _password = LineEdit.new()
    _password.placeholder_text = "Пароль"
    _password.secret = true
    _password.custom_minimum_size.y = 72
    _password.add_theme_font_size_override("font_size", 25)
    _password.add_theme_stylebox_override("normal", _make_panel(Color(0.09, 0.15, 0.24, 0.96), Color(0.36, 0.49, 0.65)))
    parent.add_child(_password)

    _remember = CheckBox.new()
    _remember.text = "Запомнить меня"
    _remember.button_pressed = true
    _remember.add_theme_font_size_override("font_size", 23)
    parent.add_child(_remember)
    _login = Button.new()
    _login.text = "ВОЙТИ В АККАУНТ"
    _login.custom_minimum_size.y = 90
    parent.add_child(_login)
    _register = Button.new()
    _register.text = "СОЗДАТЬ АККАУНТ"
    _register.custom_minimum_size.y = 90
    parent.add_child(_register)
    _style_button(_login, Color(0.62, 0.34, 0.035), Color(1, 0.81, 0.28))
    _style_button(_register, Color(0.62, 0.34, 0.035), Color(1, 0.81, 0.28))
    _login.pressed.connect(func(): _credentials(false))
    _register.pressed.connect(func(): _credentials(true))

    var divider := Label.new()
    divider.text = "ИЛИ"
    divider.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    divider.add_theme_font_size_override("font_size", 21)
    divider.add_theme_color_override("font_color", Color(0.84, 0.86, 0.92))
    parent.add_child(divider)
    _guest_btn.text = "ПРОДОЛЖИТЬ КАК ГОСТЬ"
    _guest_btn.custom_minimum_size.y = 88
    parent.move_child(_guest_btn, parent.get_child_count() - 1)
    _style_button(_guest_btn, Color(0.01, 0.30, 0.34, 0.96), Color(0.22, 0.96, 0.91))
    _status.add_theme_font_size_override("font_size", 19)
    parent.move_child(_status, parent.get_child_count() - 1)

    _server_chip = Label.new()
    _server_chip.text = "● Проверяем сервер..."
    _server_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _server_chip.add_theme_font_size_override("font_size", 21)
    _server_chip.add_theme_color_override("font_color", Color(0.95, 0.83, 0.54))
    layout.add_child(_server_chip)
    layout.move_child(_server_chip, layout.get_child_count() - 1)
    _switch_tab(false)
    resized.connect(_adapt_layout)
    _adapt_layout()
    set_process(true)

func _adapt_layout() -> void:
    if not is_inside_tree():
        return
    var w := size.x
    var h := size.y
    var compact := h < 1650.0
    var card: PanelContainer = $Safe/Layout/Card
    var parent: VBoxContainer = $Safe/Layout/Card/CardMargin/VBox
    var scale_factor := clampf(h / 1900.0, 0.68, 1.0)
    var padding := maxi(14, int(24 * scale_factor))
    for side in ["left", "right", "top", "bottom"]:
        $Safe/Layout/Card/CardMargin.add_theme_constant_override("margin_" + side, padding)
    parent.add_theme_constant_override("separation", maxi(6, int(13 * scale_factor)))
    for control in [_tab_login, _tab_signup, _email, _password, _login, _register, _guest_btn]:
        if control != null:
            control.custom_minimum_size.y = maxf(52, control.custom_minimum_size.y if not compact else 64)
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
    _style_button(_tab_login, Color(0.62, 0.34, 0.035) if not registration else Color(0.09, 0.15, 0.24), Color(1, 0.81, 0.28) if not registration else Color(0.34, 0.45, 0.59))
    _style_button(_tab_signup, Color(0.62, 0.34, 0.035) if registration else Color(0.09, 0.15, 0.24), Color(1, 0.81, 0.28) if registration else Color(0.34, 0.45, 0.59))
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
