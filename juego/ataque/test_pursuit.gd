extends Node

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.titulo_nivel = "PURSUIT TEST"

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

	# TEST 1: Capture when arriving at pursuer's node
	inst.pursuers.append({
		"id": 1,
		"pos": &"Puerta_A",
		"delay": 0,
		"speed": 1,
		"active": true
	})
	inst._mover_jugador(&"Puerta_A")
	inst._process_pursuers()
	await get_tree().process_frame

	if inst.game_over and not inst.game_won:
		print("PASS: captura al llegar a nodo del perseguidor")
		passed += 1
	else:
		print("FAIL: no capturo al llegar (game_over=%s)" % inst.game_over)
		failed += 1

	# TEST 2: Pursuer chases from start node (1-step path)
	inst.reset_state()
	await get_tree().process_frame
	if inst.game_over or inst.graph == null:
		print("FAIL: reset_state no funciono")
		failed += 1
		_quit()
		return

	inst.pursuers.append({
		"id": 2,
		"pos": &"Inicio",
		"delay": 0,
		"speed": 1,
		"active": true
	})

	# Player at Inicio, pursuer at Inicio.
	# Move to Puerta_A -> pursuer follows along Inicio→Puerta_A (1 step) -> capture
	inst._mover_jugador(&"Puerta_A")
	inst._process_pursuers()
	await get_tree().process_frame

	if inst.game_over and not inst.game_won:
		print("PASS: perseguidor persigue y captura (Inicio→Puerta_A)")
		passed += 1
	else:
		print("FAIL: perseguidor no persiguio (p=%s game_over=%s)" % [inst.pursuers[0]["pos"] if inst.pursuers.size() > 0 else "none", inst.game_over])
		failed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
