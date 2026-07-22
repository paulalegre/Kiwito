## MODIFIED Requirements

### Requirement: SaveManager is the sole persistence I/O layer
`SaveManager` SHALL be the only autoload that performs file I/O against `user://save_data.json`. No game
rule or business logic SHALL live in `SaveManager`. `SaveManager` SHALL write atomically (write to
`user://save_data.json.tmp`, then rename over the real file — never in-place), SHALL include a
`save_version: int` field in the persisted JSON, and SHALL fall back to documented default values —
without crashing or blocking boot — when the save file is missing, corrupt, or reports an unknown
`save_version`. Other autoloads (`SettingsManager`, `ProgressionManager`) SHALL request persistence of
their own fields through typed `SaveManager` methods rather than touching the file directly, and a
`SaveManager` save/load round-trip SHALL preserve every domain's fields unchanged even when only one
domain's setter was called.

#### Scenario: Only SaveManager touches the save file path
- **WHEN** the codebase is searched for direct `FileAccess` usage against `user://save_data.json`
- **THEN** every match is inside `SaveManager`'s script

#### Scenario: Write is atomic
- **WHEN** `SaveManager` persists the save data
- **THEN** it writes to `user://save_data.json.tmp` first and only replaces the real file via a rename
  once the temporary file is fully written, so an interruption mid-write leaves the previously-committed
  `user://save_data.json` untouched

#### Scenario: Missing save file falls back to defaults
- **WHEN** `SaveManager` loads and `user://save_data.json` does not exist
- **THEN** it returns the documented default values for every field and does not crash or block boot

#### Scenario: Corrupt save file falls back to defaults
- **WHEN** `SaveManager` loads a `user://save_data.json` that is not valid JSON
- **THEN** it logs a warning (not an error) and returns the documented default values instead of crashing

#### Scenario: Unknown save_version falls back to defaults
- **WHEN** `SaveManager` loads a save file whose `save_version` is not one it recognizes
- **THEN** it logs a warning and returns the documented default values rather than attempting to interpret
  unknown-shaped data

#### Scenario: SettingsManager persists through SaveManager, not directly
- **WHEN** `SettingsManager.gd` is inspected
- **THEN** it contains no direct `FileAccess` usage and instead calls typed `SaveManager` methods to read
  or write `low_stim_mode`

#### Scenario: Round-trip preserves fields the caller didn't touch
- **WHEN** `SaveManager` loads existing save data, `SettingsManager` changes and persists only
  `low_stim_mode`, and the save file is loaded again
- **THEN** `unlocked_stickers` and `total_balloons_popped` are unchanged from what was loaded before the
  `low_stim_mode` change
