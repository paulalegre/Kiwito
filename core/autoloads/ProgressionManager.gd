extends Node

## Único dueño en memoria del progreso de hitos (GDD_MVP.md §6). SaveManager
## solo hace I/O; las reglas de desbloqueo viven aquí.

signal sticker_unlocked(id: StringName)

## Tabla de hitos congelada (GDD_MVP.md §6). Un solo lector (este autoload);
## añadir un 4º hito es una línea nueva aquí, no requiere un Resource aparte.
const MILESTONES: Array[Dictionary] = [
	{"threshold": 5, "sticker_id": &"sticker_01"},
	{"threshold": 20, "sticker_id": &"sticker_02"},
	{"threshold": 50, "sticker_id": &"sticker_03"},
]

var total_balloons_popped: int = 0
var unlocked_stickers: Array = []


func _ready() -> void:
	total_balloons_popped = SaveManager.get_total_balloons_popped()
	unlocked_stickers = SaveManager.get_unlocked_stickers()


func record_session_result(result: MinigameResult) -> void:
	total_balloons_popped += result.correct_pops

	for milestone: Dictionary in MILESTONES:
		var sticker_id: StringName = milestone["sticker_id"]
		if total_balloons_popped >= milestone["threshold"] and not unlocked_stickers.has(sticker_id):
			unlocked_stickers.append(sticker_id)
			sticker_unlocked.emit(sticker_id)

	SaveManager.set_total_balloons_popped(total_balloons_popped)
	SaveManager.set_unlocked_stickers(unlocked_stickers)
	SaveManager.flush()
