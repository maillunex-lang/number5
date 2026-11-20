extends Control
## ROOT-01: живая 2.5D карта мира

@onready var _regions: Control = $Scroll/World/Regions
@onready var _scroll: ScrollContainer = $Scroll
@onready var _title: Label = $Header/Title

func _ready() -> void:
	_title.text = "Карта мира · Элиориан"
	_build()
	$Header/ContinueBtn.pressed.connect(_on_continue)
	$Header/BackHint.text = "Выберите регион или «Продолжить»"

func _build() -> void:
	for c in _regions.get_children():
		c.queue_free()
	# Decorative parallax layers
	for i in 5:
		var layer := ColorRect.new()
		layer.size = Vector2(1000, 280)
		layer.position = Vector2(40, 80 + i * 260)
		layer.color = Color(0.1 + i * 0.02, 0.16 + i * 0.015, 0.14 + i * 0.02, 0.9)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Scroll/World/Parallax.add_child(layer)
	var regions: Array = DemoData.campaign_progress["regions"]
	for i in regions.size():
		var r: Dictionary = regions[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(420, 200)
		b.position = Vector2(120 + (i % 2) * 380, 160 + i * 240)
		b.text = "%s\n%s" % [r.name, "Открыт" if r.unlocked else "🔒 %s" % r.get("req", "")]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var unlocked: bool = r.unlocked
		var rid: String = r.id
		b.pressed.connect(func():
			if not unlocked:
				ModalManager.push_locked(str(r.name), str(r.get("req", "Недоступно")))
				return
			ScreenRouter.go("MAP-01", {"region_id": rid})
		)
		_regions.add_child(b)
		# Ambient float
		if ThemeManager.parallax_enabled and unlocked:
			var tw := create_tween().set_loops()
			tw.tween_property(b, "position:y", b.position.y - 8, 1.4).set_trans(Tween.TRANS_SINE)
			tw.tween_property(b, "position:y", b.position.y, 1.4).set_trans(Tween.TRANS_SINE)

func _on_continue() -> void:
	ScreenRouter.go("MAP-01", {"region_id": "r1", "focus_current": true})
