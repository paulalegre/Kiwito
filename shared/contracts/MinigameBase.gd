class_name MinigameBase
extends Node2D

## El Host conecta esta señal local al instanciar el cartucho.
signal session_finished(result: MinigameResult)

func start(config: LevelConfig) -> void:
	push_error("start() no implementado")

func pause() -> void:
	get_tree().paused = true

func resume() -> void:
	get_tree().paused = false

func stop() -> void:
	queue_free()
