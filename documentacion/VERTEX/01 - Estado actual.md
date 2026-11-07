---
title: "Estado Actual del Proyecto"
created: "2026-06-26"
updated: "2026-10-28"
status: "active"
tags:
  - status
  - snapshot
---

# Estado Actual del Proyecto

## Resumen ejecutivo

VERTEX se encuentra en **versión 0.6.0** — versión mayor con campaña completa de 16 niveles, 4 modos de juego, nivel secreto cinemático ("Sector 0: Root Genesis"), terminal CLI interactiva in-game, sistema de 3 ranuras de guardado independientes (Save Slots) con snapshots automáticos y respaldo criptográfico `.bak` (SHA-256), visualizador de audio reactivo en riel de nodos y suite de pruebas automatizadas con 45 suites en verde.

## Modos de juego

| Modo | Mecánica | Estado |
|---|---|:---:|
| **Heist** | Presupuesto de movimiento + waypoints + IA bloqueadora + bonus nodes | ✅ Completo (5 niveles) |
| **Hacker** | Ruido perimetral + scans + 4 exploits abstractos (Bypass, Escalate, Persist, Decoy) | ✅ Completo (5 niveles) |
| **Cybersecurity (Blue Team)** | Ciclo reactivo 1:1 (Ping-Pong) + Rastreo Forense EDR (0..100%) + Cuarentena [C] | ✅ Completo (5 niveles) |
| **Sector 0 (Nivel Secreto)** | Kernel Void + Lluvia Hex Dump + Nodos cinemáticos + Colapso de memoria | ✅ Desbloqueo Konami |

## Inventario Completo de Niveles (16 Niveles)

| Mundo | Nivel | Título | Dificultad | Mecánica Central |
|---|---|---|:---:|---|
| **Heist** | N1 | La Entrada | 1 | Presupuesto base, waypoints de bóveda |
| **Heist** | N2 | El Laberinto | 2 | Cruce de seguridad perimetral |
| **Heist** | N3 | Ojo del Casino | 3 | Desvío de cámaras y sensores |
| **Heist** | N4 | Blackout | 4 | Niebla y re-enrutado por corte |
| **Heist** | N5 | Extracción Final | 5 | Evasión multinodal min-cut $\ge 2$ |
| **Hacker** | N1 | Lateral Movement | 2 | Introducción a ruido y exploits |
| **Hacker** | N2 | Brecha Corporativa | 3 | DMZ a Base de Datos |
| **Hacker** | N3 | Persistencia de Red | 3 | Creación de zonas seguras (Persist) |
| **Hacker** | N4 | Guerra de Señuelos | 4 | Desvío de bloqueos con Decoy |
| **Hacker** | N5 | Root Compromise | 5 | Infiltración a Quantum Vault min-cut $\ge 3$ |
| **Cybersecurity** | N1 | Defensa Perimetral (`defense_n1`) | 1 | Ciclo 1:1 y bloqueo de aristas |
| **Cybersecurity** | N2 | Defensa en Capas (`cyber_n1`) | 2 | Detección perimetral y contención |
| **Cybersecurity** | N3 | Movimiento Lateral (`cyber_n2`) | 3 | Aislamiento de host con tecla [C] |
| **Cybersecurity** | N4 | Niebla de Guerra (`cyber_n3`) | 4 | Intercepción de telemetría [P] |
| **Cybersecurity** | N5 | Operación Zero Trust (`cyber_n4`) | 5 | Contención ante intrusos con Bypass |
| **Sector 0** | Secret | Root Genesis (`secret_root`) | Master | Desintegración por entropía de kernel |

## Tutoriales y Academia

13 módulos estructurados en 4 pistas temáticas interactivas:
- **General (Fundamentos):** Módulos 1 y 2 (conceptos de grafo, navegación y paradas obligatorias).
- **Heist:** Módulos 1 y 2 (gestión de presupuesto y evasión).
- **Hacker:** Módulos 1 al 4 (uso de los 4 exploits abstractos y gestión de ruido).
- **Defender:** Módulos 1 y 2 (ciclo reactivo 1:1, EDR Trace, contención y cuarentena [C]).

## Sistema de Guardado, Persistencia y Seguridad (v0.6.0)

- **3 Save Slots independientes:** Carpetas aisladas en `user://slots/slot_1..3/`.
- **Snapshots preventivos automáticos:** Hasta 5 copias históricas por slot en `user://slots/slot_X/backups/`.
- **Respaldo `.bak` con SHA-256:** Exportación e importación atómica de perfiles con validación criptográfica ante corrupción.
- **Controles en StartScreen:** Teclas directas `[E]` Exportar, `[I]` Importar, `[R]` Restaurar y `[Supr]` Borrar seguro.

## Paisaje Sonoro y Audio Reactivo

- **Motor Multicanal:** Buses dedicados Master, Music y SFX gestionados por `AudioManager`.
- **AudioSpectrumVisualizer:** Onda reactiva densa montada directamente a lo largo del riel de niveles (envolvente simétrica basada en decibelios -52 dB).
- **Banda sonora:** Packs de DavidKBD (Cyberpunk / Synth) y 16 SFX procedurales con prioridades dinámicas.

## Calidad y Pruebas Automatizadas

- **Suite de Pruebas:** 45 suites activas ejecutables en headless mediante `tests/runner/run_all.gd` con watchdog de 10 segundos.
- **Cero regresiones:** Módulos desacoplados en `core/`, `juego/system/` y `juego/ui/`.
- **Documentación formal:** Diagramas UML 2.5 (Figuras 1 a 7) compilados en PDF vectorial y fichas técnicas de Casos de Uso (CU-01 a CU-11).

## Entrega y Repositorio

- **Versión:** `v0.6.0`
- **Repositorio:** https://github.com/Laeoon/vertex.git
- **Ejecutable:** `VERtex-0.6.0.exe` (Windows x64) en GitHub Releases.
