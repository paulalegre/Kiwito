## 1. Spawn placement implementation

- [x] 1.1 Add `BALLOON_CLEARANCE_SIZE: Vector2` and `MAX_SPAWN_ATTEMPTS: int` constants to
      `mg_balloons.gd`, sized to conservatively bound the balloon's hitbox regardless of its concrete
      `Shape2D` (per design.md — do not introspect `CollisionShape2D.shape`).
- [x] 1.2 Extract a stateless overlap-check helper (e.g. `shared/utils/spawn_placement.gd`, static methods
      only, no dependency on `mg_balloons.gd` or any node) that takes a candidate `Rect2` and an
      `Array[Rect2]` of active footprints and returns whether the candidate is clear of all of them.
- [x] 1.3 Rewrite `_spawn_balloon()` to build the list of active balloons' current bounding `Rect2`s (from
      `_active_balloons`, using `BALLOON_CLEARANCE_SIZE` centered at each balloon's position), then try up
      to `MAX_SPAWN_ATTEMPTS` random X candidates via the helper from 1.2, accepting the first clear one.
- [x] 1.4 If no candidate is accepted within the attempt cap, return from `_spawn_balloon()` without
      instantiating a balloon, without touching `_active_balloons`, and without emitting any warning/error
      — the next `spawn_interval_sec` timeout tries again unaffected.
- [x] 1.5 Update the spawn Y calculation to `viewport_size.y + BALLOON_CLEARANCE_SIZE.y / 2 +
      SPAWN_MARGIN_PX` so the full balloon footprint clears the viewport at spawn.

## 2. Automated tests (GUT)

- [x] 2.1 Test: the overlap helper returns not-clear for a candidate `Rect2` intersecting an active
      footprint.
- [x] 2.2 Test: the overlap helper returns clear for a candidate `Rect2` that does not intersect any active
      footprint.
- [x] 2.3 Test: the overlap helper returns clear when the active-footprints array is empty (first spawn of
      a session).
- [x] 2.4 Test: given active footprints that saturate the entire valid X range, the helper rejects every
      candidate up to the attempt cap (drives the skip-fallback path exercised in task 3).

## 3. Manual in-editor verification

- [x] 3.1 Run the project via `mcp__godot__run_project`, start Explotaglobos with a short
      `spawn_interval_sec` preset, and visually confirm balloons never appear overlapping and never show a
      partial pop-in at the bottom edge.
- [x] 3.2 Check `mcp__godot__get_debug_output` for any unexpected warning/error during a multi-minute play
      session (confirms the skip-fallback path, if triggered, stays silent).
- [x] 3.3 Confirm existing tap/scoring behavior (`MATCH_ANY` and `MATCH_COLOR` presets) is unaffected —
      no regression to `session_finished`/`MinigameResult` reporting.
- [x] 3.4 Stop the project via `mcp__godot__stop_project` once verified.

## 4. Spec validation

- [x] 4.1 Run `npx --yes @fission-ai/openspec@1.6.0 validate mg-balloons-spawn-collision --strict` and
      resolve any errors before archiving.
