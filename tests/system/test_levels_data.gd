extends Node

## Validación data-driven de TODOS los niveles del juego.
##
## Recorre los 7 niveles (defense_n1, hacker_n1/n2, heist_n1/n2/n3, cyber_n1)
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
## Test estático (FileAccess + load de recursos), sin autoloads ni escena:
## los recursos de core/network/ son Resource puros.

const Registry = preload("res://juego/system/level_registry.gd")

const NIVELES: Array[String] = [
	"res://juego/defense/defense_n1.json",
	"res://juego/hacker/hacker_n1.json",
	"res://juego/hacker/hacker_n2.json",
	"res://juego/heist/heist_n1.json",
	"res://juego/heist/heist_n2.json",
	"res://juego/heist/heist_n3.json",
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

	_finalizar()


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
