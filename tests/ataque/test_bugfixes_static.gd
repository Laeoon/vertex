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
##   - 1.3: `mostrar_ruta()` está implementado (slice 4): el orquestador
##         delega en GameState.mostrar_ruta(), que puebla `current_path` con
##         la ruta óptima respetando bloqueos. Historia: stub silencioso
##         (origen) → push_warning deliberado (slice 1) → no-op documentado
##         (P5) → implementación real delegada (slice 4).
##
## La verificación comportamental completa de 1.3 (conmutación del flag) y la
## prueba de integración de 1.4 sobre el `_draw()` real se hacen con escenas
## (autoloads registrados): ver `tests/ataque/test_defender_brain_draw_null.tscn`.

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

	# ── Tarea 1.3 (actualizada por slice 4): mostrar_ruta() implementado ──
	# El orquestador delega en GameState.mostrar_ruta() (puebla current_path,
	# respeta bloqueos del runtime y es no-op en modo defensor).
	var inicio: int = src_juego.find("func mostrar_ruta")
	_afirmar(inicio != -1, "1.3: existe func mostrar_ruta()")
	var cuerpo: String = ""
	if inicio != -1:
		var fin: int = src_juego.find("\nfunc ", inicio + 1)
		cuerpo = src_juego.substr(inicio, (fin if fin != -1 else src_juego.length()) - inicio)
	_afirmar(cuerpo.find("_game_state.mostrar_ruta()") != -1,
		"1.3: mostrar_ruta() delega en GameState (slice 4)")
	_afirmar(cuerpo.find("push_warning") == -1,
		"1.3: mostrar_ruta() sin push_warning")
	_afirmar(src_juego.find("_ruta_warning_emitido") == -1,
		"1.3: el flag _ruta_warning_emitido sigue eliminado")
	var src_state_impl: String = FileAccess.get_file_as_string("res://juego/ataque/game_state.gd")
	var ini_impl: int = src_state_impl.find("func mostrar_ruta")
	_afirmar(ini_impl != -1
		and src_state_impl.find("current_path", ini_impl) != -1
		and src_state_impl.find("find_path_with_cost", ini_impl) != -1,
		"1.3: GameState.mostrar_ruta() puebla current_path vía pathfinder")

	# ── Dia 3.7: Fix waypoint vacio en _ganar() ──
	# Slice 3/etapa 3: _ganar() migró a juego/ataque/game_logic.gd.
	var src_logic: String = FileAccess.get_file_as_string("res://juego/ataque/game_logic.gd")
	_afirmar(src_logic.find("_game.waypoints.size() > 0 and _game.current_waypoint_idx") != -1,
		"D3.7: _ganar() verifica waypoints.size() > 0 antes de comparar indices (game_logic.gd)")
	# Slice 3/etapa 1: reset_state() migró a juego/ataque/game_state.gd —
	# el marcador D3.7 se busca ahora en el fuente del módulo.
	var src_state: String = FileAccess.get_file_as_string("res://juego/ataque/game_state.gd")
	_afirmar(src_state.find("current_waypoint_idx = -1 if _game.waypoints.is_empty() else 0") != -1,
		"D3.7: current_waypoint_idx se inicializa en -1 cuando waypoints esta vacio (game_state.gd)")

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