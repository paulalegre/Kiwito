## Why

`docs/Propuesta_MVP.md` §8 groups "Config de proyecto (renderer, escalado, input)" into Phase 1
("Fundaciones del Core") alongside the directory topology, autoloads, `SceneDirector`, and shared
contracts. The archived change `core-foundations-phase1` deliberately left this piece out of scope (see
its `proposal.md` "Why" section) so the folder/autoload/contract work could land as one reviewable unit.
`project.godot` still uses `renderer/rendering_method="mobile"` with the `d3d12` Windows driver, and no
touch-emulation input flag is set, instead of the `GL Compatibility` renderer and `Emulate Touch From
Mouse` input path mandated by `docs/Core_Architecture.md` §0 and its input-handling section. This is the
last unclosed piece of Phase 1's roadmap item; every later phase's on-tablet touch behavior (hitboxes,
palm rejection, PC/tablet input parity) assumes it's already in place, so it should close before Phase 3
(the balloon cartridge) starts wiring real touch input.

## What Changes

- Switch `[rendering]` in `project.godot` from `renderer/rendering_method="mobile"` (`d3d12` driver) to
  the `GL Compatibility` renderer, per the "Decisiones fundacionales" table in `Propuesta_MVP.md` §6
  ("Tablets de gama baja/media; 2D plano no necesita más").
- Enable `Emulate Touch From Mouse` in `[input_devices]` so PC (mouse) and tablet (touch) share one input
  code path, per `Core_Architecture.md`'s input-handling section and this repo's `CLAUDE.md`. Do **not**
  enable `Emulate Mouse From Touch` — the two together double-fire input events.
- Verify `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"` (already set from Phase
  1) still match `Core_Architecture.md` §0; no change expected, just confirmation.
- No GDScript, no new scenes, no gameplay behavior.

## Capabilities

### New Capabilities
- `project-runtime-settings`: the project-level engine configuration contract (renderer, stretch/aspect,
  touch-emulation input) that every visual/input-handling capability built on top of this project depends
  on holding true — distinct from `project-directory-topology` (which governs the folder structure, not
  engine settings).

### Modified Capabilities
(none — the four existing specs from Phase 1 govern folder structure, autoloads, scene transitions, and
minigame contracts; none of them assert renderer/input engine settings today)

## Impact

- **Affected code:** `project.godot` only (`[rendering]` and `[input_devices]` sections). No scripts, no
  scenes, no autoloads touched.
- **Product/UX invariants:** touches the input-handling invariant indirectly — `Emulate Touch From Mouse`
  is what lets the palm-rejection (`event.index == 0`) and 30%-larger-hitbox rules (already documented,
  not yet exercised by any code) work identically on PC and tablet. Zero text, zero punishment, and
  Low-Stim are not touched.
- **Fixed color/pattern table:** not touched.
- **Dependencies:** none added.
- **Downstream:** unblocks Phase 3 (the balloon cartridge's real touch input, hitboxes, and palm
  rejection), which needs the input path this change establishes to be meaningful on both PC and tablet.
