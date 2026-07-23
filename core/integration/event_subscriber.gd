class_name EventSubscriber extends RefCounted

## Utilidad para conectar y desconectar agentes al Event Bus de forma tipada.
##
## Centraliza la logica de subscripcion en un solo lugar. Esto permite:
##   - agregar logging/metricas/retry en un solo punto
##   - validar que la senal existe antes de conectar
##   - documentar el patron de uso de forma canonica
##
## Uso desde un agente reactivo:
##
##   class_name ReactivePathfinder extends RefCounted
##
##   func _init(graph, responder) -> void:
##       _graph = graph
##       _responder = responder
##       EventSubscriber.subscribe(self, &"threat_detected", &"_on_threat_detected")
##
##   func _on_threat_detected(node_id: StringName, threat_level: float) -> void:
##       # ...
##       pass
##
## Para desconectar (opcional, RefCounted libera al agente):
##
##   EventSubscriber.unsubscribe(&"threat_detected", _threat_callback)
##
##   var _threat_callback: Callable = Callable(self, &"_on_threat_detected")


## Conecta `target.method_name` al senal `signal_name` del Event Bus.
## Devuelve el Callable resultante para que el caller pueda guardarlo
## y desconectar despues.
static func subscribe(
	target: Object,
	signal_name: StringName,
	method_name: StringName
) -> Callable:
	var callable: Callable = Callable(target, method_name)
	if Events.is_connected(signal_name, callable):
		return callable
	Events.connect(signal_name, callable)
	return callable


## Desconecta un Callable del Event Bus. Es seguro llamarlo aunque no
## estuviera conectado (no lanza error).
static func unsubscribe(signal_name: StringName, callable: Callable) -> void:
	if not callable.is_valid():
		return
	if Events.is_connected(signal_name, callable):
		Events.disconnect(signal_name, callable)
