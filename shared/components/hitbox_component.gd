class_name HitboxComponent
extends Area2D

## Componente de composición (sin dependencia de un padre específico). El área
## de colisión se dimensiona al autorizar la escena (+30% del sprite visible,
## CLAUDE.md reglas de input); este script solo filtra y emite el toque.

signal tapped

func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventScreenTouch:
		return

	var touch: InputEventScreenTouch = event
	if touch.index != 0 or not touch.pressed:
		return

	tapped.emit()
	get_viewport().set_input_as_handled()
