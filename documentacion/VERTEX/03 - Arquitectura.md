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
- **Logger** (`core/autoloads/logger.gd`, Fase 0 Slice 7): Autoload singleton
  para logging estructurado. API:
  - `debug(module, message)` — información detallada para desarrollo.
  - `info(module, message)` — operación normal del sistema.
  - `warn(module, message)` — problemas recuperables.
  - `error(module, message)` — fallos que requieren atención.
  - Formato de salida: `[LEVEL] [Module] message`.
  - Nivel por defecto: DEBUG en debug builds, INFO en release.
  - Configurable vía `set_level(level)`.
- **SceneParams** (`core/autoloads/scene_params.gd`, Fase 0 Slice 8): Autoload
  singleton con configuración global de escenas. Validación de tipos y rangos:
  - Propiedades numéricas: setters con `clampi()` para rangos (0-10, 0-9999,
    0-1000, 0-100, 0-20, 1-100, 0-50, 1-20, 1-10 según propiedad).
  - Propiedades de string: `graph_path` y `level_key` rechazan vacío
    (mantienen valor anterior); `tutorial_path` acepta vacío (opcional).
  - `GameLogger.warn()` cuando se clampea un valor fuera de rango.
  - `reset()` usa acceso directo para evitar validación innecesaria.
  - Ver: `tests/core/test_scene_params_validation.gd` (82 aserciones).

Ver: [[09 - Defensa#Event Bus]]

### Algoritmos
- **DefensivePathfinder**: Dijkstra O((V+E)logV) con min-heap
- **StrategicAnalyzer**: Edmonds-Karp O(VE²) para corte mínimo
- **MinHeap**: Estructura de datos para Dijkstra

Ver: [[04 - Mecánicas#Algoritmos]]

### Lógica de juego
- **juego_ataque.gd**: Orquestador principal (~1300 líneas → 1002 tras
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
- **ProgressService** (`juego/ataque/progress_service.gd`, Fase 0 Slice 5):
  RefCounted con ref `_game` (mismo patrón que `DefenderBrain`/
  `AIBlocker`/`PursuitSystem`). Encapsula la persistencia de progreso y
  el cálculo de estrellas del modo ataque. API:
  - `setup(game)` — inyecta el juego.
  - `calculate_stars() -> int` — el viejo `_calcular_estrellas` (ratio de
    `movement_points` si `max_movement_points > 0`, sino cost_ratio vs
    `STAR_THRESHOLDS` + turn_ratio vs `max_turns`; devuelve el mínimo).
  - `save(nuevas_estrellas)` — el viejo `_guardar_progreso` (actualiza
    `user://progress.cfg` si `nuevas_estrellas > prev`, registra victoria
    en `user://stats.cfg`).
  - `record_loss()` — el tracking de derrota que vivía en `_perder()`
    (registra pérdida en `user://stats.cfg`).
  - `load_all() -> Dictionary` (static) — el viejo `_cargar_progreso`
    (carga `{level_key: estrellas}` de `user://progress.cfg`).

  Equivalencia conductual probada por
  `tests/ataque/_test_progress_service_equivalence.{gd,tscn}` (scene-based):
  4 aserciones de star count (movement_points mode: 3/2/1 stars + cost_ratio
  mode) + 10 aserciones de round-trip de archivo (save → lectura directa
  de ConfigFile, verificación de overwrite rules, record_loss, load_all).
- **ProgressUtil** (`juego/utils/progress_util.gd`, Fase 0 Slice 6):
  RefCounted con funciones estáticas para cargar progreso del jugador.
  Consolida `_cargar_progreso()` duplicado en `main_menu.gd`,
  `tutorials_menu.gd`, `level_select_screen.gd` y `database.gd`. API:
  - `cargar_progreso() -> Dictionary` (static) — carga `{level_key:
    estrellas}` de `user://progress.cfg`.
  - `get_stars(level_key) -> int` (static) — obtiene estrellas de un
    nivel específico.
  - `cargar_misiones(missions)` (static) — pobla un array de misiones
    con `stars`/`completed` (usado por `database.gd`).
- **LocUtil** (`juego/utils/loc_util.gd`, Fase 0 Slice 6):
  RefCounted con funciones estáticas para localización. Consolida `loc()`
  duplicado en 5 archivos de menú. API:
  - `loc(node, key) -> String` (static) — traduce clave vía
    LocaleManager (requiere Node para acceder al SceneTree).
  - `set_locale(node, lang)` (static) — cambia locale activo.
  - `get_manager(node)` (static) — devuelve LocaleManager o null.

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
