extends Control


func _ready() -> void:
	UIStyle.apply_panel(%AfkCard)
	UIStyle.apply_panel(%CampaignCard)
	UIStyle.apply_button(%BattleButton, true)
	UIStyle.apply_button(%ClaimButton, false)
	%BattleButton.pressed.connect(func(): ScreenRouter.open_battle())
	%ClaimButton.pressed.connect(_on_claim)
	_refresh()


func _refresh() -> void:
	%Welcome.text = "Welcome, %s" % AppState.player_name
	%AfkLabel.text = "AFK loot ready (stub): +%d gold" % 120
	%CampaignLabel.text = "Campaign Chapter 1 — Stage 1-3 (placeholder)"


func _on_claim() -> void:
	AppState.add_gold(120)
	%AfkLabel.text = "Claimed! Come back later (stub)."
