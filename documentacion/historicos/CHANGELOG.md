# Changelog — Simulador de Ciberseguridad

| Hito | Nombre | Sandboxes | Estado |
|---|---|---|---|---|---|
| 1 | Cimientos del grafo estático | A, B | Cerrado |
| 2 | Agente de intercepción (Dijkstra) | C | Cerrado |
| 3 | Análisis estratégico (Edmonds-Karp) | D | Cerrado |
| 4 | Event Bus + FSM | E | Cerrado |
| 5 | Wrappers de Integración Reactiva | F | Cerrado |
| 6 | GUI + Niveles Jugables + Mecánicas | — | Cerrado |

## Histórico de cambios

| Fecha | Versión | Cambio |
|---|---|---|
| 2026-06-25 | 2.0.0 | **Hito 6 completo**: niveles jugables (Heist, Hacker, Cybersecurity), mecánicas de infiltración, UI/UX rediseñada, documentación actualizada |
| 2026-06-24 | 1.9.0 | Rediseño de grafos: Hacker forza waypoints obligatorios, Heist con presupuesto balanceado, línea amarilla eliminada y reemplazada por hints opcionales (P) |
| 2026-06-24 | 1.8.0 | Mecánicas Hacker implementadas: ruido, scans, exploits abstractos (bypass/escalate/persist), HUD hacker en panel lateral |
| 2026-06-24 | 1.7.0 | UI/UX: HUD reorganizado en 3 zonas, grid de fondo, menú cyberpunk (scan lines, glow), barra visual de presupuesto, labels de arista con protocolo |
| 2026-06-24 | 1.6.0 | Bug fixes: tutorial input blocking, waypoints validation, game over por sin salida, GameManager + LevelRegistry |
| 2026-06-23 | 1.5.0 | Sistema de niveles: LevelManager, LevelRegistry, selector de niveles (mapa de nodos), mecánica de presupuesto de movimiento |
| 2026-06-23 | 1.4.0 | GameRenderer extraído de juego_ataque.gd, fix tutorial is_game_paused(), fix get_edge() en NetworkGraphResource |
| 2026-06-23 | 1.3.0 | Auditoría completa: corrección de paleta de colores (alto contraste), fix Edmons→Edmonds, FMS→FSM |
| 2026-06-22 | 1.2.0 | Base teórica WJARR 2022 integrada, actualización ROADMAP.md con hitos 1-5 completados |
| 2026-06-17 | 1.1.0 | Menú principal con selector de 4 escenas, export a Windows (.exe), controles de navegación (Q→menú, ESC→salir) |

## Estado actual de mecánicas

| Mundo | Mecánica central | Presupuesto | Estrellas |
|---|---|---|---|
| **Heist** | Presupuesto de movimiento + IA bloqueadora | 12 puntos | Puntos sobrantes |
| **Hacker** | Ruido + scans + exploits abstractos | Sin presupuesto | Ruido bajo + turnos eficientes |
| **Cybersecurity** | Roles invertidos (defensa) | Pendiente | Pendiente |

## Niveles implementados

| Mundo | Nivel | Grafo | Nodos | Aristas | Dificultad |
|---|---|---|---|---|---|
| Heist | N1 — Infiltración en la Bóveda | nivel1_red.tres | 8 | 10 | 1 |
| Heist | N2 — La Ruta del Oro | heist_n2.tres | 10 | 12 | 2 |
| Hacker | N1 — Lateral Movement | hacker_n1.tres | 11 | 12 | 2 |
| Cybersecurity | N1 — Defensa en Capas | cyber_n1.tres | 8 | 11 | 3 |

## Próximos hitos sugeridos

| Hito | Nombre tentativo |
|---|---|
| 7 | Mecánicas Cybersecurity (defensa invertida) |
| 8 | Transiciones fade entre escenas |
| 9 | Sonidos y feedback audiovisual |
| 10 | Balanced tuning y playtesting |
