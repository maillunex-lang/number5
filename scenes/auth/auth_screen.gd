extends Control

@onready var _user: LineEdit = %Username
@onready var _pass: LineEdit = %Password
@onready var _error: Label = %ErrorLabel


func _ready() -> void:
	_error.text = ""
	UIStyle.apply_button(%LoginButton, true)
	UIStyle.apply_button(%GuestButton, false)
	UIStyle.apply_panel(%Card)
	%LoginButton.pressed.connect(_on_login)
	%GuestButton.pressed.connect(_on_guest)
	_user.text_submitted.connect(func(_t): _on_login())
	_pass.text_submitted.connect(func(_t): _on_login())


func _on_login() -> void:
	var user := _user.text.strip_edges()
	if user.is_empty():
		_error.text = "Enter a username (stub — no server yet)."
		return
	AppState.login(user, _pass.text)
	get_tree().change_scene_to_file("res://scenes/hub/main_hub.tscn")


func _on_guest() -> void:
	AppState.login("Guest Commander", "")
	get_tree().change_scene_to_file("res://scenes/hub/main_hub.tscn")
