# mg-balloons-sensory-polish Specification

## Purpose

Layers the sensory polish that Phase 3 deliberately scoped out of `mg-balloons-cartridge` (consumed
unmodified here) onto the already-shipped balloon cartridge: the "Meta Persistente" goal box showing the
active `MATCH_COLOR` target, and the 2-level escalating-help system that operationalizes `GDD_MVP.md` §3's
non-punitive frustration response — detect frustration from tap cadence, then nudge the child toward success
with pulses, halos, and a VO cue, never freezing or discarding input — plus a correct/incorrect juice pass
that brings balloon feedback in line with `Direccion_de_Arte.md` §7's feedback vocabulary table.

## Requirements

### Requirement: Persistent goal box shows the current MATCH_COLOR target
During a `MATCH_COLOR` session, `mg_balloons` SHALL display a static goal box in a fixed screen corner
showing the current target color, tinted from `shared/global_assets/palette.tres` (never a literal hex
value), visible for the whole session.

#### Scenario: Goal box reflects the active target color
- **WHEN** a `MATCH_COLOR` session starts with `target_color_id == &"red_coral"`
- **THEN** the goal box renders tinted with `red_coral` from `palette.tres`

### Requirement: Frustration detection triggers level-1 help
`mg_balloons` SHALL detect frustration when either 3 incorrect taps occur within 1.5 seconds, or 4 seconds
elapse with no correct tap, and SHALL respond with level-1 help: the goal box pulses (scale 1.0→1.12→1.0)
with an amber halo, plus a VO cue via `AudioManager.play_vo()`. This SHALL be repeatable each time
frustration is freshly detected.

#### Scenario: Three incorrect taps within 1.5s trigger level-1 help
- **WHEN** 3 incorrect taps land within a 1.5-second window
- **THEN** the goal box pulses with an amber halo and a VO cue is requested

#### Scenario: 4 seconds with no correct tap triggers level-1 help
- **WHEN** 4 seconds elapse since the last correct tap (or session start) with no correct tap in between
- **THEN** the goal box pulses with an amber halo and a VO cue is requested

### Requirement: Sustained frustration escalates to level-2 help
If frustration persists after level-1 help has fired, `mg_balloons` SHALL escalate to level-2 help: every
currently-alive target-color `Balloon` SHALL receive a non-chromatic halo and a slow bounce highlight on a
~1.5 second cycle, with no accompanying audio.

#### Scenario: Sustained frustration highlights target balloons
- **WHEN** frustration remains detected after level-1 help has already fired once
- **THEN** all currently-alive target-color balloons show a non-chromatic halo + slow bounce, and no
  additional sound plays

### Requirement: A correct tap resets frustration state
Any correct tap SHALL immediately reset the frustration-detection window and clear any active level-1 or
level-2 escalation.

#### Scenario: Correct tap clears active escalation
- **WHEN** a correct tap lands while level-2 help is active
- **THEN** the target-balloon highlight stops and the frustration counters reset

### Requirement: Escalating help never blocks or discards input
At no point during level-1 or level-2 help SHALL the screen freeze, ignore, or discard a valid tap; the
level SHALL keep advancing toward its win condition unaffected by active help.

#### Scenario: Taps remain fully responsive during escalation
- **WHEN** level-1 or level-2 help is active
- **THEN** every valid tap on any balloon is still processed normally (correct pop or neutral incorrect
  feedback), with no dropped or delayed input

### Requirement: Correct/incorrect juice matches the feedback vocabulary table
A correct tap SHALL produce feedback consistent with `Direccion_de_Arte.md` §7's "Toque válido" row
(compress-then-release scale animation). An incorrect tap SHALL produce a ±6px/200ms shake in standard mode
(±3px/150ms in Low-Stim, per the `low-stim-contract` capability) plus a brief warm-grey tint (from
`palette.tres`'s `warm_grey_tint` entry, never a literal hex value) over the same duration as the shake.

#### Scenario: Incorrect tap shows the warm-grey tint
- **WHEN** an incorrect tap lands on a balloon
- **THEN** the balloon briefly tints toward `palette.tres`'s `warm_grey_tint` color and returns to normal
  within the shake's duration
