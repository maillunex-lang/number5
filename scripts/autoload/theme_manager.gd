extends Node
## GRAPHICS-UI-001 A — пресеты + тема/motion из контент-пакета

signal preset_changed(preset: String)
signal theme_reloaded

const PRESETS := ["low", "medium", "high", "ultra"]

var preset: String = "high"
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var max_active_fx: int = 24
var parallax_enabled: bool = true
var particle_scale: float = 1.0
var transition_ms: int = 280
var hub_decor_layers: int = 3
var hub_pulse: bool = true
var hub_pulse_sec: float = 1.1
var building_float: bool = true
var toast_ms: int = 2200
var palette: Dictionary = {}
var radius_map: Dictionary = {}
var components: Dictionary = {}

func _ready() -> void:
	_load_local()
	_apply_package_theme()
	apply_preset(preset, false)
	ContentPackageLoader.package_loaded.connect(func(_v):
		_apply_package_theme()
		apply_preset(preset, false)
		theme_reloaded.emit()
	)

func _apply_package_theme() -> void:
	palette = ContentPackageLoader.theme.get("palette", {}).duplicate(true)
	radius_map = ContentPackageLoader.theme.get("radius", {}).duplicate(true)
	components = ContentPackageLoader.theme.get("components", {}).duplicate(true)
	var motion: Dictionary = ContentPackageLoader.motion
	if not motion.is_empty():
		if motion.has("transition_ms"):
			transition_ms = int(motion["transition_ms"])
		if motion.has("parallax_enabled"):
			parallax_enabled = bool(motion["parallax_enabled"])
		if motion.has("particle_scale"):
			particle_scale = float(motion["particle_scale"])
		if motion.has("max_active_fx"):
			max_active_fx = int(motion["max_active_fx"])
		if motion.has("hub_decor_layers"):
			hub_decor_layers = int(motion["hub_decor_layers"])
		hub_pulse = bool(motion.get("hub_pulse", true))
		hub_pulse_sec = float(motion.get("hub_pulse_sec", 1.1))
		building_float = bool(motion.get("building_float", true))
		toast_ms = int(motion.get("toast_ms", 2200))

func color(key: String, fallback: Color = Color.WHITE) -> Color:
	if palette.has(key):
		return Color(str(palette[key]))
	return ContentPackageLoader.color_of(key, fallback)

func radius(key: String = "md") -> int:
	if radius_map.has(key):
		return int(radius_map[key])
	return ContentPackageLoader.radius(key)

func apply_preset(name: String, save: bool = true) -> void:
	if name not in PRESETS:
		name = "medium"
	preset = name
	# Package motion is baseline; presets scale FX budget.
	_apply_package_theme()
	match preset:
		"low":
			max_active_fx = mini(max_active_fx, 6)
			parallax_enabled = false
			particle_scale = minf(particle_scale, 0.35)
			transition_ms = mini(transition_ms, 160)
			hub_decor_layers = mini(hub_decor_layers, 1)
			hub_pulse = false
		"medium":
			max_active_fx = mini(max_active_fx, 12)
			particle_scale = minf(particle_scale, 0.7)
			hub_decor_layers = mini(hub_decor_layers, 2)
		"high":
			pass
		"ultra":
			max_active_fx = maxi(max_active_fx, 40)
			particle_scale = maxf(particle_scale, 1.25)
			hub_decor_layers = maxi(hub_decor_layers, 4)
	if save:
		_save_local()
	preset_changed.emit(preset)
	AppState.graphics_changed.emit(preset)

func preset_label(name: String = "") -> String:
	var p := name if name != "" else preset
	match p:
		"low": return "Низкая"
		"medium": return "Средняя"
		"high": return "Высокая"
		"ultra": return "Ультра"
		_: return p

func _save_local() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("graphics", "preset", preset)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save("user://lunex_settings.cfg")

func _load_local() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://lunex_settings.cfg") != OK:
		return
	preset = str(cfg.get_value("graphics", "preset", "high"))
	music_volume = float(cfg.get_value("audio", "music", 0.7))
	sfx_volume = float(cfg.get_value("audio", "sfx", 0.8))

func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	_save_local()
	AudioManager.apply_volumes()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_save_local()
	AudioManager.apply_volumes()
