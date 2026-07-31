## 1. Documentation clarification (unblocked, do first)

- [ ] 1.1 In `design/Assets_Pendientes.md` §2 ("UI de pausa — iconos"), add a note next to the three
      checklist entries stating the file→pictogram mapping explicitly: `ui_icon_home.png` = pause glyph
      (named after the `_home_button` code identifier, not a house), `ui_icon_continue.png` = play glyph,
      `ui_icon_exit.png` = house glyph. Also note the alpha-mask delivery requirement (opaque white
      silhouette on transparent background, no baked color) inline.

## 2. TappableIcon texture support

- [ ] 2.1 In `shared/ui_elements/pause_menu/tappable_icon.gd`, remove `enum Glyph` and all procedural
      glyph-drawing methods (`_draw_glyph`, `_draw_pause_glyph`, `_draw_capsule`, `_draw_play_glyph`,
      `_draw_home_glyph`, `_draw_home_roof`, `_draw_home_base`, `_draw_rounded_triangle`,
      `_draw_rounded_rect`) and their `*_RATIO` constants.
- [ ] 2.2 Add `@export var glyph_texture: Texture2D` and `const GLYPH_COLOR_ID: StringName = &"cream_fade"`
      (kept from the removed code).
- [ ] 2.3 In `_draw()`, after the base-circle `draw_circle` call, if `glyph_texture != null`, compute a
      `Rect2` centered on the icon sized from `icon_radius` and call
      `draw_texture_rect(glyph_texture, rect, false, palette.get_color(GLYPH_COLOR_ID))`.

## 3. Wire textures into the pause overlay (blocked on designer delivery)

- [ ] 3.1 **Blocked**: requires `design/ui/ui_icon_home.png`, `ui_icon_continue.png`, `ui_icon_exit.png` to
      exist in the repo (see `design/Assets_Pendientes.md` §2). Do not start until at least one file lands.
- [ ] 3.2 In `shared/ui_elements/pause_menu/pause_overlay.tscn`, replace `glyph = 1/2/3` on
      `HomeButton`/`ContinuarButton`/`SalirButton` with `glyph_texture = ExtResource(...)` pointing at the
      corresponding `res://design/ui/ui_icon_*.png`.

## 4. Verification (blocked on task 3)

- [ ] 4.1 Run the project via `mcp__godot__run_project`, check `get_debug_output` for import/resource
      errors on the three new textures.
- [ ] 4.2 Visually confirm (manual check, no MCP screenshot tooling available) all three glyphs render at
      the correct tint (`cream_fade`) and scale for both `icon_radius` values in use (40.0 and 48.0).
- [ ] 4.3 Confirm no regression to existing `pause-menu` behavior: Home button visibility timing, tap
      handling while `get_tree().paused`, Continuar/Salir al Hub flows.
