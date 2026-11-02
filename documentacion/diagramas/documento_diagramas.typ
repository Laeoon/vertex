#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 1.5cm, top: 1.2cm, bottom: 1.2cm),
  header: align(right)[
    #text(8pt, fill: rgb("#6b7280"), font: "Liberation Sans")[
      VERTEX // Documentación Técnica de Arquitectura, Persistencia e Ingeniería de Software
    ]
  ],
  footer: context {
    let page_number = counter(page).get().first()
    let total_pages = counter(page).final().first()
    align(center)[
      #text(9pt, fill: rgb("#374151"), font: "Liberation Sans")[
        Página #page_number de #total_pages
      ]
    ]
  }
)

#set text(
  font: "Liberation Serif",
  size: 10pt,
  lang: "es"
)

#set par(justify: true, leading: 0.6em)

// ==================== PORTADA ====================
#align(center + horizon)[
  #text(12pt, font: "Liberation Sans", fill: rgb("#475569"))[
    PLATAFORMA EDUCATIVA DE CIBERSEGURIDAD
  ]
  
  #v(1.0cm)
  #text(22pt, weight: "bold", fill: rgb("#0f172a"))[
    ESPECIFICACIÓN DE ARQUITECTURA, PERSISTENCIA Y MODELADO UML 2.5 \
    SUITE DE DIAGRAMAS (FIGURAS 1 A 7)
  ]
  #v(0.4cm)
  #text(13pt, style: "italic", fill: rgb("#1e3a8a"), font: "Liberation Sans")[
    "VERTEX: Plataforma Educativa de Ciberseguridad basada en Teoría de Grafos"
  ]
  
  #v(1.2cm)
  #grid(
    columns: (1fr, 1fr),
    align: (left, right),
    [
      #text(10pt, font: "Liberation Sans")[
        *Proyecto de Software:* \
        • Sistema VERTEX (Godot Engine / Data-Driven) \
        • Modelo de Grafo Ponderado $G=(V, E)$ \
        • Aislamiento Multi-Slot y Respaldo Atómico
      ]
    ],
    [
      #text(10pt, font: "Liberation Sans")[
        *Estándares de Ingeniería:* \
        • Especificación UML 2.5 (Casos de Uso, Secuencia, Actividades, Clases, FSM) \
        • Diagrama Entidad-Relación Físico (Notación Crow's Foot) \
        • Diccionario de Datos Formal (IEEE Std 1059)
      ]
    ]
  )
]

#pagebreak()

// ==================== FIGURA 1 ====================
== Figura 1. Diagrama de Casos de Uso General del Sistema

La *Figura 1* presenta el modelo formal de Casos de Uso General del sistema *VERTEX* bajo el estándar UML 2.5, estructurado estrictamente mediante *verbos de acción en infinitivo* de acuerdo con las buenas prácticas metodológicas. El diagrama delimita el alcance perimetral del software frente al actor primario (*Operador*) y los servicios secundarios (*Adversario IA* y el subsistema de *Persistencia I/O*). Los casos de uso unifican la administración de ranuras, la formación en academia, la selección y ejecución de los modos de simulación táctica (Heist, Hacker y Ciberdefensa) como punto de entrada operacional único, junto a sus extensiones («extend») de contramedidas y relaciones de inclusión («include») para guardado transaccional.

#v(0.1cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 4pt,
    radius: 4pt,
    image("svg/figura_1_casos_de_uso_general.svg", height: 11.5cm, fit: "contain")
  )
  #v(0.1cm)
  #text(8.5pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 1.* Diagrama de Casos de Uso General del Sistema VERTEX según especificación UML 2.5.
  ]
]

#pagebreak()

// ==================== FIGURA 2 ====================
== Figura 2. Diagrama de Secuencia del Ciclo Reactivo de Ciberdefensa

La *Figura 2* ilustra el *diagrama de secuencia* del ciclo reactivo Blue Team. El flujo temporal modela la recepción del evento de bloqueo comandado por el analista en la interfaz gráfica (`InputHandler`), la delegación hacia el mediador de lógica (`GameLogic`), el sellado transaccional de aristas con costo infinito en la capa de grafo (`NetworkRuntime`), la resolución automática del turno en `DefenderBrain`, el cálculo y avance del rastreo forense EDR, la respuesta estocástica del atacante (`move_enemy()`) mediante movimiento lateral o exploit `Bypass`, y la actualización visual de estados en `GameRenderer`.

#v(0.1cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 4pt,
    radius: 4pt,
    image("svg/figura_2_secuencia_ciberdefensa.svg", height: 11.5cm, fit: "contain")
  )
  #v(0.1cm)
  #text(8.5pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 2.* Diagrama de secuencia del ciclo de respuesta reactiva 1:1 en modo Ciberdefensa.
  ]
]

#pagebreak()

// ==================== FIGURA 3 ====================
== Figura 3. Diagrama de Actividades de Ciberdefensa (Procesos)

La *Figura 3* presenta el *diagrama de actividades (flujo de proceso)* del ciclo de defensa perimetral según el estándar UML. El proceso modela el nodo inicial de inicio de asedio, la bifurcación condicional de acciones del operador (bloqueo de arista, colocación de firewall permanente o aislamiento de host en cuarentena), la resolución del turno de la Inteligencia Artificial mediante búsqueda de camino mínimo, la evaluación de contingencia por exploit `Bypass`, la ramificación de decisión por estado de rastreo forense (Trace EDR $>= 100%$) y los nodos finales correspondientes a la victoria por mitigación o la derrota por brecha en el Núcleo.

#v(0.1cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 4pt,
    radius: 4pt,
    image("svg/figura_3_actividades_ciberdefensa.svg", height: 11.5cm, fit: "contain")
  )
  #v(0.1cm)
  #text(8.5pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 3.* Diagrama de actividades del ciclo de resolución de Ciberdefensa según estándar UML.
  ]
]

#pagebreak()

// ==================== FIGURA 4 ====================
== Figura 4. Diagrama de Actividades de Infiltración Ofensiva (Modo Hacker)

La *Figura 4* ilustra el *diagrama de actividades* del proceso de infiltración ofensiva del modo Hacker (Red Team). Describe la secuencia de decisiones que gobierna el reconocimiento pasivo con `Nmap`, el consumo de exploits (`Bypass`, `Escalate`, `Persist`, `Decoy`), el cálculo y acumulación del nivel de ruido en la red perimetral, la evaluación de umbrales de detección ante la IA centinela (despacho de patrullas y perseguidores), y la finalización del escenario con persistencia de estrellas de maestría según el sigilo alcanzado.

#v(0.1cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 4pt,
    radius: 4pt,
    image("svg/figura_4_actividades_hacker.svg", height: 11.5cm, fit: "contain")
  )
  #v(0.1cm)
  #text(8.5pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 4.* Diagrama de actividades del ciclo de infiltración y balance de ruido en modo Hacker.
  ]
]

#pagebreak()

// ==================== FIGURA 5 ====================
== Figura 5. Diagrama de Clases de Arquitectura (UML 2.5)

La *Figura 5* presenta el *diagrama de clases* del núcleo arquitectónico de *VERTEX* bajo el estándar UML 2.5. Modela la separación estricta de responsabilidades entre los recursos inmutables del grafo (`NetworkGraphResource`, `NetworkNodeResource`, `NetworkEdgeResource`), la capa de mutación en memoria de tiempo de ejecución (`NetworkRuntime`), los algoritmos deterministas independientes (`DefensivePathfinder` con Dijkstra y `StrategicAnalyzer` con Edmonds-Karp), y los controladores de dominio y presentación (`DefenderBrain`, `GameLogic` y `GameRenderer`). Se evidencian las relaciones de composición fuerte, agregación y dependencia unidireccional.

#v(0.1cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 4pt,
    radius: 4pt,
    image("svg/figura_5_clases_arquitectura.svg", height: 11.5cm, fit: "contain")
  )
  #v(0.1cm)
  #text(8.5pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 5.* Diagrama de clases de arquitectura y separación estructural de responsabilidades (UML 2.5).
  ]
]

#pagebreak()

// ==================== FIGURA 6 ====================
== Figura 6. Diagrama Entidad-Relación y Modelo de Persistencia (Crow's Foot)

La *Figura 6* presenta el *diagrama de modelo de datos entidad-relación (ERD / Esquema Físico de Persistencia)* de *VERTEX* bajo notación *Crow's Foot* (Pata de Gallo). Modela la estructura transaccional de archivos de configuración alojados en `user://`. El meta-registro `SlotMeta` gobierna el puntero de sesión activa sobre las tres ranuras independientes (`SaveSlot`). Cada ranura aísla la entidad de identidad del agente (`Profile`), el registro de maestría por escenario (`LevelProgress`), las métricas históricas de rendimiento (`GlobalStats` y `LevelStats`), el catálogo de méritos desbloqueados (`BadgeRecord`) y la política de snapshots rotativos atómicos (`SlotSnapshot`).

#v(0.1cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 4pt,
    radius: 4pt,
    image("svg/figura_6_modelo_datos_persistencia.svg", height: 11.5cm, fit: "contain")
  )
  #v(0.1cm)
  #text(8.5pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 6.* Diagrama Entidad-Relación y Modelo de Persistencia Transaccional bajo notación Crow's Foot.
  ]
]

#pagebreak()

// ==================== FIGURA 7 ====================
== Figura 7. Diagrama de Máquina de Estados FSM (Dual)

La *Figura 7* ilustra el *diagrama de máquina de estados (State Machine / FSM)* dual del sistema: en la partición superior modela el ciclo de vida de los activos de red (`NetworkNode`), transitando desde el estado de operación normal hasta el bloqueo perimetral, la infección por movimiento lateral o el aislamiento físico en cuarentena; en la partición inferior modela el autómata de toma de decisiones del adversario simulado (`Adversary AI FSM`), gobernado por la detección de aristas cerradas, el consumo de exploits `Bypass` y la contención total hacia los estados terminales de brecha o mitigación forense.

#v(0.1cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#cbd5e1"),
    fill: rgb("#ffffff"),
    inset: 4pt,
    radius: 4pt,
    image("svg/figura_7_estados_fsm.svg", height: 11.5cm, fit: "contain")
  )
  #v(0.1cm)
  #text(8.5pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 7.* Diagrama de estados (FSM) del ciclo de vida de los nodos y del autómata reactivo del adversario.
  ]
]
