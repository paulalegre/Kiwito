## ADDED Requirements

### Requirement: Pause-menu affordances render a distinct glyph
Each of the three pause-menu affordances (the Home/pause button owned by `SceneDirector`, and the
"Continuar"/"Salir al Hub" buttons on the pause overlay) SHALL render a flat glyph layered on top of its
base color circle — pause, play, and home respectively — via `TappableIcon`'s `glyph` export, so the three
affordances are distinguishable by shape, not only by color or screen position.

#### Scenario: Home button shows a pause glyph
- **WHEN** the Home button is visible during an active minigame session
- **THEN** it draws a pause glyph (two vertical bars) on top of its base circle, colored from
  `palette.tres`'s `cream_fade` entry

#### Scenario: Continuar shows a play glyph
- **WHEN** the pause overlay is visible
- **THEN** the "Continuar" affordance draws a play glyph (a triangle) on top of its base circle, colored
  from `palette.tres`'s `cream_fade` entry

#### Scenario: Salir al Hub shows a home glyph
- **WHEN** the pause overlay is visible
- **THEN** the "Salir al Hub" affordance draws a home glyph (a rounded roof over a rounded base, no sharp
  90° corners) on top of its base circle, colored from `palette.tres`'s `cream_fade` entry
