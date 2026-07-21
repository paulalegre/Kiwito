# Manifiesto de Arquitectura Técnica (Core_Architecture v3.0)
**Proyecto:** MVP Plataforma Minijuegos Educativos 2D
**Motor:** Godot 4.x (mínimo 4.3; usar la estable más reciente de la rama 4.x)
**Viewport lógico:** 1920x1080, Formato 16:9 (Landscape)
**Audiencia:** Primera Infancia (3 a 8 años)
**Plataforma primaria:** Tablets (Android/iPadOS); PC solo como entorno de validación local.

## 0. Plataforma, Renderizado y Escalado (Decisiones Fundacionales)

Se deciden ahora porque son costosas de cambiar después y condicionan todo lo demás.

*   **Renderer: `GL Compatibility`.** El público juega en tablets de gama baja/media. Se prioriza compatibilidad y consumo sobre efectos avanzados. `Forward+`/`Mobile` no aportan nada a un 2D plano y sí excluyen hardware barato. Sin sombras dinámicas ni post-proceso costoso.
*   **Escalado (`Project Settings > Display > Window > Stretch`):**
    *   `Mode = canvas_items` (escala el contenido 2D manteniendo nitidez, no píxeles).
    *   `Aspect = expand` (muestra más área en pantallas no-16:9 en vez de recortar o deformar). El diseño respeta una **zona segura**; ver GDD (regla del 8% de margen).
    *   Toda la UI usa nodos `Control` con *anchors*, nunca posiciones absolutas.
*   **Orientación:** `landscape` bloqueada. Sin soporte de rotación en MVP.
*   **Presupuesto de rendimiento (objetivo, no aspiracional):** 60 FPS estables en tablet de gama media; degradación aceptable a 30 FPS mínimo en gama baja. El modo Low-Stim también reduce carga (menos partículas) como beneficio secundario de rendimiento.
*   **Assets:** texturas potencia-de-dos donde aplique, importadas con compresión adecuada a móvil; atlas para sprites del mismo dominio. Evitar texturas 4K para elementos pequeños.

## 1. Filosofía Central: Arquitectura de "Cartuchos"
Este proyecto utiliza una arquitectura de **Inyección de Dependencias (Core/Features)**. Los minijuegos no son islas completamente aisladas, sino "cartuchos" que se insertan en una "consola" (el Core).

*   **Regla del Cartucho:** Un minijuego solo expone métodos de control básicos (`start()`, `pause()`, `stop()`). El Core se encarga de las transiciones de pantalla, la música global y la persistencia de datos.
*   **Composición sobre Herencia:** Estrictamente prohibido crear árboles de herencia profunda. Todo comportamiento se inyecta mediante nodos Componentes aislados (ej. `FloatUpwardComponent` para hacer subir elementos por la pantalla, o `PopOnTouchComponent`).

### 1.1. El Contrato del Cartucho (`MinigameBase`)
Godot 4 no tiene interfaces reales. El contrato se materializa como una **clase base fina de un solo nivel** — la *única* herencia sancionada del proyecto (no contradice "composición sobre herencia": lo prohibido son los árboles *profundos*, no un contrato de un nivel):

```gdscript
class_name MinigameBase
extends Node2D

## El Host conecta esta señal local al instanciar el cartucho (ver §2A caso 3).
signal session_finished(result: MinigameResult)

## Contrato. Los cartuchos DEBEN sobrescribir start(); el resto es opcional.
func start(config: LevelConfig) -> void: push_error("start() no implementado")
func pause() -> void: get_tree().paused = true
func resume() -> void: get_tree().paused = false
func stop() -> void: queue_free()
```
*   **Regla de aislamiento reforzada:** un cartucho recibe todo lo que necesita por inyección (`start(config)`); **nunca** conoce al Host, a otro minijuego, ni referencia nodos fuera de su subárbol. Comunica su resultado solo por `session_finished`.

### 1.2. Ciclo de Vida y Transiciones (`SceneDirector`)
Un autoload `SceneDirector` (en `core/autoloads/`) es el **único** que cambia de escena. Los cartuchos y el Hub no llaman a `get_tree().change_scene_*` directamente.
*   **Carga:** el minijuego se instancia como escena hija bajo un nodo contenedor persistente (patrón de escena raíz + slot), no con `change_scene_to_file` sobre el árbol completo — así el Core (autoloads + música + overlay de pausa) nunca se descarga.
*   **Transiciones sin fricción:** todo cambio Hub↔Minijuego pasa por un fundido (`ui_elements/transitions/`) que **cubre la carga** — el niño nunca ve un salto brusco ni una pantalla de "cargando". Precargar la escena destino antes del fundido de salida.
*   **Descarga:** al volver al Hub, `stop()` libera el cartucho (`queue_free`) y su memoria; el Hub se re-muestra. Verificar ausencia de fugas de nodos huérfanos en el `Monitor` de Godot.

### 1.3. Pausa Global y `process_mode`
*   La pausa usa `get_tree().paused = true`.
*   El overlay de pausa y el botón Casa se configuran con `process_mode = PROCESS_MODE_ALWAYS` (siguen respondiendo con el árbol pausado).
*   Los autoloads que deben seguir vivos en pausa (ej. `AudioManager` para bajar la música) usan `PROCESS_MODE_ALWAYS`; el resto hereda el pausado.
*   El gameplay del cartucho usa el modo por defecto (`INHERIT`) para congelarse limpiamente.

## 2. Patrones de Diseño Estrictos

### A. Comunicación ("Signals Up, Calls Down" + Inyección)
*   **Prohibido el uso de un EventBus global basado en strings.** En Godot 4, esto anula el autocompletado y rompe el tipado.
*   Regla state-of-the-art (Godot 4.x, 2026): las señales globales **no** son el canal por defecto. Un conjunto de autoloads que emiten señales globales es, en la práctica, un EventBus distribuido y comparte su peor defecto: la pérdida de trazabilidad del flujo. Se aplica el principio **"señales hacia arriba, llamadas hacia abajo"** y se reservan las señales globales para difusión real (*fan-out*).

    **1. Comunicación local (hijo → padre): señal local.**
    El hijo emite; el padre conecta al instanciarlo. Scope acotado y trazable.
    *   *Bien:* el globo emite `popped(correct: bool)` hacia su minijuego contenedor.

    **2. Comunicación descendente (padre → hijo): llamada directa tipada.**
    *   *Bien:* el Host llama `minigame.start(config)` sobre el cartucho que instanció.

    **3. Cross-dominio Minijuego → Core: inyección / señal local, nunca autoload global.**
    El Core ya posee la referencia al cartucho que instanció, por lo que conecta una **señal local** del propio cartucho. Esto mantiene el aislamiento del cartucho (no referencia al Core) *y* el flujo local. El resultado viaja en un objeto tipado `MinigameResult` (`correct_pops: int`, `failed_taps: int`, `duration: float`, `errors_by_color: Dictionary`), que alimenta a la vez a `ProgressionManager` y `MetricsLogger`.
    *   *Bien:* `minigame.session_finished.connect(_on_session_finished)` → el Host llama `ProgressionManager.register_result(result)`.
    *   *Mal:* `ProgressionManager.minigame_won.emit(stars_earned)` (rodeo global + estrellas eliminadas del alcance).

    **4. Estado global de difusión (fan-out): autoload de dominio con señal tipada.**
    Único caso donde el patrón observador aporta: múltiples oyentes no relacionados reaccionan a un cambio de estado global.
    *   *Bien:* `SettingsManager.low_stim_changed.emit(enabled)`; `ProgressionManager.sticker_unlocked.emit(sticker_id)`.
    *   *Bien:* `AudioManager.play_sfx("pop_01")` (llamada de servicio, no señal).
    *   *Mal:* `EventBus.emit_signal("juego_terminado")`.

### B. Rendimiento MVP (Carga en Caché)
*   Para el MVP, la legibilidad y velocidad de desarrollo priorizan sobre la micro-optimización. El uso de Object Pooling **no es obligatorio** inicialmente.
*   Para instanciar múltiples objetos interactivos (ej. globos que ascienden), se `preload()` la `PackedScene` una vez y se `instantiate()` bajo demanda.
*   *Corrección técnica (importante):* Godot **no** tiene un *garbage collector* con pausas *stop-the-world*; los objetos GDScript son de **conteo de referencias** (*refcounting*) y se liberan de forma determinista. Por tanto no existe "stutter por GC". El coste real de instanciar es el de construir el subárbol de nodos (`.instantiate()`) y entrar/salir del `SceneTree`, que en el orden de magnitud de este juego (una decena de globos en pantalla, spawn espaciado) es **despreciable**. Conclusión: pooling innecesario para el MVP — pero por el motivo correcto.
*   *Nota de Refactorización:* Reconsiderar Object Pooling solo si el Profiler registra picos de frame concretos en el `instantiate()` de escenas pesadas (muchas partículas/nodos), no de forma preventiva.

### C. Diseño Basado en Datos (Custom Resources)
*   Ninguna variable de diseño de nivel (colores objetivos, velocidad de ascenso, cantidad máxima de entidades) estará *hardcodeada* en los scripts.
*   Todo minijuego requerirá heredar de `Resource` para configurar sus niveles (ej. `LevelConfig.tres`), permitiendo iterar dificultad puramente modificando texto.
*   **La regla de juego es dato, no código:** `LevelConfig` incluye `match_rule` (enum: `MATCH_ANY`, `MATCH_COLOR`, `MATCH_SHAPE`, …) y sus parámetros (color/atributo objetivo, ratio de señuelos, nº a completar). El motor del minijuego evalúa la regla activa de forma **genérica** — un único `func matches(balloon, rule) -> bool`. Añadir una dimensión educativa nueva es crear un `.tres`, jamás tocar scripts (ver GDD §5).
*   **Frontera `.tres` vs JSON:** `.tres` se usa **exclusivamente para configuración de diseño cargada desde `res://`** (contenido de confianza, editado por el equipo). Los **datos escribibles por el usuario** (save, telemetría) **nunca** usan `.tres`/`ResourceLoader` — se serializan como JSON vía `FileAccess`, para evitar la deserialización insegura de recursos y mantener legibilidad de depuración (ver GDD §7).

## 3. Convenciones de GDScript 2.0

*   **Tipado Estático Obligatorio:** Variables, retornos y parámetros deben estar tipados estrictamente.
    *   *Bien:* `var current_color: Color` / `func pop_balloon() -> void:`
*   **Nomenclatura:** `snake_case` para variables/funciones, `PascalCase` para Nodos/Clases, `SCREAMING_SNAKE_CASE` para constantes.
*   **Rutas Estables:** Prohibido usar rutas relativas encadenadas (`get_parent().get_node()`). Usar `@export` para inyectar nodos desde el Inspector.

## 4. Reglas de Interacción Niño-Computadora (CCI) y Accesibilidad

Diseñar para niños de 3 a 8 años requiere tolerancias de interacción específicas. Cualquier código que maneje *Inputs* o UI debe respetar:

### A. Hitboxes Extendidos y Rechazo de Palma (Input Handling)
*   **Tolerancia Táctil:** Las áreas de colisión (`Area2D`, `TextureButton`) deben ser un **30% más grandes** que el Sprite visible.
*   **Filtro Multitouch:** Los niños pequeños suelen apoyar la palma en la pantalla. Todo script de interacción debe filtrar toques secundarios validando el índice táctil: `if event is InputEventScreenTouch and event.index == 0:`.
*   **Táctil y ratón unificados:** el MVP se valida en PC pero se despliega en tablet. Activar `Project Settings > Input Devices > Pointing > Emulate Touch From Mouse` para que el ratón genere `InputEventScreenTouch` — así el mismo código de input funciona en ambos sin ramas duplicadas. (No activar "Emulate Mouse From Touch".)
*   **Detección local, no global:** cada globo detecta su propio toque vía el `input_event` de su `Area2D` (o un `HitboxComponent` reutilizable), no un `_input` global que haga *picking* manual. Esto respeta "señales hacia arriba" (§2A) y el aislamiento por componentes.
*   **Consumo de eventos:** un toque válido sobre un globo marca el evento como manejado (`get_viewport().set_input_as_handled()`) para que un mismo tap no impacte dos globos solapados.

### B. Feedback Inmediato y Modo Low-Stim (Baja Estimulación)
*   **Juice Dinámico:** Toda interacción táctil válida devuelve feedback visual (escala/rebote) en menos de 100ms mediante un `JuiceComponent`. Los elementos como globos deben explotar visualmente al tocarlos sin retraso.
*   **Accesibilidad (TEA):** El sistema Core incluirá un `SettingsManager.low_stim_mode`. Si este valor es `true`, los componentes de *Juice* desactivarán automáticamente destellos intensos (flashes), reducirán la emisión de partículas y suavizarán los efectos de sonido para evitar la sobrecarga sensorial.

### C. Prevención de la Frustración
*   **Cero Textos:** Las instrucciones serán puramente auditivas y visuales (animaciones de una mano indicando qué hacer).
*   **Cero Castigos:** No existen estados de "Game Over" severos. Los errores devuelven un feedback neutro (vibración leve, sonido opaco) y el nivel continúa hasta resolverse positivamente.

## 5. Telemetría Local (Métricas en la Sombra)
*   El Core incluirá un Autoload pasivo llamado `MetricsLogger`.
*   Cada minijuego debe reportar métricas de sesión (tiempo de resolución, número de toques fallidos, colores donde más se equivoca el usuario) para guardarlas en un archivo JSON local. Esta data será el pilar futuro para los reportes de progreso de padres/tutores.
*   **Buffer en memoria, flush en puntos seguros:** no escribir a disco por evento (castiga el almacenamiento de la tablet y arriesga corrupción). Se acumula en memoria y se hace *append* al archivo al terminar la sesión y en `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST` (mismas garantías atómicas que el save, GDD §7.3).
*   **Pasivo de verdad:** `MetricsLogger` solo escucha (recibe el `MinigameResult` que el Host le pasa); no altera gameplay ni bloquea. Su fallo (disco lleno, permiso denegado) se traga silenciosamente — nunca interrumpe el juego del niño.
*   **Privacidad:** datos 100% locales, anónimos, sin identificadores personales. Cualquier envío remoto es explícitamente Fase 2 y requeriría consentimiento parental (COPPA/GDPR-K); no forma parte del MVP.

## 5.1. Orden de Inicialización de Autoloads
El orden de registro de autoloads en `Project Settings > Autoload` es una dependencia real y debe fijarse:
1.  `SaveManager` (lee el archivo a memoria primero).
2.  `SettingsManager`, `ProgressionManager` (hidratan su estado desde `SaveManager`).
3.  `AudioManager`, `MetricsLogger`, `SceneDirector` (consumen lo anterior).

Regla: ningún autoload accede a otro en su `_init()`; las dependencias entre autoloads se resuelven en `_ready()`, cuando todos ya existen.

## 6. Topología de Directorios (Package-Based Architecture)

El proyecto rechaza la agrupación tradicional por tipo de archivo. Se utiliza una estructura basada en dominios (Feature-Sliced) para garantizar modularidad estricta y permitir el empaquetado dinámico (`.pck`) en el futuro.

### 6.1. `res://core/` (El Motor Invisible)
Código base de la aplicación. Gestiona el ciclo de vida, estado global y utilidades sin representación visual directa.
*   `autoloads/`: Única carpeta donde residen los Singletons activos en la jerarquía. **Regla:** Solo deben gestionar el estado de un dominio específico; prohibidos los "EventBuses" monolíticos y los `GameState` god-object. Autoloads del MVP:
    *   `ProgressionManager.gd`: dueño de `total_balloons_popped` y `unlocked_stickers` + lógica de hitos. Emite `sticker_unlocked(id)`.
    *   `SettingsManager.gd`: dueño de `low_stim_mode`. Emite `low_stim_changed(enabled)`.
    *   `AudioManager.gd`: servicio de audio global (`play_sfx`, música del Hub, *ducking* de música bajo la VO).
    *   `MetricsLogger.gd`: telemetría pasiva (ver §5).
    *   `SceneDirector.gd`: único autor de cambios de escena y transiciones (ver §1.2).
    *   *Orden de registro:* ver §5.1.
*   `data/`: Scripts y recursos dedicados exclusivamente a la lectura/escritura de datos. Contiene `SaveManager.gd`: **única** capa de I/O de persistencia (`user://save_data.json`); sin reglas de juego. `ProgressionManager` y `SettingsManager` persisten a través de él.
*   `utils/`: Clases con métodos estáticos (`static func`). **Regla:** Cero estado (stateless). Utilidades matemáticas, conversores de formatos o validadores.

### 6.2. `res://shared/` (Piezas de Lego Globales)
Elementos instanciables y reutilizables en múltiples escenas. Todo lo que cruza los límites de un dominio vive aquí.
*   `contracts/`: Clases base de contrato y tipos de datos compartidos. Aquí viven `MinigameBase.gd` (§1.1), `MinigameResult.gd` (`RefCounted`, objeto de resultado efímero) y la base `LevelConfig.gd` (`Resource`). Son el vocabulario que Core y Features comparten sin acoplarse a implementaciones concretas.
*   `components/`: Nodos puramente lógicos bajo el patrón de Composición (ej. `HitboxComponent`, `JuiceScaleComponent`). **Regla:** Deben ser "Plug & Play", sin depender del nodo padre específico en el que se instancien.
*   `ui_elements/`: Componentes visuales estandarizados (Botón de pausa global, transiciones de pantalla, modales genéricos).
*   `global_assets/`: Recursos físicos. **Regla:** Solo archivos que aplican al 100% del proyecto (tipografía corporativa, música de fondo del Hub, paleta de colores global).

### 6.3. `res://features/` (Los Cartuchos)
Módulos de dominio aislados. Contienen el producto final consumible.
*   `hub_main/`: Escenas, scripts y assets exclusivos del menú principal y el álbum de stickers.
*   `minigames/`: Contenedor principal de módulos de juego.
    *   `mg_balloons/`: Aislamiento total del minijuego de globos. **Regla de Oro: Ningún archivo dentro de esta carpeta puede ser referenciado, importado o invocado por otro minijuego.**
        *   `assets/`: Texturas y audios exclusivos (`vo_inst_rojo.ogg`).
        *   `components/`: Lógica de composición exclusiva de este minijuego (ej. `FloatUpwardComponent`).
        *   `resources/`: Configuraciones específicas inyectables (`.tres` para balance de dificultad o hitos).
        *   *(Archivos raíz del feature)*: `mg_balloons_main.tscn` y `mg_balloons_main.gd` (este último `extends MinigameBase`).

## 7. Testabilidad y Calidad (Seam para Escalar)

Arquitectura limpia significa poder verificar la lógica sin abrir el juego. Diseñar los *seams* ahora es barato; retrofitear tests sobre código acoplado al `SceneTree` es caro.

*   **Lógica pura separada del nodo:** las reglas testeables (evaluación de hitos de sticker, serialización/deserialización del save, cálculo de `MinigameResult`) viven en clases sin dependencia del árbol (`RefCounted`/`static func`), invocadas por los autoloads. Así se testean de forma unitaria y determinista.
*   **Framework:** GUT (Godot Unit Test) para las suites de lógica pura. Prioridad de cobertura en MVP: (1) migración/robustez del save (GDD §7.3), (2) lógica de hitos de progresión, (3) parsing de `LevelConfig`.
*   **Determinismo:** la lógica de negocio no lee `Time`/`randi` directamente; recibe esos valores por parámetro (inyección) para poder fijarlos en tests.
*   **Presupuesto MVP:** no se busca cobertura total. Se testea lo que, si se rompe en silencio, corrompe datos del niño o su progreso (save y progresión). El gameplay se valida jugando.

## 8. Arquitectura de Audio (`AudioManager`)

El audio es servicio, no evento: se invoca por **llamadas** (§2A caso 4), nunca por señales globales. Diseñado para latencia baja y bajo consumo en tablet.

### 8.1. Buses (Audio Bus Layout)
Tres buses hijos de `Master`, con volumen independiente y persistible a futuro:
*   `Music` — música de fondo (Hub, ambiente de minijuego). Un solo stream a la vez, con *loop*.
*   `SFX` — efectos cortos (pop, plop seco, celebración).
*   `VO` — voz en off (instrucciones, refuerzos hablados). Prioridad narrativa.

### 8.2. *Ducking* de música bajo la voz
La VO debe entenderse siempre. Al reproducir un clip de VO, `AudioManager` atenúa el bus `Music` (~-12 dB) mediante un `Tween` de `volume_db` y lo restaura al terminar (señal `finished` del reproductor de VO). Solución simple, determinista y sin coste de CPU de un compresor sidechain — suficiente para el MVP.

### 8.3. Integración con Low-Stim (§4B)
Cuando `SettingsManager.low_stim_mode` es `true`, `AudioManager` aplica un **perfil suave**: baja el nivel global de `SFX`, evita sonidos estridentes/agudos (variantes de clip más cálidas o pitch/volumen reducido) y suaviza los ataques. Es un beneficio secundario de rendimiento (menos voces simultáneas).

### 8.4. Rendimiento y latencia (móvil)
*   **Precarga:** todos los `AudioStream` (formato **`.ogg` Vorbis**, mono, cortos) se `preload()` — jamás se carga desde disco en el momento del *tap*, para cumplir el presupuesto de <100 ms de juice (GDD §3).
*   **Pool pequeño de reproductores de SFX:** un conjunto fijo y reducido de `AudioStreamPlayer` reutilizados round-robin, en lugar de instanciar/`queue_free` uno por disparo. (Este es el *único* pooling justificado del MVP: los taps de SFX pueden solaparse rápido; ver contraste con §2B.)
*   **Límite de polifonía:** tope de voces simultáneas de SFX para evitar saturación auditiva (mala para la audiencia) y picos de CPU.
*   **VO no se solapa:** política de un clip de VO a la vez (el nuevo interrumpe o encola al anterior); nunca dos voces hablando encima.

### 8.5. API de servicio (borrador)
```gdscript
AudioManager.play_sfx(sfx_id: StringName) -> void
AudioManager.play_vo(vo_id: StringName) -> void      # aplica ducking + política de no-solape
AudioManager.set_music(track_id: StringName) -> void # crossfade suave entre pistas
AudioManager.stop_vo() -> void
```
*   **Robustez:** un `id` inexistente registra un `push_warning` y no reproduce nada — nunca crashea ni bloquea el juego del niño.