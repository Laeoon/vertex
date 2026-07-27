class_name ProgressService extends RefCounted
## Encapsula la persistencia de progreso y el cálculo de estrellas (modo ataque).
##
## Extraído de `juego_ataque.gd` (fase-0/slice-5, tareas 5.1–5.4) siguiendo el
## patrón `AIBlocker`/`PursuitSystem`: RefCounted con referencia `_game` al
## juego. Responsable de las escrituras de progreso en tiempo de ejecución
## (estrellas, stats de victoria/derrota) hacia `user://progress.cfg` y
## `user://stats.cfg`.
##
## El menú principal y la pantalla de selección de nivel tienen sus propias
## copias de `_cargar_progreso()` — esas se consolidan en Slice 6
## (`ProgressUtil`). Este módulo cubre SOLO el lado del juego (runtime writes).
##
## Contrato conductual (equivalencia con la lógica original inline):
##   - `calculate_stars()` reproduce exactamente el cuerpo del viejo
##     `_calcular_estrellas()`: ratio de movement_points si `max_movement_points
##     > 0`, sino cost_ratio vs `STAR_THRESHOLDS` y turn_ratio vs max_turns.
##   - `save(nuevas_estrellas)` reproduce el viejo `_guardar_progreso()` +
##     tracking de stats de victoria en `user://stats.cfg`.
##   - `record_loss()` reproduce el tracking de stats de derrota que vivía en
##     `_perder()`.
##   - `load_all()` es un static helper para lecturas desde el juego (usado por
##     `_draw` para mostrar estrellas en game over).

const DefensivePathfinder = preload("res://core/agents/defensive_pathfinder.gd")

var _game: Node  # referencia a juego_ataque.gd


func setup(game: Node) -> void:
	"""Configura el servicio de progreso con la referencia al juego."""
	_game = game


# ─── API pública ────────────────────────────────────────────────────

func calculate_stars() -> int:
	"""Calcula las estrellas ganadas (portado de `_calcular_estrellas`).

	Dos modos de cálculo:
	  1. Si `max_movement_points > 0`: ratio de puntos restantes.
	  2. Sino: ratio de coste real vs óptimo (STAR_THRESHOLDS) y ratio de
	     turnos vs max_turns. Devuelve el mínimo de ambas categorías."""
	if _game == null:
		return 1

	if _game.max_movement_points > 0:
		var ratio: float = float(_game.movement_points) / float(_game.max_movement_points)
		if ratio >= 0.5:
			return 3
		if ratio >= 0.25:
			return 2
		return 1

	var optimal_cost: float = 0.0
	var prev: StringName = _game.start_node
	for wp in _game.waypoints:
		var seg: Dictionary = DefensivePathfinder.find_path_with_cost(_game.graph, prev, wp, null)
		if not seg["reachable"]:
			return 1
		optimal_cost += seg["cost"]
		prev = wp
	var seg_final: Dictionary = DefensivePathfinder.find_path_with_cost(_game.graph, prev, _game.target_node, null)
	if not seg_final["reachable"]:
		return 1
	optimal_cost += seg_final["cost"]

	if optimal_cost <= 0:
		return 1

	var cost_ratio: float = _game.player_total_cost / optimal_cost
	var cost_stars: int = 3 if cost_ratio <= _game.STAR_THRESHOLDS[0] else (2 if cost_ratio <= _game.STAR_THRESHOLDS[1] else 1)

	var turn_stars: int = 3
	if _game.max_turns > 0:
		var turn_ratio: float = float(_game.turn) / float(_game.max_turns)
		turn_stars = 3 if turn_ratio <= 0.5 else (2 if turn_ratio <= 0.75 else 1)

	return mini(cost_stars, turn_stars)


func save(nuevas_estrellas: int) -> void:
	"""Guarda estrellas y stats de victoria (portado de `_guardar_progreso`).

	Actualiza `user://progress.cfg` solo si `nuevas_estrellas` supera el
	récord previo. Registra victoria en `user://stats.cfg`."""
	if _game == null:
		return
	var key: String = _level_key()

	# Progreso (estrellas)
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load("user://progress.cfg")
	if err != OK and err != ERR_FILE_NOT_FOUND:
		print("Error cargando progress: ", err)
	var prev: int = cfg.get_value("estrellas", key, 0)
	if nuevas_estrellas > prev:
		cfg.set_value("estrellas", key, nuevas_estrellas)
		cfg.set_value("estrellas", key + "_mejor_coste", _game.player_total_cost)
		cfg.save("user://progress.cfg")
		print("Progreso guardado: ", key, " → ", nuevas_estrellas, " estrellas")
		if prev > 0:
			_game.mensaje_estado += " (nuevo record!)"

	# Estadísticas extendidas
	var stats_cfg := ConfigFile.new()
	stats_cfg.load("user://stats.cfg")
	var wins: int = stats_cfg.get_value("stats", "total_wins", 0)
	stats_cfg.set_value("stats", "total_wins", wins + 1)

	# Track per-level wins
	var level_wins: int = stats_cfg.get_value("levels", key + "_wins", 0)
	stats_cfg.set_value("levels", key + "_wins", level_wins + 1)

	stats_cfg.set_value("stats", "best_streak", maxi(stats_cfg.get_value("stats", "best_streak", 0), 1))
	stats_cfg.save("user://stats.cfg")


func record_loss() -> void:
	"""Registra derrota en stats (portado del tracking en `_perder`)."""
	if _game == null:
		return
	var stats_cfg := ConfigFile.new()
	stats_cfg.load("user://stats.cfg")
	var losses: int = stats_cfg.get_value("stats", "total_losses", 0)
	stats_cfg.set_value("stats", "total_losses", losses + 1)
	var key: String = _level_key()
	var level_losses: int = stats_cfg.get_value("levels", key + "_losses", 0)
	stats_cfg.set_value("levels", key + "_losses", level_losses + 1)
	stats_cfg.set_value("stats", "total_attempts", stats_cfg.get_value("stats", "total_attempts", 0) + 1)
	stats_cfg.save("user://stats.cfg")


static func load_all() -> Dictionary:
	"""Carga todo el progreso guardado (portado de `_cargar_progreso`).

	Devuelve `{level_key: estrellas}` excluyendo las claves `_mejor_coste`."""
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load("user://progress.cfg")
	if err != OK:
		return {}
	var result: Dictionary = {}
	for k in cfg.get_section_keys("estrellas"):
		if k.ends_with("_mejor_coste"):
			continue
		result[k] = cfg.get_value("estrellas", k, 0)
	return result


# ─── Helpers internos ───────────────────────────────────────────────

func _level_key() -> String:
	"""Devuelve la clave del nivel actual (portado de `_level_key`).

	Usa `_game.level_key` (poblado desde `SceneParams.level_key` en
	`_ready` del juego) si está definido; sino deriva del nombre del
	archivo del grafo."""
	if _game.level_key != "":
		return _game.level_key
	var path: String = _game.graph_path
	return path.get_file().trim_suffix(".tres")
