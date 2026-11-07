---
title: "Tareas Pendientes"
created: "2026-06-26"
updated: "2026-10-28"
tags:
  - tasks
  - todo
---

# Tareas Pendientes

## Hecho (Cierre v0.6.0)

| # | Tarea | Notas |
|---|-------|-------|
| ✅ | Campaña completa de 15 niveles de historia | 5 Heist, 5 Hacker, 5 Cybersecurity implementados y testeados. |
| ✅ | Sector 0: Root Genesis | Nivel secreto con mecánicas de desintegración y colapso de memoria. |
| ✅ | Activación por Konami Code | Secuencia en StartScreen con lanzamiento directo al nivel secreto. |
| ✅ | Sistema de 3 Save Slots independientes | Gestión aislada por carpetas en `user://slots/slot_1..3/`. |
| ✅ | Backup & Restore criptográfico `.bak` | Checksum SHA-256, snapshots automáticos y recuperación ante fallos. |
| ✅ | Visualizador de Espectro de Audio Reactivo | Envolvente simétrica sobre el riel de niveles basada en decibelios. |
| ✅ | Terminal CLI interactiva in-game | Consola estilo UNIX accesible con `[~]` o botón en HUD. |
| ✅ | Sistema de 10 Condecoraciones / Badges | Pestaña interactiva en Perfil con glifos vectoriales. |
| ✅ | Pista DEFENDER en Academia | 2 módulos interactivos con validación de paso en `TutorialPlayer`. |
| ✅ | Watchdog del Runner ajustado a 10s | Prevención de cuelgues por temporizadores en tests headless. |
| ✅ | Documentación formal UML 2.5 (Figuras 1 a 7) | Compilación a PDF consolidado con Typst y casos de uso CU-01 a CU-11. |

## Backlog para Siguientes Versiones (v0.7.0+)

| # | Tarea | Prioridad | Notas |
|---|-------|:---:|-------|
| 1 | Tarjeta teaser para Sector 0 en selector de mundos | Media | Mostrar nodo con candado "ACCESO CLASIFICADO (15 ★)" como alternativa visible a Konami. |
| 2 | Refactor de `database_renderer.gd` | Baja | Extraer el diccionario estático de 13 entradas a archivos `.json` en `res://data/codex/`. |
| 3 | Modo Endless / Boss Rush en Ciberdefensa | Baja | Generación continua de adversarios con mitigación y aumento progresivo de velocidad. |
| 4 | Auditoría completa de i18n para Sector 0 | Baja | Revisar que todas las cadenas de la terminal y glitch tengan paridad en inglés y portugués. |
