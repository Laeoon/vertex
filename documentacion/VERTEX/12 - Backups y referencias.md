---
title: "Backups y Referencias"
created: "2026-06-26"
updated: "2026-08-03"
tags:
  - backup
  - references
---

# Backups y Referencias

## Repositorio

- **Rama principal:** `main`
- **Remoto:** https://github.com/Laeoon/vertex.git
- **Release:** https://github.com/Laeoon/vertex/releases/latest

## Paper de referencia

**Shivakumar MD & Mamatha N (2022)**
"Applications of graph theory in cybersecurity: Network defense models"
World Journal of Advanced Research and Reviews, 14(02), 735–743
DOI: 10.30574/wjarr.2022.14.2.0467

### Mapping paper → implementación

| Sección del paper | Implementación en VERTEX |
|-------------------|--------------------------|
| §2 Network Topology Modeling | NetworkGraphResource + NetworkNodeResource + NetworkEdgeResource |
| §3 Attack Graph Generation | DefensivePathfinder (Dijkstra) |
| §3 Cut-Set Analysis | StrategicAnalyzer (Edmonds-Karp) |
| §4 Intrusion Detection | detection_chance + pursuers |
| §5 Vulnerability Assessment | Pesos duales (transit_cost + mitigation_capacity) |
| §6 Game-Theoretic Defense | Gameplay (jugador vs IA defensora) |
| §6 Moving Target Defense | IA bloquea/reconfigura aristas por turno |

## Enlaces

- [[00 - Inicio]]
- [[03 - Arquitectura]]
