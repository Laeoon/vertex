extends Node

## Equivalence test (golden) del flujo del modo defensor — fix "Enmienda A".
##
## Congela las invariantes del fix defensor sobre juego/ataque/game_state.gd
## (reset_state) y juego_ataque.gd (_on_move_requested):
##   1. player_pos respeta el start_node real del JSON (adiós sentinel
##      &"DEFENSOR").
##   2. _ai_blocker.initial_block() se saltea en modo defensor: NINGÚN
##      bloqueo inicial (para ejercitar el skip, este test arranca con
##      ai_enabled=true y ai_bloquea_al_inicio=true — sin el fix, la IA
##      bloquearía una arista al inicio del nivel).
##   3. El defensor NO se mueve: _on_move_requested hacia vecinos reales
##      es un no-op (player_pos y turn no cambian).
##   4. El turno avanza por la vía del defensor (bloquear + resolver) y el
##      juego sigue activo, con player_pos clavado en el start_node.
##
## Corre como escena (autoloads: SceneParams, Events, GameLogger). Patrón
## idéntico a _test_game_state_equivalence.gd: replay determinista + snapshot
## comparado contra golden hardcodeado (capturado con CAPTURE=true).
##
## Invocación:
##     godot --headless res://tests/ataque/_test_defender_flow_equivalence.tscn

const CAPTURE := false

var passed: int = 0
var failed: int = 0
var _juego = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# defense_n1.json, con la IA de bloqueo ACTIVADA para ejercitar el skip
	# del bloqueo inicial en modo defensor (parte 3 del fix).
	SceneParams.graph_path = "res://juego/defense/defense_n1.tres"
	SceneParams.start_node = &"Internet"
	SceneParams.target_node = &"DataCenter"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = true
	SceneParams.ai_block_per_turn = 1
	SceneParams.ai_bloquea_al_inicio = true
	SceneParams.max_ai_blocks = 999
	SceneParams.max_turns = 12
	SceneParams.max_movement_points = 0
	SceneParams.titulo_nivel = "DEFENDER FLOW GOLDEN"
	SceneParams.defender_mode = true
	SceneParams.defender_blocks_per_turn = 2
	SceneParams.defender_block_duration = 4
	SceneParams.enemy_start_node = &"Internet"
	SceneParams.enemy_target_node = &"DataCenter"

	var scene = load("res://juego/ataque/escena_juego.tscn")
	_juego = scene.instantiate()
	get_tree().root.add_child(_juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if _juego.graph == null or not _juego.defender_mode:
		print("FAIL: escena no booteó en modo defensor")
		failed += 1
		_finish()
		return

	var snap: Array[String] = []

	# ── S1: player_pos arranca en el start_node real del JSON ──
	snap.append("pos_inicial|pos=%s|turn=%d" % [_juego.player_pos, _juego.turn])

	# ── S2: sin bloqueo inicial de la IA (skip en modo defensor) ──
	snap.append("sin_bloqueo_inicial|blocked=%d|ai_used=%d" % [
		_juego.blocked_edges.size(), _juego._ai_blocks_used])

	# ── S3/S4: intentos de movimiento hacia vecinos reales son no-op ──
	_juego._on_move_requested(&"FirewallExt")
	snap.append("no_move_FirewallExt|pos=%s|turn=%d|over=%s" % [
		_juego.player_pos, _juego.turn, _juego.game_over])
	_juego._on_move_requested(&"Proxy")
	snap.append("no_move_Proxy|pos=%s|turn=%d|over=%s" % [
		_juego.player_pos, _juego.turn, _juego.game_over])

	# ── S5: bloqueo deliberado del defensor (fuera de la ruta enemigo) ──
	_juego._on_defender_block_edge("Internet→Proxy")
	snap.append("bloqueo_defensor|placed=%d|blocked=%d" % [
		_juego._defender_brain.defender_blocks_placed,
		_juego.blocked_edges.size()])

	# ── S6: resolver el turno avanza el turno y mueve al atacante ──
	_juego._on_defender_resolve_turn()
	snap.append("resolve|turn=%d|over=%s|enemy=%s" % [
		_juego.turn, _juego.game_over, _juego.enemy_pos])

	# ── S7: el defensor sigue sin moverse tras avanzar el turno ──
	snap.append("pos_tras_turno|pos=%s" % _juego.player_pos)

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_finish()
		return

	var golden: Array[String] = [
		"pos_inicial|pos=Internet|turn=0",
		"sin_bloqueo_inicial|blocked=0|ai_used=0",
		"no_move_FirewallExt|pos=Internet|turn=0|over=false",
		"no_move_Proxy|pos=Internet|turn=0|over=false",
		"bloqueo_defensor|placed=1|blocked=1",
		"resolve|turn=1|over=false|enemy=FirewallExt",
		"pos_tras_turno|pos=Internet",
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
