class_name JuiceComponent
extends Node

## Feedback táctil de su nodo padre en menos de 100ms (CLAUDE.md). Sin
## dependencia de un padre específico. Los montos exactos de cada modo
## (estándar/Low-Stim) vienen de Direccion_de_Arte.md §6.4; se leen en cada
## llamada, nunca cacheados (design.md de audio-and-sensory-polish, Decisión 4).

const FEEDBACK_DURATION_SEC: float = 0.12
const STANDARD_SCALE_PUNCH: float = 1.12
const LOW_STIM_SCALE_PUNCH: float = 1.06

const STANDARD_SHAKE_DURATION_SEC: float = 0.2
const STANDARD_SHAKE_OFFSET_PX: float = 6.0
const LOW_STIM_SHAKE_DURATION_SEC: float = 0.15
const LOW_STIM_SHAKE_OFFSET_PX: float = 3.0

@export var palette: Palette

func play_feedback() -> void:
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node == null:
		return

	var scale_punch: float = LOW_STIM_SCALE_PUNCH if SettingsManager.low_stim_mode else STANDARD_SCALE_PUNCH

	var base_scale: Vector2 = owner_node.scale
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(owner_node, "scale", base_scale * scale_punch, FEEDBACK_DURATION_SEC * 0.5)
	tween.tween_property(owner_node, "scale", base_scale, FEEDBACK_DURATION_SEC * 0.5)

func play_shake() -> void:
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node == null:
		return

	var low_stim: bool = SettingsManager.low_stim_mode
	var shake_duration: float = LOW_STIM_SHAKE_DURATION_SEC if low_stim else STANDARD_SHAKE_DURATION_SEC
	var shake_offset: float = LOW_STIM_SHAKE_OFFSET_PX if low_stim else STANDARD_SHAKE_OFFSET_PX

	var base_position: Vector2 = owner_node.position
	var tween: Tween = owner_node.create_tween()
	tween.tween_property(owner_node, "position:x", base_position.x + shake_offset, shake_duration * 0.25)
	tween.tween_property(owner_node, "position:x", base_position.x - shake_offset, shake_duration * 0.5)
	tween.tween_property(owner_node, "position:x", base_position.x, shake_duration * 0.25)

	if palette != null:
		var tint: Color = palette.get_color(&"warm_grey_tint")
		var tint_tween: Tween = owner_node.create_tween()
		tint_tween.tween_property(owner_node, "modulate", tint, shake_duration * 0.5)
		tint_tween.tween_property(owner_node, "modulate", Color.WHITE, shake_duration * 0.5)
