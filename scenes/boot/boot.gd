extends Control


func _ready() -> void:
	# Brief splash then auth (or hub if already logged in).
	await get_tree().create_timer(0.35).timeout
	if AppState.logged_in:
		get_tree().change_scene_to_file("res://scenes/hub/main_hub.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/auth/auth_screen.tscn")
