## Why

Los glifos del pause-menu (`pause-menu-iconography`, ya archivado) se dibujan con primitivas
(`draw_polygon`/`draw_circle`/`draw_rect`) directamente en `TappableIcon.gd`. Es una solución de arranque
razonable para no bloquear la iteración de UX, pero produce formas más toscas que un pictograma diseñado a
mano, y `design/Assets_Pendientes.md` §2 ya trackea estos tres íconos como arte pendiente de un diseñador
humano. Este change deja el código listo para consumir esas texturas en cuanto existan — sin bloquear en
que ya existan — y corrige una ambigüedad de nomenclatura en el checklist antes de que un diseñador la lea
mal. Propuesta_MVP.md §8, Fase 5 ("Audio y pulido sensorial"), la misma fase de la que salió `pause-menu`.

## What Changes

- `TappableIcon` reemplaza su `enum Glyph` y el dibujo procedural por un único `@export var glyph_texture:
  Texture2D`, renderizado con `draw_texture_rect(glyph_texture, rect, false, glyph_color)` — reemplazo
  limpio del código de dibujo anterior, no una rama condicional conviviendo con la nueva (mismo patrón que
  el proyecto ya siguió con `PlaceholderCircle.gd` al recibir el arte real del Hub).
- `pause_overlay.tscn` referencia las tres texturas finales por ruta (`design/ui/ui_icon_pause.png`,
  `ui_icon_continue.png`, `ui_icon_exit.png`) en vez del `glyph` enum.
- `design/Assets_Pendientes.md` §2 renombra su entrada del botón Casa de `ui_icon_home.png` a
  `ui_icon_pause.png`: el nombre pasa a describir el pictograma real (glifo de **pausa**), no el
  identificador de código del botón (`_home_button` de `SceneDirector`) que lo consume. El pictograma de
  **casa** va en `ui_icon_exit.png` (Salir al Hub), y el de **play** en `ui_icon_continue.png`.
- Requisito de entrega explícito para el diseñador: los tres PNG deben ser máscara alfa (silueta blanca
  opaca sobre transparente, sin color horneado), para poder seguir tiñéndose en runtime con `cream_fade` vía
  `modulate` — igual regla de "color siempre desde `palette.tres`" que ya rige el resto del proyecto.
- **BREAKING** (interno, no afecta jugadores): el `@export var glyph: Glyph` de `TappableIcon` desaparece;
  cualquier escena que lo usara debe migrar a `glyph_texture`. Solo `pause_overlay.tscn` lo usa hoy.

**Fuera de alcance:**
- Generar los PNG finales — corresponde a un diseñador humano fuera de este flujo de OpenSpec.
- El tamaño de `icon_radius` en `pause_overlay.tscn` (hoy 40/48) vs. los tamaños objetivo del checklist
  (140/96, `Direccion_de_Arte.md` §5.2) — gap preexistente, tracked aparte, no se toca aquí para no mezclar
  la migración de renderizado con un cambio de tamaño de touch target.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `pause-menu`: el requirement "Pause-menu affordances render a distinct glyph" (añadido en
  `pause-menu-iconography`) cambia su contrato de "dibuja un glifo con primitivas de `_draw()`" a "renderiza
  una textura de glifo (`Texture2D`) tintada vía `modulate`".

## Impact

- Código: `shared/ui_elements/pause_menu/tappable_icon.gd` (reemplazo del enum/dibujo procedural),
  `shared/ui_elements/pause_menu/pause_overlay.tscn` (wiring a las tres texturas).
- Documentación de proceso: `design/Assets_Pendientes.md` §2 (nota de mapeo archivo→pictograma).
- Bloqueo externo: el wiring final a `res://design/ui/ui_icon_*.png` y la verificación visual no pueden
  completarse hasta que esos tres archivos existan en el repo — son una entrega de diseño pendiente, no un
  paso de código.
- Sin cambios en autoloads, señales, contrato `MinigameBase`, ni en la tabla fija de colores/patrones de
  `MATCH_COLOR`. No toca zero-text ni Low-Stim.
