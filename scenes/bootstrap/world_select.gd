extends Control

func _ready() -> void:
	$Safe/VBox/WorldBtn.text = "Мир: %s" % AppState.world_name
	$Safe/VBox/Meta.text = "Командир: %s · %s" % [AppState.display_name, AppState.BUILD_LABEL]
	$Safe/VBox/EnterBtn.pressed.connect(_enter)
	var tw := create_tween().set_loops()
	tw.tween_property($Glow, "modulate:a", 0.85, 1.2)
	tw.tween_property($Glow, "modulate:a", 0.35, 1.2)

func _enter() -> void:
	ScreenRouter.enter_game_shell()
