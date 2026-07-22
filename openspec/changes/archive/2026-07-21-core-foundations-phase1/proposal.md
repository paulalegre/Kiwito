## Why

The project is still the flat, untyped prototype (`scripts/main.gd`, `scripts/globo.gd`) that predates the
cartridge architecture in `docs/Core_Architecture.md` (v3.0): no `core/`/`shared/`/`features/` split, no
autoloads, no `SceneDirector`, and none of the shared contracts (`MinigameBase`, `MinigameResult`,
`LevelConfig`) exist yet. Every later phase in the roadmap — persistence (Phase 2), the balloon cartridge
(Phase 3), progression/Hub (Phase 4) — depends on this skeleton being in place first. This change builds
**Phase 1, "Fundaciones del Core"** (`docs/Propuesta_MVP.md` §8, item 1): the directory topology, the six
domain autoloads registered empty in their fixed init order, `SceneDirector` with its fade transition, and
the three shared contracts. It does not implement any gameplay, persistence, or UI behavior — those are
later phases building on this scaffold.

**Explicitly out of scope for this change:** `docs/Propuesta_MVP.md` §8 groups "Config de proyecto
(renderer, escalado, input)" into Phase 1 alongside the four items above. `project.godot` currently uses
`renderer/rendering_method="mobile"` with the `d3d12` driver, not the `GL Compatibility` renderer mandated
by `Core_Architecture.md` §0, and the `canvas_items`/`expand` stretch settings and touch-emulation input
flags are not yet set either. That project-settings work is independent of the folder/autoload/contract
work here (different files, no code dependency) and is left for a follow-up change so this one stays
reviewable as a single unit.

## What Changes

- Create the target directory topology under `res://` per `Core_Architecture.md` §6: `core/autoloads/`,
  `core/data/`, `core/utils/`, `shared/contracts/`, `shared/components/`, `shared/ui_elements/`,
  `shared/global_assets/`, `features/hub_main/`, `features/minigames/mg_balloons/` (with its
  `assets/`/`components/`/`resources/` subfolders). Folders with no content yet get a `.gitkeep` so the
  structure is visible in git.
- Register six autoloads in `project.godot`, in the fixed dependency order from §5.1: `SaveManager` →
  `SettingsManager`, `ProgressionManager` → `AudioManager`, `MetricsLogger`, `SceneDirector`. Each is an
  empty stub (domain-owning class shape, no logic yet) living in `core/autoloads/` (`SaveManager.gd` in
  `core/data/` per §6.1). No autoload touches another in `_init()`.
- Implement `SceneDirector.gd` as the sole scene-change authority: Hub↔minigame transitions instantiate the
  target as a child under a persistent container (never `get_tree().change_scene_*` on the whole tree) and
  are covered by a fade transition (`shared/ui_elements/transitions/`) that hides load time.
- Add the three shared contracts in `shared/contracts/`: `MinigameBase.gd` (thin `Node2D` base — the one
  sanctioned inheritance point — exposing `start(config)`, `pause()`, `resume()`, `stop()`, and the
  `session_finished(result)` signal), `MinigameResult.gd` (`RefCounted`: `correct_pops`, `failed_taps`,
  `duration`, `errors_by_color`), and `LevelConfig.gd` (`Resource` base carrying the `MatchRule` enum:
  `MATCH_ANY`, `MATCH_COLOR`, with `MATCH_SHAPE`/`MATCH_SIZE`/`MATCH_COUNT` reserved for Phase 2+).
- Remove the flat `scripts/main.gd` / `scripts/globo.gd` prototype and its scene once the equivalent
  boot path exists under the new topology (empty Hub placeholder scene loaded via `SceneDirector`), so the
  repo does not carry two competing architectures side by side.

## Capabilities

### New Capabilities
- `project-directory-topology`: the `core/`/`shared`/`features/` folder structure and placement rules
  (what kind of code/asset goes where, `mg_balloons` isolation) that all later phases build inside.
- `autoload-bootstrap`: the six domain autoloads existing, registered in the fixed init order, each owning
  exactly one domain with no cross-autoload access during `_init()`.
- `scene-director`: `SceneDirector` as the only code path allowed to change scenes, the persistent-container
  load pattern, and the fade transition that covers load time.
- `minigame-contracts`: the `MinigameBase`/`MinigameResult`/`LevelConfig` shared vocabulary — the cartridge
  contract shape and isolation rule (a cartridge never references the Host or another minigame).

### Modified Capabilities
(none — no existing specs yet; this is the first change in the project)

## Impact

- **Affected code:** `project.godot` (autoload registration); new `core/`, `shared/`, `features/` trees;
  removal of `scripts/main.gd`, `scripts/globo.gd`, and their scene(s) under `scenes/`.
- **Product/UX invariants:** not touched. This change ships no player-facing behavior — zero text, zero
  punishment, and Low-Stim are not yet exercised by any code added here (Low-Stim lands with
  `SettingsManager`'s real implementation in a later phase; this change only registers the empty stub).
- **Fixed color/pattern table:** not touched — no visual/gameplay assets are added in this change.
- **Dependencies:** none added; pure GDScript/Godot project structure.
- **Downstream:** unblocks Phase 2 (`SaveManager` I/O + `SettingsManager` Low-Stim + GUT tests), which is the
  next roadmap phase and depends on the autoload slots and directory topology created here.
