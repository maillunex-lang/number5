extends Control

var _channel := "World"
@onready var _feed: VBoxContainer = %Feed
@onready var _input: LineEdit = %MessageInput


func _ready() -> void:
	UIStyle.apply_panel(%ChatPanel)
	UIStyle.apply_button(%WorldBtn, true)
	UIStyle.apply_button(%GuildBtn, false)
	UIStyle.apply_button(%CloseBtn, false)
	UIStyle.apply_button(%SendBtn, true)
	%WorldBtn.pressed.connect(func(): _set_channel("World"))
	%GuildBtn.pressed.connect(func(): _set_channel("Guild"))
	%CloseBtn.pressed.connect(func(): ScreenRouter.close_overlay())
	%SendBtn.pressed.connect(_send)
	_input.text_submitted.connect(func(_t): _send())
	_rebuild()


func _set_channel(ch: String) -> void:
	_channel = ch
	UIStyle.apply_button(%WorldBtn, ch == "World")
	UIStyle.apply_button(%GuildBtn, ch == "Guild")
	_rebuild()


func _rebuild() -> void:
	for child in _feed.get_children():
		child.queue_free()
	for msg in AppState.chat_messages:
		if msg.channel != _channel:
			continue
		var lbl := Label.new()
		lbl.text = "[%s] %s: %s" % [msg.channel, msg.user, msg.text]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", UIColors.TEXT)
		_feed.add_child(lbl)


func _send() -> void:
	var text := _input.text.strip_edges()
	if text.is_empty():
		return
	AppState.chat_messages.append({
		"channel": _channel,
		"user": AppState.player_name,
		"text": text,
	})
	_input.text = ""
	_rebuild()
