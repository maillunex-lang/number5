extends Node
## Версионные контент-пакеты. Клиент только читает и рисует.
## Не является сервером прогресса / валют / боя.

signal package_loaded(version: String)
signal package_error(message: String)

const BUNDLED_ROOT := "res://content/packages"
const CACHE_ROOT := "user://content_cache/packages"
const ACTIVE_FILE := "res://content/packages/active.json"

var version: String = "0.1.0"
var manifest: Dictionary = {}
var hub: Dictionary = {}
var campaign: Dictionary = {}
var heroes_pack: Dictionary = {}
var battle_modes: Dictionary = {}
var features: Dictionary = {}
var theme: Dictionary = {}
var shell: Dictionary = {}
var strings: Dictionary = {}
var motion: Dictionary = {}
var assets: Dictionary = {}
var loaded: bool = false

func _ready() -> void:
	load_active_package()

func load_active_package() -> bool:
	var active := _read_json(ACTIVE_FILE)
	if not active.is_empty() and active.has("version"):
		version = str(active["version"])
	var ok := load_package(version)
	if not ok:
		package_error.emit("Не удалось загрузить пакет %s" % version)
	return ok

func load_package(ver: String) -> bool:
	var base := "%s/%s" % [BUNDLED_ROOT, ver]
	var cache_base := "%s/%s" % [CACHE_ROOT, ver]
	if DirAccess.open(cache_base) != null and FileAccess.file_exists("%s/hub.json" % cache_base):
		base = cache_base
	_load_docs(base)
	if hub.is_empty() or heroes_pack.is_empty() or campaign.is_empty():
		base = "%s/%s" % [BUNDLED_ROOT, ver]
		_load_docs(base)
	loaded = not hub.is_empty() and not heroes_pack.is_empty() and not campaign.is_empty()
	if loaded:
		version = ver
		package_loaded.emit(version)
		print("ContentPackage loaded: ", version, " from ", base)
	return loaded

func _load_docs(base: String) -> void:
	manifest = _read_json("%s/manifest.json" % base)
	hub = _read_json("%s/hub.json" % base)
	campaign = _read_json("%s/campaign.json" % base)
	heroes_pack = _read_json("%s/heroes.json" % base)
	battle_modes = _read_json("%s/battle_modes.json" % base)
	features = _read_json("%s/features.json" % base)
	theme = _read_json("%s/theme.json" % base)
	shell = _read_json("%s/shell.json" % base)
	strings = _read_json("%s/strings.json" % base)
	motion = _read_json("%s/motion.json" % base)
	assets = _read_json("%s/assets.json" % base)

func reload() -> bool:
	return load_active_package()

func package_label() -> String:
	return "Пакет %s · только чтение" % version

func tr_key(key: String, fallback: String = "") -> String:
	var entries: Dictionary = strings.get("entries", {})
	if entries.has(key):
		return str(entries[key])
	return fallback if fallback != "" else key

func color_of(key: String, fallback: Color = Color.WHITE) -> Color:
	var pal: Dictionary = theme.get("palette", {})
	if pal.has(key):
		return Color(str(pal[key]))
	return fallback

func radius(key: String = "md") -> int:
	var r: Dictionary = theme.get("radius", {})
	return int(r.get(key, 14))

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data

func get_hub_buildings() -> Array:
	return hub.get("buildings", [])

func get_side_rail() -> Array:
	return hub.get("side_rail", [])

func get_hub_world() -> Dictionary:
	return hub.get("world", {"width": 1080, "height": 2400})

func get_battle_portals() -> Array:
	return battle_modes.get("portals", [])

func get_shell_tabs() -> Array:
	var bn: Dictionary = shell.get("bottom_nav", {})
	return bn.get("tabs", [])

func get_asset_binding(key: String) -> String:
	var bindings: Dictionary = assets.get("bindings", {})
	return str(bindings.get(key, ""))
