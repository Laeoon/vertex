class_name ReactiveAnalyzer extends RefCounted

## Wrapper reactivo del StrategicAnalyzer.
##
## Se suscribe automaticamente a `Events.node_state_changed` y, cuando
## un nodo entra en CAPTURADO (`new_state == 2`), corre el analisis
## de corte minimo entre un nodo "atacante" y un nodo "activo critico".
## Si encuentra un corte no vacio, emite `Events.min_cut_identified`.
##
## Por que solo en CAPTURADO: el corte minimo tiene sentido cuando un
## activo ya esta comprometido y queremos planificar la respuesta
## (parchear aristas). En ALERTADO es muy pronto, en DISPONIBLE no
## hay amenaza.
##
## Uso:
##   var ra := ReactiveAnalyzer.new(graph, &"Atacante", &"Base_de_Datos")
##   # listo. Cuando un nodo entre en CAPTURADO, ra calcula y emite.
##
## Limpieza (opcional):
##   ra.cleanup()

const CAPTURADO_STATE: int = 2

const _EventSubscriber = preload("res://core/integration/event_subscriber.gd")
const _StrategicAnalyzer = preload("res://core/agents/strategic_analyzer.gd")

var _graph: NetworkGraphResource
var _attacker: StringName
var _target: StringName
var _state_callback: Callable


func _init(
	graph: NetworkGraphResource,
	attacker: StringName,
	target: StringName
) -> void:
	assert(graph != null, "ReactiveAnalyzer: graph nulo")
	_graph = graph
	_attacker = attacker
	_target = target
	_state_callback = _EventSubscriber.subscribe(
		self, &"node_state_changed", &"_on_node_state_changed"
	)


## Desconecta del bus. Idempotente.
func cleanup() -> void:
	_EventSubscriber.unsubscribe(&"node_state_changed", _state_callback)


## Callback invocado por el bus ante cualquier cambio de estado.
## Filtra por CAPTURADO y corre el analisis.
func _on_node_state_changed(
	node_id: StringName,
	old_state: int,
	new_state: int
) -> void:
	if new_state != CAPTURADO_STATE:
		return

	# Validaciones defensivas (replican las de StrategicAnalyzer)
	if _graph.get_node_by_id(_attacker) == null:
		push_warning(
			"ReactiveAnalyzer: attacker '%s' no existe en el grafo" % _attacker
		)
		return
	if _graph.get_node_by_id(_target) == null:
		push_warning(
			"ReactiveAnalyzer: target '%s' no existe en el grafo" % _target
		)
		return
	if _attacker == _target:
		return  # caso degenerado, no hay corte posible

	var result: Dictionary = _StrategicAnalyzer.find_min_cut(
		_graph, _attacker, _target
	)
	var cut_edges: Array = result["cut_edges"]
	if cut_edges.is_empty():
		# Si max_flow == 0 el activo ya esta aislado. No emitimos senal
		# para no confundir a los suscriptores.
		return

	var max_flow: float = result["max_flow"]
	Events.min_cut_identified.emit(_attacker, _target, max_flow, cut_edges)
