extends SceneTree

## Lanzador individual de pruebas para VERTEX.
##
## Se invoca una vez por prueba desde `run_all.gd` con:
##     godot --headless --script res://tests/runner/_run_one.gd \
##           --test-path res://tests/<dir>/test_*.gd
##
## Carga el script cuyo `extends Node` está dado por convención, lo instancia
## como hijo de `root`, deja correr el SceneTree para que reciba `_ready`,
## `_process`, timers y `await`, y termina cuando la prueba llama
## `get_tree().quit(codigo)`. El código de salida se propaga al proceso del
## mismo, de modo que el runner externo lo lee con `OS.execute(...)`.
##
## Este archivo empieza con `_` de manera que `run_all.gd` no lo descubre.

const OPCION_RUTA := "--test-path"


func _init() -> void:
	var ruta := _obtener_ruta_prueba()
	if ruta.is_empty():
		push_error("RUN_ONE: falta argumento %s <ruta>" % OPCION_RUTA)
		quit(2)
		return
	if not ResourceLoader.exists(ruta, "Script"):
		push_error("RUN_ONE: no existe el script de prueba: %s" % ruta)
		quit(2)
		return
	var script := load(ruta)
	if script == null or not (script is Script):
		push_error("RUN_ONE: no se pudo cargar como Script: %s" % ruta)
		quit(2)
		return
	# Forzar la detección de errores de parseo temprano: un script con errores
	# sintácticos igual "carga" (lazy), pero `reload()` los reporta de inmediato.
	# Sin esto, el nodo se crearía sin comportamiento y el SceneTree correría
	# en vacío hasta el watchdog (30s) en lugar de fallar al instante.
	var err_parseo: int = script.reload()
	if err_parseo != OK:
		push_error("RUN_ONE: error de parseo en %s: %s" % [ruta, error_string(err_parseo)])
		quit(3)
		return
	var nodo := Node.new()
	nodo.name = "Prueba"
	nodo.set_script(script)
	root.add_child(nodo)
	# A partir de aquí el motor entra al main loop: el nodo recibirá _ready
	# (→ call_deferred("_run_tests") según convención) y el SceneTree correrá
	# hasta que la prueba invoque get_tree().quit(codigo).


func _obtener_ruta_prueba() -> String:
	var args := OS.get_cmdline_args()
	var i := 0
	while i < args.size():
		if args[i] == OPCION_RUTA and i + 1 < args.size():
			return args[i + 1]
		i += 1
	return ""