## 1. Documentation clarification (unblocked, do first)

- [x] 1.1 In `design/Assets_Pendientes.md` §2 ("UI de pausa — iconos"), rename the Botón Casa checklist
      entry's target file from `ui_icon_home.png` to `ui_icon_pause.png` (it delivers a pause glyph, not a
      house — the old name only matched the `_home_button` code identifier). Also note the alpha-mask
      delivery requirement (opaque white silhouette on transparent background, no baked color) inline for
      all three entries.

## 2. TappableIcon texture support

- [x] 2.1 In `shared/ui_elements/pause_menu/tappable_icon.gd`, remove `enum Glyph` and all procedural
      glyph-drawing methods (`_draw_glyph`, `_draw_pause_glyph`, `_draw_capsule`, `_draw_play_glyph`,
      `_draw_home_glyph`, `_draw_home_roof`, `_draw_home_base`, `_draw_rounded_triangle`,
      `_draw_rounded_rect`) and their `*_RATIO` constants.
- [x] 2.2 Add `@export var glyph_texture: Texture2D` and `const GLYPH_COLOR_ID: StringName = &"cream_fade"`
      (kept from the removed code).
- [x] 2.3 In `_draw()`, after the base-circle `draw_circle` call, if `glyph_texture != null`, compute a
      `Rect2` centered on the icon, sized as the largest square inscribed in the base circle
      (`icon_radius × √2`, see `GLYPH_INSCRIBED_SCALE`) rather than the circumscribing square
      (`icon_radius × 2`), and call
      `draw_texture_rect(glyph_texture, rect, false, palette.get_color(GLYPH_COLOR_ID))`.

## 3. Wire textures into the pause overlay (blocked on designer delivery)

- [x] 3.1 **Blocked**: requires `design/ui/ui_icon_pause.png`, `ui_icon_continue.png`, `ui_icon_exit.png` to
      exist in the repo (see `design/Assets_Pendientes.md` §2). Do not start until at least one file lands.
      Unblocked: the three files landed in `design/ui/` (originally misnamed per content — see rename in
      commit history — and reimported via the Godot editor).
- [x] 3.2 In `shared/ui_elements/pause_menu/pause_overlay.tscn`, replace `glyph = 1/2/3` on
      `HomeButton`/`ContinuarButton`/`SalirButton` with `glyph_texture = ExtResource(...)` pointing at the
      corresponding `res://design/ui/ui_icon_*.png`.

## 4. Verification (blocked on task 3)

- [x] 4.1 Run the project via `mcp__godot__run_project`, check `get_debug_output` for import/resource
      errors on the three new textures. Confirmed clean: no import/parse errors after the editor generated
      `.import` metadata for the three PNGs; only pre-existing, unrelated `MinigameBase.gd` warnings remain.
- [x] 4.2 Visually confirm (manual check, no MCP screenshot tooling available) all three glyphs render at
      the correct tint (`cream_fade`) and scale for both `icon_radius` values in use (40.0 and 48.0).
      Confirmed by user in-editor; required a code fix (see `design.md` Decision 3 update) since the initial
      circumscribing-square rect left the glyphs flush against the circle's rim with no padding.
- [x] 4.3 Confirm no regression to existing `pause-menu` behavior: Home button visibility timing, tap
      handling while `get_tree().paused`, Continuar/Salir al Hub flows. Confirmed by user in-editor.
