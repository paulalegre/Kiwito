## Why

`docs/Propuesta_MVP.md` §8 item 4 ("Progresión y Hub") is next in the roadmap. `ProgressionManager`
currently exists only as an empty autoload stub (state fields declared, zero logic, not wired to
`SaveManager`), and `features/hub_main/hub_main.tscn` is a bare empty `Node2D` with no children. Without
this change there is no way to actually reach the balloon cartridge built in Phase 3 from a running game,
and no meta-progression (`GDD_MVP.md` §6) exists yet, even though `SaveManager` has already carried full
read/write support for `unlocked_stickers`/`total_balloons_popped` since Phase 2. This change closes the
Hub↔Minijuego loop end to end, which `Propuesta_MVP.md` §8 explicitly calls the point at which "la
validación con niños puede empezar."

## What Changes

- `ProgressionManager` gains real logic: loads `total_balloons_popped`/`unlocked_stickers` from
  `SaveManager` on `_ready()` (same shape as `SettingsManager`'s existing pattern), exposes a method to
  record a finished minigame session's correct pops as cumulative progress, checks the 3 frozen milestone
  thresholds from `GDD_MVP.md` §6 (5/20/50 total correct pops), unlocks the corresponding sticker id the
  first time a threshold is crossed, emits the already-declared `sticker_unlocked(id)` signal, and
  persists + flushes via `SaveManager` at that safe point (`GDD_MVP.md` §7.3).
- `SceneDirector` forwards a finished minigame's `MinigameResult` to `ProgressionManager` (direct typed
  autoload-to-autoload call, the same shape as `SettingsManager` calling into `SaveManager` — not a global
  string EventBus) before returning to the Hub.
- `features/hub_main/hub_main.tscn` gets its first two interactive nodes: **Caja de Globos** (tap launches
  the Phase 3 balloon cartridge via `SceneDirector.launch_minigame()`) and **Libro Mágico** (tap opens an
  Álbum de Stickers modal).
- A new Álbum de Stickers modal under `shared/ui_elements/` shows all known sticker slots as black
  silhouettes when locked and in color when unlocked, reading `ProgressionManager.unlocked_stickers`.
- All new visual placeholders (Caja de Globos, Libro Mágico, sticker slots) are flat shapes tinted from
  `shared/global_assets/palette.tres` — **no final Hub/sticker art exists yet**, and this change explicitly
  proceeds without it (same product decision already made for Change #3's balloon art); the deferred final
  art pass is noted as a follow-up in `design.md` so it isn't lost. Zero text throughout, per the
  product's zero-text invariant — all cues are visual/audio only.

## Capabilities

### New Capabilities
- `progression-and-hub`: `ProgressionManager`'s milestone/sticker-unlock logic, the Hub's two interactive
  nodes, the Álbum de Stickers modal, and the closed Hub↔Minijuego session loop.

### Modified Capabilities
- None. `minigame-contracts`, `match-rule-engine`, and `mg-balloons-cartridge` are consumed unmodified —
  this change only calls the balloon cartridge's existing `MinigameBase`/`session_finished(MinigameResult)`
  contract from the Hub side, it does not alter any of their requirements.

## Impact

- Modified: `core/autoloads/ProgressionManager.gd` (stub → real logic), `core/autoloads/SceneDirector.gd`
  (forward `MinigameResult` to `ProgressionManager`), `features/hub_main/hub_main.tscn` (empty → Caja de
  Globos + Libro Mágico).
- New: a sticker-album modal scene/script under `shared/ui_elements/`, placeholder Hub/sticker art tinted
  via `palette.tres`, no new autoloads (init order in `CLAUDE.md`/`Core_Architecture.md` §5.1 is unchanged).
- Out of scope, deferred to their already-assigned later phases: pause menu (not named in roadmap item 4's
  own text, despite being part of the frozen MVP scope list), `AudioManager` real audio/VO (Phase 5),
  Low-Stim reactions in the new Hub UI (Phase 5), `MetricsLogger` telemetry (Phase 6).
