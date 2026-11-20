extends Node

## Test Suite: Acto 1 (Nodos Dorados + Anclaje EDR) & Sector 0 (Multi-Stage + 3 Daemons vs 1)

const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")
const SlotManagerClass = preload("res://juego/system/slot_manager.gd")
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")
const MultiStageDirectorClass = preload("res://juego/ataque/multi_stage_director.gd")
const MultiDaemonControllerClass = preload("res://juego/ataque/multi_daemon_controller.gd")
const RuntimeClass = preload("res://core/network/network_runtime.gd")
const AI_BLOCKER_PATH: String = "res://juego/ataque/ai_blocker.gd"
const DEFENDER_BRAIN_PATH: String = "res://juego/ataque/defender_brain.gd"
const HackerMechanicsClass = preload("res://juego/system/hacker_mechanics.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST ACTO 1 & SECTOR 0 ---")
	test_sector0_world_registry_and_levels()
	test_golden_nodes_and_slot_gating()
	test_multi_stage_director()
	test_multi_daemon_controller()
	test_stage_transition_snap_and_codec_wiring()
	test_ai_blocker_targets_near_edges_and_multi_block()
	test_hacker_scan_risk_reward()
	test_defender_golden_anchor_and_ping_pong()
	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func test_sector0_world_registry_and_levels() -> void:
	var w_alias: Dictionary = LevelRegistryClass.get_world("sector0")
	var w_secret: Dictionary = LevelRegistryClass.get_world("secret")
	_assert(not w_alias.is_empty() and w_alias.get("title", "") == w_secret.get("title", ""), "sector0 aliases cleanly to secret world")
	var levels: Array = w_secret.get("levels", [])
	_assert(levels.size() >= 4, "Sector 0 has secret_root + trilogy (0.1, 0.2, 0.3)")

	var h5: Dictionary = LevelRegistryClass.load_level_data("res://juego/hacker/hacker_n5.json")
	var c4: Dictionary = LevelRegistryClass.load_level_data("res://juego/cyber/cyber_n4.json")
	_assert(h5.get("bonus_nodes", []).has("Vault_KMS"), "hacker_n5 has Golden Node Vault_KMS")
	_assert(c4.get("bonus_nodes", []).has("VaultEnclave"), "cyber_n4 has Golden Node VaultEnclave")


func test_golden_nodes_and_slot_gating() -> void:
	var orig_slot: int = SlotManagerClass.get_active_slot()
	SlotManagerClass.set_active_slot(1)
	_assert(ProgressUtilClass.is_sector0_unlocked({}), "Slot 1 remains unlocked for testing")

	SlotManagerClass.set_active_slot(2)
	var empty_prog: Dictionary = {"golden_nodes": {}, "konami_unlocked": false}
	_assert(not ProgressUtilClass.is_sector0_unlocked(empty_prog), "New profile (Slot 2) locks Sector 0 initially")

	var partial_prog: Dictionary = {"golden_nodes": {"heist_n5": true, "hacker_n5": true}, "konami_unlocked": false}
	_assert(not ProgressUtilClass.is_sector0_unlocked(partial_prog), "Slot 2 stays locked with only 2/3 Golden Nodes")

	var full_prog: Dictionary = {"golden_nodes": {"heist_n5": true, "hacker_n5": true, "cyber_n4": true}, "konami_unlocked": false}
	_assert(ProgressUtilClass.is_sector0_unlocked(full_prog), "Slot 2 unlocks Sector 0 when all 3 Act 1 Golden Nodes collected")

	SlotManagerClass.set_active_slot(orig_slot)


func test_multi_stage_director() -> void:
	var s01: Dictionary = LevelRegistryClass.load_level_data("res://juego/secret/sector_0_1.json")
	var dir := MultiStageDirectorClass.new()
	dir.setup(s01.get("stages", []))
	_assert(dir.stages.size() == 2, "Sector 0.1 loads 2 stages")
	_assert(dir.has_next_stage(), "Sector 0.1 has next stage after stage 0")

	var s02: Dictionary = LevelRegistryClass.load_level_data("res://juego/secret/sector_0_2.json")
	var dir2 := MultiStageDirectorClass.new()
	dir2.setup(s02.get("stages", []))
	_assert(dir2.stages.size() == 4, "Sector 0.2 loads 4 marathon stages")


func test_multi_daemon_controller() -> void:
	var s03: Dictionary = LevelRegistryClass.load_level_data("res://juego/secret/sector_0_3.json")
	var g: Resource = load(str(s03.get("graph_path", "")))
	_assert(g != null, "Sector 0.3 graph resource loads cleanly")
	var rt := RuntimeClass.new(g)
	var ctrl := MultiDaemonControllerClass.new()
	ctrl.setup(s03.get("multi_daemons", []))
	_assert(ctrl.is_active() and ctrl.daemons.size() == 3, "Sector 0.3 initializes 3 simultaneous Daemons")

	var step1: Dictionary = ctrl.step_daemons(g, rt)
	_assert(not bool(step1.get("breached", true)) and not bool(step1.get("all_contained", true)), "Step 1 advances 3 Daemons without instant breach")

	# Block all 3 exit gateways
	rt.set_transit_cost(&"Exfil_RelayA", &"Exit_Exfil", INF)
	rt.set_transit_cost(&"Exfil_RelayB", &"Exit_Exfil", INF)
	rt.set_transit_cost(&"Fuzz_RelayA", &"Exit_Fuzz", INF)
	rt.set_transit_cost(&"Fuzz_RelayB", &"Exit_Fuzz", INF)
	rt.set_transit_cost(&"Cordon_RelayA", &"Exit_Cordon", INF)
	rt.set_transit_cost(&"Cordon_RelayB", &"Exit_Cordon", INF)
	_assert(ctrl.check_all_contained(g, rt), "Blocking all 3 branches contains EXFIL, FUZZ, and CORDON")


# ─── Stubs y helpers para los tests de gameplay ────────────────────────

class StubPursuit extends RefCounted:
	func process_pursuers(_pos: StringName) -> void:
		pass


class StubGame extends Node:
	var graph: Resource
	var runtime: RefCounted
	var player_pos: StringName = &"A"
	var target_node: StringName = &"F"
	var defender_mode: bool = false
	var game_over: bool = false
	var hacker_mode: bool = false
	var hacker_state: Dictionary = {}
	var ai_enabled: bool = true
	var ai_bloquea_al_inicio: bool = false
	var ia_predictiva: bool = true
	var ai_block_per_turn: int = 2
	var max_ai_blocks: int = 99
	var _ai_blocks_used: int = 0
	var mensaje_estado: String = ""
	var turn: int = 0
	var max_turns: int = 0
	var bonus_nodes: Array = []
	var bonus_visitados: Array = []
	var blocked: Dictionary = {}
	var lost_reason: String = ""
	var _pursuit_system: StubPursuit = StubPursuit.new()

	func _target_actual() -> StringName:
		return target_node

	func _is_blocked(edge_key: String) -> bool:
		return blocked.has(edge_key)

	func _block_edge(edge_key: String, from_n: StringName, to_n: StringName) -> void:
		blocked[edge_key] = true
		runtime.set_transit_cost(from_n, to_n, INF)

	func _perder(reason: String) -> void:
		lost_reason = reason

	func _limpiar_bloqueos_expirados() -> void:
		pass

	func queue_redraw() -> void:
		pass


func _make_graph(edge_list: Array) -> NetworkGraphResource:
	var g := NetworkGraphResource.new()
	var seen: Dictionary = {}
	for pair: Array in edge_list:
		var from_id: StringName = pair[0] as StringName
		var to_id: StringName = pair[1] as StringName
		for nid: StringName in [from_id, to_id]:
			if not seen.has(nid):
				seen[nid] = true
				var n := NetworkNodeResource.new()
				n.id = nid
				g.nodes.append(n)
		var e := NetworkEdgeResource.new()
		e.from_id = from_id
		e.to_id = to_id
		e.transit_cost = float(pair[2])
		g.edges.append(e)
	return g


func _make_stub(edge_list: Array) -> StubGame:
	var stub := StubGame.new()
	stub.graph = _make_graph(edge_list)
	stub.runtime = RuntimeClass.new(stub.graph)
	add_child(stub)
	return stub


func test_stage_transition_snap_and_codec_wiring() -> void:
	var src: String = FileAccess.get_file_as_string("res://juego/ataque/juego_ataque.gd")
	_assert(src.contains("stage_after != stage_before"), "_mover_jugador detects stage change and snaps instead of tweening")
	_assert(src.contains("_input_handler.set_process_input(false)") and src.contains("_input_handler.set_process_input(true)"), "Codec overlay pauses and restores input handler")
	_assert(src.contains("_codec_overlay.size = get_viewport_rect().size"), "Codec overlay is resized to the viewport")


func test_ai_blocker_targets_near_edges_and_multi_block() -> void:
	# Ruta principal A-B-C-D-E-F con dos desvíos alternativos C-X-D y C-Y-D.
	var edge_list: Array = [
		["A", "B", 1], ["B", "C", 1], ["C", "D", 1], ["D", "E", 1], ["E", "F", 1],
		["C", "X", 2], ["X", "D", 2], ["C", "Y", 3], ["Y", "D", 3],
	]
	var stub: StubGame = _make_stub(edge_list)
	var blocker: RefCounted = (load(AI_BLOCKER_PATH) as GDScript).new()
	blocker.setup(stub)
	blocker.take_turn()
	_assert(stub.blocked.has("C→D"), "Predictive AI blocks an edge 2 hops ahead (C→D), not the route end (E→F)")
	_assert(not stub.blocked.has("E→F"), "Predictive AI does not waste the block on the end of the route")
	_assert(stub.blocked.size() == 2, "Predictive AI uses the remaining block of the turn after rerouting")
	_assert(stub.blocked.has("C→X"), "Second block targets the recomputed alternative route (C→X)")
	_assert(stub.lost_reason == "", "AI never isolates the player while using multiple blocks")
	stub.queue_free()

	# Con un solo bloqueo por turno solo se bloquea una arista.
	var stub2: StubGame = _make_stub(edge_list)
	stub2.ai_block_per_turn = 1
	var blocker2: RefCounted = (load(AI_BLOCKER_PATH) as GDScript).new()
	blocker2.setup(stub2)
	blocker2.take_turn()
	_assert(stub2.blocked.size() == 1, "ai_block_per_turn = 1 yields exactly one block")
	stub2.queue_free()


func test_hacker_scan_risk_reward() -> void:
	var st: Dictionary = HackerMechanicsClass.create_state()
	var r1: Dictionary = HackerMechanicsClass.apply_scan_risk_reward(st, &"N1", true, 3, false)
	_assert(int(r1["noise_added"]) == 8 and int(st["noise"]) == 8, "New scan adds +8 IDS noise")
	_assert(str(r1["exploit_gained"]) != "" and int(st["exploits"].get(str(r1["exploit_gained"]), 0)) == 1, "Scan on node_type >= 2 extracts +1 exploit charge")
	var r2: Dictionary = HackerMechanicsClass.apply_scan_risk_reward(st, &"N1", true, 3, false)
	_assert(str(r2["exploit_gained"]) == "", "Exploit charge is extracted once per node")
	var r3: Dictionary = HackerMechanicsClass.apply_scan_risk_reward(st, &"N2", true, 1, false)
	_assert(str(r3["exploit_gained"]) == "", "Nodes with node_type < 2 yield no exploit charge")

	var st2: Dictionary = HackerMechanicsClass.create_state()
	var g: Dictionary = HackerMechanicsClass.apply_scan_risk_reward(st2, &"GOLD", true, 1, true)
	_assert(int(g["noise_added"]) == 26 and int(st2["noise"]) == 26, "Golden scan adds +18 risk on top of +8")
	_assert(bool(g["deep_harvest"]) and int(g["extra_turns"]) == 2, "Golden scan triggers Deep Harvest (+2 max turns)")
	_assert(int(st2["exploits"].get("bypass", 0)) == 1 and int(st2["exploits"].get("escalate", 0)) == 1, "Deep Harvest grants +1 bypass and +1 escalate")


func test_defender_golden_anchor_and_ping_pong() -> void:
	var edge_list: Array = [["S", "M", 1], ["M", "T", 1], ["S", "G", 1], ["G", "T", 1], ["M", "G", 1]]
	var stub: StubGame = _make_stub(edge_list)
	stub.target_node = &"T"
	stub.bonus_nodes = [&"G"]
	var brain: RefCounted = (load(DEFENDER_BRAIN_PATH) as GDScript).new()
	brain.setup(stub, {"enemy_start": &"S", "enemy_target": &"T", "blocks_per_turn": 2, "block_duration": 4})
	brain.init()
	brain.defender_max_blocks = 10
	var turn_before: int = stub.turn
	var max_before: int = brain.defender_max_blocks
	brain.anchor_golden_node(&"G")
	_assert(stub.bonus_visitados.has(&"G"), "Anchoring registers the Golden Node")
	_assert(brain.defender_max_blocks == max_before + 1, "Anchoring a Golden Node grants +1 defender_max_blocks")
	_assert(stub.turn == turn_before + 1, "Ping-pong: anchoring resolves the turn immediately")
	_assert(brain.forensics_trace >= 20.0, "Anchoring grants +20% forensics trace (plus turn trace)")

	# Nodo Dorado corrompido: el atacante lo pisa antes del anclaje.
	var stub2: StubGame = _make_stub(edge_list)
	stub2.target_node = &"T"
	stub2.bonus_nodes = [&"G"]
	var brain2: RefCounted = (load(DEFENDER_BRAIN_PATH) as GDScript).new()
	brain2.setup(stub2, {"enemy_start": &"S", "enemy_target": &"T", "blocks_per_turn": 2, "block_duration": 4})
	brain2.init()
	brain2._corrupt_golden_if_stepped(&"G")
	brain2.anchor_golden_node(&"G")
	_assert(not stub2.bonus_visitados.has(&"G"), "A corrupted Golden Node cannot be anchored")

	# Firewall en modo ping-pong resuelve el turno al instante.
	var stub3: StubGame = _make_stub(edge_list)
	stub3.target_node = &"T"
	var brain3: RefCounted = (load(DEFENDER_BRAIN_PATH) as GDScript).new()
	brain3.setup(stub3, {"enemy_start": &"S", "enemy_target": &"T", "blocks_per_turn": 2, "block_duration": 4, "firewall_cost": 1})
	brain3.init()
	var t3: int = stub3.turn
	brain3.place_firewall(&"G")
	_assert(stub3.turn == t3 + 1, "Ping-pong: placing a firewall resolves the turn immediately")
	stub.queue_free()
	stub2.queue_free()
	stub3.queue_free()
