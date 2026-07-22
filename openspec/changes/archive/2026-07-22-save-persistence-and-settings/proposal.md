## Why

`docs/Propuesta_MVP.md` §8 item 2, "Persistencia y settings," is the next unblocked roadmap phase: the
archived `core-foundations-phase1` change left `SaveManager` (`core/data/SaveManager.gd`) as an empty
I/O-layer stub with a comment only, and `SettingsManager` (`core/autoloads/SettingsManager.gd`) with a bare
`low_stim_mode: bool = false` field and an unused `low_stim_changed` signal — no file I/O, no persistence,
no logic. `docs/GDD_MVP.md` §7.3 frames save robustness as non-negotiable ("Un niño cierra la app de golpe y
la tablet se suspende sin aviso. El save debe sobrevivir a eso"), and the roadmap explicitly orders it
first: "se testea primero lo que corrompe datos del niño." This change makes `SaveManager` a real,
crash-safe I/O layer, gives `SettingsManager` real Low-Stim persistence, and adds the project's first GUT
tests so save robustness has automated coverage before any gameplay code exists to distract from it.

## What Changes

- **`SaveManager` (`core/data/SaveManager.gd`)**: real JSON I/O against `user://save_data.json` per
  `docs/GDD_MVP.md` §7 — atomic writes (write `user://save_data.json.tmp`, then rename over the real file,
  never in-place), a `save_version: int` field, and fallback to documented defaults when the file is
  missing, corrupt, or an unknown `save_version` — never crashes or blocks Zero-Click Boot. `SaveManager`
  owns only the file and the round-trip of the full save dict (`save_version`, `unlocked_stickers`,
  `total_balloons_popped`, `low_stim_mode`); it holds no opinion on what those values *mean* — that stays
  with `SettingsManager`/`ProgressionManager` per `GDD_MVP.md` §7.2's one-owner-per-domain rule. Flush
  happens at the safe points `GDD_MVP.md` §7.3 names (setting change, session end, app-pause/close
  notifications) — not on every event.
- **`SettingsManager` (`core/autoloads/SettingsManager.gd`)**: on `_ready()`, requests the persisted
  `low_stim_mode` from `SaveManager` and hydrates its in-memory field; exposes a setter that updates the
  in-memory value, asks `SaveManager` to persist it, and emits `low_stim_changed(enabled)` only when the
  value actually changes. `ProgressionManager`'s fields are *not* touched by this change (still Phase 4),
  but `SaveManager`'s round-trip must not silently drop them from the JSON when `SettingsManager` triggers
  a save.
- **First GUT tests**: add the GUT addon under `addons/gut/` and a `tests/` (or `res://tests/`, per GUT
  convention) suite covering `SaveManager` robustness — missing file, corrupt JSON, unknown `save_version`,
  and that an interrupted/simulated-crash write never leaves the real save file corrupted (only the `.tmp`
  file is at risk, never the committed one). No `ProgressionManager`-milestone or `LevelConfig`-parsing
  tests yet — `CLAUDE.md`'s testing note orders those later, and `ProgressionManager` has no real logic
  yet to test.

## Capabilities

### New Capabilities
- `gut-test-suite`: the GUT (Godot Unit Test) framework being present in the project and the convention for
  where pure-logic tests live, prioritized in the order `docs/Core_Architecture.md` §7 fixes (save
  robustness first).

### Modified Capabilities
- `autoload-bootstrap`: the "SaveManager is the sole persistence I/O layer" requirement moves from
  "no autoload does I/O yet" (implicitly true because `SaveManager` was an empty stub) to real, verifiable
  atomic-write/versioning/fallback behavior. Adds a scenario for `SettingsManager` requesting
  `low_stim_mode` persistence *through* `SaveManager` rather than touching the file itself, and a scenario
  confirming a `SaveManager` round-trip doesn't drop `ProgressionManager`'s not-yet-implemented fields.

## Impact

- **Affected code:** `core/data/SaveManager.gd`, `core/autoloads/SettingsManager.gd`; new `addons/gut/`
  and a test suite directory. No autoload registration order changes, no other autoload touched.
- **Product/UX invariants:** directly serves the zero-punishment/robustness invariant (`Propuesta_MVP.md`
  §5, §9 risk table: "Cierre abrupto de la tablet → Escritura atómica + versionado + fallback a defaults").
  Low-Stim mode itself is not yet *consumed* by any rendering/audio/juice code (that's Phase 5) — this
  change only makes the flag persist and broadcast correctly.
- **Fixed color/pattern table:** not touched.
- **Dependencies:** adds the GUT addon (dev-time test framework only, not a runtime dependency).
- **Downstream:** unblocks Phase 3 (the balloon cartridge can now assume `SettingsManager.low_stim_mode` is
  real and persisted) and Phase 4 (`ProgressionManager`'s milestones will plug into the same `SaveManager`
  I/O layer this change hardens).
