---
title: "Decisiones de Diseño"
created: "2026-06-26"
tags:
  - decisions
  - design
---

# Decisiones de Diseño

## Arquitectura

| Decisión | Razón | Alternativa descartada | Fecha |
|----------|-------|------------------------|-------|
| Data-Driven (.tres) | Separar datos de lógica, facilita validación | Hardcodear grafos en scripts | Hito 1 |
| Event Bus centralizado | Desacoplamiento total entre componentes | Llamadas directas | Hito 4 |
| Algoritmos stateless | Reutilizables, testables, sin efectos secundarios | Estado compartido | Hito 2-3 |
| GameRenderer separado | Separación rendering/lógica | Todo en juego_ataque.gd | v1.4.0 |

## Gameplay

| Decisión | Razón | Fecha |
|----------|-------|-------|
| Línea amarilla eliminada | Confundía al jugador, no era la ruta óptima real | 2026-06-24 |
| Hints opcionales con P | UX: el jugador decide cuándo ver ayuda | 2026-06-24 |
| Core solo accesible desde AdminPanel | Forzar waypoints obligatorios en hacker | 2026-06-24 |
| Aislamiento = Victoria | Transformar bloqueos en decisiones tácticas | 2026-06-26 |
| Firewall de nodo permanente | Estrategia de defensa a largo plazo | 2026-06-26 |
| Presupuesto gradual por nivel | No frustrar pero exigir decisiones | 2026-06-24 |

## UI/UX

| Decisión | Razón | Fecha |
|----------|-------|-------|
| HUD en 3 zonas | Legibilidad y escaneo rápido | 2026-06-24 |
| Grid de fondo sutil | Sensación de tablero de red | 2026-06-24 |
| Menú cyberpunk (scan lines, glow) | Identidad visual | 2026-06-24 |
| Paleta de alto contraste | Accesibilidad visual | 2026-06-23 |

## Decisiones descartadas

| Decisión | Por qué se descartó |
|----------|---------------------|
| Multiplayer en tiempo real | Complejidad excesiva para proyecto TSU |
| Niveles proceduralmente generados | Difícil de balancear y validar |
| Motor personalizado | Godot cumple todos los requisitos |

## Enlaces

- [[03 - Arquitectura]]
- [[04 - Mecánicas]]
- [[05 - UI HUD]]
