## ADDED Requirements

### Requirement: GL Compatibility renderer
The project SHALL use the `GL Compatibility` rendering method in `project.godot`, per
`docs/Core_Architecture.md` §0's foundational decision for low/mid-range tablet GPUs running flat 2D
content.

#### Scenario: project.godot declares GL Compatibility
- **WHEN** `project.godot`'s `[rendering]` section is inspected
- **THEN** the rendering method is `gl_compatibility`, not `mobile` or `forward_plus`, and no
  Windows-specific rendering device driver override (e.g. `d3d12`) is set

#### Scenario: Project boots cleanly under the new renderer
- **WHEN** the project is run after the renderer switch
- **THEN** it boots to the placeholder Hub via `SceneDirector.goto_hub()` with no rendering-related
  console errors, and the six autoloads are present in their declared order

### Requirement: Unified touch/mouse input path
The project SHALL enable `Emulate Touch From Mouse` so a PC mouse and a tablet's touchscreen drive the same
input code path, and SHALL NOT enable `Emulate Mouse From Touch`, per `docs/Core_Architecture.md`'s
input-handling section and this repo's `CLAUDE.md`.

#### Scenario: Emulate Touch From Mouse is enabled
- **WHEN** `project.godot`'s `[input_devices]` section is inspected
- **THEN** `pointing/emulate_touch_from_mouse` is `true`

#### Scenario: Emulate Mouse From Touch stays disabled
- **WHEN** `project.godot`'s `[input_devices]` section is inspected
- **THEN** `pointing/emulate_mouse_from_touch` is absent or `false`, so a touch event never also
  synthesizes a mouse event

### Requirement: Stretch mode and aspect remain correct
The project SHALL keep `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"` in
`project.godot`, matching `docs/Core_Architecture.md` §0's tablet aspect-ratio handling, unchanged by this
or later changes unless a new design decision explicitly revisits them.

#### Scenario: Stretch settings are still canvas_items/expand
- **WHEN** `project.godot`'s `[display]` section is inspected
- **THEN** `window/stretch/mode` is `canvas_items` and `window/stretch/aspect` is `expand`
