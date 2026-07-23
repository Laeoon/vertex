class_name ReactivePathfinder extends RefCounted

## Wrapper reactivo del DefensivePathfinder.
##
## Se suscribe automaticamente a `Events.threat_detected` y, cuando
## detecta una amenaza en un nodo, calcula el camino desde un nodo
## "respondedor" hasta el nodo amenazado usando `DefensivePathfinder`.
## Si el camino existe, emite `Events.path_calculated`.
##
## Patron: el agente existe como instancia viva en memoria y reacciona
## a eventos. Es independiente de la FSM (no la modifica) y del UI
## (no sabe quien escucha sus emisiones).
##
## Uso:
##   var rp := ReactivePathfinder.new(graph, &"Agente")
##   # listo. Cuando alguien emita threat_detected(&"Servidor_Web", 0.8),
##   # rp calcula el camino Agente -> Servidor_Web y emite path_calculated.
##
## Limpieza (opcional, RefCounted libera al agente):
##   rp.cleanup()
##
## Por que una clase wrapper y no modificar DefensivePathfinder:
##   - DefensivePathfinder es una pieza estatica y pura (Hito 2). Agregarle
##     estado mutable rompe su contrato.
##   - Los sandboxes C y D siguen llamando a los metodos estaticos.
##   - El wrapper es la unica pieza que gana dependencias del bus.

const _EventSubscriber = preload("res://core/integration/event_subscriber.gd")

var _graph: NetworkGraphResource
var _responder: StringName
var _threat_callback: Callable


func _init(graph: NetworkGraphResource, responder: StringName) -> void:
	assert(graph != null, "ReactivePathfinder: graph nulo")
	_graph = graph
	_responder = responder
	_threat_callback = _EventSubscriber.subscribe(
		self, &"threat_detected", &"_on_threat_detected"
	)


## Desconecta del bus. Idempotente.
func cleanup() -> void:
	_EventSubscriber.unsubscribe(&"threat_detected", _threat_callback)


## Callback invocado por el bus cuando un nodo entra en ALERTADO.
## Calcula el camino responder -> node_id y, si existe, lo emite.
func _on_threat_detected(node_id: StringName, threat_level: float) -> void:
	# Si el nodo amenazado no esta en el grafo, no hacemos nada.
	if _graph.get_node_by_id(node_id) == null:
		push_warning(
			"ReactivePathfinder: nodo amenazado '%s' no existe en el grafo" % node_id
		)
		return

	# Caso degenerado: el respondedor ES el nodo amenazado (sin camino que
	# calcular). Evitamos la llamada a Dijkstra y emitimos un path de un
	# solo nodo con coste 0.
	if node_id == _responder:
		var trivial_path: Array[StringName] = [_responder]
		Events.path_calculated.emit(_responder, node_id, trivial_path, 0.0)
		return

	var result: Dictionary = DefensivePathfinder.find_path_with_cost(
		_graph, _responder, node_id
	)
	if not result["reachable"]:
		# Nodo inalcanzable: no emitimos (los suscriptores pueden inferir
		# la no-respuesta como senal de alarma por si mismos).
		return

	var path: Array[StringName] = result["path"]
	var cost: float = result["cost"]
	Events.path_calculated.emit(_responder, node_id, path, cost)
