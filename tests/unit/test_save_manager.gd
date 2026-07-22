extends GutTest

const TEST_SAVE_PATH: String = "user://test_save_data.json"

var _original_save_path: String
var _original_save_data: Dictionary
var _original_settings_low_stim: bool


func before_each() -> void:
	_original_save_path = SaveManager.save_path
	_original_save_data = SaveManager._save_data.duplicate(true)
	_original_settings_low_stim = SettingsManager.low_stim_mode

	SaveManager.save_path = TEST_SAVE_PATH
	_delete_test_files()


func after_each() -> void:
	_delete_test_files()
	SaveManager.save_path = _original_save_path
	SaveManager._save_data = _original_save_data
	SettingsManager.low_stim_mode = _original_settings_low_stim


func _delete_test_files() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists("test_save_data.json"):
		dir.remove("test_save_data.json")
	if dir.file_exists("test_save_data.json.tmp"):
		dir.remove("test_save_data.json.tmp")


func test_missing_file_returns_defaults() -> void:
	SaveManager.reload()

	assert_false(SaveManager.get_low_stim_mode(), "low_stim_mode should default to false")
	assert_eq(SaveManager.get_total_balloons_popped(), 0, "total_balloons_popped should default to 0")
	assert_eq(SaveManager.get_unlocked_stickers(), [], "unlocked_stickers should default to an empty array")


func test_corrupt_json_returns_defaults() -> void:
	var file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ this is not valid json ]")
	file.close()

	SaveManager.reload()

	assert_false(SaveManager.get_low_stim_mode(), "corrupt JSON should fall back to defaults")
	assert_eq(SaveManager.get_total_balloons_popped(), 0, "corrupt JSON should fall back to defaults")


func test_unknown_save_version_returns_defaults() -> void:
	var file: FileAccess = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"save_version": 999,
		"unlocked_stickers": ["sticker_99"],
		"total_balloons_popped": 42,
		"low_stim_mode": true,
	}))
	file.close()

	SaveManager.reload()

	assert_false(SaveManager.get_low_stim_mode(), "unknown save_version should fall back to defaults")
	assert_eq(SaveManager.get_total_balloons_popped(), 0, "unknown save_version should fall back to defaults")


func test_stray_incomplete_tmp_file_does_not_corrupt_committed_save() -> void:
	SaveManager.reload()
	SaveManager.set_total_balloons_popped(5)
	SaveManager.flush()

	var tmp_file: FileAccess = FileAccess.open(TEST_SAVE_PATH + ".tmp", FileAccess.WRITE)
	tmp_file.store_string("{ incomplete")
	tmp_file.close()

	SaveManager.reload()

	assert_eq(SaveManager.get_total_balloons_popped(), 5, "a stray incomplete .tmp file must not affect the committed save")


func test_settings_manager_flush_preserves_untouched_progression_fields() -> void:
	SaveManager.reload()
	SaveManager.set_unlocked_stickers(["sticker_01"])
	SaveManager.set_total_balloons_popped(7)
	SaveManager.flush()

	SettingsManager.low_stim_mode = false
	SettingsManager.set_low_stim_mode(true)

	SaveManager.reload()

	assert_eq(SaveManager.get_unlocked_stickers(), ["sticker_01"], "unlocked_stickers must be unchanged by a SettingsManager-only flush")
	assert_eq(SaveManager.get_total_balloons_popped(), 7, "total_balloons_popped must be unchanged by a SettingsManager-only flush")
	assert_true(SaveManager.get_low_stim_mode(), "low_stim_mode must reflect the value SettingsManager persisted")
