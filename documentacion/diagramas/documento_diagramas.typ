#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 1.0cm, top: 0.8cm, bottom: 0.8cm),
  header: align(right)[
    #text(8pt, fill: rgb("#6b7280"), font: "Liberation Sans")[
      VERTEX // Documentación Técnica de Arquitectura, Persistencia e Ingeniería de Software
    ]
  ],
  footer: context {
    let page_number = counter(page).get().first()
    let total_pages = counter(page).final().first()
    align(center)[
      #text(8.5pt, fill: rgb("#374151"), font: "Liberation Sans")[
        Página #page_number de #total_pages
      ]
    ]
  }
)

#set text(
  font: "Liberation Serif",
  size: 9.5pt,
  lang: "es"
)

#set par(justify: true, leading: 0.55em)

// ==================== PORTADA ====================
#align(center + horizon)[
  #text(12pt, font: "Liberation Sans", fill: rgb("#475569"))[
    PLATAFORMA EDUCATIVA DE CIBERSEGURIDAD
  ]
  
  #v(0.8cm)
  #text(22pt, weight: "bold", fill: rgb("#0f172a"))[
    ESPECIFICACIÓN DE ARQUITECTURA, PERSISTENCIA Y MODELADO UML 2.5 \
    SUITE DE DIAGRAMAS (FIGURAS 1 A 7) Y DICCIONARIO DE DATOS
  ]
  #v(0.4cm)
  #text(13pt, style: "italic", fill: rgb("#1e3a8a"), font: "Liberation Sans")[
    "VERTEX: Plataforma Educativa de Ciberseguridad basada en Teoría de Grafos"
  ]
  
  #v(1.0cm)
  #grid(
    columns: (1fr, 1fr),
    align: (left, right),
    [
      #text(9.5pt, font: "Liberation Sans")[
        *Proyecto de Software:* \
        • Sistema VERTEX (Godot Engine / Data-Driven) \
        • Modelo de Grafo Ponderado $G=(V, E)$ \
        • Aislamiento Multi-Slot y Respaldo Atómico
      ]
    ],
    [
      #text(9.5pt, font: "Liberation Sans")[
        *Estándares de Ingeniería:* \
        • Especificación UML 2.5 (Casos de Uso, Secuencia, Actividades, Clases, FSM) \
        • Diagrama Entidad-Relación Físico (Notación Crow's Foot) \
        • Diccionario de Datos Formal (ANSI/IEEE Std 1059)
      ]
    ]
  )
]

#pagebreak()

// ==================== FIGURA 1 ====================
== Figura 1. Diagrama de Casos de Uso General del Sistema

#text(9pt)[La *Figura 1* presenta el modelo formal de Casos de Uso General del sistema *VERTEX* bajo el estándar UML 2.5, estructurado estrictamente mediante *verbos de acción en infinitivo* de acuerdo con las buenas prácticas metodológicas. Delimita el alcance perimetral del software frente al actor primario (*Operador*) y los servicios secundarios (*Adversario IA* y el subsistema de *Persistencia I/O*). Los casos de uso unifican la administración de ranuras, la formación en academia y la selección y ejecución de los modos tácticos (Heist, Hacker y Ciberdefensa).]

#v(0.05cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 2pt,
    radius: 4pt,
    image("svg/figura_1_casos_de_uso_general.svg", height: 14.8cm, fit: "contain")
  )
  #v(0.05cm)
  #text(8pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 1.* Diagrama de Casos de Uso General del Sistema VERTEX según especificación UML 2.5.
  ]
]

#pagebreak()

// ==================== FIGURA 2 ====================
== Figura 2. Diagrama de Secuencia del Ciclo Reactivo de Ciberdefensa

#text(9pt)[La *Figura 2* ilustra el *diagrama de secuencia* del ciclo reactivo Blue Team. El flujo temporal modela la recepción del evento de bloqueo en `InputHandler`, la delegación hacia el mediador de lógica (`GameLogic`), el sellado de aristas con costo infinito en `NetworkRuntime`, la resolución automática del turno en `DefenderBrain`, el avance del rastreo forense EDR, la respuesta estocástica del atacante (`move_enemy()`) mediante movimiento lateral o exploit `Bypass`, y la actualización de estados en `GameRenderer`.]

#v(0.05cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 2pt,
    radius: 4pt,
    image("svg/figura_2_secuencia_ciberdefensa.svg", height: 14.8cm, fit: "contain")
  )
  #v(0.05cm)
  #text(8pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 2.* Diagrama de secuencia del ciclo de respuesta reactiva 1:1 en modo Ciberdefensa.
  ]
]

#pagebreak()

// ==================== FIGURA 3 ====================
== Figura 3. Diagrama de Actividades de Ciberdefensa (Procesos)

#text(9pt)[La *Figura 3* presenta el *diagrama de actividades (flujo de proceso)* del ciclo de defensa perimetral según el estándar UML. Modela el nodo inicial de inicio de asedio, la bifurcación condicional de acciones del operador (bloqueo de arista, colocación de firewall o aislamiento de host en cuarentena), la resolución del turno de la IA mediante búsqueda de camino mínimo, la evaluación de contingencia por exploit `Bypass`, la ramificación por estado de rastreo forense (Trace EDR $>= 100%$) y los nodos de victoria o derrota.]

#v(0.05cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 2pt,
    radius: 4pt,
    image("svg/figura_3_actividades_ciberdefensa.svg", height: 14.8cm, fit: "contain")
  )
  #v(0.05cm)
  #text(8pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 3.* Diagrama de actividades del ciclo de resolución de Ciberdefensa según estándar UML.
  ]
]

#pagebreak()

// ==================== FIGURA 4 ====================
== Figura 4. Diagrama de Actividades de Infiltración Ofensiva (Modo Hacker)

#text(9pt)[La *Figura 4* ilustra el *diagrama de actividades* del proceso de infiltración ofensiva del modo Hacker (Red Team). Describe la secuencia de decisiones que gobierna el reconocimiento pasivo con `Nmap`, el consumo de exploits (`Bypass`, `Escalate`, `Persist`, `Decoy`), el cálculo y acumulación del nivel de ruido en la red perimetral, la evaluación de umbrales de detección ante la IA centinela (despacho de patrullas y perseguidores), y la finalización del escenario con persistencia de estrellas de maestría.]

#v(0.05cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 2pt,
    radius: 4pt,
    image("svg/figura_4_actividades_hacker.svg", height: 14.8cm, fit: "contain")
  )
  #v(0.05cm)
  #text(8pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 4.* Diagrama de actividades del ciclo de infiltración y balance de ruido en modo Hacker.
  ]
]

#pagebreak()

// ==================== FIGURA 5 ====================
== Figura 5. Diagrama de Clases de Arquitectura (UML 2.5)

#text(9pt)[La *Figura 5* presenta el *diagrama de clases* del núcleo arquitectónico de *VERTEX* bajo el estándar UML 2.5. Modela la separación estricta de responsabilidades entre los recursos inmutables del grafo (`NetworkGraphResource`, `NetworkNodeResource`, `NetworkEdgeResource`), la capa de mutación en memoria (`NetworkRuntime`), los algoritmos deterministas independientes (`DefensivePathfinder` con Dijkstra y `StrategicAnalyzer` con Edmonds-Karp), y los controladores de dominio y presentación (`DefenderBrain`, `GameLogic` y `GameRenderer`).]

#v(0.05cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 2pt,
    radius: 4pt,
    image("svg/figura_5_clases_arquitectura.svg", height: 14.8cm, fit: "contain")
  )
  #v(0.05cm)
  #text(8pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 5.* Diagrama de clases de arquitectura y separación estructural de responsabilidades (UML 2.5).
  ]
]

#pagebreak()

// ==================== FIGURA 6 ====================
== Figura 6. Diagrama Entidad-Relación y Modelo de Persistencia (Crow's Foot)

#text(9pt)[La *Figura 6* presenta el *diagrama de modelo de datos entidad-relación (ERD / Esquema Físico de Persistencia)* de *VERTEX* bajo notación *Crow's Foot* (Pata de Gallo). Modela la estructura transaccional de archivos de configuración alojados en `user://`. El meta-registro `SlotMeta` gobierna el puntero de sesión activa sobre las tres ranuras independientes (`SaveSlot`). Cada ranura aísla la entidad de identidad del agente (`Profile`), el progreso (`LevelProgress`), las métricas históricas (`GlobalStats` y `LevelStats`), las condecoraciones (`BadgeRecord`) y los respaldos rotativos (`SlotSnapshot`).]

#v(0.05cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 2pt,
    radius: 4pt,
    image("svg/figura_6_modelo_datos_persistencia.svg", height: 14.8cm, fit: "contain")
  )
  #v(0.05cm)
  #text(8pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 6.* Diagrama Entidad-Relación y Modelo de Persistencia Transaccional bajo notación Crow's Foot.
  ]
]

#pagebreak()

// ==================== FIGURA 7 ====================
== Figura 7. Diagrama de Máquina de Estados FSM (Dual)

#text(9pt)[La *Figura 7* ilustra el *diagrama de máquina de estados (State Machine / FSM)* dual del sistema: en la partición superior modela el ciclo de vida de los activos de red (`NetworkNode`), transitando desde el estado normal hasta el bloqueo perimetral, la infección por movimiento lateral o el aislamiento físico en cuarentena; en la partición inferior modela el autómata de toma de decisiones del adversario simulado (`Adversary AI FSM`), gobernado por la detección de aristas cerradas, el consumo de exploits `Bypass` y la contención total hacia los estados terminales.]

#v(0.05cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 2pt,
    radius: 4pt,
    image("svg/figura_7_estados_fsm.svg", height: 14.8cm, fit: "contain")
  )
  #v(0.05cm)
  #text(8pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 7.* Diagrama de estados (FSM) del ciclo de vida de los nodos y del autómata reactivo del adversario.
  ]
]

#pagebreak()

// ==================== DICCIONARIO DE DATOS (PARTE 1) ====================
== Diccionario de Datos: Persistencia Transaccional (ANSI/IEEE Std 1059)

El presente diccionario de datos documenta formalmente la arquitectura de almacenamiento de *VERTEX* basada en el motor de serialización `ConfigFile` en la ruta de espacio de usuario `user://`. La persistencia implementa un desacoplamiento modular en tres ranuras (`slot_1`, `slot_2`, `slot_3`), gobernadas por el archivo de control maestro `slots.cfg` y respaldos automáticos en `backups/`.

=== Catálogo de Entidades y Archivos de Persistencia

#table(
  columns: (1.8fr, 2.2fr, 1.2fr, 4.8fr),
  fill: (col, row) => if row == 0 { rgb("#1e293b") } else if calc.even(row) { rgb("#f8fafc") } else { rgb("#ffffff") },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 5pt,
  align: (col, row) => if row == 0 { center } else { left },
  [#text(white, weight: "bold", size: 8.5pt)[Entidad / Tabla]],
  [#text(white, weight: "bold", size: 8.5pt)[Archivo Físico]],
  [#text(white, weight: "bold", size: 8.5pt)[Ámbito]],
  [#text(white, weight: "bold", size: 8.5pt)[Descripción Funcional]],
  
  [*`SlotMeta`*], [`user://slots.cfg`], [Global], [Puntero maestro de ranura activa y banderas de migración heredada.],
  [*`SaveSlot`*], [`user://slots/slot_X/`], [Ranura], [Contenedor de ranura (1..3) con metadatos de integridad y caché de estrellas.],
  [*`Profile`*], [`.../profile.cfg`], [Ranura], [Identidad del analista (alias, icono y color de acento de interfaz).],
  [*`LevelProgress`*], [`.../progress.cfg`], [Ranura], [Registro de estrellas obtenidas y menor coste de camino por escenario.],
  [*`GlobalStats`*], [`.../stats.cfg`], [Ranura], [Métricas históricas agregadas (victorias, derrotas, racha y tiempo de juego).],
  [*`LevelStats`*], [`.../stats.cfg`], [Ranura], [Desglose discreto de victorias y derrotas por nivel táctico.],
  [*`BadgeRecord`*], [`BadgeRegistry`], [Memoria], [Catálogo de méritos, condecoraciones y avance hacia metas operacionales.],
  [*`SlotSnapshot`*], [`.../backups/`], [Ranura / FS], [Instantáneas atómicas rotativas (máx. 5) previas a borrados o modificaciones.]
)

#v(0.2cm)
=== 1. Entidad: `SlotMeta` (Metadatos Globales de Ranuras)
*Archivo:* `user://slots.cfg` | *Sección:* `[slots]`

#table(
  columns: (1.6fr, 1fr, 1.2fr, 1fr, 0.9fr, 1.3fr, 3fr),
  fill: (col, row) => if row == 0 { rgb("#334155") } else if calc.even(row) { rgb("#f8fafc") } else { rgb("#ffffff") },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 4pt,
  align: (col, row) => if row == 0 { center } else { left },
  [#text(white, weight: "bold", size: 7.5pt)[Campo / Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Tipo]],
  [#text(white, weight: "bold", size: 7.5pt)[Rango]],
  [#text(white, weight: "bold", size: 7.5pt)[Nulidad]],
  [#text(white, weight: "bold", size: 7.5pt)[Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Por Defecto]],
  [#text(white, weight: "bold", size: 7.5pt)[Regla de Negocio / Descripción]],
  
  [`config_id`], [String], [32 chars], [NOT NULL], [*PK*], [`meta_global`], [Identificador maestro del archivo.],
  [`active_slot`], [int], [1 .. 3], [NOT NULL], [Atrib], [1], [Índice de ranura activa del operador.],
  [`migrated_legacy`], [bool], [0 / 1], [NOT NULL], [Atrib], [false], [Bandera de migración atómica a slot_1.]
)

#v(0.2cm)
=== 2. Entidad: `SaveSlot` (Contenedor de Ranura)
*Ubicación:* `user://slots/slot_X/` (donde $X in {1, 2, 3}$)

#table(
  columns: (1.6fr, 1fr, 1.2fr, 1fr, 0.9fr, 1.3fr, 3fr),
  fill: (col, row) => if row == 0 { rgb("#334155") } else if calc.even(row) { rgb("#f8fafc") } else { rgb("#ffffff") },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 4pt,
  align: (col, row) => if row == 0 { center } else { left },
  [#text(white, weight: "bold", size: 7.5pt)[Campo / Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Tipo]],
  [#text(white, weight: "bold", size: 7.5pt)[Rango]],
  [#text(white, weight: "bold", size: 7.5pt)[Nulidad]],
  [#text(white, weight: "bold", size: 7.5pt)[Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Por Defecto]],
  [#text(white, weight: "bold", size: 7.5pt)[Regla de Negocio / Descripción]],
  
  [`slot_id`], [int], [1 .. 3], [NOT NULL], [*PK*], [N/A], [Identificador ordinal de la ranura.],
  [`is_empty`], [bool], [0 / 1], [NOT NULL], [Atrib], [true], [Indica ausencia de progreso y perfil.],
  [`updated_at`], [int], [Epoch 64b], [NOT NULL], [Atrib], [0], [Marca de tiempo Unix de última modificación.],
  [`cached_stars`], [int], [0 .. 45], [NOT NULL], [Atrib], [0], [Caché de estrellas para lectura rápida en menú.],
  [`slot_path`], [String], [128 chars], [NOT NULL], [Atrib], [`user://slots/slot_X`], [Ruta normalizada en el sandbox de Godot.],
)

#pagebreak()

// ==================== DICCIONARIO DE DATOS (PARTE 2) ====================
== Diccionario de Datos: Perfil, Progreso, Métricas y Respaldo

=== 3. Entidad: `Profile` (Identidad del Analista)
*Archivo:* `user://slots/slot_X/profile.cfg` | *Sección:* `[profile]`

#table(
  columns: (1.6fr, 1fr, 1.2fr, 1fr, 0.9fr, 1.3fr, 3fr),
  fill: (col, row) => if row == 0 { rgb("#334155") } else if calc.even(row) { rgb("#f8fafc") } else { rgb("#ffffff") },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 4pt,
  align: (col, row) => if row == 0 { center } else { left },
  [#text(white, weight: "bold", size: 7.5pt)[Campo / Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Tipo]],
  [#text(white, weight: "bold", size: 7.5pt)[Rango]],
  [#text(white, weight: "bold", size: 7.5pt)[Nulidad]],
  [#text(white, weight: "bold", size: 7.5pt)[Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Por Defecto]],
  [#text(white, weight: "bold", size: 7.5pt)[Regla de Negocio / Descripción]],
  
  [`profile_id`], [String], [36 chars], [NOT NULL], [*PK*], [UUID], [Identificador único de perfil en la ranura.],
  [`slot_id`], [int], [1 .. 3], [NOT NULL], [*FK*], [N/A], [Referencia a SaveSlot.slot_id.],
  [`player_name`], [String], [1..32 ch], [NOT NULL], [Atrib], [`Operador`], [Alias del analista (alfanumérico sanitizado).],
  [`avatar_icon`], [String], [32 chars], [NOT NULL], [Atrib], [`agent_blue`], [Identificador del glifo de avatar táctico.],
  [`theme_color`], [String], [7 chars], [NOT NULL], [Atrib], [`#00E5FF`], [Hexadecimal para acentos visuales y HUD.],
)

#v(0.15cm)
=== 4. Entidad: `LevelProgress` (Progresión y Puntuación)
*Archivo:* `user://slots/slot_X/progress.cfg` | *Sección:* `[estrellas]`

#table(
  columns: (1.6fr, 1fr, 1.2fr, 1fr, 0.9fr, 1.3fr, 3fr),
  fill: (col, row) => if row == 0 { rgb("#334155") } else if calc.even(row) { rgb("#f8fafc") } else { rgb("#ffffff") },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 4pt,
  align: (col, row) => if row == 0 { center } else { left },
  [#text(white, weight: "bold", size: 7.5pt)[Campo / Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Tipo]],
  [#text(white, weight: "bold", size: 7.5pt)[Rango]],
  [#text(white, weight: "bold", size: 7.5pt)[Nulidad]],
  [#text(white, weight: "bold", size: 7.5pt)[Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Por Defecto]],
  [#text(white, weight: "bold", size: 7.5pt)[Regla de Negocio / Descripción]],
  
  [`level_key`], [String], [32 chars], [NOT NULL], [*PK (Comp)*], [N/A], [Clave del escenario (ej. \"cyber_n1\", \"heist_n2\").],
  [`slot_id`], [int], [1 .. 3], [NOT NULL], [*FK (Comp)*], [N/A], [Vinculación a SaveSlot.slot_id.],
  [`stars`], [int], [0 .. 3], [NOT NULL], [Atrib], [0], [Estrellas de maestría según optimización.],
  [`mejor_coste`], [float], [Float 32], [NOT NULL], [Atrib], [0.0], [Menor peso acumulado de ruta (Dijkstra).],
  [`completed`], [bool], [0 / 1], [NOT NULL], [Atrib], [false], [stars > 0; habilita acceso al siguiente nivel.]
)

#v(0.15cm)
=== 5. Entidades de Estadísticas: `GlobalStats` y `LevelStats`
*Archivo:* `user://slots/slot_X/stats.cfg` | *Secciones:* `[stats]` y `[levels]`

#table(
  columns: (1.6fr, 1fr, 1.2fr, 1fr, 0.9fr, 1.3fr, 3fr),
  fill: (col, row) => if row == 0 { rgb("#334155") } else if calc.even(row) { rgb("#f8fafc") } else { rgb("#ffffff") },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 4pt,
  align: (col, row) => if row == 0 { center } else { left },
  [#text(white, weight: "bold", size: 7.5pt)[Campo / Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Tipo]],
  [#text(white, weight: "bold", size: 7.5pt)[Rango]],
  [#text(white, weight: "bold", size: 7.5pt)[Nulidad]],
  [#text(white, weight: "bold", size: 7.5pt)[Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Por Defecto]],
  [#text(white, weight: "bold", size: 7.5pt)[Regla de Negocio / Descripción]],
  
  [`total_wins`], [int], [$>= 0$], [NOT NULL], [Atrib], [0], [Misiones culminadas con éxito (ambos bandos).],
  [`total_losses`], [int], [$>= 0$], [NOT NULL], [Atrib], [0], [Intentos fallidos (brechas o capturas).],
  [`best_streak`], [int], [$>= 0$], [NOT NULL], [Atrib], [0], [Máxima racha consecutiva de victorias.],
  [`play_time`], [int], [$>= 0$], [NOT NULL], [Atrib], [0], [Tiempo de enlace total en segundos.],
  [`wins / losses`], [int], [$>= 0$], [NOT NULL], [Atrib], [0], [Desglose discreto en sección [levels] por nivel.]
)

#v(0.15cm)
=== 6. Entidades de Soporte: `BadgeRecord` y `SlotSnapshot`

#table(
  columns: (1.6fr, 1fr, 1.2fr, 1fr, 0.9fr, 1.3fr, 3fr),
  fill: (col, row) => if row == 0 { rgb("#334155") } else if calc.even(row) { rgb("#f8fafc") } else { rgb("#ffffff") },
  stroke: 0.5pt + rgb("#cbd5e1"),
  inset: 4pt,
  align: (col, row) => if row == 0 { center } else { left },
  [#text(white, weight: "bold", size: 7.5pt)[Campo / Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Tipo]],
  [#text(white, weight: "bold", size: 7.5pt)[Rango]],
  [#text(white, weight: "bold", size: 7.5pt)[Nulidad]],
  [#text(white, weight: "bold", size: 7.5pt)[Clave]],
  [#text(white, weight: "bold", size: 7.5pt)[Por Defecto]],
  [#text(white, weight: "bold", size: 7.5pt)[Regla de Negocio / Descripción]],
  
  [`badge_id`], [String], [32 chars], [NOT NULL], [*PK*], [N/A], [Identificador canónico de condecoración militar.],
  [`unlocked`], [bool], [0 / 1], [NOT NULL], [Atrib], [false], [Estado de desbloqueo evaluado por BadgeRegistry.],
  [`snapshot_name`], [String], [64 chars], [NOT NULL], [*PK*], [N/A], [Nombre de carpeta (snapshot_ts_tag).],
  [`tag / timestamp`], [Str / int], [Varios], [NOT NULL], [Atrib], [`auto`], [Metadatos de rotación y captura atómica (máx. 5).],
)
