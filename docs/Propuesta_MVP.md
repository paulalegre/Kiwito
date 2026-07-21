# Propuesta de MVP — Plataforma de Minijuegos Educativos 2D

**Estado:** Propuesta para validación local (pre-desarrollo)
**Fecha:** 2026-07-21
**Motor:** Godot 4.x (mínimo 4.3)
**Plataforma primaria:** Tablets (Android / iPadOS). PC solo como entorno de validación.
**Público objetivo:** Primera infancia, 3 a 8 años.

> **Documentos de referencia.** Esta propuesta consolida y resume las decisiones ya trabajadas en detalle en:
> - **[GDD_MVP.md](./GDD_MVP.md)** — diseño de juego, mecánica, UX y accesibilidad.
> - **[Core_Architecture.md](./Core_Architecture.md)** (v3.0) — manifiesto técnico y arquitectura.
> - **[Direccion_de_Arte.md](./Direccion_de_Arte.md)** (v1.0) — dirección de arte, paleta, movimiento y diseño sensorial.
>
> Este documento es la vista ejecutiva para decisión y arranque; los tres anteriores son la fuente de verdad técnica y visual.

---

## 1. Visión y objetivo de la validación

Construir el esqueleto reutilizable de una **plataforma** de minijuegos educativos —no un juego suelto— y probarlo localmente con un primer cartucho jugable. El MVP debe responder a **una** pregunta de validación:

> **¿Un niño de 3 a 8 años, sin saber leer y sin ayuda de un adulto, entiende el juego, lo disfruta y quiere volver?**

Todo lo que no sirva para responder esa pregunta queda fuera del alcance (ver §3). El valor a largo plazo no está en el minijuego de globos, sino en la **arquitectura de cartuchos** que permite añadir juegos nuevos —y dimensiones educativas nuevas— casi sin código.

### Principios de producto (no negociables)

| Principio | Implicación |
| --- | --- |
| **Arranque sin fricción** (Zero-Click Boot) | La app abre directo al Hub jugable. Cero pantallas de título, cero login, cero menús de texto. |
| **Cero texto** | Toda instrucción es auditiva y visual (voz + animación de una mano). El usuario no sabe leer. |
| **Cero castigos** | No hay "Game Over", ni puntuación, ni pantallas de fracaso. El error da feedback neutro y el nivel siempre avanza al éxito. |
| **Accesible por defecto** | Modo Low-Stim (baja estimulación sensorial, TEA) y redundancia no-cromática incorporados desde el día 1, no como parche. |
| **Plataforma, no juego** | Cada decisión se toma pensando en el segundo y tercer cartucho, no solo en el primero. |

---

## 2. Experiencia (Core Loop)

1. **Inicio:** carga directa al **Hub Principal** interactivo.
2. **Selección:** el niño toca un objeto del entorno (la Caja de Globos) para entrar al minijuego.
3. **Juego:** desafío de ciclo corto (1–2 min) — explotar globos que cumplen la regla activa.
4. **Recompensa:** celebración inmediata **siempre**; entrega de sticker si se alcanzó un hito; retorno automático al Hub.

El Hub tiene dos nodos interactivos en el MVP: **la Caja de Globos** (inicia el minijuego) y **el Libro Mágico** (abre el Álbum de Stickers).

---

## 3. Alcance congelado

### ✅ Incluido en el MVP

- 1 **Hub Principal** interactivo básico.
- 1 **Minijuego** funcional ("Explotaglobos") con motor de coincidencia configurable.
- 1 **Sistema de meta-progreso** local (Álbum de Stickers por hitos).
- **Menú de pausa** global (Continuar / Salir al Hub).
- **Modo Low-Stim** integrado.
- **Telemetría local** pasiva (base para futuros reportes a padres/tutores).
- **Persistencia robusta** del progreso (tolerante a cierres abruptos de la tablet).

### ❌ Fuera de alcance (Fase 2+)

- Perfiles, avatares o selección de usuario.
- Tienda virtual, nube o analítica remota.
- Tutoriales interactivos complejos (se usa onboarding visual in-game).
- Puntuación numérica o sistema de estrellas.
- Ajuste dinámico de dificultad (DDA) y segundos cartuchos.

---

## 4. La mecánica: un motor, no un juego

> **Decisión clave.** No se elige entre "juego de colores" y "explotar globos a secas". Se construye un **motor genérico de coincidencia**: *"explota los globos que cumplen la regla X"*. El color es la **primera regla configurable**, no la esencia del producto.

Cada nivel define en su `LevelConfig` **qué cuenta como correcto** (`MatchRule`). El mismo cartucho, **sin código nuevo**, cubre todo el rango evolutivo:

| Regla | Objetivo educativo | Estado |
| --- | --- | --- |
| `MATCH_ANY` | Causa-efecto (explotar cualquiera). Suelo para 3–4 años y onboarding. | **MVP** |
| `MATCH_COLOR` | Discriminación de color. Foco pedagógico de la validación (4–6 años). | **MVP** |
| `MATCH_SHAPE`, `MATCH_SIZE`, `MATCH_COUNT` | Nuevas dimensiones (forma, tamaño, conteo). | Fase 2 — **solo `.tres`, cero código** |

Este diseño resuelve de raíz el riesgo de accesibilidad cromática: el color deja de ser el único eje posible, y **la redundancia no-cromática pasa de obligatoria a mejora**.

- **Dificultad = dato.** Velocidad de ascenso, ritmo de spawn, nº de señuelos, ratio objetivo/señuelo y tamaño de hitbox viven en `LevelConfig.tres`. El MVP embarca un **preset suave por defecto**; la telemetría recoge datos para calibrar presets futuros.
- **Recompensa por sesión independiente de los hitos.** Todo cierre exitoso celebra, exista o no desbloqueo de sticker. Para un niño pequeño, la mayoría de sesiones no pueden sentirse "vacías".

Detalle completo de la mecánica, onboarding y balance en **[GDD §5](./GDD_MVP.md)**.

---

## 5. Accesibilidad y diseño para la infancia (CCI)

No es una capa opcional; condiciona la arquitectura. Resumen de las garantías de MVP:

- **Hitboxes +30%** sobre el sprite visible; tolerancia táctil generosa.
- **Rechazo de palma:** se filtran toques secundarios (`event.index == 0`) — los niños apoyan la mano.
- **Táctil y ratón unificados** (`Emulate Touch From Mouse`) para validar en PC y desplegar en tablet con el mismo código.
- **Ayuda escalonada, nunca bloqueante:** ante frustración, la ayuda escala (pulso visual + audio → realce no-cromático del objetivo) pero **la pantalla nunca se congela ni descarta toques**. Reemplaza al antiguo "congelamiento" punitivo.
- **Accesibilidad cromática:** cada color porta un rasgo redundante no-cromático (patrón/ícono) + contraste de luminancia. ~1 de cada 12 niños tiene deficiencia de visión al color.
- **Modo Low-Stim (TEA):** desactiva destellos, reduce partículas y suaviza audio. Beneficio secundario de rendimiento.
- **Feedback <100 ms** en toda interacción táctil (Juice).

---

## 6. Arquitectura (resumen ejecutivo)

Arquitectura de **"Cartuchos" (Core/Features)** con inyección de dependencias: los minijuegos son cartuchos que se insertan en una consola (el Core). Fundamentos:

- **Contrato fino (`MinigameBase`):** un cartucho solo expone `start(config)`, `pause()`, `resume()`, `stop()` y comunica su resultado por una señal local `session_finished(result)`. **Nunca** conoce al Host ni a otro minijuego.
- **Composición sobre herencia:** comportamiento por componentes Plug & Play (`HitboxComponent`, `FloatUpwardComponent`, `JuiceComponent`), no árboles de herencia.
- **Comunicación "Signals Up, Calls Down":** señales locales hacia arriba, llamadas tipadas hacia abajo. **Prohibido el EventBus global basado en strings**; las señales globales se reservan para difusión real (fan-out).
- **Autoloads de dominio (sin god-objects):** `SaveManager` (única capa de I/O), `SettingsManager`, `ProgressionManager`, `AudioManager`, `MetricsLogger`, `SceneDirector` (único autor de cambios de escena). Orden de init fijado.
- **Datos, no código:** balance y reglas en `LevelConfig.tres`; añadir contenido no requiere programar.
- **Topología Feature-Sliced:** `core/`, `shared/`, `features/` — preparada para empaquetado dinámico (`.pck`) de cartuchos futuros.

### Decisiones fundacionales (costosas de revertir, ya tomadas)

| Área | Decisión | Motivo |
| --- | --- | --- |
| Renderer | `GL Compatibility` | Tablets de gama baja/media; 2D plano no necesita más. |
| Escalado | `canvas_items` + `aspect = expand`, zona segura, margen 8% | Aspect ratios de tablet heterogéneos; no recortar UI crítica. |
| Persistencia | **JSON** vía `FileAccess`, no `.tres` | Un `.tres` escribible es vector de deserialización insegura. |
| Robustez del save | Escritura atómica (tmp+rename), `save_version`, fallback a defaults | Sobrevivir a suspensión/cierre abrupto sin corromper el progreso del niño. |
| Audio | Buses `Music`/`SFX`/`VO`, ducking, pool de SFX, `.ogg` mono precargado | Latencia <100 ms y bajo consumo en tablet. |
| Testabilidad | Lógica pura separada del `SceneTree` + GUT | Verificar save/progresión sin abrir el juego. |

Detalle completo en **[Core_Architecture.md](./Core_Architecture.md)**.

---

## 7. Progresión y datos

- **Stickers por hitos acumulativos** (globos correctos totales entre sesiones): 5 → básico, 20 → intermedio, 50 → especial. Los stickers son variaciones estéticas de globos (bajo coste de assets, alta rejugabilidad).
- **Propiedad del dato:** un único dueño por dominio (`ProgressionManager` para stickers y conteo; `SettingsManager` para Low-Stim). `SaveManager` solo hace I/O. No existe `GameState` monolítico.
- **Telemetría local, anónima y 100% offline:** tiempo de resolución, toques fallidos, colores con más error. Pilar de los futuros reportes a tutores. Cualquier envío remoto es Fase 2 y requeriría consentimiento parental (COPPA/GDPR-K).

---

## 8. Roadmap de construcción

Fases de trabajo del MVP (secuencia lógica, no compromiso de fechas):

1. **Fundaciones del Core.** Config de proyecto (renderer, escalado, input), topología de carpetas, autoloads vacíos con su orden de init, `SceneDirector` + transición de fundido, contratos (`MinigameBase`, `MinigameResult`, `LevelConfig`).
2. **Persistencia y settings.** `SaveManager` (I/O atómico + versionado + fallback), `SettingsManager` (Low-Stim), tests GUT de robustez del save. *Se testea primero lo que corrompe datos del niño.*
3. **Cartucho "Explotaglobos".** Motor de coincidencia genérico (`matches()`), componentes (hitbox, ascenso, juice), spawn, `MATCH_ANY` + `MATCH_COLOR`, preset de dificultad por defecto.
4. **Progresión y Hub.** `ProgressionManager` + hitos + Álbum de Stickers; Hub con Caja de Globos y Libro Mágico; ciclo completo Hub↔Minijuego.
5. **Audio y pulido sensorial.** `AudioManager` (buses, ducking, pool SFX, VO no-solapada), integración Low-Stim, juice final, ayuda escalonada.
6. **Telemetría y cierre.** `MetricsLogger`, flush en puntos seguros, verificación de fugas de nodos, pase de accesibilidad.

Cada fase deja el juego en estado ejecutable; la validación con niños puede empezar en cuanto la fase 4 esté completa y refinarse con 5–6.

---

## 9. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación (ya en el diseño) |
| --- | --- | --- |
| Daltonismo infantil (~1/12) | El gancho educativo excluye a parte del público | Motor de reglas + redundancia no-cromática + `MATCH_ANY` |
| Brecha evolutiva 3–8 años | Una curva única aburre o frustra | Dificultad 100% en datos; preset suave + telemetría para calibrar |
| Cierre abrupto de la tablet | Pérdida/corrupción del progreso | Escritura atómica + versionado + fallback a defaults |
| Sobrecarga sensorial (TEA) | Rechazo del producto | Modo Low-Stim desde el día 1 |
| Diversidad de aspect ratios | UI recortada en tablets no-16:9 | `aspect = expand` + zona segura + regla del 8% |
| Sobre-ingeniería del MVP | Retraso de la validación | Pooling y DDA explícitamente diferidos; se testea solo save/progresión |

---

## 10. Criterios de validación (definición de éxito)

El MVP se considera exitoso si, en pruebas locales con niños del rango objetivo:

1. **Comprensión sin adulto:** el niño entra al minijuego y entiende qué hacer solo con la señal audiovisual, sin instrucción verbal externa.
2. **Disfrute observable:** hay señales de placer (risa, concentración positiva) y ausencia de frustración bloqueante.
3. **Retorno voluntario:** el niño quiere jugar otra vez y/o explorar el Hub por iniciativa propia.
4. **Robustez:** ninguna sesión pierde progreso; la app no crashea ante toques caóticos, palmas apoyadas o cierres abruptos.
5. **Accesibilidad efectiva:** un niño con visión al color reducida completa `MATCH_COLOR` gracias a la redundancia; el modo Low-Stim resulta perceptiblemente más calmado.

La telemetría local aporta la evidencia cuantitativa (tiempos, errores por color) para respaldar la observación cualitativa.

---

## 11. Próximo paso

Con esta propuesta y los documentos de referencia aprobados, el trabajo puede comenzar por la **Fase 1 (Fundaciones del Core)**.

- ✅ **Dirección de arte y paleta global** — resuelta en **[Direccion_de_Arte.md](./Direccion_de_Arte.md)**: estilo de libro ilustrado interactivo, paleta con escalera de luminancia para los 4 colores jugables, tipografía (Nunito), presupuesto de animación y contrato visual del Modo Low-Stim. Pendiente de aprobación.
- ⬜ **Set inicial de assets de audio** (VO de instrucción por color, SFX de pop/plop/celebración, música de Hub). Se rige por [Core_Architecture §8](./Core_Architecture.md) y por la tabla de feedback de [DA §7](./Direccion_de_Arte.md).
