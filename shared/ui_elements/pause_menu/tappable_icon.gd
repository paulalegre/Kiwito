class_name TappableIcon
extends Control

## Ícono táctil reutilizable para chrome de UI (botón Casa, Continuar, Salir
## al Hub). Hitbox +30% sobre el ícono visible (CLAUDE.md reglas de input),
## sin texto: un círculo teñido desde `Palette` con una textura de glifo
## encima, teñida en runtime vía `modulate` (mismo mecanismo que
## `Balloon.setup()` con `balloon_base.png`/`balloon_volume.png`).

signal tapped

const GLYPH_COLOR_ID: StringName = &"cream_fade"

## Lado del mayor cuadrado inscrito en el círculo base (radio × √2): el
## padding entre el glifo y el borde del círculo vive acá, no en el margen
## interno del PNG entregado — así ninguna textura, tenga o no margen propio,
## puede sobresalir del círculo.
const GLYPH_INSCRIBED_SCALE: float = 1.4142135

@export var palette: Palette
@export var color_id: StringName = &""
@export var icon_radius: float = 40.0
@export var glyph_texture: Texture2D

func _ready() -> void:
	var hitbox_radius: float = icon_radius * 1.3
	custom_minimum_size = Vector2(hitbox_radius * 2.0, hitbox_radius * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	queue_redraw()

func _draw() -> void:
	if palette == null:
		return
	var center: Vector2 = size / 2.0
	draw_circle(center, icon_radius, palette.get_color(color_id))
	if glyph_texture != null:
		var glyph_size: Vector2 = Vector2.ONE * icon_radius * GLYPH_INSCRIBED_SCALE
		var rect: Rect2 = Rect2(center - glyph_size / 2.0, glyph_size)
		draw_texture_rect(glyph_texture, rect, false, palette.get_color(GLYPH_COLOR_ID))

func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return

	var touch: InputEventScreenTouch = event
	if touch.index != 0 or not touch.pressed:
		return

	tapped.emit()
	get_viewport().set_input_as_handled()
