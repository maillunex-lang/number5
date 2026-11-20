extends Control

@onready var _body: Label = %BodyLabel
var _tab := "overview"


func _ready() -> void:
	UIStyle.apply_panel(%BodyCard)
	for btn_path in [%OverviewBtn, %MembersBtn, %QuestsBtn]:
		UIStyle.apply_button(btn_path, false)
	%OverviewBtn.pressed.connect(func(): _set_tab("overview"))
	%MembersBtn.pressed.connect(func(): _set_tab("members"))
	%QuestsBtn.pressed.connect(func(): _set_tab("quests"))
	_set_tab("overview")


func _set_tab(tab: String) -> void:
	_tab = tab
	UIStyle.apply_button(%OverviewBtn, tab == "overview")
	UIStyle.apply_button(%MembersBtn, tab == "members")
	UIStyle.apply_button(%QuestsBtn, tab == "quests")
	match tab:
		"overview":
			_body.text = "Guild: Ember Pact\nLevel 3 · 28 / 40 members\nBanner & perks TBD.\n\nThis is a shell — join/create guild via VPS later."
		"members":
			_body.text = "Members (stub)\n• IronHowl — Leader\n• MossWitch — Officer\n• AshRunner — Member\n• Cinder — Member\n• TideGuard — Member"
		"quests":
			_body.text = "Guild Quests (stub)\n1. Clear 20 campaign stages — 0/20\n2. Donate 5k gold — 0/5000\n3. Win 3 arena matches — 0/3"
