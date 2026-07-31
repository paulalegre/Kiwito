class_name PaletteBackgroundRect
extends Node2D

## Capa de color sólido a pantalla completa, resuelta desde `Palette` (nunca un
## literal hex). Cubre siempre el área revelada por
## `stretch/aspect = expand` (Core_Architecture.md §0) en cualquier aspect
## ratio de tablet, sin necesitar un `Sprite2D`/`ColorRect` dimensionado a
## mano. Es un `Node2D`, no un `Control`, para no interferir con la
## detección de toques por `Area2D` de los `HitboxComponent` de la escena.

@export var palette: Palette
@export var color_id: StringName = &""

const MARGIN: float = 400.0

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if palette == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var rect: Rect2 = Rect2(
		-MARGIN,
		-MARGIN,
		viewport_size.x + MARGIN * 2.0,
		viewport_size.y + MARGIN * 2.0
	)
	draw_rect(rect, palette.get_color(color_id))
