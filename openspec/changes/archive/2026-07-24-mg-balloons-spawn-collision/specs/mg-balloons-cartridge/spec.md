## MODIFIED Requirements

### Requirement: Ascent component drives balloons upward from below the camera
`shared/components/ascent_component.gd` SHALL move its parent balloon upward along the Y axis at a
configurable speed, with no dependency on a specific parent scene. The spawning cartridge SHALL position
each balloon at spawn time so that its full bounding footprint (sprite and hitbox, not just its origin
point) lies entirely outside the visible viewport bounds — no part of a balloon SHALL be visible at the
moment it is spawned.

#### Scenario: Balloon ascends over time
- **WHEN** a balloon with the ascent component is spawned below the camera
- **THEN** its Y position decreases (moves upward) over subsequent frames at the configured
  `ascent_speed`

#### Scenario: No part of a balloon is visible at spawn
- **WHEN** a balloon is spawned
- **THEN** its entire bounding footprint (sprite and hitbox) lies outside the viewport's visible bounds at
  that instant

## ADDED Requirements

### Requirement: Newly spawned balloons do not spatially overlap active balloons
When placing a new balloon, the cartridge SHALL reject candidate spawn positions whose bounding footprint
intersects any currently active balloon's bounding footprint, honoring the same +30% hitbox-to-sprite
clearance already required of `hitbox_component.gd`. If no non-overlapping candidate position is found
within a bounded number of attempts on a given spawn tick, the cartridge SHALL skip spawning a balloon that
tick — without crashing, blocking, delaying the next scheduled spawn tick, or emitting an error — and
attempt again on the next `spawn_interval_sec` timeout.

#### Scenario: Candidate position overlapping an active balloon is rejected
- **WHEN** a spawn tick's first candidate X position would place the new balloon's bounding footprint
  overlapping an already-active balloon's current bounding footprint
- **THEN** that candidate is rejected and a different candidate position is tried instead

#### Scenario: Non-overlapping candidate is accepted
- **WHEN** a spawn tick finds a candidate X position whose bounding footprint does not intersect any active
  balloon's current bounding footprint
- **THEN** the new balloon is spawned at that position

#### Scenario: Spawn is skipped without side effects when no valid position exists
- **WHEN** every candidate position tried on a spawn tick would overlap an active balloon
- **THEN** no balloon is spawned that tick, no error is raised, gameplay continues unaffected, and the
  cartridge attempts to spawn again on the next `spawn_interval_sec` timeout
