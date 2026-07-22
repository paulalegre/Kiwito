## ADDED Requirements

### Requirement: palette.tres declares all 4 MATCH_COLOR colors with an assigned pattern
`shared/global_assets/palette.tres` SHALL declare exactly the 4 `MATCH_COLOR` colors fixed by
`Direccion_de_Arte.md` §2.2 (`yellow_sol` `#F2C14E`, `green_hoja` `#5FB65A`, `red_coral` `#E2574C`,
`blue_oceano` `#245C9E`), each with a non-empty `pattern_id` (`stars`, `stripes`, `dots`, `zigzag`
respectively). No script or scene in this change SHALL contain a literal hex or `Color(...)` value for
any of these 4 colors — they SHALL be read from `palette.tres`.

#### Scenario: Every game color has a pattern_id
- **WHEN** `palette.tres` is inspected
- **THEN** all 4 `MATCH_COLOR` entries are present and each has a non-empty `pattern_id`

#### Scenario: No literal hex in mg_balloons scripts or scenes
- **WHEN** the scripts and scenes added under `features/minigames/mg_balloons/` and
  `shared/components/` are inspected
- **THEN** none contain a hardcoded hex string or `Color(...)` literal for any of the 4 game colors

### Requirement: Cartridge isolation and MinigameBase compliance
The balloon minigame SHALL live entirely under `features/minigames/mg_balloons/`, extend `MinigameBase`
exactly one level deep, and satisfy `minigame-contracts` unmodified: implementing `start(config)`,
inheriting default `pause()`/`resume()`/`stop()`, and emitting `session_finished(result)` instead of any
direct reference to a Host or another minigame.

#### Scenario: No external references from the cartridge
- **WHEN** the balloon cartridge's scripts are inspected
- **THEN** none reference a Host node, another minigame's class, or a node path outside its own scene
  subtree

### Requirement: start(config) spawns balloons per a BalloonLevelConfig
A `BalloonLevelConfig` subclass of `LevelConfig` SHALL add `target_color_id: StringName`,
`win_count: int`, `spawn_interval_sec: float`, and `ascent_speed: float`, all consumed by
`start(config: LevelConfig)` with no hardcoded fallback values in the cartridge script for any of them.

#### Scenario: Spawn rate and speed come from config, not code
- **WHEN** `start()` is called with two different `BalloonLevelConfig` instances with different
  `spawn_interval_sec`/`ascent_speed` values
- **THEN** the observed spawn cadence and ascent speed differ accordingly, with no code change required

### Requirement: Two presets prove the engine needs no new code per rule
`features/minigames/mg_balloons/resources/` SHALL include at least one `MATCH_ANY` preset and one
`MATCH_COLOR` preset (targeting `red_coral`, the color with a complete asset set), both usable by the same
unmodified cartridge script.

#### Scenario: MATCH_ANY preset accepts any balloon tap as correct
- **WHEN** the cartridge is started with the `MATCH_ANY` preset
- **THEN** a tap on any balloon, regardless of color, counts as a correct pop

#### Scenario: MATCH_COLOR preset only accepts the target color
- **WHEN** the cartridge is started with the `MATCH_COLOR` preset targeting `red_coral`
- **THEN** a tap on a `red_coral` balloon counts as a correct pop and a tap on any other color does not

### Requirement: Hitbox component rejects secondary touches and consumes the event
`shared/components/hitbox_component.gd` SHALL expose an `Area2D`-based hitbox sized at least 30% larger
than its associated visible sprite, filter out any input event where `event.index != 0`, and call
`get_viewport().set_input_as_handled()` when it handles a tap, per `CLAUDE.md`'s input rules. It SHALL have
no dependency on being a child of any specific parent scene.

#### Scenario: Hitbox is oversized relative to the sprite
- **WHEN** a balloon's hitbox and visible sprite bounds are compared
- **THEN** the hitbox area is at least 30% larger than the sprite's

#### Scenario: Secondary touch is ignored
- **WHEN** an input event arrives with `event.index != 0`
- **THEN** the hitbox component does not treat it as a valid tap

#### Scenario: A handled tap consumes the input event
- **WHEN** a primary-touch tap lands inside the hitbox
- **THEN** the component calls `get_viewport().set_input_as_handled()` so overlapping hitboxes do not
  double-fire

### Requirement: Ascent component drives balloons upward from below the camera
`shared/components/ascent_component.gd` SHALL move its parent balloon upward along the Y axis at a
configurable speed, starting from a spawn position below the visible camera area, with no dependency on a
specific parent scene.

#### Scenario: Balloon ascends over time
- **WHEN** a balloon with the ascent component is spawned below the camera
- **THEN** its Y position decreases (moves upward) over subsequent frames at the configured
  `ascent_speed`

### Requirement: Juice component gives sub-100ms feedback on a valid touch
`shared/components/juice_component.gd` SHALL trigger a visible scale/bounce response within 100ms of a
valid touch being registered, with no dependency on a specific parent scene.

#### Scenario: Feedback starts within budget
- **WHEN** a valid tap is registered on a balloon
- **THEN** the juice component's visual feedback begins in under 100ms

### Requirement: Zero-punishment resolution of incorrect taps
Tapping a balloon that does not satisfy the active `MatchRule` SHALL NOT end, restart, or penalize the
level. It SHALL produce neutral feedback only (a shake animation and a distinct, non-success sound cue)
and the level SHALL continue toward its win condition unaffected.

#### Scenario: Incorrect tap does not end the level
- **WHEN** a balloon is tapped that does not match the active rule
- **THEN** the balloon shakes, a neutral sound plays, the balloon is not removed for having "failed", and
  the level's progress toward `win_count` correct pops is unchanged

### Requirement: Session ends and reports a populated MinigameResult
When `win_count` correct pops are reached, the cartridge SHALL stop spawning, clear remaining balloons, and
emit `session_finished(result: MinigameResult)` with `correct_pops`, `failed_taps`, `duration`, and
`errors_by_color` (keyed by `color_id: StringName`, counting incorrect taps per color) all populated from
the session that just ran.

#### Scenario: Win condition triggers session_finished with correct counts
- **WHEN** the child correctly pops `win_count` balloons, having also mis-tapped 2 balloons of
  `blue_oceano` along the way
- **THEN** `session_finished` fires with `correct_pops == win_count`, `failed_taps == 2`, and
  `errors_by_color[&"blue_oceano"] == 2`
