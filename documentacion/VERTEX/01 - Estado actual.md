---
title: "Estado Actual del Proyecto"
created: "2026-06-26"
updated: "2026-08-03"
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

- **Tests automatizados:** suite completa en `tests/` — core (Dijkstra, Edmonds-Karp, MinHeap, SceneParams), ataque y tutoriales.
- **Logging:** GameLogger estructurado en lugar de `print()`.
- **Refactorización:** lógica de gameplay extraída a servicios dedicados (AIBlocker, PursuitSystem, ProgressService) y utilidades compartidas (ProgressUtil, LocUtil).

## Entrega

- **Ejecutable:** VERtex-alpha-0.1.0.exe (Windows x64, autocontenido) en GitHub Releases.
- **Repositorio:** https://github.com/Laeoon/vertex.git

## Enlaces

- [[00 - Inicio]]
- [[03 - Arquitectura]]
- [[10 - Bugs y deuda técnica]]
- [[13 - Tareas pendientes]]
