class_name GameLogic
extends RefCounted

## Lógica central del turno — etapa 3 de la descomposición de juego_ataque.gd.
##
## Aporta movimiento del jugador (turno completo), victoria/derrota, cálculo
## de vecinos y selección/ciclado de vecino. El estado permanece en
## juego_ataque.gd (patrón setup(game); ver header de pursuit_system.gd).
##
## Equivalencia congelada por
## tests/ataque/_test_game_logic_equivalence.{gd,tscn}.

const DefensivePathfinderClass = preload("res://core/agents/defensive_pathfinder.gd")
const HackerMechanicsClass = preload("res://juego/system/hacker_mechanics.gd")

var _game: Node


func setup(game: Node) -> void:
	_game = game


## Puerto del viejo juego_ataque._mover_jugador().
func mover_jugador(destino: StringName) -> void:
	var edge_key: String = "%s→%s" % [_game.player_pos, destino]
	if _game._is_blocked(edge_key):
		# Si el destino tiene persist activa, ignorar bloqueo
		if _game.hacker_mode and _game.hacker_state.get("active_persists", {}).has(str(destino)):
			GameLogger.debug("JuegoAtaque", "Persist activo en %s — ignorando bloqueo" % str(destino))
		else:
			return

	_game.mensaje_estado = ""
	GameLogger.debug("JuegoAtaque", "[Turno %d] Jugador: %s → %s" % [_game.turn + 1, _game.player_pos, destino])

	var edge_cost: float = 0.0
	for e in _game.graph.edges:
		if e != null and e.from_id == _game.player_pos and e.to_id == destino:
			edge_cost = e.transit_cost
			break
	_game.player_total_cost += edge_cost

	if _game.hacker_mode and not _game.game_over:
		HackerMechanicsClass.add_noise(_game.hacker_state, HackerMechanicsClass.NOISE_MOVE_BASE)

	if _game.max_movement_points > 0:
		_game.movement_points -= int(edge_cost)
		if _game.movement_points <= 0 and destino != _game._target_actual():
			perder("¡Sin presupuesto de movimiento!")
			return

	_game.player_pos = destino
	AudioManager.play_sfx("move")

	_game._pursuit_system.check_detection(_game.player_pos)

	if _game.tutorial_player != null and _game.tutorial_player.is_active:
		_game.tutorial_player.notify_moved()

	_game.turn += 1

	var target_check: StringName = _game._target_actual()
	if _game.player_pos == target_check:
		if _game.current_waypoint_idx >= 0 and _game.current_waypoint_idx < _game.waypoints.size():
			_game.current_waypoint_idx += 1
			var next: StringName = _game._target_actual()
			if _game.player_pos == next:
				ganar()
				return
			GameLogger.info("JuegoAtaque", "Waypoint %s alcanzado! Siguiente: %s" % [target_check, next])
			_game.mensaje_estado = "Waypoint alcanzado! Ve hacia %s" % next
			_game.mostrar_ruta()
			_game.queue_redraw()
			return
		else:
			ganar()
			return

	if _game.max_turns > 0 and _game.turn >= _game.max_turns:
		perder("Te detectaron! (%d turnos maximo)" % _game.max_turns)
		return

	_game._limpiar_bloqueos_expirados()

	if _game.ai_enabled:
		_game._ai_blocker.take_turn()

	# Refrescar SIEMPRE la ruta tras el turno (slice 5): si la IA cortó la
	# ruta al waypoint, take_turn() retorna temprano sin actualizar
	# current_path — la ruta dibujada quedaba stale y guiaba al jugador (y al
	# bot) hacia sumideros. mostrar_ruta() limpia la ruta si quedó inalcanzable.
	_game.mostrar_ruta()

	if _game.hacker_mode and not _game.game_over:
		# Si hay persists activos, el ruido no decae (mantienes acceso audible)
		if _game.hacker_state.get("active_persists", {}).is_empty():
			HackerMechanicsClass.decay_noise(_game.hacker_state)
		else:
			GameLogger.debug("JuegoAtaque", "Persist activo — decay de ruido suspendido")

	# Revisar consecuencias de ruido/persists cada turno
	if _game.hacker_mode:
		_game._check_hacker_consequences()

	if not _game.game_over:
		target_check = _game._target_actual()
		var desde_aqui: Dictionary = DefensivePathfinderClass.find_path_with_cost(_game.graph, _game.player_pos, target_check, _game.runtime)
		if not desde_aqui["reachable"]:
			_game.mensaje_estado = "¡Sin ruta hacia %s desde %s!" % [target_check, _game.player_pos]

		var vecinos: Array = vecinos_jugador()
		if vecinos.is_empty() and _game.player_pos != _game._target_actual() and not _game.game_over:
			# Fix sumidero (slice 5): llegar al target FINAL con waypoints
			# pendientes moría con "¡Sin salida!" (el target no tiene aristas
			# salientes) — el mensaje de diseño es el de _ganar(): avisar el
			# waypoint pendiente en lugar de un "sin salida" confuso.
			if _game.waypoints.size() > 0 and _game.current_waypoint_idx >= 0 \
					and _game.current_waypoint_idx < _game.waypoints.size() \
					and _game.player_pos == _game.target_node:
				perder("Debes pasar por %s primero" % str(_game.waypoints[_game.current_waypoint_idx]))
				return
			perder("¡Sin salida! No hay caminos accesibles desde %s" % str(_game.player_pos))
			return

	_game._turn_locked_until = Time.get_ticks_msec() + 200


## Puerto del viejo juego_ataque._ganar().
func ganar() -> void:
	# Si hay waypoints definidos y no se han visitado todos, perder
	if _game.waypoints.size() > 0 and _game.current_waypoint_idx < _game.waypoints.size():
		perder("Debes pasar por %s primero" % str(_game.waypoints[_game.current_waypoint_idx]))
		return

	# Si hay tutorial activo, completarlo antes de marcar victoria
	var is_tutorial_level: bool = _game.tutorial_player != null and is_instance_valid(_game.tutorial_player) and _game.tutorial_player.is_active
	if is_tutorial_level:
		_game.tutorial_player.complete_tutorial()
		GameLogger.info("JuegoAtaque", "Tutorial completado al alcanzar el objetivo")

	_game.game_over = true
	_game._game_over_time = Time.get_ticks_msec() / 1000.0
	_game.game_won = true
	AudioManager.play_sfx("win")
	var target: StringName = _game._target_actual()
	var stars: int = _game._progress_service.calculate_stars()
	_game._progress_service.save(stars)
	var star_str: String = ""
	for i in range(3):
		star_str += "★" if i < stars else "☆"

	if is_tutorial_level:
		_game.mensaje_estado = "TUTORIAL COMPLETADO! Llegaste a %s en %d turnos  %s\nPresiona [Q] para volver al menú" % [target, _game.turn, star_str]
	else:
		_game.mensaje_estado = "GANASTE! Llegaste a %s en %d turnos  %s" % [target, _game.turn, star_str]
	GameLogger.info("JuegoAtaque", "VICTORIA en turno %d | estrellas: %d | coste: %.1f" % [_game.turn, stars, _game.player_total_cost])
	_game.queue_redraw()


## Puerto del viejo juego_ataque._perder().
func perder(razon: String) -> void:
	_game.game_over = true
	_game._game_over_time = Time.get_ticks_msec() / 1000.0
	_game.game_won = false
	AudioManager.play_sfx("lose")
	_game.mensaje_estado = "PERDISTE: %s" % razon
	GameLogger.info("JuegoAtaque", "DERROTA: %s" % razon)
	# Track pérdida en estadísticas (migrado a ProgressService)
	_game._progress_service.record_loss()
	_game.queue_redraw()


## Puerto del viejo juego_ataque._vecinos_jugador().
func vecinos_jugador() -> Array:
	var neighbors: Array = _game.runtime.get_neighbors(_game.player_pos)
	var result: Array[StringName] = []
	for n in neighbors:
		var nid: StringName = n["to_id"]
		var edge_key: String = "%s→%s" % [_game.player_pos, nid]
		if _game._is_blocked(edge_key):
			continue
		result.append(nid)
	return result


## Puerto del viejo juego_ataque._auto_select_vecino().
func auto_select_vecino() -> void:
	var vecinos: Array = vecinos_jugador()
	if vecinos.size() > 0:
		if _game.selected_neighbor in vecinos:
			return
		_game.selected_neighbor = vecinos[0]
	else:
		_game.selected_neighbor = &""


## Puerto del viejo juego_ataque._cycle_neighbor().
func cycle_neighbor(dir: int) -> void:
	var vecinos: Array = vecinos_jugador()
	if vecinos.size() == 0:
		_game.selected_neighbor = &""
		return
	if _game.selected_neighbor == &"" or not (_game.selected_neighbor in vecinos):
		_game.selected_neighbor = vecinos[0] if dir > 0 else vecinos[-1]
		_game.queue_redraw()
		return
	var idx: int = vecinos.find(_game.selected_neighbor)
	idx = (idx + dir) % vecinos.size()
	_game.selected_neighbor = vecinos[idx]
	_game.queue_redraw()


## Puerto del viejo juego_ataque._reveal_optimal_route() (P5): toggle [P] de
## la pista de ruta más corta.
func reveal_optimal_route() -> void:
	_game.show_optimal_overlay = not _game.show_optimal_overlay
	if _game.show_optimal_overlay:
		var target: StringName = _game._target_actual()
		var result: Dictionary = DefensivePathfinderClass.find_path_with_cost(_game.graph, _game.player_pos, target, null)
		_game.optimal_overlay_path = result["path"]
		if result["reachable"]:
			_game.mensaje_estado = "Pista: ruta más corta a %s" % str(target)
		else:
			_game.mensaje_estado = "No hay ruta disponible"
	else:
		_game.optimal_overlay_path.clear()
		_game.mensaje_estado = ""
	_game.queue_redraw()


## Puerto del body de juego_ataque._on_brain_defender_won() (P5).
func defender_won(stars: int) -> void:
	_game.game_over = true
	_game._game_over_time = Time.get_ticks_msec() / 1000.0
	_game.game_won = true
	AudioManager.play_sfx("win")
	_game._progress_service.save(stars)
	_game.queue_redraw()


## Puerto del body de juego_ataque._on_brain_defender_lost() (P5).
func defender_lost() -> void:
	_game.game_over = true
	_game._game_over_time = Time.get_ticks_msec() / 1000.0
	_game.game_won = false
	AudioManager.play_sfx("lose")
	_game.queue_redraw()


## Puerto del body de juego_ataque._on_defender_block_edge() (P5): SFX y
## notificación al tutorial SÓLO si el bloqueo se aplicó de verdad (el brain
## puede rechazarlo: ya bloqueado, sin recursos, sin arista).
func defender_block_edge(edge_key: String) -> void:
	AudioManager.play_sfx("block")
	if _game._defender_brain == null:
		return
	var antes: int = _game._defender_brain.defender_blocks_total_used
	_game._defender_brain.block_edge(edge_key)
	if _game._defender_brain.defender_blocks_total_used > antes:
		_game._notify_tutorial_input()


## Puerto del body de juego_ataque._on_defender_place_firewall() (P5):
## notifica al tutorial sólo si el firewall se colocó realmente.
func defender_place_firewall(node_id: StringName) -> void:
	if _game._defender_brain == null:
		return
	var antes: int = _game._defender_brain.defender_blocks_total_used
	_game._defender_brain.place_firewall(node_id)
	if _game._defender_brain.defender_blocks_total_used > antes:
		_game._notify_tutorial_input()
