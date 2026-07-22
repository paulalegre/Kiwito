## Context

`core/autoloads/ProgressionManager.gd` is currently an empty stub (fields + signal declared, zero logic,
never touches `SaveManager`). `core/data/SaveManager.gd` already has working `get_total_balloons_popped()`/
`set_total_balloons_popped()`/`get_unlocked_stickers()`/`set_unlocked_stickers()` since Phase 2 — this
change is pure consumption, no `SaveManager` shape changes. `core/autoloads/SceneDirector.gd` already
implements the full Hub↔minigame swap (`launch_minigame()`, `goto_hub()`, container/fade pattern, teardown)
per the already-shipped `scene-director` spec; its `_on_minigame_session_finished(_result)` handler
currently discards the `MinigameResult` and just calls `goto_hub()`. `features/hub_main/hub_main.tscn` is a
bare `Node2D` with no children or script. `shared/components/hitbox_component.gd` (built for the balloon
cartridge in Phase 3) is already parent-agnostic — it only needs to be a child of some `Node2D` with an
`Area2D` — so it is directly reusable for the Hub's two interactive nodes without modification.

`GDD_MVP.md` §6 freezes the milestone table (5 → `sticker_01` básico, 20 → `sticker_02` intermedio, 50 →
`sticker_03` especial) and specifies the Álbum shows "un Grid con las siluetas en negro de los stickers.
Los stickers desbloqueados se muestran a color." No Hub or sticker art exists yet anywhere in the project
(`design/` only has the balloon cartridge's assets). Per the same product decision already made for Change
#3, this change proceeds with placeholder visuals rather than blocking on illustration.

## Goals / Non-Goals

**Goals:**
- `ProgressionManager` becomes the real, sole in-memory owner of `total_balloons_popped` and
  `unlocked_stickers`, following `SettingsManager`'s existing load/mutate/persist shape.
- A finished balloon session's correct pops flow through `SceneDirector` into `ProgressionManager`,
  potentially unlocking a sticker, before the Hub is shown again.
- The Hub has two working interactive nodes (Caja de Globos, Libro Mágico) that close the loop end to end.
- The Álbum de Stickers modal renders the 3 frozen milestone slots as black silhouettes (locked) or
  palette-tinted (unlocked), per `GDD_MVP.md` §6.

**Non-Goals:**
- Final Hub/sticker illustration — explicitly deferred (see Open Questions).
- Pause menu — named in `Propuesta_MVP.md` §3's frozen MVP scope list, but not in roadmap item 4's own
  text; flagged here as an identified gap, not silently pulled into this change.
- Any audio (Phase 5), Low-Stim reactions in the new Hub UI (Phase 5), telemetry (Phase 6).
- A second minigame cartridge or a Hub "cartridge selector" — one cartridge, one entry point, per MVP scope.

## Decisions

**1. Milestone table lives as a `const` array of dictionaries inside `ProgressionManager.gd`, not a
`Resource`.** Unlike `palette.tres` (referenced from multiple scenes via `@export`, and conceptually
design-owned data an artist/designer might open in the Inspector), the milestone table is consumed from
exactly one place — `ProgressionManager`'s own logic — and nothing external needs to reference it by path.
A `Resource` would add an indirection with no consumer benefit. Alternative considered: a
`ProgressionMilestone.gd` `Resource` subclass mirroring `Palette.gd`'s pattern — rejected as unneeded
abstraction for data that has exactly one reader and is already frozen in `GDD_MVP.md` §6 (adding a 4th
milestone later is a one-line array edit either way).
```gdscript
const MILESTONES: Array[Dictionary] = [
    {"threshold": 5, "sticker_id": &"sticker_01"},
    {"threshold": 20, "sticker_id": &"sticker_02"},
    {"threshold": 50, "sticker_id": &"sticker_03"},
]
```

**2. `ProgressionManager.record_session_result(result: MinigameResult)` is the single entry point for
awarding progress.** It adds `result.correct_pops` to `total_balloons_popped`, then walks `MILESTONES` in
ascending order unlocking any `sticker_id` whose `threshold` is now met and not already in
`unlocked_stickers`, emitting `sticker_unlocked(id)` once per newly-crossed milestone, then persists both
fields via `SaveManager` and calls `flush()` once at the end (session-end is one of `GDD_MVP.md` §7.3's
named safe points). This mirrors `SettingsManager.set_low_stim_mode()`'s existing shape: mutate in-memory
state, push to `SaveManager`, flush, emit signal.

**3. `SceneDirector` forwards the result directly — no event bus.** `_on_minigame_session_finished` changes
from `func(_result: MinigameResult) -> void: goto_hub()` to
`func(result: MinigameResult) -> void: ProgressionManager.record_session_result(result); goto_hub()`. This
is a direct typed autoload-to-autoload call, the same shape already used by `SettingsManager` calling into
`SaveManager` — not the forbidden global string EventBus, and not a new signal, since `SceneDirector`
already legitimately owns the `MinigameResult` as the "Host" side of the Minigame→Core contract
(`CLAUDE.md`: cross-domain results travel as `MinigameResult` to whatever connects `session_finished`,
which is already `SceneDirector`). No existing `scene-director` spec requirement changes shape — this is
additive behavior layered on top, so it is captured as a new requirement under this change's own
`progression-and-hub` capability rather than a delta against the frozen `scene-director` spec.

**4. Hub interactive nodes reuse `HitboxComponent` unmodified, wrapped in new Hub-only placeholder
visuals.** `Caja de Globos` and `Libro Mágico` are each a small `Node2D` with a child `HitboxComponent`
(from `shared/components/`, already parent-agnostic) for input, and a runtime `_draw()`-based circle for
its placeholder body — a circle has no sharp corners or 90° angles by construction, satisfying
`Direccion_de_Arte.md`'s shape language for free, with zero new texture assets. Each circle's fill color is
resolved from `palette.tres` at `_ready()` (never a literal hex), reusing an existing gameplay color purely
for visual distinction between the two nodes (`red_coral` for Caja de Globos, `blue_oceano` for Libro
Mágico) — this carries no `MatchRule` semantic meaning, it is only today's placeholder differentiation.
Tapping Caja de Globos calls `SceneDirector.launch_minigame(MG_BALLOONS_SCENE, DEFAULT_LEVEL_CONFIG)` using
Phase 3's `level_match_color_red.tres` preset (the one preset with a fully-realized asset set, matching the
same reasoning Phase 3 used when picking its own verification target). Tapping Libro Mágico opens the
Álbum modal.

**5. Álbum de Stickers is a `CanvasLayer`-based modal under `shared/ui_elements/`, mirroring
`fade_transition`'s existing pattern.** `sticker_album.tscn`: a `CanvasLayer` (`process_mode =
PROCESS_MODE_ALWAYS`, matching `fade_transition`) containing a full-screen `Control` background (tap
anywhere to close — no icon/label needed, keeping the zero-text invariant and avoiding a blocking modal a
child can't dismiss) and a `GridContainer` with one slot `Control` per `MILESTONES` entry. A locked slot is
plain black (`Color(0,0,0,1)`) — this is the same "achromatic, not one of the 4 game colors" exemption
already relied on by `fade_transition`'s black overlay and the balloon's `PatternSprite` overlay opacity, and
it is also the literal doc requirement (`GDD_MVP.md` §4: "siluetas en negro"), not an arbitrary color
choice. An unlocked slot is tinted `red_coral` from `palette.tres` (GDD's own sticker example is "globo
rojo con gafas" — reusing that color is grounded in the doc, not invented) — all 3 unlocked slots share this
one placeholder tint today; giving each of the 3 stickers its own distinct appearance is real illustration
work, deferred with the rest of the Hub art pass. `ProgressionManager.unlocked_stickers` is read once when
the modal opens to decide each slot's lock state.

## Risks / Trade-offs

- **[Risk]** Reusing `red_coral`/`blue_oceano` for Hub icon placeholders with no semantic tie to `MatchRule`
  could be mistaken for a gameplay hint by a future reader. → **Mitigation:** explicitly documented here and
  in code comments at the point of assignment; the final art pass removes this placeholder tinting entirely.
- **[Risk]** `record_session_result()` is Explotaglobos-specific in spirit (reads `result.correct_pops`) but
  lives on `ProgressionManager`, a domain-generic autoload. If a second cartridge ships later with a
  different notion of "progress," this method's meaning may need to generalize. → **Mitigation:** not
  addressed now (only one cartridge exists; premature to design for a hypothetical second one), but flagged
  so it isn't a silent surprise later.
- **[Trade-off]** Circle-based `_draw()` placeholders vs. authoring even rough placeholder texture files —
  chosen because it needs zero new binary assets and trivially satisfies the shape-language rule, at the
  cost of looking obviously programmer-art. Acceptable since Hub illustration is already a known, separate
  follow-up.

## Open Questions

None blocking. Follow-ups explicitly deferred, to avoid being lost:
- Real Hub illustration (Caja de Globos, Libro Mágico) and per-sticker illustration (3 distinct designs per
  `GDD_MVP.md` §6's own examples, e.g. "gafas"/"capa"/"brillo") — a full art pass, not scoped here.
- Pause menu (`Propuesta_MVP.md` §3) has no assigned phase in the roadmap's own item text; worth deciding
  which future change owns it before Phase 5 starts.
- `record_session_result()`'s Explotaglobos-specific shape (see Risks) — revisit if/when a second cartridge
  is proposed.
