extends Node

## Única capa de I/O de persistencia (user://save_data.json). Sin reglas de juego.
## Escritura atómica (tmp + rename), versionada, con fallback a defaults ante
## archivo ausente/corrupto/de versión desconocida (GDD_MVP.md §7).

const DEFAULT_SAVE_PATH: String = "user://save_data.json"
const CURRENT_SAVE_VERSION: int = 1

var save_path: String = DEFAULT_SAVE_PATH
var _save_data: Dictionary = {}


func _ready() -> void:
	reload()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush()


func reload() -> void:
	_save_data = _read_from_disk()


func flush() -> void:
	var tmp_path: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: no se pudo abrir %s para escritura (error %d)" % [tmp_path, FileAccess.get_open_error()])
		return

	file.store_string(JSON.stringify(_save_data))
	file.close()

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_warning("SaveManager: no se pudo acceder a user:// para finalizar el guardado")
		return

	var err: Error = dir.rename(_filename(tmp_path), _filename(save_path))
	if err != OK:
		push_warning("SaveManager: el rename hacia %s falló con error %d" % [save_path, err])


func get_low_stim_mode() -> bool:
	return _save_data.get("low_stim_mode", false)


func set_low_stim_mode(value: bool) -> void:
	_save_data["low_stim_mode"] = value


func get_unlocked_stickers() -> Array:
	return _save_data.get("unlocked_stickers", [])


func set_unlocked_stickers(value: Array) -> void:
	_save_data["unlocked_stickers"] = value


func get_total_balloons_popped() -> int:
	return _save_data.get("total_balloons_popped", 0)


func set_total_balloons_popped(value: int) -> void:
	_save_data["total_balloons_popped"] = value


func _default_data() -> Dictionary:
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"unlocked_stickers": [],
		"total_balloons_popped": 0,
		"low_stim_mode": false,
	}


func _read_from_disk() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return _default_data()

	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: no se pudo abrir %s para lectura (error %d); usando defaults" % [save_path, FileAccess.get_open_error()])
		return _default_data()

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: %s no contiene JSON válido; usando defaults" % save_path)
		return _default_data()

	var data: Dictionary = parsed
	var defaults: Dictionary = _default_data()

	if int(data.get("save_version", -1)) != CURRENT_SAVE_VERSION:
		push_warning("SaveManager: %s tiene un save_version desconocido; usando defaults" % save_path)
		return defaults

	return {
		"save_version": CURRENT_SAVE_VERSION,
		"unlocked_stickers": data.get("unlocked_stickers", defaults["unlocked_stickers"]),
		"total_balloons_popped": data.get("total_balloons_popped", defaults["total_balloons_popped"]),
		"low_stim_mode": data.get("low_stim_mode", defaults["low_stim_mode"]),
	}


func _filename(path: String) -> String:
	return path.trim_prefix("user://")
