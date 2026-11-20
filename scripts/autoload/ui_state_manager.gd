extends Node
## UI-STATE-001 B: вкладка, прокрутка, выбранный герой, фильтры (сессия).

var current_tab: String = "hub" # map | heroes | hub | battle
var hub_scroll_y: float = 0.0
var map_scroll: Vector2 = Vector2.ZERO
var heroes_scroll_y: float = 0.0
var selected_hero_id: String = ""
var hero_filter_faction: String = ""
var hero_filter_rarity: String = ""
var hero_filter_class: String = ""
var hero_sort: String = "power"
var hero_search: String = ""
var last_combat_context: Dictionary = {} # mode, stage_id, return_route
var battle_modes_scroll: Vector2 = Vector2.ZERO

func remember_tab(tab: String) -> void:
	current_tab = tab

func set_hero_selection(hero_id: String) -> void:
	selected_hero_id = hero_id
	DemoData.selected_hero_id = hero_id

func set_combat_context(ctx: Dictionary) -> void:
	last_combat_context = ctx.duplicate(true)

func clear_combat_context() -> void:
	last_combat_context.clear()
