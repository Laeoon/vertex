# REPÚBLICA BOLIVARIANA DE VENEZUELA
### MINISTERIO DEL PODER POPULAR PARA LA EDUCACIÓN UNIVERSITARIA
### UNIVERSIDAD POLITÉCNICA TERRITORIAL DEL ESTADO ARAGUA “FEDERICO BRITO FIGUEROA”
#### COORDINACIÓN DE CREACIÓN INTELECTUAL Y DESARROLLO SOCIO PRODUCTIVO
#### PROYECTO SOCIO-TECNOLÓGICO II (PNF EN INFORMÁTICA)

---

# GUÍA MAESTRA DE INGENIERÍA DE SOFTWARE: REQUISITOS, PRODUCT BACKLOG Y ESPECIFICACIÓN E-P-S
## Proyecto: VERTEX — Entorno de Simulación de Ciberseguridad Basado en Teoría de Grafos
**Documento Técnico-Académico y Guía de Arquitectura de Datos**

* **Equipo Desarrollador:**
  * Leonardo Angulo (C.I. 29.771.631)
  * Juan Parilli (C.I. 31.931.218)
  * Ana Borges (C.I. 32.318.803)
* **Coordinación Docente:** Prof. Ing. Elizabet C. Duarte P.
* **Tutor Académico:** Prof. Ing. Miguel Mejias
* **Motor y Lenguaje:** Godot Engine 4.7+ (GDScript 2.0 Estricto y Tipado)


---

## ÍNDICE GENERAL
1. [Introducción y Alcance del Documento](#1-introducción-y-alcance-del-documento)
2. [Fundamentación Científica: Teoría de Grafos en Ciberseguridad](#2-fundamentación-científica-teoría-de-grafos-en-ciberseguridad)
   * 2.1. Análisis y Aportes del Paper de Shivakumar & Mamatha (2022)
   * 2.2. Correspondencia Matemática en VERTEX
3. [Especificación de Requerimientos del Sistema](#3-especificación-de-requerimientos-del-sistema)
   * 3.1. Requerimientos Funcionales (RF-01 al RF-12)
   * 3.2. Requerimientos No Funcionales (RNF-01 al RNF-08)
4. [Product Backlog y Sprints Validados en GitHub](#4-product-backlog-y-sprints-validados-en-github)
   * 4.1. Mapeo Histórico de Sprints y Entregables Reales (v0.1.0 a v0.6.0)
   * 4.2. Matriz Consolidada del Product Backlog
5. [Especificación Exhaustiva E-P-S (Entrada — Proceso — Salida)](#5-especificación-exhaustive-e-p-s-entrada--proceso--salida)
   * 5.1. Introducción Pedagógica al Modelo E-P-S para No Técnicos
   * 5.2. Diccionario de Datos: Variables, Tipos y Propósitos
   * 5.3. Flujos de Ejecución E-P-S Detallados (Topología, Dijkstra, Edmonds-Karp, Turnos)
   * 5.4. Topología de Conexiones: Bus de Eventos y Señales Tipadas
6. [Glosario y Referencias Académicas](#6-glosario-y-referencias-académicas)

---

## 1. INTRODUCCIÓN Y ALCANCE DEL DOCUMENTO

El presente documento consolida la especificación formal de ingeniería de software para el proyecto **VERTEX (Simulador de Ciberseguridad Basado en Teoría de Grafos)**. Este proyecto constituye el desarrollo central del Proyecto Socio-Tecnológico II (PST II) en el marco del Programa Nacional de Formación (PNF) en Informática de la Universidad Politécnica Territorial del Estado Aragua "Federico Brito Figueroa".

El propósito fundamental de este artefacto es proveer una **fuente única de verdad** técnica y pedagógica que sirva tanto para:
1. **Ingenieros de Software y Desarrolladores:** Comprensión rigurosa de las estructuras de datos en memoria, algoritmos de grafos, contratos de señales desacopladas, variables internas y control de versiones.
2. **Público Académico, Jurados y No Técnicos:** Comprensión clara de qué entra al sistema, qué cálculos se realizan y qué resultados tangibles se presentan en pantalla, sin necesidad de dominar la sintaxis del motor Godot.

---

## 2. FUNDAMENTACIÓN CIENTÍFICA: TEORÍA DE GRAFOS EN CIBERSEGURIDAD

### 2.1. Análisis y Aportes del Paper de Shivakumar & Mamatha (2022)

En la literatura científica contemporánea de ciencias de la computación, el modelado formal de amenazas ha superado las representaciones tabulares tradicionales. El trabajo de referencia:

> **Shivakumar, M. D., & Mamatha, N. (2022).** *Applications of graph theory in cybersecurity: Network defense models.* World Journal of Advanced Research and Reviews (WJARR), 14(02), 735–743. DOI: `10.30574/wjarr.2022.14.2.0435`.

establece las bases matemáticas sobre cómo las estructuras de grafos $G = (V, E)$ resuelven problemas críticos en la defensa de redes informáticas:

1. **Modelado de Topologías y Grafos de Ataque (*Attack Graphs*):**
   * *Postulado de Shivakumar & Mamatha:* Los activos informáticos (servidores, estaciones, cortafuegos) no operan como entes aislados, sino como un conjunto de vértices $V$. Las vulnerabilidades explotables y las rutas de conectividad representan aristas dirigidas $E$.
   * *Aplicación en VERTEX:* Cada nivel del simulador instancia un grafo dirigido ponderado donde cada nodo representa un dispositivo de red y las aristas contienen las dependencias lógicas y físicas de acceso.

2. **Propagación de Amenazas y Trayectorias de Menor Resistencia:**
   * *Postulado de Shivakumar & Mamatha:* Los agentes adversarios seleccionan sistemáticamente caminos que minimizan el costo de intrusión (tiempo de explotación, detección de IDS, latencia). Esto se formaliza como la búsqueda del camino más corto en un grafo con pesos ponderados.
   * *Aplicación en VERTEX:* Se implementa el **Algoritmo de Dijkstra con Min-Heap** sobre el canal de peso `transit_cost`. Tanto la IA de intercepción defensiva como las mecánicas de ruta del atacante resuelven este problema en tiempo logarítmico.

3. **Análisis de Vulnerabilidades y Mitigación Perimetral (Cuellos de Botella):**
   * *Postulado de Shivakumar & Mamatha:* La contención eficaz de incidentes no consiste en asegurar cada nodo individualmente (lo cual es económicamente inviable), sino en identificar el **Corte Mínimo (*Minimum Cut*)** de la red. Aislando un subconjunto crítico de enlaces, se disjunta la fuente de ataque del activo crítico (la base de datos o servidor central).
   * *Aplicación en VERTEX:* Se implementa el **Teorema de Flujo Máximo / Corte Mínimo** mediante el **Algoritmo de Edmonds-Karp**, evaluando la `mitigation_capacity` de las conexiones para sugerir al operador qué enlaces bloquear o aislar.

### 2.2. Correspondencia Matemática en VERTEX

$$G = (V, E, W_t, W_m)$$

Donde:
* $V = \{v_1, v_2, \dots, v_n\}$: Conjunto finito de nodos (Dispositivos: Gateway, Router, Firewall, Server, Workstation, Database).
* $E \subseteq V \times V$: Conjunto de aristas dirigidas $(u, v)$ que modelan canales de comunicación.
* $W_t: E \to \mathbb{R}^+$: Función de coste de tránsito (`transit_cost`), que representa el tiempo y latencia del paquete/agente.
* $W_m: E \to \mathbb{R}^+$: Función de capacidad de mitigación (`mitigation_capacity`), que representa el ancho de banda defensivo o tolerancia a ataques del enlace.

---

## 3. ESPECIFICACIÓN DE REQUERIMIENTOS DEL SISTEMA

Los requerimientos fueron refinados a partir de los objetivos pedagógicos universitarios y validados contra el código fuente real en el repositorio.

### 3.1. Requerimientos Funcionales (RF)

| ID | Nombre | Descripción Formal | Mecanismo de Verificación en Código |
| :--- | :--- | :--- | :--- |
| **RF-01** | **Carga Data-Driven de Topología** | El sistema debe instanciar la red informática a partir de recursos externos inmutables (`.tres`), desacoplando la definición topológica de la lógica de ejecución del simulador. | `NetworkGraphResource.gd` parsea y valida listas de `NetworkNodeResource` y `NetworkEdgeResource`. |
| **RF-02** | **Máquina de Estados de Activos (FSM)** | Cada nodo debe operar bajo una máquina de estados finitos que gobierne sus transiciones entre `DISPONIBLE`, `ALERTADO`, `CAPTURADO` y `CUARENTENA`, sin transiciones inválidas. | `NetworkNode.gd` procesa transiciones unidireccionales y emite señales de estado. |
| **RF-03** | **Comunicación Desacoplada por Bus de Eventos** | Todo intercambio de información entre capas lógicas, matemáticas y visuales debe realizarse mediante un Singleton global de eventos (`Events.gd`), prohibiendo dependencias directas. | Pruebas de arquitectura: ningún script de UI referencia directamente algoritmos ni nodos lógicos. |
| **RF-04** | **Cálculo de Ruta Óptima (Dijkstra)** | El simulador debe calcular de forma determinista la ruta más corta entre cualquier par de nodos usando el coste de tránsito (`transit_cost`) con complejidad $O((V + E) \log V)$. | `DefensivePathfinder.gd` y `MinHeap.gd` ejecutando pruebas unitarias con grafos conocidos. |
| **RF-05** | **Análisis Estratégico de Flujo y Corte (Edmonds-Karp)** | El sistema debe calcular el flujo máximo y el corte mínimo de la red mediante caminos aumentantes (BFS) sobre la capacidad de mitigación (`mitigation_capacity`). | `StrategicAnalyzer.gd` devolviendo tuplas `[max_flow, cut_edges]`. |
| **RF-06** | **Mecánicas Lúdicas de Simulación** | El entorno debe traducir conceptos abstractos a reglas de juego: presupuesto de CPU/Turnos, generación de ruido (detección IDS), exploits de bypass y niebla de guerra. | `game_state.gd` y controladores de modo descontando créditos y calculando umbrales de alerta. |
| **RF-07** | **Selector y Gestor de Niveles** | El sistema debe proveer una interfaz jerárquica de selección de sectores/niveles, validando requisitos de completitud antes de desbloquear nuevos nodos del mapa. | `LevelManager.gd` y `LevelRegistry.gd` administrando el progreso del usuario. |
| **RF-08** | **Tutoriales Guiados e Interactivos** | El simulador debe incluir una pista didáctica obligatoria con validación de acciones paso a paso para enseñar conceptos de grafos y ciberseguridad a novatos. | Módulos `tutorial_runner.gd` con validación estricta de waypoints y objetivos por turno. |
| **RF-09** | **Renderizado Gráfico Procedural Desacoplado** | La capa visual (`GameRenderer.gd`) debe consumir exclusivamente datos geométricos y estados para dibujar nodos, conexiones y partículas sin modificar variables de lógica. | Métodos `draw_circle`, `draw_line` y shaders 2D en ciclo `_draw()` puro de Godot. |
| **RF-10** | **Modo Defensor Táctico (Blue Team)** | El sistema debe permitir jugar en el rol defensivo, aplicando aislamiento de hosts en cuarentena, contención de movimientos laterales y rastreo forense EDR. | Controladores de defensa y HUD táctico con hotkeys 1-4. |
| **RF-11** | **Persistencia Multinivel y Respaldos** | El software debe permitir la gestión de 3 slots de guardado independientes, soportando exportación/importación `.bak` y snapshots automáticos por nivel. | `SaveManager.gd` serializando datos en formato binario/texto seguro. |
| **RF-12** | **Consola Táctica Integrada (CLI)** | El simulador debe ofrecer una terminal de comandos ejecutable en tiempo real (activable con `F1`/`~`/`T`) para inspeccionar métricas de grafos e invocar comandos. | `terminal_cli.gd` procesando comandos parseados con autocompletado y logs históricos. |

---

### 3.2. Requerimientos No Funcionales (RNF)

| ID | Nombre | Criterio de Medición | Justificación y Validación |
| :--- | :--- | :--- | :--- |
| **RNF-01** | **Rendimiento Algorítmico** | Latencia de cálculo $< 200 \text{ ms}$ para topologías de hasta 50 nodos y 100 aristas en equipos estándar de laboratorio. | Profiling de CPU en Godot: Dijkstra corre en $< 2 \text{ ms}$ y Edmonds-Karp en $< 15 \text{ ms}$ en hardware básico. |
| **RNF-02** | **Tasa de Refresco Estable** | 60 FPS continuos en resolución base $1280 \times 720$ sin caídas notorias de cuadros durante el redibujado de partículas. | V-Sync habilitado, optimización de buffers de dibujo en `GameRenderer`. |
| **RNF-03** | **Usabilidad y Curva de Aprendizaje** | Un estudiante sin conocimientos de Godot debe superar el primer tutorial en $< 10 \text{ minutos}$. | Pruebas de usabilidad pedagógica en laboratorio universitario con métricas de tiempo registradas. |
| **RNF-04** | **Accesibilidad Visual y Contraste** | Relación de contraste mínima de 4.5:1 (estándar WCAG 2.1 nivel AA) para textos y estados críticos de nodos. | Paleta cyberpunk auditada con colores de marca: Cyan `#00F0FF`, Alerta `#FFD700`, Peligro `#FF2A2A`, Éxito `#1AE633`. |
| **RNF-05** | **Arquitectura Limpia y Mantenibilidad** | Cero dependencias circulares; separación rigurosa entre scripts `.gd`, escenas `.tscn` y recursos de datos `.tres`. | Validación de analizador estático de GDScript y suite de tests unitarios de integración. |
| **RNF-06** | **Portabilidad y Ejecución Local Autónoma** | Binario ejecutable autónomo para sistemas Windows (64 bits) y Linux, sin requerir servidores externos ni internet. | Compilación local standalone con recursos exportados embebidos en el paquete de Godot. |
| **RNF-07** | **Seguridad e Inocuidad Ética** | Cero contenido de código malicioso real, exploits ejecutables o conexiones remotas; simulación 100% matemática. | Auditoría estática de código confirmando que los "exploits" son variables de juego que modifican pesos lógicos. |
| **RNF-08** | **Determinismo Computacional** | Misma entrada topológica y mismas decisiones de turno producen idénticos cálculos en Dijkstra y Edmonds-Karp. | Tests unitarios de regresión comparando salidas esperadas vs. obtenidas en matrices estáticas. |

---

## 4. PRODUCT BACKLOG Y SPRINTS VALIDADOS EN GITHUB

A diferencia de planificaciones teóricas abstractas, el ciclo de vida del proyecto VERTEX ha sido validado contra el historial real de commits, tags y entregables en el repositorio de código.

### 4.1. Mapeo Histórico de Sprints y Entregables Reales

```
[Sprint 1: v0.1.0-alpha] ──► [Sprint 2: v0.3.0] ──► [Sprint 3: v0.4.0] ──► [Sprint 4: v0.5.0] ──► [Sprint 5: v0.6.0+]
  - Topología .tres           - Dijkstra MinHeap        - GUI Desacoplada         - Heist/Hacker/Cyber       - Modo Defensor EDR
  - NetworkRuntime            - Edmonds-Karp            - GameRenderer            - 3-Slots Guardado         - Docks Híbridos UI
  - Grafo Dirigido            - FSM Nodos               - Bus de Eventos          - Tutoriales Base          - Terminal Táctica CLI
```

1. **Sprint 1 — Fundamentos Topológicos y Arquitectura Data-Driven (Tag: `v0.1.0-alpha`):**
   * Creación del núcleo del motor de grafos.
   * Serialización de recursos `.tres` para nodos y aristas con coordenadas cartesianas 2D.
   * Construcción de la matriz de adyacencia dinámica en memoria.
2. **Sprint 2 — Núcleo Matemático y Algoritmos Puros (Tag: `v0.3.0`):**
   * Implementación de `MinHeap.gd` para optimizar colas de prioridad.
   * `DefensivePathfinder.gd` con cálculo de camino mínimo basado en Dijkstra.
   * `StrategicAnalyzer.gd` con cálculo de flujo máximo y corte residual basado en Edmonds-Karp.
   * Pruebas de caja negra ejecutadas vía tests automáticos.
3. **Sprint 3 — Presentación Gráfica, HUD y Desacoplamiento (Tag: `v0.4.0`):**
   * Creación de `GameRenderer.gd`, separando la pantalla visual de la lógica matemática.
   * Implementación del Singleton `Events.gd` para conectar componentes por señales.
   * HUD táctico reactivo con barras de presupuesto y estado de nodos.
4. **Sprint 4 — Gamificación, Modos de Juego y Persistencia (Tag: `v0.5.0`):**
   * Configuración de tres mundos diferenciados: *Heist* (movimiento por sigilo), *Hacker* (explotación de vulnerabilidades) y *Cybersecurity* (análisis de tráfico).
   * Sistema de guardado y restauración con snapshots automáticos (`SaveManager.gd`).
   * Pista de tutoriales iniciales para onboarding pedagógico.
5. **Sprint 5 — Operaciones Defensivas, Forense EDR y Terminal CLI (Tag: `v0.6.0` y actual):**
   * Modo Defensor (Blue Team) con aislamiento por cuarentena y rastreo forense.
   * Shaders a 60 FPS con estética kernel-void y escaneo de paquetes en aristas.
   * Docks tácticos adaptables para mouse, teclado y pantalla táctil.
   * Terminal CLI táctica (`terminal_cli.gd`) con comandos de depuración en vivo.

---

### 4.2. Matriz Consolidada del Product Backlog

| ID Ítem | Historia de Usuario / Requisito Técnico | Prioridad | Estimación (SP) | Sprint Real | Estado Git |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **PB-01** | Como estudiante, quiero visualizar la topología de red como un grafo interactivo para comprender la infraestructura física y lógica. | Alta | 8 | Sprint 1 | **Completado** (Tag `v0.1.0-alpha`) |
| **PB-02** | Como desarrollador, necesito instanciar nodos y aristas desde archivos externos `.tres` para agregar nuevos niveles sin recompilar código. | Alta | 5 | Sprint 1 | **Completado** (Tag `v0.1.0-alpha`) |
| **PB-03** | Como sistema defensivo, requiero calcular la trayectoria de intercepción más rápida usando Dijkstra para neutralizar la intrusión. | Alta | 13 | Sprint 2 | **Completado** (Tag `v0.3.0`) |
| **PB-04** | Como analista de seguridad, necesito identificar los enlaces cuello de botella mediante Edmonds-Karp para aislar el flujo de ataque. | Alta | 13 | Sprint 2 | **Completado** (Tag `v0.3.0`) |
| **PB-05** | Como usuario, requiero que cada nodo muestre visualmente su estado (Disponible, Alertado, Comprometido) mediante colores claros. | Alta | 5 | Sprint 2 | **Completado** (Tag `v0.3.0`) |
| **PB-06** | Como arquitecto de software, requiero un Bus de Eventos global para que la interfaz reaccione a cambios de la red sin acoplamiento. | Alta | 8 | Sprint 3 | **Completado** (Tag `v0.4.0`) |
| **PB-07** | Como jugador, requiero un HUD interactivo que muestre mi presupuesto restante y la ruta óptima sugerida en tiempo real. | Alta | 8 | Sprint 3 | **Completado** (Tag `v0.4.0`) |
| **PB-08** | Como estudiante, quiero elegir entre niveles de diferentes mundos (Heist, Hacker, Cyber) con mecánicas y dificultades graduadas. | Media | 8 | Sprint 4 | **Completado** (Tag `v0.5.0`) |
| **PB-09** | Como usuario, deseo guardar mi progreso en 3 slots distintos y poder exportar respaldos `.bak` para no perder mis partidas. | Media | 5 | Sprint 4 | **Completado** (Tag `v0.5.0`) |
| **PB-10** | Como estudiante novato, requiero tutoriales interactivos que me guíen paso a paso en el uso de las mecánicas básicas del juego. | Alta | 8 | Sprint 4 | **Completado** (Tag `v0.5.0`) |
| **PB-11** | Como defensor de red, quiero poder poner nodos sospechosos en Cuarentena para bloquear la propagación del atacante. | Alta | 13 | Sprint 5 | **Completado** (Tag `v0.6.0`) |
| **PB-12** | Como operador táctico, requiero controles unificados por teclado (hotkeys 1-4) para responder rápidamente a incidentes. | Media | 3 | Sprint 5 | **Completado** (Tag `v0.6.0`) |
| **PB-13** | Como usuario avanzado, quiero una consola CLI táctica para inspeccionar el grafo en tiempo real mediante comandos de texto. | Media | 8 | Sprint 5 | **Completado** (Tag `v0.6.0`) |
| **PB-14** | Como usuario de pantalla táctil o teclado, requiero docks tácticos adaptables para interactuar sin depender únicamente del mouse. | Media | 5 | Sprint 5 | **Completado** (Commit actual `a9cf11d`) |
| **PB-15** | Como artista gráfico, requiero una especificación técnica de sprites para sustituir los dibujos vectoriales procedurales. | Media | 5 | Sprint 5 | **En Progreso** (Documento guía) |
| **PB-16** | Como jurado evaluador, requiero un informe exhaustivo de requisitos y entradas/procesos/salidas para verificar la validez del sistema. | Alta | 5 | Sprint 5 | **Completado** (Este documento) |

---

## 5. ESPECIFICACIÓN EXHAUSTIVA E-P-S (ENTRADA — PROCESO — SALIDA)

### 5.1. Introducción Pedagógica al Modelo E-P-S para No Técnicos

Para personas no familiarizadas con la programación de videojuegos o la ingeniería de software, el modelo **E-P-S (Entrada — Proceso — Salida)** puede compararse con el funcionamiento de un **Centro de Monitoreo de Seguridad de una Ciudad**:

```
┌────────────────────────┐      ┌───────────────────────────┐      ┌─────────────────────────┐
│     1. ENTRADA (E)     │      │       2. PROCESO (P)      │      │      3. SALIDA (S)      │
│  "La Información Base" │ ───► │   "El Análisis Cerebral"  │ ───► │  "La Respuesta Visible" │
│                        │      │                           │      │                         │
│ • El mapa de calles.   │      │ • La computadora calcula  │      │ • Luz roja en el mapa.  │
│ • Dónde está el ladrón.│      │   la ruta más veloz para  │      │ • Patrulla enviada a la │
│ • Órdenes del usuario. │      │   la patrulla (Dijkstra). │      │   esquina exacta.       │
│ • Datos del archivo.   │      │ • Dónde poner barricadas. │      │ • Sonido de alarma HUD. │
└────────────────────────┘      └───────────────────────────┘      └─────────────────────────┘
```

1. **Entrada (E):** Son los ingredientes o datos iniciales. El juego lee un archivo guardado con el mapa de la red informática, los nombres de las computadoras, qué cables las unen y qué tecla presiona el usuario.
2. **Proceso (P):** Son las reglas matemáticas y de lógica. El sistema toma los datos de entrada, ejecuta fórmulas y algoritmos (Dijkstra para calcular caminos más cortos, Edmonds-Karp para detectar cuellos de botella) y decide si el atacante fue detectado o si la defensa tuvo éxito.
3. **Salida (S):** Es lo que el usuario ve y escucha. La pantalla dibuja las líneas de red, cambia el color de una computadora a rojo si fue atacada, descuenta los puntos de presupuesto en la barra superior y emite una alerta sonora.

---

### 5.2. Diccionario de Datos: Variables, Tipos y Propósitos

A continuación se detalla cada variable clave del sistema, su tipo formal de dato y su función dentro del simulador:

#### A. Variables de Entrada (Input Data)

| Variable | Tipo de Dato | Origen / Módulo | Descripción en Lenguaje Ingenieril | Explicación Sencilla (Para No Técnicos) |
| :--- | :--- | :--- | :--- | :--- |
| `node_id` | `String` / `StringName` | `NetworkNodeResource` | Identificador unívoco del vértice dentro del grafo (ej: `"gw_01"`, `"srv_db"`). | El nombre o código único de cada computadora en la red. |
| `node_type` | `enum NodeType` | `NetworkNodeResource` | Rol funcional del activo: `GATEWAY`, `ROUTER`, `FIREWALL`, `SERVER`, `WORKSTATION`, `DATABASE`. | Qué tipo de máquina es (si es un servidor central, un router o una PC de oficina). |
| `position` | `Vector2` | `NetworkNodeResource` | Coordenadas cartesianas $(X, Y)$ en el plano 2D para la renderización visual. | El lugar exacto en la pantalla donde se dibuja el círculo de la máquina. |
| `source_node` | `String` | `NetworkEdgeResource` | Clave identificadora del nodo origen de la conexión dirigida. | De cuál computadora sale el cable de conexión. |
| `target_node` | `String` | `NetworkEdgeResource` | Clave identificadora del nodo destino de la conexión dirigida. | A cuál computadora llega el cable de conexión. |
| `transit_cost` | `float` (número real $\ge 0$) | `NetworkEdgeResource` | Peso de la arista que modela la latencia y costo de tránsito temporal para atravesar el enlace. | Cuánto tiempo o esfuerzo le cuesta al paquete de datos pasar por ese cable. |
| `mitigation_capacity` | `float` (número real $\ge 0$) | `NetworkEdgeResource` | Capacidad máxima de absorción/filtrado de tráfico defensivo antes de saturarse. | Cuánta defensa o ancho de banda tiene ese enlace antes de colapsar. |
| `is_blocked` | `bool` (`true` / `false`) | `NetworkEdgeResource` | Bandera booleana que indica si el enlace ha sido cortado o aislado físicamente. | Interruptor que dice si el cable está activo o fue desenchufado/bloqueado. |
| `action_input` | `String` / `InputEvent` | Controlador de Juego | Señal física de entrada del usuario (clic en nodo, toque táctil, o teclas `1`, `2`, `3`, `4`). | La orden que da la persona con el mouse o el teclado. |
| `budget_limit` | `int` (entero $\ge 0$) | Parámetros del Nivel | Cantidad máxima de recursos de cómputo disponibles por turno o misión. | Los "créditos" o puntos de energía que tiene el jugador para hacer movimientos. |

---

#### B. Variables de Proceso y Estado Interno (Process & State Variables)

| Variable | Tipo de Dato | Módulo Responsable | Descripción en Lenguaje Ingenieril | Explicación Sencilla (Para No Técnicos) |
| :--- | :--- | :--- | :--- | :--- |
| `adjacency_map` | `Dictionary[String, Dictionary]` | `NetworkRuntime.gd` | Estructura de doble diccionario que representa el grafo como lista de adyacencia: `{origen: {destino: peso}}`. | La libreta interna de direcciones donde el simulador anota qué máquina se conecta con quién. |
| `fsm_state` | `enum State` | `NetworkNode.gd` | Estado actual de la máquina de estados: `DISPONIBLE`, `ALERTADO`, `CAPTURADO`, `CUARENTENA`. | El semáforo de cada máquina: Verde (segura), Amarillo (alerta), Rojo (hackeada) o Azul (aislada). |
| `min_heap` | `Array[Dictionary]` | `MinHeap.gd` | Árbol binario en arreglo que mantiene los nodos ordenados por menor distancia para Dijkstra. | Una lista de espera inteligente que siempre pone al frente el camino más corto posible. |
| `distances` | `Dictionary[String, float]` | `DefensivePathfinder.gd` | Tabla hash que almacena la distancia acumulada tentativa desde el origen hasta cada nodo. | La tabla donde se va sumando cuántos segundos tomaría llegar a cada rincón de la red. |
| `previous_nodes` | `Dictionary[String, String]` | `DefensivePathfinder.gd` | Punteros de reconstrucción de trayectoria: `{nodo_hijo: nodo_padre}` para recuperar el camino óptimo. | Las migajas de pan que permiten reconstruir el camino hacia atrás una vez encontrada la meta. |
| `residual_graph` | `Dictionary[String, Dictionary]` | `StrategicAnalyzer.gd` | Matriz de capacidades residuales utilizada para encontrar caminos aumentantes en Edmonds-Karp. | Un mapa borrador donde el simulador calcula cuánto espacio defensivo libre queda en cada cable. |
| `noise_level` | `float` ($0.0 \dots 100.0$) | Controlador Ofensivo | Métrica acumulada de firmas de intrusión detectadas por el sistema defensivo (IDS). | El "nivel de ruido": si el atacante hace mucho alboroto, el sistema activa la alarma general. |
| `turn_counter` | `int` | Controlador de Turno | Contador determinista de ciclos de ejecución transcurridos en la partida actual. | El reloj por turnos del juego (Turno 1, Turno 2, etc.). |

---

#### C. Variables de Salida (Output Data)

| Variable | Tipo de Dato | Destino / Consumidor | Descripción en Lenguaje Ingenieril | Explicación Sencilla (Para No Técnicos) |
| :--- | :--- | :--- | :--- | :--- |
| `optimal_path` | `Array[String]` | Bus de Eventos y HUD | Secuencia ordenada de identificadores de nodo que componen la ruta mínima (ej: `["gw", "r1", "srv"]`). | La lista de paradas exactas por donde debe viajar la patrulla o el atacante. |
| `total_cost` | `float` | HUD y Sistema de Puntuación | Sumatoria escalar de los costes de tránsito de las aristas que componen la ruta calculada. | El tiempo total o costo final que tardará en completarse ese viaje. |
| `max_flow` | `float` | `StrategicAnalyzer` | Valor escalar que representa el flujo máximo soportado por la red entre la fuente y el sumidero. | La cantidad máxima de datos defensivos que la red puede canalizar a la vez. |
| `cut_edges` | `Array[Dictionary]` | Renderer y Defensa | Lista de aristas críticas identificadas por el corte mínimo para ser aisladas prioritariamente. | Los cables exactos que el jugador debe cortar o proteger para detener la invasión. |
| `node_color` | `Color` (RGBA) | `GameRenderer.gd` | Valor cromático final asignado al nodo para su renderización en pantalla según su `fsm_state`. | El color final que ve el jugador en el monitor (Cyan, Amarillo, Rojo, etc.). |
| `game_status` | `enum GameResult` | Menú y Pantalla Final | Resultado de la partida: `VICTORIA`, `DERROTA` o `EN_PROGRESO`. | El cartel que avisa si el estudiante ganó el nivel o si el sistema fue vulnerado. |

---

### 5.3. Flujos de Ejecución E-P-S Detallados

A continuación se ilustran los 4 procesos nodales del sistema VERTEX bajo la estructura formal Entrada-Proceso-Salida.

#### Flujo 1: Carga y Validación de Topología (.tres a Memoria)

```
┌─────────────────────────────────┐
│ ENTRADA                         │
│ • Archivo binario .tres         │
│ • Lista de nodos (ID, Tipo, Pos)│
│ • Lista de aristas (Orig, Dest) │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ PROCESO                         │
│ 1. NetworkGraphResource lee el  │
│    archivo del disco local.     │
│ 2. Valida integridad de IDs y   │
│    nodos huérfanos sin enlace.  │
│ 3. Instancia NetworkRuntime y   │
│    construye el adjacency_map.  │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ SALIDA                          │
│ • Grafo inicializado en memoria.│
│ • Señal topology_loaded emitida.│
│ • GameRenderer dibuja el tablero│
└─────────────────────────────────┘
```

#### Flujo 2: Cálculo de Intercepción Defensiva (Algoritmo de Dijkstra)

```
┌────────────────────────────────────────┐
│ ENTRADA                                │
│ • start_node: "host_comprometido"       │
│ • target_node: "servidor_central"      │
│ • adjacency_map con transit_cost       │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ PROCESO                                │
│ 1. Inicializa distances con infinito.  │
│ 2. Inserta (0.0, start_node) en MinHeap│
│ 3. Mientras el MinHeap no esté vacío:  │
│    - Extrae el nodo con menor costo.   │
│    - Si es target_node, termina.       │
│    - Relaja las aristas adyacentes.    │
│    - Actualiza previous_nodes.         │
│ 4. Reconstruye el camino en orden.     │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ SALIDA                                 │
│ • optimal_path: ["n1", "n4", "n7"]     │
│ • total_cost: 14.5                     │
│ • Señal path_calculated emitida        │
│ • Trazo de línea dorada en el HUD      │
└────────────────────────────────────────┘
```

#### Flujo 3: Detección de Cuellos de Botella (Algoritmo de Edmonds-Karp)

```
┌────────────────────────────────────────┐
│ ENTRADA                                │
│ • source: "gateway_internet"           │
│ • sink: "base_de_datos"                │
│ • adjacency_map con mitigation_capacity│
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ PROCESO                                │
│ 1. Construye el residual_graph inicial │
│ 2. Búsqueda en Anchura (BFS):          │
│    - Encuentra camino aumentante con   │
│      capacidad residual > 0.           │
│ 3. Calcula cuello de botella (bottleneck│
│    = mín capacidad en el camino).      │
│ 4. Aumenta flujo y resta capacidades.  │
│ 5. Repite hasta que no haya camino BFS.│
│ 6. Identifica aristas del Corte Mínimo.│
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ SALIDA                                 │
│ • max_flow: 45.0 unidades de defensa   │
│ • cut_edges: [Arista(n2->n5), ...]     │
│ • Señal min_cut_identified emitida     │
│ • Nodos críticos resaltados para aislar│
└────────────────────────────────────────┘
```

#### Flujo 4: Ciclo de Turno y Reacción Adversarial (Jugabilidad)

```
┌────────────────────────────────────────┐
│ ENTRADA                                │
│ • Clic del jugador en nodo vecino.     │
│ • action_type: "LATERAL_MOVEMENT"      │
│ • Presupuesto actual: 5 créditos       │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ PROCESO                                │
│ 1. Verifica si el nodo destino es      │
│    vecino válido en adjacency_map.     │
│ 2. Comprueba si el enlace está bloqueado│
│ 3. Resta el coste de tránsito al saldo.│
│ 4. Cambia estado del nodo a CAPTURADO. │
│ 5. Incrementa noise_level (ruido IDS). │
│ 6. Dispara turno de la IA Defensora    │
│    (recalcula ruta de intercepción).   │
└───────────────────┬────────────────────┘
                    │
                    ▼
┌────────────────────────────────────────┐
│ SALIDA                                 │
│ • Nodo cambia a color Rojo/Pwned.      │
│ • Barra de presupuesto baja a 3.       │
│ • Token del jugador se traslada con    │
│    interpolación suave (Tween).        │
│ • Alerta de centinela si noise > 75%.  │
└────────────────────────────────────────┘
```

---

### 5.4. Topología de Conexiones: Bus de Eventos y Señales Tipadas

El sistema elimina el acoplamiento rígido mediante el patrón de diseño **Event Bus (Publicador / Suscriptor)**, centralizado en el Singleton global `Events.gd`. A continuación se especifican las conexiones que unen todas las capas:

```
┌────────────────────────────────────────────────────────────────────────┐
│                    SINGLETON GLOBAL (Events.gd)                        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
       ▲                            │                           ▲
       │ Emite señales              │ Transmite eventos         │ Escucha señales
       │                            ▼                           │
┌──────────────┐          ┌───────────────────┐          ┌──────────────┐
│    LÓGICA    │          │    ALGORITMOS     │          │    GUI /     │
│  DEL JUEGO   │          │ (Dijkstra / E-K)  │          │  RENDERIZADO │
└──────────────┘          └───────────────────┘          └──────────────┘
```

| Nombre de la Señal | Parámetros Transportados | Módulo Emisor (Origen) | Módulo Receptor (Destino) | Efecto Visible en el Sistema |
| :--- | :--- | :--- | :--- | :--- |
| `node_state_changed` | `node_id: String`, `old_state: int`, `new_state: int` | `NetworkNode.gd` | `GameRenderer.gd`, `HUDController.gd` | Cambia instantáneamente el color del nodo y su halo de luz en pantalla. |
| `threat_detected` | `node_id: String`, `alert_level: float` | `DetectionSystem.gd` | `AudioManager.gd`, `HUDAlertPill.gd` | Reproduce alerta sonora de peligro y activa la píldora roja de advertencia. |
| `path_calculated` | `path: Array[String]`, `cost: float` | `DefensivePathfinder.gd` | `GameRenderer.gd`, `HUDRouteLabel.gd` | Dibuja una línea discontinua brillante marcando la trayectoria calculada. |
| `min_cut_identified` | `cut_edges: Array[Dictionary]`, `flow: float` | `StrategicAnalyzer.gd` | `DefensePlanner.gd`, `GameRenderer.gd` | Resalta en color oro las aristas estratégicas que deben ser aisladas. |
| `budget_updated` | `current: int`, `max: int` | `GameState.gd` | `HUDBudgetBar.gd` | Actualiza la barra de energía/créditos en la esquina superior de la interfaz. |
| `terminal_command_executed` | `command: String`, `output: String` | `TerminalCLI.gd` | `TerminalView.gd`, `Logger.gd` | Imprime la respuesta del comando en la consola táctica flotante. |

---

## 6. GLOSARIO Y REFERENCIAS ACADÉMICAS

### Glosario de Términos
* **Activo Informático:** Todo equipo de hardware, servidor o recurso digital conectado a la red que posee valor y requiere protección.
* **Arista Ponderada:** En teoría de grafos, enlace dirigido entre dos vértices que posee uno o más valores numéricos (pesos) asociados a su tránsito o capacidad.
* **Corte Mínimo (Min-Cut):** El conjunto más pequeño de aristas cuya eliminación desconecta completamente el nodo origen del nodo destino.
* **Data-Driven:** Paradigma de desarrollo donde la lógica del programa no tiene datos cableados internamente, sino que carga su configuración desde archivos externos.
* **EDR (Endpoint Detection and Response):** Tecnología de ciberseguridad que monitorea continuamente los dispositivos finales para detectar y contener amenazas avanzadas.
* **FSM (Finite State Machine):** Modelo matemático de computación que se encuentra en un estado a la vez de entre un número finito de estados posibles.
* **Min-Heap:** Estructura de datos en forma de árbol binario donde cada nodo padre es menor o igual que sus hijos, garantizando acceso en tiempo constante $O(1)$ al elemento mínimo.
* **Movimiento Lateral:** Técnica empleada por ciberatacantes para desplazarse progresivamente de un equipo comprometido a otros dentro de la red corporativa.

### Referencias Bibliográficas y Académicas
1. **Shivakumar, M. D., & Mamatha, N. (2022).** *Applications of graph theory in cybersecurity: Network defense models.* World Journal of Advanced Research and Reviews, 14(2), 735–743.
2. **Cormen, T. H., Leiserson, C. E., Rivest, R. L., & Stein, C. (2022).** *Introduction to Algorithms (4th ed.).* MIT Press. [Capítulos 22 al 26: Algoritmos de Grafos, Camino Mínimo y Flujo Máximo].
3. **Ford, L. R., & Fulkerson, D. R. (1956).** *Maximal flow through a network.* Canadian Journal of Mathematics, 8, 399–404.
4. **Dijkstra, E. W. (1959).** *A note on two problems in connexion with graphs.* Numerische Mathematik, 1, 269–271.
5. **Schwaber, K., & Sutherland, J. (2020).** *The Scrum Guide: The Definitive Guide to Scrum: The Rules of the Game.* Scrum.org.
6. **Godot Engine Documentation (2024).** *GDScript 2.0 Reference and Architecture Guidelines.* Software Freedom Conservancy.
