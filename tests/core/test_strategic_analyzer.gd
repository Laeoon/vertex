extends Node

## Pruebas del algoritmo Edmonds-Karp (`StrategicAnalyzer`) sobre
## NetworkGraphResource. Cubre los escenarios de la tarea 2.3:
##   1. Flujo máximo + corte mínimo en una red con reenrutado por arista
##      cruzada (verifica max-flow == min-cut y orden ASC por capacidad).
##   2. Cero en desconexión (source aislado de sink).
##   3. source == sink → resultado vacío.
##   4. Grafo vacío → resultado vacío.
##   5. Puente único → |cut_edges| == 1 y capacity == max_flow.
##   6. Teorema max-flow/min-cut en diamante paralelo (2 caminos).
##
## Mapeo de ramas de core/agents/strategic_analyzer.gd:
##   -validaciones (40–52)        : vacíos, source/sink inexistentes, src==snk
##   -build_residual (146–166)     : construcción + suma de capacidades paralelas
##   -bucle Edmonds-Karp (60–99)   : BFS, bottleneck, update residual, max_flow
##   -bfs_reachable (103)          : set S/T final
##   -cut_edges (118–131)          : aristas S→T originales + sort ASC
## No se cubre la rama de `parent.get(v,&"")` roto (defensivo, línea 73–74)
## con datos válidos; se documenta como no cubrible.
##
## Autoload-free, basada en extends Node, corre vía tests/runner/_run_one.gd.

const GraphBuilder = preload("res://tests/core/_graph_builder.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_flujo_maximo_con_reenrutado()
	_cero_en_desconexion()
	_origen_igual_destino()
	_grafo_vacio()
	_puente_unico()
	_diamante_paralelo()
	_finalizar()


# ─── Escenarios ────────────────────────────────────────────────────────

func _flujo_maximo_con_reenrutado() -> void:
	# S→A(3), S→B(2), A→T(2), B→T(3), A→B(1)
	# Flujo: 2 (S→A→T) + 2 (S→B→T) + 1 (S→A→B→T tras saturar) = 5
	var g := GraphBuilder.weighted([
		[&"S", &"A", 1.0, 3.0], [&"S", &"B", 1.0, 2.0],
		[&"A", &"T", 1.0, 2.0], [&"B", &"T", 1.0, 3.0],
		[&"A", &"B", 1.0, 1.0],
	])
	var r: Dictionary = StrategicAnalyzer.find_min_cut(g, &"S", &"T")
	var max_flow: float = float(r["max_flow"])
	var cut: Array = r["cut_edges"]
	_afirmar(abs(max_flow - 5.0) < 1e-6, "red con reenrutado: max_flow = 5.0")
	_afirmar(cut.size() == 2, "red con reenrutado: |cut_edges| = 2 (S→A y S→B)")
	_afirmar(cut[0]["capacity"] < cut[1]["capacity"] + 1e-9,
		"red con reenrutado: cut_edges ordenado ASC por capacidad")
	var suma: float = 0.0
	for e in cut:
		suma += float(e["capacity"])
	_afirmar(abs(suma - max_flow) < 1e-6,
		"red con reenrutado: teorema max-flow == min-cut (Σ caps == max_flow)")
	# El corte esperado son las aristas salientes de S: S→A(3) y S→B(2).
	var caps := _caps_origen(cut, &"S")
	_afirmar(caps.has(2.0) and caps.has(3.0),
		"red con reenrutado: corte son S→B(2) y S→A(3)")


func _cero_en_desconexion() -> void:
	# source S sólo alcanza A; sink T sólo entra desde D; sin puente S↔T.
	var g := GraphBuilder.weighted([
		[&"S", &"A", 1.0, 3.0], [&"T", &"D", 1.0, 2.0],
	])
	var r: Dictionary = StrategicAnalyzer.find_min_cut(g, &"S", &"T")
	_afirmar(abs(float(r["max_flow"]) - 0.0) < 1e-6,
		"desconexión: max_flow = 0")
	_afirmar((r["cut_edges"] as Array).is_empty(),
		"desconexión: cut_edges vacío")
	_afirmar((r["isolated_T"] as Array).has(&"T"),
		"desconexión: sink queda en el lado aislado T")


func _origen_igual_destino() -> void:
	var g := GraphBuilder.chain([&"S", &"A", &"T"])
	var r: Dictionary = StrategicAnalyzer.find_min_cut(g, &"S", &"S")
	_afirmar(abs(float(r["max_flow"]) - 0.0) < 1e-6,
		"source==sink: max_flow = 0")
	_afirmar((r["cut_edges"] as Array).is_empty(),
		"source==sink: cut_edges vacío (guard explícito)")


func _grafo_vacio() -> void:
	var r1: Dictionary = StrategicAnalyzer.find_min_cut(GraphBuilder.empty(), &"S", &"T")
	_afirmar(r1["cut_edges"] != null and (r1["cut_edges"] as Array).is_empty(),
		"grafo vacío: cut_edges vacío")
	var r2: Dictionary = StrategicAnalyzer.find_min_cut(null, &"S", &"T")
	_afirmar((r2["cut_edges"] as Array).is_empty(),
		"grafo null: cut_edges vacío")


func _puente_unico() -> void:
	# S→T es el único puente; min-cut = 1 arista, capacity == max_flow.
	var g := GraphBuilder.weighted([[&"S", &"T", 1.0, 4.0]])
	var r: Dictionary = StrategicAnalyzer.find_min_cut(g, &"S", &"T")
	var cut: Array = r["cut_edges"]
	_afirmar(abs(float(r["max_flow"]) - 4.0) < 1e-6,
		"puente único: max_flow = 4.0 (= capacidad del puente)")
	_afirmar(cut.size() == 1, "puente único: |cut_edges| = 1")
	if cut.size() == 1:
		_afirmar(cut[0]["from_id"] == &"S" and cut[0]["to_id"] == &"T",
			"puente único: la arista cortada es S→T")
		_afirmar(abs(float(cut[0]["capacity"]) - 4.0) < 1e-6,
			"puente único: capacity == max_flow (teorema)")


func _diamante_paralelo() -> void:
	# Dos caminos paralelos S→A→T y S→B→T, ambos cuello 3.
	# max_flow = 6 (3+3); corte = {S→A(3), S→B(3)}.
	var g := GraphBuilder.weighted([
		[&"S", &"A", 1.0, 3.0], [&"S", &"B", 1.0, 3.0],
		[&"A", &"T", 1.0, 3.0], [&"B", &"T", 1.0, 3.0],
	])
	var r: Dictionary = StrategicAnalyzer.find_min_cut(g, &"S", &"T")
	var cut: Array = r["cut_edges"]
	_afirmar(abs(float(r["max_flow"]) - 6.0) < 1e-6,
		"diamante paralelo: max_flow = 6.0")
	_afirmar(cut.size() == 2, "diamante paralelo: |cut_edges| = 2")
	var suma: float = 0.0
	for e in cut:
		suma += float(e["capacity"])
	_afirmar(abs(suma - 6.0) < 1e-6,
		"diamante paralelo: teorema Σ caps == max_flow")


# ─── Helpers ─────────────────────────────────────────────────────────────

func _caps_origen(cut: Array, origen: StringName) -> Array:
	var caps: Array = []
	for e in cut:
		if e["from_id"] == origen:
			caps.append(float(e["capacity"]))
	return caps


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