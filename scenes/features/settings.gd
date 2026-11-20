extends Control
## SETTINGS-01: вкладки; графика только пресеты; звук; аккаунт; контент OTA

var _tab: String = "graphics"

func setup(_payload: Dictionary = {}) -> void:
	pass

func _ready() -> void:
	ContentUpdateService.status_changed.connect(_rebuild)
	ContentUpdateService.update_finished.connect(func(_ok, _msg): _rebuild())
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header("Настройки"))
	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["graphics", "Графика"], ["audio", "Звук"], ["content", "Контент"], ["account", "Аккаунт"], ["general", "Общие"]]:
		var b := UIFactory.fantasy_button(t[1], 48)
		var key: String = t[0]
		if key == _tab:
			b.modulate = Color(1.2, 1.1, 0.9)
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)
	match _tab:
		"graphics":
			root.add_child(UIFactory.label("Только готовые пресеты", 24, LunexColors.TEXT_SECONDARY))
			root.add_child(UIFactory.label("Текущий: %s" % ThemeManager.preset_label(), 26, LunexColors.GOLD))
			for p in ThemeManager.PRESETS:
				var b := UIFactory.gold_button(ThemeManager.preset_label(p)) if p == ThemeManager.preset else UIFactory.fantasy_button(ThemeManager.preset_label(p))
				var preset: String = p
				b.pressed.connect(func():
					ThemeManager.apply_preset(preset)
					NotificationManager.success("Графика: %s" % ThemeManager.preset_label())
					_rebuild()
				)
				root.add_child(b)
		"audio":
			root.add_child(UIFactory.label("Музыка", 24))
			var m := HSlider.new()
			m.min_value = 0
			m.max_value = 1
			m.step = 0.05
			m.value = ThemeManager.music_volume
			m.custom_minimum_size = Vector2(0, 40)
			m.value_changed.connect(func(v): ThemeManager.set_music_volume(v))
			root.add_child(m)
			root.add_child(UIFactory.label("Эффекты", 24))
			var s := HSlider.new()
			s.min_value = 0
			s.max_value = 1
			s.step = 0.05
			s.value = ThemeManager.sfx_volume
			s.custom_minimum_size = Vector2(0, 40)
			s.value_changed.connect(func(v): ThemeManager.set_sfx_volume(v))
			root.add_child(s)
		"content":
			root.add_child(UIFactory.label("Обновление контента (OTA)", 26, LunexColors.GOLD))
			root.add_child(UIFactory.muted("Фон, иконки, раскладка, тексты — без переустановки APK. Код игры так не обновить.", 20))
			root.add_child(UIFactory.label(ContentPackageLoader.package_label(), 22))
			root.add_child(UIFactory.label("CDN: %s" % ContentUpdateService.cdn_base, 18, LunexColors.TEXT_MUTED))
			root.add_child(UIFactory.label("Статус: %s" % ContentUpdateService.last_status, 20))
			if ContentUpdateService.last_error != "":
				root.add_child(UIFactory.label(ContentUpdateService.last_error, 18, LunexColors.TEXT_DANGER))
			if ContentUpdateService.last_check_at != "":
				root.add_child(UIFactory.muted("Проверено: %s" % ContentUpdateService.last_check_at, 18))
			var check := UIFactory.gold_button("Проверить и скачать обновление")
			check.disabled = ContentUpdateService.busy
			check.pressed.connect(func(): ContentUpdateService.check_for_updates(false))
			root.add_child(check)
			var reload := UIFactory.fantasy_button("Перечитать локальный пакет")
			reload.pressed.connect(func(): ContentUpdateService.force_reload_current())
			root.add_child(reload)
			var toggle := UIFactory.fantasy_button("OTA: %s" % ("вкл" if ContentUpdateService.enabled else "выкл"))
			toggle.pressed.connect(func():
				ContentUpdateService.set_enabled(not ContentUpdateService.enabled)
				_rebuild()
			)
			root.add_child(toggle)
		"account":
			root.add_child(UIFactory.label("Email: %s" % (AppState.email_hint if AppState.email_hint != "" else "— (гость)"), 24))
			root.add_child(UIFactory.muted("Пароль не хранится в локальных файлах прототипа.", 20))
			var logout := UIFactory.fantasy_button("Выход")
			logout.pressed.connect(func():
				ModalManager.push_confirm("Выйти из аккаунта?", "Вернуться на экран входа.", func():
					AppState.logout()
					get_tree().change_scene_to_file("res://scenes/bootstrap/auth.tscn")
				)
			)
			root.add_child(logout)
		"general":
			root.add_child(UIFactory.muted("Язык, уведомления и поддержка — кандидаты, набор не утверждён полностью.", 22))
			root.add_child(UIFactory.label("Версия клиента: %s" % AppState.VERSION, 22))
			root.add_child(UIFactory.label(AppState.BUILD_LABEL, 20, LunexColors.TEXT_MUTED))
			root.add_child(UIFactory.label("Контент: %s" % ContentPackageLoader.version, 20, LunexColors.TEXT_MUTED))
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
