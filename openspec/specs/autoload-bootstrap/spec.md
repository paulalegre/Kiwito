# autoload-bootstrap Specification

## Purpose

Establishes the six domain-owning singletons and their fixed dependency order (`SaveManager` →
`SettingsManager`/`ProgressionManager` → `AudioManager`/`MetricsLogger`/`SceneDirector`) so that persisted
state (Low-Stim, progression) is always hydrated before anything reads it, and so no autoload ever becomes
a monolithic `GameState` duplicating another's data (`docs/Core_Architecture.md` §5.1, §6.1). This is the
seam later phases build real behavior into: Phase 2 fills in `SaveManager`'s atomic I/O and
`SettingsManager`'s Low-Stim logic, Phase 4 fills in `ProgressionManager`'s milestones, Phase 5 fills in
`AudioManager`, Phase 6 fills in `MetricsLogger` — without ever needing to renegotiate ownership or init
order.

## Requirements

### Requirement: Six domain autoloads registered in fixed init order
The project SHALL register exactly six autoloads in `project.godot`, in this order:
`SaveManager`, `SettingsManager`, `ProgressionManager`, `AudioManager`, `MetricsLogger`, `SceneDirector`.
`SaveManager` SHALL be first (nothing may read persisted state before it exists); `SettingsManager` and
`ProgressionManager` SHALL come immediately after (they hydrate from `SaveManager`); `AudioManager`,
`MetricsLogger`, and `SceneDirector` SHALL come last (they consume the state established above).

#### Scenario: Autoload order matches the dependency chain
- **WHEN** `project.godot`'s `[autoload]` section is inspected
- **THEN** the six entries appear in exactly the order `SaveManager`, `SettingsManager`,
  `ProgressionManager`, `AudioManager`, `MetricsLogger`, `SceneDirector`

### Requirement: Each autoload owns exactly one domain
Each autoload SHALL live in the location its domain dictates (`SaveManager` in `core/data/`; the other five
in `core/autoloads/`), expose only the state and signals belonging to its own domain, and SHALL NOT
duplicate state owned by another autoload (no monolithic `GameState`).

#### Scenario: SettingsManager owns low_stim_mode exclusively
- **WHEN** any autoload other than `SettingsManager` is inspected
- **THEN** it does not declare its own copy of `low_stim_mode` or re-derive Low-Stim state independently

#### Scenario: ProgressionManager declares its documented signal
- **WHEN** `ProgressionManager.gd` is inspected
- **THEN** it declares a `sticker_unlocked(id)` signal matching `Core_Architecture.md` §6.1

#### Scenario: SettingsManager declares its documented signal
- **WHEN** `SettingsManager.gd` is inspected
- **THEN** it declares a `low_stim_changed(enabled)` signal matching `Core_Architecture.md` §6.1

### Requirement: No autoload accesses another during `_init()`
Autoloads SHALL NOT reference another autoload's singleton inside their own `_init()` method. Cross-autoload
wiring SHALL happen only in `_ready()`, once every autoload is guaranteed to exist.

#### Scenario: Autoload script has no cross-autoload call in _init
- **WHEN** any of the six autoload scripts' `_init()` method is inspected
- **THEN** it contains no reference to another autoload's singleton name

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
