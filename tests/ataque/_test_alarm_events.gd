extends Node

## Test de la Escalada de Alarma (E1): eventos por turno del JSON del nivel.
##   1. Disparo por turno: pursuer_speed_up en t1, spawn_pursuer + ai_extra_block
##      en t2, evento lejano (t50) NO dispara, efecto desconocido se descarta.
##   2. reset_state(): la cola se re-arma completa y los valores escalables
##      (pursuer_speed / max_ai_blocks) vuelven a su base — replay determinista.
##
## Invocación:
##     godot --headless res://tests/ataque/_test_alarm_events.tscn

var passed: int = 0
var failed: int = 0
var juego = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SceneParams.reset()
	# Grafo limpio (sin detección orgánica) para asserts deterministas:
	# Inicio ↔ Puerta_A ↔ Puerta_B → Target. Alternando Inicio/Puerta_A
	# nunca se gana y ningún nodo dispara perseguidores por sí solo.
	SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.max_turns = 30
	SceneParams.max_movement_points = 60
	SceneParams.pursuer_delay = 1
	SceneParams.max_pursuers = 4
	SceneParams.pursuer_speed = 1
	SceneParams.max_ai_blocks = 3
	SceneParams.eventos_alarma = [
		{"turno": 1, "efecto": "pursuer_speed_up"},
		{"turno": 2, "efecto": "spawn_pursuer"},
		{"turno": 2, "efecto": "ai_extra_block"},
		{"turno": 50, "efecto": "spawn_pursuer"},
		{"turno": 1, "efecto": "efecto_inexistente"},
	]
	SceneParams.titulo_nivel = "ALARM EVENTS TEST"
	SceneParams.level_key = "heist_n1"

	juego = load("res://juego/ataque/escena_juego.tscn").instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame
	await get_tree().process_frame
	if juego.graph == null:
		print("FAIL: graph no cargo")
		failed += 1
		_fin()
		return

	var base_speed: int = juego.pursuer_speed
	var base_blocks: int = juego.max_ai_blocks
	_af(base_speed == 1 and base_blocks == 3 and juego.pursuers.is_empty(),
		"base: speed=1, max_ai_blocks=3, sin perseguidores")
	_af(juego._eventos_pendientes.size() == 5,
		"cola de eventos armada con los 5 del JSON")

	# ── Turno 1: speed_up dispara; desconocido se descarta ──
	_mover()
	_af(juego.turn == 1, "turno avanzó a 1")
	_af(juego.pursuer_speed == base_speed + 1,
		"t1: pursuer_speed escaló (+1)")
	_af(juego._eventos_pendientes.size() == 3,
		"t1: cola consumió 2 (speed_up disparado, desconocido descartado)")
	_af(String(juego.mensaje_estado).contains("ALARMA"),
		"t1: HUD anuncia la alarma")

	# ── Turno 2: spawn + ai_extra_block juntos ──
	_mover()
	_af(juego.pursuers.size() == 1, "t2: spawn_pursuer agregó un perseguidor")
	_af(juego.max_ai_blocks == base_blocks + 1,
		"t2: ai_extra_block (+1)")
	_af(juego._eventos_pendientes.size() == 1,
		"t2: queda solo el evento lejano (t50)")

	# El evento t50 no dispara aunque siga moviéndose:
	_mover()
	_af(juego.pursuers.size() == 1, "t3: el evento lejano sigue dormido")

	# ── reset_state: replay determinista ──
	juego.reset_state()
	_af(juego._eventos_pendientes.size() == 5,
		"reset: cola re-armada completa")
	_af(juego.pursuer_speed == base_speed and juego.max_ai_blocks == base_blocks,
		"reset: valores escalables vuelven a la base (sin acumulación)")
	_af(juego.pursuers.is_empty(), "reset: perseguidores limpiados")

	# Re-fuego tras reset funciona igual que la primera vez:
	_mover()
	_af(juego.pursuer_speed == base_speed + 1,
		"post-reset t1: la escalada vuelve a disparar desde cero")

	juego.queue_free()
	_fin()


## Un movimiento legal hacia un vecino que NO sea el target actual.
func _mover() -> void:
	var vecinos: Array = juego._vecinos_jugador()
	var destino: StringName = &""
	for v in vecinos:
		if v != juego._target_actual():
			destino = v
			break
	if destino == &"":
		destino = vecinos[0]
	juego._mover_jugador(destino)


func _af(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _fin() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
