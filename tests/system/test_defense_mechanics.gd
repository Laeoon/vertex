extends Node

## Test Suite: Defense Mechanics (EDR Trace, Lateral Movement & Quarantine)
## Tests that defender mode does not trivially win on turn 1, accumulates EDR trace,
## handles attacker lateral diversion, and isolates nodes via quarantine.

const DefenderBrainClass = preload("res://juego/ataque/defender_brain.gd")
const NetworkGraphResourceClass = preload("res://core/network/network_graph_resource.gd")
const NetworkNodeResourceClass = preload("res://core/network/network_node_resource.gd")
const NetworkEdgeResourceClass = preload("res://core/network/network_edge_resource.gd")
const NetworkRuntimeClass = preload("res://core/network/network_runtime.gd")

var _passed: int = 0
var _failed: int = 0


# Mock Game container for DefenderBrain testing
class MockDefenseGame extends Node:
	var graph = null
	var runtime = null
	var turn: int = 0
	var max_turns: int = 10
	var game_over: bool = false
	var game_won: bool = false
	var target_node: StringName = &"DataCenter"
	var _blocked_edges: Dictionary = {}

	func _is_blocked(edge_key: String) -> bool:
		return _blocked_edges.has(edge_key)

	func _block_edge(edge_key: String, from_n: StringName, to_n: StringName) -> void:
		_blocked_edges[edge_key] = 3
		if runtime != null:
			runtime.set_transit_cost(from_n, to_n, INF)

	func _limpiar_bloqueos_expirados() -> void:
		var a_eliminar := []
		for ek in _blocked_edges:
			_blocked_edges[ek] -= 1
			if _blocked_edges[ek] <= 0:
				a_eliminar.append(ek)
		for ek in a_eliminar:
			_blocked_edges.erase(ek)
			var parts = ek.split("→")
			if parts.size() == 2 and runtime != null:
				runtime.set_transit_cost(parts[0] as StringName, parts[1] as StringName, 1.0)


func _ready() -> void:
	print("--- START TEST DEFENSE MECHANICS ---")
	test_initial_state_and_no_instant_win()
	test_forensics_trace_progression()
	test_attacker_lateral_movement()
	test_quarantine_node_severing()
	test_fog_of_war_and_star_penalty()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func _build_diamond_graph() -> Dictionary:
	# Topología:
	# Internet ──► RouterA ──► DataCenter
	#    │                      ▲
	#    └───────► RouterB ─────┘
	var g := NetworkGraphResourceClass.new()
	var n_in := NetworkNodeResourceClass.new(); n_in.id = &"Internet"; n_in.node_type = 0
	var n_ra := NetworkNodeResourceClass.new(); n_ra.id = &"RouterA"; n_ra.node_type = 3
	var n_rb := NetworkNodeResourceClass.new(); n_rb.id = &"RouterB"; n_rb.node_type = 3
	var n_dc := NetworkNodeResourceClass.new(); n_dc.id = &"DataCenter"; n_dc.node_type = 5
	g.nodes = [n_in, n_ra, n_rb, n_dc]

	var e1 := NetworkEdgeResourceClass.new(); e1.from_id = &"Internet"; e1.to_id = &"RouterA"; e1.transit_cost = 1.0; e1.mitigation_capacity = 1.0
	var e2 := NetworkEdgeResourceClass.new(); e2.from_id = &"RouterA"; e2.to_id = &"DataCenter"; e2.transit_cost = 1.0; e2.mitigation_capacity = 1.0
	var e3 := NetworkEdgeResourceClass.new(); e3.from_id = &"Internet"; e3.to_id = &"RouterB"; e3.transit_cost = 2.0; e3.mitigation_capacity = 1.0
	var e4 := NetworkEdgeResourceClass.new(); e4.from_id = &"RouterB"; e4.to_id = &"DataCenter"; e4.transit_cost = 2.0; e4.mitigation_capacity = 1.0
	g.edges = [e1, e2, e3, e4]

	var rt := NetworkRuntimeClass.new(g)
	return {"graph": g, "runtime": rt}


func test_initial_state_and_no_instant_win() -> void:
	var fixtures := _build_diamond_graph()
	var game := MockDefenseGame.new()
	game.graph = fixtures["graph"]
	game.runtime = fixtures["runtime"]

	var brain = DefenderBrainClass.new()
	brain.setup(game, {
		"enemy_start": &"Internet",
		"enemy_target": &"DataCenter",
		"blocks_per_turn": 2,
		"block_duration": 4
	})
	brain.init()

	_assert(brain.forensics_trace == 0.0, "forensics_trace starts at 0.0%")
	_assert(brain.quarantined_nodes.is_empty(), "quarantined_nodes starts empty")

	# Bloquear ambas rutas hacia DataCenter en turno 0
	brain.block_edge("Internet→RouterA")
	brain.block_edge("Internet→RouterB")

	# Bajo la doctrina nueva: el bloqueo total NO da victoria instantánea inmediata en Turno 0
	_assert(not game.game_won, "Blocking both paths does NOT trigger instant win on turn 0")
	_assert(not game.game_over, "Game is still active under siege")


func test_forensics_trace_progression() -> void:
	var fixtures := _build_diamond_graph()
	var game := MockDefenseGame.new()
	game.graph = fixtures["graph"]
	game.runtime = fixtures["runtime"]

	var brain = DefenderBrainClass.new()
	brain.setup(game, {
		"enemy_start": &"Internet",
		"enemy_target": &"DataCenter",
		"blocks_per_turn": 1,
		"block_duration": 4
	})
	brain.init()

	var win_fired: Array = [false]
	brain.defender_won.connect(func(_r, _s): win_fired[0] = true)

	# Ciclo Ping-Pong reactivo: CADA bloqueo ejecuta automáticamente el turno
	# Turno 1: bloqueamos Internet->RouterA. El atacante inmediatamente responde y se mueve a RouterB.
	brain.block_edge("Internet→RouterA")
	_assert(brain.enemy_pos == &"RouterB", "Ping-pong: Attacker immediately reacts and moves to RouterB")
	_assert(game.turn == 1, "Turn automatically advanced to 1 upon block")
	_assert(brain.forensics_trace >= 20.0, "forensics_trace reaches >= 20%% on turn 1")

	# Turno 2: bloqueamos RouterB->DataCenter. El atacante queda contenido sondeando.
	brain.block_edge("RouterB→DataCenter")
	_assert(game.turn == 2, "Turn automatically advanced to 2 upon block")
	_assert(brain.forensics_trace >= 50.0, "forensics_trace reaches >= 50%% on turn 2 (contained bonus)")

	# Turno 3 y 4: bloqueos adicionales para acumular el 100% de Trace
	brain.block_edge("Internet→RouterB")
	brain.block_edge("RouterA→DataCenter")

	_assert(brain.forensics_trace >= 100.0, "forensics_trace reaches 100.0%")
	_assert(win_fired[0], "EDR Trace 100% triggers defender_won in ping-pong loop")


func test_attacker_lateral_movement() -> void:
	var fixtures := _build_diamond_graph()
	var game := MockDefenseGame.new()
	game.graph = fixtures["graph"]
	game.runtime = fixtures["runtime"]

	var brain = DefenderBrainClass.new()
	brain.setup(game, {
		"enemy_start": &"Internet",
		"enemy_target": &"DataCenter",
		"blocks_per_turn": 1,
		"block_duration": 4
	})
	brain.init()

	# El camino más corto original es Internet -> RouterA -> DataCenter
	_assert(brain.enemy_path[1] == &"RouterA", "Original shortest path heads to RouterA")

	# Ping-pong: Al bloquear la arista principal Internet->RouterA, el atacante busca ruta y avanza hacia RouterB
	brain.block_edge("Internet→RouterA")
	_assert(brain.enemy_pos == &"RouterB", "Attacker lateral movement advances to RouterB upon block (got %s)" % brain.enemy_pos)


func test_quarantine_node_severing() -> void:
	var fixtures := _build_diamond_graph()
	var game := MockDefenseGame.new()
	game.graph = fixtures["graph"]
	game.runtime = fixtures["runtime"]

	var brain = DefenderBrainClass.new()
	brain.setup(game, {
		"enemy_start": &"Internet",
		"enemy_target": &"DataCenter",
		"blocks_per_turn": 2,
		"block_duration": 4
	})
	brain.init()

	# Poner en cuarentena a RouterB
	brain.quarantine_node(&"RouterB")
	_assert(brain.is_node_quarantined(&"RouterB"), "RouterB is marked as quarantined")

	# Verificar que el costo de transitar hacia o desde RouterB sea infinito
	var cost_to: float = game.runtime.get_transit_cost(&"Internet", &"RouterB")
	var cost_from: float = game.runtime.get_transit_cost(&"RouterB", &"DataCenter")
	_assert(is_inf(cost_to), "Incoming transit cost to quarantined node is INF")
	_assert(is_inf(cost_from), "Outgoing transit cost from quarantined node is INF")


func test_fog_of_war_and_star_penalty() -> void:
	var fixtures := _build_diamond_graph()
	var game := MockDefenseGame.new()
	game.graph = fixtures["graph"]
	game.runtime = fixtures["runtime"]

	var brain = DefenderBrainClass.new()
	brain.setup(game, {
		"enemy_start": &"Internet",
		"enemy_target": &"DataCenter",
		"blocks_per_turn": 1,
		"block_duration": 4,
		"fog_of_war": true
	})
	brain.init()

	_assert(brain.fog_of_war == true, "fog_of_war is active on level 2+")
	_assert(brain.is_enemy_path_revealed() == false, "Enemy path is hidden by default under fog of war")

	# Revelar ruta con intercepción táctica (tecla P)
	brain.reveal_enemy_path()
	_assert(brain.is_enemy_path_revealed() == true, "Enemy path is revealed after manual intercept")
	_assert(brain.telemetry_intercepted == true, "telemetry_intercepted flag is set")

	# Verificar que el cálculo de estrellas esté topado a 2 estrellas máximo
	var stars: int = brain.calcular_estrellas()
	_assert(stars <= 2, "Star rating is capped at maximum 2 stars when telemetry is intercepted (got %d)" % stars)

