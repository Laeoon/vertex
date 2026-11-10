class_name GameRenderer extends RefCounted

const BrandClass = preload("res://juego/ui/brand.gd")

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


func draw_rect(rect: Rect2, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void:
	if filled:
		_canvas.draw_rect(rect, color, true)
	else:
		_canvas.draw_rect(rect, color, false, width, antialiased)


func draw_line(from: Vector2, to: Vector2, color: Color, width: float = 1.0, antialiased: bool = false) -> void:
	_canvas.draw_line(from, to, color, width, antialiased)


func draw_circle(pos: Vector2, radius: float, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void:
	if filled:
		_canvas.draw_circle(pos, radius, color, true)
	else:
		_canvas.draw_circle(pos, radius, color, false, width, antialiased)


func draw_polygon(points: PackedVector2Array, color: Color) -> void:
	_canvas.draw_colored_polygon(points, color)


func draw_polyline(points: PackedVector2Array, color: Color, width: float = -1.0) -> void:
	_canvas.draw_polyline(points, color, width)


func draw_string(pos: Vector2, text: String, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1, font_size_override: int = -1, color: Color = Color.WHITE) -> void:
	var fs: int = font_size_override if font_size_override > 0 else font_size
	_canvas.draw_string(font, pos, text, alignment, width, fs, color)


func draw_error(vp_size: Vector2, mensaje_estado: String) -> void:
	draw_rect(Rect2(20, 80, vp_size.x - 40, 40), Color(0.15, 0.02, 0.02, 0.9))
	draw_string(Vector2(30, 106), mensaje_estado, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.RED)


static func resolve_node_display_name(nid: Variant, node_cache: Dictionary) -> String:
	var s_nid := StringName(str(nid))
	if node_cache.has(s_nid):
		var res = node_cache[s_nid]
		if res != null:
			if "display_name" in res and str(res.display_name).strip_edges() != "":
				return str(res.display_name)
			elif "name" in res and str(res.name).strip_edges() != "":
				return str(res.name)
	return str(nid)


static func get_defender_pill_rects(
	vp_size: Vector2,
	p_font: Font,
	p_font_size: int,
	fog_of_war: bool = false,
	telemetry_intercepted: bool = false
) -> Array[Dictionary]:
	var pills_info: Array[Dictionary] = [
		{"id": "edges", "text": "[1] SEGMENTAR ARISTA", "color": BrandClass.ACCENT},
		{"id": "firewall", "text": "[2] FIREWALL", "color": Color(0.2, 0.7, 1.0)},
		{"id": "quarantine", "text": "[3] CUARENTENA", "color": Color(1.0, 0.75, 0.0)},
	]
	if fog_of_war or telemetry_intercepted:
		var p_label := "REVELADO (2★)" if telemetry_intercepted else "[4] RADAR"
		pills_info.append({"id": "radar", "text": p_label, "color": BrandClass.WARNING if telemetry_intercepted else Color("80d8ff")})
	else:
		pills_info.append({"id": "radar", "text": "[4] RADAR", "color": Color("80d8ff")})
	pills_info.append({"id": "terminal", "text": "[~] CLI", "color": Color("00e5ff")})

	var pill_h := 36.0
	var gap := 12.0
	var total_w := 0.0
	var widths: Array[float] = []

	for p in pills_info:
		var txt: String = p["text"]
		var tw: float = 80.0
		if p_font != null:
			tw = p_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, p_font_size - 3).x
		var w := tw + 24.0
		widths.append(w)
		total_w += w
	total_w += gap * float(pills_info.size() - 1)

	var start_x := (vp_size.x - total_w) / 2.0
	var pill_y := 6.0

	var result: Array[Dictionary] = []
	var cur_x := start_x
	for i in range(pills_info.size()):
		var w := widths[i]
		var rect := Rect2(cur_x, pill_y, w, pill_h)
		result.append({
			"id": pills_info[i]["id"],
			"text": pills_info[i]["text"],
			"color": pills_info[i]["color"],
			"rect": rect
		})
		cur_x += w + gap

	return result


## Sub-header ribbon dedicado para telemetría secundaria / Kain ghost stream (y = 48..76)
func draw_sub_header_ribbon(vp_size: Vector2, text: String, is_secret: bool = false) -> void:
	var rib_y := 48.0
	var rib_h := 28.0
	var rib_rect := Rect2(0, rib_y, vp_size.x, rib_h)
	draw_rect(rib_rect, Color(0.05, 0.05, 0.09, 0.94))
	draw_rect(rib_rect, Color(0.16, 0.18, 0.29, 0.8), false, 1.0)

	var draw_text := text
	var tag := "[STATUS]: "
	var tag_col: Color = BrandClass.ACCENT
	if is_secret:
		tag = "[TCP_SEQ_GHOST // ARCHITECT-0]: "
		tag_col = BrandClass.WORLD_SECRET
		if draw_text == "":
			draw_text = "Infiltración en espacio de memoria del kernel. Bypass o desvío requerido."

	var tag_sz := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3)
	draw_string(Vector2(20.0, rib_y + 19.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, tag_col)
	draw_string(Vector2(20.0 + tag_sz.x, rib_y + 19.0), draw_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT)


## Orquestación del frame completo (P5): juego_ataque._draw() sólo hace los
## guards (brain válido, runtime/graph cargados) y delega acá con un
## diccionario de datos puro armado por GameState.frame_data() — sin
## callables ni lectura de estado del nodo juego.
func draw_frame(d: Dictionary) -> void:
	var pan: Vector2 = d.get("topology_pan", Vector2.ZERO)
	var zoom: float = d.get("topology_zoom", 1.0)
	var has_transform: bool = pan != Vector2.ZERO or not is_equal_approx(zoom, 1.0)

	# 1. Capa de topología: sujeta a pan y zoom
	if has_transform:
		_canvas.draw_set_transform(pan, 0.0, Vector2(zoom, zoom))

	var is_secret_sector: bool = str(d.get("level_key", "")).begins_with("secret") or d.get("world", "") == "secret" or str(d.get("titulo_nivel", "")).find("Sector 0") != -1 or d.node_positions.has(&"GenesisCore") or d.node_positions.has("GenesisCore")
	var core_pos: Vector2 = d.node_positions.get(&"GenesisCore", d.node_positions.get("GenesisCore", Vector2(935, 272))) as Vector2
	if is_secret_sector:
		_draw_kernel_void_background(d.vp_size, pan, zoom, core_pos)
	else:
		draw_background_grid(d.vp_size, pan, zoom)

	var hidden_nodes: Array = d.get("hidden_nodes", [])
	var should_draw_enemy_path: bool = d.get("brain_path_revealed", true) if d.defender_mode else false
	draw_edges(d.graph, d.node_positions, d.blocked_edges, d.blocked_keys, d.current_path, d.node_radius, d.game_over, d.brain_hovered_edge if d.defender_mode else "", d.brain_enemy_path if should_draw_enemy_path else [], d.turn, d.unblock_flash_time, d.unblock_flash_edge, hidden_nodes, d.player_pos, d.selected_neighbor, is_secret_sector)
	if d.defender_mode:
		var q_mode_active: bool = d.get("quarantine_mode", false)
		var enemy_start_node: StringName = d.graph.nodes[0].id if d.graph != null and d.graph.nodes.size() > 0 else &""
		if d.get("enemy_start_node", &"") != &"":
			enemy_start_node = d.get("enemy_start_node")
		var enemy_vis: Vector2 = d.get("enemy_visual_pos", Vector2.ZERO)
		draw_nodes(d.graph, d.node_positions, &"", d.brain_enemy_target, [], d.current_path, d.node_radius, d.game_over, d.alerted_nodes, &"", d.scan_results, d.waypoints, -1, d.brain_firewalls, d.brain_enemy_pos, d.enemy_move_flash_time, d.bonus_nodes, d.bonus_visitados, hidden_nodes, enemy_vis, false, true, d.brain_enemy_pos, d.get("brain_quarantined_nodes", {}), q_mode_active, enemy_start_node, d.brain_enemy_target, is_secret_sector)
		if should_draw_enemy_path and d.brain_enemy_path.size() >= 2:
			draw_optimal_overlay(d.brain_enemy_path, d.node_positions, d.node_radius)
	else:
		draw_nodes(d.graph, d.node_positions, d.player_pos, d.target, d.neighbors, d.current_path, d.node_radius, d.game_over, d.alerted_nodes, d.selected_neighbor, d.scan_results, d.waypoints, d.waypoint_idx, {}, &"", d.enemy_move_flash_time, d.bonus_nodes, d.bonus_visitados, hidden_nodes, d.get("player_visual_pos", Vector2.ZERO), d.get("is_moving", false), false, &"", {}, false, &"", &"", is_secret_sector)

	draw_pursuers(d.pursuers, d.node_positions, d.node_radius)
	if d.show_optimal_overlay:
		draw_optimal_overlay(d.optimal_overlay_path, d.node_positions, d.node_radius)
	if d.tutorial_player != null and d.tutorial_player.is_active:
		# Flecha guía del tutorial: en modo defensor no hay jugador.
		draw_tutorial_highlights(d.tutorial_player, d.node_positions, d.node_radius, d.tutorial_arrow_pos)

	# Preview predictivo táctico en hover / touch (en coordenadas de topología)
	draw_predictive_hover_preview(d)

	# 2. Capa de UI fija (HUD, status bar, tutoriales, paneles)
	if has_transform:
		_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if d.defender_mode:
		var q_mode_active: bool = d.get("quarantine_mode", false)
		draw_defender_hud(d.vp_size, d.turn, d.brain_blocks_placed, d.brain_blocks_per_turn, d.brain_enemy_pos, d.brain_enemy_target, d.max_turns, d.brain_min_cut, d.blocked_edges, d.brain_firewalls, d.brain_firewall_mode, d.get("brain_forensics_trace", 0.0), d.get("brain_quarantined_nodes", {}), d.get("brain_fog_of_war", false), d.get("brain_telemetry_intercepted", false), q_mode_active, d.get("node_cache", {}))
	else:
		draw_hud(d.vp_size, d.titulo_nivel, d.turn, d.player_pos, d.target, d.player_total_cost, d.max_turns, d.waypoints, d.waypoint_idx, d.pursuers, d.alerted_nodes, d.movement_points, d.max_movement_points, d.budget_display, d.get("node_cache", {}), d.get("hacker_state", {}), d.get("hacker_mode", false), is_secret_sector)

	# Sub-header ribbon dedicado para estado / Kain stream (y = 48..76, fuera del canvas)
	var mensaje_estado: String = d.get("mensaje_estado", "")
	if (mensaje_estado != "" and not mensaje_estado.begins_with("Ve hacia")) or is_secret_sector:
		draw_sub_header_ribbon(d.vp_size, mensaje_estado, is_secret_sector)

	if d.mensaje_tutorial != "" and not d.game_over:
		draw_tutorial_text(d.mensaje_tutorial)
	if d.selected_neighbor != &"" and not d.game_over:
		draw_node_info_panel(d.vp_size, d.selected_neighbor, d.player_pos, d.graph, d.node_cache, is_secret_sector)

	# Menú contextual de nodo en modo Defensor (pantalla UI)
	if d.defender_mode and d.get("defender_context_node", &"") != &"":
		draw_defender_contextual_menu(d.vp_size, d.get("defender_context_node"), d.node_positions, pan, zoom)

	# Dock táctico unificado (Heist, Hacker, Defender, Cámara touch)
	draw_tactical_action_dock(d)


## Fondo Abisal de Kernel Panic / Glitch Void para el Sector 0 secreto (Artboard 03)
func _draw_kernel_void_background(vp_size: Vector2, _pan: Vector2, _zoom: float, core_pos: Vector2 = Vector2(935, 272)) -> void:
	# Fondo Crimson / Void Hypervisor profundo (#14080e)
	draw_rect(Rect2(0, 0, vp_size.x, vp_size.y), Color("14080e"))

	# Cuadrícula sutil crimson (espaciado 48px)
	var grid_color := Color(1.0, 0.16, 0.42, 0.07)
	var spacing := 48.0
	var x: float = 0.0
	while x <= vp_size.x:
		draw_line(Vector2(x, 0), Vector2(x, vp_size.y), grid_color, 1.0)
		x += spacing
	var y: float = 0.0
	while y <= vp_size.y:
		draw_line(Vector2(0, y), Vector2(vp_size.x, y), grid_color, 1.0)
		y += spacing

	# Anillos concéntricos de gravedad hipervisor centrados en GenesisCore (935, 272)
	var t: float = Time.get_ticks_msec() * 0.001
	draw_circle(core_pos, 76.0, Color(1.0, 0.16, 0.42, 0.25), false, 1.5)
	draw_circle(core_pos, 130.0, Color(0.75, 0.35, 0.95, 0.18), false, 1.2)
	draw_circle(core_pos, 190.0, Color(1.0, 0.16, 0.42, 0.12), false, 1.0)

	# Lluvia volumétrica de memoria (Hex Dump y registros de fallo del kernel)
	var hex_words: Array[String] = [
		"0xDEADBEEF", "0xC001CAFE", "0x00000000", "0xFFFFFFFF",
		"SEGFAULT", "KERNEL_PANIC", "STACK_DUMP", "NULL_PTR",
		"PAGE_FAULT", "ROOT_EXPLOIT", "MEM_CORRUPT", "0x89AB_CDEF"
	]

	var col_w: float = 140.0
	var num_cols := int(vp_size.x / col_w) + 1
	for col in range(num_cols):
		var col_x := float(col) * col_w + 10.0
		var seed_speed := 35.0 + float((col * 17) % 25)
		var y_offset := fmod((t * seed_speed) + float(col * 85), vp_size.y + 120.0) - 60.0
		var word_idx: int = (col + int(t * 0.5)) % hex_words.size()
		var text := hex_words[word_idx]

		var hex_alpha := 0.12 + sin(t * 2.0 + float(col)) * 0.06
		draw_string(Vector2(col_x, y_offset), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.2, 0.35, hex_alpha))

	# Líneas de cuadrícula corrompidas / Glitch scan
	var glitch_y := fmod(t * 90.0, vp_size.y)
	draw_line(Vector2(0, glitch_y), Vector2(vp_size.x, glitch_y), Color(1.0, 0.1, 0.3, 0.25), 1.5)
	draw_line(Vector2(0, glitch_y + 4.0), Vector2(vp_size.x, glitch_y + 4.0), Color(0.2, 1.0, 0.8, 0.15), 1.0)


func draw_background_grid(vp_size: Vector2, pan: Vector2 = Vector2.ZERO, zoom: float = 1.0) -> void:
	# Fondo táctico blueprint cyberpunk (plano militar con cruces e iluminación focal)
	var spacing: float = 60.0
	var grid_color: Color = Color(0.04, 0.12, 0.22, 0.40)
	var cross_color: Color = Color(0.10, 0.35, 0.55, 0.35)
	var z := zoom if zoom > 0.0 else 1.0

	var x_start: float = floor((-pan.x / z) / spacing) * spacing
	var x_end: float = ceil(((vp_size.x - pan.x) / z) / spacing) * spacing
	var y_start: float = floor((-pan.y / z) / spacing) * spacing
	var y_end: float = ceil(((vp_size.y - pan.y) / z) / spacing) * spacing

	# 1. Líneas de cuadrícula sutiles
	var x: float = x_start
	while x <= x_end:
		draw_line(Vector2(x, y_start), Vector2(x, y_end), grid_color, 1.0)
		x += spacing
	var y: float = y_start
	while y <= y_end:
		draw_line(Vector2(x_start, y), Vector2(x_end, y), grid_color, 1.0)
		y += spacing

	# 2. Cruces tácticas en las intersecciones (estilo blueprint CAD/militar)
	var cross_sz: float = 3.5
	var cy: float = y_start
	while cy <= y_end:
		var cx: float = x_start
		while cx <= x_end:
			draw_line(Vector2(cx - cross_sz, cy), Vector2(cx + cross_sz, cy), cross_color, 1.0)
			draw_line(Vector2(cx, cy - cross_sz), Vector2(cx, cy + cross_sz), cross_color, 1.0)
			cx += spacing
		cy += spacing


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
	_budget_display: float = 0.0,
	node_cache: Dictionary = {},
	hacker_state: Dictionary = {},
	hacker_mode: bool = false,
	is_secret: bool = false
) -> void:
	var bar_h: float = 48.0

	# ZONA 1: Barra superior con fondo (Artboard 01 / 03)
	draw_rect(Rect2(0, 0, vp_size.x, bar_h), BrandClass.PANEL_SOLID)
	draw_rect(Rect2(0, bar_h, vp_size.x, 1.5), BrandClass.accent_dim(0.4))

	# Título del nivel (izquierda)
	draw_string(Vector2(16, 20), titulo_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 3, BrandClass.ACCENT)

	# Indicadores principales (centro)
	var center_x: float = vp_size.x / 2.0
	var ind_y: float = 20.0

	# Turno
	var turn_text: String = "TURNO %d" % turn
	var turn_w: float = font.get_string_size(turn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
	draw_string(Vector2(center_x - turn_w / 2.0 - 130, ind_y), "TURNO ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
	draw_string(Vector2(center_x - turn_w / 2.0 - 130 + font.get_string_size("TURNO ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x, ind_y), "%d" % turn, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, Color.WHITE)

	# Puntos de movimiento con barra visual
	if max_movement_points > 0:
		var pts_label_x: float = center_x - 70
		var pts_color: Color = Color(0.0, 1.0, 0.5) if movement_points > max_movement_points * 0.3 else BrandClass.WARNING if movement_points > max_movement_points * 0.1 else BrandClass.DANGER
		draw_string(Vector2(pts_label_x, ind_y), "PUNTOS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

		# Barra de progreso
		var bar_x: float = pts_label_x + 50
		var bar_w: float = 80.0
		var bar_y: float = ind_y - 10
		var bar_h_inner: float = 12.0
		var fill_ratio: float = _budget_display / float(max_movement_points)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h_inner), Color(0.1, 0.12, 0.18))
		draw_rect(Rect2(bar_x, bar_y, bar_w * fill_ratio, bar_h_inner), pts_color)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h_inner), Color(0.3, 0.35, 0.45), false, 1.0)

		# Texto sobre la barra
		var pts_text: String = "%d/%d" % [movement_points, max_movement_points]
		draw_string(Vector2(bar_x + bar_w + 8, ind_y), pts_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, pts_color)

	# Noise IDS meter integrado en barra superior (en lugar del panel derecho duplicado)
	if hacker_mode or is_secret:
		var noise: int = hacker_state.get("noise", 0)
		var max_noise: int = hacker_state.get("max_noise", 100)
		var noise_col: Color = BrandClass.SUCCESS
		if noise >= 85:
			noise_col = BrandClass.DANGER
		elif noise >= 60:
			noise_col = Color(1.0, 0.5, 0.0)
		elif noise >= 30:
			noise_col = BrandClass.WARNING

		var nm_x := center_x + (85.0 if max_movement_points > 0 else -60.0)
		draw_string(Vector2(nm_x, ind_y), "RUIDO IDS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
		var nm_bar_x := nm_x + 68.0
		var nm_bar_w := 80.0
		var nm_fill_w := nm_bar_w * clampf(float(noise) / float(maxi(1, max_noise)), 0.0, 1.0)
		draw_rect(Rect2(nm_bar_x, ind_y - 10.0, nm_bar_w, 12.0), Color(0.1, 0.12, 0.18))
		if nm_fill_w > 0:
			draw_rect(Rect2(nm_bar_x, ind_y - 10.0, nm_fill_w, 12.0), noise_col)
		draw_rect(Rect2(nm_bar_x, ind_y - 10.0, nm_bar_w, 12.0), Color(0.3, 0.35, 0.45), false, 1.0)
		draw_string(Vector2(nm_bar_x + nm_bar_w + 8.0, ind_y), "%d/%d" % [noise, max_noise], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, noise_col)

	# Indicadores secundarios (debajo)
	var sec_y: float = 38.0
	var sec_x: float = 16.0

	# Posición con nombre legible de nodo
	var pos_display: String = resolve_node_display_name(player_pos, node_cache)
	var pos_text: String = "POS: %s" % pos_display
	draw_string(Vector2(sec_x, sec_y), pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	sec_x += font.get_string_size(pos_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x + 18.0

	# Coste
	var cost_text: String = "COSTE: %.1f" % player_total_cost
	draw_string(Vector2(sec_x, sec_y), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	sec_x += font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x + 18.0

	# Turnos restantes
	if max_turns > 0:
		var rem_text: String = "RESTANTE: %d" % (max_turns - turn)
		var rem_color: Color = Color(0.0, 1.0, 0.5) if (max_turns - turn) > max_turns * 0.3 else BrandClass.WARNING
		draw_string(Vector2(sec_x, sec_y), rem_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, rem_color)
		sec_x += font.get_string_size(rem_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x + 18.0

	# Waypoints
	if waypoints.size() > 0:
		var wp_text: String = "WP: %d/%d" % [current_waypoint_idx + 1, waypoints.size()]
		draw_string(Vector2(sec_x, sec_y), wp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	# Indicador de amenaza (derecha)
	var alert_x: float = vp_size.x - 16.0
	var badge_left: float = vp_size.x - 16.0
	if pursuers.size() > 0:
		var p_text: String = "PERSEGUIDORES: %d" % pursuers.size()
		var pw: float = font.get_string_size(p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x
		alert_x -= pw + 8.0
		badge_left = alert_x - 6.0
		draw_rect(Rect2(alert_x - 6, ind_y - 14, pw + 12, 20), Color(0.8, 0.05, 0.02, 0.4))
		draw_rect(Rect2(alert_x - 6, ind_y - 14, pw + 12, 20), Color(1.0, 0.2, 0.1, 0.7), false, 1.0)
		draw_string(Vector2(alert_x, ind_y), p_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.DANGER)
	elif alerted_nodes.size() > 0:
		var a_text: String = "ALERTAS: %d" % alerted_nodes.size()
		var aw: float = font.get_string_size(a_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x
		alert_x -= aw + 8.0
		badge_left = alert_x
		draw_string(Vector2(alert_x, ind_y), a_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.WARNING)

	# Meta con nombre legible de nodo (a la izquierda de las insignias de amenaza, sin colisión)
	var target_display: String = resolve_node_display_name(target, node_cache)
	var meta_text: String = "META: %s" % target_display
	var meta_w: float = font.get_string_size(meta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1).x
	var meta_x: float = badge_left - 16.0 - meta_w
	draw_string(Vector2(meta_x, ind_y), meta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.DANGER)


## Legacy helper — el panel derecho duplicado fue eliminado.
func draw_hacker_hud(_vp_size: Vector2, _hacker_state: Dictionary, _scan_results: Dictionary) -> void:
	pass


func draw_defender_hud(
	vp_size: Vector2,
	turn: int,
	blocks_placed: int,
	blocks_per_turn: int,
	enemy_pos: StringName,
	enemy_target: StringName,
	_max_turns: int,
	_min_cut_analysis: Dictionary = {},
	_blocked_edges: Dictionary = {},
	_node_firewalls: Dictionary = {},
	firewall_mode: bool = false,
	forensics_trace: float = 0.0,
	_quarantined_nodes: Dictionary = {},
	fog_of_war: bool = false,
	telemetry_intercepted: bool = false,
	quarantine_mode: bool = false,
	node_cache: Dictionary = {}
) -> void:
	# Barra de fondo sutil (Artboard 02)
	draw_rect(Rect2(0, 0, vp_size.x, 48.0), Color(0.02, 0.03, 0.07, 0.94))
	draw_rect(Rect2(0, 48.0, vp_size.x, 1.5), Color(0.15, 0.65, 0.95, 0.7))

	# 1. Isla Flotante Superior Izquierda (BLUE TEAM // T#, BLOQUEOS, RASTREO EDR)
	var island_left_w: float = 330.0
	var island_left := Rect2(12.0, 5.0, island_left_w, 38.0)
	draw_rect(island_left, Color(0.04, 0.06, 0.12, 0.94))
	draw_rect(island_left, Color(0.15, 0.65, 0.95, 0.6), false, 1.0)
	draw_rect(Rect2(12.0, 5.0, 3.0, 38.0), BrandClass.ACCENT)

	draw_string(Vector2(22, 23), "BLUE TEAM", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
	var turn_txt := " // T%d" % turn
	var t_sz := font.get_string_size("BLUE TEAM", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
	draw_string(Vector2(22 + t_sz.x, 23), turn_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)

	# Presupuesto de bloqueos (Pips gráficos ● ● ○)
	var pips_x := 125.0
	var blocks_avail := maxi(0, blocks_per_turn - blocks_placed)
	draw_string(Vector2(pips_x, 18), "BLOQUEOS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.TEXT_DIM)
	for b in range(maxi(1, blocks_per_turn)):
		var pip_pos := Vector2(pips_x + b * 12.0 + 4.0, 29.0)
		var is_ready := b < blocks_avail
		draw_circle(pip_pos, 3.5, Color(0.0, 0.9, 0.6) if is_ready else Color(0.25, 0.28, 0.35))
		if is_ready:
			draw_circle(pip_pos, 5.5, Color(0.0, 0.9, 0.6, 0.25), false, 1.0)

	# RASTREO EDR Forensics Trace (barra compacta)
	var trace_box_x := 185.0
	var trace_box_w := 135.0
	var trace_label := "RASTREO EDR: %.0f%%" % forensics_trace
	draw_string(Vector2(trace_box_x, 18), trace_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, Color("b388ff"))

	var tb_bg := Rect2(trace_box_x, 24, trace_box_w, 8.0)
	draw_rect(tb_bg, Color(0.08, 0.08, 0.15, 0.8))
	draw_rect(tb_bg, Color(0.4, 0.3, 0.7, 0.4), false, 1.0)
	var tb_fill_w := trace_box_w * clampf(forensics_trace / 100.0, 0.0, 1.0)
	if tb_fill_w > 0:
		draw_rect(Rect2(trace_box_x, 24, tb_fill_w, 8.0), Color("b388ff"))

	# 2. Isla Flotante Superior Derecha (INTRUSO & NÚCLEO con nombres humanos)
	var enemy_display: String = resolve_node_display_name(enemy_pos, node_cache)
	var target_display: String = resolve_node_display_name(enemy_target, node_cache)

	var intruso_text := "INTRUSO: %s" % enemy_display
	var nucleo_text := "NÚCLEO: %s" % target_display

	var iw: float = maxf(
		font.get_string_size(intruso_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x,
		font.get_string_size(nucleo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x
	) + 24.0
	var island_right_w: float = maxf(190.0, iw)
	var island_right := Rect2(vp_size.x - island_right_w - 12.0, 5.0, island_right_w, 38.0)
	draw_rect(island_right, Color(0.04, 0.06, 0.12, 0.94))
	draw_rect(island_right, Color(0.15, 0.65, 0.95, 0.6), false, 1.0)
	draw_rect(Rect2(vp_size.x - 15.0, 5.0, 3.0, 38.0), Color(1.0, 0.35, 0.25))

	var rx: float = island_right.position.x + 10.0
	draw_string(Vector2(rx, 20), intruso_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(1.0, 0.35, 0.25))
	draw_string(Vector2(rx, 35), nucleo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.1, 0.85, 0.95))

	# 3. Dock Centrado Flotante de Acciones Defender (Dynamic Width Measurement & 12px gap)
	var pill_rects := get_defender_pill_rects(vp_size, font, font_size, fog_of_war, telemetry_intercepted)
	for p in pill_rects:
		var is_active := false
		var is_pulse := false
		match p["id"]:
			"edges":
				is_active = not firewall_mode and not quarantine_mode
			"firewall":
				is_active = firewall_mode
			"quarantine":
				is_active = quarantine_mode
				is_pulse = true
			"radar":
				is_active = telemetry_intercepted
			"terminal":
				is_active = false
		_draw_hud_pill(p["rect"].position, p["text"], is_active, p["color"], is_pulse)


func _draw_hud_pill(pos: Vector2, text: String, active: bool, color: Color, pulse: bool = false) -> void:
	var t_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x
	var pill_h := 36.0  # Altura cómoda >= 36px para touch y mouse
	var pill_w := t_w + 24.0
	var pill_rect := Rect2(pos.x, pos.y, pill_w, pill_h)

	var bg_col := BrandClass.with_alpha(color, 0.25 if active else 0.08)
	var border_col := BrandClass.with_alpha(color, 0.85 if active else 0.3)
	if active and pulse:
		var p_wave := 0.6 + sin(Time.get_ticks_msec() * 0.008) * 0.35
		border_col = BrandClass.with_alpha(color, p_wave)
		draw_rect(Rect2(pos.x - 2, pos.y - 2, pill_w + 4.0, pill_h + 4.0), BrandClass.with_alpha(color, p_wave * 0.25), false, 1.5)

	draw_rect(pill_rect, bg_col)
	draw_rect(pill_rect, border_col, false, 1.2)
	draw_string(Vector2(pos.x + 12.0, pos.y + 23.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, color if active else BrandClass.TEXT_DIM)


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
	_unblock_flash_edge: String = "",
	hidden_nodes: Array = [],
	player_pos: StringName = &"",
	selected_neighbor: StringName = &"",
	is_secret_sector: bool = false
) -> void:
	# Pre-pasada: set de claves para detectar pares bidireccionales (A→B + B→A)
	# y curvarlos aparte — dibujados rectos se superponen exactamente y las
	# etiquetas de protocolo se apilan en el mismo punto medio.
	var claves: Dictionary = {}
	for e2 in graph.edges:
		if e2 != null:
			claves["%s→%s" % [e2.from_id, e2.to_id]] = true

	for e in graph.edges:
		if e == null:
			continue
		if hidden_nodes.has(e.from_id) or hidden_nodes.has(e.to_id) or hidden_nodes.has(String(e.from_id)) or hidden_nodes.has(String(e.to_id)):
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
		elif is_secret_sector:
			# Sector 0 Triad Daemon branch coloring
			var f_str := String(e.from_id)
			var t_str := String(e.to_id)
			var upper_branch := ["NexusA", "HexNode_4", "VoidTrap"]
			var lower_branch := ["NexusB", "HexNode_5", "GenesisAntechamber"]
			var spine_branch := ["HexNode_3", "RootBastion", "HexNode_1", "HexNode_2"]

			if upper_branch.has(f_str) or upper_branch.has(t_str):
				edge_color = Color("#bf5af2")
			elif lower_branch.has(f_str) or lower_branch.has(t_str):
				edge_color = Color("#00d2ff")
			elif spine_branch.has(f_str) or spine_branch.has(t_str):
				edge_color = Color("#39ff88")
			else:
				edge_color = Color("#ff2a6d")
			line_width = 2.0
		else:
			edge_color = Color(0.35, 0.5, 0.7, 0.9)
			line_width = 1.5

		var tip: Vector2 = to_pos - dir * node_radius
		var inicio: Vector2 = from_pos + dir * node_radius
		var centro: Vector2 = (from_pos + to_pos) / 2.0
		var perp: Vector2 = dir.rotated(PI / 2.0)

		# Par bidireccional → arco cuadrático; el lado es determinístico por
		# comparación de ids (cada dirección dobla para lados opuestos).
		var bend: float = 0.0
		if claves.has("%s→%s" % [e.to_id, e.from_id]):
			bend = 15.0 * (1.0 if String(e.from_id) < String(e.to_id) else -1.0)
		elif absf(bend) < 0.5:
			# Si la arista cruza cerca de un nodo intermedio, curvarla para que nunca lo atraviese
			for other_nid in node_positions.keys():
				if other_nid != e.from_id and other_nid != e.to_id:
					var inter_pos: Vector2 = node_positions[other_nid] as Vector2
					var closest: Vector2 = Geometry2D.get_closest_point_to_segment(inter_pos, from_pos, to_pos)
					if closest.distance_to(inter_pos) < 38.0 and from_pos.distance_to(to_pos) > 80.0:
						var offset_vec := inter_pos - closest
						var cross_prod := dir.x * offset_vec.y - dir.y * offset_vec.x
						bend = -45.0 if cross_prod >= 0.0 else 45.0
						break

		var puntos: PackedVector2Array = PackedVector2Array()
		if absf(bend) < 0.5:
			puntos.append(inicio)
			puntos.append(tip)
		else:
			var ctrl: Vector2 = centro + perp * bend * 2.0
			for s in range(15):
				var t := s / 14.0
				puntos.append(inicio.lerp(ctrl, t).lerp(ctrl.lerp(tip, t), t))

		draw_polyline(puntos, edge_color, line_width)

		# VFX: Pulso de fotones de datos viajando a lo largo de aristas activas no bloqueadas
		if not is_blocked and not game_over and puntos.size() >= 2:
			var time_sec: float = Time.get_ticks_msec() * 0.001
			var speed_mod: float = 0.85
			var photon_t: float = fmod((time_sec * speed_mod) + (float(hash(edge_key) % 100) * 0.01), 1.0)
			var photon_pos: Vector2 = puntos[0].lerp(puntos[puntos.size() - 1], photon_t)
			if absf(bend) >= 0.5:
				var ctrl: Vector2 = centro + perp * bend * 2.0
				photon_pos = inicio.lerp(ctrl, photon_t).lerp(ctrl.lerp(tip, photon_t), photon_t)
			var photon_col := Color("ffffff") if (in_path or in_enemy_path) else edge_color.lightened(0.4)
			draw_circle(photon_pos, 2.2, photon_col)
			draw_circle(photon_pos, 4.0, BrandClass.with_alpha(photon_col, 0.35), false, 1.0)

		if is_blocked:
			# Chispas de desconexión perimetral alrededor del bloqueo
			var time_sec: float = Time.get_ticks_msec() * 0.001
			for sp_i in range(3):
				var sp_angle := time_sec * 3.0 + float(sp_i) * (TAU / 3.0)
				var spark_pos := centro + Vector2(cos(sp_angle), sin(sp_angle)) * 17.0
				draw_circle(spark_pos, 1.5, Color(1.0, 0.4, 0.2, 0.8))

			draw_circle(centro, 14.0, Color(0.15, 0.05, 0.05, 0.8))
			draw_circle(centro, 14.0, Color(1.0, 0.2, 0.2, 0.9), false, 2.0)
			draw_string(centro + Vector2(-5, 5), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.3, 0.3, 1.0))
			# TAREA 3: Mostrar duración restante del bloqueo
			var block_data: Dictionary = blocked_edges.get(edge_key, {})
			if block_data.has("expires_at") and not block_data.get("locked", false):
				var remaining: int = int(block_data["expires_at"]) - current_turn
				if remaining > 0 and remaining < 1000:

					var dur_color: Color
					if remaining >= 4:
						dur_color = Color(0.0, 1.0, 0.5)  # verde
					elif remaining >= 2:
						dur_color = BrandClass.WARNING  # amarillo
					else:
						dur_color = BrandClass.DANGER  # rojo
					var dur_label: String = "%dt" % remaining
					draw_string(centro + Vector2(18, 5), dur_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, dur_color)
		else:
			# Punta de flecha sólida (triángulo) — la dirección se lee de un vistazo.
			var tangente: Vector2 = (
				(puntos[puntos.size() - 1] - puntos[puntos.size() - 2]).normalized()
				if puntos.size() >= 2
				else dir
			)
			var perp_t: Vector2 = tangente.rotated(PI / 2.0)
			var base_f: Vector2 = tip - tangente * 13.0
			draw_polygon(
				PackedVector2Array([
					tip,
					base_f + perp_t * 6.0,
					base_f - perp_t * 6.0,
				]),
				edge_color
			)

			var show_badge: bool = false
			if (player_pos != &"" and player_pos != "") and (e.from_id == player_pos or e.to_id == player_pos or String(e.from_id) == String(player_pos) or String(e.to_id) == String(player_pos)):
				show_badge = true
			elif (selected_neighbor != &"" and selected_neighbor != "") and (e.from_id == selected_neighbor or e.to_id == selected_neighbor or String(e.from_id) == String(selected_neighbor) or String(e.to_id) == String(selected_neighbor)):
				show_badge = true
			elif hovered_edge != "" and hovered_edge == edge_key:
				show_badge = true
			elif in_path or in_enemy_path:
				show_badge = true
			elif String(e.protocol) != "" and String(e.protocol) != "TCP":
				show_badge = true

			if show_badge:
				var apex: Vector2 = (
					inicio.lerp(centro + perp * bend * 2.0, 0.5).lerp(
						(centro + perp * bend * 2.0).lerp(tip, 0.5), 0.5)
					if absf(bend) >= 0.5
					else centro
				)
				# Anti-colisión: omitir etiqueta de protocolo si el punto medio está a menos de 48px de cualquier nodo
				var too_close := false
				for np in node_positions.values():
					if (np as Vector2).distance_to(apex) < 48.0:
						too_close = true
						break
				if not too_close:
					var label_bg: Color = BrandClass.PANEL_SOLID
					var label_text: String = str(e.protocol)
					var text_w: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x
					var label_pos: Vector2 = apex + Vector2(-text_w / 2.0, -12.0)
					draw_rect(Rect2(label_pos.x - 4, label_pos.y - 12, text_w + 8, 16), label_bg)
					draw_rect(Rect2(label_pos.x - 4, label_pos.y - 12, text_w + 8, 16), Color(edge_color.r, edge_color.g, edge_color.b, 0.5), false, 1.0)
					draw_string(label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.85, 0.88, 0.95, 0.95))


## Polígono regular centrado en `centro` (identidad visual de nodos, E2).
static func _poligono(centro: Vector2, radio: float, lados: int, rot: float = 0.0) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in lados:
		var a := rot + TAU * i / lados - PI / 2.0
		pts.append(centro + Vector2(cos(a), sin(a)) * radio)
	return pts


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
	_enemy_move_flash_time: float = -1.0,
	bonus_nodes: Array = [],
	bonus_visitados: Array = [],
	hidden_nodes: Array = [],
	player_visual_pos: Vector2 = Vector2.ZERO,
	is_moving: bool = false,
	defender_mode: bool = false,
	brain_enemy_pos: StringName = &"",
	quarantined_nodes: Dictionary = {},
	quarantine_mode_active: bool = false,
	enemy_start_node: StringName = &"",
	enemy_target_node: StringName = &"",
	is_secret_sector: bool = false
) -> void:
	# Identidad por tipo (E2): forma geométrica según NodeType.
	# INTERNET=doble anillo · FIREWALL=triángulo · ROUTER=círculo ·
	# SERVER=hexágono · WORKSTATION=cuadrado · DATABASE=rombo.
	var nodos_res: Dictionary = {}
	for n in graph.nodes:
		if n != null:
			nodos_res[n.id] = n

	for nid in node_positions.keys():
		var nid_str: StringName = nid as StringName
		if hidden_nodes.has(nid_str) or hidden_nodes.has(String(nid_str)):
			continue
		var pos: Vector2 = node_positions[nid] as Vector2

		var is_player: bool = nid_str == player_pos and not is_moving
		var is_dest: bool = nid_str == player_pos and is_moving
		var is_target: bool = nid_str == target
		var es_vecino: bool = nid_str in neighbors
		var in_path: bool = nid_str in current_path
		var is_bonus: bool = (nid_str in bonus_nodes) or (String(nid_str) in bonus_nodes)
		var bonus_ya_visitado: bool = (nid_str in bonus_visitados) or (String(nid_str) in bonus_visitados)
		var is_golden: bool = is_bonus and not bonus_ya_visitado

		var node_color: Color
		if is_player:
			node_color = Color(0.0, 0.7, 1.0)
		elif is_dest:
			node_color = Color(0.12, 0.35, 0.45, 0.9)
		elif is_target:
			node_color = Color(1.0, 0.15, 0.15)
		elif is_golden:
			node_color = Color(1.0, 0.82, 0.0)
		elif es_vecino and not game_over:
			node_color = Color(0.1, 0.85, 0.2)
		else:
			node_color = Color(0.2, 0.22, 0.3, 0.85)

		var radius: float = node_radius
		if is_player:
			radius += 6.0
		elif is_dest:
			radius += 4.0
		elif is_target or es_vecino or is_golden:
			radius += 3.0

		var node_res = nodos_res.get(nid_str, null)
		var tipo: int = int(node_res.node_type) if node_res != null else 3
		var forma: PackedVector2Array
		var es_circulo := false
		match tipo:
			1:
				forma = _poligono(pos, radius + 2.0, 3)
			3:
				forma = _poligono(pos, radius, 6)
			4:
				forma = _poligono(pos, radius, 4, PI / 4.0)
			5:
				forma = _poligono(pos, radius, 4)
			_:
				es_circulo = true

		if is_golden:
			var g_pulse: float = 0.5 + sin(Time.get_ticks_msec() * 0.007) * 0.3
			draw_circle(pos, radius + 6.0, Color(1.0, 0.82, 0.0, g_pulse * 0.45), false, 2.5)
			draw_circle(pos, radius + 11.0, Color(1.0, 0.82, 0.0, g_pulse * 0.2), false, 1.5)

		# Sector 0 Glitch Node: Anillos de energía en contrarrotación si es un nodo de secret_root
		if nid_str.begins_with("HexNode_") or nid_str == &"GenesisCore" or nid_str == &"RootBastion":
			var t_sec := Time.get_ticks_msec() * 0.001
			var rot1 := t_sec * 1.5
			var rot2 := -t_sec * 2.2
			var oct1 := _poligono(pos, radius + 7.0, 8, rot1)
			var oct2 := _poligono(pos, radius + 12.0, 8, rot2)
			oct1.append(oct1[0]); oct2.append(oct2[0])
			draw_polyline(oct1, Color(1.0, 0.2, 0.4, 0.45), 1.2)
			draw_polyline(oct2, Color(1.0, 0.7, 0.0, 0.30), 1.0)

		# Sombra con la MISMA silueta de la forma (un círculo genérico asomaba
		# detrás del triángulo/cuadrado/rombo como aureola redonda).
		if es_circulo:
			draw_circle(pos + Vector2(2, 3), radius, Color(0, 0, 0, 0.4))
		else:
			var sombra: PackedVector2Array = PackedVector2Array()
			for p in forma:
				sombra.append(p + Vector2(2, 3))
			draw_polygon(sombra, Color(0, 0, 0, 0.4))

		if es_circulo:
			draw_circle(pos, radius, node_color)
		else:
			draw_polygon(forma, node_color)

		var border_color: Color = Color(0.3, 0.32, 0.4)
		if is_player:
			border_color = Color(0.0, 0.9, 1.0)
		elif is_dest:
			border_color = Color(0.0, 0.95, 1.0, 0.85)
		elif is_target:
			border_color = BrandClass.DANGER
		elif is_golden:
			border_color = Color(1.0, 0.95, 0.3)
		elif es_vecino:
			border_color = Color(0.3, 1.0, 0.4)


		if tipo == 0:
			# INTERNET: doble anillo (puerta al exterior).
			draw_circle(pos, radius, border_color, false, 2.5)
			draw_circle(pos, radius - 5.0, BrandClass.accent_dim(0.4), false, 1.5)
		elif tipo == 3 or tipo == 2:
			draw_circle(pos, radius, border_color, false, 2.5)
		else:
			var borde := forma.duplicate()
			borde.append(borde[0])
			draw_polyline(borde, border_color, 2.5)

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
			# Dual-ring tactical cyber reticle
			draw_circle(pos, radius + 7.0, Color(0.0, 0.95, 1.0, sel_pulse * 0.8), false, 2.5)
			draw_circle(pos, radius + 3.5, Color(1.0, 0.85, 0.2, sel_pulse * 0.5), false, 1.5)
			# 4 corner framing brackets
			var b_offset: float = radius + 9.0
			var b_arm: float = 6.0
			var bracket_color: Color = Color(0.0, 0.95, 1.0, clampf(sel_pulse * 0.9, 0.0, 1.0))
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var corner: Vector2 = pos + Vector2(sx * b_offset, sy * b_offset)
					draw_line(corner, corner + Vector2(-sx * b_arm, 0.0), bracket_color, 1.5)
					draw_line(corner, corner + Vector2(0.0, -sy * b_arm), bracket_color, 1.5)

		var label_bg_color: Color = Color(0.03, 0.03, 0.07, 0.9)
		var label_text: String = str(nid_str)
		if node_res != null and String(node_res.display_name) != "":
			label_text = node_res.display_name

		# Sector 0 Triad Daemon branch accenting
		if is_secret_sector:
			var s_nid := String(nid_str)
			if ["NexusA", "HexNode_4", "VoidTrap"].has(s_nid):
				border_color = Color("#bf5af2")
			elif ["NexusB", "HexNode_5", "GenesisAntechamber"].has(s_nid):
				border_color = Color("#00d2ff")
			elif ["HexNode_1", "HexNode_2", "HexNode_3", "RootBastion"].has(s_nid):
				border_color = Color("#39ff88")

		if nid_str == selected_neighbor and not game_over:
			var sel_pulse: float = 0.6 + sin(Time.get_ticks_msec() * 0.006) * 0.3
			# Dual-ring tactical cyber reticle
			draw_circle(pos, radius + 7.0, Color(0.0, 0.95, 1.0, sel_pulse * 0.8), false, 2.5)
			draw_circle(pos, radius + 3.5, Color(1.0, 0.85, 0.2, sel_pulse * 0.5), false, 1.5)
			# 4 corner framing brackets
			var b_offset: float = radius + 9.0
			var b_arm: float = 6.0
			var bracket_color: Color = Color(0.0, 0.95, 1.0, clampf(sel_pulse * 0.9, 0.0, 1.0))
			for sx in [-1.0, 1.0]:
				for sy in [-1.0, 1.0]:
					var corner: Vector2 = pos + Vector2(sx * b_offset, sy * b_offset)
					draw_line(corner, corner + Vector2(-sx * b_arm, 0.0), bracket_color, 1.5)
					draw_line(corner, corner + Vector2(0.0, -sy * b_arm), bracket_color, 1.5)

			# Merge cost delta cleanly into unified neighbor top label pill (Artboard 03)
			var transit_cost: float = 0.0
			if graph != null and graph.edges != null:
				for ed in graph.edges:
					if ed != null and ((ed.from_id == player_pos and ed.to_id == selected_neighbor) or (ed.to_id == player_pos and ed.from_id == selected_neighbor)):
						transit_cost = ed.transit_cost
						break
			if transit_cost > 0.0:
				var base_name: String = node_res.display_name if (node_res != null and String(node_res.display_name) != "") else str(nid_str)
				label_text = "%s · Δ %.1f" % [base_name, transit_cost]
				border_color = BrandClass.ACCENT

		# Sector 0 Climax Boss Node: Genesis Root Core (counter-rotating octagons)
		if is_secret_sector and (nid_str == &"GenesisCore" or nid_str == "GenesisCore"):
			var time_sec: float = Time.get_ticks_msec() * 0.001
			var poly_outer := _poligono(pos, 38.0, 8, time_sec * 0.35)
			var poly_inner := _poligono(pos, 26.0, 8, -time_sec * 0.50)
			draw_polyline(poly_outer, Color(1.0, 0.16, 0.42, 0.9), 2.2)
			draw_polyline(poly_inner, Color(1.0, 0.78, 0.34, 0.85), 1.8)
			draw_circle(pos, 16.0, Color(1.0, 0.16, 0.42, 0.45))

		var text_w: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var label_x: float = pos.x - text_w / 2.0
		var label_y: float = pos.y - radius - 8.0
		draw_rect(Rect2(label_x - 4, label_y - 14, text_w + 8, 18), label_bg_color)
		draw_rect(Rect2(label_x - 4, label_y - 14, text_w + 8, 18), border_color, false, 1.0)
		draw_string(Vector2(label_x, label_y), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

		if defender_mode:
			if nid_str == brain_enemy_pos:
				draw_string(Vector2(pos.x - 22, pos.y + radius + 16), "ATACANTE", HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(1.0, 0.3, 0.2))
			elif is_target:
				draw_string(Vector2(pos.x - 18, pos.y + radius + 16), "NÚCLEO", HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, BrandClass.ACCENT)
		else:
			if is_player and not is_moving:
				draw_string(Vector2(pos.x - 8, pos.y + radius + 16), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(0.0, 0.9, 1.0))
			elif is_target:
				draw_string(Vector2(pos.x - 18, pos.y + radius + 16), "TARGET", HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, BrandClass.DANGER)
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
					scan_color = BrandClass.WARNING
				"decoy":
					scan_color = BrandClass.DANGER
				_:
					scan_color = BrandClass.TEXT_DIM
			draw_circle(pos, radius + 12.0, scan_color, false, 2.0)
			draw_string(Vector2(pos.x + radius + 4, pos.y - radius + 2), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, scan_color)

		# Waypoint indicator
		if waypoints.has(nid_str):
			var wp_idx: int = waypoints.find(nid_str)
			if wp_idx >= current_waypoint_idx:
				var wp_color: Color = BrandClass.WARNING if wp_idx == current_waypoint_idx else Color(0.6, 0.55, 0.3, 0.7)
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
			# Icono de firewall
			draw_string(Vector2(pos.x - 7, pos.y + 5), "FW", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.3, 0.8, 1.0))

		# Quarantined node indicator (Fase 2 Blue Team)
		if quarantined_nodes.has(nid_str):
			var q_color: Color = Color(1.0, 0.7, 0.0, 0.9)
			draw_rect(Rect2(pos.x - radius - 6.0, pos.y - radius - 6.0, (radius + 6.0) * 2.0, (radius + 6.0) * 2.0), q_color, false, 2.0)
			draw_string(Vector2(pos.x - 14, pos.y + 4), "AISLADO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, q_color)
		elif defender_mode and quarantine_mode_active and not game_over:
			# Halo ámbar/dorado en los nodos que sí se pueden aislar
			if nid_str != enemy_start_node and nid_str != enemy_target_node:
				var q_pulse: float = 0.5 + sin(Time.get_ticks_msec() * 0.006) * 0.3
				draw_circle(pos, radius + 8.0, Color(1.0, 0.75, 0.0, q_pulse * 0.5), false, 2.0)
				draw_circle(pos, radius + 13.0, Color(1.0, 0.75, 0.0, q_pulse * 0.25), false, 1.0)
				draw_string(Vector2(pos.x - 6, pos.y - radius - 4), "☣", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, Color(1.0, 0.85, 0.2))

		# Bonus node marker (E3): rombo pequeño flotando arriba-izquierda —
		# WARNING mientras pendiente, TEXT_DIM cuando ya fue visitado.
		if nid_str in bonus_nodes:
			var bonus_color: Color = BrandClass.TEXT_DIM if nid_str in bonus_visitados else BrandClass.WARNING
			draw_polygon(_poligono(pos + Vector2(-(radius + 12.0), -(radius + 12.0)), 6.0, 4), bonus_color)

	# Token visual del jugador interpolado (movimiento fluido) — omitido en modo defensor
	if not defender_mode:
		var ppos: Vector2 = player_visual_pos if player_visual_pos != Vector2.ZERO else (node_positions.get(player_pos, Vector2.ZERO) as Vector2)
		if ppos != Vector2.ZERO and not game_over and player_pos != &"":
			var pulse: float = 0.6 + sin(Time.get_ticks_msec() * 0.007) * 0.25
			# Anillo de energía exterior
			var ring_r: float = (node_radius + 6.0) if is_moving else (node_radius + 4.0)
			var ring_alpha: float = 0.9 if is_moving else (pulse * 0.6)
			draw_circle(ppos, ring_r, Color(0.0, 0.95, 1.0, ring_alpha), false, 2.5 if is_moving else 2.0)
			if is_moving:
				draw_circle(ppos, node_radius + 11.0, Color(0.0, 0.8, 1.0, 0.4), false, 1.5)
			# Núcleo del avatar
			draw_circle(ppos, 8.0 if is_moving else 7.0, Color(0.0, 1.0, 1.0, 0.95))
			draw_circle(ppos, 4.0 if is_moving else 3.5, Color.WHITE)
			draw_string(Vector2(ppos.x - 8, ppos.y + node_radius + 16), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(0.0, 0.9, 1.0))
	else:
		# En modo defensor, dibujamos el token táctico del atacante hostil en su posición actual o interpolada
		var epos: Vector2 = player_visual_pos if player_visual_pos != Vector2.ZERO else (node_positions.get(brain_enemy_pos, Vector2.ZERO) as Vector2)
		if epos != Vector2.ZERO and not game_over and brain_enemy_pos != &"":
			var e_pulse: float = 0.6 + sin(Time.get_ticks_msec() * 0.008) * 0.3
			draw_circle(epos, node_radius + 6.0, Color(1.0, 0.2, 0.1, e_pulse * 0.7), false, 2.5)
			draw_circle(epos, node_radius + 10.0, Color(1.0, 0.2, 0.1, e_pulse * 0.3), false, 1.5)
			draw_circle(epos, 6.0, Color(1.0, 0.2, 0.1, 0.95))


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


func draw_node_info_panel(
	vp_size: Vector2,
	selected_neighbor: StringName,
	player_pos: StringName,
	graph: NetworkGraphResource,
	node_cache: Dictionary,
	is_secret: bool = false
) -> void:
	# P5/tarea 3: datos en lugar de callable — el cache {id: NodeResource}
	# poblado en GameState.load_graph() reemplaza a find_node_res_func.
	var node_res = node_cache.get(selected_neighbor)
	if node_res == null:
		return

	var panel_w: float = 232.0
	var panel_h: float = 148.0
	var panel_x: float = vp_size.x - 245.0
	var panel_y: float = 82.0
	var panel_rect: Rect2 = Rect2(panel_x, panel_y, panel_w, panel_h)

	draw_rect(panel_rect, Color(0.04, 0.05, 0.09, 0.94))
	draw_rect(panel_rect, BrandClass.PANEL_BORDER, false, 1.0)
	draw_line(Vector2(panel_x, panel_y), Vector2(panel_x + panel_w, panel_y), BrandClass.SUCCESS, 2.0)

	var px: float = panel_x + 12.0
	var py: float = panel_y + 18.0
	var line_h: float = 17.0

	var display_title: String = resolve_node_display_name(selected_neighbor, node_cache)
	draw_string(Vector2(px, py), display_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)

	var id_tag: String = "#%s" % str(selected_neighbor)
	var tag_sz := font.get_string_size(id_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4).x
	draw_string(Vector2(panel_x + panel_w - tag_sz - 12.0, py), id_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)
	py += line_h + 2.0

	var meta: Dictionary = node_res.metadata
	var edge_cost: float = 0.0
	var deg: int = 0
	if graph != null and graph.edges != null:
		for e in graph.edges:
			if e != null:
				if (e.from_id == player_pos and e.to_id == selected_neighbor) or (e.to_id == player_pos and e.from_id == selected_neighbor):
					edge_cost = e.transit_cost
				if e.from_id == selected_neighbor or e.to_id == selected_neighbor:
					deg += 1

	# Coste de Salto
	draw_string(Vector2(px, py), "Coste de Salto:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	draw_string(Vector2(px + 120, py), "%.1f" % edge_cost, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color.WHITE)
	py += line_h

	# Centralidad deg(v)
	draw_string(Vector2(px, py), "Centralidad deg(v):", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	draw_string(Vector2(px + 140, py), "%d" % deg, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
	py += line_h

	# Latencia BGP simulada
	var latency: int = 8 + (deg * 4) % 15
	draw_string(Vector2(px, py), "Latencia BGP:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	draw_string(Vector2(px + 120, py), "%d ms" % latency, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.7, 0.85, 1.0))
	py += line_h

	# Alerta IDS
	var detect: float = meta.get("detection_chance", 0.0)
	var det_label: String = "%.0f%%" % (detect * 100.0)
	var det_color: Color = Color(0.0, 1.0, 0.5) if detect <= 0.0 else (Color(1.0, 0.8, 0.0) if detect < 0.3 else BrandClass.DANGER)
	draw_string(Vector2(px, py), "Alerta IDS:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	draw_string(Vector2(px + 120, py), det_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, det_color)
	py += line_h

	if meta.has("label"):
		draw_string(Vector2(px, py), str(meta["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.6, 0.65, 0.75))
		py += line_h

	if meta.get("has_firewall", false):
		draw_rect(Rect2(px - 2, py - 10, 70, 14), Color(0.0, 0.5, 0.8, 0.3))
		draw_string(Vector2(px, py), "FIREWALL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.0, 0.8, 1.0))
		py += line_h

	if meta.get("security_spawn", false):
		draw_rect(Rect2(px - 2, py - 10, 100, 14), Color(0.8, 0.3, 0.0, 0.3))
		draw_string(Vector2(px, py), "SPAWN SEGURIDAD", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(1.0, 0.5, 0.0))
		py += line_h

	# En Sector 0: segunda tarjeta compacta con la TRÍADA GENESIS (Artboard 03)
	if is_secret:
		var triad_y: float = panel_y + panel_h + 10.0
		var triad_h: float = 84.0
		var triad_rect := Rect2(panel_x, triad_y, panel_w, triad_h)
		draw_rect(triad_rect, Color(0.04, 0.04, 0.08, 0.95))
		draw_rect(triad_rect, BrandClass.PANEL_BORDER, false, 1.0)
		draw_line(Vector2(panel_x, triad_y), Vector2(panel_x + panel_w, triad_y), BrandClass.WORLD_SECRET, 2.0)

		var ty: float = triad_y + 16.0
		draw_string(Vector2(px, ty), "TRÍADA GENESIS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.WORLD_SECRET)
		ty += 18.0
		draw_string(Vector2(px, ty), "● DAEMON: EXFIL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, Color("#bf5af2"))
		draw_string(Vector2(panel_x + panel_w - 70.0, ty), "ACTIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)
		ty += 16.0
		draw_string(Vector2(px, ty), "● DAEMON: FUZZ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, Color("#39ff88"))
		draw_string(Vector2(panel_x + panel_w - 70.0, ty), "PIVOT", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)
		ty += 16.0
		draw_string(Vector2(px, ty), "● DAEMON: CORDON", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, Color("#00d2ff"))
		draw_string(Vector2(panel_x + panel_w - 70.0, ty), "ARMADO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)


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
		# Retículo y flecha en el centro de la arista
		var mid: Vector2 = (from_pos + to_pos) / 2.0
		_draw_target_reticle_and_arrow(mid, "▼ ARISTA", "TAP / CLICK AQUÍ", color)

	# Si es un paso de acción con nodos destacados, retículo y flecha direccional inequívocos
	for nid in highlight_nodes:
		if node_positions.has(nid):
			var pos: Vector2 = node_positions[nid] as Vector2
			var col: Color = Color(0.3, 1.0, 0.6) if is_action_step else Color(0.0, 0.9, 1.0)
			_draw_target_reticle_and_arrow(pos, "▼ OBJETIVO", "TAP / CLICK AQUÍ", col)


func draw_tutorial_text(mensaje_tutorial: String) -> void:
	# Placa de fondo (Capa 1): el texto del tutorial pisa el tablero — sin
	# placa es ilegible sobre aristas/nodos claros.
	var lines: PackedStringArray = mensaje_tutorial.split("\n")
	var max_w: float = 0.0
	for line in lines:
		max_w = maxf(max_w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x)
	var plate_h: float = lines.size() * 16.0 + 10.0
	draw_rect(Rect2(14, 80 - small_font_size + 2, max_w + 16, plate_h), BrandClass.PANEL)
	draw_rect(Rect2(14, 80 - small_font_size + 2, max_w + 16, plate_h), BrandClass.accent_dim(0.25), false, 1.0)
	var py: float = 80.0
	for line in lines:
		draw_string(Vector2(20, py), line, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.WARNING)
		py += 16


func draw_status_bar(
	vp_size: Vector2,
	mensaje_estado: String,
	selected_neighbor: StringName,
	game_over: bool,
	game_won: bool,
	defender_mode: bool = false
) -> void:
	# Wrapper para mantener compatibilidad si se invoca directamente
	var d := {
		"vp_size": vp_size,
		"mensaje_estado": mensaje_estado,
		"selected_neighbor": selected_neighbor,
		"game_over": game_over,
		"game_won": game_won,
		"defender_mode": defender_mode,
		"hacker_mode": false,
		"movement_points": 0,
	}
	draw_tactical_action_dock(d)


## Dock Táctico Inferior Unificado (Touch + Mouse + Teclado)
func draw_tactical_action_dock(d: Dictionary) -> void:
	var vp_size: Vector2 = d.get("vp_size", Vector2(1280, 720))
	var bar_h: float = 52.0
	var bar_y: float = vp_size.y - bar_h

	# Fondo del dock táctico
	draw_rect(Rect2(0, bar_y, vp_size.x, bar_h), Color(0.02, 0.03, 0.07, 0.95))
	draw_rect(Rect2(0, bar_y, vp_size.x, 1.5), BrandClass.accent_dim(0.35))

	# 1. Controles táctiles de cámara y pausa en la esquina derecha
	var c_y := bar_y + 6.0
	var c_h := 40.0
	_draw_dock_button(Rect2(vp_size.x - 240.0, c_y, 75.0, c_h), "[⟲ CENTRAR]", Color(0.3, 0.7, 0.9))
	_draw_dock_button(Rect2(vp_size.x - 160.0, c_y, 40.0, c_h), "[-]", Color(0.3, 0.7, 0.9))
	_draw_dock_button(Rect2(vp_size.x - 115.0, c_y, 40.0, c_h), "[+]", Color(0.3, 0.7, 0.9))
	_draw_dock_button(Rect2(vp_size.x - 70.0, c_y, 56.0, c_h), "[⏸]", BrandClass.WARNING)

	# 2. Modo Hacker: Barra táctica de Exploits y Scan (min height 42px)
	if d.get("hacker_mode", false) and not d.get("game_over", false):
		var hs: Dictionary = d.get("hacker_state", {})
		var exps: Dictionary = hs.get("exploits", {})
		var byp_cnt: int = exps.get("bypass", 0)
		var esc_cnt: int = exps.get("escalate", 0)
		var per_cnt: int = exps.get("persist", 0)
		var dec_cnt: int = exps.get("decoy", 0)

		var h_y := bar_y + 5.0
		var h_h := 42.0

		_draw_dock_button(Rect2(16.0, h_y, 95.0, h_h), "[X] SCAN", BrandClass.SUCCESS, true)
		_draw_dock_button(Rect2(116.0, h_y, 110.0, h_h), "[1] BYPASS x%d" % byp_cnt, BrandClass.ACCENT if byp_cnt > 0 else BrandClass.TEXT_DIM, byp_cnt > 0)
		_draw_dock_button(Rect2(231.0, h_y, 120.0, h_h), "[2] ESCALATE x%d" % esc_cnt, Color(0.4, 0.7, 1.0) if esc_cnt > 0 else BrandClass.TEXT_DIM, esc_cnt > 0)
		_draw_dock_button(Rect2(356.0, h_y, 115.0, h_h), "[3] PERSIST x%d" % per_cnt, Color(0.9, 0.5, 1.0) if per_cnt > 0 else BrandClass.TEXT_DIM, per_cnt > 0)
		_draw_dock_button(Rect2(476.0, h_y, 130.0, h_h), "[4] HONEYPOT x%d" % dec_cnt, Color(1.0, 0.75, 0.0) if dec_cnt > 0 else BrandClass.TEXT_DIM, dec_cnt > 0)

	# 3. Modo Heist / Atacante: Botón prominente de confirmar movimiento
	elif not d.get("defender_mode", false) and not d.get("game_over", false):
		var sel_n: StringName = d.get("selected_neighbor", &"")
		if sel_n != &"":
			var m_btn := Rect2((vp_size.x - 280.0) / 2.0, bar_y + 5.0, 280.0, 42.0)
			var pulse := 0.6 + sin(Time.get_ticks_msec() * 0.008) * 0.35
			draw_rect(m_btn, Color(0.0, 0.35, 0.25, 0.95))
			draw_rect(m_btn, Color(0.0, 1.0, 0.6, pulse), false, 2.0)
			draw_rect(m_btn.grow(2.0), Color(0.0, 1.0, 0.6, pulse * 0.35), false, 1.2)
			var m_txt := "⏭ CONFIRMAR: %s" % str(sel_n)
			var m_sz := font.get_string_size(m_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1)
			draw_string(Vector2(m_btn.position.x + (m_btn.size.x - m_sz.x) / 2.0, m_btn.position.y + 26.0), m_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, Color.WHITE)

		var kb_text := "[Flechas] Sel  [Enter/Clic] Mover  [P] Ruta"
		draw_string(Vector2(16, bar_y + 30.0), kb_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	# 4. Modo Defensor
	elif d.get("defender_mode", false):
		var d_text := "[~] CLI  [1..3] Herramientas  [WASD/Drag] Cámara"
		draw_string(Vector2(16, bar_y + 30.0), d_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)


func _draw_dock_button(rect: Rect2, text: String, color: Color, active: bool = false) -> void:
	var bg_col := BrandClass.with_alpha(color, 0.22 if active else 0.08)
	var border_col := BrandClass.with_alpha(color, 0.85 if active else 0.35)
	draw_rect(rect, bg_col)
	draw_rect(rect, border_col, false, 1.5 if active else 1.0)
	var t_sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3)
	var t_pos := Vector2(rect.position.x + (rect.size.x - t_sz.x) / 2.0, rect.position.y + 25.0)
	draw_string(t_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, color if active else BrandClass.TEXT_DIM)


## Menú contextual de nodo en modo Defensor (Blue Team)
func draw_defender_contextual_menu(vp_size: Vector2, context_node: StringName, node_positions: Dictionary, pan: Vector2, zoom: float) -> void:
	if context_node == &"" or not node_positions.has(context_node):
		return
	var npos: Vector2 = node_positions[context_node] as Vector2
	var screen_pos: Vector2 = npos * zoom + pan

	var pill_w: float = 270.0
	var pill_h: float = 46.0
	var menu_rect := Rect2(screen_pos.x - pill_w / 2.0, screen_pos.y - 60.0, pill_w, pill_h)

	# Fondo translúcido sci-fi
	draw_rect(menu_rect, Color(0.02, 0.04, 0.09, 0.94))
	draw_rect(menu_rect, Color(0.2, 0.7, 1.0, 0.85), false, 1.5)

	# Botón 1: FIREWALL
	var btn_fw := Rect2(menu_rect.position.x + 8.0, menu_rect.position.y + 5.0, 105.0, 36.0)
	draw_rect(btn_fw, Color(0.1, 0.3, 0.6, 0.6))
	draw_rect(btn_fw, Color(0.2, 0.7, 1.0, 0.9), false, 1.2)
	draw_string(Vector2(btn_fw.position.x + 10.0, btn_fw.position.y + 23.0), "[2] FIREWALL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color.WHITE)

	# Botón 2: CUARENTENA
	var btn_q := Rect2(menu_rect.position.x + 120.0, menu_rect.position.y + 5.0, 110.0, 36.0)
	draw_rect(btn_q, Color(0.5, 0.35, 0.05, 0.6))
	draw_rect(btn_q, Color(1.0, 0.75, 0.0, 0.9), false, 1.2)
	draw_string(Vector2(btn_q.position.x + 8.0, btn_q.position.y + 23.0), "[3] CUARENTENA", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color.WHITE)

	# Botón 3: CERRAR
	var btn_close := Rect2(menu_rect.position.x + 236.0, menu_rect.position.y + 5.0, 26.0, 36.0)
	draw_rect(btn_close, Color(0.3, 0.1, 0.1, 0.5))
	draw_rect(btn_close, Color(1.0, 0.3, 0.3, 0.8), false, 1.0)
	draw_string(Vector2(btn_close.position.x + 8.0, btn_close.position.y + 23.0), "✕", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color.WHITE)


## Previsualización predictiva en hover / touch sobre nodo adyacente o arista
func draw_predictive_hover_preview(d: Dictionary) -> void:
	if d.get("game_over", false):
		return

	# Modo Atacante: el coste ya está integrado en la píldora superior del nodo vecino
	# (Celda Alfa · Δ 1.0) para garantizar cero superposición.
	# Modo Defensor: Preview sobre arista hovered
	if d.get("defender_mode", false):
		var h_edge: String = d.get("brain_hovered_edge", "")
		if h_edge != "":
			var parts := h_edge.split("→")
			if parts.size() == 2 and d.node_positions.has(parts[0]) and d.node_positions.has(parts[1]):
				var pA: Vector2 = d.node_positions[parts[0]] as Vector2
				var pB: Vector2 = d.node_positions[parts[1]] as Vector2
				var mid: Vector2 = (pA + pB) / 2.0
				var preview_text := "[ BLOQUEAR ARISTA (-1) ]"
				var badge_w := font.get_string_size(preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x + 16.0
				var badge_rect := Rect2(mid.x - badge_w / 2.0, mid.y - 14.0, badge_w, 22.0)
				draw_rect(badge_rect, Color(0.12, 0.04, 0.02, 0.92))
				draw_rect(badge_rect, Color(1.0, 0.4, 0.2, 0.9), false, 1.2)
				draw_string(Vector2(badge_rect.position.x + 8.0, badge_rect.position.y + 15.0), preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(1.0, 0.7, 0.4))


## Dibuja un retículo animado con halo pulsante y flecha direccional en coordenadas de topología
func _draw_target_reticle_and_arrow(pos: Vector2, label: String, sub_label: String, color: Color) -> void:
	var t: float = Time.get_ticks_msec() * 0.006
	var pulse: float = 0.55 + sin(t) * 0.35
	var r_outer: float = 34.0 + sin(t * 1.5) * 4.0
	var r_inner: float = 24.0

	# Anillos concéntricos
	draw_circle(pos, r_outer, Color(color.r, color.g, color.b, pulse * 0.25), false, 2.0)
	draw_circle(pos, r_inner, Color(color.r, color.g, color.b, pulse * 0.55), false, 2.5)

	# Brackets en 4 esquinas
	var b_sz: float = 28.0
	var b_arm: float = 8.0
	var b_col := Color(color.r, color.g, color.b, pulse * 0.9)
	draw_line(pos + Vector2(-b_sz, -b_sz), pos + Vector2(-b_sz + b_arm, -b_sz), b_col, 2.0)
	draw_line(pos + Vector2(-b_sz, -b_sz), pos + Vector2(-b_sz, -b_sz + b_arm), b_col, 2.0)
	draw_line(pos + Vector2(b_sz, -b_sz), pos + Vector2(b_sz - b_arm, -b_sz), b_col, 2.0)
	draw_line(pos + Vector2(b_sz, -b_sz), pos + Vector2(b_sz, -b_sz + b_arm), b_col, 2.0)
	draw_line(pos + Vector2(-b_sz, b_sz), pos + Vector2(-b_sz + b_arm, b_sz), b_col, 2.0)
	draw_line(pos + Vector2(-b_sz, b_sz), pos + Vector2(-b_sz, b_sz - b_arm), b_col, 2.0)
	draw_line(pos + Vector2(b_sz, b_sz), pos + Vector2(b_sz - b_arm, b_sz), b_col, 2.0)
	draw_line(pos + Vector2(b_sz, b_sz), pos + Vector2(b_sz, b_sz - b_arm), b_col, 2.0)

	# Flecha animada oscilante apuntando hacia abajo
	var bob: float = sin(t * 2.0) * 6.0
	var tip: Vector2 = pos + Vector2(0.0, -32.0 + bob)
	var base_l: Vector2 = pos + Vector2(-12.0, -48.0 + bob)
	var base_r: Vector2 = pos + Vector2(12.0, -48.0 + bob)
	draw_polygon(PackedVector2Array([tip, base_l, base_r]), Color(color.r, color.g, color.b, pulse * 0.95))

	# Badge con texto
	var badge_w: float = 135.0
	var badge_h: float = 32.0
	var badge_pos: Vector2 = pos + Vector2(-badge_w / 2.0, -82.0 + bob)
	draw_rect(Rect2(badge_pos, Vector2(badge_w, badge_h)), Color(0.03, 0.05, 0.1, 0.92))
	draw_rect(Rect2(badge_pos, Vector2(badge_w, badge_h)), Color(color.r, color.g, color.b, pulse * 0.8), false, 1.5)

	var l_sz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(Vector2(pos.x - l_sz.x / 2.0, badge_pos.y + 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	var s_sz := font.get_string_size(sub_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	draw_string(Vector2(pos.x - s_sz.x / 2.0, badge_pos.y + 27.0), sub_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)

## El game over (victoria/derrota) ya no se dibuja acá: lo lleva GameOverOverlay
## (capa 2b) a pantalla completa. draw_defender_game_over se eliminó al pasar
## TODO el contenido al overlay. frame_data() sigue exponiendo los campos.
