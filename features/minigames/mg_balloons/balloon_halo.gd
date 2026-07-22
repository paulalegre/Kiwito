extends Node2D

## Halo no-cromático de la ayuda escalonada nivel 2 (Direccion_de_Arte.md §7).
## Blanco a opacidad parcial: acromático a propósito, no es uno de los 4
## colores de juego y por eso no requiere `Palette`.

const HALO_COLOR: Color = Color(1.0, 1.0, 1.0, 0.28)
const HALO_RADIUS: float = 240.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, HALO_RADIUS, HALO_COLOR)
