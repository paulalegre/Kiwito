## Context

`SaveManager` (`core/data/SaveManager.gd`) is currently an empty stub — just a comment saying atomic
I/O + versioning "se implementa en la Fase 2." `SettingsManager` (`core/autoloads/SettingsManager.gd`) has
`low_stim_mode: bool = false` and `signal low_stim_changed(enabled: bool)` but nothing reads or writes them
against disk. Both are already registered as autoloads in the fixed order `SaveManager` → `SettingsManager`
(§5.1), so `SaveManager` is guaranteed to exist by the time `SettingsManager._ready()` runs. No autoload
may reference another's singleton in `_init()` (already-locked `autoload-bootstrap` requirement) — so all
cross-autoload calls (`SettingsManager` asking `SaveManager` to load/save) must happen in `_ready()` or
later.

`docs/GDD_MVP.md` §7 is the frozen save contract: JSON only (never `.tres`, which is an insecure
deserialization vector for user-writable data), one owner per field (`ProgressionManager` owns
`unlocked_stickers`/`total_balloons_popped`, `SettingsManager` owns `low_stim_mode`, `SaveManager` owns only
the file), atomic tmp-then-rename writes, a `save_version: int`, fallback to defaults on any read failure,
and flushing only at safe points (setting change, minigame session end,
`NOTIFICATION_APPLICATION_PAUSED`/`NOTIFICATION_WM_CLOSE_REQUEST`) rather than every event.

`ProgressionManager` still has no real logic (Phase 4). This design has to decide how `SaveManager` handles
fields it doesn't yet have a live writer for, without inventing `ProgressionManager` behavior early.

## Goals / Non-Goals

**Goals:**
- `SaveManager` can load the full save schema (`save_version`, `unlocked_stickers`,
  `total_balloons_popped`, `low_stim_mode`), returning documented defaults for any field/file it can't read.
- `SaveManager` writes atomically and never leaves `user://save_data.json` itself corrupted, even if the
  process dies mid-write.
- `SettingsManager` persists `low_stim_mode` through `SaveManager` and hydrates from it on boot.
- A round-trip (load → `SettingsManager` changes `low_stim_mode` → save) preserves
  `unlocked_stickers`/`total_balloons_popped` unchanged, even though nothing writes them yet.
- GUT is runnable in this project and has tests proving the above.

**Non-Goals:**
- No `ProgressionManager` logic, no milestone/sticker rules, no signal wiring for progression saves
  (Phase 4).
- No consumption of `low_stim_mode` by rendering/audio/juice code (Phase 5) — this change only makes the
  flag persist and broadcast.
- No save-format migration logic beyond "unknown version → defaults" — versioned migrations are explicitly
  post-MVP per `GDD_MVP.md` §7.3.
- No UI for settings (no pause-menu toggle) — this change is the autoload logic only.

## Decisions

- **`SaveManager` owns one in-memory dict mirroring the JSON schema, exposed through typed
  getter/setter methods (not raw dict access) per field-owner.** E.g. `get_low_stim_mode() -> bool`,
  `set_low_stim_mode(value: bool) -> void`, and equivalents shaped for `ProgressionManager`'s fields even
  though nothing calls the progression setters yet. Alternative considered: expose the whole `Dictionary`
  for each autoload to mutate directly — rejected because it lets a caller touch a field it doesn't own
  (violates `GDD_MVP.md` §7.2's one-owner-per-domain rule) and couples callers to the JSON's exact shape
  instead of a stable method contract.
- **Load-then-cache, write-through on every setter call, actual disk flush only at named safe points.**
  `SaveManager` keeps the loaded dict in memory after boot; setters update the in-memory copy immediately
  (so a same-session `get` reflects the latest `set`) but the atomic disk write is triggered explicitly by
  the caller (e.g. `SettingsManager` calls a `SaveManager.flush()`/`save()` after changing
  `low_stim_mode`, and later `NOTIFICATION_APPLICATION_PAUSED` also triggers one) rather than on every
  setter. Alternative (write to disk on every setter call) was rejected — `GDD_MVP.md` §7.3 explicitly
  says not to persist on every event, and an atomic tmp-then-rename write on every single setting toggle
  is unnecessary I/O churn for a tablet.
- **Atomic write implementation: `FileAccess.open(path + ".tmp", WRITE)` → write JSON → `close()` →
  `DirAccess.rename(...)` over the real path.** Godot's `FileAccess` doesn't expose a POSIX `rename()`
  directly on itself, so the rename goes through `DirAccess`. This is the same pattern already documented
  in `GDD_MVP.md` §7.3 and referenced by the archived Phase 1 change; no alternative was considered since
  it's already a frozen decision.
- **Corrupt/missing/unknown-version handling: catch at load time, log via `push_warning` (not
  `push_error`, since this is an expected recoverable path, not a bug), and return an in-memory default
  dict — never `push_error`/crash.** Telemetry logging of the discarded save (`GDD_MVP.md` §7.3: "Un save
  ilegible se registra en telemetría") is deferred: `MetricsLogger` is still an empty stub (Phase 6), so
  this change can only leave a `push_warning` for now, not a real telemetry event — noted as a follow-up,
  not implemented here.
- **GUT lives under `addons/gut/` (standard Godot addon location) with tests under `res://tests/unit/`.**
  Matches GUT's own convention and keeps test code out of `core/`/`shared/`/`features/`, which
  `project-directory-topology`'s spec reserves for product code, not tooling.

## Risks / Trade-offs

- [Simulating a "crash mid-write" in an automated GUT test is inherently approximate — Godot doesn't offer
  a way to kill the process at an exact byte offset from within the test itself] → Mitigation: the test
  verifies the *mechanism* (a `.tmp` file is written and only renamed into place after the full write
  succeeds; manually leaving a stray/partial `.tmp` file and a valid original never corrupts the original
  on next load) rather than truly injecting a kill signal mid-syscall.
- [Adding typed getter/setter methods for `ProgressionManager`'s fields on `SaveManager` before
  `ProgressionManager` itself has any logic risks guessing wrong about the exact API `ProgressionManager`
  will want in Phase 4] → Mitigation: keep the getters/setters minimal and directly mirroring the frozen
  JSON schema in `GDD_MVP.md` §7.4 (`get_unlocked_stickers() -> Array`,
  `set_unlocked_stickers(value: Array) -> void`, `get_total_balloons_popped() -> int`,
  `set_total_balloons_popped(value: int) -> void`) — if Phase 4 needs a different shape, only
  `SaveManager`'s narrow method surface needs revisiting, not the file format.
- [GUT is a new third-party addon dependency] → Mitigation: it's editor/CI-time only, never shipped in an
  exported build's runtime path; `docs/Core_Architecture.md` §7 already names GUT as the intended
  framework, so this isn't introducing an undocumented dependency.

## Migration Plan

1. Implement `SaveManager`'s load/save/atomic-write/versioning/fallback logic and typed
   getters/setters.
2. Implement `SettingsManager._ready()` hydration and the `low_stim_mode` setter wired through
   `SaveManager`.
3. Add the GUT addon and the `SaveManager` robustness test suite; run it green before considering the
   change done.
4. Boot-verify the full project (`mcp__godot__run_project` + `get_debug_output`) with no `user://save_data.json`
   present (first-run/no-save case) and again with a hand-corrupted save file, confirming both boot
   without errors.
5. No rollback complexity: this only touches two autoload scripts plus additive test/addon files; a revert
   is a plain file revert with no data-migration concern (no save format shipped to real users yet).

## Open Questions

None — the save schema, ownership rules, and atomic-write mechanism are already frozen in `GDD_MVP.md` §7;
this change applies them rather than deciding them.
