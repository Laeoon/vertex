class_name ProfileRenderer extends RefCounted

## ProfileRenderer
## Dedicated renderer for the Operator Profile Dossier (Perfil de Operador).
## Provides a clean, modern two-panel cyberpunk telemetry layout.
## All insignia, ranks, and technical copy in Spanish per specification.

const BrandClass = preload("res://juego/ui/brand.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")

const TABS: Array[Dictionary] = [
	{"id": "heist", "label": "HEIST", "color": BrandClass.SUCCESS},
	{"id": "hacker", "label": "HACKER", "color": BrandClass.ACCENT},
	{"id": "cybersecurity", "label": "CYBERSECURITY", "color": BrandClass.WARNING},
	{"id": "badges", "label": "CONDECORACIONES", "color": Color("b388ff")},
]


static func get_rank_info(total_stars: int) -> Dictionary:
	if total_stars >= 30:
		return {
			"title": "FANTASMA DE RED",
			"tier": "RANGO V",
			"color": Color("b388ff"),
			"icon": "ghost"
		}
	elif total_stars >= 20:
		return {
			"title": "ÉLITE CIBERNÉTICA",
			"tier": "RANGO IV",
			"color": BrandClass.WARNING,
			"icon": "elite"
		}
	elif total_stars >= 12:
		return {
			"title": "ESPECIALISTA EN INTRUSIÓN",
			"tier": "RANGO III",
			"color": BrandClass.ACCENT,
			"icon": "specialist"
		}
	elif total_stars >= 5:
		return {
			"title": "OPERADOR DE RED",
			"tier": "RANGO II",
			"color": BrandClass.SUCCESS,
			"icon": "operator"
		}
	else:
		return {
			"title": "INICIADO",
			"tier": "RANGO I",
			"color": Color("80d8ff"),
			"icon": "initiate"
		}


func get_back_button_rect(_vp: Vector2) -> Rect2:
	return Rect2(40.0, 36.0, 170.0, 36.0)


func get_name_box_rect(vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 320.0, 390.0)
	var left_x := 40.0
	var top_y := 96.0
	return Rect2(left_x + 20.0, top_y + 115.0, left_w - 40.0, 38.0)


func get_tab_rect(tab_idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 320.0, 390.0)
	var right_x := 40.0 + left_w + 24.0
	var right_w := vp.x - right_x - 40.0
	var tab_w := clampf(right_w / float(TABS.size()), 110.0, 170.0)
	var tab_h := 34.0
	var top_y := 142.0
	return Rect2(right_x + float(tab_idx) * (tab_w + 10.0), top_y, tab_w, tab_h)


func draw(
	canvas: CanvasItem,
	vp: Vector2,
	font: Font,
	font_size: int,
	big_font_size: int,
	pulse: float,
	player_name: String,
	editing_name: bool,
	cursor_pos: int,
	cursor_visible: bool,
	stats: Dictionary,
	world_progress: Dictionary,
	active_tab_idx: int,
	hovered_tab_idx: int,
	hovered_back: bool,
	hovered_name_box: bool,
	progress: Dictionary
) -> void:
	var alpha: float = 1.0

	# 1. Header Bar: Back Button, Dossier Title, System Status
	_draw_header(canvas, vp, alpha, font, font_size, big_font_size, hovered_back)

	# 2. Main Two-Panel Layout Boundaries
	var left_w := clampf(vp.x * 0.35, 320.0, 390.0)
	var left_x := 40.0
	var top_y := 96.0
	var panel_h := vp.y - top_y - 32.0

	var right_x := left_x + left_w + 24.0
	var right_w := vp.x - right_x - 40.0

	var left_rect := Rect2(left_x, top_y, left_w, panel_h)
	var right_rect := Rect2(right_x, top_y, right_w, panel_h)

	# 3. Left Panel: Operative Identity, Tactical Rank & Metrics
	_draw_left_panel(
		canvas,
		left_rect,
		alpha,
		font,
		font_size,
		big_font_size,
		pulse,
		player_name,
		editing_name,
		cursor_pos,
		cursor_visible,
		stats,
		hovered_name_box
	)

	# 4. Right Panel: Sector Telemetry, Tabs & Mission Breakdown
	_draw_right_panel(
		canvas,
		right_rect,
		alpha,
		font,
		font_size,
		big_font_size,
		pulse,
		stats,
		world_progress,
		active_tab_idx,
		hovered_tab_idx,
		progress
	)


func _draw_header(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	font: Font,
	font_size: int,
	big_font_size: int,
	hovered_back: bool
) -> void:
	# Back Button
	var btn_rect := get_back_button_rect(vp)
	if hovered_back:
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.85), false, 1.5)
		canvas.draw_string(font, Vector2(btn_rect.position.x + 16, btn_rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.ACCENT)
	else:
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.70))
		canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.40), false, 1.0)
		canvas.draw_string(font, Vector2(btn_rect.position.x + 16, btn_rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)

	# Dossier Title & Subtitle
	var title_txt := "DOSSIER DE OPERADOR"
	var tpos := Vector2(230.0, 52.0)
	canvas.draw_string(font, tpos, title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 4, BrandClass.ACCENT)

	var sub_txt := "REGISTRO DE IDENTIDAD Y TELEMETRÍA DE RED"
	canvas.draw_string(font, Vector2(230.0, 72.0), sub_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	# Right Tactical System Status Badge
	var sys_txt := "SISTEMA VERTEX // ACTIVO"
	var ssize := font.get_string_size(sys_txt, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 2)
	var badge_rect := Rect2(vp.x - ssize.x - 56.0, 36.0, ssize.x + 32.0, 36.0)
	canvas.draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.75))
	canvas.draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.45), false, 1.0)
	canvas.draw_string(font, Vector2(badge_rect.position.x + 16.0, badge_rect.position.y + 23.0), sys_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)


func _draw_left_panel(
	canvas: CanvasItem,
	rect: Rect2,
	alpha: float,
	font: Font,
	font_size: int,
	big_font_size: int,
	pulse: float,
	player_name: String,
	editing_name: bool,
	cursor_pos: int,
	cursor_visible: bool,
	stats: Dictionary,
	hovered_name_box: bool
) -> void:
	# Main Panel Plate
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.92))
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.50), false, 1.4)

	# Corner bracket decorations
	var cb := 10.0
	canvas.draw_line(rect.position, rect.position + Vector2(cb, 0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position, rect.position + Vector2(0, cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x - cb, rect.position.y), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + cb), BrandClass.ACCENT, 2.0)

	# Panel Header
	var h_rect := Rect2(rect.position.x, rect.position.y, rect.size.x, 34.0)
	canvas.draw_rect(h_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.12))
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + 34.0), Vector2(rect.position.x + rect.size.x, rect.position.y + 34.0), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.40), 1.0)
	canvas.draw_string(font, Vector2(rect.position.x + 14.0, rect.position.y + 23.0), "[IDENTIDAD DEL AGENTE]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)

	# Rank Info & Insignia
	var total_stars: int = stats.get("total_stars", 0)
	var rank_info := get_rank_info(total_stars)
	var rank_col: Color = rank_info["color"]

	# Avatar Glyphs Disk (Top Left of panel content)
	var avatar_center := Vector2(rect.position.x + 55.0, rect.position.y + 78.0)
	var avatar_r := 26.0
	canvas.draw_circle(avatar_center, avatar_r, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
	canvas.draw_circle(avatar_center, avatar_r, BrandClass.with_alpha(rank_col, alpha * 0.85), false, 1.5)
	canvas.draw_circle(avatar_center, avatar_r + 4.0, BrandClass.with_alpha(rank_col, alpha * 0.25), false, 1.0)
	_draw_rank_glyph(canvas, avatar_center, rank_info["icon"], rank_col, alpha)

	# Rank Text & Tier
	var rtier: String = rank_info["tier"]
	var rtitle: String = rank_info["title"]
	canvas.draw_string(font, Vector2(rect.position.x + 94.0, rect.position.y + 70.0), rtier, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(rank_col, alpha * 0.85))
	canvas.draw_string(font, Vector2(rect.position.x + 94.0, rect.position.y + 90.0), rtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.with_alpha(BrandClass.TEXT, alpha))

	# Alias / Call-sign Header & Input Box
	var name_box := Rect2(rect.position.x + 14.0, rect.position.y + 118.0, rect.size.x - 28.0, 36.0)
	var nb_bg := BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * (0.95 if editing_name else 0.75))
	var nb_border := BrandClass.with_alpha(BrandClass.ACCENT if (editing_name or hovered_name_box) else BrandClass.PANEL_BORDER, alpha * (0.90 if editing_name else 0.45))
	canvas.draw_rect(name_box, nb_bg)
	canvas.draw_rect(name_box, nb_border, false, 1.4 if editing_name else 1.0)

	var label_alias := "INDICATIVO: "
	var lsize := font.get_string_size(label_alias, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1)
	canvas.draw_string(font, Vector2(name_box.position.x + 10.0, name_box.position.y + 24.0), label_alias, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT_DIM)

	var text_x := name_box.position.x + 10.0 + lsize.x
	var display_name := player_name if player_name != "" else "Jugador"
	var name_col := BrandClass.TEXT if editing_name else BrandClass.ACCENT
	canvas.draw_string(font, Vector2(text_x, name_box.position.y + 24.0), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, name_col)

	# Blinking cursor while editing
	if editing_name and cursor_visible:
		var cur_sub := player_name.left(cursor_pos)
		var cur_w := font.get_string_size(cur_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1).x
		canvas.draw_rect(Rect2(text_x + cur_w + 1.0, name_box.position.y + 9.0, 2.0, font_size + 4), BrandClass.ACCENT)

	# Edit Hint Prompt below box
	var hint_y := name_box.position.y + 50.0
	if editing_name:
		var ehint := "[ENTER] Confirmar  [ESC] Cancelar"
		canvas.draw_string(font, Vector2(rect.position.x + 14.0, hint_y), ehint, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.ACCENT)
	else:
		var ehint := "[ENTER / CLIC] Editar indicativo"
		canvas.draw_string(font, Vector2(rect.position.x + 14.0, hint_y), ehint, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.75))

	# Metrics Divider
	var div_y := hint_y + 14.0
	canvas.draw_line(Vector2(rect.position.x + 14.0, div_y), Vector2(rect.position.x + rect.size.x - 14.0, div_y), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.40), 1.0)

	# Telemetry Metrics Rows
	var cur_y := div_y + 24.0
	var step_y := 32.0

	_draw_metric_row(canvas, font, font_size, rect.position.x + 14.0, rect.size.x - 28.0, cur_y, "ESTRELLAS TOTALES", "%d ★" % total_stars, BrandClass.WARNING)
	cur_y += step_y
	_draw_metric_row(canvas, font, font_size, rect.position.x + 14.0, rect.size.x - 28.0, cur_y, "NIVELES SUPERADOS", "%d" % stats.get("levels_completed", 0), BrandClass.TEXT)
	cur_y += step_y
	_draw_metric_row(canvas, font, font_size, rect.position.x + 14.0, rect.size.x - 28.0, cur_y, "TIEMPO DE ENLACE", _format_time(stats.get("play_time_seconds", 0)), BrandClass.TEXT)
	cur_y += step_y
	_draw_metric_row(canvas, font, font_size, rect.position.x + 14.0, rect.size.x - 28.0, cur_y, "MEJOR RACHA", "%d VICTORIAS" % stats.get("best_streak", 0), BrandClass.SUCCESS)
	cur_y += step_y
	_draw_metric_row(canvas, font, font_size, rect.position.x + 14.0, rect.size.x - 28.0, cur_y, "INTENTOS REGISTRADOS", "%d" % stats.get("total_attempts", 0), BrandClass.TEXT_DIM)
	cur_y += step_y

	# Victory Rate Progress Bar Card
	var win_rate: float = stats.get("win_rate", 0.0)
	var bar_card_y := cur_y + 6.0
	var bar_card_h := 54.0
	var bar_card_rect := Rect2(rect.position.x + 14.0, bar_card_y, rect.size.x - 28.0, bar_card_h)
	canvas.draw_rect(bar_card_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.75))
	canvas.draw_rect(bar_card_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.40), false, 1.0)

	canvas.draw_string(font, Vector2(bar_card_rect.position.x + 10.0, bar_card_rect.position.y + 20.0), "TASA DE ÉXITO OPERATIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	var wr_text := "%.0f%% (%d V / %d D)" % [win_rate, stats.get("total_wins", 0), stats.get("total_losses", 0)]
	var wr_sz := font.get_string_size(wr_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3)
	canvas.draw_string(font, Vector2(bar_card_rect.position.x + bar_card_rect.size.x - wr_sz.x - 10.0, bar_card_rect.position.y + 20.0), wr_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.SUCCESS if win_rate >= 50.0 else BrandClass.WARNING)

	# Progress Bar Fill
	var pb_x := bar_card_rect.position.x + 10.0
	var pb_y := bar_card_rect.position.y + 28.0
	var pb_w := bar_card_rect.size.x - 20.0
	var pb_h := 12.0
	canvas.draw_rect(Rect2(pb_x, pb_y, pb_w, pb_h), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.35))
	var fill_w := pb_w * clampf(win_rate / 100.0, 0.0, 1.0)
	if fill_w > 0:
		canvas.draw_rect(Rect2(pb_x, pb_y, fill_w, pb_h), BrandClass.SUCCESS if win_rate >= 50.0 else BrandClass.WARNING)


func _draw_right_panel(
	canvas: CanvasItem,
	rect: Rect2,
	alpha: float,
	font: Font,
	font_size: int,
	big_font_size: int,
	pulse: float,
	stats: Dictionary,
	world_progress: Dictionary,
	active_tab_idx: int,
	hovered_tab_idx: int,
	progress: Dictionary
) -> void:
	# Main Panel Plate
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.92))
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.50), false, 1.4)

	# Corner bracket decorations
	var cb := 10.0
	canvas.draw_line(rect.position, rect.position + Vector2(cb, 0), BrandClass.ACCENT, 2.0)
	canvas.draw_line(rect.position, rect.position + Vector2(0, cb), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x - cb, rect.position.y), BrandClass.ACCENT, 2.0)
	canvas.draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + cb), BrandClass.ACCENT, 2.0)

	# Header Plate
	var h_rect := Rect2(rect.position.x, rect.position.y, rect.size.x, 34.0)
	canvas.draw_rect(h_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.12))
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + 34.0), Vector2(rect.position.x + rect.size.x, rect.position.y + 34.0), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.40), 1.0)
	var header_title := "[REGISTRO DE CONDECORACIONES & MÉRITOS]" if active_tab_idx == 3 else "[TELEMETRÍA DE SECTORES & HISTORIAL DE MISIÓN]"
	canvas.draw_string(font, Vector2(rect.position.x + 14.0, rect.position.y + 23.0), header_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)

	# World Selector Tabs
	var top_tabs_y := rect.position.y + 44.0
	var tab_w := clampf((rect.size.x - 40.0) / float(TABS.size()), 100.0, 180.0)
	var tab_h := 32.0

	for i in range(TABS.size()):
		var tab_item := TABS[i]
		var tab_rect := Rect2(rect.position.x + 14.0 + float(i) * (tab_w + 8.0), top_tabs_y, tab_w, tab_h)
		var is_active := i == active_tab_idx
		var is_hover := i == hovered_tab_idx
		var tcol: Color = tab_item["color"]

		var tbg := BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * (0.95 if is_active else 0.70))
		var tbdr := BrandClass.with_alpha(tcol if (is_active or is_hover) else BrandClass.PANEL_BORDER, alpha * (0.90 if is_active else 0.40))
		canvas.draw_rect(tab_rect, tbg)
		canvas.draw_rect(tab_rect, tbdr, false, 1.4 if is_active else 1.0)
		if is_active:
			canvas.draw_line(Vector2(tab_rect.position.x + 2, tab_rect.position.y + tab_h - 2), Vector2(tab_rect.position.x + tab_w - 2, tab_rect.position.y + tab_h - 2), tcol, 2.0)

		var tlabel: String = tab_item["label"]
		var lpos := Vector2(tab_rect.position.x + tab_w * 0.5, tab_rect.position.y + 21.0)
		var lsize := font.get_string_size(tlabel, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3)
		canvas.draw_string(font, lpos - Vector2(lsize.x * 0.5, 0), tlabel, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3, BrandClass.TEXT if is_active else BrandClass.TEXT_DIM)

	if active_tab_idx == 3:
		_draw_badges_view(canvas, rect, alpha, font, font_size, top_tabs_y + tab_h + 12.0, stats)
		return

	# Active World Telemetry Card
	var active_tab: Dictionary = TABS[active_tab_idx]
	var active_wid: String = active_tab["id"]
	var active_col: Color = active_tab["color"]
	var is_unlocked := ProgressUtilClass.is_world_unlocked(active_wid, progress)

	var info_box_y := top_tabs_y + tab_h + 12.0
	var info_box_h := 48.0
	var info_rect := Rect2(rect.position.x + 14.0, info_box_y, rect.size.x - 28.0, info_box_h)
	canvas.draw_rect(info_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.85))
	canvas.draw_rect(info_rect, BrandClass.with_alpha(active_col if is_unlocked else BrandClass.WARNING, alpha * 0.45), false, 1.0)

	var sec_title := "SECTOR: %s" % active_tab["label"]
	canvas.draw_string(font, Vector2(info_rect.position.x + 14.0, info_rect.position.y + 22.0), sec_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)

	var status_txt := "ESTADO: AUTORIZADO // ENLACE DISPONIBLE" if is_unlocked else ("ESTADO: RESTRINGIDO // %s" % ProgressUtilClass.get_world_lock_reason(active_wid, progress))
	canvas.draw_string(font, Vector2(info_rect.position.x + 14.0, info_rect.position.y + 40.0), status_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, active_col if is_unlocked else BrandClass.WARNING)

	var sec_stars: int = world_progress.get(active_wid, {}).get("stars", 0)
	var stars_text := "ESTRELLAS DE SECTOR: %d ★" % sec_stars
	var stars_sz := font.get_string_size(stars_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1)
	canvas.draw_string(font, Vector2(info_rect.position.x + info_rect.size.x - stars_sz.x - 14.0, info_rect.position.y + 22.0), stars_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.WARNING)

	# Mission Breakdown Table Header
	var table_y := info_box_y + info_box_h + 16.0
	var col_x_level := rect.position.x + 14.0
	var col_x_stars := rect.position.x + rect.size.x * 0.42
	var col_x_cost := rect.position.x + rect.size.x * 0.60
	var col_x_vd := rect.position.x + rect.size.x * 0.76

	var th_rect := Rect2(rect.position.x + 14.0, table_y, rect.size.x - 28.0, 24.0)
	canvas.draw_rect(th_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.25))

	canvas.draw_string(font, Vector2(col_x_level + 8.0, table_y + 17.0), "MISIÓN / OPERACIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	canvas.draw_string(font, Vector2(col_x_stars, table_y + 17.0), "CALIFICACIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	canvas.draw_string(font, Vector2(col_x_cost, table_y + 17.0), "MEJOR COSTE", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	canvas.draw_string(font, Vector2(col_x_vd, table_y + 17.0), "V / D (INTENTOS)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	# Table Rows
	var row_y := table_y + 28.0
	var row_h := 28.0
	var rows: Array = stats.get("levels_detail", [])

	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var r_rect := Rect2(rect.position.x + 14.0, row_y, rect.size.x - 28.0, row_h)
		var has_data: bool = row.get("attempts", 0) > 0 or row.get("stars", 0) > 0

		# Alternating stripe
		if i % 2 == 1:
			canvas.draw_rect(r_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.45))

		var rcol := BrandClass.TEXT if has_data else BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.50)
		var stars_count: int = row.get("stars", 0)

		# Misión Title
		var title_txt: String = String(row.get("title", row.get("key", ""))).to_upper()
		canvas.draw_string(font, Vector2(col_x_level + 8.0, row_y + 19.0), title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, rcol)

		# Stars String
		var s_str := ""
		for si in range(3):
			s_str += "★" if si < stars_count else "☆"
		canvas.draw_string(font, Vector2(col_x_stars, row_y + 19.0), s_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.WARNING if stars_count > 0 else BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.40))

		# Best Cost
		var cost_val: float = float(row.get("best_cost", 0.0))
		var cost_str := "%.1f" % cost_val if cost_val > 0.0 else "—"
		canvas.draw_string(font, Vector2(col_x_cost, row_y + 19.0), cost_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, rcol)

		# V/D Attempts
		var w_cnt: int = int(row.get("wins", 0))
		var l_cnt: int = int(row.get("losses", 0))
		var att_cnt: int = int(row.get("attempts", 0))
		var att_str := "%d / %d (%d)" % [w_cnt, l_cnt, att_cnt] if att_cnt > 0 else "—"
		canvas.draw_string(font, Vector2(col_x_vd, row_y + 19.0), att_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, rcol)

		row_y += row_h + 3.0


func _draw_metric_row(
	canvas: CanvasItem,
	font: Font,
	font_size: int,
	x: float,
	w: float,
	y: float,
	label: String,
	value: String,
	val_color: Color
) -> void:
	canvas.draw_string(font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
	var vsize := font.get_string_size(value, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1)
	canvas.draw_string(font, Vector2(x + w - vsize.x, y), value, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1, val_color)


func _draw_rank_glyph(
	canvas: CanvasItem,
	pos: Vector2,
	icon_type: String,
	col: Color,
	alpha: float
) -> void:
	match icon_type:
		"ghost":
			# Spectral cyber visor / dual arc
			canvas.draw_arc(pos, 14.0, PI * 0.2, PI * 0.8, 10, BrandClass.with_alpha(col, alpha), 2.0)
			canvas.draw_arc(pos, 14.0, PI * 1.2, PI * 1.8, 10, BrandClass.with_alpha(col, alpha), 2.0)
			canvas.draw_circle(pos, 4.0, BrandClass.with_alpha(col, alpha))
		"elite":
			# Diamond with central core
			var pts := PackedVector2Array([
				pos + Vector2(0, -12),
				pos + Vector2(12, 0),
				pos + Vector2(0, 12),
				pos + Vector2(-12, 0),
				pos + Vector2(0, -12)
			])
			canvas.draw_polyline(pts, BrandClass.with_alpha(col, alpha), 1.8)
			canvas.draw_circle(pos, 3.5, BrandClass.with_alpha(col, alpha))
		"specialist":
			# Hexagonal reticle
			var hpts := PackedVector2Array()
			for s in range(7):
				var a := float(s) * TAU / 6.0
				hpts.append(pos + Vector2(cos(a) * 12.0, sin(a) * 12.0))
			canvas.draw_polyline(hpts, BrandClass.with_alpha(col, alpha), 1.6)
			canvas.draw_circle(pos, 3.0, BrandClass.with_alpha(col, alpha))
		"operator":
			# Tactical crosshairs & dual bars
			canvas.draw_arc(pos, 11.0, 0, TAU, 18, BrandClass.with_alpha(col, alpha), 1.5)
			canvas.draw_line(pos + Vector2(-14, 0), pos + Vector2(14, 0), BrandClass.with_alpha(col, alpha * 0.7), 1.2)
		_:
			# Initiate: simple glowing ring & dot
			canvas.draw_arc(pos, 10.0, 0, TAU, 16, BrandClass.with_alpha(col, alpha), 1.4)
			canvas.draw_circle(pos, 2.5, BrandClass.with_alpha(col, alpha))


func _draw_badges_view(
	canvas: CanvasItem,
	rect: Rect2,
	alpha: float,
	font: Font,
	font_size: int,
	start_y: float,
	stats: Dictionary
) -> void:
	var badges: Array = stats.get("badges", [])
	var unlocked_count: int = 0
	for b in badges:
		if b.get("unlocked", false):
			unlocked_count += 1

	# Telemetry summary card
	var sum_h := 44.0
	var sum_rect := Rect2(rect.position.x + 14.0, start_y, rect.size.x - 28.0, sum_h)
	canvas.draw_rect(sum_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.85))
	canvas.draw_rect(sum_rect, BrandClass.with_alpha(Color("b388ff"), alpha * 0.45), false, 1.0)

	var title_text := "ESTADO DE MÉRITOS MILITARES // ACCESO CLASIFICADO"
	canvas.draw_string(font, Vector2(sum_rect.position.x + 14.0, sum_rect.position.y + 20.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT)
	var count_str := "%d / %d CONCEDIDAS" % [unlocked_count, badges.size()]
	var count_sz := font.get_string_size(count_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1)
	canvas.draw_string(font, Vector2(sum_rect.position.x + sum_rect.size.x - count_sz.x - 14.0, sum_rect.position.y + 20.0), count_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1, Color("b388ff"))

	var desc_sub := "Condecoraciones evaluadas de forma retroactiva a partir del registro operativo."
	canvas.draw_string(font, Vector2(sum_rect.position.x + 14.0, sum_rect.position.y + 36.0), desc_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	# 2-column Grid of Badges
	var grid_y := start_y + sum_h + 12.0
	var col_gap := 10.0
	var row_gap := 8.0
	var col_w := (rect.size.x - 28.0 - col_gap) * 0.5
	var card_h := 62.0

	for i in range(badges.size()):
		var b: Dictionary = badges[i]
		var col_idx := i % 2
		var row_idx := i / 2
		var cx := rect.position.x + 14.0 + float(col_idx) * (col_w + col_gap)
		var cy := grid_y + float(row_idx) * (card_h + row_gap)
		var c_rect := Rect2(cx, cy, col_w, card_h)

		var is_unlocked: bool = b.get("unlocked", false)
		var b_color: Color = Color("b388ff") if is_unlocked else BrandClass.PANEL_BORDER

		# Card plate
		canvas.draw_rect(c_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * (0.90 if is_unlocked else 0.50)))
		canvas.draw_rect(c_rect, BrandClass.with_alpha(b_color, alpha * (0.80 if is_unlocked else 0.25)), false, 1.2 if is_unlocked else 1.0)

		# Vector Glyph Disk
		var g_center := Vector2(cx + 26.0, cy + card_h * 0.5)
		var g_rad := 16.0
		canvas.draw_circle(g_center, g_rad, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
		canvas.draw_circle(g_center, g_rad, BrandClass.with_alpha(b_color, alpha * (0.90 if is_unlocked else 0.35)), false, 1.2)
		_draw_badge_glyph(canvas, g_center, b.get("icon", ""), b_color, alpha * (1.0 if is_unlocked else 0.40))

		# Title & description
		var tx := cx + 50.0
		var title_col := BrandClass.TEXT if is_unlocked else BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.70)
		canvas.draw_string(font, Vector2(tx, cy + 18.0), b.get("title", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, title_col)
		canvas.draw_string(font, Vector2(tx, cy + 34.0), b.get("description", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)

		# Progress bar or Granted Tag
		if is_unlocked:
			var tag := "[CONCEDIDA]"
			var t_sz := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4)
			canvas.draw_string(font, Vector2(cx + col_w - t_sz.x - 8.0, cy + 18.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.SUCCESS)
		else:
			var cur: int = b.get("current", 0)
			var tgt: int = b.get("target", 1)
			var prog_str := "%d/%d" % [cur, tgt]
			var p_sz := font.get_string_size(prog_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4)
			canvas.draw_string(font, Vector2(cx + col_w - p_sz.x - 8.0, cy + 18.0), prog_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)

			# Small progress line
			var bar_x := tx
			var bar_y := cy + 44.0
			var bar_w := col_w - 58.0
			var bar_h := 3.0
			canvas.draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.30))
			var ratio: float = b.get("progress_ratio", 0.0)
			if ratio > 0.0:
				canvas.draw_rect(Rect2(bar_x, bar_y, bar_w * ratio, bar_h), BrandClass.with_alpha(Color("b388ff"), alpha * 0.60))


func _draw_badge_glyph(
	canvas: CanvasItem,
	pos: Vector2,
	icon_type: String,
	col: Color,
	alpha: float
) -> void:
	match icon_type:
		"glyph_breach":
			# Prompt >_
			canvas.draw_line(pos + Vector2(-6, -5), pos + Vector2(-1, 0), BrandClass.with_alpha(col, alpha), 1.5)
			canvas.draw_line(pos + Vector2(-1, 0), pos + Vector2(-6, 5), BrandClass.with_alpha(col, alpha), 1.5)
			canvas.draw_line(pos + Vector2(2, 5), pos + Vector2(7, 5), BrandClass.with_alpha(col, alpha), 1.5)
		"glyph_ghost":
			# Arc + center dot
			canvas.draw_arc(pos, 8.0, PI * 0.2, PI * 0.8, 8, BrandClass.with_alpha(col, alpha), 1.5)
			canvas.draw_arc(pos, 8.0, PI * 1.2, PI * 1.8, 8, BrandClass.with_alpha(col, alpha), 1.5)
			canvas.draw_circle(pos, 2.5, BrandClass.with_alpha(col, alpha))
		"glyph_vault":
			# Hexagonal key
			var pts := PackedVector2Array()
			for s in range(7):
				var a := float(s) * TAU / 6.0
				pts.append(pos + Vector2(cos(a) * 7.0, sin(a) * 7.0))
			canvas.draw_polyline(pts, BrandClass.with_alpha(col, alpha), 1.4)
			canvas.draw_rect(Rect2(pos.x - 2, pos.y - 2, 4, 4), BrandClass.with_alpha(col, alpha))
		"glyph_network":
			# Diamond network
			canvas.draw_line(pos + Vector2(0, -7), pos + Vector2(7, 0), BrandClass.with_alpha(col, alpha), 1.2)
			canvas.draw_line(pos + Vector2(7, 0), pos + Vector2(0, 7), BrandClass.with_alpha(col, alpha), 1.2)
			canvas.draw_line(pos + Vector2(0, 7), pos + Vector2(-7, 0), BrandClass.with_alpha(col, alpha), 1.2)
			canvas.draw_line(pos + Vector2(-7, 0), pos + Vector2(0, -7), BrandClass.with_alpha(col, alpha), 1.2)
			canvas.draw_circle(pos, 2.0, BrandClass.with_alpha(col, alpha))
		"glyph_shield":
			# Defense shield
			var spts := PackedVector2Array([
				pos + Vector2(-6, -6),
				pos + Vector2(6, -6),
				pos + Vector2(5, 2),
				pos + Vector2(0, 7),
				pos + Vector2(-5, 2),
				pos + Vector2(-6, -6)
			])
			canvas.draw_polyline(spts, BrandClass.with_alpha(col, alpha), 1.4)
		"glyph_streak":
			# Lightning bolt
			var lpts := PackedVector2Array([
				pos + Vector2(1, -7),
				pos + Vector2(-4, 0),
				pos + Vector2(0, 0),
				pos + Vector2(-1, 7),
				pos + Vector2(4, -1),
				pos + Vector2(0, -1),
				pos + Vector2(1, -7)
			])
			canvas.draw_polyline(lpts, BrandClass.with_alpha(col, alpha), 1.3)
		"glyph_stars":
			# Star triad
			canvas.draw_circle(pos + Vector2(0, -5), 2.0, BrandClass.with_alpha(col, alpha))
			canvas.draw_circle(pos + Vector2(-5, 4), 2.0, BrandClass.with_alpha(col, alpha))
			canvas.draw_circle(pos + Vector2(5, 4), 2.0, BrandClass.with_alpha(col, alpha))
		"glyph_chip":
			# Integrated circuit microchip
			canvas.draw_rect(Rect2(pos.x - 5, pos.y - 5, 10, 10), BrandClass.with_alpha(col, alpha), false, 1.2)
			canvas.draw_line(pos + Vector2(-8, 0), pos + Vector2(-5, 0), BrandClass.with_alpha(col, alpha), 1.2)
			canvas.draw_line(pos + Vector2(5, 0), pos + Vector2(8, 0), BrandClass.with_alpha(col, alpha), 1.2)
		"glyph_radar":
			# Concentric sweep
			canvas.draw_arc(pos, 7.0, 0, TAU, 14, BrandClass.with_alpha(col, alpha), 1.2)
			canvas.draw_line(pos, pos + Vector2(5, -5), BrandClass.with_alpha(col, alpha), 1.4)
		"glyph_crown":
			# Crown chevron
			var cpts := PackedVector2Array([
				pos + Vector2(-7, 5),
				pos + Vector2(-6, -4),
				pos + Vector2(-2, 0),
				pos + Vector2(0, -6),
				pos + Vector2(2, 0),
				pos + Vector2(6, -4),
				pos + Vector2(7, 5),
				pos + Vector2(-7, 5)
			])
			canvas.draw_polyline(cpts, BrandClass.with_alpha(col, alpha), 1.3)
		_:
			canvas.draw_arc(pos, 6.0, 0, TAU, 12, BrandClass.with_alpha(col, alpha), 1.2)


func _format_time(seconds: int) -> String:
	var h: int = int(seconds) / 3600
	var m: int = (int(seconds) % 3600) / 60
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%dm" % m
