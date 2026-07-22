class_name PauseOverlay
extends CanvasLayer

## Chrome de Core, propiedad de SceneDirector (Core_Architecture.md §1.3):
## botón Casa (visible solo durante una sesión de minijuego activa) + overlay
## de pausa con dos affordances icon-only (Continuar / Salir al Hub), cero
## texto. Botón y overlay usan PROCESS_MODE_ALWAYS para seguir respondiendo
## con el árbol pausado.

@onready var _home_button: TappableIcon = $HomeButton
@onready var _overlay: ColorRect = $Overlay
@onready var _continuar_button: TappableIcon = $Overlay/CenterContainer/HBoxContainer/ContinuarButton
@onready var _salir_button: TappableIcon = $Overlay/CenterContainer/HBoxContainer/SalirButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_home_button.visible = false
	_overlay.visible = false
	_home_button.tapped.connect(_on_home_tapped)
	_continuar_button.tapped.connect(_on_continuar_tapped)
	_salir_button.tapped.connect(_on_salir_tapped)

func set_home_button_visible(value: bool) -> void:
	_home_button.visible = value

func _on_home_tapped() -> void:
	get_tree().paused = true
	_overlay.visible = true

func _on_continuar_tapped() -> void:
	get_tree().paused = false
	_overlay.visible = false

func _on_salir_tapped() -> void:
	get_tree().paused = false
	_overlay.visible = false
	SceneDirector.goto_hub()
