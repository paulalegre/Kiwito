# Dirección de Arte y Diseño Sensorial (DA v1.3)

**Proyecto:** MVP Plataforma Minijuegos Educativos 2D
**Lienzo de diseño:** 1920x1080 (16:9 landscape) — *lienzo, no promesa de recorte* (ver GDD, nota de plataforma)
**Público:** Primera infancia, 3 a 8 años
**Estado:** Propuesta de dirección para aprobación. Cierra el punto pendiente de [Propuesta_MVP §11](./Propuesta_MVP.md).

> **Historial de revisión.**
> - **v1.1** — cambio de técnica en §3, confirmado con referencias reales de Sago Mini: se elimina el contorno y el sombreado con degradado/grano de la v1.0, sustituidos por **falso volumen mediante superposición de formas planas** y **abstracción facial** (ojos-punto, sin esclerótica).
> - **v1.2** — profundiza §3 con parámetros exactos de producción: regla universal de vértices redondeados (no solo en interactivos), anatomía de extremidades "salchicha" (§3.4), rostro como componente reutilizable/*prefab* (§3.3), composición de fondos por capas lista para `ParallaxLayer` (nueva §3.5), sombra de contacto fijada a 20% de opacidad, y la única excepción de degradado del proyecto (cielo lejano nocturno). Añade tabla-resumen paramétrica (§3.6) y especifica el icono de acceso "Padres" (§5.4). El resto del documento (paleta, tipografía, movimiento, tamaños táctiles, feedback) no cambia.
> - **v1.3** — matiza §3.3: el *prefab* facial pasa de regla absoluta a **regla por defecto con excepción documentada**, para personajes cuyo rasgo facial distintivo es parte de su identidad o cuyo caso de uso educativo lo requiere.

> **Documentos hermanos.** Este documento es la **fuente de verdad visual y sensorial**. No repite decisiones de mecánica ni de ingeniería:
> - **[GDD_MVP.md](./GDD_MVP.md)** — mecánica, UX y accesibilidad de juego.
> - **[Core_Architecture.md](./Core_Architecture.md)** — arquitectura técnica, escalado, audio.
>
> Donde este documento fija un valor (un color, un tamaño, una duración), ese valor es **normativo** para los assets y las escenas.

---

## 1. Declaración de estilo (la decisión de una línea)

> **Soft Vector Flat-Art: formas redondeadas construidas con primitivas geométricas, sin contorno, volumen falso por superposición de planos de color, colores suaves con acentos vivos, animación expresiva de baja complejidad y una interfaz casi invisible.**

La referencia de lenguaje es la familia de apps preescolares tipo *Sago Mini*: mundos pequeños, cálidos y sin ruido, donde **el objeto interactivo es lo más brillante de la pantalla** y todo lo demás se retira. No se copian personajes, marcas ni assets de ninguna franquicia; se adopta la **técnica**: geometría simple, cero contorno, abstracción facial y jerarquía por contraste.

> **Nota de revisión (confirmado con referencias reales).** La v1.0 de este documento describía el estilo con contorno a mano y sombreado plano de 2 tonos con textura de grano — una hipótesis razonable pero genérica. Al analizar capturas reales de Sago Mini, el lenguaje real es **más radical y más barato de producir**: cero contorno, cero degradado, cero textura interna; el volumen se sugiere superponiendo formas planas del mismo color o de un tono muy cercano. Este documento adopta esa versión más específica en §3 porque está respaldada por evidencia visual concreta y porque reduce aún más el coste de producción y de render en tablets de gama baja (Arq. §0) — el mismo objetivo que ya perseguía la v1.0, mejor cumplido.

### Por qué esta dirección y no otra

| Alternativa | Por qué se descarta |
| --- | --- |
| 3D / semirrealismo | Coste de producción y de GPU incompatible con `GL Compatibility` en tablets de gama baja (Arq. §0). Envejece peor. |
| "Corporate flat" (vector plano genérico, iconografía fría) | Comparte la ausencia de contorno y sombreado, pero le falta calidez: paletas frías uniformes, sin abstracción facial expresiva, sin jerarquía cálido/frío entre personaje y fondo. Nuestra versión es flat **pero cálida** — la diferencia la hace el color y la expresión, no el detalle. |
| Saturación total tipo "juego de móvil casual" | Destruye la jerarquía visual y choca frontalmente con el Modo Low-Stim, que dejaría de ser un modo para ser una corrección. |

### Los cinco principios visuales (no negociables)

1. **Una sola cosa manda en pantalla.** En cada escena hay un objetivo visual dominante; el resto baja de contraste, saturación o tamaño.
2. **El fondo nunca compite.** Fondos desaturados, sin detalle fino, sin patrón que pueda leerse como "objeto tocable".
3. **Si brilla, se toca.** El brillo, el rebote y la saturación alta son **vocabulario de interactividad**, no decoración. Un elemento no interactivo jamás se anima solo para "dar vida".
4. **El color nunca informa solo.** Toda regla comunicada por color lleva un segundo canal: forma, patrón, movimiento o sonido (GDD §3).
5. **Calma por defecto, energía a demanda.** El estado de reposo de la app es tranquilo; la energía aparece **como respuesta al niño**, no antes de que actúe.

---

## 2. Paleta global

La paleta se divide en tres roles con función distinta. Está pensada para pantalla de tablet con brillo exterior, y para que la capa de gameplay se despegue del fondo por **luminancia**, no solo por tono.

### 2.1. Base (fondos y superficies) — nunca compiten

| Rol | Nombre | Hex | Luminancia rel. | Uso |
| --- | --- | --- | --- | --- |
| Fondo principal | Crema papel | `#FBF3E4` | 0.90 | Fondo del Hub, del álbum, de modales. |
| Fondo secundario | Arena | `#F3E7D3` | 0.81 | Superficies apiladas, tarjetas, celdas del álbum. |
| Ambiente frío | Menta | `#CFE7DA` | 0.76 | Cielo/fondo del minijuego de globos. |
| Ambiente cálido-frío alt. | Lavanda clara | `#D9D3EC` | 0.67 | Variante de escena, modo noche suave (Fase 2). |
| Tinta | Marrón tinta | `#3B3028` | 0.03 | Tipografía, siluetas de stickers bloqueados, puntos de ojos/boca (abstracción facial, §3.3). |

> **Regla:** el texto usa **Tinta sobre Crema** (contraste 11.6:1, muy por encima del 4.5:1 exigido). **Nunca** negro puro `#000000` sobre blanco puro `#FFFFFF`: es agresivo en pantalla brillante y ajeno al lenguaje de libro ilustrado. La Tinta **no** se usa como color de contorno (§3.1: el estilo no lleva contorno) — su uso está limitado a texto, rasgos faciales y siluetas bloqueadas del álbum.

### 2.2. Colores de juego (los 4 del `MATCH_COLOR`) — escalera de luminancia

Este es el punto **crítico de accesibilidad** del MVP: la mecánica pedagógica central es discriminar color, y ~1 de cada 12 niños tiene deficiencia de visión al color (GDD §3). La mitigación no es cosmética, es estructural: los cuatro colores forman una **escalera de luminancia monótona** con separación mínima ΔL ≥ 0.12, de modo que **siguen siendo distinguibles en escala de grises**.

| Color | Hex | Luminancia rel. | ΔL con el anterior | Rasgo no-cromático (patrón) |
| --- | --- | --- | --- | --- |
| Amarillo sol | `#F2C14E` | 0.576 | — | **Estrellas** pequeñas |
| Verde hoja | `#5FB65A` | 0.366 | 0.21 | **Rayas** diagonales |
| Rojo coral | `#E2574C` | 0.235 | 0.13 | **Lunares** (topos) |
| Azul océano | `#245C9E` | 0.105 | 0.13 | **Zigzag** |

- **Verificación obligatoria antes de aprobar assets:** convertir la lámina de los 4 globos a escala de grises. Si dos no se distinguen, el color está mal elegido, no el niño mal visto.
- **El patrón vive en una capa separada** del sprite del globo (`Sprite2D` hijo con la textura de patrón, alfa modulable). Esto permite: (a) atenuarlo al 15–25% de opacidad en el modo estándar para no recargar visualmente, (b) subirlo al 100% en un futuro "modo alto contraste", (c) reutilizar el mismo globo base para los 4 colores vía `modulate` — **4 texturas de patrón en vez de 4 globos completos**.
- **El patrón se declara en `LevelConfig`**, junto al color, como especifica el GDD §3. Un color sin patrón asignado es un error de datos, no un caso válido.

### 2.3. Acentos de sistema (UI y feedback)

| Rol | Nombre | Hex | Uso |
| --- | --- | --- | --- |
| Acción / navegación | Azul cielo | `#4E9BE0` | Botón Casa, botones del menú de pausa. |
| Éxito / celebración | Verde brote | `#7ED08A` | Destellos de acierto, marco del sticker desbloqueado. |
| Atención (nunca "error") | Ámbar suave | `#F0B23F` | Pulso del recuadro de meta en la ayuda escalonada. |
| Neutro de rechazo | Gris cálido | `#B9AEA0` | Feedback de toque incorrecto: **sin rojo**. |

> **Decisión deliberada: no existe un "color de error".** El rojo puro está reservado a nada, porque el rojo ya es un **color jugable** (`#E2574C`) y porque el proyecto tiene una política de Cero Castigos (Propuesta §1). Un toque incorrecto se comunica con **movimiento (shake) + sonido opaco + gris cálido**, jamás con un aspa roja.

### 2.4. Presupuesto de color por escena

- **Máximo 5 colores dominantes** visibles simultáneamente por escena, contando fondo.
- El fondo aporta **1**; el objetivo interactivo aporta el acento saturado; el resto se mantiene en la base.
- Los 4 colores de juego **solo** aparecen a plena saturación en los globos y en el recuadro de meta. La UI nunca los usa (evita que el niño confunda un botón con un objetivo).

### 2.5. Implementación

La paleta vive en **`res://shared/global_assets/palette.tres`** (un `Resource` con constantes `Color` tipadas), coherente con Arq. §6.2 ("paleta de colores global" es explícitamente un `global_asset`). **Prohibido escribir literales hex en escenas o scripts.** El color de un globo se resuelve desde `LevelConfig`, que referencia la paleta — nunca al revés.

---

## 3. Lenguaje de formas y materialidad

### 3.1. Forma

- **Todo se construye sobre primitivas geométricas:** círculos, óvalos, triángulos de esquina redondeada y rectángulos de esquina muy redondeada. Un árbol es un círculo sobre un rectángulo; un pino es dos o tres triángulos superpuestos; una nube es un racimo de círculos blancos superpuestos. No se dibuja detalle que no sea una primitiva reconocible.
- **Vértices redondeados — regla universal, no solo interactiva.** Prohibido cualquier ángulo de 90° exacto o punta afilada en **cualquier** vector del proyecto, sea interactivo o de ambiente (montañas, nubes, contenedores de UI). Todo vértice lleva *corner radius*; los picos leen como "peligro" y rompen la calidez incluso en un elemento decorativo. Los valores concretos para UI ya están fijados en §5.1 (radio mínimo 24 px, 48 px en contenedores grandes); para formas orgánicas de personaje/naturaleza el criterio es el mismo principio, sin un valor fijo — si un vértice se ve puntiagudo al ojo, se redondea más.
- **Silueta primero.** Todo personaje u objeto interactivo debe ser reconocible **relleno de negro a 64 px de alto**. Si la silueta no lo identifica, el diseño se rehace. Sin contorno que ayude a definir el borde (ver abajo), este test es aún más crítico que en un estilo con línea.
- **Sin contorno (regla dura).** Ningún sprite lleva línea de borde, ni en Tinta ni en tono oscurecido. La separación entre planos se logra por **superposición de formas**, nunca por una línea que las delimite. Es la corrección más importante frente a la v1.0 de este documento (ver nota de §1) y coincide con el asset placeholder actual (`design/globo.png`), que **queda desactualizado** y debe rehacerse sin contorno, sin brillo y sin degradado (ver §8, pendiente de producción).

### 3.2. Falso volumen (sin textura, sin sombreado con degradado)

Nada de "materialidad artesanal": el estilo es **vector plano puro**, y esa planitud es la fuente de su bajo coste. El volumen se sugiere, no se pinta.

- **Técnica de falso volumen:** una forma secundaria plana se superpone a la forma base para sugerir un plano distinto (una mejilla, la panza de un animal, la curva superior de un globo). Esa forma secundaria usa **el mismo color base, o un único tono plano a ±6–8% de luminancia** — nunca un degradado. Máximo **dos tonos planos por objeto** (base + una forma de acento).
- **Cero textura interna.** Sin grano de papel, sin patrón de témpera ni fieltro. Una nube es un racimo de círculos blancos sólidos, no una nube con motas. (La única textura del proyecto es el patrón no-cromático de accesibilidad de los globos, §2.2 — esa es funcional, no decorativa, y por eso se mantiene.)
- **Prohibido:** contorno, brillo especular (el reflejo clásico de globo), degradados de cualquier número de paradas, sombras proyectadas realistas, textura de grano/papel, partículas de "polvo mágico" permanentes.
- Sombra de contacto: una elipse oscura translúcida a **20% de opacidad** (alfa fijo, sin degradado interno) bajo los objetos apoyados en el suelo. Es la única "sombra" permitida en todo el vocabulario visual — su función es anclar el objeto al entorno, no simular luz.
- **Excepción única y acotada al gradiente — cielos de ambiente lejano.** El único lugar del proyecto donde se permite un degradado es un **cielo de fondo lejano** (capa de `ParallaxLayer` más profunda, §3.5), y solo para leer atmósfera/profundidad — nunca en un personaje, objeto interactivo o pieza de UI. Reservado para la variante nocturna (§12, pendiente): tonos de azul oscuro a turquesa, **nunca negro puro** — el negro absoluto en una pantalla de niño pequeño resulta más inquietante que un azul muy oscuro.

### 3.3. Abstracción facial

La cara es donde más se juega la calidez del estilo, y donde el estado del arte de referencia es más contraintuitivo: **menos detalle, más expresión**.

- **Ojos:** puntos circulares sólidos en **Tinta `#3B3028`** (equivalente a un negro suave; no se introduce un segundo tono de "negro de ojos" separado de la paleta), **sin esclerótica blanca y sin brillo/highlight**. Un punto y una posición comunican más que un ojo detallado a esta escala.
- **Nariz / pico:** un óvalo simple superpuesto en el centro del rostro, en Tinta o en un tono plano de acento (§3.2). Nunca más de una primitiva por rasgo.
- **Boca:** una forma sólida simple (arco o línea gruesa de **6–10 px** en el lienzo lógico, el mismo rango que el contorno ya descartado en §3.1 — se reutiliza el grosor, no la técnica). La exageración emocional se logra **escalando la forma** (una boca de llanto es la misma forma, mucho más grande), no añadiendo detalle nuevo (lágrimas, arrugas, dientes).
- **Rostro como componente reutilizable ("prefab" facial) — regla por defecto, no absoluta.** Ojos, nariz/pico y boca se diseñan como **un único set de geometría** (mismo tamaño de punto, mismo grosor de arco) que se reutiliza sin cambios en la **gran mayoría** de personajes y stickers. No se rediseña la cara por personaje salvo motivo concreto — solo cambian el cuerpo y el color base. Esto es lo que mantiene barato cada sticker nuevo ("cuerpo + color", nunca "cara nueva") y permite animar o intercambiar expresiones de forma global.
  - **Excepción justificada:** cuando un rasgo facial distinto **es** la identidad del personaje (p. ej. ojos grandes y ovalados en vez del punto estándar, unas gafas, una forma de pico propia de una especie) o el propio caso de uso educativo lo exige (p. ej. un futuro cartucho de discriminación de formas donde la cara sea el objeto de la mecánica), se permite desviarse del *prefab*. La excepción se documenta junto al personaje que la origina — no se improvisa una cara nueva por comodidad de un solo asset — y sigue heredando el resto del vocabulario de §3.2–§3.3: sin esclerótica, sin brillo/highlight, tonos planos, exageración por escala.
- **Elementos no-personaje también tienen cara si ayuda a la calidez** (p. ej. un sol con ojos-punto y una curva por boca) — mismo vocabulario, mismo *prefab* facial, mismo presupuesto de detalle.
- Cero cejas articuladas, cero pupilas con brillo, cero rubor con degradado. La emoción vive en la forma y en su tamaño relativo, no en el sombreado.

### 3.4. Personajes

El MVP no tiene personaje protagonista (el Hub es un entorno con dos nodos interactivos). Cuando lo tenga — y lo tendrá, porque es el vehículo del onboarding sin texto (GDD §5) — se rige por:

- **1 protagonista + máximo 3 secundarios recurrentes.** Más personajes diluyen el reconocimiento.
- Emociones **amplias y de lectura instantánea** vía la abstracción facial de §3.3: los ojos y la boca hacen el 90% del trabajo; el cuerpo el resto.
- **Extremidades tipo "salchicha".** Brazos y piernas son tubos de grosor constante terminados en semicírculo, sin dedos ni artejos dibujados en manos o pies, y sin articulación marcada en codo/rodilla — la extremidad se curva entera como goma blanda. Elimina de raíz el mayor foco de complejidad anatómica (y de coste de animación) de un personaje 2D simple.
- **Diversidad integrada, no señalizada:** variedad de tonos de piel, cuerpos, capacidades y familias presente de forma natural en el mundo, nunca como una "lección" aparte.
- **Excepción del MVP:** la **mano de onboarding** (la que demuestra el gesto) ya es un personaje de facto. Se diseña con la misma vara: silueta clara, tono de piel neutro-cálido plano (sin sombreado degradado), sin género marcado, sin manga que sugiera un cuerpo concreto.

### 3.5. Composición de fondos por capas (listos para Parallax)

El principio "el fondo nunca compite" (§1) no significa un fondo plano de un solo color: significa **profundidad por capas de siluetas planas**, sin detalle interno en ninguna capa.

- **Técnica:** el fondo se apila en 2–4 capas de siluetas sólidas de distinto tono (más lejos = más claro/frío, más cerca = más oscuro/saturado), nunca con textura ni degradado *dentro* de una capa — la profundidad la da el apilamiento, no el sombreado (única excepción: el cielo lejano de §3.2).
- **Naturaleza en primitivas:** pinos = 2–3 triángulos de esquina redondeada superpuestos sobre un rectángulo delgado; montañas lejanas = curvas suaves de color plano, cero textura interna; nubes = racimo de círculos blancos sólidos (§3.1). Ningún elemento de ambiente se dibuja "a mano" con detalle libre — todo sale del mismo catálogo de primitivas que los objetos interactivos.
- **Mapeo a motor:** esta construcción por capas está pensada para `ParallaxBackground` + `ParallaxLayer` (una capa por plano de profundidad, con `motion_scale` decreciente hacia el fondo). Es una nota de producción, no una obligación del MVP: el Hub actual es estático y no requiere paralaje, pero cualquier fondo nuevo se diseña ya separado en capas para no rehacer el arte cuando se active el movimiento. Detalle de implementación en Godot: fuera del alcance de este documento (ver [Core_Architecture.md](./Core_Architecture.md) si se formaliza).
- **Elementos abstractos por patrón de primitiva:** igual que las nubes, cualquier motivo repetitivo (estrellas, chispas, confeti de fondo) se resuelve como un racimo de círculos pequeños del mismo tono, nunca como una textura o partícula con detalle propio.

### 3.6. Resumen paramétrico (referencia rápida de producción)

Tabla de bolsillo para quien produce el asset — cada valor remite a su regla completa más arriba.

| Parámetro | Valor |
| --- | --- |
| Vértices | Sin ángulos de 90° exactos ni puntas; *corner radius* siempre (§3.1) |
| Contorno | Ninguno, nunca (§3.1) |
| Tonos por objeto | Máx. 2 (base + acento de falso volumen, ±6–8% luminancia) (§3.2) |
| Degradado | Prohibido, salvo cielo lejano en capa de fondo (§3.2, §3.5) |
| Ojos | Punto circular sólido, Tinta `#3B3028`, sin esclerótica ni brillo — por defecto; excepción documentada si el rasgo es identidad del personaje (§3.3) |
| Boca | Arco/línea sólida de 6–10 px lienzo lógico; exageración = escala, no detalle (§3.3) |
| Extremidades | Tubo de grosor constante + semicírculo, sin dedos ni articulación dibujada (§3.4) |
| Sombra de contacto | Elipse translúcida al 20% de opacidad; único tipo de sombra del proyecto (§3.2) |
| Fondo | 2–4 capas de siluetas planas por tono/profundidad, cero textura interna (§3.5) |

---

## 4. Tipografía

El usuario **no sabe leer** (Propuesta §1, "Cero texto"). Por tanto la tipografía **no es un canal de instrucción**; existe solo para el adulto y para cifras marginales.

- **Familia:** sans serif geométrica **redondeada**, con `a` y `g` de una sola planta (formas que el niño reconoce de su aprendizaje escolar). Candidatas libres y embebibles: *Nunito*, *Quicksand*, *Baloo 2*. **Decisión sugerida: Nunito** — legibilidad superior en cuerpos pequeños, cobertura de acentos y `ñ` completa, licencia SIL OFL (redistribuible en la app sin fricción legal).
- **Pesos:** solo dos — `SemiBold (600)` para etiquetas, `Bold (700)` para títulos. Sin cursivas, sin `Light`.
- **Tamaño mínimo:** 32 px en el lienzo 1920x1080. Por debajo de eso no se pone texto: se pone un icono.
- **Interletraje** ligeramente abierto (+2%) y altura de línea 1.4.
- **Color:** Tinta `#3B3028` sobre base clara. Nunca texto claro sobre fondo oscuro en superficies grandes.
- **Regla dura:** **ningún botón se identifica solo por texto.** Todo botón lleva icono; el texto, si aparece, es refuerzo secundario. Esto también elimina el 90% del coste de localización futura.
- Ubicación: `res://shared/global_assets/` (la "tipografía corporativa" de Arq. §6.2).

---

## 5. Layout, zona segura y tamaños táctiles

### 5.1. Rejilla y zona segura

- **Unidad base: 8 px.** Todo espaciado, tamaño y radio es múltiplo de 8. Elimina discusiones y produce ritmo visual coherente.
- **Margen de seguridad: 8%** del lienzo → **154 px horizontales, 86 px verticales** (GDD, nota de plataforma). Ningún elemento interactivo ni información crítica entra en esa banda; es territorio de fondo, exclusivamente.
- Toda la UI se ancla con `Control` *anchors* a las esquinas, **nunca** a coordenadas absolutas (Arq. §0).

### 5.2. Tamaños táctiles — derivación explícita

El estándar de la industria es **48–64 dp mínimo**, y más para preescolares. Traducido a nuestro lienzo lógico: una tablet de ~10" presenta el ancho útil en torno a **~1280 dp**, así que **1 px lógico ≈ 0.67 dp**. De ahí:

| Elemento | Sprite visible (px lógicos) | ≈ dp | Hitbox (+30%, Arq. §4A) |
| --- | --- | --- | --- |
| **Mínimo absoluto** de cualquier interactivo | 120 | ~80 | 156 |
| Globo (objetivo de gameplay) | 180–220 de alto | ~120–147 | 234–286 |
| Botón Casa | 140 | ~93 | 182 |
| Nodo del Hub (Caja de Globos, Libro Mágico) | 320+ | ~213 | 416 |
| Celda del álbum de stickers | 200 | ~133 | 260 |
| CTA único de pantalla (ej. "Continuar" del menú de pausa) | 260–320 | ~174–213 | hasta 400+ |

- **Separación mínima entre dos elementos interactivos: 64 px** entre bordes de *hitbox*, no de sprite. Dos hitboxes ampliados que se solapan producen toques ambiguos — exactamente lo que el consumo de evento de Arq. §4A intenta arbitrar; mejor evitar el conflicto en el layout.
- **Excepción deliberada — el CTA único.** Cuando una pantalla tiene **una sola** acción posible (p. ej. el botón "Continuar" del menú de pausa), no aplica el tope de 120–220 px: puede — y debe — ser notablemente más grande que cualquier otro interactivo del juego, ocupando una porción sustancial de la zona inferior central. La referencia de Sago Mini confirma este patrón (círculo de color vibrante + icono blanco simple, sin texto). Este juego no tiene pantalla de "play" en el MVP (arranca directo al Hub, Propuesta §1), así que la excepción aplica hoy solo al menú de pausa.
- El asset actual `design/globo.png` (189x435 px) tiene la **proporción correcta** (alta y estrecha, con nudo) y se conserva a ese tamaño, pero su **acabado visual no** — lleva contorno, brillo especular y degradado, incompatibles con §3.1–§3.2. Queda marcado como pendiente de rehacer en §12.

### 5.3. Composición por escena

- **Hub:** los dos nodos interactivos ocupan el tercio central-inferior, separados horizontalmente, ambos con espacio libre alrededor. El botón Casa **no existe en el Hub** (no hay a dónde escapar): en su lugar, la esquina superior izquierda queda vacía, para que el niño aprenda que **esa posición siempre significa "salir"** cuando sí aparezca.
- **Minijuego:** franja superior reservada a la UI persistente (Casa a la izquierda, recuadro de meta a la derecha, ambos dentro de la zona segura). Los dos tercios inferiores son zona de juego limpia. Los globos ascienden por el eje Y — **no se coloca nada tocable en su trayectoria** que pueda recibir un toque destinado a un globo.
- **Álbum:** rejilla de celdas grandes, siluetas en Tinta al 100% de opacidad para lo bloqueado y arte a color para lo desbloqueado. El contraste entre ambos estados es de **luminancia**, así que se lee sin depender del color.

### 5.4. UI flotante, sin chrome de ventana

La interfaz **flota directamente sobre la escena**: nada de recuadros con borde, marcos ni ventanas modales con barra de título. Un modal (p. ej. el Álbum) se resuelve como una superficie de esquinas muy redondeadas (§3.1) sobre un velo translúcido que atenúa el fondo, no como una "ventana" con chrome. Los botones nunca llevan caja rectangular visible: son la forma del icono, punto — el círculo del CTA (§5.2) *es* el botón, no un contenedor que lo envuelve.

- **Excepción explícita — el acceso "Padres":** es el único elemento de la UI que se diseña deliberadamente **para no atraer el toque de un niño**, en contra de la regla "si brilla, se toca" (§1). Icono universal (p. ej. un candado o una silueta de adulto), **monocromático** en un gris neutro de baja saturación, tamaño pequeño en una esquina — nunca a plena saturación, nunca del tamaño mínimo interactivo de §5.2. Detalle completo pendiente en §12.

---

## 6. Movimiento: el presupuesto de animación

La animación es la mitad del carácter del juego y la fuente de riesgo de sobreestimulación. Se rige por presupuesto, no por gusto.

### 6.1. Duraciones normativas

| Evento | Duración | Curva |
| --- | --- | --- |
| Respuesta al toque (escala/rebote) | **≤ 100 ms** al primer fotograma perceptible (Arq. §4B) | `EASE_OUT`, `TRANS_BACK` |
| Acción común (explotar, abrir, aparecer) | 200–400 ms | `EASE_OUT`, `TRANS_CUBIC` |
| Transición de escena (fundido) | 350–500 ms por lado | `TRANS_SINE` |
| Celebración de fin de nivel | ≤ 1200 ms | escalonada, no simultánea |
| Reposo (respiración, flotar) | ciclo de 2–4 s | `TRANS_SINE`, ida y vuelta |

**Nada dura más de 0,8 s en el bucle de acción.** El niño de 3 años no espera; una animación de recompensa larga se percibe como pérdida de control.

### 6.2. Vocabulario de movimiento

- **Squash & stretch moderado:** máximo ±12% de deformación. Suficiente para leer como elástico, insuficiente para marear.
- **Anticipación mínima:** un objeto que va a explotar se comprime ~4% durante 60 ms antes. Es lo que hace que el toque se sienta "físico".
- **Reposo vivo pero lento:** los globos flotan con una oscilación horizontal suave (±8 px, 3 s de ciclo). El Hub tiene **como máximo dos** elementos en animación de reposo simultánea.
- **Escalonamiento (stagger):** cuando varias cosas aparecen a la vez (celdas del álbum, globos de una tanda), se desfasan 60–80 ms entre sí. Nunca todo a la vez.

### 6.3. Lo prohibido

- Parpadeos, estroboscopios o flashes de pantalla completa (riesgo real, no estético).
- Partículas persistentes de ambiente. Las partículas son **puntuales y consecuencia de una acción**.
- Dos animaciones que compiten por la atención en el mismo momento.
- Rotación continua o pulsos infinitos en elementos que no son interactivos.
- Cualquier estética de ruleta, cofre, giro de premio o caja sorpresa. **Es una prohibición de producto, no de arte** (Propuesta §1, Cero castigos / sin loot boxes).

### 6.4. Contrato del Modo Low-Stim

El Modo Low-Stim (Arq. §4B) tiene una traducción visual **exacta y verificable**, no interpretativa. Cuando `SettingsManager.low_stim_mode == true`:

| Parámetro | Estándar | Low-Stim |
| --- | --- | --- |
| Partículas por evento | 100% | **0** (se sustituye por un anillo de escala única) |
| Destellos / flashes | permitidos (breves) | **eliminados** |
| Saturación de acentos | 100% | **–30%** (vía `CanvasModulate` o `modulate` del contenedor) |
| Animaciones de reposo simultáneas | máx. 2 | **máx. 1** |
| Duración de celebración | ≤ 1200 ms | ≤ 700 ms, un solo elemento |
| Shake de error | ±6 px, 200 ms | ±3 px, 150 ms |
| Amplitud de squash & stretch | ±12% | ±6% |

**Criterio de aceptación:** un adulto que active el modo debe **percibir la diferencia en menos de 5 segundos de juego**. Si no la nota, el modo no está implementado, está declarado.

---

## 7. Vocabulario de feedback (la tabla que evita discusiones)

Cada evento del juego tiene una firma audiovisual fija. Toda la app la respeta; así el niño aprende el idioma una vez y le sirve en todos los cartuchos futuros.

| Evento | Visual | Audio (bus) | Duración |
| --- | --- | --- | --- |
| **Toque válido (pop)** | Globo se comprime 4% → estalla en 6–8 fragmentos que caen y se desvanecen | `pop_0X` variado (SFX) | 300 ms |
| **Toque incorrecto** | Shake horizontal ±6 px, tinte gris cálido al 20% por 150 ms. **Sin rojo, sin aspa.** | plop seco y grave (SFX) | 200 ms |
| **Ayuda nivel 1** | Recuadro de meta pulsa en escala 1.0→1.12→1.0, halo ámbar | VO breve "¡Busca este!" (VO, con ducking) | 600 ms, repetible |
| **Ayuda nivel 2** | Globos objetivo con halo suave + rebote lento **no-cromático** | ninguno (evita saturar) | ciclo de 1,5 s |
| **Fin de nivel** | Confeti escalonado desde el centro + globo(s) restante(s) que ascienden y salen | jingle corto ascendente (SFX/Music) | ≤ 1200 ms |
| **Sticker desbloqueado** | La silueta del álbum se rellena de color con un barrido + marco Verde brote | campanilla cálida (SFX) + VO opcional | 900 ms |
| **Transición Hub↔Minijuego** | Fundido a Crema (no a negro) que **cubre la carga** | ducking de música, sin SFX | 350–500 ms |

> **Fundir a crema, no a negro.** El negro pleno en pantalla es una interrupción brusca y ligeramente ansiógena para un niño pequeño; el fundido a `#FBF3E4` mantiene la continuidad del mundo. Aplica al `ui_elements/transitions/` de Arq. §1.2.

**Regla transversal (accesibilidad auditiva):** todo mensaje sonoro relevante tiene equivalente visual, y viceversa. Ningún estado del juego se comunica **solo** por sonido — porque el dispositivo puede estar silenciado, y porque hay niños con pérdida auditiva.

---

## 8. Producción de assets (especificación técnica)

Alineado con Arq. §0 (`GL Compatibility`, tablets de gama media).

| Aspecto | Especificación |
| --- | --- |
| Formato de autoría | PSD / vectorial, con capas separadas (forma base, formas de acento para falso volumen §3.2, patrón de accesibilidad). **Sin capa de contorno ni de sombreado degradado.** |
| Formato de entrega | **PNG con alfa premultiplicado desactivado**, sRGB |
| Resolución de entrega | **1.5× el tamaño de uso en el lienzo lógico** — margen para tablets de alta densidad sin pagar 2× en memoria |
| Atlas | Uno por dominio (`mg_balloons`, `hub_main`, `ui`). **Nunca** un atlas que cruce features — rompería el aislamiento de cartuchos (Arq. §6.3) |
| Compresión de importación | `VRAM Compressed` para sprites grandes; `Lossless` para UI e iconos pequeños con bordes duros |
| Mipmaps | Desactivados en 2D salvo elementos que escalan de forma continua |
| Tamaño máximo por textura | 2048x2048. Nada de 4K para elementos pequeños |
| Nomenclatura | `snake_case`, prefijo de dominio: `balloon_base.png`, `balloon_pattern_stars.png`, `hub_book.png`, `ui_icon_home.png` |

**Estrategia de coste (relevante para el MVP):** el globo se produce **una sola vez** en blanco/gris y se tiñe con `modulate` desde la paleta. Los 4 patrones son 4 texturas pequeñas en escala de grises. Total: **5 assets** cubren los 4 colores × 2 estados, en lugar de 8+ ilustraciones completas. Los stickers, siendo "variaciones estéticas de los globos" (GDD §6), heredan esta misma base y solo añaden el accesorio (gafas, sombrero) como capa.

---

## 9. Ritmo de sesión y diseño anti-compulsión

La estética también comunica un modelo de negocio y una ética. Esta dirección de arte **excluye por construcción** el vocabulario visual de la compulsión:

- **Nada de:** contadores regresivos visibles, barras de racha, cofres, ruletas, gemas, monedas, insignias de "no rompas tu racha", badges de notificación rojos.
- **Sí:** progreso como **colección visible y contemplable** (el álbum), recompensas **narrativas y creativas**, y un cierre de sesión que **no empuja a una partida más**.
- **El final es amable:** al terminar un nivel, el retorno al Hub es automático a los 4 s (GDD §5). El Hub en reposo es tranquilo y no lanza ningún reclamo. Si el niño se va, no pierde nada; si vuelve, todo está donde lo dejó.

El objetivo de la dirección de arte, medido: que el niño diga **"quiero volver a este mundo"** y el adulto piense **"puedo confiar en esto"**. Un mundo al que se quiere volver no necesita retenerte.

---

## 10. Adaptación por tramo de edad (una estética, dos lecturas)

El rango 3–8 es demasiado ancho para una única curva, pero **no requiere dos estéticas** — eso duplicaría el coste y fragmentaría la identidad. La adaptación es de **densidad**, no de estilo:

| Tramo | Ajuste visual (todo vía `LevelConfig`, cero arte nuevo) |
| --- | --- |
| 3–4 años | Menos elementos en pantalla, sprites en el extremo alto del rango de tamaño, movimiento lento, patrones no-cromáticos al 25% |
| 5–6 años | Densidad media, tamaños nominales, más señuelos simultáneos |
| 7–8 años | Mayor densidad y velocidad, sprites en el extremo bajo del rango, composiciones con más profundidad de escena |

La regla de estilo que impide que el juego se sienta "de bebé" para un niño de 8 años no es hacerlo más oscuro o más serio: es **respetar su inteligencia con composiciones más ricas y retos con más piezas**, manteniendo exactamente la misma calidez.

---

## 11. Checklist de validación por pantalla

Antes de dar por buena cualquier escena o asset:

**Legibilidad**
- [ ] ¿Un niño que no sabe leer entiende qué hacer sin ninguna palabra?
- [ ] ¿Hay **una** acción claramente prioritaria?
- [ ] ¿El objeto interactivo se distingue del fondo por tamaño, saturación **y** luminancia?
- [ ] ¿La silueta a 64 px sigue siendo reconocible?
- [ ] ¿La captura en escala de grises sigue siendo jugable?

**Estilo (Soft Vector Flat-Art)**
- [ ] ¿El asset no lleva contorno ni brillo especular?
- [ ] ¿El volumen se sugiere por superposición de formas planas, no por degradado?
- [ ] ¿Todo vértice está redondeado, sin ángulos de 90° exactos ni puntas?
- [ ] ¿Los ojos son puntos sólidos sin esclerótica ni brillo (si aplica)? ¿Reutiliza el *prefab* facial salvo excepción documentada?
- [ ] ¿Manos/pies sin dedos y codos/rodillas sin articulación marcada (si aplica)?

**Interacción**
- [ ] ¿Todo interactivo mide ≥120 px de lado (sprite) con hitbox +30%?
- [ ] ¿Hay ≥64 px de separación entre hitboxes?
- [ ] ¿Todo lo tocable está fuera del margen del 8%?
- [ ] ¿La respuesta al toque llega en <100 ms?
- [ ] ¿Se puede fallar sin frustración y sin ver un solo elemento rojo de "error"?

**Carga sensorial**
- [ ] ¿Hay ≤5 colores dominantes en pantalla?
- [ ] ¿Hay ≤2 animaciones de reposo simultáneas (≤1 en Low-Stim)?
- [ ] ¿Ninguna animación del bucle de acción supera 0,8 s?
- [ ] ¿Cada mensaje sonoro tiene equivalente visual y viceversa?
- [ ] ¿La diferencia de Low-Stim se percibe en <5 s?

**Producto**
- [ ] ¿Alguna recompensa apela a azar, escasez o presión? → si sí, se elimina.
- [ ] ¿El niño puede terminar la sesión sin ninguna presión visual?
- [ ] ¿Los colores hex están en `palette.tres` y no incrustados en la escena?

---

## 12. Pendientes que este documento deja abiertos

Deliberadamente fuera del MVP, pero ya encuadrados por esta dirección:

1. **Rehacer `design/globo.png`.** Es el único asset visual existente y no cumple la v1.1 del estilo: tiene contorno, degradado y brillo especular. Se rehace en flat puro (base + 1 forma de acento, sin contorno) manteniendo su proporción actual (189x435, alta y estrecha con nudo) — ver §5.2 y §3.1–§3.2.
2. **Diseño del protagonista y secundarios** (necesario en cuanto haya narrativa; §3.3–§3.4 fijan las reglas).
3. **Modo alto contraste** — la capa de patrón al 100% + acentos reforzados ya está prevista arquitectónicamente (§2.2), falta especificarla.
4. **Variante de ambiente nocturno** (Lavanda `#D9D3EC` reservado). Ya especificada como la única superficie con degradado permitida (§3.2): azul oscuro a turquesa, nunca negro puro; estrellas como racimos de círculos pequeños (§3.5).
5. **Set de audio** — el otro pendiente de Propuesta §11; se rige por Arq. §8 y por la tabla de feedback de §7 de este documento.
6. **Puerta parental** (verificación de adulto para ajustes): visualmente debe ser sobria y deliberadamente **poco atractiva** para un niño — es la única pantalla del juego que puede permitirse ser "aburrida" a propósito. El **icono de acceso** ya está especificado en §5.4 (monocromático, esquina, bajo el tamaño mínimo interactivo); falta diseñar la pantalla de verificación en sí (operación matemática o pulsación prolongada para confirmar que quien toca es un adulto).
