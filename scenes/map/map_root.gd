extends Control
## ROOT-01: живая 2.5D карта мира (регионы из контент-пакета)

@onready var _regions: Control = $Scroll/World/Regions
@onready var _scroll: ScrollContainer = $Scroll
@onready var _title: Label = $Header/Title
var _float_tweens: Array[Tween] = []

func _ready() -> void:
	_title.text = ContentPackageLoader.tr_key("map.title", "Карта мира · Разлом эпох")
	_build()
	$Header/ContinueBtn.pressed.connect(_on_continue)
	$Header/BackHint.text = "Выберите регион для просмотра этапов"
	DemoData.content_reloaded.connect(_build)

func _build() -> void:
	for tw in _float_tweens:
		if tw != null and is_instance_valid(tw):
			tw.kill()
	_float_tweens.clear()
	for c in _regions.get_children():
		c.queue_free()
	for c in $Scroll/World/Parallax.get_children():
		c.queue_free()
	var landscape := TextureRect.new()
	landscape.texture = preload("res://assets/login/background.webp")
	landscape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	landscape.modulate = Color(0.42, 0.52, 0.56)
	landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Scroll/World/Parallax.add_child(landscape)
	var regions: Array = DemoData.campaign_progress.get("regions", [])
	for i in regions.size():
		var r: Dictionary = regions[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(420, 200)
		var px := float(r.get("x", 120 + (i % 2) * 380))
		var py := float(r.get("y", 160 + i * 240))
		b.position = Vector2(clampf(px, 16, $Scroll/World.custom_minimum_size.x - b.custom_minimum_size.x - 28), py)
		$Scroll/World.custom_minimum_size.y = maxf($Scroll/World.custom_minimum_size.y, py + b.custom_minimum_size.y + 48)
		b.text = "%s\n%s" % [r.name, "Открыт" if r.unlocked else "Закрыто · %s" % r.get("req", "")]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var unlocked: bool = bool(r.unlocked)
		var rid: String = str(r.id)
		b.pressed.connect(func():
			if not unlocked:
				ModalManager.push_locked(str(r.name), str(r.get("req", "Недоступно")))
				return
			ScreenRouter.go("MAP-01", {"region_id": rid})
		)
		_regions.add_child(b)
		if ThemeManager.parallax_enabled and unlocked and DisplayServer.get_name() != "headless":
			var tw := create_tween().set_loops()
			tw.tween_property(b, "position:y", b.position.y - 8, 1.4).set_trans(Tween.TRANS_SINE)
			tw.tween_property(b, "position:y", b.position.y, 1.4).set_trans(Tween.TRANS_SINE)
			_float_tweens.append(tw)

func _on_continue() -> void:
	var ch := str(DemoData.campaign_progress.get("chapter_id", "CH01"))
	ScreenRouter.go("MAP-01", {"region_id": ch, "focus_current": true})
