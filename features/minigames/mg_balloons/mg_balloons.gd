class_name MgBalloons
extends MinigameBase

## Primer cartucho jugable ("Explotaglobos", GDD_MVP.md §4-5). Aislamiento
## estricto: nada aquí es referenciado por otro minijuego.

const BALLOON_SCENE: PackedScene = preload("res://features/minigames/mg_balloons/balloon.tscn")
const SPAWN_MARGIN_PX: float = 80.0
const DISTRACTOR_COLOR_ID: StringName = &"blue_oceano"

@export var palette: Palette

@onready var _spawn_timer: Timer = $SpawnTimer

var _config: BalloonLevelConfig
var _correct_pops: int = 0
var _failed_taps: int = 0
var _errors_by_color: Dictionary = {}
var _session_start_msec: int = 0
var _active_balloons: Array[Balloon] = []

func _ready() -> void:
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_spawn_balloon)

func start(config: LevelConfig) -> void:
	_config = config as BalloonLevelConfig
	if _config == null:
		push_error("MgBalloons.start() requiere un BalloonLevelConfig")
		return

	_correct_pops = 0
	_failed_taps = 0
	_errors_by_color = {}
	_session_start_msec = Time.get_ticks_msec()

	_spawn_timer.wait_time = _config.spawn_interval_sec
	_spawn_timer.start()
	_spawn_balloon()

func _spawn_balloon() -> void:
	var color_id: StringName = _config.target_color_id
	if _config.match_rule == LevelConfig.MatchRule.MATCH_COLOR and randf() < 0.5:
		color_id = DISTRACTOR_COLOR_ID

	var balloon: Balloon = BALLOON_SCENE.instantiate()
	add_child(balloon)
	balloon.setup(color_id, palette, _config.ascent_speed)

	var viewport_size: Vector2 = get_viewport_rect().size
	balloon.position = Vector2(
		randf_range(SPAWN_MARGIN_PX, viewport_size.x - SPAWN_MARGIN_PX),
		viewport_size.y + SPAWN_MARGIN_PX
	)

	balloon.tapped.connect(_on_balloon_tapped)
	_active_balloons.append(balloon)

func _on_balloon_tapped(balloon: Balloon) -> void:
	if not is_instance_valid(balloon):
		return

	if MatchRuleEngine.matches(balloon.color_id, _config):
		_correct_pops += 1
		balloon.play_correct_feedback()
		_remove_balloon(balloon)
		if _correct_pops >= _config.win_count:
			_finish_session()
	else:
		_failed_taps += 1
		_errors_by_color[balloon.color_id] = _errors_by_color.get(balloon.color_id, 0) + 1
		balloon.play_incorrect_feedback()

func _remove_balloon(balloon: Balloon) -> void:
	_active_balloons.erase(balloon)
	balloon.queue_free()

func _finish_session() -> void:
	_spawn_timer.stop()
	for balloon: Balloon in _active_balloons.duplicate():
		_remove_balloon(balloon)

	var result: MinigameResult = MinigameResult.new()
	result.correct_pops = _correct_pops
	result.failed_taps = _failed_taps
	result.duration = (Time.get_ticks_msec() - _session_start_msec) / 1000.0
	result.errors_by_color = _errors_by_color
	session_finished.emit(result)
