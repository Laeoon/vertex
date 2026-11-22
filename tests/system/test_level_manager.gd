extends Node

## Pruebas para LevelManager (juego/system/).
##
## LevelManager referencia SceneParams y SceneTransition (autoloads) en los
## cuerpos de launch_level/launch_tutorial, así que NO compila en modo
## `--script` — este test corre como escena (ver test_level_manager.tscn,
## el runner lo detecta y ejecuta en modo proyecto con autoloads).
##
## Se prueban los caminos que NO disparan transición de escena (mundo/índice
## inválido, tutorial inexistente) más las consultas puras. NO se llama al
## launch_level exitoso porque SceneTransition.fade_to_scene cambiaría la
## escena activa a mitad de test; esa integración la cubren los smoke tests
## por modo (tests/ataque/test_*_sanity.gd) que bootean escena_juego.tscn
## directamente con los mismos parámetros.

const LevelManager = preload("res://juego/system/level_manager.gd")
const RegistryClass = preload("res://juego/system/level_registry.gd")
const GameStateClass = preload("res://juego/ataque/game_state.gd")
const JuegoAtaqueScene = preload("res://juego/ataque/escena_juego.tscn")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var worlds: Dictionary = LevelManager.get_worlds()
	_afirmar(worlds.has("heist") and worlds.has("hacker") and worlds.has("cybersecurity"),
		"get_worlds() expone los 3 mundos del registry")

	_afirmar(LevelManager.get_world_title("heist") == "Heist",
		"get_world_title('heist') = 'Heist'")
	_afirmar(LevelManager.get_world_title("desconocido") == "desconocido",
		"get_world_title desconocido → devuelve el id como fallback")

	_afirmar(LevelManager.launch_level("mundo_inexistente", 0) == false,
		"launch_level con mundo inválido → false (sin transición)")
	_afirmar(LevelManager.launch_level("heist", 99) == false,
		"launch_level con índice fuera de rango → false")

	_afirmar(LevelManager.launch_tutorial("res://tutorials/no_existe.json") == false,
		"launch_tutorial con ruta inexistente → false")

	# Side-effect verificable sin transición: el arranque fallido resetea
	# SceneParams (launch_level llama reset() antes de validar).
	SceneParams.titulo_nivel = "BASURA_PRE_LAUNCH"
	LevelManager.launch_level("mundo_inexistente", 0)
	_afirmar(SceneParams.titulo_nivel != "BASURA_PRE_LAUNCH",
		"launch_level resetea SceneParams aunque el nivel no exista")

	await _test_f1_3_unified_loader_and_cleanup()

	_finalizar()


func _test_f1_3_unified_loader_and_cleanup() -> void:
	# 1. Unified LevelManager: eventos_alarma + node_positions from secret_root.json
	SceneParams.reset()
	var secret_data: Dictionary = RegistryClass.load_level_data("res://juego/secret/secret_root.json")
	_afirmar(not secret_data.is_empty(), "secret_root.json carga desde LevelRegistry")
	LevelManager._apply_to_scene_params(secret_data)
	_afirmar(SceneParams.eventos_alarma.size() == 3,
		"LevelManager carga eventos_alarma (3) desde secret_root.json")
	_afirmar(SceneParams.node_positions.size() == 12,
		"LevelManager carga node_positions (12) desde secret_root.json")
	_afirmar(SceneParams.node_positions.get("Incursor", []) == [95.0, 272.0] or SceneParams.node_positions.get("Incursor", []) == [95, 272],
		"SceneParams.node_positions['Incursor'] == [95, 272]")

	# Fallback 'eventos' from heist_n4.json
	SceneParams.reset()
	var heist4_data: Dictionary = RegistryClass.load_level_data("res://juego/heist/heist_n4.json")
	LevelManager._apply_to_scene_params(heist4_data)
	_afirmar(SceneParams.eventos_alarma.size() > 0,
		"LevelManager mantiene fallback 'eventos' desde heist_n4.json")
	_afirmar(SceneParams.node_positions.is_empty(),
		"heist_n4.json sin node_positions deja SceneParams.node_positions vacío")

	# 2. GameState.edge_en_posicion() + juego_ataque._edge_en_posicion() delegation + SceneParams.node_positions applied in load_graph
	SceneParams.reset()
	LevelManager._apply_to_scene_params(secret_data)
	var juego: Node = JuegoAtaqueScene.instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame

	_afirmar(juego.node_positions.get(&"Incursor", Vector2.ZERO) == Vector2(95.0, 272.0),
		"GameState.load_graph() aplica SceneParams.node_positions sin override ad-hoc")
	var p_incursor: Vector2 = juego.node_positions.get(&"Incursor", Vector2.ZERO)
	var p_hex1: Vector2 = juego.node_positions.get(&"HexNode_1", Vector2.ZERO)
	var mid_edge: Vector2 = (p_incursor + p_hex1) * 0.5
	var hit_gs: String = juego._game_state.edge_en_posicion(mid_edge)
	var hit_ja: String = juego._edge_en_posicion(mid_edge)
	_afirmar(hit_gs != "" and hit_gs == hit_ja,
		"juego_ataque._edge_en_posicion() delega exactamente en GameState.edge_en_posicion() ('%s')" % hit_gs)
	_afirmar(juego._game_state.edge_en_posicion(Vector2(-9999.0, -9999.0)) == "",
		"GameState.edge_en_posicion() devuelve '' fuera del umbral de 30px")
	juego.queue_free()

	# 3. Structural F1.3 checks: no DiveMode duplication in main_menu.gd, no shadowing in tutorials_menu.gd
	var main_menu_src: String = FileAccess.get_file_as_string("res://escenas/main_menu.gd")
	_afirmar(not main_menu_src.contains("enum DiveMode") and not main_menu_src.contains("func _draw_dive_in"),
		"main_menu.gd sin duplicación DiveMode/_draw_dive_in")
	var tut_menu_src: String = FileAccess.get_file_as_string("res://escenas/main_menu/tutorials_menu.gd")
	_afirmar(not tut_menu_src.contains("_sp_instance") and not tut_menu_src.contains("_st_instance"),
		"tutorials_menu.gd sin shadowing de SceneParams/SceneTransition")


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
