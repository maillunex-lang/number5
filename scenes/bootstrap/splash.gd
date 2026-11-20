extends Control

@onready var _bar: ProgressBar = $Safe/VBox/Bar
@onready var _hint: Label = $Safe/VBox/Hint

func _ready() -> void:
	_bar.value = 0
	var tw := create_tween()
	tw.tween_property(_bar, "value", 100.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property($BGAccent, "modulate:a", 1.0, 0.8).from(0.2)
	await tw.finished
	_hint.text = "Проверка версии…"
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://scenes/bootstrap/version_check.tscn")
