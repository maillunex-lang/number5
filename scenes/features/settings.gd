extends Control
## SETTINGS-01: вкладки; графика только пресеты; звук музыка/эффекты; аккаунт

var _tab: String = "graphics"

func setup(_payload: Dictionary = {}) -> void:
	pass

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header("Настройки"))
	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["graphics", "Графика"], ["audio", "Звук"], ["account", "Аккаунт"], ["general", "Общие"]]:
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
			root.add_child(UIFactory.label("Версия: %s" % AppState.VERSION, 22))
			root.add_child(UIFactory.label(AppState.BUILD_LABEL, 20, LunexColors.TEXT_MUTED))
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)
