extends Control
## PROFILE-01: профиль / косметика / приватность из profile.json (DEMO).

var _tab: String = "self"

func setup(_payload: Dictionary = {}) -> void:
	pass

func _ready() -> void:
	_rebuild()

func _pack() -> Dictionary:
	return ContentPackageLoader.profile_pack

func _rebuild() -> void:
	var root := $Safe/Scroll/VBox
	for c in root.get_children():
		c.queue_free()
	var pack := _pack()
	var demo: Dictionary = pack.get("demo", {})
	root.add_child(UIFactory.section_header(ContentPackageLoader.tr_key("profile.title", "Профиль")))
	root.add_child(UIFactory.muted("%s · %s" % [
		ContentPackageLoader.package_label(),
		str(pack.get("disclaimer", "DEMO")),
	], 18))

	var tabs := UIFactory.hbox(8)
	root.add_child(tabs)
	for t in [["self", "Карточка"], ["cosmetics", "Оформление"], ["privacy", "Приватность"]]:
		var b := UIFactory.fantasy_button(t[1])
		b.custom_minimum_size = Vector2(150, 44)
		var key: String = t[0]
		b.pressed.connect(func():
			_tab = key
			_rebuild()
		)
		tabs.add_child(b)

	match _tab:
		"cosmetics":
			_build_cosmetics(root, pack)
		"privacy":
			_build_privacy(root, pack)
		_:
			_build_self(root, pack, demo)

	var ach := UIFactory.fantasy_button("Достижения")
	ach.pressed.connect(func(): ScreenRouter.go("PROFILE-03"))
	root.add_child(ach)
	var back := UIFactory.fantasy_button("Назад")
	back.pressed.connect(func(): ScreenRouter.handle_back())
	root.add_child(back)

func _build_self(root: VBoxContainer, pack: Dictionary, demo: Dictionary) -> void:
	root.add_child(UIFactory.label("%s · #%s" % [
		str(demo.get("nickname", AppState.display_name)),
		str(demo.get("public_player_id", "—")),
	], 28, LunexColors.GOLD))
	root.add_child(UIFactory.muted("%s · %s · %s" % [
		str(demo.get("title_id", "")),
		str(demo.get("frame_id", "")),
		str(demo.get("avatar_id", "")),
	], 16))
	root.add_child(UIFactory.hero_portrait(Color("E8C56A"), Vector2(180, 220)))
	root.add_child(UIFactory.label("Любимый герой %s · этап %s · герои %s/45 · Башня %s" % [
		str(demo.get("favorite_hero_id", "—")),
		str(demo.get("max_stage", "—")),
		str(demo.get("owned_heroes", 0)),
		str(demo.get("tower_floor", 0)),
	], 20))
	if demo.has("guild_tag"):
		root.add_child(UIFactory.label("Гильдия [%s]" % str(demo["guild_tag"]), 22, LunexColors.CYAN))
	root.add_child(UIFactory.muted("Email / VIP / платежи скрыты по умолчанию", 16))
	var nick: Dictionary = pack.get("nickname", {})
	root.add_child(UIFactory.muted("Ник %s–%s · rename бесплатно раз в %s дн." % [
		str(nick.get("min", 3)), str(nick.get("max", 18)), str(nick.get("free_renames_period_days", 30)),
	], 16))

func _build_cosmetics(root: VBoxContainer, pack: Dictionary) -> void:
	var cos: Dictionary = pack.get("cosmetics", {})
	root.add_child(UIFactory.label("Аватары (%d)" % (cos.get("avatars", []) as Array).size(), 24, LunexColors.GOLD))
	for a in cos.get("avatars", []):
		root.add_child(UIFactory.muted("%s · %s" % [str(a.get("id", "")), str(a.get("kind", ""))], 16))
	root.add_child(UIFactory.label("Рамки", 24, LunexColors.GOLD))
	for f in cos.get("frames", []):
		root.add_child(UIFactory.muted("%s · %s / %s" % [str(f.get("id", "")), str(f.get("source", "")), str(f.get("unlock", ""))], 16))
	root.add_child(UIFactory.label("Титулы (главы + секреты)", 24, LunexColors.GOLD))
	for t in cos.get("titles", []):
		var tag := " · секрет" if bool(t.get("secret", false)) else ""
		root.add_child(UIFactory.muted("%s — %s%s" % [str(t.get("id", "")), str(t.get("name", "")), tag], 16))

func _build_privacy(root: VBoxContainer, pack: Dictionary) -> void:
	root.add_child(UIFactory.label("Приватность (дефолты пакета)", 24, LunexColors.GOLD))
	var priv: Dictionary = pack.get("privacy_defaults", {})
	for k in priv.keys():
		root.add_child(UIFactory.label("%s: %s" % [str(k), "да" if bool(priv[k]) else "нет"], 20))
	root.add_child(UIFactory.muted("Поиск по email/телефону запрещён · last_seen скрыт", 16))
