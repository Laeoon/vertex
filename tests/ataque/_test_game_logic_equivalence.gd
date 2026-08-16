extends Node

## Equivalence test (golden) para juego/ataque/game_logic.gd — etapa 3 del
## slice de descomposición. Congela el comportamiento PRE-migración de
## _mover_jugador(), _ganar(), _perder(), _vecinos_jugador(),
## _auto_select_vecino() y _cycle_neighbor().
##
## Determinismo: ai_enabled=false, detection_chance=0 en todos los nodos,
## grafo tut2_red (Inicio→{Puerta_A,Puerta_B}→Target). Patron replay+golden.

const CAPTURE := false

var passed: int = 0
var failed: int = 0
var _juego = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = [&"Puerta_B"]
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.max_ai_blocks = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 0
	SceneParams.max_movement_points = 0
	SceneParams.titulo_nivel = "GAME LOGIC GOLDEN"

	var scene = load("res://juego/ataque/escena_juego.tscn")
	_juego = scene.instantiate()
	get_tree().root.add_child(_juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if _juego.graph == null:
		print("FAIL: graph no cargo")
		failed += 1
		_finish()
		return

	for n in _juego.graph.nodes:
		if n != null:
			n.metadata["detection_chance"] = 0.0

	var snap: Array[String] = []
	_gs(snap, "boot")

	# ── S1: vecinos y auto-select ──
	snap.append("vecinos|%s" % str(_juego._vecinos_jugador()))
	snap.append("autosel|%s" % str(_juego.selected_neighbor))

	# ── S2: mover a bloqueado es no-op ──
	_juego._block_edge("Inicio→Puerta_A", &"Inicio", &"Puerta_A")
	snap.append("vecinos_bloq|%s" % str(_juego._vecinos_jugador()))
	_juego._mover_jugador(&"Puerta_A")
	_gs(snap, "mover_bloqueado")

	# ── S3: mover a Puerta_B = waypoint 0 alcanzado ──
	_juego._mover_jugador(&"Puerta_B")
	snap.append("waypoint|%s" % _juego.mensaje_estado)
	_gs(snap, "post_waypoint")

	# ── S4: mover a Target = victoria ──
	_juego._mover_jugador(&"Target")
	snap.append("win|over=%s|won=%s|%s" % [str(_juego.game_over), str(_juego.game_won), _juego.mensaje_estado])
	_gs(snap, "post_win")

	# ── S5: reset + cycle_neighbor ──
	_juego._unblock_edge("Inicio→Puerta_A")
	_juego.reset_state()
	_gs(snap, "reset")
	_juego._cycle_neighbor(1)
	snap.append("cyc1|%s" % str(_juego.selected_neighbor))
	_juego._cycle_neighbor(1)
	snap.append("cyc2|%s" % str(_juego.selected_neighbor))
	_juego._cycle_neighbor(-1)
	snap.append("cyc3|%s" % str(_juego.selected_neighbor))

	# ── S6: derrota por sin salida (Puerta_A→Target bloqueada) ──
	_juego._block_edge("Puerta_A→Target", &"Puerta_A", &"Target")
	_juego._mover_jugador(&"Puerta_A")
	snap.append("sin_salida|%s" % _juego.mensaje_estado)
	_gs(snap, "post_sin_salida")

	# ── S7: derrota por turnos máximos (sin waypoints: el branch waypoint
	# hace return temprano y saltearía el chequeo) ──
	_juego.waypoints = []
	_juego.max_turns = 1
	_juego.reset_state()
	_juego._mover_jugador(&"Puerta_B")
	snap.append("max_turnos|%s" % _juego.mensaje_estado)
	_gs(snap, "post_max_turnos")

	# ── S8: derrota por presupuesto de movimiento ──
	_juego.max_turns = 0
	_juego.waypoints = []
	_juego.max_movement_points = 1
	_juego.reset_state()
	_juego._mover_jugador(&"Puerta_B")
	snap.append("presupuesto|%s|mp=%d" % [_juego.mensaje_estado, _juego.movement_points])
	_gs(snap, "post_presupuesto")

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_finish()
		return

	var golden: Array[String] = [
		"boot|pos=Inicio|turn=0|wpi=0|cost=0.0|mp=0|over=false|won=false|sel=Puerta_A",
		"vecinos|[&\"Puerta_A\", &\"Puerta_B\"]",
		"autosel|Puerta_A",
		"vecinos_bloq|[&\"Puerta_B\"]",
		"mover_bloqueado|pos=Inicio|turn=0|wpi=0|cost=0.0|mp=0|over=false|won=false|sel=Puerta_A",
		"waypoint|Waypoint alcanzado! Ve hacia Target",
		"post_waypoint|pos=Puerta_B|turn=1|wpi=1|cost=1.0|mp=0|over=false|won=false|sel=Puerta_A",
		"win|over=true|won=true|GANASTE! Llegaste a Target en 2 turnos  ★★★",
		"post_win|pos=Target|turn=2|wpi=1|cost=6.0|mp=0|over=true|won=true|sel=Puerta_A",
		"reset|pos=Inicio|turn=0|wpi=0|cost=0.0|mp=0|over=false|won=false|sel=Puerta_A",
		"cyc1|Puerta_B",
		"cyc2|Puerta_A",
		"cyc3|Puerta_B",
		"sin_salida|PERDISTE: ¡Sin salida! No hay caminos accesibles desde Puerta_A",
		"post_sin_salida|pos=Puerta_A|turn=1|wpi=0|cost=1.0|mp=0|over=true|won=false|sel=Puerta_B",
		"max_turnos|PERDISTE: Te detectaron! (1 turnos maximo)",
		"post_max_turnos|pos=Puerta_B|turn=1|wpi=-1|cost=1.0|mp=0|over=true|won=false|sel=Puerta_B",
		"presupuesto|PERDISTE: ¡Sin presupuesto de movimiento!|mp=0",
		"post_presupuesto|pos=Inicio|turn=0|wpi=-1|cost=1.0|mp=0|over=true|won=false|sel=Puerta_B",
	]

	if snap.size() != golden.size():
		print("FAIL: tamaño snapshot %d != golden %d" % [snap.size(), golden.size()])
		failed += 1
	for i in snap.size():
		if snap[i] == golden[i]:
			print("PASS: %s" % golden[i])
			passed += 1
		else:
			print("FAIL: got='%s' want='%s'" % [snap[i], golden[i]])
			failed += 1

	_finish()


func _gs(snap: Array[String], tag: String) -> void:
	snap.append("%s|pos=%s|turn=%d|wpi=%d|cost=%.1f|mp=%d|over=%s|won=%s|sel=%s" % [
		tag, str(_juego.player_pos), _juego.turn, _juego.current_waypoint_idx,
		_juego.player_total_cost, _juego.movement_points,
		str(_juego.game_over), str(_juego.game_won), str(_juego.selected_neighbor)])


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
