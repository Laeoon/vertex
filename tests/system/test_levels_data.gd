extends Node

## Validación data-driven de TODOS los niveles del juego.
##
## Recorre los 9 niveles (defense_n1, hacker_n1/n2, heist_n1..n5, cyber_n1)
## y verifica por cada uno:
##   1. El .json parsea a Dictionary.
##   2. Tiene las claves mínimas de configuración (id, world, graph_path,
##      start_node, target_node, titulo_nivel, max_turns).
##   3. El grafo referenciado por graph_path existe y carga como
##      NetworkGraphResource, pasa su propio validate(), y tiene nodos/aristas.
##   4. start_node/target_node existen dentro del grafo cargado.
##   5. Coherencia de modo: si hacker_mode → starting_exploits no vacío;
##      si defender_mode → enemy_start_node/enemy_target_node presentes y
##      dentro del grafo.
##
##   6. Diversidad de rutas: si el JSON declara "diversidad_minima": K, el
##      min-cut en aristas (# caminos arista-independientes) entre cada par
##      de objetivos consecutivos (start → waypoints → target) debe ser ≥ K.
##      Siempre se imprime un reporte informativo con los min-cuts por tramo.
##
## Test estático (FileAccess + load de recursos), sin autoloads ni escena:
## los recursos de core/network/ son Resource puros.

const Registry = preload("res://juego/system/level_registry.gd")
const GraphBuilder = preload("res://tests/core/_graph_builder.gd")

const NIVELES: Array[String] = [
	"res://juego/defense/defense_n1.json",
	"res://juego/hacker/hacker_n1.json",
	"res://juego/hacker/hacker_n2.json",
	"res://juego/hacker/hacker_n3.json",
	"res://juego/hacker/hacker_n4.json",
	"res://juego/hacker/hacker_n5.json",
	"res://juego/heist/heist_n1.json",
	"res://juego/heist/heist_n2.json",
	"res://juego/heist/heist_n3.json",
	"res://juego/heist/heist_n4.json",
	"res://juego/heist/heist_n5.json",
	"res://juego/cyber/cyber_n1.json",
]

const CLAVES_MINIMAS: Array[String] = [
	"id", "world", "graph_path", "start_node", "target_node", "titulo_nivel", "max_turns",
]

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# El inventario de niveles coincide con lo que declara LevelRegistry:
	# si alguien agrega un JSON sin registrarlo (o al revés), esto falla.
	var rutas_registry: Array = []
	for world_id in Registry.WORLDS:
		for cfg in Registry.WORLDS[world_id]["levels"]:
			rutas_registry.append(cfg["path"])
	var conjunto_registry: Dictionary = {}
	for r in rutas_registry:
		conjunto_registry[r] = true
	var conjunto_disk: Dictionary = {}
	for r in NIVELES:
		conjunto_disk[r] = true
	_afirmar(conjunto_registry == conjunto_disk,
		"el inventario de JSON en disco == el registro de LevelRegistry (%d niveles)" % NIVELES.size())

	for ruta in NIVELES:
		_validar_nivel(ruta)

	_unit_extra_min_cut()
	_verificar_diversidad_niveles()

	_finalizar()


## ─── Diversidad de rutas (min-cut ≥ K entre objetivos consecutivos) ───

## Unit extra: grafos sintéticos que fijan la semántica del min-cut.
func _unit_extra_min_cut() -> void:
	var cadena := GraphBuilder.chain([&"A", &"B", &"C"])
	_afirmar(_min_cut_aristas(cadena, &"A", &"C") == 1,
		"unit cadena A→B→C: min-cut(A,C)=1")

	var rombo := GraphBuilder.build([&"A", &"B", &"C", &"D"], [
		{"from": &"A", "to": &"B"}, {"from": &"B", "to": &"D"},
		{"from": &"A", "to": &"C"}, {"from": &"C", "to": &"D"},
	])
	_afirmar(_min_cut_aristas(rombo, &"A", &"D") == 2,
		"unit rombo A→B→D / A→C→D: min-cut(A,D)=2")


## Recorre todos los niveles y verifica diversidad de rutas:
##   - SIEMPRE imprime una línea informativa con el min-cut de cada tramo.
##   - Si el JSON declara "diversidad_minima": K, afirma min-cut ≥ K por tramo.
func _verificar_diversidad_niveles() -> void:
	for ruta in NIVELES:
		var nombre: String = ruta.get_file().get_basename()
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
		if not (data is Dictionary):
			continue
		var graph = load(data.get("graph_path", ""))
		if graph == null or not ("edges" in graph and "nodes" in graph):
			continue

		var objetivos: Array[String] = [str(data["start_node"])]
		for wp in data.get("waypoints", []):
			objetivos.append(str(wp))
		objetivos.append(str(data["target_node"]))

		var k: int = int(data.get("diversidad_minima", 0))
		var cuts: Array[String] = []
		for i in range(objetivos.size() - 1):
			var a := StringName(objetivos[i])
			var b := StringName(objetivos[i + 1])
			var mc := _min_cut_aristas(graph, a, b)
			cuts.append("%s→%s=%d" % [a, b, mc])
			if k > 0:
				if mc < k:
					print("FAIL: %s: tramo %s→%s min-cut=%d < %d" % [nombre, a, b, mc, k])
					failed += 1
				else:
					print("PASS: %s: tramo %s→%s min-cut=%d ≥ %d" % [nombre, a, b, mc, k])
					passed += 1
		print("INFO: %s diversidad (K=%d): %s" % [nombre, k, ", ".join(cuts)])


## Min-cut en ARISTAS entre origen y destino con capacidad 1 por arista
## (= cantidad máxima de caminos arista-independientes).
##
## Reutiliza StrategicAnalyzer.find_min_cut (Edmonds-Karp de producción,
## core/agents/strategic_analyzer.gd), que lee mitigation_capacity; para
## imponer capacidad unitaria se reconstruye el grafo vía GraphBuilder con
## las mismas topología y aristas pero capacity por defecto = 1.
func _min_cut_aristas(
		graph: NetworkGraphResource,
		origen: StringName,
		destino: StringName
) -> int:
	if graph == null or origen == destino:
		return 0
	var ids: Array = []
	for n in graph.nodes:
		ids.append(n.id)
	var specs: Array = []
	for e in graph.edges:
		specs.append({"from": e.from_id, "to": e.to_id})
	var unitario: NetworkGraphResource = GraphBuilder.build(ids, specs)
	return int(StrategicAnalyzer.find_min_cut(unitario, origen, destino)["max_flow"])


func _validar_nivel(ruta: String) -> void:
	var nombre: String = ruta.get_file().get_basename()
	var problemas: Array[String] = []

	if not FileAccess.file_exists(ruta):
		_afirmar(false, "%s: el archivo existe" % nombre)
		return

	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not (data is Dictionary):
		_afirmar(false, "%s: el JSON parsea a Dictionary" % nombre)
		return

	for clave in CLAVES_MINIMAS:
		if not data.has(clave) or str(data[clave]) == "":
			problemas.append("falta clave '%s'" % clave)

	if data.get("world") != null and not Registry.WORLDS.has(data["world"]):
		problemas.append("world '%s' no está en WORLDS" % data["world"])

	var graph_path: String = data.get("graph_path", "")
	if not FileAccess.file_exists(graph_path):
		problemas.append("graph_path inexistente: %s" % graph_path)

	var graph = null
	if FileAccess.file_exists(graph_path):
		graph = load(graph_path)
	if graph == null:
		problemas.append("graph_path no carga como recurso")
	elif not ("nodes" in graph and "edges" in graph):
		problemas.append("el recurso cargado no es un grafo (sin nodes/edges)")
	else:
		if graph.nodes.is_empty() or graph.edges.is_empty():
			problemas.append("grafo vacío (nodes=%d, edges=%d)" % [graph.nodes.size(), graph.edges.size()])
		for err in graph.validate():
			problemas.append("validate(): %s" % err)
		for clave_nodo in ["start_node", "target_node"]:
			if graph.get_node_by_id(StringName(str(data[clave_nodo]))) == null:
				problemas.append("%s '%s' no existe en el grafo" % [clave_nodo, data[clave_nodo]])

	if data.get("hacker_mode", false):
		var exploits: Variant = data.get("starting_exploits")
		if not (exploits is Dictionary) or exploits.is_empty():
			problemas.append("hacker_mode sin starting_exploits")

	if data.get("defender_mode", false):
		for clave in ["enemy_start_node", "enemy_target_node"]:
			var valor: Variant = data.get(clave, "")
			if str(valor) == "":
				problemas.append("defender_mode sin %s" % clave)
			elif graph != null and graph.get_node_by_id(StringName(str(valor))) == null:
				problemas.append("%s '%s' no existe en el grafo" % [clave, valor])

	# Par por nivel (slice 5): obligatorio en heist (balanceado con self-play),
	# opcional en el resto (aún usan la lógica legacy de estrellas).
	if data.get("world") == "heist":
		for clave in ["par_turnos", "par_coste"]:
			var par: Variant = data.get(clave)
			if not (par is float or par is int) or float(par) <= 0:
				problemas.append("heist sin %s válido (>0)" % clave)
	elif data.has("par_turnos") != data.has("par_coste"):
		problemas.append("par incompleto: par_turnos y par_coste van juntos")

	if problemas.is_empty():
		print("PASS: %s válido (grafo: %d nodos, %d aristas)" % [nombre, graph.nodes.size(), graph.edges.size()])
		passed += 1
	else:
		print("FAIL: %s — %s" % [nombre, " | ".join(problemas)])
		failed += 1


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
