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
	SceneParams.titulo_nivel = "BLOCK DURATION TEST"

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

	# Manually block Inicio → Puerta_A
	var edge_key: String = "Inicio→Puerta_A"
	inst._block_edge(edge_key, &"Inicio", &"Puerta_A")

	if not inst._is_blocked(edge_key):
		print("FAIL: edge no bloqueado tras _block_edge")
		failed += 1
		_quit()
		return
	print("PASS: edge bloqueado correctamente")
	passed += 1

	# Verify the cost was set to INF in runtime
	var cost: float = inst.runtime.get_transit_cost(&"Inicio", &"Puerta_A")
	if cost != INF:
		print("FAIL: costo no es INF bloqueado: %.1f" % cost)
		failed += 1
		_quit()
		return

	# Check expires_at
	var data = inst.blocked_edges[edge_key]
	var expected_expiry: int = inst.turn + 3
	if data["expires_at"] != expected_expiry:
		print("FAIL: expires_at incorrecto: %d (esperado %d)" % [data["expires_at"], expected_expiry])
		failed += 1
		_quit()
		return
	print("PASS: expires_at=%d (turn=%d + 3)" % [data["expires_at"], inst.turn])
	passed += 1

	# Advance turns to just before expiry (turn=2, expires_at=3 → 2 < 3)
	for i in range(2):
		inst.turn += 1
	inst._limpiar_bloqueos_expirados()
	await get_tree().process_frame

	if not inst._is_blocked(edge_key):
		print("FAIL: bloqueo expiro antes de tiempo (turn=%d expires_at=%d)" % [inst.turn, data["expires_at"]])
		failed += 1
		_quit()
		return
	print("PASS: bloqueo aun activo en turno %d (expires %d)" % [inst.turn, data["expires_at"]])
	passed += 1

	# ONE more turn (now turn=3 >= expires_at=3) → expires
	inst.turn += 1
	inst._limpiar_bloqueos_expirados()
	await get_tree().process_frame

	if inst._is_blocked(edge_key):
		print("FAIL: bloqueo no expiro (turn=%d)" % inst.turn)
		failed += 1
		_quit()
		return
	print("PASS: bloqueo expirado en turno %d" % inst.turn)
	passed += 1

	# Verify cost restored
	var restored_cost: float = inst.runtime.get_transit_cost(&"Inicio", &"Puerta_A")
	if restored_cost == INF:
		print("FAIL: costo no restaurado tras expiracion (sigue INF)")
		failed += 1
	else:
		print("PASS: costo restaurado a %.1f" % restored_cost)
		passed += 1

	_quit()


func _quit() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
