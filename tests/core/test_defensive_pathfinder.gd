extends Node

## Pruebas del algoritmo Dijkstra (`DefensivePathfinder`) sobre NetworkGraphResource.
##
## Cubre los escenarios de la tarea 2.2:
##   1. Camino más corto en cadena A→B→C.
##   2. Objetivo inalcanzable (segmentación de red) → [].
##   3. Corrección del coste acumulado.
##   4. Desempate entre caminos de igual coste (diamante A→{B,D}→C).
##   5. Mallado grande 10×10: distancia Manhattan exacta y alcanzabilidad.
##   6. Casos triviales/de frontera: origen==destino, grafo vacío, nodos
##      inexistentes, equivalencia find_path ↔ find_path_with_cost.
##
## Mapeo de escenarios → ramas de core/agents/defensive_pathfinder.gd
## (inspección visual de cobertura, no hay tooling de line-coverage GDScript):
##   -validaciones entrada  : líneas 80–88 (graph vacío, start/target inexistentes)
##   -trivial start==target : líneas 91–95
##   -init distancias/heap   : líneas 106–115
##   -relajación + early break: líneas 118–150
##   -INF safety break       : línea 126 (objetivo inalcanzable)
##   -target break           : línea 135 (caso normal)
##   -reconstrucción/éxito    : líneas 158–176
##   -inalcanzable final     : líneas 153–156
## Quedan fuera (defensivos no disparables con datos válidos): el sanity de
## reconstrucción inconsistente (líneas 169–171) — se documenta como no cubierto.
##
## Autoload-free y basada en `extends Node` (corre vía tests/runner/_run_one.gd).

const GraphBuilder = preload("res://tests/core/_graph_builder.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_camino_cadena_abc()
	_inalcanzable()
	_coste_acumulado()
	_desempate_diamante()
	_mallado_grande()
	_origen_igual_destino()
	_grafo_vacio()
	_nodos_inexistentes()
	_equivalencia_find_path_with_cost()
	_finalizar()


# ─── Escenarios ────────────────────────────────────────────────────────

func _camino_cadena_abc() -> void:
	var g := GraphBuilder.chain([&"A", &"B", &"C"])
	var path: Array = DefensivePathfinder.find_path(g, &"A", &"C")
	_afirmar(path.size() == 3, "cadena A→B→C: 3 nodos")
	_afirmar(path[0] == &"A" and path[1] == &"B" and path[2] == &"C",
		"cadena A→B→C: secuencia exacta A,B,C")


func _inalcanzable() -> void:
	# A→B pero C está aislado: Dijkstra no puede alcanzar C desde A.
	var g := GraphBuilder.build([&"A", &"B", &"C"], [{"from": &"A", "to": &"B"}])
	var path: Array = DefensivePathfinder.find_path(g, &"A", &"C")
	_afirmar(path.is_empty(), "objetivo inalcanzable → [] (red segmentada)")


func _coste_acumulado() -> void:
	var g := GraphBuilder.weighted([[&"A", &"B", 5.0], [&"B", &"C", 3.0]])
	var r := DefensivePathfinder.find_path_with_cost(g, &"A", &"C")
	_afirmar(r.reachable == true, "camino A→B→C alcanzable")
	_afirmar(abs(float(r.cost) - 8.0) < 1e-6, "coste A→C = 5 + 3 = 8.0")
	_afirmar(r.path.size() == 3, "camino A→B→C tiene 3 nodos")


func _desempate_diamante() -> void:
	# Dos caminos de igual coste 2: A→B→C y A→D→C.
	var g := GraphBuilder.weighted([
		[&"A", &"B", 1.0], [&"A", &"D", 1.0],
		[&"B", &"C", 1.0], [&"D", &"C", 1.0],
	])
	var r := DefensivePathfinder.find_path_with_cost(g, &"A", &"C")
	_afirmar(r.reachable == true, "diamante: C alcanzable")
	_afirmar(abs(float(r.cost) - 2.0) < 1e-6, "diamante: coste mínimo = 2.0")
	_afirmar(r.path.size() == 3, "diamante: camino pasa por un intermedio")
	_afirmar(r.path[0] == &"A" and r.path[2] == &"C", "diamante: extremos A y C")
	_afirmar(r.path[1] == &"B" or r.path[1] == &"D", "diamante: intermedio válido (B o D)")


func _mallado_grande() -> void:
	var n := 10
	var g := GraphBuilder.grid(n, 1.0)
	var origen := StringName(&"n0_0")
	var destino := StringName(&"n%d_%d" % [n - 1, n - 1])
	var r := DefensivePathfinder.find_path_with_cost(g, origen, destino)
	# Manhattan entre (0,0) y (n-1,n-1) = 2*(n-1) saltos de coste 1.
	var esperado := float(2 * (n - 1))
	_afirmar(r.reachable == true, "grid 10×10: destino alcanzable")
	_afirmar(abs(float(r.cost) - esperado) < 1e-6,
		"grid 10×10: coste = Manhattan = %.0f" % esperado)
	_afirmar(r.path.size() == esperado + 1, "grid 10×10: |path| = saltos + 1")
	_afirmar(r.path[0] == origen and r.path[r.path.size() - 1] == destino,
		"grid 10×10: extremos correctos")


func _origen_igual_destino() -> void:
	var g := GraphBuilder.chain([&"A", &"B", &"C"])
	var path: Array = DefensivePathfinder.find_path(g, &"A", &"A")
	_afirmar(path.size() == 1, "origen==destino: path = [A]")
	_afirmar(path[0] == &"A", "origen==destino: único elemento es A")
	var r := DefensivePathfinder.find_path_with_cost(g, &"A", &"A")
	_afirmar(r.reachable == true, "origen==destino: reachable true")
	_afirmar(abs(float(r.cost) - 0.0) < 1e-6, "origen==destino: coste 0")


func _grafo_vacio() -> void:
	var g := GraphBuilder.empty()
	var path: Array = DefensivePathfinder.find_path(g, &"A", &"B")
	_afirmar(path.is_empty(), "grafo vacío → []")
	_afirmar(DefensivePathfinder.find_path(null, &"A", &"B").is_empty(),
		"grafo null → []")


func _nodos_inexistentes() -> void:
	var g := GraphBuilder.chain([&"A", &"B", &"C"])
	_afirmar(DefensivePathfinder.find_path(g, &"Z", &"C").is_empty(),
		"origen inexistente → []")
	_afirmar(DefensivePathfinder.find_path(g, &"A", &"Z").is_empty(),
		"destino inexistente → []")


func _equivalencia_find_path_with_cost() -> void:
	var g := GraphBuilder.weighted([[&"A", &"B", 2.0], [&"B", &"C", 2.5]])
	var path: Array = DefensivePathfinder.find_path(g, &"A", &"C")
	var r := DefensivePathfinder.find_path_with_cost(g, &"A", &"C")
	_afirmar(path.size() == r.path.size(), "find_path == find_path_with_cost (size)")
	_afirmar(path.size() == 3, "ambas APIs devuelven 3 nodos en A→B→C")
	_afirmar(abs(float(r.cost) - 4.5) < 1e-6, "with_cost: coste = 2.0 + 2.5 = 4.5")


# ─── Helpers de asserts y cierre ─────────────────────────────────────────

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