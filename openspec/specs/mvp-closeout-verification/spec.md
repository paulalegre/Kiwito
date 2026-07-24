# mvp-closeout-verification Specification

## Purpose

A project-wide re-verification pass run at MVP closeout to confirm invariants established across earlier
phases (scene teardown, hitbox sizing, zero-text, non-chromatic color redundancy, Low-Stim perceptibility)
still hold now that Phase 5's full juice pass has shipped — catching regressions introduced by later work
rather than re-deriving the rules themselves.

## Requirements

### Requirement: No orphaned nodes across repeated Hub↔minigame cycles
Repeating the Hub→minigame→Hub cycle multiple times in succession SHALL leave the engine's orphan node
count unchanged from before the first cycle began, verifying `scene-director`'s existing single-cycle
teardown guarantee holds under repetition, not just once.

#### Scenario: Orphan count stays flat across repeated cycles
- **WHEN** the Hub→minigame→Hub cycle is repeated several times in succession
- **THEN** the orphan node count measured after the last cycle equals the orphan node count measured before
  the first cycle

### Requirement: Interactive elements meet the extended-hitbox rule project-wide
Every interactive on-screen element shipped through Phase 5 (balloons, pause-menu icons, Hub tappables,
sticker-album close affordance) SHALL have a touch/collision area at least 30% larger than its visible
sprite, per `CLAUDE.md`'s input-handling rule.

#### Scenario: Every interactive element's hitbox is audited
- **WHEN** each interactive element shipped so far is inspected for its hitbox-to-sprite size ratio
- **THEN** every one is at least 30% larger than its visible sprite, and any violation found is fixed as
  part of this change

### Requirement: Zero on-screen text project-wide
No shipped scene (Hub, minigame, pause menu, sticker album) SHALL render a `Label`, `RichTextLabel`, or
other text node as an instructional or navigational element, per the zero-text product invariant.

#### Scenario: No instructional text node exists in any shipped scene
- **WHEN** all shipped `.tscn` files are inspected for text-rendering nodes used for instruction or
  navigation
- **THEN** none are found, and any violation found is fixed as part of this change

### Requirement: Non-chromatic redundancy holds for every MATCH_COLOR game color
Every one of the four `MATCH_COLOR` game colors SHALL still carry its assigned non-chromatic pattern
wherever it is used to convey a rule-relevant distinction (balloons, goal box), per the fixed color/pattern
table in `Direccion_de_Arte.md` §2.2.

#### Scenario: Every game-color use has its redundant pattern
- **WHEN** every place a `MATCH_COLOR` game color is used to signal a rule-relevant distinction is
  inspected
- **THEN** its assigned non-chromatic pattern is present alongside the color

### Requirement: Low-Stim mode remains perceptibly different across all shipped juice
Toggling `SettingsManager.low_stim_mode` SHALL still produce a difference an adult can perceive in under 5
seconds across every shipped feedback path (balloon pop/shake, escalating help, transitions), per
`Direccion_de_Arte.md` §6.4's acceptance bar, re-verified now that Phase 5 has shipped its full juice pass.

#### Scenario: Low-Stim toggle is perceptible across the full shipped surface
- **WHEN** `low_stim_mode` is toggled and each shipped feedback path is triggered in both states
- **THEN** an adult observer perceives a difference within 5 seconds for every one of them
