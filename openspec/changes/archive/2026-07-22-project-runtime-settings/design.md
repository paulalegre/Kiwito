## Context

`project.godot` was left with its Godot-default rendering config (`renderer/rendering_method="mobile"`,
`rendering_device/driver.windows="d3d12"`) when the archived `core-foundations-phase1` change built the
directory topology, autoloads, `SceneDirector`, and shared contracts. That change explicitly deferred
renderer/input settings as out of scope so the folder/autoload/contract work could land as one reviewable
unit. `docs/Core_Architecture.md` §0 mandates `GL Compatibility` as a foundational, costly-to-revert
decision (low/mid-range tablet GPUs, flat 2D doesn't need the extra feature set of `Forward+`/`Mobile`),
and its input-handling section mandates `Emulate Touch From Mouse` so the same input code path is
exercised on PC (dev/validation) and tablet (target hardware) — see also the "Decisiones fundacionales"
table in `Propuesta_MVP.md` §6.

Stretch mode (`canvas_items`) and aspect (`expand`) were already set correctly in Phase 1; this change
only needs to confirm them, not change them.

## Goals / Non-Goals

**Goals:**
- `project.godot`'s `[rendering]` section uses `GL Compatibility` instead of `mobile`/`d3d12`.
- `[input_devices]` has `Emulate Touch From Mouse` enabled and `Emulate Mouse From Touch` left disabled.
- The project still boots cleanly (`SceneDirector.goto_hub()` → placeholder Hub, six autoloads present,
  zero console errors) after the renderer switch, since a renderer change can surface driver-specific
  boot issues on Windows.

**Non-Goals:**
- No change to `window/stretch/mode`/`aspect` (already correct — verified, not modified).
- No GDScript, no new nodes/components, no actual touch-input consumption code (hitboxes, palm rejection,
  `set_input_as_handled()`) — that lands with the balloon cartridge in Phase 3, which is the first code
  that will exercise this input path.
- No autoload, contract, or scene-topology changes — those are done and out of scope here.

## Decisions

- **Renderer: `GL Compatibility` over keeping `mobile`/`d3d12`.** This is a `docs/Core_Architecture.md` §0
  foundational decision already made in the design docs, not a new architectural choice being litigated
  here — this change just applies it. Alternative (do nothing, keep `mobile`) was rejected because it
  leaves the project permanently diverged from its own normative architecture doc, and `Core_Architecture`
  frames the renderer as "costly to revert" — the earlier this is applied, the less future rendering code
  (particle/shader use in Phase 5 juice, Low-Stim visual effects) has to be re-validated against a renderer
  switch.
- **Enable `Emulate Touch From Mouse`; explicitly do NOT enable `Emulate Mouse From Touch`.** Both flags
  exist in Godot's input settings and are sometimes toggled together by habit. Enabling both would cause a
  touch event to also synthesize a mouse event and vice versa, double-firing hitbox/`input_event` handlers
  documented in `Core_Architecture.md`'s input section. Only the touch-from-mouse direction is needed: it
  lets the same `Area2D.input_event`-based hitbox code path used on tablets also be driven by a PC mouse
  during local validation.
- **Verify, don't touch, stretch/aspect.** Re-deriving already-correct settings risks accidental
  regression for no benefit; this change scopes itself to the two settings that are actually wrong today.

## Risks / Trade-offs

- [Switching to `GL Compatibility` could reveal Windows/D3D12-specific rendering behavior the prototype
  scenes were incidentally relying on] → Mitigation: post-switch boot verification via
  `mcp__godot__run_project` / headless run (same method used to verify Phase 1), checking for console
  errors and that the placeholder Hub still renders.
- [No existing scene currently registers any `_input`/`_unhandled_input` touch handling, so this change is
  effectively unverifiable by playtesting until Phase 3 adds real hitboxes] → Mitigation: verification for
  this change is limited to "project boots with no errors and the flag is set correctly in
  `project.godot`"; end-to-end touch-parity verification is deferred to Phase 3's own tasks, which is
  already a downstream consumer of this change per the proposal's "Impact" section.

## Migration Plan

1. Edit `project.godot`: `[rendering]` renderer key(s) to `GL Compatibility`; add/confirm
   `input_devices/pointing/emulate_touch_from_mouse=true` and confirm
   `input_devices/pointing/emulate_mouse_from_touch` stays unset/`false`.
2. Boot-verify via `mcp__godot__run_project` + `get_debug_output` (or the headless invocation pattern from
   Phase 1's tasks if the MCP tool proves stateless again).
3. No rollback complexity beyond reverting the `project.godot` diff — no data migration, no save-format
   impact.

## Open Questions

None — this is a small, well-scoped settings change with no ambiguity left to resolve.
