## ADDED Requirements

### Requirement: Three independent audio buses
`AudioManager` SHALL rely on three audio buses — `Music`, `SFX`, `VO` — each with independently controllable
volume, as declared in the project's audio bus layout.

#### Scenario: Buses are independently addressable
- **WHEN** the project's audio bus layout is inspected
- **THEN** `Music`, `SFX`, and `VO` buses exist as children of `Master`, each independently controllable

### Requirement: SFX playback via a round-robin player pool
`AudioManager.play_sfx(sfx_id: StringName)` SHALL dispatch playback through a fixed pool of
`AudioStreamPlayer` nodes assigned to the `SFX` bus, cycling round-robin, so that rapidly overlapping calls
each play audibly instead of one cutting another off.

#### Scenario: Overlapping SFX calls do not cut each other off
- **WHEN** `play_sfx()` is called twice in quick succession with a registered id
- **THEN** both calls are assigned to different pool players and both play to completion

### Requirement: VO playback ducks Music and never overlaps itself
`AudioManager.play_vo(vo_id: StringName)` SHALL attenuate the `Music` bus by approximately -12dB via a
`Tween` while a VO clip plays, and restore it when the VO player's `finished` signal fires. At most one VO
clip SHALL play at a time; a new `play_vo()` call while one is active SHALL immediately stop the current
clip and start the new one.

#### Scenario: Music ducks during VO and restores after
- **WHEN** `play_vo()` is called with a registered id
- **THEN** the `Music` bus volume drops by ~12dB for the duration of playback and returns to its prior level
  once the clip finishes

#### Scenario: A second VO call interrupts the first
- **WHEN** `play_vo()` is called while a previous VO clip is still playing
- **THEN** the previous clip stops immediately and the new clip begins with no overlap

### Requirement: Unregistered sound ids never crash or block
`AudioManager.play_sfx()`, `play_vo()`, and `set_music()` SHALL log a `push_warning` and play nothing when
called with an id not present in the sound registry. They SHALL NOT crash, throw, or block the caller.

#### Scenario: Missing id is a safe no-op
- **WHEN** `play_sfx()`, `play_vo()`, or `set_music()` is called with an id that has no registered
  `AudioStream`
- **THEN** a `push_warning` is logged, nothing plays, and execution continues normally
