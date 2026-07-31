## Context

`TappableIcon` (`shared/ui_elements/pause_menu/tappable_icon.gd`) currently owns an `enum Glyph { NONE,
PAUSE, PLAY, HOME }` and draws each glyph procedurally in `_draw()` (capsules, a rounded triangle, a
rounded-rect house) tinted with `palette.get_color(&"cream_fade")`. `pause_overlay.tscn` sets `glyph = 1/2/3`
per instance. This was the fastest path to a distinguishable pause-menu (`pause-menu-iconography`, already
archived), but `design/Assets_Pendientes.md` §2 already tracks these three icons as pending designer art
under `design/ui/` — `ui_icon_home.png` (Casa/pausa), `ui_icon_continue.png` (Continuar),
`ui_icon_exit.png` (Salir al Hub). None of those three files exist yet in the repo.

## Goals / Non-Goals

**Goals:**
- Replace the `Glyph` enum and its procedural draw methods with a single `@export var glyph_texture:
  Texture2D`, drawn via `draw_texture_rect(glyph_texture, rect, false, glyph_color)`.
- Keep the runtime tint (`cream_fade` from `palette.tres`) so the icon still needs no per-color asset
  variants and stays consistent if the palette ever changes.
- Remove the ambiguity in `Assets_Pendientes.md` §2 between the `ui_icon_home.png` filename (named after
  the `_home_button` code identifier) and its actual pictogram (a pause glyph, not a house).

**Non-Goals:**
- Producing the final PNG files — that is a human designer's deliverable, outside this OpenSpec change.
- Resizing `icon_radius` in `pause_overlay.tscn` to match the checklist's target visible/hitbox sizes
  (140/182 for Home, ~96 for Continuar/Salir) — a separate, already-tracked `Direccion_de_Arte.md` §5.2 gap.
- Any change to tap handling, pause/resume/exit flow, or `PauseOverlay`/`SceneDirector` wiring.

## Decisions

**1. Clean replacement of the enum, not a dual code path.**
Considered keeping `glyph_texture` optional with a fallback to the existing procedural draw when unset
(useful while assets are still pending). Rejected: the project's own precedent for this exact situation —
`features/hub_main/placeholder_circle.gd`, which drew the Hub's placeholder circles before real art
shipped — was fully superseded and left unreferenced once `wire-hub-main-art-assets` landed, not kept as a
runtime-conditional branch inside the same component. A dual-path `TappableIcon` would be exactly the kind
of "no half-finished implementation / no feature flag" case CLAUDE.md warns against. Consequence: this
change's code lands as soon as the tasks are done, but `pause_overlay.tscn` cannot be wired to real
textures — and the pause-menu icons will render nothing — until the three PNGs exist at `design/ui/`. That
is an accepted, explicit blocker (see Risks), not a hidden one.

**2. Asset format: alpha-mask PNG, tinted via `modulate`, not pre-colored.**
`Assets_Pendientes.md`'s general rules already state color must resolve from `palette.tres`, "nunca hex
literal en el asset final si el color se aplica por `modulate` en código." A pre-colored PNG (like
`balloon_bg.png`) would bake `cream_fade`'s current RGB into the file, breaking if the palette changes and
needing re-export by the designer. An alpha-only silhouette (opaque white or greyscale shape on a
transparent background) lets `draw_texture_rect`'s `modulate` parameter reproduce the exact palette color at
draw time — same technique already used for the achromatic pattern overlays in `GoalBox`/`balloon_halo.gd`,
just asset-based instead of procedural.

**3. Sizing: draw at `icon_radius`-derived rect, texture resolution left to the designer's 1.5× margin.**
`Assets_Pendientes.md`'s naming convention already specifies delivery at 1.5× the logical use size for
headroom. `TappableIcon` draws the texture into a `Rect2` sized from `icon_radius` (not from the texture's
native pixel size), so the source PNG's exact resolution doesn't need to match the on-screen size 1:1 —
consistent with how `CoverSprite`/`PaletteBackgroundRect` already decouple asset resolution from on-screen
size elsewhere in the project.

**4. Fix the `Assets_Pendientes.md` §2 naming ambiguity in-place, don't rename the files.**
Renaming `ui_icon_home.png` to something like `ui_icon_pause.png` would be clearer, but the filename is
already tied to the code identifier `_home_button` (matches the project's existing "one asset name per code
role" convention seen elsewhere, e.g. `hub_balloon_box.png` for `CajaDeGlobos`). Renaming buys marginal
clarity at the cost of the button then having a diverging semantic meaning; simpler to add one clarifying
line stating explicitly which pictogram (pause / play / house) each of the three filenames must contain.

## Risks / Trade-offs

- **[Risk]** Once this change's code lands, the pause-menu icons render blank (no glyph) until the
  designer delivers the three PNGs, because the procedural fallback is deliberately removed (Decision 1).
  → **Mitigation:** this is an explicit, tracked state, not a silent regression — `tasks.md` calls out the
  asset-delivery dependency as a blocking precondition for the final wiring task, and `Assets_Pendientes.md`
  §2 remains the single source of truth for what's still outstanding. The base color circle still renders,
  so the buttons remain visible and tappable — only the pictogram is missing, not the affordance itself.
- **[Risk]** A designer reads `ui_icon_home.png` and draws a house pictogram for the pause button, since
  the filename says "home."
  → **Mitigation:** Decision 4 — add the explicit file→pictogram mapping note to `Assets_Pendientes.md` §2
  as part of this change, before any asset request goes out.
- **[Risk]** `draw_texture_rect`'s `modulate` multiplies the source texture's color; if the designer
  delivers a non-white (e.g. mid-grey) silhouette, the resulting tint will be darker than the intended
  `cream_fade`.
  → **Mitigation:** state the "opaque white silhouette on transparent background" requirement explicitly in
  the spec delta and in the `Assets_Pendientes.md` note, not just in this design doc.

## Migration Plan

1. Land the `TappableIcon` code change (enum → `glyph_texture` export) and the `Assets_Pendientes.md`
   clarification — these do not depend on the assets existing.
2. Wire `pause_overlay.tscn` to `res://design/ui/ui_icon_home.png` / `ui_icon_continue.png` /
   `ui_icon_exit.png` and run a visual check — blocked until the designer delivers those three files.
3. Rollback: revert `tappable_icon.gd`/`pause_overlay.tscn` to the procedural-glyph version from
   `2026-07-31-pause-menu-iconography` if the texture approach needs to be abandoned; no data/save impact
   either way.

## Open Questions

None blocking. Exact PNG resolution is the designer's call within the 1.5× margin convention already
documented in `Assets_Pendientes.md`.
