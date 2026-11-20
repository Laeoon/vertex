class_name MultiDaemonController extends RefCounted

## Controlador de múltiples demonios simultáneos para Sector 0.3 (3 Daemons vs 1).
## Gestiona el avance independiente de EXFIL, FUZZ y CORDON y verifica contención total.

const DefensivePathfinderClass = preload("res://core/agents/defensive_pathfinder.gd")

var daemons: Array[Dictionary] = []


func setup(p_defs: Array) -> void:
	daemons.clear()
	for raw_d in p_defs:
		if not (raw_d is Dictionary):
			continue
		var d: Dictionary = raw_d
		daemons.append({
			"id": str(d.get("id", "DAEMON")),
			"pos": StringName(str(d.get("start", ""))),
			"target": StringName(str(d.get("target", ""))),
			"color": Color(str(d.get("color", "#FF2E88"))),
			"contained": false
		})


func is_active() -> bool:
	return daemons.size() > 0


func check_all_contained(graph: Resource, runtime: RefCounted) -> bool:
	if daemons.is_empty():
		return false
	for d: Dictionary in daemons:
		var cur: StringName = d.get("pos", &"")
		var tgt: StringName = d.get("target", &"")
		var res: Dictionary = DefensivePathfinderClass.find_path_with_cost(graph, cur, tgt, runtime)
		var reachable: bool = bool(res.get("reachable", false))
		var path: Array = res.get("path", [])
		d["contained"] = (not reachable) or path.size() < 2
		if not bool(d["contained"]):
			return false
	return true


func step_daemons(graph: Resource, runtime: RefCounted) -> Dictionary:
	var moved: Array[String] = []
	var breached_id: String = ""
	for d: Dictionary in daemons:
		var cur: StringName = d.get("pos", &"")
		var tgt: StringName = d.get("target", &"")
		var res: Dictionary = DefensivePathfinderClass.find_path_with_cost(graph, cur, tgt, runtime)
		var reachable: bool = bool(res.get("reachable", false))
		var path: Array = res.get("path", [])
		if not reachable or path.size() < 2:
			d["contained"] = true
			continue
		d["contained"] = false
		var next_node: StringName = StringName(str(path[1]))
		d["pos"] = next_node
		moved.append("%s→%s" % [str(d.get("id", "")), str(next_node)])
		if next_node == tgt:
			breached_id = str(d.get("id", "DAEMON"))
			break

	var all_contained: bool = (breached_id == "") and check_all_contained(graph, runtime)
	return {
		"breached": breached_id != "",
		"breached_id": breached_id,
		"all_contained": all_contained,
		"moved": moved
	}
