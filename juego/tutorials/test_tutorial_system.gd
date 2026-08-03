extends Node

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- TUTORIAL SYSTEM TEST ---")

	var tutorial_scene = preload("res://juego/tutorials/tutorial_player.tscn")
	var tutorial_root = tutorial_scene.instantiate()
	get_tree().root.add_child(tutorial_root)
	var tp = tutorial_root.get_node("Control")
	await get_tree().process_frame

	# TEST 1: JSON loads
	var loaded: bool = tp.load_tutorial("res://juego/tutorials/data/tut1_movimiento.json")
	if loaded and tp.steps.size() == 8:
		print("PASS: tutorial JSON carga (8 pasos)")
		passed += 1
	else:
		print("FAIL: tutorial JSON no cargo (loaded=%s steps=%d)" % [loaded, tp.steps.size()])
		failed += 1

	# TEST 2: Start at step 0
	tp.start()
	if tp.is_active and tp.current_step_index == 0:
		print("PASS: inicia en paso 0")
		passed += 1
	else:
		print("FAIL: no inicio (active=%s step=%d)" % [tp.is_active, tp.current_step_index])
		failed += 1

	# TEST 3: Step data correct
	var step0: Dictionary = tp.steps[0]
	if step0.get("id", "") == "intro" and step0.get("pause_game", false) == true:
		print("PASS: paso 0 correcto (id=intro)")
		passed += 1
	else:
		print("FAIL: paso 0 datos: %s" % str(step0))
		failed += 1

	# TEST 4: Advance works (step 0 has no action_required)
	tp.advance()
	if tp.current_step_index == 1:
		print("PASS: advance() → paso 1")
		passed += 1
	else:
		print("FAIL: advance() fallo (step=%d)" % tp.current_step_index)
		failed += 1

	# TEST 5: Step 1 has pause
	if tp.is_game_paused():
		print("PASS: is_game_paused()=true en paso 1")
		passed += 1
	else:
		print("FAIL: is_game_paused()=false en paso 1")
		failed += 1

	# TEST 6: Step 3 has action_required="move"
	var step3: Dictionary = tp.steps[3]
	if step3.get("action_required", "") == "move":
		print("PASS: paso 3 tiene action_required=move")
		passed += 1
	else:
		print("FAIL: paso 3 action_required=%s" % step3.get("action_required"))
		failed += 1

	# TEST 7: Advance to step 2 (step 1 has no action_required)
	tp.advance()
	if tp.current_step_index == 2:
		print("PASS: advance() → paso 2")
		passed += 1
	else:
		print("FAIL: advance() a paso 2 fallo (step=%d)" % tp.current_step_index)
		failed += 1

	# Advance through step 2 (move_basics, no action_required) to step 3
	tp.advance()

	# TEST 8: Action required blocks advance at step 3 + can_perform_action
	# restringe a la acción requerida (Slice 3.8 v2)
	tp.advance()
	if tp.current_step_index == 3 and tp._waiting_for_action:
		print("PASS: action_required bloquea advance")
		passed += 1
	else:
		print("FAIL: no bloqueo (step=%d wait=%s)" % [tp.current_step_index, tp._waiting_for_action])
		failed += 1

	# TEST 9: can_perform_action permite SOLO la acción requerida
	if tp.can_perform_action("move") and not tp.can_perform_action("input") and not tp.can_perform_action("scan"):
		print("PASS: can_perform_action restringe a la acción requerida")
		passed += 1
	else:
		print("FAIL: can_perform_action (move=%s input=%s scan=%s)" % [tp.can_perform_action("move"), tp.can_perform_action("input"), tp.can_perform_action("scan")])
		failed += 1

	# TEST 10: notify_action cumple SIN avanzar (espera confirmación con Enter)
	tp.notify_action("move")
	if tp._action_fulfilled and tp.current_step_index == 3:
		print("PASS: notify_action() cumple y espera confirmación [Enter]")
		passed += 1
	else:
		print("FAIL: notify_action() (step=%d fulfilled=%s)" % [tp.current_step_index, tp._action_fulfilled])
		failed += 1

	# TEST 11: advance() tras la acción cumplida avanza a paso 4
	tp.advance()
	if tp.current_step_index == 4:
		print("PASS: advance() avanza tras acción cumplida")
		passed += 1
	else:
		print("FAIL: advance() tras acción (step=%d)" % tp.current_step_index)
		failed += 1

	# TEST 12: Highlight nodes on step with highlights (step 4: after_first_move)
	var highlights: Array = tp.get_highlight_nodes()
	if highlights.size() == 2 and highlights[0] == "Relay" and highlights[1] == "Target":
		print("PASS: get_highlight_nodes() correcto")
		passed += 1
	else:
		print("FAIL: highlights: %s (step=%d)" % [str(highlights), tp.current_step_index])
		failed += 1

	# TEST 13: Skip
	tp.skip()
	if not tp.is_active and tp.current_step_index == -1:
		print("PASS: skip() desactiva")
		passed += 1
	else:
		print("FAIL: skip() (active=%s step=%d)" % [tp.is_active, tp.current_step_index])
		failed += 1

	# TEST 14: Load tut2
	var loaded2: bool = tp.load_tutorial("res://juego/tutorials/data/tut2_perimetro.json")
	if loaded2 and tp.steps.size() == 7:
		print("PASS: tut2 carga (7 pasos)")
		passed += 1
	else:
		print("FAIL: tut2 no cargo")
		failed += 1

	# TEST 15: Load tut3
	var loaded3: bool = tp.load_tutorial("res://juego/tutorials/data/tut3_avanzado.json")
	if loaded3 and tp.steps.size() == 9:
		print("PASS: tut3 carga (9 pasos)")
		passed += 1
	else:
		print("FAIL: tut3 no cargo")
		failed += 1

	# TEST 16: is_game_paused on active tutorial
	tp.start()
	if tp.is_game_paused():
		print("PASS: is_game_paused() en tut3")
		passed += 1
	else:
		print("FAIL: is_game_paused() fallo")
		failed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
