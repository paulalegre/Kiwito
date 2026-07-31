class_name CoverSprite
extends Sprite2D

## Escala un Sprite2D en modo "cover"/"aspect fill" (equivalente a
## `background-size: cover`): cubre el 100% del área revelada por
## `stretch/aspect = expand` (Core_Architecture.md §0) en cualquier aspect
## ratio de tablet, recortando el sobrante en el eje que excede, sin dejar
## nunca un borde sin cubrir. Recalcula en cada resize porque `expand` no
## crece simétrico desde el centro del lienzo de diseño: ancla (0,0) arriba-
## izquierda y agrega el área extra abajo/derecha, así que el centro real del
## viewport se mueve con el aspect ratio y no puede asumirse fijo.

func _ready() -> void:
	centered = true
	get_viewport().size_changed.connect(_update_cover)
	_update_cover()

func _update_cover() -> void:
	if texture == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var tex_size: Vector2 = texture.get_size()
	var cover_scale: float = max(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	scale = Vector2(cover_scale, cover_scale)
	position = viewport_size / 2.0
