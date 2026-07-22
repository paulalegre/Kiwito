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
rule or business logic SHALL live in `SaveManager`.

#### Scenario: Only SaveManager touches the save file path
- **WHEN** the codebase is searched for direct `FileAccess` usage against `user://save_data.json`
- **THEN** every match is inside `SaveManager`'s script
