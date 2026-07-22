extends GutTest

const TEST_SAVE_PATH: String = "user://test_save_data.json"

var _original_save_path: String
var _original_save_data: Dictionary
var _original_total_balloons_popped: int
var _original_unlocked_stickers: Array


func before_each() -> void:
	_original_save_path = SaveManager.save_path
	_original_save_data = SaveManager._save_data.duplicate(true)
	_original_total_balloons_popped = ProgressionManager.total_balloons_popped
	_original_unlocked_stickers = ProgressionManager.unlocked_stickers.duplicate()

	SaveManager.save_path = TEST_SAVE_PATH
	_delete_test_files()
	SaveManager.reload()
	ProgressionManager.total_balloons_popped = 0
	ProgressionManager.unlocked_stickers = []


func after_each() -> void:
	_delete_test_files()
	SaveManager.save_path = _original_save_path
	SaveManager._save_data = _original_save_data
	ProgressionManager.total_balloons_popped = _original_total_balloons_popped
	ProgressionManager.unlocked_stickers = _original_unlocked_stickers


func _delete_test_files() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists("test_save_data.json"):
		dir.remove("test_save_data.json")
	if dir.file_exists("test_save_data.json.tmp"):
		dir.remove("test_save_data.json.tmp")


func _make_result(correct_pops: int) -> MinigameResult:
	var result: MinigameResult = MinigameResult.new()
	result.correct_pops = correct_pops
	return result


func test_correct_pops_accumulate_across_sessions() -> void:
	ProgressionManager.record_session_result(_make_result(3))
	ProgressionManager.record_session_result(_make_result(5))

	assert_eq(ProgressionManager.total_balloons_popped, 8, "correct pops should accumulate across sessions")


func test_crossing_first_milestone_unlocks_sticker_and_emits_once() -> void:
	watch_signals(ProgressionManager)

	ProgressionManager.record_session_result(_make_result(6))

	assert_true(ProgressionManager.unlocked_stickers.has(&"sticker_01"), "sticker_01 should unlock at 5 correct pops")
	assert_signal_emit_count(ProgressionManager, "sticker_unlocked", 1, "sticker_unlocked should fire exactly once")
	assert_signal_emitted_with_parameters(ProgressionManager, "sticker_unlocked", [&"sticker_01"])


func test_already_unlocked_sticker_is_not_reunlocked() -> void:
	ProgressionManager.record_session_result(_make_result(6))
	watch_signals(ProgressionManager)

	ProgressionManager.record_session_result(_make_result(1))

	assert_signal_emit_count(ProgressionManager, "sticker_unlocked", 0, "an already-unlocked sticker must not re-emit")
	assert_eq(ProgressionManager.unlocked_stickers.count(&"sticker_01"), 1, "sticker_01 must not be duplicated")


func test_multiple_milestones_crossed_in_one_session_each_emit_once() -> void:
	watch_signals(ProgressionManager)

	ProgressionManager.record_session_result(_make_result(25))

	assert_true(ProgressionManager.unlocked_stickers.has(&"sticker_01"))
	assert_true(ProgressionManager.unlocked_stickers.has(&"sticker_02"))
	assert_false(ProgressionManager.unlocked_stickers.has(&"sticker_03"))
	assert_signal_emit_count(ProgressionManager, "sticker_unlocked", 2, "two milestones crossed in one session should emit twice")


func test_progress_persists_through_save_manager_reload() -> void:
	ProgressionManager.record_session_result(_make_result(6))

	SaveManager.reload()

	assert_eq(SaveManager.get_total_balloons_popped(), 6, "total_balloons_popped must be persisted")
	assert_eq(SaveManager.get_unlocked_stickers(), ["sticker_01"], "unlocked_stickers must be persisted (JSON round-trip yields plain String, not StringName)")
