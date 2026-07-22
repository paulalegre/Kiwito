## ADDED Requirements

### Requirement: JuiceComponent applies the exact Low-Stim parameter table
`JuiceComponent` SHALL read `SettingsManager.low_stim_mode` at the moment each feedback method is called and
apply the exact parameter table from `Direccion_de_Arte.md` §6.4: shake amplitude/duration ±6px/200ms in
standard mode vs ±3px/150ms in Low-Stim; squash-and-stretch scale amplitude ±12% in standard mode vs ±6% in
Low-Stim.

#### Scenario: Standard mode uses full amplitude
- **WHEN** `SettingsManager.low_stim_mode` is `false` and `play_shake()`/`play_feedback()` are called
- **THEN** the shake uses ±6px over 200ms and the scale punch uses ±12% amplitude

#### Scenario: Low-Stim mode uses reduced amplitude
- **WHEN** `SettingsManager.low_stim_mode` is `true` and `play_shake()`/`play_feedback()` are called
- **THEN** the shake uses ±3px over 150ms and the scale punch uses ±6% amplitude

### Requirement: AudioManager applies a softer SFX profile in Low-Stim mode
`AudioManager.play_sfx()` SHALL apply a reduced `SFX` bus output level when `SettingsManager.low_stim_mode`
is `true`, compared to standard mode.

#### Scenario: SFX plays quieter in Low-Stim mode
- **WHEN** `SettingsManager.low_stim_mode` is `true` and `play_sfx()` is called
- **THEN** the resulting playback level is lower than the same call would produce in standard mode

### Requirement: Low-Stim toggling takes effect immediately
Neither `JuiceComponent` nor `AudioManager` SHALL cache `SettingsManager.low_stim_mode` across calls; each
feedback/audio call SHALL reflect whatever the value is at that exact moment.

#### Scenario: Toggling mid-session applies on the very next call
- **WHEN** `SettingsManager.low_stim_mode` is toggled between two consecutive feedback calls
- **THEN** the second call already reflects the new mode's parameters, with no stale state from the first
