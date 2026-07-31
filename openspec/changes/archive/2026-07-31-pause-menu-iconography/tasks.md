## 1. TappableIcon glyph support

- [x] 1.1 Add `enum Glyph { NONE, PAUSE, PLAY, HOME }` and `@export var glyph: Glyph = Glyph.NONE` to
      `shared/ui_elements/pause_menu/tappable_icon.gd`.
- [x] 1.2 In `_draw()`, after the existing base-circle `draw_circle` call, branch on `glyph` and draw the
      corresponding shape using `palette.get_color(&"cream_fade")`, with geometry expressed as ratios of
      `icon_radius` (following `GoalBox`'s `PATTERN_EXTENT_RATIO`/`PATTERN_LINE_WIDTH_RATIO` precedent).
- [x] 1.3 Implement the pause glyph: two rounded vertical bars centered on the icon.
- [x] 1.4 Implement the play glyph: a rounded-corner triangle pointing right, centered on the icon.
- [x] 1.5 Implement the home glyph: a rounded-triangle roof over a rounded-rect base, no sharp 90° corners,
      built from overlapping flat primitives per `Direccion_de_Arte.md` §3.2.

## 2. Wire glyphs into the pause overlay

- [x] 2.1 In `shared/ui_elements/pause_menu/pause_overlay.tscn`, set `glyph = 1` (PAUSE) on `HomeButton`.
- [x] 2.2 Set `glyph = 2` (PLAY) on `ContinuarButton`.
- [x] 2.3 Set `glyph = 3` (HOME) on `SalirButton`.

## 3. Verification

- [x] 3.1 Run the project via `mcp__godot__run_project`, launch a minigame session, and visually confirm all
      three glyphs render correctly, at the right scale for both `icon_radius` values (40.0 and 48.0), with
      no outlines/gradients/sharp corners and sufficient contrast against `warm_grey_tint`, `green_hoja`,
      and `blue_oceano`. (Ran without errors via `mcp__godot__run_project`; final visual confirmation given
      by the user directly, since the available Godot MCP tools have no screenshot capability.)
- [x] 3.2 Confirm no regression to existing `pause-menu` behavior: Home button visibility timing, tap
      handling while `get_tree().paused`, Continuar/Salir al Hub flows.
