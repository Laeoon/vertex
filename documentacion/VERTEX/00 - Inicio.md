---
title: "VERTEX — Simulador de Ciberseguridad"
status: "active"
version: "0.1.0-alpha"
tags:
  - project
  - godot
  - graph-theory
  - cybersecurity
  - education
---

# VERTEX — Simulador de Ciberseguridad Basado en Teoría de Grafos

## Qué es

Un simulador educativo donde una red informática se modela como un grafo dirigido y ponderado G=(V,E). El jugador infiltra, hackea o defiende la red usando mecánicas basadas en [[03 - Arquitectura|algoritmos de grafos]] reales (Dijkstra, Edmonds-Karp).

## Objetivo pedagógico

Enseñar conceptos de ciberseguridad y teoría de grafos de forma abstracta y segura. El jugador no ejecuta ataques reales — aprende lógica, patrones y consecuencias dentro de un entorno controlado.

## Stack técnico

| Componente | Versión | Propósito |
|---|---|---|
| Godot Engine | 4.7 stable | Motor del juego |
| GDScript | 4.7 | Lógica con tipado estático |
| Custom Resources | `.tres` | Topología de red (Data-Driven) |
| SceneTree headless | `godot --headless` | Tests automatizados |

## Estructura del proyecto

```
core/                    # Motor de teoría de grafos
│   ├── network/         # .tres + runtime del grafo
│   ├── agents/          # Dijkstra, Edmonds-Karp, MinHeap
│   ├── fsm/             # Máquinas de estado
│   ├── autoloads/       # GameLogger, Events, SceneParams, SceneTransition, AudioManager
│   ├── locale/          # Internacionalización (ES/EN/PT)
│   └── integration/     # Wrappers reactivos
juego/                   # Lógica de gameplay
│   ├── ataque/          # Modo ataque (gameplay principal)
│   ├── system/          # GameManager, LevelRegistry, mecánicas
│   ├── heist/           # Niveles Heist (.tres + .json)
│   ├── hacker/          # Niveles Hacker (.tres + .json)
│   ├── cyber/           # Niveles Cybersecurity (.tres + .json)
│   ├── defense/         # Nivel Defensa Perimetral
│   ├── tutorials/       # Sistema de tutoriales
│   └── utils/           # Utilidades compartidas (ProgressUtil, LocUtil)
escenas/                 # Menús (main_menu, selector de mundos)
tests/                   # Tests automatizados (core, ataque, tutorials)
documentacion/           # Documentación del proyecto
```

## Modos de juego

| Modo | Mecánica central | Algoritmo |
|------|------------------|-----------|
| Heist | Infiltración con presupuesto y waypoints | Dijkstra |
| Hacker | Movimiento lateral con ruido y exploits | Dijkstra |
| Cybersecurity | Defensa con bloqueos y corte mínimo | Edmonds-Karp |

## Tutoriales

Sistema integrado de tutoriales guiados con progreso, glosario, tooltips y recordatorios de acción. Cubren los cuatro modos y un nivel experto combinado. Ver [[16 - Tutoriales Alfa 0.1.0]].

## Enlaces

- [[01 - Estado actual]]
- [[02 - Roadmap]]
- [[03 - Arquitectura]]
- [[04 - Mecánicas]]
