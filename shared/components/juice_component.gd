class_name JuiceComponent
extends Node

## Feedback táctil de su nodo padre en menos de 100ms (CLAUDE.md). Sin
## dependencia de un padre específico.

const FEEDBACK_DURATION_SEC: float = 0.12
const SCALE_PUNCH: float = 1.2
const SHAKE_DURATION_SEC: float = 0.15
const SHAKE_OFFSET_PX: float = 6.0

func play_feedback() -> void:
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node == null:
		return

	var base_scale: Vector2 = owner_node.scale
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(owner_node, "scale", base_scale * SCALE_PUNCH, FEEDBACK_DURATION_SEC * 0.5)
	tween.tween_property(owner_node, "scale", base_scale, FEEDBACK_DURATION_SEC * 0.5)

func play_shake() -> void:
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node == null:
		return

	var base_position: Vector2 = owner_node.position
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(owner_node, "position:x", base_position.x + SHAKE_OFFSET_PX, SHAKE_DURATION_SEC * 0.25)
	tween.tween_property(owner_node, "position:x", base_position.x - SHAKE_OFFSET_PX, SHAKE_DURATION_SEC * 0.5)
	tween.tween_property(owner_node, "position:x", base_position.x, SHAKE_DURATION_SEC * 0.25)
