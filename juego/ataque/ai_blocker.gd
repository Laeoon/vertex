class_name AIBlocker extends RefCounted
## Encapsula la lógica del turno de la IA bloqueadora (modo ataque).
##
## Extraído de `juego_ataque.gd` (fase-0/slice-3, tareas 3.1–3.4) siguiendo el
## patrón `DefenderBrain`: RefCounted con referencia `_game` al juego y métodos
## que delegan bloqueo/estado al juego (que sigue siendo el dueño de
## `blocked_edges`, `runtime`, `_ai_blocks_used`, etc., compartidos con el modo
## defensor). El modo defensor NO usa AIBlocker: ahí el atacante se mueve vía
## `DefenderBrain.move_enemy()`, por lo que `take_turn()` retorna temprano bajo
## `defender_mode`.
##
## Contrato conductual (equivalencia con la lógica original inline):
##   - `take_turn()` reproduce exactamente el cuerpo del viejo `_turno_ia()`.
##   - `would_isolate(edge_key)` reproduce el viejo `_no_aisla_al_jugador()`
##     pero con semántica honesta: devuelve `true` SI bloquear `edge_key`
##     aislaría al jugador de su objetivo. El código original usaba el negado
##     (`_no_aisla_al_jugador` → `true` = NO aísla); al renombrar, los call
##     sites se actualizan a `if not would_isolate(edge):` para preservar la
##     conducta observable (`blocked_edges`, `turn`, `mensaje_estado`).
##   - `initial_block()` reproduce el bucle de bloqueo inicial de `reset_state`
##     (viejo lines 272–289) como método propio, para que el juego deje de
##     contener esa lógica inline.

const DefensivePathfinder = preload("res://core/agents/defensive_pathfinder.gd")

var _game: Node  # referencia a juego_ataque.gd


func setup(game: Node) -> void:
	"""Configura el blocker con la referencia al juego."""
	_game = game


# ─── API pública ────────────────────────────────────────────────────

func initial_block() -> void:
	"""Bloqueo inicial de la IA al inicio de la partida (portado de reset_state)."""
	if _game == null:
		return
	# Mismas guardas que el original (lines 273 del viejo juego_ataque.gd).
	if not _game.ai_enabled or not _game.ai_bloquea_al_inicio:
		return
	if _game._ai_blocks_used >= _game.max_ai_blocks:
		return
	if _game.game_over:
		return
	_game._ai_blocks_used += 1
	var target: StringName = _game._target_actual()
	var result: Dictionary = DefensivePathfinder.find_path_with_cost(_game.graph, _game.player_pos, target, _game.runtime)
	if result["reachable"] and not result["path"].is_empty() and result["path"].size() >= 2:
		var path: Array[StringName] = result["path"]
		var idx_bloqueo: int = path.size() - 2
		while idx_bloqueo >= 0:
			var from_n: StringName = path[idx_bloqueo]
			var to_n: StringName = path[idx_bloqueo + 1]
			var edge_key: String = "%s→%s" % [from_n, to_n]
			# Original: `if not _is_blocked(edge_key) and _no_aisla_al_jugador(edge_key):`
			# con `_no_aisla_al_jugador` → true == NO aísla. Renombrado a
			# `would_isolate` (true == SÍ aísla) → call site usa `not` para
			# preservar la condición "bloquear solo si NO aísla".
			if not _game._is_blocked(edge_key) and not would_isolate(edge_key):
				_game._block_edge(edge_key, from_n, to_n)
				print("  IA bloqueo inicial: %s → %s" % [from_n, to_n])
				break
			idx_bloqueo -= 1
	_game.mensaje_estado = "IA bloqueo una ruta al inicio"


func take_turn() -> void:
	"""Ejecuta el turno de la IA (portado de `_turno_ia`)."""
	if _game == null:
		return
	if _game.defender_mode:
		return  # En defender mode, el atacante se maneja en _enemy_move().
	_game._pursuit_system.process_pursuers(_game.player_pos)  # fase-0/slice-4
	if _game.game_over:
		return

	if _game._ai_blocks_used >= _game.max_ai_blocks:
		_game.mensaje_estado = "IA sin recursos para bloquear"
		return
	_game._ai_blocks_used += 1

	var target: StringName = _game._target_actual()
	var result: Dictionary = DefensivePathfinder.find_path_with_cost(_game.graph, _game.player_pos, target, _game.runtime)
	if not result["reachable"] or result["path"].is_empty():
		_game.mensaje_estado = "No hay ruta hacia %s — busca otro camino" % target
		return

	var path: Array[StringName] = result["path"]
	print("  IA detecta ruta: ", path)

	if path.size() < 2:
		_game.mensaje_estado = "Estas al lado de %s, pero la arista esta bloqueada" % target
		return

	var bloqueos: int = 0
	# Iterar desde el final de la ruta (bloquear rio abajo primero)
	var idx: int = path.size() - 2
	while idx >= 0 and bloqueos < _game.ai_block_per_turn:
		var from_n: StringName = path[idx]
		var to_n: StringName = path[idx + 1]
		var edge_key: String = "%s→%s" % [from_n, to_n]
		if not _game._is_blocked(edge_key):
			# Original: `if _no_aisla_al_jugador(edge_key): _block_edge(...)`
			# Renombrado a `would_isolate` (true == SÍ aísla): se bloquea solo
			# cuando NO aisla → `if not would_isolate(edge_key):`.
			if not would_isolate(edge_key):
				_game._block_edge(edge_key, from_n, to_n)
				print("  IA bloquea: %s → %s" % [from_n, to_n])
				bloqueos += 1
			else:
				print("  IA evita aislar: saltando %s" % edge_key)
		idx -= 1

	if bloqueos > 0:
		_game.mensaje_estado = "IA bloqueo %d arista(s)" % bloqueos
	else:
		_game.mensaje_estado = "IA no pudo bloquear mas aristas"

	_game.mostrar_ruta()

	var result2: Dictionary = DefensivePathfinder.find_path_with_cost(_game.graph, _game.player_pos, target, _game.runtime)
	if not result2["reachable"] or result2["path"].is_empty():
		_game._perder("IA bloqueo todas las rutas!")
		return

	print("  Nueva ruta: ", result2["path"], " (coste %.1f)" % result2["cost"])
	_game.mensaje_estado += " — Tu turno"
	_game.queue_redraw()


func would_isolate(edge_key: String) -> bool:
	"""Devuelve `true` SI bloquear `edge_key` aislaría al jugador de su objetivo.

	Semántica HONESTA (true == aisla). Portado del viejo `_no_aisla_al_jugador`,
cuyo `return result["reachable"] and not result["path"].is_empty()` era true
	cuando el target SEGUIA alcanzable (== NO aísla). Aquí invertimos el booleano
	para que el nombre refleje la conducta; los call sites usan `not` para
	preservar el efecto original."""
	if _game == null:
		return true
	var parts: PackedStringArray = edge_key.split("→")
	if parts.size() != 2:
		return true
	var from_n: StringName = parts[0] as StringName
	var to_n: StringName = parts[1] as StringName
	var target: StringName = _game._target_actual()

	# Guardar coste original
	var orig: float = -1.0
	for e in _game.graph.edges:
		if e != null and e.from_id == from_n and e.to_id == to_n:
			orig = e.transit_cost
			break
	if orig < 0:
		return true

	# Simular bloqueo y verificar que el target sigue alcanzable
	_game.runtime.set_transit_cost(from_n, to_n, INF)
	var result: Dictionary = DefensivePathfinder.find_path_with_cost(_game.graph, _game.player_pos, target, _game.runtime)
	_game.runtime.set_transit_cost(from_n, to_n, orig)

	# Original retornaba `reachable and not empty` (true == NO aisla).
	# Aquí invertimos: true == aisla.
	return not (result["reachable"] and not result["path"].is_empty())