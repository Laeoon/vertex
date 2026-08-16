extends Node

## Equivalence test (golden) para juego/ataque/hacker_logic.gd — etapa 2 del
## slice de descomposición. Congela el comportamiento PRE-migración de
## _scan_selected_node(), _use_hacker_exploit() (incluido el refund de exploit
## fallido) y _check_hacker_consequences().
##
## Determinismo: ai_enabled=false, detection_chance neutralizado a 0 en todos
## los nodos (mutación de la Resource, patrón de _test_ai_blocker_equivalence),
## pursuers prellenado a 4 antes del nivel crítico para saltear el spawn
## (no determinista). Patrón replay + golden hardcodeado (CAPTURE=true).

const CAPTURE := false
const HM = preload("res://juego/system/hacker_mechanics.gd")

var passed: int = 0
var failed: int = 0
var _juego = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
	SceneParams.start_node = &"DMZ"
	SceneParams.target_node = &"Core"
	SceneParams.waypoints = [&"WebServer", &"AdminPanel"]
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.max_ai_blocks = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 18
	SceneParams.max_movement_points = 0
	SceneParams.titulo_nivel = "HACKER GOLDEN"
	SceneParams.hacker_mode = true
	SceneParams.starting_exploits = {"bypass": 2, "escalate": 1, "persist": 1}

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

	# Neutralizar detección (randf) — determinismo total.
	for n in _juego.graph.nodes:
		if n != null:
			n.metadata["detection_chance"] = 0.0

	var snap: Array[String] = []
	_hs(snap, "boot")

	# ── S1: acciones sin nodo seleccionado ──
	_juego.selected_neighbor = &""
	_juego._scan_selected_node()
	snap.append("scan_vacio|%s" % _juego.mensaje_estado)
	_juego._use_hacker_exploit("bypass")
	snap.append("exploit_vacio|%s" % _juego.mensaje_estado)

	# ── S2: escaneo de nodo vulnerable (WebServer: exploit bypass, 0.10) ──
	_juego.selected_neighbor = &"WebServer"
	_juego._scan_selected_node()
	var sr: Dictionary = _juego.scan_results.get("WebServer", {})
	snap.append("scan_web|%s|%s|%s" % [sr.get("node_type"), sr.get("exploit_hint"), sr.get("risk_level")])
	_hs(snap, "post_scan")

	# ── S3: escaneo de nodo protegido (DBServer: has_firewall) ──
	_juego.selected_neighbor = &"DBServer"
	_juego._scan_selected_node()
	var sr2: Dictionary = _juego.scan_results.get("DBServer", {})
	snap.append("scan_db|%s|%s" % [sr2.get("node_type"), sr2.get("exploit_hint")])
	_hs(snap, "post_scan2")

	# ── S4: exploit sin stock (persist ya gastado no; usar escalate 2da vez luego) ──
	# (se cubre al final; primero persist exitoso)

	# ── S5: persist en WebServer ──
	_juego.selected_neighbor = &"WebServer"
	_juego._use_hacker_exploit("persist")
	snap.append("persist|persists=%s|%s" % [str(_juego.hacker_state["active_persists"]), _juego.mensaje_estado])
	_hs(snap, "post_persist")

	# ── S6: bypass sin conexión directa (AppServer no es vecino de DMZ) → refund ──
	_juego.selected_neighbor = &"AppServer"
	_juego._use_hacker_exploit("bypass")
	snap.append("bypass_sin_edge|%s" % _juego.mensaje_estado)
	_hs(snap, "post_refund_bypass")

	# ── S7: bypass en vecino no bloqueado → mueve ──
	_juego.selected_neighbor = &"WebServer"
	_juego._use_hacker_exploit("bypass")
	snap.append("bypass_move|pos=%s|turn=%d|wpi=%d" % [str(_juego.player_pos), _juego.turn, _juego.current_waypoint_idx])
	_hs(snap, "post_bypass_move")

	# ── S8: escalate en vecino (AppServer desde WebServer) → mueve + ruido alto ──
	_juego.selected_neighbor = &"AppServer"
	_juego._use_hacker_exploit("escalate")
	snap.append("escalate_move|pos=%s|%s" % [str(_juego.player_pos), _juego.mensaje_estado])
	_hs(snap, "post_escalate")

	# ── S9: exploit sin stock ──
	_juego._use_hacker_exploit("escalate")
	snap.append("sin_stock|%s" % _juego.mensaje_estado)

	# ── S10: nivel crítico con pursuers llenos (sin spawn) + expira persist ──
	# Perseguidores REALES con delay 99 (nunca actúan) para llenar el cupo y
	# saltear el spawn no determinista de la rama crítica.
	_juego.pursuers = []
	for i in 4:
		_juego._pursuit_system.spawn_pursuer(&"Core", 99, 1)
	HM.add_noise(_juego.hacker_state, 90 - int(_juego.hacker_state["noise"]))
	_juego._check_hacker_consequences()
	snap.append("critico|%s|persists=%s|pursuers=%d" % [
		_juego.mensaje_estado, str(_juego.hacker_state["active_persists"]), _juego.pursuers.size()])
	_hs(snap, "post_critico")

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_finish()
		return

	var golden: Array[String] = [
		"boot|noise=0|used=0|bypass=2|esc=1|per=1|pos=DMZ|turn=0",
		"scan_vacio|Selecciona un nodo para escanear [X]",
		"exploit_vacio|Selecciona un nodo para explotar",
		"scan_web|vulnerable|Salta la protección de un nodo|bajo",
		"post_scan|noise=2|used=0|bypass=2|esc=1|per=1|pos=DMZ|turn=0",
		"scan_db|protected|Requiere elevación de privilegios",
		"post_scan2|noise=4|used=0|bypass=2|esc=1|per=1|pos=DMZ|turn=0",
		"persist|persists={ \"WebServer\": 2 }|♻ Persistencia aplicado en WebServer (ruido: 14)",
		"post_persist|noise=14|used=1|bypass=2|esc=1|per=0|pos=DMZ|turn=0",
		"bypass_sin_edge|Sin conexión directa a AppServer",
		"post_refund_bypass|noise=14|used=1|bypass=2|esc=1|per=0|pos=DMZ|turn=0",
		"bypass_move|pos=WebServer|turn=1|wpi=1",
		"post_bypass_move|noise=34|used=2|bypass=1|esc=1|per=0|pos=WebServer|turn=1",
		"escalate_move|pos=AppServer|⚠ Ruido alto — cuidado con los movimientos",
		"post_escalate|noise=64|used=3|bypass=1|esc=0|per=0|pos=AppServer|turn=2",
		"sin_stock|No tienes exploits de tipo Elevación",
		"critico|⚠ RUIDO CRÍTICO — Seguridad máxima activada|persists={  }|pursuers=4",
		"post_critico|noise=90|used=3|bypass=1|esc=0|per=0|pos=AppServer|turn=2",
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


## Snapshot compacto del estado hacker.
func _hs(snap: Array[String], tag: String) -> void:
	var e: Dictionary = _juego.hacker_state["exploits"]
	snap.append("%s|noise=%d|used=%d|bypass=%d|esc=%d|per=%d|pos=%s|turn=%d" % [
		tag, _juego.hacker_state["noise"], _juego.hacker_state["exploits_used"],
		e.get("bypass", 0), e.get("escalate", 0), e.get("persist", 0),
		str(_juego.player_pos), _juego.turn])


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
