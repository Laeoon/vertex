---
title: "Arquitectura del Sistema"
created: "2026-06-26"
tags:
  - architecture
  - godot
  - design
---

# Arquitectura del Sistema

## Visión general

VERTEX usa una arquitectura **Data-Driven** con separación estricta entre datos, lógica y presentación.

```
┌─────────────────────────────────────────────────────┐
│                    PRESENTACIÓN                      │
│  GameRenderer (game_renderer.gd)                    │
│  Menú principal, selector de niveles, HUD           │
├─────────────────────────────────────────────────────┤
│                    LÓGICA DE JUEGO                   │
│  juego_ataque.gd (orquestador)                      │
│  hacker_mechanics.gd                                │
│  LevelManager / LevelRegistry                       │
├─────────────────────────────────────────────────────┤
│                    ALGORITMOS                        │
│  DefensivePathfinder (Dijkstra)                     │
│  StrategicAnalyzer (Edmonds-Karp)                   │
│  MinHeap                                            │
├─────────────────────────────────────────────────────┤
│                    ESTADO Y EVENTOS                  │
│  NetworkRuntime (mutable)                           │
│  Event Bus (events.gd)                              │
│  FSM (network_node.gd)                              │
├─────────────────────────────────────────────────────┤
│                    DATOS (inmutables)                │
│  NetworkGraphResource (.tres)                       │
│  NetworkNodeResource / NetworkEdgeResource          │
│  JSON de niveles (.json)                            │
└─────────────────────────────────────────────────────┘
```

## Capas detalladas

### Datos (inmutables)
- **NetworkGraphResource**: Contenedor del grafo con arrays de nodos y aristas
- **NetworkNodeResource**: Nodo con id, posición, tipo, metadata
- **NetworkEdgeResource**: Arista con `transit_cost` (Dijkstra) y `mitigation_capacity` (Edmonds-Karp)
- **JSON de niveles**: Configuración de cada nivel (graph_path, waypoints, IA, etc.)

Ver: [[04 - Mecánicas#Pesos duales]]

### Estado y eventos
- **NetworkRuntime**: Capa mutable que envuelve un `.tres` inmutable. Mapa de adyacencia O(1)
- **Event Bus**: 4 señales centralizadas (node_state_changed, threat_detected, path_calculated, min_cut_identified)
  - **Emisores**: juego_ataque.gd, network_node.gd, reactive_analyzer.gd, reactive_pathfinder.gd
  - **Consumidores**: Solo wrappers reactivos (Hito 5) y sandboxes de test. El UI no consume eventos (diseño actual: datos directos al renderer)
- **FSM**: Estados DISPONIBLE → ALERTADO → CAPTURADO por nodo

Ver: [[09 - Defensa#Event Bus]]

### Algoritmos
- **DefensivePathfinder**: Dijkstra O((V+E)logV) con min-heap
- **StrategicAnalyzer**: Edmonds-Karp O(VE²) para corte mínimo
- **MinHeap**: Estructura de datos para Dijkstra

Ver: [[04 - Mecánicas#Algoritmos]]

### Lógica de juego
- **juego_ataque.gd**: Orquestador principal (~1300 líneas)
- **GameRenderer**: Rendering separado de lógica
- **hacker_mechanics.gd**: Sistema de ruido y exploits

### Presentación
- **GameRenderer**: HUD en 3 zonas, grid de fondo, hints opcionales
- **Menú principal**: Cyberpunk (scan lines, glow)
- **Selector de niveles**: Mapa de nodos estilo subway

## Decisiones de arquitectura

| Decisión | Razón | Alternativa descartada |
|----------|-------|------------------------|
| Data-Driven (.tres) | Separar datos de lógica | Hardcodear grafos en scripts |
| Event Bus centralizado | Desacoplamiento total | Llamadas directas entre módulos |
| Algoritmos stateless | Reutilizables y testables | Estado compartido |
| GameRenderer separado | Separación rendering/lógica | Todo en un solo script |

## Enlaces

- [[00 - Inicio]]
- [[04 - Mecánicas]]
- [[09 - Defensa#Event Bus]]
