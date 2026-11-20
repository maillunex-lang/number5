extends Control
## HERO-02: chrome в .tscn; слоты FormationSlot; сетка HeroCard.

var _payload: Dictionary = {}
var _selected_slot: int = 0

const HERO_CARD := "res://scenes/ui/components/hero_card.tscn"

@onready var _power: Label = $Safe/Scroll/VBox/PowerLabel
@onready var _presets: HBoxContainer = $Safe/Scroll/VBox/PresetsHost
@onready var _heroes: GridContainer = $Safe/Scroll/VBox/HeroesHost
@onready var _slots_row: HBoxContainer = $Safe/Scroll/VBox/SlotsRow
var _slots: Array[FormationSlot] = []

func setup(payload: Dictionary = {}) -> void:
	_payload = payload

func _ready() -> void:
	_slots.clear()
	for c in _slots_row.get_children():
		if c is FormationSlot:
			_slots.append(c)
	for i in _slots.size():
		var idx := i
		_slots[i].pressed.connect(func():
			_selected_slot = idx
			_refresh_selection()
		)
	$Safe/Scroll/VBox/BackBtn.pressed.connect(func(): ScreenRouter.handle_back())
	_rebuild()
	DemoData.squad_changed.connect(_rebuild)

func _rebuild() -> void:
	_power.text = "Сила отряда: %d" % DemoData.squad_power()
	for i in 5:
		var hid: String = DemoData.squad_slots[i] if i < DemoData.squad_slots.size() else ""
		var h := DemoData.get_hero(hid)
		if h.is_empty():
			_slots[i].clear_slot()
		else:
			_slots[i].set_hero(h)
	_refresh_selection()
	for c in _presets.get_children():
		c.queue_free()
	for p in DemoData.squad_presets:
		var b := Button.new()
		b.text = str(p.name)
		b.custom_minimum_size = Vector2(0, 52)
		b.theme_type_variation = &"GameButton"
		b.disabled = true
		_presets.add_child(b)
	for c in _heroes.get_children():
		c.queue_free()
	var card_scene: PackedScene = load(HERO_CARD)
	for h in DemoData.heroes:
		var card: HeroCard = card_scene.instantiate()
		card.card_size = Vector2(200, 260)
		card.set_hero(h)
		card.modulate = Color(0.75, 0.75, 0.78, 1) # assign disabled until server API
		_heroes.add_child(card)

func _refresh_selection() -> void:
	for i in _slots.size():
		_slots[i].modulate = Color(1.15, 1.08, 0.9) if i == _selected_slot else Color.WHITE
