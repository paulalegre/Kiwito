extends Node2D

const GLOBO_SCENE: PackedScene = preload("res://scenes/globo.tscn")

@export var spawn_interval_min: float = 0.6
@export var spawn_interval_max: float = 1.4
@export var horizontal_margin: float = 60.0

var _screen_size: Vector2

@onready var _spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	randomize()
	_screen_size = get_viewport_rect().size
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_start_next_spawn()

func _start_next_spawn() -> void:
	_spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	_spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	_spawn_globo()
	_start_next_spawn()

func _spawn_globo() -> void:
	var globo := GLOBO_SCENE.instantiate()
	var x := randf_range(horizontal_margin, _screen_size.x - horizontal_margin)
	globo.position = Vector2(x, _screen_size.y + 120.0)
	add_child(globo)
