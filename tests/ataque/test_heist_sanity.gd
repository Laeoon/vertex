extends Node

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	SceneParams.graph_path = "res://juego/nivel1/nivel1_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Boveda"
	SceneParams.waypoints = [&"Seguridad", &"Cajas"]
	SceneParams.ai_enabled = true
	SceneParams.ai_block_per_turn = 1
	SceneParams.max_ai_blocks = 6
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 14
	SceneParams.titulo_nivel = "HEIST SANITY TEST"

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

	# --- Verify Heist params ---
	if inst.start_node != &"Inicio":
		print("FAIL: start_node != Inicio: %s" % inst.start_node)
		failed += 1
	elif inst.target_node != &"Boveda":
		print("FAIL: target_node != Boveda: %s" % inst.target_node)
		failed += 1
	elif inst.waypoints.size() != 2 or inst.waypoints[0] != &"Seguridad" or inst.waypoints[1] != &"Cajas":
		print("FAIL: waypoints incorrectos: %s" % inst.waypoints)
		failed += 1
	elif inst.max_turns != 14:
		print("FAIL: max_turns != 14: %d" % inst.max_turns)
		failed += 1
	elif inst._target_actual() != &"Seguridad":
		print("FAIL: primer target no es Seguridad: %s" % inst._target_actual())
		failed += 1
	else:
		print("PASS: params Heist correctos")
		passed += 1

	# --- Verify detection_chance on key nodes ---
	var expected_detection: Dictionary = {
		&"Puerta": 0.08,
		&"RPA": 0.05,
		&"Seguridad": 0.15,
		&"CPD": 0.20,
		&"Cajas": 0.18,
		&"Sala": 0.12,
	}
	var det_ok: bool = true
	for nid in expected_detection.keys():
		var nr = inst._find_node_resource(nid)
		if nr == null:
			print("FAIL: nodo %s no encontrado en grafo" % nid)
			det_ok = false
			continue
		var dc: float = float(nr.metadata.get("detection_chance", 0.0))
		var expected: float = expected_detection[nid]
		if abs(dc - expected) > 0.001:
			print("FAIL: %s detection_chance=%.2f (esperado %.2f)" % [nid, dc, expected])
			det_ok = false
	if det_ok:
		print("PASS: detection_chance correctos en todos los nodos")
		passed += 1
	else:
		failed += 1

	# --- Verify has_firewall ---
	var fw_puerta = inst._find_node_resource(&"Puerta")
	var fw_seguridad = inst._find_node_resource(&"Seguridad")
	if fw_puerta == null or not fw_puerta.metadata.get("has_firewall", false):
		print("FAIL: Puerta deberia tener has_firewall=true")
		failed += 1
	elif fw_seguridad == null or not fw_seguridad.metadata.get("has_firewall", false):
		print("FAIL: Seguridad deberia tener has_firewall=true")
		failed += 1
	else:
		print("PASS: has_firewall en Puerta y Seguridad")
		passed += 1

	# --- Verify security_spawn ---
	var ss = inst._find_node_resource(&"Seguridad")
	if ss == null or not ss.metadata.get("security_spawn", false):
		print("FAIL: Seguridad deberia tener security_spawn=true")
		failed += 1
	else:
		print("PASS: security_spawn en Seguridad")
		passed += 1

	# --- Verify AI does NOT block at start (ai_bloquea_al_inicio=false) ---
	if inst._ai_blocks_used != 0:
		print("FAIL: IA bloqueo al inicio (ai_blocks_used=%d)" % inst._ai_blocks_used)
		failed += 1
	else:
		print("PASS: IA no bloquea al inicio")
		passed += 1

	# --- Move Inicio → Puerta (should work) ---
	var vecinos = inst._vecinos_jugador()
	if not (&"Puerta" in vecinos):
		print("FAIL: Puerta no es vecino de Inicio: %s" % vecinos)
		failed += 1
		_quit()
		return

	inst._mover_jugador(&"Puerta")
	await get_tree().process_frame

	if inst.player_pos != &"Puerta":
		print("FAIL: no se movio a Puerta: %s" % inst.player_pos)
		failed += 1
	elif inst.turn != 1:
		print("FAIL: turn no avanzo a 1: %d" % inst.turn)
		failed += 1
	else:
		print("PASS: Inicio → Puerta, turn=%d" % inst.turn)
		passed += 1

	# --- Move Puerta → Seguridad (first waypoint) ---
	vecinos = inst._vecinos_jugador()
	if not (&"Seguridad" in vecinos):
		print("FAIL: Seguridad no es vecino de Puerta: %s" % vecinos)
		failed += 1
		_quit()
		return

	inst._mover_jugador(&"Seguridad")
	await get_tree().process_frame

	if inst.player_pos != &"Seguridad":
		print("FAIL: no se movio a Seguridad: %s" % inst.player_pos)
		failed += 1
	elif inst.current_waypoint_idx != 1:
		print("FAIL: waypoint idx no avanzo: %d" % inst.current_waypoint_idx)
		failed += 1
	elif inst._target_actual() != &"Cajas":
		print("FAIL: siguiente target no es Cajas: %s" % inst._target_actual())
		failed += 1
	else:
		print("PASS: Puerta → Seguridad (waypoint 1), target→Cajas")
		passed += 1

	# --- Verify player_total_cost increments ---
	if inst.player_total_cost <= 0:
		print("FAIL: player_total_cost no se acumulo: %.1f" % inst.player_total_cost)
		failed += 1
	else:
		print("PASS: player_total_cost=%.1f" % inst.player_total_cost)
		passed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
