## Context

`features/hub_main/hub_main.tscn` today has three children with no background: `CajaDeGlobos` and
`LibroMagico`, each a thin wrapper instancing a `PlaceholderCircle` (a `_draw()`-based circle tinted
from `palette.tres`) plus a `HitboxComponent` (`Area2D` + `CircleShape2D`, radius 83.2 — i.e. a 128px
visible / 166.4px hitbox circle, already smaller than the §5.2 "Nodo del Hub" spec of 320+/416, since
the placeholder was never meant to be final-sized art). Final art now exists at
`design/hub_main/{hub_bg,hub_balloon_box,hub_magic_book}.png`. `features/minigames/mg_balloons/balloon.tscn`
already establishes the project's convention for wiring `design/*.png` into a scene: a `Sprite2D` child
per visual layer, referenced via `ext_resource type="Texture2D"`, sibling to (not replacing) the
`HitboxComponent`.

## Goals / Non-Goals

**Goals:**
- Hub renders real art for its background and both interactive nodes instead of engine-default gray /
  procedural circles.
- Follow the existing `balloon.tscn` wiring convention (`Sprite2D` + `ext_resource Texture2D`) so
  there's one pattern for "how design/ art gets into a scene" project-wide.
- Keep `HitboxComponent` untouched in behavior; only resize/reposition it if the new sprite's actual
  visible bounds require it to stay correctly oversized (Core_Architecture.md's 30%-larger-than-sprite
  rule) and roughly centered on the art.
- Leave a clear paper trail (this design doc's Open Questions) for the two size/shape deviations found
  during proposal research, instead of silently building around them.

**Non-Goals:**
- Not re-exporting or resizing the delivered PNGs ourselves — that's a design-owner decision (Open
  Questions below), not an implementation one.
- Not touching `caja_de_globos.gd`, `libro_magico.gd`, `hub_main.gd`, or any tap/signal/launch logic.
- Not implementing `ParallaxBackground`/`ParallaxLayer` — `hub_bg.png` is a single flat layer for MVP;
  `Direccion_de_Arte.md` §3.5 explicitly marks layered parallax as a production note, not an MVP
  requirement ("el Hub actual es estático y no requiere paralaje").
- Not touching the other `Assets_Pendientes.md` checklist items (pause-menu icons, sticker accessories,
  `mg_balloons` sky) — no assets delivered for those yet.

## Decisions

**Background node type: `Sprite2D`, not `TextureRect`/`ParallaxBackground`.**
`hub_main.tscn` is a `Node2D` scene (not `Control`), matching every other scene in the project
(`balloon.tscn`, `caja_de_globos.tscn`) — a `Sprite2D` is consistent with that and with how
`mg_balloons` art is wired. `ParallaxBackground` is explicitly deferred by §3.5. Add it as the first
child (`node name="Background"`) so it draws behind `CajaDeGlobos`/`LibroMagico` by default Node2D
z-order (declaration order = draw order for siblings with equal z-index).

**Hub node art: replace `PlaceholderCircle` with `Sprite2D`, keep `HitboxComponent` as its own sibling
node.** Mirrors `balloon.tscn`'s pattern exactly (art sprites and `HitboxComponent` are siblings under
the same root, not parent/child). `PlaceholderCircle.gd` itself is not deleted — it's still the
documented placeholder-art pattern (`design.md` of `progression-and-hub`) for any future Hub node that
ships before its art does.

**Hitbox sizing left as a scene-authoring judgment call, not scripted math.** The existing radius 83.2
CircleShape2D was already undersized relative to §5.2 (it was placeholder-matched, not spec-matched).
Since the delivered art's own logical size is itself an open question (below), recomputing an exact
"final" hitbox radius now would just be re-deriving a number from an unconfirmed input. Tasks.md calls
out sizing the hitbox to 1.3× the actual imported sprite's visible radius once the art is placed in the
Godot editor (where `Texture2D.get_size()` and the scene's actual scale are visible), rather than
guessing pixel math here.

**Background gets a `ColorRect` base layer beneath `hub_bg.png`, tinted from `palette.tres`'s
`cream_fade` (`#FBF3E4`, the "Crema papel" of `Direccion_de_Arte.md` §2).** Added 2026-07-31 after
measuring the delivered `hub_bg.png` at exactly 1920×1080 — i.e. it covers the logical design canvas
with zero bleed margin. `Core_Architecture.md` §0's `stretch/aspect = expand` reveals *more* than
1920×1080 on any tablet aspect ratio narrower than 16:9 (iPad 4:3, Android 3:2/16:10, per `GDD_MVP.md`'s
platform note) — worst case iPad 4:3 reveals up to 1920×1440 (height +33%). Rather than asking for a
bigger painted PNG (which would also collide with §8's 2048×2048 max-texture cap once combined with the
1.5× delivery-scale convention), the full-viewport `ColorRect` guarantees zero engine-gray at any aspect
ratio for free, and its `cream_fade` tone is already a near-exact match for `hub_bg.png`'s own painted
edge color, so the seam where the PNG ends and the `ColorRect` shows through is not visually detectable.
Added as the first child of `Background` (or as `Background`'s own `color` if implemented as a
`ColorRect` root with `hub_bg.png` as a `Sprite2D` child) — either way it must draw behind `hub_bg.png`.

**Added 2026-07-31 (later same day): `Background`'s `Sprite2D` gets a `CoverSprite`
(`shared/components/cover_sprite.gd`) script — "cover"/"aspect fill" scaling, not a static 1:1
render.** Requested explicitly ("que ocupe el máximo de ancho y alto... como un cover aplicado").
Computes `scale = max(viewport.size.x / texture.size.x, viewport.size.y / texture.size.y)` and
re-centers on `get_viewport_rect().size / 2.0`, recalculated on every `Viewport.size_changed`. The
re-centering (not a fixed `Vector2(960, 540)`) matters because `stretch/aspect = expand` anchors
`(0,0)` at the window's top-left and only grows the revealed area toward bottom-right — it is *not*
a symmetric expansion around the design canvas's center — so a fixed-position cover sprite would
misalign against the actually-revealed viewport on non-16:9 aspect ratios. Trade-off, stated
explicitly to the user: cover-fit crops the sprite's excess axis (e.g. on iPad 4:3, ~160px is cropped
off each of the *left/right* edges, the axis that overshoots once the same uniform scale needed to
satisfy the height axis is applied) — the inverse trade-off from the earlier composition-discipline
conversation (that one traded "safe margin at the edges" for "never crop"; this one takes the
opposite trade for a guaranteed zero-seam full-bleed look). The `BackgroundBase` `ColorRect`-equivalent
described above is kept as a zero-cost fallback (covers the one-frame gap before `_update_cover()`
runs, and any aspect ratio more extreme than tested) rather than removed.

## Risks / Trade-offs

- **[Risk, superseded 2026-07-31] Delivered PNGs are smaller than the §5.2/§8 production spec.** The
  assets referenced when this design doc was written (hub_balloon_box.png / hub_magic_book.png ≈
  300–340 logical px, hub_bg.png at 1225×684) have since been replaced in `design/hub_main/` with a new
  delivery. Re-measured 2026-07-31 (PNG `IHDR`, exact pixel dims):
  - `hub_bg.png`: **1920×1080** — now matches the logical design canvas exactly (was 1225×684).
    Resolves former Open Question 2 in the "does it need to hit 1920×1080" sense; see the new
    `ColorRect`-base Decision above for the remaining aspect-ratio-bleed gap this doesn't cover.
  - `hub_balloon_box.png`: **332×332** (square). Clears the §5.2 320px+ visible minimum *only* if
    displayed at native scale 1.0 (no high-density headroom) — at the project's 1.5× delivery
    convention this would read as ~221px logical, well under spec. Its square canvas also reads as
    confirming the circular icon-button direction (former Open Question 3).
  - `hub_magic_book.png`: **170×210** (portrait). Does **not** clear 320px+ under any interpretation —
    max dimension 210px is below the minimum even at native 1× scale. It is also ~1.6× smaller than
    `hub_balloon_box.png` on its long side, which conflicts with `Assets_Pendientes.md`'s own "mismo
    tamaño" requirement between the two Hub nodes.

  → **Mitigation (decision, 2026-07-31):** ship as-is for MVP. Both Hub-node sprites are accepted at
  their delivered size — `hub_magic_book.png` displayed at native scale (not upscaled in-editor, to
  avoid introducing blur on top of an already-undersized asset) even though it lands under the §5.2
  target and mismatched vs. its sibling node. This is judged strictly better than the procedural
  `PlaceholderCircle` it replaces, and is expected to be revisited with a proper re-export once the
  product moves past MVP into a stable-release art pass — not blocking this change.
- **[Risk] Circular icon-button treatment diverges from the checklist's literal box/book silhouette
  language** → **Mitigation:** flagged as an Open Question rather than silently implemented as if it
  were the originally-planned shape; `Direccion_de_Arte.md` itself doesn't mandate a literal shape for
  Hub nodes, so this isn't a spec violation, just a checklist deviation worth a conscious sign-off.
- **[Risk] No `.import` files exist yet for the three new PNGs** → **Mitigation:** this is expected;
  Godot generates `.import` metadata on first load in the editor. Tasks.md treats "open the project in
  the Godot editor once to trigger import, then verify via `mcp__godot__get_project_info` /
  `run_project`" as an explicit step, not an assumption.
- **[Trade-off] Background is a flat single PNG, not the 2–4 layered silhouettes §3.5 describes for
  future parallax** → accepted for MVP per §3.5's own text; re-layering later means redoing this one
  asset, not a structural rework, since it's a single `Sprite2D` node either way.

## Open Questions

**Resolved 2026-07-31** (product owner decision — assets in this state are MVP-acceptable and will be
revisited in a stable-release art pass, not before shipping this change):

1. ~~Should `hub_balloon_box.png` / `hub_magic_book.png` be re-exported to hit the 320px+ logical /
   1.5× delivery-scale spec~~ → **No re-export for MVP.** Ship both at native scale as delivered
   (332×332 and 170×210 respectively), accepting that `hub_magic_book.png` lands under §5.2's 320px+
   target and is smaller than its sibling node. Tracked for a follow-up art pass post-MVP.
2. ~~Should `hub_bg.png` be re-exported closer to the 1920×1080 logical design canvas~~ → **Moot**, the
   asset delivered 2026-07-31 already measures 1920×1080 exactly.
3. ~~Is the circular icon-button treatment... the confirmed final direction for Hub nodes~~ → **Yes**,
   treated as confirmed (the square `hub_balloon_box.png` canvas is consistent with a circular
   icon-button composition). `Assets_Pendientes.md`'s "box/chest" and "book" silhouette wording is
   superseded; update it when checking off item 1 (see tasks.md 6.2).
