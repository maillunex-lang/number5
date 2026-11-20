extends Control
## Предпросмотр UI без авторизации и сервера. Открыть сцену в редакторе (F6).

@onready var _host: Control = $Safe/Body/PreviewHost
@onready var _hint: Label = $Safe/Body/Hint

const PAGES := {
	"Компоненты": "_show_components",
	"TopBar": "_show_top_bar",
	"BottomNav": "_show_bottom_nav",
	"Battle Result": "_show_battle_result",
	"Feature Screen": "_show_feature_screen",
	"Hero Card": "_show_hero_card",
	"Settings scaffold": "_show_settings",
}

func _ready() -> void:
	var row: HBoxContainer = $Safe/Body/Tabs
	for title in PAGES.keys():
		var b := UIFactory.fantasy_button(str(title), 56)
		var method: String = PAGES[title]
		b.pressed.connect(func(): call(method))
		row.add_child(b)
	_show_components()

func _clear_host() -> void:
	for c in _host.get_children():
		c.queue_free()

func _show_components() -> void:
	_clear_host()
	_hint.text = "Библиотека компонентов · без сервера"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(col)
	col.add_child(UIFactory.title("Game / Gold buttons", 32))
	col.add_child(UIFactory.fantasy_button("Обычная кнопка"))
	col.add_child(UIFactory.gold_button("Золотая кнопка"))
	var rc: ResourceCounter = (load("res://scenes/ui/components/resource_counter.tscn") as PackedScene).instantiate()
	rc.caption = "Золото"
	rc.value_text = "12.4K"
	col.add_child(rc)
	var meter: ProgressMeter = (load("res://scenes/ui/components/progress_meter.tscn") as PackedScene).instantiate()
	meter.title = "VIP прогресс"
	meter.set_progress(40, 100)
	col.add_child(meter)
	var reward: RewardCard = (load("res://scenes/ui/components/reward_card.tscn") as PackedScene).instantiate()
	reward.line_text = "Алмазы ×50"
	col.add_child(reward)

func _show_top_bar() -> void:
	_clear_host()
	_hint.text = "TopBar · preview тексты из Inspector экспортов"
	var bar: Control = (load("res://scenes/shell/top_bar.tscn") as PackedScene).instantiate()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size.y = 158
	_host.add_child(bar)

func _show_bottom_nav() -> void:
	_clear_host()
	_hint.text = "BottomNav · 4 вкладки"
	var nav: Control = (load("res://scenes/shell/bottom_nav.tscn") as PackedScene).instantiate()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.custom_minimum_size.y = 156
	_host.add_child(nav)

func _show_battle_result() -> void:
	_clear_host()
	_hint.text = "COMBAT-03 chrome · без claim (нет battle_id)"
	var sc: Control = (load("res://scenes/battle/battle_result.tscn") as PackedScene).instantiate()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if sc.has_method("setup"):
		sc.call("setup", {"victory": true, "stage_id": "CH01-01", "mode": "campaign"})
	_host.add_child(sc)

func _show_feature_screen() -> void:
	_clear_host()
	_hint.text = "FeatureScreen scaffold"
	var sc: FeatureScreen = (load("res://scenes/ui/components/feature_screen.tscn") as PackedScene).instantiate()
	sc.screen_title = "Демо-раздел"
	sc.screen_subtitle = "Предпросмотр без онлайна"
	sc.show_back_button = false
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(sc)
	sc.clear_dynamic()
	sc.dynamic_host.add_child(UIFactory.label("Сюда код кладёт динамические карточки.", 24))
	sc.dynamic_host.add_child(UIFactory.fantasy_button("Пример действия"))

func _show_hero_card() -> void:
	_clear_host()
	_hint.text = "HeroCard template"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_host.add_child(row)
	for sample in [
		{"id": "H01", "name": "Айлэрис", "power": 2866, "tint": Color("5EC8E8")},
		{"id": "H02", "name": "Герой 2", "power": 2100, "tint": Color("E8C56A")},
	]:
		var card: HeroCard = (load("res://scenes/ui/components/hero_card.tscn") as PackedScene).instantiate()
		card.set_hero(sample)
		row.add_child(card)

func _show_settings() -> void:
	_clear_host()
	_hint.text = "Settings scaffold (.tscn) — без заполнения вкладок"
	var sc: Control = (load("res://scenes/features/settings.tscn") as PackedScene).instantiate()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(sc)
