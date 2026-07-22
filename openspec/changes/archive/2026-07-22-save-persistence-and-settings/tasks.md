## 1. SaveManager core I/O

- [x] 1.1 Define the in-memory save-data shape in `core/data/SaveManager.gd` matching `GDD_MVP.md` §7.4
      (`save_version: int`, `unlocked_stickers: Array`, `total_balloons_popped: int`,
      `low_stim_mode: bool`) with documented default values for a fresh install
- [x] 1.2 Implement `load_save() -> void` (or equivalent internal load called from `_ready()`): reads
      `user://save_data.json` via `FileAccess`, parses JSON, validates `save_version` is known; on any
      failure (missing file, invalid JSON, unknown version) logs a `push_warning` and falls back to the
      default shape from 1.1 without crashing
- [x] 1.3 Implement the atomic write: write full current save dict as JSON to
      `user://save_data.json.tmp`, close the file, then use `DirAccess` to rename it over
      `user://save_data.json`
- [x] 1.4 Add typed getters/setters per field-owner: `get_low_stim_mode()/set_low_stim_mode(value: bool)`,
      `get_unlocked_stickers()/set_unlocked_stickers(value: Array)`,
      `get_total_balloons_popped()/set_total_balloons_popped(value: int)` — setters update the in-memory
      dict only, they do not themselves trigger a disk write
- [x] 1.5 Add an explicit `flush() -> void` (or `save() -> void`) that performs the atomic write of the
      current in-memory dict; wire it to `NOTIFICATION_APPLICATION_PAUSED` and
      `NOTIFICATION_WM_CLOSE_REQUEST` inside `SaveManager` itself (via `_notification()`) per `GDD_MVP.md`
      §7.3's safe-flush-points list

## 2. SettingsManager real Low-Stim logic

- [x] 2.1 In `SettingsManager._ready()`, call `SaveManager.get_low_stim_mode()` and hydrate the in-memory
      `low_stim_mode` field from it (no direct file access from `SettingsManager`)
- [x] 2.2 Add a setter (e.g. `set_low_stim_mode(value: bool) -> void`) that updates the in-memory field,
      calls `SaveManager.set_low_stim_mode(value)` + `SaveManager.flush()`, and emits
      `low_stim_changed(value)` only if the value actually changed from before

## 3. GUT setup

- [x] 3.1 Add the GUT addon under `addons/gut/` (per `docs/Core_Architecture.md` §7) and enable it in
      `project.godot`'s `[editor_plugins]`/addon list
- [x] 3.2 Create the test directory (`res://tests/unit/`) and a GUT run configuration usable headlessly

## 4. SaveManager robustness tests

- [x] 4.1 Test: loading with no `user://save_data.json` present returns documented defaults, no error
- [x] 4.2 Test: loading a file containing invalid JSON returns documented defaults, logs a warning, no
      crash
- [x] 4.3 Test: loading a file with an unrecognized `save_version` returns documented defaults, no crash
- [x] 4.4 Test: a leftover incomplete `user://save_data.json.tmp` alongside a valid committed
      `user://save_data.json` does not affect the load result — the committed file wins
- [x] 4.5 Test: after `SettingsManager` changes and flushes `low_stim_mode`, reloading the save preserves
      `unlocked_stickers`/`total_balloons_popped` unchanged from before the change

## 5. Verification

- [x] 5.1 Run the full GUT suite headlessly and confirm all `SaveManager` tests pass — 5/5 tests, 11
      asserts, all green (`Godot_v4.7.1-stable_win64_console.exe --headless --script
      res://addons/gut/gut_cmdln.gd -gexit`); required one prior `--headless --editor --quit` run to
      rebuild the script-class cache for GUT's `class_name` scripts, same one-time step Phase 1 needed for
      `MinigameBase`/`LevelConfig`/`MinigameResult`
- [x] 5.2 Boot the project (`mcp__godot__run_project` + `get_debug_output`) with no existing save file and
      confirm zero errors — clean boot, zero errors, only the 3 pre-existing unrelated stub warnings
      (the previous 4th warning, `low_stim_changed` unused, is now gone since `SettingsManager` emits it)
- [x] 5.3 Boot the project again with a hand-corrupted `user://save_data.json` and confirm zero errors and
      that defaults are used — Godot's own JSON parser logs its standard `ERROR: Parse JSON failed` line
      (engine diagnostic, not a crash), `SaveManager` catches it and logs
      `WARNING: SaveManager: user://save_data.json no contiene JSON válido; usando defaults`, and the
      process continues running normally with no crash
