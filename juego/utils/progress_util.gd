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


const SlotManagerClass = preload("res://juego/system/slot_manager.gd")


## Resuelve dinámicamente la ruta al archivo progress.cfg según el slot activo.
static func get_progress_file_path() -> String:
	return SlotManagerClass.get_progress_path()


## Carga todo el progreso guardado como `{level_key: estrellas}`.
##
## Lee la sección `"estrellas"` del slot activo. Excluye claves que
## terminan en `_mejor_coste` (metadatos internos de ProgressService).
static func cargar_progreso() -> Dictionary:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(get_progress_file_path())
	if err != OK:
		return {"seen_cinematics": {}, "golden_nodes": {}, "konami_unlocked": false, "total_stars": 0}
	var result: Dictionary = {}
	var total_stars: int = 0
	if cfg.has_section("estrellas"):
		for k: String in cfg.get_section_keys("estrellas"):
			if k.ends_with("_mejor_coste") or k == "total_stars":
				continue
			var stars: int = maxi(0, int(cfg.get_value("estrellas", k, 0)))
			result[k] = stars
			total_stars += stars
	result["total_stars"] = total_stars
	var seen: Dictionary = {}
	if cfg.has_section("seen_cinematics"):
		for k in cfg.get_section_keys("seen_cinematics"):
			if cfg.get_value("seen_cinematics", k, false):
				seen[k] = true
	result["seen_cinematics"] = seen
	var golden: Dictionary = {}
	if cfg.has_section("golden_nodes"):
		for k in cfg.get_section_keys("golden_nodes"):
			if cfg.get_value("golden_nodes", k, false):
				golden[k] = true
	result["golden_nodes"] = golden
	result["konami_unlocked"] = bool(cfg.get_value("unlocks", "konami_sector0", false))
	return result


## Devuelve las estrellas de un nivel específico (0 si no existe).
static func get_stars(level_key: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(get_progress_file_path()) != OK:
		return 0
	return cfg.get_value("estrellas", level_key, 0)


## Guarda las estrellas de un nivel o tutorial si superan el registro previo.
static func guardar_progreso(level_key: String, stars: int) -> void:
	if level_key.is_empty() or stars <= 0:
		return
	var path := get_progress_file_path()
	var cfg := ConfigFile.new()
	cfg.load(path)
	var prev: int = cfg.get_value("estrellas", level_key, 0)
	if stars > prev:
		cfg.set_value("estrellas", level_key, stars)
		cfg.save(path)
		SlotManagerClass.invalidate_cache()


## Carga el progreso y pobla un array de misiones con stars/completed.
##
## `missions` es un Array[Dictionary] donde cada entrada tiene clave `"id"`.
## Tras la llamada, cada entrada tendrá `"stars"` (int) y `"completed"` (bool).
## Usado por `database.gd`.
static func cargar_misiones(missions: Array[Dictionary]) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(get_progress_file_path()) != OK:
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
## - "cybersecurity": Requiere General + tut_defensa_1 y tut_defensa_2.
static func is_world_unlocked(world_id: String, progress: Dictionary) -> bool:
	if world_id == "tutorials":
		return true
	if world_id == "sector0" or world_id == "secret":
		return is_sector0_unlocked(progress)

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
			return progress.get("tut_defensa_1", 0) > 0 and progress.get("tut_defensa_2", 0) > 0
		_:
			return true


## Devuelve la razón de bloqueo o los requisitos faltantes para un mundo.
static func get_world_lock_reason(world_id: String, progress: Dictionary) -> String:
	if world_id == "tutorials":
		return ""
	if world_id == "sector0" or world_id == "secret":
		if not is_sector0_unlocked(progress):
			return "REQ: 3 NODOS DORADOS (JEFES ACTO 1)"
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
			if progress.get("tut_defensa_1", 0) <= 0 or progress.get("tut_defensa_2", 0) <= 0:
				return "REQ: TUTORIAL DEFENSOR (MODULOS 1 Y 2)"
	return ""


## Comprueba si el jugador ya vio una cinemática o transmisión Codec.
static func has_seen_cinematic(cin_id: String, progress_data: Dictionary = {}) -> bool:
	if cin_id.is_empty():
		return true
	if not progress_data.is_empty():
		if progress_data.has("seen_cinematics") and progress_data["seen_cinematics"] is Dictionary:
			return bool(progress_data["seen_cinematics"].get(cin_id, false))
		if progress_data.has(cin_id):
			return bool(progress_data.get(cin_id, false))
		return false
	var cfg := ConfigFile.new()
	if cfg.load(get_progress_file_path()) == OK:
		return bool(cfg.get_value("seen_cinematics", cin_id, false))
	return false


## Marca una cinemática como vista (tanto en memoria como persistida en progress.cfg).
static func mark_cinematic_seen(cin_id: String, progress_data: Dictionary = {}) -> void:
	if cin_id.is_empty():
		return
	if not progress_data.is_empty():
		if not progress_data.has("seen_cinematics") or not (progress_data["seen_cinematics"] is Dictionary):
			progress_data["seen_cinematics"] = {}
		progress_data["seen_cinematics"][cin_id] = true
	var path := get_progress_file_path()
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("seen_cinematics", cin_id, true)
	cfg.save(path)


## Registra de forma persistente el Nodo Dorado obtenido en un nivel jefe.
static func mark_golden_node_collected(level_id: String, progress_data: Dictionary = {}) -> void:
	if level_id.is_empty():
		return
	if not progress_data.is_empty():
		if not progress_data.has("golden_nodes") or not (progress_data["golden_nodes"] is Dictionary):
			progress_data["golden_nodes"] = {}
		progress_data["golden_nodes"][level_id] = true
	var path: String = get_progress_file_path()
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("golden_nodes", level_id, true)
	cfg.save(path)


## Verifica si el Nodo Dorado de un nivel específico ya fue asegurado.
static func has_golden_node(level_id: String, progress_data: Dictionary = {}) -> bool:
	if level_id.is_empty():
		return false
	if not progress_data.is_empty() and progress_data.has("golden_nodes") and progress_data["golden_nodes"] is Dictionary:
		var g_dict: Dictionary = progress_data["golden_nodes"]
		return bool(g_dict.get(level_id, false))
	var cfg := ConfigFile.new()
	if cfg.load(get_progress_file_path()) == OK:
		return bool(cfg.get_value("golden_nodes", level_id, false))
	return false


## Desbloqueo de Sector 0: el perfil principal de pruebas (Slot 1) permanece abierto;
## los perfiles nuevos (Slot 2/3) requieren los 3 Nodos Dorados del Acto 1 o código Konami.
static func is_sector0_unlocked(progress_data: Dictionary = {}) -> bool:
	if SlotManagerClass.get_active_slot() == 1:
		return true
	if bool(progress_data.get("konami_unlocked", false)):
		return true
	return has_golden_node("heist_n5", progress_data) \
		and has_golden_node("hacker_n5", progress_data) \
		and has_golden_node("cyber_n4", progress_data)

