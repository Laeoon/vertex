class_name InputHandler extends Node
## Procesa todo el input del juego y emite señales.
## Reemplaza el _input() inline en juego_ataque.gd.
##
## Señales emitidas:
##   move_requested, scan_requested, exploit_used, reset_requested,
##   return_to_menu, next_level, level_select, quit, toggle_optimal_route,
##   cycle_neighbor, defender_resolve_turn, defender_toggle_firewall,
##   defender_block_edge, defender_place_firewall,
##   defender_hover_edge, tutorial_skipped, node_targeted

signal move_requested(destino: StringName)
signal node_targeted(clicked: StringName, first_step: StringName)
signal scan_requested()
signal exploit_used(exploit_type: String)
signal reset_requested()
signal return_to_menu_requested()
signal next_level_requested()
signal level_select_requested()
signal quit_requested()
signal toggle_optimal_route()
signal cycle_neighbor(dir: int)

signal defender_resolve_turn()
signal defender_toggle_firewall()
signal defender_block_edge(edge_key: String)
signal defender_place_firewall(node_id: StringName)
signal defender_hover_edge(edge_key: String)

signal tutorial_skipped()

var game: Node:
	set(value):
		game = value
var tutorial_player = null

var game_over: bool = false
var game_won: bool = false
var defender_mode: bool = false
var hacker_mode: bool = false
var firewall_mode: bool = false
var _turn_locked_until: float = 0.0
var selected_neighbor: StringName = &""
var hovered_edge: String = ""
var player_pos: StringName = &""


func sync_state() -> void:
	"""Sincroniza estado desde el juego antes de procesar input."""
	if game == null:
		return
	game_over = game.game_over if "game_over" in game else false
	game_won = game.game_won if "game_won" in game else false
	defender_mode = game.defender_mode if "defender_mode" in game else false
	hacker_mode = game.hacker_mode if "hacker_mode" in game else false
	firewall_mode = game.firewall_mode if "firewall_mode" in game else false
	_turn_locked_until = game._turn_locked_until if "_turn_locked_until" in game else 0.0
	selected_neighbor = game.selected_neighbor if "selected_neighbor" in game else &""
	player_pos = game.player_pos if "player_pos" in game else &""
	tutorial_player = game.tutorial_player if "tutorial_player" in game else null


func _input(event: InputEvent) -> void:
	sync_state()

	# ─── Tutorial ──────────────────────────────────────────────
	if tutorial_player != null and is_instance_valid(tutorial_player) and tutorial_player.is_active:
		if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
			var k: InputEventKey = event as InputEventKey
			if k.keycode == KEY_ESCAPE:
				tutorial_skipped.emit()
				return
		if tutorial_player.is_game_paused():
			return

	# ─── Teclado general ──────────────────────────────────────
	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k: InputEventKey = event as InputEventKey
		match k.keycode:
			KEY_Q:
				return_to_menu_requested.emit()
				return
			KEY_ESCAPE:
				quit_requested.emit()
				return
			KEY_R:
				reset_requested.emit()
				return
			KEY_N:
				# Slice 6: siguiente nivel — sólo con la partida ganada (evita
				# saltarse niveles por accidente o tras una derrota).
				if game_over and game_won:
					next_level_requested.emit()
				return
			KEY_L:
				# Slice 6: selector de niveles — sólo al terminar la partida.
				if game_over:
					level_select_requested.emit()
				return
			KEY_P:
				toggle_optimal_route.emit()
				return
			KEY_UP, KEY_W:
				cycle_neighbor.emit(-1)
				return
			KEY_DOWN, KEY_S:
				cycle_neighbor.emit(1)
				return
			KEY_TAB:
				cycle_neighbor.emit(1)
				return
			KEY_ENTER, KEY_SPACE:
				# Slice 3.8 v2: si el tutorial exige OTRA acción (ej. escanear),
				# bloquear el movimiento accidental (Tab+Enter por camino incorrecto).
				if _tutorial_blocks("move"):
					_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
					return
				if not game_over and selected_neighbor != &"" and Time.get_ticks_msec() >= _turn_locked_until:
					move_requested.emit(selected_neighbor)
					return
			KEY_X:
				if hacker_mode and not game_over:
					if _tutorial_blocks("input"):
						_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
						return
					scan_requested.emit()
					return
			KEY_1:
				if hacker_mode and not game_over:
					if _tutorial_blocks("input"):
						_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
						return
					exploit_used.emit("bypass")
					return
			KEY_2:
				if hacker_mode and not game_over:
					if _tutorial_blocks("input"):
						_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
						return
					exploit_used.emit("escalate")
					return
			KEY_3:
				if hacker_mode and not game_over:
					if _tutorial_blocks("input"):
						_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
						return
					exploit_used.emit("persist")
					return

	# ─── Modo defensor: mouse motion ──────────────────────────
	if defender_mode and event is InputEventMouseMotion:
		var edge: String = _find_edge_at_pos(event.position)
		defender_hover_edge.emit(edge)
		return

	# ─── Modo defensor: teclas ────────────────────────────────
	if defender_mode and event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k: InputEventKey = event as InputEventKey
		if k.keycode in [KEY_ENTER, KEY_SPACE] and not game_over and Time.get_ticks_msec() >= _turn_locked_until:
			defender_resolve_turn.emit()
			return
		if k.keycode == KEY_F and not game_over:
			defender_toggle_firewall.emit()
			return

	# ─── Click izquierdo ──────────────────────────────────────
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game_over or Time.get_ticks_msec() < _turn_locked_until:
			return
		var click_pos: Vector2 = event.position

		# Defender mode: clics
		if defender_mode:
			if firewall_mode and not game_over:
				var node_id: StringName = _find_node_at_pos_firewall(click_pos)
				if node_id != &"":
					# Slice 3.8 v2: bloquear acciones que no son la requerida
					if _tutorial_blocks("input"):
						_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
						return
					defender_place_firewall.emit(node_id)
				else:
					_mensaje_temp("Haz clic en un NODO para colocar firewall, o presiona [F] para cambiar al modo bloqueo de aristas")
			else:
				var edge_key: String = _find_edge_at_pos(click_pos)
				if edge_key != "":
					if _tutorial_blocks("input"):
						_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
						return
					defender_block_edge.emit(edge_key)
			return

		# Modo atacante: clic en nodo
		var clicked_node: StringName = _find_node_at_pos(click_pos)
		if clicked_node == &"" or clicked_node == player_pos:
			return
		if _es_vecino_valido(clicked_node):
			# Slice 3.8 v2: clic = movimiento → respetar la acción requerida
			if _tutorial_blocks("move"):
				_mensaje_temp("⚠ Tutorial: completa la acción indicada en el recordatorio primero")
				return
			move_requested.emit(clicked_node)
		else:
			# Ruta indirecta: encontrar primer paso
			var path_to: Array[StringName] = _pathfind_to(player_pos, clicked_node)
			if path_to.size() >= 2:
				var first_step: StringName = path_to[1] as StringName
				var ekey: String = "%s→%s" % [player_pos, first_step]
				if not _is_edge_blocked(ekey):
					node_targeted.emit(clicked_node, first_step)


# ─── Helpers de input que consultan al juego ─────────────────────

func _find_edge_at_pos(pos: Vector2) -> String:
	"""Delega a _edge_en_posicion del juego."""
	if game == null or not game.has_method("_edge_en_posicion"):
		return ""
	return game._edge_en_posicion(pos)


func _find_node_at_pos(pos: Vector2) -> StringName:
	"""Delega a _nodo_en_posicion del juego."""
	if game == null or not game.has_method("_nodo_en_posicion"):
		return &""
	return game._nodo_en_posicion(pos)


func _find_node_at_pos_firewall(pos: Vector2) -> StringName:
	"""Delega a _nodo_en_posicion_firewall del juego."""
	if game == null or not game.has_method("_nodo_en_posicion_firewall"):
		return &""
	return game._nodo_en_posicion_firewall(pos)


func _es_vecino_valido(nid: StringName) -> bool:
	"""Delega a _vecinos_jugador del juego."""
	if game == null or not game.has_method("_vecinos_jugador"):
		return false
	var vecinos: Array = game._vecinos_jugador()
	return nid in vecinos


func _is_edge_blocked(ekey: String) -> bool:
	"""Delega a _is_blocked del juego."""
	if game == null or not game.has_method("_is_blocked"):
		return false
	return game._is_blocked(ekey)


const DefensivePathfinder = preload("res://core/agents/defensive_pathfinder.gd")

func _pathfind_to(from_id: StringName, to_id: StringName) -> Array[StringName]:
	"""Pathfinding usando DefensivePathfinder con el grafo/runtime del juego.

	Antes este método pasaba `null` como grafo a `find_path`, lo que hacía que
	siempre devolviera [] (los clics en nodos no-vecinos nunca generaban una
	ruta al primer paso). Ahora valida `game.graph` y `game.runtime` y usa
	`find_path_with_cost` para respetar bloqueos/firewalls activos.
	Devuelve [] y registra un error si las referencias no son válidas.
	(fase-0/slice-1, tarea 1.1)"""
	# Guard contra grafo/runtime nulo o freed: sin ellos no hay pathfinding
	# seguro. La evaluación cortocircuita (||) para no tocar .graph si game
	# ya es inválido.
	if game == null or not is_instance_valid(game) \
			or not is_instance_valid(game.graph) or not is_instance_valid(game.runtime):
		push_error("InputHandler._pathfind_to: game/graph/runtime inválido — no se puede calcular la ruta")
		return []
	var resultado: Dictionary = DefensivePathfinder.find_path_with_cost(
		game.graph, from_id, to_id, game.runtime)
	if not resultado.get("reachable", false):
		return []
	return resultado["path"]


func _mensaje_temp(texto: String) -> void:
	"""Establece mensaje de estado temporal."""
	if game == null:
		return
	game.set("mensaje_estado", texto)
	if game.has_method("queue_redraw"):
		game.queue_redraw()


func _tutorial_blocks(action_type: String) -> bool:
	"""Slice 3.8 v2 — True si el tutorial está activo esperando una acción
	diferente a `action_type`, en cuyo caso esta se bloquea (evita que el
	jugador haga movimientos/acciones accidentales por el camino incorrecto).
	Fuera del tutorial o en pasos informativos devuelve false (no bloquea)."""
	if tutorial_player == null or not is_instance_valid(tutorial_player) or not tutorial_player.is_active:
		return false
	return not tutorial_player.can_perform_action(action_type)
