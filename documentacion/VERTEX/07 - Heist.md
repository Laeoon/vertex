---
title: "Mundo Heist"
created: "2026-06-26"
tags:
  - heist
  - mechanics
  - levels
---

# Mundo Heist — Infiltración

## Concepto

El jugador infiltra una red bancaria moviéndose por nodos. Cada movimiento cuesta puntos de presupuesto. Debe pasar por waypoints obligatorios antes de llegar a la Bóveda.

## Mecánica central

- **Presupuesto fijo** por nivel (12-25 puntos)
- **Costo por movimiento** = `transit_cost` de la arista
- **Waypoints obligatorios** (◇ dorados en el grafo)
- **IA bloqueadora** que corta rutas después de cada turno
- **Estrellas** = puntos sobrantes / presupuesto total

## Niveles

| Nivel | Nodos | Budget | Óptimo | Margen | Waypoints | IA |
|-------|-------|--------|--------|--------|-----------|-----|
| N1 — Infiltración en la Bóveda | 8 | 12 | ~9 | 33% | Seguridad, Cajas | 1/turno, max 3 |
| N2 — La Ruta del Oro | 12 | 25 | ~11 | 56% | Lobby, CCTV, Cajas | 1/turno, max 5 |

## Balance

- **Nivel 1:** Margen 33% — permite explorar pero exige planificar
- **Nivel 2:** Margen 56% — más holgado, más rutas alternativas

## Tutoriales asociados

- [[04 - Mecánicas#Tutorial 1]]: Movimiento básico
- [[04 - Mecánicas#Tutorial 2]]: Perímetro e IA
- [[04 - Mecánicas#Tutorial 3]]: Waypoints y detección

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `juego/nivel1/nivel1_red.tres` | Grafo N1 |
| `juego/heist/heist_n1.json` | Config N1 |
| `juego/heist/heist_n2.tres` | Grafo N2 |
| `juego/heist/heist_n2.json` | Config N2 |

## Enlaces

- [[04 - Mecánicas#Sistema de presupuesto]]
- [[06 - Level Design#Grafo Heist N1]]
- [[05 - UI HUD]]
