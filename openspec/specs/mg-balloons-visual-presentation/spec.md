# mg-balloons-visual-presentation Specification

## Purpose

The balloon minigame renders final background art instead of the engine's default clear color, at any
tablet aspect ratio, with all color resolved from `shared/global_assets/palette.tres`. Mirrors
`hub-main-visual-presentation`'s contract for the Hub. Introduced by `wire-mg-balloons-background`.

## Requirements

### Requirement: Balloon minigame renders a background art layer
`features/minigames/mg_balloons/mg_balloons.tscn` SHALL render
`design/minigames/mg_balloons/balloon_bg.png` as a background node positioned behind every gameplay node
(spawned `Balloon` instances and `GoalBox`), rather than the engine's default clear color.

#### Scenario: Minigame scene shows background art
- **WHEN** `mg_balloons.tscn` is loaded and rendered
- **THEN** `balloon_bg.png` is visible behind all spawned balloons and the `GoalBox`, with no default-gray
  background visible in the play area

### Requirement: Background covers the full play area across tablet aspect ratios
Per `Core_Architecture.md` §0's `stretch/aspect = expand` strategy and `GDD_MVP.md`'s platform note on
heterogeneous tablet aspect ratios, the background SHALL cover 100% of the revealed viewport at any aspect
ratio, with no default-gray sliver visible at any edge.

#### Scenario: Background fills a non-16:9 viewport with no gray edges
- **WHEN** the viewport is resized to an aspect ratio narrower or wider than the 1920×1080 design canvas
- **THEN** the background still fully covers the revealed play area, with no default-gray strip visible at
  any edge

### Requirement: Background color resolves from palette.tres, never a literal hex
The background's base color layer SHALL be tinted using a `color_id` resolved from
`shared/global_assets/palette.tres`. No script or scene added by this change SHALL contain a hardcoded hex
string or `Color(...)` literal for that color.

#### Scenario: Background base layer is tinted from the palette
- **WHEN** `mg_balloons.tscn`'s background base layer is inspected
- **THEN** its color is read from a `palette.tres` entry via `Palette.get_color()`, with no literal hex or
  `Color(...)` value in the scene or any script added by this change
