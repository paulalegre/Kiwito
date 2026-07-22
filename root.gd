extends Node

## Punto de arranque mínimo: cede el control a SceneDirector inmediatamente.
## Vive en res:// (no en core/shared/features) porque es plumbing de motor,
## no código de dominio — análogo a project.godot.

func _ready() -> void:
	SceneDirector.goto_hub()
