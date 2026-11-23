class_name GameRenderer extends RefCounted

const BrandClass = preload("res://juego/ui/brand.gd")
const DefensivePathfinderClass = preload("res://core/agents/defensive_pathfinder.gd")

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
	if font == null:
		return
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


static func get_top_perk_rects(
	vp_size: Vector2,
	mode: String,
	fog_of_war: bool = false,
	telemetry_intercepted: bool = false,
	p_font: Font = null,
	p_font_size: int = 14,
	hacker_state: Dictionary = {},
	extra_context: Dictionary = {}
) -> Array[Dictionary]:
	var pills_info: Array[Dictionary] = []
	if mode == "hacker" or mode == "secret":
		var exps: Dictionary = hacker_state.get("exploits", {}) if hacker_state.has("exploits") else hacker_state
		var byp_cnt: int = exps.get("bypass", 0)
		var esc_cnt: int = exps.get("escalate", 0)
		var per_cnt: int = exps.get("persist", 0)
		var dec_cnt: int = exps.get("decoy", 0)

		pills_info.append({"id": "scan", "text": "[X] SCAN", "color": BrandClass.SUCCESS, "is_action": true})
		pills_info.append({"id": "bypass", "text": "[1] BYPASS x%d" % byp_cnt, "color": BrandClass.ACCENT, "is_action": true})
		pills_info.append({"id": "escalate", "text": "[2] ESCALATE x%d" % esc_cnt, "color": Color(0.4, 0.7, 1.0), "is_action": true})
		pills_info.append({"id": "persist", "text": "[3] PERSIST x%d" % per_cnt, "color": Color(0.9, 0.5, 1.0), "is_action": true})
		pills_info.append({"id": "decoy", "text": "[4] HONEYPOT x%d" % dec_cnt, "color": Color(1.0, 0.75, 0.0), "is_action": true})
	elif mode == "defender":
		pills_info.append({"id": "edges", "text": "[1] SEGMENTAR ARISTA", "color": BrandClass.ACCENT, "is_action": true})
		pills_info.append({"id": "firewall", "text": "[2] FIREWALL", "color": Color(0.2, 0.7, 1.0), "is_action": true})
		pills_info.append({"id": "quarantine", "text": "[3] CUARENTENA", "color": Color(1.0, 0.75, 0.0), "is_action": true})
		var p_label := "REVELADO (2★)" if telemetry_intercepted else "[4] RADAR"
		pills_info.append({"id": "radar", "text": p_label, "color": BrandClass.WARNING if telemetry_intercepted else Color("80d8ff"), "is_action": true})
		var threat_hops: int = int(extra_context.get("threat_hops", 3))
		pills_info.append({"id": "soc_threat", "text": "[AMENAZA: %d SALTOS]" % threat_hops, "color": BrandClass.DANGER, "is_action": false})
	else:
		# Heist mode
		pills_info.append({"id": "tab_neighbor", "text": "[TAB] VECINO", "color": BrandClass.SUCCESS, "is_action": true})
		pills_info.append({"id": "optimal_route", "text": "[P] RUTA DIJKSTRA", "color": BrandClass.ACCENT, "is_action": true})
		var alert_str: String = str(extra_context.get("ids_alert", "0%"))
		var alert_num: float = float(extra_context.get("alert_num", 0.0))
		var alert_col: Color = BrandClass.SUCCESS if alert_num <= 0.0 else (BrandClass.WARNING if alert_num < 0.3 else BrandClass.DANGER)
		pills_info.append({"id": "ids_alert", "text": "[ALERTA IDS: %s]" % alert_str, "color": alert_col, "is_action": false})
		var hops: int = int(extra_context.get("hops_to_target", 3))
		pills_info.append({"id": "distance_target", "text": "[DISTANCIA: %d SALTOS]" % hops, "color": BrandClass.ACCENT, "is_action": false})

	var pill_h := 36.0
	var gap := 8.0
	var total_w := 0.0
	var widths: Array[float] = []

	for p in pills_info:
		var txt: String = p["text"]
		var tw: float = 70.0
		if p_font != null:
			tw = p_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, p_font_size - 3).x
		var w := tw + 20.0
		widths.append(w)
		total_w += w
	total_w += gap * float(maxi(0, pills_info.size() - 1))

	var safe_left := 445.0
	var safe_right := vp_size.x - 230.0
	var start_x := maxf(safe_left, safe_left + (safe_right - safe_left - total_w) * 0.5)
	var pill_y := 8.0

	var result: Array[Dictionary] = []
	var cur_x := start_x
	for i in range(pills_info.size()):
		var w := widths[i]
		var rect := Rect2(cur_x, pill_y, w, pill_h)
		result.append({
			"id": pills_info[i]["id"],
			"text": pills_info[i]["text"],
			"color": pills_info[i]["color"],
			"is_action": pills_info[i].get("is_action", true),
			"rect": rect
		})
		cur_x += w + gap

	return result


static func get_defender_pill_rects(
	vp_size: Vector2,
	p_font: Font,
	p_font_size: int,
	fog_of_war: bool = false,
	telemetry_intercepted: bool = false,
	extra_context: Dictionary = {}
) -> Array[Dictionary]:
	return get_top_perk_rects(vp_size, "defender", fog_of_war, telemetry_intercepted, p_font, p_font_size, {}, extra_context)


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

	var is_secret_sector: bool = str(d.get("level_key", "")).begins_with("secret") or d.get("world", "") == "secret" or str(d.get("titulo_nivel", "")).find("Sector 0") != -1 or d.node_positions.has(&"GenesisCore") or d.node_positions.has("GenesisCore")

	var mode: String = "heist"
	var mode_color := Color("#bf5af2")
	var bg_color := Color("#120918")

	if is_secret_sector:
		mode = "secret"
		mode_color = Color("#ff2a6d")
		bg_color = Color("#14080e")
	elif d.defender_mode:
		mode = "defender"
		mode_color = Color("#00d2ff")
		bg_color = Color("#081018")
	elif d.get("hacker_mode", false):
		mode = "hacker"
		mode_color = Color("#39ff88")
		bg_color = Color("#09120e")

	# BEFORE calling draw_set_transform: Full-Screen Mode Background in screen coordinates
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_fullscreen_mode_background(d.vp_size, mode, mode_color, bg_color, pan, zoom, is_secret_sector)

	# 1. Capa de topología: sujeta a pan y zoom
	if has_transform:
		_canvas.draw_set_transform(pan, 0.0, Vector2(zoom, zoom))

	# Anillos concéntricos de gravedad en torno al nodo meta en los 4 modos
	var target_node: StringName = d.brain_enemy_target if d.defender_mode else d.target
	if target_node == &"" and is_secret_sector:
		target_node = &"GenesisCore" if d.node_positions.has(&"GenesisCore") else &"HexNode_1"
	if d.node_positions.has(target_node):
		var target_pos: Vector2 = d.node_positions[target_node] as Vector2
		_draw_concentric_target_rings(target_pos, mode_color)

	var hidden_nodes: Array = d.get("hidden_nodes", [])
	var should_draw_enemy_path: bool = d.get("brain_path_revealed", true) if d.defender_mode else false
	draw_edges(d.graph, d.node_positions, d.blocked_edges, d.blocked_keys, d.current_path, d.node_radius, d.game_over, d.brain_hovered_edge if d.defender_mode else "", d.brain_enemy_path if should_draw_enemy_path else [], d.turn, d.unblock_flash_time, d.unblock_flash_edge, hidden_nodes, d.player_pos, d.selected_neighbor, is_secret_sector, mode)
	if d.defender_mode:
		var q_mode_active: bool = d.get("quarantine_mode", false)
		var enemy_start_node: StringName = d.graph.nodes[0].id if d.graph != null and d.graph.nodes.size() > 0 else &""
		if d.get("enemy_start_node", &"") != &"":
			enemy_start_node = d.get("enemy_start_node")
		var enemy_vis: Vector2 = d.get("enemy_visual_pos", Vector2.ZERO)
		draw_nodes(d.graph, d.node_positions, &"", d.brain_enemy_target, [], d.current_path, d.node_radius, d.game_over, d.alerted_nodes, &"", d.scan_results, d.waypoints, -1, d.brain_firewalls, d.brain_enemy_pos, d.enemy_move_flash_time, d.bonus_nodes, d.bonus_visitados, hidden_nodes, enemy_vis, false, true, d.brain_enemy_pos, d.get("brain_quarantined_nodes", {}), q_mode_active, enemy_start_node, d.brain_enemy_target, is_secret_sector)
		if should_draw_enemy_path and d.brain_enemy_path.size() >= 2:
			draw_optimal_overlay(d.brain_enemy_path, d.node_positions, d.node_radius, d.graph, hidden_nodes)
	else:
		draw_nodes(d.graph, d.node_positions, d.player_pos, d.target, d.neighbors, d.current_path, d.node_radius, d.game_over, d.alerted_nodes, d.selected_neighbor, d.scan_results, d.waypoints, d.waypoint_idx, {}, &"", d.enemy_move_flash_time, d.bonus_nodes, d.bonus_visitados, hidden_nodes, d.get("player_visual_pos", Vector2.ZERO), d.get("is_moving", false), false, &"", {}, false, &"", &"", is_secret_sector)

	draw_pursuers(d.pursuers, d.node_positions, d.node_radius)
	var m_daemons: Array = d.get("multi_daemons", [])
	for md_raw in m_daemons:
		if not (md_raw is Dictionary):
			continue
		var md: Dictionary = md_raw
		var md_pos_key: StringName = md.get("pos", &"")
		if d.node_positions.has(md_pos_key):
			var md_pos: Vector2 = d.node_positions[md_pos_key]
			var md_col: Color = md.get("color", BrandClass.ENEMY)
			var is_cont: bool = bool(md.get("contained", false))
			var draw_col: Color = BrandClass.TEXT_DIM if is_cont else md_col
			_canvas.draw_arc(md_pos, d.node_radius + 7.0, 0.0, TAU, 24, draw_col, 2.5)
			if font != null:
				_canvas.draw_string(font, md_pos + Vector2(-24.0, -d.node_radius - 10.0), str(md.get("id", "DAEMON")), HORIZONTAL_ALIGNMENT_CENTER, 48.0, 10, draw_col)
	if d.show_optimal_overlay:
		draw_optimal_overlay(d.optimal_overlay_path, d.node_positions, d.node_radius, d.graph, hidden_nodes)
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
		var threat_hops := 3
		var e_path: Array = d.get("brain_enemy_path", [])
		if e_path.size() > 1:
			threat_hops = e_path.size() - 1
		draw_defender_hud(d.vp_size, d.turn, d.brain_blocks_placed, d.brain_blocks_per_turn, d.brain_enemy_pos, d.brain_enemy_target, d.max_turns, d.brain_min_cut, d.blocked_edges, d.brain_firewalls, d.brain_firewall_mode, d.get("brain_forensics_trace", 0.0), d.get("brain_quarantined_nodes", {}), d.get("brain_fog_of_war", false), d.get("brain_telemetry_intercepted", false), q_mode_active, d.get("node_cache", {}), {"threat_hops": threat_hops})
	else:
		var det_num: float = 0.0
		var det_str := "0%"
		var nc: Dictionary = d.get("node_cache", {})
		if nc.has(d.player_pos):
			var node_res = nc[d.player_pos]
			var meta: Dictionary = node_res.metadata if (node_res != null and "metadata" in node_res and node_res.metadata is Dictionary) else (node_res if node_res is Dictionary else {})
			det_num = float(meta.get("detection_chance", 0.0))
			det_str = "%.0f%%" % (det_num * 100.0)
		var alerted: Array = d.get("alerted_nodes", [])
		if str(d.player_pos) in alerted:
			det_num = 1.0
			det_str = "100%"

		var hops := int(d.get("heist_hops_to_target", 0))
		if hops <= 0:
			var opt_path: Array = d.get("optimal_overlay_path", [])
			if opt_path.size() > 1:
				hops = opt_path.size() - 1
			elif d.get("graph", null) != null and d.player_pos != &"" and d.target != &"":
				var path_res: Dictionary = DefensivePathfinderClass.find_path_with_cost(d.graph, d.player_pos, d.target, null)
				if path_res.get("reachable", false) and path_res.get("path", []).size() > 1:
					hops = path_res["path"].size() - 1
				else:
					hops = 3
			else:
				hops = 3

		var heist_extra := {
			"ids_alert": det_str,
			"alert_num": det_num,
			"hops_to_target": hops
		}
		draw_hud(d.vp_size, d.titulo_nivel, d.turn, d.player_pos, d.target, d.player_total_cost, d.max_turns, d.waypoints, d.waypoint_idx, d.pursuers, d.alerted_nodes, d.movement_points, d.max_movement_points, d.budget_display, d.get("node_cache", {}), d.get("hacker_state", {}), d.get("hacker_mode", false), is_secret_sector, heist_extra)

	if d.mensaje_tutorial != "" and not d.game_over:
		draw_tutorial_text(d.mensaje_tutorial)
	if d.selected_neighbor != &"" and not d.game_over:
		draw_node_info_panel(d.vp_size, d.selected_neighbor, d.player_pos, d.graph, d.node_cache, is_secret_sector)

	# Menú contextual de nodo en modo Defensor (pantalla UI)
	if d.defender_mode and d.get("defender_context_node", &"") != &"":
		draw_defender_contextual_menu(d.vp_size, d.get("defender_context_node"), d.node_positions, pan, zoom)

	# Dock táctico unificado (Heist, Hacker, Defender, Cámara touch)
	draw_tactical_action_dock(d)


## Fondo de pantalla completa con grilla infinita que jamás se encoje con zoom out
func draw_fullscreen_mode_background(
	vp_size: Vector2,
	mode: String,
	mode_color: Color,
	bg_color: Color,
	pan: Vector2,
	zoom: float,
	is_secret_sector: bool
) -> void:
	# 1. Relleno total del viewport
	draw_rect(Rect2(0, 0, vp_size.x, vp_size.y), bg_color)

	# 2. Grilla infinita que responde a pan y zoom
	var z := zoom if zoom > 0.0 else 1.0
	var spacing: float = 48.0 * z
	while spacing < 32.0:
		spacing *= 2.0
	while spacing > 120.0:
		spacing *= 0.5

	var grid_alpha := 0.08
	var grid_col := Color(mode_color.r, mode_color.g, mode_color.b, grid_alpha)

	var start_x := fmod(pan.x, spacing)
	if start_x < 0.0:
		start_x += spacing
	while start_x <= vp_size.x:
		draw_line(Vector2(start_x, 0), Vector2(start_x, vp_size.y), grid_col, 1.0)
		start_x += spacing

	var start_y := fmod(pan.y, spacing)
	if start_y < 0.0:
		start_y += spacing
	while start_y <= vp_size.y:
		draw_line(Vector2(0, start_y), Vector2(vp_size.x, start_y), grid_col, 1.0)
		start_y += spacing

	# 3. Lluvia de memoria y escaneo para Sector 0
	if is_secret_sector:
		var t: float = Time.get_ticks_msec() * 0.001
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
			var hex_alpha := 0.08 + sin(t * 2.0 + float(col)) * 0.04
			draw_string(Vector2(col_x, y_offset), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.2, 0.35, hex_alpha))

		var glitch_y := fmod(t * 90.0, vp_size.y)
		draw_line(Vector2(0, glitch_y), Vector2(vp_size.x, glitch_y), Color(1.0, 0.1, 0.3, 0.18), 1.5)


func _draw_concentric_target_rings(center: Vector2, mode_color: Color) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	var r1 := 48.0 + sin(t * 2.0) * 3.0
	var r2 := 84.0
	var r3 := 128.0
	draw_circle(center, r1, Color(mode_color.r, mode_color.g, mode_color.b, 0.18), false, 1.5)
	draw_circle(center, r2, Color(mode_color.r, mode_color.g, mode_color.b, 0.12), false, 1.2)
	draw_circle(center, r3, Color(mode_color.r, mode_color.g, mode_color.b, 0.07), false, 1.0)


## Fondo Abisal de Kernel Panic / Glitch Void para el Sector 0 secreto (Artboard 03)
func _draw_kernel_void_background(vp_size: Vector2, pan: Vector2, zoom: float, _core_pos: Vector2 = Vector2(935, 272)) -> void:
	draw_fullscreen_mode_background(vp_size, "secret", Color("#ff2a6d"), Color("#14080e"), pan, zoom, true)


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


func _draw_numeric_chip(pos: Vector2, label: String, val_text: String, val_color: Color) -> float:
	var lbl_sz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4) if font else Vector2(50.0, 12.0)
	var val_sz := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2) if font else Vector2(40.0, 14.0)
	var chip_w := lbl_sz.x + val_sz.x + 20.0
	var chip_rect := Rect2(pos.x, pos.y, chip_w, 32.0)
	draw_rect(chip_rect, Color(1.0, 1.0, 1.0, 0.03))
	draw_rect(chip_rect, BrandClass.PANEL_BORDER, false, 1.0)
	draw_string(Vector2(pos.x + 8.0, pos.y + 20.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)
	draw_string(Vector2(pos.x + 8.0 + lbl_sz.x + 6.0, pos.y + 20.0), val_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, val_color)
	return chip_w


func draw_hud(
	vp_size: Vector2,
	titulo_nivel: String,
	turn: int,
	player_pos: StringName,
	target: StringName,
	player_total_cost: float,
	_max_turns: int,
	waypoints: Array,
	current_waypoint_idx: int,
	_pursuers: Array,
	_alerted_nodes: Array,
	movement_points: int,
	max_movement_points: int,
	_budget_display: float = 0.0,
	node_cache: Dictionary = {},
	hacker_state: Dictionary = {},
	hacker_mode: bool = false,
	is_secret: bool = false,
	extra_hud_data: Dictionary = {}
) -> void:
	var bar_h: float = 52.0
	var mode := "heist"
	var theme_col: Color = BrandClass.WORLD_HEIST
	if is_secret:
		mode = "secret"
		theme_col = BrandClass.WORLD_SECRET
	elif hacker_mode:
		mode = "hacker"
		theme_col = BrandClass.WORLD_HACKER

	# Barra superior con fondo unificado
	draw_rect(Rect2(0, 0, vp_size.x, bar_h), BrandClass.PANEL_SOLID)
	draw_rect(Rect2(0, bar_h - 1.5, vp_size.x, 1.5), theme_col)

	# 1. Left Cluster (x = 16.0, max width = 220.0)
	# Line 1 (y = 20): Level Title
	var title_font_size := font_size + 1
	var title_w := font.get_string_size(titulo_nivel, HORIZONTAL_ALIGNMENT_LEFT, -1, title_font_size).x if font else 120.0
	if title_w > 220.0:
		title_font_size = maxi(8, font_size - 2)
	draw_string(Vector2(16.0, 20.0), titulo_nivel, HORIZONTAL_ALIGNMENT_LEFT, 220.0, title_font_size, theme_col)

	# Line 2 (y = 38): Subtitle
	var sub_text := "T%d" % turn
	if waypoints.size() > 0:
		sub_text = "T%d · WP %d/%d" % [turn, current_waypoint_idx + 1, waypoints.size()]
	if hacker_mode or is_secret:
		sub_text += " · PROXY: TOR-04"
	draw_string(Vector2(16.0, 38.0), sub_text, HORIZONTAL_ALIGNMENT_LEFT, 220.0, font_size - 3, BrandClass.TEXT_DIM)

	# Divisor at x = 244.0 (stack_end_x = 236.0)
	draw_line(Vector2(244.0, 10.0), Vector2(244.0, 42.0), BrandClass.PANEL_BORDER, 1.0)

	# Pure Numeric Chips (NO progress bars!) starting at x = 252.0
	var chip_x: float = 252.0
	var pts_col: Color = BrandClass.SUCCESS if movement_points > int(max_movement_points * 0.3) else BrandClass.WARNING
	if hacker_mode or is_secret:
		var noise: int = hacker_state.get("noise", 0)
		var noise_col: Color = BrandClass.SUCCESS
		if noise >= 85:
			noise_col = BrandClass.DANGER
		elif noise >= 60:
			noise_col = Color(1.0, 0.5, 0.0)
		elif noise >= 30:
			noise_col = BrandClass.WARNING

		var w1 := _draw_numeric_chip(Vector2(chip_x, 10.0), "PTS", "%d" % movement_points, pts_col)
		_draw_numeric_chip(Vector2(chip_x + w1 + 8.0, 10.0), "RUIDO", "%d%%" % noise, noise_col)
	else:
		var w1 := _draw_numeric_chip(Vector2(chip_x, 10.0), "PTS", "%d" % movement_points, pts_col)
		_draw_numeric_chip(Vector2(chip_x + w1 + 8.0, 10.0), "COSTE", "%.1f" % player_total_cost, Color.WHITE)

	# 2. Center Cluster: ALL Perks / Tools in Top Bar (y = 8.0, height = 36.0)
	var top_perks := get_top_perk_rects(vp_size, mode, false, false, font, font_size, hacker_state, extra_hud_data)
	for p in top_perks:
		var is_act := false
		if p.get("is_action", true) == false:
			is_act = true
		elif hacker_mode or is_secret:
			if p["id"] == "scan":
				is_act = true
			else:
				var exps: Dictionary = hacker_state.get("exploits", {}) if hacker_state.has("exploits") else hacker_state
				is_act = exps.get(p["id"], 0) > 0
		else:
			if p["id"] == "tab_neighbor":
				is_act = true
		_draw_hud_pill(p["rect"].position, p["text"], is_act, p["color"])

	# 3. Right Cluster (right-aligned at vp_size.x - 16.0)
	var pos_display: String = resolve_node_display_name(player_pos, node_cache)
	var target_display: String = resolve_node_display_name(target, node_cache)

	var pos_lbl := "POS: "
	var pos_lbl_w := font.get_string_size(pos_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x if font else 30.0
	var pos_val_w := font.get_string_size(pos_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x if font else 60.0
	var pos_total_w := pos_lbl_w + pos_val_w

	draw_string(Vector2(vp_size.x - 16.0 - pos_total_w, 20.0), pos_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	draw_string(Vector2(vp_size.x - 16.0 - pos_total_w + pos_lbl_w, 20.0), pos_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color.WHITE)

	var meta_lbl := "META: "
	var meta_lbl_w := font.get_string_size(meta_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x if font else 40.0
	var meta_val_w := font.get_string_size(target_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x if font else 70.0
	var meta_total_w := meta_lbl_w + meta_val_w

	draw_string(Vector2(vp_size.x - 16.0 - meta_total_w, 38.0), meta_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
	draw_string(Vector2(vp_size.x - 16.0 - meta_total_w + meta_lbl_w, 38.0), target_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color("#ff4757"))


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
	node_cache: Dictionary = {},
	extra_hud_data: Dictionary = {}
) -> void:
	var bar_h: float = 52.0
	var theme_col: Color = BrandClass.WORLD_CYBER

	# Barra superior con fondo unificado
	draw_rect(Rect2(0, 0, vp_size.x, bar_h), BrandClass.PANEL_SOLID)
	draw_rect(Rect2(0, bar_h - 1.5, vp_size.x, 1.5), theme_col)

	# 1. Left Cluster (x = 16.0, max width = 220.0)
	var title_str := "Defensa Perimetral"
	var def_title_font_size := font_size + 1
	var def_title_w := font.get_string_size(title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, def_title_font_size).x if font else 120.0
	if def_title_w > 220.0:
		def_title_font_size = maxi(8, font_size - 2)
	draw_string(Vector2(16.0, 20.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, 220.0, def_title_font_size, theme_col)

	var sub_str := "T%d · SOC ACTIVO" % turn
	draw_string(Vector2(16.0, 38.0), sub_str, HORIZONTAL_ALIGNMENT_LEFT, 220.0, font_size - 3, BrandClass.TEXT_DIM)

	# Divisor at x = 244.0 (stack_end_x = 236.0)
	draw_line(Vector2(244.0, 10.0), Vector2(244.0, 42.0), BrandClass.PANEL_BORDER, 1.0)

	# Pure Numeric Chips (NO progress bars!) starting at x = 252.0
	var chip_x: float = 252.0
	var blocks_avail := maxi(0, blocks_per_turn - blocks_placed)
	var pips_str := "%d/%d" % [blocks_avail, blocks_per_turn]

	var w1 := _draw_numeric_chip(Vector2(chip_x, 10.0), "BLOQ", pips_str, BrandClass.SUCCESS if blocks_avail > 0 else BrandClass.DANGER)
	_draw_numeric_chip(Vector2(chip_x + w1 + 8.0, 10.0), "EDR", "%.0f%%" % forensics_trace, Color("#00d2ff"))

	# 2. Center Cluster: ALL Perks / Tools in Top Bar
	var top_perks := get_top_perk_rects(vp_size, "defender", fog_of_war, telemetry_intercepted, font, font_size, {}, extra_hud_data)
	for p in top_perks:
		var is_active := false
		var is_pulse := false
		if p.get("is_action", true) == false:
			is_active = true
			if p["id"] == "soc_threat":
				is_pulse = true
		else:
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
		_draw_hud_pill(p["rect"].position, p["text"], is_active, p["color"], is_pulse)

	# 3. Right Cluster (right-aligned at vp_size.x - 16.0)
	var enemy_display: String = resolve_node_display_name(enemy_pos, node_cache)
	var target_display: String = resolve_node_display_name(enemy_target, node_cache)

	var intruso_lbl := "INTRUSO: "
	var intruso_lbl_w := font.get_string_size(intruso_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x if font else 45.0
	var intruso_val_w := font.get_string_size(enemy_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x if font else 70.0
	var intruso_total_w := intruso_lbl_w + intruso_val_w

	draw_string(Vector2(vp_size.x - 16.0 - intruso_total_w, 20.0), intruso_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	draw_string(Vector2(vp_size.x - 16.0 - intruso_total_w + intruso_lbl_w, 20.0), enemy_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(1.0, 0.35, 0.25))

	var nucleo_lbl := "NÚCLEO: "
	var nucleo_lbl_w := font.get_string_size(nucleo_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x if font else 45.0
	var nucleo_val_w := font.get_string_size(target_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x if font else 70.0
	var nucleo_total_w := nucleo_lbl_w + nucleo_val_w

	draw_string(Vector2(vp_size.x - 16.0 - nucleo_total_w, 38.0), nucleo_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
	draw_string(Vector2(vp_size.x - 16.0 - nucleo_total_w + nucleo_lbl_w, 38.0), target_display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.0, 0.82, 1.0))


func _draw_hud_pill(pos: Vector2, text: String, active: bool, color: Color, pulse: bool = false) -> void:
	var t_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x if font else 70.0
	var pill_h := 36.0  # Altura cómoda >= 36px para touch y mouse
	var pill_w := t_w + 20.0
	var pill_rect := Rect2(pos.x, pos.y, pill_w, pill_h)

	var bg_col := BrandClass.with_alpha(color, 0.25 if active else 0.08)
	var border_col := BrandClass.with_alpha(color, 0.85 if active else 0.3)
	if active and pulse:
		var p_wave := 0.6 + sin(Time.get_ticks_msec() * 0.008) * 0.35
		border_col = BrandClass.with_alpha(color, p_wave)
		draw_rect(Rect2(pos.x - 2, pos.y - 2, pill_w + 4.0, pill_h + 4.0), BrandClass.with_alpha(color, p_wave * 0.25), false, 1.5)

	draw_rect(pill_rect, bg_col)
	draw_rect(pill_rect, border_col, false, 1.2)
	draw_string(Vector2(pos.x + 10.0, pos.y + 23.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, color if active else BrandClass.TEXT_DIM)


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
	is_secret_sector: bool = false,
	mode: String = ""
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
			match mode:
				"heist":
					edge_color = Color(0.75, 0.35, 0.95, 0.75)
					line_width = 2.0
				"hacker":
					edge_color = Color(0.22, 1.0, 0.53, 0.75)
					line_width = 2.0
				"defender":
					edge_color = Color(0.0, 0.82, 1.0, 0.75)
					line_width = 2.0
				_:
					edge_color = Color(0.35, 0.5, 0.7, 0.9)
					line_width = 1.8

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

		# Sutil halo o glow temático
		draw_polyline(puntos, Color(edge_color.r, edge_color.g, edge_color.b, 0.16), line_width + 2.5)
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

		var used_font_size: int = font_size
		var label_y_offset: float = 0.0

		var has_close_horizontal_node: bool = false
		var is_higher_x_than_close_node: bool = false
		for other_id in node_positions.keys():
			if other_id == nid:
				continue
			var other_p: Vector2 = node_positions[other_id] as Vector2
			var dx: float = absf(other_p.x - pos.x)
			var dy: float = absf(other_p.y - pos.y)
			if dx > 0.1 and dx < 155.0 and dy < 32.0:
				has_close_horizontal_node = true
				if pos.x > other_p.x:
					is_higher_x_than_close_node = true
				break

		if label_text.length() > 16 and has_close_horizontal_node:
			used_font_size = tiny_font_size
			label_y_offset = -8.0 if is_higher_x_than_close_node else 6.0

		var text_sz: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, used_font_size) if font else Vector2(label_text.length() * 8.0, 14.0)
		var text_w: float = text_sz.x
		var label_x: float = pos.x - text_w / 2.0
		var label_y: float = pos.y - radius - 8.0 + label_y_offset
		var box_h: float = 14.0 if used_font_size == tiny_font_size else 18.0
		var box_top: float = (label_y - 10.0) if used_font_size == tiny_font_size else (label_y - 14.0)
		draw_rect(Rect2(label_x - 4, box_top, text_w + 8, box_h), label_bg_color)
		draw_rect(Rect2(label_x - 4, box_top, text_w + 8, box_h), border_color, false, 1.0)
		draw_string(Vector2(label_x, label_y), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, used_font_size, Color.WHITE)

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


func compute_edge_curve_points(
	from_id: StringName,
	to_id: StringName,
	node_positions: Dictionary,
	node_radius: float,
	graph: NetworkGraphResource = null
) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	var from_pos: Vector2 = node_positions.get(from_id, Vector2.ZERO) as Vector2
	var to_pos: Vector2 = node_positions.get(to_id, Vector2.ZERO) as Vector2
	if from_pos == Vector2.ZERO or to_pos == Vector2.ZERO:
		return puntos
	var seg_vec: Vector2 = to_pos - from_pos
	var seg_len: float = seg_vec.length()
	if seg_len <= node_radius * 2.0:
		return puntos
	var dir: Vector2 = seg_vec / seg_len
	var inicio: Vector2 = from_pos + dir * node_radius
	var tip: Vector2 = to_pos - dir * node_radius
	var centro: Vector2 = (from_pos + to_pos) * 0.5
	var perp: Vector2 = dir.rotated(PI * 0.5)

	var has_reverse: bool = false
	if graph != null:
		for e2 in graph.edges:
			if e2 != null and e2.from_id == to_id and e2.to_id == from_id:
				has_reverse = true
				break

	var bend: float = 0.0
	if has_reverse:
		bend = 15.0 * (1.0 if String(from_id) < String(to_id) else -1.0)
	else:
		for other_nid in node_positions.keys():
			if other_nid != from_id and other_nid != to_id:
				var inter_pos: Vector2 = node_positions[other_nid] as Vector2
				var closest: Vector2 = Geometry2D.get_closest_point_to_segment(inter_pos, from_pos, to_pos)
				if closest.distance_to(inter_pos) < 38.0 and seg_len > 80.0:
					var offset_vec: Vector2 = inter_pos - closest
					var cross_prod: float = dir.x * offset_vec.y - dir.y * offset_vec.x
					bend = -45.0 if cross_prod >= 0.0 else 45.0
					break

	if absf(bend) < 0.5:
		puntos.append(inicio)
		puntos.append(tip)
	else:
		var ctrl: Vector2 = centro + perp * bend * 2.0
		for s in range(15):
			var t: float = float(s) / 14.0
			puntos.append(inicio.lerp(ctrl, t).lerp(ctrl.lerp(tip, t), t))
	return puntos


func draw_optimal_overlay(
	optimal_path: Array,
	node_positions: Dictionary,
	node_radius: float,
	graph: NetworkGraphResource = null,
	hidden_nodes: Array = []
) -> void:
	if optimal_path.size() < 2:
		return
	var pulse: float = 0.5 + sin(Time.get_ticks_msec() * 0.005) * 0.3

	# 1. 3-pass Neon Green route lines following exact edge curves
	for i in range(optimal_path.size() - 1):
		var from_id: StringName = StringName(optimal_path[i])
		var to_id: StringName = StringName(optimal_path[i + 1])
		if hidden_nodes.has(from_id) or hidden_nodes.has(to_id) or hidden_nodes.has(String(from_id)) or hidden_nodes.has(String(to_id)):
			continue
		var pts: PackedVector2Array = compute_edge_curve_points(from_id, to_id, node_positions, node_radius, graph)
		if pts.size() < 2:
			continue

		# 3-pass Neon Green (#39ff88 / Color(0.22, 1.0, 0.53)) route line:
		draw_polyline(pts, Color(0.1, 1.0, 0.45, 0.24 * pulse), 10.0)
		draw_polyline(pts, Color(0.2, 1.0, 0.55, 0.55 * pulse), 5.0)
		draw_polyline(pts, Color(0.4, 1.0, 0.65, 0.95), 2.5)

		# Animated directional chevrons / photon pulses traveling along exact curve
		var progress: float = fmod((Time.get_ticks_msec() * 0.0012) + float(i) * 0.25, 1.0)
		var f_idx: float = progress * float(pts.size() - 1)
		var seg_idx: int = clampi(int(floorf(f_idx)), 0, pts.size() - 2)
		var local_t: float = f_idx - float(seg_idx)
		var travel_pos: Vector2 = pts[seg_idx].lerp(pts[seg_idx + 1], local_t)
		var dir: Vector2 = (pts[seg_idx + 1] - pts[seg_idx]).normalized()
		var normal: Vector2 = Vector2(-dir.y, dir.x)
		var chev_tip := travel_pos + dir * 6.0
		var chev_left := travel_pos - dir * 4.0 + normal * 4.5
		var chev_right := travel_pos - dir * 4.0 - normal * 4.5
		draw_circle(travel_pos, 4.0, Color(0.1, 1.0, 0.45, 0.3 * pulse))
		draw_circle(travel_pos, 2.0, Color(0.8, 1.0, 0.9, 0.95))
		draw_line(chev_left, chev_tip, Color(0.35, 1.0, 0.65, 0.9), 2.0)
		draw_line(chev_right, chev_tip, Color(0.35, 1.0, 0.65, 0.9), 2.0)

	# 2. Node highlights along optimal_path with crisp neon green rings and step numbers
	for i in range(optimal_path.size()):
		var node_id: StringName = optimal_path[i] as StringName
		var pos: Vector2 = node_positions.get(node_id, Vector2.ZERO) as Vector2
		if pos == Vector2.ZERO:
			continue
		var is_start: bool = i == 0
		var is_end: bool = i == optimal_path.size() - 1

		var ring_col := Color(0.22, 1.0, 0.53, 0.85)
		if is_start:
			ring_col = Color(0.0, 0.95, 1.0, 0.9)
		elif is_end:
			ring_col = Color(1.0, 0.3, 0.3, 0.9)
		draw_circle(pos, node_radius + 9.0, Color(ring_col.r, ring_col.g, ring_col.b, 0.22 * pulse))
		draw_circle(pos, node_radius + 9.0, ring_col, false, 2.0)
		draw_circle(pos, node_radius + 13.0, Color(ring_col.r, ring_col.g, ring_col.b, 0.3 * pulse), false, 1.2)

		var step_str := str(i + 1)
		var badge_pos := pos + Vector2(node_radius + 7.0, -node_radius - 5.0)
		draw_circle(badge_pos, 9.0, Color(0.04, 0.15, 0.08, 0.92))
		draw_circle(badge_pos, 9.0, Color(0.22, 1.0, 0.53, 0.85), false, 1.2)
		var num_sz := font.get_string_size(step_str, HORIZONTAL_ALIGNMENT_CENTER, -1, tiny_font_size) if font else Vector2(7.0, 10.0)
		draw_string(Vector2(badge_pos.x - num_sz.x * 0.5, badge_pos.y + 4.0), step_str, HORIZONTAL_ALIGNMENT_LEFT, -1, tiny_font_size, Color(0.85, 1.0, 0.9))


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

	var id_str := str(selected_neighbor)
	var title_w := font.get_string_size(display_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if font else 80.0
	var id_tag: String = "#%s" % id_str
	var tag_sz := font.get_string_size(id_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4).x if font else 40.0

	var is_redundant: bool = id_str.to_lower() == display_title.to_lower() or (title_w + tag_sz > panel_w - 24.0)
	if not is_redundant:
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


## Dock Táctico Inferior Unificado (Artboard 04: Status izq | Confirm centro | Controles der)
func draw_tactical_action_dock(d: Dictionary) -> void:
	var vp_size: Vector2 = d.get("vp_size", Vector2(1280, 720))
	var bar_h: float = 44.0
	var bar_y: float = vp_size.y - bar_h

	# Fondo del dock táctico
	draw_rect(Rect2(0, bar_y, vp_size.x, bar_h), BrandClass.PANEL_SOLID)
	draw_rect(Rect2(0, bar_y, vp_size.x, 1.5), BrandClass.PANEL_BORDER)

	var is_secret_sector: bool = str(d.get("level_key", "")).begins_with("secret") or d.get("world", "") == "secret" or str(d.get("titulo_nivel", "")).find("Sector 0") != -1 or d.node_positions.has(&"GenesisCore") or d.node_positions.has("GenesisCore")

	# Measure confirm button if active
	var has_confirm_btn := false
	var confirm_btn_w := 260.0
	var confirm_btn_x := (vp_size.x - 260.0) * 0.5
	var m_txt := ""
	var sel_display := ""
	if not d.get("defender_mode", false) and not d.get("game_over", false):
		var sel_n: StringName = d.get("selected_neighbor", &"")
		if sel_n != &"":
			has_confirm_btn = true
			sel_display = resolve_node_display_name(sel_n, d.get("node_cache", {}))
			m_txt = "⏭ CONFIRMAR: %s" % sel_display
			var measured_txt_w: float = font.get_string_size(m_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1).x if font else 160.0
			confirm_btn_w = maxf(260.0, measured_txt_w + 32.0)
			confirm_btn_x = (vp_size.x - confirm_btn_w) * 0.5

	# 1. Left Cluster: Single status / operator log line
	var tag := "[EXFIL // VEX]: "
	var tag_col: Color = BrandClass.WORLD_HEIST
	var def_msg := "Tu turno: seleccioná un nodo adyacente para exfiltrar el fragmento Shamir."

	if is_secret_sector:
		tag = "[TCP_SEQ_GHOST // KAIN]: "
		tag_col = BrandClass.WORLD_SECRET
		def_msg = "«IA bloqueó una ruta al inicio. Inyectá [1] BYPASS o pivotá por Celda Gamma.»"
	elif d.defender_mode:
		tag = "[CORDON // AEGIS]: "
		tag_col = BrandClass.WORLD_CYBER
		def_msg = "Contén al intruso. Cada bloqueo avanza el turno y el rastreo forense EDR."
	elif d.get("hacker_mode", false):
		tag = "[FUZZ // N0X]: "
		tag_col = BrandClass.WORLD_HACKER
		def_msg = "IA bloqueó una ruta al inicio. Usá tus Perks arriba o pivotá por otro nodo."

	var msg_text: String = d.get("mensaje_estado", "")
	if msg_text == "" or msg_text.begins_with("Ve hacia"):
		msg_text = def_msg

	var tag_w := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x if font else 90.0
	var right_boundary := (confirm_btn_x - 28.0) if has_confirm_btn else (vp_size.x - 305.0)
	var max_msg_w := maxf(60.0, right_boundary - (16.0 + tag_w))
	draw_string(Vector2(16.0, bar_y + 26.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, tag_col)
	draw_string(Vector2(16.0 + tag_w, bar_y + 26.0), msg_text, HORIZONTAL_ALIGNMENT_LEFT, max_msg_w, font_size - 3, BrandClass.TEXT)

	# 2. Center: Prominent green confirm move button when selected_neighbor != &"" in Attacker/Hacker
	if has_confirm_btn:
		var m_btn := Rect2(confirm_btn_x, bar_y + 5.0, confirm_btn_w, 34.0)
		var pulse := 0.7 + sin(Time.get_ticks_msec() * 0.008) * 0.3
		draw_rect(m_btn, Color(0.0, 0.25, 0.15, 0.95))
		draw_rect(m_btn, Color(0.22, 1.0, 0.53, pulse), false, 1.5)
		var m_sz := font.get_string_size(m_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2) if font else Vector2(120.0, 14.0)
		draw_string(Vector2(m_btn.position.x + (m_btn.size.x - m_sz.x) * 0.5, bar_y + 23.0), m_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color.WHITE)

	# 3. Right Cluster: [~] CLI, [⟲ CENTRAR], [-], [+], [⏸]
	var btn_y := bar_y + 5.0
	var btn_h := 34.0
	_draw_dock_button(Rect2(vp_size.x - 295.0, btn_y, 55.0, btn_h), "[~] CLI", Color("00e5ff"))
	_draw_dock_button(Rect2(vp_size.x - 235.0, btn_y, 85.0, btn_h), "[⟲ CENTRAR]", Color(0.3, 0.7, 0.9))
	_draw_dock_button(Rect2(vp_size.x - 145.0, btn_y, 32.0, btn_h), "[-]", Color(0.3, 0.7, 0.9))
	_draw_dock_button(Rect2(vp_size.x - 108.0, btn_y, 32.0, btn_h), "[+]", Color(0.3, 0.7, 0.9))
	_draw_dock_button(Rect2(vp_size.x - 71.0, btn_y, 55.0, btn_h), "[⏸]", BrandClass.WARNING)


func _draw_dock_button(rect: Rect2, text: String, color: Color, active: bool = false) -> void:
	var bg_col := BrandClass.with_alpha(color, 0.22 if active else 0.08)
	var border_col := BrandClass.with_alpha(color, 0.85 if active else 0.35)
	draw_rect(rect, bg_col)
	draw_rect(rect, border_col, false, 1.5 if active else 1.0)
	var t_sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3) if font else Vector2(20.0, 12.0)
	var t_pos := Vector2(rect.position.x + (rect.size.x - t_sz.x) * 0.5, rect.position.y + rect.size.y * 0.68)
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
