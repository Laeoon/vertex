extends Node

## Pruebas del Event Bus (core/autoloads/events.gd).
##
## Events es un Node de señales tipadas sin dependencias, así que se
## instancia una copia local (preload + add_child) y corre vía `--script`
## sin depender del autoload registrado.

const EventsScript = preload("res://core/autoloads/events.gd")

var passed: int = 0
var failed: int = 0

var _bus: Node


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_bus = Node.new()
	_bus.set_script(EventsScript)
	add_child(_bus)

	for señal in ["node_state_changed", "threat_detected", "path_calculated", "min_cut_identified"]:
		_afirmar(_bus.has_signal(señal), "declara la señal %s" % señal)

	var recibido: Array = []
	_bus.node_state_changed.connect(func(id, old, new): recibido.append([id, old, new]))
	_bus.threat_detected.connect(func(id, nivel): recibido.append([id, nivel]))

	_bus.node_state_changed.emit(&"Router", 0, 2)
	_afirmar(recibido.size() == 1 and recibido[0] == [&"Router", 0, 2],
		"node_state_changed entrega (id, estado_viejo, estado_nuevo) al suscriptor")

	_bus.threat_detected.emit(&"FW", 0.75)
	_afirmar(recibido.size() == 2 and recibido[1] == [&"FW", 0.75],
		"threat_detected entrega (id, threat_level) al suscriptor")

	var caminos: Array = []
	_bus.path_calculated.connect(func(src, dst, path, cost): caminos.append([src, dst, path, cost]))
	_bus.path_calculated.emit(&"A", &"B", [&"A", &"X", &"B"], 4.5)
	_afirmar(caminos.size() == 1 and caminos[0][2] == [&"A", &"X", &"B"] and caminos[0][3] == 4.5,
		"path_calculated propaga el camino y el coste intactos")

	var cortes: Array = []
	_bus.min_cut_identified.connect(func(s, t, flow, edges): cortes.append(flow))
	_bus.min_cut_identified.emit(&"S", &"T", 6.0, [])
	_afirmar(cortes == [6.0],
		"min_cut_identified propaga max_flow y cut_edges")

	# Dos suscriptores al mismo evento reciben ambos (patrón observer).
	# Nota: las lambdas capturan primitivas por valor, se usa un Array
	# (referencia) como acumulador compartido.
	var hits: Array = []
	_bus.threat_detected.connect(func(_id, _n): hits.append("a"))
	_bus.threat_detected.connect(func(_id, _n): hits.append("b"))
	_bus.threat_detected.emit(&"N", 0.1)
	_afirmar(hits.has("a") and hits.has("b") and hits.size() == 2,
		"múltiples suscriptores del mismo evento reciben todos")

	_finalizar()


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _finalizar() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
