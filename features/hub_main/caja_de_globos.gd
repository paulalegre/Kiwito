class_name CajaDeGlobos
extends Node2D

## Nodo interactivo del Hub que inicia el cartucho Explotaglobos (GDD_MVP.md
## §4). Expone su propio toque como señal local (signals up); hub_main.gd
## decide qué hacer con ella.

signal tapped

@onready var _hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	_hitbox.tapped.connect(_on_hitbox_tapped)

func _on_hitbox_tapped() -> void:
	tapped.emit()
