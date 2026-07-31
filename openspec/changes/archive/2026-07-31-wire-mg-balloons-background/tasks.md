## 1. Add the palette entry

- [x] 1.1 Add `&"mint_ambiente": Color(0.811765, 0.905882, 0.854902, 1)` (`#CFE7DA`) to the `colors`
      dictionary in `shared/global_assets/palette.tres`, alongside the existing entries — additive only,
      no existing key touched.

## 2. Import the asset in the Godot editor

- [x] 2.1 Open the project in the Godot editor (`mcp__godot__launch_editor`) so
      `design/minigames/mg_balloons/balloon_bg.png` gets a generated `.import` file. — Done; generated
      `uid://cn00xegg84g7w`.
- [x] 2.2 Set import compression per `Direccion_de_Arte.md` §8 (`compress/mode=2`, VRAM Compressed — it's
      the "sprite grande" full-background case, matching how `hub_bg.png` was set in
      `wire-hub-main-art-assets`); confirm mipmaps stay off. — `compress/mode` set to `2` directly in
      `balloon_bg.png.import`; `mipmaps/generate` was already `false` by default.

## 3. Wire the background into mg_balloons.tscn

- [x] 3.1 Add a `Node2D` named `BackgroundBase` as the first child of `MgBalloons`, running
      `shared/components/palette_background_rect.gd` (`PaletteBackgroundRect`) with `palette` set to
      `shared/global_assets/palette.tres` and `color_id = &"mint_ambiente"`.
- [x] 3.2 Add a `Sprite2D` named `Background` as the next sibling (still before `SpawnTimer`, `IdleTimer`,
      `GoalBox`), referencing `design/minigames/mg_balloons/balloon_bg.png`, with
      `shared/components/cover_sprite.gd` (`CoverSprite`) attached so it scales in cover/aspect-fill mode
      across tablet aspect ratios — identical pattern to `hub_main.tscn`'s `Background` node.
- [x] 3.3 Verify both new nodes sit before `GoalBox` in the scene tree so runtime-spawned `Balloon`
      instances (appended via `add_child()` in `mg_balloons.gd`) and `GoalBox` draw on top of the
      background without needing any explicit z-index. — Confirmed by construction: `BackgroundBase` and
      `Background` are the first two children in `mg_balloons.tscn`, before `SpawnTimer`/`IdleTimer`/
      `GoalBox`.

## 4. Verify

- [x] 4.1 Run the project via `mcp__godot__run_project`, launch the balloon minigame from the Hub, and
      check `mcp__godot__get_debug_output` for zero errors (no missing-resource or script-compile errors
      for the new texture, script, or palette entry). — Done; only pre-existing, unrelated warnings
      (`MinigameBase` unused-signal/param, `AudioManager` missing `help_level_1` VO — documented as
      intentional in `AudioManager.gd`). No new errors.
- [x] 4.2 Ask the user to eyeball the running window: background visible behind balloons and the goal box,
      no default-gray visible anywhere in the play area — no screenshot tool is available via the
      `mcp__godot__*` MCP surface to confirm this independently. — **Confirmed by user.**
- [x] 4.3 Confirm gameplay is unaffected: balloons still spawn, ascend, and register correct/incorrect taps
      normally; a full session still reaches `session_finished` and returns to the Hub. — **Confirmed by
      user**, manual taps on correct and incorrect balloons in the running window.

## 5. Close out

- [x] 5.1 In `design/Assets_Pendientes.md`, check off the "Cielo/fondo de Explotaglobos" line under
      section 0, and correct its filename reference from `mg_balloons_bg_sky.png` to the actual delivered
      `balloon_bg.png`.
