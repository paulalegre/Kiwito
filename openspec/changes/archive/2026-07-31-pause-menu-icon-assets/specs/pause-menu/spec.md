## MODIFIED Requirements

### Requirement: Pause-menu affordances render a distinct glyph
Each of the three pause-menu affordances (the Home/pause button owned by `SceneDirector`, and the
"Continuar"/"Salir al Hub" buttons on the pause overlay) SHALL render a glyph texture layered on top of its
base color circle — pause, play, and home respectively — via `TappableIcon`'s `glyph_texture` export
(`Texture2D`), tinted at draw time with `palette.tres`'s `cream_fade` entry, so the three affordances are
distinguishable by shape, not only by color or screen position. The source texture SHALL be an opaque
silhouette on a transparent background (no baked color), so the runtime tint reproduces the palette color
exactly.

#### Scenario: Home button shows a pause glyph texture
- **WHEN** the Home button is visible during an active minigame session and its `glyph_texture` is set
- **THEN** it draws that texture on top of its base circle, tinted with `palette.tres`'s `cream_fade` entry

#### Scenario: Continuar shows a play glyph texture
- **WHEN** the pause overlay is visible and the "Continuar" affordance's `glyph_texture` is set
- **THEN** it draws that texture on top of its base circle, tinted with `palette.tres`'s `cream_fade` entry

#### Scenario: Salir al Hub shows a home glyph texture
- **WHEN** the pause overlay is visible and the "Salir al Hub" affordance's `glyph_texture` is set
- **THEN** it draws that texture on top of its base circle, tinted with `palette.tres`'s `cream_fade` entry

#### Scenario: Missing glyph texture leaves the base circle as the only affordance
- **WHEN** an affordance's `glyph_texture` is unset (e.g. before the designer's asset lands)
- **THEN** the base color circle still renders and remains tappable, with no glyph drawn on top and no
  error
