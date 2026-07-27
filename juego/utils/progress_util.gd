class_name ProgressUtil extends RefCounted
## Utilidad estática para cargar/guardar progreso del jugador.
##
## Consolida la lógica duplicada de `_cargar_progreso()` que existía en:
## - `escenas/main_menu.gd`
## - `escenas/main_menu/tutorials_menu.gd`
## - `juego/system/level_select_screen.gd`
## - `escenas/menu/database.gd` (usa `cargar_progreso` internamente)
##
## Todas las funciones son estáticas — no requieren instancia.


## Carga todo el progreso guardado como `{level_key: estrellas}`.
##
## Lee `user://progress.cfg` sección `"estrellas"`. Excluye claves que
## terminan en `_mejor_coste` (metadatos internos de ProgressService).
static func cargar_progreso() -> Dictionary:
	var cfg := ConfigFile.new()
	var err: int = cfg.load("user://progress.cfg")
	if err != OK:
		return {}
	var result: Dictionary = {}
	for k in cfg.get_section_keys("estrellas"):
		if k.ends_with("_mejor_coste"):
			continue
		result[k] = cfg.get_value("estrellas", k, 0)
	return result


## Devuelve las estrellas de un nivel específico (0 si no existe).
static func get_stars(level_key: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load("user://progress.cfg") != OK:
		return 0
	return cfg.get_value("estrellas", level_key, 0)


## Carga el progreso y pobla un array de misiones con stars/completed.
##
## `missions` es un Array[Dictionary] donde cada entrada tiene clave `"id"`.
## Tras la llamada, cada entrada tendrá `"stars"` (int) y `"completed"` (bool).
## Usado por `database.gd`.
static func cargar_misiones(missions: Array[Dictionary]) -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://progress.cfg") != OK:
		return
	for i in missions.size():
		var key: String = missions[i]["id"]
		var stars: int = cfg.get_value("estrellas", key, 0)
		missions[i]["stars"] = stars
		missions[i]["completed"] = stars > 0
