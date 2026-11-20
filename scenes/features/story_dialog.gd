extends Control
## DIALOG-01: сюжетные сцены из dialogs.json (DEMO).

var _payload: Dictionary = {}
var _dialog: Dictionary = {}
var _line_i: int = 0

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	var did := str(_payload.get("dialog_id", ""))
	var stage_id := str(_payload.get("stage_id", ""))
	var pack: Dictionary = ContentPackageLoader.dialogs_pack
	if did != "":
		for d in pack.get("dialogs", []):
			if str(d.get("id", "")) == did:
				_dialog = d
				break
	elif stage_id != "":
		var timing := str(_payload.get("timing", "before"))
		for d in pack.get("dialogs", []):
			if str(d.get("stage_id", "")) == stage_id and str(d.get("timing", "")) == timing:
				_dialog = d
				break
		if _dialog.is_empty():
			for d in pack.get("dialogs", []):
				if str(d.get("stage_id", "")) == stage_id:
					_dialog = d
					break
	if _dialog.is_empty():
		NotificationManager.error("Диалог не найден")
		_finish()
		return
	_line_i = 0
	_rebuild()

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("dialogs.title", "Диалог")))
	root.add_child(UIFactory.muted("%s · %s · %s" % [
		ContentPackageLoader.package_label(),
		str(_dialog.get("id", "")),
		str(_dialog.get("note", "")),
	], 16))
	var lines: Array = _dialog.get("lines", [])
	if _line_i < 0 or _line_i >= lines.size():
		_finish()
		return
	var line: Dictionary = lines[_line_i]
	var p := UIFactory.panel()
	var v := UIFactory.vbox(8)
	p.add_child(v)
	v.add_child(UIFactory.label(str(line.get("speaker", "")), 26, LunexColors.GOLD))
	v.add_child(UIFactory.label(str(line.get("text", "")), 24))
	v.add_child(UIFactory.muted("%d / %d" % [_line_i + 1, lines.size()], 16))
	root.add_child(p)

	var row := UIFactory.hbox(10)
	root.add_child(row)
	var next := UIFactory.gold_button("Далее" if _line_i < lines.size() - 1 else "Готово")
	next.pressed.connect(func():
		_line_i += 1
		if _line_i >= lines.size():
			_finish()
		else:
			_rebuild()
	)
	row.add_child(next)
	var skip := UIFactory.fantasy_button("Пропустить")
	skip.pressed.connect(_finish)
	row.add_child(skip)

func _finish() -> void:
	var next_route := str(_payload.get("next_route", ""))
	var next_payload: Dictionary = _payload.get("next_payload", {})
	if next_route != "":
		ScreenRouter.go(next_route, next_payload)
	else:
		ScreenRouter.handle_back()
