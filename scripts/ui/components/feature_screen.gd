@tool
class_name FeatureScreen
extends Control
## Стандартный каркас feature-экрана: фон, safe margins, scroll, dynamic host, назад.

@export_category("Lunex Feature Screen")
@export_group("Chrome")
@export var screen_title: String = "Раздел":
	set(v):
		screen_title = v
		if _title:
			_title.text = v
@export var screen_subtitle: String = "":
	set(v):
		screen_subtitle = v
		if _subtitle:
			_subtitle.text = v
			_subtitle.visible = v != ""
@export var bg_color: Color = Color(0.025, 0.045, 0.09, 1):
	set(v):
		bg_color = v
		if _bg:
			_bg.color = v

@export_group("Margins")
@export var margin_left: int = 28:
	set(v):
		margin_left = v
		_apply_margins()
@export var margin_top: int = 48:
	set(v):
		margin_top = v
		_apply_margins()
@export var margin_right: int = 28:
	set(v):
		margin_right = v
		_apply_margins()
@export var margin_bottom: int = 28:
	set(v):
		margin_bottom = v
		_apply_margins()

@export_group("Navigation")
@export var show_back_button: bool = true:
	set(v):
		show_back_button = v
		if _back:
			_back.visible = v

@onready var _bg: ColorRect = $BG
@onready var _safe: MarginContainer = $Safe
@onready var _title: Label = $Safe/Layout/Header/Title
@onready var _subtitle: Label = $Safe/Layout/Subtitle
@onready var _back: Button = $Safe/Layout/BackButton
@onready var dynamic_host: VBoxContainer = $Safe/Layout/Scroll/DynamicHost

func _ready() -> void:
	if _bg:
		_bg.color = bg_color
	_apply_margins()
	if _title:
		_title.text = screen_title
	if _subtitle:
		_subtitle.text = screen_subtitle
		_subtitle.visible = screen_subtitle != ""
	if _back:
		_back.visible = show_back_button
		if not Engine.is_editor_hint() and not _back.pressed.is_connected(_on_back):
			_back.pressed.connect(_on_back)

func clear_dynamic() -> void:
	if dynamic_host == null:
		return
	for c in dynamic_host.get_children():
		c.queue_free()

func _apply_margins() -> void:
	if _safe == null:
		return
	_safe.add_theme_constant_override("margin_left", margin_left)
	_safe.add_theme_constant_override("margin_top", margin_top)
	_safe.add_theme_constant_override("margin_right", margin_right)
	_safe.add_theme_constant_override("margin_bottom", margin_bottom)

func _on_back() -> void:
	if ScreenRouter:
		ScreenRouter.handle_back()
