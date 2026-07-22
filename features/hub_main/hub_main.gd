extends Node2D

## Hub Principal (GDD_MVP.md §4): dos nodos interactivos, Caja de Globos y
## Libro Mágico. "Signals up, calls down" — este script conecta las señales
## locales de ambos nodos y decide qué hacer con cada toque.

const MG_BALLOONS_SCENE: PackedScene = preload("res://features/minigames/mg_balloons/mg_balloons.tscn")
const DEFAULT_LEVEL_CONFIG: LevelConfig = preload("res://features/minigames/mg_balloons/resources/level_match_color_red.tres")
const STICKER_ALBUM_SCENE: PackedScene = preload("res://shared/ui_elements/sticker_album/sticker_album.tscn")

@onready var _caja_de_globos: CajaDeGlobos = $CajaDeGlobos
@onready var _libro_magico: LibroMagico = $LibroMagico

var _sticker_album: Node = null

func _ready() -> void:
	_caja_de_globos.tapped.connect(_on_caja_de_globos_tapped)
	_libro_magico.tapped.connect(_on_libro_magico_tapped)

func _on_caja_de_globos_tapped() -> void:
	SceneDirector.launch_minigame(MG_BALLOONS_SCENE, DEFAULT_LEVEL_CONFIG)

func _on_libro_magico_tapped() -> void:
	if _sticker_album != null:
		return

	_sticker_album = STICKER_ALBUM_SCENE.instantiate()
	add_child(_sticker_album)
	_sticker_album.closed.connect(_on_sticker_album_closed)

func _on_sticker_album_closed() -> void:
	_sticker_album.queue_free()
	_sticker_album = null
