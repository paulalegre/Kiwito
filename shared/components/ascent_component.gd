class_name AscentComponent
extends Node

## Hace ascender a su nodo padre en el eje Y a velocidad configurable
## (GDD_MVP.md §5). Sin dependencia de un padre específico.

@export var ascent_speed: float = 80.0

func _physics_process(delta: float) -> void:
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node == null:
		return

	owner_node.position.y -= ascent_speed * delta
