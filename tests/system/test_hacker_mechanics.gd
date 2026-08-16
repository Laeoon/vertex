extends Node

## Pruebas de lógica pura para HackerMechanics (juego/system/).
##
## HackerMechanics es 100% static y no toca autoloads, así que corre vía
## `--script` sin escena. Se accede por preload (no por class_name) para no
## depender del caché global de clases en modo MainLoop personalizado.

const HM = preload("res://juego/system/hacker_mechanics.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_exploit_types()
	_test_state_creation()
	_test_exploit_economy()
	_test_noise()
	_test_alert_levels()
	_test_scan_node()
	_test_stars()
	_finalizar()


func _test_exploit_types() -> void:
	var tipos: Array = [HM.EXPLOIT_BYPASS, HM.EXPLOIT_ESCALATE, HM.EXPLOIT_PERSIST]
	for t in tipos:
		_afirmar(HM.EXPLOIT_NAMES.has(t) and HM.EXPLOIT_NAMES[t] != "",
			"exploit %s tiene nombre de UI no vacío" % t)
		_afirmar(HM.EXPLOIT_ICONS.has(t) and HM.EXPLOIT_ICONS[t] != "",
			"exploit %s tiene ícono" % t)
	# Los nombres son estilizados, no el id crudo en inglés.
	_afirmar(HM.EXPLOIT_NAMES[HM.EXPLOIT_BYPASS] == "Infiltración",
		"bypass se muestra como 'Infiltración'")


func _test_state_creation() -> void:
	var s: Dictionary = HM.create_state()
	_afirmar(s["noise"] == 0 and s["max_noise"] == 100 and s["exploits_used"] == 0,
		"create_state() por defecto: sin ruido, 0 exploits usados")
	_afirmar(s["max_exploits"] == HM.MAX_EXPLOITS_DEFAULT,
		"max_exploits por defecto = %d" % HM.MAX_EXPLOITS_DEFAULT)
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


func _test_stars() -> void:
	var perfecto: Dictionary = HM.create_state()
	_afirmar(HM.calculate_hacker_stars(perfecto, 1, 20) == 3,
		"run silenciosa y rápida → 3 estrellas")
	var malo: Dictionary = HM.create_state()
	HM.add_noise(malo, 100)
	_afirmar(HM.calculate_hacker_stars(malo, 20, 20) == 1,
		"run ruidosa y lenta → 1 estrella")


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
