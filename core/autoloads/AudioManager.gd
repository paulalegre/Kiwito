extends Node

## Servicio de audio global (Core_Architecture.md §8). Audio es servicio, no
## evento: se invoca por llamadas directas, nunca por señales globales.
## Un id sin AudioStream registrado nunca crashea ni bloquea el juego del
## niño — solo emite push_warning y no reproduce nada (§8.5).

const DUCK_VOLUME_DB: float = -12.0
const DUCK_TWEEN_DURATION_SEC: float = 0.2
const SFX_POOL_SIZE: int = 4
const SFX_LOW_STIM_ATTENUATION_DB: float = -6.0
const MUSIC_CROSSFADE_DURATION_SEC: float = 0.8

## Registro disperso de sonidos. Ningún archivo de audio existe aún en el
## proyecto (design.md, Decisión 1): un id ausente aquí es el camino normal,
## no un error — cae en el fallback de _play_missing().
const SFX_REGISTRY: Dictionary[StringName, AudioStream] = {}
const VO_REGISTRY: Dictionary[StringName, AudioStream] = {}
const MUSIC_REGISTRY: Dictionary[StringName, AudioStream] = {}

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _vo_player: AudioStreamPlayer
var _music_players: Array[AudioStreamPlayer] = []
var _active_music_index: int = 0
var _duck_tween: Tween


func _ready() -> void:
	for i in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)

	_vo_player = AudioStreamPlayer.new()
	_vo_player.bus = &"VO"
	_vo_player.finished.connect(_on_vo_finished)
	add_child(_vo_player)

	for i in range(2):
		var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
		music_player.bus = &"Music"
		add_child(music_player)
		_music_players.append(music_player)


func play_sfx(sfx_id: StringName) -> void:
	var stream: AudioStream = SFX_REGISTRY.get(sfx_id)
	if stream == null:
		_warn_missing(sfx_id, "play_sfx")
		return

	var player: AudioStreamPlayer = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()

	player.volume_db = SFX_LOW_STIM_ATTENUATION_DB if SettingsManager.low_stim_mode else 0.0
	player.stream = stream
	player.play()


func play_vo(vo_id: StringName) -> void:
	var stream: AudioStream = VO_REGISTRY.get(vo_id)
	if stream == null:
		_warn_missing(vo_id, "play_vo")
		return

	_vo_player.stop()
	_vo_player.stream = stream
	_vo_player.play()
	_duck_music()


func stop_vo() -> void:
	_vo_player.stop()
	_restore_music()


func set_music(track_id: StringName) -> void:
	var stream: AudioStream = MUSIC_REGISTRY.get(track_id)
	if stream == null:
		_warn_missing(track_id, "set_music")
		return

	var old_player: AudioStreamPlayer = _music_players[_active_music_index]
	var new_index: int = 1 - _active_music_index
	var new_player: AudioStreamPlayer = _music_players[new_index]

	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(new_player, "volume_db", 0.0, MUSIC_CROSSFADE_DURATION_SEC)
	if old_player.playing:
		tween.tween_property(old_player, "volume_db", -80.0, MUSIC_CROSSFADE_DURATION_SEC)
		tween.chain().tween_callback(old_player.stop)

	_active_music_index = new_index


func _duck_music() -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()

	var music_bus_idx: int = AudioServer.get_bus_index(&"Music")
	var start_db: float = AudioServer.get_bus_volume_db(music_bus_idx)
	_duck_tween = create_tween()
	_duck_tween.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(music_bus_idx, db),
		start_db,
		DUCK_VOLUME_DB,
		DUCK_TWEEN_DURATION_SEC
	)


func _restore_music() -> void:
	if _duck_tween != null and _duck_tween.is_valid():
		_duck_tween.kill()

	var music_bus_idx: int = AudioServer.get_bus_index(&"Music")
	var start_db: float = AudioServer.get_bus_volume_db(music_bus_idx)
	_duck_tween = create_tween()
	_duck_tween.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(music_bus_idx, db),
		start_db,
		0.0,
		DUCK_TWEEN_DURATION_SEC
	)


func _on_vo_finished() -> void:
	_restore_music()


func _warn_missing(id: StringName, caller: String) -> void:
	push_warning("AudioManager.%s: id no registrado '%s', no se reproduce nada" % [caller, id])
