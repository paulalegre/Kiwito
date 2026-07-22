## 1. Palette and data

- [x] 1.1 Create `shared/global_assets/palette.tres` as a typed `Resource` (new `Palette.gd` script,
      `class_name Palette`) declaring all 4 game colors (`yellow_sol`, `green_hoja`, `red_coral`,
      `blue_oceano`) with their real hex values and their `pattern_id` (`stars`, `stripes`, `dots`,
      `zigzag`), per `Direccion_de_Arte.md` §2.2.
- [x] 1.2 Create `shared/contracts/BalloonLevelConfig.gd` extending `LevelConfig`, adding
      `target_color_id: StringName`, `win_count: int`, `spawn_interval_sec: float`,
      `ascent_speed: float` — no change to the frozen `LevelConfig`/`MinigameResult` shapes.

## 2. Match rule engine

- [x] 2.1 Create `shared/utils/match_rule_engine.gd` (`class_name MatchRuleEngine`) with static
      `matches(balloon_color_id: StringName, config: LevelConfig) -> bool`, evaluating `MATCH_ANY`
      (always true) and `MATCH_COLOR` (equality against `config.target_color_id`) via a `match`
      statement structured so future `MatchRule` values are additive branches.

## 3. Shared components

- [x] 3.1 Create `shared/components/hitbox_component.gd`: `Area2D`-based, `@export`-configurable size
      at least 30% larger than the sprite it's paired with, filters `event.index != 0`, calls
      `get_viewport().set_input_as_handled()` on a handled tap, emits a local `tapped` signal (signals
      up) with no reference to any specific parent scene.
- [x] 3.2 Create `shared/components/ascent_component.gd`: moves its owner `Node2D` upward on Y each
      frame at an `@export var ascent_speed: float`, with no dependency on a specific parent.
- [x] 3.3 Create `shared/components/juice_component.gd`: on a `play_feedback()` call, triggers a
      scale/bounce tween starting within 100ms, with no dependency on a specific parent.

## 4. Balloon cartridge

- [x] 4.1 Create `features/minigames/mg_balloons/balloon.tscn` + `balloon.gd`: a single balloon node
      wiring the hitbox/ascent/juice components, tinting the shared `balloon_base.png`/
      `balloon_volume.png`/`balloon_face.png` via `modulate` from its assigned `color_id` (looked up in
      `palette.tres`), and showing/hiding a pattern-overlay `Sprite2D` depending on whether a texture is
      registered for that color's `pattern_id` (only `dots` exists now — others stay hidden, not an
      error).
- [x] 4.2 Create `features/minigames/mg_balloons/mg_balloons.tscn` + `mg_balloons.gd` extending
      `MinigameBase`: implements `start(config: LevelConfig)`, spawns `balloon.tscn` instances below
      camera at `spawn_interval_sec` using `ascent_speed` from the config, assigning each spawned
      balloon a color id (target color plus at least one distractor color for `MATCH_COLOR` presets).
- [x] 4.3 Wire tap resolution: on a balloon's `tapped` signal, evaluate `MatchRuleEngine.matches()`;
      on true, play juice feedback, pop/remove the balloon, increment `correct_pops`; on false, trigger
      a shake animation + neutral sound cue, increment `failed_taps` and `errors_by_color[color_id]`,
      and leave the balloon alive and the level state otherwise unaffected (Zero-Punishment — no level
      end, no restart).
- [x] 4.4 Implement win condition: once `correct_pops >= win_count`, stop spawning, clear remaining
      balloons, and emit `session_finished(result: MinigameResult)` with `correct_pops`, `failed_taps`,
      `duration`, and `errors_by_color` populated from the session.

## 5. LevelConfig presets

- [x] 5.1 Create `features/minigames/mg_balloons/resources/level_match_any.tres`: `match_rule =
      MATCH_ANY`, sane default `win_count`/`spawn_interval_sec`/`ascent_speed`.
- [x] 5.2 Create `features/minigames/mg_balloons/resources/level_match_color_red.tres`: `match_rule =
      MATCH_COLOR`, `target_color_id = &"red_coral"`, `win_count = 5` per `GDD_MVP.md` §5, same
      spawn/ascent tunables.

## 6. Verification

- [x] 6.1 Manually run the cartridge scene standalone via the Godot MCP tools (`run_project` /
      `get_debug_output`) with each preset and confirm: `MATCH_ANY` accepts any tap as correct;
      `MATCH_COLOR` (red preset) accepts only red taps, shakes on wrong-color taps without ending the
      level, and fires `session_finished` with correct `correct_pops`/`failed_taps`/`errors_by_color`
      once `win_count` is reached. Verified via a temporary harness scene (deleted after use): `MATCH_ANY`
      → `correct_pops=2 failed_taps=0`; `MATCH_COLOR` (red) → `correct_pops=2 failed_taps=11
      errors={blue_oceano: 11}`, confirming zero-punishment (level continued through 11 wrong taps) and
      accurate result reporting.
- [x] 6.2 Confirm no script or `.tscn` added in this change contains a literal hex/`Color(...)` for any
      of the 4 game colors (grep check). Only hit: `PatternSprite`'s `modulate = Color(1, 1, 1, 0.2)`
      (pure opacity control, not one of the 4 game colors) — compliant.
- [x] 6.3 Update `openspec/changes/mg-balloons-cartridge/design.md`'s Open Questions / follow-up note
      is still accurate. All 3 missing pattern textures (stars/stripes/zigzag) arrived mid-implementation
      and were wired into `balloon.gd`'s `PATTERN_TEXTURES` registry — design.md's Context, Decision 4,
      Risks, and Open Questions sections were updated to reflect that the "missing pattern" fallback is
      now defensive-only (all 4 colors currently resolve a real texture).
