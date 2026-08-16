---
title: "Bugs y Deuda Técnica"
created: "2026-06-26"
updated: "2026-08-16"
tags:
  - bugs
  - technical-debt
  - issues
---

# Bugs y Deuda Técnica

## Deuda técnica pendiente

| # | Problema | Severidad | Notas |
|---|----------|-----------|-------|
| D1 | Warnings de compilación (~10) | Baja | NO VERIFICABLE: no hay registro reproducible del conteo ni del comando usado; señales/parámetros no usados |
| D2 | draw_rect width ignorado con filled=true | Baja | Warning cosmético Godot 4.7 |

## Bugs conocidos (no críticos)

| # | Bug | Severidad |
|---|-----|-----------|
| B1 | CharacterBody2D no detecta colisiones en modo defensa | Baja | NO VERIFICABLE: sin pasos de reproducción documentados ni test que lo cubra |

### Saldado (2026-08-16)

- Archivos obsoletos `heist_n2_old.*` y `cyber_n1_old.*` eliminados (sin referencias).
- Tests scene-based de `juego/ataque/` y `juego/tutorials/` movidos a `tests/ataque/` y `tests/tutorials/`; `run_all.gd` ahora los ejecuta como escenas `.tscn` (modo proyecto) porque con `--script` los autoloads no se registran.
- `*.uid` agregado a `.gitignore`.

## Decisiones de diseño registradas

| Decisión | Razón |
|----------|-------|
| Línea amarilla eliminada | Confundía al jugador, no mostraba ruta óptima real |
| Hints opcionales con P | Mejor UX: el jugador decide cuándo ver ayuda |
| Core solo accesible desde AdminPanel | Forzar waypoints obligatorios en hacker |
| Aislamiento = Victoria | Transformar bloqueos en decisiones tácticas reales |
| Event Bus no conecta al UI | Datos directos al renderer es más simple y eficiente. Las señales se emiten para wrappers reactivos y testing |

## Enlaces

- [[01 - Estado actual]]
- [[03 - Arquitectura]]
