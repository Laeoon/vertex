class_name MultiStageDirector extends RefCounted

## Director de misiones multi-grafo sin pantalla de victoria intermedia (Sector 0.1 y 0.2).
## Reutiliza `GameState.load_graph()` manteniendo `juego_ataque.gd` y `game_logic.gd` acotados.

var stages: Array = []
var stage_index: int = 0


func setup(p_stages: Array) -> void:
	stages = p_stages.duplicate(true)
	stage_index = 0


func has_next_stage() -> bool:
	return stages.size() > 1 and stage_index + 1 < stages.size()


func get_current_stage() -> Dictionary:
	if stage_index >= 0 and stage_index < stages.size():
		return stages[stage_index] as Dictionary
	return {}


func advance_stage(game: Node) -> Dictionary:
	if not has_next_stage() or game == null:
		return {}
	stage_index += 1
	var st: Dictionary = stages[stage_index] as Dictionary

	var prev_turn: int = game.turn
	var prev_cost: float = game.player_total_cost
	var prev_mp: int = game.movement_points
	var prev_bonus_visitados: Array = game.bonus_visitados.duplicate()
	var prev_noise: int = int(game.hacker_state.get("noise", 0)) if (game.hacker_mode and game.hacker_state is Dictionary) else 0

	game.graph_path = str(st.get("graph_path", game.graph_path))
	game.start_node = StringName(str(st.get("start_node", "")))
	game.target_node = StringName(str(st.get("target_node", "")))
	game.waypoints = st.get("waypoints", []).duplicate()
	game.bonus_nodes = st.get("bonus_nodes", []).duplicate()

	if game._game_state != null:
		game._game_state.load_graph()

	game.turn = prev_turn
	game.player_total_cost = prev_cost
	if game.max_movement_points > 0:
		game.movement_points = mini(game.max_movement_points, prev_mp + 4)
	for b_node in prev_bonus_visitados:
		if not (b_node in game.bonus_visitados):
			game.bonus_visitados.append(b_node)
	if game.hacker_mode and game.hacker_state is Dictionary:
		game.hacker_state["noise"] = int(prev_noise * 0.5)

	var msg: String = str(st.get("message", "ETAPA %d/%d INICIADA" % [stage_index + 1, stages.size()]))
	game.mensaje_estado = msg
	return st
