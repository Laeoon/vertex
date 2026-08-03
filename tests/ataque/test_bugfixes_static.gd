extends Node

## Pruebas estáticas (autoload-free) para las tareas 1.2 y 1.3 del slice 1.
##
## Esta prueba es deliberadamente agnóstica de autoloads: sólo hace lectura de
## texto de archivos `.gd` con FileAccess y busca subcadenas. Por eso corre
## vía el runner `--script` (res://tests/runner/run_all.gd) sin depender de
## SceneParams/AudioManager/etc., que NO se registran en modo MainLoop
## personalizado (ver slice-0 apply-progress, hallazgo #6 / limitación runner).
##
## Verifica:
##   - 1.2: el archivo `juego/ataque/ia_defensora.gd` ya no existe en disco, y
##         el texto fuente de `juego_ataque.gd` ya no declara `const IADefensora`.
##   - 1.3: `mostrar_ruta()` ya no es un `pass` silencioso: el fuente contiene
##         la advertencia deliberada (push_warning + _ruta_warning_emitido).
##
## La verificación comportamental completa de 1.3 (conmutación del flag) y la
## prueba de integración de 1.4 sobre el `_draw()` real se hacen con escenas
## (autoloads registrados): ver `juego/ataque/test_defender_brain_draw_null.tscn`.

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# ── Tarea 1.2: ia_defensora.gd eliminado ──
	_afirmar(not FileAccess.file_exists("res://juego/ataque/ia_defensora.gd"),
		"1.2: ia_defensora.gd no existe en disco")
	var src_juego: String = FileAccess.get_file_as_string("res://juego/ataque/juego_ataque.gd")
	_afirmar(not src_juego.is_empty(),
		"1.2/1.3: se leyó el fuente de juego_ataque.gd")
	_afirmar(src_juego.find("IADefensora") == -1,
		"1.2: juego_ataque.gd no contiene el símbolo IADefensora (preload muerto)")
	_afirmar(src_juego.find('preload("res://juego/ataque/ia_defensora.gd")') == -1,
		"1.2: juego_ataque.gd no preload la ruta ia_defensora.gd")

	# ── Tarea 1.3: mostrar_ruta() ya no es un pass silencioso ──
	# El cuerpo nuevo referencia el flag y emite push_warning (advertencia
	# deliberada). Buscamos los marcadores característicos de la nueva
	# implementación.
	_afirmar(src_juego.find("_ruta_warning_emitido") != -1,
		"1.3: el fuente declara el flag _ruta_warning_emitido")
	_afirmar(src_juego.find("mostrar_ruta(): la visualización automática") != -1,
		"1.3: mostrar_ruta() emite un push_warning deliberado (no es un pass)")
	# Además, el cuerpo viejo ("# Solo calcular si se pide explícitamente con P"
	# seguido de `pass`) ya no debe aparecer.
	_afirmar(not (src_juego.find("# Solo calcular si se pide explícitamente con P") != -1
			and src_juego.find("pass", src_juego.find("func mostrar_ruta")) != -1),
		"1.3: el stub silencioso original (pass) fue reemplazado")

	# ── Dia 3.7: Fix waypoint vacio en _ganar() ──
	_afirmar(src_juego.find("waypoints.size() > 0 and current_waypoint_idx") != -1,
		"D3.7: _ganar() verifica waypoints.size() > 0 antes de comparar indices")
	_afirmar(src_juego.find("current_waypoint_idx = -1 if waypoints.is_empty() else 0") != -1,
		"D3.7: current_waypoint_idx se inicializa en -1 cuando waypoints esta vacio")

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