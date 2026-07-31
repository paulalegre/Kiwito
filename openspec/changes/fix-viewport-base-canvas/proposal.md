## Why

`project.godot`'s `[display]` section sets `window/stretch/mode="canvas_items"` and
`window/stretch/aspect="expand"`, but never sets `window/size/viewport_width` / `viewport_height`.
Without those two keys, Godot 4 falls back to its engine default base canvas of **1152×648** instead of
the **1920×1080** logical viewport `Core_Architecture.md` §0 and `Direccion_de_Arte.md` mandate ("Viewport
lógico: 1920x1080", "Lienzo de diseño: 1920x1080"). Confirmed via `grep` across every `.gd`/`.tscn`/
`project.godot` in the repo: no file anywhere references `1920`/`1080` or sets `viewport_width`/
`viewport_height`.

This went unnoticed because 1152×648 is also exactly 16:9 — `expand` still avoids visible distortion or
letterboxing, so nothing looks broken. It's a silent scale/density bug, not a visual-distortion bug: every
scene authored against the documented 1920×1080 canvas (e.g. `features/hub_main/hub_main.tscn`'s
`CajaDeGlobos` at `(400, 500)` and `LibroMagico` at `(900, 500)`, wired in the just-archived
`wire-hub-main-art-assets`) is actually rendering in a canvas 60% the size assumed, and art delivered at
the project's "1.5× logical size" convention (`Direccion_de_Arte.md` §8) is being displayed smaller than
its own margin was meant to cover.

This corrects a gap in Phase 1, "Fundaciones del Core" (`Propuesta_MVP.md` §8, item 1: "Config de proyecto
(renderer, escalado, input)") — the `project-runtime-settings` capability already locked in the renderer
and input-emulation config that Phase 1 left pinned down late, but its stretch-mode requirement never
pinned the base viewport size the stretch mode actually operates against.

## What Changes

- Add `window/size/viewport_width=1920` and `window/size/viewport_height=1080` to `project.godot`'s
  `[display]` section.
- Visually re-verify (not redesign) the Hub layout (`hub_main.tscn`), whose two node positions are
  hardcoded `Vector2` literals and were therefore tuned by eye against the wrong 1152×648 base. Adjust
  only if something now reads as cramped, overlapping, or off-screen — a verification pass, not a
  redesign.
- `mg_balloons.gd`'s spawn/goal-box logic (checked directly) already computes its bounds from
  `get_viewport_rect().size` at runtime rather than hardcoding 1152/648 or 1920/1080 — it should
  self-adapt to the corrected canvas with no code change needed. Still worth one visual spot-check as
  part of this change's verification pass, but it's not expected to need edits.
- No autoload, script logic, or `MinigameBase`/`LevelConfig` contract changes. `shared/components/
  cover_sprite.gd` and `shared/components/palette_background_rect.gd` (added in `wire-hub-main-art-assets`)
  need no code changes — both already compute against `get_viewport_rect()` at runtime, so they self-correct
  once the base canvas is fixed.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `project-runtime-settings`: its "Stretch mode and aspect remain correct" requirement is extended to also
  require the base viewport size (`window/size/viewport_width`/`viewport_height` = 1920×1080) that
  `stretch/mode`/`stretch/aspect` compute against — previously unstated, silently defaulting to Godot's
  1152×648 engine default.

## Impact

- `project.godot` — add the two `[display]` keys.
- `features/hub_main/hub_main.tscn` — re-verify `CajaDeGlobos`/`LibroMagico` positions against the
  corrected canvas; adjust only if visually broken.
- `features/minigames/mg_balloons/mg_balloons.gd` — spot-check only; its spawn/goal-box bounds are
  already viewport-relative, not hardcoded, so no change is expected.
- No changes to `core/`, `shared/contracts/`, or any autoload's logic.
