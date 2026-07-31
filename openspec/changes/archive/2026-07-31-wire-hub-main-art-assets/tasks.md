## 1. Resolve open questions with the design owner

- [x] 1.1 Confirm whether `hub_balloon_box.png` / `hub_magic_book.png` need re-export at the §5.2/§8
      target size, or whether the current size is accepted (design.md Open Question 1) — **Resolved
      2026-07-31: ship as delivered (332×332 / 170×210) for MVP, no re-export; revisit post-MVP.**
- [x] 1.2 Confirm whether `hub_bg.png` needs re-export closer to 1920×1080 (design.md Open Question 2)
      — **Resolved: moot, the 2026-07-31 delivery already measures 1920×1080 exactly.**
- [x] 1.3 Confirm the circular icon-button treatment is the intended final direction for Hub nodes, and
      update `design/Assets_Pendientes.md`'s wording if so (design.md Open Question 3) — **Resolved:
      confirmed as final direction; update the checklist wording in task 6.2.**

## 2. Import assets in the Godot editor

- [x] 2.1 Open the project once in the Godot editor (`mcp__godot__launch_editor`) so
      `design/hub_main/{hub_bg,hub_balloon_box,hub_magic_book}.png` each get a generated `.import` file
      — **Done 2026-07-31.**
- [x] 2.2 Set import compression per `Direccion_de_Arte.md` §8; mipmaps off — **Done 2026-07-31, revised
      from the original plan.** `mcp__godot__launch_editor`'s default import left all three at
      `compress/mode=0` (Lossless), same as the existing `design/minigames/mg_balloons/balloon_base.png`
      (checked directly — it is *not* VRAM Compressed despite this task's original wording). Applied:
      `hub_bg.png` → `compress/mode=2` (VRAM Compressed, it's the "sprite grande" full-background case);
      `hub_balloon_box.png` / `hub_magic_book.png` → left at Lossless (mode=0), matching §8's "UI e
      iconos pequeños con bordes duros" bucket and the actual `balloon_base.png` precedent, not the
      "VRAM Compressed for all three" this task originally called for. Mipmaps were already
      `mipmaps/generate=false` by default on all three, matching §8.

## 3. Wire the Hub background

- [x] 3.1a **Implemented differently than planned:** instead of a `ColorRect`, added a `Node2D` named
      `BackgroundBase` running a new `shared/components/palette_background_rect.gd`
      (`PaletteBackgroundRect`) as the first child of `features/hub_main/hub_main.tscn` — draws a
      full-viewport-plus-margin rect via `_draw()`, colored from `palette.tres`'s `cream_fade`. `Node2D`
      was chosen over `ColorRect`/`Control` specifically to avoid `Control.mouse_filter` intercepting
      touch input ahead of the `Area2D`-based `HitboxComponent`s (see 4.3/5.3 caveat below).
- [x] 3.1b Added a `Sprite2D` node named `Background` as the next sibling, referencing
      `design/hub_main/hub_bg.png`.
- [x] 3.1c **Added 2026-07-31, later same day** (requested explicitly): attached a new
      `shared/components/cover_sprite.gd` (`CoverSprite`) script to `Background` so it scales in
      "cover"/"aspect fill" mode instead of rendering at a fixed 1:1/centered size — always fills the
      full revealed viewport with no crop-free axis left uncovered, recalculating scale and position
      on every `Viewport.size_changed` (position tracks the actual viewport center, not a fixed
      `Vector2(960, 540)`, because `expand` anchors at the top-left, not centered — see design.md).
      Re-ran `mcp__godot__run_project` after this change: no new errors.
- [x] 3.2 Verified via `mcp__godot__run_project` + `get_debug_output`: project boots to the Hub
      (`root.gd` → `SceneDirector.goto_hub()`) with zero errors — no missing-resource or script-compile
      errors for any of the three new textures or the new script. **Not independently confirmed:**
      whether the background is visually gray-free — no screenshot/visual tool available via the
      `mcp__godot__*` MCP surface; ask the user to eyeball the running window.

## 4. Wire Caja de Globos art

- [x] 4.1 Removed `PlaceholderCircle`, added `Sprite2D` (named `ArtSprite`) referencing
      `design/hub_main/hub_balloon_box.png`, sibling of `HitboxComponent` — matches `balloon.tscn`'s
      pattern.
- [x] 4.2 `hub_balloon_box.png` is 332×332 at scale 1.0 (visible radius 166) → `CircleShape2D` radius
      set to **215.8** (166 × 1.3).
- [x] 4.3 **Confirmed by user 2026-07-31**, manual tap in the running window: Caja de Globos still
      launches Explotaglobos correctly (debug log even showed a full play session — balloon taps,
      incorrect-tap frustration-help trigger — proving the launch and the minigame both work end to end).

## 5. Wire Libro Mágico art

- [x] 5.1 Removed `PlaceholderCircle`, added `Sprite2D` (`ArtSprite`) referencing
      `design/hub_main/hub_magic_book.png`, same pattern as Caja de Globos.
- [x] 5.2 `hub_magic_book.png` is 170×210 at scale 1.0 (visible radius = long side / 2 = 105) →
      `CircleShape2D` radius set to **136.5** (105 × 1.3).
- [x] 5.3 **Confirmed by user 2026-07-31**, manual tap in the running window: Libro Mágico still opens
      the Álbum de Stickers correctly.

## 6. Verify and close out

- [x] 6.1 Confirmed by user 2026-07-31: both Hub nodes tapped manually in the running window,
      Explotaglobos launches from Caja de Globos and the Álbum de Stickers opens from Libro Mágico,
      unchanged from before this art swap.
- [x] 6.2 Checked off the Hub-background line of item 0 (split into a separate "modales" line, still
      unchecked, since modals weren't touched) and all of item 1 in `design/Assets_Pendientes.md`;
      updated item 1's wording to the confirmed circular icon-button direction and noted both Hub-node
      sizes as an accepted MVP shortfall pending a post-MVP re-export.
- [x] 6.3 Confirmed via `grep -rn "PlaceholderCircle" features/hub_main/` — no remaining references in
      either `.tscn`; `placeholder_circle.gd` itself is untouched.
