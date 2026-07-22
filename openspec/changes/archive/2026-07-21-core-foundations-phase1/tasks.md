## 1. Directory topology

- [x] 1.1 Create `core/autoloads/`, `core/data/`, `core/utils/` (add `.gitkeep` to any left empty)
- [x] 1.2 Create `shared/contracts/`, `shared/components/`, `shared/ui_elements/`,
      `shared/ui_elements/transitions/`, `shared/global_assets/` (add `.gitkeep` to any left empty)
- [x] 1.3 Create `features/hub_main/` and `features/minigames/mg_balloons/{assets,components,resources}/`
      (add `.gitkeep` to any left empty)

## 2. Shared contracts

- [x] 2.1 Add `shared/contracts/MinigameBase.gd`: `class_name MinigameBase extends Node2D` with
      `session_finished(result: MinigameResult)` signal, `start(config: LevelConfig) -> void` (default
      `push_error`), `pause()`/`resume()` (toggle `get_tree().paused`), `stop()` (`queue_free()`)
- [x] 2.2 Add `shared/contracts/MinigameResult.gd`: `class_name MinigameResult extends RefCounted` with
      typed fields `correct_pops: int`, `failed_taps: int`, `duration: float`,
      `errors_by_color: Dictionary`
- [x] 2.3 Add `shared/contracts/LevelConfig.gd`: `class_name LevelConfig extends Resource` with a
      `MatchRule` enum (`MATCH_ANY`, `MATCH_COLOR`, `MATCH_SHAPE`, `MATCH_SIZE`, `MATCH_COUNT`) and a typed
      `match_rule: MatchRule` field

## 3. Autoload stubs

- [x] 3.1 Add `core/data/SaveManager.gd` (empty I/O-layer stub, no logic yet — Phase 2 fills this in)
- [x] 3.2 Add `core/autoloads/SettingsManager.gd` with `low_stim_mode: bool = false` and
      `signal low_stim_changed(enabled: bool)`
- [x] 3.3 Add `core/autoloads/ProgressionManager.gd` with `total_balloons_popped: int = 0`,
      `unlocked_stickers: Array = []`, and `signal sticker_unlocked(id: StringName)`
- [x] 3.4 Add `core/autoloads/AudioManager.gd` (empty service stub — Phase 5 fills this in)
- [x] 3.5 Add `core/autoloads/MetricsLogger.gd` (empty passive-listener stub — Phase 6 fills this in)
- [x] 3.6 Verify none of the five stub scripts reference another autoload singleton inside `_init()`

## 4. SceneDirector and transition

- [x] 4.1 Add `shared/ui_elements/transitions/fade_transition.tscn` + `.gd`: full-screen
      `ColorRect`/`CanvasLayer` fade with a start/finish signal-driven API
- [x] 4.2 Add `core/autoloads/SceneDirector.gd`: persistent container/slot node reference, API to load a
      target `PackedScene` as a child under the container (never `change_scene_to_file`/`_to_packed`),
      driving the fade transition so the target is ready before the fade uncovers it
- [x] 4.3 Implement `SceneDirector.goto_hub()` and a `launch_minigame(scene: PackedScene, config:
      LevelConfig)`-shaped entry point that instantiates the cartridge, calls `start(config)`, and connects
      `session_finished` back for teardown
- [x] 4.4 Implement return-to-Hub path: call `stop()` on the active cartridge before/during the transition
      back so it's freed with no orphaned nodes

## 5. Register autoloads and boot path

- [x] 5.1 Register the six autoloads in `project.godot` in order: `SaveManager`, `SettingsManager`,
      `ProgressionManager`, `AudioManager`, `MetricsLogger`, `SceneDirector`
- [x] 5.2 Add a minimal placeholder Hub scene at `features/hub_main/hub_main.tscn` (empty `Node2D`, no
      Caja de Globos / Libro Mágico / art yet)
- [x] 5.3 Point the project's main scene / boot flow so it loads through `SceneDirector.goto_hub()` to the
      placeholder Hub — `run/main_scene="res://root.tscn"`, a minimal `res://root.gd`/`.tscn` boot node
      (lives at res:// root, not under core/shared/features, since it's engine plumbing analogous to
      `project.godot`/`icon.svg`, not domain code) whose sole job is `SceneDirector.goto_hub()`

## 6. Verification and prototype cleanup

- [x] 6.1 Run the project (`mcp__godot__run_project` + `get_debug_output`): confirm it boots directly to the
      placeholder Hub with no console errors and the six autoloads present in the declared order —
      `mcp__godot__run_project`/`get_debug_output` proved stateless in this session (spawned a window it
      then lost track of); verified instead via direct headless invocation
      (`Godot_v4.7.1-stable_win64_console.exe --path . --headless --quit-after 60`), zero errors. Required
      first running `--headless --editor --quit` once to rebuild `.godot/global_script_class_cache.cfg`,
      which was stale/empty and caused `Could not find type "MinigameBase"/"LevelConfig"/"MinigameResult"`
      parse errors on the new `class_name` scripts until rebuilt.
- [x] 6.2 Delete `scripts/main.gd`, `scripts/globo.gd`, and their now-orphaned scene(s) under `scenes/`
      (and the now-empty `scripts/`/`scenes/` directories themselves — not part of the target topology)
- [x] 6.3 Re-run the project after deletion to confirm the boot path still works with the prototype removed
      — re-ran the same headless invocation after deleting `scripts/`/`scenes/`, zero errors
