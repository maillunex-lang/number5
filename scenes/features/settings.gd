extends Control
## SETTINGS-01: вкладки; графика только пресеты; звук; аккаунт; контент OTA

var _tab: String = "graphics"

func setup(_payload: Dictionary = {}) -> void:
	pass

func _ready() -> void:
	ContentUpdateService.status_changed.connect(_rebuild)
	ContentUpdateService.update_finished.connect(func(_ok, _msg): _rebuild())
	_selected_preset = ThemeManager.preset
	_selected_fps = Engine.max_fps if Engine.max_fps in [30, 60, 90, 120] else 60
	_rebuild()

const GOLD := Color("#ffcc70")
const BLUE := Color("#142b49")
const INK := Color("#071426")
const LINE := Color("#bd8a39")
var _selected_preset: String = ""
var _selected_fps: int = 60

func _panel(bg: Color = INK, edge: Color = LINE, radius: int = 18) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = edge
	st.set_border_width_all(2)
	st.set_corner_radius_all(radius)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	return st

func _button(label_text: String, active: bool = false, height: int = 66) -> Button:
	var b := Button.new()
	b.text = label_text
	b.custom_minimum_size.y = height
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _panel(Color("#714510") if active else BLUE, GOLD if active else Color("#47749b")))
	b.add_theme_stylebox_override("hover", _panel(Color("#94601b"), GOLD))
	b.add_theme_stylebox_override("pressed", _panel(Color("#513109"), GOLD))
	b.add_theme_stylebox_override("disabled", _panel(Color("#41331e"), GOLD))
	return b

func _label(value: String, font_size: int = 24, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _rebuild() -> void:
	var root: VBoxContainer = $Safe/Layout/Scroll/VBox
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	root.add_theme_constant_override("separation", 15)
	var head: HBoxContainer = $Safe/Layout/Header
	for c in head.get_children():
		head.remove_child(c)
		c.queue_free()
	head.add_theme_constant_override("separation", 12)
	var title := _label("⚙ Настройки", 39, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := _button("✕", false, 64)
	close.custom_minimum_size.x = 70
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(func(): ScreenRouter.handle_back())
	head.add_child(close)
	var tabs: HBoxContainer = $Safe/Layout/Tabs
	for c in tabs.get_children():
		tabs.remove_child(c)
		c.queue_free()
	tabs.add_theme_constant_override("separation", 5)
	for t in [["graphics", "▣\nГрафика"], ["audio", "♫\nЗвук"], ["content", "▧\nКонтент"], ["account", "♙\nАккаунт"], ["general", "☷\nОбщие"]]:
		var key: String = t[0]
		var b := _button(t[1], key == _tab, 95)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_select_tab.bind(key))
		tabs.add_child(b)
	var content := PanelContainer.new()
	content.add_theme_stylebox_override("panel", _panel(Color("#081a30"), LINE, 22))
	root.add_child(content)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 17)
	content.add_child(body)
	match _tab:
		"graphics":
			_build_graphics(body)
		"audio":
			body.add_child(_label("♫ Звук", 31, GOLD))
			for spec in [["Музыка", ThemeManager.music_volume, true], ["Звуковые эффекты", ThemeManager.sfx_volume, false]]:
				body.add_child(_label(spec[0]))
				var slider := HSlider.new()
				slider.min_value = 0
				slider.max_value = 1
				slider.step = 0.05
				slider.value = spec[1]
				slider.custom_minimum_size.y = 60
				if spec[2]:
					slider.value_changed.connect(func(v): ThemeManager.set_music_volume(v))
				else:
					slider.value_changed.connect(func(v): ThemeManager.set_sfx_volume(v))
				body.add_child(slider)
		"content":
			body.add_child(_label("▧ Обновление контента", 31, GOLD))
			body.add_child(_label(ContentPackageLoader.package_label(), 22))
			body.add_child(_label("Статус: " + ContentUpdateService.last_status, 20))
			var check := _button("Проверить обновления")
			check.disabled = ContentUpdateService.busy
			check.pressed.connect(func(): ContentUpdateService.check_for_updates(false))
			body.add_child(check)
			var reload := _button("Перечитать локальный пакет")
			reload.pressed.connect(func(): ContentUpdateService.force_reload_current())
			body.add_child(reload)
			var toggle := _button("Автообновление: " + ("Вкл" if ContentUpdateService.enabled else "Выкл"))
			toggle.pressed.connect(func():
				ContentUpdateService.set_enabled(not ContentUpdateService.enabled)
				_rebuild()
			)
			body.add_child(toggle)
		"account":
			body.add_child(_label("♙ Аккаунт", 31, GOLD))
			body.add_child(_label("Игрок: " + AppState.display_name, 23))
			body.add_child(_label("Тип: " + ("Гостевой" if AppState.is_guest else "Зарегистрированный"), 21))
			body.add_child(_label("Email: " + (AppState.email_hint if AppState.email_hint != "" else ("Не привязан" if AppState.is_guest else "Не получен от сервера")), 21))
			if AppState.is_guest:
				body.add_child(_label("Привязать email — прогресс гостя сохранится", 20, GOLD))
				var email := LineEdit.new()
				email.placeholder_text = "email@example.com"
				email.custom_minimum_size.y = 56
				email.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				body.add_child(email)
				var pass := LineEdit.new()
				pass.placeholder_text = "Пароль (от 10 символов)"
				pass.secret = true
				pass.custom_minimum_size.y = 56
				pass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				body.add_child(pass)
				var link := _button("Привязать аккаунт")
				link.pressed.connect(func():
					link.disabled = true
					var ok := await ApiClient.link_guest(email.text.strip_edges(), pass.text)
					link.disabled = false
					pass.clear()
					if ok:
						NotificationManager.success("Аккаунт привязан")
						_rebuild()
					else:
						NotificationManager.warn("Не удалось привязать · проверь email/пароль")
				)
				body.add_child(link)
			var logout := _button("Выйти из аккаунта")
			logout.pressed.connect(func():
				ModalManager.push_confirm("Выйти из аккаунта?", "Вернуться на экран входа. Сессия на сервере будет отозвана.", _logout_confirmed)
			)
			body.add_child(logout)
		"general":
			body.add_child(_label("☷ Общие", 31, GOLD))
			body.add_child(_label("Версия клиента: " + AppState.VERSION, 22))
			body.add_child(_label("Контент: " + ContentPackageLoader.version, 22))
			body.add_child(_label("Другие настройки появятся по мере разработки.", 21))
	root.add_child(_label("LUNEX AFK  •  ONLINE", 18, GOLD))

func _build_graphics(body: VBoxContainer) -> void:
	body.add_child(_label("▣ Графика", 34, GOLD))
	body.add_child(_label("Качество изображения и производительность игры", 21))
	var preview := TextureRect.new()
	preview.texture = load("res://assets/login/background.webp")
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.custom_minimum_size.y = 180
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(preview)
	body.add_child(_label("Готовые пресеты", 26, GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	body.add_child(grid)
	for preset_name in ThemeManager.PRESETS:
		var key: String = preset_name
		var selected := key == _selected_preset
		var b := _button(("✓  " if selected else "") + ThemeManager.preset_label(key), selected, 92)
		b.pressed.connect(func():
			_selected_preset = key
			_rebuild()
		)
		grid.add_child(b)
	body.add_child(_label("Частота кадров (FPS)", 25, GOLD))
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 8)
	body.add_child(fps_row)
	for fps in [30, 60, 90, 120]:
		var f: int = fps
		var b := _button(str(f), f == _selected_fps, 60)
		b.pressed.connect(func():
			_selected_fps = f
			_rebuild()
		)
		fps_row.add_child(b)
	body.add_child(_label("Дополнительные эффекты", 25, GOLD))
	body.add_child(_label("Эффекты и частицы: регулируются пресетом", 20))
	body.add_child(_label("Тени и сглаживание: зависят от рендера", 20))
	body.add_child(_label("Параллакс: " + ("включён" if ThemeManager.parallax_enabled else "выключен") + " (по пресету)", 20))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	var reset := _button("↺ Сбросить", false, 76)
	reset.pressed.connect(func():
		_selected_preset = "medium"
		_selected_fps = 60
		_rebuild()
	)
	actions.add_child(reset)
	var apply := _button("✓ Применить", true, 76)
	apply.pressed.connect(func():
		ThemeManager.apply_preset(_selected_preset)
		Engine.max_fps = _selected_fps
		NotificationManager.success("Графика: " + ThemeManager.preset_label() + " • " + str(_selected_fps) + " FPS")
		_rebuild()
	)
	actions.add_child(apply)

func _logout_confirmed() -> void:
	await ApiClient.logout_remote()
	AppState.logout()
	get_tree().change_scene_to_file("res://scenes/bootstrap/auth.tscn")

func _select_tab(tab_name: String) -> void:
	if tab_name == _tab:
		return
	_tab = tab_name
	_rebuild()
