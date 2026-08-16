extends Node

## Equivalence test (golden) para juego/ataque/game_state.gd — etapa 1 del
## slice de descomposición de juego_ataque.gd.
##
## Congela el comportamiento PRE-migración de: reset_state(), _target_actual(),
## _find_node_resource(), _is_blocked/_block_edge/_unblock_edge y
## _limpiar_bloqueos_expirados(). Corre como escena (autoloads: SceneParams,
## Events, GameLogger). Patrón idéntico a _test_ai_blocker_equivalence.gd:
## replay determinista + snapshot comparado contra golden hardcodeado
## (capturado con CAPTURE=true antes de migrar).
##
## Invocación:
##     godot --headless res://tests/ataque/_test_game_state_equivalence.tscn

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
	SceneParams.waypoints = [&"Puerta_A"]
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.max_ai_blocks = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 0
	SceneParams.max_movement_points = 0
	SceneParams.titulo_nivel = "GAME STATE GOLDEN"

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

	var snap: Array[String] = []

	# ── S1: estado tras reset inicial ──
	snap.append("reset|pos=%s|turn=%d|wpi=%d|over=%s|blocked=%d" % [
		_juego.player_pos, _juego.turn, _juego.current_waypoint_idx,
		_juego.game_over, _juego.blocked_edges.size()])

	# ── S2: _target_actual() según índice de waypoint ──
	for idx in [0, 1, 99, -1]:
		_juego.current_waypoint_idx = idx
		snap.append("target_actual[%d]|%s" % [idx, _juego._target_actual()])
	_juego.current_waypoint_idx = 0

	# ── S3: _find_node_resource ──
	var nr = _juego._find_node_resource(&"Inicio")
	snap.append("find|Inicio=%s|dn=%s" % [nr != null, nr.display_name if nr else "-"])
	snap.append("find|Puerta_B=%s" % (_juego._find_node_resource(&"Puerta_B") != null))
	snap.append("find|NoExiste=%s" % (_juego._find_node_resource(&"NoExiste") == null))

	# ── S4: ciclo block/unblock sobre Inicio→Puerta_A (costo original 1.0) ──
	var key := "Inicio→Puerta_A"
	snap.append("blk|pre=%s" % _juego._is_blocked(key))
	_juego._block_edge(key, &"Inicio", &"Puerta_A")
	var bdata: Dictionary = _juego.blocked_edges.get(key, {})
	snap.append("blk|post=%s|cost=%s|exp=%s|orig=%s" % [
		_juego._is_blocked(key),
		_juego.runtime.get_transit_cost(&"Inicio", &"Puerta_A"),
		bdata.get("expires_at", -1), bdata.get("orig_cost", -1)])
	_juego._unblock_edge(key)
	snap.append("unblk|is=%s|cost=%s" % [
		_juego._is_blocked(key),
		_juego.runtime.get_transit_cost(&"Inicio", &"Puerta_A")])

	# ── S5: expiración ──
	_juego._block_edge(key, &"Inicio", &"Puerta_A")
	_juego.blocked_edges[key]["expires_at"] = 0  # ya vencido (turn=0)
	_juego._limpiar_bloqueos_expirados()
	snap.append("expira|size=%d|is=%s|cost=%s" % [
		_juego.blocked_edges.size(), _juego._is_blocked(key),
		_juego.runtime.get_transit_cost(&"Inicio", &"Puerta_A")])

	# ── S6: block de arista inexistente es no-op ──
	_juego._block_edge("Inicio→Target", &"Inicio", &"Target")
	snap.append("noedge|size=%d" % _juego.blocked_edges.size())

	# ── S7: reset_state() restaura tras mutaciones ──
	_juego.turn = 7
	_juego.player_pos = &"Puerta_B"
	_juego.game_over = true
	_juego._block_edge(key, &"Inicio", &"Puerta_A")
	_juego.reset_state()
	snap.append("reset2|pos=%s|turn=%d|wpi=%d|over=%s|blocked=%d" % [
		_juego.player_pos, _juego.turn, _juego.current_waypoint_idx,
		_juego.game_over, _juego.blocked_edges.size()])

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_finish()
		return

	var golden: Array[String] = [
		"reset|pos=Inicio|turn=0|wpi=0|over=false|blocked=0",
		"target_actual[0]|Puerta_A",
		"target_actual[1]|Target",
		"target_actual[99]|Target",
		"target_actual[-1]|Target",
		"find|Inicio=true|dn=Inicio",
		"find|Puerta_B=true",
		"find|NoExiste=true",
		"blk|pre=false",
		"blk|post=true|cost=inf|exp=3|orig=1.0",
		"unblk|is=false|cost=1.0",
		"expira|size=0|is=false|cost=1.0",
		"noedge|size=0",
		"reset2|pos=Inicio|turn=0|wpi=0|over=false|blocked=0",
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


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
