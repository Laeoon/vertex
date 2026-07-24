---
title: "Arquitectura del Sistema"
created: "2026-06-26"
tags:
  - architecture
  - godot
  - design
---

# Arquitectura del Sistema

## Visión general

VERTEX usa una arquitectura **Data-Driven** con separación estricta entre datos, lógica y presentación.

```
┌─────────────────────────────────────────────────────┐
│                    PRESENTACIÓN                      │
│  GameRenderer (game_renderer.gd)                    │
│  Menú principal, selector de niveles, HUD           │
├─────────────────────────────────────────────────────┤
│                    LÓGICA DE JUEGO                   │
│  juego_ataque.gd (orquestador)                      │
│  hacker_mechanics.gd                                │
│  LevelManager / LevelRegistry                       │
├─────────────────────────────────────────────────────┤
│                    ALGORITMOS                        │
│  DefensivePathfinder (Dijkstra)                     │
│  StrategicAnalyzer (Edmonds-Karp)                   │
│  MinHeap                                            │
├─────────────────────────────────────────────────────┤
│                    ESTADO Y EVENTOS                  │
│  NetworkRuntime (mutable)                           │
│  Event Bus (events.gd)                              │
│  FSM (network_node.gd)                              │
├─────────────────────────────────────────────────────┤
│                    DATOS (inmutables)                │
│  NetworkGraphResource (.tres)                       │
│  NetworkNodeResource / NetworkEdgeResource          │
│  JSON de niveles (.json)                            │
└─────────────────────────────────────────────────────┘
```

## Capas detalladas

### Datos (inmutables)
- **NetworkGraphResource**: Contenedor del grafo con arrays de nodos y aristas
- **NetworkNodeResource**: Nodo con id, posición, tipo, metadata
- **NetworkEdgeResource**: Arista con `transit_cost` (Dijkstra) y `mitigation_capacity` (Edmonds-Karp)
- **JSON de niveles**: Configuración de cada nivel (graph_path, waypoints, IA, etc.)

Ver: [[04 - Mecánicas#Pesos duales]]

### Estado y eventos
- **NetworkRuntime**: Capa mutable que envuelve un `.tres` inmutable. Mapa de adyacencia O(1)
- **Event Bus**: 4 señales centralizadas (node_state_changed, threat_detected, path_calculated, min_cut_identified)
  - **Emisores**: juego_ataque.gd, network_node.gd, reactive_analyzer.gd, reactive_pathfinder.gd
  - **Consumidores**: Solo wrappers reactivos (Hito 5) y sandboxes de test. El UI no consume eventos (diseño actual: datos directos al renderer)
- **FSM**: Estados DISPONIBLE → ALERTADO → CAPTURADO por nodo

Ver: [[09 - Defensa#Event Bus]]

### Algoritmos
- **DefensivePathfinder**: Dijkstra O((V+E)logV) con min-heap
- **StrategicAnalyzer**: Edmonds-Karp O(VE²) para corte mínimo
- **MinHeap**: Estructura de datos para Dijkstra

Ver: [[04 - Mecánicas#Algoritmos]]

### Lógica de juego
- **juego_ataque.gd**: Orquestador principal (~1300 líneas → 1086 tras
  Fase 0 Slice 4; objetivo ≤700 al cerrar Slices 5-6)
- **GameRenderer**: Rendering separado de lógica
- **hacker_mechanics.gd**: Sistema de ruido y exploits
- **DefenderBrain** (`juego/ataque/defender_brain.gd`): RefCounted con
  ref `_game`; encapsula todo el modo defensor y emite señales.
- **AIBlocker** (`juego/ataque/ai_blocker.gd`, Fase 0 Slice 3):
  RefCounted con ref `_game` (mismo patrón que `DefenderBrain`). Encapsula
  el turno de la IA bloqueadora del modo ataque. API:
  - `setup(game)` — inyecta el juego.
  - `take_turn()` — el viejo `_turno_ia` (procesa perseguidores vía
    `_game._pursuit_system.process_pursuers` desde el slice 4, calcula ruta
    del jugador, bloquea aristas rio abajo evitando aislarlo).
  - `would_isolate(edge)` — el viejo `_no_aisla_al_jugador` con semántica
    honesta: `true` SI bloquear `edge` aislaría al jugador del objetivo
    (el original devolvía `true` cuando NO aisla; al renombrar se invierte
    el booleano y los call sites usan `not would_isolate(...)`).
  - `initial_block()` — el bucle de bloqueo inicial que vivía inline en
    `reset_state`.

  El estado compartido (`blocked_edges`, `runtime`, `_ai_blocks_used`,
  `max_ai_blocks`, `turn`, `mensaje_estado`) sigue en `juego_ataque.gd`
  porque también lo usa el modo defensor (vía `DefenderBrain` que llama de
  vuelta a `_game._block_edge`/`_game._is_blocked`). `AIBlocker` solo
  aporta la LÓGICA de decisión del turno, no posee estado persistente.

  Equivalencia conductual probada por
  `tests/ataque/_test_ai_blocker_equivalence.{gd,tscn}` (scene-based,
  10-turn replay + flip `would_isolate` vs referencia congelada).
- **PursuitSystem** (`juego/ataque/pursuit_system.gd`, Fase 0 Slice 4):
  RefCounted con ref `_game` (mismo patrón que `DefenderBrain`/
  `AIBlocker`). Encapsula el subsistema de detección y persecución del
  modo ataque. API:
  - `setup(game)` — inyecta el juego.
  - `check_detection(player_pos)` — el viejo `_chequear_deteccion` (tira
    `randf()` contra `detection_chance` del nodo, alerta el nodo y, si hay
    cupo, spawnea un perseguidor). PORTADO VERBATIM: mismo orden/cantidad
    de llamadas a `randf()` del original (incl. el segundo `randf()` del
    print de alerta) para preservar replays con `seed(N)`.
  - `process_pursuers(player_pos) -> bool` — el viejo `_process_pursuers`
    (cuenta down del delay, activa perseguidores, los mueve por la ruta
    óptima hacia el jugador); devuelve `true` si captura (vía
    `_game._perder`). Extensión mínima sobre el `void` original.
  - `find_spawn_node(detected, node_res)` — el viejo `_find_spawn_node`.
  - `spawn_pursuer(spawn_node, delay, speed)` — helper que deduplica el
    bloque de append + `_pursuer_next_id++`, invocado tanto por
    `check_detection` (con `pursuer_delay`/`pursuer_speed` del juego) como
    por el spawn de ruido crítico del hacker (delay=1, speed=2).
  - `reset()` — reagrupa `alerted_nodes.clear()`/`pursuers.clear()`/
    `_pursuer_next_id = 1` que vivía al final de `reset_state`.

  El estado mutable compartido (`alerted_nodes`, `pursuers`,
  `_pursuer_next_id`, `pursuer_delay`/`speed`/`max`) sigue en
  `juego_ataque.gd` porque también lo leen directamente `GameRenderer`
  (`draw_hud`/`draw_nodes`/`draw_pursuers`), el modo defensor y las
  pruebas scene-based existentes (`test_detection`, `test_pursuit`).
  `PursuitSystem` solo aporta la LÓGICA, no posee estado persistente —
  idéntico al criterio aplicado a `AIBlocker` en el slice 3.

  Equivalencia conductual probada por
  `tests/ataque/_test_pursuit_system_equivalence.{gd,tscn}` (scene-based):
  replay determinista `seed(42)` de 4 pasos (detección → alerta → spawn en
  `security_spawn` → countdown de delay → activación → re-detección en nodo
  ya alertado → 2.º spawn → chase+captura → reset) contra un golden
  capturado con la lógica ORIGINAL inline, más un sanity unitario del
  helper `spawn_pursuer`.

### Presentación
- **GameRenderer**: HUD en 3 zonas, grid de fondo, hints opcionales
- **Menú principal**: Cyberpunk (scan lines, glow)
- **Selector de niveles**: Mapa de nodos estilo subway

## Decisiones de arquitectura

| Decisión | Razón | Alternativa descartada |
|----------|-------|------------------------|
| Data-Driven (.tres) | Separar datos de lógica | Hardcodear grafos en scripts |
| Event Bus centralizado | Desacoplamiento total | Llamadas directas entre módulos |
| Algoritmos stateless | Reutilizables y testables | Estado compartido |
| GameRenderer separado | Separación rendering/lógica | Todo en un solo script |

## Enlaces

- [[00 - Inicio]]
- [[04 - Mecánicas]]
- [[09 - Defensa#Event Bus]]
