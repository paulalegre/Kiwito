## Context

`project-runtime-settings` (`openspec/specs/project-runtime-settings/spec.md`) already locks
`window/stretch/mode="canvas_items"` and `window/stretch/aspect="expand"` in `project.godot`'s
`[display]` section, per `Core_Architecture.md` §0's tablet aspect-ratio handling. What it does not
pin — and what `project.godot` has never set, checked directly — is the base canvas those two settings
actually scale/expand *against*: `window/size/viewport_width` and `window/size/viewport_height`. Absent
those keys, Godot 4 uses its own engine default, **1152×648**, not the **1920×1080** logical canvas
`Core_Architecture.md` §0 and `Direccion_de_Arte.md` (`"Lienzo de diseño: 1920x1080"`) both treat as
settled. `grep` across every `.gd`/`.tscn`/`project.godot` in the repo confirms zero references to
`1920`/`1080` anywhere — this was never wired, not a regression.

Discovered during `wire-hub-main-art-assets` (archived 2026-07-31) while investigating why a
`CoverSprite` background-scaling component needed to query `get_viewport_rect()` live rather than assume
a fixed 1920×1080: the live viewport turned out to already be smaller than documented, for a reason
unrelated to that change's own scope.

## Goals / Non-Goals

**Goals:**
- `project.godot` declares the documented 1920×1080 base canvas explicitly, closing the gap in
  `project-runtime-settings`.
- Confirm the Hub and `mg_balloons` still render sensibly at the corrected scale — catch anything
  concretely broken (off-screen, overlapping, crushed against an edge), not polish everything to a new
  visual standard.

**Non-Goals:**
- Not a Hub or `mg_balloons` layout redesign. Any position edit here is a minimal correction to
  something the corrected canvas revealed as broken, not a fresh composition pass.
- Not touching `shared/components/cover_sprite.gd` or `shared/components/palette_background_rect.gd` —
  both already compute against `get_viewport_rect()` at runtime (see Decisions), so they need no code
  change; they simply start computing against the right numbers.
- Not touching `mg_balloons.gd`'s spawn/goal-box logic unless the spot-check in tasks.md turns up an
  actual problem — it already reads `get_viewport_rect().size` at runtime instead of hardcoding a base
  size (checked directly, `features/minigames/mg_balloons/mg_balloons.gd:47,73-80`).
- Not re-litigating `stretch/mode`/`stretch/aspect` themselves — `project-runtime-settings` already
  settled those; this only adds the missing base-size requirement.

## Decisions

**Fix is a two-line `project.godot` addition, not a code change.** `window/size/viewport_width=1920` and
`window/size/viewport_height=1080` under `[display]`, alongside the existing `window/stretch/*` keys.
This is the standard, documented Godot mechanism for declaring a design-time logical canvas under
`canvas_items` stretch mode — no alternative considered, since the two "existing" settings already
assume this key exists and simply weren't given a value.

**No compensating code changes to the two viewport-aware components added in
`wire-hub-main-art-assets`.** `CoverSprite` (cover/aspect-fill background scaling) and
`PaletteBackgroundRect` (full-viewport solid-color fallback) both call `get_viewport_rect().size` at
`_ready()` and on every `Viewport.size_changed`, rather than assuming a fixed 1920×1080. They were
written this way specifically so they'd be correct under *any* base canvas — this fix validates that
choice rather than requiring rework. Same reasoning applies to `mg_balloons.gd`'s spawn bounds.

**Hub node positions are the one real risk, and get a manual spot-check, not a formula.**
`CajaDeGlobos`/`LibroMagico` in `hub_main.tscn` are hardcoded `Vector2(400, 500)` /
`Vector2(900, 500)` — literal scene data, appropriate for one-off Hub layout (not a `LevelConfig`
gameplay-tunable, so hardcoding here doesn't violate the data-driven-design rule). These were placed by
eye against whatever canvas was live at the time (1152×648), so after the fix they'll occupy a smaller
*fraction* of a now-larger 1920×1080 canvas — mechanically not broken, but possibly reading as too far
left/high, or with awkward empty space. Task 3 calls for a visual check in the running project and a
manual reposition only if it actually looks wrong, the same "let the human eyeball it" approach agreed
on for `wire-hub-main-art-assets`'s visual polish.

## Risks / Trade-offs

- **[Risk] Every prior playtest/screenshot was against the wrong canvas** → **Mitigation:** none needed
  beyond this fix; nothing about the smaller canvas was unsafe (no distortion, no crash), it was
  strictly a "smaller than intended" issue, and MVP hasn't shipped yet.
- **[Risk] Hub node positions look off after the canvas grows** → **Mitigation:** explicit manual
  verification task (not assumed fine, not silently re-derived by formula); see Decisions above.
- **[Trade-off] This change touches `project.godot`, a file every other scene implicitly depends on** →
  accepted; it's the only correct place to fix this, and the two components proven safe under a
  viewport-size change (`CoverSprite`, `PaletteBackgroundRect`) plus `mg_balloons.gd`'s dynamic bounds
  mean the blast radius is smaller than a `project.godot` change might normally imply.
