---
title: "Historial de Cambios"
created: "2026-06-26"
updated: "2026-08-16"
tags:
  - changelog
  - history
---

# Historial de Cambios

## Slice 3 — Descomposición en módulos + fix defensor (2026-08-16)

### Orquestadores delgados

- **Nuevo** `juego/ataque/game_state.gd` — estado y ciclo de vida: `cargar_params()` (SceneParams), `load_graph()`, `reset_state()`, `target_actual()`, `find_node_resource()`, ciclo de bloqueos, hit-testing del input, `blocked_edge_keys()` y `frame_data()` (datos puros del frame).
- **Nuevo** `juego/ataque/game_logic.gd` — turnos: `mover_jugador()`, `ganar()`/`perder()`, `vecinos_jugador()`, selección de vecino, `reveal_optimal_route()` ([P]) y cierre del defensor (`defender_won/lost/block_edge/place_firewall`).
- **Nuevo** `juego/ataque/hacker_logic.gd` — scans/exploits (refund unificado) y consecuencias del ruido; SFX scan/exploit movidos al módulo.
- **Nuevos** `juego/tutorials/tutorial_logic.gd` (ciclo de vida, `process_timers`, `ensure_locale`), `glossary.gd` (estado del glosario + `draw_pack`), `tutorial_render.gd` (layout y `_draw_*` puros), `tutorial_input.gd` (teclado→señales + tooltips).
- **Modificado** `juego/ataque/juego_ataque.gd` — 704 → **371 líneas**: estado + wiring + handlers delgados; delegates conservados por duck-typing/tests.
- **Modificado** `juego/tutorials/tutorial_player.gd` — 340 → **212 líneas**: orquestador.

### Renderer por datos (sin callables)

- **Modificado** `juego/ataque/game_renderer.gd` — nuevo `draw_frame(d)`: orquesta el frame con el diccionario de `GameState.frame_data()`. `draw_edges` pierde `is_blocked_func`/`is_in_path_func` (usa `blocked_keys` + deriva in_path de `current_path`); `draw_node_info_panel` usa `node_cache` en vez de `find_node_res_func`. Validado en runtime (atacante/hacker/defensor) con escena temporal.

### Fix defensor ("Enmienda A")

- **Modificado** `game_state.gd` `reset_state()` — usa el `start_node` real de SceneParams (eliminado el sentinel `&"DEFENSOR"`; dato muerto de los JSON) y saltea `_ai_blocker.initial_block()` en modo defensor.
- **Modificado** `juego_ataque.gd` `_on_move_requested()` — no-op en modo defensor (no hay jugador que se mueva).
- **Modificado** `test_defense_sanity.gd` / `test_cyber_sanity.gd` — esperan `player_pos == start_node` real.

### mostrar_ruta() a no-op documentado

- **Modificado** `juego_ataque.gd` — eliminado el push_warning del slice 1 (ruido de consola por partida); queda `pass` documentado. `test_bugfixes_static.gd` actualizado al contrato nuevo.

### Tests de equivalencia (golden, scene-based, prefijo `_`)

- **Nuevos** en `tests/ataque/`: `_test_game_state_` (14), `_test_game_logic_` (19), `_test_hacker_logic_` (18), `_test_defender_flow_` (7 — congela el fix defensor).
- **Nuevos** en `tests/tutorials/`: `_test_tutorial_logic_` (17), `_test_glossary_` (14), `_test_tutorial_render_` (34).

### Verificación

- `run_all.gd`: 25/25. Equivalences: 7/7 (123 aserciones). Cero `print()` en código de juego. Ver [[17 - Handoff a orquestador]].

## Slice Día 3.7 — Correcciones Finales para Alfa 0.1.0 (2026-08-02)

### Bug crítico: Tutorial se salía al completar con waypoints vacíos

- **Causa raíz:** `_ganar()` en `juego_ataque.gd` comparaba `current_waypoint_idx < waypoints.size()` sin verificar `waypoints.size() > 0`. Con `waypoints: []`, `current_waypoint_idx = -1` y `-1 < 0 = true`, causando `_perder()` al ganar en tutoriales sin waypoints.
- **Solución:** Agregada verificación `waypoints.size() > 0 and` en `_ganar()`.
- **Modificado:** `juego/ataque/juego_ataque.gd` — `_ganar()` ahora usa `waypoints.size() > 0 and current_waypoint_idx < waypoints.size()`.
- **Modificado:** `tests/ataque/test_bugfixes_static.gd` — 2 nuevas aserciones de guarda en fuente.

### Reducción de textos de tutoriales (~50% de reducción)

- **Modificado:** `juego/tutorials/data/tut1_movimiento.json` — Pasos 1-4 reducidos (572→352, 649→447, 515→321, 448→284 chars).
- **Modificado:** `juego/tutorials/data/tut2_perimetro.json` — Pasos 1, 2, 4 reducidos (735→468, 633→425, 610→383 chars).
- **Modificado:** `juego/tutorials/data/tut3_avanzado.json` — Pasos 1, 4, 5 reducidos (814→432, 862→463, 879→488 chars).
- **Modificado:** `juego/tutorials/data/tut4_hacker.json` — 7 pasos reducidos (promedio 1100→450 chars).
- **Modificado:** `juego/tutorials/data/tut4_defensa.json` — 6 pasos reducidos (promedio 890→480 chars).
- **Modificado:** `juego/tutorials/data/tut5_defense.json` — 7 pasos reducidos (promedio 1130→560 chars).
- **Modificado:** `juego/tutorials/data/tut6_combined.json` — 4 pasos reducidos (promedio 840→530 chars).

### Separación de condiciones de victoria

- **Modificado:** `juego/ataque/game_renderer.gd` — `draw_game_over()` muestra "TUTORIAL COMPLETADO" (no "VICTORIA") para tutoriales.
- **Modificado:** `juego/ataque/juego_ataque.gd` — `_draw()` pasa flag de tutorial al renderer.
- **Modificado:** `juego/tutorials/tutorial_player.gd` — `complete_tutorial()` ya no emite señal duplicada.

### Verificación

- Tests principales: 7/7 pasan. Tutoriales: 15/15 pasan. JSONs: 7/7 válidos. Sin errores.

## Slice Día 3 — Mejoras UX, Testing y Documentación para Alfa 0.1.0 (2026-08-02)

### Indicador de progreso mejorado

- **Modificado**: `juego/tutorials/tutorial_player.gd` — `_draw_step_indicator()`:
  - Muestra el título del paso actual sobre los puntos indicadores
  - Muestra el objetivo general del tutorial debajo del contador de pasos
  - Formato: "Paso 3 de 8: Título del paso"
- **Modificado**: `juego/tutorials/data/*.json` (7 archivos) — Añadidos campos
  `title` en cada paso y `objective` en la raíz de cada tutorial.
- **Commits**: Primer commit del slice.

### Navegación mejorada

- **Modificado**: `juego/tutorials/tutorial_player.gd`:
  - `previous()`: Volver al paso anterior (← o Backspace).
  - `go_to_step(idx)`: Saltar a un paso específico.
  - `get_steps_summary()`: Resumen de todos los pasos del tutorial.
  - `_input()` actualizado: LEFT/BACKSPACE → previous, ESC → skip, I → índice.
  - `_draw_skip_hint()`: Barra de controles `[←] Anterior [Enter] Siguiente [ESC] Saltar [I] Índice`.
  - `_draw_step_index_overlay()`: Overlay oscuro listando todos los pasos.
- **Modificado**: `core/locale/{es,en,pt}.json` — Nuevas claves:
  `tutorial.previous`, `tutorial.index`, `tutorial.hint_button`.
- **Commits**: Segundo commit del slice.

### Sistema de hints contextuales

- **Modificado**: `juego/tutorials/tutorial_player.gd`:
  - `get_hint()`: Retorna la pista del paso actual.
  - `show_hint()`: Revela manualmente la pista con [H].
  - Auto-reveal: A los 10 segundos o 3 intentos fallidos bloqueado en un paso.
  - `_draw_hint_panel()`: Panel amarillo mostrando la pista.
  - Variables de tracking: `_hint_used`, `_attempts`, `_hint_shown`,
    `_hint_stuck_timer`.
- **Modificado**: `juego/tutorials/data/tut1_movimiento.json`,
  `tut2_perimetro.json`, `tut3_avanzado.json`, `tut4_hacker.json` —
  Añadidos campos `hint` en pasos con `action_required`.
- **Commits**: Incluido en los commits anteriores.

### Verificación

- Tests del sistema de tutoriales: 15/15 pasan.
- Tests principales (`run_all.gd`): 7/7 pasan (84+ aserciones).
- Sin errores de script al iniciar el juego.
- Sin TODOs ni FIXMEs pendientes en tutoriales.

## Slice Día 2 — Tutoriales expandidos con contexto pedagógico (2026-08-02)

### Expansión de contenido pedagógico

- **Modificado**: `juego/tutorials/data/tut1_movimiento.json` — 8 pasos con
  analogías del mundo real (OSPF, BGP, nmap, traceroute).
- **Modificado**: `juego/tutorials/data/tut2_perimetro.json` — 7 pasos con
  contexto de firewalls reales (Cisco ASA, Snort, Suricata), route redundancy
  (HSRP, VRRP).
- **Modificado**: `juego/tutorials/data/tut3_avanzado.json` — 9 pasos con
  modelo de defense in depth (castillo medieval), IDS/SIEM reales
  (Splunk, ELK, QRadar), CSIRT.
- **Modificado**: `juego/tutorials/data/tut4_hacker.json` — 7 pasos con
  Cyber Kill Chain (Lockheed Martin), Metasploit, privilege escalation,
  nota ética sobre uso legal.
- **Modificado**: `juego/tutorials/test_tutorial_system.gd` — Actualizados
  step counts para reflejar las expansiones.
- **Commits**: 5 commits — Expandir tut1-4 + actualizar tests.

## Slice Día 1 — Preparación de Tutoriales para Alfa 0.1.0 (2026-08-02)

### Localización de textos del tutorial player

- **Modificado**: `core/locale/es.json`, `en.json`, `pt.json` — Añadidas claves
  `tutorial.next`, `tutorial.skip`, `tutorial.step`, `tutorial.of`,
  `tutorial.hint_action` con namespace `tutorial.*` para separar los textos
  del sistema de tutoriales de las claves genéricas existentes.
- **Modificado**: `juego/tutorials/tutorial_player.gd` — Todas las llamadas
  a `t()` actualizadas para usar las claves con prefijo (`t("tutorial.next")`
  en vez de `t("next")`, etc.).
- **Commits**:
  - Primer commit del slice.

### Correcciones tipográficas en tutoriales JSON

- **Corregido**: `juego/tutorials/data/tut4_hacker.json`:
  - `infiltracion` → `infiltración` (acento faltante)
  - `Cuanto mas` → `Cuanto más` (acentos en "más")
  - `CRITICO` → `CRÍTICO` (acento faltante)
  - `muevete` → `muévete` (acentos faltantes)
  - `Bien!` → `¡Bien!` (signo de exclamación inicial)
  - `Continua` → `Continúa` (acento faltante)
  - `ruta optima` → `ruta óptima` (acento faltante)
- **Corregido**: `juego/tutorials/data/tut6_combined.json`:
  - `Muevete` → `Muévete` (acentos faltantes)
  - `BIEN!` → `¡BIEN!` (signo de exclamación inicial)
- **Commits**:
  - Segundo commit del slice.

### Verificación

- Tests del sistema de tutoriales: 15/15 pasan.
- Tests principales (`run_all.gd`): pasan sin errores.
- Sin errores de script al iniciar el juego.

## Fase 0 — Auditoría y Estabilización (SDD, 2026-07-23, en curso)

Cambio SDD `fase-0-auditoria` — 10 slices encadenados (stacked-to-main) para
estabilizar el simulador. Avance: Slices 0-8 completados (33/39 tareas).

### Slice 8 — SceneParams Validation (2026-07-27)

- **Modificado**: `core/autoloads/scene_params.gd` (63 → 183 líneas) —
  Añadida validación de tipos y rangos con setters:
  - 12 propiedades numéricas con `clampi()`: `ai_block_per_turn` (0-10),
    `max_ai_blocks` (0-9999), `max_turns` (0-1000), `max_movement_points`
    (0-100), `defender_blocks_per_turn` (0-20), `defender_block_duration`
    (1-100), `defender_max_blocks` (0-9999), `firewall_cost` (1-100),
    `block_duration` (1-100), `pursuer_delay` (0-50), `max_pursuers` (1-20),
    `pursuer_speed` (1-10).
  - 2 propiedades de string con validación no-vacío: `graph_path`, `level_key`.
  - 1 propiedad de string opcional (acepta vacío): `tutorial_path`.
  - `GameLogger.warn()` cuando se clampea un valor fuera de rango.
  - `reset()` mantiene acceso directo para evitar validación innecesaria.
- **Agregado**: `tests/core/test_scene_params_validation.gd` (378 líneas) —
  82 aserciones: 12 tests de rangos numéricos (min, max, clamp), 3 tests de
  strings, 1 test de reset().
- **Commits**:
  - `3fd72be` refactor(scene-params): añadir validación de tipos y rangos con setters
  - `42c3f1d` test(scene-params): añadir tests de validación de rangos y tipos
- **Verificación**: Todos los tests pasan. Sin errores de parseo.
- **Issues**: Ninguno.

### Slice 7 — Sistema de logging estructurado (2026-07-27)

- **Agregado**: `core/autoloads/logger.gd` (70 líneas) — Autoload singleton
  `Logger` con niveles de log (DEBUG, INFO, WARN, ERROR). API: `debug()`,
  `info()`, `warn()`, `error()`. Formato: `[LEVEL] [Module] message`. Nivel
  por defecto: DEBUG en debug builds, INFO en release. Configurable vía
  `set_level(level)`.
- **Modificado**: `project.godot` — Logger agregado como primer autoload
  (antes de Events) para disponibilidad universal.
- **Migrado**: ~55 `print()` reemplazados por llamadas a Logger en código
  de producción:
  - `core/locale/locale_manager.gd`: 1 print → Logger.info (LocaleManager).
  - `juego/ataque/ai_blocker.gd`: 5 prints → Logger.debug (AIBlocker).
  - `juego/ataque/defender_brain.gd`: 11 prints → Logger.debug/info
    (DefenderBrain).
  - `juego/ataque/juego_ataque.gd`: 16 prints → Logger.debug/info
    (JuegoAtaque).
  - `juego/ataque/progress_service.gd`: 2 prints → Logger.error/info
    (ProgressService).
  - `juego/ataque/pursuit_system.gd`: 3 prints → Logger.debug
    (PursuitSystem).
  - `juego/tutorials/tutorial_player.gd`: 4 prints → Logger.info
    (TutorialPlayer).
- **No migrado**: `print()` en archivos de test (`test_*.gd`, `_test_*.gd`,
  `run_all.gd`) — output intencional del runner de pruebas.
- **Commits**:
  - `af76308` feat(core): crear Logger autoload con niveles de log
  - `09d7376` chore: configurar Logger en autoloads
  - `479066f` refactor: migrar print() a Logger en core y juego/ataque
  - `857d740` refactor: migrar print() a Logger en tutoriales
- **Verificación**: Todos los prints de producción migrados. Solo queda
  `print()` en logger.gd (implementación) y archivos de test (intencional).
- **Issues**: Ninguno.

### Slice 6 — Consolidar utilidades duplicadas (2026-07-27)

- **Agregado**: `juego/utils/progress_util.gd` (51 líneas) — `class_name
  ProgressUtil extends RefCounted` con funciones estáticas para cargar
  progreso del jugador. API: `cargar_progreso() -> Dictionary` (carga
  `{level_key: estrellas}` de `user://progress.cfg`), `get_stars(level_key)
  -> int`, `cargar_misiones(missions)` (pobla array con stars/completed).
- **Agregado**: `juego/utils/loc_util.gd` (45 líneas) — `class_name LocUtil
  extends RefCounted` con funciones estáticas para localización. API:
  `loc(node, key) -> String` (traduce clave vía LocaleManager),
  `set_locale(node, lang)`, `get_manager(node)`.
- **Modificado**: 6 archivos migrados a utilidades compartidas:
  - `escenas/main_menu.gd`: `_cargar_progreso()` → `ProgressUtil
    .cargar_progreso()`, `loc()` → `LocUtil.loc()`, eliminado
    `_get_locale_manager()`.
  - `escenas/main_menu/tutorials_menu.gd`: `_cargar_progreso()` →
    `ProgressUtil.cargar_progreso()`, `loc()` → `LocUtil.loc()`.
  - `juego/system/level_select_screen.gd`: `_cargar_progreso()` →
    `ProgressUtil.cargar_progreso()`.
  - `escenas/menu/database.gd`: `_load_progress()` → `ProgressUtil
    .cargar_misiones()`, `loc()` → `LocUtil.loc()`.
  - `escenas/menu/profile.gd`: `loc()` → `LocUtil.loc()`.
  - `escenas/menu/options.gd`: `loc()` → `LocUtil.loc()`, acceso directo
    a locale_manager → `LocUtil.set_locale()`.
- **Eliminado**: código duplicado de `_cargar_progreso()` (3 copias),
  `_load_progress()` (1 copia), `loc()` (5 copias), `_get_locale_manager()`
  (1 copia). Reducción neta: −75 líneas.
- **Commits**:
  - `f5dcaf2` refactor(utils): crear ProgressUtil compartido
  - `e415750` refactor(utils): crear LocUtil compartido
  - `eca3c09` refactor: migrar call sites a utilidades compartidas
- **Verificación**: `run_all.gd` 6/6 verde (84+ aserciones). Sin
  regresiones.
- **Issues**: Ninguno.

### Slice 5 — Extraer persistencia de progreso y estrellas a `ProgressService` (2026-07-26)

- **Agregado**: `juego/ataque/progress_service.gd` (163 líneas) — `class_name
  ProgressService extends RefCounted` siguiendo el patrón `AIBlocker`/
  `PursuitSystem`/`DefenderBrain` (RefCounted + ref `_game`). API:
  `setup(game)`, `calculate_stars() -> int` (era `_calcular_estrellas`),
  `save(nuevas_estrellas)` (era `_guardar_progreso` + stats de victoria),
  `record_loss()` (stats de derrota que vivía en `_perder`),
  `load_all() -> Dictionary` (static, era `_cargar_progreso`).
- **Agregado**: `tests/ataque/_test_progress_service_equivalence.{gd,tscn}`
  (212+3 líneas) — scene-based, 14 aserciones: 4 star count (movement_points
  mode 3/2/1 + cost_ratio mode) + 10 round-trip de archivo (save → lectura
  directa ConfigFile, overwrite rules, record_loss, load_all).
- **Modificado**: `juego/ataque/juego_ataque.gd`:
  - Cableado `_progress_service` en `_ready` (antes de `_load_graph`).
  - `_ganar`: `_calcular_estrellas()` + `_guardar_progreso(stars)` →
    `_progress_service.calculate_stars()` + `_progress_service.save(stars)`.
  - `_on_brain_defender_won`: `_guardar_progreso(stars)` →
    `_progress_service.save(stars)`.
  - `_perder`: bloque de stats inline (8 líneas) → `_progress_service.record_loss()`.
  - `_draw`: `_calcular_estrellas()` → `_progress_service.calculate_stars()`.
  - Añadido `level_key: String` property (poblado desde `SceneParams.level_key`
    en `_ready`) para que ProgressService acceda vía `_game.level_key` en
    lugar de depender directamente del autoload SceneParams.
  - Borrados `_level_key`, `_calcular_estrellas`, `_guardar_progreso`,
    `_cargar_progreso` (82 líneas netas eliminadas).
- **Reducción**: `juego_ataque.gd` 1087 → 1002 líneas (−85 netas en el slice).
  Objetivo `god-script-extraction` ≤700; Slices 6 continúan (ProgressUtil,
  LocUtil).
- **Commits**:
  - `532849f` refactor(ataque): extraer persistencia de progreso y estrellas a ProgressService
  - `9cdf0fe` test(ataque): añadir tests de equivalencia para ProgressService
  - `804f91c` refactor(ataque): migrar call sites a ProgressService
  - `7ff57cb` refactor(ataque): eliminar lógica vieja de progreso/estrellas
- **Issues**: Ninguno. Migración limpia sin desviaciones del design.

### Slice 4 — Extraer sistema de detección/persecución a `PursuitSystem` (2026-07-23)

- **Agregado**: `juego/ataque/pursuit_system.gd` (158 líneas) — `class_name
  PursuitSystem extends RefCounted` siguiendo el patrón `AIBlocker`/
  `DefenderBrain` (RefCounted + ref `_game`). API: `setup(game)`,
  `check_detection(player_pos)` (era `_chequear_deteccion`, porte VERBATIM
  conservando orden/cantidad de `randf()` para replays con `seed`),
  `process_pursuers(player_pos) -> bool` (era `_process_pursuers`, devuelve
  `true` si captura), `find_spawn_node(detected, node_res)` (era
  `_find_spawn_node`), `spawn_pursuer(spawn_node, delay, speed)` (helper que
  deduplica el bloque de append+incremento del perseguidor, compartido entre
  la detección normal y el spawn de ruido crítico del hacker), `reset()`
  (reagrupa los clears de `alerted_nodes`/`pursuers`/`_pursuer_next_id` que
  vivían al final de `reset_state`).
- **Agregado**: `tests/ataque/_test_pursuit_system_equivalence.gd` + `.tscn`
  (304 líneas) — scene-based (excluida del runner `--script` por prefijo
  `_`, toca autoloads; misma convención que `_test_ai_blocker_equivalence`).
  Parte A: replay determinista `seed(42)` de 4 pasos (detección → alerta →
  spawn en `security_spawn` → countdown de delay → activación →
  re-detección en nodo ya alertado → 2.º spawn → chase+captura → reset)
  contra un golden capturado con la lógica original inline (9 snapshots
  estructurales: `alerted_nodes`, `pursuers` dict, `_pursuer_next_id`,
  `game_over`, `mensaje_estado`, contador de capturas). Parte B: sanity
  unitario del helper `spawn_pursuer(delay=1, speed=2)` (camino del spawn
  del hacker crítico de ruido). 9 golden + 1 sanity = 10/10 verde.
- **Modificado**: `juego/ataque/juego_ataque.gd` — cableado `_pursuit_system`
  en `_ready` (antes de `_load_graph`, mismo patrón que `_ai_blocker`);
  `reset_state` migrado a `_pursuit_system.reset()`; `_mover_jugador` a
  `_pursuit_system.check_detection(player_pos)`; el spawn de ruido crítico
  del hacker (`_check_hacker_consequences`) migrado a
  `_pursuit_system.spawn_pursuer`+`find_spawn_node`. **Borrados** los cuerpos
  inline de `_chequear_deteccion`, `_process_pursuers`, `_find_spawn_node`.
- **Modificado**: `juego/ataque/ai_blocker.gd` — `AIBlocker.take_turn` migra
  `_game._process_pursuers()` → `_game._pursuit_system.process_pursuers(...)`
  (necesario para que el borrado del inline no deje callers rotos).
- **Modificado**: `juego/ataque/test_pursuit.gd` — sus 2 llamadas a
  `inst._process_pursuers()` migradas a `inst._pursuit_system.process_pursuers`
  (el inline privado fue borrado; API pública equivalente probada).
- **Reducción**: `juego_ataque.gd` 1140 → 1086 líneas (−54 netas en el slice;
  −60 en el commit 4.4). Objetivo `god-script-extraction` ≤700; Slices 5-6
  continúan el recorte (ProgressService, ProgressUtil, LocUtil).
- **Verificación**: equivalencia PursuitSystem 10/10 (reproduce golden
  capturado con inline original); equivalencia AIBlocker (slice 3) 19/19
  — la migración del `take_turn` no rompe la equivalencia de IA del slice 3;
  las 6 scene-based regression verdes (block_duration 5, defender_brain_draw
  _null 3, detection 3, pursuit 2, restart 2, heist_sanity 8); `run_all.gd`
  6/6 verde. Total 58 verificaciones verde.
- **Commits**: `ec1f3bf` (4.1), `c94742f` (4.2), `2019e65` (4.3),
  `98c8e78` (4.4).

### Slice 3 — Extraer lógica de turno IA a `AIBlocker` (2026-07-23)

- **Agregado**: `juego/ataque/ai_blocker.gd` (165 líneas) — `class_name
  AIBlocker extends RefCounted` siguiendo el patrón `DefenderBrain`
  (RefCounted + ref `_game`). API: `setup(game)`, `take_turn()` (era
  `_turno_ia`), `would_isolate(edge)` (era `_no_aisla_al_jugador` con
  semántica honesta y flip de booleano), `initial_block()` (porta el bucle
  de bloqueo inicial que vivía en `reset_state`).
- **Agregado**: `tests/ataque/_test_ai_blocker_equivalence.gd` + `.tscn`
  (277 líneas) — prueba scene-based (excluida del runner `--script` por
  prefijo `_`, toca autoloads). Parte A: flip `would_isolate` vs referencia
  congelada (9 aristas, 9/9 verde). Parte B: replay determinista de 10
  turnos de IA vs golden capturado con la lógica original inline (10/10
  verde). `seed(42)`, `tut3_red` con `detection_chance=0`.
- **Modificado**: `juego/ataque/juego_ataque.gd` — cableado `_ai_blocker` en
  `_ready` (antes de `_load_graph`), bucle inicial de `reset_state`
  reemplazado por `_ai_blocker.initial_block()`, llamada per-turn en
  `_mover_jugador` reemplazada por `_ai_blocker.take_turn()`. **Borrados**
  los cuerpos inline de `_turno_ia` y `_no_aisla_al_jugador`.
- **Reducción**: `juego_ataque.gd` 1229 → 1140 líneas (−89). Objetivo
  `god-script-extraction` ≤700; Slices 4-6 continúan el recorte
  (PursuitSystem, ProgressService, LocUtil).
- **Verificación**: equivalencia 19/19 verde; las 6 scene-based regression
  (`test_block_duration`, `test_defender_brain_draw_null`,
  `test_detection`, `test_pursuit`, `test_restart`, `test_heist_sanity`)
  verdes; `run_all.gd` 6/6 verde.
- **Hallazgo (fuera de scope)**: bug pre-existente en `juego_ataque._ganar`
  línea 710 — `waypoints[current_waypoint_idx]` con `current_waypoint_idx =
  -1` y `waypoints` vacío produce OOB al llegar al objetivo sin waypoints.
  Reportado en apply-progress; la prueba de equivalencia evita el camino
  viajando SOLO la lógica de IA. Recomendado para un slice futuro de bug
  fixes (no bloquea Slice 3).
- **Commits**: `9811432` (3.1), `4093a87` (3.2), `9b10921` (3.3),
  `e3e4330` (3.4).

### Slices 0-2 (2026-07-22/23)

Documentados en `sdd/fase-0-auditoria/apply-progress` (Engram):
- Slice 0: Test runner (`tests/runner/run_all.gd`, `_run_one.gd`).
- Slice 1: 4 bug fixes HIGH (InputHandler null guard, `ia_defensora.gd`
  borrado, `mostrar_ruta()` no-op, `_draw()` null guard).
- Slice 2: Core algorithm tests (Dijkstra, Edmonds-Karp, MinHeap; 70
  asserts, helper `_graph_builder.gd`).

## Versión 0.1.0-alpha (2026-07-10)

**Alpha release** — Menú funcional, tutoriales corregidos, feedback visual

### Agregado
- Menú Opciones: sliders de audio, toggles de gráficos, selección de idioma
- Menú Perfil: nombre editable, estadísticas, progreso por mundo
- Menú Database: lista de misiones, conceptos teóricos, lore
- Feedback visual: flash de movimiento del atacante, alerta de bloqueo expirado
- Partículas de escaneo en nodos alertados
- Transición fade-in en victoria/derrota
- Barra de presupuesto con animación suave
- Locale: ES, EN, PT completos (~50 keys nuevas)

### Corregido
- tut4_defensa: graph_path corregido (referenciaba archivo inexistente)
- tut6_combined: action_required cambiado a "input" (evita bloqueo)
- tut4_hacker: explicación de exploits expandida con detalles
- tut5_defense: reescrito como "Estrategias Avanzadas" (diferente a tut4)
- tut3_avanzado: título corregido a "Waypoints, Detección y Perseguidores"
- Flash de movimiento: corregido para aparecer en enemy_pos (no player_pos)
- Barra de presupuesto: inicializada correctamente al cargar nivel

### Documentación
- Reescritura completa de docs para alinear con código
- Creado 15 - Event Bus.md
- D1 movido de "deuda técnica" a "decisión de diseño"

## Versión 2.0.0 (2026-06-25)

**Hito 6 completo** — Niveles jugables, mecánicas, UI/UX

### Agregado
- 5 niveles jugables (Heist N1/N2, Hacker N1, Cyber N1, Defense N1)
- Mecánicas de Heist: presupuesto de movimiento + waypoints
- Mecánicas de Hacker: ruido + scans + exploits abstractos
- Mecánicas de Defensa: bloqueo de aristas + firewall de nodo
- Sistema de niveles: LevelManager + LevelRegistry + selector de nodos
- GameRenderer separado de juego_ataque.gd
- HUD reorganizado en 3 zonas
- Grid de fondo cyberpunk
- Menú principal con scan lines y glow
- 7 tutoriales (movimiento, perímetro, waypoints, defensa, hacker, defensa avanzada, combinado)
- Documentación: CHANGELOG, ROADMAP, INDICE actualizados

### Corregido
- Tutorial input blocking (is_game_paused)
- Waypoints validation antes de ganar
- Game over por sin salida
- get_edge() agregado a NetworkGraphResource

## Versión 1.9.0 (2026-06-24)

### Agregado
- Rediseño de grafos: Heist N1 balanceado, Hacker N1 con waypoints forzados
- Línea amarilla eliminada, hints opcionales con P
- Budget ajustado: Heist N1 = 12pts, N2 = 25pts

### Corregido
- Grafo Hacker: Core solo accesible desde AdminPanel
- Grafo Heist: rutas alternativas funcionales

## Versión 1.8.0 (2026-06-24)

### Agregado
- Mecánicas Hacker: sistema de ruido, scans, exploits (bypass/escalate/persist)
- hacker_mechanics.gd con 245 líneas
- HUD hacker en panel lateral

## Versión 1.7.0 (2026-06-24)

### Agregado
- HUD reorganizado en 3 zonas (superior, tablero, inferior)
- Grid de fondo sutil
- Menú cyberpunk (scan lines, glow, decoraciones)
- Barra visual de presupuesto de movimiento
- Labels de arista con protocolo en vez de tc=
- Paleta de colores de alto contraste

## Versión 1.6.0 (2026-06-24)

### Corregido
- Tutorial input blocking (is_game_paused para action_required)
- Waypoints validation antes de ganar
- Game over por sin salida
- GameManager + LevelRegistry

## Versión 1.5.0 (2026-06-23)

### Agregado
- Sistema de niveles: LevelManager, LevelRegistry, selector de nodos
- Mecánica de presupuesto de movimiento
- SceneParams: max_movement_points

## Versión 1.4.0 (2026-06-23)

### Agregado
- GameRenderer extraído de juego_ataque.gd (~500 líneas)
- fix tutorial is_game_paused()
- fix get_edge() en NetworkGraphResource

## Versión 1.3.0 (2026-06-23)

### Corregido
- Paleta de colores a alto contraste
- Fix Edmons → Edmonds (ortografía)
- Fix FMS → FSM (ortografía)

## Versión 1.2.0 (2026-06-22)

### Agregado
- Base teórica WJARR 2022 integrada
- ROADMAP.md actualizado con hitos 1-5 completados

## Versión 1.1.0 (2026-06-17)

### Agregado
- Menú principal con selector de 4 escenas
- Export a Windows (.exe)
- Controles de navegación (Q→menú, ESC→salir)

## Enlaces

- [[01 - Estado actual]]
- [[10 - Bugs y deuda técnica]]
