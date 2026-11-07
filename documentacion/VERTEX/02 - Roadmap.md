---
title: "Roadmap del Proyecto"
created: "2026-06-26"
updated: "2026-10-28"
tags:
  - roadmap
  - planning
---

# Roadmap del Proyecto

## Entregado en v0.6.0 (Hitos Completados)

| # | Entregable | Estado | Notas |
|---|---|:---:|---|
| ✅ | Campaña completa de 15 niveles de historia | Completado | 5 Heist, 5 Hacker, 5 Cybersecurity con min-cut $\ge 2$. |
| ✅ | Nivel Secreto cinemático "Sector 0: Root Genesis" | Completado | Estética Kernel Void, lluvia Hex Dump y colapso de memoria. |
| ✅ | Desbloqueo de nivel secreto vía Konami Code | Completado | `[↑ ↑ ↓ ↓ ← → ← → B A]` en StartScreen. |
| ✅ | Sistema de 3 Save Slots independientes | Completado | Gestión en `SlotManager`, migración automática y borrado seguro. |
| ✅ | Snapshots automáticos y Backup `.bak` (SHA-256) | Completado | Rotación máx 5, exportación e importación atómica con verificación. |
| ✅ | Visualizador de Espectro de Audio Reactivo | Completado | `AudioSpectrumVisualizer` en decibelios a lo largo del riel de niveles. |
| ✅ | Terminal Táctica CLI In-Game | Completado | `TerminalOverlay` con comandos `help`, `netstat`, `traceroute`, etc. |
| ✅ | Metajuego de 10 Condecoraciones / Badges | Completado | `BadgeRegistry` con evaluación pura de méritos y pestaña en Perfil. |
| ✅ | Pista DEFENDER en Academia de Tutoriales | Completado | Lecciones interactivas 1 y 2 para el modo Ciberdefensa. |
| ✅ | Audio multicanal con buses y 16 SFX tácticos | Completado | `AudioManager`, música DavidKBD y persistencia en arranque. |
| ✅ | Documentación UML formal (Figuras 1 a 7 en PDF) | Completado | Estándar UML 2.5, verbos en infinitivo y fichas de Casos de Uso. |
| ✅ | Suite de pruebas headless con watchdog de 10s | Completado | 45 suites en verde, 0 fallos, 0 cuelgues. |

## Futuras Mejoras (v0.7.0+)

| # | Propuesta | Prioridad | Notas |
|---|---|:---:|---|
| 1 | Tarjeta de Sector 0 en selector de mundos | Media | Candado visual "ACCESO CLASIFICADO" al alcanzar 15★ sin depender solo de Konami. |
| 2 | Niveles de Ciberdefensa adicionales (D6+ / Boss Rush) | Baja | Modos de asedio continuo con oleadas múltiples de atacantes. |
| 3 | Extracción de lore de Database a JSON externo | Baja | Desacoplar textos de `database_renderer.gd` a recursos de datos. |
| 4 | Soporte para paquetes de mapas comunitarios | Baja | Importador de grafos en formato JSON externo desde la carpeta de usuario. |

## Criterios de Calidad

Un nivel o módulo se considera "terminado" cuando:
- [x] Grafo validado topológicamente (sin dead-ends involuntarios y con corte mínimo verificado).
- [x] Mecánicas funcionales probadas en suites de tests headless.
- [x] HUD limpio y legible sin solapamientos en resoluciones estándar.
- [x] Persistencia y registro de estrellas/par integrado en el slot activo.
- [x] Cero regresiones en la suite global de 45 pruebas automatizadas.
