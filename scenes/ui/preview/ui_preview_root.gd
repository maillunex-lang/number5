extends Control
## Предпросмотр UI без авторизации и сервера. Открыть сцену в редакторе (F6).

@onready var _host: Control = $Safe/Body/PreviewHost
@onready var _hint: Label = $Safe/Body/Hint

const PAGES := {
	"Компоненты": "_show_components",
	"TopBar": "_show_top_bar",
	"BottomNav": "_show_bottom_nav",
	"Battle Result": "_show_battle_result",
	"Battle Unit": "_show_battle_unit",
	"Hub Building": "_show_hub_building",
	"Feature Screen": "_show_feature_screen",
	"Hero Card": "_show_hero_card",
	"Mail / Shop": "_show_mail_shop",
	"Formation / Map": "_show_wave3",
	"Settings scaffold": "_show_settings",
	"Wave4 Heroes/Auth": "_show_wave4",
	"Wave5 VIP/Social/Result": "_show_wave5",
	"Wave5+ Chat/Friends/Rank": "_show_wave5_plus",
	"Wave6 demos": "_show_wave6",
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

func _show_battle_unit() -> void:
	_clear_host()
	_hint.text = "BattleUnit template"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	_host.add_child(row)
	for sample in [
		{"id": "H01", "name": "Айлэрис", "side": "ally", "hp": 2000, "max_hp": 2500, "energy": 40, "tint": Color("5EC8E8")},
		{"id": "E01", "name": "Враг", "side": "enemy", "hp": 800, "max_hp": 1200, "energy": 10, "tint": Color("8A4A5A")},
	]:
		var u: BattleUnit = (load("res://scenes/ui/components/battle_unit.tscn") as PackedScene).instantiate()
		u.set_unit(sample)
		row.add_child(u)

func _show_hub_building() -> void:
	_clear_host()
	_hint.text = "HubBuilding template · позиция в игре из hub.json"
	var b: HubBuilding = (load("res://scenes/ui/components/hub_building.tscn") as PackedScene).instantiate()
	b.set_building({
		"id": "shop", "name": "Лавка", "x": 200, "y": 200, "w": 200, "h": 160,
		"color": Color("E8C56A"), "locked": false, "route": "HUB-06",
	}, 0.5)
	b.position = Vector2(40, 40)
	_host.add_child(b)

func _show_mail_shop() -> void:
	_clear_host()
	_hint.text = "MailItem + ShopOfferCard"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(col)
	var mail: MailItem = (load("res://scenes/ui/components/mail_item.tscn") as PackedScene).instantiate()
	mail.set_mail({
		"id": "m1", "category": "reward", "status": "unread",
		"subject": "Ежедневная награда", "body": "Заберите золото",
		"attachments": [{"resource_id": "gold", "amount": 500}],
	})
	col.add_child(mail)
	var offer: ShopOfferCard = (load("res://scenes/ui/components/shop_offer_card.tscn") as PackedScene).instantiate()
	offer.set_offer({
		"sku": "diamond_s", "title": "Горсть алмазов",
		"grants": [{"resource_id": "diamonds", "amount": 100}],
		"nominal_price_rub": 99, "payable_price_rub": 0, "cta": "Получить бесплатно",
	})
	col.add_child(offer)

func _show_wave3() -> void:
	_clear_host()
	_hint.text = "Wave3: FormationSlot · StageListItem · MapRegionButton"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(col)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	col.add_child(slots)
	for sample in [
		{"name": "Айлэрис", "tint": Color("5EC8E8")},
		{},
		{"name": "Герой 3", "tint": Color("E8C56A")},
	]:
		var slot: FormationSlot = (load("res://scenes/ui/components/formation_slot.tscn") as PackedScene).instantiate()
		if sample.is_empty():
			slot.clear_slot()
		else:
			slot.set_hero(sample)
		slots.add_child(slot)
	var stage: StageListItem = (load("res://scenes/ui/components/stage_list_item.tscn") as PackedScene).instantiate()
	stage.set_stage({
		"id": "CH01-01", "name": "Первый шаг", "type": "main", "state": "available",
		"power": 1200, "rewards": ["gold", "hero_xp"],
	})
	col.add_child(stage)
	var region: MapRegionButton = (load("res://scenes/ui/components/map_region_button.tscn") as PackedScene).instantiate()
	region.set_region({"id": "CH01", "name": "Уфимский разлом", "unlocked": true, "x": 0, "y": 0})
	col.add_child(region)

func _show_settings() -> void:
	_clear_host()
	_hint.text = "Settings chrome (.tscn) · вкладки в сцене, DynamicHost"
	var sc: Control = (load("res://scenes/features/settings.tscn") as PackedScene).instantiate()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(sc)

func _show_wave4() -> void:
	_clear_host()
	_hint.text = "Wave4: HeroDetails · SquadManager · Auth chrome"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(col)
	for path in [
		"res://scenes/heroes/hero_details.tscn",
		"res://scenes/heroes/squad_manager.tscn",
		"res://scenes/bootstrap/auth.tscn",
	]:
		var btn := UIFactory.fantasy_button(path.get_file(), 56)
		var p: String = path
		btn.pressed.connect(func():
			_clear_host()
			_hint.text = p
			var sc: Control = (load(p) as PackedScene).instantiate()
			sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			if sc.has_method("setup"):
				sc.call("setup", {"hero_id": "H01", "region_id": "CH01"})
			_host.add_child(sc)
		)
		col.add_child(btn)

func _show_wave5() -> void:
	_clear_host()
	_hint.text = "Wave5: BattleResult · VIP · SocialHub"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(col)
	for path in [
		"res://scenes/battle/battle_result.tscn",
		"res://scenes/features/vip.tscn",
		"res://scenes/features/social_hub.tscn",
	]:
		var btn := UIFactory.fantasy_button(path.get_file(), 56)
		var p: String = path
		btn.pressed.connect(func():
			_clear_host()
			_hint.text = p
			var sc: Control = (load(p) as PackedScene).instantiate()
			sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			if sc.has_method("setup"):
				sc.call("setup", {"victory": true, "battle_id": "", "stage_id": "CH01-01"})
			_host.add_child(sc)
		)
		col.add_child(btn)

func _show_wave5_plus() -> void:
	_clear_host()
	_hint.text = "Wave5+: Chat · Friends · Rankings"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(col)
	for path in [
		"res://scenes/features/chat.tscn",
		"res://scenes/features/friends.tscn",
		"res://scenes/features/rankings.tscn",
	]:
		var btn := UIFactory.fantasy_button(path.get_file(), 56)
		var p: String = path
		btn.pressed.connect(func():
			_clear_host()
			_hint.text = p
			var sc: Control = (load(p) as PackedScene).instantiate()
			sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_host.add_child(sc)
		)
		col.add_child(btn)

func _show_wave6() -> void:
	_clear_host()
	_hint.text = "Wave6: BattlePass · PvP · Profile · Rewards · Sys"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.add_child(col)
	for path in [
		"res://scenes/features/battle_pass.tscn",
		"res://scenes/features/pvp_center.tscn",
		"res://scenes/features/pvp_defense.tscn",
		"res://scenes/features/profile_public.tscn",
		"res://scenes/features/rewards_panel.tscn",
		"res://scenes/features/sys_download.tscn",
		"res://scenes/features/sys_error.tscn",
	]:
		var btn := UIFactory.fantasy_button(path.get_file(), 56)
		var p: String = path
		btn.pressed.connect(func():
			_clear_host()
			_hint.text = p
			var sc: Control = (load(p) as PackedScene).instantiate()
			sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_host.add_child(sc)
		)
		col.add_child(btn)
