extends Node2D

const NetworkGraphResource = preload("res://core/network/network_graph_resource.gd")
const NetworkRuntime = preload("res://core/network/network_runtime.gd")
const DefensivePathfinder = preload("res://core/agents/defensive_pathfinder.gd")
const GameRendererClass = preload("res://juego/ataque/game_renderer.gd")
const HackerMechanicsClass = preload("res://juego/system/hacker_mechanics.gd")
const InputHandlerClass = preload("res://juego/ataque/input_handler.gd")
const DefenderBrainClass = preload("res://juego/ataque/defender_brain.gd")
const AIBlockerClass = preload("res://juego/ataque/ai_blocker.gd")
const PursuitSystemClass = preload("res://juego/ataque/pursuit_system.gd")

var graph_path: String = ""
var start_node: StringName = &""
var target_node: StringName = &""
var waypoints: Array = []
var ai_enabled: bool = true
var ai_block_per_turn: int = 1
var ai_bloquea_al_inicio: bool = true
var max_ai_blocks: int = 999
var max_turns: int = 0
var max_movement_points: int = 0
var titulo_nivel: String = ""
var mensaje_tutorial: String = ""

var graph: NetworkGraphResource
var runtime: NetworkRuntime
var player_pos: StringName
var current_waypoint_idx: int = 0
var turn: int = 0
var game_over: bool = false
var game_won: bool = false
var blocked_edges: Dictionary = {}
var current_path: Array[StringName] = []
var current_path_cost: float = INF
var _ai_blocks_used: int = 0
var mensaje_estado: String = ""

var font: Font
var font_size: int = 14
var big_font_size: int = 20
var small_font_size: int = 11
var tiny_font_size: int = 10

var node_radius: float = 22.0
var node_positions: Dictionary = {}
var node_order: Array[StringName] = []
var hovered_node: StringName = &""
var showing_path: bool = false
var modo_pausa: bool = false
var selected_neighbor: StringName = &""
var show_optimal_overlay: bool = false
var optimal_overlay_path: Array[StringName] = []
var player_total_cost: float = 0.0
var movement_points: int = 0
var _turn_locked_until: float = 0.0
# usado por mostrar_ruta() para emitir su advertencia una sola vez por partida
# (ver tarea 1.3 — la visualización de ruta aún no está cableada al renderer)
var _ruta_warning_emitido: bool = false

# Tutorial
var tutorial_player = null
var tutorial_path: String = ""

# Detection & Pursuers
var alerted_nodes: Array = []
var pursuers: Array = []
var _pursuer_next_id: int = 1

var pursuer_delay: int = 2
var pursuer_speed: int = 1
const STAR_THRESHOLDS: Array[float] = [1.0, 1.5]
var pursuer_max: int = 4

# Defender mode
var defender_mode: bool = false
var defender_blocks_per_turn: int = 2
var defender_block_duration: int = 4
var defender_blocks_placed: int = 0  # blocks placed THIS turn
var defender_blocks_total_used: int = 0  # total blocks placed entire game
var defender_max_blocks: int = 999  # max total blocks allowed
var enemy_pos: StringName = &""
var enemy_start_node: StringName = &""
var enemy_target_node: StringName = &""
var enemy_path: Array[StringName] = []
var selected_edge: String = ""  # "from→to" for defender edge selection
var hovered_edge: String = ""

# Strategic analysis (min-cut) result from StrategicAnalyzer
var min_cut_analysis: Dictionary = {}

# Node firewalls: permanent blocks on specific nodes
var node_firewalls: Dictionary = {}  # node_id -> true
var firewall_mode: bool = false  # Toggle for placing firewalls on nodes
var _node_cache: Dictionary = {}  # n.id → NodeResource (cache O(1))
var firewall_cost: int = 2  # Block resources to place one node firewall

var block_duration: int = 3
const DEFENDER_PHASE_ATTACK: String = "defense"
const DEFENDER_PHASE_RESOLVE: String = "resolve"
const DEFENDER_PHASE_WAIT: String = "wait"

# Hacker mode
var hacker_mode: bool = false
var hacker_state: Dictionary = {}
var scan_results: Dictionary = {}

# Visual feedback timing
var _enemy_move_flash_time: float = -1.0
var _unblock_flash_time: float = -1.0
var _unblock_flash_edge: String = ""
var _game_over_time: float = -1.0
var _budget_display: float = 0.0

# Fase 1: Componentes extraídos
var _input_handler: InputHandler
var _defender_brain: DefenderBrain
var _ai_blocker: AIBlocker
var _pursuit_system: PursuitSystem
var _renderer: GameRendererClass

func _process(_delta: float) -> void:
	if not game_over:
		_budget_display = lerp(_budget_display, float(movement_points), 0.15)


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 6
	small_font_size = font_size - 3
	tiny_font_size = font_size - 4

	graph_path = SceneParams.graph_path
	start_node = SceneParams.start_node
	target_node = SceneParams.target_node
	waypoints = SceneParams.waypoints
	ai_enabled = SceneParams.ai_enabled
	ai_block_per_turn = SceneParams.ai_block_per_turn
	ai_bloquea_al_inicio = SceneParams.ai_bloquea_al_inicio
	max_ai_blocks = SceneParams.max_ai_blocks
	max_turns = SceneParams.max_turns
	max_movement_points = SceneParams.max_movement_points
	_budget_display = float(movement_points)
	titulo_nivel = SceneParams.titulo_nivel
	mensaje_tutorial = SceneParams.mensaje_tutorial
	tutorial_path = SceneParams.tutorial_path
	SceneParams.tutorial_path = ""

	hacker_mode = SceneParams.hacker_mode

	defender_mode = SceneParams.defender_mode
	defender_blocks_per_turn = SceneParams.defender_blocks_per_turn
	defender_block_duration = SceneParams.defender_block_duration
	enemy_start_node = SceneParams.enemy_start_node
	enemy_target_node = SceneParams.enemy_target_node
	defender_max_blocks = SceneParams.defender_max_blocks
	firewall_cost = SceneParams.firewall_cost
	block_duration = SceneParams.block_duration
	pursuer_delay = SceneParams.pursuer_delay
	pursuer_max = SceneParams.max_pursuers
	pursuer_speed = SceneParams.pursuer_speed

	# Cachear renderer (no crear new cada frame)
	_renderer = GameRendererClass.new(self, font, font_size, big_font_size, small_font_size, tiny_font_size)

	# Input handler
	_input_handler = InputHandlerClass.new()
	add_child(_input_handler)
	_input_handler.game = self
	_connect_input_signals()

	# IA bloqueadora (fase-0/slice-3): se inicializa ANTES de _load_graph()
	# porque reset_state() dispara el bloqueo inicial via _ai_blocker.
	_ai_blocker = AIBlockerClass.new()
	_ai_blocker.setup(self)

	# Sistema de detección/persecución (fase-0/slice-4): se inicializa ANTES
	# de _load_graph() porque reset_state() (vía _load_graph) invoca
	# `_pursuit_system.reset()` para limpiar alertas/perseguidores.
	_pursuit_system = PursuitSystemClass.new()
	_pursuit_system.setup(self)

	_load_graph()

	if tutorial_path != "":
		_setup_tutorial()

	if defender_mode and not game_over:
		_init_defender_mode()
		print("🛡️ MODO DEFENSOR activado")
		print("  Enemigo: %s → %s" % [enemy_start_node, enemy_target_node])
		print("  Bloques/turno: %d, Duración: %d" % [defender_blocks_per_turn, defender_block_duration])


func _load_graph() -> void:
	if graph_path == "":
		mensaje_estado = "ERROR: graph_path vacio"
		push_error("Juego: graph_path esta vacio")
		queue_redraw()
		return

	graph = load(graph_path) as NetworkGraphResource
	if graph == null:
		mensaje_estado = "ERROR: no se pudo cargar el grafo: %s" % graph_path
		push_error("Juego: no se pudo cargar ", graph_path)
		queue_redraw()
		return

	var errors: Array[String] = graph.validate()
	if not errors.is_empty():
		var msg: String = "ERROR en grafo %s:" % graph_path
		for e in errors:
			push_error(e)
			msg += "\n  - " + e
		mensaje_estado = msg
		queue_redraw()
		return

	node_positions.clear()
	node_order.clear()
	_node_cache.clear()
	for n in graph.nodes:
		if n == null:
			continue
		node_positions[n.id] = n.position
		node_order.append(n.id)
		_node_cache[n.id] = n

	reset_state()


func reset_state() -> void:
	if graph == null:
		return

	runtime = NetworkRuntime.new(graph)
	blocked_edges.clear()
	_ai_blocks_used = 0
	turn = 0
	game_over = false
	game_won = false
	current_path.clear()
	showing_path = false
	player_pos = start_node
	current_waypoint_idx = -1 if waypoints.is_empty() else 0
	# Detección/persecución (fase-0/slice-4): limpieza migrada a
	# `_pursuit_system.reset()` (porta el viejo `alerted_nodes.clear()` +
	# `pursuers.clear()` + `_pursuer_next_id = 1`). Equivalencia cubierta por
	# tests/ataque/_test_pursuit_system_equivalence.{gd,tscn} (snapshot RESET).
	_pursuit_system.reset()
	show_optimal_overlay = false
	optimal_overlay_path.clear()
	player_total_cost = 0.0
	movement_points = max_movement_points
	_turn_locked_until = 0.0

	if hacker_mode:
		var starting_exploits: Dictionary = SceneParams.starting_exploits
		hacker_state = HackerMechanicsClass.create_state()
		for exploit_type in starting_exploits:
			HackerMechanicsClass.grant_exploits(hacker_state, exploit_type, starting_exploits[exploit_type])
		scan_results.clear()

	if defender_mode:
		enemy_pos = enemy_start_node if enemy_start_node != &"" else target_node
		defender_blocks_placed = 0
		defender_blocks_total_used = 0
		defender_max_blocks = defender_blocks_per_turn * max_turns + 2 if max_turns > 0 else 999
		selected_edge = ""
		hovered_edge = ""
		node_firewalls.clear()
		firewall_mode = false
		ai_enabled = true
		start_node = &"DEFENSOR"
		player_pos = &"DEFENSOR"
		mensaje_estado = "DEFENSOR: Bloquea aristas para detener al atacante"
		# Recrear brain si es un reset durante la partida
		if _defender_brain != null:
			_init_defender_mode()
	else:
		mensaje_estado = "Tu turno: haz clic en un vecino para moverte"
	print("--- %s ---" % titulo_nivel)
	print("Inicio: %s, Meta: %s" % [start_node, target_node])
	if not waypoints.is_empty():
		print("Waypoints: ", waypoints)
		mensaje_estado = "Ve hacia %s" % _target_actual()

	# Bloqueo inicial de la IA si está configurado (fase-0/slice-3):
	# migrado a `_ai_blocker.initial_block()` (porta el bucle viejo lines
	# 272-289 verbatim). Equivalencia cubierta por
	# tests/ataque/_test_ai_blocker_equivalence.{gd,tscn}.
	_ai_blocker.initial_block()

	mostrar_ruta()
	_auto_select_vecino()
	queue_redraw()


func _target_actual() -> StringName:
	if current_waypoint_idx >= 0 and current_waypoint_idx < waypoints.size():
		return waypoints[current_waypoint_idx]
	return target_node


func _find_node_resource(nid: StringName):
	# Cache O(1) — poblado en _load_graph()
	if _node_cache.has(nid):
		return _node_cache[nid]
	# Fallback seguro si el cache no está poblado
	for n in graph.nodes:
		if n != null and n.id == nid:
			return n
	return null


func mostrar_ruta() -> void:
	# La visualización de la ruta NO se renderiza automáticamente sobre el
	# tablero. El jugador puede pedirla explícitamente con [P]
	# (_reveal_optimal_route, implementado). Antes este método era un `pass`
	# silencioso: los 3 call sites (reset_state, _mover_jugador al alcanzar un
	# waypoint, _turno_ia) dejaban la ruta ignorada sin señalización. Ahora es
	# un no-op deliberado que advierte una sola vez por partida para no acallar
	# la omisión. Cuando se cablee un render de ruta al GameRenderer, basta
	# reemplazar este cuerpo.
	# (fase-0/slice-1, tarea 1.3)
	if _ruta_warning_emitido:
		return
	_ruta_warning_emitido = true
	push_warning("mostrar_ruta(): la visualización automática de ruta no está implementada — usa [P] para la ruta óptima.")


func _vecinos_jugador() -> Array:
	var neighbors: Array = runtime.get_neighbors(player_pos)
	var result: Array[StringName] = []
	for n in neighbors:
		var nid: StringName = n["to_id"]
		var edge_key: String = "%s→%s" % [player_pos, nid]
		if _is_blocked(edge_key):
			continue
		result.append(nid)
	return result


# ─── DEFENDER MODE ─────────────────────────────────────────────────

func _init_defender_mode() -> void:
	"""Inicializa el estado del modo defensor usando DefenderBrain."""
	if graph == null:
		return
	_defender_brain = DefenderBrainClass.new()
	_defender_brain.setup(self, {
		"enemy_start": enemy_start_node,
		"enemy_target": enemy_target_node,
		"blocks_per_turn": defender_blocks_per_turn,
		"block_duration": defender_block_duration,
		"firewall_cost": firewall_cost,
	})
	_defender_brain.defender_won.connect(_on_brain_defender_won)
	_defender_brain.defender_lost.connect(_on_brain_defender_lost)
	_defender_brain.message.connect(_on_brain_message)
	_defender_brain.state_changed.connect(_on_brain_state_changed)
	_defender_brain.init()
	# Sincronizar estado desde el brain
	enemy_pos = _defender_brain.enemy_pos
	enemy_target_node = _defender_brain.enemy_target_node
	queue_redraw()


func _edge_en_posicion(pos: Vector2) -> String:
	"""Encuentra la arista más cercana a la posición del clic para defender mode."""
	if graph == null or node_positions.is_empty():
		return ""
	var best_edge: String = ""
	var best_dist: float = 30.0  # Radio de clic en píxeles
	for e in graph.edges:
		if e == null:
			continue
		var from_pos: Vector2 = node_positions.get(e.from_id, Vector2.ZERO) as Vector2
		var to_pos: Vector2 = node_positions.get(e.to_id, Vector2.ZERO) as Vector2
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


func _nodo_en_posicion_firewall(pos: Vector2) -> StringName:
	"""Encuentra el nodo más cercano al clic (radio más generoso para firewall)."""
	for nid in node_positions.keys():
		var npos: Vector2 = node_positions[nid] as Vector2
		if npos.distance_to(pos) <= node_radius + 30.0:
			return nid as StringName
	return &""


func _mover_jugador(destino: StringName) -> void:
	var edge_key: String = "%s→%s" % [player_pos, destino]
	if _is_blocked(edge_key):
		# Si el destino tiene persist activa, ignorar bloqueo
		if hacker_mode and hacker_state.get("active_persists", {}).has(str(destino)):
			print("  ♻ Persist activo en %s — ignorando bloqueo" % str(destino))
		else:
			return

	mensaje_estado = ""
	print("[Turno %d] Jugador: %s → %s" % [turn + 1, player_pos, destino])

	var edge_cost: float = 0.0
	for e in graph.edges:
		if e != null and e.from_id == player_pos and e.to_id == destino:
			edge_cost = e.transit_cost
			break
	player_total_cost += edge_cost

	if hacker_mode and not game_over:
		HackerMechanicsClass.add_noise(hacker_state, HackerMechanicsClass.NOISE_MOVE_BASE)

	if max_movement_points > 0:
		movement_points -= int(edge_cost)
		if movement_points <= 0 and destino != _target_actual():
			_perder("¡Sin presupuesto de movimiento!")
			return

	player_pos = destino
	AudioManager.play_sfx("move")

	_pursuit_system.check_detection(player_pos)  # fase-0/slice-4: antes _chequear_deteccion() inline

	if tutorial_player != null and tutorial_player.is_active:
		tutorial_player.notify_moved()

	turn += 1

	var target_check: StringName = _target_actual()
	if player_pos == target_check:
		if current_waypoint_idx >= 0 and current_waypoint_idx < waypoints.size():
			current_waypoint_idx += 1
			var next: StringName = _target_actual()
			if player_pos == next:
				_ganar()
				return
			print("  Waypoint %s alcanzado! Siguiente: %s" % [target_check, next])
			mensaje_estado = "Waypoint alcanzado! Ve hacia %s" % next
			mostrar_ruta()
			queue_redraw()
			return
		else:
			_ganar()
			return

	if max_turns > 0 and turn >= max_turns:
		_perder("Te detectaron! (%d turnos maximo)" % max_turns)
		return

	_limpiar_bloqueos_expirados()

	if ai_enabled:
		_ai_blocker.take_turn()  # fase-0/slice-3: antes _turno_ia() inline

	if hacker_mode and not game_over:
		# Si hay persists activos, el ruido no decae (mantienes acceso audible)
		if hacker_state.get("active_persists", {}).is_empty():
			HackerMechanicsClass.decay_noise(hacker_state)
		else:
			print("  ♻ Persist activo — decay de ruido suspendido")

	# Revisar consecuencias de ruido/persists cada turno
	if hacker_mode:
		_check_hacker_consequences()

	if not game_over:
		target_check = _target_actual()
		var desde_aqui: Dictionary = DefensivePathfinder.find_path_with_cost(graph, player_pos, target_check, runtime)
		if not desde_aqui["reachable"]:
			mensaje_estado = "¡Sin ruta hacia %s desde %s!" % [target_check, player_pos]

		var vecinos: Array = _vecinos_jugador()
		if vecinos.is_empty() and player_pos != _target_actual() and not game_over:
			_perder("¡Sin salida! No hay caminos accesibles desde %s" % str(player_pos))
			return

	_turn_locked_until = Time.get_ticks_msec() + 200


func _is_blocked(edge_key: String) -> bool:
	if blocked_edges.has(edge_key):
		return true
	# También verificar si el runtime tiene costo INF (firewalls, etc.)
	var parts: PackedStringArray = edge_key.split("→")
	if parts.size() == 2 and runtime != null:
		var from_n: StringName = parts[0] as StringName
		var to_n: StringName = parts[1] as StringName
		if runtime.get_transit_cost(from_n, to_n) == INF:
			return true
	return false


func _block_edge(edge_key: String, from_n: StringName, to_n: StringName) -> void:
	var orig: float = -1.0
	for e in graph.edges:
		if e != null and e.from_id == from_n and e.to_id == to_n:
			orig = e.transit_cost
			break
	if orig < 0:
		return
	var duration: int = defender_block_duration if defender_mode else block_duration
	blocked_edges[edge_key] = {"expires_at": turn + duration, "orig_cost": orig}
	runtime.set_transit_cost(from_n, to_n, INF)


func _unblock_edge(edge_key: String) -> void:
	if not blocked_edges.has(edge_key):
		return
	var data = blocked_edges[edge_key]
	blocked_edges.erase(edge_key)
	var parts: PackedStringArray = edge_key.split("→")
	if parts.size() != 2:
		return
	var from_n: StringName = parts[0] as StringName
	var to_n: StringName = parts[1] as StringName
	var orig: float = data.get("orig_cost", 1.0)
	runtime.set_transit_cost(from_n, to_n, orig)


func _limpiar_bloqueos_expirados() -> void:
	var expired: Array[String] = []
	for key in blocked_edges.keys():
		var data = blocked_edges[key]
		if data.get("expires_at", -1) <= turn:
			expired.append(key)
	for key in expired:
		_unblock_flash_time = Time.get_ticks_msec() / 1000.0
		_unblock_flash_edge = key
		# TAREA 4: Emitir evento de cambio de estado para nodos conectados al bloqueo
		var parts: PackedStringArray = key.split("→")
		if parts.size() == 2:
			Events.node_state_changed.emit(parts[0] as StringName, 1, 0)  # BLOQUEADO → DISPONIBLE
			Events.node_state_changed.emit(parts[1] as StringName, 1, 0)
		_unblock_edge(key)
	if expired.size() > 0:
		print("  Bloqueos expirados: %d" % expired.size())


func _reveal_optimal_route() -> void:
	show_optimal_overlay = not show_optimal_overlay
	if show_optimal_overlay:
		var target: StringName = _target_actual()
		var result: Dictionary = DefensivePathfinder.find_path_with_cost(graph, player_pos, target, null)
		optimal_overlay_path = result["path"]
		if result["reachable"]:
			mensaje_estado = "Pista: ruta más corta a %s" % str(target)
		else:
			mensaje_estado = "No hay ruta disponible"
	else:
		optimal_overlay_path.clear()
		mensaje_estado = ""
	queue_redraw()


func _ganar() -> void:
	if current_waypoint_idx < waypoints.size():
		_perder("Debes pasar por %s primero" % str(waypoints[current_waypoint_idx]))
		return
	game_over = true
	_game_over_time = Time.get_ticks_msec() / 1000.0
	game_won = true
	AudioManager.play_sfx("win")
	var target: StringName = _target_actual()
	var stars: int = _calcular_estrellas()
	_guardar_progreso(stars)
	var star_str: String = ""
	for i in range(3):
		star_str += "★" if i < stars else "☆"
	mensaje_estado = "GANASTE! Llegaste a %s en %d turnos  %s" % [target, turn, star_str]
	print("🏆 VICTORIA en turno ", turn, " | estrellas: ", stars, " | coste: ", player_total_cost)
	queue_redraw()


func _level_key() -> String:
	if SceneParams.level_key != "":
		return SceneParams.level_key
	var path: String = graph_path
	return path.get_file().trim_suffix(".tres")


func _calcular_estrellas() -> int:
	if max_movement_points > 0:
		var ratio: float = float(movement_points) / float(max_movement_points)
		if ratio >= 0.5:
			return 3
		if ratio >= 0.25:
			return 2
		return 1

	var optimal_cost: float = 0.0
	var prev: StringName = start_node
	for wp in waypoints:
		var seg: Dictionary = DefensivePathfinder.find_path_with_cost(graph, prev, wp, null)
		if not seg["reachable"]:
			return 1
		optimal_cost += seg["cost"]
		prev = wp
	var seg_final: Dictionary = DefensivePathfinder.find_path_with_cost(graph, prev, target_node, null)
	if not seg_final["reachable"]:
		return 1
	optimal_cost += seg_final["cost"]

	if optimal_cost <= 0:
		return 1

	var cost_ratio: float = player_total_cost / optimal_cost
	var cost_stars: int = 3 if cost_ratio <= STAR_THRESHOLDS[0] else (2 if cost_ratio <= STAR_THRESHOLDS[1] else 1)

	var turn_stars: int = 3
	if max_turns > 0:
		var turn_ratio: float = float(turn) / float(max_turns)
		turn_stars = 3 if turn_ratio <= 0.5 else (2 if turn_ratio <= 0.75 else 1)

	return mini(cost_stars, turn_stars)


func _guardar_progreso(nuevas_estrellas: int) -> void:
	var key: String = _level_key()
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load("user://progress.cfg")
	if err != OK and err != ERR_FILE_NOT_FOUND:
		print("Error cargando progress: ", err)
	var prev: int = cfg.get_value("estrellas", key, 0)
	if nuevas_estrellas > prev:
		cfg.set_value("estrellas", key, nuevas_estrellas)
		cfg.set_value("estrellas", key + "_mejor_coste", player_total_cost)
		cfg.save("user://progress.cfg")
		print("Progreso guardado: ", key, " → ", nuevas_estrellas, " estrellas")
		if prev > 0:
			mensaje_estado += " (nuevo record!)"
	
	# Estadísticas extendidas
	var stats_cfg := ConfigFile.new()
	stats_cfg.load("user://stats.cfg")
	var wins: int = stats_cfg.get_value("stats", "total_wins", 0)
	stats_cfg.set_value("stats", "total_wins", wins + 1)
	
	# Track per-level attempts y wins
	var level_wins: int = stats_cfg.get_value("levels", key + "_wins", 0)
	stats_cfg.set_value("levels", key + "_wins", level_wins + 1)
	
	stats_cfg.set_value("stats", "best_streak", maxi(stats_cfg.get_value("stats", "best_streak", 0), 1))
	stats_cfg.save("user://stats.cfg")


func _cargar_progreso() -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load("user://progress.cfg")
	if err != OK:
		return {}
	var result: Dictionary = {}
	for k in cfg.get_section_keys("estrellas"):
		if k.ends_with("_mejor_coste"):
			continue
		result[k] = cfg.get_value("estrellas", k, 0)
	return result


func _perder(razon: String) -> void:
	game_over = true
	_game_over_time = Time.get_ticks_msec() / 1000.0
	game_won = false
	AudioManager.play_sfx("lose")
	mensaje_estado = "PERDISTE: %s" % razon
	print("💀 DERROTA: ", razon)
	# Track pérdida en estadísticas
	var stats_cfg := ConfigFile.new()
	stats_cfg.load("user://stats.cfg")
	var losses: int = stats_cfg.get_value("stats", "total_losses", 0)
	stats_cfg.set_value("stats", "total_losses", losses + 1)
	var key: String = _level_key()
	var level_losses: int = stats_cfg.get_value("levels", key + "_losses", 0)
	stats_cfg.set_value("levels", key + "_losses", level_losses + 1)
	stats_cfg.set_value("stats", "total_attempts", stats_cfg.get_value("stats", "total_attempts", 0) + 1)
	stats_cfg.save("user://stats.cfg")
	queue_redraw()


func _connect_input_signals() -> void:
	_input_handler.move_requested.connect(_on_move_requested)
	_input_handler.node_targeted.connect(_on_node_targeted)
	_input_handler.scan_requested.connect(_on_scan_requested)
	_input_handler.exploit_used.connect(_on_exploit_used)
	_input_handler.reset_requested.connect(_on_reset_requested)
	_input_handler.return_to_menu_requested.connect(_on_return_to_menu)
	_input_handler.quit_requested.connect(_on_quit)
	_input_handler.toggle_optimal_route.connect(_on_toggle_optimal_route)
	_input_handler.cycle_neighbor.connect(_on_cycle_neighbor)
	_input_handler.defender_resolve_turn.connect(_on_defender_resolve_turn)
	_input_handler.defender_toggle_firewall.connect(_on_defender_toggle_firewall)
	_input_handler.defender_block_edge.connect(_on_defender_block_edge)
	_input_handler.defender_place_firewall.connect(_on_defender_place_firewall)
	_input_handler.defender_hover_edge.connect(_on_defender_hover_edge)
	_input_handler.tutorial_skipped.connect(_on_tutorial_skipped_input)


# ─── Signal Handlers ──────────────────────────────────────────────

func _on_move_requested(destino: StringName) -> void:
	_mover_jugador(destino)


func _on_node_targeted(clicked: StringName, first_step: StringName) -> void:
	selected_neighbor = first_step
	mensaje_estado = "Ruta hacia %s → seleccionado: %s" % [clicked, first_step]
	queue_redraw()


func _on_scan_requested() -> void:
	AudioManager.play_sfx("scan")
	_scan_selected_node()


func _on_exploit_used(exploit_type: String) -> void:
	AudioManager.play_sfx("exploit")
	_use_hacker_exploit(exploit_type)


func _on_reset_requested() -> void:
	AudioManager.play_sfx("reset")
	reset_state()


func _on_return_to_menu() -> void:
	SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")


func _on_quit() -> void:
	get_tree().quit()


func _on_toggle_optimal_route() -> void:
	_reveal_optimal_route()


func _on_cycle_neighbor(dir: int) -> void:
	_cycle_neighbor(dir)


func _on_defender_resolve_turn() -> void:
	if _defender_brain != null:
		_defender_brain.resolve_turn()


func _on_defender_toggle_firewall() -> void:
	if _defender_brain != null:
		_defender_brain.toggle_firewall_mode()
		firewall_mode = _defender_brain.firewall_mode


func _on_defender_block_edge(edge_key: String) -> void:
	AudioManager.play_sfx("block")
	if _defender_brain != null:
		_defender_brain.block_edge(edge_key)


func _on_defender_place_firewall(node_id: StringName) -> void:
	if _defender_brain != null:
		_defender_brain.place_firewall(node_id)


func _on_defender_hover_edge(edge_key: String) -> void:
	if _defender_brain != null:
		_defender_brain.set_hovered_edge(edge_key)
		hovered_edge = edge_key
		queue_redraw()


func _on_tutorial_skipped_input() -> void:
	if tutorial_player != null and is_instance_valid(tutorial_player):
		tutorial_player.skip()


# ─── Señales de DefenderBrain ─────────────────────────────────────

func _on_brain_defender_won(reason: String, stars: int) -> void:
	game_over = true
	_game_over_time = Time.get_ticks_msec() / 1000.0
	game_won = true
	AudioManager.play_sfx("win")
	_guardar_progreso(stars)
	queue_redraw()


func _on_brain_defender_lost(reason: String) -> void:
	game_over = true
	_game_over_time = Time.get_ticks_msec() / 1000.0
	game_won = false
	AudioManager.play_sfx("lose")
	queue_redraw()


func _on_brain_message(text: String) -> void:
	mensaje_estado = text


func _on_brain_state_changed() -> void:
	# Sincronizar estado del brain para renderizado y otras referencias
	if _defender_brain != null:
		enemy_pos = _defender_brain.enemy_pos
		enemy_target_node = _defender_brain.enemy_target_node
		enemy_path = _defender_brain.enemy_path
		hovered_edge = _defender_brain.hovered_edge
		firewall_mode = _defender_brain.firewall_mode
		node_firewalls = _defender_brain.node_firewalls
	queue_redraw()


func _on_enemy_moved() -> void:
	_enemy_move_flash_time = Time.get_ticks_msec() / 1000.0


func _setup_tutorial() -> void:
	var tutorial_scene = preload("res://juego/tutorials/tutorial_player.tscn")
	var tutorial_root = tutorial_scene.instantiate()
	add_child(tutorial_root)
	tutorial_player = tutorial_root.get_node("Control")
	tutorial_player.step_changed.connect(_on_tutorial_step_changed)
	tutorial_player.tutorial_completed.connect(_on_tutorial_completed)
	tutorial_player.tutorial_skipped.connect(_on_tutorial_skipped)
	if tutorial_player.load_tutorial(tutorial_path):
		tutorial_player.start()
	else:
		push_warning("No se pudo cargar tutorial: %s" % tutorial_path)
		tutorial_player = null


func _on_tutorial_step_changed(step_index: int, step_data: Dictionary) -> void:
	queue_redraw()


func _on_tutorial_completed(tutorial_id: String) -> void:
	mensaje_estado = "Tutorial completado!"
	queue_redraw()


func _on_tutorial_skipped(tutorial_id: String) -> void:
	mensaje_estado = "Tutorial saltado"
	queue_redraw()


func _auto_select_vecino() -> void:
	var vecinos: Array = _vecinos_jugador()
	if vecinos.size() > 0:
		if selected_neighbor in vecinos:
			return
		selected_neighbor = vecinos[0]
	else:
		selected_neighbor = &""


func _cycle_neighbor(dir: int) -> void:
	var vecinos: Array = _vecinos_jugador()
	if vecinos.size() == 0:
		selected_neighbor = &""
		return
	if selected_neighbor == &"" or not (selected_neighbor in vecinos):
		selected_neighbor = vecinos[0] if dir > 0 else vecinos[-1]
		queue_redraw()
		return
	var idx: int = vecinos.find(selected_neighbor)
	idx = (idx + dir) % vecinos.size()
	selected_neighbor = vecinos[idx]
	queue_redraw()


func _nodo_en_posicion(pos: Vector2) -> StringName:
	for nid in node_positions.keys():
		var npos: Vector2 = node_positions[nid] as Vector2
		if npos.distance_to(pos) <= node_radius + 22.0:
			return nid as StringName
	return &""


func _draw() -> void:
	# Guard (fase-0/slice-1, tarea 1.4): si estamos en modo defensor pero el
	# brain no es una instancia válida (null o liberado), acceder a sus miembros
	# más abajo sería un error en runtime. Antes el chequeo era `_defender_brain
	# != null`, que NO detecta objetos freed (no null pero ya liberados). Aquí
	# se valida con is_instance_valid y, en modo defensor, se omite el dibujado
	# con una advertencia. En modo atacante _defender_brain es legítimamente
	# null y el resto de _draw debe correr normalmente, por eso el guard sólo
	# aborta cuando defender_mode exige el brain.
	if defender_mode and not is_instance_valid(_defender_brain):
		push_warning("_draw(): _defender_brain no es válido en modo defensor — se omite el dibujado del tablero.")
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var r := _renderer  # Usar renderer cacheado (no crear new cada frame)

	# Sincronizar datos desde el brain si existe (is_instance_valid cubre tanto
	# null como objetos freed; el fallback usa el estado local del juego).
	var def_blocks_placed: int = _defender_brain.defender_blocks_placed if is_instance_valid(_defender_brain) else defender_blocks_placed
	var def_blocks_per_turn: int = _defender_brain.defender_blocks_per_turn if is_instance_valid(_defender_brain) else defender_blocks_per_turn
	var def_enemy_pos: StringName = _defender_brain.enemy_pos if is_instance_valid(_defender_brain) else enemy_pos
	var def_enemy_target: StringName = _defender_brain.enemy_target_node if is_instance_valid(_defender_brain) else enemy_target_node
	var def_enemy_path: Array = _defender_brain.enemy_path if is_instance_valid(_defender_brain) else enemy_path
	var def_hovered_edge: String = _defender_brain.hovered_edge if is_instance_valid(_defender_brain) else hovered_edge
	var def_node_firewalls: Dictionary = _defender_brain.node_firewalls if is_instance_valid(_defender_brain) else node_firewalls
	var def_firewall_mode: bool = _defender_brain.firewall_mode if is_instance_valid(_defender_brain) else firewall_mode
	var def_min_cut: Dictionary = _defender_brain.min_cut_analysis if is_instance_valid(_defender_brain) else min_cut_analysis

	if runtime == null or graph == null:
		if mensaje_estado != "" and font != null:
			r.draw_error(vp_size, mensaje_estado)
		return

	r.draw_background_grid(vp_size)
	if defender_mode:
		r.draw_defender_hud(vp_size, turn, def_blocks_placed, def_blocks_per_turn, def_enemy_pos, def_enemy_target, max_turns, def_min_cut, blocked_edges, def_node_firewalls, def_firewall_mode)
	else:
		r.draw_hud(vp_size, titulo_nivel, turn, player_pos, _target_actual(), player_total_cost, max_turns, waypoints, current_waypoint_idx, pursuers, alerted_nodes, movement_points, max_movement_points, _budget_display)
	if hacker_mode:
		r.draw_hacker_hud(vp_size, hacker_state, scan_results)
	r.draw_edges(graph, node_positions, blocked_edges, current_path, node_radius, game_over, _is_blocked, _is_in_path, def_hovered_edge if defender_mode else "", def_enemy_path if defender_mode else [], turn, _unblock_flash_time, _unblock_flash_edge)
	if defender_mode:
		r.draw_nodes(graph, node_positions, def_enemy_pos, def_enemy_target, [], current_path, node_radius, game_over, alerted_nodes, &"", scan_results, waypoints, -1, def_node_firewalls, def_enemy_pos, _enemy_move_flash_time)
		if def_enemy_path.size() >= 2:
			r.draw_optimal_overlay(def_enemy_path, node_positions, node_radius)
	else:
		r.draw_nodes(graph, node_positions, player_pos, _target_actual(), _vecinos_jugador(), current_path, node_radius, game_over, alerted_nodes, selected_neighbor, scan_results, waypoints, current_waypoint_idx, {}, &"", _enemy_move_flash_time)
	r.draw_pursuers(pursuers, node_positions, node_radius)

	if show_optimal_overlay:
		r.draw_optimal_overlay(optimal_overlay_path, node_positions, node_radius)

	if tutorial_player != null and tutorial_player.is_active:
		r.draw_tutorial_highlights(tutorial_player, node_positions, node_radius)

	if game_over:
		var stars: int = _defender_brain.calcular_estrellas() if defender_mode and _defender_brain != null else _calcular_estrellas()
		if defender_mode:
			r.draw_defender_game_over(vp_size, game_won, mensaje_estado, stars, _game_over_time)
		else:
			r.draw_game_over(vp_size, game_won, mensaje_estado, stars, _game_over_time)

	if mensaje_tutorial != "" and not game_over:
		r.draw_tutorial_text(mensaje_tutorial)

	if selected_neighbor != &"" and not game_over:
		r.draw_node_info_panel(vp_size, selected_neighbor, player_pos, graph, _find_node_resource)

	r.draw_status_bar(vp_size, mensaje_estado, selected_neighbor, game_over, game_won, defender_mode)


func _is_in_path(from_id: StringName, to_id: StringName) -> bool:
	if current_path.size() < 2:
		return false
	for i in current_path.size() - 1:
		if current_path[i] == from_id and current_path[i + 1] == to_id:
			return true
	return false


# ─── HACKER MODE ─────────────────────────────────────────────────

func _scan_selected_node() -> void:
	if selected_neighbor == &"":
		mensaje_estado = "Selecciona un nodo para escanear [X]"
		queue_redraw()
		return
	var node_res = _find_node_resource(selected_neighbor)
	if node_res == null:
		return
	var result: Dictionary = HackerMechanicsClass.scan_node(hacker_state, selected_neighbor, node_res.metadata)
	scan_results[str(selected_neighbor)] = result
	var type_label: String = result.get("node_type", "unknown")
	var hint: String = result.get("exploit_hint", "")
	mensaje_estado = "ESCANEADO %s → %s | %s" % [str(selected_neighbor), type_label.to_upper(), hint]
	print("  [SCAN] %s: %s — %s" % [str(selected_neighbor), type_label, hint])
	queue_redraw()


func _use_hacker_exploit(exploit_type: String) -> void:
	if selected_neighbor == &"":
		mensaje_estado = "Selecciona un nodo para explotar"
		queue_redraw()
		return
	var result: Dictionary = HackerMechanicsClass.use_exploit(hacker_state, exploit_type, selected_neighbor)
	if not result.get("success", false):
		mensaje_estado = result.get("reason", "Exploit fallido")
		queue_redraw()
		return
	# Aplicar efecto del exploit
	match exploit_type:
		"bypass":
			# Saltar protección: solo funciona en nodos conectados
			if selected_neighbor in _vecinos_jugador():
				_mover_jugador(selected_neighbor)
			else:
				# Verificar que existe una arista (bloqueada o no)
				var edge_key: String = "%s→%s" % [player_pos, selected_neighbor]
				var edge_exists: bool = false
				for e in graph.edges:
					if e != null and e.from_id == player_pos and e.to_id == selected_neighbor:
						edge_exists = true
						break
				if not edge_exists:
					mensaje_estado = "Sin conexión directa a %s" % str(selected_neighbor)
					# Devolver el exploit
					hacker_state["exploits"]["bypass"] = hacker_state["exploits"].get("bypass", 0) + 1
					hacker_state["exploits_used"] = maxi(hacker_state["exploits_used"] - 1, 0)
					hacker_state["noise"] = maxi(hacker_state["noise"] - HackerMechanicsClass.NOISE_EXPLOIT_BYPASS, 0)
					queue_redraw()
					return
				if _is_blocked(edge_key):
					blocked_edges.erase(edge_key)
					runtime.set_transit_cost(player_pos, selected_neighbor, 1.0)
					_mover_jugador(selected_neighbor)
				else:
					mensaje_estado = "No hay protección que saltar en %s" % str(selected_neighbor)
					hacker_state["exploits"]["bypass"] = hacker_state["exploits"].get("bypass", 0) + 1
					hacker_state["exploits_used"] = maxi(hacker_state["exploits_used"] - 1, 0)
					hacker_state["noise"] = maxi(hacker_state["noise"] - HackerMechanicsClass.NOISE_EXPLOIT_BYPASS, 0)
					queue_redraw()
					return
		"escalate":
			# Acceder a área restringida: solo nodos conectados
			if selected_neighbor in _vecinos_jugador():
				_mover_jugador(selected_neighbor)
			else:
				var edge_exists: bool = false
				for e in graph.edges:
					if e != null and e.from_id == player_pos and e.to_id == selected_neighbor:
						edge_exists = true
						break
				if not edge_exists:
					mensaje_estado = "Sin conexión directa a %s" % str(selected_neighbor)
					hacker_state["exploits"]["escalate"] = hacker_state["exploits"].get("escalate", 0) + 1
					hacker_state["exploits_used"] = maxi(hacker_state["exploits_used"] - 1, 0)
					hacker_state["noise"] = maxi(hacker_state["noise"] - HackerMechanicsClass.NOISE_EXPLOIT_ESCALATE, 0)
					queue_redraw()
					return
				_mover_jugador(selected_neighbor)
		"persist":
			# Mantener acceso: permite moverte a través de bloqueos y evita decay de ruido por 3 turnos
			var node_key: String = str(selected_neighbor)
			hacker_state["active_persists"][node_key] = 3
			mensaje_estado = "♻ Persistencia activa en %s por 3 turnos" % str(selected_neighbor)
	mensaje_estado = "%s %s aplicado en %s (ruido: %d)" % [result.get("icon", ""), result.get("name", ""), str(selected_neighbor), hacker_state.get("noise", 0)]
	print("  [EXPLOIT] %s en %s — ruido: %d" % [exploit_type, str(selected_neighbor), hacker_state.get("noise", 0)])
	_check_hacker_consequences()
	queue_redraw()


func _check_hacker_consequences() -> void:
	# Reducir contadores de persist activos
	if hacker_mode and hacker_state.get("active_persists", {}).size() > 0:
		var expired: Array[String] = []
		for node_key: String in hacker_state["active_persists"].keys():
			hacker_state["active_persists"][node_key] -= 1
			if hacker_state["active_persists"][node_key] <= 0:
				expired.append(node_key)
		for node_key: String in expired:
			hacker_state["active_persists"].erase(node_key)
			print("  ♻ Persist expirado en %s" % node_key)

	var alert_level: String = HackerMechanicsClass.get_alert_level(hacker_state)
	match alert_level:
		"critical":
			mensaje_estado = "⚠ RUIDO CRÍTICO — Seguridad máxima activada"
			# Spawnear pursuedor extra (fase-0/slice-4): spawn dict + id
			# increment migrados a `_pursuit_system.spawn_pursuer(delay=1,
			# speed=2)` — el helper deduplica el bloque que vivía inline
			# (idéntico al de `_chequear_deteccion` con delay/speed por defecto).
			if hacker_state.get("noise", 0) >= 85 and pursuers.size() < 4:
				var spawn_node: StringName = _pursuit_system.find_spawn_node(player_pos, _find_node_resource(player_pos))
				_pursuit_system.spawn_pursuer(spawn_node, 1, 2)
		"high":
			mensaje_estado = "⚠ Ruido alto — cuidado con los movimientos"
		"low":
			pass
