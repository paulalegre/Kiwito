## Context

The repo currently has a flat prototype (`scripts/main.gd`, `scripts/globo.gd`, `scenes/`) with no
autoloads and no `core/`/`shared`/`features/` split. `Core_Architecture.md` v3.0 is normative for the
target shape but nothing has been built against it yet. This change is purely structural/scaffolding: real
logic (save I/O, matching engine, progression, audio) is deliberately deferred to Phases 2–5. The risk this
design has to manage is getting the *shape* right once, since every later phase builds inside these folders
and against these contracts — a wrong autoload boundary or a contract signature that changes later touches
every feature built on top of it.

## Goals / Non-Goals

**Goals:**
- Stand up the exact directory topology from `Core_Architecture.md` §6 so every later phase has a home for
  its files from day one.
- Register the six domain autoloads in the fixed init order from §5.1, as empty/stub classes — the *shape*
  of each domain's public surface (fields, signals) exists even though the logic behind it doesn't yet.
- Give `SceneDirector` a real (if minimal) implementation: it is the only thing Phase 1 needs to actually
  *do* something, since a Hub placeholder needs to be reachable at boot and the fade-transition pattern is
  easiest to get right before other code starts depending on `change_scene_*` habits.
- Add `MinigameBase`, `MinigameResult`, `LevelConfig` as real, usable base classes/resources so Phase 3 can
  extend/instantiate them without redesigning their shape.

**Non-Goals:**
- No gameplay, save I/O, progression, or audio logic — those are Phases 2–5.
- No project-settings changes (renderer, stretch mode, input emulation flags) — tracked as a separate
  follow-up change per the proposal's "explicitly out of scope" note.
- No real Hub scene (art, stickers, Caja de Globos) — Phase 1 needs only an empty placeholder scene so
  `SceneDirector` has somewhere to point at boot; the real Hub is Phase 4.
- No GUT test harness setup — `Core_Architecture.md` §7 prioritizes save/progression tests first, which
  don't exist as logic yet; nothing in this change has pure logic worth unit-testing beyond what manual
  Godot-editor verification already covers.

## Decisions

**Autoloads are stub classes with declared public surface, not `push_error`-only placeholders.**
Each of the six autoloads (`SaveManager`, `SettingsManager`, `ProgressionManager`, `AudioManager`,
`MetricsLogger`, `SceneDirector`) gets its own script in the location `Core_Architecture.md` §6.1
specifies, with `class_name`, its documented signals declared (`SettingsManager.low_stim_changed`,
`ProgressionManager.sticker_unlocked`), and its owned fields declared with correct static types and
sensible defaults (e.g. `SettingsManager.low_stim_mode: bool = false`) — but method bodies are empty or
`pass` except where §5.1's init-order needs to be visibly correct. *Alternative considered:* leave
autoloads as bare empty scripts with no declared surface, filled in per-phase. Rejected — Phase 2+ would
then be simultaneously inventing the domain's public shape *and* implementing it, and other autoloads that
reference e.g. `SettingsManager.low_stim_mode` (a cross-cutting concern touched by many later systems)
would have nothing to compile against.

**`SceneDirector` is fully implemented in this phase, not stubbed.**
Unlike the other five autoloads, `SceneDirector` gets real logic now: `goto_hub()` /
`launch_minigame(scene: PackedScene, config: LevelConfig)`-shaped API, the persistent-container/slot
pattern (§1.2), and a fade transition in `shared/ui_elements/transitions/`. *Rationale:* without it there is
no way to reach even a placeholder Hub at boot, and the container/fade pattern is the one piece of Phase 1
that is easy to get subtly wrong (e.g. reaching for `change_scene_to_file` out of habit) if it's deferred
until a feature is already depending on ad hoc scene-swapping.

**Placeholder Hub is a bare empty `Node2D` scene, not a stub of the real Hub.**
`features/hub_main/` gets one minimal scene (no Caja de Globos, no Libro Mágico, no art) so
`SceneDirector.goto_hub()` has a real target to load and the boot path is exercisable end-to-end.
*Alternative considered:* skip the placeholder and leave `SceneDirector` untested until Phase 4 builds the
real Hub. Rejected — that would leave the one piece of Phase 1 with actual behavior (the fade/load pattern)
unverified until three phases later.

**`MinigameBase`/`MinigameResult`/`LevelConfig` are added with no concrete minigame consuming them yet.**
They're written to match `Core_Architecture.md` §1.1/§2A/§2C exactly (signal name, method signatures,
`RefCounted` vs `Resource` base, `MatchRule` enum values). *Risk accepted:* until Phase 3 actually extends
`MinigameBase`, the contract is unverified by real usage — mitigated by keeping the shape a direct, literal
transcription of the doc's code block rather than a reinterpretation.

**Old prototype (`scripts/main.gd`, `scripts/globo.gd`) is deleted, not left in place.**
`CLAUDE.md` already flags it as predating the architecture. *Alternative considered:* leave it untouched
and let it die of neglect once the new boot path lands. Rejected — two competing "how does the game start"
code paths in the same repo is confusing for anyone reading the project fresh, and the prototype's untyped,
flat style directly contradicts the conventions (`Core_Architecture.md` §3) this change is establishing.

## Risks / Trade-offs

- **[Risk]** Declaring autoload public surface (fields/signals) before the logic behind it exists means
  Phase 2+ could discover the shape was wrong once real usage arrives (e.g. `ProgressionManager` needing a
  field not anticipated here). → **Mitigation:** the declared surface is deliberately minimal (only what
  `Core_Architecture.md` explicitly names) and Godot has no compiled/frozen ABI across scripts — widening a
  stub's surface later is a cheap, localized edit, not a breaking migration.
- **[Risk]** Building `SceneDirector` against a placeholder Hub scene risks the container/slot pattern being
  quietly wrong in a way only the real Hub (with actual persistent-audio/state needs) would expose. →
  **Mitigation:** the persistent-container pattern is fully specified in §1.2 (container node survives,
  child is swapped) — the placeholder exercises exactly that mechanism; only Hub *content* changes in
  Phase 4, not the mechanism.
- **[Risk]** Deleting the prototype removes the only currently-running, manually-verified scene in the
  project, so `run_project` shows an empty placeholder instead of the balloon prototype until Phase 3 lands.
  → **Mitigation:** expected and acceptable — this change's own verification is "boots to placeholder Hub
  without errors," not "balloon gameplay still works," and the roadmap already treats Phase 1 as
  non-playable scaffolding.

## Migration Plan

1. Create the directory topology (folders + `.gitkeep` where empty).
2. Add the three shared contracts (`shared/contracts/`) — no dependents yet, safe to add first.
3. Add the six autoload scripts, then register them in `project.godot` in the exact §5.1 order.
4. Build the fade transition scene/script and `SceneDirector`, plus the placeholder Hub scene.
5. Verify boot (`mcp__godot__run_project` + `get_debug_output`): app opens directly to the placeholder Hub
   with no console errors, autoloads present in the declared order.
6. Delete `scripts/main.gd`, `scripts/globo.gd`, and their now-orphaned scene(s); update `project.godot`'s
   main-scene setting to boot through `SceneDirector`/the placeholder Hub.
7. Re-verify boot after deletion.

No rollback beyond standard git revert is needed — nothing in this change touches persisted user data
(`user://save_data.json` doesn't exist yet).

## Open Questions

- Should the placeholder Hub scene live at its final Phase-4 path (`features/hub_main/hub_main.tscn`) now,
  so Phase 4 edits it in place, or at a throwaway path replaced wholesale later? This design assumes the
  former (final path, minimal content) to avoid a churn-only rename in Phase 4.
