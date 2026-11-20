extends Control

@onready var _email: LineEdit = $Safe/Card/VBox/Email
@onready var _pass: LineEdit = $Safe/Card/VBox/Pass
@onready var _status: Label = $Safe/Card/VBox/Status

func _ready() -> void:
	$Safe/Card/VBox/GuestBtn.pressed.connect(_on_guest)
	$Safe/Card/VBox/LoginBtn.pressed.connect(_on_login)
	$Safe/Card/VBox/SettingsBtn.pressed.connect(_on_settings)
	$Safe/News.text = "Новости демо: UI Prototype v0.1 · сервер не подключён · локальные данные"
	_status.text = "Статус сервера: демо (офлайн-прототип)"
	_animate_in()

func _animate_in() -> void:
	$Safe/Card.modulate.a = 0.0
	$Safe/Card.position.y += 40
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property($Safe/Card, "modulate:a", 1.0, 0.45)
	tw.tween_property($Safe/Card, "position:y", $Safe/Card.position.y - 40, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_guest() -> void:
	AppState.enter_as_guest()
	NotificationManager.success("Гостевой вход (локально)")
	get_tree().change_scene_to_file("res://scenes/bootstrap/world_select.tscn")

func _on_login() -> void:
	var email := _email.text.strip_edges()
	if email.is_empty() or not "@" in email:
		_status.text = "Введите корректный email для локального демо-входа."
		NotificationManager.warn("Некорректный email")
		return
	# Password field exists for UI parity; value is NEVER stored.
	_pass.text = ""
	AppState.enter_as_local_demo(email)
	NotificationManager.info("Локальный демо-вход без серверной авторизации")
	get_tree().change_scene_to_file("res://scenes/bootstrap/world_select.tscn")

func _on_settings() -> void:
	# Pre-shell settings: open lightweight dialog
	ModalManager.push_info("Настройки", "Полные настройки доступны после входа в игру.\nПресеты графики: Низкая / Средняя / Высокая / Ультра.")
