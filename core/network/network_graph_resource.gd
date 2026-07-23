class_name NetworkGraphResource extends Resource

## Contenedor del grafo: arrays de nodos y aristas.
## Es la "foto estática" de la topología. Inmutable en runtime.
##
## Toda mutación se canaliza a través de NetworkRuntime, que envuelve
## una instancia de este recurso y mantiene un caché de adyacencia.

@export var nodes: Array[NetworkNodeResource] = []
@export var edges: Array[NetworkEdgeResource] = []
@export var directed: bool = true


## Devuelve el nodo con el id solicitado, o null si no existe.
func get_node_by_id(p_id: StringName) -> NetworkNodeResource:
	for n in nodes:
		if n != null and n.id == p_id:
			return n
	return null


## Valida la coherencia interna del grafo.
## Devuelve un array de mensajes de error (vacío si todo está OK).
func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen_ids: Dictionary = {}

	# 1) IDs de nodos únicos y no vacíos
	for n in nodes:
		if n == null:
			errors.append("Nodo nulo en el array 'nodes'")
			continue
		if n.id == &"":
			errors.append("Nodo con id vacío (display_name='%s')" % n.display_name)
			continue
		if seen_ids.has(n.id):
			errors.append("ID de nodo duplicado: '%s'" % n.id)
		seen_ids[n.id] = true

	# 2) Aristas coherentes
	var seen_edges: Dictionary = {}
	for e in edges:
		if e == null:
			errors.append("Arista nula en el array 'edges'")
			continue
		if not seen_ids.has(e.from_id):
			errors.append("Arista '%s'→'%s' tiene origen inexistente" % [e.from_id, e.to_id])
		if not seen_ids.has(e.to_id):
			errors.append("Arista '%s'→'%s' tiene destino inexistente" % [e.from_id, e.to_id])
		if e.is_self_loop():
			errors.append("Self-loop no permitido: '%s'" % e.from_id)
		if e.transit_cost < 0.0:
			errors.append("transit_cost negativo en '%s'→'%s'" % [e.from_id, e.to_id])
		if e.mitigation_capacity < 0.0:
			errors.append("mitigation_capacity negativo en '%s'→'%s'" % [e.from_id, e.to_id])
		if directed:
			var key: String = "%s→%s" % [e.from_id, e.to_id]
			if seen_edges.has(key):
				errors.append("Arista duplicada: '%s'" % key)
			seen_edges[key] = true

	return errors


## Cuenta de nodos. Útil para asserts.
func node_count() -> int:
	return nodes.size()


## Cuenta de aristas. Útil para asserts.
func edge_count() -> int:
	return edges.size()


func get_edge(p_from: StringName, p_to: StringName) -> NetworkEdgeResource:
	for e in edges:
		if e != null and e.from_id == p_from and e.to_id == p_to:
			return e
	return null


func _to_string() -> String:
	return "Graph(|V|=%d, |E|=%d, directed=%s)" % [nodes.size(), edges.size(), directed]
