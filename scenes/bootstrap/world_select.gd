extends Control

func _ready() -> void:
	$Safe/VBox/WorldBtn.text = "Мир: %s" % AppState.world_name
	$Safe/VBox/Meta.text = "Командир: %s · %s" % [AppState.display_name, ("%s · ONLINE" % AppState.BUILD_LABEL)]
	$Safe/VBox/EnterBtn.pressed.connect(_enter)
	var tw := create_tween().set_loops()
	tw.tween_property($Glow, "modulate:a", 0.85, 1.2)
	tw.tween_property($Glow, "modulate:a", 0.35, 1.2)

func _enter() -> void:
	if not ApiClient.has_session() or not ApiClient.online:
		NotificationManager.warn("Нужен вход на онлайн-сервер")
		get_tree().change_scene_to_file("res://scenes/bootstrap/auth.tscn")
		return
	ScreenRouter.enter_game_shell()
