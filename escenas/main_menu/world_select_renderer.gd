class_name WorldSelectRenderer extends RefCounted

## WorldSelectRenderer
## Dedicated renderer for the World Selection screen in VERTEX.
## Implements Artboard 02: Asymmetric Dossier Spine (3-column layout, live algorithmic simulations, tactical dossier).

const BrandClass = preload("res://juego/ui/brand.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")
const AudioSpectrumVisualizerClass = preload("res://juego/ui/audio_spectrum_visualizer.gd")

var _vertical_pulses: Array[Dictionary] = []
var _spectrum_viz := AudioSpectrumVisualizerClass.new(24)
var _time: float = 0.0


func _init() -> void:
	_init_vertical_pulses()


func _init_vertical_pulses() -> void:
	_vertical_pulses.clear()
	for i: int in range(18):
		_vertical_pulses.append({
			"col_x": randf_range(80.0, 1300.0),
			"y": randf_range(0.0, 672.0),
			"speed": randf_range(90.0, 220.0),
			"length": randf_range(25.0, 80.0),
			"alpha": randf_range(0.18, 0.45)
		})


func update(delta: float, vp: Vector2) -> void:
	_time += delta
	_spectrum_viz.update(delta)
	for p: Dictionary in _vertical_pulses:
		p["y"] = float(p["y"]) + float(p["speed"]) * delta
		if float(p["y"]) - float(p["length"]) > vp.y:
			p["y"] = -float(p["length"])
			p["col_x"] = randf_range(80.0, vp.x - 80.0)
			p["speed"] = randf_range(90.0, 220.0)


func get_world_tab_rect(tab_idx: int, vp: Vector2) -> Rect2:
	var tab_w: float = 256.0
	var tab_h: float = 42.0
	var mid_gap: float = 148.0
	var cx: float = vp.x * 0.5
	var start_x: float = cx - mid_gap * 0.5 - tab_w if tab_idx == 0 else cx + mid_gap * 0.5
	return Rect2(start_x, 104.0, tab_w, tab_h)


func get_card_rect(idx: int, vp: Vector2) -> Rect2:
	var left_x: float = 48.0
	var card_w: float = clampf(vp.x * 0.32, 410.0, 440.0)
	var card_h: float = 74.0
	var start_y: float = 166.0
	var step_y: float = 96.0
	return Rect2(left_x, start_y + float(idx) * step_y, card_w, card_h)


func get_node_pos(idx: int, _total: int, vp: Vector2) -> Vector2:
	var r: Rect2 = get_card_rect(idx, vp)
	return Vector2(r.position.x + 38.0, r.position.y + r.size.y * 0.5)


func get_hologram_rect(vp: Vector2) -> Rect2:
	var left_card: Rect2 = get_card_rect(0, vp)
	var hx: float = left_card.end.x + 22.0
	var hw: float = clampf(vp.x * 0.25, 308.0, 340.0)
	return Rect2(hx, 162.0, hw, 424.0)


func get_dossier_rect(vp: Vector2) -> Rect2:
	var holo: Rect2 = get_hologram_rect(vp)
	var dx: float = holo.end.x + 22.0
	var dw: float = maxf(340.0, vp.x - dx - 44.0)
	return Rect2(dx, 162.0, dw, 424.0)


func get_launch_button_rect(vp: Vector2) -> Rect2:
	var dos: Rect2 = get_dossier_rect(vp)
	return Rect2(dos.position.x + 20.0, dos.end.y - 62.0, dos.size.x - 40.0, 44.0)


func get_world_color(world_id: String) -> Color:
	return BrandClass.get_world_color(world_id)


func draw(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	ox: float,
	selected_idx: int,
	items: Array[Dictionary],
	progress: Dictionary,
	pulse: float,
	font: Font,
	font_size: int,
	big_font_size: int,
	world_tab_idx: int = 0
) -> void:
	var total_items: int = items.size()
	if total_items == 0:
		return

	var sel_item: Dictionary = items[selected_idx] if (selected_idx >= 0 and selected_idx < total_items) else items[0]
	var active_color: Color = get_world_color(str(sel_item.get("id", "")))

	# 1. Ambient Vertical Matrix Code Pulses
	_draw_matrix_pulses(canvas, vp, alpha)

	# 2. Top Navigation Tabs & Shortcut Chip
	_draw_world_tabs(canvas, vp, alpha, ox, world_tab_idx, font, font_size, active_color)

	# 3. Sector Telemetry Badge (Top Right)
	_draw_sector_telemetry(canvas, vp, alpha, ox, font, font_size, active_color, total_items)

	# 4. Column 1: Left Vertical Spine & World Node Cards
	_draw_left_spine_and_cards(canvas, vp, alpha, ox, selected_idx, items, progress, font, font_size, big_font_size)

	# 5. Column 2: Center Interactive Algorithmic Graph Hologram
	_draw_center_hologram(canvas, vp, alpha, ox, sel_item, font, font_size, active_color, pulse)

	# 6. Column 3: Right Tactical Dossier Card
	_draw_right_dossier(canvas, vp, alpha, ox, sel_item, progress, font, font_size, big_font_size, active_color)


func _draw_world_tabs(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	ox: float,
	world_tab_idx: int,
	font: Font,
	font_size: int,
	active_col: Color
) -> void:
	var hov_tab: int = int(canvas.get("_hovered_tab_idx")) if canvas.get("_hovered_tab_idx") != null else -1
	var tab_names: Array[String] = ["[ CAMPAÑA PRINCIPAL ]", "[ EXTRAS ]"]
	for t: int in range(2):
		var r: Rect2 = get_world_tab_rect(t, vp)
		r.position.x += ox
		var is_active: bool = t == world_tab_idx
		var fill_col: Color = active_col if is_active else BrandClass.PANEL_SOLID
		var border_col: Color = active_col if is_active else BrandClass.PANEL_BORDER
		
		canvas.draw_rect(r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.92))
		if is_active:
			canvas.draw_rect(r, BrandClass.with_alpha(active_col, alpha * 0.18))
			canvas.draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), active_col)
			canvas.draw_rect(r, BrandClass.with_alpha(active_col, alpha * 0.95), false, 1.8)
			var tstr: String = "▸ " + tab_names[t] + " ◂"
			var tsize: Vector2 = font.get_string_size(tstr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1)
			canvas.draw_string(font, Vector2(r.position.x + (r.size.x - tsize.x) * 0.5, r.position.y + 26.0), tstr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.with_alpha(BrandClass.TEXT, alpha))
		else:
			if t == hov_tab:
				canvas.draw_rect(r, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.10))
				canvas.draw_rect(r, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.70), false, 1.2)
			else:
				canvas.draw_rect(r, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.55), false, 1.0)
			var tstr: String = tab_names[t]
			var tsize: Vector2 = font.get_string_size(tstr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
			var txt_col: Color = BrandClass.TEXT if t == hov_tab else BrandClass.TEXT_DIM
			canvas.draw_string(font, Vector2(r.position.x + (r.size.x - tsize.x) * 0.5, r.position.y + 26.0), tstr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.with_alpha(txt_col, alpha))

	# Separate central shortcut chip: ⇄ TAB / Q / E
	var cx: float = vp.x * 0.5 + ox
	var chip_rect: Rect2 = Rect2(cx - 64.0, 108.0, 128.0, 34.0)
	canvas.draw_rect(chip_rect, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.10))
	canvas.draw_rect(chip_rect, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.45), false, 1.0)
	var cstr: String = "⇄ TAB / Q / E"
	var csize: Vector2 = font.get_string_size(cstr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5)
	canvas.draw_string(font, Vector2(chip_rect.position.x + (chip_rect.size.x - csize.x) * 0.5, chip_rect.position.y + 21.0), cstr, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 5, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.90))


func _draw_matrix_pulses(canvas: CanvasItem, _vp: Vector2, alpha: float) -> void:
	for p: Dictionary in _vertical_pulses:
		var x: float = float(p["col_x"])
		var y_top: float = float(p["y"]) - float(p["length"])
		var y_bot: float = float(p["y"])
		var col: Color = BrandClass.with_alpha(BrandClass.ACCENT, float(p["alpha"]) * alpha * 0.35)
		canvas.draw_line(Vector2(x, y_top), Vector2(x, y_bot), col, 1.0)
		canvas.draw_circle(Vector2(x, y_bot), 1.2, BrandClass.with_alpha(Color.WHITE, float(p["alpha"]) * alpha * 0.70))


func _draw_sector_telemetry(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	ox: float,
	font: Font,
	font_size: int,
	active_col: Color,
	total_nodes: int = 4
) -> void:
	var tr_w: float = 240.0
	var tr_x: float = vp.x - tr_w - 36.0 + ox
	var tr_y: float = 32.0
	var tr_rect: Rect2 = Rect2(tr_x, tr_y, tr_w, 44.0)

	canvas.draw_rect(tr_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.88))
	canvas.draw_rect(tr_rect, BrandClass.with_alpha(active_col, alpha * 0.45), false, 1.0)
	canvas.draw_rect(Rect2(tr_rect.position.x + tr_w - 3, tr_rect.position.y, 3, tr_rect.size.y), active_col)

	var hud_t1: String = "[SECTOR::DOMAINS]"
	var nodes_str: String = "0%d" % total_nodes if total_nodes < 10 else str(total_nodes)
	var hud_t2: String = "NODES: %s  |  INTEGRITY: 99.8%%" % nodes_str
	canvas.draw_string(font, Vector2(tr_x + 10, tr_y + 16), hud_t1, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(active_col, alpha * 0.90))
	canvas.draw_string(font, Vector2(tr_x + 10, tr_y + 32), hud_t2, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.75))


func _draw_left_spine_and_cards(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	ox: float,
	selected_idx: int,
	items: Array[Dictionary],
	progress: Dictionary,
	font: Font,
	font_size: int,
	_big_font_size: int
) -> void:
	var hov_card: int = int(canvas.get("_hovered_card_idx")) if canvas.get("_hovered_card_idx") != null else -1
	var spine_x: float = 48.0 + 16.0 + ox
	var spine_top: float = 160.0
	var spine_bot: float = 546.0
	canvas.draw_line(Vector2(spine_x, spine_top), Vector2(spine_x, spine_bot), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.50), 2.0)
	
	var t_packet: float = fmod(_time * 1.5, 1.0)
	var packet_y: float = lerpf(spine_top, spine_bot, t_packet)
	canvas.draw_circle(Vector2(spine_x, packet_y), 3.0, BrandClass.with_alpha(Color.WHITE, alpha * 0.90))

	for i: int in range(items.size()):
		var item: Dictionary = items[i]
		var card_rect: Rect2 = get_card_rect(i, vp)
		card_rect.position.x += ox
		var is_sel: bool = i == selected_idx
		var is_hov: bool = i == hov_card
		var world_id: String = str(item.get("id", ""))
		var is_unlocked: bool = ProgressUtilClass.is_world_unlocked(world_id, progress)
		var world_col: Color = get_world_color(world_id)
		
		var border_col: Color = world_col if (is_sel or is_hov) else BrandClass.PANEL_BORDER

		canvas.draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * (0.95 if is_sel else (0.88 if is_hov else 0.85))))
		if is_sel or is_hov:
			canvas.draw_rect(card_rect, BrandClass.with_alpha(world_col, alpha * (0.12 if is_sel else 0.08)))
		canvas.draw_rect(card_rect, BrandClass.with_alpha(border_col, alpha * (0.95 if is_sel else (0.70 if is_hov else 0.40))), false, 1.5 if (is_sel or is_hov) else 1.0)
		if is_sel:
			canvas.draw_rect(Rect2(card_rect.position.x, card_rect.position.y, 4.0, card_rect.size.y), world_col)

		var icon_box_rect: Rect2 = Rect2(card_rect.position.x + 16.0, card_rect.position.y + 15.0, 44.0, 44.0)
		canvas.draw_rect(icon_box_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.90))
		canvas.draw_rect(icon_box_rect, BrandClass.with_alpha(world_col, alpha * 0.80), false, 1.2)
		var icon_center: Vector2 = icon_box_rect.position + icon_box_rect.size * 0.5
		if not is_unlocked:
			_draw_vector_icon(canvas, icon_center, "lock", 1.0, BrandClass.with_alpha(BrandClass.WARNING, alpha))
		else:
			var vec_icon: String = str(item.get("vector_icon", "default"))
			_draw_vector_icon(canvas, icon_center, vec_icon, 1.0, BrandClass.with_alpha(world_col, alpha))

		var text_x: float = card_rect.position.x + 74.0
		var sec_code_val: String = str(item.get("sec_code", "01"))
		var sec_code_str: String = "%s // SEC-NODE" % sec_code_val
		canvas.draw_string(font, Vector2(text_x, card_rect.position.y + 22.0), sec_code_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(world_col, alpha * 0.90))

		var title_str: String = str(item.get("display_title", item.get("label", "")))
		var max_title_w: float = card_rect.size.x - 84.0
		var title_fs: int = font_size - 1
		if font.get_string_size(title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs).x > max_title_w:
			title_fs = font_size - 3
		canvas.draw_string(font, Vector2(text_x, card_rect.position.y + 42.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, BrandClass.with_alpha(BrandClass.TEXT, alpha))

		var status_str: String = str(item.get("status_line", item.get("desc", "")))
		var max_status_w: float = card_rect.size.x - 86.0
		if font.get_string_size(status_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4).x > max_status_w:
			while status_str.length() > 1 and font.get_string_size(status_str + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4).x > max_status_w:
				status_str = status_str.left(status_str.length() - 1)
			status_str += "..."
		canvas.draw_string(font, Vector2(text_x, card_rect.position.y + 59.0), status_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.80))


func _draw_center_hologram(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	ox: float,
	sel_item: Dictionary,
	font: Font,
	font_size: int,
	active_col: Color,
	pulse: float
) -> void:
	var holo: Rect2 = get_hologram_rect(vp)
	holo.position.x += ox

	canvas.draw_rect(holo, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_rect(holo, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.80), false, 1.0)
	canvas.draw_rect(Rect2(holo.position.x, holo.position.y, holo.size.x, 3.0), active_col)

	var header_rect: Rect2 = Rect2(holo.position.x + 12.0, holo.position.y + 12.0, holo.size.x - 24.0, 26.0)
	canvas.draw_line(Vector2(header_rect.position.x, header_rect.end.y + 4.0), Vector2(header_rect.end.x, header_rect.end.y + 4.0), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.6), 1.0)
	
	var mode_name: String = str(sel_item.get("id", "tutorials")).to_upper()
	canvas.draw_string(font, Vector2(header_rect.position.x, header_rect.position.y + 16.0), "SIMULACIÓN // [%s]" % mode_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(active_col, alpha))
	var active_str: String = "● ACTIVE"
	var asize: Vector2 = font.get_string_size(active_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 3)
	canvas.draw_string(font, Vector2(header_rect.end.x - asize.x, header_rect.position.y + 16.0), active_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.SUCCESS, alpha))

	var sim_rect: Rect2 = Rect2(holo.position.x + 12.0, holo.position.y + 46.0, holo.size.x - 24.0, 320.0)
	canvas.draw_rect(sim_rect, BrandClass.with_alpha(Color(0.04, 0.05, 0.09), alpha * 0.90))
	canvas.draw_rect(sim_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.50), false, 1.0)

	var gx: float = sim_rect.position.x + 20.0
	while gx < sim_rect.end.x:
		canvas.draw_line(Vector2(gx, sim_rect.position.y), Vector2(gx, sim_rect.end.y), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.15), 1.0)
		gx += 20.0
	var gy: float = sim_rect.position.y + 20.0
	while gy < sim_rect.end.y:
		canvas.draw_line(Vector2(sim_rect.position.x, gy), Vector2(sim_rect.end.x, gy), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.15), 1.0)
		gy += 20.0

	var wid: String = str(sel_item.get("id", "tutorials"))
	match wid:
		"tutorials":
			_sim_tutorials(canvas, sim_rect, alpha, pulse)
		"heist":
			_sim_heist(canvas, sim_rect, alpha, pulse)
		"hacker":
			_sim_hacker(canvas, sim_rect, alpha, pulse)
		"cybersecurity":
			_sim_cyber(canvas, sim_rect, alpha, pulse)
		"sector0":
			_sim_sector0(canvas, sim_rect, alpha, pulse)
		"free_ops":
			_sim_free_ops(canvas, sim_rect, alpha, pulse)
		_:
			_sim_tutorials(canvas, sim_rect, alpha, pulse)

	var formula_rect: Rect2 = Rect2(holo.position.x + 12.0, holo.end.y - 36.0, holo.size.x - 24.0, 24.0)
	canvas.draw_line(Vector2(formula_rect.position.x, formula_rect.position.y - 4.0), Vector2(formula_rect.end.x, formula_rect.position.y - 4.0), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.6), 1.0)
	var algo_txt: String = str(sel_item.get("algorithm", ""))
	var fsize: Vector2 = font.get_string_size(algo_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4)
	canvas.draw_string(font, Vector2(formula_rect.position.x + (formula_rect.size.x - fsize.x) * 0.5, formula_rect.position.y + 16.0), algo_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(BrandClass.WARNING, alpha))


func _draw_sim_badge(canvas: CanvasItem, center_pos: Vector2, text: String, col: Color, bg_alpha: float, fsize: int = 11) -> void:
	var f: Font = BrandClass.font_regular()
	var tsize: Vector2 = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var pad_x: float = 8.0
	var box_h: float = float(fsize) + 8.0
	var box: Rect2 = Rect2(center_pos.x - tsize.x * 0.5 - pad_x, center_pos.y - box_h * 0.5, tsize.x + pad_x * 2.0, box_h)
	canvas.draw_rect(box, BrandClass.with_alpha(BrandClass.PANEL_SOLID, bg_alpha * 0.95))
	canvas.draw_rect(box, BrandClass.with_alpha(col, bg_alpha * 0.75), false, 1.0)
	canvas.draw_string(f, Vector2(box.position.x + pad_x, box.position.y + box_h - 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, BrandClass.with_alpha(col, bg_alpha))


func _sim_tutorials(canvas: CanvasItem, rect: Rect2, alpha: float, pulse: float) -> void:
	var top_banner: Rect2 = Rect2(rect.position.x + 10.0, rect.position.y + 8.0, rect.size.x - 20.0, 26.0)
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.6), false, 1.0)
	var phase: int = int(fmod(_time * 0.45, 3.0))
	var lessons: Array[String] = [
		"PASO 1/3: CONECTAR NODOS",
		"PASO 2/3: COSTE DE ARISTA",
		"PASO 3/3: DESBLOQUEAR MODO"
	]
	canvas.draw_string(BrandClass.font_regular(), top_banner.position + Vector2(10.0, 17.0), lessons[phase], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.ACCENT, alpha))

	var n_core: Vector2 = Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 85.0)
	_draw_sim_badge(canvas, n_core + Vector2(0, -22), "ACADEMIA", BrandClass.TEXT, alpha, 11)
	canvas.draw_circle(n_core, 16.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_circle(n_core, 16.0, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.90), false, 2.0)

	var targets: Array[Vector2] = [
		Vector2(rect.position.x + 62.0, rect.position.y + 195.0),
		Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 225.0),
		Vector2(rect.position.x + rect.size.x - 62.0, rect.position.y + 195.0)
	]
	var t_cols: Array[Color] = [
		BrandClass.get_world_color("heist"),
		BrandClass.get_world_color("hacker"),
		BrandClass.get_world_color("cybersecurity")
	]
	var t_names: Array[String] = ["HEIST", "HACKER", "CYBER"]

	for i: int in range(3):
		var tp: Vector2 = targets[i]
		var tcol: Color = t_cols[i]
		canvas.draw_line(n_core, tp, BrandClass.with_alpha(tcol, alpha * 0.50), 1.5)
		canvas.draw_circle(tp, 14.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
		canvas.draw_circle(tp, 14.0, BrandClass.with_alpha(tcol, alpha * 0.8), false, 1.5)
		_draw_sim_badge(canvas, tp + Vector2(0, 24), t_names[i], tcol, alpha, 11)

		if i == phase:
			canvas.draw_arc(tp, 21.0 + sin(pulse * 4.0) * 3.0, 0, TAU, 16, BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.9), 1.8)

		var t_pkt: float = fmod(_time * 1.2 + float(i) * 0.33, 1.0)
		var pkt_pos: Vector2 = n_core.lerp(tp, t_pkt)
		canvas.draw_circle(pkt_pos, 4.5, BrandClass.with_alpha(BrandClass.SUCCESS, alpha))

	var explain_txts: Array[String] = [
		"SALTO -> HEIST (DIJKSTRA)",
		"SALTO -> HACKER (PIVOTEO)",
		"SALTO -> CYBER (FIREWALL)"
	]
	_draw_sim_badge(canvas, Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 140.0), explain_txts[phase], BrandClass.SUCCESS, alpha, 11)

	var bar_r: Rect2 = Rect2(rect.position.x + 10.0, rect.end.y - 26.0, rect.size.x - 20.0, 24.0)
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.6), false, 1.0)
	canvas.draw_string(BrandClass.font_regular(), bar_r.position + Vector2(10.0, 16.0), "COMPLETA CADA TUTORIAL PARA DESBLOQUEAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.TEXT, alpha))


func _sim_heist(canvas: CanvasItem, rect: Rect2, alpha: float, _pulse: float) -> void:
	var top_banner: Rect2 = Rect2(rect.position.x + 10.0, rect.position.y + 8.0, rect.size.x - 20.0, 26.0)
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.get_world_color("heist"), alpha * 0.6), false, 1.0)
	canvas.draw_string(BrandClass.font_regular(), top_banner.position + Vector2(10.0, 17.0), "DIJKSTRA: BUSCA LA RUTA DE MENOR COSTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.get_world_color("heist"), alpha))

	var n_in: Vector2 = rect.position + Vector2(48.0, 165.0)
	var n_top: Vector2 = rect.position + Vector2(rect.size.x * 0.5, 88.0)
	var n_bot: Vector2 = rect.position + Vector2(rect.size.x * 0.5, 232.0)
	var n_out: Vector2 = rect.position + Vector2(rect.size.x - 48.0, 165.0)

	_draw_sim_badge(canvas, n_in + Vector2(0, 26), "ENTRADA", BrandClass.TEXT, alpha, 11)
	_draw_sim_badge(canvas, n_top + Vector2(0, -24), "RUTA CARA: COSTE 8 ✕", BrandClass.ENEMY, alpha, 11)
	_draw_sim_badge(canvas, n_bot + Vector2(0, 26), "RUTA MÍNIMA: COSTE 3 ★", BrandClass.SUCCESS, alpha, 11)
	_draw_sim_badge(canvas, n_out + Vector2(0, 26), "BÓVEDA ★", BrandClass.SUCCESS, alpha, 11)

	# Upper expensive route
	canvas.draw_line(n_in, n_top, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.5), 1.5)
	canvas.draw_line(n_top, n_out, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.5), 1.5)
	var m1: Vector2 = n_in.lerp(n_top, 0.5)
	var m2: Vector2 = n_top.lerp(n_out, 0.5)
	_draw_sim_badge(canvas, m1, "COSTE 4", BrandClass.ENEMY, alpha, 10)
	_draw_sim_badge(canvas, m2, "COSTE 4", BrandClass.ENEMY, alpha, 10)

	# Lower optimal route
	canvas.draw_line(n_in, n_bot, BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.9), 3.0)
	canvas.draw_line(n_bot, n_out, BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.9), 3.0)
	var m3: Vector2 = n_in.lerp(n_bot, 0.5)
	var m4: Vector2 = n_bot.lerp(n_out, 0.5)
	_draw_sim_badge(canvas, m3, "-2 PTS", BrandClass.SUCCESS, alpha, 10)
	_draw_sim_badge(canvas, m4, "-1 PT", BrandClass.SUCCESS, alpha, 10)

	for pos: Vector2 in [n_in, n_top, n_bot, n_out]:
		canvas.draw_circle(pos, 10.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
		canvas.draw_circle(pos, 10.0, BrandClass.with_alpha(BrandClass.get_world_color("heist"), alpha * 0.8), false, 1.5)

	var route_pts: Array[Vector2] = [n_in, n_bot, n_out]
	var t_path: float = fmod(_time * 0.75, 2.0)
	var seg_idx: int = int(t_path) % 2
	var seg_t: float = fmod(t_path, 1.0)
	var vpos: Vector2 = route_pts[seg_idx].lerp(route_pts[seg_idx + 1], seg_t)
	canvas.draw_circle(vpos, 5.0, BrandClass.with_alpha(BrandClass.SUCCESS, alpha))
	canvas.draw_string(BrandClass.font_regular(), vpos + Vector2(8.0, -4.0), "VEX", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.SUCCESS, alpha))

	var rem_pts: int = 8 if seg_idx == 0 else 7
	var bar_txt: String = "PRESUPUESTO: %d / 10 PTS [ÓPTIMO]" % rem_pts if seg_idx == 1 else "PRESUPUESTO: %d / 10 PTS (COSTE -2)" % rem_pts
	var bar_r: Rect2 = Rect2(rect.position.x + 10.0, rect.end.y - 26.0, rect.size.x - 20.0, 24.0)
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.get_world_color("heist"), alpha * 0.6), false, 1.0)
	canvas.draw_rect(Rect2(bar_r.position, Vector2(bar_r.size.x * (float(rem_pts) / 10.0), bar_r.size.y)), BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.35))
	canvas.draw_string(BrandClass.font_regular(), bar_r.position + Vector2(10.0, 16.0), bar_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.TEXT, alpha))


func _sim_hacker(canvas: CanvasItem, rect: Rect2, alpha: float, pulse: float) -> void:
	var top_banner: Rect2 = Rect2(rect.position.x + 10.0, rect.position.y + 8.0, rect.size.x - 20.0, 26.0)
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.get_world_color("hacker"), alpha * 0.6), false, 1.0)
	canvas.draw_string(BrandClass.font_regular(), top_banner.position + Vector2(10.0, 17.0), "MOVIMIENTO LATERAL & TRAMPA HONEYPOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.get_world_color("hacker"), alpha))

	var n_in: Vector2 = rect.position + Vector2(48.0, 150.0)
	var n_fw: Vector2 = rect.position + Vector2(155.0, 82.0)
	var n_piv: Vector2 = rect.position + Vector2(145.0, 215.0)
	var n_root: Vector2 = rect.position + Vector2(rect.size.x - 48.0, 150.0)
	var n_honey: Vector2 = rect.position + Vector2(rect.size.x - 68.0, 245.0)

	_draw_sim_badge(canvas, n_in + Vector2(0, 24), "ACCESO", BrandClass.TEXT, alpha, 11)
	_draw_sim_badge(canvas, n_fw + Vector2(0, -22), "🔒 FIREWALL", BrandClass.ENEMY, alpha, 11)
	_draw_sim_badge(canvas, n_piv + Vector2(0, 24), "[1] BYPASS SUBRED", BrandClass.SUCCESS, alpha, 11)
	_draw_sim_badge(canvas, n_root + Vector2(0, -22), "[2] ROOT OK", BrandClass.SUCCESS, alpha, 11)
	_draw_sim_badge(canvas, n_honey + Vector2(0, 24), "[4] SEÑUELO IDS", BrandClass.WARNING, alpha, 11)

	canvas.draw_line(n_in, n_fw, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.8), 1.5)
	canvas.draw_line(n_in, n_piv, BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.9), 2.5)
	canvas.draw_line(n_piv, n_root, BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.9), 2.5)
	canvas.draw_line(n_piv, n_honey, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.7), 1.5)

	for pos: Vector2 in [n_in, n_fw, n_piv, n_root]:
		canvas.draw_circle(pos, 10.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
		canvas.draw_circle(pos, 10.0, BrandClass.with_alpha(BrandClass.get_world_color("hacker"), alpha * 0.8), false, 1.5)

	# Honeydecoy node
	canvas.draw_circle(n_honey, 10.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_circle(n_honey, 10.0, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.9), false, 1.5)
	canvas.draw_arc(n_honey, 18.0 + sin(pulse * 3.0) * 3.0, 0, TAU, 16, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.7), 1.2)

	var lateral_pts: Array[Vector2] = [n_in, n_piv, n_root]
	var t_lat: float = fmod(_time * 0.9, 2.0)
	var l_idx: int = int(t_lat) % 2
	var l_t: float = fmod(t_lat, 1.0)
	var lpos: Vector2 = lateral_pts[l_idx].lerp(lateral_pts[l_idx + 1], l_t)
	canvas.draw_circle(lpos, 5.0, BrandClass.with_alpha(BrandClass.WARNING, alpha))
	canvas.draw_string(BrandClass.font_regular(), lpos + Vector2(8.0, -4.0), "N0X", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.WARNING, alpha))

	var noise_pct: int = 28 + int(abs(sin(_time * 1.4)) * 24.0)
	var bar_r: Rect2 = Rect2(rect.position.x + 10.0, rect.end.y - 26.0, rect.size.x - 20.0, 24.0)
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.get_world_color("hacker"), alpha * 0.6), false, 1.0)
	canvas.draw_rect(Rect2(bar_r.position, Vector2(bar_r.size.x * (float(noise_pct) / 100.0), bar_r.size.y)), BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.50))
	canvas.draw_string(BrandClass.font_regular(), bar_r.position + Vector2(10.0, 16.0), "RUIDO IDS: %d%% [SIGILO CONTROLADO]" % noise_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.TEXT, alpha))


static func sample_polyline(pts: PackedVector2Array, t: float) -> Vector2:
	if pts.is_empty():
		return Vector2.ZERO
	if pts.size() == 1:
		return pts[0]
	var total_len: float = 0.0
	var seg_lens: Array[float] = []
	for i: int in range(pts.size() - 1):
		var d: float = pts[i].distance_to(pts[i + 1])
		seg_lens.append(d)
		total_len += d
	if total_len <= 0.0001:
		return pts[0]
	var target_dist: float = clampf(t, 0.0, 1.0) * total_len
	var accum: float = 0.0
	for i: int in range(seg_lens.size()):
		var sl: float = seg_lens[i]
		if accum + sl >= target_dist or i == seg_lens.size() - 1:
			var local_t: float = (target_dist - accum) / sl if sl > 0.0001 else 0.0
			return pts[i].lerp(pts[i + 1], clampf(local_t, 0.0, 1.0))
		accum += sl
	return pts[pts.size() - 1]


func _sim_cyber(canvas: CanvasItem, rect: Rect2, alpha: float, pulse: float) -> void:
	var top_banner: Rect2 = Rect2(rect.position.x + 10.0, rect.position.y + 8.0, rect.size.x - 20.0, 26.0)
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.get_world_color("cybersecurity"), alpha * 0.6), false, 1.0)
	canvas.draw_string(BrandClass.font_regular(), top_banner.position + Vector2(10.0, 17.0), "CORTE MÍNIMO: BLOQUEO DE FLUJO HOSTIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.get_world_color("cybersecurity"), alpha))

	var n_apt: Vector2 = rect.position + Vector2(48.0, 160.0)
	var relays: Array[Vector2] = [
		rect.position + Vector2(130.0, 85.0),
		rect.position + Vector2(130.0, 160.0),
		rect.position + Vector2(130.0, 235.0)
	]
	var n_core: Vector2 = rect.position + Vector2(rect.size.x - 48.0, 160.0)

	_draw_sim_badge(canvas, n_apt + Vector2(0, 26), "ATACANTE", BrandClass.ENEMY, alpha, 11)
	_draw_sim_badge(canvas, n_core + Vector2(0, 26), "NÚCLEO SEGURO", BrandClass.SUCCESS, alpha, 11)

	var cut_x: float = rect.position.x + 185.0
	_draw_sim_badge(canvas, Vector2(cut_x, rect.position.y + 54.0), "✂ CORTE FIREWALL", BrandClass.WARNING, alpha, 11)

	var cy: float = rect.position.y + 65.0
	while cy < rect.end.y - 40.0:
		canvas.draw_line(Vector2(cut_x, cy), Vector2(cut_x, cy + 6.0), BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.9), 2.0)
		cy += 12.0

	for r_pos: Vector2 in relays:
		canvas.draw_line(n_apt, r_pos, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.7), 1.5)
		canvas.draw_line(r_pos, n_core, BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.8), 2.0)
		canvas.draw_circle(r_pos, 9.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
		canvas.draw_circle(r_pos, 9.0, BrandClass.with_alpha(BrandClass.get_world_color("cybersecurity"), alpha * 0.8), false, 1.5)
		canvas.draw_arc(r_pos, 14.0 + sin(pulse * 3.0) * 2.0, 0, TAU, 12, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.7), 1.0)

		# Animated packet streaming along [n_apt, r_pos, cut_pt] where cut_pt lies exactly on r_pos -> n_core
		var cut_frac: float = clampf((cut_x - r_pos.x) / maxf(1.0, n_core.x - r_pos.x), 0.0, 1.0)
		var cut_pt: Vector2 = r_pos.lerp(n_core, cut_frac)
		var pkt_t: float = fmod(_time * 1.5 + float(relays.find(r_pos)) * 0.33, 1.0)
		var pkt_pos: Vector2 = sample_polyline(PackedVector2Array([n_apt, r_pos, cut_pt]), pkt_t)
		canvas.draw_circle(pkt_pos, 4.0, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.95))
		canvas.draw_circle(cut_pt, 6.0 + sin(pulse * 4.0) * 2.0, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.8))

	canvas.draw_circle(n_apt, 11.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_circle(n_apt, 11.0, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.9), false, 2.0)
	canvas.draw_circle(n_core, 13.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_circle(n_core, 13.0, BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.9), false, 2.0)

	var edr_pct: int = 75 + int(fmod(_time * 12.0, 24.0))
	var bar_r: Rect2 = Rect2(rect.position.x + 10.0, rect.end.y - 26.0, rect.size.x - 20.0, 24.0)
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.get_world_color("cybersecurity"), alpha * 0.6), false, 1.0)
	canvas.draw_rect(Rect2(bar_r.position, Vector2(bar_r.size.x * (float(edr_pct) / 100.0), bar_r.size.y)), BrandClass.with_alpha(BrandClass.SUCCESS, alpha * 0.40))
	canvas.draw_string(BrandClass.font_regular(), bar_r.position + Vector2(10.0, 16.0), "RASTREO EDR: %d%% [AMENAZA CONTENIDA]" % edr_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.TEXT, alpha))


func _sim_sector0(canvas: CanvasItem, rect: Rect2, alpha: float, pulse: float) -> void:
	var top_banner: Rect2 = Rect2(rect.position.x + 10.0, rect.position.y + 8.0, rect.size.x - 20.0, 26.0)
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.6), false, 1.0)
	canvas.draw_string(BrandClass.font_regular(), top_banner.position + Vector2(10.0, 17.0), "CONVERGENCIA TRÍADA EN EL NÚCLEO OMEGA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.WARNING, alpha))

	var center: Vector2 = rect.position + Vector2(rect.size.x * 0.5, 162.0)
	canvas.draw_circle(center, 22.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_circle(center, 22.0, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.90), false, 2.0)
	canvas.draw_arc(center, 30.0 + sin(pulse * 3.0) * 4.0, 0, TAU, 24, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.5), 1.0)
	canvas.draw_string(BrandClass.font_regular(), center + Vector2(-6.0, 6.0), "Ω", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, BrandClass.with_alpha(BrandClass.WARNING, alpha))

	var triad_cols: Array[Color] = [
		BrandClass.get_world_color("heist"),
		BrandClass.get_world_color("hacker"),
		BrandClass.get_world_color("cybersecurity")
	]
	var triad_labels: Array[String] = ["VEX · DIJKSTRA", "N0X · PIVOTEO", "AEGIS · CORTE"]

	for i: int in range(3):
		var ang: float = _time * 0.6 + float(i) * (TAU / 3.0)
		var dpos: Vector2 = center + Vector2(cos(ang), sin(ang)) * 78.0
		var tcol: Color = triad_cols[i]
		canvas.draw_line(center, dpos, BrandClass.with_alpha(tcol, alpha * 0.4), 1.2)
		canvas.draw_circle(dpos, 9.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
		canvas.draw_circle(dpos, 9.0, BrandClass.with_alpha(tcol, alpha * 0.9), false, 1.5)
		_draw_sim_badge(canvas, dpos + Vector2(0, 24), triad_labels[i], tcol, alpha, 11)

		var t_in: float = fmod(_time * 1.0 + float(i) * 0.33, 1.0)
		var pkt_in: Vector2 = dpos.lerp(center, t_in)
		canvas.draw_circle(pkt_in, 3.5, BrandClass.with_alpha(tcol, alpha))

	var bar_r: Rect2 = Rect2(rect.position.x + 10.0, rect.end.y - 26.0, rect.size.x - 20.0, 24.0)
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.6), false, 1.0)
	canvas.draw_rect(Rect2(bar_r.position, Vector2(bar_r.size.x * 0.82, bar_r.size.y)), BrandClass.with_alpha(BrandClass.WARNING, alpha * 0.40))
	canvas.draw_string(BrandClass.font_regular(), bar_r.position + Vector2(10.0, 16.0), "SINCRONÍA TRÍADA Ω: 82% [3 OPERADORES]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.TEXT, alpha))


func _sim_free_ops(canvas: CanvasItem, rect: Rect2, alpha: float, _pulse: float) -> void:
	var top_banner: Rect2 = Rect2(rect.position.x + 10.0, rect.position.y + 8.0, rect.size.x - 20.0, 26.0)
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(top_banner, BrandClass.with_alpha(BrandClass.get_world_color("free_ops"), alpha * 0.6), false, 1.0)
	canvas.draw_string(BrandClass.font_regular(), top_banner.position + Vector2(10.0, 17.0), "SANDBOX: TOPOLOGÍA PROCEDURAL ABIERTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.get_world_color("free_ops"), alpha))

	var center: Vector2 = rect.position + Vector2(rect.size.x * 0.5, 162.0)
	_draw_sim_badge(canvas, center + Vector2(0, -26), "SANDBOX", BrandClass.get_world_color("free_ops"), alpha, 11)
	canvas.draw_circle(center, 16.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_circle(center, 16.0, BrandClass.with_alpha(BrandClass.get_world_color("free_ops"), alpha * 0.90), false, 2.0)

	var outer_pts: Array[Vector2] = []
	for i: int in range(6):
		var ang: float = _time * 0.4 + float(i) * (TAU / 6.0)
		var opos: Vector2 = center + Vector2(cos(ang), sin(ang)) * 78.0
		outer_pts.append(opos)
		canvas.draw_line(center, opos, BrandClass.with_alpha(BrandClass.get_world_color("free_ops"), alpha * 0.35), 1.0)
		canvas.draw_circle(opos, 9.0, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
		canvas.draw_circle(opos, 9.0, BrandClass.with_alpha(BrandClass.get_world_color("free_ops"), alpha * 0.8), false, 1.5)

	# Outer hexagon ring and animated colored packets
	var packet_colors: Array[Color] = [
		BrandClass.get_world_color("heist"),
		BrandClass.get_world_color("hacker"),
		BrandClass.get_world_color("cybersecurity")
	]
	for i: int in range(6):
		var p1: Vector2 = outer_pts[i]
		var p2: Vector2 = outer_pts[(i + 1) % 6]
		canvas.draw_line(p1, p2, BrandClass.with_alpha(BrandClass.get_world_color("free_ops"), alpha * 0.5), 1.2)
	
	for p_idx: int in range(3):
		var edge_idx: int = (p_idx * 2) % 6
		var p1: Vector2 = outer_pts[edge_idx]
		var p2: Vector2 = outer_pts[(edge_idx + 1) % 6]
		var t_fac: float = fmod(_time * 1.1 + float(p_idx) * 0.33, 1.0)
		var pkt_pos: Vector2 = p1.lerp(p2, t_fac)
		canvas.draw_circle(pkt_pos, 4.5, BrandClass.with_alpha(packet_colors[p_idx], alpha * 0.95))

	var bar_r: Rect2 = Rect2(rect.position.x + 10.0, rect.end.y - 26.0, rect.size.x - 20.0, 24.0)
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.9))
	canvas.draw_rect(bar_r, BrandClass.with_alpha(BrandClass.get_world_color("free_ops"), alpha * 0.6), false, 1.0)
	canvas.draw_string(BrandClass.font_regular(), bar_r.position + Vector2(10.0, 16.0), "MODO EXPANSIÓN: 3 ALGORITMOS COMBINADOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BrandClass.with_alpha(BrandClass.TEXT, alpha))


func _draw_right_dossier(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	ox: float,
	sel_item: Dictionary,
	_progress: Dictionary,
	font: Font,
	font_size: int,
	_big_font_size: int,
	active_col: Color
) -> void:
	var hov_launch: bool = bool(canvas.get("_hovered_launch")) if canvas.get("_hovered_launch") != null else false
	var dossier: Rect2 = get_dossier_rect(vp)
	dossier.position.x += ox

	canvas.draw_rect(dossier, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_rect(dossier, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.80), false, 1.0)
	canvas.draw_rect(Rect2(dossier.position.x, dossier.position.y, dossier.size.x, 3.0), active_col)

	var watermark_pos: Vector2 = Vector2(dossier.end.x - 42.0, dossier.position.y + 52.0)
	var vec_icon: String = str(sel_item.get("vector_icon", "default"))
	_draw_vector_icon(canvas, watermark_pos, vec_icon, 2.4, BrandClass.with_alpha(active_col, alpha * 0.10))

	var top_y: float = dossier.position.y + 18.0
	var left_x: float = dossier.position.x + 20.0
	var sec_code: String = str(sel_item.get("sec_code", "01"))
	canvas.draw_string(font, Vector2(left_x, top_y), "DOSSIER // SEC-%s" % sec_code, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(active_col, alpha))

	var title_str: String = str(sel_item.get("display_title", sel_item.get("label", "")))
	var d_title_fs: int = font_size + 1
	if font.get_string_size(title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, d_title_fs).x > dossier.size.x - 90.0:
		d_title_fs = font_size - 1
	canvas.draw_string(font, Vector2(left_x, top_y + 22.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, -1, d_title_fs, BrandClass.with_alpha(BrandClass.TEXT, alpha))

	var status_line: String = str(sel_item.get("status_line", ""))
	canvas.draw_string(font, Vector2(left_x, top_y + 42.0), status_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(active_col, alpha * 0.90))

	canvas.draw_line(Vector2(left_x, top_y + 54.0), Vector2(dossier.end.x - 20.0, top_y + 54.0), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.60), 1.0)

	var desc_y: float = top_y + 74.0
	var dossier_desc: String = str(sel_item.get("dossier_desc", sel_item.get("desc", "")))
	canvas.draw_multiline_string(font, Vector2(left_x, desc_y), dossier_desc, HORIZONTAL_ALIGNMENT_LEFT, dossier.size.x - 40.0, font_size - 2, 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.90))

	var metrics_y: float = desc_y + 90.0
	var metrics: Array[Dictionary] = [
		{"label": "ALGORITMO / MECÁNICA:", "val": str(sel_item.get("algorithm", "")), "col": active_col},
		{"label": "OPERADOR ASIGNADO:", "val": str(sel_item.get("operator", "")), "col": BrandClass.TEXT},
		{"label": "REQUISITO ACCESO:", "val": str(sel_item.get("unlock_req", "")), "col": BrandClass.SUCCESS}
	]

	for m: Dictionary in metrics:
		var lbl_str: String = str(m.get("label", ""))
		var val_str: String = str(m.get("val", ""))
		var m_col: Color = m.get("col", BrandClass.TEXT) as Color
		
		canvas.draw_string(font, Vector2(left_x, metrics_y), lbl_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.80))
		canvas.draw_string(font, Vector2(left_x, metrics_y + 15.0), val_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(m_col, alpha))
		
		metrics_y += 23.0
		canvas.draw_line(Vector2(left_x, metrics_y), Vector2(dossier.end.x - 20.0, metrics_y), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.35), 1.0)
		metrics_y += 13.0

	var launch_rect: Rect2 = get_launch_button_rect(vp)
	launch_rect.position.x += ox
	
	var launch_fill: Color = active_col if hov_launch else active_col
	var launch_alpha: float = 0.28 if hov_launch else 0.14
	canvas.draw_rect(launch_rect, BrandClass.with_alpha(launch_fill, alpha * launch_alpha))
	canvas.draw_rect(launch_rect, BrandClass.with_alpha(active_col, alpha * (0.95 if hov_launch else 0.90)), false, 2.0 if hov_launch else 1.5)
	if hov_launch:
		canvas.draw_rect(Rect2(launch_rect.position.x, launch_rect.position.y, 3.0, launch_rect.size.y), active_col)
		canvas.draw_rect(Rect2(launch_rect.end.x - 3.0, launch_rect.position.y, 3.0, launch_rect.size.y), active_col)
	
	var launch_str: String = "▸ [ ENTER // INICIAR INMERSIÓN ] ◂" if hov_launch else "[ ENTER // INICIAR INMERSIÓN ]"
	var l_size: Vector2 = font.get_string_size(launch_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
	var txt_col: Color = BrandClass.TEXT if hov_launch else active_col
	canvas.draw_string(font, Vector2(launch_rect.position.x + (launch_rect.size.x - l_size.x) * 0.5, launch_rect.position.y + 27.0), launch_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.with_alpha(txt_col, alpha))


func _draw_vector_icon(canvas: CanvasItem, pos: Vector2, icon_type: String, nscale: float, col: Color) -> void:
	match icon_type:
		"lock":
			var rw: float = 14.0 * nscale
			var rh: float = 11.0 * nscale
			canvas.draw_rect(Rect2(pos.x - rw * 0.5, pos.y - rh * 0.5 + 2.5 * nscale, rw, rh), col, false, 1.6 * nscale)
			var sh_r: float = 4.5 * nscale
			canvas.draw_arc(Vector2(pos.x, pos.y - rh * 0.5 + 2.5 * nscale), sh_r, PI, TAU, 14, col, 1.6 * nscale)
			canvas.draw_circle(Vector2(pos.x, pos.y + 2.0 * nscale), 1.8 * nscale, col)
		"heist":
			var pts: PackedVector2Array = PackedVector2Array([
				pos + Vector2(0, -9) * nscale,
				pos + Vector2(8, 0) * nscale,
				pos + Vector2(0, 9) * nscale,
				pos + Vector2(-8, 0) * nscale
			])
			canvas.draw_polyline(pts, col, 1.8 * nscale)
		"hacker":
			canvas.draw_line(pos + Vector2(-7, -6) * nscale, pos + Vector2(-1, 0) * nscale, col, 2.0 * nscale)
			canvas.draw_line(pos + Vector2(-1, 0) * nscale, pos + Vector2(-7, 6) * nscale, col, 2.0 * nscale)
			canvas.draw_line(pos + Vector2(2, 6) * nscale, pos + Vector2(8, 6) * nscale, col, 2.0 * nscale)
		"cyber":
			var spts: PackedVector2Array = PackedVector2Array([
				pos + Vector2(0, -10) * nscale,
				pos + Vector2(9, -5) * nscale,
				pos + Vector2(7, 4) * nscale,
				pos + Vector2(0, 10) * nscale,
				pos + Vector2(-7, 4) * nscale,
				pos + Vector2(-9, -5) * nscale,
				pos + Vector2(0, -10) * nscale
			])
			canvas.draw_polyline(spts, col, 1.8 * nscale)
		"tutorials":
			canvas.draw_line(pos + Vector2(-8, -2) * nscale, pos + Vector2(0, -7) * nscale, col, 1.8 * nscale)
			canvas.draw_line(pos + Vector2(0, -7) * nscale, pos + Vector2(8, -2) * nscale, col, 1.8 * nscale)
			canvas.draw_line(pos + Vector2(8, -2) * nscale, pos + Vector2(0, 3) * nscale, col, 1.8 * nscale)
			canvas.draw_line(pos + Vector2(0, 3) * nscale, pos + Vector2(-8, -2) * nscale, col, 1.8 * nscale)
			canvas.draw_line(pos + Vector2(8, -2) * nscale, pos + Vector2(8, 6) * nscale, col, 1.8 * nscale)
		"omega":
			canvas.draw_arc(pos, 16.0 * nscale, 0, TAU, 20, BrandClass.with_alpha(BrandClass.WARNING, col.a * 0.7), 1.0 * nscale, true)
			canvas.draw_circle(pos, 12.5 * nscale, BrandClass.with_alpha(col, col.a * 0.2))
			canvas.draw_arc(pos, 12.5 * nscale, 0, TAU, 20, col, 1.5 * nscale)
			canvas.draw_arc(pos + Vector2(0, -1) * nscale, 6.8 * nscale, PI * 0.78, TAU + PI * 0.22, 16, col, 2.4 * nscale)
			canvas.draw_line(pos + Vector2(-8.5, 6.2) * nscale, pos + Vector2(-3.2, 6.2) * nscale, col, 2.2 * nscale)
			canvas.draw_line(pos + Vector2(3.2, 6.2) * nscale, pos + Vector2(8.5, 6.2) * nscale, col, 2.2 * nscale)
		"network":
			var p1: Vector2 = pos + Vector2(0, -9) * nscale
			var p2: Vector2 = pos + Vector2(-8, 7) * nscale
			var p3: Vector2 = pos + Vector2(8, 7) * nscale
			canvas.draw_line(p1, p2, col, 1.6 * nscale)
			canvas.draw_line(p2, p3, col, 1.6 * nscale)
			canvas.draw_line(p3, p1, col, 1.6 * nscale)
			canvas.draw_circle(p1, 3.5 * nscale, col)
			canvas.draw_circle(p2, 3.5 * nscale, col)
			canvas.draw_circle(p3, 3.5 * nscale, col)
		_:
			canvas.draw_circle(pos, 4.0 * nscale, col)
