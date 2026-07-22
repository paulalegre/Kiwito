# scene-director Specification

## Purpose

Makes `SceneDirector` the only code path allowed to change what's on screen, using a persistent
container/slot so Core autoloads and any playing music survive a Hub↔minigame transition, and a fade that
always hides load time. This exists to guarantee the zero-friction, zero-punishment UX invariants a young
child depends on (`docs/Propuesta_MVP.md` §5): no loading screen, no scene-change jump cut, and no orphaned
minigame nodes left behind when a session ends and the app returns to the Hub.

## Requirements

### Requirement: SceneDirector is the sole scene-change authority
`SceneDirector` (autoload) SHALL be the only code in the project that changes the active scene. No minigame
and no Hub code SHALL call `get_tree().change_scene_to_file()` / `change_scene_to_packed()` directly.

#### Scenario: No direct scene-change call outside SceneDirector
- **WHEN** the codebase is searched for `change_scene_to_file` or `change_scene_to_packed`
- **THEN** every match is inside `SceneDirector`'s script

### Requirement: Persistent container/slot loading pattern
`SceneDirector` SHALL load the Hub and minigames as child scenes under a persistent container node, never by
replacing the entire scene tree, so that Core autoloads and any running music survive a Hub↔minigame
transition.

#### Scenario: Container survives a scene swap
- **WHEN** `SceneDirector` swaps the active child scene (e.g. Hub → minigame)
- **THEN** the persistent container node remains in the tree and autoload singletons are unaffected

### Requirement: Fade transition covers load time
Every scene change SceneDirector performs SHALL be covered by a fade transition that hides the load time
of the destination scene; the destination scene SHALL be preloaded/instantiated before the outgoing fade
completes, so no loading screen or abrupt cut is ever visible.

#### Scenario: Transition hides load with no visible jump
- **WHEN** `SceneDirector` is asked to switch from the current scene to a target scene
- **THEN** it starts the fade-out, prepares the target scene during the fade, and only swaps the visible
  content once the screen is fully covered by the transition

### Requirement: Minigame teardown on stop
When returning to the Hub, `SceneDirector` SHALL call `stop()` on the active minigame cartridge to free it
(`queue_free`) before or during the transition back, leaving no orphaned nodes once the Hub is shown again.

#### Scenario: No orphaned nodes after returning to Hub
- **WHEN** a minigame cartridge session ends and `SceneDirector` returns to the Hub
- **THEN** the freed cartridge's node subtree no longer exists in the tree (verifiable via the Godot
  Monitor's orphan-node count)
