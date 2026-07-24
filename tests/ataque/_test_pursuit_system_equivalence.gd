extends Node

## Equivalencia conductual: PursuitSystem vs lógica original de detección/persecución
## (slice 4).
##
## Verifica que la extracción de `_chequear_deteccion` / `_process_pursuers` /
## `_find_spawn_node` + gestión de estado de perseguidores en `PursuitSystem`
## (juego/ataque/pursuit_system.gd) preserva la conducta observable.
##
## A diferencia del slice 3 (que tenía un flip semántico `would_isolate` vs
## `_no_aisla_al_jugador`), el slice 4 es un porte VERBATIM — no hay
## transformación semántica que contrastar bloque-a-bloque. La equivalencia se
## prueba entonces con un replay determinista (`seed`) contra un golden
## capturado con la lógica ORIGINAL inline, exactamente como la Parte B del
## slice 3. El flag `USE_PURSUIT_SYSTEM` conmuta entre el camino inline
## (pre-migración, task 4.2) y el camino extraído (`PursuitSystem`,
## post-migración task 4.3); el golden debe reproducirse idéntico en ambos.
##
## Escenario (determinista — detección forzada a 1.0): conduce SOLO la lógica
## de detección/persecución fijando `player_pos` directamente e invocando
## `_invoke_check_detection()` + `_invoke_process_pursuers()` por paso. NO usa
## `_mover_jugador` (chocaría con el bug PRE-EXISTENTE en `_ganar` línea 710
## `waypoints[-1]` OOB reportado en slice 3, fuera de scope). NO dispara IA
## (`ai_enabled=false`) ni hacker/defender. Aserta en estado ESTRUCTURAL
## (`alerted_nodes`, `pursuers`, `_pursuer_next_id`, `game_over`,
## `mensaje_estado`) — no en el texto impreso, salvo `mensaje_estado` que sí
## forma parte del golden.
##
## Parte A — replay determinista vs golden (detection + spawn + delay +
## activación + chase + captura + reset). USE-gated.
## Parte B — sanity del helper `spawn_pursuer` (delay/speed custom) — no
## depende de la migración (instancia `PursuitSystem` directo vía preload).
##
## Recaptura del golden: poner `CAPTURE = true`, correr la escena, copiar el
## bloque `=== CAPTURE ===` a `_golden_pasos`, devolver `CAPTURE = false` y
## re-correr. El golden se captura con `USE_PURSUIT_SYSTEM = false` (inline,
## HEAD de task 4.2, pre-migración), `seed(42)`, tut3_red con detección
## forzada. Tras la migración 4.3 (USE=true), la corrida debe reproducir
## idéntico el golden.
##
## Por qué `_` prefijo + `.tscn`: la prueba instancia `escena_juego.tscn`,
## cuyo script raíz referencia autoloads (SceneParams, AudioManager, Events).
## En Godot 4.7, `--script` NO registra autoloads (slice-0 hallazgo #6), por
## lo que `run_all.gd` no puede ejecutarla — se excluye con `_` (establecido
## en slice-3 para `_test_ai_blocker_equivalence`) y se corre vía escena:
##     godot --headless res://tests/ataque/_test_pursuit_system_equivalence.tscn
## Única desviación del path indicado por el task: prefijo `_`. Slice 9
## (tarea 9.1) extenderá `run_all.gd` para descubrir/correr `.tscn`.

const GRAPH_PATH := "res://juego/tutorial3/tut3_red.tres"
const SEMILLA := 42

# Modo captura: true → imprime snapshots de la Parte A y NO afirma
# (regenerar golden). false → afirma contra `_golden_pasos`.
const CAPTURE := false

# Conmutador de camino de invocación — se edita en la task 4.3.
# false (pre-migración 4.2): llama al inline `_chequear_deteccion` /
#   `_process_pursuers` (presentes hasta la task 4.4).
# true (post-migración 4.3+): llama al `PursuitSystem` cableado en `_ready`.
var USE_PURSUIT_SYSTEM := true

var passed: int = 0
var failed: int = 0
var _juego: Node2D
var _captures: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# SceneParams para una partida determinista de modo ataque (no defensor).
	SceneParams.graph_path = GRAPH_PATH
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Servidor"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_ai_blocks = 0
	SceneParams.max_turns = 0
	SceneParams.max_movement_points = 0
	SceneParams.block_duration = 99
	SceneParams.defender_mode = false
	SceneParams.hacker_mode = false
	SceneParams.tutorial_path = ""
	SceneParams.titulo_nivel = "PURSUIT EQUIV TEST"
	SceneParams.pursuer_delay = 2
	SceneParams.max_pursuers = 4
	SceneParams.pursuer_speed = 1

	var scene := load("res://juego/ataque/escena_juego.tscn") as PackedScene
	_juego = scene.instantiate()
	get_tree().root.add_child(_juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if _juego == null or not is_instance_valid(_juego) or _juego.graph == null:
		print("FAIL: escena_juego o grafo no cargaron")
		failed += 1
		_quit()
		return

	# Determinismo de detección: forzar detection_chance=1.0 en Firewall y
	# Router (donde el jugador se pondrá), Inicio en 0.0 (sin detección al
	# inicio), y el resto en 0.0 para aislar el escenario. La mutación de la
	# Resource cacheada persiste solo durante la vida del proceso Godot.
	# Seguridad: ningún otro test bajo tests/ o juego/ataque/ usa tut3_red
	# con detección activa en la misma corrida (slice-3 silenció tut3_red).
	for n in _juego.graph.nodes:
		if n == null or n.metadata == null:
			continue
		n.metadata["detection_chance"] = 0.0
	_juego._find_node_resource(&"Firewall").metadata["detection_chance"] = 1.0
	_juego._find_node_resource(&"Router").metadata["detection_chance"] = 1.0
	# Spawn en un nodo CON salida (Inicio→Firewall/Router) y DISTINTO del
	# jugador: tapar has_firewall de Firewall para que find_spawn_node itere
	# hasta el security_spawn, y marcar Inicio como security_spawn.
	_juego._find_node_resource(&"Firewall").metadata["has_firewall"] = false
	_juego._find_node_resource(&"Inicio").metadata["security_spawn"] = true

	# Partir de un estado limpio (reset_state ya lo hizo en _ready, pero la
	# mutación de metadata puede haber dejado inconsistencias; repetimos para
	# garantizar Pursuers/alerted vacíos antes del replay).
	_juego.alerted_nodes.clear()
	_juego.pursuers.clear()
	_juego._pursuer_next_id = 1
	_game_over_reset()

	seed(SEMILLA)

	_parte_a_replay_deteccion_persecucion()
	_parte_b_spawn_pursuer_sanity()

	_quit()


# ── Parte A: replay determinista (detección + persecución + captura) ─────

func _parte_a_replay_deteccion_persecucion() -> void:
	var snapshots: Array = []

	# S0: jugador en Inicio (det 0). Sin detección, sin perseguidores.
	_step(&"Inicio", "S0", snapshots)

	# S1: jugador en Firewall (det 1.0). Detección → alerta → spawn en Inicio
	# (security_spawn), delay=2. Perseguidor no activo aún.
	_step(&"Firewall", "S1", snapshots)

	# S2: jugador sigue en Firewall (ya alertado). Detección re-dispara
	# randf (consume RNG) pero alertado → return sin nuevo spawn. Perseguidor
	# delay 1→0 → activo.
	_step(&"Firewall", "S2", snapshots)

	# S3: jugador en Router (det 1.0). Segunda detección → segundo perseguidor
	# en Inicio. Perseguidor 1 (retardado, activo en Inicio) persigue al
	# jugador en Router → captura → _perder.
	_step(&"Router", "S3", snapshots)

	# Tras captura, reset_state limpia detección/perseguidores. (4.2 inline
	# clear; 4.3+ _pursuit_system.reset() — mismo resultado observable.)
	_invoke_reset_state()
	snapshots.append(_snapshot("RESET"))

	if CAPTURE:
		print("=== CAPTURE START ===")
		for s in snapshots:
			print("\t\"%s\"," % s)
		print("=== CAPTURE END ===")
		print("PASS (capture A): %d snapshots impresos — copiar a _golden_pasos y poner CAPTURE=false (USE=%s)" % [snapshots.size(), str(USE_PURSUIT_SYSTEM)])
		passed += 1
		return

	if snapshots.size() != _golden_pasos.size():
		print("FAIL A: snapshot count got=%d want=%d" % [snapshots.size(), _golden_pasos.size()])
		failed += 1
		return

	for i in range(snapshots.size()):
		if snapshots[i] == _golden_pasos[i]:
			print("PASS A.%d coincide" % i)
			passed += 1
		else:
			print("FAIL A.%d:\n  got =%s\n  want=%s" % [i, snapshots[i], _golden_pasos[i]])
			failed += 1


# ── Parte B: sanity del helper spawn_pursuer ─────────────────────────────

func _parte_b_spawn_pursuer_sanity() -> void:
	# Instancia PursuitSystem directo vía preload (no requiere cableado del
	# juego — funciona igual pre/post migración). Verifica que spawn_pursuer
	# construye el dict esperado con delay/speed custom (como el spawn del
	# hacker crítico de ruido: delay=1, speed=2) e incrementa _pursuer_next_id.
	if CAPTURE:
		print("SKIP (capture B): sanity spawn_pursuer pospuesto a CAPTURE=false")
		return
	var ps_class := preload("res://juego/ataque/pursuit_system.gd")
	var ps := ps_class.new()
	ps.setup(_juego)
	# Estado limpio para la aserción.
	_juego.pursuers.clear()
	_juego._pursuer_next_id = 7

	ps.spawn_pursuer(&"DMZ", 1, 2)

	var ok_id: bool = _juego._pursuer_next_id == 8
	var ok_count: bool = _juego.pursuers.size() == 1
	var p: Dictionary = _juego.pursuers[0] if ok_count else {}
	var ok_struct: bool = ok_count and p["id"] == 7 and p["pos"] == &"DMZ" and int(p["delay"]) == 1 and int(p["speed"]) == 2 and p["active"] == false

	if USE_PURSUIT_SYSTEM and ok_id and ok_count and ok_struct:
		print("PASS B.0 spawn_pursuer custom delay/speed OK")
		passed += 1
	elif not USE_PURSUIT_SYSTEM:
		# Pre-migración (4.2), Parte B no depende del flag USE, corre igual.
		if ok_id and ok_count and ok_struct:
			print("PASS B.0 spawn_pursuer custom delay/speed OK")
			passed += 1
		else:
			print("FAIL B.0 spawn_pursuer: next_id=%d count=%d struct_ok=%s" % [_juego._pursuer_next_id, _juego.pursuers.size(), str(ok_struct)])
			failed += 1
	else:
		print("FAIL B.0 spawn_pursuer: next_id=%d count=%d struct_ok=%s" % [_juego._pursuer_next_id, _juego.pursuers.size(), str(ok_struct)])
		failed += 1


# ─── helpers de invocación — conmutados por USE_PURSUIT_SYSTEM ──────────

func _step(player_pos: StringName, lbl: String, out: Array) -> void:
	_juego.player_pos = player_pos
	_juego.turn = 0
	_invoke_check_detection()
	out.append(_snapshot(lbl + ".D"))
	if not _juego.game_over:
		_invoke_process_pursuers()
	out.append(_snapshot(lbl + ".P"))


func _invoke_check_detection() -> void:
	if USE_PURSUIT_SYSTEM:
		_juego._pursuit_system.check_detection(_juego.player_pos)
	else:
		_juego._chequear_deteccion()


func _invoke_process_pursuers() -> void:
	var captured: bool
	if USE_PURSUIT_SYSTEM:
		captured = _juego._pursuit_system.process_pursuers(_juego.player_pos)
	else:
		_juego._process_pursuers()
		captured = _juego.game_over  # el inline no devuelve bool; proxy
	if captured:
		_captures += 1


func _invoke_reset_state() -> void:
	_juego.reset_state()


func _game_over_reset() -> void:
	# Forzar game_over=false de salida (reset_state puede no tocarlo si el
	# grafo cargó limpio; aseguramos para el replay).
	_juego.game_over = false
	_juego.game_won = false
	_captures = 0


func _snapshot(label: String) -> String:
	# Compact single-line: label|alert=[..]|pursuers=[{..},..]|next=N|
	# game_over=B|msg=...|captures=N
	var alert_strs: Array = []
	for a in _juego.alerted_nodes:
		alert_strs.append(str(a))
	var pers_strs: Array = []
	for p in _juego.pursuers:
		pers_strs.append("{id=%d,pos=%s,delay=%d,speed=%d,active=%s}" % [
			int(p["id"]), str(p["pos"]), int(p["delay"]), int(p["speed"]), str(p["active"])])
	return "%s|alert=[%s]|pursuers=[%s]|next=%d|game_over=%s|msg=%s|captures=%d" % [
		label, ",".join(alert_strs), ",".join(pers_strs), int(_juego._pursuer_next_id),
		str(_juego.game_over), _juego.mensaje_estado, _captures]


# Golden capturado con lógica inline ORIGINAL (HEAD de task 4.2, USE=false),
# seed(42), tut3_red con detección forzada (Firewall/Router=1.0, Inicio=0.0,
# Firewall.has_firewall=false, Inicio.security_spawn=true), pursuer_delay=2,
# pursuer_max=4, pursuer_speed=1. Pasos S0..S3 + RESET (cada paso duro D y P).
# Ver encabezado para recaptura. Se rellena tras la primera corrida CAPTURE=true.
var _golden_pasos: Array = [
	"S0.D|alert=[]|pursuers=[]|next=1|game_over=false|msg=Tu turno: haz clic en un vecino para moverte|captures=0",
	"S0.P|alert=[]|pursuers=[]|next=1|game_over=false|msg=Tu turno: haz clic en un vecino para moverte|captures=0",
	"S1.D|alert=[Firewall]|pursuers=[{id=1,pos=Inicio,delay=2,speed=1,active=false}]|next=2|game_over=false|msg=¡Alerta en Firewall! Seguridad en camino...|captures=0",
	"S1.P|alert=[Firewall]|pursuers=[{id=1,pos=Inicio,delay=1,speed=1,active=false}]|next=2|game_over=false|msg=¡Alerta en Firewall! Seguridad en camino...|captures=0",
	"S2.D|alert=[Firewall]|pursuers=[{id=1,pos=Inicio,delay=1,speed=1,active=false}]|next=2|game_over=false|msg=¡Alerta en Firewall! Seguridad en camino...|captures=0",
	"S2.P|alert=[Firewall]|pursuers=[{id=1,pos=Inicio,delay=0,speed=1,active=true}]|next=2|game_over=false|msg=¡Alerta en Firewall! Seguridad en camino...|captures=0",
	"S3.D|alert=[Firewall,Router]|pursuers=[{id=1,pos=Inicio,delay=0,speed=1,active=true},{id=2,pos=Inicio,delay=2,speed=1,active=false}]|next=3|game_over=false|msg=¡Alerta en Router! Seguridad en camino...|captures=0",
	"S3.P|alert=[Firewall,Router]|pursuers=[{id=1,pos=Router,delay=0,speed=1,active=true},{id=2,pos=Inicio,delay=2,speed=1,active=false}]|next=3|game_over=true|msg=PERDISTE: Capturado por seguridad (perseguidor 1)|captures=1",
	"RESET|alert=[]|pursuers=[]|next=1|game_over=false|msg=Tu turno: haz clic en un vecino para moverte|captures=1",
]


func _quit() -> void:
	if _juego != null and is_instance_valid(_juego):
		_juego.queue_free()
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if failed == 0 else 1)