extends SceneTree

## Runner de pruebas para VERTEX.
##
## Descubre todos los scripts `.gd` bajo `res://tests/` recursivamente y los
## ejecuta uno a uno como escenas independientes, agregando aprobadas /
## fallidas y terminando con un código de salida distinto de cero si alguna
## falló o no pudo ejecutarse.
##
## Convención de nombres (excluida del descubrimiento):
##   - `_*.gd`        → archivos auxiliares (helpers, lanzadores, fixtures).
##   - `run_all.gd`   → el propio runner. Se excluye por nombre.
## Todo `test_*.gd` se considera prueba y se ejecuta.
##
## Por qué lanzador por separado: en Godot 4.7, `--script` exige que el script
## extienda `SceneTree`/`MainLoop`; las pruebas conviven con la convención del
## proyecto (`extends Node`) y requieren un SceneTree corriendo para recibir
## `_ready`, timers y `await`. Por eso cada prueba se ejecuta en un processo
## dedicado vía `res://tests/runner/_run_one.gd`, que la instancia como hijo
## de `root` y deja que el nodo llame `get_tree().quit(codigo)`. El exit code
## se propaga al subproceso y el runner lo interpreta:
##     0  → aprobada
##   124  → timeout (la prueba colgó, matada por el watchdog)
##  otro → fallida (asserts fallaron / crash / error de parseo)
##
## Watchdog: en POSIX donde el binario `timeout` (GNU coreutils) está
## disponible, cada lanzamiento se envuelve con `timeout N godot ...` para que
## una prueba colgada no bloquee el runner. En Windows se omite y se confía en
## el auto-quit convencional de las pruebas.
##
## Uso:
##     godot --headless --script res://tests/runner/run_all.gd

const RAIZ_PRUEBAS := "res://tests"
const NOMBRE_RUNNER := "run_all.gd"
const RUTA_LANZADOR := "res://tests/runner/_run_one.gd"
const OPCION_RUTA := "--test-path"
const TIMEOUT_SEGUNDOS := 30
const BIN_GODOT_RESERVA := "godot"
const CODIGO_TIMEOUT := 124

var _descubiertas: Array[String] = []
var _aprobadas: int = 0
var _fallidas: int = 0
var _errores: int = 0
var _usar_timeout := false


func _init() -> void:
	print("==============================================")
	print("RUNNER VERTEX — iniciando descubrimiento")
	print("==============================================")
	_detectar_timeout()
	_descubrir_pruebas(RAIZ_PRUEBAS, _descubiertas)
	_descubiertas.sort()

	if _descubiertas.is_empty():
		print("RUNNER: No se hallaron pruebas bajo %s" % RAIZ_PRUEBAS)
		_imprimir_resumen()
		quit(0)
		return

	print("RUNNER: %d prueba(s) descubierta(s):" % _descubiertas.size())
	for ruta in _descubiertas:
		print("  - %s" % ruta)
	print("----------------------------------------------")
	if _usar_timeout:
		print("RUNNER: watchdog activo (timeout %ds por prueba)" % TIMEOUT_SEGUNDOS)
	else:
		print("RUNNER: watchdog inactivo — las pruebas deben auto-terminar")
	print("----------------------------------------------")

	for ruta in _descubiertas:
		_ejecutar_prueba(ruta)

	_imprimir_resumen()
	var codigo_salida: int = 1 if (_fallidas > 0 or _errores > 0) else 0
	quit(codigo_salida)


## Recorre `ruta` recursivamente y acumula los `test_*.gd` ignorando `_*.gd`
## y al propio runner.
func _descubrir_pruebas(ruta: String, acumulado: Array[String]) -> void:
	var dir := DirAccess.open(ruta)
	if dir == null:
		push_warning("RUNNER: no se pudo abrir %s — se omite" % ruta)
		return
	dir.list_dir_begin()
	var nombre := dir.get_next()
	while nombre != "":
		if nombre == "." or nombre == "..":
			nombre = dir.get_next()
			continue
		var ruta_completa := "%s/%s" % [ruta, nombre]
		if dir.current_is_dir():
			_descubrir_pruebas(ruta_completa, acumulado)
		elif nombre.ends_with(".gd") and not nombre.begins_with("_") and nombre != NOMBRE_RUNNER:
			acumulado.push_back(ruta_completa)
		nombre = dir.get_next()
	dir.list_dir_end()


## Ejecuta una prueba aislada en su propio Godot headless y registra el
## resultado interpretando el código de salida.
##
## Hay dos modos:
##   - Script puro (por defecto): vía el lanzador `_run_one.gd`.
##   - Scene-based: si existe un `.tscn` con el mismo basename junto al
##     script, se ejecuta `godot --headless <tscn>` directamente. Con `--script`
##     Godot NO registra los autoloads del proyecto, y estas pruebas dependen
##     de ellos (SceneParams, etc.); correrlas como escena en modo proyecto sí
##     los carga.
func _ejecutar_prueba(ruta: String) -> void:
	var bin_godot := _binario_godot()
	var argumentos_base: PackedStringArray
	var ruta_escena := ruta.get_basename() + ".tscn"
	if FileAccess.file_exists(ruta_escena):
		argumentos_base = PackedStringArray(["--headless", ruta_escena])
	else:
		argumentos_base = PackedStringArray([
			"--headless",
			"--script", RUTA_LANZADOR,
			OPCION_RUTA, ruta,
		])
	print("RUNNER: ejecutando %s" % ruta)

	var salida := []
	var codigo: int
	if _usar_timeout:
		var con_timeout := PackedStringArray([str(TIMEOUT_SEGUNDOS), bin_godot])
		for a in argumentos_base:
			con_timeout.append(a)
		codigo = OS.execute("timeout", con_timeout, salida)
	else:
		codigo = OS.execute(bin_godot, argumentos_base, salida)

	# Reenviar la salida capturada del subproceso para trazabilidad.
	if salida.size() > 0:
		for entrada in salida:
			var texto := String(entrada)
			if texto.is_empty():
				continue
			if texto.contains("\n"):
				for linea in texto.split("\n"):
					if not linea.is_empty():
						print(linea)
			else:
				print(texto)

	_registrar_resultado(ruta, codigo)


func _registrar_resultado(ruta: String, codigo: int) -> void:
	if codigo == 0:
		_aprobadas += 1
		print("RUNNER: OK %s" % ruta)
	elif codigo == CODIGO_TIMEOUT:
		_errores += 1
		print("RUNNER: TIMEOUT %s (>%ds)" % [ruta, TIMEOUT_SEGUNDOS])
	else:
		_fallidas += 1
		print("RUNNER: FALLO %s (código %d)" % [ruta, codigo])
	print("----------------------------------------------")


func _imprimir_resumen() -> void:
	print("==============================================")
	print("Resumen: %d aprobadas, %d fallidas, %d errores" % [_aprobadas, _fallidas, _errores])
	print("==============================================")


## Reusa el mismo binario Godot que ejecuta este runner; si no hay, recurre
## a `godot` en PATH.
func _binario_godot() -> String:
	var bin := OS.get_executable_path()
	if bin.is_empty():
		return BIN_GODOT_RESERVA
	return bin


## Detecta si el binario `timeout` (GNU coreutils) está disponible para usar
## como watchdog. En Windows no existe, se omite.
func _detectar_timeout() -> void:
	_usar_timeout = false
	if OS.get_name() == "Windows":
		return
	var descartable := []
	_usar_timeout = OS.execute("timeout", PackedStringArray(["--version"]), descartable) == 0