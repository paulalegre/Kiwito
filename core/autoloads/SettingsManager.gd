extends Node

signal low_stim_changed(enabled: bool)

var low_stim_mode: bool = false


func _ready() -> void:
	low_stim_mode = SaveManager.get_low_stim_mode()


func set_low_stim_mode(value: bool) -> void:
	if value == low_stim_mode:
		return

	low_stim_mode = value
	SaveManager.set_low_stim_mode(value)
	SaveManager.flush()
	low_stim_changed.emit(value)
