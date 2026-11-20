extends Node
## MODAL-UI-001 C — очередь тематических окон. Блокировка двойного подтверждения.

signal modal_opened(id: String)
signal modal_closed(id: String)
signal queue_changed

var _stack: Array[Dictionary] = []
var _busy_ids: Dictionary = {} # id -> true while pending confirm
var host: Node = null # assigned by GameShell / overlays
var _fallback_layer: CanvasLayer = null
var _fallback_root: Control = null

func bind_host(h: Node) -> void:
	host = h

func _ensure_fallback() -> void:
	if host != null:
		return
	if _fallback_layer != null:
		return
	_fallback_layer = CanvasLayer.new()
	_fallback_layer.layer = 100
	_fallback_layer.name = "ModalFallback"
	add_child(_fallback_layer)
	_fallback_root = Control.new()
	_fallback_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fallback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fallback_layer.add_child(_fallback_root)

func is_open() -> bool:
	return _stack.size() > 0

func top() -> Dictionary:
	if _stack.is_empty():
		return {}
	return _stack.back()

func push_confirm(title: String, body: String, on_yes: Callable = Callable(), on_no: Callable = Callable(), id: String = "") -> void:
	var mid := id if id != "" else "confirm_%d" % Time.get_ticks_msec()
	_stack.append({
		"id": mid,
		"type": "confirm",
		"title": title,
		"body": body,
		"on_yes": on_yes,
		"on_no": on_no,
	})
	_refresh()
	modal_opened.emit(mid)

func push_info(title: String, body: String, id: String = "") -> void:
	var mid := id if id != "" else "info_%d" % Time.get_ticks_msec()
	_stack.append({
		"id": mid,
		"type": "info",
		"title": title,
		"body": body,
	})
	_refresh()
	modal_opened.emit(mid)

func push_rewards(title: String, rewards: Array, id: String = "") -> void:
	var mid := id if id != "" else "rewards_%d" % Time.get_ticks_msec()
	_stack.append({
		"id": mid,
		"type": "rewards",
		"title": title,
		"rewards": rewards,
	})
	_refresh()
	modal_opened.emit(mid)
	AudioManager.play_reward()

func push_locked(feature: String, requirement: String) -> void:
	push_info("Пока недоступно", "%s\n\nУсловие открытия:\n%s" % [feature, requirement], "locked_%s" % feature)

func close_top() -> bool:
	if _stack.is_empty():
		return false
	var m: Dictionary = _stack.pop_back()
	var mid: String = m.get("id", "")
	_busy_ids.erase(mid)
	_refresh()
	modal_closed.emit(mid)
	queue_changed.emit()
	return true

func confirm_yes() -> void:
	if _stack.is_empty():
		return
	var m: Dictionary = _stack.back()
	var mid: String = m.get("id", "")
	if _busy_ids.get(mid, false):
		return
	_busy_ids[mid] = true
	var cb: Callable = m.get("on_yes", Callable())
	close_top()
	if cb.is_valid():
		cb.call()

func confirm_no() -> void:
	if _stack.is_empty():
		return
	var m: Dictionary = _stack.back()
	var cb: Callable = m.get("on_no", Callable())
	close_top()
	if cb.is_valid():
		cb.call()

func _refresh() -> void:
	queue_changed.emit()
	if host and host.has_method("refresh_modals"):
		host.call("refresh_modals", _stack)
		return
	_ensure_fallback()
	_draw_fallback()

func _draw_fallback() -> void:
	if _fallback_root == null:
		return
	for c in _fallback_root.get_children():
		c.queue_free()
	if _stack.is_empty():
		_fallback_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	_fallback_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var m: Dictionary = _stack.back()
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.62)
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			pass
	)
	_fallback_root.add_child(dim)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(720, 0)
	card.offset_left = -360
	card.offset_right = 360
	card.offset_top = -220
	card.offset_bottom = 220
	card.add_theme_stylebox_override("panel", UIFactory.panel_style(LunexColors.BG_PANEL, LunexColors.GOLD, 18, 2))
	_fallback_root.add_child(card)
	var v := UIFactory.vbox(16)
	card.add_child(v)
	v.add_child(UIFactory.title(str(m.get("title", "")), 34))
	var body := UIFactory.label(str(m.get("body", "")), 26, LunexColors.TEXT_SECONDARY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	if m.get("type", "") == "rewards":
		for r in m.get("rewards", []):
			v.add_child(UIFactory.label("• %s" % str(r), 24, LunexColors.GOLD))
	var row := UIFactory.hbox(12)
	v.add_child(row)
	if m.get("type", "") == "confirm":
		var yes := UIFactory.gold_button("Да")
		yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		yes.pressed.connect(confirm_yes)
		row.add_child(yes)
		var no := UIFactory.fantasy_button("Нет")
		no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		no.pressed.connect(confirm_no)
		row.add_child(no)
	else:
		var ok := UIFactory.gold_button("Понятно")
		ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ok.pressed.connect(close_top)
		row.add_child(ok)
