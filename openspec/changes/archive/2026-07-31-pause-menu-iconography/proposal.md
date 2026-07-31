## Why

El chrome de pausa (`SceneDirector` + `PauseOverlay`, spec `pause-menu`) ya cumple el contrato de "dos
affordances icon-only, cero texto", pero `TappableIcon._draw()` solo pinta un círculo plano teñido con el
color de `palette.tres` — no hay ningún glifo que distinga el botón Home/pausa de "Continuar" o "Salir al
Hub". Para la audiencia de 3-8 años el color solo no es un canal suficiente (mismo principio ya aplicado a
los globos, que llevan un patrón no-cromático redundante junto al color). Sin un glifo, un niño no puede
diferenciar los tres botones por forma, solo por posición/color, lo que debilita el principio de cero-texto
del MVP. Este cambio pule visualmente esa capability (Propuesta_MVP.md §8, Fase 5 — "Audio y pulido
sensorial", la misma fase que introdujo `pause-menu`).

## What Changes

- `TappableIcon` gana la capacidad de dibujar un glifo plano encima del círculo base, seleccionable por
  `@export`, manteniendo Soft Vector Flat-Art (sin outlines, sin gradientes, vértices redondeados, solo
  color desde `palette.tres`).
- Tres glifos nuevos:
  - Botón Home/pausa (`PauseOverlay._home_button`): ícono de pausa (dos barras verticales). Se elige pausa
    y no una flecha de "back" porque el botón no navega directo — abre un menú intermedio (overlay con dos
    opciones), igual que la convención estándar de pausa en juegos.
  - "Continuar" (`PauseOverlay._continuar_button`): ícono de play (triángulo).
  - "Salir al Hub" (`PauseOverlay._salir_button`): ícono de casa, porque este botón sí navega directo al
    Hub.
- Ningún cambio de comportamiento: la lógica de pausa/resume/salida y la visibilidad condicional del botón
  Home no se tocan, solo el dibujo.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `pause-menu`: el requirement "Tapping Home pauses and shows a zero-text overlay" (y por extensión la
  noción de "affordance icon-only") se extiende para exigir que cada uno de los tres botones dibuje un
  glifo distintivo (pausa / play / casa) además del color, no solo un círculo plano.

## Impact

- Código: `shared/ui_elements/pause_menu/tappable_icon.gd` (agrega dibujo de glifo), posiblemente
  `pause_overlay.tscn`/`pause_overlay.gd` para pasar qué glifo usa cada instancia.
- Ningún cambio de UX/producto fuera de lo visual: no toca zero-text (los glifos son iconografía, no
  texto), zero-punishment, ni Low-Stim. No toca la tabla fija de colores/patrones de `MATCH_COLOR` (esos
  glifos son de chrome, no de juego).
- Sin cambios en autoloads, señales, ni en el contrato `MinigameBase`.
