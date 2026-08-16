extends Node

## Smoke test del modo DEFENSA: bootea escena_juego.tscn con los parámetros
## de juego/defense/defense_n1.json y verifica que el modo inicia sin crash
## y expone su estado esperado (defensor en Internet, enemigo hacia
## DataCenter). Scene-based: SceneParams es autoload.

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	SceneParams.graph_path = "res://juego/defense/defense_n1.tres"
	SceneParams.start_node = &"Internet"
	SceneParams.target_node = &"DataCenter"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_ai_blocks = 0
	SceneParams.max_turns = 12
	SceneParams.titulo_nivel = "DEFENSE SANITY TEST"
	SceneParams.defender_mode = true
	SceneParams.defender_blocks_per_turn = 2
	SceneParams.defender_block_duration = 4
	SceneParams.enemy_start_node = &"Internet"
	SceneParams.enemy_target_node = &"DataCenter"

	var scene = load("res://juego/ataque/escena_juego.tscn")
	var inst = scene.instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame

	if inst.graph == null:
		print("FAIL: graph no cargo (defense_n1.tres)")
		failed += 1
		_quit()
		return
	print("PASS: grafo defense_n1 cargó sin crash")
	passed += 1

	if not inst.defender_mode:
		print("FAIL: defender_mode no quedó activo")
		failed += 1
	else:
		print("PASS: defender_mode activo")
		passed += 1

	if inst.enemy_start_node != &"Internet" or inst.enemy_target_node != &"DataCenter":
		print("FAIL: enemigo mal configurado: %s → %s" % [inst.enemy_start_node, inst.enemy_target_node])
		failed += 1
	elif inst.enemy_pos != &"Internet":
		print("FAIL: enemy_pos != Internet: %s" % inst.enemy_pos)
		failed += 1
	else:
		print("PASS: enemigo inicia en Internet rumbo a DataCenter")
		passed += 1

	# Fix defensor (Enmienda A): player_pos respeta el start_node real del
	# JSON (Internet); el sentinel &"DEFENSOR" fue eliminado de reset_state().
	if inst.player_pos != &"Internet":
		print("FAIL: player_pos != Internet (start_node real): %s" % inst.player_pos)
		failed += 1
	elif inst.turn != 0:
		print("FAIL: turn inicial != 0: %d" % inst.turn)
		failed += 1
	elif inst.game_over:
		print("FAIL: arranca en game_over")
		failed += 1
	else:
		print("PASS: estado inicial: defensor en Internet (start_node real), turn 0, juego activo")
		passed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
