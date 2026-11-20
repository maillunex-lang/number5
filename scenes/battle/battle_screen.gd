extends Control
## Side-view 5x5 battle sandbox. Slots ready for AnimatedSprite2D later.

const ROWS := 5
const COLS := 5

@onready var _ally_grid: GridContainer = %AllyGrid
@onready var _enemy_grid: GridContainer = %EnemyGrid
@onready var _status: Label = %StatusLabel


func _ready() -> void:
	UIStyle.apply_panel(%HudPanel, UIColors.BG_PANEL)
	UIStyle.apply_button(%StartBtn, true)
	UIStyle.apply_button(%FleeBtn, false)
	%StartBtn.pressed.connect(_on_start)
	%FleeBtn.pressed.connect(func(): ScreenRouter.close_overlay())
	_build_grids()
	_status.text = "Placeholders only — combat logic later."


func _build_grids() -> void:
	_fill_grid(_ally_grid, true)
	_fill_grid(_enemy_grid, false)


func _fill_grid(grid: GridContainer, ally: bool) -> void:
	for child in grid.get_children():
		child.queue_free()
	grid.columns = COLS
	for row in range(ROWS):
		for col in range(COLS):
			var slot := PanelContainer.new()
			slot.custom_minimum_size = Vector2(56, 56)
			var bg := UIColors.BG_SLOT if ally else Color("3a2430")
			# Highlight a sample formation (front 2 rows for allies / enemies).
			var occupied := false
			if ally and col >= 3 and row >= 1 and row <= 3:
				occupied = true
			elif (not ally) and col <= 1 and row >= 1 and row <= 3:
				occupied = true
			UIStyle.apply_panel(slot, UIColors.ACCENT_DIM if occupied else bg)
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			label.add_theme_font_size_override("font_size", 14)
			if occupied:
				label.text = "H" if ally else "E"
				label.add_theme_color_override("font_color", UIColors.TEXT)
			else:
				label.text = ""
			slot.add_child(label)
			# Future: replace Label with AnimatedSprite2D child.
			grid.add_child(slot)


func _on_start() -> void:
	_status.text = "Battle started (stub). No damage sim yet."
	AppState.add_gold(25)
