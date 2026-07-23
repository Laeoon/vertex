class_name NetworkRuntime extends RefCounted

## Capa MUTABLE en memoria que envuelve un NetworkGraphResource.
##
## Es la única vía permitida para consultar y modificar el estado
## dinámico del grafo. El archivo .tres original NO se toca.
##
## Mantiene:
##   - graph               → referencia al recurso inmutable
##   - node_states         → {id: StringName} estado FSM por nodo
##   - node_threat_levels  → {id: float}       nivel de amenaza (0..1)
##   - _adjacency          → {from: {to: {tc, mc, protocol}}} caché O(1)

const INF_COST: float = INF

var graph: NetworkGraphResource
var node_states: Dictionary = {}          # {StringName: StringName}
var node_threat_levels: Dictionary = {}   # {StringName: float}
var _adjacency: Dictionary = {}           # {StringName: {StringName: Dictionary}}


func _init(p_graph: NetworkGraphResource = null) -> void:
	if p_graph != null:
		graph = p_graph
		_initialize()


func _initialize() -> void:
	_adjacency.clear()
	node_states.clear()
	node_threat_levels.clear()

	if graph == null:
		return

	# Inicializa estados desde los defaults de cada nodo
	for n in graph.nodes:
		if n == null:
			continue
		node_states[n.id] = n.initial_state
		node_threat_levels[n.id] = 0.0

	rebuild_adjacency()


## Reconstruye el índice de adyacencia a partir del grafo.
## Llamar después de modificar edges en el recurso (raro en runtime).
func rebuild_adjacency() -> void:
	_adjacency.clear()
	if graph == null:
		return
	for e in graph.edges:
		if e == null:
			continue
		if not _adjacency.has(e.from_id):
			_adjacency[e.from_id] = {}
		_adjacency[e.from_id][e.to_id] = {
			"transit_cost": e.transit_cost,
			"mitigation_capacity": e.mitigation_capacity,
			"protocol": e.protocol,
		}


## Devuelve un array de diccionarios con los vecinos salientes de un nodo.
## Cada dict: {to_id, transit_cost, mitigation_capacity, protocol}.
## Devuelve array vacío si el nodo no existe o no tiene aristas salientes.
func get_neighbors(p_id: StringName) -> Array:
	if not _adjacency.has(p_id):
		return []
	var adj: Dictionary = _adjacency[p_id]
	var result: Array = []
	for to_id in adj.keys():
		var data: Dictionary = adj[to_id]
		result.append({
			"to_id": to_id,
			"transit_cost": data["transit_cost"],
			"mitigation_capacity": data["mitigation_capacity"],
			"protocol": data["protocol"],
		})
	return result


## ¿Existe la arista (from → to)?
func has_edge(p_from: StringName, p_to: StringName) -> bool:
	if not _adjacency.has(p_from):
		return false
	return _adjacency[p_from].has(p_to)


## Devuelve el transit_cost de la arista, o INF si no existe.
## Pensado para Dijkstra: INF representa "camino bloqueado / inalcanzable".
func get_transit_cost(p_from: StringName, p_to: StringName) -> float:
	if not has_edge(p_from, p_to):
		return INF_COST
	return _adjacency[p_from][p_to]["transit_cost"]


## Devuelve la mitigation_capacity de la arista, o 0 si no existe.
## Pensado para Edmonds-Karp: 0 representa "no se puede empujar flujo".
func get_mitigation_capacity(p_from: StringName, p_to: StringName) -> float:
	if not has_edge(p_from, p_to):
		return 0.0
	return _adjacency[p_from][p_to]["mitigation_capacity"]


# ─── MUTACIONES (en memoria, .tres intacto) ───────────────────────────

func set_transit_cost(p_from: StringName, p_to: StringName, p_value: float) -> void:
	if not has_edge(p_from, p_to):
		push_warning("set_transit_cost: arista '%s'→'%s' no existe" % [p_from, p_to])
		return
	_adjacency[p_from][p_to]["transit_cost"] = p_value


func set_mitigation_capacity(p_from: StringName, p_to: StringName, p_value: float) -> void:
	if not has_edge(p_from, p_to):
		push_warning("set_mitigation_capacity: arista '%s'→'%s' no existe" % [p_from, p_to])
		return
	_adjacency[p_from][p_to]["mitigation_capacity"] = p_value


func set_node_state(p_id: StringName, p_state: StringName) -> void:
	if not node_states.has(p_id):
		push_warning("set_node_state: nodo '%s' no existe" % p_id)
		return
	node_states[p_id] = p_state


func get_node_state(p_id: StringName) -> StringName:
	return node_states.get(p_id, &"unknown")


func set_threat_level(p_id: StringName, p_level: float) -> void:
	if not node_threat_levels.has(p_id):
		push_warning("set_threat_level: nodo '%s' no existe" % p_id)
		return
	node_threat_levels[p_id] = p_level


func get_threat_level(p_id: StringName) -> float:
	return node_threat_levels.get(p_id, 0.0)
