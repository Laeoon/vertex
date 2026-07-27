class_name PursuitSystem extends RefCounted
## Encapsula el subsistema de detección y persecución del modo ataque.
##
## Extraído de `juego_ataque.gd` (fase-0/slice-4, tareas 4.1–4.4) siguiendo el
## patrón `AIBlocker`/`DefenderBrain`: RefCounted con referencia `_game` al
## juego. El estado mutable compartido (`alerted_nodes`, `pursuers`,
## `_pursuer_next_id`, `pursuer_delay`, `pursuer_speed`, `pursuer_max`) PERMANECE
## en `juego_ataque.gd` porque otros módulos ya lo leen directamente de ahí
## (`GameRenderer.draw_hud`/`draw_nodes`/`draw_pursuers`, el spawn de ruido del
## hacker, las pruebas scene-based `test_detection`/`test_pursuit`). La
## extracción aporta la LÓGICA de detección/persecución, sin poseer estado
## persistente propio — idéntico al criterio aplicado en slice-3 para
## `AIBlocker`.
##
## Contrato conductual (equivalencia con la lógica original inline):
##   - `check_detection(player_pos)` reproduce EXACTAMENTE el cuerpo del viejo
##     `_chequear_deteccion()` (mismas llamadas a `randf()`, en el mismo orden
##     y la misma cantidad) — crítico para que los replays con `seed(N)`
##     produzcan los mismos `alerted_nodes`/`pursuers` antes y después de la
##     migración. El `print` de alerta llama a `randf()` una SEGUNDA vez para
##     mostrar el "roll"; este consumo de RNG se preserva verbatim.
##   - `process_pursuers(player_pos)` reproduce el viejo `_process_pursuers()`
##     llamando a `_game._perder(...)` al capturar, y devuelve `true` cuando la
##     captura ocurrió (extensión mínima sobre el `void` original, útil para
##     tests sin tener que inspeccionar `game_over`).
##   - `find_spawn_node(detected, node_res)` porta el viejo `_find_spawn_node`.
##   - `spawn_pursuer(spawn_node, delay, speed)` es un helper interno que
##     deduplica el bloque de construcción+append+incremento del perseguidor,
##     ahora invocado tanto por `check_detection` (con `pursuer_delay`/
##     `pursuer_speed` del juego) como por el spawn de ruido crítico del hacker
##     (con `delay=1, speed=2`). No estaba en el interfaz del design pero
##     elimina la duplicación y pertenece al scope "pursuer state management"
##     del task 4.1.
##   - `reset()` reagrupa el `alerted_nodes.clear()/pursuers.clear()/
##     _pursuer_next_id=1` que vivía al final del viejo `reset_state()`.
##
## Equivalencia cubierta por `tests/ataque/_test_pursuit_system_equivalence.
## {gd,tscn}` (replay determinista con `seed(42)` contra un golden capturado
## con la lógica inline ORIGINAL antes de la migración del task 4.3).

const DefensivePathfinder = preload("res://core/agents/defensive_pathfinder.gd")

var _game: Node  # referencia a juego_ataque.gd


func setup(game: Node) -> void:
	"""Configura el sistema de persecución con la referencia al juego."""
	_game = game


# ─── API pública ────────────────────────────────────────────────────

func reset() -> void:
	"""Reinicia el estado de detección/persecución de la partida.

	Portado del bloque final del viejo `reset_state()` (viejo lines 239-241):
	limpia alertas y perseguidores y resetea el contador de IDs."""
	if _game == null:
		return
	_game.alerted_nodes.clear()
	_game.pursuers.clear()
	_game._pursuer_next_id = 1


func check_detection(player_pos: StringName) -> void:
	"""Ejecuta la tirada de detección en `player_pos` (portado de
	`_chequear_deteccion`).

	CONSERVA verbatim el orden/cantidad de llamadas a `randf()` del original
	para que los replays con `seed(N)` sean reproducibles antes y después de la
	migración."""
	if _game == null:
		return
	var node_res = _game._find_node_resource(player_pos)
	if node_res == null:
		return
	var detect_chance: float = float(node_res.metadata.get("detection_chance", 0.0))
	if detect_chance <= 0.0:
		return
	if randf() > detect_chance:
		return
	# Alertado!
	if _game.alerted_nodes.has(player_pos):
		return
	_game.alerted_nodes.append(player_pos)
	if _game.pursuers.size() < _game.pursuer_max:
		var spawn_node: StringName = find_spawn_node(player_pos, node_res)
		spawn_pursuer(spawn_node, _game.pursuer_delay, _game.pursuer_speed)
		# El print original llama `randf()` de nuevo para mostrar el roll —
		# se conserva verbatim para no alterar el flujo del RNG.
		GameLogger.debug("PursuitSystem", "¡ALERTA! %s (roll %.3f <= %.3f) → perseguidor %d en %s" % [
			player_pos, randf(), detect_chance, _game._pursuer_next_id - 1, spawn_node])
	_game.mensaje_estado = "¡Alerta en %s! Seguridad en camino..." % str(player_pos)
	_game.queue_redraw()


func process_pursuers(player_pos: StringName) -> bool:
	"""Avanza un turno de los perseguidores activos (portado de
	`_process_pursuers`). Devuelve `true` si un perseguidor capturó al jugador
	(vía `_game._perder(...)`)."""
	if _game == null:
		return false
	for p in _game.pursuers:
		if p["delay"] > 0:
			p["delay"] -= 1
			if p["delay"] == 0:
				p["active"] = true
				GameLogger.debug("PursuitSystem", "Perseguidor %d activado en %s" % [p["id"], p["pos"]])
			continue
		if not p["active"]:
			continue
		var result: Dictionary = DefensivePathfinder.find_path_with_cost(_game.graph, p["pos"], player_pos, _game.runtime)
		if not result["reachable"] or result["path"].is_empty():
			continue
		var path: Array = result["path"]
		var steps: int = mini(p["speed"], path.size() - 1)
		p["pos"] = path[steps]
		GameLogger.debug("PursuitSystem", "Perseguidor %d → %s" % [p["id"], p["pos"]])
		if p["pos"] == player_pos:
			_game._perder("Capturado por seguridad (perseguidor %d)" % p["id"])
			return true
	return false


func find_spawn_node(detected: StringName, node_res) -> StringName:
	"""Elige el nodo donde aparece un nuevo perseguidor (portado de
	`_find_spawn_node`).

	Si el nodo detectado tiene firewall, el perseguidor aparece ahí (no hay
	zona de seguridad mejor). Si no, busca el primer nodo marcado
	`security_spawn` en el grafo. Si tampoco existe, cae al `detected`."""
	if _game == null:
		return detected
	if node_res != null and node_res.metadata.get("has_firewall", false):
		return detected
	for n in _game.graph.nodes:
		if n != null and n.metadata.get("security_spawn", false):
			return n.id
	return detected


func spawn_pursuer(spawn_node: StringName, delay: int, speed: int) -> void:
	"""Construye, agrega y contabiliza un perseguidor.

	Deduplica el bloque de append+incremento que el original repetía en
	`_chequear_deteccion` (delay/speed = `pursuer_delay`/`pursuer_speed`) y en
	la consecuencia de ruido crítico del hacker (delay=1, speed=2). No modifica
	`_pursuer_next_id` si el juego está saturado (el caller decide con
	`pursuers.size() < pursuer_max` antes de llamar)."""
	if _game == null:
		return
	_game.pursuers.append({
		"id": _game._pursuer_next_id,
		"pos": spawn_node,
		"delay": delay,
		"speed": speed,
		"active": false
	})
	_game._pursuer_next_id += 1