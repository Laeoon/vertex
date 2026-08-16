class_name GameState
extends RefCounted

## Estado del juego y ciclo de vida de bloqueos — etapa 1 de la
## descomposición de juego_ataque.gd (slice 3).
##
## Patrón del proyecto (ver header de pursuit_system.gd): el estado mutable
## PERMANECE declarado en juego_ataque.gd porque GameRenderer, los demás
## servicios y los tests lo leen de ahí (DefenderBrain escribe `turn`,
## cuatro servicios escriben `mensaje_estado`, los tests leen
## `player_pos` directo). Este módulo aporta el COMPORTAMIENTO de estado:
## reset, target actual, lookup de nodos y el ciclo de bloqueos.
##
## Equivalencia congelada por
## tests/ataque/_test_game_state_equivalence.{gd,tscn}.

const NetworkRuntimeClass = preload("res://core/network/network_runtime.gd")
const HackerMechanicsClass = preload("res://juego/system/hacker_mechanics.gd")
const NetworkGraphResource = preload("res://core/network/network_graph_resource.gd")
const DefensivePathfinderClass = preload("res://core/agents/defensive_pathfinder.gd")

var _game: Node


func setup(game: Node) -> void:
	_game = game


## Puerto del bloque de lectura de SceneParams del viejo _ready() (P5).
func cargar_params() -> void:
	_game.graph_path = SceneParams.graph_path
	_game.start_node = SceneParams.start_node
	_game.target_node = SceneParams.target_node
	_game.waypoints = SceneParams.waypoints
	_game.ai_enabled = SceneParams.ai_enabled
	_game.ai_block_per_turn = SceneParams.ai_block_per_turn
	_game.ai_bloquea_al_inicio = SceneParams.ai_bloquea_al_inicio
	_game.max_ai_blocks = SceneParams.max_ai_blocks
	_game.max_turns = SceneParams.max_turns
	_game.max_movement_points = SceneParams.max_movement_points
	_game.titulo_nivel = SceneParams.titulo_nivel
	_game.mensaje_tutorial = SceneParams.mensaje_tutorial
	_game.tutorial_path = SceneParams.tutorial_path
	SceneParams.tutorial_path = ""
	_game.hacker_mode = SceneParams.hacker_mode
	_game.defender_mode = SceneParams.defender_mode
	_game.defender_blocks_per_turn = SceneParams.defender_blocks_per_turn
	_game.defender_block_duration = SceneParams.defender_block_duration
	_game.enemy_start_node = SceneParams.enemy_start_node
	_game.enemy_target_node = SceneParams.enemy_target_node
	_game.defender_max_blocks = SceneParams.defender_max_blocks
	_game.firewall_cost = SceneParams.firewall_cost
	_game.block_duration = SceneParams.block_duration
	_game.pursuer_delay = SceneParams.pursuer_delay
	_game.pursuer_max = SceneParams.max_pursuers
	_game.pursuer_speed = SceneParams.pursuer_speed
	_game.level_key = SceneParams.level_key
	_game._budget_display = float(_game.max_movement_points)


## Puerto del viejo juego_ataque._load_graph() (P5): carga y valida el grafo,
## pobla node_positions/_node_cache y resetea el estado.
func load_graph() -> void:
	if _game.graph_path == "":
		_game.mensaje_estado = "ERROR: graph_path vacio"
		push_error("Juego: graph_path esta vacio")
		_game.queue_redraw()
		return

	var graph_res = load(_game.graph_path) as NetworkGraphResource
	if graph_res == null:
		_game.mensaje_estado = "ERROR: no se pudo cargar el grafo: %s" % _game.graph_path
		push_error("Juego: no se pudo cargar ", _game.graph_path)
		_game.queue_redraw()
		return

	var errors: Array[String] = graph_res.validate()
	if not errors.is_empty():
		var msg: String = "ERROR en grafo %s:" % _game.graph_path
		for e in errors:
			push_error(e)
			msg += "\n  - " + e
		_game.mensaje_estado = msg
		_game.queue_redraw()
		return

	_game.graph = graph_res
	_game.node_positions.clear()
	_game._node_cache.clear()
	for n in graph_res.nodes:
		if n == null:
			continue
		_game.node_positions[n.id] = n.position
		_game._node_cache[n.id] = n

	reset_state()


## Snapshot {edge_key: true} de aristas bloqueadas para el renderer (P5/tarea
## 3: datos en lugar del callable is_blocked_func). Usa el mismo criterio que
## is_blocked(): bloqueos temporales + costo INF del runtime (firewalls).
func blocked_edge_keys() -> Dictionary:
	var out: Dictionary = {}
	if _game.graph == null:
		return out
	for e in _game.graph.edges:
		if e == null:
			continue
		var key: String = "%s→%s" % [e.from_id, e.to_id]
		if is_blocked(key):
			out[key] = true
	return out


## Puerto del viejo juego_ataque._edge_en_posicion() (P5): hit-test de
## aristas para el modo defensor; el input handler lo consume por duck-typing.
func edge_en_posicion(pos: Vector2) -> String:
	if _game.graph == null or _game.node_positions.is_empty():
		return ""
	var best_edge: String = ""
	var best_dist: float = 30.0  # Radio de clic en píxeles
	for e in _game.graph.edges:
		if e == null:
			continue
		var from_pos: Vector2 = _game.node_positions.get(e.from_id, Vector2.ZERO) as Vector2
		var to_pos: Vector2 = _game.node_positions.get(e.to_id, Vector2.ZERO) as Vector2
		if from_pos == Vector2.ZERO or to_pos == Vector2.ZERO:
			continue
		# Distancia punto a segmento
		var ab: Vector2 = to_pos - from_pos
		var ap: Vector2 = pos - from_pos
		var t: float = ap.dot(ab) / ab.length_squared() if ab.length_squared() > 0 else 0.0
		t = clampf(t, 0.0, 1.0)
		var closest: Vector2 = from_pos + ab * t
		var d: float = pos.distance_to(closest)
		if d < best_dist:
			best_dist = d
			best_edge = "%s→%s" % [e.from_id, e.to_id]
	return best_edge


## Puerto del viejo juego_ataque._nodo_en_posicion() (P5).
func nodo_en_posicion(pos: Vector2) -> StringName:
	for nid in _game.node_positions.keys():
		var npos: Vector2 = _game.node_positions[nid] as Vector2
		if npos.distance_to(pos) <= _game.node_radius + 22.0:
			return nid as StringName
	return &""


## Puerto del viejo juego_ataque._nodo_en_posicion_firewall() (P5): radio más
## generoso para colocar firewalls de nodo.
func nodo_en_posicion_firewall(pos: Vector2) -> StringName:
	for nid in _game.node_positions.keys():
		var npos: Vector2 = _game.node_positions[nid] as Vector2
		if npos.distance_to(pos) <= _game.node_radius + 30.0:
			return nid as StringName
	return &""


## Empaqueta TODO lo que consume GameRenderer.draw_frame() — diccionario de
## datos puro, sin callables (P5/tarea 3). Precondición: _draw() ya validó el
## brain (modo defensor) y runtime/graph != null.
func frame_data(vp_size: Vector2) -> Dictionary:
	var def: bool = _game.defender_mode
	var b = _game._defender_brain
	var tp = _game.tutorial_player
	var stars: int = b.calcular_estrellas() if def else _game._progress_service.calculate_stars()
	return {
		"vp_size": vp_size,
		"defender_mode": def,
		"turn": _game.turn,
		"max_turns": _game.max_turns,
		"game_over": _game.game_over,
		"game_won": _game.game_won,
		"game_over_time": _game._game_over_time,
		"graph": _game.graph,
		"node_positions": _game.node_positions,
		"node_radius": _game.node_radius,
		"node_cache": _game._node_cache,
		"current_path": _game.current_path,
		"blocked_edges": _game.blocked_edges,
		"blocked_keys": blocked_edge_keys(),
		"unblock_flash_time": _game._unblock_flash_time,
		"unblock_flash_edge": _game._unblock_flash_edge,
		"enemy_move_flash_time": _game._enemy_move_flash_time,
		"titulo_nivel": _game.titulo_nivel,
		"player_pos": _game.player_pos,
		"target": target_actual(),
		"neighbors": _game._game_logic.vecinos_jugador(),
		"player_total_cost": _game.player_total_cost,
		"waypoints": _game.waypoints,
		"waypoint_idx": _game.current_waypoint_idx,
		"pursuers": _game.pursuers,
		"alerted_nodes": _game.alerted_nodes,
		"movement_points": _game.movement_points,
		"max_movement_points": _game.max_movement_points,
		"budget_display": _game._budget_display,
		"hacker_mode": _game.hacker_mode,
		"hacker_state": _game.hacker_state,
		"scan_results": _game.scan_results,
		"selected_neighbor": _game.selected_neighbor,
		"mensaje_estado": _game.mensaje_estado,
		"mensaje_tutorial": _game.mensaje_tutorial,
		"show_optimal_overlay": _game.show_optimal_overlay,
		"optimal_overlay_path": _game.optimal_overlay_path,
		"tutorial_player": tp,
		"tutorial_arrow_pos": (&"" if def else _game.player_pos),
		"es_tutorial": (tp != null and is_instance_valid(tp)),
		"stars": stars,
		"brain_blocks_placed": (b.defender_blocks_placed if def else 0),
		"brain_blocks_per_turn": (b.defender_blocks_per_turn if def else 0),
		"brain_enemy_pos": (b.enemy_pos if def else &""),
		"brain_enemy_target": (b.enemy_target_node if def else &""),
		"brain_min_cut": (b.min_cut_analysis if def else {}),
		"brain_firewalls": (b.node_firewalls if def else {}),
		"brain_firewall_mode": (b.firewall_mode if def else false),
		"brain_hovered_edge": (b.hovered_edge if def else ""),
		"brain_enemy_path": (b.enemy_path if def else []),
	}


## Puerto del viejo juego_ataque.reset_state() (pre-slice-3).
func reset_state() -> void:
	if _game.graph == null:
		return

	_game.runtime = NetworkRuntimeClass.new(_game.graph)
	_game.blocked_edges.clear()
	_game._ai_blocks_used = 0
	_game.turn = 0
	_game.game_over = false
	_game.game_won = false
	_game.current_path.clear()
	_game.showing_path = false
	_game.player_pos = _game.start_node
	_game.current_waypoint_idx = -1 if _game.waypoints.is_empty() else 0
	# Detección/persecución: limpieza en `_pursuit_system.reset()` (porta el
	# viejo `alerted_nodes.clear()` + `pursuers.clear()` + `_pursuer_next_id=1`).
	_game._pursuit_system.reset()
	_game.show_optimal_overlay = false
	_game.optimal_overlay_path.clear()
	_game.player_total_cost = 0.0
	_game.movement_points = _game.max_movement_points
	_game._turn_locked_until = 0.0

	if _game.hacker_mode:
		var starting_exploits: Dictionary = SceneParams.starting_exploits
		_game.hacker_state = HackerMechanicsClass.create_state()
		for exploit_type in starting_exploits:
			HackerMechanicsClass.grant_exploits(_game.hacker_state, exploit_type, starting_exploits[exploit_type])
		_game.scan_results.clear()

	# Reiniciar tutorial si existe
	if _game.tutorial_player != null and is_instance_valid(_game.tutorial_player):
		if _game.tutorial_path != "" and _game.tutorial_player.load_tutorial(_game.tutorial_path):
			_game.tutorial_player.start()
			GameLogger.info("JuegoAtaque", "Tutorial reiniciado en reset_state")

	if _game.defender_mode:
		_game.enemy_pos = _game.enemy_start_node if _game.enemy_start_node != &"" else _game.target_node
		_game.defender_blocks_placed = 0
		_game.defender_blocks_total_used = 0
		_game.defender_max_blocks = _game.defender_blocks_per_turn * _game.max_turns + 2 if _game.max_turns > 0 else 999
		_game.selected_edge = ""
		_game.hovered_edge = ""
		_game.node_firewalls.clear()
		_game.firewall_mode = false
		_game.ai_enabled = true
		_game.mensaje_estado = "DEFENSOR: Bloquea aristas para detener al atacante"
		# Recrear brain si es un reset durante la partida
		if _game._defender_brain != null:
			_game._init_defender_mode()
	else:
		_game.mensaje_estado = "Tu turno: haz clic en un vecino para moverte"
	GameLogger.info("JuegoAtaque", "--- %s ---" % _game.titulo_nivel)
	GameLogger.info("JuegoAtaque", "Inicio: %s, Meta: %s" % [_game.start_node, _game.target_node])
	if not _game.waypoints.is_empty():
		GameLogger.info("JuegoAtaque", "Waypoints: %s" % str(_game.waypoints))
		_game.mensaje_estado = "Ve hacia %s" % target_actual()

	# Bloqueo inicial de la IA si está configurado:
	# `_ai_blocker.initial_block()` porta el bucle viejo verbatim.
	# Fix defensor (Enmienda A): en modo defensor se saltea — antes el
	# sentinel &"DEFENSOR" lo hacía fallar silencioso; con el start_node
	# real colocaría un bloqueo que el defensor no eligió.
	if not _game.defender_mode:
		_game._ai_blocker.initial_block()

	_game.mostrar_ruta()
	_game._auto_select_vecino()
	_game.queue_redraw()


func target_actual() -> StringName:
	if _game.current_waypoint_idx >= 0 and _game.current_waypoint_idx < _game.waypoints.size():
		return _game.waypoints[_game.current_waypoint_idx]
	return _game.target_node


## Ruta actual del jugador (slice 4): puebla current_path con la ruta óptima
## desde player_pos hasta el objetivo actual, RESPETANDO bloqueos del
## runtime (a diferencia del hint [P], que usa el grafo limpio). El resaltado
## sale gratis: draw_edges deriva in_path de current_path. En modo defensor no
## hay jugador → no-op. Reemplaza el no-op documentado del slice 3/P5.
func mostrar_ruta() -> void:
	_game.showing_path = false
	if _game.defender_mode or _game.runtime == null or _game.graph == null:
		_game.current_path.clear()
		return
	var result: Dictionary = DefensivePathfinderClass.find_path_with_cost(
		_game.graph, _game.player_pos, target_actual(), _game.runtime)
	if result["reachable"]:
		_game.current_path = result["path"]
		_game.showing_path = true
	else:
		_game.current_path.clear()
	_game.queue_redraw()


func find_node_resource(nid: StringName):
	# Cache O(1) — poblado en _load_graph()
	if _game._node_cache.has(nid):
		return _game._node_cache[nid]
	# Fallback seguro si el cache no está poblado
	for n in _game.graph.nodes:
		if n != null and n.id == nid:
			return n
	return null


func is_blocked(edge_key: String) -> bool:
	if _game.blocked_edges.has(edge_key):
		return true
	# También verificar si el runtime tiene costo INF (firewalls, etc.)
	var parts: PackedStringArray = edge_key.split("→")
	if parts.size() == 2 and _game.runtime != null:
		var from_n: StringName = parts[0] as StringName
		var to_n: StringName = parts[1] as StringName
		if _game.runtime.get_transit_cost(from_n, to_n) == INF:
			return true
	return false


func block_edge(edge_key: String, from_n: StringName, to_n: StringName) -> void:
	var orig: float = -1.0
	for e in _game.graph.edges:
		if e != null and e.from_id == from_n and e.to_id == to_n:
			orig = e.transit_cost
			break
	if orig < 0:
		return
	var duration: int = _game.defender_block_duration if _game.defender_mode else _game.block_duration
	_game.blocked_edges[edge_key] = {"expires_at": _game.turn + duration, "orig_cost": orig}
	_game.runtime.set_transit_cost(from_n, to_n, INF)


func unblock_edge(edge_key: String) -> void:
	if not _game.blocked_edges.has(edge_key):
		return
	var data = _game.blocked_edges[edge_key]
	_game.blocked_edges.erase(edge_key)
	var parts: PackedStringArray = edge_key.split("→")
	if parts.size() != 2:
		return
	var from_n: StringName = parts[0] as StringName
	var to_n: StringName = parts[1] as StringName
	var orig: float = data.get("orig_cost", 1.0)
	_game.runtime.set_transit_cost(from_n, to_n, orig)


func limpiar_bloqueos_expirados() -> void:
	var expired: Array[String] = []
	for key in _game.blocked_edges.keys():
		var data = _game.blocked_edges[key]
		if data.get("expires_at", -1) <= _game.turn:
			expired.append(key)
	for key in expired:
		_game._unblock_flash_time = Time.get_ticks_msec() / 1000.0
		_game._unblock_flash_edge = key
		# Emitir evento de cambio de estado para nodos conectados al bloqueo
		var parts: PackedStringArray = key.split("→")
		if parts.size() == 2:
			Events.node_state_changed.emit(parts[0] as StringName, 1, 0)  # BLOQUEADO → DISPONIBLE
			Events.node_state_changed.emit(parts[1] as StringName, 1, 0)
		unblock_edge(key)
	if expired.size() > 0:
		GameLogger.debug("JuegoAtaque", "Bloqueos expirados: %d" % expired.size())
