extends GutTest

const TEST_METRICS_PATH: String = "user://test_metrics_log.json"

var _original_metrics_path: String
var _original_buffer: Array[Dictionary]


func before_each() -> void:
	_original_metrics_path = MetricsLogger.metrics_path
	_original_buffer = MetricsLogger._buffer.duplicate(true)

	MetricsLogger.metrics_path = TEST_METRICS_PATH
	MetricsLogger._buffer = []
	_delete_test_files()


func after_each() -> void:
	_delete_test_files()
	MetricsLogger.metrics_path = _original_metrics_path
	MetricsLogger._buffer = _original_buffer


func _delete_test_files() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists("test_metrics_log.json"):
		dir.remove("test_metrics_log.json")
	if dir.file_exists("test_metrics_log.json.tmp"):
		dir.remove("test_metrics_log.json.tmp")


func _make_result(correct_pops: int, failed_taps: int = 0) -> MinigameResult:
	var result: MinigameResult = MinigameResult.new()
	result.correct_pops = correct_pops
	result.failed_taps = failed_taps
	result.duration = 12.5
	result.errors_by_color = {}
	return result


func test_recording_a_session_appends_to_buffer_without_disk_io() -> void:
	MetricsLogger.record_session(_make_result(3))

	assert_eq(MetricsLogger._buffer.size(), 1, "recording should append to the in-memory buffer")
	assert_false(FileAccess.file_exists(TEST_METRICS_PATH), "recording alone must not write to disk")


func test_flush_appends_buffered_entries_to_telemetry_file_atomically() -> void:
	MetricsLogger.record_session(_make_result(3))
	MetricsLogger.record_session(_make_result(5))

	MetricsLogger.flush()

	assert_true(FileAccess.file_exists(TEST_METRICS_PATH), "flush should write the telemetry file")
	assert_false(FileAccess.file_exists(TEST_METRICS_PATH + ".tmp"), "the .tmp file must not survive a successful flush")
	assert_true(MetricsLogger._buffer.is_empty(), "flush should drain the in-memory buffer")

	var file: FileAccess = FileAccess.open(TEST_METRICS_PATH, FileAccess.READ)
	var parsed: Array = JSON.parse_string(file.get_as_text())
	file.close()

	assert_eq(parsed.size(), 2, "both buffered entries should be appended")
	assert_eq(int(parsed[0]["correct_pops"]), 3)
	assert_eq(int(parsed[1]["correct_pops"]), 5)


func test_second_flush_appends_rather_than_overwrites() -> void:
	MetricsLogger.record_session(_make_result(3))
	MetricsLogger.flush()

	MetricsLogger.record_session(_make_result(7))
	MetricsLogger.flush()

	var file: FileAccess = FileAccess.open(TEST_METRICS_PATH, FileAccess.READ)
	var parsed: Array = JSON.parse_string(file.get_as_text())
	file.close()

	assert_eq(parsed.size(), 2, "a second flush should append to, not overwrite, existing entries")


func test_corrupt_existing_file_is_tolerated_and_treated_as_empty_history() -> void:
	var corrupt_file: FileAccess = FileAccess.open(TEST_METRICS_PATH, FileAccess.WRITE)
	corrupt_file.store_string("{ not valid json ]")
	corrupt_file.close()

	MetricsLogger.record_session(_make_result(4))
	MetricsLogger.flush()

	var file: FileAccess = FileAccess.open(TEST_METRICS_PATH, FileAccess.READ)
	var parsed: Array = JSON.parse_string(file.get_as_text())
	file.close()

	assert_eq(parsed.size(), 1, "corrupt existing history should be discarded, not appended to")
	assert_eq(int(parsed[0]["correct_pops"]), 4)


func test_flush_failure_discards_buffer_and_does_not_raise() -> void:
	MetricsLogger.metrics_path = "user://nonexistent_dir_xyz/metrics_log.json"
	MetricsLogger.record_session(_make_result(9))

	MetricsLogger.flush()

	assert_true(MetricsLogger._buffer.is_empty(), "a failed flush should still discard the buffered entries")
	assert_false(FileAccess.file_exists("user://nonexistent_dir_xyz/metrics_log.json"), "no file should be created when the write fails")


func test_empty_buffer_flush_is_a_no_op() -> void:
	MetricsLogger.flush()

	assert_false(FileAccess.file_exists(TEST_METRICS_PATH), "flushing an empty buffer must not create a file")
