## Context

`TappableIcon` (`shared/ui_elements/pause_menu/tappable_icon.gd`) is the shared component behind all three
pause-menu affordances (`PauseOverlay._home_button`, `_continuar_button`, `_salir_button`). Today its
`_draw()` only paints `draw_circle(size / 2.0, icon_radius, palette.get_color(color_id))` — the three
buttons are distinguished only by `color_id` (`warm_grey_tint`, `green_hoja`, `blue_oceano`, set per-instance
in `pause_overlay.tscn`) and by screen position, with no shape/glyph differentiation. This is the same
component used for all three, so the fix belongs in `TappableIcon` itself rather than in three ad hoc
draw routines.

## Goals / Non-Goals

**Goals:**
- Give each of the three existing pause-menu buttons a distinct flat glyph (pause / play / home) drawn on
  top of the existing base circle.
- Keep the change confined to rendering: no change to tap handling, visibility rules, or the
  pause/resume/exit flow already covered by the `pause-menu` spec.
- Stay inside Soft Vector Flat-Art (`Direccion_de_Arte.md` §3): no outlines, no gradients, rounded
  primitives, colors sourced from `palette.tres` only.

**Non-Goals:**
- No new palette entries — the glyph reuses an existing palette color.
- No generalized icon library or asset-based icons (`.svg`/`.png`) for this change; glyphs are drawn with
  `_draw()` primitives, consistent with how `GoalBox` and `Balloon` already draw their non-chromatic
  patterns procedurally.
- No changes to `SceneDirector`, `PauseOverlay` control flow, or the `MinigameBase` contract.

## Decisions

**1. Add the glyph to `TappableIcon` itself, not a new wrapping node.**
`TappableIcon` already owns `_draw()`, sizing, and the hitbox. A separate `GlyphIcon` child node was
considered, but it would duplicate `_draw()`/sizing logic and add a node with no interactive purpose of its
own — composition-over-inheritance (Core_Architecture.md) is about avoiding deep inheritance chains, not
about splitting one component's draw call into two nodes when the extra node carries no independent
behavior. A `@export var glyph: Glyph` enum (`NONE`, `PAUSE`, `PLAY`, `HOME`) with a `match` in `_draw()`
keeps one component owning its own appearance.

**2. Glyph geometry as ratios of `icon_radius`.**
`icon_radius` differs between instances today (40.0 for Home, 48.0 for Continuar/Salir). Following the
existing precedent in `GoalBox` (`PATTERN_EXTENT_RATIO`, `PATTERN_LINE_WIDTH_RATIO`), glyph strokes/shapes
are expressed as ratios of `icon_radius` rather than fixed pixel sizes, so both instance sizes render
proportionally without per-instance tuning.

**3. Glyph color: `palette.get_color(&"cream_fade")`.**
CLAUDE.md forbids literal hex colors in scenes/scripts. `cream_fade` already exists in `palette.tres` and
is the project's established light neutral (used for scene-transition fades and as the "Tinta sobre Crema"
background tone). Using it for the glyph fill needs no new palette key and keeps every color on this
component sourced from `Palette`, unlike the achromatic-pattern precedent in `goal_box.gd`/`balloon_halo.gd`
which hardcodes `Color(1.0, 1.0, 1.0, 0.28)` with a comment justifying the exception. Reusing `cream_fade`
avoids introducing a second, undocumented exception.

**4. Wiring stays declarative in the `.tscn`, not in `pause_overlay.gd`.**
Each `TappableIcon` instance in `pause_overlay.tscn` gets its `glyph` export set directly
(`HomeButton: glyph = PAUSE`, `ContinuarButton: glyph = PLAY`, `SalirButton: glyph = HOME`), the same way
`color_id` is already set per-instance today. `pause_overlay.gd` is not touched — the proposal's "no
behavior change" holds structurally, not just by convention.

## Risks / Trade-offs

- **[Risk]** A literal "house" glyph (roof + base) drawn with hard corners would violate the "no sharp/90°
  angles" rule (`Direccion_de_Arte.md` §3.1).
  → **Mitigation:** build it from two rounded primitives — a rounded-triangle roof and a rounded-rect base
  — the same overlapping-flat-shapes technique already used for character "falso volumen", not a single
  outlined pictogram.
- **[Risk]** `cream_fade` (near-white, high luminance) could read as low-contrast against the base circle
  colors if any of them are also light.
  → **Mitigation:** the three colors in use (`warm_grey_tint`, `green_hoja`, `blue_oceano`) are all
  mid-to-dark tones, and the existing achromatic pattern overlay in `GoalBox` already proves a light
  neutral reads clearly against these same palette colors at even lower opacity (0.28) than the fully
  opaque `cream_fade` used here. Confirm visually via `mcp__godot__run_project` once implemented, since this
  is an aesthetic check, not a measurable one.
- **[Risk]** The `Glyph` enum only names the three glyphs needed today; a future fourth pause-menu button
  would need a new enum member.
  → **Mitigation:** acceptable — this is chrome iconography (a handful of fixed UI affordances), not
  gameplay balance data, so it does not fall under the `LevelConfig`-style "no hardcoded values" rule that
  governs minigame tuning.

## Migration Plan

None. Purely additive rendering change to two files (`tappable_icon.gd`, `pause_overlay.tscn`); no save
data, autoload, or signal contract is touched. Rollback is a plain revert of those two files.

## Open Questions

None blocking — exact glyph proportions (bar width, triangle size, roof/base ratio) are tuned visually
against the running scene during implementation rather than specified numerically here.
