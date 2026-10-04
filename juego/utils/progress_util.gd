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


## Comprueba si un mundo está desbloqueado según el progreso de tutoriales.
## Reglas:
## - "tutorials": Siempre desbloqueado.
## - General: Requiere tutorial1 y tutorial3 (fundamentos de redes y defensa).
## - "heist": Requiere General + tutorial2 y tutorial6 (sensores y presupuesto).
## - "hacker": Requiere General + tut_hacker_1..tut_hacker_4.
## - "cybersecurity": Requiere General (modo defender en standby).
static func is_world_unlocked(world_id: String, progress: Dictionary) -> bool:
	if world_id == "tutorials":
		return true

	var general_done: bool = progress.get("tutorial1", 0) > 0 and progress.get("tutorial3", 0) > 0
	if not general_done:
		return false

	match world_id:
		"heist":
			return progress.get("tutorial2", 0) > 0 and progress.get("tutorial6", 0) > 0
		"hacker":
			return progress.get("tut_hacker_1", 0) > 0 \
				and progress.get("tut_hacker_2", 0) > 0 \
				and progress.get("tut_hacker_3", 0) > 0 \
				and progress.get("tut_hacker_4", 0) > 0
		"cybersecurity":
			return true
		_:
			return true


## Devuelve la razón de bloqueo o los requisitos faltantes para un mundo.
static func get_world_lock_reason(world_id: String, progress: Dictionary) -> String:
	if world_id == "tutorials":
		return ""

	var general_done: bool = progress.get("tutorial1", 0) > 0 and progress.get("tutorial3", 0) > 0
	if not general_done:
		return "REQ: TUTORIAL GENERAL (MODULOS 1 Y 2)"

	match world_id:
		"heist":
			if progress.get("tutorial2", 0) <= 0 or progress.get("tutorial6", 0) <= 0:
				return "REQ: TUTORIAL HEIST (MODULOS 1 Y 2)"
		"hacker":
			if progress.get("tut_hacker_1", 0) <= 0 \
				or progress.get("tut_hacker_2", 0) <= 0 \
				or progress.get("tut_hacker_3", 0) <= 0 \
				or progress.get("tut_hacker_4", 0) <= 0:
				return "REQ: TUTORIAL HACKER (MODULOS 1-4)"
		"cybersecurity":
			return ""
	return ""
