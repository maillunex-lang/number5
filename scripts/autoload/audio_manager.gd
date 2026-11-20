extends Node
## AUDIO-UI-001 A — только музыка и эффекты.

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)
	apply_volumes()

func apply_volumes() -> void:
	# Procedural prototype: no audio files yet; volumes ready for streams.
	_music_player.volume_db = linear_to_db(maxf(ThemeManager.music_volume, 0.0001))
	_sfx_player.volume_db = linear_to_db(maxf(ThemeManager.sfx_volume, 0.0001))

func play_ui_tap() -> void:
	# Placeholder — no asset; keep API for later packs.
	pass

func play_reward() -> void:
	pass

func play_battle_hit() -> void:
	pass
