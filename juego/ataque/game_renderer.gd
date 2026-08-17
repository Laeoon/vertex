class_name GameRenderer extends RefCounted

## Capa de rendering separada de la lógica de juego.
## Recibe un CanvasItem (Node2D) como target de dibujo y todo el estado
## como parámetros. No tiene estado propio.

var _canvas: CanvasItem
var font: Font
var font_size: int
var big_font_size: int
var small_font_size: int
var tiny_font_size: int


func _init(
	p_canvas: CanvasItem,
	p_font: Font,
	p_font_size: int,
	p_big: int,
	p_small: int,
	p_tiny: int
) -> void:
	_canvas = p_canvas
	font = p_font
	font_size = p_font_size
	big_font_size = p_big
	small_font_size = p_small
	tiny_font_size = p_tiny


func draw_rect(rect: Rect2, color: Color, filled: bool = true, width: float = 1.0, antialiased: bool = false) -> void:
	_canvas.draw_rect(rect, color, filled, width, antialiased)


func draw_line(from: Vector2, to: Vector2, color: Color, width: float = 1.0, antialiased: bool = false) -> void:
	_canvas.draw_line(from, to, color, width, antialiased)


func draw_circle(pos: Vector2, radius: float, color: Color, filled: bool = true, width: float = 1.0, antialiased: bool = false) -> void:
	_canvas.draw_circle(pos, radius, color, filled, width, antialiased)


func draw_polygon(points: PackedVector2Array, color: Color) -> void:
	_canvas.draw_colored_polygon(points, color)


func draw_string(pos: Vector2, text: String, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1, font_size_override: int = -1, color: Color = Color.WHITE) -> void:
	var fs: int = font_size_override if font_size_override > 0 else font_size
	_canvas.draw_string(font, pos, text, alignment, width, fs, color)


func draw_error(vp_size: Vector2, mensaje_estado: String) -> void:
	draw_rect(Rect2(20, 80, vp_size.x - 40, 40), Color(0.15, 0.02, 0.02, 0.9))
	draw_string(Vector2(30, 106), mensaje_estado, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)


## Orquestación del frame completo (P5): juego_ataque._draw() sólo hace los
## guards (brain válido, runtime/graph cargados) y delega acá con un
## diccionario de datos puro armado por GameState.frame_data() — sin
## callables ni lectura de estado del nodo juego.
func draw_frame(d: Dictionary) -> void:
	if d.defender_mode:
		draw_defender_hud(d.vp_size, d.turn, d.brain_blocks_placed, d.brain_blocks_per_turn, d.brain_enemy_pos, d.brain_enemy_target, d.max_turns, d.brain_min_cut, d.blocked_edges, d.brain_firewalls, d.brain_firewall_mode)
	else:
		draw_hud(d.vp_size, d.titulo_nivel, d.turn, d.player_pos, d.target, d.player_total_cost, d.max_turns, d.waypoints, d.waypoint_idx, d.pursuers, d.alerted_nodes, d.movement_points, d.max_movement_points, d.budget_display)
	if d.hacker_mode:
		draw_hacker_hud(d.vp_size, d.hacker_state, d.scan_results)
	draw_edges(d.graph, d.node_positions, d.blocked_edges, d.blocked_keys, d.current_path, d.node_radius, d.game_over, d.brain_hovered_edge if d.defender_mode else "", d.brain_enemy_path if d.defender_mode else [], d.turn, d.unblock_flash_time, d.unblock_flash_edge)
	if d.defender_mode:
		draw_nodes(d.graph, d.node_positions, d.brain_enemy_pos, d.brain_enemy_target, [], d.current_path, d.node_radius, d.game_over, d.alerted_nodes, &"", d.scan_results, d.waypoints, -1, d.brain_firewalls, d.brain_enemy_pos, d.enemy_move_flash_time)
		if d.brain_enemy_path.size() >= 2:
			draw_optimal_overlay(d.brain_enemy_path, d.node_positions, d.node_radius)
	else:
		draw_nodes(d.graph, d.node_positions, d.player_pos, d.target, d.neighbors, d.current_path, d.node_radius, d.game_over, d.alerted_nodes, d.selected_neighbor, d.scan_results, d.waypoints, d.waypoint_idx, {}, &"", d.enemy_move_flash_time)
	draw_pursuers(d.pursuers, d.node_positions, d.node_radius)
	if d.show_optimal_overlay:
		draw_optimal_overlay(d.optimal_overlay_path, d.node_positions, d.node_radius)
	if d.tutorial_player != null and d.tutorial_player.is_active:
		# Flecha guía del tutorial: en modo defensor no hay jugador.
		draw_tutorial_highlights(d.tutorial_player, d.node_positions, d.node_radius, d.tutorial_arrow_pos)
	if d.game_over:
		if d.defender_mode:
			draw_defender_game_over(d.vp_size, d.game_won, d.mensaje_estado, d.stars, d.game_over_time, d.has_next_level)
		else:
			draw_game_over(d.vp_size, d.game_won, d.mensaje_estado, d.stars, d.game_over_time, d.es_tutorial, d.has_next_level)
	if d.mensaje_tutorial != "" and not d.game_over:
		draw_tutorial_text(d.mensaje_tutorial)
	if d.selected_neighbor != &"" and not d.game_over:
		draw_node_info_panel(d.vp_size, d.selected_neighbor, d.player_pos, d.graph, d.node_cache)
	draw_status_bar(d.vp_size, d.mensaje_estado, d.selected_neighbor, d.game_over, d.game_won, d.defender_mode)


func draw_background_grid(vp_size: Vector2) -> void:
	var spacing: float = 50.0
	var grid_color: Color = Color(0.12, 0.14, 0.2, 0.3)
	var x: float = 0.0
	while x < vp_size.x:
		draw_line(Vector2(x, 0), Vector2(x, vp_size.y), grid_color, 1.0)
		x += spacing
	var y: float = 0.0
	while y < vp_size.y:
		draw_line(Vector2(0, y), Vector2(vp_size.x, y), grid_color, 1.0)
		y += spacing


func draw_hud(
	vp_size: Vector2,
	titulo_nivel: String,
	turn: int,
	player_pos: StringName,
	target: StringName,
	player_total_cost: float,
	max_turns: int,
	waypoints: Array,
	current_waypoint_idx: int,
	pursuers: Array,
	alerted_nodes: Array,
	movement_points: int,
	max_movement_points: int,
	_budget_display: float = 0.0
) -> void:
	var bar_h: float = 52.0

	# ZONA 1: Barra superior con fondo
	draw_rect(Rect2(0, 0, vp_size.x, bar_h), Color(0.04, 0.04, 0.08, 0.95))
	draw_rect(Rect2(0, bar_h, vp_size.x, 2.0), Color(0.0, 1.0, 0.83, 0.5))

	# Título del nivel (izquierda)
	draw_string(Vector2(16, 22), titulo_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, Color(0.0, 1.0, 0.83))

	# Indicadores principales (centro)
	var center_x: float = vp_size.x / 2.0
	var ind_y: float = 22.0

	# Turno
	var turn_text: String = "TURNO %d" % turn
	var turn_w: float = font.get_string_size(turn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
	draw_string(Vector2(center_x - turn_w / 2.0 - 120, ind_y), "TURNO ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))
	draw_string(Vector2(center_x - turn_w / 2.0 - 120 + font.get_string_size("TURNO ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x, ind_y), "%d" % turn, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, Color.WHITE)

	# Puntos de movimiento con barra visual
	if max_movement_points > 0:
		var pts_label_x: float = center_x - 60
		var pts_color: Color = Color(0.0, 1.0, 0.5) if movement_points > max_movement_points * 0.3 else Color(1.0, 0.6, 0.0) if movement_points > max_movement_points * 0.1 else Color(1.0, 0.2, 0.2)
		draw_string(Vector2(pts_label_x, ind_y), "PUNTOS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))

		# Barra de progreso
		var bar_x: float = pts_label_x + 50
		var bar_w: float = 100.0
		var bar_y: float = ind_y - 10
		var bar_h_inner: float = 12.0
		var fill_ratio: float = _budget_display / float(max_movement_points)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h_inner), Color(0.1, 0.12, 0.18))
		draw_rect(Rect2(bar_x, bar_y, bar_w * fill_ratio, bar_h_inner), pts_color)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h_inner), Color(0.3, 0.35, 0.45), false, 1.0)

		# Texto sobre la barra
		var pts_text: String = "%d/%d" % [movement_points, max_movement_points]
		draw_string(Vector2(bar_x + bar_w + 8, ind_y), pts_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, pts_color)

	# Meta (derecha, después de puntos)
	var meta_text: String = "META: %s" % str(target)
	var meta_x: float = vp_size.x - 200.0
	draw_string(Vector2(meta_x, ind_y), meta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.3, 0.3))

	# Indicadores secundarios (debajo)
	var sec_y: float = 42.0
	var sec_x: float = 16.0

	# Posición
	var pos_text: String = "POS: %s" % str(player_pos)
	draw_string(Vector2(sec_x, sec_y), pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))
	sec_x += font.get_string_size(pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x + 20.0

	# Coste
	var cost_text: String = "COSTE: %.1f" % player_total_cost
	draw_string(Vector2(sec_x, sec_y), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))
	sec_x += font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x + 20.0

	# Turnos restantes
	if max_turns > 0:
		var rem_text: String = "RESTANTE: %d" % (max_turns - turn)
		var rem_color: Color = Color(0.0, 1.0, 0.5) if (max_turns - turn) > max_turns * 0.3 else Color(1.0, 0.6, 0.0)
		draw_string(Vector2(sec_x, sec_y), rem_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, rem_color)
		sec_x += font.get_string_size(rem_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x + 20.0

	# Waypoints
	if waypoints.size() > 0:
		var wp_text: String = "WP: %d/%d" % [current_waypoint_idx + 1, waypoints.size()]
		draw_string(Vector2(sec_x, sec_y), wp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))

	# Indicador de amenaza (derecha)
	var alert_x: float = vp_size.x - 16.0
	if pursuers.size() > 0:
		var p_text: String = "PERSEGUIDORES: %d" % pursuers.size()
		var pw: float = font.get_string_size(p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x
		alert_x -= pw + 8.0
		draw_rect(Rect2(alert_x - 6, ind_y - 14, pw + 12, 20), Color(0.8, 0.05, 0.02, 0.4))
		draw_rect(Rect2(alert_x - 6, ind_y - 14, pw + 12, 20), Color(1.0, 0.2, 0.1, 0.7), false, 1.0)
		draw_string(Vector2(alert_x, ind_y), p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(1.0, 0.3, 0.2))
	elif alerted_nodes.size() > 0:
		var a_text: String = "ALERTAS: %d" % alerted_nodes.size()
		var aw: float = font.get_string_size(a_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x
		alert_x -= aw + 8.0
		draw_string(Vector2(alert_x, ind_y), a_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(1.0, 0.7, 0.0))


func draw_hacker_hud(vp_size: Vector2, hacker_state: Dictionary, scan_results: Dictionary) -> void:
	var noise: int = hacker_state.get("noise", 0)
	var max_noise: int = hacker_state.get("max_noise", 100)
	var exploits: Dictionary = hacker_state.get("exploits", {})

	# Panel derecho — separado del tablero y el panel de info de nodo
	var panel_w: float = 160.0
	var panel_x: float = vp_size.x - panel_w - 12.0
	var panel_y: float = 200.0

	# Fondo del panel
	draw_rect(Rect2(panel_x - 8, panel_y - 12, panel_w + 16, 130), Color(0.03, 0.03, 0.07, 0.9))
	draw_rect(Rect2(panel_x - 8, panel_y - 12, panel_w + 16, 130), Color(0.0, 0.8, 0.5, 0.4), false, 1.0)

	# Título del panel
	draw_string(Vector2(panel_x, panel_y), "HACKER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, Color(0.0, 1.0, 0.5))
	draw_rect(Rect2(panel_x, panel_y + 4, 50, 1.0), Color(0.0, 1.0, 0.5, 0.4))

	# Noise meter
	var nm_y: float = panel_y + 20.0
	var nm_w: float = panel_w - 10.0
	var nm_h: float = 10.0
	var fill_ratio: float = float(noise) / float(max_noise)

	var noise_color: Color
	if noise >= 85:
		noise_color = Color(1.0, 0.1, 0.0)
	elif noise >= 60:
		noise_color = Color(1.0, 0.5, 0.0)
	elif noise >= 30:
		noise_color = Color(1.0, 0.9, 0.0)
	else:
		noise_color = Color(0.0, 1.0, 0.5)

	draw_string(Vector2(panel_x, nm_y), "RUIDO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.5, 0.55, 0.65))
	draw_rect(Rect2(panel_x, nm_y + 6, nm_w, nm_h), Color(0.1, 0.12, 0.18))
	draw_rect(Rect2(panel_x, nm_y + 6, nm_w * fill_ratio, nm_h), noise_color)
	draw_rect(Rect2(panel_x, nm_y + 6, nm_w, nm_h), Color(0.3, 0.35, 0.45), false, 1.0)
	draw_string(Vector2(panel_x + nm_w + 4, nm_y), "%d/%d" % [noise, max_noise], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, noise_color)

	# Exploit inventory
	var ei_y: float = nm_y + 28.0
	var exploit_types: Array = ["bypass", "escalate", "persist"]
	var exploit_icons: Dictionary = {"bypass": "⚡", "escalate": "🔓", "persist": "♻"}
	var exploit_names: Dictionary = {"bypass": "Infiltrar", "escalate": "Escalar", "persist": "Mantener"}

	for i in exploit_types.size():
		var et: String = exploit_types[i]
		var count: int = exploits.get(et, 0)
		var icon: String = exploit_icons.get(et, "?")
		var label: String = exploit_names.get(et, et)
		var key_hint: String = "[%d]" % (i + 1)

		var color: Color = Color(0.0, 1.0, 0.5) if count > 0 else Color(0.4, 0.4, 0.45)
		draw_string(Vector2(panel_x, ei_y), "%s %s %s x%d" % [key_hint, icon, label, count], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, color)
		ei_y += 16.0

	# Scan hint
	draw_string(Vector2(panel_x, ei_y + 4), "[X] Escanear", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.4, 0.45, 0.55, 0.6))


func draw_defender_hud(
	vp_size: Vector2,
	turn: int,
	blocks_placed: int,
	blocks_per_turn: int,
	enemy_pos: StringName,
	enemy_target: StringName,
	max_turns: int,
	min_cut_analysis: Dictionary = {},
	blocked_edges: Dictionary = {},
	node_firewalls: Dictionary = {},
	firewall_mode: bool = false
) -> void:
	var bar_h: float = 52.0
	draw_rect(Rect2(0, 0, vp_size.x, bar_h), Color(0.04, 0.04, 0.08, 0.95))
	draw_rect(Rect2(0, bar_h, vp_size.x, 2.0), Color(1.0, 0.5, 0.0, 0.6))

	draw_string(Vector2(16, 22), "🛡️ DEFENSOR — Protege la red", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, Color(1.0, 0.5, 0.0))
	draw_string(Vector2(16, 42), "TURNO %d  |  FASE: %s" % [turn, "BLOQUEO" if blocks_placed < blocks_per_turn or blocks_per_turn == 0 else "LISTO"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))

	var center_x: float = vp_size.x / 2.0
	var blocks_remaining: int = blocks_per_turn - blocks_placed
	var block_color: Color = Color(1.0, 0.5, 0.0) if blocks_remaining > 0 else Color(0.5, 0.8, 0.5)
	draw_string(Vector2(center_x - 100, 22), "BLOQUEOS: %d/%d" % [blocks_placed, blocks_per_turn], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, block_color)
	
	if blocks_remaining > 0:
		draw_string(Vector2(center_x - 100, 42), "Restan: %d" % blocks_remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.8, 0.5, 0.2))
	else:
		draw_string(Vector2(center_x - 100, 42), "[Enter] para resolver", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.0, 1.0, 0.5))

	if enemy_pos != &"":
		var enemy_color: Color = Color(1.0, 0.2, 0.2)
		if enemy_pos == enemy_target:
			enemy_color = Color(1.0, 0.0, 0.0)
		draw_string(Vector2(center_x + 40, 22), "👾 ATACANTE: %s" % str(enemy_pos), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, enemy_color)
	if enemy_target != &"":
		draw_string(Vector2(center_x + 40, 42), "🎯 OBJETIVO: %s" % str(enemy_target), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(1.0, 0.6, 0.2))
	if max_turns > 0:
		var turns_left: int = max_turns - turn
		var turn_color: Color = Color(0.5, 0.8, 1.0) if turns_left > 5 else (Color(1.0, 0.8, 0.0) if turns_left > 2 else Color(1.0, 0.2, 0.2))
		draw_string(Vector2(vp_size.x - 160, 22), "⏱ %d" % turns_left, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, turn_color)

	# Indicador de modo firewall (en la barra principal)
	if firewall_mode:
		draw_rect(Rect2(center_x - 100, 42, vp_size.x - center_x + 100 - 160 - 120, 14), Color(1.0, 0.3, 0.0, 0.2))
		draw_string(Vector2(center_x - 100, 42), "🔥 CORTARRUEGOS ACTIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(1.0, 0.4, 0.0))

	# Indicador de estado de rutas del atacante
	var has_path: bool = enemy_pos != &"" and enemy_pos != enemy_target
	if has_path and enemy_target != &"":
		var route_status_y: float = 42.0 if not firewall_mode else 56.0
		# Se muestra integrado en la info del atacante

	# ═══ ZONA 1b: Análisis de corte mínimo (TAREA 1) ═══
	var analysis_y: float = 56.0
	draw_rect(Rect2(0, analysis_y, vp_size.x, 22.0), Color(0.04, 0.04, 0.08, 0.8))
	draw_rect(Rect2(0, analysis_y + 22.0, vp_size.x, 1.0), Color(1.0, 0.85, 0.0, 0.3))

	var has_analysis: bool = not min_cut_analysis.is_empty() and min_cut_analysis.get("cut_edges", []).size() > 0
	if has_analysis:
		var cut_edges: Array = min_cut_analysis["cut_edges"]
		var max_flow: float = min_cut_analysis.get("max_flow", 0.0)

		# Texto de cabecera
		var flow_text: String = "✂ CORTE MÍNIMO — Flujo máx: %.1f" % max_flow
		draw_string(Vector2(16, analysis_y + 16), flow_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(1.0, 0.85, 0.0))

		# Aristas sugeridas (hasta 4) con icono dorado
		var x_offset: float = vp_size.x - 12.0
		var max_show: int = mini(cut_edges.size(), 4)
		for i in range(max_show):
			var edge: Dictionary = cut_edges[i]
			var edge_text: String = "■ %s→%s (%.1f)" % [edge["from_id"], edge["to_id"], edge.get("capacity", 0.0)]
			var tw: float = font.get_string_size(edge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size).x
			x_offset -= tw + 10.0
			draw_rect(Rect2(x_offset - 2, analysis_y + 4, tw + 6, 14), Color(0.85, 0.65, 0.0, 0.12))
			draw_rect(Rect2(x_offset - 2, analysis_y + 4, tw + 6, 14), Color(1.0, 0.85, 0.0, 0.3), false, 1.0)
			draw_string(Vector2(x_offset, analysis_y + 16), edge_text, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(1.0, 0.85, 0.4))
		if cut_edges.size() > 4:
			var extra_text: String = "... (+%d)" % (cut_edges.size() - 4)
			x_offset -= font.get_string_size(extra_text, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size).x + 6
			draw_string(Vector2(x_offset, analysis_y + 16), extra_text, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(0.7, 0.6, 0.3))
	else:
		draw_string(Vector2(16, analysis_y + 16), "✂ CORTE MÍNIMO: Sin sugerencias", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.5, 0.5))

	# ═══ ZONA 1c: Duración de bloqueos activos (TAREA 3) ═══
	var active_blocks: int = blocked_edges.size()
	if active_blocks > 0:
		var blocks_y: float = analysis_y + 24.0
		draw_rect(Rect2(0, blocks_y, vp_size.x, 18.0), Color(0.04, 0.04, 0.08, 0.7))

		var blocks_text: String = "🔒 Bloqueos activos: %d  |  " % active_blocks
		var bx: float = 16.0
		draw_string(Vector2(bx, blocks_y + 14), blocks_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.8, 0.8, 0.9))
		bx += font.get_string_size(blocks_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x + 4.0

		# Mostrar hasta 5 bloqueos con su duración
		var count: int = 0
		for edge_key in blocked_edges.keys():
			if count >= 5:
				break
			var block_data: Dictionary = blocked_edges[edge_key]
			var remaining: int = int(block_data.get("expires_at", 0)) - turn
			if remaining < 0:
				remaining = 0

			var dur_color: Color
			if remaining >= 4:
				dur_color = Color(0.2, 1.0, 0.5)
			elif remaining >= 2:
				dur_color = Color(1.0, 0.8, 0.0)
			else:
				dur_color = Color(1.0, 0.2, 0.2)

			var label: String = "%s:%dt" % [edge_key, remaining]
			var lw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size).x
			if bx + lw + 10 > vp_size.x:
				# Salto de línea virtual — cortamos
				break
			draw_rect(Rect2(bx - 2, blocks_y + 2, lw + 4, 14), Color(dur_color.r, dur_color.g, dur_color.b, 0.12))
			draw_string(Vector2(bx, blocks_y + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, dur_color)
			bx += lw + 12.0
			count += 1

		if blocked_edges.size() > 5:
			var more: String = "... (+%d)" % (blocked_edges.size() - 5)
			draw_string(Vector2(bx, blocks_y + 14), more, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(0.5, 0.5, 0.6))


func draw_edges(
	graph: NetworkGraphResource,
	node_positions: Dictionary,
	blocked_edges: Dictionary,
	blocked_keys: Dictionary,
	current_path: Array,
	node_radius: float,
	game_over: bool,
	hovered_edge: String = "",
	enemy_path: Array = [],
	current_turn: int = 0,
	_unblock_flash_time: float = -1.0,
	_unblock_flash_edge: String = ""
) -> void:
	for e in graph.edges:
		if e == null:
			continue
		var from_pos: Vector2 = node_positions.get(e.from_id, Vector2.ZERO) as Vector2
		var to_pos: Vector2 = node_positions.get(e.to_id, Vector2.ZERO) as Vector2
		if from_pos == Vector2.ZERO or to_pos == Vector2.ZERO:
			continue

		var edge_key: String = "%s→%s" % [e.from_id, e.to_id]
		# P5/tarea 3: datos en lugar de callables — is_blocked_func se reemplaza
		# por el snapshot blocked_keys ({edge_key: true}, mismo criterio que
		# GameState.is_blocked) e is_in_path_func se deriva de current_path.
		var is_blocked: bool = blocked_keys.has(edge_key)
		var in_path: bool = false
		if current_path.size() >= 2:
			for i in current_path.size() - 1:
				if current_path[i] == e.from_id and current_path[i + 1] == e.to_id:
					in_path = true
					break

		# TAREA 2: Verificar si la arista está en la ruta del atacante
		var in_enemy_path: bool = false
		if enemy_path.size() >= 2:
			for i in enemy_path.size() - 1:
				if enemy_path[i] == e.from_id and enemy_path[i + 1] == e.to_id:
					in_enemy_path = true
					break

		var dir: Vector2 = (to_pos - from_pos).normalized()
		var edge_color: Color
		var line_width: float

		var is_hovered: bool = hovered_edge != "" and hovered_edge == edge_key

		if is_blocked:
			edge_color = Color(1.0, 0.15, 0.15, 0.85)
			line_width = 3.0
		elif edge_key == _unblock_flash_edge and _unblock_flash_time > 0:
			var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _unblock_flash_time
			if elapsed < 0.3:
				var alpha: float = 1.0 - (elapsed / 0.3)
				edge_color = Color(0.0, 1.0, 0.3, alpha)
				line_width = 4.0
			else:
				edge_color = Color(0.35, 0.5, 0.7, 0.9)
				line_width = 1.5
		elif in_enemy_path and not game_over:
			# TAREA 2: Arista en la ruta del atacante — naranja pulsante
			var pulse: float = 0.6 + sin(Time.get_ticks_msec() * 0.006) * 0.3
			edge_color = Color(1.0, 0.5, 0.0, 0.7 + pulse * 0.3)
			line_width = 4.0
		elif is_hovered:
			edge_color = Color(1.0, 0.6, 0.0, 0.95)
			line_width = 4.0
		else:
			edge_color = Color(0.35, 0.5, 0.7, 0.9)
			line_width = 1.5

		var tip: Vector2 = to_pos - dir * node_radius
		draw_line(from_pos + dir * node_radius, tip, edge_color, line_width)

		if is_blocked:
			var mid: Vector2 = (from_pos + to_pos) / 2.0
			draw_circle(mid, 14.0, Color(0.15, 0.05, 0.05, 0.8))
			draw_circle(mid, 14.0, Color(1.0, 0.2, 0.2, 0.9), false, 2.0)
			draw_string(mid + Vector2(-5, 5), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.3, 0.3, 1.0))
			# TAREA 3: Mostrar duración restante del bloqueo
			var block_data: Dictionary = blocked_edges.get(edge_key, {})
			if block_data.has("expires_at"):
				var remaining: int = int(block_data["expires_at"]) - current_turn
				if remaining > 0:
					var dur_color: Color
					if remaining >= 4:
						dur_color = Color(0.0, 1.0, 0.5)  # verde
					elif remaining >= 2:
						dur_color = Color(1.0, 0.85, 0.0)  # amarillo
					else:
						dur_color = Color(1.0, 0.2, 0.2)  # rojo
					var dur_label: String = "%dt" % remaining
					draw_string(mid + Vector2(18, 5), dur_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, dur_color)
		else:
			var arrow_len: float = 10.0
			var arrow_w: float = 5.0
			var base: Vector2 = tip - dir * arrow_len
			var perp: Vector2 = dir.rotated(PI / 2.0)
			draw_line(tip, base + perp * arrow_w, edge_color, line_width)
			draw_line(tip, base - perp * arrow_w, edge_color, line_width)

			var mid: Vector2 = (from_pos + to_pos) / 2.0
			var label_bg: Color = Color(0.04, 0.04, 0.08, 0.92)
			var label_text: String = str(e.protocol)
			var text_w: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x
			var label_pos: Vector2 = mid + Vector2(-text_w / 2.0, -12.0)
			draw_rect(Rect2(label_pos.x - 4, label_pos.y - 12, text_w + 8, 16), label_bg)
			draw_rect(Rect2(label_pos.x - 4, label_pos.y - 12, text_w + 8, 16), Color(edge_color.r, edge_color.g, edge_color.b, 0.5), false, 1.0)
			draw_string(label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.85, 0.88, 0.95, 0.95))


func draw_nodes(
	graph: NetworkGraphResource,
	node_positions: Dictionary,
	player_pos: StringName,
	target: StringName,
	neighbors: Array,
	current_path: Array,
	node_radius: float,
	game_over: bool,
	alerted_nodes: Array,
	selected_neighbor: StringName,
	scan_results: Dictionary = {},
	waypoints: Array = [],
	current_waypoint_idx: int = 0,
	node_firewalls: Dictionary = {},
	enemy_pos: StringName = &"",
	_enemy_move_flash_time: float = -1.0
) -> void:
	for nid in node_positions.keys():
		var nid_str: StringName = nid as StringName
		var pos: Vector2 = node_positions[nid] as Vector2

		var is_player: bool = nid_str == player_pos
		var is_target: bool = nid_str == target
		var es_vecino: bool = nid_str in neighbors
		var in_path: bool = nid_str in current_path

		var node_color: Color
		if is_player:
			node_color = Color(0.0, 0.7, 1.0)
		elif is_target:
			node_color = Color(1.0, 0.15, 0.15)
		elif es_vecino and not game_over:
			node_color = Color(0.1, 0.85, 0.2)
		else:
			node_color = Color(0.2, 0.22, 0.3, 0.85)

		var radius: float = node_radius
		if is_player:
			radius += 6.0
		elif is_target or es_vecino:
			radius += 3.0

		draw_circle(pos + Vector2(2, 3), radius, Color(0, 0, 0, 0.4))
		draw_circle(pos, radius, node_color)

		var border_color: Color = Color(0.3, 0.32, 0.4)
		if is_player:
			border_color = Color(0.0, 0.9, 1.0)
		elif is_target:
			border_color = Color(1.0, 0.3, 0.3)
		elif es_vecino:
			border_color = Color(0.3, 1.0, 0.4)
		draw_circle(pos, radius, border_color, false, 2.5)

		if nid_str in alerted_nodes:
			var pulse: float = 0.5 + sin(Time.get_ticks_msec() * 0.008) * 0.3
			draw_circle(pos, radius + 6.0, Color(1.0, 0.15, 0.0, pulse * 0.5), false, 3.0)
			draw_circle(pos, radius + 10.0, Color(1.0, 0.15, 0.0, pulse * 0.25), false, 2.0)
			# Partículas de escaneo (4 puntos rotatorios)
			var scan_angle: float = Time.get_ticks_msec() * 0.003
			for i in range(4):
				var angle: float = scan_angle + (i * PI / 2.0)
				var particle_pos: Vector2 = pos + Vector2(cos(angle), sin(angle)) * (radius + 14.0)
				draw_circle(particle_pos, 2.0, Color(1.0, 0.4, 0.0, pulse * 0.7))

		# T1: Flash de movimiento del atacante
		if nid_str == enemy_pos and _enemy_move_flash_time > 0:
			var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _enemy_move_flash_time
			if elapsed < 0.3:
				var alpha: float = 1.0 - (elapsed / 0.3)
				draw_circle(pos, radius + 8.0, Color(1.0, 1.0, 1.0, alpha * 0.6), false, 3.0)

		if nid_str == selected_neighbor and not game_over:
			var sel_pulse: float = 0.6 + sin(Time.get_ticks_msec() * 0.006) * 0.3
			draw_circle(pos, radius + 7.0, Color(1.0, 0.4, 0.8, sel_pulse * 0.45), false, 3.0)

		var label_bg_color: Color = Color(0.03, 0.03, 0.07, 0.9)
		var label_text: String = str(nid_str)
		var text_w: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var label_x: float = pos.x - text_w / 2.0
		var label_y: float = pos.y - radius - 8.0
		draw_rect(Rect2(label_x - 4, label_y - 14, text_w + 8, 18), label_bg_color)
		draw_rect(Rect2(label_x - 4, label_y - 14, text_w + 8, 18), border_color, false, 1.0)
		draw_string(Vector2(label_x, label_y), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

		if is_player:
			draw_string(Vector2(pos.x - 8, pos.y + radius + 16), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(0.0, 0.9, 1.0))
		elif is_target:
			draw_string(Vector2(pos.x - 18, pos.y + radius + 16), "TARGET", HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(1.0, 0.3, 0.3))
		elif es_vecino and not game_over:
			draw_string(Vector2(pos.x - 8, pos.y + radius + 16), "→", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.3, 1.0, 0.4))

		# Scan indicator
		if scan_results.has(str(nid_str)):
			var scan_data: Dictionary = scan_results[str(nid_str)]
			var node_type: String = scan_data.get("node_type", "")
			var scan_color: Color
			match node_type:
				"vulnerable":
					scan_color = Color(0.0, 1.0, 0.5)
				"protected":
					scan_color = Color(1.0, 0.6, 0.0)
				"decoy":
					scan_color = Color(1.0, 0.2, 0.2)
				_:
					scan_color = Color(0.5, 0.55, 0.65)
			draw_circle(pos, radius + 12.0, scan_color, false, 2.0)
			draw_string(Vector2(pos.x + radius + 4, pos.y - radius + 2), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, scan_color)

		# Waypoint indicator
		if waypoints.has(nid_str):
			var wp_idx: int = waypoints.find(nid_str)
			if wp_idx >= current_waypoint_idx:
				var wp_color: Color = Color(1.0, 0.85, 0.0) if wp_idx == current_waypoint_idx else Color(0.6, 0.55, 0.3, 0.7)
				var wp_symbol: String = "◇" if wp_idx == current_waypoint_idx else "○"
				draw_circle(pos, radius + 14.0, wp_color, false, 2.0)
				draw_string(Vector2(pos.x - radius - 14, pos.y + 5), wp_symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, wp_color)

		# Firewalled node indicator (TAREA: Defensa estratégica)
		if node_firewalls.has(nid_str):
			var shield_color: Color = Color(0.1, 0.6, 1.0, 0.9)
			var shield_radius: float = radius + 10.0
			# Círculo exterior pulsante
			var pulse: float = 0.5 + sin(Time.get_ticks_msec() * 0.004) * 0.2
			draw_circle(pos, shield_radius + 4.0, Color(0.0, 0.5, 1.0, pulse * 0.25), false, 3.0)
			draw_circle(pos, shield_radius, Color(0.02, 0.12, 0.25, 0.7))
			draw_circle(pos, shield_radius, shield_color, false, 2.5)
			# Icono de escudo
			draw_string(Vector2(pos.x - 7, pos.y + 5), "🛡", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, Color(0.3, 0.8, 1.0))


func draw_pursuers(pursuers: Array, node_positions: Dictionary, node_radius: float) -> void:
	for p in pursuers:
		var pos: Vector2 = node_positions.get(p["pos"], Vector2.ZERO) as Vector2
		if pos == Vector2.ZERO:
			continue
		var active: bool = p["active"]
		var s: float = 10.0
		var color: Color = Color(1.0, 0.1, 0.0, 0.95) if active else Color(0.9, 0.4, 0.05, 0.7)
		draw_rect(Rect2(pos.x - s, pos.y - s, s * 2, s * 2), color)
		draw_rect(Rect2(pos.x - s, pos.y - s, s * 2, s * 2), Color(1.0, 0.9, 0.0, 0.9) if active else Color(1.0, 0.7, 0.2, 0.5), false, 2.0)
		var p_text: String = "P%d" % p["id"]
		var tw: float = font.get_string_size(p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size).x
		draw_rect(Rect2(pos.x + s + 2, pos.y - 10, tw + 6, 14), Color(0.1, 0.02, 0.0, 0.9))
		draw_string(pos + Vector2(s + 5, -4), p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, color)


func draw_optimal_overlay(
	optimal_path: Array,
	node_positions: Dictionary,
	node_radius: float
) -> void:
	if optimal_path.size() < 2:
		return
	# Dibujar highlights en los nodos del camino (no línea continua)
	var pulse: float = 0.5 + sin(Time.get_ticks_msec() * 0.005) * 0.3
	for i in range(optimal_path.size()):
		var node_id: StringName = optimal_path[i] as StringName
		var pos: Vector2 = node_positions.get(node_id, Vector2.ZERO) as Vector2
		if pos == Vector2.ZERO:
			continue
		var is_start: bool = i == 0
		var is_end: bool = i == optimal_path.size() - 1
		var highlight_color: Color
		if is_start:
			highlight_color = Color(0.0, 0.9, 1.0, pulse)
		elif is_end:
			highlight_color = Color(1.0, 0.3, 0.3, pulse)
		else:
			highlight_color = Color(0.6, 0.4, 1.0, pulse)
		draw_circle(pos, node_radius + 10.0, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.2))
		draw_circle(pos, node_radius + 10.0, highlight_color, false, 2.0)


func draw_game_over(
	vp_size: Vector2,
	game_won: bool,
	mensaje_estado: String,
	star_count: int,
	_game_over_time: float = -1.0,
	is_tutorial: bool = false,
	has_next_level: bool = false
) -> void:
	var center: Vector2 = vp_size / 2.0

	var fade_alpha: float = min(1.0, (Time.get_ticks_msec() / 1000.0 - _game_over_time) / 0.5) if _game_over_time > 0 else 1.0
	draw_rect(Rect2(center.x - 180, center.y - 60, 360, 140), Color(0.04, 0.04, 0.1, 0.95 * fade_alpha))
	draw_rect(Rect2(center.x - 180, center.y - 60, 360, 140), Color(0.0, 1.0, 0.83, 0.6), false, 2.0)

	var texto: String
	var color: Color
	if not game_won:
		texto = "DERROTA"
		color = Color(1.0, 0.2, 0.2)
	elif is_tutorial:
		texto = "TUTORIAL COMPLETADO"
		color = Color(0.0, 1.0, 0.83)
	else:
		texto = "VICTORIA"
		color = Color(0.0, 1.0, 0.5)
	draw_string(center + Vector2(-50, -20), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, color)
	draw_string(center + Vector2(-140, 12), mensaje_estado, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color.WHITE)

	if game_won:
		var star_text: String = ""
		for i in range(3):
			star_text += "★" if i < star_count else "☆"
		draw_string(center + Vector2(-50, 40), star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.YELLOW)

	_draw_game_over_hints(center, game_won, has_next_level)


## Línea de controles post-partida (slice 6): [N] siguiente sólo tras
## victoria con nivel siguiente disponible; [L] selector y [Q] menú siempre.
func _draw_game_over_hints(center: Vector2, game_won: bool, has_next_level: bool) -> void:
	var hint: String = "[R] Reiniciar"
	if game_won and has_next_level:
		hint += "   [N] Siguiente"
	hint += "   [L] Niveles   [Q] Menú"
	var w: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x
	draw_string(center + Vector2(-w / 2.0, 65), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.6, 0.6, 0.7))


func draw_node_info_panel(
	vp_size: Vector2,
	selected_neighbor: StringName,
	player_pos: StringName,
	graph: NetworkGraphResource,
	node_cache: Dictionary
) -> void:
	# P5/tarea 3: datos en lugar de callable — el cache {id: NodeResource}
	# poblado en GameState.load_graph() reemplaza a find_node_res_func.
	var node_res = node_cache.get(selected_neighbor)
	if node_res == null:
		return

	var panel_w: float = 200.0
	var panel_h: float = 120.0
	var panel_x: float = vp_size.x - panel_w - 12.0
	var panel_y: float = 56.0
	var panel_rect: Rect2 = Rect2(panel_x, panel_y, panel_w, panel_h)

	draw_rect(panel_rect, Color(0.03, 0.03, 0.07, 0.95))
	draw_rect(panel_rect, Color(0.0, 1.0, 0.83, 0.6), false, 1.5)

	var px: float = panel_x + 12.0
	var py: float = panel_y + 20.0
	var line_h: float = 18.0

	draw_string(Vector2(px, py), str(selected_neighbor), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, Color(0.0, 1.0, 0.83))
	py += line_h + 4.0

	var meta: Dictionary = node_res.metadata
	var edge_cost: float = 0.0
	for e in graph.edges:
		if e != null and e.from_id == player_pos and e.to_id == selected_neighbor:
			edge_cost = e.transit_cost
			break

	draw_string(Vector2(px, py), "Coste: ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))
	draw_string(Vector2(px + 52, py), "%.1f" % edge_cost, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, Color.WHITE)
	py += line_h

	var detect: float = meta.get("detection_chance", 0.0)
	var det_label: String = "%.0f%%" % (detect * 100.0)
	var det_color: Color = Color(0.0, 1.0, 0.5) if detect <= 0.0 else (Color(1.0, 0.8, 0.0) if detect < 0.3 else Color(1.0, 0.2, 0.2))
	draw_string(Vector2(px, py), "Alerta: ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.5, 0.55, 0.65))
	draw_string(Vector2(px + 50, py), det_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, det_color)
	py += line_h

	if meta.has("label"):
		draw_string(Vector2(px, py), str(meta["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.6, 0.65, 0.75))
		py += line_h

	if meta.get("has_firewall", false):
		draw_rect(Rect2(px - 2, py - 10, 70, 14), Color(0.0, 0.5, 0.8, 0.3))
		draw_string(Vector2(px, py), "FIREWALL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.0, 0.8, 1.0))
		py += line_h

	if meta.get("security_spawn", false):
		draw_rect(Rect2(px - 2, py - 10, 100, 14), Color(0.8, 0.3, 0.0, 0.3))
		draw_string(Vector2(px, py), "SPAWN SEGURIDAD", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(1.0, 0.5, 0.0))
		py += line_h


func draw_tutorial_highlights(tutorial_player, node_positions: Dictionary, node_radius: float, player_pos: StringName = &"") -> void:
	## Railes visuales del tutorial (Slice 3.8 v2):
	##   Rail 1 — nodos destacados más grandes, brillantes y con anillo pulsante.
	##   Rail 3 — flecha desde la posición del jugador al nodo objetivo cuando el
	##            paso actual pide una acción (move/input).
	if tutorial_player == null or not tutorial_player.is_active:
		return
	var idx: int = tutorial_player.current_step_index
	if idx < 0 or idx >= tutorial_player.steps.size():
		return
	var step: Dictionary = tutorial_player.steps[idx]

	var is_action_step: bool = false
	var ar = step.get("action_required", "")
	if ar != null and str(ar) != "":
		is_action_step = true

	var highlight_nodes: Array = step.get("highlight_nodes", [])
	for nid in highlight_nodes:
		if not node_positions.has(nid):
			continue
		var pos: Vector2 = node_positions[nid] as Vector2
		var r: float = node_radius + (16.0 if is_action_step else 10.0)
		var t: float = Time.get_ticks_msec() * 0.005
		var pulse: float = 0.5 + sin(t) * 0.3
		var color: Color
		if is_action_step:
			# Verde brillante: nodo sobre el que hay que actuar ahora
			color = Color(0.3, 1.0, 0.6, 0.55 + pulse * 0.45)
		else:
			color = Color(0.0, 0.9, 1.0, pulse)
		draw_circle(pos, r, Color(color.r, color.g, color.b, 0.18))
		draw_circle(pos, r, color, false, 3.0)
		# Anillo exterior pulsante
		var ring_r: float = r + 4.0 + sin(t * 1.4) * 3.0
		draw_circle(pos, ring_r, Color(color.r, color.g, color.b, pulse * 0.5), false, 2.0)

	# Rail 3: flecha hacia el objetivo — desde la posición del jugador al
	# primer nodo destacado que no sea el propio jugador (en pasos de acción).
	if is_action_step and player_pos != &"" and not highlight_nodes.is_empty():
		var target_nid: String = ""
		for nid in highlight_nodes:
			if str(nid) != str(player_pos):
				target_nid = str(nid)
				break
		var player_key: String = str(player_pos)
		if target_nid != "" and node_positions.has(target_nid) and node_positions.has(player_key):
			var from_pos: Vector2 = node_positions[player_key] as Vector2
			var to_pos: Vector2 = node_positions[target_nid] as Vector2
			if from_pos != to_pos:
				var t2: float = Time.get_ticks_msec() * 0.004
				var alpha: float = 0.55 + sin(t2) * 0.35
				var dir: Vector2 = (to_pos - from_pos).normalized()
				var tip: Vector2 = to_pos - dir * (node_radius + 20.0)
				var base: Vector2 = tip - dir * 26.0
				var perp: Vector2 = Vector2(-dir.y, dir.x) * 9.0
				draw_line(from_pos, tip, Color(0.3, 1.0, 0.6, alpha), 3.0, true)
				draw_polygon(PackedVector2Array([tip, base + perp, base - perp]), Color(0.3, 1.0, 0.6, alpha))

	var highlight_edges: Array = step.get("highlight_edges", [])
	for edge_key in highlight_edges:
		var parts: PackedStringArray = edge_key.split("→")
		if parts.size() != 2:
			continue
		if not node_positions.has(parts[0]) or not node_positions.has(parts[1]):
			continue
		var from_pos: Vector2 = node_positions[parts[0]] as Vector2
		var to_pos: Vector2 = node_positions[parts[1]] as Vector2
		var pulse: float = 0.6 + sin(Time.get_ticks_msec() * 0.006) * 0.3
		var color: Color = Color(0.0, 0.9, 1.0, pulse)
		draw_line(from_pos, to_pos, color, 5.0, true)


func draw_tutorial_text(mensaje_tutorial: String) -> void:
	var lines: PackedStringArray = mensaje_tutorial.split("\n")
	var py: float = 80.0
	for line in lines:
		draw_string(Vector2(20, py), line, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color.YELLOW)
		py += 16


func draw_status_bar(
	vp_size: Vector2,
	mensaje_estado: String,
	selected_neighbor: StringName,
	game_over: bool,
	game_won: bool,
	defender_mode: bool = false
) -> void:
	# ZONA 3: Barra inferior con fondo
	var bar_h: float = 32.0
	draw_rect(Rect2(0, vp_size.y - bar_h, vp_size.x, bar_h), Color(0.04, 0.04, 0.08, 0.9))
	draw_rect(Rect2(0, vp_size.y - bar_h, vp_size.x, bar_h), Color(0.0, 1.0, 0.83, 0.2), false, 1.0)

	# Keybinds (izquierda)
	var kb_text: String
	if defender_mode:
		kb_text = "[Click arista] Bloquear  [F] Firewall  [Enter] Resolver  [R] Reset  [Q] Menu"
	else:
		kb_text = "[Click] Mover  [Tab] Sel  [Enter] Ir  [P] Ruta  [R] Reset  [Q] Menu"
	draw_string(Vector2(16, vp_size.y - 10), kb_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.4, 0.45, 0.55, 0.7))

	# Estado (centro-derecha)
	if mensaje_estado != "":
		var color_estado: Color = Color(0.0, 1.0, 0.5) if game_won else (Color(1.0, 0.2, 0.2) if game_over else Color(0.0, 1.0, 0.83))
		var texto_estado: String = mensaje_estado
		if selected_neighbor != &"" and not game_over:
			texto_estado += "  → %s" % selected_neighbor
		var tw: float = font.get_string_size(texto_estado, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x
		var state_x: float = vp_size.x - tw - 20.0
		draw_rect(Rect2(state_x - 6, vp_size.y - bar_h + 4, tw + 12, bar_h - 8), Color(0.06, 0.06, 0.12, 0.8))
		draw_rect(Rect2(state_x - 6, vp_size.y - bar_h + 4, tw + 12, bar_h - 8), color_estado, false, 1.0)
		draw_string(Vector2(state_x, vp_size.y - 10), texto_estado, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, color_estado)


func draw_defender_game_over(
	vp_size: Vector2,
	game_won: bool,
	mensaje_estado: String,
	star_count: int,
	_game_over_time: float = -1.0,
	has_next_level: bool = false
) -> void:
	var center: Vector2 = vp_size / 2.0

	var fade_alpha: float = min(1.0, (Time.get_ticks_msec() / 1000.0 - _game_over_time) / 0.5) if _game_over_time > 0 else 1.0
	draw_rect(Rect2(center.x - 180, center.y - 60, 360, 140), Color(0.04, 0.04, 0.1, 0.95 * fade_alpha))
	
	if game_won:
		draw_rect(Rect2(center.x - 180, center.y - 60, 360, 140), Color(0.0, 1.0, 0.5, 0.6), false, 2.0)
		var texto: String = "🛡️ VICTORIA DEFENSIVA"
		draw_string(center + Vector2(-140, -20), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.0, 1.0, 0.5))
	else:
		draw_rect(Rect2(center.x - 180, center.y - 60, 360, 140), Color(1.0, 0.2, 0.2, 0.6), false, 2.0)
		var texto: String = "💀 DERROTA"
		draw_string(center + Vector2(-60, -20), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.2, 0.2))
	
	draw_string(center + Vector2(-140, 12), mensaje_estado, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color.WHITE)

	if game_won:
		var star_text: String = ""
		for i in range(3):
			star_text += "★" if i < star_count else "☆"
		draw_string(center + Vector2(-50, 40), star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.YELLOW)

	_draw_game_over_hints(center, game_won, has_next_level)
