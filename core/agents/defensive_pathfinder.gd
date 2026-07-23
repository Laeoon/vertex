class_name DefensivePathfinder extends RefCounted

## Motor de Reacción del Agente Defensivo.
## Implementa Dijkstra con min-heap binario para encontrar el camino
## de menor transit_cost entre dos nodos del grafo.
##
## - Salida principal:  Array[StringName] con la secuencia origen→destino.
## - Salida diagnóstica: Dictionary con {path, cost, reachable}.
##
## Características:
##   - O((V + E) log V) con heap binario (escala a miles de nodos).
##   - Early break de seguridad cuando la distancia mínima extraída es INF
##     (segmentación de red: el objetivo es inalcanzable).
##   - Early break al alcanzar el target (no necesita explorar todo el grafo).
##   - Consume EXCLUSIVAMENTE transit_cost (no toca mitigation_capacity).
##   - Stateless: cada llamada es independiente. No hay efectos secundarios.
##
## Uso:
##   var path: Array[StringName] = \
##       DefensivePathfinder.find_path(graph, &"Agente", &"Servidor_Web")
##   if path.is_empty():
##       push_warning("Objetivo inalcanzable, replantear")
##   else:
##       fsm.follow(path)

const MinHeap = preload("res://core/agents/min_heap.gd")


## ─── API PÚBLICA ──────────────────────────────────────────────────────

## Devuelve el camino más corto como Array[StringName].
## Devuelve [] si el objetivo es inalcanzable o los inputs son inválidos.
static func find_path(
	graph: NetworkGraphResource,
	start: StringName,
	target: StringName
) -> Array[StringName]:
	var result := _dijkstra(graph, start, target)
	return result.path


## Devuelve un Dictionary con tres campos:
##   path      → Array[StringName]   secuencia de nodos
##   cost      → float                coste total acumulado (INF si inalcanzable)
##   reachable → bool                 true si existe camino
##
## Si se pasa un runtime, usa ese (respeta bloqueos/modificaciones).
## Si no, crea uno nuevo desde el grafo original.
static func find_path_with_cost(
	graph: NetworkGraphResource,
	start: StringName,
	target: StringName,
	runtime: NetworkRuntime = null
) -> Dictionary:
	var result := _dijkstra(graph, start, target, runtime)
	return {
		"path": result.path,
		"cost": result.cost,
		"reachable": result.reachable,
	}


# ─── IMPLEMENTACIÓN ───────────────────────────────────────────────────

class _Result extends RefCounted:
	var path: Array[StringName] = []
	var cost: float = INF
	var reachable: bool = false


static func _dijkstra(
	graph: NetworkGraphResource,
	start: StringName,
	target: StringName,
	runtime: NetworkRuntime = null
) -> _Result:
	var result := _Result.new()

	# ── Validaciones de entrada ──
	if graph == null or graph.nodes.is_empty():
		push_warning("DefensivePathfinder: grafo nulo o vacío")
		return result
	if graph.get_node_by_id(start) == null:
		push_warning("DefensivePathfinder: nodo origen '%s' no existe" % start)
		return result
	if graph.get_node_by_id(target) == null:
		push_warning("DefensivePathfinder: nodo objetivo '%s' no existe" % target)
		return result

	# Caso trivial: origen == destino
	if start == target:
		result.path = [start]
		result.cost = 0.0
		result.reachable = true
		return result

	# ── Runtime: usa el inyectado o crea uno nuevo ──
	if runtime == null:
		runtime = NetworkRuntime.new(graph)

	# ── Estado del algoritmo ──
	var distances: Dictionary = {}   # {StringName: float}
	var previous: Dictionary = {}    # {StringName: StringName}
	var visited: Dictionary = {}     # {StringName: bool}

	for n in graph.nodes:
		if n == null:
			continue
		distances[n.id] = INF

	distances[start] = 0.0

	# ── Min-heap de (distancia, nodo) ──
	var heap := MinHeap.new()
	heap.push(0.0, start)

	# ── Bucle principal ──
	while not heap.is_empty():
		var entry: Array = heap.pop()
		var current_dist: float = entry[0]
		var current: StringName = entry[1]

		# Early safety break: el siguiente nodo más cercano está a INF.
		# Significa que el resto del grafo es inalcanzable desde `start`
		# (red segmentada). No seguimos, devolvemos camino vacío.
		if current_dist == INF:
			break

		# Si ya pasamos por este nodo con una distancia mejor o igual, skip.
		# (El heap puede contener entradas obsoletas tras un decrease-key.)
		if visited.get(current, false):
			continue

		# Si llegamos al objetivo, paramos. No hace falta relajar más.
		if current == target:
			break

		visited[current] = true

		# ── Relajación de aristas salientes ──
		for neighbor in runtime.get_neighbors(current):
			var to_id: StringName = neighbor["to_id"]
			if visited.get(to_id, false):
				continue
			var edge_cost: float = neighbor["transit_cost"]
			var tentative: float = current_dist + edge_cost
			if tentative < distances.get(to_id, INF):
				distances[to_id] = tentative
				previous[to_id] = current
				heap.push(tentative, to_id)

	# ── Reconstrucción del camino ──
	if distances.get(target, INF) == INF:
		# Inalcanzable: el resultado por defecto (path=[], reachable=false)
		# ya es correcto.
		return result

	var path: Array[StringName] = []
	var node: StringName = target
	var safety: int = graph.nodes.size() + 1  # guard contra bucles
	while node != &"" and safety > 0:
		path.push_front(node)
		if node == start:
			break
		node = previous.get(node, &"")
		safety -= 1

	# Sanity: el camino debe empezar en `start`.
	if path.is_empty() or path[0] != start:
		push_warning("DefensivePathfinder: reconstrucción inconsistente")
		return _Result.new()

	result.path = path
	result.cost = distances[target]
	result.reachable = true
	return result
