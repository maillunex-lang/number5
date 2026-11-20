extends Node
## Отложенная загрузка и кеш текстур. ART-05: портреты/атласы из content package media/.

signal load_progress(done: int, total: int, label: String)
signal load_finished

const HERO_CLIPS := ["idle", "attack", "hit", "death"]
const FRAME := 128

var _cache: Dictionary = {} # path -> Resource
var _active_loads: int = 0
var texture_budget_mb: float = 96.0
var _anim_cache: Dictionary = {} # key -> Dictionary

func get_cached(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var res := load(path) if ResourceLoader.exists(path) else null
		if res == null and FileAccess.file_exists(path):
			# Raw image not yet imported — ImageTexture from file bytes.
			var img := Image.new()
			if img.load(path) == OK:
				res = ImageTexture.create_from_image(img)
		if res != null:
			_cache[path] = res
			return res
	return null

func package_media_path(rel: String) -> String:
	var base := ContentPackageLoader.source_path
	if base == "":
		base = "res://content/packages/%s" % ContentPackageLoader.version
	return "%s/%s" % [base, rel.lstrip("/")]

func load_package_texture(rel_path: String) -> Texture2D:
	if rel_path == "":
		return null
	var path := package_media_path(rel_path)
	var tex: Resource = get_cached(path)
	return tex as Texture2D

func hero_portrait(hero_id: String) -> Texture2D:
	if hero_id == "":
		return null
	var tex := load_package_texture("media/heroes/%s/portrait.webp" % hero_id.to_lower())
	if tex != null:
		return tex
	# binding fallback
	var item: Dictionary = ContentPackageLoader.resolve_asset("hero.%s.portrait" % hero_id)
	return load_package_texture(str(item.get("path", "")))

func hero_atlas(hero_id: String) -> Texture2D:
	if hero_id == "":
		return null
	return load_package_texture("media/heroes/%s/atlas.webp" % hero_id.to_lower())

func hero_anim_doc(hero_id: String) -> Dictionary:
	var key := "hero_anim:%s" % hero_id
	if _anim_cache.has(key):
		return _anim_cache[key]
	var path := package_media_path("media/heroes/%s/animations.json" % hero_id.to_lower())
	var doc := _read_json(path)
	_anim_cache[key] = doc
	return doc

func enemy_atlas(enemy_id: String) -> Texture2D:
	var rig := _rig_for_enemy(enemy_id)
	if rig.is_empty():
		return null
	var prefix := str(rig.get("asset_prefix", ""))
	if prefix == "":
		return null
	return load_package_texture("%s/atlas.webp" % prefix)

func enemy_skin(enemy_id: String) -> Texture2D:
	var meta := _enemy_meta(enemy_id)
	var rig := _rig_for_enemy(enemy_id)
	if rig.is_empty():
		return null
	var prefix := str(rig.get("asset_prefix", ""))
	var skin := str(meta.get("skin_id", "skin_a"))
	return load_package_texture("%s/%s.webp" % [prefix, skin])

func atlas_frame(atlas: Texture2D, frame_index: int, frame_w: int = FRAME, frame_h: int = FRAME) -> AtlasTexture:
	if atlas == null:
		return null
	var at := AtlasTexture.new()
	at.atlas = atlas
	at.region = Rect2(frame_index * frame_w, 0, frame_w, frame_h)
	return at

func clip_frame_index(anim_doc: Dictionary, clip_id: String) -> int:
	for c in anim_doc.get("clips", []):
		if str(c.get("id", "")) == clip_id:
			if c.has("frame_index"):
				return int(c.get("frame_index"))
			# fallback order
			var idx := HERO_CLIPS.find(clip_id)
			return idx if idx >= 0 else 0
	var fallback := HERO_CLIPS.find(clip_id)
	return fallback if fallback >= 0 else 0

func _enemy_meta(enemy_id: String) -> Dictionary:
	for e in ContentPackageLoader.enemies_pack.get("enemies", []):
		if str(e.get("id", "")) == enemy_id:
			return e
	for e in ContentPackageLoader.enemies_pack.get("bosses", []):
		if str(e.get("id", "")) == enemy_id:
			return e
	return {}

func _rig_for_enemy(enemy_id: String) -> Dictionary:
	var meta := _enemy_meta(enemy_id)
	var rid := str(meta.get("rig_id", ""))
	for r in ContentPackageLoader.enemies_pack.get("rigs", []):
		if str(r.get("id", "")) == rid:
			return r
	return {}

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if typeof(data) == TYPE_DICTIONARY else {}

func preload_essentials(labels: PackedStringArray = PackedStringArray()) -> void:
	# Lightweight prototype: mark progress for bootstrap UI only.
	var steps := ["Тема", "Шрифты", "Оболочка", "Демо-данные", "Хаб"]
	if labels.size() > 0:
		steps = labels
	for i in steps.size():
		load_progress.emit(i + 1, steps.size(), steps[i])
		await get_tree().create_timer(0.08).timeout
	load_finished.emit()

func clear_nonessential() -> void:
	# Keep theme/fonts; drop optional textures if budget tight.
	var keys: Array = _cache.keys()
	for k in keys:
		if String(k).begins_with("res://assets/optional/"):
			_cache.erase(k)

func make_gradient_texture(top: Color, bottom: Color, w: int = 8, h: int = 64) -> GradientTexture2D:
	var key := "grad:%s:%s:%d:%d" % [top.to_html(), bottom.to_html(), w, h]
	if _cache.has(key):
		return _cache[key]
	var g := Gradient.new()
	g.colors = PackedColorArray([top, bottom])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = w
	tex.height = h
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	_cache[key] = tex
	return tex

func make_radial_glow(col: Color, size: int = 64) -> GradientTexture2D:
	var key := "glow:%s:%d" % [col.to_html(), size]
	if _cache.has(key):
		return _cache[key]
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(col.r, col.g, col.b, 0.55), Color(col.r, col.g, col.b, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = size
	tex.height = size
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	_cache[key] = tex
	return tex
