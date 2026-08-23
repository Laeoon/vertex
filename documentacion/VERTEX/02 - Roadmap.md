---
title: "Roadmap del Proyecto"
created: "2026-06-26"
updated: "2026-08-23"
tags:
  - roadmap
  - planning
---

# Roadmap del Proyecto

## Entregado (alpha 0.1.0)

| # | Entregable | Notas |
|---|-----------|-------|
| ✅ | Menú principal con Opciones, Perfil y Database | Audio, gráficos, idioma |
| ✅ | Feedback visual (flashes, animaciones) | — |
| ✅ | Sistema de tutoriales completo | 7 tutoriales guiados, glosario, tooltips |
| ✅ | Modos Heist, Hacker, Defensa y Ataque | Mecánicas funcionales |
| ✅ | Tests automatizados de core y gameplay | Suite completa |
| ✅ | Ejecutable Windows publicado | GitHub Releases |
| ✅ | Transiciones fade entre escenas | Fade ya existe y está en uso (ver [[18 - Overview y auditoría pendiente]], §7) |

## Próximas sesiones

| # | Tarea | Prioridad | Dependencias |
|---|-------|-----------|--------------|
| 1 | Sonidos y feedback audiovisual | Baja | — |
| 2 | Balanced tuning y playtesting — **Heist N1-N3 hecho (slice 5: self-play + par por nivel, ver [[14 - Historial de cambios]])**; falta hacker/cyber/defense | Alta | Todos los niveles |
| 3 | Stats extendidas (tiempo, racha, intentos) | Baja | Perfil |

## Futuro cercano

| # | Tarea | Prioridad | Dependencias |
|---|-------|-----------|--------------|
| 4 | Más niveles por mundo (N2, N3) | Media | Balance actual |
| 5 | Integrar señales Event Bus en tutoriales | Baja | Event Bus |
| 6 | Optimización de rendimiento | Baja | Playtesting |

## Ideas futuras

| # | Idea | Notas |
|---|------|-------|
| 7 | Multiplayer educativo | Red local, 2 jugadores |
| 8 | Niveles generados proceduralmente | Basados en parámetros de dificultad |
| 9 | Modo sandbox libre | Sin objetivos, exploración pura |

## Criterios de terminado

Un nivel está "terminado" cuando:
- [x] Grafo validado (sin dead ends)
- [x] Mecánicas funcionales probadas
- [x] HUD correcto y sin solapamientos
- [x] Tutorial asociado creado
- [x] Balance verificado (presupuesto/ruido/turnos alcanzables)

## Enlaces

- [[00 - Inicio]]
- [[01 - Estado actual]]
- [[10 - Bugs y deuda técnica]]
