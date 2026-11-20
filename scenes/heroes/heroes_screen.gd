extends Control

@onready var _list: VBoxContainer = %HeroList
@onready var _detail: Label = %DetailLabel


func _ready() -> void:
	UIStyle.apply_panel(%DetailCard)
	_rebuild()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for hero in AppState.heroes:
		var btn := Button.new()
		btn.text = "%s  ·  %s  ·  Lv.%d" % [hero.name, hero.rarity, hero.level]
		btn.custom_minimum_size = Vector2(0, 64)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UIStyle.apply_button(btn, false)
		btn.pressed.connect(_show_detail.bind(hero))
		_list.add_child(btn)
	if AppState.heroes.size() > 0:
		_show_detail(AppState.heroes[0])


func _show_detail(hero: Dictionary) -> void:
	_detail.text = "%s\nRarity: %s\nFaction: %s\nLevel: %d\nPower: %d\n\n(Stub card — art & skills later)" % [
		hero.name, hero.rarity, hero.faction, hero.level, hero.power
	]
