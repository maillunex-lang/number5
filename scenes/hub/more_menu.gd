extends Control


func _ready() -> void:
	UIStyle.apply_panel(%MenuCard)
	UIStyle.apply_button(%ChatBtn, true)
	UIStyle.apply_button(%BattleBtn, false)
	UIStyle.apply_button(%LogoutBtn, false)
	%ChatBtn.pressed.connect(func(): ScreenRouter.open_chat())
	%BattleBtn.pressed.connect(func(): ScreenRouter.open_battle())
	%LogoutBtn.pressed.connect(func(): ScreenRouter.request_logout())
