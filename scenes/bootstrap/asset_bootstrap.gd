extends Control

@onready var _bar: ProgressBar = $Safe/VBox/Bar
@onready var _label: Label = $Safe/VBox/Op

func _ready() -> void:
	AssetLoader.load_progress.connect(_on_progress)
	AssetLoader.load_finished.connect(_on_done)
	$Safe/VBox/Tip.text = "Контент: %s" % ContentPackageLoader.package_label()
	AssetLoader.preload_essentials(PackedStringArray(["Тема", "Шрифты", "Пакет %s" % ContentPackageLoader.version, "Оболочка", "Хаб"]))

func _on_progress(done: int, total: int, label: String) -> void:
	_bar.max_value = total
	_bar.value = done
	_label.text = "Загрузка: %s (%d/%d)" % [label, done, total]

func _on_done() -> void:
	_label.text = "Готово"
	await get_tree().create_timer(0.2).timeout
	if AppState.session_active:
		get_tree().change_scene_to_file("res://scenes/bootstrap/world_select.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/bootstrap/auth.tscn")
