---
title: "Estado Actual del Proyecto"
created: "2026-06-26"
updated: "2026-08-23"
status: "active"
tags:
  - status
  - snapshot
---

# Estado Actual del Proyecto

## Resumen ejecutivo

VERTEX está en **versión 0.1.0-alpha** — release universitario publicada. Menú funcional, cuatro modos de juego con mecánicas completas, sistema de tutoriales guiado y build ejecutable para Windows publicado en GitHub Releases.

## Modos de juego

| Mundo | Mecánica | Estado |
|-------|----------|--------|
| Heist | Presupuesto de movimiento + waypoints + IA bloqueadora | ✅ |
| Hacker | Ruido + scans + exploits abstractos | ✅ |
| Defensa (Cybersecurity) | Bloqueos + firewall de nodo + corte mínimo | ✅ |
| Ataque | Gameplay principal con detección y perseguidores | ✅ |

## Niveles disponibles

| Mundo | Nivel | Dificultad | Presupuesto |
|-------|-------|------------|-------------|
| Heist | N1 — Infiltración en la Bóveda | 1 | 12 pts |
| Heist | N2 — La Ruta del Oro | 2 | 25 pts |
| Hacker | N1 — Lateral Movement | 2 | Sin presupuesto |
| Cybersecurity | N1 — Defensa en Capas | 3 | 3 bloqueos/turno |
| Cybersecurity | N2 — Defensa Perimetral | 2 | 2 bloqueos/turno |

## Tutoriales

| ID | Nombre | Pasos |
|----|--------|-------|
| tut1 | Reconocimiento y Navegación | 8 |
| tut2 | Perímetro e IA Adaptativa | 7 |
| tut3 | Waypoints, Detección y Rutas Forzadas | 9 |
| tut4_defensa | Defensa en Capas | 6 |
| tut4_hacker | Modo Hacker | 7 |
| tut5_defense | Modo Defensa — Protección de Red | 7 |
| tut6_combined | Nivel Experto | 4 |

Cada tutorial incluye glosario [G], tooltips, barra de progreso y recordatorios de acción. Ver [[16 - Tutoriales Alfa 0.1.0]].

## Calidad

- **Tests automatizados:** suite en `tests/` ejecutada por `tests/runner/run_all.gd` — core (Dijkstra, Edmonds-Karp, MinHeap, SceneParams), ataque y tutoriales. Además, tests de equivalencia (golden, scene-based) congelan los módulos extraídos: `_test_{game_state,game_logic,hacker_logic,defender_flow,tutorial_logic,glossary,tutorial_render}_equivalence`. Cobertura parcial: no toda la lógica de juego tiene tests.
- **Logging:** GameLogger estructurado en lugar de `print()`.
- **Refactorización (slice 3, P5):** orquestadores delgados — `juego_ataque.gd` (371 líneas) y `tutorial_player.gd` (212 líneas) conservan sólo estado + wiring + handlers. La lógica vive en módulos: ataque (GameState, GameLogic, HackerLogic + servicios Fase 0 AIBlocker/PursuitSystem/ProgressService/DefenderBrain) y tutoriales (TutorialLogic, Glossary, TutorialRender, TutorialInput). El renderer dibuja por datos puros (`GameRenderer.draw_frame` + `GameState.frame_data`, sin callables).
- **Fix defensor ("Enmienda A"):** en modo defensor el start_node es real (sin sentinel `&"DEFENSOR"`), la IA no bloquea al inicio y el "jugador" no se mueve — congelado por `_test_defender_flow_equivalence`.
- **Slice 4:** `mostrar_ruta()` implementado (ruta óptima respetando bloqueos del runtime) y renderer congelado con `_test_game_renderer_equivalence`.
- **Slice 5:** balance Heist N1-N3 con self-play (harness `tests/balance/_balance_harness`) + par por nivel (estilo golf) en ProgressService vía LevelRegistry.
- **Slice 6:** navegación post-partida — teclas [N]/[L]/[Q] en game over, cubierto por `_test_level_nav` (13).
- **Auditoría P1-P5 (2026-08-21):** PASS con hallazgos menores (ver [[18 - Overview y auditoría pendiente]], sección 3).
- **Capa visual completa:** paleta "Neón Ciberpunk" + JetBrains Mono vía `juego/ui/brand.gd` (tokens únicos); game over con **pantalla completa** — botones reales ([R]/[N]/[L]/[Q], foco navegable) + fondos procedurales por resultado y fade de entrada. El renderer ya NO dibuja el game over (vive en `GameOverOverlay`). Ver [[14 - Historial de cambios]] capas 0+1, 2 y 2b.
- **Stats visibles en Perfil:** el Perfil muestra progreso por nivel del mundo heist (estrellas, mejor coste, victorias/derrotas e intentos) vía `build_level_rows()` en `escenas/menu/profile.gd`.

## Entrega

- **Ejecutable:** VERtex-alpha-0.1.0.exe (Windows x64, autocontenido) en GitHub Releases.
- **Repositorio:** https://github.com/Laeoon/vertex.git

## Enlaces

- [[00 - Inicio]]
- [[03 - Arquitectura]]
- [[10 - Bugs y deuda técnica]]
- [[13 - Tareas pendientes]]
