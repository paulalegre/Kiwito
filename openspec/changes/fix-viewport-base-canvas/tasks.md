## 1. Fix the base viewport config

- [ ] 1.1 Add `window/size/viewport_width=1920` and `window/size/viewport_height=1080` to
      `project.godot`'s `[display]` section, alongside the existing `window/stretch/mode`/
      `window/stretch/aspect` keys.
- [ ] 1.2 Run the project (`mcp__godot__run_project` + `get_debug_output`) and confirm it boots to the
      Hub with no new errors.

## 2. Verify the Hub layout against the corrected canvas

- [ ] 2.1 With the project running, visually inspect `hub_main.tscn`: is `CajaDeGlobos` (currently
      `Vector2(400, 500)`) and `LibroMagico` (currently `Vector2(900, 500)`) still readable as a sane
      two-node layout at the new 1920×1080 scale, or does it now read as cramped to one side / oddly
      spaced?
- [ ] 2.2 If — and only if — 2.1 finds something concretely off, reposition the affected node(s)
      manually in the Godot editor (per the "user does the visual fine-tuning" workflow agreed in
      `wire-hub-main-art-assets`) rather than computing new coordinates from a formula.
- [ ] 2.3 Confirm `BackgroundBase` (`PaletteBackgroundRect`) and `Background` (`CoverSprite`,
      `hub_bg.png`) still fully cover the viewport with no gray/seam visible — expected to need zero
      changes since both already compute against `get_viewport_rect()` live, but confirm rather than
      assume.

## 3. Spot-check mg_balloons

- [ ] 3.1 Launch Explotaglobos from the Hub and confirm balloons still spawn across a sane horizontal
      band and the goal box still sits in its intended corner — `mg_balloons.gd`'s spawn/goal-box logic
      already reads `get_viewport_rect().size` at runtime (not a hardcoded base size), so this is
      expected to need no changes; this task exists to confirm that expectation, not to redo the spawn
      logic.

## 4. Close out

- [ ] 4.1 Confirm no other `.gd`/`.tscn` in the repo has a hardcoded position/bound that assumed the old
      1152×648 default (re-run the `grep -rn "1152\|648"` sweep across `.gd`/`.tscn` to be sure nothing
      was missed).
- [ ] 4.2 `openspec validate fix-viewport-base-canvas --strict` passes.
