---
title: "VERTEX — Simulador de Ciberseguridad"
created: "2026-06-26"
status: "active"
version: "2.0.0"
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
nuevo-proyecto-de-juego/
├── core/                    # Código de producción
│   ├── network/             # .tres + runtime del grafo
│   ├── agents/              # Dijkstra, Edmonds-Karp
│   ├── fsm/                 # Máquina de estados
│   ├── autoloads/           # Event Bus, SceneParams
│   └── integration/         # Wrappers reactivos
├── juego/                   # Lógica de juego
│   ├── ataque/              # Escena principal + renderer
│   ├── system/              # GameManager, LevelRegistry, mecánicas
│   ├── heist/               # Niveles Heist (.tres + .json)
│   ├── hacker/              # Niveles Hacker (.tres + .json)
│   ├── cyber/               # Niveles Cybersecurity (.tres + .json)
│   ├── tutorials/           # Sistema de tutoriales
│   └── nivel1/              # Grafo base Heist N1
├── escenas/                 # Menú principal
├── docs/                    # Documentación del código
└── archive/                 # Sandboxes históricos (A-F)
```

## Rutas importantes

| Recurso | Ruta |
|---------|------|
| Proyecto Godot | `/home/leonardo/nuevo-proyecto-de-juego/` |
| Backup histórico | `/home/leonardo/Documentos/nuevo-proyecto-de-juego/` |
| Obsidian Vault | `/home/leonardo/Documentos/Obsidian Vault/` |
| Paper WJARR | `/home/leonardo/Descargas/WJARR-2022-0467.pdf` |
| Documento tesis | `/home/leonardo/Documentos/Indormacion_mimo/` |

## Notas para agentes

- **No tocar** el `.docx` de la tesis — solo contribuir en `.md` del proyecto
- **Ziva** se usa para tareas de editor (visual, grafos, builds)
- **MiMo Code** se usa para análisis, arquitectura, documentación
- Tokens de MiMo Code ilimitados; tokens de Ziva limitados ($3/mes)

## Enlaces

- [[01 - Estado actual]]
- [[02 - Roadmap]]
- [[03 - Arquitectura]]
- [[04 - Mecánicas]]
