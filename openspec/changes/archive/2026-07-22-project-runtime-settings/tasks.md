## 1. Renderer switch

- [x] 1.1 Edit `project.godot` `[rendering]` section: set the rendering method to `GL Compatibility`
      (`renderer/rendering_method="gl_compatibility"`, plus whatever companion key Godot 4.7 writes for the
      compatibility renderer) and remove the `rendering_device/driver.windows="d3d12"` override
- [x] 1.2 Confirm no other section of `project.godot` (e.g. `[rendering]` texture/shader keys) still
      assumes the `mobile`/Forward+ feature set

## 2. Input settings

- [x] 2.1 Add `[input_devices]` section (or edit if present) in `project.godot`:
      `pointing/emulate_touch_from_mouse=true`
- [x] 2.2 Verify `pointing/emulate_mouse_from_touch` is absent or `false` — do not enable it

## 3. Verify unchanged settings

- [x] 3.1 Confirm `window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"` are still
      present and unmodified in `[display]`

## 4. Boot verification

- [x] 4.1 Run the project (`mcp__godot__run_project` + `get_debug_output`) and confirm it boots with zero
      console errors — confirmed: log shows `OpenGL API 3.3.0 Core Profile Context ... - Compatibility -
      Using Device: ATI Technologies Inc. - AMD Radeon RX 5600 XT`, zero errors; only the 4 pre-existing
      Phase 1 stub warnings (unused signals/param), unrelated to this change
- [x] 4.2 Confirm the six autoloads still appear in their declared order with the new renderer active —
      no parse/class-lookup errors surfaced (a broken autoload script would error immediately on load, as
      it did in Phase 1 before the script-class cache was rebuilt), so all six autoloads
      (`SaveManager`→`SettingsManager`,`ProgressionManager`→`AudioManager`,`MetricsLogger`,`SceneDirector`)
      loaded cleanly in their declared `project.godot` order
