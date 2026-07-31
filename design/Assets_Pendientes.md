# Assets pendientes

Checklist de arte visual que falta para reemplazar los placeholders procedurales actuales
(`PlaceholderCircle`, `ColorRect`, círculos de `_draw()`). Especificaciones tomadas de
`docs/Direccion_de_Arte.md` (normativo) y `docs/GDD_MVP.md`. Marca cada ítem al cargarlo en el
proyecto.

Convención de nomenclatura: `snake_case`, prefijo de dominio (§8 de Direccion_de_Arte.md).
Un atlas por dominio (`hub_main`, `ui`, `mg_balloons`) — nunca cruzar dominios. Entrega en PNG,
sRGB, alfa premultiplicado desactivado, 1.5× el tamaño de uso en el lienzo lógico.

Reglas de estilo que aplican a todo lo de abajo (no repetir por ítem): sin contorno, sin
degradado (única excepción: cielo lejano de fondo), volumen falso con máx. 2 tonos por
elemento, vértices redondeados, color siempre resuelto desde `shared/global_assets/palette.tres`
(nunca hex literal en el asset final si el color se aplica por `modulate` en código).

---

## 0. Fondos — no existe ninguno hoy

Ni `root.tscn` ni las escenas del Hub/minijuego definen un fondo o `clear_color`; ambas corren
sobre el gris por defecto del motor. Es el gap más grande y el primero a resolver.

- [x] **Fondo del Hub** — Crema `#FBF3E4` como base. Opcional: 2–4 capas de siluetas
      planas por tono para profundidad (§3.5), sin textura interna en ninguna capa.
      → `design/hub_main/hub_bg.png` (1920×1080). Implementado como `Sprite2D` sobre una base
      `ColorRect`-equivalente (`PaletteBackgroundRect`, `shared/components/`) tintada con
      `cream_fade` de `palette.tres`, para cubrir sin gris por defecto cualquier aspect ratio de
      tablet bajo `stretch/aspect = expand` (Core_Architecture.md §0). Ver `wire-hub-main-art-assets`.
- [ ] **Fondo de modales** (Álbum de Stickers) — mismo tratamiento Crema, pendiente; no incluido en
      `wire-hub-main-art-assets` (fuera de su alcance).
- [ ] **Cielo/fondo de Explotaglobos** — Menta `#CFE7DA`. Único lugar del proyecto donde se
      permite degradado (capa de cielo lejano, §3.2), si decides usarlo.
      → `design/minigames/mg_balloons/mg_balloons_bg_sky.png`

## 1. Hub — nodos interactivos (dominio `hub_main`)

Reemplazan `PlaceholderCircle` en `caja_de_globos.tscn` / `libro_magico.tscn`. Dirección final
confirmada 2026-07-31: **botón-icono circular** (glifo de play / glifo de libro sobre un círculo
tintado), reemplazando el lenguaje original de silueta literal de caja/cofre y libro.

- [x] **Caja de Globos** — `design/hub_main/hub_balloon_box.png` (332×332 px). Por debajo del ideal
      de §5.2 (320+ *lógicos* con margen de entrega 1.5×; a escala nativa 1× apenas alcanza el
      mínimo, sin colchón de alta densidad) — **aceptado para MVP**, revisar en el próximo pase de
      arte de una versión estable.
- [x] **Libro Mágico** — `design/hub_main/hub_magic_book.png` (170×210 px). No alcanza el mínimo de
      320px de §5.2 bajo ninguna interpretación, y es ~1.6× más chico que Caja de Globos (rompe el
      "mismo tamaño" pedido originalmente aquí) — **aceptado para MVP** por la misma razón; es el
      candidato más urgente para el próximo re-export.

## 2. UI de pausa — iconos (dominio `ui`)

Reemplazan los círculos lisos de `tappable_icon.gd` (`pause_overlay.tscn`). Sin pictograma hoy
el significado depende solo de color/posición, lo cual roza el invariante de cero-texto.

- [ ] **Botón Casa** — 140 px visible / 182 px hitbox (§5.2).
      → `design/ui/ui_icon_home.png`
- [ ] **Continuar** — ~96 px visible (icon_radius 48 en la escena actual).
      → `design/ui/ui_icon_continue.png`
- [ ] **Salir al Hub** — mismo tamaño que Continuar.
      → `design/ui/ui_icon_exit.png`

## 3. Álbum de stickers — 3 accesorios (dominio `mg_balloons`)

Por diseño (GDD §6, Direccion_de_Arte §8) los stickers **no son ilustraciones nuevas**: heredan
`balloon_base.png`/`balloon_volume.png` ya tintados y solo agregan una capa de accesorio.
Reemplazan los `ColorRect` de `sticker_album.gd`. Tamaño: 200 px visible (celda del álbum, §5.2).

- [ ] **Sticker 1 — Básico** (hito: 5 globos correctos) — accesorio simple, ej. gafas.
      → `design/minigames/mg_balloons/sticker_01_accessory.png`
- [ ] **Sticker 2 — Intermedio** (hito: 20 globos correctos) — ej. sombrero.
      → `design/minigames/mg_balloons/sticker_02_accessory.png`
- [ ] **Sticker 3 — Especial/Brillante** (hito: 50 globos correctos) — acento "brillante" como
      formas planas (racimo de destellos/estrellas), nunca un highlight o degradado.
      → `design/minigames/mg_balloons/sticker_03_accessory.png`

> Nota: la silueta bloqueada (Tinta `#3B3028` al 100%) no necesita asset aparte — se resuelve
> tintando el mismo compuesto en código, no es trabajo de arte.

## Fuera de esta lista (a propósito, post-MVP)

`docs/Direccion_de_Arte.md §12` marca explícitamente estos pendientes como fuera del MVP — no
generar todavía: puerta parental (icono + pantalla de verificación), protagonista/secundarios,
modo alto contraste, variante de ambiente nocturno.

---

## Hallazgo: `design/globo.png` / `design/globo.png.import` están huérfanos

Verificado por búsqueda de texto y por UID (`uid://ct2n3dpr1i1rr`) en todos los `.tscn`/`.gd`/`.tres`
del proyecto: **ninguna escena ni script los referencia**. El prototipo que los usaba
(`scripts/main.gd`, `scripts/globo.gd`, mencionado como bootstrap temprano en `CLAUDE.md`) ya no
existe en el repo — las carpetas `scripts/` y `scenes/` fueron reemplazadas por la arquitectura
actual (`core/`, `features/`, `shared/`). El globo real del minijuego usa el set en capas
(`balloon_base.png`/`balloon_volume.png`/`balloon_face.png` + patrones), no este archivo.

**Recomendación:** seguros de eliminar `design/globo.png` y `design/globo.png.import`.
`design/globo.psd` (el archivo fuente) queda fuera de esta verificación — no se pidió revisarlo,
pero probablemente esté igual de huérfano si nada más lo usa como fuente de edición.
