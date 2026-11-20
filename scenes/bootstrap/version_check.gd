extends Control

func _ready() -> void:
	$Safe/VBox/Status.text = "Клиент %s запускает онлайн-проверку." % AppState.VERSION
	await get_tree().create_timer(0.55).timeout
	get_tree().change_scene_to_file("res://scenes/bootstrap/asset_bootstrap.tscn")
