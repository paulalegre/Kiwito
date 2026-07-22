# project-directory-topology Specification

## Purpose

TBD - created by archiving change core-foundations-phase1. Update Purpose after archive.

## Requirements

### Requirement: Feature-sliced directory topology
The project SHALL organize `res://` by domain (Core/Shared/Features), not by file type. The following
directories SHALL exist: `core/autoloads/`, `core/data/`, `core/utils/`, `shared/contracts/`,
`shared/components/`, `shared/ui_elements/`, `shared/global_assets/`, `features/hub_main/`,
`features/minigames/mg_balloons/` (with `assets/`, `components/`, `resources/` subfolders).

#### Scenario: Fresh checkout has the full topology
- **WHEN** the repository is inspected after this change lands
- **THEN** every directory listed above exists under `res://`, including empty ones (tracked via
  `.gitkeep` where no file yet lives in them)

### Requirement: `core/` contains no visual or gameplay-rule code
`core/autoloads/`, `core/data/`, and `core/utils/` SHALL contain only singleton/state/persistence-adjacent
code and stateless utility functions — no `Node2D`-based gameplay scenes, no minigame-specific logic, and
no hardcoded level/balance values.

#### Scenario: Utility script under core/utils is stateless
- **WHEN** a script is added under `core/utils/`
- **THEN** it exposes only `static func` members and declares no instance state

### Requirement: `shared/` contains no domain-specific logic
`shared/contracts/`, `shared/components/`, `shared/ui_elements/`, and `shared/global_assets/` SHALL contain
only code, components, or assets usable across more than one feature — nothing that hardcodes a specific
minigame's data (e.g. balloon-specific values).

#### Scenario: Component under shared/components has no parent dependency
- **WHEN** a node script is added under `shared/components/`
- **THEN** it does not reference a specific parent node type or path, so it can be attached under any
  compatible node

### Requirement: `mg_balloons` isolation
Nothing inside `features/minigames/mg_balloons/` SHALL be referenced, imported, or invoked by any other
minigame folder under `features/minigames/`.

#### Scenario: No cross-minigame reference exists
- **WHEN** the codebase is searched for references to a path under `features/minigames/mg_balloons/`
- **THEN** no matching reference originates from outside `features/minigames/mg_balloons/`
