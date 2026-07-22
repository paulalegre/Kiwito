## ADDED Requirements

### Requirement: GUT is available for pure-logic tests
The project SHALL include the GUT (Godot Unit Test) addon so that pure-logic systems — decoupled from the
`SceneTree` — can be tested without running the full game, per `docs/Core_Architecture.md` §7.

#### Scenario: GUT addon is present
- **WHEN** the `addons/` directory is inspected
- **THEN** a `gut/` addon directory exists and GUT test scripts under the project's test directory can be
  discovered and run by it

### Requirement: Test priority order matches the roadmap
Test coverage SHALL be added in the priority order `docs/Core_Architecture.md` §7 and
`docs/Propuesta_MVP.md` §8 fix: save robustness first, then progression milestones, then `LevelConfig`
parsing. This change SHALL add only save-robustness tests.

#### Scenario: No progression or LevelConfig tests exist yet
- **WHEN** the test directory is inspected after this change
- **THEN** it contains `SaveManager` robustness tests and no tests exercising `ProgressionManager`
  milestone logic or `LevelConfig` parsing (those remain for their respective later phases)

### Requirement: SaveManager robustness has automated coverage
`SaveManager`'s crash-safety behavior — missing file, corrupt JSON, unknown `save_version`, and that a
partially-written temp file never corrupts the previously-committed save — SHALL each have at least one
GUT test.

#### Scenario: Missing-file, corrupt-JSON, and unknown-version cases are each covered
- **WHEN** the `SaveManager` test suite is run
- **THEN** there is a passing test for the missing-file fallback, a passing test for the corrupt-JSON
  fallback, and a passing test for the unknown-`save_version` fallback, each asserting the documented
  default values are returned and no error is thrown

#### Scenario: A stray incomplete .tmp file never corrupts the committed save
- **WHEN** a valid `user://save_data.json` exists alongside a leftover, incomplete
  `user://save_data.json.tmp` (simulating a crash after the tmp write started but before rename) and
  `SaveManager` loads
- **THEN** it reads the valid committed file and is unaffected by the stray incomplete temp file
