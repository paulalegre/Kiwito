## Context

Phases 1-2 built the empty vessel: autoloads, `MinigameBase`/`MinigameResult`/`LevelConfig` contracts, and
real save/settings persistence. Nothing implements `MinigameBase` yet and no `LevelConfig.tres` exists.
`GDD_MVP.md` §4-5 and `Direccion_de_Arte.md` §2.2 already freeze the game-design and color decisions this
change needs — the 4 `MATCH_COLOR` colors, their exact hex values, and their assigned accessibility
patterns are **data already decided**, not open design work:

| Color id | Hex | Pattern id |
| --- | --- | --- |
| `yellow_sol` | `#F2C14E` | stars |
| `green_hoja` | `#5FB65A` | stripes |
| `red_coral` | `#E2574C` | dots |
| `blue_oceano` | `#245C9E` | zigzag |

At proposal time, `design/minigames/mg_balloons/` only had a complete asset set (base shape, volume accent,
face, pattern overlay) for `red_coral`/dots — the other 3 pattern-overlay textures did not exist yet.
`Direccion_de_Arte.md` §2.2 itself prescribes the production technique this change leans on regardless: one
neutral balloon base + `modulate` tinting per color, plus a separate pattern-overlay `Sprite2D` — "4
texturas de patrón en vez de 4 globos completos" — so the *body* of all 4 balloons never depended on new
art.

**Update, mid-implementation:** `pattern_stars.png`, `pattern_stripes.png`, and `pattern_zigzag.png` were
delivered into `design/minigames/mg_balloons/` while this change was being implemented. All 4
pattern-overlay textures now exist, so the "graceful degradation for a missing pattern" behavior below
(Decision 4) is exercised by zero colors in practice today — it remains in the code as the correct
behavior for whenever a 5th+ color or a re-illustrated pattern is added later, but is not currently masking
any gap.

## Goals / Non-Goals

**Goals:**
- A generic, reusable `matches()` evaluation function that never needs to change when new `MatchRule`
  values are added later (only new branches).
- A first playable `MinigameBase` cartridge exercising `MATCH_ANY` and `MATCH_COLOR`, fully wired
  end-to-end (spawn → tap → result), even though it is not yet reachable from the Hub.
- `palette.tres` populated with all 4 real, frozen colors now — this is data entry against an already-locked
  doc table, not new art.
- Ship with placeholder-safe handling for any pattern texture that might be missing (originally 3 of 4;
  now none, see Context update above) that doesn't silently violate the "a color without a pattern is a
  data error" rule at the *data* level even if a *visual* gap existed.

**Non-Goals:**
- No new illustration (pattern textures for stars/stripes/zigzag, or any polished balloon art).
- No Hub wiring / `SceneDirector` integration (Phase 4).
- No `ProgressionManager`, `AudioManager`, `MetricsLogger`, or Low-Stim reaction (Phases 4-6).
- No onboarding VO.

## Decisions

### 1. `matches()` lives in a new `shared/utils/match_rule_engine.gd`, not on `LevelConfig` or `MinigameBase`
A `static func matches(balloon_color_id: StringName, config: LevelConfig) -> bool` in a small
`class_name MatchRuleEngine` `RefCounted`-less static-only script. `core/utils/` (per `CLAUDE.md`) is
reserved for core-singleton-facing stateless utilities; `shared/utils/` is a small, precedent-consistent
extension for stateless logic shared *between cartridges* rather than core systems. Alternatives
considered: a method on `LevelConfig` (rejected — `LevelConfig` must stay pure data per the data-driven
design rule, and a `Resource` carrying behavior blurs that); a method on `MinigameBase` (rejected — the
whole point of `GDD_MVP.md` §4, "un motor, no un juego," is that the matching rule is testable and reusable
independent of any scene tree, which also makes it GUT-testable in isolation later without instancing a
scene).

### 2. `LevelConfig` stores a `target_color_id: StringName`, never a raw `Color`
The balloon cartridge's `LevelConfig` subclass (`BalloonLevelConfig`) adds `target_color_id: StringName`
(e.g. `&"red_coral"`) plus `win_count: int`, `spawn_interval_sec: float`, `ascent_speed: float`. At runtime,
the actual `Color` is resolved by looking up `target_color_id` in `palette.tres` — never embedded as a
literal. Alternative considered: store a `Color` field directly on the `.tres` (rejected —
`Direccion_de_Arte.md` §6.2 is explicit that a balloon's color "se resuelve desde `LevelConfig`, que
referencia la paleta — nunca al revés"; a raw `Color` field on the `.tres` would let the two drift out of
sync with no single source of truth).

### 3. `palette.tres` ships fully populated with all 4 real colors now
Since the 4 hex values and their pattern assignments are already frozen in `Direccion_de_Arte.md` §2.2,
populating `palette.tres` now is transcription of a locked decision, not new design or art work. Each entry
carries `{color: Color, pattern_id: StringName}` so "a color without an assigned pattern" stays structurally
impossible to represent even before every pattern texture exists.

### 4. Balloon bodies for all 4 colors via `modulate` tinting of the existing neutral assets; pattern overlay degrades gracefully where texture is missing
The balloon scene tints `balloon_base.png`/`balloon_volume.png`/`balloon_face.png` (already neutral,
already in the repo) via `modulate = palette color` — this matches the documented production technique
and needs no new art. The pattern-overlay `Sprite2D` looks up a texture by `pattern_id` from a small
registry in `balloon.gd`; when no texture is registered for a `pattern_id`, the overlay node stays hidden
(`visible = false`) rather than erroring — a defensive fallback, not a crash or a data-model gap. All 4
pattern textures (`dots`, `stars`, `stripes`, `zigzag`) landed during this change's implementation, so the
fallback is currently unused in practice, but stays in place as the correct behavior for a future 5th
color or pattern rework. The default `MATCH_COLOR` preset targets `red_coral`; a `blue_oceano` balloon is
used as the in-cartridge distractor.

### 5. `errors_by_color: Dictionary` keys by `color_id: StringName`, counting incorrect taps
Matches `MinigameResult`'s existing frozen shape (`Dictionary`, no change to that contract). Populated only
for taps on a balloon that failed to match — i.e. it counts *which distractor colors* a child mis-taps, per
`GDD_MVP.md` §7's telemetry intent ("colores con más error"), without adding any new field to
`MinigameResult`.

## Risks / Trade-offs

- **[Risk]** `shared/utils/` is a new directory not in `CLAUDE.md`'s explicit topology list.
  **Mitigation:** scoped narrowly to one static-method file, consistent in spirit with `core/utils`'s
  existing "stateless static-method utilities only" rule; flagged here for visibility rather than added
  silently.
- **[Trade-off]** Reusing `balloon_base.png`/`balloon_volume.png` via `modulate` for all 4 colors means the
  "false volume" accent shape was authored looking correct only for red; worth a quick visual check (and
  the mandatory grayscale accessibility check, `Direccion_de_Arte.md` §2.2) once someone looks at the
  cartridge with fresh eyes, but not a blocker for this change.

## Migration Plan

No migration — purely additive (new files under `shared/utils/`, `shared/components/`,
`features/minigames/mg_balloons/`, `shared/global_assets/palette.tres`). Nothing existing changes shape.

## Open Questions

- None blocking. Now that all 4 pattern textures exist, the mandatory grayscale accessibility check
  (`Direccion_de_Arte.md` §2.2 — convert the 4-balloon sheet to grayscale and confirm all 4 remain
  distinguishable) is worth running as a follow-up, since it was not part of this change's scope.
