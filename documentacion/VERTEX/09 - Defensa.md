---
title: "Mundo Defensa (Cybersecurity)"
created: "2026-06-26"
tags:
  - cybersecurity
  - defense
  - mechanics
  - strategic-analyzer
---

# Mundo Defensa — Cybersecurity

## Concepto

El jugador es el DEFENSOR. Un atacante avanza por la red hacia Database. El jugador bloquea rutas para proteger la base de datos.

## Mecánica central

- **Bloqueo de aristas** con duración configurable
- **Firewall de nodo** (sellado permanente, cuesta 2 bloqueos)
- **Corte mínimo** como herramienta de sugerencia (StrategicAnalyzer)
- **Victoria por:** aislamiento, firewall, o tiempo agotado

## Acciones del defensor

| Acción | Tecla | Costo | Efecto |
|--------|-------|-------|--------|
| Bloquear arista | Click en arista | 1 bloqueo | Bloquea por N turnos |
| Firewall de nodo | [F] + click en nodo | 2 bloqueos | Sella permanentemente |
| Escanear | — | — | (pendiente) |

## Condiciones de victoria

| Condición | Gatillo | Feedback |
|-----------|---------|----------|
| Aislamiento | Bloquear última ruta del atacante | "¡Aislamiento total!" |
| Firewall | Firewall que corta toda ruta | "¡Firewall estratégico!" |
| Tiempo | Atacante no llega en N turnos | "N turnos resistidos" |
| Sin ruta | Atacante empieza sin camino | "Atacante sin ruta" |

## Corte mínimo (StrategicAnalyzer)

El StrategicAnalyzer calcula las aristas más baratas para cortar todas las rutas del atacante:

```gdscript
var result = StrategicAnalyzer.find_min_cut(graph, &"Internet", &"Database")
# result["cut_edges"] = aristas sugeridas (ordenadas por capacidad ASC)
# result["max_flow"] = valor del flujo máximo
```

Se muestra en el HUD como "✂ CORTE MÍNIMO — Flujo máx: X.X" con aristas en dorado.

Ver: [[03 - Arquitectura#Algoritmos]]

## Event Bus integrado

- `Events.path_calculated` → ruta del atacante (naranja pulsante)
- `Events.node_state_changed` → bloqueos expirando

Ver: [[03 - Arquitectura#Estado y eventos]]

## Niveles

| Nivel | Nodos | Turnos | Bloqueos/turno | Duración bloqueo | Dificultad |
|-------|-------|--------|----------------|------------------|------------|
| N1 — Defensa en Capas | 10 | 18 | 3 | 5 turnos | 3 |
| N2 — Defensa Perimetral | — | 12 | 2 | 4 turnos | 2 |

## Grafo N1 — Defensa en Capas

```
Internet → FirewallPer → DMZ → InternalFW → ServInterno → Database
Internet → Proxy → MailServer → InternalFW ↗
Internet → IDS → Monitor → Database
```

**El atacante empieza en Internet y avanza hacia Database.**

## Grafo N2 — Defensa Perimetral

```
(Ver defense_n1.tres para el grafo completo)
```

**El atacante empieza en Internet y avanza hacia DataCenter.**

## Tutoriales asociados

- [[04 - Mecánicas#Tutorial defensa]]: Fundamentos de defensa
- [[04 - Mecánicas#Tutorial 5]]: Defensa perimetral

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `juego/cyber/cyber_n1.tres` | Grafo N1 |
| `juego/cyber/cyber_n1.json` | Config N1 (defender_mode: true) |
| `juego/defense/defense_n1.tres` | Grafo N2 |
| `juego/defense/defense_n1.json` | Config N2 (defender_mode: true) |

## Enlaces

- [[04 - Mecánicas#Sistema de defensa]]
- [[06 - Level Design#Grafo Cyber N1]]
- [[05 - UI HUD#ZONA 1b]]
- [[03 - Arquitectura#Algoritmos]]
