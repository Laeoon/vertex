class_name LevelManager

## Gestor de niveles: conecta el menú con la carga de escenas.
## Lee la configuración desde JSON y setea SceneParams antes de cargar.

const _Registry = preload("res://juego/system/level_registry.gd")
const _ProgressUtil = preload("res://juego/utils/progress_util.gd")
const LevelLoaderV2Class = preload("res://juego/system/level_loader_v2.gd")


static func launch_level(world_id: String, level_idx: int = 0) -> bool:
	SceneParams.reset()
	var config: Dictionary = _Registry.get_level_config(world_id, level_idx)
	if config.is_empty():
		push_error("LevelManager: nivel no encontrado: %s[%d]" % [world_id, level_idx])
		return false

	var data: Dictionary = _Registry.load_level_data(config["path"])
	if data.is_empty():
		return false

	var fallback_id: String = str(config.get("path", "")).get_file().trim_suffix(".level.json").trim_suffix(".json")
	SceneParams.level_key = str(data.get("id", fallback_id))
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
	var progress: Dictionary = _ProgressUtil.cargar_progreso()
	if not _ProgressUtil.is_world_unlocked(world_id, progress):
		push_warning("LevelManager: el mundo '%s' esta bloqueado. Redirigiendo a menu principal." % world_id)
		SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
		return
	SceneParams.titulo_nivel = world_id
	SceneTransition.fade_to_scene("res://juego/system/level_select_screen.tscn")


static func _apply_to_scene_params(data: Dictionary) -> void:
	var ctx := LevelLoaderV2Class.build_launch_context(data, SceneParams.level_key)
	SceneParams.apply_launch_context(ctx)



static func get_worlds() -> Dictionary:
	return _Registry.WORLDS


static func get_world_title(world_id: String) -> String:
	var world: Dictionary = _Registry.get_world(world_id)
	return world.get("title", world_id)
