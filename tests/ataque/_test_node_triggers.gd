extends Node

## Triggers reactivos por nodo y aristas condicionales (E4).
##
## Escenarios (grafo tut2_red: Inicio→{Puerta_A, Puerta_B}→Target):
##   S1 — Pisar un nodo con trigger ejecuta efectos (alert_network, spawn_pursuer, mensaje).
##   S2 — Aristas en locked_edges nacen bloqueadas y se desbloquean con unlock_edge.
##   S3 — Idempotencia: un trigger no se dispara 2 veces en la misma partida.
##   S4 — reset_state() restaura triggered_nodes y vuelve a bloquear locked_edges.
##
## Invocación:
##     godot --headless res://tests/ataque/_test_node_triggers.tscn

const TUT2 := "res://juego/tutorial2/tut2_red.tres"

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _s1_trigger_efectos_basicos()
	await _s2_locked_edges_y_unlock()
	await _s3_idempotencia_trigger()
	await _s4_reset_state_restaura()
	_fin()


func _lanzar(triggers: Dictionary, locked: Array = []) -> Node:
	SceneParams.reset()
	SceneParams.graph_path = TUT2
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.max_ai_blocks = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 20
	SceneParams.max_movement_points = 50
	SceneParams.node_triggers = triggers
	SceneParams.locked_edges = locked
	SceneParams.pursuer_delay = 1
	SceneParams.pursuer_speed = 1
	SceneParams.max_pursuers = 4

	var scene = load("res://juego/ataque/escena_juego.tscn")
	var j = scene.instantiate()
	get_tree().root.add_child(j)
	await get_tree().process_frame
	await get_tree().process_frame
	if j.graph == null:
		print("FAIL: no cargo tut2")
		failed += 1
		return null
	for n in j.graph.nodes:
		if n != null:
			n.metadata["detection_chance"] = 0.0
	return j


func _s1_trigger_efectos_basicos() -> void:
	var triggers := {
		"Puerta_A": {
			"efectos": ["alert_network", "spawn_pursuer"],
			"mensaje": "ACCESO DETECTADO"
		}
	}
	var j := await _lanzar(triggers)
	if j == null:
		return

	_af(j.pursuers.size() == 0, "S1: inicia sin perseguidores")
	_af(j.alerted_nodes.is_empty(), "S1: inicia sin nodos alertados")

	j._mover_jugador(&"Puerta_A")

	_af(j.player_pos == &"Puerta_A", "S1: jugador se movió a Puerta_A")
	_af(j.alerted_nodes.has(&"Puerta_A"), "S1: alert_network agregó Puerta_A")
	_af(j.pursuers.size() == 1, "S1: spawn_pursuer creó un perseguidor")
	_af(j.mensaje_estado == "ACCESO DETECTADO", "S1: mensaje aplicado correctamente")

	j.queue_free()
	await get_tree().process_frame


func _s2_locked_edges_y_unlock() -> void:
	var triggers := {
		"Puerta_A": {
			"efectos": ["unlock_edge:Puerta_B→Target"],
			"mensaje": "PUERTA B DESBLOQUEADA"
		}
	}
	var locked := ["Puerta_B→Target"]
	var j := await _lanzar(triggers, locked)
	if j == null:
		return

	_af(j._is_blocked("Puerta_B→Target"), "S2: arista Puerta_B→Target inicia bloqueada")

	j._mover_jugador(&"Puerta_A")

	_af(not j._is_blocked("Puerta_B→Target"), "S2: trigger desbloqueó Puerta_B→Target")
	_af(j.mensaje_estado == "PUERTA B DESBLOQUEADA", "S2: mensaje de desbloqueo aplicado")

	j.queue_free()
	await get_tree().process_frame


func _s3_idempotencia_trigger() -> void:
	var triggers := {
		"Puerta_A": {
			"efectos": ["spawn_pursuer"],
			"mensaje": "TEST"
		}
	}
	var j := await _lanzar(triggers)
	if j == null:
		return

	j._mover_jugador(&"Puerta_A")
	_af(j.pursuers.size() == 1, "S3: primer ingreso spawnea 1 perseguidor")
	_af(j.triggered_nodes.has(&"Puerta_A"), "S3: Puerta_A registrado en triggered_nodes")

	# Simulamos re-visita interna
	j._game_logic._procesar_trigger_nodo(&"Puerta_A")
	_af(j.pursuers.size() == 1, "S3: re-procesar no duplica el spawn")

	j.queue_free()
	await get_tree().process_frame


func _s4_reset_state_restaura() -> void:
	var triggers := {
		"Puerta_A": {
			"efectos": ["unlock_edge:Puerta_B→Target"]
		}
	}
	var locked := ["Puerta_B→Target"]
	var j := await _lanzar(triggers, locked)
	if j == null:
		return

	j._mover_jugador(&"Puerta_A")
	_af(not j._is_blocked("Puerta_B→Target"), "S4: desbloqueada antes de reset")
	_af(j.triggered_nodes.has(&"Puerta_A"), "S4: triggered_nodes poblado")

	j._reset_state()

	_af(j._is_blocked("Puerta_B→Target"), "S4: locked_edge vuelve a bloquearse tras reset")
	_af(j.triggered_nodes.is_empty(), "S4: triggered_nodes limpio tras reset")

	j.queue_free()
	await get_tree().process_frame


func _af(cond: bool, msg: String) -> void:
	if cond:
		print("PASS: %s" % msg)
		passed += 1
	else:
		print("FAIL: %s" % msg)
		failed += 1


func _fin() -> void:
	print("\n---")
	print("Results: %d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)
