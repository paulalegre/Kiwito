class_name TappableIcon
extends Control

## Ícono táctil reutilizable para chrome de UI (botón Casa, Continuar, Salir
## al Hub). Hitbox +30% sobre el ícono visible (CLAUDE.md reglas de input),
## sin texto: solo un círculo teñido desde `Palette`.

signal tapped

@export var palette: Palette
@export var color_id: StringName = &""
@export var icon_radius: float = 40.0

func _ready() -> void:
	var hitbox_radius: float = icon_radius * 1.3
	custom_minimum_size = Vector2(hitbox_radius * 2.0, hitbox_radius * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	queue_redraw()

func _draw() -> void:
	if palette == null:
		return
	draw_circle(size / 2.0, icon_radius, palette.get_color(color_id))

func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return

	var touch: InputEventScreenTouch = event
	if touch.index != 0 or not touch.pressed:
		return

	tapped.emit()
	get_viewport().set_input_as_handled()
