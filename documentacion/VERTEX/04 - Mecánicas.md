---
title: "Mecánicas del Juego"
created: "2026-06-26"
tags:
  - mechanics
  - gameplay
---

# Mecánicas del Juego

## Pesos duales

Cada arista del grafo tiene dos pesos independientes:

| Peso | Variable | Uso | Algoritmo |
|------|----------|-----|-----------|
| Tránsito | `transit_cost` | Costo de movimiento | Dijkstra |
| Mitigación | `mitigation_capacity` | Capacidad de bloqueo | Edmonds-Karp |

**Regla:** Dijkstra solo lee `transit_cost`. Edmonds-Karp solo lee `mitigation_capacity`. Nunca se mezclan.

## Algoritmos

### Dijkstra (DefensivePathfinder)
- **Ruta:** Nodo origen → nodo destino de menor costo
- **Complejidad:** O((V+E)logV) con min-heap
- **Uso:** Heist (ruta del jugador), Hacker (ruta del atacante), Defensa (ruta del enemigo)

### Edmonds-Karp (StrategicAnalyzer)
- **Flujo máximo** entre source y sink
- **Corte mínimo:** Aristas más baratas para cortar todas las rutas
- **Complejidad:** O(V·E²)
- **Uso:** Modo defensor — sugerir bloqueos óptimos

Ver: [[09 - Defensa#Corte mínimo]]

## Sistema de waypoints

- Los waypoints son nodos que el jugador DEBE visitar antes del target
- Se marcan con ◇ dorado en el grafo
- Si el jugador llega al target sin completar waypoints → derrota
- Waypoints se procesan en orden secuencial

## Sistema de presupuesto (Heist)

- Presupuesto fijo por nivel (ej: 12 puntos)
- Cada movimiento resta `transit_cost` del presupuesto
- Si presupuesto = 0 y no estás en target → derrota
- Estrellas = puntos sobrantes / presupuesto total

Ver: [[07 - Heist]]

## Sistema de ruido (Hacker)

- Cada movimiento: +5 ruido
- Exploits: +15 (bypass), +25 (escalate), +10 (persist)
- Decay: -3 ruido por turno
- Umbrales: 30 (baja), 60 (alta), 85 (crítica)

Ver: [[08 - Hacker]]

## Sistema de defensa (Cybersecurity)

- El jugador es el DEFENSOR, la IA es el ATACANTE
- Bloqueos de aristas con duración configurable
- Firewall de nodo: sellado permanente (2 bloqueos)
- Victoria por aislamiento, firewall o tiempo

Ver: [[09 - Defensa]]

## Enlaces

- [[07 - Heist]]
- [[08 - Hacker]]
- [[09 - Defensa]]
- [[03 - Arquitectura]]
