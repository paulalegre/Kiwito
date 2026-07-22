# progression-and-hub Specification

## Purpose

Closes the Hub↔Minijuego loop end to end — the point `docs/Propuesta_MVP.md` §8 calls out as where "la
validación con niños puede empezar." Gives `ProgressionManager` its real logic (cumulative correct-pop
tracking loaded from `SaveManager`, milestone evaluation, and exactly-once sticker unlocking per the frozen
5/20/50 table in `docs/GDD_MVP.md` §6), has `SceneDirector` forward each finished minigame's
`MinigameResult` into that logic before returning to the Hub, and gives `features/hub_main/hub_main.tscn`
its first two interactive nodes — Caja de Globos (launches the Phase 3 balloon cartridge) and Libro Mágico
(opens the Álbum de Stickers) — plus the Álbum de Stickers modal itself, which renders one slot per
milestone as a locked black silhouette or an unlocked `palette.tres`-tinted shape. `minigame-contracts`,
`match-rule-engine`, and `mg-balloons-cartridge` are consumed unmodified; this capability only wires the
Hub side of the already-shipped cartridge contract.

## Requirements

### Requirement: ProgressionManager records cumulative correct pops
`ProgressionManager` SHALL load `total_balloons_popped` and `unlocked_stickers` from `SaveManager` on
`_ready()`, and SHALL expose `record_session_result(result: MinigameResult)` which adds
`result.correct_pops` to `total_balloons_popped`, persists the updated value via `SaveManager`, and flushes
at that point.

#### Scenario: Correct pops accumulate across sessions
- **WHEN** `record_session_result()` is called with `result.correct_pops == 5` after a prior
  `total_balloons_popped` of 3
- **THEN** `total_balloons_popped` becomes 8 and the new value is persisted via `SaveManager`

### Requirement: Milestone crossings unlock stickers exactly once
`ProgressionManager` SHALL evaluate the frozen milestone table (5 → `sticker_01`, 20 → `sticker_02`, 50 →
`sticker_03`, per `GDD_MVP.md` §6) after every `record_session_result()` call. Each milestone whose
threshold is newly met SHALL add its `sticker_id` to `unlocked_stickers` (if not already present) and emit
`sticker_unlocked(id)` exactly once for that crossing. An already-unlocked sticker SHALL NOT be re-added or
re-emitted.

#### Scenario: Crossing a threshold unlocks its sticker
- **WHEN** `total_balloons_popped` moves from 4 to 6 via `record_session_result()`
- **THEN** `sticker_01` is added to `unlocked_stickers`, `sticker_unlocked(&"sticker_01")` is emitted once,
  and the updated `unlocked_stickers` is persisted via `SaveManager`

#### Scenario: Already-unlocked sticker is not re-unlocked
- **WHEN** `record_session_result()` is called again while `total_balloons_popped` stays above 5 and
  `sticker_01` is already in `unlocked_stickers`
- **THEN** `sticker_unlocked` does not fire again for `sticker_01` and `unlocked_stickers` is unchanged

### Requirement: SceneDirector forwards session results to ProgressionManager
`SceneDirector` SHALL call `ProgressionManager.record_session_result(result)` with the `MinigameResult` from
a finished minigame's `session_finished` signal before returning to the Hub via `goto_hub()`.

#### Scenario: Session result reaches ProgressionManager before the Hub is shown
- **WHEN** a minigame cartridge emits `session_finished(result)`
- **THEN** `ProgressionManager.record_session_result(result)` is called with that same result before the
  Hub scene becomes active again

### Requirement: Hub's Caja de Globos launches the balloon cartridge
The Hub SHALL contain an interactive node ("Caja de Globos") that, on a valid tap, calls
`SceneDirector.launch_minigame()` with the balloon cartridge scene and a `BalloonLevelConfig` preset. It
SHALL use the shared `HitboxComponent` for input handling (oversized hitbox, palm-touch rejection,
input-consumption), unmodified from its Phase 3 implementation.

#### Scenario: Tapping the Caja de Globos launches the minigame
- **WHEN** a valid primary tap lands on the Caja de Globos's hitbox
- **THEN** `SceneDirector.launch_minigame()` is called with the balloon cartridge scene and a
  `BalloonLevelConfig` instance

### Requirement: Hub's Libro Mágico opens the Álbum de Stickers
The Hub SHALL contain an interactive node ("Libro Mágico") that, on a valid tap, opens the Álbum de
Stickers modal. It SHALL use the shared `HitboxComponent` for input handling, same as Caja de Globos.

#### Scenario: Tapping the Libro Mágico opens the album
- **WHEN** a valid primary tap lands on the Libro Mágico's hitbox
- **THEN** the Álbum de Stickers modal becomes visible

### Requirement: Álbum de Stickers renders lock state per milestone
The Álbum de Stickers modal SHALL render exactly one slot per entry in the frozen milestone table, reading
`ProgressionManager.unlocked_stickers` when it opens. A slot for a sticker not in `unlocked_stickers` SHALL
render as a plain black silhouette; a slot for a sticker present in `unlocked_stickers` SHALL render tinted
from `shared/global_assets/palette.tres` (never a literal hex value). The modal SHALL be dismissible by a
tap anywhere on its background, with no text or icon required to close it.

#### Scenario: Locked slot renders as a black silhouette
- **WHEN** the Álbum opens and `sticker_02` is not in `ProgressionManager.unlocked_stickers`
- **THEN** the `sticker_02` slot renders as plain black

#### Scenario: Unlocked slot renders in color
- **WHEN** the Álbum opens and `sticker_01` is in `ProgressionManager.unlocked_stickers`
- **THEN** the `sticker_01` slot renders tinted from `palette.tres`, not black

#### Scenario: Tapping the background dismisses the modal
- **WHEN** a valid primary tap lands anywhere on the Álbum's background while it is open
- **THEN** the modal closes
