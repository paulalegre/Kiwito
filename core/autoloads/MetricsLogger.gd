extends Node

## Telemetría local pasiva (buffer en memoria, flush en puntos seguros).
## Verdaderamente pasivo (Core_Architecture.md §5): un fallo de I/O nunca
## interrumpe el juego del niño. No depende de SaveManager (las métricas no
## son save data) ni abre ninguna conexión de red.

const DEFAULT_METRICS_PATH: String = "user://metrics_log.json"

var metrics_path: String = DEFAULT_METRICS_PATH
var _buffer: Array[Dictionary] = []


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush()


func record_session(result: MinigameResult) -> void:
	_buffer.append({
		"timestamp": Time.get_datetime_string_from_system(true),
		"correct_pops": result.correct_pops,
		"failed_taps": result.failed_taps,
		"duration": result.duration,
		"errors_by_color": result.errors_by_color,
	})


func flush() -> void:
	if _buffer.is_empty():
		return

	var entries: Array[Dictionary] = _buffer
	_buffer = []

	var history: Array = _read_existing()
	history.append_array(entries)

	var tmp_path: String = metrics_path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_warning("MetricsLogger: no se pudo abrir %s para escritura (error %d); se descarta el flush" % [tmp_path, FileAccess.get_open_error()])
		return

	file.store_string(JSON.stringify(history))
	file.close()

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_warning("MetricsLogger: no se pudo acceder a user:// para finalizar el flush")
		return

	var err: Error = dir.rename(_filename(tmp_path), _filename(metrics_path))
	if err != OK:
		push_warning("MetricsLogger: el rename hacia %s falló con error %d" % [metrics_path, err])


func _read_existing() -> Array:
	if not FileAccess.file_exists(metrics_path):
		return []

	var file: FileAccess = FileAccess.open(metrics_path, FileAccess.READ)
	if file == null:
		push_warning("MetricsLogger: no se pudo abrir %s para lectura (error %d); se ignora el histórico" % [metrics_path, FileAccess.get_open_error()])
		return []

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("MetricsLogger: %s no contiene JSON válido; se ignora el histórico" % metrics_path)
		return []

	return parsed


func _filename(path: String) -> String:
	return path.trim_prefix("user://")
