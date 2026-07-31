# hub-main-visual-presentation Specification

## Purpose

The Hub's background and its two interactive nodes (Caja de Globos, Libro Mágico) render final art
assets instead of procedural placeholders (`PlaceholderCircle`), at the sizes/hitbox contract
`Direccion_de_Arte.md` §5.2 mandates for Hub nodes. Introduced by `wire-hub-main-art-assets`.

## Requirements

### Requirement: Hub renders a background art layer
`features/hub_main/hub_main.tscn` SHALL render `design/hub_main/hub_bg.png` as a background node
positioned behind both interactive nodes, rather than the engine's default clear color.

#### Scenario: Hub scene shows background art
- **WHEN** `hub_main.tscn` is loaded and rendered
- **THEN** `hub_bg.png` is visible behind `CajaDeGlobos` and `LibroMagico`, with no default-gray
  background visible in the play area

### Requirement: Caja de Globos renders final art, not a procedural placeholder
`features/hub_main/caja_de_globos.tscn` SHALL render `design/hub_main/hub_balloon_box.png` in place of
the `PlaceholderCircle` node, while keeping the `tapped` signal and `HitboxComponent`-based input
handling unchanged.

#### Scenario: Caja de Globos shows final art
- **WHEN** `hub_main.tscn` is loaded and rendered
- **THEN** the Caja de Globos node displays `hub_balloon_box.png` and no longer renders a
  `PlaceholderCircle`

#### Scenario: Tap behavior is unaffected by the art swap
- **WHEN** a valid primary tap lands on the Caja de Globos's hitbox
- **THEN** `tapped` is still emitted exactly as before this change, launching the balloon cartridge via
  `hub_main.gd`'s existing connection

### Requirement: Libro Mágico renders final art, not a procedural placeholder
`features/hub_main/libro_magico.tscn` SHALL render `design/hub_main/hub_magic_book.png` in place of the
`PlaceholderCircle` node, while keeping the `tapped` signal and `HitboxComponent`-based input handling
unchanged.

#### Scenario: Libro Mágico shows final art
- **WHEN** `hub_main.tscn` is loaded and rendered
- **THEN** the Libro Mágico node displays `hub_magic_book.png` and no longer renders a
  `PlaceholderCircle`

#### Scenario: Tap behavior is unaffected by the art swap
- **WHEN** a valid primary tap lands on the Libro Mágico's hitbox
- **THEN** `tapped` is still emitted exactly as before this change, opening the Álbum de Stickers via
  `hub_main.gd`'s existing connection

### Requirement: Hub node hitboxes stay oversized relative to their displayed art
Per `Core_Architecture.md`'s hitbox rule, each Hub node's `HitboxComponent` collision shape SHALL remain
at least 30% larger in radius than that node's actual displayed sprite bounds after the art swap.

#### Scenario: Hitbox covers the full displayed sprite plus margin
- **WHEN** `hub_balloon_box.png` or `hub_magic_book.png` is displayed at its final in-scene scale
- **THEN** the corresponding `HitboxComponent`'s `CollisionShape2D` radius is at least 1.3× that
  sprite's visible radius at that scale
