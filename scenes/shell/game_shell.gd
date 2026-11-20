extends Control
## GameShell: TopBar + BottomNav + ScreenRouter host + Modal/Toast layers.

@onready var _tab_host: Control = $SafeArea/Col/Body/TabHost
@onready var _overlay_host: Control = $OverlayLayer/OverlayHost
@onready var _modal_host: Control = $ModalLayer/ModalHost
@onready var _toast_host: VBoxContainer = $ToastLayer/Safe/Toasts
@onready var _transition: ColorRect = $TransitionLayer/Fade
@onready var _top_bar = $SafeArea/Col/TopBar
@onready var _bottom_nav = $SafeArea/Col/BottomNav
@onready var _blocker: ColorRect = $BlockerLayer/Blocker
@onready var _safe_area: MarginContainer = $SafeArea

var _tabs: Dictionary = {}
var _overlay_stack: Array[Control] = []
var _current_tab: String = "hub"

func _ready() -> void:
	ScreenRouter.bind_shell(self)
	ModalManager.bind_host(self)
	NotificationManager.toast_requested.connect(_on_toast)
	ModalManager.queue_changed.connect(func(): refresh_modals(ModalManager._stack))
	_blocker.visible = false
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition.modulate.a = 0.0
	_transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_android_safe_area()
	_load_tabs()
	_top_bar.setup(self)
	_bottom_nav.setup(self)
	ScreenRouter.switch_tab(UIStateManager.current_tab if UIStateManager.current_tab != "" else "hub")

func _apply_android_safe_area() -> void:
	# Android display safe-area is in physical screen pixels; Godot UI is in logical viewport units.
	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	var safe := DisplayServer.get_display_safe_area()
	var scale_y := viewport_size.y / maxf(float(window_size.y), 1.0)
	var scale_x := viewport_size.x / maxf(float(window_size.x), 1.0)
	var top_inset := maxf(float(safe.position.y) * scale_y, 0.0)
	var right_inset := maxf(float(window_size.x - safe.end.x) * scale_x, 0.0)
	# Reserve enough space for camera cutouts even when Android reports an empty safe-area.
	var top_margin := maxi(110, ceili(top_inset) + 20) if OS.has_feature("android") else 16
	_safe_area.add_theme_constant_override("margin_top", top_margin)
	_safe_area.add_theme_constant_override("margin_right", maxi(0, ceili(right_inset)))
	print("ANDROID_SAFE_AREA: top=", top_margin, " right=", right_inset, " screen=", window_size)

func _load_tabs() -> void:
	var paths := {
		"map": "res://scenes/map/map_root.tscn",
		"heroes": "res://scenes/heroes/heroes_root.tscn",
		"hub": "res://scenes/hub/hub_root.tscn",
		"battle": "res://scenes/battle/battle_modes_root.tscn",
	}
	for k in paths:
		var sc: PackedScene = load(paths[k])
		var node: Control = sc.instantiate()
		node.name = "Tab_%s" % k
		node.visible = false
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_tab_host.add_child(node)
		_tabs[k] = node

func show_tab(tab: String) -> void:
	if tab not in _tabs:
		return
	_current_tab = tab
	UIStateManager.remember_tab(tab)
	for k in _tabs:
		_tabs[k].visible = (k == tab)
	_bottom_nav.set_active(tab)
	_top_bar.refresh()
	# Nested overlays closed when switching tabs via nav — без покадрового rewind.
	clear_overlays()
	_update_chrome()

func _update_chrome() -> void:
	var hide_chrome := has_overlay() and _is_fullscreen_overlay()
	_bottom_nav.visible = not hide_chrome
	# Top bar stays for most overlays except combat playback
	var top_hide := false
	if has_overlay():
		var top_name := String(_overlay_stack.back().name)
		top_hide = top_name.begins_with("COMBAT-02") or top_name.begins_with("COMBAT-03")
	_top_bar.visible = not top_hide

func _is_fullscreen_overlay() -> bool:
	if not has_overlay():
		return false
	var n := String(_overlay_stack.back().name)
	return n.begins_with("COMBAT-") or n.begins_with("HUB-01") or n.begins_with("MAP-")

func has_overlay() -> bool:
	return _overlay_stack.size() > 0

## Сбросить весь стек оверлеев сразу, не показывая промежуточные экраны.
func clear_overlays() -> void:
	while not _overlay_stack.is_empty():
		var n: Control = _overlay_stack.pop_back()
		n.hide()
		n.queue_free()
	_update_chrome()

func open_overlay(route_id: String, scene_path: String, payload: Dictionary = {}) -> void:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		NotificationManager.warn("Экран %s недоступен" % route_id)
		return
	_blocker.visible = true
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade(true)
	# Replace same-level overlay of same route if reopening
	var sc: PackedScene = AssetLoader.get_cached(scene_path) as PackedScene
	if sc == null:
		sc = load(scene_path)
	var node: Control = sc.instantiate()
	node.name = route_id
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if node.has_method("setup"):
		node.call("setup", payload)
	if has_overlay():
		_overlay_stack.back().hide()
	_overlay_host.add_child(node)
	_overlay_stack.append(node)
	_update_chrome()
	await _fade(false)
	_blocker.visible = false
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	AudioManager.play_ui_tap()

func close_overlay() -> void:
	if not has_overlay():
		return
	_blocker.visible = true
	await _fade(true)
	var n: Control = _overlay_stack.pop_back()
	n.hide()
	n.queue_free()
	if has_overlay():
		_overlay_stack.back().show()
	_update_chrome()
	await _fade(false)
	_blocker.visible = false
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fade(out: bool) -> void:
	var ms := ThemeManager.transition_ms / 1000.0
	_transition.mouse_filter = Control.MOUSE_FILTER_STOP if out else Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(_transition, "modulate:a", 1.0 if out else 0.0, ms * 0.5)
	await tw.finished

func refresh_modals(stack: Array) -> void:
	for c in _modal_host.get_children():
		c.queue_free()
	if stack.is_empty():
		_modal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	_modal_host.mouse_filter = Control.MOUSE_FILTER_STOP
	var m: Dictionary = stack.back()
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.06, 0.7)
	_modal_host.add_child(dim)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -380
	card.offset_right = 380
	card.offset_top = -260
	card.offset_bottom = 260
	card.add_theme_stylebox_override("panel", UIFactory.panel_style(LunexColors.BG_PANEL, LunexColors.GOLD, 20, 2))
	_modal_host.add_child(card)
	var v := UIFactory.vbox(18)
	card.add_child(v)
	v.add_child(UIFactory.title(str(m.get("title", "")), 36))
	var body := UIFactory.label(str(m.get("body", "")), 26, LunexColors.TEXT_SECONDARY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	if m.get("type", "") == "rewards":
		for r in m.get("rewards", []):
			v.add_child(UIFactory.label("✦ %s" % str(r), 26, LunexColors.GOLD_BRIGHT))
	var row := UIFactory.hbox(12)
	v.add_child(row)
	match str(m.get("type", "")):
		"confirm":
			var yes := UIFactory.gold_button("Подтвердить")
			yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			yes.pressed.connect(ModalManager.confirm_yes)
			row.add_child(yes)
			var no := UIFactory.fantasy_button("Отмена")
			no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			no.pressed.connect(ModalManager.confirm_no)
			row.add_child(no)
		_:
			var ok := UIFactory.gold_button("Закрыть")
			ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ok.pressed.connect(ModalManager.close_top)
			row.add_child(ok)
	card.scale = Vector2(0.92, 0.92)
	card.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.18)

func _on_toast(text: String, kind: String) -> void:
	var color := LunexColors.TEXT_PRIMARY
	match kind:
		"success": color = LunexColors.EMERALD
		"warn": color = LunexColors.AMBER
		"error": color = LunexColors.TEXT_DANGER
		_: color = LunexColors.CYAN
	var p := UIFactory.panel(Color(0.07, 0.1, 0.16, 0.92))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UIFactory.panel_style(Color(0.07, 0.1, 0.16, 0.92), color, 14, 2))
	var l := UIFactory.label(text, 24, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	_toast_host.add_child(p)
	p.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)

func on_nav(tab: String) -> void:
	if has_overlay():
		# Switching tab closes overlays via show_tab
		pass
	ScreenRouter.switch_tab(tab)

func on_open_route(route_id: String, payload: Dictionary = {}) -> void:
	ScreenRouter.go(route_id, payload)
