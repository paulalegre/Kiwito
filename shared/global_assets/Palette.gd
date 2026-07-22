class_name Palette
extends Resource

## Fuente única de color del proyecto (Direccion_de_Arte.md §2.2/§6.2).
## Prohibido literales hex en escenas/scripts: todo color de juego se resuelve
## desde aquí, nunca al revés.

@export var colors: Dictionary[StringName, Color] = {}
@export var pattern_ids: Dictionary[StringName, StringName] = {}

func get_color(color_id: StringName) -> Color:
	return colors.get(color_id, Color.WHITE)

func get_pattern_id(color_id: StringName) -> StringName:
	return pattern_ids.get(color_id, &"")
