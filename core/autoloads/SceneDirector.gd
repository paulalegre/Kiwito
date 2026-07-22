extends Node

## Único autor de cambios de escena (ver Core_Architecture.md §1.2).
## Patrón "escena raíz + slot": el Hub y los minijuegos se instancian como
## hijos del contenedor persistente, nunca vía change_scene_to_*.

const FADE_TRANSITION_SCENE: PackedScene = preload("res://shared/ui_elements/transitions/fade_transition.tscn")
const HUB_SCENE: PackedScene = preload("res://features/hub_main/hub_main.tscn")

var _container: Node
var _fade: CanvasLayer
var _active_minigame: MinigameBase

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_container = Node.new()
	_container.name = "SceneContainer"
	add_child(_container)

	_fade = FADE_TRANSITION_SCENE.instantiate()
	add_child(_fade)

func goto_hub() -> void:
	await _swap_scene(HUB_SCENE.instantiate())

func launch_minigame(scene: PackedScene, config: LevelConfig) -> void:
	var minigame: MinigameBase = scene.instantiate() as MinigameBase
	await _swap_scene(minigame)
	_active_minigame = minigame
	_active_minigame.session_finished.connect(_on_minigame_session_finished)
	_active_minigame.start(config)

func _on_minigame_session_finished(_result: MinigameResult) -> void:
	goto_hub()

func _swap_scene(new_scene: Node) -> void:
	await _fade.fade_out()

	var old_scene: Node = null
	if _container.get_child_count() > 0:
		old_scene = _container.get_child(0)
		_container.remove_child(old_scene)

	if _active_minigame != null and old_scene == _active_minigame:
		_active_minigame.stop()
		_active_minigame = null
	elif old_scene != null:
		old_scene.queue_free()

	_container.add_child(new_scene)
	await _fade.fade_in()
