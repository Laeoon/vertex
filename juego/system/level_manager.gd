class_name LevelManager

## Gestor de niveles: conecta el menú con la carga de escenas.
## Lee la configuración desde JSON y setea SceneParams antes de cargar.

const _Registry = preload("res://juego/system/level_registry.gd")


static func launch_level(world_id: String, level_idx: int = 0) -> bool:
	SceneParams.reset()
	var config: Dictionary = _Registry.get_level_config(world_id, level_idx)
	if config.is_empty():
		push_error("LevelManager: nivel no encontrado: %s[%d]" % [world_id, level_idx])
		return false

	var data: Dictionary = _Registry.load_level_data(config["path"])
	if data.is_empty():
		return false

	SceneParams.level_key = data.get("id", config.get("path", "").get_file().trim_suffix(".json"))
	_apply_to_scene_params(data)
	SceneTransition.fade_to_scene("res://juego/ataque/escena_juego.tscn")
	return true


static func launch_tutorial(tutorial_json_path: String) -> bool:
	var file: FileAccess = FileAccess.open(tutorial_json_path, FileAccess.READ)
	if file == null:
		push_error("LevelManager: no se pudo abrir %s" % tutorial_json_path)
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null or not parsed is Dictionary:
		return false
	_apply_to_scene_params(parsed)
	SceneParams.tutorial_path = tutorial_json_path
	SceneTransition.fade_to_scene("res://juego/ataque/escena_juego.tscn")
	return true


## Navegación post-partida (slice 6): lanza el nivel SIGUIENTE al dado en su
## mismo mundo. Devuelve false si es el último del mundo o el id no está
## registrado (el llamador puede abrir el selector como fallback).
static func launch_next(level_id: String) -> bool:
	var ubic: Dictionary = _Registry.find_level(level_id)
	if ubic.is_empty():
		return false
	return launch_level(ubic["world"], ubic["idx"] + 1)


## Vuelve al selector de niveles del mundo dado (mismo transporte que el menú
## principal: world_id viaja por SceneParams.titulo_nivel).
static func goto_level_select(world_id: String) -> void:
	SceneParams.titulo_nivel = world_id
	SceneTransition.fade_to_scene("res://juego/system/level_select_screen.tscn")


static func _apply_to_scene_params(data: Dictionary) -> void:
	SceneParams.graph_path = data.get("graph_path", "")
	SceneParams.start_node = data.get("start_node", "")
	SceneParams.target_node = data.get("target_node", "")
	SceneParams.waypoints = data.get("waypoints", [])
	SceneParams.ai_enabled = data.get("ai_enabled", true)
	SceneParams.ai_block_per_turn = data.get("ai_block_per_turn", 1)
	SceneParams.ai_bloquea_al_inicio = data.get("ai_bloquea_al_inicio", true)
	SceneParams.max_ai_blocks = data.get("max_ai_blocks", 999)
	SceneParams.max_turns = data.get("max_turns", 0)
	SceneParams.max_movement_points = data.get("max_movement_points", 0)
	SceneParams.titulo_nivel = data.get("titulo_nivel", "")
	SceneParams.hacker_mode = data.get("hacker_mode", false)
	SceneParams.starting_exploits = data.get("starting_exploits", {})
	SceneParams.mensaje_tutorial = data.get("mensaje_tutorial", "")
	SceneParams.defender_mode = data.get("defender_mode", false)
	SceneParams.defender_blocks_per_turn = data.get("defender_blocks_per_turn", 2)
	SceneParams.defender_block_duration = data.get("defender_block_duration", 4)
	SceneParams.defender_max_blocks = data.get("defender_max_blocks", 999)
	SceneParams.enemy_start_node = data.get("enemy_start_node", "")
	SceneParams.enemy_target_node = data.get("enemy_target_node", "")
	SceneParams.firewall_cost = data.get("firewall_cost", 2)
	SceneParams.block_duration = data.get("block_duration", 3)
	SceneParams.pursuer_delay = data.get("pursuer_delay", 2)
	SceneParams.max_pursuers = data.get("max_pursuers", 4)
	SceneParams.pursuer_speed = data.get("pursuer_speed", 1)


static func get_worlds() -> Dictionary:
	return _Registry.WORLDS


static func get_world_title(world_id: String) -> String:
	var world: Dictionary = _Registry.get_world(world_id)
	return world.get("title", world_id)
