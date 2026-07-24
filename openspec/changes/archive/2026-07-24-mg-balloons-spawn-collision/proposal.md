## Why

Explotaglobos advances the MVP roadmap's Fase 3 cartridge work (Propuesta_MVP.md §8, item 3: "motor de
coincidencia genérico... spawn") — this change is post-MVP-closeout polish on that same spawn behavior,
requested after playtesting revealed two rough edges. Today `_spawn_balloon()` in `mg_balloons.gd` picks an
independent random X for every new balloon with no awareness of already-active balloons, so two balloons can
spawn overlapping/touching. It also spawns each balloon at `viewport_size.y + SPAWN_MARGIN_PX` (80px below
the bottom edge); given the balloon's actual collision half-height (~132px at the scene's current scale),
roughly 50px of the balloon is already inside the visible viewport at the moment it appears, producing a
visible "pop-in" rather than a smooth entrance from off-screen. Neither issue breaks any existing
requirement in `mg-balloons-cartridge` (which only specifies "below the visible camera area" and doesn't
address overlap or full off-screen clearance), so both are new spec-level behavior, not bugs against the
current spec.

## What Changes

- Spawn positioning in `mg_balloons.gd` gains a non-overlap check: a newly spawned balloon's hitbox area
  must not overlap any currently active balloon's hitbox area, honoring the same +30% hitbox-to-sprite
  margin already required by `CLAUDE.md` and `hitbox_component.gd`.
- Define the non-blocking fallback when no non-overlapping spawn position exists on a given spawn tick:
  the spawn is skipped and retried on the next `SpawnTimer` timeout rather than forcing an overlapping
  placement, delaying indefinitely, or erroring — preserving the zero-punishment / never-stall product
  invariant (nothing in the child-facing experience may hitch or block).
- Spawn Y position is tightened so the entire balloon (sprite + oversized hitbox) is fully outside the
  viewport bounds at spawn time, not just the balloon's origin/anchor point — closing the ~50px visible
  pop-in gap.
- No change to `ascent_speed`, `spawn_interval_sec`, color/pattern selection, scoring, or any other
  `BalloonLevelConfig` field — this is purely spawn-position placement logic.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `mg-balloons-cartridge`: the existing requirement "Ascent component drives balloons upward from below the
  camera" is tightened to require the full balloon (sprite + hitbox) to spawn outside the viewport, and a
  new requirement is added: newly spawned balloons must not spatially overlap any active balloon's hitbox
  area, with a defined non-blocking retry-next-tick fallback when no valid position is available.

## Impact

- `features/minigames/mg_balloons/mg_balloons.gd` — `_spawn_balloon()` gains overlap-checking against
  `_active_balloons` and adjusted spawn-Y math.
- `shared/components/ascent_component.gd` / `hitbox_component.gd` — read-only reference for hitbox sizing;
  no contract change expected there (still consumed unmodified per `minigame-contracts`).
- No change to `BalloonLevelConfig`, save data, `MinigameResult`, or any other minigame/autoload — isolated
  to `mg_balloons`'s own spawn logic, consistent with the cartridge's strict-isolation rule.
- Out of scope (explicitly excluded from this change): swapping the hitbox's `RectangleShape2D` for a
  `CapsuleShape2D` — that is pure calibration within the existing +30% contract and does not require a
  spec change; it will be done directly in the editor, separately from this change.
