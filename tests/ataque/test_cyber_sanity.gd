extends Node

## Smoke test del modo CYBER (Defensa en Capas): bootea escena_juego.tscn
## con los parámetros de juego/cyber/cyber_n1.json y verifica el arranque
## sin crash y el estado esperado. Scene-based: SceneParams es autoload.
## Nota: cyber comparte mecánica defender_mode con defense; lo distintivo
## es su grafo, budget de bloqueos (3/turno, 5 de duración) y nodos.

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	SceneParams.graph_path = "res://juego/cyber/cyber_n1.tres"
	SceneParams.start_node = &"Defensor"
	SceneParams.target_node = &"Database"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_ai_blocks = 12
	SceneParams.max_turns = 18
	SceneParams.titulo_nivel = "CYBER SANITY TEST"
	SceneParams.defender_mode = true
	SceneParams.defender_blocks_per_turn = 3
	SceneParams.defender_block_duration = 5
	SceneParams.enemy_start_node = &"Internet"
	SceneParams.enemy_target_node = &"Database"

	var scene = load("res://juego/ataque/escena_juego.tscn")
	var inst = scene.instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	await get_tree().process_frame

	if inst.graph == null:
		print("FAIL: graph no cargo (cyber_n1.tres)")
		failed += 1
		_quit()
		return
	print("PASS: grafo cyber_n1 cargó sin crash")
	passed += 1

	if not inst.defender_mode:
		print("FAIL: defender_mode no quedó activo")
		failed += 1
	else:
		print("PASS: defender_mode activo (defensa en capas)")
		passed += 1

	if inst.defender_blocks_per_turn != 3 or inst.defender_block_duration != 5:
		print("FAIL: budget defensor incorrecto: %d/turno, dur %d" % [
			inst.defender_blocks_per_turn, inst.defender_block_duration])
		failed += 1
	else:
		print("PASS: budget defensor cyber: 3 bloqueos/turno, duración 5")
		passed += 1

	# Fix defensor (Enmienda A): player_pos respeta el start_node real del
	# JSON ("Defensor", nodo existente en cyber_n1.tres); el sentinel
	# &"DEFENSOR" fue eliminado de reset_state().
	if inst.player_pos != &"Defensor":
		print("FAIL: player_pos != Defensor (start_node real): %s" % inst.player_pos)
		failed += 1
	elif inst.enemy_start_node != &"Internet" or inst.enemy_target_node != &"Database":
		print("FAIL: enemigo mal configurado: %s → %s" % [inst.enemy_start_node, inst.enemy_target_node])
		failed += 1
	elif inst.max_turns != 18:
		print("FAIL: max_turns != 18: %d" % inst.max_turns)
		failed += 1
	else:
		print("PASS: estado inicial: defensor en Defensor, enemigo Internet→Database, 18 turnos")
		passed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
