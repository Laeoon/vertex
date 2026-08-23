---
title: "Tareas Pendientes"
created: "2026-06-26"
updated: "2026-08-23"
tags:
  - tasks
  - todo
---

# Tareas Pendientes

## Hecho (cierre al 2026-08-23)

| # | Tarea | Notas |
|---|-------|-------|
| ✅ | Transiciones fade entre escenas | Fade ya existe y está en uso (ver [[18 - Overview y auditoría pendiente]], §7) |
| ✅ | Balance Heist N1-N3 | Self-play + par por nivel (slice 5, ver [[14 - Historial de cambios]]) |
| ✅ | Navegación post-partida con UI | Teclas [N]/[L]/[Q] en game over + botones (slice 6 + capas 2/2b) |
| ✅ | Stats visibles en Perfil | Progreso por nivel del mundo heist (ver [[14 - Historial de cambios]]) |

## Pendiente (prioridad alta)

| # | Tarea | Dependencias | Notas |
|---|-------|--------------|-------|
| 1 | Balance hacker/cyber/defense | Harness de balance | Políticas propias por modo (ver [[18 - Overview y auditoría pendiente]], §7) |
| 2 | Stats extendidas (tiempo, racha, intentos) | Perfil funcional | `user://stats.cfg` ya existe (ProgressService); falta medición y superficie |

## Pendiente (prioridad media/baja)

| # | Tarea | Dependencias | Notas |
|---|-------|--------------|-------|
| 3 | i18n del contenido pedagógico | Tutoriales + glosario | Doc 16 (ver [[18 - Overview y auditoría pendiente]], §7) |
| 4 | Limpieza menor post-auditoría | — | `ai_enabled=true` inerte en defensor; naming legacy `nivel1_red.tres` (grafo de heist_n1) |

## Indefinido (no planificado)

| # | Tarea | Notas |
|---|-------|-------|
| 5 | Música | Punto de enganche AudioManager en `show_overlay`; implementación indefinida (ver [[14 - Historial de cambios]], Capa 2b) |

## Futuro (no planificado)

| # | Tarea | Notas |
|---|-------|-------|
| 6 | Más niveles por mundo | Balance actual primero |
| 7 | Optimización de rendimiento | Playtesting primero |
| 8 | Multiplayer educativo | Red local, 2 jugadores |
| 9 | Niveles generados proceduralmente | Difícil de balancear |
| 10 | Modo sandbox libre | Sin objetivos |

## Enlaces

- [[02 - Roadmap]]
- [[01 - Estado actual]]
