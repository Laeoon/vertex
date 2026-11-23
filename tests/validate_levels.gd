extends Node

## Headless Level Validator for VERTEX (F2.2).
##
## Validates all levels registered in LevelRegistry.WORLDS for:
##   1. Schema & inventory consistency (v1 & v2 *.level.json, alarm events, strict raw checks).
##   2. Cross-references (start, target, waypoints, bonus_nodes, hidden_nodes,
##      node_positions, locked_edges, node_triggers, stages, defender/multi_daemons).
##   3. Spatial & grid collision checks (minimum 24px separation, unique v2 grid cells).
##   4. Algorithmic solvability (Dijkstra multi-segment / multi-stage, Golden Nodes,
##      Par 3-star achievability, Edmonds-Karp Min-Cut containment in Defender mode).
##   5. Multivariable Tactical Pressure Index (IPT 0..100, Tier 1..5) & ascending
##      difficulty curves across heist, hacker, and cybersecurity.
##   6. Negative unit tests (5 synthetic broken levels must fail validation).

const Registry = preload("res://juego/system/level_registry.gd")
const LoaderV2 = preload("res://juego/system/level_loader_v2.gd")
const DefensivePathfinder = preload("res://core/agents/defensive_pathfinder.gd")
const StrategicAnalyzer = preload("res://core/agents/strategic_analyzer.gd")
const GraphBuilder = preload("res://tests/core/_graph_builder.gd")

const VALID_ALARM_EFFECTS: Array[String] = [
	"spawn_pursuer",
	"ai_extra_block",
	"pursuer_speed_up",
]
const MIN_NODE_DISTANCE_PX: float = 24.0
const MIN_CLAVES: Array[String] = [
	"id",
	"world",
	"start_node",
	"target_node",
	"titulo_nivel",
	"max_turns",
]

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var ipt_by_id: Dictionary = {}
	print("==============================================")
	print("VALIDATE_LEVELS — Auditoria de Solubilidad & IPT")
	print("==============================================")

	for world_id_var in Registry.WORLDS.keys():
		var world_id: String = str(world_id_var)
		var world_cfg: Dictionary = Registry.WORLDS[world_id]
		var levels: Array = world_cfg.get("levels", [])
		for cfg_var in levels:
			var cfg: Dictionary = cfg_var
			var path: String = str(cfg.get("path", ""))
			var raw_data: Dictionary = _load_raw_json(path)
			var norm_data: Dictionary = Registry.load_level_data(path)
			var res: Dictionary = validate_level_dict(norm_data, raw_data, path.get_file(), false)
			var errs: Array = res.get("errors", [])
			var metrics: Dictionary = res.get("metrics", {})
			var lvl_id: String = str(norm_data.get("id", path.get_file()))
			ipt_by_id[lvl_id] = metrics
			print("IPT | %-13s | %-13s | ipt=%5.1f (T%d) | hops=%d cost=%.1f mc=%d alt=%d" % [
				world_id,
				lvl_id,
				float(metrics.get("ipt_score", 0.0)),
				int(metrics.get("tier", 1)),
				int(metrics.get("min_hops", 0)),
				float(metrics.get("min_cost", 0.0)),
				int(metrics.get("min_cut", 0)),
				int(metrics.get("alt_routes", 0)),
			])
			_afirmar(bool(res.get("ok", false)),
				"nivel %s valido (%s)" % [lvl_id, "OK" if errs.is_empty() else "; ".join(errs)])

	_verify_difficulty_curves(ipt_by_id)
	_run_negative_unit_tests()

	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)


# ─── Public Validation API ─────────────────────────────────────────────

static func validate_level_dict(
	data: Dictionary,
	raw_data: Dictionary = {},
	label: String = "level",
	strict_raw_check: bool = false
) -> Dictionary:
	var errors: Array[String] = []
	var metrics: Dictionary = {}

	if data.is_empty():
		errors.append("%s: diccionario de nivel vacio" % label)
		return {"ok": false, "errors": errors, "metrics": metrics}

	for clave in MIN_CLAVES:
		if not data.has(clave) or str(data.get(clave, "")).is_empty():
			errors.append("%s: falta clave obligatoria '%s'" % [label, clave])

	var world_id: String = str(data.get("world", ""))
	if not world_id.is_empty() and not Registry.WORLDS.has(world_id):
		errors.append("%s: world '%s' no registrado en LevelRegistry" % [label, world_id])

	if strict_raw_check and not raw_data.is_empty() and int(raw_data.get("schema_version", 1)) < 2:
		if raw_data.has("eventos") and not raw_data.has("eventos_alarma"):
			errors.append("%s: clave legacy 'eventos' sin normalizar a 'eventos_alarma'" % label)

	var eventos_var: Variant = data.get("eventos_alarma", data.get("eventos", []))
	if eventos_var is Array:
		var max_t: int = int(data.get("max_turns", 0))
		for ev_var in (eventos_var as Array):
			if not (ev_var is Dictionary):
				errors.append("%s: evento de alarma no es Dictionary" % label)
				continue
			var ev: Dictionary = ev_var
			var turno: int = int(ev.get("turno", 0))
			var efecto: String = str(ev.get("efecto", ""))
			if turno <= 0 or (max_t > 0 and turno > max_t):
				errors.append("%s: evento con turno fuera de rango (%d)" % [label, turno])
			if not VALID_ALARM_EFFECTS.has(efecto):
				errors.append("%s: efecto de alarma desconocido '%s'" % [label, efecto])

	var graph: NetworkGraphResource = _resolve_graph(data)
	if graph == null:
		errors.append("%s: no se pudo cargar grafo valido" % label)
		return {"ok": false, "errors": errors, "metrics": metrics}

	for g_err in graph.validate():
		errors.append("%s: graph.validate(): %s" % [label, g_err])

	errors.append_array(_validate_cross_references(graph, data, label, strict_raw_check, raw_data))
	errors.append_array(validate_spatial_layout(graph, data))

	var solv: Dictionary = validate_solvability(graph, data)
	for s_err in solv.get("errors", []):
		errors.append("%s: %s" % [label, str(s_err)])

	metrics = compute_tactical_pressure(graph, data, solv)
	metrics["min_hops"] = int(solv.get("min_hops", 0))
	metrics["min_cost"] = float(solv.get("min_cost", 0.0))
	metrics["min_cut"] = int(solv.get("min_cut", 0))
	metrics["alt_routes"] = int(solv.get("alt_routes", 0))

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"metrics": metrics,
	}


static func validate_spatial_layout(graph: NetworkGraphResource, data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var positions: Dictionary = {}
	var np_override: Variant = data.get("node_positions", {})
	var override_dict: Dictionary = np_override if (np_override is Dictionary) else {}

	for n in graph.nodes:
		if n == null:
			continue
		var nid: String = str(n.id)
		var pos: Vector2 = n.position
		if override_dict.has(nid):
			var raw_pos: Variant = override_dict[nid]
			if raw_pos is Array and (raw_pos as Array).size() >= 2:
				var arr: Array = raw_pos
				pos = Vector2(float(arr[0]), float(arr[1]))
			elif raw_pos is Vector2:
				pos = raw_pos
		positions[nid] = pos

	var ids: Array = positions.keys()
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var id_a: String = str(ids[i])
			var id_b: String = str(ids[j])
			var pos_a: Vector2 = positions[id_a]
			var pos_b: Vector2 = positions[id_b]
			if pos_a.distance_to(pos_b) < MIN_NODE_DISTANCE_PX:
				errors.append("colision espacial entre '%s' y '%s' (dist=%.1fpx < %.1fpx)" % [
					id_a, id_b, pos_a.distance_to(pos_b), MIN_NODE_DISTANCE_PX
				])

	if data.has("graph") and data.get("graph") is Dictionary:
		var graph_dict: Dictionary = data.get("graph")
		var layout: Dictionary = data.get("layout", {}) if data.get("layout") is Dictionary else {}
		var cols: int = int(layout.get("grid_cols", 8))
		var rows: int = int(layout.get("grid_rows", 5))
		var used_cells: Dictionary = {}
		var raw_nodes: Variant = graph_dict.get("nodes", [])
		if raw_nodes is Array:
			for n_var in (raw_nodes as Array):
				if not (n_var is Dictionary):
					continue
				var nd: Dictionary = n_var
				if nd.has("grid") and nd.get("grid") is Array and (nd.get("grid") as Array).size() >= 2:
					var g: Array = nd.get("grid")
					var col: int = int(g[0])
					var row: int = int(g[1])
					var nid: String = str(nd.get("id", "?"))
					if col < 0 or col >= cols or row < 0 or row >= rows:
						errors.append("nodo '%s' fuera de grilla [%d,%d] en %dx%d" % [nid, col, row, cols, rows])
					var cell_key: String = "%d,%d" % [col, row]
					if used_cells.has(cell_key):
						errors.append("colision de grilla en [%s] entre '%s' y '%s'" % [
							cell_key, str(used_cells[cell_key]), nid
						])
					else:
						used_cells[cell_key] = nid

	return errors


static func validate_solvability(graph: NetworkGraphResource, data: Dictionary) -> Dictionary:
	if bool(data.get("defender_mode", false)):
		return _validate_defender_solvability(graph, data)
	return _validate_attack_solvability(graph, data)


static func compute_tactical_pressure(
	graph: NetworkGraphResource,
	data: Dictionary,
	solv: Dictionary
) -> Dictionary:
	var is_def: bool = bool(data.get("defender_mode", false))
	var max_turns: int = maxi(1, int(data.get("max_turns", 15)))
	var min_hops: int = maxi(1, int(solv.get("min_hops", 1)))
	var min_cost: float = float(solv.get("min_cost", 1.0))
	var min_cut: int = maxi(1, int(solv.get("min_cut", 1)))
	var alt_routes: int = int(solv.get("alt_routes", 0))

	# 1. Budget / Containment Pressure (0..25)
	var budget_pressure: float = 0.0
	if is_def:
		var blocks_per_turn: int = maxi(1, int(data.get("defender_blocks_per_turn", 1)))
		var dur: int = maxi(1, int(data.get("defender_block_duration", 3)))
		var cut_count: int = maxi(1, int(solv.get("cut_count", min_cut)))
		var cap_ratio: float = clampf(float(cut_count) / float(blocks_per_turn * dur), 0.0, 1.0)
		var turn_urgency: float = clampf(float(blocks_per_turn * 3) / float(maxi(1, min_hops)), 0.0, 1.0)
		budget_pressure = 12.0 * cap_ratio + 13.0 * clampf(float(cut_count) / float(blocks_per_turn), 0.0, 1.5) / 1.5
		if dur <= 3:
			budget_pressure += 3.0 * turn_urgency
	else:
		var turn_ratio: float = clampf(float(min_hops) / float(max_turns), 0.0, 1.0)
		var max_mp: int = int(data.get("max_movement_points", 0))
		var mp_ratio: float = clampf(min_cost / float(max_mp), 0.0, 1.0) if max_mp > 0 else 0.35
		budget_pressure = 12.5 * turn_ratio + 12.5 * mp_ratio
	budget_pressure = clampf(budget_pressure, 0.0, 25.0)

	# 2. AI / Threat Pressure (0..20)
	var ai_pressure: float = 0.0
	if is_def:
		var max_flow: float = float(solv.get("max_flow", 1.0))
		var daemons: Array = data.get("multi_daemons", []) if data.get("multi_daemons") is Array else []
		ai_pressure = clampf(max_flow * 2.5 + float(daemons.size()) * 3.0, 0.0, 20.0)
	elif bool(data.get("ai_enabled", false)):
		ai_pressure += 5.0
		ai_pressure += minf(6.0, float(int(data.get("ai_block_per_turn", 1))) * 3.0)
		if bool(data.get("ai_bloquea_al_inicio", false)):
			ai_pressure += 3.0
		if bool(data.get("ia_predictiva", false)):
			ai_pressure += 4.0
		if int(data.get("block_duration", 3)) >= 3:
			ai_pressure += 2.0
	ai_pressure = clampf(ai_pressure, 0.0, 20.0)

	# 3. Pursuit & Alarm Pressure (0..15)
	var pursuit_pressure: float = 0.0
	if not is_def and bool(data.get("ai_enabled", false)):
		var p_delay: int = int(data.get("pursuer_delay", 0))
		var p_speed: int = int(data.get("pursuer_speed", 1))
		var p_max: int = int(data.get("max_pursuers", 1))
		if data.has("pursuer_delay") or data.has("pursuer_speed") or data.has("max_pursuers"):
			pursuit_pressure += clampf(float(p_speed) * 2.0 + float(p_max) * 1.2 + maxf(0.0, 4.0 - float(p_delay)), 0.0, 9.0)
	var eventos: Array = data.get("eventos_alarma", data.get("eventos", [])) if data.get("eventos_alarma", data.get("eventos", [])) is Array else []
	pursuit_pressure += minf(6.0, float(eventos.size()) * 2.0)
	pursuit_pressure = clampf(pursuit_pressure, 0.0, 15.0)

	# 4. Topology Pressure (0..15)
	var stages: Array = data.get("stages", []) if data.get("stages") is Array else []
	var waypoints: Array = data.get("waypoints", []) if data.get("waypoints") is Array else []
	var bonus_nodes: Array = data.get("bonus_nodes", []) if data.get("bonus_nodes") is Array else []
	var topology_pressure: float = 0.0
	topology_pressure += clampf(float(graph.nodes.size()) / 26.0 * 6.0, 0.0, 6.0)
	topology_pressure += clampf(float(waypoints.size()) * 2.0, 0.0, 6.0)
	topology_pressure += clampf(float(stages.size()) * 1.5 + float(bonus_nodes.size()) * 1.5, 0.0, 5.0)
	topology_pressure = clampf(topology_pressure, 0.0, 15.0)

	# 5. Mechanics Pressure (0..15)
	var mechanics_pressure: float = 0.0
	var hidden: Array = data.get("hidden_nodes", []) if data.get("hidden_nodes") is Array else []
	var locked: Array = data.get("locked_edges", []) if data.get("locked_edges") is Array else []
	var triggers: Dictionary = data.get("node_triggers", {}) if data.get("node_triggers") is Dictionary else {}
	mechanics_pressure += minf(6.0, float(hidden.size() + locked.size() + triggers.size()) * 1.2)
	var sec_nodes: int = 0
	for n in graph.nodes:
		if n == null:
			continue
		if float(n.metadata.get("detection_chance", 0.0)) > 0.0 or bool(n.metadata.get("has_firewall", false)) or bool(n.metadata.get("is_decoy", false)):
			sec_nodes += 1
	mechanics_pressure += minf(5.0, float(sec_nodes) * 0.6)
	if bool(data.get("hacker_mode", false)):
		var exp_dict: Dictionary = data.get("starting_exploits", {}) if data.get("starting_exploits") is Dictionary else {}
		var total_exp: int = 0
		for v in exp_dict.values():
			total_exp += int(v)
		mechanics_pressure += clampf(6.0 - float(total_exp) * 0.4, 1.5, 5.0)
	mechanics_pressure = clampf(mechanics_pressure, 0.0, 15.0)

	# 6. Route Scarcity (0..10)
	var route_scarcity: float = 0.0
	if is_def:
		route_scarcity = clampf(float(alt_routes) * 1.5 + float(min_cut) * 2.0, 0.0, 10.0)
	else:
		route_scarcity = clampf((1.0 / float(min_cut)) * 5.0 + (5.0 if alt_routes <= 1 else 2.0), 0.0, 10.0)

	var ipt_score: float = clampf(
		budget_pressure + ai_pressure + pursuit_pressure + topology_pressure + mechanics_pressure + route_scarcity,
		0.0,
		100.0
	)
	var tier: int = 1
	if ipt_score >= 68.0:
		tier = 5
	elif ipt_score >= 54.0:
		tier = 4
	elif ipt_score >= 40.0:
		tier = 3
	elif ipt_score >= 26.0:
		tier = 2

	return {
		"ipt_score": ipt_score,
		"tier": tier,
		"breakdown": {
			"budget": budget_pressure,
			"ai": ai_pressure,
			"pursuit": pursuit_pressure,
			"topology": topology_pressure,
			"mechanics": mechanics_pressure,
			"scarcity": route_scarcity,
		},
	}


# ─── Internal Helpers ──────────────────────────────────────────────────

static func _resolve_graph(data: Dictionary) -> NetworkGraphResource:
	var inline: Variant = data.get("inline_graph", null)
	if inline is NetworkGraphResource:
		return inline as NetworkGraphResource
	var graph_path: String = str(data.get("graph_path", ""))
	if graph_path.is_empty() or not ResourceLoader.exists(graph_path):
		return null
	var res: Resource = load(graph_path)
	return res as NetworkGraphResource if (res is NetworkGraphResource) else null


static func _validate_cross_references(
	graph: NetworkGraphResource,
	data: Dictionary,
	label: String,
	strict_raw_check: bool,
	raw_data: Dictionary
) -> Array[String]:
	var errors: Array[String] = []
	for key in ["start_node", "target_node"]:
		var nid: String = str(data.get(key, ""))
		if not nid.is_empty() and graph.get_node_by_id(StringName(nid)) == null:
			errors.append("%s: %s '%s' no existe en el grafo" % [label, key, nid])

	for arr_key in ["waypoints", "bonus_nodes", "hidden_nodes"]:
		var arr_var: Variant = data.get(arr_key, [])
		if arr_var is Array:
			for item in (arr_var as Array):
				var nid: String = str(item)
				if graph.get_node_by_id(StringName(nid)) == null:
					errors.append("%s: %s '%s' no existe en el grafo" % [label, arr_key, nid])

	var np_var: Variant = data.get("node_positions", {})
	if np_var is Dictionary:
		var np: Dictionary = np_var
		for k in np.keys():
			if graph.get_node_by_id(StringName(str(k))) == null:
				errors.append("%s: node_positions referencia nodo inexistente '%s'" % [label, str(k)])
		if strict_raw_check and not np.is_empty() and np.size() < graph.nodes.size():
			errors.append("%s: node_positions incompleto (%d/%d nodos)" % [label, np.size(), graph.nodes.size()])

	var locked_var: Variant = data.get("locked_edges", [])
	if locked_var is Array:
		for ek_var in (locked_var as Array):
			var ek: String = str(ek_var)
			var parts: PackedStringArray = ek.split("→")
			if parts.size() != 2:
				errors.append("%s: locked_edge invalida '%s'" % [label, ek])
			elif not _edge_exists(graph, StringName(parts[0]), StringName(parts[1])):
				errors.append("%s: locked_edge '%s' no existe en el grafo" % [label, ek])

	var trig_var: Variant = data.get("node_triggers", {})
	if trig_var is Dictionary:
		var trigs: Dictionary = trig_var
		for t_node in trigs.keys():
			if graph.get_node_by_id(StringName(str(t_node))) == null:
				errors.append("%s: node_trigger '%s' no existe en el grafo" % [label, str(t_node)])
			var t_cfg: Variant = trigs[t_node]
			if t_cfg is Dictionary:
				var effs: Variant = (t_cfg as Dictionary).get("efectos", [])
				if effs is Array:
					for eff_var in (effs as Array):
						var eff: String = str(eff_var)
						if eff.begins_with("reveal_nodes:"):
							for rn in eff.trim_prefix("reveal_nodes:").split(","):
								if graph.get_node_by_id(StringName(rn)) == null:
									errors.append("%s: trigger reveal_nodes apunta a '%s' inexistente" % [label, rn])
						elif eff.begins_with("unlock_edge:"):
							var ep: PackedStringArray = eff.trim_prefix("unlock_edge:").split("→")
							if ep.size() != 2 or not _edge_exists(graph, StringName(ep[0]), StringName(ep[1])):
								errors.append("%s: trigger unlock_edge '%s' invalida" % [label, eff])

	if bool(data.get("defender_mode", false)):
		for ek_name in ["enemy_start_node", "enemy_target_node"]:
			var nid: String = str(data.get(ek_name, ""))
			if nid.is_empty() or graph.get_node_by_id(StringName(nid)) == null:
				errors.append("%s: defender_mode %s '%s' invalido" % [label, ek_name, nid])
		var md_var: Variant = data.get("multi_daemons", [])
		if md_var is Array:
			for d_var in (md_var as Array):
				if not (d_var is Dictionary):
					continue
				var dd: Dictionary = d_var
				var ds: StringName = StringName(str(dd.get("start", "")))
				var dt: StringName = StringName(str(dd.get("target", "")))
				if graph.get_node_by_id(ds) == null or graph.get_node_by_id(dt) == null or ds == dt:
					errors.append("%s: multi_daemon '%s' invalido (%s -> %s)" % [label, str(dd.get("id", "?")), ds, dt])

	var stages_var: Variant = data.get("stages", [])
	if stages_var is Array and not (stages_var as Array).is_empty():
		for idx in range((stages_var as Array).size()):
			var st: Variant = (stages_var as Array)[idx]
			if not (st is Dictionary):
				errors.append("%s: stage[%d] no es Dictionary" % [label, idx])
				continue
			var st_dict: Dictionary = st
			var sg: NetworkGraphResource = _resolve_graph(st_dict)
			if sg == null:
				errors.append("%s: stage[%d] sin grafo valido" % [label, idx])
				continue
			for sk in ["start_node", "target_node"]:
				var snid: String = str(st_dict.get(sk, ""))
				if sg.get_node_by_id(StringName(snid)) == null:
					errors.append("%s: stage[%d] %s '%s' inexistente" % [label, idx, sk, snid])
			for arr_k in ["waypoints", "bonus_nodes"]:
				var s_arr: Variant = st_dict.get(arr_k, [])
				if s_arr is Array:
					for it in (s_arr as Array):
						if sg.get_node_by_id(StringName(str(it))) == null:
							errors.append("%s: stage[%d] %s '%s' inexistente" % [label, idx, arr_k, str(it)])

	return errors


static func _validate_attack_solvability(graph: NetworkGraphResource, data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var stages_var: Variant = data.get("stages", [])
	if stages_var is Array and not (stages_var as Array).is_empty():
		return _validate_multistage_solvability(stages_var as Array, data)

	var runtime: NetworkRuntime = NetworkRuntime.new(graph)
	var locked: Array = data.get("locked_edges", []) if data.get("locked_edges") is Array else []
	for ek_var in locked:
		var ep: PackedStringArray = str(ek_var).split("→")
		if ep.size() == 2:
			runtime.set_transit_cost(StringName(ep[0]), StringName(ep[1]), INF)

	var start_n: StringName = StringName(str(data.get("start_node", "")))
	var target_n: StringName = StringName(str(data.get("target_node", "")))
	var wps: Array = data.get("waypoints", []) if data.get("waypoints") is Array else []
	var chain: Array[StringName] = [start_n]
	for wp in wps:
		chain.append(StringName(str(wp)))
	chain.append(target_n)

	var total_hops: int = 0
	var total_cost: float = 0.0
	var min_cut_overall: int = 999
	var optimal_edges: Array[Array] = []

	for i in range(chain.size() - 1):
		var a: StringName = chain[i]
		var b: StringName = chain[i + 1]
		var seg: Dictionary = DefensivePathfinder.find_path_with_cost(graph, a, b, runtime)
		if not bool(seg.get("reachable", false)):
			errors.append("tramo inalcanzable %s→%s" % [a, b])
			continue
		var p: Array = seg.get("path", [])
		total_hops += maxi(0, p.size() - 1)
		total_cost += float(seg.get("cost", 0.0))
		for k in range(p.size() - 1):
			optimal_edges.append([p[k], p[k + 1]])
		var mc: int = _min_cut_aristas(graph, a, b)
		min_cut_overall = mini(min_cut_overall, mc)

	if min_cut_overall == 999:
		min_cut_overall = 0

	var div_min: int = int(data.get("diversidad_minima", 0))
	if div_min > 0 and min_cut_overall < div_min:
		errors.append("min-cut=%d < diversidad_minima=%d" % [min_cut_overall, div_min])

	var max_turns: int = int(data.get("max_turns", 0))
	if max_turns > 0 and total_hops > max_turns:
		errors.append("saltos minimos (%d) > max_turns (%d)" % [total_hops, max_turns])

	var max_mp: int = int(data.get("max_movement_points", 0))
	if max_mp > 0 and total_cost > float(max_mp):
		errors.append("coste minimo (%.1f) > max_movement_points (%d)" % [total_cost, max_mp])

	if data.has("par_turnos") and data.has("par_coste"):
		var par_t: int = int(data.get("par_turnos", 0))
		var par_c: float = float(data.get("par_coste", 0.0))
		if total_hops > par_t:
			errors.append("par_turnos (%d) inalcanzable (min_hops=%d)" % [par_t, total_hops])
		if max_turns > 0 and par_t > max_turns:
			errors.append("par_turnos (%d) > max_turns (%d)" % [par_t, max_turns])
		if total_cost > par_c + 1e-4:
			errors.append("par_coste (%.1f) inalcanzable (min_cost=%.1f)" % [par_c, total_cost])
		if max_mp > 0 and par_c > float(max_mp) + 1e-4:
			errors.append("par_coste (%.1f) > max_movement_points (%d)" % [par_c, max_mp])

	var bonus_var: Variant = data.get("bonus_nodes", [])
	if bonus_var is Array:
		for bn_var in (bonus_var as Array):
			var bn: StringName = StringName(str(bn_var))
			var to_bn: Dictionary = DefensivePathfinder.find_path_with_cost(graph, start_n, bn, runtime)
			var from_bn: Dictionary = DefensivePathfinder.find_path_with_cost(graph, bn, target_n, runtime)
			if not bool(to_bn.get("reachable", false)) or not bool(from_bn.get("reachable", false)):
				errors.append("bonus_node '%s' no permite ruta completa start→bonus→target" % bn)
			else:
				var b_hops: int = maxi(0, (to_bn["path"] as Array).size() - 1) + maxi(0, (from_bn["path"] as Array).size() - 1)
				var b_cost: float = float(to_bn["cost"]) + float(from_bn["cost"])
				if max_turns > 0 and b_hops > max_turns:
					errors.append("bonus_node '%s' excede max_turns (%d > %d)" % [bn, b_hops, max_turns])
				if max_mp > 0 and b_cost > float(max_mp):
					errors.append("bonus_node '%s' excede presupuesto (%.1f > %d)" % [bn, b_cost, max_mp])

	var alt_routes: int = _count_alternative_routes(graph, chain, optimal_edges, max_turns, max_mp, locked)

	return {
		"errors": errors,
		"min_hops": total_hops,
		"min_cost": total_cost,
		"min_cut": min_cut_overall,
		"alt_routes": alt_routes,
	}


static func _validate_multistage_solvability(stages: Array, data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var total_hops: int = 0
	var total_cost: float = 0.0
	var min_cut_overall: int = 999
	var max_turns: int = int(data.get("max_turns", 0))
	var max_mp: int = int(data.get("max_movement_points", 0))

	for idx in range(stages.size()):
		var st_dict: Dictionary = stages[idx]
		var sg: NetworkGraphResource = _resolve_graph(st_dict)
		if sg == null:
			errors.append("stage[%d]: grafo invalido" % idx)
			continue
		var s_start: StringName = StringName(str(st_dict.get("start_node", "")))
		var s_target: StringName = StringName(str(st_dict.get("target_node", "")))
		var chain: Array[StringName] = [s_start]
		for wp in (st_dict.get("waypoints", []) as Array):
			chain.append(StringName(str(wp)))
		chain.append(s_target)

		for i in range(chain.size() - 1):
			var seg: Dictionary = DefensivePathfinder.find_path_with_cost(sg, chain[i], chain[i + 1], null)
			if not bool(seg.get("reachable", false)):
				errors.append("stage[%d] tramo inalcanzable %s→%s" % [idx, chain[i], chain[i + 1]])
			else:
				total_hops += maxi(0, (seg["path"] as Array).size() - 1)
				total_cost += float(seg["cost"])
			min_cut_overall = mini(min_cut_overall, _min_cut_aristas(sg, chain[i], chain[i + 1]))

		for bn_var in (st_dict.get("bonus_nodes", []) as Array):
			var bn: StringName = StringName(str(bn_var))
			var r1: Dictionary = DefensivePathfinder.find_path_with_cost(sg, s_start, bn, null)
			var r2: Dictionary = DefensivePathfinder.find_path_with_cost(sg, bn, s_target, null)
			if not bool(r1.get("reachable", false)) or not bool(r2.get("reachable", false)):
				errors.append("stage[%d] bonus_node '%s' inalcanzable" % [idx, bn])

	if max_turns > 0 and total_hops > max_turns:
		errors.append("multistage saltos minimos (%d) > max_turns (%d)" % [total_hops, max_turns])
	if max_mp > 0 and total_cost > float(max_mp):
		errors.append("multistage coste minimo (%.1f) > max_movement_points (%d)" % [total_cost, max_mp])

	return {
		"errors": errors,
		"min_hops": total_hops,
		"min_cost": total_cost,
		"min_cut": 0 if min_cut_overall == 999 else min_cut_overall,
		"alt_routes": 2 if min_cut_overall >= 2 else 1,
	}


static func _validate_defender_solvability(graph: NetworkGraphResource, data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var blocks_per_turn: int = int(data.get("defender_blocks_per_turn", 0))
	var block_duration: int = int(data.get("defender_block_duration", 0))
	if blocks_per_turn <= 0:
		errors.append("defender_blocks_per_turn <= 0 (%d)" % blocks_per_turn)
	if block_duration <= 0:
		errors.append("defender_block_duration <= 0 (%d)" % block_duration)

	var pairs: Array[Array] = []
	var daemons: Variant = data.get("multi_daemons", [])
	if daemons is Array and not (daemons as Array).is_empty():
		for d_var in (daemons as Array):
			var dd: Dictionary = d_var
			pairs.append([StringName(str(dd.get("start", ""))), StringName(str(dd.get("target", "")))])
	else:
		pairs.append([
			StringName(str(data.get("enemy_start_node", ""))),
			StringName(str(data.get("enemy_target_node", "")))
		])

	var total_cut_edges: int = 0
	var min_attacker_hops: int = 999
	var total_flow: float = 0.0
	for pair in pairs:
		var src: StringName = pair[0]
		var snk: StringName = pair[1]
		var mc: Dictionary = StrategicAnalyzer.find_min_cut(graph, src, snk)
		var flow: float = float(mc.get("max_flow", 0.0))
		var cut_edges: Array = mc.get("cut_edges", [])
		var apath: Dictionary = DefensivePathfinder.find_path_with_cost(graph, src, snk, null)
		if flow <= 0.0 or cut_edges.is_empty():
			errors.append("Edmonds-Karp sin corte valido para %s→%s (max_flow=%.1f)" % [src, snk, flow])
		if not bool(apath.get("reachable", false)):
			errors.append("atacante %s→%s desconectado en grafo base" % [src, snk])
		else:
			var hops: int = maxi(1, (apath["path"] as Array).size() - 1)
			min_attacker_hops = mini(min_attacker_hops, hops)
		total_cut_edges += cut_edges.size()
		total_flow += flow

	if min_attacker_hops == 999:
		min_attacker_hops = 1

	var max_simultaneous: int = blocks_per_turn * block_duration
	if total_cut_edges > max_simultaneous:
		errors.append("corte minimo requiere %d aristas > capacidad sostenida %d (%d/turno x %d)" % [
			total_cut_edges, max_simultaneous, blocks_per_turn, block_duration
		])
	var containment_window: int = maxi(1, min_attacker_hops) * blocks_per_turn
	if total_cut_edges > containment_window:
		errors.append("corte minimo (%d) excede ventana de contencion (%d saltos x %d bloques/turno = %d)" % [
			total_cut_edges, min_attacker_hops, blocks_per_turn, containment_window
		])

	return {
		"errors": errors,
		"min_hops": min_attacker_hops,
		"min_cost": total_flow,
		"min_cut": total_cut_edges,
		"cut_count": total_cut_edges,
		"max_flow": total_flow,
		"alt_routes": pairs.size(),
	}


static func _count_alternative_routes(
	graph: NetworkGraphResource,
	chain: Array[StringName],
	optimal_edges: Array[Array],
	max_turns: int,
	max_mp: int,
	locked: Array
) -> int:
	if optimal_edges.is_empty():
		return 0
	var seen_sigs: Dictionary = {}
	var base_rt := NetworkRuntime.new(graph)
	for ek_var in locked:
		var ep: PackedStringArray = str(ek_var).split("→")
		if ep.size() == 2:
			base_rt.set_transit_cost(StringName(ep[0]), StringName(ep[1]), INF)

	for edge_pair in optimal_edges:
		var u: StringName = edge_pair[0]
		var v: StringName = edge_pair[1]
		var orig: float = base_rt.get_transit_cost(u, v)
		base_rt.set_transit_cost(u, v, maxf(1.0, orig) * 1000.0)
		var hops: int = 0
		var cost: float = 0.0
		var ok: bool = true
		var sig_parts: PackedStringArray = []
		for i in range(chain.size() - 1):
			var seg: Dictionary = DefensivePathfinder.find_path_with_cost(graph, chain[i], chain[i + 1], base_rt)
			if not bool(seg.get("reachable", false)):
				ok = false
				break
			var p: Array = seg.get("path", [])
			hops += maxi(0, p.size() - 1)
			cost += float(seg.get("cost", 0.0))
			for node_id in p:
				sig_parts.append(str(node_id))
		base_rt.set_transit_cost(u, v, orig)
		if ok and (max_turns <= 0 or hops <= max_turns) and (max_mp <= 0 or cost <= float(max_mp)):
			seen_sigs["|".join(sig_parts)] = true
	return seen_sigs.size()


static func _min_cut_aristas(
	graph: NetworkGraphResource,
	origen: StringName,
	destino: StringName
) -> int:
	if graph == null or origen == destino:
		return 0
	var ids: Array = []
	for n in graph.nodes:
		ids.append(n.id)
	var specs: Array = []
	for e in graph.edges:
		specs.append({"from": e.from_id, "to": e.to_id})
	var unitario: NetworkGraphResource = GraphBuilder.build(ids, specs)
	return int(StrategicAnalyzer.find_min_cut(unitario, origen, destino).get("max_flow", 0))


static func _edge_exists(graph: NetworkGraphResource, from_id: StringName, to_id: StringName) -> bool:
	for e in graph.edges:
		if e != null and e.from_id == from_id and e.to_id == to_id:
			return true
	return false


static func _load_raw_json(path: String) -> Dictionary:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed as Dictionary if (parsed is Dictionary) else {}


# ─── Difficulty Curve & Negative Unit Tests ────────────────────────────

func _verify_difficulty_curves(ipt_by_id: Dictionary) -> void:
	var h1: float = float(ipt_by_id.get("heist_n1", {}).get("ipt_score", 0.0))
	var h2: float = float(ipt_by_id.get("heist_n2", {}).get("ipt_score", 0.0))
	var h4: float = float(ipt_by_id.get("heist_n4", {}).get("ipt_score", 0.0))
	var h5: float = float(ipt_by_id.get("heist_n5", {}).get("ipt_score", 0.0))
	_afirmar(h5 > h1 and ((h4 + h5) * 0.5) > ((h1 + h2) * 0.5),
		"curva IPT ascendente en heist (n1=%.1f, n5=%.1f)" % [h1, h5])

	var k1: float = float(ipt_by_id.get("hacker_n1", {}).get("ipt_score", 0.0))
	var k2: float = float(ipt_by_id.get("hacker_n2", {}).get("ipt_score", 0.0))
	var k4: float = float(ipt_by_id.get("hacker_n4", {}).get("ipt_score", 0.0))
	var k5: float = float(ipt_by_id.get("hacker_n5", {}).get("ipt_score", 0.0))
	_afirmar(k5 > k1 and ((k4 + k5) * 0.5) > ((k1 + k2) * 0.5),
		"curva IPT ascendente en hacker (n1=%.1f, n5=%.1f)" % [k1, k5])

	var c1: float = float(ipt_by_id.get("defense_n1", {}).get("ipt_score", 0.0))
	var c2: float = float(ipt_by_id.get("cyber_n1", {}).get("ipt_score", 0.0))
	var c3: float = float(ipt_by_id.get("cyber_n3", {}).get("ipt_score", 0.0))
	var c4: float = float(ipt_by_id.get("cyber_n4", {}).get("ipt_score", 0.0))
	_afirmar(c4 > c1 and ((c3 + c4) * 0.5) > ((c1 + c2) * 0.5),
		"curva IPT ascendente en cybersecurity (d1=%.1f, c4=%.1f)" % [c1, c4])


func _run_negative_unit_tests() -> void:
	# 1. Regresion estilo secret_root.json ('eventos' sin normalizar + node_positions roto)
	var raw_secret: Dictionary = _load_raw_json("res://juego/secret/secret_root.json")
	var broken_secret: Dictionary = raw_secret.duplicate(true)
	broken_secret["eventos"] = broken_secret.get("eventos_alarma", [])
	broken_secret.erase("eventos_alarma")
	var np_broken: Dictionary = (broken_secret.get("node_positions", {}) as Dictionary).duplicate(true)
	np_broken["NodoFantasma"] = [100, 100]
	broken_secret["node_positions"] = np_broken
	var res1: Dictionary = validate_level_dict(broken_secret, broken_secret, "neg_secret_root", true)
	_afirmar(not bool(res1.get("ok", true)),
		"unit negativo 1: detecta regresion secret_root ('eventos' legacy + node_positions invalido)")

	# 2. Colision de grilla v2
	var raw_free: Dictionary = _load_raw_json("res://juego/free_ops/free_ops_01.level.json")
	var broken_grid: Dictionary = raw_free.duplicate(true)
	(broken_grid["graph"]["nodes"][1] as Dictionary)["grid"] = [0, 1]
	var norm_grid: Dictionary = LoaderV2.normalize_dict(broken_grid)
	var res2: Dictionary = validate_level_dict(norm_grid, broken_grid, "neg_grid_collision", false)
	_afirmar(not bool(res2.get("ok", true)),
		"unit negativo 2: detecta colision de grilla y distancia < 24px en v2")

	# 3. Nivel insoluble por Dijkstra (presupuesto imposible)
	var broken_budget: Dictionary = Registry.load_level_data("res://juego/heist/heist_n1.json")
	broken_budget["max_movement_points"] = 2
	var res3: Dictionary = validate_level_dict(broken_budget, {}, "neg_dijkstra_budget", false)
	_afirmar(not bool(res3.get("ok", true)),
		"unit negativo 3: detecta nivel insoluble por presupuesto Dijkstra")

	# 4. Par 3 estrellas imposible
	var broken_par: Dictionary = Registry.load_level_data("res://juego/heist/heist_n1.json")
	broken_par["par_coste"] = 1.0
	var res4: Dictionary = validate_level_dict(broken_par, {}, "neg_impossible_par", false)
	_afirmar(not bool(res4.get("ok", true)),
		"unit negativo 4: detecta par_coste matematicamente inalcanzable")

	# 5. Nivel Cyber insoluble por Edmonds-Karp
	var broken_cyber: Dictionary = Registry.load_level_data("res://juego/cyber/cyber_n1.json")
	broken_cyber["defender_blocks_per_turn"] = 0
	var res5: Dictionary = validate_level_dict(broken_cyber, {}, "neg_cyber_edmonds_karp", false)
	_afirmar(not bool(res5.get("ok", true)),
		"unit negativo 5: detecta nivel Cyber incontenible (Edmonds-Karp)")


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1
