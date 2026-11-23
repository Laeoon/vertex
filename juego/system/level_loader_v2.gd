class_name LevelLoaderV2
extends RefCounted

## Data-driven loader and compiler for VERTEX level definitions (v1 legacy & v2 *.level.json).
## Resolves archetype inheritance ("extends"), projects normalized grid coordinates,
## maps symbolic NodeType names, and builds typed LevelLaunchContext / NetworkGraphResource.

const NetworkGraphResourceClass = preload("res://core/network/network_graph_resource.gd")
const NetworkNodeResourceClass = preload("res://core/network/network_node_resource.gd")
const NetworkEdgeResourceClass = preload("res://core/network/network_edge_resource.gd")
const LevelLaunchContextClass = preload("res://juego/system/level_launch_context.gd")

const NODE_TYPE_MAP: Dictionary = {
	"INTERNET": NetworkNodeResourceClass.NodeType.INTERNET,
	"FIREWALL": NetworkNodeResourceClass.NodeType.FIREWALL,
	"ROUTER": NetworkNodeResourceClass.NodeType.ROUTER,
	"SERVER": NetworkNodeResourceClass.NodeType.SERVER,
	"WORKSTATION": NetworkNodeResourceClass.NodeType.WORKSTATION,
	"DATABASE": NetworkNodeResourceClass.NodeType.DATABASE,
}


static func load_and_normalize(json_path: String, visited: Array[String] = []) -> Dictionary:
	if json_path.is_empty() or visited.has(json_path):
		return {}
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("LevelLoaderV2: cannot open %s" % json_path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("LevelLoaderV2: invalid JSON in %s" % json_path)
		return {}

	var raw: Dictionary = (parsed as Dictionary).duplicate(true)
	var next_visited: Array[String] = visited.duplicate()
	next_visited.append(json_path)

	var merged: Dictionary = raw
	if raw.has("extends"):
		var base_path: String = str(raw.get("extends", ""))
		var base_dict: Dictionary = _load_raw_with_extends(base_path, next_visited)
		merged = _deep_merge(base_dict, raw)

	return normalize_dict(merged)


static func _load_raw_with_extends(json_path: String, visited: Array[String]) -> Dictionary:
	if json_path.is_empty() or visited.has(json_path):
		return {}
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {}
	var raw: Dictionary = (parsed as Dictionary).duplicate(true)
	var next_visited: Array[String] = visited.duplicate()
	next_visited.append(json_path)
	if raw.has("extends"):
		var base_dict: Dictionary = _load_raw_with_extends(str(raw.get("extends", "")), next_visited)
		return _deep_merge(base_dict, raw)
	return raw


static func _deep_merge(base: Dictionary, override: Dictionary) -> Dictionary:
	var result: Dictionary = base.duplicate(true)
	for key in override.keys():
		var val: Variant = override[key]
		if result.has(key) and result[key] is Dictionary and val is Dictionary:
			result[key] = _deep_merge(result[key] as Dictionary, val as Dictionary)
		else:
			result[key] = val.duplicate(true) if (val is Dictionary or val is Array) else val
	return result


static func normalize_dict(raw_data: Dictionary) -> Dictionary:
	var out: Dictionary = raw_data.duplicate(true)
	var schema_ver: int = int(out.get("schema_version", 1))
	var is_v2: bool = schema_ver >= 2 or out.has("graph") or out.has("rules")
	if not is_v2:
		return out

	out["schema_version"] = maxi(2, schema_ver)

	var meta: Dictionary = out.get("meta", {}) if out.get("meta") is Dictionary else {}
	var rules: Dictionary = out.get("rules", {}) if out.get("rules") is Dictionary else {}
	var graph_dict: Dictionary = out.get("graph", {}) if out.get("graph") is Dictionary else {}

	if not meta.is_empty():
		_copy_if_present(meta, out, "title", "titulo_nivel")
		_copy_if_present(meta, out, "titulo_nivel", "titulo_nivel")
		_copy_if_present(meta, out, "operator", "operator")
		_copy_if_present(meta, out, "is_golden_boss", "is_golden_boss")
		_copy_if_present(meta, out, "cinematic_intro", "cinematic_intro")
		_copy_if_present(meta, out, "cinematic_outro", "cinematic_outro")
		_copy_if_present(meta, out, "unlocks", "unlocks")
		_copy_if_present(meta, out, "mensaje_tutorial", "mensaje_tutorial")

	if not rules.is_empty():
		var mode_str: String = str(rules.get("mode", "")).to_lower()
		if mode_str == "hacker":
			out["hacker_mode"] = true
			out["defender_mode"] = false
		elif mode_str == "defender" or mode_str == "cyber" or mode_str == "cybersecurity":
			out["defender_mode"] = true
			out["hacker_mode"] = false
		elif mode_str == "heist":
			out["hacker_mode"] = false
			out["defender_mode"] = false

		for rk: String in [
			"ai_enabled", "ai_block_per_turn", "ai_bloquea_al_inicio", "max_ai_blocks",
			"max_turns", "max_movement_points", "hacker_mode", "starting_exploits",
			"defender_mode", "defender_blocks_per_turn", "defender_block_duration",
			"defender_max_blocks", "enemy_start_node", "enemy_target_node", "firewall_cost",
			"block_duration", "pursuer_delay", "max_pursuers", "pursuer_speed",
			"eventos_alarma", "ia_predictiva", "stages", "multi_daemons"
		]:
			if rules.has(rk):
				out[rk] = rules[rk]

	if not graph_dict.is_empty():
		for gk: String in [
			"start_node", "target_node", "waypoints", "bonus_nodes",
			"hidden_nodes", "locked_edges", "node_triggers", "node_positions"
		]:
			if graph_dict.has(gk):
				out[gk] = graph_dict[gk]
		out["inline_graph"] = build_graph_from_v2(out)

	return out


static func _copy_if_present(src: Dictionary, dst: Dictionary, src_key: String, dst_key: String) -> void:
	if src.has(src_key) and not dst.has(dst_key):
		dst[dst_key] = src[src_key]


static func resolve_node_type(raw_type: Variant) -> NetworkNodeResourceClass.NodeType:
	if raw_type is int or raw_type is float:
		var idx: int = clampi(int(raw_type), 0, 5)
		return idx as NetworkNodeResourceClass.NodeType
	var key: String = str(raw_type).strip_edges().to_upper()
	return NODE_TYPE_MAP.get(key, NetworkNodeResourceClass.NodeType.SERVER) as NetworkNodeResourceClass.NodeType


static func project_grid_to_screen(col: float, row: float, layout: Dictionary) -> Vector2:
	var cols: float = maxf(2.0, float(layout.get("grid_cols", 8)))
	var rows: float = maxf(2.0, float(layout.get("grid_rows", 5)))
	var min_x: float = float(layout.get("min_x", 120.0))
	var max_x: float = float(layout.get("max_x", 1160.0))
	var min_y: float = float(layout.get("min_y", 110.0))
	var max_y: float = float(layout.get("max_y", 560.0))
	var tx: float = clampf(col / (cols - 1.0), 0.0, 1.0)
	var ty: float = clampf(row / (rows - 1.0), 0.0, 1.0)
	return Vector2(lerpf(min_x, max_x, tx), lerpf(min_y, max_y, ty))


static func build_graph_from_v2(data: Dictionary) -> NetworkGraphResourceClass:
	var graph_res := NetworkGraphResourceClass.new()
	var graph_dict: Dictionary = data.get("graph", {}) if data.get("graph") is Dictionary else {}
	var layout: Dictionary = data.get("layout", {}) if data.get("layout") is Dictionary else {}
	graph_res.directed = bool(graph_dict.get("directed", true))

	var nodes_arr: Array[NetworkNodeResourceClass] = []
	var raw_nodes: Variant = graph_dict.get("nodes", [])
	if raw_nodes is Array:
		for n_var in raw_nodes:
			if not (n_var is Dictionary):
				continue
			var nd: Dictionary = n_var
			var node_res := NetworkNodeResourceClass.new()
			node_res.id = StringName(str(nd.get("id", "")))
			node_res.node_type = resolve_node_type(nd.get("type", nd.get("node_type", "SERVER")))
			node_res.display_name = str(nd.get("display_name", str(node_res.id)))
			node_res.initial_state = StringName(str(nd.get("initial_state", "disponible")))

			var raw_meta: Variant = nd.get("meta", nd.get("metadata", {}))
			node_res.metadata = (raw_meta as Dictionary).duplicate(true) if (raw_meta is Dictionary) else {}

			if nd.has("grid") and nd.get("grid") is Array and (nd.get("grid") as Array).size() >= 2:
				var g: Array = nd.get("grid")
				node_res.position = project_grid_to_screen(float(g[0]), float(g[1]), layout)
			elif nd.has("pos") and nd.get("pos") is Array and (nd.get("pos") as Array).size() >= 2:
				var p: Array = nd.get("pos")
				node_res.position = Vector2(float(p[0]), float(p[1]))

			nodes_arr.append(node_res)
	graph_res.nodes = nodes_arr

	var edges_arr: Array[NetworkEdgeResourceClass] = []
	var raw_edges: Variant = graph_dict.get("edges", [])
	if raw_edges is Array:
		for e_var in raw_edges:
			if not (e_var is Dictionary):
				continue
			var ed: Dictionary = e_var
			var edge_res := NetworkEdgeResourceClass.new()
			edge_res.from_id = StringName(str(ed.get("from", ed.get("from_id", ""))))
			edge_res.to_id = StringName(str(ed.get("to", ed.get("to_id", ""))))
			edge_res.transit_cost = float(ed.get("cost", ed.get("transit_cost", 1.0)))
			edge_res.mitigation_capacity = float(ed.get("capacity", ed.get("mitigation_capacity", 1.0)))
			edge_res.protocol = StringName(str(ed.get("protocol", "TCP")))
			edges_arr.append(edge_res)
	graph_res.edges = edges_arr

	return graph_res


static func build_launch_context(raw_data: Dictionary, fallback_id: String = "") -> LevelLaunchContextClass:
	var data: Dictionary = normalize_dict(raw_data)
	var ctx := LevelLaunchContextClass.new()
	ctx.schema_version = int(data.get("schema_version", 1))
	ctx.level_key = str(data.get("id", fallback_id))
	ctx.world_id = str(data.get("world", ""))
	ctx.act = int(data.get("act", 1))
	ctx.order = int(data.get("order", 1))
	ctx.is_golden_boss = bool(data.get("is_golden_boss", false))
	ctx.cinematic_intro = str(data.get("cinematic_intro", ""))
	ctx.cinematic_outro = str(data.get("cinematic_outro", ""))
	var raw_unlocks: Variant = data.get("unlocks", {})
	ctx.unlocks = (raw_unlocks as Dictionary).duplicate(true) if (raw_unlocks is Dictionary) else {}

	ctx.graph_path = str(data.get("graph_path", ""))
	var ig: Variant = data.get("inline_graph", null)
	ctx.inline_graph = ig as NetworkGraphResourceClass if (ig is NetworkGraphResourceClass) else null

	ctx.start_node = StringName(str(data.get("start_node", "")))
	ctx.target_node = StringName(str(data.get("target_node", "")))
	ctx.waypoints = (data.get("waypoints", []) as Array).duplicate(true) if (data.get("waypoints") is Array) else []
	ctx.titulo_nivel = str(data.get("titulo_nivel", data.get("title", "")))
	ctx.mensaje_tutorial = str(data.get("mensaje_tutorial", ""))

	ctx.ai_enabled = bool(data.get("ai_enabled", true))
	ctx.ai_block_per_turn = int(data.get("ai_block_per_turn", 1))
	ctx.ai_bloquea_al_inicio = bool(data.get("ai_bloquea_al_inicio", true))
	ctx.max_ai_blocks = int(data.get("max_ai_blocks", 999))
	ctx.max_turns = int(data.get("max_turns", 0))
	ctx.max_movement_points = int(data.get("max_movement_points", 0))

	ctx.hacker_mode = bool(data.get("hacker_mode", false))
	ctx.starting_exploits = (data.get("starting_exploits", {}) as Dictionary).duplicate(true) if (data.get("starting_exploits") is Dictionary) else {}

	ctx.defender_mode = bool(data.get("defender_mode", false))
	ctx.defender_blocks_per_turn = int(data.get("defender_blocks_per_turn", 2))
	ctx.defender_block_duration = int(data.get("defender_block_duration", 4))
	ctx.defender_max_blocks = int(data.get("defender_max_blocks", 999))
	ctx.enemy_start_node = StringName(str(data.get("enemy_start_node", "")))
	ctx.enemy_target_node = StringName(str(data.get("enemy_target_node", "")))
	ctx.firewall_cost = int(data.get("firewall_cost", 2))

	ctx.block_duration = int(data.get("block_duration", 3))
	ctx.pursuer_delay = int(data.get("pursuer_delay", 2))
	ctx.max_pursuers = int(data.get("max_pursuers", 4))
	ctx.pursuer_speed = int(data.get("pursuer_speed", 1))

	var raw_eventos: Variant = data.get("eventos_alarma", data.get("eventos", []))
	ctx.eventos_alarma = (raw_eventos as Array).duplicate(true) if (raw_eventos is Array) else []
	ctx.ia_predictiva = bool(data.get("ia_predictiva", false))
	ctx.bonus_nodes = (data.get("bonus_nodes", []) as Array).duplicate(true) if (data.get("bonus_nodes") is Array) else []
	ctx.node_triggers = (data.get("node_triggers", {}) as Dictionary).duplicate(true) if (data.get("node_triggers") is Dictionary) else {}
	ctx.locked_edges = (data.get("locked_edges", []) as Array).duplicate(true) if (data.get("locked_edges") is Array) else []
	ctx.hidden_nodes = (data.get("hidden_nodes", []) as Array).duplicate(true) if (data.get("hidden_nodes") is Array) else []
	ctx.node_positions = (data.get("node_positions", {}) as Dictionary).duplicate(true) if (data.get("node_positions") is Dictionary) else {}
	ctx.stages = (data.get("stages", []) as Array).duplicate(true) if (data.get("stages") is Array) else []
	ctx.multi_daemons = (data.get("multi_daemons", []) as Array).duplicate(true) if (data.get("multi_daemons") is Array) else []

	return ctx
