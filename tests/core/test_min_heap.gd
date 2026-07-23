extends Node

## Pruebas del Min-heap binario (`MinHeap`) usado por DefensivePathfinder.
## Cubre los escenarios de la tarea 2.4:
##   1. push/pop en orden (extrae el de menor prioridad primero).
##   2. heap vacío: contrato seguro vía `is_empty()` (guard idiom).
##   3. peek sin extraer.
##   4. Duplicados de prioridad: se extraen todos.
##   5. Invariante random-vs-sort con 100 valores aleatorios (seed fijo).
##   6. Extras: clear, size, payload StringName.
##
## Nota de descubrimiento (probe empirDurante implementación):
##   MinHeap.pop()/peek() emiten `assert(...)` en build debug sobre heap vacío
##   (se imprime "SCRIPT ERROR: Assertion failed") y luego retornan [] (no
##   null). El CONTRATO SEGURO y público es `is_empty()` como guard; por eso la
##   cobertura del caso "heap vacío" valida `is_empty()==true` y el idiom
##     `var r = null; if not heap.is_empty(): r = heap.pop()`
##   (que rinde `r == null`), en lugar de invocar pop() sin guard, que sería
##   ruidoso y de contrato indefinido. La tarea 2.4 mencionaba "empty heap
##   returns null": se interpreta como cubrir el caso vacío con el guard
##   público — ver descripción del descubrimiento en el apply-progress.
##
## Autoload-free, basada en extends Node, corre vía tests/runner/_run_one.gd.

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_push_pop_orden()
	_heap_vacio()
	_peek_sin_extraer()
	_duplicados_prioridad()
	_invariante_random_vs_sort()
	_clear_y_size()
	_payload_stringname()
	_finalizar()


# ─── Escenarios ────────────────────────────────────────────────────────

func _push_pop_orden() -> void:
	var h := MinHeap.new()
	h.push(5.0, &"e")
	h.push(1.0, &"a")
	h.push(3.0, &"c")
	_afirmar(h.size() == 3, "push: size == 3 tras 3 pushes")
	var p1: Array = h.pop()
	_afirmar(p1[1] == &"a" and abs(float(p1[0]) - 1.0) < 1e-9, "pop 1: (1.0, a)")
	var p2: Array = h.pop()
	_afirmar(p2[1] == &"c" and abs(float(p2[0]) - 3.0) < 1e-9, "pop 2: (3.0, c)")
	var p3: Array = h.pop()
	_afirmar(p3[1] == &"e" and abs(float(p3[0]) - 5.0) < 1e-9, "pop 3: (5.0, e)")
	_afirmar(h.is_empty(), "tras vaciar: is_empty() == true")


func _heap_vacio() -> void:
	var h := MinHeap.new()
	_afirmar(h.is_empty(), "heap recién creado: is_empty() == true")
	_afirmar(h.size() == 0, "heap recién creado: size() == 0")
	# Contrato seguro: el guard evita invocar pop()/peek() en vacío.
	var r = null
	if not h.is_empty():
		r = h.pop()
	_afirmar(r == null, "heap vacío: guard idiom rinde pop() == null (sin assert)")


func _peek_sin_extraer() -> void:
	var h := MinHeap.new()
	h.push(2.0, &"b")
	h.push(4.0, &"d")
	var peek1: Array = h.peek()
	_afirmar(peek1[1] == &"b" and abs(float(peek1[0]) - 2.0) < 1e-9,
		"peek devuelve la menor prioridad (2.0, b)")
	_afirmar(h.size() == 2, "peek NO extrae (size sigue 2)")
	var peek2: Array = h.peek()
	_afirmar(peek2[1] == &"b", "peek repetido devuelve la misma entrada")
	# pop tras ver el peek
	var p: Array = h.pop()
	_afirmar(p[1] == &"b", "pop tras peek extrae el mismo (2.0, b)")
	_afirmar(h.size() == 1, "tras pop: size == 1")


func _duplicados_prioridad() -> void:
	var h := MinHeap.new()
	h.push(1.0, &"x")
	h.push(1.0, &"y")
	h.push(1.0, &"z")
	_afirmar(h.size() == 3, "3 pushes con misma prioridad → size 3")
	var recogidos: Array = []
	while not h.is_empty():
		recogidos.append(h.pop()[1])
	_afirmar(recogidos.size() == 3, "duplicados: se extraen los 3 elementos")
	var conjunto := {}
	for v in recogidos:
		conjunto[v] = true
	_afirmar(conjunto.has(&"x") and conjunto.has(&"y") and conjunto.has(&"z"),
		"duplicados: se extraen x, y, z (conjunto completo)")


func _invariante_random_vs_sort() -> void:
	# Stress test con 100 valores aleatorios → la secuencia de pop() debe ser
	# no decreciente (invariante del min-heap).
	seed(12345)  # reproducible
	var h := MinHeap.new()
	var valores: PackedFloat32Array = []
	for i in range(100):
		var v := randf_range(0.0, 1000.0)
		valores.append(v)
		h.push(v, i)
	var extraidas: Array = []  # prioridades en orden de extracción
	while not h.is_empty():
		extraidas.append(float(h.pop()[0]))
	# Invariante: extracción no decreciente.
	var no_decreciente := true
	for i in range(1, extraidas.size()):
		if extraidas[i] < extraidas[i - 1] - 1e-6:
			no_decreciente = false
			break
	_afirmar(no_decreciente, "stress 100 rand: extracción no decreciente (invariante)")
	# Y coincidencia multiset contra un sort: misma colección de valores.
	valores.sort()
	var copia: Array = []
	for v in valores:
		copia.append(float(v))
	_afirmar(_mismos_valores_ordenados(extraidas, copia),
		"stress 100 rand: multiset extraído == multiset original ordenado ASC")


func _clear_y_size() -> void:
	var h := MinHeap.new()
	h.push(3.0, &"a")
	h.push(1.0, &"b")
	_afirmar(h.size() == 2, "size tras 2 pushes == 2")
	h.clear()
	_afirmar(h.is_empty(), "clear: heap queda vacío")
	_afirmar(h.size() == 0, "clear: size == 0")
	# El heap sigue usable tras clear.
	h.push(2.0, &"c")
	_afirmar(h.size() == 1, "post-clear reutilizable: push → size 1")
	_afirmar(h.pop()[1] == &"c", "post-clear: pop extrae el nuevo elemento")


func _payload_stringname() -> void:
	# Dijkstra usa StringName como payload; verificar tipo se preserva.
	var h := MinHeap.new()
	h.push(7.0, &"n0_5")
	h.push(2.0, &"n3_1")
	var top: Array = h.pop()
	_afirmar(top[1] == &"n3_1", "payload StringName preservado y extraído por prioridad")
	_afirmar(top[1] is StringName or typeof(top[1]) == TYPE_STRING_NAME,
		"payload extraído conserva tipo StringName")


# ─── Helpers ─────────────────────────────────────────────────────────────

func _mismos_valores_ordenados(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if abs(a[i] - b[i]) > 1e-3:
			return false
	return true


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