extends Area2D

@export var speed: float = 140.0
@export var sway_amplitude: float = 25.0
@export var sway_speed: float = 2.0

var _base_x: float
var _time: float = 0.0
var _popped: bool = false

func _ready() -> void:
	_base_x = position.x
	if $CollisionShape2D.shape == null:
		var shape := CircleShape2D.new()
		shape.radius = 55.0
		$CollisionShape2D.shape = shape
	input_event.connect(_on_input_event)

func _process(delta: float) -> void:
	if _popped:
		return
	_time += delta
	position.y -= speed * delta
	position.x = _base_x + sin(_time * sway_speed) * sway_amplitude
	if position.y < -250.0:
		queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _popped:
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var is_touch: bool = event is InputEventScreenTouch and event.pressed
	if is_click or is_touch:
		pop()

func pop() -> void:
	_popped = true
	input_pickable = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", scale * 1.4, 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
