extends Node

## Test del mostrar_ruta() real (slice 4): puebla current_path con la ruta
## óptima desde player_pos hasta el objetivo actual RESPETANDO bloqueos del
## runtime (el hint [P] usa el grafo limpio; ver GameState.mostrar_ruta).
##
## Corre como escena (autoloads: SceneParams, Events, GameLogger). Aserciones
## directas (feature nueva, no hay comportamiento pre-slice que congelar).
##
## Invocación:
##     godot --headless res://tests/ataque/_test_mostrar_ruta.tscn

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = [&"Puerta_A"]
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.max_ai_blocks = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 0
	SceneParams.max_movement_points = 0
	SceneParams.titulo_nivel = "MOSTRAR RUTA TEST"

	var scene = load("res://juego/ataque/escena_juego.tscn")
	var juego = scene.instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if juego.graph == null:
		print("FAIL: graph no cargo")
		failed += 1
		_fin()
		return

	# ── S1: tras el arranque, current_path conecta player_pos → objetivo ──
	var ruta: Array = juego.current_path
	_af(juego.showing_path, "S1: showing_path=true tras reset")
	_af(ruta.size() >= 2, "S1: current_path poblada (len=%d)" % ruta.size())
	_af(ruta[0] == juego.player_pos, "S1: ruta empieza en player_pos (%s)" % str(ruta[0]))
	_af(ruta[ruta.size() - 1] == juego._target_actual(),
		"S1: ruta termina en el objetivo actual (%s)" % juego._target_actual())

	# ── S2: bloquear la primera arista de la ruta → recalcula evitándola ──
	var first_edge: String = "%s→%s" % [ruta[0], ruta[1]]
	juego._block_edge(first_edge, ruta[0], ruta[1])
	juego.mostrar_ruta()
	var ruta2: Array = juego.current_path
	if ruta2.size() >= 2:
		var first_edge2: String = "%s→%s" % [ruta2[0], ruta2[1]]
		_af(first_edge2 != first_edge,
			"S2: ruta recalculada evita la arista bloqueada (%s → %s)" % [first_edge, first_edge2])
		_af(not juego._is_blocked(first_edge2), "S2: la primera arista nueva no está bloqueada")
	else:
		_af(true, "S2: objetivo inalcanzable tras bloqueo — ruta vacía (válido)")
	_af(ruta2.size() == 0 or ruta2[ruta2.size() - 1] == juego._target_actual(),
		"S2: ruta nueva sigue terminando en el objetivo (o vacía)")

	# ── S3: tras moverse, la ruta parte desde la posición nueva ──
	juego.reset_state()  # limpia el bloqueo de S2 y recalcula
	var vecinos: Array = juego._vecinos_jugador()
	if vecinos.size() > 0:
		juego._mover_jugador(vecinos[0])
		juego.mostrar_ruta()
		_af(juego.current_path.size() >= 2
			and juego.current_path[0] == juego.player_pos,
			"S3: tras mover a %s, ruta parte desde ahí" % str(juego.player_pos))
	else:
		_af(false, "S3: sin vecinos accesibles (setup inesperado)")
	juego.queue_free()

	# ── S4: en modo defensor no hay jugador → current_path vacía ──
	SceneParams.graph_path = "res://juego/defense/defense_n1.tres"
	SceneParams.start_node = &"Internet"
	SceneParams.target_node = &"DataCenter"
	SceneParams.waypoints = []
	SceneParams.defender_mode = true
	SceneParams.defender_blocks_per_turn = 2
	SceneParams.defender_block_duration = 4
	SceneParams.enemy_start_node = &"Internet"
	SceneParams.enemy_target_node = &"DataCenter"
	var jd = load("res://juego/ataque/escena_juego.tscn").instantiate()
	get_tree().root.add_child(jd)
	await get_tree().process_frame
	await get_tree().process_frame
	_af(jd.defender_mode and jd.current_path.size() == 0 and not jd.showing_path,
		"S4: modo defensor → current_path vacía y showing_path=false")
	jd.queue_free()

	_fin()


func _af(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _fin() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
