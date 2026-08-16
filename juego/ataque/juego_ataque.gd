extends Node2D

## Orquestador del juego (slice 3 / P5): estado mutable (lo leen los módulos,
## el renderer y los tests vía duck-typing) + wiring; el comportamiento vive
## en game_state.gd (params/grafo/reset/bloqueos/hit-testing/frame_data),
## game_logic.gd (turnos/mover/win-lose/vecinos/ruta [P]/defensor) y
## hacker_logic.gd (scans/exploits/consecuencias). Equivalencias:
## tests/ataque/_test_{game_state,game_logic,hacker_logic,defender_flow}_equivalence

const NetworkGraphResource = preload("res://core/network/network_graph_resource.gd")
const NetworkRuntime = preload("res://core/network/network_runtime.gd")
const GameRendererClass = preload("res://juego/ataque/game_renderer.gd")
const InputHandlerClass = preload("res://juego/ataque/input_handler.gd")
const DefenderBrainClass = preload("res://juego/ataque/defender_brain.gd")
const AIBlockerClass = preload("res://juego/ataque/ai_blocker.gd")
const PursuitSystemClass = preload("res://juego/ataque/pursuit_system.gd")
const ProgressServiceClass = preload("res://juego/ataque/progress_service.gd")
const GameStateClass = preload("res://juego/ataque/game_state.gd")
const HackerLogicClass = preload("res://juego/ataque/hacker_logic.gd")
const GameLogicClass = preload("res://juego/ataque/game_logic.gd")

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
var _ai_blocks_used: int = 0
var mensaje_estado: String = ""

var font: Font
var font_size: int = 14

var node_radius: float = 22.0
var node_positions: Dictionary = {}
var showing_path: bool = false
var selected_neighbor: StringName = &""
var show_optimal_overlay: bool = false
var optimal_overlay_path: Array[StringName] = []
var player_total_cost: float = 0.0
var movement_points: int = 0
var _turn_locked_until: float = 0.0

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
var defender_max_blocks: int = 999
var enemy_pos: StringName = &""
var enemy_start_node: StringName = &""
var enemy_target_node: StringName = &""
var enemy_path: Array[StringName] = []
var selected_edge: String = ""
var hovered_edge: String = ""
var min_cut_analysis: Dictionary = {}  # min-cut (StrategicAnalyzer)
var node_firewalls: Dictionary = {}
var firewall_mode: bool = false
var _node_cache: Dictionary = {}  # n.id → NodeResource (cache O(1))
var firewall_cost: int = 2

var block_duration: int = 3
var level_key: String = ""

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

# Componentes extraídos. Tipos omitidos donde el class_name no se resuelve
# en CLI headless sin editor (convención del proyecto).
var _input_handler: InputHandler
var _defender_brain: DefenderBrain
var _ai_blocker: AIBlocker
var _pursuit_system: PursuitSystem
var _progress_service  # ProgressService
var _renderer: GameRendererClass
var _game_state  # GameState
var _hacker_logic  # HackerLogic
var _game_logic  # GameLogic


func _process(_delta: float) -> void:
	if not game_over:
		_budget_display = lerp(_budget_display, float(movement_points), 0.15)


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size

	# game_state/hacker_logic/game_logic ANTES de cargar el grafo: reset_state()
	# (vía load_graph) y los turnos dependen de sus métodos.
	_game_state = GameStateClass.new()
	_game_state.setup(self)
	_game_state.cargar_params()
	_hacker_logic = HackerLogicClass.new()
	_hacker_logic.setup(self)
	_game_logic = GameLogicClass.new()
	_game_logic.setup(self)

	# Renderer cacheado (no crear new cada frame) + input por señales.
	_renderer = GameRendererClass.new(self, font, font_size, font_size + 6, font_size - 3, font_size - 4)
	_input_handler = InputHandlerClass.new()
	add_child(_input_handler)
	_input_handler.game = self
	_connect_input_signals()

	# IA bloqueadora, persecución y progreso ANTES de load_graph: reset_state()
	# dispara el bloqueo inicial, limpia alertas y persiste resultados.
	_ai_blocker = AIBlockerClass.new()
	_ai_blocker.setup(self)
	_pursuit_system = PursuitSystemClass.new()
	_pursuit_system.setup(self)
	_progress_service = ProgressServiceClass.new()
	_progress_service.setup(self)

	_game_state.load_graph()
	if tutorial_path != "":
		_setup_tutorial()
	if defender_mode and not game_over:
		_init_defender_mode()
		GameLogger.info("JuegoAtaque", "MODO DEFENSOR activado")
		GameLogger.info("JuegoAtaque", "Enemigo: %s → %s" % [enemy_start_node, enemy_target_node])
		GameLogger.info("JuegoAtaque", "Bloques/turno: %d, Duración: %d" % [defender_blocks_per_turn, defender_block_duration])


# ─── Delegates a módulos (duck-typing de servicios + tests) ────────

# game_state.gd — InputHandler y tests los consumen vía has_method/refs.
func reset_state() -> void: _game_state.reset_state()
func _target_actual() -> StringName: return _game_state.target_actual()
func _find_node_resource(nid: StringName): return _game_state.find_node_resource(nid)
func _is_blocked(edge_key: String) -> bool: return _game_state.is_blocked(edge_key)
func _block_edge(edge_key: String, from_n: StringName, to_n: StringName) -> void: _game_state.block_edge(edge_key, from_n, to_n)
func _unblock_edge(edge_key: String) -> void: _game_state.unblock_edge(edge_key)
func _limpiar_bloqueos_expirados() -> void: _game_state.limpiar_bloqueos_expirados()
func _edge_en_posicion(pos: Vector2) -> String: return _game_state.edge_en_posicion(pos)
func _nodo_en_posicion(pos: Vector2) -> StringName: return _game_state.nodo_en_posicion(pos)
func _nodo_en_posicion_firewall(pos: Vector2) -> StringName: return _game_state.nodo_en_posicion_firewall(pos)

# game_logic.gd
func _vecinos_jugador() -> Array: return _game_logic.vecinos_jugador()
func _mover_jugador(destino: StringName) -> void: _game_logic.mover_jugador(destino)
func _perder(razon: String) -> void: _game_logic.perder(razon)
func _auto_select_vecino() -> void: _game_logic.auto_select_vecino()
func _cycle_neighbor(dir: int) -> void: _game_logic.cycle_neighbor(dir)

# hacker_logic.gd
func _scan_selected_node() -> void: _hacker_logic.scan_selected_node()
func _use_hacker_exploit(exploit_type: String) -> void: _hacker_logic.use_hacker_exploit(exploit_type)
func _check_hacker_consequences() -> void: _hacker_logic.check_hacker_consequences()


func mostrar_ruta() -> void:
	# No-op deliberado: la visualización automática de ruta no está cableada al
	# renderer; el jugador puede pedir la ruta óptima con [P]. El render real
	# de ruta no es parte de este cambio (P5/tarea 2).
	pass


# ─── MODO DEFENSOR ─────────────────────────────────────────────────

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
	enemy_pos = _defender_brain.enemy_pos
	enemy_target_node = _defender_brain.enemy_target_node
	queue_redraw()


# ─── Wiring de señales del InputHandler ────────────────────────────

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


# ─── Handlers del InputHandler (delgados; lógica en módulos) ───────

func _on_move_requested(destino: StringName) -> void:
	# Fix defensor (Enmienda A): en modo defensor no hay jugador que se mueva
	# por aristas — el movimiento del "jugador" es un no-op.
	if not defender_mode:
		_mover_jugador(destino)


func _on_node_targeted(clicked: StringName, first_step: StringName) -> void:
	selected_neighbor = first_step
	mensaje_estado = "Ruta hacia %s → seleccionado: %s" % [clicked, first_step]
	queue_redraw()


func _on_scan_requested() -> void: _scan_selected_node()
func _on_exploit_used(exploit_type: String) -> void: _use_hacker_exploit(exploit_type)
func _on_toggle_optimal_route() -> void: _game_logic.reveal_optimal_route()
func _on_cycle_neighbor(dir: int) -> void: _cycle_neighbor(dir)
func _on_defender_block_edge(edge_key: String) -> void: _game_logic.defender_block_edge(edge_key)
func _on_defender_place_firewall(node_id: StringName) -> void: _game_logic.defender_place_firewall(node_id)
func _on_return_to_menu() -> void: SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
func _on_quit() -> void: get_tree().quit()


func _on_reset_requested() -> void:
	AudioManager.play_sfx("reset")
	reset_state()


func _on_tutorial_skipped_input() -> void:
	if is_instance_valid(tutorial_player):
		tutorial_player.skip()


func _on_defender_resolve_turn() -> void:
	if _defender_brain != null:
		_defender_brain.resolve_turn()


func _on_defender_toggle_firewall() -> void:
	if _defender_brain != null:
		_defender_brain.toggle_firewall_mode()
		firewall_mode = _defender_brain.firewall_mode


func _on_defender_hover_edge(edge_key: String) -> void:
	if _defender_brain != null:
		_defender_brain.set_hovered_edge(edge_key)
		hovered_edge = edge_key
		queue_redraw()


func _notify_tutorial_input() -> void:
	## Slice 3.8 v2: reporta al tutorial una acción tipo "input" (escanear,
	## explotar, bloquear, firewall); el paso se marca cumplido y [Enter] avanza.
	if is_instance_valid(tutorial_player):
		tutorial_player.notify_input()


# ─── Señales de DefenderBrain (cierre de partida en game_logic.gd) ─

func _on_brain_defender_won(_reason: String, stars: int) -> void: _game_logic.defender_won(stars)
func _on_brain_defender_lost(_reason: String) -> void: _game_logic.defender_lost()


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


# ─── Tutorial ──────────────────────────────────────────────────────

func _setup_tutorial() -> void:
	var tutorial_root = preload("res://juego/tutorials/tutorial_player.tscn").instantiate()
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


func _on_tutorial_step_changed(_step_index: int, _step_data: Dictionary) -> void: queue_redraw()
func _on_tutorial_completed(_tutorial_id: String) -> void:
	mensaje_estado = "Tutorial completado!"
	queue_redraw()


func _on_tutorial_skipped(_tutorial_id: String) -> void:
	mensaje_estado = "Tutorial saltado"
	queue_redraw()


# ─── Render ────────────────────────────────────────────────────────

func _draw() -> void:
	# Guard (tarea 1.4): en modo defensor el brain debe ser una instancia
	# válida (null o freed); si no, omitir el dibujado en lugar de crashear.
	if defender_mode and not is_instance_valid(_defender_brain):
		push_warning("_draw(): _defender_brain no es válido en modo defensor — se omite el dibujado del tablero.")
		return
	var vp_size: Vector2 = get_viewport_rect().size
	if runtime == null or graph == null:
		if mensaje_estado != "" and font != null:
			_renderer.draw_error(vp_size, mensaje_estado)
		return
	# P5/tarea 3: el frame se dibuja con datos puros (GameState.frame_data),
	# sin callables — orquestación en GameRenderer.draw_frame().
	_renderer.draw_frame(_game_state.frame_data(vp_size))
