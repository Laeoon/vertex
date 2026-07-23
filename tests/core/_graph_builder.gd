extends RefCounted

## Constructor de grafos inline para las pruebas de los algoritmos core
## (`DefensivePathfinder`, `StrategicAnalyzer`, `MinHeap`).
##
## Permite armar un `NetworkGraphResource` íntegramente en código —sin tocar
## archivos `.tres`— con helpers legibles orientados a escenarios de test:
##
##   - `chain([a, b, c])`     → grafo dirigido a→b→c con costos por defecto.
##   - `isolated(a)`           → un único nodo, sin aristas.
##   - `empty()`               → grafo vacío (nodos=[] aristas=[]).
##   - `weighted([[a,b,tc,mc], ...])` → aristas con pesos explícitos.
##   - `grid(n)`               → mallado n×n dirigido (derecha y abajo).
##   - `bidir(specs)`          → cada arista se añade en ambos sentidos.
##   - `build(ids, edges)`     → composición a bajo nivel.
##
## Todos los ids aceptan String o StringName; se normalizan a StringName porque
## los algoritmos indexan internamente con `StringName` (igualdad y hash estables).
##
## Pesos por defecto:
##   transit_cost        = 1.0  (consumido por Dijkstra).
##   mitigation_capacity = 1.0  (consumido por Edmonds-Karp).
##   protocol            = "TCP".
##
## Empezamos con `_` para que el runner (`run_all.gd`) NO lo descubra: es un
## auxiliar, no una prueba.

const _TRANSIT_COST_DEFAULT := 1.0
const _MITIGATION_CAPACITY_DEFAULT := 1.0
const _PROTOCOL_DEFAULT := &"TCP"


## Constructor base: dado un array de ids y un array de specs de aristas,
## monta el `NetworkGraphResource`. Cada spec es un Dictionary con claves
## `from`, `to` y opcionalmente `transit_cost`, `mitigation_capacity`,
## `protocol`. Los ids faltantes se crean automáticamente.
static func build(ids: Array, edges: Array = []) -> NetworkGraphResource:
	var graph := NetworkGraphResource.new()
	var vistos: Dictionary = {}
	for id in ids:
		var sid := _norm(id)
		if vistos.has(sid):
			continue
		vistos[sid] = true
		graph.nodes.append(_nodo(sid))
	for spec in edges:
		var arista := _arista(spec)
		_asegurar_nodo(graph, vistos, arista.from_id)
		_asegurar_nodo(graph, vistos, arista.to_id)
		graph.edges.append(arista)
	return graph


## Cadena dirigida a→b→c→… con costos por defecto (transit_cost=1,
## mitigation_capacity=1). Útil para validar caminos secuenciales.
static func chain(ids: Array) -> NetworkGraphResource:
	var edges: Array = []
	for i in range(ids.size() - 1):
		edges.append({"from": ids[i], "to": ids[i + 1]})
	return build(ids, edges)


## Cadena bidireccional a↔b↔c↔… ; cada arista se añade en ambos sentidos.
## Útil cuando la prueba necesita camino en cualquier dirección.
static func chain_bidir(ids: Array) -> NetworkGraphResource:
	var edges: Array = []
	for i in range(ids.size() - 1):
		edges.append({"from": ids[i], "to": ids[i + 1]})
		edges.append({"from": ids[i + 1], "to": ids[i]})
	return build(ids, edges)


## Grafo con un único nodo aislado (sin aristas).
static func isolated(id) -> NetworkGraphResource:
	return build([id])


## Grafo vacío (nodos=[] aristas=[]). Sirve para cubrir la rama de guard de
## los algoritmos ("grafo nulo o vacío").
static func empty() -> NetworkGraphResource:
	return NetworkGraphResource.new()


## Aristas ponderadas explícitas. Cada entrada de `specs` es un array
## `[from, to, transit_cost]` o `[from, to, transit_cost, mitigation_capacity]`.
## Los ids se recolectan automáticamente; los nodos repetidos se deduplican.
static func weighted(specs: Array) -> NetworkGraphResource:
	var ids: Array = []
	var vistos: Dictionary = {}
	var edges: Array = []
	for s in specs:
		var from_id := _norm(s[0])
		var to_id := _norm(s[1])
		var tc: float = float(s[2])
		var mc: float = float(s[3]) if s.size() > 3 else _MITIGATION_CAPACITY_DEFAULT
		if not vistos.has(from_id):
			vistos[from_id] = true
			ids.append(from_id)
		if not vistos.has(to_id):
			vistos[to_id] = true
			ids.append(to_id)
		edges.append({
			"from": from_id,
			"to": to_id,
			"transit_cost": tc,
			"mitigation_capacity": mc,
		})
	return build(ids, edges)


## Mallado cuadrado n×n dirigido (sólo hacia la derecha y hacia abajo),
## con `transit_cost` uniforme. La distancia Manhattan del origen (0,0) al
## destino (n-1,n-1) es exactamente `2*(n-1)` saltos — útil para validar
## costos y alcance en un grafo más grande.
static func grid(n: int, transit_cost: float = _TRANSIT_COST_DEFAULT) -> NetworkGraphResource:
	var ids: Array = []
	var edges: Array = []
	for r in range(n):
		for c in range(n):
			ids.append(&"n%d_%d" % [r, c])
	for r in range(n):
		for c in range(n):
			if c + 1 < n:
				edges.append({
					"from": &"n%d_%d" % [r, c],
					"to": &"n%d_%d" % [r, c + 1],
					"transit_cost": transit_cost,
				})
			if r + 1 < n:
				edges.append({
					"from": &"n%d_%d" % [r, c],
					"to": &"n%d_%d" % [r + 1, c],
					"transit_cost": transit_cost,
				})
	return build(ids, edges)


# ─── Internos ──────────────────────────────────────────────────────────

static func _nodo(id: StringName) -> NetworkNodeResource:
	var n := NetworkNodeResource.new()
	n.id = id
	n.display_name = String(id)
	n.initial_state = &"disponible"
	return n


static func _arista(spec: Dictionary) -> NetworkEdgeResource:
	var e := NetworkEdgeResource.new()
	e.from_id = _norm(spec["from"])
	e.to_id = _norm(spec["to"])
	e.transit_cost = float(spec.get("transit_cost", _TRANSIT_COST_DEFAULT))
	e.mitigation_capacity = float(spec.get("mitigation_capacity", _MITIGATION_CAPACITY_DEFAULT))
	e.protocol = spec.get("protocol", _PROTOCOL_DEFAULT)
	return e


static func _asegurar_nodo(
		graph: NetworkGraphResource,
		vistos: Dictionary,
		id: StringName
) -> void:
	if vistos.has(id):
		return
	vistos[id] = true
	graph.nodes.append(_nodo(id))


static func _norm(id) -> StringName:
	if id is StringName:
		return id
	return StringName(id)