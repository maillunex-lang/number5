@tool
class_name BattleUnit
extends Control
## Визуальный юнит боя. ART-05: atlas frames + portrait fallback; HP/energy — playback.

@export_category("Lunex Battle Unit")
@export var unit_size: Vector2 = Vector2(140, 160):
	set(v):
		unit_size = v
		custom_minimum_size = v
@export var preview_name: String = "Юнит":
	set(v):
		preview_name = v
		if _name:
			_name.text = v
@export var preview_tint: Color = Color("5EC8E8"):
	set(v):
		preview_tint = v
		_paint_body(v)

var unit_id: String = ""
var side: String = "ally"
var _atlas: Texture2D = null
var _anim_doc: Dictionary = {}
var _clip: String = "idle"
var _clip_tween: Tween = null

@onready var _body: ColorRect = $Body
@onready var _sprite: TextureRect = $Sprite
@onready var _name: Label = $Name
@onready var _hp: ProgressBar = $HP
@onready var _energy: ProgressBar = $Energy

func _ready() -> void:
	custom_minimum_size = unit_size
	if Engine.is_editor_hint():
		if _name:
			_name.text = preview_name
		_paint_body(preview_tint)
		if _hp:
			_hp.max_value = 100
			_hp.value = 80
		if _energy:
			_energy.max_value = 100
			_energy.value = 30
			_energy.modulate = LunexColors.ENERGY

func set_unit(data: Dictionary) -> void:
	unit_id = str(data.get("id", ""))
	side = str(data.get("side", "ally"))
	if _name:
		_name.text = str(data.get("name", preview_name))
	var tint_raw: Variant = data.get("tint", preview_tint)
	var tint: Color = preview_tint
	if typeof(tint_raw) == TYPE_COLOR:
		tint = tint_raw
	elif str(tint_raw).begins_with("#"):
		tint = Color(str(tint_raw))
	_paint_body(tint)
	_bind_art(data)
	var max_hp: float = float(data.get("max_hp", data.get("hp", 1000)))
	if _hp:
		_hp.max_value = max_hp
		_hp.value = float(data.get("hp", max_hp))
	if _energy:
		_energy.max_value = 100
		_energy.value = float(data.get("energy", 0))
		_energy.modulate = LunexColors.ENERGY
	play_clip("idle")

func _bind_art(data: Dictionary) -> void:
	_atlas = null
	_anim_doc = {}
	if Engine.is_editor_hint():
		return
	if side == "ally":
		var hid := str(data.get("id", ""))
		_atlas = AssetLoader.hero_atlas(hid)
		_anim_doc = AssetLoader.hero_anim_doc(hid)
		if _atlas == null:
			var portrait := AssetLoader.hero_portrait(hid)
			if portrait != null and _sprite:
				_sprite.texture = portrait
				_sprite.visible = true
				if _body:
					_body.visible = false
				return
	else:
		var eid := str(data.get("enemy_id", ""))
		_atlas = AssetLoader.enemy_atlas(eid)
		if _atlas == null:
			var skin := AssetLoader.enemy_skin(eid)
			if skin != null and _sprite:
				_sprite.texture = skin
				_sprite.visible = true
				if _body:
					_body.visible = false
				return
	if _atlas != null and _sprite:
		_sprite.visible = true
		if _body:
			_body.visible = false
	elif _sprite:
		_sprite.visible = false
		if _body:
			_body.visible = true

func play_clip(clip_id: String, return_idle: bool = true) -> void:
	_clip = clip_id
	if _atlas == null or _sprite == null:
		# tint pulse fallback
		if clip_id == "attack" or clip_id == "hit":
			var tw := create_tween()
			tw.tween_property(self, "modulate", Color(1.4, 1.2, 0.9), 0.08)
			tw.tween_property(self, "modulate", Color.WHITE, 0.15)
		return
	var idx := AssetLoader.clip_frame_index(_anim_doc, clip_id)
	_sprite.texture = AssetLoader.atlas_frame(_atlas, idx)
	if _clip_tween != null and is_instance_valid(_clip_tween):
		_clip_tween.kill()
	if return_idle and clip_id != "idle" and clip_id != "death":
		var dur := 0.35
		for c in _anim_doc.get("clips", []):
			if str(c.get("id", "")) == clip_id:
				dur = float(c.get("duration_hint_sec", dur))
				break
		_clip_tween = create_tween()
		_clip_tween.tween_interval(dur)
		_clip_tween.tween_callback(func():
			if is_instance_valid(self) and _clip != "death":
				play_clip("idle", false)
		)

func set_hp(v: float) -> void:
	if _hp:
		_hp.value = v

func set_energy(v: float) -> void:
	if _energy:
		_energy.value = v

func set_dead(dead: bool = true) -> void:
	if dead:
		play_clip("death", false)
		modulate = Color(0.45, 0.45, 0.45, 0.7)
	else:
		modulate = Color.WHITE
		play_clip("idle", false)

func hp_bar() -> ProgressBar:
	return _hp

func energy_bar() -> ProgressBar:
	return _energy

func body_node() -> Control:
	return _sprite if _sprite and _sprite.visible else _body

func _paint_body(tint: Color) -> void:
	if _body:
		_body.color = Color(tint.r * 0.45, tint.g * 0.45, tint.b * 0.45, 1)
