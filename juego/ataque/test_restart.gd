extends Node

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# Setup via SceneParams
	SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = true
	SceneParams.ai_block_per_turn = 1
	SceneParams.max_ai_blocks = 1
	SceneParams.ai_bloquea_al_inicio = true
	SceneParams.titulo_nivel = "RESTART TEST"

	var scene = load("res://juego/ataque/escena_juego.tscn")
	var inst = scene.instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame

	if inst.graph == null:
		print("FAIL: graph no cargo")
		failed += 1
		_quit()
		return

	# --- Estado inicial ---
	var start_player: StringName = inst.player_pos
	var start_block_count: int = inst.blocked_edges.size()
	var start_turn: int = inst.turn
	var start_ai_used: int = inst._ai_blocks_used
	var start_game_over: bool = inst.game_over
	print("Estado inicial: pos=%s turn=%d blocks=%d ai_used=%d game_over=%s" % [
		start_player, start_turn, start_block_count, start_ai_used, start_game_over])

	# --- Simular movimiento y bloqueo IA ---
	var vecinos = inst._vecinos_jugador()
	if vecinos.size() == 0:
		print("FAIL: sin vecinos al inicio")
		failed += 1
		_quit()
		return

	var destino = vecinos[0]
	inst._mover_jugador(destino)
	await get_tree().process_frame

	print("Despues de mover: pos=%s turn=%d blocks=%d ai_used=%d game_over=%s" % [
		inst.player_pos, inst.turn, inst.blocked_edges.size(), inst._ai_blocks_used, inst.game_over])

	var mid_player: StringName = inst.player_pos
	var mid_blocks: int = inst.blocked_edges.size()
	var mid_turn: int = inst.turn

	# --- Reiniciar ---
	inst.reset_state()
	await get_tree().process_frame

	print("Despues de reset: pos=%s turn=%d blocks=%d ai_used=%d game_over=%s" % [
		inst.player_pos, inst.turn, inst.blocked_edges.size(), inst._ai_blocks_used, inst.game_over])

	# --- Verificaciones: debe ser identico al estado inicial tras carga ---
	var ok: bool = true

	if inst.player_pos != start_player:
		print("FAIL: player_pos no reinicio: %s != %s" % [inst.player_pos, start_player])
		ok = false

	if inst.turn != start_turn:
		print("FAIL: turn no es %d: %d" % [start_turn, inst.turn])
		ok = false

	if inst._ai_blocks_used != start_ai_used:
		print("FAIL: _ai_blocks_used no es %d: %d" % [start_ai_used, inst._ai_blocks_used])
		ok = false

	if inst.game_over != start_game_over:
		print("FAIL: game_over deberia ser %s" % start_game_over)
		ok = false

	if inst.game_won != false:
		print("FAIL: game_won deberia ser false")
		ok = false

	if inst.blocked_edges.size() != start_block_count:
		print("FAIL: blocked_edges size no es %d: %d" % [start_block_count, inst.blocked_edges.size()])
		ok = false

	if ok:
		print("PASS: reset_state restaura todo correctamente")
		passed += 1
	else:
		failed += 1

	# --- Verificar que realmente se pueden hacer movimientos nuevos ---
	vecinos = inst._vecinos_jugador()
	if vecinos.size() == 0:
		print("FAIL: sin vecinos tras reinicio")
		failed += 1
	else:
		print("PASS: vecinos disponibles tras reinicio: ", vecinos)
		passed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
