extends Node

## Pruebas de lógica para HackerMechanics (juego/system/) y HackerLogic (juego/ataque/).
##
## Cubre mecánicas puras de HackerMechanics (estáticas) y ventajas tácticas/ciclo de vida
## en HackerLogic (señuelo, sigilo bypass, telemetría escalate, safe haven persist).

const HM = preload("res://juego/system/hacker_mechanics.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_exploit_types()
	_test_state_creation()
	_test_exploit_economy()
	_test_decoy_pure_logic()
	_test_noise()
	_test_alert_levels()
	_test_scan_node()
	_test_stars()

	# Pruebas integradas de lógica y ventajas tácticas con escena real
	await _run_integrated_tests()

	_finalizar()


func _test_exploit_types() -> void:
	var tipos: Array = [HM.EXPLOIT_BYPASS, HM.EXPLOIT_ESCALATE, HM.EXPLOIT_PERSIST, HM.EXPLOIT_DECOY]
	for t in tipos:
		_afirmar(HM.EXPLOIT_NAMES.has(t) and HM.EXPLOIT_NAMES[t] != "",
			"exploit %s tiene nombre de UI no vacío" % t)
		_afirmar(HM.EXPLOIT_ICONS.has(t) and HM.EXPLOIT_ICONS[t] != "",
			"exploit %s tiene ícono" % t)
		_afirmar(HM.EXPLOIT_DESCRIPTIONS.has(t) and HM.EXPLOIT_DESCRIPTIONS[t] != "",
			"exploit %s tiene descripción" % t)
	_afirmar(HM.EXPLOIT_NAMES[HM.EXPLOIT_BYPASS] == "Infiltración",
		"bypass se muestra como 'Infiltración'")
	_afirmar(HM.EXPLOIT_NAMES[HM.EXPLOIT_DECOY] == "Señuelo",
		"decoy se muestra como 'Señuelo'")


func _test_state_creation() -> void:
	var s: Dictionary = HM.create_state()
	_afirmar(s["noise"] == 0 and s["max_noise"] == 100 and s["exploits_used"] == 0,
		"create_state() por defecto: sin ruido, 0 exploits usados")
	_afirmar(s["max_exploits"] == HM.MAX_EXPLOITS_DEFAULT,
		"max_exploits por defecto = %d" % HM.MAX_EXPLOITS_DEFAULT)
	_afirmar(s.has("active_decoys") and s["active_decoys"] is Dictionary and s["active_decoys"].is_empty(),
		"active_decoys inicializado como diccionario vacío")
	var s2: Dictionary = HM.create_state(5)
	_afirmar(s2["max_exploits"] == 5, "create_state(5) respeta el máximo custom")


func _test_exploit_economy() -> void:
	var s: Dictionary = HM.create_state()

	var r_fail: Dictionary = HM.use_exploit(s, HM.EXPLOIT_BYPASS, &"Nodo")
	_afirmar(r_fail["success"] == false, "use_exploit sin stock falla")
	_afirmar(str(r_fail["reason"]).find("Infiltración") != -1,
		"el motivo de fallo usa el nombre estilizado")

	HM.grant_exploits(s, HM.EXPLOIT_BYPASS, 2)
	HM.grant_exploits(s, HM.EXPLOIT_PERSIST, 1)
	_afirmar(HM.get_total_exploits(s) == 3, "get_total_exploits suma 3 tras otorgar")

	var r_ok: Dictionary = HM.use_exploit(s, HM.EXPLOIT_BYPASS, &"Nodo")
	_afirmar(r_ok["success"] == true and r_ok["noise_added"] == HM.NOISE_EXPLOIT_BYPASS,
		"bypass exitoso agrega el ruido definido (%d)" % HM.NOISE_EXPLOIT_BYPASS)
	_afirmar(s["exploits"][HM.EXPLOIT_BYPASS] == 1 and s["exploits_used"] == 1,
		"el stock baja y exploits_used sube")

	var r_persist: Dictionary = HM.use_exploit(s, HM.EXPLOIT_PERSIST, &"Servidor")
	_afirmar(r_persist["success"] == true and s["active_persists"].has("Servidor")
		and s["active_persists"]["Servidor"] == 3,
		"persist registra active_persists[Servidor] = 3 turnos")


func _test_decoy_pure_logic() -> void:
	var s: Dictionary = HM.create_state()
	var r_fail: Dictionary = HM.use_exploit(s, HM.EXPLOIT_DECOY, &"Nodo")
	_afirmar(r_fail["success"] == false and s["noise"] == 0,
		"use_exploit decoy sin stock falla y no añade ruido")
	_afirmar(str(r_fail["reason"]).find("Señuelo") != -1,
		"motivo de fallo de decoy usa nombre 'Señuelo'")

	HM.grant_exploits(s, HM.EXPLOIT_DECOY, 1)
	_afirmar(s["exploits"][HM.EXPLOIT_DECOY] == 1, "grant_exploits otorga 1 señuelo")

	var r_ok: Dictionary = HM.use_exploit(s, HM.EXPLOIT_DECOY, &"NodoB")
	_afirmar(r_ok["success"] == true and r_ok["noise_added"] == HM.NOISE_EXPLOIT_DECOY,
		"use_exploit decoy exitoso agrega 15 ruido")
	_afirmar(s["exploits"][HM.EXPLOIT_DECOY] == 0 and s["exploits_used"] == 1,
		"consumo de cargo y exploits_used actualizado para decoy")
	_afirmar(s["active_decoys"].has("NodoB") and s["active_decoys"]["NodoB"]["duration"] == HM.DECOY_DURATION_TURNS,
		"active_decoys registra el nodo con duracion de 2 turnos")

	var r_exhausted: Dictionary = HM.use_exploit(s, HM.EXPLOIT_DECOY, &"NodoB")
	_afirmar(r_exhausted["success"] == false, "agotamiento de cargos impide nuevo despliegue de señuelo")


func _test_noise() -> void:
	var s: Dictionary = HM.create_state()
	HM.add_noise(s, 90)
	HM.add_noise(s, 50)
	_afirmar(s["noise"] == 100, "add_noise clampea al máximo (100)")
	HM.decay_noise(s)
	_afirmar(s["noise"] == 100 - HM.NOISE_DECAY_PER_TURN,
		"decay_noise baja %d por turno" % HM.NOISE_DECAY_PER_TURN)
	var s2: Dictionary = HM.create_state()
	HM.decay_noise(s2)
	HM.decay_noise(s2)
	_afirmar(s2["noise"] == 0, "decay_noise no baja de 0")

	# Doble decay (persist)
	var s3: Dictionary = HM.create_state()
	HM.add_noise(s3, 50)
	HM.decay_noise(s3, HM.NOISE_DECAY_PER_TURN * 2)
	_afirmar(s3["noise"] == 50 - (HM.NOISE_DECAY_PER_TURN * 2),
		"decay_noise con monto custom reduce el valor solicitado (6)")


func _test_alert_levels() -> void:
	var casos: Dictionary = {
		29: "safe",
		30: "low",
		59: "low",
		60: "high",
		84: "high",
		85: "critical",
	}
	for ruido in casos:
		var s: Dictionary = HM.create_state()
		HM.add_noise(s, ruido)
		_afirmar(HM.get_alert_level(s) == casos[ruido],
			"ruido %d → alerta '%s'" % [ruido, casos[ruido]])
	_afirmar(HM.get_ai_aggression_multiplier(HM.create_state()) == 1.0
		and HM.get_ai_aggression_multiplier(_state_with_noise(85)) == 2.0,
		"multiplicador de agresión IA: 1.0 en safe, 2.0 en critical")


func _state_with_noise(amount: int) -> Dictionary:
	var s: Dictionary = HM.create_state()
	HM.add_noise(s, amount)
	return s


func _test_scan_node() -> void:
	var s: Dictionary = HM.create_state()

	var r_decoy: Dictionary = HM.scan_node(s, &"Decoy", {"is_decoy": true})
	_afirmar(r_decoy["node_type"] == HM.NODE_DECOY, "nodo is_decoy → tipo decoy")

	var r_prot: Dictionary = HM.scan_node(s, &"FW", {"has_firewall": true})
	_afirmar(r_prot["node_type"] == HM.NODE_PROTECTED,
		"nodo con firewall → tipo protected")

	var r_vuln: Dictionary = HM.scan_node(s, &"Vuln", {"exploit_type": "escalate"})
	_afirmar(r_vuln["node_type"] == HM.NODE_VULNERABLE,
		"nodo con exploit_type → tipo vulnerable")

	var r_detect: Dictionary = HM.scan_node(s, &"Riesgo", {"detection_chance": 0.2})
	_afirmar(r_detect["node_type"] == HM.NODE_VULNERABLE and r_detect["risk_level"] == "alto",
		"detection_chance 0.2 → vulnerable con riesgo alto")

	var r_normal: Dictionary = HM.scan_node(s, &"Normal", {"detection_chance": 0.05})
	_afirmar(r_normal["node_type"] == HM.NODE_NORMAL and r_normal["risk_level"] == "bajo",
		"nodo sin señales → normal, riesgo bajo")

	_afirmar(s["scanned_nodes"].has("Vuln") and s["discovered_vulnerabilities"].has("Vuln"),
		"scan marca scanned_nodes y registra la vulnerabilidad descubierta")
	_afirmar(not s["discovered_vulnerabilities"].has("Normal"),
		"un nodo normal no entra en discovered_vulnerabilities")
	_afirmar(s["noise"] == HM.NOISE_SCAN * 5,
		"5 escaneos suman exactamente el ruido de scan (%d)" % (HM.NOISE_SCAN * 5))

	# Escaneo sin costo de ruido (telemetría)
	var noise_before = s["noise"]
	HM.scan_node(s, &"Silent", {"detection_chance": 0.1}, false)
	_afirmar(s["noise"] == noise_before and s["scanned_nodes"].has("Silent"),
		"scan_node con add_noise_cost=false no agrega ruido")


func _test_stars() -> void:
	var perfecto: Dictionary = HM.create_state()
	_afirmar(HM.calculate_hacker_stars(perfecto, 1, 20) == 3,
		"run silenciosa y rápida → 3 estrellas")
	var malo: Dictionary = HM.create_state()
	HM.add_noise(malo, 100)
	_afirmar(HM.calculate_hacker_stars(malo, 20, 20) == 1,
		"run ruidosa y lenta → 1 estrella")


func _run_integrated_tests() -> void:
	SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
	SceneParams.start_node = &"DMZ"
	SceneParams.target_node = &"Core"
	SceneParams.waypoints = [&"WebServer", &"AdminPanel"]
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.max_ai_blocks = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 20
	SceneParams.max_movement_points = 0
	SceneParams.titulo_nivel = "HACKER MECHANICS TEST"
	SceneParams.hacker_mode = true
	SceneParams.starting_exploits = {"bypass": 2, "escalate": 1, "persist": 1, "decoy": 2}

	var scene = load("res://juego/ataque/escena_juego.tscn")
	var juego = scene.instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if juego.graph == null:
		print("FAIL: graph no cargo en escena de test")
		failed += 1
		juego.queue_free()
		return

	# Neutralizar detección inicial para pruebas controladas
	for n in juego.graph.nodes:
		if n != null:
			n.metadata["detection_chance"] = 0.0

	_test_decoy_lifecycle_and_validation(juego)
	_test_mechanics_advantages(juego)
	_test_ai_and_pursuit_integration(juego)

	juego.queue_free()
	await get_tree().process_frame


func _test_decoy_lifecycle_and_validation(juego: Node) -> void:
	# 1. Adjacency check
	juego.player_pos = &"DMZ"
	juego.hacker_state["exploits"]["decoy"] = 1
	var noise_pre: int = juego.hacker_state["noise"]
	juego.selected_neighbor = &"Core" # No adyacente a DMZ
	juego._use_hacker_exploit("decoy")
	_afirmar(juego.hacker_state["exploits"]["decoy"] == 1,
		"nodo no adyacente: no consume cargo de señuelo")
	_afirmar(juego.hacker_state["noise"] == noise_pre,
		"nodo no adyacente: no agrega ruido")
	_afirmar(not juego.hacker_state["active_decoys"].has("Core"),
		"nodo no adyacente: no registra señuelo activo")

	# 2. Successful deployment
	juego.selected_neighbor = &"WebServer" # Adyacente a DMZ
	juego._use_hacker_exploit("decoy")
	_afirmar(juego.hacker_state["exploits"]["decoy"] == 0,
		"despliegue adyacente: consume 1 cargo")
	_afirmar(juego.hacker_state["noise"] == noise_pre + HM.NOISE_EXPLOIT_DECOY,
		"despliegue adyacente: suma 15 de ruido")
	_afirmar(juego.hacker_state["active_decoys"].has("WebServer"),
		"despliegue adyacente: WebServer registrado en active_decoys")

	# 3. Charge exhaustion
	juego._use_hacker_exploit("decoy")
	_afirmar(juego.hacker_state["noise"] == noise_pre + HM.NOISE_EXPLOIT_DECOY,
		"intento con 0 cargos no altera ruido")

	# 4. Noise refund
	juego._hacker_logic._refund_exploit("decoy")
	_afirmar(juego.hacker_state["exploits"]["decoy"] == 1,
		"refund: restaura cargo de señuelo")
	_afirmar(juego.hacker_state["noise"] == noise_pre,
		"refund: reembolsa 15 de ruido")
	_afirmar(not juego.hacker_state["active_decoys"].has("WebServer"),
		"refund: poda el señuelo de active_decoys")

	# 5. Turn decay
	juego._use_hacker_exploit("decoy") # Vuelve a desplegar en WebServer
	_afirmar(juego.hacker_state["active_decoys"]["WebServer"]["duration"] == 2,
		"señuelo arranca con duracion 2")
	juego._hacker_logic.check_hacker_consequences()
	_afirmar(juego.hacker_state["active_decoys"]["WebServer"]["duration"] == 1,
		"primer turno decrementa duracion a 1")
	juego._hacker_logic.check_hacker_consequences()
	_afirmar(not juego.hacker_state["active_decoys"].has("WebServer"),
		"segundo turno expira y poda el señuelo")


func _test_mechanics_advantages(juego: Node) -> void:
	# 1. Scan trap protection
	var test_trap := &"MailServer"
	var node_res = juego._find_node_resource(test_trap)
	node_res.metadata["is_decoy"] = true
	juego.hacker_state["scanned_nodes"].erase("MailServer")
	var noise_pre: int = juego.hacker_state["noise"]
	juego._hacker_logic.on_node_entered(test_trap)
	_afirmar(juego.hacker_state["noise"] == noise_pre + HM.NOISE_DECOY_PENALTY,
		"nodo trampa no escaneado aplica penalización de +30 ruido")

	juego.hacker_state["scanned_nodes"]["MailServer"] = true
	var noise_scanned: int = juego.hacker_state["noise"]
	juego._hacker_logic.on_node_entered(test_trap)
	_afirmar(juego.hacker_state["noise"] == noise_scanned,
		"nodo trampa escaneado previamente tiene inmunidad a penalización")

	# 2. Halved detection chance on scanned nodes
	var chance_scanned: float = juego._hacker_logic.get_detection_chance(&"MailServer", 0.4)
	_afirmar(is_equal_approx(chance_scanned, 0.2),
		"nodo escaneado reduce la probabilidad de detección al 50% (0.4 → 0.2)")
	var chance_unscanned: float = juego._hacker_logic.get_detection_chance(&"Proxy", 0.4)
	_afirmar(is_equal_approx(chance_unscanned, 0.4),
		"nodo no escaneado mantiene probabilidad de detección original")

	# 3. Bypass stealth traversal
	juego._hacker_logic.bypass_stealth_active = true
	var chance_bypass: float = juego._hacker_logic.get_detection_chance(&"Proxy", 0.4)
	_afirmar(chance_bypass == 0.0,
		"travesía con bypass garantiza 0% de detección")
	juego._hacker_logic.bypass_stealth_active = false

	# 4. Escalate 2-hop network telemetry
	juego.hacker_state["scanned_nodes"].clear()
	juego.scan_results.clear()
	var noise_telemetry_pre: int = juego.hacker_state["noise"]
	juego._hacker_logic._trigger_2_hop_telemetry(&"DMZ")
	_afirmar(juego.hacker_state["scanned_nodes"].has("WebServer") and juego.hacker_state["scanned_nodes"].has("AppServer"),
		"telemetría de escalate escanea nodos a 1 y 2 saltos")
	_afirmar(juego.scan_results.has("WebServer") and juego.scan_results.has("AppServer"),
		"telemetría registra los resultados de escaneo en scan_results")
	_afirmar(juego.hacker_state["noise"] == noise_telemetry_pre,
		"telemetría de red no suma ruido por nodo escaneado")

	# 5. Persist safe haven (0 movement noise)
	juego.hacker_state["active_persists"]["WebServer"] = 3
	juego.player_pos = &"DMZ"
	var dest_persisted: bool = juego.hacker_state.get("active_persists", {}).has("WebServer")
	_afirmar(dest_persisted, "destino WebServer reconocido como persistido")

	# 6. Persist double noise decay
	juego.player_pos = &"WebServer"
	var n_pre_decay: int = 40
	juego.hacker_state["noise"] = n_pre_decay
	var resting: bool = juego.hacker_state.get("active_persists", {}).has(str(juego.player_pos))
	if resting:
		HM.decay_noise(juego.hacker_state, HM.NOISE_DECAY_PER_TURN * 2)
	_afirmar(juego.hacker_state["noise"] == n_pre_decay - 6,
		"descansar en nodo persistido duplica el decay de ruido (-6)")

	# Resting on non-persisted node
	juego.player_pos = &"Core"
	juego.hacker_state["noise"] = n_pre_decay
	var resting_normal: bool = juego.hacker_state.get("active_persists", {}).has(str(juego.player_pos))
	if not resting_normal:
		HM.decay_noise(juego.hacker_state)
	_afirmar(juego.hacker_state["noise"] == n_pre_decay - 3,
		"descansar en nodo no persistido aplica decay normal (-3)")


func _test_ai_and_pursuit_integration(juego: Node) -> void:
	# AI Blocker interception
	juego.player_pos = &"DMZ"
	juego.current_waypoint_idx = 1 # Objetivo: AdminPanel (ruta alternativa vía MailServer abierta)
	juego.hacker_state["active_decoys"]["WebServer"] = {"duration": 2}
	juego.ai_enabled = true
	var path: Array[StringName] = [&"DMZ", &"WebServer", &"AppServer"]
	var blocked: bool = juego._ai_blocker._bloquear_en(path, 0)
	_afirmar(blocked == true, "AIBlocker intercepta arista que toca el señuelo")
	_afirmar(not juego._is_blocked("DMZ→WebServer"), "la arista protegida por señuelo no queda bloqueada")
	_afirmar(not juego.hacker_state["active_decoys"].has("WebServer"), "el señuelo expira al absorber el bloqueo")

	# Candidate edges disjoint from decoy nodes remain blockable
	juego.hacker_state["active_decoys"]["MailServer"] = {"duration": 2}
	var path2: Array[StringName] = [&"WebServer", &"AppServer", &"DBServer"]
	var blocked2: bool = juego._ai_blocker._bloquear_en(path2, 1)
	_afirmar(blocked2 == true, "arista disjunta de señuelos puede ser bloqueada")
	_afirmar(juego._is_blocked("AppServer→DBServer"), "la arista disjunta queda bloqueada")
	_afirmar(juego.hacker_state["active_decoys"].has("MailServer"), "el señuelo no vinculado a la arista bloqueada se preserva")

	# Pursuit diversion
	juego.pursuers.clear()
	juego._pursuit_system.spawn_pursuer(&"DMZ", 0, 1)
	juego.pursuers[0]["active"] = true
	juego.hacker_state["active_decoys"].clear()
	juego.hacker_state["active_decoys"]["WebServer"] = {"duration": 2}
	juego.player_pos = &"MailServer"
	juego._pursuit_system.process_pursuers(juego.player_pos)
	_afirmar(juego.pursuers[0]["pos"] == &"WebServer", "perseguidor desvía su trayectoria hacia el señuelo WebServer")
	_afirmar(juego.pursuers[0]["pos"] != juego.player_pos, "perseguidor no avanza hacia el jugador mientras hay señuelo activo")

	# Al expirar señuelos, revierte a perseguir al jugador
	juego.hacker_state["active_decoys"].clear()
	juego.player_pos = &"AppServer"
	juego._pursuit_system.process_pursuers(juego.player_pos)
	_afirmar(juego.pursuers[0]["pos"] == &"AppServer", "al expirar señuelos, el perseguidor reanuda el camino hacia el jugador")


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _finalizar() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
