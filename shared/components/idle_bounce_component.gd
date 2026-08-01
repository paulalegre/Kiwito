class_name IdleBounceComponent
extends Node

## Rebote de reposo que invita a tocar (Direccion_de_Arte.md §3, principio 3:
## "si brilla, se toca" — el rebote es vocabulario de interactividad, se usa
## solo en elementos tocables). Amplitud y cadencia siguen §4.2 "reposo vivo
## pero lento" (mismo ciclo de 3s que la oscilación de los globos). Mismo
## patrón de Tween que Balloon.set_highlighted(): create_tween() + set_loops()
## en el nodo padre. Sin dependencia de un padre específico.

const CYCLE_DURATION_SEC: float = 3.0
const BOUNCE_HEIGHT_PX: float = 10.0
const LOW_STIM_BOUNCE_HEIGHT_PX: float = 5.0

var _tween: Tween
var _base_position_y: float

func _ready() -> void:
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node == null:
		return

	_base_position_y = owner_node.position.y
	SettingsManager.low_stim_changed.connect(_on_low_stim_changed)
	_start_loop(owner_node)

func _start_loop(owner_node: Node2D) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	owner_node.position.y = _base_position_y

	var bounce_height: float = LOW_STIM_BOUNCE_HEIGHT_PX if SettingsManager.low_stim_mode else BOUNCE_HEIGHT_PX

	_tween = owner_node.create_tween()
	_tween.set_loops()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(owner_node, "position:y", _base_position_y - bounce_height, CYCLE_DURATION_SEC * 0.5)
	_tween.tween_property(owner_node, "position:y", _base_position_y, CYCLE_DURATION_SEC * 0.5)

func _on_low_stim_changed(_enabled: bool) -> void:
	var owner_node: Node2D = get_parent() as Node2D
	if owner_node != null:
		_start_loop(owner_node)
