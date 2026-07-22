# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Moss Guardian (`MossGame`) — a Godot 4.x 2D educational minigame platform for early childhood (ages 3-8),
targeting tablets (Android/iPadOS), validated locally on PC. The product is the reusable **platform**
("cartridge" architecture), not any single minigame — the first cartridge is a color-discrimination
balloon-popping game ("Explotaglobos").

**Current state: early bootstrap.** `scripts/main.gd` and `scripts/globo.gd` are a rough prototype
(untyped-by-convention, flat `scenes/`/`scripts/` layout) that predates the architecture below. There is
no `core/`/`shared/`/`features/` split yet, no autoloads, no GUT tests, and `project.godot` currently uses
`renderer/rendering_method="mobile"` with the `d3d12` Windows driver — not yet the `GL Compatibility`
renderer mandated by the architecture doc. Do not assume the docs describe already-built code; check the
actual files before relying on either.

## Source of truth: `docs/`

Design and architecture decisions are frozen in three documents — read the relevant one before making
related changes rather than re-deriving decisions from code:

- `docs/Propuesta_MVP.md` — executive summary: scope (in/out), roadmap phases, risks.
- `docs/GDD_MVP.md` — game design: core loop, minigame mechanics (`MatchRule` engine), progression/stickers,
  save schema.
- `docs/Core_Architecture.md` (v3.0) — technical architecture: scene/node patterns, communication rules,
  directory topology, autoload contracts. **Normative for all GDScript.**
- `docs/Direccion_de_Arte.md` (v1.3) — art direction: palette, shape language, typography, motion budget,
  Low-Stim contract. Normative for all visual assets and scenes.

## Running / testing

No Godot CLI is on PATH in this environment. The project is driven through the `mcp__godot__*` MCP tools
(`run_project`, `get_debug_output`, `stop_project`, `create_scene`, `add_node`, `load_sprite`,
`get_project_info`) — use these rather than shelling out to a `godot` binary. There is no test suite yet;
`docs/Core_Architecture.md` §7 specifies GUT (Godot Unit Test) as the intended framework for pure-logic
tests (save robustness, progression milestones, `LevelConfig` parsing) once those systems exist, prioritized
in that order.

## Architecture rules (binding for all new GDScript)

### Cartridge contract (`MinigameBase`)
Minigames are "cartridges" injected into a Core "console," not standalone scenes. The *only* sanctioned
inheritance in the project is one level deep, from a thin `MinigameBase` (`extends Node2D`) exposing
`start(config)` (required override), `pause()`, `resume()`, `stop()`, and a `session_finished(result)`
signal. A cartridge never references the Host, another minigame, or anything outside its own subtree —
composition over inheritance otherwise (no deep hierarchies; behavior via component nodes like
`FloatUpwardComponent`, `HitboxComponent`).

### Communication: "Signals up, calls down"
- Child → parent (local): child emits a local signal, parent connects it. Default for most communication.
- Parent → child: direct typed method call (e.g. `minigame.start(config)`).
- Minigame → Core (cross-domain): still a local signal on the cartridge that the Host connects when
  instantiating it — never a global autoload signal. Results travel as a typed `MinigameResult`
  (`correct_pops`, `failed_taps`, `duration`, `errors_by_color`).
- Global fan-out only: a domain autoload with a typed signal, reserved for real one-to-many broadcast
  (e.g. `SettingsManager.low_stim_changed`, `ProgressionManager.sticker_unlocked`).
- **A global string-based EventBus is explicitly forbidden.**

### Data-driven design
No level/balance values (colors, ascent speed, spawn rate, entity counts) are hardcoded in scripts. Every
minigame's tunables live in a `Resource` subclass (`LevelConfig.tres`); the matching rule itself is data
(`MatchRule` enum: `MATCH_ANY`, `MATCH_COLOR`, later `MATCH_SHAPE`/`MATCH_SIZE`/`MATCH_COUNT`) evaluated by
one generic `matches()` function — adding an educational dimension means adding a `.tres`, never touching
scripts. `.tres`/`ResourceLoader` is reserved for trusted `res://` design config only; anything the user's
save data touches is JSON via `FileAccess` (`user://save_data.json`), never `.tres` (avoids insecure
resource deserialization). Save writes are atomic (write `.tmp`, then rename) and versioned
(`save_version`), with fallback to defaults on missing/corrupt/unknown-version data — never crash on boot.

### GDScript conventions
Static typing is mandatory on variables, params, and returns. `snake_case` for variables/functions,
`PascalCase` for nodes/classes, `SCREAMING_SNAKE_CASE` for constants. No chained relative node paths
(`get_parent().get_node()`) — inject node references via `@export` from the Inspector.

### Directory topology (target — not yet built)
Feature-sliced, not grouped by file type:
- `core/autoloads/` — singletons, one domain each (`ProgressionManager`, `SettingsManager`, `AudioManager`,
  `MetricsLogger`, `SceneDirector`). Init order is a real dependency, fixed in
  `Core_Architecture.md` §5.1: `SaveManager` → `SettingsManager`/`ProgressionManager` →
  `AudioManager`/`MetricsLogger`/`SceneDirector`. No autoload touches another in `_init()`; cross-autoload
  wiring happens in `_ready()`.
- `core/data/` — `SaveManager.gd`, the sole persistence I/O layer (no game rules).
- `core/utils/` — stateless static-method utilities only.
- `shared/contracts/` — `MinigameBase.gd`, `MinigameResult.gd` (`RefCounted`), `LevelConfig.gd` (`Resource`).
- `shared/components/` — plug-and-play logic nodes, no dependency on a specific parent.
- `shared/ui_elements/` — pause button, screen transitions, generic modals.
- `shared/global_assets/` — assets used by 100% of the project (fonts, global palette `.tres`, Hub music).
- `features/hub_main/` — main menu + sticker album.
- `features/minigames/mg_balloons/` — first cartridge; **strict isolation**: nothing in this folder may be
  referenced by another minigame.

`SceneDirector` (autoload) is the *only* code allowed to change scenes — minigames and the Hub never call
`get_tree().change_scene_*` directly; a minigame loads as a child under a persistent container so Core
autoloads/music survive, behind a fade transition that covers load time.

### Input handling (child-audience specific)
Hitboxes must be 30% larger than the visible sprite. Filter secondary touches
(`event.index == 0`) to reject palm contact. `Emulate Touch From Mouse` is enabled so PC and tablet share
one input code path (do not also enable `Emulate Mouse From Touch`). Each interactive node detects its own
touch via its own `Area2D`'s `input_event` (or a shared `HitboxComponent`) — no manual picking in a global
`_input`. A handled tap calls `get_viewport().set_input_as_handled()` so overlapping hitboxes don't
double-fire.

### Product/UX invariants
Zero text (all instruction is audio + visual), zero punishment (no game-over/scoring; wrong taps get
neutral feedback and the level still resolves positively), escalating non-blocking help on detected
frustration, and a mandatory Low-Stim mode (`SettingsManager.low_stim_mode`) that autoload consumers
(`AudioManager`, juice components) must react to — see `Core_Architecture.md` §4 and
`Direccion_de_Arte.md` §6.4 for the exact Low-Stim parameter contract (particles, flashes, saturation,
durations). Feedback on any valid touch must land in under 100ms.

## Art rules (binding for all visual assets/scenes)

- **No literal hex colors in scenes or scripts.** All color comes from `res://shared/global_assets/palette.tres`.
- Soft Vector Flat-Art: no outlines, no gradients (only exception: a distant background sky layer), no
  internal texture/grain. Volume is faked via flat overlapping shapes (max 2 tones per object). All
  vertices rounded, no exact 90° angles or sharp points.
- The 4 `MATCH_COLOR` game colors are a fixed luminance staircase (ΔL ≥ 0.12) so they stay distinguishable
  in grayscale, and each carries a redundant non-chromatic pattern (stars/stripes/dots/zigzag) — color is
  never the only channel for a rule. A color without an assigned pattern is a data error.
  See `Direccion_de_Arte.md` §2.2 for the exact color/pattern table.
- `design/globo.png` is a stale placeholder (has outline/gradient/specular highlight) marked for rework;
  don't treat its current visual finish as the style target — see `Direccion_de_Arte.md` §12.
- Facial "prefab" (dot eyes in ink `#3B3028`, no sclera/highlight, simple mouth arc) is the default for all
  characters/stickers; deviating requires a documented reason (§3.3).
