extends Node

## Event Bus — Patrón Observer centralizado.
## Autoload registrado en project.godot como `Events`.
## Accesible globalmente desde cualquier script.
##
## Responsabilidad única: definir señales estrictamente tipadas
## y servir de punto de encuentro entre productores (FSM, agentes)
## y consumidores (otros agentes, UI, logs, persistencia).
##
## NO contiene lógica de negocio. NO decide qué hacer con los eventos.
## Solo emite y propaga.
##
## Señales:
##   node_state_changed    → un nodo cambió de estado FSM
##   threat_detected      → un nodo entró en ALERTADO (dispara al agente)
##   path_calculated      → el pathfinder terminó un cálculo
##   min_cut_identified   → el analyzer terminó un análisis
##
## Convención: los nombres de señales en pasado (calculado, identificado)
## porque describen hechos, no peticiones.


# ─── SEÑALES ──────────────────────────────────────────────────────────

## Emitida cuando un nodo cambia de estado en su FSM.
## Parámetros: id del nodo, estado anterior (int), estado nuevo (int).
## Usamos int en vez del enum para desacoplar el bus de la FSM concreta.
signal node_state_changed(node_id: StringName, old_state: int, new_state: int)

## Emitida cuando un nodo entra en estado ALERTADO.
## Es la señal que despierta al agente defensivo.
## Parámetros: id del nodo, nivel de amenaza (0.0 a 1.0).
signal threat_detected(node_id: StringName, threat_level: float)

## Emitida por el DefensivePathfinder cuando calcula un camino.
## Parámetros: origen, destino, camino (Array[StringName]), coste total.
signal path_calculated(source: StringName, target: StringName, path: Array[StringName], cost: float)

## Emitida por el StrategicAnalyzer cuando identifica un corte mínimo.
## Parámetros: source, sink, max_flow, cut_edges (Array[Dictionary]).
signal min_cut_identified(source: StringName, sink: StringName, max_flow: float, cut_edges: Array)
