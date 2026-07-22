## ADDED Requirements

### Requirement: Home button appears only during an active minigame session
`SceneDirector` SHALL show its Home/pause button only while `_active_minigame` is set, and hide it while the
Hub is showing.

#### Scenario: Home button visible during a minigame session
- **WHEN** a minigame has been launched via `SceneDirector.launch_minigame()` and no session has finished yet
- **THEN** the Home button is visible

#### Scenario: Home button hidden in the Hub
- **WHEN** the Hub is the active scene (no minigame running)
- **THEN** the Home button is hidden

### Requirement: Tapping Home pauses and shows a zero-text overlay
Tapping the Home button SHALL set `get_tree().paused = true` and show a pause overlay with exactly two
icon-only affordances (Continuar, Salir al Hub) — no text.

#### Scenario: Home tap pauses the game and opens the overlay
- **WHEN** a valid primary tap lands on the Home button
- **THEN** `get_tree().paused` becomes `true` and the pause overlay becomes visible with its two icon
  affordances, no text

### Requirement: Continuar resumes exactly where paused
Tapping "Continuar" on the pause overlay SHALL set `get_tree().paused = false` and hide the overlay, leaving
the minigame's state unchanged from the moment it was paused.

#### Scenario: Continuar resumes without altering state
- **WHEN** "Continuar" is tapped while paused
- **THEN** `get_tree().paused` becomes `false`, the overlay hides, and the minigame continues from its
  paused state with no data lost

### Requirement: Salir al Hub returns via the existing teardown path
Tapping "Salir al Hub" on the pause overlay SHALL first unpause the tree, then invoke
`SceneDirector.goto_hub()`, reusing the already-shipped minigame teardown and fade transition unmodified.

#### Scenario: Salir al Hub unpauses before transitioning
- **WHEN** "Salir al Hub" is tapped while paused
- **THEN** `get_tree().paused` becomes `false` before the fade transition begins, and the Hub becomes the
  active scene with the minigame torn down (no orphaned nodes)

### Requirement: Home button and pause overlay keep responding while paused
The Home button and pause overlay SHALL use `process_mode = PROCESS_MODE_ALWAYS` so they remain responsive
even while `get_tree().paused` is `true`.

#### Scenario: Overlay remains interactive while the tree is paused
- **WHEN** `get_tree().paused` is `true` and the pause overlay is visible
- **THEN** its "Continuar" and "Salir al Hub" affordances still receive and process input normally

### Requirement: Scene transitions fade to cream, not black
`shared/ui_elements/transitions/fade_transition.gd` SHALL fade using the `cream_fade` color resolved from
`shared/global_assets/palette.tres`, never a hardcoded black or any other literal color value.

#### Scenario: Fade uses the palette's cream color
- **WHEN** a scene transition's fade is inspected mid-transition
- **THEN** its color matches `palette.tres`'s `cream_fade` entry, not `Color(0, 0, 0, ...)`
