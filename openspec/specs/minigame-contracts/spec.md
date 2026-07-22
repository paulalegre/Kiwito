# minigame-contracts Specification

## Purpose

Defines the thin shared vocabulary — `MinigameBase`, `MinigameResult`, `LevelConfig` — that lets a minigame
be built and dropped in as an isolated "cartridge" that never references the Host or another minigame,
communicating only through `start(config)` and the `session_finished(result)` signal
(`docs/Core_Architecture.md` §3). This is what makes "add a minigame, or a new educational dimension inside
one, without touching architecture code" possible: `MatchRule` on `LevelConfig` grows by adding enum values
and `.tres` data (Phase 2+), never by changing `MinigameBase` or `MinigameResult`.

## Requirements

### Requirement: MinigameBase contract shape
`shared/contracts/MinigameBase.gd` SHALL define `class_name MinigameBase extends Node2D` exposing
`start(config: LevelConfig) -> void` (required override — the default implementation SHALL
`push_error`), `pause() -> void`, `resume() -> void`, `stop() -> void`, and a
`session_finished(result: MinigameResult)` signal. This is the only inheritance point in the project deeper
than one level from an engine base class.

#### Scenario: Default start() is not silently usable
- **WHEN** a `MinigameBase` instance's `start()` is called without being overridden by a subclass
- **THEN** it calls `push_error()` and performs no gameplay setup

#### Scenario: Default pause/resume toggle tree pause state
- **WHEN** `pause()` is called on a `MinigameBase` instance
- **THEN** `get_tree().paused` becomes `true`, and calling `resume()` afterward sets it back to `false`

### Requirement: Cartridge isolation
A class extending `MinigameBase` SHALL NOT reference the Host, another minigame's nodes/scripts, or any
node outside its own subtree. It SHALL communicate its result exclusively through the
`session_finished(result: MinigameResult)` signal, which the Host connects when instantiating the
cartridge.

#### Scenario: Cartridge script has no external references
- **WHEN** a `MinigameBase` subclass's script is inspected
- **THEN** it contains no reference to a Host node, another minigame's class, or a node path that escapes
  its own scene subtree

### Requirement: MinigameResult shape
`shared/contracts/MinigameResult.gd` SHALL define a `RefCounted` class (not `Node`, not `Resource`) with
typed fields `correct_pops: int`, `failed_taps: int`, `duration: float`, and
`errors_by_color: Dictionary`, used to carry a single session's outcome from a cartridge to the Host.

#### Scenario: MinigameResult is a RefCounted value object
- **WHEN** `MinigameResult.gd` is inspected
- **THEN** it extends `RefCounted` and declares the four typed fields with no scene-tree dependency

### Requirement: LevelConfig shape and MatchRule enum
`shared/contracts/LevelConfig.gd` SHALL define a `Resource`-based base class carrying a `match_rule` field
typed to a `MatchRule` enum with at least the values `MATCH_ANY` and `MATCH_COLOR` (with
`MATCH_SHAPE`/`MATCH_SIZE`/`MATCH_COUNT` reserved as future enum values for Phase 2+, requiring no script
changes to add). `LevelConfig` instances SHALL only ever be loaded as trusted `res://` design content, never
as user-writable data.

#### Scenario: LevelConfig is a Resource, not user save data
- **WHEN** `LevelConfig.gd` is inspected
- **THEN** it extends `Resource` and no code path loads a `LevelConfig` `.tres` from `user://`

#### Scenario: MatchRule enum includes the two MVP values
- **WHEN** the `MatchRule` enum on `LevelConfig` is inspected
- **THEN** it includes `MATCH_ANY` and `MATCH_COLOR`
