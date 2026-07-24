class_name MgBalloons
extends MinigameBase

## Primer cartucho jugable ("Explotaglobos", GDD_MVP.md §4-5). Aislamiento
## estricto: nada aquí es referenciado por otro minijuego.

const BALLOON_SCENE: PackedScene = preload("res://features/minigames/mg_balloons/balloon.tscn")
const SPAWN_MARGIN_PX: float = 80.0
const GOAL_BOX_MARGIN_PX: float = 160.0
const DISTRACTOR_COLOR_ID: StringName = &"blue_oceano"

## Caja conservadora que acota el hitbox del globo para fines de spawn, sin
## depender de su Shape2D concreto (rectángulo hoy, cápsula planeada aparte).
const BALLOON_CLEARANCE_SIZE: Vector2 = Vector2(220.0, 280.0)
const MAX_SPAWN_ATTEMPTS: int = 8

## Umbrales de frustración (GDD_MVP.md §3): 3 toques incorrectos en <1.5s, o
## 4s sin ningún toque correcto, escalan la ayuda sin nunca bloquear el input.
const FRUSTRATION_TAP_WINDOW_SEC: float = 1.5
const FRUSTRATION_TAP_COUNT: int = 3
const FRUSTRATION_IDLE_SEC: float = 4.0

@export var palette: Palette

@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _idle_timer: Timer = $IdleTimer
@onready var _goal_box: GoalBox = $GoalBox

var _config: BalloonLevelConfig
var _correct_pops: int = 0
var _failed_taps: int = 0
var _errors_by_color: Dictionary = {}
var _session_start_msec: int = 0
var _active_balloons: Array[Balloon] = []

var _incorrect_tap_times_sec: Array[float] = []
var _frustration_level: int = 0

func _ready() -> void:
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_spawn_balloon)

	_idle_timer.one_shot = false
	_idle_timer.wait_time = FRUSTRATION_IDLE_SEC
	_idle_timer.timeout.connect(_on_idle_timeout)

	_goal_box.position = Vector2(get_viewport_rect().size.x - GOAL_BOX_MARGIN_PX, GOAL_BOX_MARGIN_PX)

func start(config: LevelConfig) -> void:
	_config = config as BalloonLevelConfig
	if _config == null:
		push_error("MgBalloons.start() requiere un BalloonLevelConfig")
		return

	_correct_pops = 0
	_failed_taps = 0
	_errors_by_color = {}
	_session_start_msec = Time.get_ticks_msec()
	_incorrect_tap_times_sec = []
	_frustration_level = 0

	if _config.match_rule == LevelConfig.MatchRule.MATCH_COLOR:
		_goal_box.set_target_color(_config.target_color_id)
		_idle_timer.start()
	else:
		_goal_box.hide_goal()

	_spawn_timer.wait_time = _config.spawn_interval_sec
	_spawn_timer.start()
	_spawn_balloon()

func _spawn_balloon() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var spawn_y: float = viewport_size.y + BALLOON_CLEARANCE_SIZE.y / 2.0 + SPAWN_MARGIN_PX
	var active_footprints: Array[Rect2] = _active_footprints()

	var spawn_position: Vector2 = Vector2.ZERO
	var found_position: bool = false
	for attempt: int in range(MAX_SPAWN_ATTEMPTS):
		var candidate: Vector2 = Vector2(randf_range(SPAWN_MARGIN_PX, viewport_size.x - SPAWN_MARGIN_PX), spawn_y)
		if SpawnPlacement.is_position_clear(_footprint_at(candidate), active_footprints):
			spawn_position = candidate
			found_position = true
			break

	if not found_position:
		return

	var color_id: StringName = _config.target_color_id
	if _config.match_rule == LevelConfig.MatchRule.MATCH_COLOR and randf() < 0.5:
		color_id = DISTRACTOR_COLOR_ID

	var balloon: Balloon = BALLOON_SCENE.instantiate()
	add_child(balloon)
	balloon.setup(color_id, palette, _config.ascent_speed)
	balloon.position = spawn_position

	balloon.tapped.connect(_on_balloon_tapped)
	_active_balloons.append(balloon)

	if _frustration_level >= 2 and color_id == _config.target_color_id:
		balloon.set_highlighted(true)

func _active_footprints() -> Array[Rect2]:
	var footprints: Array[Rect2] = []
	for active_balloon: Balloon in _active_balloons:
		if is_instance_valid(active_balloon):
			footprints.append(_footprint_at(active_balloon.position))
	return footprints

func _footprint_at(center: Vector2) -> Rect2:
	return Rect2(center - BALLOON_CLEARANCE_SIZE / 2.0, BALLOON_CLEARANCE_SIZE)

func _on_balloon_tapped(balloon: Balloon) -> void:
	if not is_instance_valid(balloon):
		return

	if MatchRuleEngine.matches(balloon.color_id, _config):
		_correct_pops += 1
		balloon.play_correct_feedback()
		_remove_balloon(balloon)
		_on_correct_tap()
		if _correct_pops >= _config.win_count:
			_finish_session()
	else:
		_failed_taps += 1
		_errors_by_color[balloon.color_id] = _errors_by_color.get(balloon.color_id, 0) + 1
		balloon.play_incorrect_feedback()
		_on_incorrect_tap()

func _remove_balloon(balloon: Balloon) -> void:
	_active_balloons.erase(balloon)
	balloon.queue_free()

func _finish_session() -> void:
	_spawn_timer.stop()
	_idle_timer.stop()
	for balloon: Balloon in _active_balloons.duplicate():
		_remove_balloon(balloon)

	var result: MinigameResult = MinigameResult.new()
	result.correct_pops = _correct_pops
	result.failed_taps = _failed_taps
	result.duration = (Time.get_ticks_msec() - _session_start_msec) / 1000.0
	result.errors_by_color = _errors_by_color
	session_finished.emit(result)

func _on_correct_tap() -> void:
	_incorrect_tap_times_sec.clear()
	if _config.match_rule == LevelConfig.MatchRule.MATCH_COLOR:
		_idle_timer.start()
	if _frustration_level > 0:
		_clear_escalation()

func _on_incorrect_tap() -> void:
	if _config.match_rule != LevelConfig.MatchRule.MATCH_COLOR:
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	_incorrect_tap_times_sec.append(now)
	_incorrect_tap_times_sec = _incorrect_tap_times_sec.filter(
		func(t: float) -> bool: return now - t <= FRUSTRATION_TAP_WINDOW_SEC
	)

	if _incorrect_tap_times_sec.size() >= FRUSTRATION_TAP_COUNT:
		_incorrect_tap_times_sec.clear()
		_trigger_frustration()

func _on_idle_timeout() -> void:
	_trigger_frustration()

func _trigger_frustration() -> void:
	if _frustration_level == 0:
		_frustration_level = 1
		_play_level1_help()
	elif _frustration_level == 1:
		_frustration_level = 2
		_play_level2_help()

func _play_level1_help() -> void:
	_goal_box.pulse()
	AudioManager.play_vo(&"help_level_1")

func _play_level2_help() -> void:
	for balloon: Balloon in _active_balloons:
		if is_instance_valid(balloon) and balloon.color_id == _config.target_color_id:
			balloon.set_highlighted(true)

func _clear_escalation() -> void:
	_frustration_level = 0
	for balloon: Balloon in _active_balloons:
		if is_instance_valid(balloon):
			balloon.set_highlighted(false)
