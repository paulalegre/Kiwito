class_name TappableIcon
extends Control

## Ícono táctil reutilizable para chrome de UI (botón Casa, Continuar, Salir
## al Hub). Hitbox +30% sobre el ícono visible (CLAUDE.md reglas de input),
## sin texto: un círculo teñido desde `Palette` con un glifo plano encima,
## construido por superposición de formas redondeadas (Direccion_de_Arte.md
## §3: sin contorno, sin ángulos rectos, falso volumen por planos).

signal tapped

enum Glyph { NONE, PAUSE, PLAY, HOME }

const GLYPH_COLOR_ID: StringName = &"cream_fade"

const PAUSE_BAR_WIDTH_RATIO: float = 0.16
const PAUSE_BAR_HEIGHT_RATIO: float = 0.6
const PAUSE_BAR_GAP_RATIO: float = 0.22

const PLAY_TRIANGLE_EXTENT_RATIO: float = 0.5
const PLAY_TRIANGLE_CORNER_RATIO: float = 0.08

const HOME_ROOF_EXTENT_RATIO: float = 0.5
const HOME_ROOF_HEIGHT_RATIO: float = 0.42
const HOME_ROOF_CORNER_RATIO: float = 0.08
const HOME_BASE_SIZE_RATIO: Vector2 = Vector2(0.62, 0.4)
const HOME_BASE_CORNER_RATIO: float = 0.14

@export var palette: Palette
@export var color_id: StringName = &""
@export var icon_radius: float = 40.0
@export var glyph: Glyph = Glyph.NONE

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
	_draw_glyph(center)

func _draw_glyph(center: Vector2) -> void:
	if glyph == Glyph.NONE:
		return

	var glyph_color: Color = palette.get_color(GLYPH_COLOR_ID)
	match glyph:
		Glyph.PAUSE:
			_draw_pause_glyph(center, glyph_color)
		Glyph.PLAY:
			_draw_play_glyph(center, glyph_color)
		Glyph.HOME:
			_draw_home_glyph(center, glyph_color)

func _draw_pause_glyph(center: Vector2, glyph_color: Color) -> void:
	var bar_width: float = icon_radius * PAUSE_BAR_WIDTH_RATIO
	var bar_height: float = icon_radius * PAUSE_BAR_HEIGHT_RATIO
	var gap: float = icon_radius * PAUSE_BAR_GAP_RATIO
	_draw_capsule(center + Vector2(-gap, 0.0), bar_width, bar_height, glyph_color)
	_draw_capsule(center + Vector2(gap, 0.0), bar_width, bar_height, glyph_color)

## Cápsula vertical (rectángulo + dos círculos en los extremos): la misma
## técnica de superposición de formas planas que ya usa Balloon/GoalBox para
## fingir volumen, aquí para evitar puntas rectas en las barras de pausa.
func _draw_capsule(capsule_center: Vector2, width: float, height: float, color: Color) -> void:
	var half_width: float = width / 2.0
	var straight_height: float = maxf(height - width, 0.0)
	if straight_height > 0.0:
		var rect_position: Vector2 = capsule_center - Vector2(half_width, straight_height / 2.0)
		draw_rect(Rect2(rect_position, Vector2(width, straight_height)), color)
	draw_circle(capsule_center + Vector2(0.0, -straight_height / 2.0), half_width, color)
	draw_circle(capsule_center + Vector2(0.0, straight_height / 2.0), half_width, color)

func _draw_play_glyph(center: Vector2, glyph_color: Color) -> void:
	var extent: float = icon_radius * PLAY_TRIANGLE_EXTENT_RATIO
	var corner_radius: float = icon_radius * PLAY_TRIANGLE_CORNER_RATIO
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(-extent * 0.5, -extent),
		center + Vector2(extent, 0.0),
		center + Vector2(-extent * 0.5, extent),
	])
	_draw_rounded_triangle(points, corner_radius, glyph_color)

func _draw_home_glyph(center: Vector2, glyph_color: Color) -> void:
	_draw_home_roof(center, glyph_color)
	_draw_home_base(center, glyph_color)

func _draw_home_roof(center: Vector2, glyph_color: Color) -> void:
	var extent: float = icon_radius * HOME_ROOF_EXTENT_RATIO
	var roof_height: float = icon_radius * HOME_ROOF_HEIGHT_RATIO
	var corner_radius: float = icon_radius * HOME_ROOF_CORNER_RATIO
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -roof_height),
		center + Vector2(extent, 0.0),
		center + Vector2(-extent, 0.0),
	])
	_draw_rounded_triangle(points, corner_radius, glyph_color)

func _draw_home_base(center: Vector2, glyph_color: Color) -> void:
	var base_size: Vector2 = Vector2(icon_radius, icon_radius) * HOME_BASE_SIZE_RATIO
	var corner_radius: float = icon_radius * HOME_BASE_CORNER_RATIO
	var base_center: Vector2 = center + Vector2(0.0, base_size.y / 2.0)
	_draw_rounded_rect(Rect2(base_center - base_size / 2.0, base_size), corner_radius, glyph_color)

## Triángulo relleno (draw_polygon) con un círculo superpuesto en cada
## vértice para redondear las puntas sin recurrir a un contorno.
func _draw_rounded_triangle(points: PackedVector2Array, corner_radius: float, color: Color) -> void:
	draw_polygon(points, PackedColorArray([color]))
	for point: Vector2 in points:
		draw_circle(point, corner_radius, color)

## Rectángulo redondeado: cruz de dos rectángulos inscritos + un círculo por
## esquina, misma técnica de planos superpuestos.
func _draw_rounded_rect(rect: Rect2, corner_radius: float, color: Color) -> void:
	var inset_h: Rect2 = Rect2(
		rect.position + Vector2(corner_radius, 0.0),
		rect.size - Vector2(corner_radius * 2.0, 0.0)
	)
	var inset_v: Rect2 = Rect2(
		rect.position + Vector2(0.0, corner_radius),
		rect.size - Vector2(0.0, corner_radius * 2.0)
	)
	draw_rect(inset_h, color)
	draw_rect(inset_v, color)

	var corners: Array[Vector2] = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + Vector2(0.0, rect.size.y),
		rect.position + rect.size,
	]
	for corner: Vector2 in corners:
		draw_circle(corner, corner_radius, color)

func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return

	var touch: InputEventScreenTouch = event
	if touch.index != 0 or not touch.pressed:
		return

	tapped.emit()
	get_viewport().set_input_as_handled()
