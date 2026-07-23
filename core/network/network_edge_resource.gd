class_name NetworkEdgeResource extends Resource

## Conexión dirigida entre dos nodos del grafo.
## Contiene DOS PESOS INDEPENDIENTES:
##   - transit_cost        → usado por Dijkstra (latencia/resistencia)
##   - mitigation_capacity → usado por Edmonds-Karp (coste de parchear)
##
## Inmutable en runtime; las modificaciones se hacen en NetworkRuntime.

@export var from_id: StringName = &""
@export var to_id: StringName = &""
@export var transit_cost: float = 1.0
@export var mitigation_capacity: float = 1.0
@export var protocol: StringName = &"TCP"


func is_self_loop() -> bool:
	return from_id != &"" and from_id == to_id


func _to_string() -> String:
	return "Edge(%s → %s | tc=%.2f, mc=%.2f)" % [from_id, to_id, transit_cost, mitigation_capacity]
