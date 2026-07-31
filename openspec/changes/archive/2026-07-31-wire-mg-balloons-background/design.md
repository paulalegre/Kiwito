## Context

`mg_balloons.tscn` (`MgBalloons` root, `SpawnTimer`, `IdleTimer`, `GoalBox`) currently has no background
node — it renders on the engine's default gray. `hub_main.tscn` already solved this exact problem for the
Hub via a two-node pattern: `BackgroundBase` (`PaletteBackgroundRect`, a `Node2D` that `_draw()`s a
full-viewport-plus-margin rect tinted from `palette.tres`) underneath `Background` (`Sprite2D` +
`CoverSprite`, which scales/repositions on every resize to cover 100% of the revealed area under
`stretch/aspect = expand`, per `Core_Architecture.md` §0). `design/minigames/mg_balloons/balloon_bg.png`
(1920×1080) now exists, produced to the "Menta `#CFE7DA`" ambient role `Direccion_de_Arte.md` §2.1
assigns explicitly to "Cielo/fondo del minijuego de globos" — but `palette.tres` has no entry for that
role yet (it only has `cream_fade`, the Hub's role, plus the 4 game colors, `warm_grey_tint`, and
`amber_attention`).

## Goals / Non-Goals

**Goals:**
- Balloon minigame renders `balloon_bg.png` behind all gameplay, with no default-gray visible at any
  tablet aspect ratio, using the exact same proven node pattern already shipped for the Hub.
- Every color used resolves from `palette.tres` — no literal hex, per the project-wide binding rule.

**Non-Goals:**
- Parallax layering (`Direccion_de_Arte.md` §3.5's 2-4 depth layers) — explicitly a "production note, not
  an MVP obligation" per that same section; `hub_bg.png` shipped as a single flat composited image and
  `balloon_bg.png` follows the same precedent. Revisit only if/when parallax motion is actually activated.
- Any gameplay, spawn, `MatchRule`, or frustration-escalation change — `mg_balloons.gd`/`balloon.gd`/
  `goal_box.gd` are untouched.
- A modal/Álbum background (`Assets_Pendientes.md` item 0's second unchecked line) — out of scope, tracked
  separately.

## Decisions

**Reuse `hub_main.tscn`'s exact `PaletteBackgroundRect` + `CoverSprite` two-node pattern, not a new one.**
Both components already live in `shared/components/` with no dependency on a specific parent scene
(`palette_background_rect.gd`, `cover_sprite.gd`), so this is composition, not new code. Inventing a
different background mechanism for the second scene that needs one would fragment a working pattern for
no benefit.

**Add `mint_ambiente` (`Color(0.811765, 0.905882, 0.854902, 1)` = `#CFE7DA`) to `palette.tres`.**
This is additive only — no existing key renamed, removed, or reinterpreted, so no existing consumer
(`Palette.get_color()` already resolves arbitrary `StringName` ids) is affected. It encodes a value
`Direccion_de_Arte.md` §2.1 already fixes normatively for this exact scene; the entry simply didn't exist
yet because nothing consumed it before this change. Naming follows the established mixed English-color +
Spanish-qualifier convention already used by every other entry (`blue_oceano`, `green_hoja`, `cream_fade`).

**`PaletteBackgroundRect` tinted with `mint_ambiente` sits under the `CoverSprite`, exactly mirroring why
the Hub keeps `cream_fade` under `hub_bg.png`.** `CoverSprite` covers 100% of the revealed viewport by
design, but the base layer guarantees color continuity (no gray sliver, no seam) for the first draw before
the sprite's `_ready()`/resize callback runs, and for any edge case where the cover-fill math and the
viewport's actual redraw timing diverge — the Hub's `design.md` already documents this as the reason that
layer was added there.

**Both background nodes are inserted as the first children of `MgBalloons`, before `SpawnTimer`,
`IdleTimer`, and `GoalBox`.** Godot 2D draws siblings in child-index order; runtime-spawned `Balloon`
instances are appended via `add_child()` in `mg_balloons.gd`, so as long as the background nodes are
already present as the earliest children when the scene loads, every spawned balloon and the existing
`GoalBox` sibling will naturally draw on top of it without any z-index bookkeeping.

## Risks / Trade-offs

- **[Risk]** Adding a palette entry touches a shared asset (`shared/global_assets/palette.tres`), which
  sits outside `features/minigames/mg_balloons/`'s cartridge-isolation boundary, even though the proposal
  frames this as "scene-wiring only." → **Mitigation**: the change is purely additive (one new dictionary
  key), matches the exact precedent already set when `cream_fade` was introduced for the Hub's equivalent
  need, and cannot break any other `Palette.get_color()` caller since none reference `mint_ambiente` today.
- **[Risk]** `CoverSprite`'s cover-fill scaling assumes the source texture's aspect ratio is close to the
  viewport's; `balloon_bg.png` is delivered at exactly 1920×1080, matching the design canvas, so cropping
  only occurs on non-16:9 tablet aspect ratios — the exact, already-proven behavior `hub_bg.png` relies on.
  No new risk introduced.
- **[Risk]** Godot only generates the new PNG's `.import` file on first editor load — this is a manual/
  editor step, not scriptable via the MCP tools available in this environment. → **Mitigation**: called out
  explicitly as a task step, matching how `wire-hub-main-art-assets` handled the same caveat for its three
  new textures.

## Migration Plan

None required — purely additive (new scene nodes, one new palette entry, one checklist update). No save
data, autoload state, or existing script behavior changes. Rollback is a plain revert of the scene/palette
diffs if needed.

## Open Questions

None blocking implementation. Parallax layer splitting (Non-Goals) is deferred, not undecided — revisit
only if/when motion is actually added to any background in the project.
