---
title: "Event Bus"
created: "2026-07-10"
tags:
  - event-bus
  - signals
  - architecture
---

# Event Bus

## Concepto

El Event Bus es un patrón Observer centralizado implementado como autoload en `core/autoloads/events.gd`. Funciona como punto de encuentro entre productores (FSM, agentes, pathfinders) y consumidores (UI, logs, persistencia).

**Regla:** NO contiene lógica de negocio. Solo emite y propaga señales.

## Señales definidas

| Señal | Parámetros | Emisor | Descripción |
|-------|------------|--------|-------------|
| `node_state_changed` | `node_id: StringName, old_state: int, new_state: int` | network_node.gd, juego_ataque.gd | Un nodo cambió de estado FSM |
| `threat_detected` | `node_id: StringName, threat_level: float` | network_node.gd | Nodo entra en estado ALERTADO |
| `path_calculated` | `source: StringName, target: StringName, path: Array[StringName], cost: float` | juego_ataque.gd, reactive_pathfinder.gd | Pathfinder terminó un cálculo |
| `min_cut_identified` | `source: StringName, sink: StringName, max_flow: float, cut_edges: Array` | reactive_analyzer.gd | Analyzer identificó corte mínimo |

## Convención de nombres

Los nombres usan pasado (`calculated`, `identified`) porque describen hechos, no peticiones.

## Emisores

| Archivo | Señales que emite |
|---------|-------------------|
| `juego/ataque/juego_ataque.gd` | `path_calculated`, `node_state_changed` |
| `core/fsm/network_node.gd` | `node_state_changed`, `threat_detected` |
| `core/integration/reactive_analyzer.gd` | `min_cut_identified` |
| `core/integration/reactive_pathfinder.gd` | `path_calculated` |

## Consumidores

| Archivo | Señales que consume |
|---------|---------------------|
| `core/integration/reactive_analyzer.gd` | `node_state_changed` |
| `core/integration/reactive_pathfinder.gd` | `threat_detected` |
| `archive/sandboxes/` (test files) | Todas las señales |

### Consumidores ausentes

El **UI/HUD** (game_renderer.gd, juego_ataque.gd) NO se suscribe a ninguna señal del Event Bus. Los datos se pasan como parámetros directos al renderer.

## Decisión de diseño: por qué el UI no consume eventos

El Event Bus no se conecta al UI por las siguientes razones:

1. **Simplicidad:** El diseño actual (datos directos al renderer) es más simple de entender y mantener
2. **Eficiencia:** No hay overhead de señales para datos que ya están disponibles en juego_ataque.gd
3. **Testing:** Las señales son útiles para wrappers reactivos y sandboxes de test, pero el UI no las necesita
4. **Separación de capas:** El renderer recibe estado calculado, no escucha eventos. Esto mantiene la separación lógica/rendering limpia

**Conclusión:** Las señales se emiten para uso de wrappers reactivos (Hito 5) y testing. El UI usa datos directos porque es más eficiente y no pierde funcionalidad. No es deuda técnica, es una decisión de diseño válida.

Ver: [[10 - Bugs y deuda técnica#Decisiones de diseño registradas]]

## Flujo de datos

```
network_node.gd ──emite──→ Events.node_state_changed
                           ↓
              reactive_analyzer.gd (consume, recalcula corte)
                           ↓
              Events.min_cut_identified
                           ↓
              Nadie consume (UI recibe datos directos)
```

## Uso en sandboxes de test

Los sandboxes en `archive/sandboxes/` son los únicos consumidores completos del Event Bus:

- `case_e_event_bus/` — Test de todas las señales
- `case_f_integration_e2e/` — Test end-to-end con señales

## Enlaces

- [[03 - Arquitectura#Estado y eventos]]
- [[10 - Bugs y deuda técnica#Decisiones de diseño registradas]]
