extends Node

## Test Suite: Defense Tutorials
## Verifies that tut_defensa_1.json and tut_defensa_2.json exist,
## have valid tutorial structures, load in TutorialPlayer, and expose required actions.

const TutorialPlayerScene = preload("res://juego/tutorials/tutorial_player.tscn")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST DEFENSE TUTORIALS ---")
	test_tut_defensa_1_structure()
	test_tut_defensa_2_structure()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func test_tut_defensa_1_structure() -> void:
	var path := "res://juego/tutorials/data/tut_defensa_1.json"
	_assert(FileAccess.file_exists(path), "tut_defensa_1.json exists on disk")

	var tp_inst = TutorialPlayerScene.instantiate()
	add_child(tp_inst)
	var tp = tp_inst.get_node("Control")
	var loaded: bool = tp.load_tutorial(path)
	_assert(loaded, "tut_defensa_1 loads successfully into TutorialPlayer")
	_assert(tp.steps.size() >= 5, "tut_defensa_1 has at least 5 structured steps (got %d)" % tp.steps.size())

	# Verificar que al menos un paso requiere input de acción defensiva
	var has_input_action: bool = false
	for s in tp.steps:
		if s.get("action_required", "") == "input":
			has_input_action = true
			break
	_assert(has_input_action, "tut_defensa_1 contains an interactive input action step")
	tp_inst.queue_free()


func test_tut_defensa_2_structure() -> void:
	var path := "res://juego/tutorials/data/tut_defensa_2.json"
	_assert(FileAccess.file_exists(path), "tut_defensa_2.json exists on disk")

	var tp_inst = TutorialPlayerScene.instantiate()
	add_child(tp_inst)
	var tp = tp_inst.get_node("Control")
	var loaded: bool = tp.load_tutorial(path)
	_assert(loaded, "tut_defensa_2 loads successfully into TutorialPlayer")
	_assert(tp.steps.size() >= 5, "tut_defensa_2 has at least 5 structured steps (got %d)" % tp.steps.size())
	tp_inst.queue_free()
