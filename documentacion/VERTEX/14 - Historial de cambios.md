---
title: "Historial de Cambios"
created: "2026-06-26"
updated: "2026-07-10"
tags:
  - changelog
  - history
---

# Historial de Cambios

## Fase 0 — Auditoría y Estabilización (SDD, 2026-07-23, en curso)

Cambio SDD `fase-0-auditoria` — 10 slices encadenados (stacked-to-main) para
estabilizar el simulador. Avance: Slices 0-3 completados (14/39 tareas).

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
