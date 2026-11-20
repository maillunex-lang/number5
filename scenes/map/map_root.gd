extends Control
## ROOT-01: живая 2.5D карта мира. Фон в .tscn; регионы — MapRegionButton.

@onready var _regions: Control = $Scroll/World/Regions
@onready var _world: Control = $Scroll/World
@onready var _title: Label = $Header/Title
var _float_tweens: Array[Tween] = []

const REGION_BTN := "res://scenes/ui/components/map_region_button.tscn"

func _ready() -> void:
	_title.text = ContentPackageLoader.tr_key("map.title", "Карта мира · Разлом эпох")
	_build()
	$Header/ContinueBtn.pressed.connect(_on_continue)
	DemoData.content_reloaded.connect(_build)

func _build() -> void:
	for tw in _float_tweens:
		if tw != null and is_instance_valid(tw):
			tw.kill()
	_float_tweens.clear()
	for c in _regions.get_children():
		c.queue_free()
	var regions: Array = DemoData.campaign_progress.get("regions", [])
	var scene: PackedScene = load(REGION_BTN)
	for i in regions.size():
		var r: Dictionary = regions[i]
		var b: MapRegionButton = scene.instantiate()
		var px := float(r.get("x", 120 + (i % 2) * 380))
		var py := float(r.get("y", 160 + i * 240))
		b.set_region({
			"id": r.get("id", ""),
			"name": r.get("name", ""),
			"unlocked": r.get("unlocked", false),
			"req": r.get("req", ""),
			"x": clampf(px, 16, _world.custom_minimum_size.x - 420 - 28),
			"y": py,
		})
		_world.custom_minimum_size.y = maxf(_world.custom_minimum_size.y, py + 200 + 48)
		var unlocked: bool = bool(r.unlocked)
		var rid: String = str(r.id)
		b.region_pressed.connect(func(id):
			if not unlocked:
				ModalManager.push_locked(str(r.name), str(r.get("req", "Недоступно")))
				return
			ScreenRouter.go("MAP-01", {"region_id": id if id != "" else rid})
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
