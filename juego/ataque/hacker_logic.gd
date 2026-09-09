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
var bypass_stealth_active: bool = false


func setup(game: Node) -> void:
	_game = game


## Retorna la probabilidad de detección efectiva para un nodo dado.
## Bypass activo → 0.0 (infiltración fantasma).
## Nodo escaneado → probabilidad reducida a la mitad.
func get_detection_chance(node_id: StringName, base_chance: float) -> float:
	if bypass_stealth_active:
		return 0.0
	var chance := base_chance
	if _game != null and _game.hacker_state != null and _game.hacker_state.get("scanned_nodes", {}).has(str(node_id)):
		chance *= 0.5
	return chance


## Revisa eventos al ingresar a un nodo en modo hacker (ej. trampa señuelo).
## Si el nodo es una trampa señuelo y no fue escaneado antes de entrar,
## aplica una penalización de +30 de ruido. Con escaneo previo, se evita la trampa.
func on_node_entered(node_id: StringName) -> void:
	if _game == null:
		return
	var node_res = _game._find_node_resource(node_id)
	if node_res == null:
		return
	var is_decoy: bool = node_res.metadata.get("is_decoy", false)
	if is_decoy:
		var was_scanned: bool = _game.hacker_state.get("scanned_nodes", {}).has(str(node_id))
		if not was_scanned:
			HackerMechanicsClass.add_noise(_game.hacker_state, HackerMechanicsClass.NOISE_DECOY_PENALTY)
			_game.mensaje_estado = "⚠ ¡Trampa señuelo activada! (+%d ruido)" % HackerMechanicsClass.NOISE_DECOY_PENALTY
			GameLogger.warn("HackerLogic", "Trampa señuelo en %s: penalización de +%d ruido" % [node_id, HackerMechanicsClass.NOISE_DECOY_PENALTY])
		else:
			GameLogger.info("HackerLogic", "Inmunidad a trampa señuelo en %s por escaneo previo" % node_id)


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

	# Validación previa de adyacencia para el señuelo (falla sin costo de ruido ni cargo)
	if exploit_type == "decoy":
		var neighbors: Array = _game._vecinos_jugador()
		if not (_game.selected_neighbor in neighbors):
			_game.mensaje_estado = "El señuelo solo se puede colocar en un nodo vecino conectado"
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
			# Sigilo garantizado al entrar con bypass (0% detección)
			bypass_stealth_active = true
			var edge_key: String = "%s→%s" % [_game.player_pos, _game.selected_neighbor]
			var edge_exists: bool = false
			for e in _game.graph.edges:
				if e != null and e.from_id == _game.player_pos and e.to_id == _game.selected_neighbor:
					edge_exists = true
					break
			if not edge_exists:
				bypass_stealth_active = false
				_game.mensaje_estado = "Sin conexión directa a %s" % str(_game.selected_neighbor)
				_refund_exploit(exploit_type)
				_game.queue_redraw()
				return
			if _game._is_blocked(edge_key):
				_game.blocked_edges.erase(edge_key)
				_game.runtime.set_transit_cost(_game.player_pos, _game.selected_neighbor, 1.0)
			_game._mover_jugador(_game.selected_neighbor)
			bypass_stealth_active = false
		"escalate":
			# Acceder a área restringida: solo nodos conectados
			var dest_node: StringName = _game.selected_neighbor
			if dest_node in _game._vecinos_jugador():
				_game._mover_jugador(dest_node)
			else:
				var edge_exists2: bool = false
				for e in _game.graph.edges:
					if e != null and e.from_id == _game.player_pos and e.to_id == dest_node:
						edge_exists2 = true
						break
				if not edge_exists2:
					_game.mensaje_estado = "Sin conexión directa a %s" % str(dest_node)
					_refund_exploit(exploit_type)
					_game.queue_redraw()
					return
				_game._mover_jugador(dest_node)
			# Telemetría de red: escaneo automático de nodos en radio de 2 saltos
			_trigger_2_hop_telemetry(_game.player_pos)
		"persist":
			# Mantener acceso: safe haven y reducción de ruido
			var node_key: String = str(_game.selected_neighbor)
			_game.hacker_state["active_persists"][node_key] = 3
			_game.mensaje_estado = "♻ Persistencia activa en %s por 3 turnos" % str(_game.selected_neighbor)
		"decoy":
			var node_key: String = str(_game.selected_neighbor)
			_game.mensaje_estado = "🎯 Señuelo activo en %s por %d turnos" % [str(_game.selected_neighbor), HackerMechanicsClass.DECOY_DURATION_TURNS]

	_game.mensaje_estado = "%s %s aplicado en %s (ruido: %d)" % [result.get("icon", ""), result.get("name", ""), str(_game.selected_neighbor), _game.hacker_state.get("noise", 0)]
	GameLogger.debug("JuegoAtaque", "[EXPLOIT] %s en %s — ruido: %d" % [exploit_type, str(_game.selected_neighbor), _game.hacker_state.get("noise", 0)])
	# Los exploits también pueden ser la acción requerida del tutorial
	# (action_required="input") → avisar para confirmar con Enter.
	_game._notify_tutorial_input()
	check_hacker_consequences()
	if exploit_type == "decoy":
		var node_key: String = str(_game.selected_neighbor)
		_game.hacker_state["active_decoys"][node_key] = {"duration": HackerMechanicsClass.DECOY_DURATION_TURNS}
	_game.queue_redraw()


## Dispara el escaneo automático de todos los nodos dentro de un radio de 2 saltos
## desde el nodo central, sin coste adicional de ruido.
func _trigger_2_hop_telemetry(center_node: StringName) -> void:
	var queue: Array[StringName] = [center_node]
	var distances: Dictionary = {center_node: 0}
	while queue.size() > 0:
		var curr: StringName = queue.pop_front()
		var d: int = distances[curr]
		if d >= 2:
			continue
		var neighbors: Array[StringName] = []
		if _game.runtime != null:
			for n in _game.runtime.get_neighbors(curr):
				var nid: StringName = n["to_id"]
				if not neighbors.has(nid):
					neighbors.append(nid)
		if _game.graph != null and _game.graph.edges != null:
			for e in _game.graph.edges:
				if e == null:
					continue
				if e.from_id == curr and not neighbors.has(e.to_id):
					neighbors.append(e.to_id)
				elif e.to_id == curr and not neighbors.has(e.from_id):
					neighbors.append(e.from_id)
		for next_node in neighbors:
			if not distances.has(next_node):
				distances[next_node] = d + 1
				queue.append(next_node)
				var node_res = _game._find_node_resource(next_node)
				if node_res != null:
					var res: Dictionary = HackerMechanicsClass.scan_node(
						_game.hacker_state, next_node, node_res.metadata, false
					)
					_game.scan_results[str(next_node)] = res


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
		"decoy":
			noise_cost = HackerMechanicsClass.NOISE_EXPLOIT_DECOY
			if hs.has("active_decoys"):
				hs["active_decoys"].erase(str(_game.selected_neighbor))
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

	# Reducir contadores de decoy activos
	if _game.hacker_mode and _game.hacker_state.get("active_decoys", {}).size() > 0:
		var expired_decoys: Array[String] = []
		for node_key: String in _game.hacker_state["active_decoys"].keys():
			var decoy_data = _game.hacker_state["active_decoys"][node_key]
			if decoy_data is Dictionary:
				decoy_data["duration"] = int(decoy_data.get("duration", 1)) - 1
				if decoy_data["duration"] <= 0:
					expired_decoys.append(node_key)
			elif decoy_data is int:
				_game.hacker_state["active_decoys"][node_key] -= 1
				if _game.hacker_state["active_decoys"][node_key] <= 0:
					expired_decoys.append(node_key)
		for node_key: String in expired_decoys:
			_game.hacker_state["active_decoys"].erase(node_key)
			GameLogger.debug("JuegoAtaque", "Decoy expirado en %s" % node_key)

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
