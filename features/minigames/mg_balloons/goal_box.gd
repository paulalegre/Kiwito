class_name GoalBox
extends Node2D

## Meta Persistente (GDD_MVP.md §3): muestra el color objetivo activo en una
## esquina fija. Solo tiene sentido en sesiones MATCH_COLOR (design.md de
## audio-and-sensory-polish, Decisión 7); en MATCH_ANY permanece oculto, ya
## que no hay un único color objetivo que mostrar.

const AMBER_HALO_COLOR_ID: StringName = &"amber_attention"
const PULSE_SCALE: float = 1.12
const PULSE_DURATION_SEC: float = 0.6

## Capa de patrón no-cromático (Direccion_de_Arte.md §2.2): blanco a opacidad
## parcial, igual que balloon_halo.gd — acromático a propósito, no es uno de
## los 4 colores de juego y por eso no requiere Palette. Sin esto, la meta
## persistente sería puro color, rompiendo la redundancia que exige la mecánica.
const PATTERN_COLOR: Color = Color(1.0, 1.0, 1.0, 0.28)
const PATTERN_EXTENT_RATIO: float = 0.5
const PATTERN_LINE_WIDTH_RATIO: float = 0.09
const PATTERN_DOT_RADIUS_RATIO: float = 0.1

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
	_draw_pattern(palette.get_pattern_id(_target_color_id))


func _draw_pattern(pattern_id: StringName) -> void:
	var extent: float = radius * PATTERN_EXTENT_RATIO
	match pattern_id:
		&"dots":
			_draw_dots_pattern(extent)
		&"stripes":
			_draw_stripes_pattern(extent)
		&"stars":
			_draw_stars_pattern(extent)
		&"zigzag":
			_draw_zigzag_pattern(extent)


func _draw_dots_pattern(extent: float) -> void:
	var dot_radius: float = radius * PATTERN_DOT_RADIUS_RATIO
	var offsets: Array[Vector2] = [
		Vector2(-0.6, -0.5), Vector2(0.5, -0.55), Vector2(0.0, 0.0),
		Vector2(-0.55, 0.5), Vector2(0.55, 0.55),
	]
	for offset: Vector2 in offsets:
		draw_circle(offset * extent, dot_radius, PATTERN_COLOR)


func _draw_stripes_pattern(extent: float) -> void:
	var line_width: float = radius * PATTERN_LINE_WIDTH_RATIO
	for offset: float in [-extent * 0.6, 0.0, extent * 0.6]:
		draw_line(Vector2(-extent, offset - extent * 0.4), Vector2(extent, offset + extent * 0.4), PATTERN_COLOR, line_width)


func _draw_stars_pattern(extent: float) -> void:
	var arm: float = extent * 0.35
	var line_width: float = radius * PATTERN_LINE_WIDTH_RATIO * 0.7
	var centers: Array[Vector2] = [
		Vector2(-0.5, -0.5) * extent, Vector2(0.55, -0.4) * extent, Vector2(0.0, 0.55) * extent,
	]
	for center: Vector2 in centers:
		draw_line(center + Vector2(-arm, 0.0), center + Vector2(arm, 0.0), PATTERN_COLOR, line_width)
		draw_line(center + Vector2(0.0, -arm), center + Vector2(0.0, arm), PATTERN_COLOR, line_width)


func _draw_zigzag_pattern(extent: float) -> void:
	var line_width: float = radius * PATTERN_LINE_WIDTH_RATIO
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(-extent, -extent * 0.3),
		Vector2(-extent * 0.3, extent * 0.3),
		Vector2(extent * 0.3, -extent * 0.3),
		Vector2(extent, extent * 0.3),
	])
	draw_polyline(points, PATTERN_COLOR, line_width)
