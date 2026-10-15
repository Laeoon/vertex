class_name DefenderBrain extends RefCounted
## Encapsula toda la lógica y estado del modo defensor.
## Emite señales para que juego_ataque.gd reaccione (UI, progreso, etc.).

signal defender_won(reason: String, stars: int)
signal defender_lost(reason: String)
signal message(text: String)
signal state_changed()
signal path_calculated(from: StringName, to: StringName, path: Array[StringName], cost: float)

const DEFENSIVE_PATHFINDER = preload("res://core/agents/defensive_pathfinder.gd")
const StrategicAnalyzer = preload("res://core/agents/strategic_analyzer.gd")

# ─── Estado defensor ──────────────────────────────────────────────
var firewall_cost: int = 2  # Costo de firewall (configurable por nivel)
var enemy_pos: StringName = &""
var enemy_start_node: StringName = &""
var enemy_target_node: StringName = &""
var enemy_path: Array[StringName] = []
var selected_edge: String = ""
var hovered_edge: String = ""
var defender_blocks_placed: int = 0
var defender_blocks_total_used: int = 0
var defender_blocks_per_turn: int = 2
var defender_block_duration: int = 4
var defender_max_blocks: int = 999
var node_firewalls: Dictionary = {}  # node_id -> true
var firewall_mode: bool = false
var min_cut_analysis: Dictionary = {}

# ─── Nuevas mecánicas Blue Team (Fase 2) ───────────────────────────
var forensics_trace: float = 0.0          # 0.0 .. 100.0 (condición de victoria)
var base_trace_per_turn: float = 20.0     # +20% por turno contenido
var bonus_trace_on_divert: float = 10.0   # +10% si el atacante fue forzado a desvío o sondeo
var quarantined_nodes: Dictionary = {}    # {StringName: true} nodos en cuarentena / aislados
var quarantined_count: int = 0

var _game: Node  # referencia a juego_ataque.gd
var _graph = null
var _runtime = null


func setup(game: Node, params: Dictionary) -> void:
	"""Configura el brain con referencias al juego y parámetros iniciales."""
	_game = game
	_graph = game.graph
	_runtime = game.runtime
	enemy_start_node = params.get("enemy_start", &"") as StringName
	enemy_target_node = params.get("enemy_target", &"") as StringName
	defender_blocks_per_turn = params.get("blocks_per_turn", 2)
	defender_block_duration = params.get("block_duration", 4)
	firewall_cost = params.get("firewall_cost", 2)


func init() -> void:
	"""Inicializa el estado del modo defensor."""
	if _graph == null:
		return
	enemy_pos = enemy_start_node
	defender_blocks_placed = 0
	defender_blocks_total_used = 0
	selected_edge = ""
	hovered_edge = ""
	node_firewalls.clear()
	quarantined_nodes.clear()
	quarantined_count = 0
	forensics_trace = 0.0
	firewall_mode = false
	calc_enemy_path()
	message.emit("🛡️ DEFENSOR — Contén al intruso mientras se completa el rastreo forense EDR")
	GameLogger.info("DefenderBrain", "Defensor iniciado. Enemigo en: %s, objetivo: %s" % [enemy_pos, enemy_target_node])

	# Análisis estratégico — corte mínimo
	if _graph != null and enemy_start_node != &"" and enemy_target_node != &"":
		min_cut_analysis = StrategicAnalyzer.find_min_cut(_graph, enemy_start_node, enemy_target_node)
		if not min_cut_analysis.is_empty() and not min_cut_analysis["cut_edges"].is_empty():
			GameLogger.debug("DefenderBrain", "Corte mínimo: flujo máximo = %.1f, %d aristas sugeridas" % [
				min_cut_analysis.get("max_flow", 0.0),
				min_cut_analysis["cut_edges"].size()
			])
			var edge_list: String = ""
			for ce in min_cut_analysis["cut_edges"]:
				edge_list += " %s→%s" % [ce["from_id"], ce["to_id"]]
			GameLogger.debug("DefenderBrain", "Sugeridas:%s" % edge_list)
		else:
			GameLogger.debug("DefenderBrain", "Corte mínimo: sin resultados")
	state_changed.emit()


func calc_enemy_path() -> void:
	"""Recalcula la ruta del enemigo desde su posición actual hasta su objetivo."""
	if _graph == null or enemy_pos == &"" or enemy_target_node == &"":
		return
	if enemy_pos == enemy_target_node:
		enemy_path.clear()
		return
	var result: Dictionary = DefensivePathfinder.find_path_with_cost(_graph, enemy_pos, enemy_target_node, _runtime)
	if result["reachable"] and not result["path"].is_empty():
		enemy_path = result["path"]
		GameLogger.debug("DefenderBrain", "Ruta enemiga recalculada: %s" % str(enemy_path))
		path_calculated.emit(enemy_pos, enemy_target_node, enemy_path, result.get("cost", 0.0))
	else:
		enemy_path.clear()
		GameLogger.debug("DefenderBrain", "Enemigo sin ruta hacia %s" % str(enemy_target_node))


func block_edge(edge_key: String) -> void:
	"""Bloquea una arista. Si aísla al atacante → VICTORIA."""
	if _game.game_over or defender_blocks_placed >= defender_blocks_per_turn:
		return
	if defender_blocks_total_used >= defender_max_blocks:
		message.emit("⚠ Sin recursos de bloqueo disponibles")
		return
	var parts: PackedStringArray = edge_key.split("→")
	if parts.size() != 2:
		return
	var from_n: StringName = parts[0] as StringName
	var to_n: StringName = parts[1] as StringName

	if _is_blocked(edge_key):
		message.emit("⚠ Arista ya bloqueada")
		state_changed.emit()
		return

	var target_check: StringName = enemy_target_node if enemy_target_node != &"" else _game.target_node
	var orig: float = _find_original_cost(from_n, to_n)
	if orig < 0:
		message.emit("⚠ No existe conexión de %s a %s" % [str(from_n), str(to_n)])
		return

	# Verificar si está en la ruta actual del enemigo
	var is_in_path: bool = false
	if enemy_path.size() >= 2:
		for i in enemy_path.size() - 1:
			var ek: String = "%s→%s" % [str(enemy_path[i]), str(enemy_path[i + 1])]
			if ek == edge_key:
				is_in_path = true
				break

	# Bloquear via game (shared method)
	_block_edge_in_game(edge_key, from_n, to_n)
	defender_blocks_placed += 1
	defender_blocks_total_used += 1

	# Recalcular ruta
	var old_path_size: int = enemy_path.size()
	calc_enemy_path()

	var remaining: int = defender_blocks_per_turn - defender_blocks_placed
	var blocks_left: int = defender_max_blocks - defender_blocks_total_used
	var feedback: String = "✅ Arista bloqueada"
	if is_in_path:
		feedback += " (ruta principal cortada!)"
	elif old_path_size >= 2 and (enemy_path.is_empty() or enemy_path.size() < old_path_size):
		feedback += " (ruta forzada a desvío!)"
	else:
		feedback += " (ruta alternativa)"
	if remaining > 0:
		feedback += " — Quedan %d bloqueo(s). [Enter] para resolver" % remaining
	else:
		feedback += " — [Enter] para resolver"
	if blocks_left <= 5:
		feedback += " (%d restantes)" % blocks_left
	GameLogger.debug("DefenderBrain", "DEFENSOR bloquea: %s (%d/%d turno, %d totales)" % [edge_key, defender_blocks_placed, defender_blocks_per_turn, defender_blocks_total_used])
	selected_edge = edge_key
	message.emit(feedback)
	state_changed.emit()


func resolve_turn() -> void:
	"""Finaliza el turno del defensor, acumula trace EDR y mueve al atacante."""
	var is_over: bool = _game.game_over
	var cur_turn: int = _game.turn
	if is_over:
		return
	if defender_blocks_placed == 0:
		message.emit("⚠ Coloca al menos 1 bloqueo antes de resolver el turno")
		state_changed.emit()
		return

	# Avanzar turno en el juego
	_game.turn = cur_turn + 1
	_limpiar_bloqueos_expirados()

	# Acumular progreso de Trace Forense EDR
	var trace_gain: float = base_trace_per_turn
	var target_check: StringName = enemy_target_node if enemy_target_node != &"" else _game.target_node
	var pre_path: Dictionary = DefensivePathfinder.find_path_with_cost(_graph, enemy_pos, target_check, _runtime)
	if not pre_path.get("reachable", false) or pre_path.get("path", []).size() < 2:
		# Si el atacante no tiene ruta directa libre, bonus por demorarlo/desviarlo
		trace_gain += bonus_trace_on_divert

	forensics_trace = minf(100.0, forensics_trace + trace_gain)
	GameLogger.debug("DefenderBrain", "Turno %d: Forensics Trace +%.1f%% -> %.1f%%" % [_game.turn, trace_gain, forensics_trace])

	# Chequeo de victoria por Trace Forense al 100%
	if forensics_trace >= 100.0:
		_win("¡Rastreo EDR completado! Origen del ataque neutralizado.")
		return

	move_enemy()
	if _game.game_over:
		return

	# Resetear estado del turno
	defender_blocks_placed = 0
	selected_edge = ""
	hovered_edge = ""
	calc_enemy_path()

	cur_turn = _game.turn
	var max_turns: int = _game.max_turns
	if max_turns > 0 and cur_turn >= max_turns:
		if enemy_pos != enemy_target_node:
			_win("¡Asedio resistido! El atacante agotó sus recursos de intrusión.")
		else:
			_lose("Atacante alcanzó %s justo a tiempo" % str(enemy_target_node))
		return

	var blocks_info: String = ""
	var remaining_blocks: int = defender_max_blocks - defender_blocks_total_used
	if remaining_blocks <= 5:
		blocks_info = " (%d restantes)" % remaining_blocks
	message.emit("🛡️ Turno %d // TRACE EDR: %.0f%% — Coloca hasta %d bloqueo(s)%s." % [cur_turn, forensics_trace, defender_blocks_per_turn, blocks_info])
	state_changed.emit()


func move_enemy() -> void:
	"""Mueve al atacante con movimiento lateral adaptativo."""
	if enemy_pos == &"":
		return
	var target_check: StringName = enemy_target_node if enemy_target_node != &"" else _game.target_node

	# 1. Intentar encontrar la mejor ruta hacia el objetivo
	var result: Dictionary = DefensivePathfinder.find_path_with_cost(_graph, enemy_pos, target_check, _runtime)
	var next_step: StringName = &""

	if result.get("reachable", false) and result.get("path", []).size() >= 2:
		next_step = result["path"][1] as StringName
		enemy_path = result["path"]
	else:
		# 2. Movimiento Lateral (MITRE T1021): si no hay camino directo, buscar un vecino accesible no bloqueado
		var best_neighbor: StringName = &""
		var min_h_cost: float = INF

		for e in _graph.edges:
			if e == null or e.from_id != enemy_pos:
				continue
			var ek: String = "%s→%s" % [e.from_id, e.to_id]
			if _is_blocked(ek) or quarantined_nodes.has(e.to_id):
				continue
			if _runtime != null and is_inf(_runtime.get_transit_cost(e.from_id, e.to_id)):
				continue

			# Evaluar heurística desde ese vecino hacia el target
			var test_p: Dictionary = DefensivePathfinder.find_path_with_cost(_graph, e.to_id, target_check, _runtime)
			var h_cost: float = test_p.get("cost", 99.0) if test_p.get("reachable", false) else 999.0
			if h_cost < min_h_cost:
				min_h_cost = h_cost
				best_neighbor = e.to_id

		if best_neighbor != &"":
			next_step = best_neighbor
			enemy_path = [enemy_pos, best_neighbor]
		else:
			# El atacante está totalmente cercado este turno: se queda sondeando y gana tiempo
			GameLogger.debug("DefenderBrain", "ATACANTE contenido en %s. Sondeando puertos..." % enemy_pos)
			message.emit("¡ATACANTE contenido temporalmente en %s! Sondeando alternativas..." % str(enemy_pos))
			state_changed.emit()
			return

	GameLogger.debug("DefenderBrain", "ATACANTE: %s → %s (hacia %s)" % [enemy_pos, next_step, target_check])
	enemy_pos = next_step
	# Notificar al juego para flash visual
	if _game.has_method("_on_enemy_moved"):
		_game._on_enemy_moved()
	path_calculated.emit(enemy_pos, enemy_target_node, enemy_path, result.get("cost", 0.0))
	state_changed.emit()

	if enemy_pos == target_check:
		_lose("¡Brecha crítica! El atacante vulneró %s" % target_check)
		return
	message.emit("ATACANTE avanzó a %s — Bloquea rutas!" % str(enemy_pos))


func quarantine_node(node_id: StringName) -> void:
	"""Aisla de emergencia un nodo (Host Quarantine), cortando todas sus conexiones."""
	if _game.game_over:
		return
	if node_id == enemy_start_node or node_id == enemy_target_node:
		message.emit("⚠ No puedes aislar la entrada perimetral ni el Núcleo")
		return
	if quarantined_nodes.has(node_id):
		message.emit("⚠ Ese nodo ya está en cuarentena")
		return

	quarantined_nodes[node_id] = true
	quarantined_count += 1

	# Cortar todas las aristas entrantes y salientes en el runtime
	var severed: int = 0
	for e in _graph.edges:
		if e == null:
			continue
		if e.from_id == node_id or e.to_id == node_id:
			if _runtime != null:
				_runtime.set_transit_cost(e.from_id, e.to_id, INF)
			severed += 1

	calc_enemy_path()
	var feedback: String = "☣ NODO EN CUARENTENA: %s aislado de la red (%d aristas desconectadas)" % [str(node_id), severed]
	GameLogger.info("DefenderBrain", "CUARENTENA en %s: %d aristas desconectadas" % [node_id, severed])
	message.emit(feedback)
	state_changed.emit()


func is_node_quarantined(node_id: StringName) -> bool:
	return quarantined_nodes.has(node_id)


func place_firewall(node_id: StringName) -> void:
	"""Coloca un firewall PERMANENTE en un nodo."""
	if _game.game_over:
		return
	if node_id == enemy_pos or node_id == enemy_target_node:
		message.emit("⚠ No puedes poner firewall donde está el atacante o su objetivo")
		return
	if node_firewalls.has(node_id):
		message.emit("⚠ Ese nodo ya tiene firewall")
		return
	if node_id == &"":
		return

	if defender_blocks_placed + firewall_cost > defender_blocks_per_turn:
		message.emit("⚠ Un firewall cuesta %d bloqueos — no te alcanzan (tienes %d/%d este turno)" % [firewall_cost, defender_blocks_per_turn - defender_blocks_placed, defender_blocks_per_turn])
		return
	if defender_blocks_total_used + firewall_cost > defender_max_blocks:
		message.emit("⚠ Sin presupuesto para más bloqueos")
		return

	# Bloquear TODAS las aristas entrantes al nodo permanentemente
	var edges_blocked: int = 0
	for e in _graph.edges:
		if e == null:
			continue
		if e.to_id != node_id:
			continue
		var ek: String = "%s→%s" % [e.from_id, e.to_id]
		if _is_blocked(ek):
			continue
		_runtime.set_transit_cost(e.from_id, e.to_id, INF)
		node_firewalls[node_id] = true
		edges_blocked += 1

	if edges_blocked == 0:
		message.emit("⚠ No hay aristas entrantes que bloquear en %s" % str(node_id))
		return

	defender_blocks_placed += firewall_cost
	defender_blocks_total_used += firewall_cost

	var actual_target: StringName = enemy_target_node if enemy_target_node != &"" else _game.target_node
	var iso: Dictionary = DefensivePathfinder.find_path_with_cost(_graph, enemy_pos, actual_target, _runtime)
	if not iso["reachable"] or iso["path"].is_empty():
		_win("¡Firewall estratégico! Aislaste al atacante de %s" % str(actual_target))
		return

	calc_enemy_path()

	var remaining: int = defender_blocks_per_turn - defender_blocks_placed
	var feedback: String = "🧱 Firewall plantado en %s (%d aristas selladas)" % [str(node_id), edges_blocked]
	if remaining > 0:
		feedback += " — Quedan %d bloqueo(s). [Enter] para resolver" % remaining
	else:
		feedback += " — [Enter] para resolver"
	GameLogger.debug("DefenderBrain", "FIREWALL en %s: %d aristas bloqueadas permanentemente" % [node_id, edges_blocked])
	message.emit(feedback)
	state_changed.emit()


func toggle_firewall_mode() -> void:
	firewall_mode = not firewall_mode
	if firewall_mode:
		message.emit("🔥 MODO CORTARRUEGOS: haz clic en un NODO para plantar firewall permanente (costo: %d bloqueos)" % firewall_cost)
	else:
		message.emit("🛡️ MODO BLOQUEO: haz clic en una ARISTA para bloquear temporalmente")
	state_changed.emit()


func set_hovered_edge(edge: String) -> void:
	hovered_edge = edge
	state_changed.emit()


func calcular_estrellas() -> int:
	var turn: int = _game.turn
	var max_turns: int = _game.max_turns
	var turnos_ratio: float = 1.0 - (float(turn) / float(max_turns)) if max_turns > 0 else 1.0
	var max_blocks_est: int = defender_max_blocks if defender_max_blocks > 0 else (defender_blocks_per_turn * max_turns + 2)
	var eficiencia: float = 1.0 - (float(defender_blocks_total_used) / float(max_blocks_est)) if max_blocks_est > 0 else 1.0
	var penalizacion_cuarentena: float = float(quarantined_count) * 0.15
	var score: float = (eficiencia * 0.5) + (turnos_ratio * 0.5) - penalizacion_cuarentena
	if score >= 0.65:
		return 3
	if score >= 0.35:
		return 2
	return 1


# ─── Helpers internos ─────────────────────────────────────────────

func _is_blocked(edge_key: String) -> bool:
	if _game == null or not _game.has_method("_is_blocked"):
		return false
	return _game._is_blocked(edge_key)


func _block_edge_in_game(edge_key: String, from_n: StringName, to_n: StringName) -> void:
	if _game == null or not _game.has_method("_block_edge"):
		return
	_game._block_edge(edge_key, from_n, to_n)


func _limpiar_bloqueos_expirados() -> void:
	if _game == null or not _game.has_method("_limpiar_bloqueos_expirados"):
		return
	_game._limpiar_bloqueos_expirados()


func _find_original_cost(from_n: StringName, to_n: StringName) -> float:
	for e in _graph.edges:
		if e != null and e.from_id == from_n and e.to_id == to_n:
			return e.transit_cost
	return -1.0


func _win(reason: String) -> void:
	var stars: int = calcular_estrellas()
	var star_str: String = ""
	for i in range(3):
		star_str += "★" if i < stars else "☆"
	var msg: String = "✅ VICTORIA DEFENSIVA: %s  %s" % [reason, star_str]
	GameLogger.info("DefenderBrain", "VICTORIA DEFENSIVA: %s | estrellas: %d" % [reason, stars])
	defender_won.emit(reason, stars)
	message.emit(msg)
	state_changed.emit()


func _lose(reason: String) -> void:
	var msg: String = "DERROTA: %s" % reason
	GameLogger.info("DefenderBrain", "DERROTA: %s" % reason)
	defender_lost.emit(reason)
	message.emit(msg)
	state_changed.emit()
