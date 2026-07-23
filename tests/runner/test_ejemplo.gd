extends Node

## Prueba de ejemplo para el runner de VERTEX.
##
## Demuestra la convención para escribir pruebas ad-hoc bajo `tests/` y sirve
## de plantilla para nuevas pruebas. El runner la descubre automáticamente
## (comienza con `test_`) y la ejecuta aislada en un Godot headless.
##
## Convención de nombres en `tests/`:
##   - `test_*.gd`  → archivo de prueba, descubierto y ejecutado por el runner.
##   - `_*.gd`      → archivo auxiliar (helpers, builders, fixtures);
##                    NO ejecutado por el runner. Ej: `_graph_builder.gd`.
##   - `run_all.gd` → el propio runner; se excluye de su propio descubrimiento.
##
## Estructura típica de una prueba:
##   1. `extends Node` (NO `SceneTree`; el runner ya es el SceneTree padre).
##   2. Contadores `var passed: int` y `var failed: int`.
##   3. `_ready()` → `call_deferred("_run_tests")`.
##   4. `_run_tests()` ejecuta los asserts. Para cada uno, llama a un helper
##      tipo `_afirmar(condición, "mensaje")` que imprime `PASS: ...` o
##      `FAIL: ...` y lleva los contadores.
##   5. Termina con `_finalizar()` → `get_tree().quit(0 si todo OK else 1)`.
##
## Se prefiere `call_deferred` para que el SceneTree termine de inicializarse
## antes de ejecutar la lógica; los `await get_tree().process_frame` permiten
## que los nodos hijos (escena de juego instanciada) procesen un fotograma.

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_afirmar(2 + 2 == 4, "suma básica 2 + 2 = 4")
	_afirmar("hola".length() == 4, "largo de la cadena 'hola' es 4")
	_afirmar([1, 2, 3].size() == 3, "el arreglo [1, 2, 3] tiene 3 elementos")
	_afirmar([].is_empty(), "un arreglo vacío retorna true en is_empty()")
	_afirmar(not false, "negación de false es true")
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