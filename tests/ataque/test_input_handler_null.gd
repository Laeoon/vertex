extends Node

## Prueba: InputHandler._pathfind_to con grafo/runtime inválido.
##
## Verifica la tarea 1.1 (fase-0/slice-1): un InputHandler cuya referencia
## `game` es null (o cuyo game.graph/game.runtime no son instancias válidas)
## debe devolver [] y registrarse vía push_error SIN provocar un crash.
##
## Nota: no capturamos el push_error emitido por el motor (no hay API
## trivial en Godot 4.7 headless); el contrato que afirmamos es:
##   (a) el método devuelve un Array vacío,
##   (b) el proceso no cae (llega a _finalizar con exit 0).
## La emisión del push_error se confirma por inspección de código y por la
## traza de errores en una corrida manual con --headless.

const InputHandler = preload("res://juego/ataque/input_handler.gd")

var passed: int = 0
var failed: int = 0
var _handler: InputHandler


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# Caso 1: game == null → [] y no crash
	_handler = InputHandler.new()
	add_child(_handler)
	_handler.game = null  # explícito (ya es null por defecto)
	var ruta_null: Array[StringName] = _handler._pathfind_to(&"A", &"B")
	_afirmar(ruta_null.is_empty(), "game==null → _pathfind_to devuelve []")

	# Caso 2: game apunta a un Node nuevo sin `graph` ni `runtime` cableados → []
	# (is_instance_valid(game) es true, pero game.graph/game.runtime evalúan a
	# null → el guard debe disparar y devolver [])
	var falso_game: Node = _FalsoGame.new()
	_handler.game = falso_game
	var ruta_sin_graph: Array[StringName] = _handler._pathfind_to(&"A", &"B")
	_afirmar(ruta_sin_graph.is_empty(), "game sin graph/runtime → _pathfind_to devuelve []")
	if is_instance_valid(falso_game):
		falso_game.queue_free()

	# Caso 3: referencias válidas (graph+runtime reales) no implementado aquí
	# porque requiere construir un NetworkGraphResource/NetworkRuntime — cubierto
	# en slice 2 por tests/core/test_defensive_pathfinder.gd.
	_finalizar()


class _FalsoGame extends Node:
	## Nodo degenerado que simula un `game` sin grafo/runtime cableados.
	## Tiene los miembros para que game.graph/game.runtime evalúen a null en
	## lugar de error de propiedad-inexistente (más realista que un Node puro).
	## Extiende Node porque InputHandler.game está tipado como `Node`.
	var graph = null
	var runtime = null


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _finalizar() -> void:
	if _handler != null and is_instance_valid(_handler):
		_handler.queue_free()
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)