extends Node

## Test suite for topology pan and zoom (QoL navigation)

const JuegoAtaqueClass = preload("res://juego/ataque/juego_ataque.gd")
const InputHandlerClass = preload("res://juego/ataque/input_handler.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _create_game() -> Node:
	var game = JuegoAtaqueClass.new()
	game.graph_path = "res://juego/tutorial2/tut2_red.tres"
	game.start_node = &"Inicio"
	game.target_node = &"Target"
	add_child(game)
	return game


func _run_tests() -> void:
	print("--- START TEST TOPOLOGY PAN ZOOM ---")
	_test_initial_pan_zoom_state()
	_test_zoom_clamping()
	_test_zoom_focal_point()
	_test_pan_by()
	_test_reset_pan_zoom()
	_test_input_handler_screen_to_world()
	_test_input_handler_mouse_wheel_and_drag()
	_test_reset_state_clears_pan_zoom()
	_finish()


func _test_initial_pan_zoom_state() -> void:
	var game = _create_game()
	_assert(game.topology_pan == Vector2.ZERO, "Initial topology_pan is Vector2.ZERO")
	_assert(is_equal_approx(game.topology_zoom, 1.0), "Initial topology_zoom is 1.0")
	game.queue_free()


func _test_zoom_clamping() -> void:
	var game = _create_game()
	for i in range(15):
		game.zoom_in(Vector2(640, 360))
	_assert(is_equal_approx(game.topology_zoom, 2.5), "Zoom in is clamped at ZOOM_MAX (2.5)")

	for i in range(30):
		game.zoom_out(Vector2(640, 360))
	_assert(is_equal_approx(game.topology_zoom, 0.5), "Zoom out is clamped at ZOOM_MIN (0.5)")
	game.queue_free()


func _test_zoom_focal_point() -> void:
	var game = _create_game()
	var focal_screen := Vector2(400, 300)
	var initial_world: Vector2 = (focal_screen - game.topology_pan) / game.topology_zoom

	game.zoom_in(focal_screen)
	var after_world: Vector2 = (focal_screen - game.topology_pan) / game.topology_zoom
	_assert(initial_world.is_equal_approx(after_world), "World position under mouse remains invariant after zoom_in")

	game.zoom_out(focal_screen)
	var after_out_world: Vector2 = (focal_screen - game.topology_pan) / game.topology_zoom
	_assert(initial_world.is_equal_approx(after_out_world), "World position under mouse remains invariant after zoom_out")
	game.queue_free()


func _test_pan_by() -> void:
	var game = _create_game()
	game.pan_by(Vector2(50, -30))
	_assert(game.topology_pan == Vector2(50, -30), "pan_by correctly shifts topology_pan")

	game.pan_by(Vector2(-20, 10))
	_assert(game.topology_pan == Vector2(30, -20), "Consecutive pan_by accumulates offset")
	game.queue_free()


func _test_reset_pan_zoom() -> void:
	var game = _create_game()
	game.pan_by(Vector2(100, 150))
	game.zoom_in(Vector2(100, 100))
	_assert(game.topology_pan != Vector2.ZERO, "Topology pan is modified")
	_assert(not is_equal_approx(game.topology_zoom, 1.0), "Topology zoom is modified")

	game.reset_pan_zoom()
	_assert(game.topology_pan == Vector2.ZERO, "reset_pan_zoom restores topology_pan to Vector2.ZERO")
	_assert(is_equal_approx(game.topology_zoom, 1.0), "reset_pan_zoom restores topology_zoom to 1.0")
	game.queue_free()


func _test_input_handler_screen_to_world() -> void:
	var game = _create_game()
	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = game

	var screen_pos := Vector2(300, 200)
	_assert(handler._screen_to_world(screen_pos) == screen_pos, "Identity mapping at default pan and zoom")

	game.topology_pan = Vector2(100, 50)
	game.topology_zoom = 2.0
	var expected_world := Vector2(100, 75)
	_assert(handler._screen_to_world(screen_pos).is_equal_approx(expected_world), "_screen_to_world transforms correctly with pan and zoom")

	handler.queue_free()
	game.queue_free()


func _test_input_handler_mouse_wheel_and_drag() -> void:
	var game = _create_game()
	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = game

	# Mouse wheel up
	var ev_wheel_up = InputEventMouseButton.new()
	ev_wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	ev_wheel_up.pressed = true
	ev_wheel_up.position = Vector2(500, 300)
	handler._input(ev_wheel_up)
	_assert(game.topology_zoom > 1.0, "MOUSE_BUTTON_WHEEL_UP triggers zoom_in")

	# Right-click press to start panning
	var ev_rmb_down = InputEventMouseButton.new()
	ev_rmb_down.button_index = MOUSE_BUTTON_RIGHT
	ev_rmb_down.pressed = true
	handler._input(ev_rmb_down)
	_assert(handler._is_panning == true, "Right mouse press enables _is_panning")

	# Motion during panning
	var ev_motion = InputEventMouseMotion.new()
	ev_motion.relative = Vector2(40, -25)
	handler._input(ev_motion)
	_assert(game.topology_pan.x != 0.0 or game.topology_pan.y != 0.0, "Mouse motion while panning shifts topology_pan")

	# Right-click release to end panning
	var ev_rmb_up = InputEventMouseButton.new()
	ev_rmb_up.button_index = MOUSE_BUTTON_RIGHT
	ev_rmb_up.pressed = false
	handler._input(ev_rmb_up)
	_assert(handler._is_panning == false, "Right mouse release disables _is_panning")

	# Key HOME resets pan and zoom
	var ev_home = InputEventKey.new()
	ev_home.keycode = KEY_HOME
	ev_home.pressed = true
	handler._input(ev_home)
	_assert(game.topology_pan == Vector2.ZERO, "KEY_HOME resets topology_pan")
	_assert(is_equal_approx(game.topology_zoom, 1.0), "KEY_HOME resets topology_zoom")

	handler.queue_free()
	game.queue_free()


func _test_reset_state_clears_pan_zoom() -> void:
	var game = _create_game()
	game.topology_pan = Vector2(250, 180)
	game.topology_zoom = 1.7
	game.reset_state()
	_assert(game.topology_pan == Vector2.ZERO, "reset_state clears topology_pan to Vector2.ZERO")
	_assert(is_equal_approx(game.topology_zoom, 1.0), "reset_state restores topology_zoom to 1.0")
	game.queue_free()


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
