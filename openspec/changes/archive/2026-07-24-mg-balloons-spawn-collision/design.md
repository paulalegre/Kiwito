## Context

`MgBalloons._spawn_balloon()` (features/minigames/mg_balloons/mg_balloons.gd:67-86) currently:
- Picks `position.x` via `randf_range(SPAWN_MARGIN_PX, viewport_size.x - SPAWN_MARGIN_PX)` independent of
  any other active balloon.
- Sets `position.y = viewport_size.y + SPAWN_MARGIN_PX` (80px) — a constant, identical for every spawn.
- Never checks `_active_balloons` before placing the new balloon.

The balloon's hitbox (`balloon.tscn`) is currently a `RectangleShape2D` sized `410.8 x 530.4` on a node
scaled to `0.5`, i.e. an effective world-space footprint of ~205x265px. At the current spawn Y, only 80px of
clearance exists below the viewport edge against a ~132px half-height, so roughly 50px of the balloon is
already inside the visible play area the instant it's created — a visible pop-in rather than an entrance
from off-screen.

All balloons within one session move only along Y (`AscentComponent._physics_process` only decrements
`position.y`) at the same `_config.ascent_speed` (one `BalloonLevelConfig` per session, applied uniformly).
X never changes after spawn. This matters for the overlap design below.

Separately, the user is swapping the hitbox's `RectangleShape2D` for a `CapsuleShape2D` directly in the
editor — out of scope here, but the overlap-check design must not assume a specific `Shape2D` subtype so
that swap doesn't require touching this logic.

## Goals / Non-Goals

**Goals:**
- A newly spawned balloon's exclusion footprint never overlaps any currently active balloon's exclusion
  footprint at the moment of spawn.
- The full balloon (not just its origin point) spawns outside the viewport bounds, closing the pop-in gap.
- The spawn-skip fallback never blocks, delays, or errors the level when no valid spot exists.

**Non-Goals:**
- Continuous collision resolution between balloons after spawn (not needed — see the constant-relative-
  velocity argument below).
- Changing `spawn_interval_sec`, `ascent_speed`, win/color logic, or any `BalloonLevelConfig` field.
- The `CapsuleShape2D` hitbox swap itself (separate, spec-free change).
- Horizontal movement, drift, or steering for balloons.

## Decisions

**Decision: check overlap only at spawn time, not every frame.**
Because every balloon in a session ascends along Y at the same `ascent_speed` and never moves in X, the
relative position between any two already-non-overlapping balloons is constant for the rest of their
lifetime (same speed ⇒ zero relative velocity; fixed X ⇒ no lateral convergence). If two balloons don't
overlap at spawn, they mathematically cannot overlap later. This means a one-time check in
`_spawn_balloon()` is sufficient — no per-frame overlap polling, no physics collision response needed.

**Decision: use a dedicated spawn-clearance size constant, not introspection of the hitbox's `Shape2D`.**
Reading `CollisionShape2D.shape` and branching on `RectangleShape2D` vs `CapsuleShape2D` would couple this
spawn logic to whatever shape the hitbox happens to use today. Instead, add one constant in
`mg_balloons.gd` (e.g. `BALLOON_CLEARANCE_SIZE: Vector2`) representing a conservative bounding box for
spawn-placement purposes only — sized to comfortably contain the hitbox regardless of its concrete shape.
This also decouples this change from the user's in-flight capsule-shape edit: whichever shape lands, this
constant just needs to bound it.

**Decision: rejection sampling with a capped attempt count per spawn tick, skip on exhaustion.**
On `_spawn_timer.timeout`, try up to `MAX_SPAWN_ATTEMPTS` (e.g. 8) random X candidates; for each, build the
candidate's AABB (`Rect2` from `BALLOON_CLEARANCE_SIZE` centered at the candidate position) and reject it if
it intersects any active balloon's current AABB. Accept the first non-intersecting candidate. If all
attempts are rejected, skip spawning this tick entirely — no balloon is created, no error, no state change
— and let the next regular `spawn_interval_sec` timeout try again. This is strictly additive to the existing
timer-driven cadence already in `start()`/`_ready()`; no new timer or retry loop is introduced.

**Decision: tighten spawn Y to `viewport_size.y + BALLOON_CLEARANCE_SIZE.y / 2 + SPAWN_MARGIN_PX`.**
This guarantees the balloon's entire bounding box sits below the viewport's bottom edge at spawn, with the
existing `SPAWN_MARGIN_PX` now acting as genuine extra clearance (travel buffer) rather than the only thing
standing between the balloon and being half-visible.

## Risks / Trade-offs

- [A pathological preset with a very narrow viewport-safe X range and high balloon density could make
  `MAX_SPAWN_ATTEMPTS` insufficient, causing spawns to skip more often than intended] → Mitigation: skip-and-
  retry-next-tick means the timer keeps firing every `spawn_interval_sec` regardless; as the oldest balloons
  ascend out of the clearance band, room reopens automatically. No preset shipped today (`level_match_any`,
  `level_match_color_red`) approaches this density.
- [Rejection sampling could in theory loop unbounded if not capped] → Mitigation: hard cap
  (`MAX_SPAWN_ATTEMPTS`) enforced, matching the zero-punishment / never-stall invariant.
- [Coupling to a specific hitbox `Shape2D`] → Mitigation: dedicated `BALLOON_CLEARANCE_SIZE` constant decouples
  the spawn algorithm from the shape swap happening separately.

## Migration Plan

No persisted data, `MinigameResult`, or `BalloonLevelConfig` schema is touched — this is a pure in-session
behavior change with no save-compatibility concerns. Ship as a normal code change; no rollback steps beyond
reverting the commit are needed.
