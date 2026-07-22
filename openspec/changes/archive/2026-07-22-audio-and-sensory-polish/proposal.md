## Why

`docs/Propuesta_MVP.md` §8 item 5 ("Audio y pulido sensorial") is next in the roadmap, and per that same
document, Phase 4 is the point where child validation could begin — Phase 5 is what makes that validation
sensorially honest: `AudioManager` is still an empty stub, `SettingsManager.low_stim_mode` has no consumer
anywhere despite being a mandatory MVP contract (`Direccion_de_Arte.md` §6.4), the escalating-help system
that replaces punitive freezing (`GDD_MVP.md` §3) doesn't exist, and the pause menu named in the MVP's
frozen scope (`Propuesta_MVP.md` §3) was flagged as a roadmap gap with no assigned phase during Change #4
and needs a home. Building this now also surfaced a real, previously-unnoticed bug worth fixing while
touching this code: `fade_transition.gd` fades to black, but `Direccion_de_Arte.md` §7 explicitly requires
fading to cream (`#FBF3E4`) to avoid an anxiogenic full-black cut for a young child.

## What Changes

- `AudioManager` becomes a real service: 3 buses (Music/SFX/VO), VO ducking of Music (~-12dB) with
  restore-on-finish, one-VO-at-a-time policy, a small round-robin `AudioStreamPlayer` pool for SFX, and a
  `play_sfx`/`play_vo`/`set_music`/`stop_vo` API that warns (never crashes) on an unregistered id — since no
  real audio asset files exist in the project yet, this change ships the full service wired to an
  intentionally sparse/placeholder sound registry, ready to receive real `.ogg` files later with zero code
  changes (same pattern Change #3 used for `palette.tres` before all pattern textures existed).
- The Low-Stim contract (`Direccion_de_Arte.md` §6.4's exact parameter table) gets its first real consumers:
  `JuiceComponent` and `AudioManager` both react to `SettingsManager.low_stim_changed`.
- `features/minigames/mg_balloons/` gains the "Meta Persistente" goal box (never built in Phase 3) and
  2-level escalating help (`GDD_MVP.md` §3, `Direccion_de_Arte.md` §7) triggered by detected frustration (3
  incorrect taps in <1.5s, or 4s with no correct tap) — never freezing input, always advancing toward
  success — plus a juice pass on the balloon's own correct/incorrect feedback against the feedback
  vocabulary table.
- A global pause menu: a Home-icon button (top-left, +30% hitbox, visible only while a minigame is active)
  opening a zero-text overlay with exactly two icon affordances (Continuar / Salir al Hub), owned by
  `SceneDirector` as persistent chrome alongside its existing fade transition.
- **Bug fix, bundled in while touching this exact chrome code:** `fade_transition.gd` changes from a
  hardcoded `Color(0,0,0,alpha)` fade-to-black to reading a new non-gameplay `cream_fade` entry added to
  `palette.tres`, per `Direccion_de_Arte.md` §7's explicit requirement.

## Capabilities

### New Capabilities
- `audio-manager`: the `AudioManager` service contract — buses, ducking, VO policy, SFX pooling, the
  warn-don't-crash API.
- `low-stim-contract`: the exact, verifiable Low-Stim parameter table applied to `JuiceComponent` and
  `AudioManager`.
- `mg-balloons-sensory-polish`: the goal box, 2-level escalating help, and correct/incorrect juice pass,
  scoped to the already-shipped `mg_balloons` cartridge.
- `pause-menu`: the Home button, pause overlay, `SceneDirector` wiring, and the fade-to-cream fix.

### Modified Capabilities
- None. `minigame-contracts`, `match-rule-engine`, `mg-balloons-cartridge`, and `scene-director` are all
  consumed unmodified — this change only adds new requirements layered on top (a new goal box node, new
  escalating-help behavior, a new pause overlay sibling to the existing fade transition); none of those
  specs' existing requirements change shape. `mg_balloons.gd` itself is extended as an implementation detail
  inside its own strictly-isolated feature folder, not as a change to what `mg-balloons-cartridge`'s spec
  already promises.

## Impact

- Modified: `core/autoloads/AudioManager.gd` (stub → real service), `shared/components/juice_component.gd`
  (Low-Stim-aware amounts + missing grey-tint on incorrect taps), `shared/ui_elements/transitions/
  fade_transition.gd`/`.tscn` (black → `cream_fade`), `shared/global_assets/Palette.gd`/`palette.tres` (new
  `cream_fade` entry), `core/autoloads/SceneDirector.gd` (owns the new pause overlay + Home button),
  `features/minigames/mg_balloons/mg_balloons.gd`/`.tscn` (goal box, frustration detection, escalating help).
- New: `shared/ui_elements/pause_menu/` (Home button + overlay), goal-box node/script under
  `features/minigames/mg_balloons/`.
- Out of scope, deferred to their already-assigned later phases: `MetricsLogger`/telemetry (Phase 6),
  actually recording/producing real audio assets (a follow-up asset pass, not blocked by this change), any
  second minigame cartridge. Also explicitly deferred as extra scope beyond this phase's own remit: the more
  elaborate confetti/level-end and sticker-unlock-sweep animations from the feedback vocabulary table — this
  change focuses the juice pass on the highest-frequency interactions (pop/incorrect-tap) and the Hub↔
  minigame transition color bug, not a full re-animation of every row in that table.
