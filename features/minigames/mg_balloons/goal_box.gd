class_name GoalBox
extends Node2D

## Meta Persistente (GDD_MVP.md §3): muestra el color objetivo activo en una
## esquina fija. Solo tiene sentido en sesiones MATCH_COLOR (design.md de
## audio-and-sensory-polish, Decisión 7); en MATCH_ANY permanece oculto, ya
## que no hay un único color objetivo que mostrar.

const AMBER_HALO_COLOR_ID: StringName = &"amber_attention"
const PULSE_SCALE: float = 1.12
const PULSE_DURATION_SEC: float = 0.6

@export var palette: Palette
@export var radius: float = 48.0

var _target_color_id: StringName = &""
var _halo_active: bool = false
var _pulse_tween: Tween

func set_target_color(color_id: StringName) -> void:
	_target_color_id = color_id
	visible = true
	queue_redraw()

func hide_goal() -> void:
	visible = false

func pulse() -> void:
	_halo_active = true
	queue_redraw()

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	scale = Vector2.ONE
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "scale", Vector2.ONE * PULSE_SCALE, PULSE_DURATION_SEC * 0.5)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, PULSE_DURATION_SEC * 0.5)
	_pulse_tween.tween_callback(_on_pulse_finished)

func _on_pulse_finished() -> void:
	_halo_active = false
	queue_redraw()

func _draw() -> void:
	if palette == null or _target_color_id == &"":
		return

	if _halo_active:
		draw_circle(Vector2.ZERO, radius * 1.3, palette.get_color(AMBER_HALO_COLOR_ID))

	draw_circle(Vector2.ZERO, radius, palette.get_color(_target_color_id))
