## MODIFIED Requirements

### Requirement: Stretch mode and aspect remain correct
The project SHALL keep `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"` in
`project.godot`, matching `docs/Core_Architecture.md` §0's tablet aspect-ratio handling, unchanged by this
or later changes unless a new design decision explicitly revisits them. The project SHALL also declare an
explicit base logical canvas of `window/size/viewport_width=1920` and `window/size/viewport_height=1080`
in the same `[display]` section, matching the `1920x1080` logical canvas `docs/Core_Architecture.md` §0
and `docs/Direccion_de_Arte.md` both specify — `stretch/mode`/`stretch/aspect` alone do not define this
canvas size, and without it Godot silently falls back to its own engine default (`1152x648`) instead.

#### Scenario: Stretch settings are still canvas_items/expand
- **WHEN** `project.godot`'s `[display]` section is inspected
- **THEN** `window/stretch/mode` is `canvas_items` and `window/stretch/aspect` is `expand`

#### Scenario: Base viewport size matches the documented logical canvas
- **WHEN** `project.godot`'s `[display]` section is inspected
- **THEN** `window/size/viewport_width` is `1920` and `window/size/viewport_height` is `1080`
