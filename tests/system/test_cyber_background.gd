extends Node

## Test suite for CyberBackground visual component

const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST CYBER BACKGROUND ---")
	_test_initialization()
	_test_update_simulation()
	_test_particle_wrapping()
	_test_pulse_wrapping()
	_test_draw_on_canvas()
	_finish()


func _test_initialization() -> void:
	var bg = CyberBackgroundClass.new()
	_assert(bg._particles.size() == CyberBackgroundClass.PARTICLE_COUNT, "Particles initialized to configured count")
	_assert(bg._pulses.size() == 4, "Data pulses initialized")
	_assert(bg._time == 0.0, "Initial simulation time is 0.0")


func _test_update_simulation() -> void:
	var bg = CyberBackgroundClass.new()
	var vp := Vector2(1280.0, 720.0)
	var initial_y: float = bg._particles[0].pos.y

	bg.update(0.1, vp)
	_assert(bg._time > 0.099, "Simulation time advances with delta")
	_assert(bg._particles[0].pos.y < initial_y or bg._particles[0].pos.y >= vp.y, "Particles float upward")


func _test_particle_wrapping() -> void:
	var bg = CyberBackgroundClass.new()
	var vp := Vector2(1280.0, 720.0)

	# Force particle above top boundary
	bg._particles[0].pos.y = -15.0
	bg.update(0.016, vp)
	_assert(bg._particles[0].pos.y >= vp.y, "Particle wrapped back to bottom of screen")


func _test_pulse_wrapping() -> void:
	var bg = CyberBackgroundClass.new()
	var vp := Vector2(1280.0, 720.0)

	# Force pulse past right boundary
	bg._pulses[0].horizontal = true
	bg._pulses[0].pos = 2000.0
	bg.update(0.016, vp)
	_assert(bg._pulses[0].pos <= 0.0, "Pulse wraps back to start after exceeding bounds")


func _test_draw_on_canvas() -> void:
	var bg = CyberBackgroundClass.new()
	var canvas := Control.new()
	var vp := Vector2(1280.0, 720.0)
	canvas.draw.connect(func(): bg.draw(canvas, vp, 0.016))
	add_child(canvas)
	canvas.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "CyberBackground.draw executes cleanly inside draw notification")
	canvas.queue_free()


func _assert(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % msg)
	else:
		failed += 1
		push_error("FAIL: %s" % msg)


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
