class_name PlaceholderCircle
extends Node2D

## Marcador visual temporal para nodos del Hub sin arte final aún (ver
## design.md de progression-and-hub). Un círculo no tiene esquinas ni ángulos
## rectos, así que cumple el lenguaje de forma de Direccion_de_Arte.md sin
## necesitar ningún asset nuevo. El color siempre se resuelve desde
## `Palette`, nunca un literal hex.

@export var palette: Palette
@export var color_id: StringName = &""
@export var radius: float = 64.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if palette == null:
		return

	draw_circle(Vector2.ZERO, radius, palette.get_color(color_id))
