extends Node

## Unit tests for input schemes (HYBRID, KEYBOARD_ONLY, MOUSE_ONLY) and event filtering.

const InputHandlerClass = preload("res://juego/ataque/input_handler.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST INPUT SCHEMES ---")
	_test_scheme_constants_and_default()
	_test_scheme_switching()
	_test_mouse_only_suppression()
	_test_keyboard_only_suppression()
	_test_hybrid_mode()
	_finish()


func _test_scheme_constants_and_default() -> void:
	var handler = InputHandlerClass.new()
	add_child(handler)

	_assert(InputHandlerClass.Scheme.HYBRID == 0, "Scheme.HYBRID is 0")
	_assert(InputHandlerClass.Scheme.KEYBOARD_ONLY == 1, "Scheme.KEYBOARD_ONLY is 1")
	_assert(InputHandlerClass.Scheme.MOUSE_ONLY == 2, "Scheme.MOUSE_ONLY is 2")
	_assert(handler.get_input_scheme() == InputHandlerClass.Scheme.HYBRID, "Default scheme is HYBRID")

	handler.queue_free()


func _test_scheme_switching() -> void:
	var handler = InputHandlerClass.new()
	add_child(handler)

	handler.set_input_scheme(InputHandlerClass.Scheme.KEYBOARD_ONLY)
	_assert(handler.get_input_scheme() == InputHandlerClass.Scheme.KEYBOARD_ONLY, "Switched to KEYBOARD_ONLY")

	handler.set_input_scheme(InputHandlerClass.Scheme.MOUSE_ONLY)
	_assert(handler.get_input_scheme() == InputHandlerClass.Scheme.MOUSE_ONLY, "Switched to MOUSE_ONLY")

	handler.set_input_scheme(InputHandlerClass.Scheme.HYBRID)
	_assert(handler.get_input_scheme() == InputHandlerClass.Scheme.HYBRID, "Switched to HYBRID")

	handler.queue_free()


func _test_mouse_only_suppression() -> void:
	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.set_input_scheme(InputHandlerClass.Scheme.MOUSE_ONLY)

	var emitted: Array[String] = []

	handler.directional_neighbor_requested.connect(func(_dir): emitted.append("dir"))
	handler.pause_toggle_requested.connect(func(): emitted.append("pause"))

	# Traversal keys should be ignored
	for key in [KEY_UP, KEY_W, KEY_DOWN, KEY_S, KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D]:
		var ev = InputEventKey.new()
		ev.keycode = key
		ev.pressed = true
		handler._input(ev)

	_assert(not ("dir" in emitted), "MOUSE_ONLY ignores WASD and Arrow traversal keys")

	# System keys like ESCAPE should still work
	var esc_ev = InputEventKey.new()
	esc_ev.keycode = KEY_ESCAPE
	esc_ev.pressed = true
	handler._input(esc_ev)

	_assert("pause" in emitted, "MOUSE_ONLY permits KEY_ESCAPE for pause toggle")

	handler.queue_free()


func _test_keyboard_only_suppression() -> void:
	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.set_input_scheme(InputHandlerClass.Scheme.KEYBOARD_ONLY)

	var emitted: Array[String] = []

	handler.neighbor_hovered.connect(func(_nid): emitted.append("hover"))
	handler.move_requested.connect(func(_dest): emitted.append("click_move"))
	handler.directional_neighbor_requested.connect(func(_dir): emitted.append("dir"))

	# Mouse motion should be ignored
	var mm = InputEventMouseMotion.new()
	mm.position = Vector2(100, 100)
	handler._input(mm)
	_assert(not ("hover" in emitted), "KEYBOARD_ONLY suppresses mouse hover events")

	# Left mouse button click should be ignored
	var mb = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = Vector2(100, 100)
	handler._input(mb)
	_assert(not ("click_move" in emitted), "KEYBOARD_ONLY suppresses left mouse click movement")

	# Keyboard directional keys should work
	var key_ev = InputEventKey.new()
	key_ev.keycode = KEY_W
	key_ev.pressed = true
	handler._input(key_ev)
	_assert("dir" in emitted, "KEYBOARD_ONLY processes keyboard directional movement")

	handler.queue_free()


func _test_hybrid_mode() -> void:
	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.set_input_scheme(InputHandlerClass.Scheme.HYBRID)

	var emitted: Array[String] = []

	handler.directional_neighbor_requested.connect(func(_dir): emitted.append("dir"))
	handler.pause_toggle_requested.connect(func(): emitted.append("pause"))
	handler.restart_prompt_requested.connect(func(): emitted.append("restart"))

	# Keyboard directional works
	var key_ev = InputEventKey.new()
	key_ev.keycode = KEY_RIGHT
	key_ev.pressed = true
	handler._input(key_ev)
	_assert("dir" in emitted, "HYBRID processes directional key movement")

	# ESC key works
	var esc_ev = InputEventKey.new()
	esc_ev.keycode = KEY_ESCAPE
	esc_ev.pressed = true
	handler._input(esc_ev)
	_assert("pause" in emitted, "HYBRID processes KEY_ESCAPE")

	# R key works (restart prompt)
	var r_ev = InputEventKey.new()
	r_ev.keycode = KEY_R
	r_ev.pressed = true
	handler._input(r_ev)
	_assert("restart" in emitted, "HYBRID processes KEY_R for restart prompt")

	handler.queue_free()


func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("PASS: %s" % msg)
		passed += 1
	else:
		print("FAIL: %s" % msg)
		failed += 1


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
