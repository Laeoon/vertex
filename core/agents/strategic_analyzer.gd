class_name StrategicAnalyzer extends RefCounted

## Motor de Análisis Estratégico.
## Implementa el algoritmo de Edmonds-Karp (Ford-Fulkerson con BFS)
## para calcular el FLUJO MÁXIMO entre dos nodos y, derivado de este,
## el CORTE MÍNIMO (conjunto de aristas a parchear para aislar el activo
## crítico del atacante al menor coste).
##
## - Lee EXCLUSIVAMENTE mitigation_capacity del grafo (ignora transit_cost).
## - Salida: Dictionary con max_flow, cut_edges, reachable_S, isolated_T.
## - cut_edges viene ORDENADO por capacidad ASC (parcheo más barato primero).
## - Stateless: cada llamada es independiente.
##
## Teorema Max-Flow Min-Cut: el valor del flujo máximo ES IGUAL al valor
## del corte mínimo. El sandbox D valida esta igualdad con assert().
##
## Complejidad: O(V · E²) garantizada.
##
## Uso:
##   var r: Dictionary = StrategicAnalyzer.find_min_cut(graph, &"Atacante", &"Base_de_Datos")
##   print("Flujo máximo: ", r["max_flow"])
##   print("Aristas a parchear: ", r["cut_edges"])
##   for edge in r["cut_edges"]:
##       print("  Bloquear: ", edge["from_id"], " → ", edge["to_id"], " (cap ", edge["capacity"], ")")


## ─── API PÚBLICA ──────────────────────────────────────────────────────

## Encuentra el flujo máximo y el corte mínimo entre source y sink.
## Devuelve un Dictionary con cuatro campos:
##   max_flow      → float              (valor del flujo máximo)
##   cut_edges     → Array[Dictionary]  (aristas a parchear, ASC por capacidad)
##   reachable_S   → Array[StringName]  (nodos alcanzables desde source en residual)
##   isolated_T    → Array[StringName]  (complemento, aislados del source)
static func find_min_cut(
	graph: NetworkGraphResource,
	source: StringName,
	sink: StringName
) -> Dictionary:
	# ── Validaciones defensivas ──
	if graph == null or graph.nodes.is_empty():
		push_warning("StrategicAnalyzer: grafo nulo o vacío")
		return _empty_result()
	if graph.get_node_by_id(source) == null:
		push_warning("StrategicAnalyzer: source '%s' no existe" % source)
		return _empty_result()
	if graph.get_node_by_id(sink) == null:
		push_warning("StrategicAnalyzer: sink '%s' no existe" % sink)
		return _empty_result()
	if source == sink:
		push_warning("StrategicAnalyzer: source == sink")
		return _empty_result()

	# ── Construir grafo residual ──
	# residual[u][v] = capacidad residual de la arista u→v
	# (capacidad original - flujo enviado). Empieza igual a la capacidad.
	var residual: Dictionary = _build_residual(graph)

	# ── Edmonds-Karp: BFS + augmenting path ──
	var max_flow: float = 0.0
	var safety_iter: int = (graph.nodes.size() + 1) * (graph.edges.size() + 1) + 10
	while safety_iter > 0:
		var parent: Dictionary = _bfs(residual, source, sink)
		if parent.is_empty():
			break  # No hay más caminos aumentantes

		# Encontrar el cuello de botella del camino
		var bottleneck: float = INF
		var v: StringName = sink
		var safety_path: int = graph.nodes.size() + 1
		while v != source and safety_path > 0:
			var u: StringName = parent.get(v, &"")
			if u == &"":
				break
			var cap: float = residual[u][v]
			if cap < bottleneck:
				bottleneck = cap
			v = u
			safety_path -= 1

		if bottleneck == INF or bottleneck <= 0.0:
			break

		# Actualizar grafo residual
		v = sink
		safety_path = graph.nodes.size() + 1
		while v != source and safety_path > 0:
			var u: StringName = parent.get(v, &"")
			if u == &"":
				break
			residual[u][v] -= bottleneck
			if not residual[v].has(u):
				residual[v][u] = 0.0
			residual[v][u] += bottleneck
			v = u
			safety_path -= 1

		max_flow += bottleneck
		safety_iter -= 1

	# ── BFS final en el residual para encontrar el set S ──
	# S = nodos alcanzables desde source. T = complemento.
	var reachable: Dictionary = _bfs_reachable(residual, source)

	var set_s: Array[StringName] = []
	var set_t: Array[StringName] = []
	for n in graph.nodes:
		if n == null:
			continue
		if reachable.get(n.id, false):
			set_s.append(n.id)
		else:
			set_t.append(n.id)

	# ── Corte mínimo: aristas ORIGINALES de S hacia T ──
	# Usamos la arista original (no la residual) para reportar la capacidad
	# real que habría que parchear.
	var cut_edges: Array[Dictionary] = []
	for e in graph.edges:
		if e == null:
			continue
		if reachable.get(e.from_id, false) and not reachable.get(e.to_id, false):
			cut_edges.append({
				"from_id": e.from_id,
				"to_id": e.to_id,
				"capacity": e.mitigation_capacity,
				"protocol": e.protocol,
			})

	# Ordenar ASC por capacidad: lo más barato de bloquear primero
	cut_edges.sort_custom(_compare_by_capacity_asc)

	return {
		"max_flow": max_flow,
		"cut_edges": cut_edges,
		"reachable_S": set_s,
		"isolated_T": set_t,
	}


# ─── OPERACIONES INTERNAS ────────────────────────────────────────────

## Construye el grafo residual inicial a partir de mitigation_capacity.
## residual[u][v] = mitigation_capacity(u, v)  (forward)
## residual[v][u] = 0                            (backward, se irá creando)
static func _build_residual(graph: NetworkGraphResource) -> Dictionary:
	var residual: Dictionary = {}
	for n in graph.nodes:
		if n == null:
			continue
		if not residual.has(n.id):
			residual[n.id] = {}
	for e in graph.edges:
		if e == null:
			continue
		if not residual.has(e.from_id):
			residual[e.from_id] = {}
		if not residual.has(e.to_id):
			residual[e.to_id] = {}
		if not residual[e.from_id].has(e.to_id):
			residual[e.from_id][e.to_id] = 0.0
		residual[e.from_id][e.to_id] += e.mitigation_capacity
		# La inversa empieza en 0; se irá sumando al enviar flujo
		if not residual[e.to_id].has(e.from_id):
			residual[e.to_id][e.from_id] = 0.0
	return residual


## BFS desde source. Devuelve el dict `parent` (child → parent) si
## alcanza sink, o {} si no lo alcanza.
static func _bfs(
	residual: Dictionary,
	source: StringName,
	sink: StringName
) -> Dictionary:
	var visited: Dictionary = {source: true}
	var parent: Dictionary = {}
	var queue: Array[StringName] = [source]
	while not queue.is_empty():
		var u: StringName = queue.pop_front()
		if not residual.has(u):
			continue
		for v in residual[u].keys():
			if visited.get(v, false):
				continue
			if residual[u][v] <= 0.0:
				continue
			visited[v] = true
			parent[v] = u
			if v == sink:
				return parent
			queue.append(v)
	return {}  # Sink no alcanzable


## BFS sin objetivo: devuelve todos los nodos alcanzables.
static func _bfs_reachable(residual: Dictionary, source: StringName) -> Dictionary:
	var visited: Dictionary = {source: true}
	var queue: Array[StringName] = [source]
	while not queue.is_empty():
		var u: StringName = queue.pop_front()
		if not residual.has(u):
			continue
		for v in residual[u].keys():
			if visited.get(v, false):
				continue
			if residual[u][v] <= 0.0:
				continue
			visited[v] = true
			queue.append(v)
	return visited


## Comparador para sort_custom: ASC por capacidad.
static func _compare_by_capacity_asc(a: Dictionary, b: Dictionary) -> bool:
	return a["capacity"] < b["capacity"]


## Resultado vacío en caso de error.
static func _empty_result() -> Dictionary:
	return {
		"max_flow": 0.0,
		"cut_edges": [],
		"reachable_S": [],
		"isolated_T": [],
	}
