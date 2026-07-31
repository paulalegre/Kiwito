## Why

`mg-balloons-cartridge` and `mg-balloons-sensory-polish` (both archived) shipped the balloon minigame's
full gameplay and juice, but `features/minigames/mg_balloons/mg_balloons.tscn` still has no background
node at all — it runs on the engine's default gray, exactly the "gap más grande" that
`design/Assets_Pendientes.md` item 0 called out. Final art (`design/minigames/mg_balloons/balloon_bg.png`,
1920×1080) now exists, produced to the Menta `#CFE7DA` "Cielo/fondo del minijuego de globos" spec fixed by
`Direccion_de_Arte.md` §2.1, after iterating out a visible gradient-banding seam and an accidental
symmetric "sad face" pareidolia from earlier drafts. This unblocks wiring it in, mirroring
`wire-hub-main-art-assets` (archived 2026-07-31), which did the equivalent for the Hub and produced the
`hub-main-visual-presentation` capability. This advances `docs/Propuesta_MVP.md` §8's post-Phase-3
art-integration work into the balloon cartridge, the one remaining scene still missing its background.

This is a scene-wiring change only: no gameplay logic, `MatchRule`/`LevelConfig`, or autoload changes.

## What Changes

- Add a background to `features/minigames/mg_balloons/mg_balloons.tscn`: a `PaletteBackgroundRect` base
  node (`shared/components/palette_background_rect.gd`) tinted from the mint/ambient color role in
  `shared/global_assets/palette.tres`, plus a `Sprite2D` using `cover_sprite.gd`
  (`shared/components/cover_sprite.gd`) displaying `design/minigames/mg_balloons/balloon_bg.png` —
  the exact same two-node pattern `hub_main.tscn` already uses for `hub_bg.png`.
- Position the background behind all gameplay nodes (spawned `Balloon` instances, `GoalBox`) so nothing
  gameplay-relevant is ever occluded.
- Update `design/Assets_Pendientes.md`: check off the "Cielo/fondo de Explotaglobos" line under section 0,
  and correct its suggested filename (`mg_balloons_bg_sky.png`) to the asset's actual delivered filename
  (`balloon_bg.png`, matching the `balloon_` domain prefix already used by every other asset in
  `design/minigames/mg_balloons/`).
- No changes to `mg_balloons.gd`, `balloon.gd`, `goal_box.gd`, `BalloonLevelConfig`, or any autoload —
  spawn logic, match rules, frustration escalation, and juice are all unaffected.

## Capabilities

### New Capabilities
- `mg-balloons-visual-presentation`: the balloon minigame renders final background art instead of the
  engine's default clear color, mirroring `hub-main-visual-presentation`'s contract for the Hub.

### Modified Capabilities
(none — `mg-balloons-cartridge` and `mg-balloons-sensory-polish`'s gameplay/help requirements are
unchanged; this only adds what renders behind them, not behavior)

## Impact

- `features/minigames/mg_balloons/mg_balloons.tscn` — add `PaletteBackgroundRect` + `Sprite2D` background
  nodes, positioned behind `SpawnTimer`/`IdleTimer`/`GoalBox` and all runtime-spawned `Balloon` instances.
- `design/minigames/mg_balloons/balloon_bg.png` — first real use as an `ext_resource`; Godot will generate
  its `.import` file on first editor load (manual/editor step, not scriptable).
- `design/Assets_Pendientes.md` — checklist updated (item 0 checked off, filename corrected).
- No changes to `features/minigames/mg_balloons/*.gd`, `core/`, `shared/contracts/`, or any autoload.
