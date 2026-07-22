class_name Balloon
extends Node2D

## Nodo de un solo globo. Aísla su color/patrón vía `Palette` (nunca hex
## literal) y expone su propio toque como señal local (signals up).

signal tapped(balloon: Balloon)

const PATTERN_TEXTURES: Dictionary[StringName, Texture2D] = {
	&"dots": preload("res://design/minigames/mg_balloons/pattern_dots.png"),
	&"stars": preload("res://design/minigames/mg_balloons/pattern_stars.png"),
	&"stripes": preload("res://design/minigames/mg_balloons/pattern_stripes.png"),
	&"zigzag": preload("res://design/minigames/mg_balloons/pattern_zigzag.png"),
}

@onready var _body_sprite: Sprite2D = $BodySprite
@onready var _volume_sprite: Sprite2D = $VolumeSprite
@onready var _pattern_sprite: Sprite2D = $PatternSprite
@onready var _hitbox: HitboxComponent = $HitboxComponent
@onready var _ascent: AscentComponent = $AscentComponent
@onready var _juice: JuiceComponent = $JuiceComponent

var color_id: StringName = &""

func _ready() -> void:
	_hitbox.tapped.connect(_on_hitbox_tapped)

func setup(new_color_id: StringName, palette: Palette, ascent_speed: float) -> void:
	color_id = new_color_id
	_ascent.ascent_speed = ascent_speed

	var tint: Color = palette.get_color(color_id)
	_body_sprite.modulate = tint
	_volume_sprite.modulate = tint

	var pattern_id: StringName = palette.get_pattern_id(color_id)
	var pattern_texture: Texture2D = PATTERN_TEXTURES.get(pattern_id)
	if pattern_texture != null:
		_pattern_sprite.texture = pattern_texture
		_pattern_sprite.visible = true
	else:
		_pattern_sprite.visible = false

func play_correct_feedback() -> void:
	_juice.play_feedback()

func play_incorrect_feedback() -> void:
	_juice.play_shake()

func _on_hitbox_tapped() -> void:
	tapped.emit(self)
