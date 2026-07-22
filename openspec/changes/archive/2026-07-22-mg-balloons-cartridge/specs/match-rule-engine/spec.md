## ADDED Requirements

### Requirement: Generic matches() evaluation function
`shared/utils/match_rule_engine.gd` SHALL define a `class_name MatchRuleEngine` exposing a static
`matches(balloon_color_id: StringName, config: LevelConfig) -> bool` function that evaluates the
`MatchRule` enum value on `config.match_rule`. It SHALL NOT depend on any node, scene tree, or autoload —
it must be callable from a pure-logic test with only a `LevelConfig` instance and a color id.

#### Scenario: MATCH_ANY always matches
- **WHEN** `config.match_rule` is `MatchRule.MATCH_ANY`
- **THEN** `matches()` returns `true` regardless of `balloon_color_id`

#### Scenario: MATCH_COLOR matches only the configured target
- **WHEN** `config.match_rule` is `MatchRule.MATCH_COLOR` and `balloon_color_id` equals
  `config.target_color_id`
- **THEN** `matches()` returns `true`

#### Scenario: MATCH_COLOR rejects a non-target color
- **WHEN** `config.match_rule` is `MatchRule.MATCH_COLOR` and `balloon_color_id` does not equal
  `config.target_color_id`
- **THEN** `matches()` returns `false`

### Requirement: Adding a MatchRule value never requires editing existing branches
`MatchRuleEngine.matches()` SHALL be structured (e.g. `match` statement per enum case) so that adding a new
`MatchRule` value (`MATCH_SHAPE`, `MATCH_SIZE`, `MATCH_COUNT` in later phases) is additive — a new branch —
and requires no edit to the `MATCH_ANY` or `MATCH_COLOR` branches already shipped.

#### Scenario: Existing branches are untouched by a future addition
- **WHEN** a future change adds a `MATCH_SHAPE` branch to `matches()`
- **THEN** the `MATCH_ANY` and `MATCH_COLOR` branches, and their existing test coverage, require no
  modification for that addition to work
