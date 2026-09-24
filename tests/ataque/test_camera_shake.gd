extends Node

## Test suite for Camera2D trauma-based screen shake (juice-screen-shake)

const JuegoAtaqueClass = preload("res://juego/ataque/juego_ataque.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST CAMERA SHAKE ---")
	_test_trauma_accumulation_and_clamp()
	_test_trauma_linear_decay()
	_test_zero_trauma_resets_offset()
	_finish()


func _test_trauma_accumulation_and_clamp() -> void:
	var game = JuegoAtaqueClass.new()
	add_child(game)

	_assert(game._trauma == 0.0, "Initial trauma is 0.0")

	game.add_trauma(0.25)
	_assert(is_equal_approx(game._trauma, 0.25), "add_trauma(0.25) sets trauma to 0.25")

	game.add_trauma(0.45)
	_assert(is_equal_approx(game._trauma, 0.70), "add_trauma(0.45) accumulates to 0.70")

	game.add_trauma(0.80)
	_assert(is_equal_approx(game._trauma, 1.0), "add_trauma clamps at maximum 1.0")

	game.queue_free()


func _test_trauma_linear_decay() -> void:
	var game = JuegoAtaqueClass.new()
	add_child(game)

	game._trauma = 1.0
	# TRAUMA_DECAY is 1.8/sec. For delta 0.25s, expected drop is 0.45 -> remaining 0.55
	game._process_camera_shake(0.25)
	_assert(is_equal_approx(game._trauma, 0.55), "Trauma decays by decay * delta (1.0 -> 0.55)")

	# Further delta 0.5s -> expected drop 0.90 -> clamped to 0.0
	game._process_camera_shake(0.5)
	_assert(game._trauma == 0.0, "Trauma clamps cleanly at 0.0 without going negative")

	game.queue_free()


func _test_zero_trauma_resets_offset() -> void:
	var game = JuegoAtaqueClass.new()
	add_child(game)

	_assert(game._camera != null, "Camera2D node initialized in JuegoAtaque")
	_assert(game._camera.offset == Vector2.ZERO, "Camera offset is Vector2.ZERO at rest")

	# Decay to zero
	game._trauma = 0.1
	game._process_camera_shake(0.2)
	_assert(game._camera.offset == Vector2.ZERO, "Camera offset remains Vector2.ZERO after trauma reaches zero")

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
