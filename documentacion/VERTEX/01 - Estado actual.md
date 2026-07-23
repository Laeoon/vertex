---
title: "Estado Actual del Proyecto"
created: "2026-06-26"
updated: "2026-07-10"
status: "active"
tags:
  - status
  - snapshot
---

# Estado Actual del Proyecto

## Resumen ejecutivo

VERTEX está en **versión 0.1.0-alpha** — Menú funcional, tutoriales corregidos, feedback visual implementado. Los 3 mundos tienen mecánicas funcionales. Menú principal con Opciones (audio, gráficos), Perfil (nombre, stats) y Database (misiones, conceptos, lore).

## Hitos completados

| Hito | Nombre | Estado |
|------|--------|--------|
| 1 | Cimientos del grafo estático | ✅ |
| 2 | Agente de intercepción (Dijkstra) | ✅ |
| 3 | Análisis estratégico (Edmonds-Karp) | ✅ |
| 4 | Event Bus + FSM | ✅ |
| 5 | Wrappers de Integración Reactiva | ✅ |
| 6 | GUI + Niveles + Mecánicas | ✅ |

## Mecánicas implementadas

| Mundo | Mecánica | Estado |
|-------|----------|--------|
| [[07 - Heist]] | Presupuesto de movimiento + waypoints + IA bloqueadora | ✅ |
| [[08 - Hacker]] | Ruido + scans + exploits abstractos | ✅ |
| [[09 - Defensa]] | Modo defensor + firewall de nodo + corte mínimo | ✅ |

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
| tut4_defensa | Defensa en Capas | 8 |
| tut4_hacker | Modo Hacker | 7 |
| tut5_defense | Modo Defensa — Protección de Red | 8 |
| tut6_combined | Nivel Experto | 4 |

## Último commit

```
7aa523e Archive old docs to documentacion/historicos (ignored) and import VERTEX docs from Obsidian Vault (source of truth)
```

## Rama de trabajo

`main`

## Enlaces

- [[00 - Inicio]]
- [[10 - Bugs y deuda técnica]]
- [[13 - Tareas pendientes]]
