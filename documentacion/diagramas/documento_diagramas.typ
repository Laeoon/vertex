#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 1.5cm, top: 1.5cm, bottom: 1.5cm),
  header: align(right)[
    #text(8pt, fill: rgb("#6b7280"), font: "Liberation Sans")[
      VERTEX // Documentación Técnica de Arquitectura e Ingeniería de Software
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
  size: 11pt,
  lang: "es"
)

#set par(justify: true, leading: 0.65em)

// Portada / Cabecera General
#align(center)[
  #v(0.5cm)
  #text(18pt, weight: "bold", fill: rgb("#111827"))[
    Especificación de Arquitectura y Modelado UML (Figuras 1 a 7)
  ]
  #v(0.2cm)
  #text(12pt, fill: rgb("#4b5563"), font: "Liberation Sans")[
    Proyecto: VERTEX — Plataforma Educativa de Ciberseguridad basada en Teoría de Grafos
  ]
  #v(0.2cm)
  #line(length: 100%, stroke: 0.8pt + rgb("#cbd5e1"))
]

#v(0.4cm)

// FIGURA 1
== Figura 1. Diagrama de Casos de Uso General del Sistema

La *Figura 1* presenta el modelo formal de Casos de Uso General del sistema *VERTEX* bajo el estándar UML 2.5. El diagrama ilustra los límites perimetrales del software, la interacción con el actor principal (Operador) y los servicios secundarios (el agente autónomo de Inteligencia Artificial que actúa como adversario reactivo y el subsistema de Persistencia en disco). Los casos de uso centrales descomponen la administración de perfiles, los módulos formativos de la academia, los tres modos operacionales (Heist, Hacker y Ciberdefensa) y los mecanismos de extensión funcional como la declaración de cuarentena y la revelación táctica de rutas.

#v(0.3cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#d1d5db"),
    fill: rgb("#fafafa"),
    inset: 10pt,
    radius: 4pt,
    image("svg/figura_1_casos_de_uso_general.svg", width: 85%)
  )
  #v(0.1cm)
  #text(9pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 1.* Diagrama de Casos de Uso General del Sistema VERTEX según especificación UML 2.5.
  ]
]

#pagebreak()

// FIGURA 2
== Figura 2. Diagrama de Secuencia del Ciclo Reactivo de Ciberdefensa

La *Figura 2* presenta el *diagrama de secuencia* del ciclo reactivo completo del modo Ciberdefensa (Blue Team). El flujo temporal modela la recepción del evento de bloqueo comandado por el analista en la interfaz gráfica (`InputHandler`), la delegación hacia el mediador de lógica (`GameLogic`), el sellado transaccional de aristas con costo infinito en la capa de grafo (`NetworkRuntime`), la resolución automática del turno en `DefenderBrain`, el cálculo y avance del rastreo forense EDR, la respuesta estocástica del atacante (`move_enemy()`) mediante movimiento lateral o exploit `Bypass`, y la actualización del estado visual en `GameRenderer`.

#v(0.3cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#d1d5db"),
    fill: rgb("#fafafa"),
    inset: 10pt,
    radius: 4pt,
    image("svg/figura_2_secuencia_ciberdefensa.svg", width: 88%)
  )
  #v(0.1cm)
  #text(9pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 2.* Diagrama de secuencia del ciclo de respuesta reactiva 1:1 en modo Ciberdefensa.
  ]
]

#pagebreak()

// FIGURA 3
== Figura 3. Diagrama de Actividades de Ciberdefensa (Procesos)

La *Figura 3* ilustra el *diagrama de actividades (flujo de proceso)* del ciclo de defensa perimetral según el estándar UML. El proceso modela el nodo inicial de inicio de asedio, la bifurcación condicional de acciones del operador (bloqueo de arista, colocación de firewall permanente o aislamiento de host en cuarentena), la resolución del turno de la Inteligencia Artificial mediante búsqueda de camino, la evaluación de contingencia por exploit `Bypass`, la ramificación de decisión por estado de rastreo forense (Trace EDR $>= 100%$) y los nodos finales de actividad correspondientes a la victoria por mitigación o la derrota por brecha en el Núcleo.

#v(0.3cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#d1d5db"),
    fill: rgb("#fafafa"),
    inset: 10pt,
    radius: 4pt,
    image("svg/figura_3_actividades_ciberdefensa.svg", width: 82%)
  )
  #v(0.1cm)
  #text(9pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 3.* Diagrama de actividades del ciclo de resolución de Ciberdefensa según estándar UML.
  ]
]

#pagebreak()

// FIGURA 4
== Figura 4. Diagrama de Actividades de Infiltración Ofensiva (Modo Hacker)

La *Figura 4* presenta el *diagrama de actividades* del proceso de infiltración ofensiva del modo Hacker (Red Team). Describe la secuencia de decisiones que gobierna el reconocimiento pasivo con `Nmap`, el consumo de exploits (`Bypass`, `Escalate`, `Persist`, `Decoy`), el cálculo y acumulación del nivel de ruido en la red perimetral, la evaluación de umbrales de detección ante la IA centinela (despacho de perseguidores), y la finalización del escenario con persistencia de estrellas de maestría por sigilo.

#v(0.3cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#d1d5db"),
    fill: rgb("#fafafa"),
    inset: 10pt,
    radius: 4pt,
    image("svg/figura_4_actividades_hacker.svg", width: 82%)
  )
  #v(0.1cm)
  #text(9pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 4.* Diagrama de actividades del ciclo de infiltración y balance de ruido en modo Hacker.
  ]
]

#pagebreak()

// FIGURA 5
== Figura 5. Diagrama de Clases de Arquitectura (UML 2.5)

La *Figura 5* presenta el *diagrama de clases* del núcleo arquitectónico de *VERTEX* bajo el estándar UML 2.5. Modela la separación de responsabilidades entre los recursos inmutables del grafo (`NetworkGraphResource`, `NetworkNodeResource`, `NetworkEdgeResource`), la capa de mutación en memoria de tiempo de ejecución (`NetworkRuntime`), los algoritmos deterministas independientes (`DefensivePathfinder` y `StrategicAnalyzer`), y los controladores de dominio y presentación (`DefenderBrain`, `GameLogic` y `GameRenderer`). Se representan las relaciones de composición, agregación y dependencia unidireccional que garantizan desacoplamiento modular en el motor.

#v(0.3cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#d1d5db"),
    fill: rgb("#fafafa"),
    inset: 10pt,
    radius: 4pt,
    image("svg/figura_5_clases_arquitectura.svg", width: 88%)
  )
  #v(0.1cm)
  #text(9pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 5.* Diagrama de clases de arquitectura y separación estructural de responsabilidades (UML 2.5).
  ]
]

#pagebreak()

// FIGURA 6
== Figura 6. Modelo de Datos y Persistencia de Sesión (ER / Relacional)

La *Figura 6* presenta el *diagrama de modelo de datos entidad-relación (ER / Esquema Lógico de Persistencia)* de *VERTEX*. Modela la estructura transaccional de archivos de configuración alojados en `user://`. El meta-registro `SlotMeta` gobierna el puntero de sesión activa sobre las tres ranuras independientes (`SaveSlot`). Cada ranura aísla la entidad de identidad del agente (`Profile`), el registro de maestría por escenario (`LevelProgress`), las métricas históricas de rendimiento (`GlobalStats` y `LevelStats`) y el catálogo de méritos desbloqueados (`BadgeRecord`).

#v(0.3cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#d1d5db"),
    fill: rgb("#fafafa"),
    inset: 10pt,
    radius: 4pt,
    image("svg/figura_6_modelo_datos_persistencia.svg", width: 85%)
  )
  #v(0.1cm)
  #text(9pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 6.* Modelo relacional de entidades y esquema lógico de almacenamiento transaccional en disco.
  ]
]

#pagebreak()

// FIGURA 7
== Figura 7. Diagrama de Máquina de Estados FSM (Dual)

La *Figura 7* ilustra el *diagrama de máquina de estados (State Machine / FSM)* dual del sistema: en la partición superior modela el ciclo de vida de los activos de red (`NetworkNode`), transitando desde el estado de operación normal hasta el bloqueo perimetral, la infección por movimiento lateral o el aislamiento físico en cuarentena; en la partición inferior modela el autómata de toma de decisiones del adversario simulado (`Adversary AI FSM`), gobernado por la detección de aristas cerradas, el consumo de exploits `Bypass` y la contención total hacia los estados terminales de brecha o mitigación forense.

#v(0.3cm)
#align(center)[
  #block(
    stroke: 0.8pt + rgb("#d1d5db"),
    fill: rgb("#fafafa"),
    inset: 10pt,
    radius: 4pt,
    image("svg/figura_7_estados_fsm.svg", width: 85%)
  )
  #v(0.1cm)
  #text(9pt, style: "italic", fill: rgb("#374151"), font: "Liberation Sans")[
    *Figura 7.* Diagrama de estados (FSM) del ciclo de vida de los nodos y del autómata reactivo del adversario.
  ]
]
