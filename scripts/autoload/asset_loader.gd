extends Node
## Отложенная загрузка и кеш текстур. Не держит все тяжёлые ресурсы сразу.

signal load_progress(done: int, total: int, label: String)
signal load_finished

var _cache: Dictionary = {} # path -> Resource
var _active_loads: int = 0
var texture_budget_mb: float = 96.0

func get_cached(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	if ResourceLoader.exists(path):
		var res := load(path)
		_cache[path] = res
		return res
	return null

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
