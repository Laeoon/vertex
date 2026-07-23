extends Node

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# Setup a quick scenario with guaranteed detection
	# Use a simplified graph where one node has 100% detection
	SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = true
	SceneParams.ai_block_per_turn = 1
	SceneParams.max_ai_blocks = 1
	SceneParams.ai_bloquea_al_inicio = true
	SceneParams.titulo_nivel = "DETECTION TEST"
	SceneParams.mensaje_tutorial = "test"

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

	# Manually force detection_chance on Puerta_B to 1.0 to guarantee detection
	var node_pb = inst._find_node_resource(&"Puerta_B")
	if node_pb == null:
		print("FAIL: node Puerta_B not found")
		failed += 1
		_quit()
		return
	node_pb.metadata["detection_chance"] = 1.0

	# Move to Puerta_B (which should trigger detection guaranteed)
	var vecinos = inst._vecinos_jugador()
	if vecinos.size() == 0:
		print("FAIL: sin vecinos al inicio")
		failed += 1
		_quit()
		return

	# Puerta_B should be available (IA blocked Puerta_A)
	if not (&"Puerta_B" in vecinos):
		print("FAIL: Puerta_B no es vecino")
		failed += 1
		_quit()
		return

	# Move to Puerta_B
	inst._mover_jugador(&"Puerta_B")
	await get_tree().process_frame

	# Check detection triggered
	if inst.alerted_nodes.size() != 1:
		print("FAIL: no se alerto el nodo (alerted=%d)" % inst.alerted_nodes.size())
		failed += 1
	else:
		if inst.alerted_nodes[0] != &"Puerta_B":
			print("FAIL: nodo alertado incorrecto: %s" % inst.alerted_nodes[0])
			failed += 1
		else:
			print("PASS: nodo alertado correctamente: Puerta_B")
			passed += 1

	# Check pursuer spawned
	if inst.pursuers.size() != 1:
		print("FAIL: no se creo perseguidor (pursuers=%d)" % inst.pursuers.size())
		failed += 1
	else:
		var p = inst.pursuers[0]
		if p["delay"] <= 0:
			print("FAIL: delay deberia ser >0: %d" % p["delay"])
			failed += 1
		elif p["pos"] != &"Puerta_B":
			print("FAIL: perseguidor spawn inesperado: %s" % p["pos"])
			failed += 1
		else:
			print("PASS: perseguidor creado en Puerta_B con delay=%d" % p["delay"])
			passed += 1

	# Check reset clears pursuers
	inst.reset_state()
	await get_tree().process_frame
	if inst.alerted_nodes.size() != 0:
		print("FAIL: alerted_nodes no se limpio tras reset")
		failed += 1
	elif inst.pursuers.size() != 0:
		print("FAIL: pursuers no se limpio tras reset")
		failed += 1
	else:
		print("PASS: reset_state limpia deteccion/perseguidores")
		passed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
