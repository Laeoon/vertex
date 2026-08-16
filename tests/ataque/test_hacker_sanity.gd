extends Node

## Smoke test del modo HACKER: bootea escena_juego.tscn con los parámetros
## de juego/hacker/hacker_n1.json (cargados por LevelManager en producción)
## y verifica que el modo inicia sin crash y expone su estado esperado.
## Scene-based: SceneParams es autoload (ver test_level_manager.tscn).

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
	SceneParams.start_node = &"DMZ"
	SceneParams.target_node = &"Core"
	SceneParams.waypoints = [&"WebServer", &"AdminPanel"]
	SceneParams.ai_enabled = true
	SceneParams.ai_block_per_turn = 1
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_ai_blocks = 5
	SceneParams.max_turns = 18
	SceneParams.titulo_nivel = "HACKER SANITY TEST"
	SceneParams.hacker_mode = true
	SceneParams.starting_exploits = {"bypass": 2, "escalate": 1, "persist": 1}

	var scene = load("res://juego/ataque/escena_juego.tscn")
	var inst = scene.instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame

	if inst.graph == null:
		print("FAIL: graph no cargo (hacker_n1.tres)")
		failed += 1
		_quit()
		return
	print("PASS: grafo hacker_n1 cargó sin crash")
	passed += 1

	if not inst.hacker_mode:
		print("FAIL: hacker_mode no quedó activo")
		failed += 1
	else:
		print("PASS: hacker_mode activo")
		passed += 1

	var hs: Dictionary = inst.hacker_state
	var exploits_ok: bool = hs.get("exploits", {}) == {"bypass": 2, "escalate": 1, "persist": 1}
	if exploits_ok and hs.get("noise", -1) == 0 and hs.get("exploits_used", -1) == 0:
		print("PASS: hacker_state inicializa con starting_exploits, ruido 0")
		passed += 1
	else:
		print("FAIL: hacker_state incorrecto: %s" % str(hs.get("exploits")))
		failed += 1

	if inst.player_pos != &"DMZ":
		print("FAIL: player_pos != DMZ: %s" % inst.player_pos)
		failed += 1
	elif inst._target_actual() != &"WebServer":
		print("FAIL: primer waypoint no es WebServer: %s" % inst._target_actual())
		failed += 1
	elif inst.turn != 0:
		print("FAIL: turn inicial != 0: %d" % inst.turn)
		failed += 1
	else:
		print("PASS: estado inicial: en DMZ, target WebServer, turn 0")
		passed += 1

	if inst.max_turns != 18:
		print("FAIL: max_turns != 18: %d" % inst.max_turns)
		failed += 1
	else:
		print("PASS: max_turns = 18")
		passed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
