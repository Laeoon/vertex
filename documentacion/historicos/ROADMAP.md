# ROADMAP.md — Plan de Recuperación por Hitos

## Contexto

Este documento nace del downgrade a **Hito 1** realizado desde el commit `14d3fad`.
El proyecto se adelantó hasta Hito 5 por inercia de desarrollo, pero al ser un
proyecto académico (TSU) cada hito debe validarse de forma independiente ante
profesores y tutores.

Este roadmap guía la reimplementación ordenada de cada pieza, apoyándose en el
backup de GitHub para consulta, pero **sin reutilizar código de forma directa**
— la validación académica exige que cada hito se construya y certifique paso a paso.

---

## Versión

**v2.0.0** — 2026-06-26 — Hito 6 completo con mecánicas de defensa integradas.

---

## Product Backlog

| ID | Requisito | Prio | Hito | Estado |
|---|---|---|---|---|---|
| PB-01 | Estructura de Mapa de Adyacencia anidado | Alta | 1 | ✅ |
| PB-02 | Motor de Validación de Integridad | Alta | 1 | ✅ |
| PB-03 | Sistema de Recursos Inmutables (.tres) | Alta | 1 | ✅ |
| PB-04 | Agente de Intercepción (Dijkstra) | Alta | 2 | ✅ |
| PB-05 | Agente Estratégico (Edmonds-Karp) | Alta | 3 | ✅ |
| PB-06 | Bus de Eventos Global (Singleton) | Media | 4 | ✅ |
| PB-07 | Máquina de Estados (FSM) de Nodos | Media | 4 | ✅ |
| PB-08 | Wrappers de Integración Reactiva | Media | 5 | ✅ |
| PB-09 | Interfaz Gráfica (GUI) Minimalista | Baja | 6 | ✅ |
| PB-10 | Visualización de Flujo y Saturación | Baja | 6 | ✅ |
| PB-11 | GameManager y Sistema de Niveles | Alta | 6 | ✅ |
| PB-12 | Niveles Jugables (Heist, Hacker, Cyber) | Alta | 6 | ✅ |
| PB-13 | Base Teórica WJARR 2022 | Media | 6 | ✅ |

---

## Entrada, Proceso y Salida de Datos

### 1. Entrada de Datos (Input): Definición de la Topología Inmutable

La base de datos del simulador reside en archivos con extensión `.tres`.
En el ecosistema de Godot Engine, un archivo `.tres` es un Recurso de Texto
Personalizado (Custom Resource). A diferencia de un script, este recurso actúa
como un contenedor de datos serializados que permite definir la estructura de la
red de forma independiente a la lógica del programa, facilitando un enfoque
Data-Driven.

- **Identificador_Topología**: Recurso que encapsula la lista completa de activos y sus conexiones.
- **Recurso_Activo**: Define cada nodo con su ID_Único (tipo StringName), su posición espacial y su nivel de criticidad.
- **Recurso_Conexión**: Define las aristas dirigidas mediante dos canales de peso independientes:
  - **Peso_Tránsito**: Costo de latencia o resistencia utilizado por el algoritmo de Dijkstra.
  - **Capacidad_Mitigación**: Esfuerzo de parcheo o flujo máximo utilizado por el algoritmo de Edmonds-Karp.

### 2. Proceso de Datos: Motor Lógico y Algorítmico

El procesamiento transforma los recursos estáticos en una simulación dinámica
gestionada en la memoria RAM mediante un Runtime de red.

- **Instanciación_Estructura_Eficiente**: El sistema convierte el recurso `.tres` en un Mapa de Adyacencia anidado (Doble Hash), permitiendo consultas de conectividad en tiempo constante O(1).
- **Cálculo_Ruta_Óptima (Dijkstra)**: Procesa el Peso_Tránsito para determinar la trayectoria de intercepción más rápida frente a una amenaza detectada, con una eficiencia de O((V+E)logV).
- **Análisis_Flujo_Estratégico (Edmonds-Karp)**: Evalúa la Capacidad_Mitigación a través de búsquedas en anchura (BFS) en el grafo residual para identificar el Corte Mínimo, localizando los cuellos de botella críticos de la red.
- **Control_Estados_FSM**: Gestión de la lógica de transición de cada nodo entre los estados DISPONIBLE, ALERTADO y CAPTURADO, asegurando que cada activo reaccione de forma autónoma a los incidentes.

### 3. Salida de Datos: Notificación y Visualización

La salida del sistema es estrictamente reactiva y se propaga a través del Bus de
Eventos global para mantener el desacoplamiento entre la lógica y la interfaz.

- **Señal_Estado_Nodo**: Notificación enviada cuando un activo cambia su condición en la FSM.
- **Trayectoria_Calculada (Array[StringName])**: Lista ordenada de IDs que representan el camino mínimo para el agente defensivo.
- **Diccionario_Corte_Crítico**: Conjunto de aristas que deben ser mitigadas para aislar el activo crítico al menor costo.
- **Actualización_Interfaz_2D**: Renderizado visual en tiempo real que traduce las métricas matemáticas en barras de progreso y alertas gráficas para el usuario.

---

## Requisitos Funcionales (RF)

| ID | Descripción | Estado |
|---|---|---|
| RF-01 | Carga topológica Data-Driven desde `.tres` | ✅ |
| RF-02 | Máquina de Estados Finita (FSM) por nodo | ✅ |
| RF-03 | Propagación de eventos desacoplada mediante Bus de Eventos global | ✅ |
| RF-04 | Agente Defensivo (Dijkstra): ruta de intercepción óptima con min-heap | ✅ |
| RF-05 | Agente de Análisis Estratégico (Edmonds-Karp): flujo máximo y corte mínimo | ✅ |
| RF-06 | Abstracción Lúdica de Incidentes: gamificación de conceptos de ciberseguridad | ✅ |
| RF-07 | Sistema de waypoints con validación | ✅ |
| RF-08 | Game over por sin salida | ✅ |
| RF-09 | GameManager para carga de niveles | ✅ |
| RF-10 | Mecánicas Hacker: ruido, scans, exploits abstractos | ✅ |
| RF-11 | Presupuesto de movimiento para Heist | ✅ |
| RF-12 | Selector de niveles estilo mapa de nodos | ✅ |

## Requisitos No Funcionales (RNF)

| ID | Descripción | Estado |
|---|---|---|
| RNF-01 | Godot Engine 4.x + GDScript, app local monousuario de escritorio | ✅ |
| RNF-02 | Prohibición de exploits reales — abstracción matemática pura | ✅ |
| RNF-03 | Algoritmos deterministas (sin ML), topología ≤ 3 mapas fijos | ✅ |
| RNF-04 | GUI técnica minimalista con validación participativa estudiantil | ✅ |

---

## Estado actual

| Hito | Backlog | Estado | Sandbox |
|---|---|---|---|
| 1 | PB-01, PB-02, PB-03 | ✅ Implementado | A |
| 2 | PB-04 | ✅ Implementado | C |
| 3 | PB-05 | ✅ Implementado | D |
| 4 | PB-06, PB-07 | ✅ Implementado | E |
| 5 | PB-08 | ✅ Implementado | F |
| 6 | PB-09, PB-10, PB-11, PB-12, PB-13 | ✅ Implementado | — |

## Niveles jugables

| Mundo | Nivel | Grafo | Nodos | Dificultad | Mecánica |
|---|---|---|---|---|---|
| Heist | N1 — Infiltración en la Bóveda | nivel1_red.tres | 8 | 1 | Presupuesto 12pts + waypoints |
| Heist | N2 — La Ruta del Oro | heist_n2.tres | 10 | 2 | Presupuesto 18pts + 3 waypoints |
| Hacker | N1 — Lateral Movement | hacker_n1.tres | 11 | 2 | Ruido + exploits + scans |
| Cybersecurity | N1 — Defensa en Capas | cyber_n1.tres | 8 | 3 | Pendiente |

## Base teórica

Paper de referencia: Shivakumar MD & Mamatha N (2022), "Applications of graph theory in cybersecurity: Network defense models", WJARR, 14(02), 735–743. DOI: 10.30574/wjarr.2022.14.2.0467

Mapping paper → implementación:
- §2 Network Topology Modeling → NetworkGraphResource + NetworkNodeResource + NetworkEdgeResource
- §3 Attack Graph Generation → DefensivePathfinder (Dijkstra)
- §3 Cut-Set Analysis → StrategicAnalyzer (Edmonds-Karp)
- §4 Intrusion Detection → detection_chance + pursuers
- §5 Vulnerability Assessment → Pesos duales (transit_cost + mitigation_capacity)
- §6 Game-Theoretic Defense → Gameplay (jugador vs IA defensora)
