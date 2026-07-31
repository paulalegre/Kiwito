## Why

`progression-and-hub` (archived 2026-07-22) wired the Hub's tap behavior — Caja de Globos launches
Explotaglobos, Libro Mágico opens the Álbum de Stickers — but both nodes still render as
`PlaceholderCircle` procedural circles, and `hub_main.tscn` has no background at all (it runs on the
engine's default gray). `design/Assets_Pendientes.md` (the art-production checklist derived from
`docs/Direccion_de_Arte.md`) calls this out as item 0 (backgrounds — "el gap más grande") and item 1
(Hub interactive nodes). Final art for all three — `hub_bg.png`, `hub_balloon_box.png`,
`hub_magic_book.png` — now exists in `design/hub_main/`, unblocking this wiring. This advances
`docs/Propuesta_MVP.md` §8's post-Phase-3 art-integration work, replacing placeholder art now that the
Hub↔Minijuego loop (`progression-and-hub`) is functionally complete.

This is a scene-wiring change only: no tap logic, autoload, or data-driven config changes.

## What Changes

- Add a background node to `features/hub_main/hub_main.tscn` using `design/hub_main/hub_bg.png`,
  anchored full-screen behind the two interactive nodes.
- Replace the `PlaceholderCircle` node in `features/hub_main/caja_de_globos.tscn` with a `Sprite2D`
  using `design/hub_main/hub_balloon_box.png`, following the same `ext_resource Texture2D` pattern
  already used in `features/minigames/mg_balloons/balloon.tscn`.
- Replace the `PlaceholderCircle` node in `features/hub_main/libro_magico.tscn` with a `Sprite2D` using
  `design/hub_main/hub_magic_book.png`.
- Preserve existing `HitboxComponent` sizing/behavior in both scenes — this change touches visuals only,
  not `caja_de_globos.gd` / `libro_magico.gd` tap logic.
- Check off the corresponding lines in `design/Assets_Pendientes.md` (item 0's Hub-background line, all
  of item 1) once shipped.
- **Open questions to resolve with the design owner before/while implementing** (see `design.md`):
  delivered asset pixel dimensions appear under the §5.2/§8 production spec, and the delivered shape
  (circular icon-button) deviates from the checklist's literal "box/chest" and "book" silhouette
  language — neither blocks wiring, but both should be confirmed rather than silently accepted.

## Capabilities

### New Capabilities
- `hub-main-visual-presentation`: the Hub's background and its two interactive nodes render final art
  assets (not procedural placeholders), at the sizes/hitbox contract `Direccion_de_Arte.md` §5.2
  mandates for Hub nodes.

### Modified Capabilities
(none — `progression-and-hub`'s tap/launch/album requirements are unchanged; this only changes what
renders, not behavior)

## Impact

- `features/hub_main/hub_main.tscn` — add background node.
- `features/hub_main/caja_de_globos.tscn` — swap `PlaceholderCircle` for `Sprite2D`.
- `features/hub_main/libro_magico.tscn` — swap `PlaceholderCircle` for `Sprite2D`.
- `design/hub_main/*.png` — first real use as `ext_resource`s; Godot will generate their `.import`
  files on first editor load (manual/editor step, not scriptable).
- `design/Assets_Pendientes.md` — checklist updated.
- No changes to `features/hub_main/*.gd`, `core/`, `shared/contracts/`, or any autoload.
