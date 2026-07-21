# Game Design Document - MVP (GDD_MVP)
**Proyecto:** Plataforma Minijuegos Educativos 2D (Validación Local)
**Resolución de Diseño (viewport lógico):** 1920x1080 (16:9 Landscape)
**Público Objetivo:** Primera Infancia (3 a 8 años)

> **Nota de plataforma (crítica para diseño).** El público objetivo juega mayoritariamente en **tablets**, cuyos aspect ratios reales son heterogéneos (iPad 4:3, Android 16:10, 3:2). "1920x1080" es el **lienzo de diseño**, no una promesa de recorte. Todo el layout debe respetar una **zona segura** central (`safe area`) y anclar los elementos de UI críticos (botón Casa, recuadro de meta) a las esquinas mediante `Control` anchors, nunca a coordenadas absolutas. La estrategia técnica de escalado (`stretch mode = canvas_items`, `aspect = expand`) está definida en el Manifiesto de Arquitectura §0. Regla de diseño derivada: **ningún elemento interactivo puede quedar dentro del 8% de margen exterior** (posible recorte en pantallas más anchas/altas que 16:9).

## 1. El Bucle Principal (Core Loop)
El juego implementa una filosofía de **Arranque Sin Fricción (Zero-Click Boot)**.
1. **Inicio de App:** Carga directa al "Hub Principal". Cero pantallas de título estáticas.
2. **Selección:** Interacción táctil con un objeto en el entorno para iniciar.
3. **Gameplay:** Resolución de un desafío de ciclo corto (1-2 minutos).
4. **Recompensa:** Evaluación de hitos, entrega visual de Sticker (si aplica), y retorno automático al Hub.

## 2. Alcance Estricto del Prototipo (MVP Scope)
Para garantizar la viabilidad de la validación local, el alcance queda estrictamente congelado:

* **SÍ SE DESARROLLA:**
  * 1 Escena "Hub Principal" interactiva básica.
  * 1 Minijuego funcional ("Explotaglobos" - Discriminación de colores).
  * 1 Sistema de Meta-progreso (Álbum de Stickers local).
  * Menú de Pausa global (Continuar / Salir al Hub).
  * Integración del "Modo Low-Stim" (Baja estimulación).

* **NO SE DESARROLLA (Queda para Fase 2):**
  * Pantallas de selección de perfiles o avatares.
  * Tiendas virtuales, conectividad en la nube o analíticas remotas.
  * Tutoriales interactivos complejos (se usa onboarding visual in-game).
  * Sistema de puntuación numérica o de 3 estrellas.

## 3. UI/UX Global y Accesibilidad

> **Fuente de verdad visual.** Los valores concretos de paleta, tamaños táctiles, duraciones de animación, tipografía y el contrato exacto del Modo Low-Stim viven en **[Direccion_de_Arte.md](./Direccion_de_Arte.md)**. Este apartado fija las *reglas* de UX; aquel fija los *valores*.
* **Botón de Escape:** Icono de "Casa" (esquina superior izquierda) con hitbox gigante (+30%) para pausar o salir.
* **Meta Persistente:** Un recuadro estático en la esquina superior derecha mostrará siempre el objetivo actual (ej. la imagen de un globo rojo vibrando suavemente).
* **Ayuda Escalonada (reemplaza al "congelamiento" punitivo):** Congelar el input de un niño de 3-8 años se percibe como "se rompió", no como ayuda, y viola el principio de Cero Castigos (§Core 4C). En su lugar, ante frustración detectada — 3 toques incorrectos en <1.5s, **o** 4 segundos sin ningún toque correcto — el juego **escala la ayuda sin nunca bloquear la interacción**:
  1. El recuadro de la meta emite un pulso visual (`PulseAnimation`) y un refuerzo auditivo suave ("¡Busca este!").
  2. Si persiste, los globos del color objetivo reciben un realce no-cromático (halo/rebote lento) que los hace destacar — un empujón, no una solución automática.
  3. La pantalla **nunca** se congela ni descarta toques. El nivel siempre avanza hacia el éxito.
* **Accesibilidad cromática (obligatoria en un juego de color):** ~1 de cada 12 niños tiene deficiencia de visión al color; un juego cuya mecánica central es "distingue el rojo" es un riesgo de accesibilidad directo. Mitigaciones de MVP: (a) el recuadro de meta y cada globo portan un **rasgo distintivo redundante no-cromático** (patrón/forma/ícono sutil por color, definido en `LevelConfig`), de modo que el color nunca es el único canal de información; (b) se emplea una paleta con suficiente contraste de luminancia entre los 4 colores. El *asset* de patrón se diseña como capa opcional para no recargar visualmente el modo estándar.
* **Feedback (Juice):** Toda interacción táctil devuelve feedback (escala/rebote y SFX) en menos de 100ms.

## 4. El Hub Principal y el Álbum
Entorno visual estático con dos nodos interactivos principales:
* **La Caja de Globos:** Inicia el minijuego de colores.
* **El Libro Mágico:** Abre el modal del "Álbum de Stickers". Muestra un Grid con las siluetas en negro de los stickers. Los stickers desbloqueados se muestran a color.

## 5. Minijuego Punta de Lanza: "Explotaglobos"

> **Decisión de diseño (mecánica central).** No se elige entre "juego de colores" y "explotar globos a secas". Se construye un **motor genérico de coincidencia** — *"explota los globos que cumplen la regla X"* — del que el color es la **primera regla configurable**, no la esencia. El mismo cartucho, sin código nuevo, cubre desde el niño de 3 años (explotar cualquiera) hasta discriminación de color, forma o tamaño. Esto disuelve el riesgo de daltonismo (§3): el color deja de ser el único eje posible del producto, y la redundancia no-cromática pasa de obligatoria a mejora.

* **Objetivo Pedagógico (foco del MVP):** Discriminación visual de colores — es el gancho educativo que la validación local pone a prueba.
* **Motor de coincidencia (`MatchRule`) — el corazón reutilizable:** cada nivel define en `LevelConfig` **qué cuenta como "correcto"**. Desde el mismo motor:
    * `MATCH_ANY` — **Libre / Causa-Efecto:** explota cualquier globo. Suelo de dificultad para 3-4 años y rampa de onboarding de la primera sesión. Cero carga cognitiva; no depende del color (accesibilidad total).
    * `MATCH_COLOR` — **Discriminación de color:** explota solo el color objetivo. Foco pedagógico del MVP (4-6 años).
    * *(Fase 2, sin código nuevo — solo `.tres`)* `MATCH_SHAPE`, `MATCH_SIZE`, `MATCH_COUNT`: nuevas dimensiones educativas puramente por datos.
* **Alcance del MVP:** se embarcan **solo `MATCH_ANY` y `MATCH_COLOR`** (el modo *Libre* es la regla degenerada, coste de implementación ~cero). El resto es *seam* preparado, no desarrollo.
* **Mecánica Base:** Los globos spawnean desde el margen inferior (fuera de cámara) y ascienden en el eje Y. El jugador explota los que cumplen la `MatchRule` activa. En `MATCH_COLOR` los colores del MVP son rojo, azul, amarillo y verde.
* **Onboarding:** Voz en off inicial: *"¡Explota los globos [COLOR]!"* simultánea a una animación de una mano tocando el color correcto. La VO completa suena en la primera sesión; en sesiones posteriores se reduce a la señal breve (evita fatiga por repetición).
* **Resolución de Errores:** Tocar el color incorrecto genera un sonido opaco (plop seco) y el globo vibra (`ShakeAnimation`), pero no explota ni reinicia el nivel.
* **Espectro de dificultad (3–8 años):** La brecha evolutiva entre 3 y 8 años es demasiado amplia para una curva única. **Ningún parámetro de balance se hardcodea**; todos viven en `LevelConfig.tres` (ver Arquitectura §2C): velocidad de ascenso, ritmo de spawn, nº de colores señuelo simultáneos, ratio objetivo/señuelo, y tamaño de hitbox. El MVP embarca **un preset por defecto suave** (pocos señuelos, ascenso lento), pero deja el *seam* de dificultad listo. Dado que el MVP no tiene selección de perfil (§2), la adaptación es implícita: la telemetría (`MetricsLogger`) registra aciertos/errores para calibrar presets futuros; la DDA (ajuste dinámico) queda para Fase 2, no se implementa ahora.
* **Recompensa por sesión (independiente de los hitos):** Todo cierre de nivel exitoso entrega refuerzo positivo inmediato (celebración visual + SFX), **exista o no** desbloqueo de sticker. Los stickers (§6) son la capa de meta-progreso de largo plazo; nunca deben ser la única fuente de gratificación, o la mayoría de sesiones se sentirían "vacías" para un niño pequeño.
* **Condición de Fin de Nivel:** Explotar N globos correctos (N=5 en el preset por defecto, parametrizado en `LevelConfig`). Al terminar, los restantes desaparecen, suena un refuerzo positivo, se actualizan las métricas y a los 4 segundos retorna al Hub.

## 6. Progresión (Sistema de Stickers por Hitos)
Para maximizar la rejugabilidad del MVP sin producir *assets* masivos, los stickers son variaciones estéticas de los globos (ej. globo rojo con gafas) y se desbloquean acumulando globos correctos totales a lo largo de las sesiones.
* **Hito 1:** 5 globos correctos totales -> Sticker Básico.
* **Hito 2:** 20 globos correctos totales -> Sticker Intermedio.
* **Hito 3:** 50 globos correctos totales -> Sticker Especial (Brillante).

## 7. Persistencia de Datos

### 7.1. Formato: JSON (decisión congelada)
Los datos del jugador se guardan en `user://save_data.json` mediante `FileAccess` + `JSON`.
**No se usa `.tres` para el save.** Motivo: un `.tres` escribible por el usuario es un vector de deserialización insegura (puede embeber tipos/objetos arbitrarios); además JSON es legible para depuración y coherente con el formato de la telemetría (`MetricsLogger`). El formato `.tres` queda reservado para configuración de diseño cargada desde `res://` (ver `LevelConfig` en el Manifiesto de Arquitectura §2C).

### 7.2. Propiedad del dato (un solo dueño por dominio)
No existe un `GameState` monolítico. Cada dato tiene un autoload de dominio dueño, y todos persisten a través de una única capa de I/O (`SaveManager`, en `core/data/`):

| Dato | Tipo | Autoload dueño |
| --- | --- | --- |
| `unlocked_stickers` | Array de Strings (ej. `["sticker_01", "sticker_03"]`) | `ProgressionManager` |
| `total_balloons_popped` | Entero | `ProgressionManager` |
| `low_stim_mode` | Booleano (`true`/`false`) | `SettingsManager` |

`SaveManager` solo lee/escribe el archivo; no contiene reglas de juego. `SettingsManager` y `ProgressionManager` son la fuente de verdad en memoria de sus respectivos campos y solicitan la persistencia a `SaveManager`.

### 7.3. Robustez del guardado (requisito, no opcional)
Un niño cierra la app de golpe y la tablet se suspende sin aviso. El save debe sobrevivir a eso:
* **Escritura atómica:** escribir a `user://save_data.json.tmp` y luego renombrar sobre el definitivo. Nunca escribir in-place (una interrupción a mitad dejaría un JSON truncado e ilegible).
* **Versionado:** el JSON incluye `save_version: int`. Permite migraciones no destructivas post-MVP sin borrar el progreso del niño.
* **Tolerancia a fallos:** si el archivo falta, está corrupto o es de una versión desconocida → cargar valores por defecto **sin crashear ni bloquear el arranque** (el Zero-Click Boot no puede depender de un save válido). Un save ilegible se registra en telemetría y se regenera.
* **Frecuencia de escritura:** no se persiste en cada evento. Se hace flush en puntos seguros: fin de sesión de minijuego, cambio de setting, y al recibir `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST`.

### 7.4. Esquema de ejemplo
```json
{
  "save_version": 1,
  "unlocked_stickers": ["sticker_01", "sticker_03"],
  "total_balloons_popped": 27,
  "low_stim_mode": false
}
```