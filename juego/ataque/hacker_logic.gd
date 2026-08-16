class_name HackerLogic
extends RefCounted

## Lógica del modo hacker — etapa 2 de la descomposición de juego_ataque.gd.
##
## Aporta el comportamiento de escaneo, uso de exploits y consecuencias del
## ruido. El estado (hacker_state, scan_results, selected_neighbor) permanece
## en juego_ataque.gd (patrón setup(game); ver header de pursuit_system.gd).
##
## Mejora incluida (aprobada en el plan): el refund de exploit fallido estaba
## triplicado inline (bypass sin arista, bypass sin protección, escalate sin
## arista) — se unifica en _refund_exploit() con semántica idéntica.
##
## Equivalencia congelada por
## tests/ataque/_test_hacker_logic_equivalence.{gd,tscn}.

const HackerMechanicsClass = preload("res://juego/system/hacker_mechanics.gd")

var _game: Node


func setup(game: Node) -> void:
	_game = game


## Puerto del viejo juego_ataque._scan_selected_node(). El SFX vive acá (como
## el "move" en GameLogic.mover_jugador) para que el handler sea delgado (P5).
func scan_selected_node() -> void:
	AudioManager.play_sfx("scan")
	if _game.selected_neighbor == &"":
		_game.mensaje_estado = "Selecciona un nodo para escanear [X]"
		_game.queue_redraw()
		return
	var node_res = _game._find_node_resource(_game.selected_neighbor)
	if node_res == null:
		return
	var result: Dictionary = HackerMechanicsClass.scan_node(_game.hacker_state, _game.selected_neighbor, node_res.metadata)
	_game.scan_results[str(_game.selected_neighbor)] = result
	var type_label: String = result.get("node_type", "unknown")
	var hint: String = result.get("exploit_hint", "")
	_game.mensaje_estado = "ESCANEADO %s → %s | %s" % [str(_game.selected_neighbor), type_label.to_upper(), hint]
	GameLogger.debug("JuegoAtaque", "[SCAN] %s: %s — %s" % [str(_game.selected_neighbor), type_label, hint])
	# El escaneo es una acción de tutorial (try_scan) → avisar al tutorial
	# para que marque el paso como cumplido.
	_game._notify_tutorial_input()
	_game.queue_redraw()


## Puerto del viejo juego_ataque._use_hacker_exploit() con el refund unificado
## (SFX acá, como "scan" — ver scan_selected_node).
func use_hacker_exploit(exploit_type: String) -> void:
	AudioManager.play_sfx("exploit")
	if _game.selected_neighbor == &"":
		_game.mensaje_estado = "Selecciona un nodo para explotar"
		_game.queue_redraw()
		return
	var result: Dictionary = HackerMechanicsClass.use_exploit(_game.hacker_state, exploit_type, _game.selected_neighbor)
	if not result.get("success", false):
		_game.mensaje_estado = result.get("reason", "Exploit fallido")
		_game.queue_redraw()
		return
	# Aplicar efecto del exploit
	match exploit_type:
		"bypass":
			# Saltar protección: solo funciona en nodos conectados
			if _game.selected_neighbor in _game._vecinos_jugador():
				_game._mover_jugador(_game.selected_neighbor)
			else:
				# Verificar que existe una arista (bloqueada o no)
				var edge_key: String = "%s→%s" % [_game.player_pos, _game.selected_neighbor]
				var edge_exists: bool = false
				for e in _game.graph.edges:
					if e != null and e.from_id == _game.player_pos and e.to_id == _game.selected_neighbor:
						edge_exists = true
						break
				if not edge_exists:
					_game.mensaje_estado = "Sin conexión directa a %s" % str(_game.selected_neighbor)
					_refund_exploit(exploit_type)
					_game.queue_redraw()
					return
				if _game._is_blocked(edge_key):
					_game.blocked_edges.erase(edge_key)
					_game.runtime.set_transit_cost(_game.player_pos, _game.selected_neighbor, 1.0)
					_game._mover_jugador(_game.selected_neighbor)
				else:
					_game.mensaje_estado = "No hay protección que saltar en %s" % str(_game.selected_neighbor)
					_refund_exploit(exploit_type)
					_game.queue_redraw()
					return
		"escalate":
			# Acceder a área restringida: solo nodos conectados
			if _game.selected_neighbor in _game._vecinos_jugador():
				_game._mover_jugador(_game.selected_neighbor)
			else:
				var edge_exists2: bool = false
				for e in _game.graph.edges:
					if e != null and e.from_id == _game.player_pos and e.to_id == _game.selected_neighbor:
						edge_exists2 = true
						break
				if not edge_exists2:
					_game.mensaje_estado = "Sin conexión directa a %s" % str(_game.selected_neighbor)
					_refund_exploit(exploit_type)
					_game.queue_redraw()
					return
				_game._mover_jugador(_game.selected_neighbor)
		"persist":
			# Mantener acceso: permite moverte a través de bloqueos y evita
			# decay de ruido por 3 turnos
			var node_key: String = str(_game.selected_neighbor)
			_game.hacker_state["active_persists"][node_key] = 3
			_game.mensaje_estado = "♻ Persistencia activa en %s por 3 turnos" % str(_game.selected_neighbor)
	_game.mensaje_estado = "%s %s aplicado en %s (ruido: %d)" % [result.get("icon", ""), result.get("name", ""), str(_game.selected_neighbor), _game.hacker_state.get("noise", 0)]
	GameLogger.debug("JuegoAtaque", "[EXPLOIT] %s en %s — ruido: %d" % [exploit_type, str(_game.selected_neighbor), _game.hacker_state.get("noise", 0)])
	# Los exploits también pueden ser la acción requerida del tutorial
	# (action_required="input") → avisar para confirmar con Enter.
	_game._notify_tutorial_input()
	check_hacker_consequences()
	_game.queue_redraw()


## Devuelve un exploit consumido por un camino fallido: restaura stock,
## uso y ruido. Unifica los 3 refunds inline duplicados del original
## (bypass sin arista / bypass sin protección / escalate sin arista).
func _refund_exploit(exploit_type: String) -> void:
	var hs: Dictionary = _game.hacker_state
	hs["exploits"][exploit_type] = hs["exploits"].get(exploit_type, 0) + 1
	hs["exploits_used"] = maxi(hs["exploits_used"] - 1, 0)
	var noise_cost: int = 0
	match exploit_type:
		"bypass":
			noise_cost = HackerMechanicsClass.NOISE_EXPLOIT_BYPASS
		"escalate":
			noise_cost = HackerMechanicsClass.NOISE_EXPLOIT_ESCALATE
		"persist":
			noise_cost = HackerMechanicsClass.NOISE_EXPLOIT_PERSIST
	hs["noise"] = maxi(hs["noise"] - noise_cost, 0)


## Puerto del viejo juego_ataque._check_hacker_consequences().
func check_hacker_consequences() -> void:
	# Reducir contadores de persist activos
	if _game.hacker_mode and _game.hacker_state.get("active_persists", {}).size() > 0:
		var expired: Array[String] = []
		for node_key: String in _game.hacker_state["active_persists"].keys():
			_game.hacker_state["active_persists"][node_key] -= 1
			if _game.hacker_state["active_persists"][node_key] <= 0:
				expired.append(node_key)
		for node_key: String in expired:
			_game.hacker_state["active_persists"].erase(node_key)
			GameLogger.debug("JuegoAtaque", "Persist expirado en %s" % node_key)

	var alert_level: String = HackerMechanicsClass.get_alert_level(_game.hacker_state)
	match alert_level:
		"critical":
			_game.mensaje_estado = "⚠ RUIDO CRÍTICO — Seguridad máxima activada"
			# Perseguidor extra en ruido crítico (spawn vía PursuitSystem).
			if _game.hacker_state.get("noise", 0) >= 85 and _game.pursuers.size() < 4:
				var spawn_node: StringName = _game._pursuit_system.find_spawn_node(_game.player_pos, _game._find_node_resource(_game.player_pos))
				_game._pursuit_system.spawn_pursuer(spawn_node, 1, 2)
		"high":
			_game.mensaje_estado = "⚠ Ruido alto — cuidado con los movimientos"
		"low":
			pass
