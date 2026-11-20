extends Node
## GRAPHICS-UI-001 A — только пресеты: low / medium / high / ultra

signal preset_changed(preset: String)

const PRESETS := ["low", "medium", "high", "ultra"]

var preset: String = "high"
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var max_active_fx: int = 24
var parallax_enabled: bool = true
var particle_scale: float = 1.0
var transition_ms: int = 280
var hub_decor_layers: int = 3

func _ready() -> void:
	_load_local()
	apply_preset(preset, false)

func apply_preset(name: String, save: bool = true) -> void:
	if name not in PRESETS:
		name = "medium"
	preset = name
	match preset:
		"low":
			max_active_fx = 6
			parallax_enabled = false
			particle_scale = 0.35
			transition_ms = 160
			hub_decor_layers = 1
		"medium":
			max_active_fx = 12
			parallax_enabled = true
			particle_scale = 0.7
			transition_ms = 220
			hub_decor_layers = 2
		"high":
			max_active_fx = 24
			parallax_enabled = true
			particle_scale = 1.0
			transition_ms = 280
			hub_decor_layers = 3
		"ultra":
			max_active_fx = 40
			parallax_enabled = true
			particle_scale = 1.25
			transition_ms = 320
			hub_decor_layers = 4
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
