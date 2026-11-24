class_name ProfileRenderer extends RefCounted

## ProfileRenderer
## Dedicated renderer for the Operator Profile Dossier & LA BÓVEDA (5-Tab Neural Hub).
## Tab 0: Expediente & 24 Insignias Tácticas
## Tab 1: Decodificador // Archivos (.ENC) (Fallout RobCo Terminal Minigame)
## Tab 2: Terminal Lab & Academia CLI UNIX
## Tab 3: MusicBox (22 DavidKBD Tracks with Progressive Unlocks)
## Tab 4: Cosméticos de Nodo (Diegetic Maintenance & Blueprint Screen)

const BrandClass = preload("res://juego/ui/brand.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

static var _style_cache: Dictionary = {}
static var _cached_crt_material: ShaderMaterial = null

const TABS: Array[Dictionary] = [
	{"id": "expediente", "code": "01", "name": "INSIGNIAS", "sub": "5 ÁRBOLES // RANGO", "label": "01 // INSIGNIAS", "color": Color("#00E5FF")},
	{"id": "decodificador", "code": "02", "name": "TERMLINK .ENC", "sub": "MEMORIA FORENSE", "label": "02 // TERMLINK .ENC", "color": Color("#39FF88")},
	{"id": "terminal_lab", "code": "03", "name": "TERMINAL & LAB", "sub": "VTX-SH // YAZI", "label": "03 // TERMINAL & LAB", "color": Color("#FFC857")},
	{"id": "musicbox", "code": "04", "name": "MUSICBOX FFT", "sub": "22 TRACKS // AUDIO", "label": "04 // MUSICBOX FFT", "color": Color("#FF2E88")},
	{"id": "cosmeticos", "code": "05", "name": "ARCADE /usr/games/", "sub": "CARTUCHOS 3D", "label": "05 // ARCADE /usr/games/", "color": Color("#BF5AF2")},
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


static func make_surface_style(bg_col: Color, border_col: Color = Color.TRANSPARENT, left_accent: Color = Color.TRANSPARENT, bottom_accent: Color = Color.TRANSPARENT, radius: int = 2) -> StyleBoxFlat:
	var cache_key: String = "%s|%s|%s|%s|%d" % [bg_col.to_html(), border_col.to_html(), left_accent.to_html(), bottom_accent.to_html(), radius]
	if _style_cache.has(cache_key):
		return _style_cache[cache_key] as StyleBoxFlat
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.border_width_left = 0
	sb.border_width_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 0
	sb.border_color = Color.TRANSPARENT

	if left_accent != Color.TRANSPARENT:
		sb.border_width_left = 3
		sb.border_color = left_accent
	elif bottom_accent != Color.TRANSPARENT:
		sb.border_width_bottom = 2
		sb.border_color = bottom_accent
	elif border_col != Color.TRANSPARENT:
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = border_col
	_style_cache[cache_key] = sb
	return sb


static func create_crt_overlay() -> ColorRect:
	var cr := ColorRect.new()
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _cached_crt_material == null:
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	float scanline = sin(uv.y * 800.0) * 0.04;
	float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y) * 15.0;
	vignette = clamp(pow(vignette, 0.25), 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, (0.07 - scanline) * (1.0 - vignette * 0.5));
}
"""
		_cached_crt_material = ShaderMaterial.new()
		_cached_crt_material.shader = shader
	cr.material = _cached_crt_material
	return cr


static func draw_equalizer(canvas: CanvasItem, rect: Rect2, mags: PackedFloat32Array, is_playing: bool, pulse: float) -> void:
	var bar_count: int = 28
	var bar_w: float = 4.0
	var gap: float = 2.0
	var total_w: float = float(bar_count) * (bar_w + gap) - gap
	var start_x: float = rect.position.x + (rect.size.x - total_w) * 0.5
	var max_h: float = rect.size.y - 8.0

	for i in range(bar_count):
		var bx: float = start_x + float(i) * (bar_w + gap)
		var mag: float = 0.0
		if mags.size() > i:
			mag = mags[i]
		elif is_playing:
			mag = 0.2 + 0.8 * abs(sin(pulse * 6.0 + float(i) * 0.3))
		else:
			mag = 0.05

		var bar_h: float = clampf(mag * max_h, 4.0, max_h)
		var by: float = rect.position.y + rect.size.y - bar_h - 4.0
		var bar_rect := Rect2(bx, by, bar_w, bar_h)

		var t: float = float(i) / float(max(1, bar_count - 1))
		var col: Color = Color("#B026FF").lerp(Color("#00F0FF"), t)
		canvas.draw_rect(bar_rect, col)


static func draw_cosmetics_maintenance(canvas: CanvasItem, rect: Rect2, font: Font, font_size: int, big_font_size: int, pulse: float) -> void:
	var bp_rect := Rect2(rect.position.x + 24.0, rect.position.y + 54.0, rect.size.x - 48.0, rect.size.y - 80.0)
	canvas.draw_rect(bp_rect, Color("0E131A"))
	canvas.draw_rect(bp_rect, Color("00d2ff"), false, 1.5)

	var scan_y: int = int(bp_rect.position.y + fmod(pulse * 120.0, bp_rect.size.y))
	canvas.draw_line(Vector2(bp_rect.position.x, float(scan_y)), Vector2(bp_rect.position.x + bp_rect.size.x, float(scan_y)), Color("00d2ff"), 2.0)

	var by: float = bp_rect.position.y + 40.0
	canvas.draw_string(font, Vector2(bp_rect.position.x + 32.0, by), "ESQUEMAS GEOMÉTRICOS DE NODO // FASE II", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 4, Color("00d2ff"))
	by += 36.0
	canvas.draw_string(font, Vector2(bp_rect.position.x + 32.0, by), "CALIBRACIÓN DE SKINS Y ESTELAS DE RED: EN PROCESO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)
	by += 40.0

	var warn_box := Rect2(bp_rect.position.x + 32.0, by, bp_rect.size.x - 64.0, 110.0)
	canvas.draw_rect(warn_box, BrandClass.with_alpha(BrandClass.WARNING, 0.15))
	canvas.draw_rect(warn_box, BrandClass.with_alpha(BrandClass.WARNING, 0.80), false, 1.5)
	canvas.draw_string(font, Vector2(warn_box.position.x + 20.0, warn_box.position.y + 28.0), "[ ⚠ SUBSISTEMA DE COSMÉTICOS EN MANTENIMIENTO // PRÓXIMA ACTUALIZACIÓN ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.WARNING)
	canvas.draw_string(font, Vector2(warn_box.position.x + 20.0, warn_box.position.y + 56.0), "Los protocolos de personalización estética de nodos coaxiales y estelas de red se encuentran", HORIZONTAL_ALIGNMENT_LEFT, int(warn_box.size.x - 40.0), font_size - 1, BrandClass.TEXT)
	canvas.draw_string(font, Vector2(warn_box.position.x + 20.0, warn_box.position.y + 80.0), "actualmente en fase de pruebas en La Bóveda de Sector 0. Estará disponible próximamente.", HORIZONTAL_ALIGNMENT_LEFT, int(warn_box.size.x - 40.0), font_size - 1, BrandClass.TEXT)


func get_back_button_rect(_vp: Vector2) -> Rect2:
	return Rect2(228.0, 32.0, 96.0, 44.0)


func get_name_box_rect(vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var left_x := 24.0
	var top_y := 24.0
	return Rect2(left_x + 16.0, top_y + 112.0, left_w - 32.0, 40.0)


func get_tab_rect(tab_idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var tab_w := clampf((right_w - 32.0) / float(TABS.size()), 90.0, 150.0)
	var tab_h := 44.0
	var top_y := 24.0
	return Rect2(right_x + float(tab_idx) * (tab_w + 6.0), top_y, tab_w, tab_h)


func get_badge_cell_rect(idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)

	var cols: int = 4
	var cell_w: float = (content_rect.size.x - 340.0 - 24.0 - float(cols - 1) * 8.0) / float(cols)
	var cell_h: float = 64.0
	var r: int = idx / cols
	var c: int = idx % cols
	var start_x: float = content_rect.position.x + 12.0
	var start_y: float = content_rect.position.y + 54.0
	return Rect2(start_x + float(c) * (cell_w + 8.0), start_y + float(r) * (cell_h + 8.0), cell_w, cell_h)


func get_feature_badge_btn_rect(vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var panel_w: float = 320.0
	var panel_x: float = content_rect.position.x + content_rect.size.x - panel_w
	var panel_y: float = content_rect.position.y + 12.0
	var panel_h: float = content_rect.size.y - 24.0
	return Rect2(panel_x + 16.0, panel_y + panel_h - 60.0, panel_w - 32.0, 44.0)


func get_enc_file_rect(idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = 260.0
	var start_y: float = content_rect.position.y + 48.0
	return Rect2(content_rect.position.x + 12.0, start_y + float(idx) * 64.0, col_w - 12.0, 52.0)


func get_enc_reset_btn_rect(vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = 260.0
	var right_col_x: float = content_rect.position.x + col_w + 12.0
	var right_col_w: float = right_w - col_w - 24.0
	return Rect2(right_col_x + 24.0, content_rect.position.y + content_rect.size.y - 70.0, right_col_w - 48.0, 44.0)


func get_hex_row_rect(hr_idx: int, vp: Vector2) -> Rect2:
	var left_w: float = clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x: float = 24.0 + left_w + 24.0
	var right_w: float = vp.x - right_x - 24.0
	var content_rect: Rect2 = Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = 260.0
	var right_col_x: float = content_rect.position.x + col_w + 12.0
	var right_col_w: float = content_rect.size.x - col_w - 24.0
	var col_idx: int = hr_idx / 14
	var row_in_col: int = hr_idx % 14
	var half_w: float = (right_col_w - 36.0) * 0.5
	var rx: float = right_col_x + 16.0 + float(col_idx) * (half_w + 12.0)
	var ry: float = content_rect.position.y + 48.0 + 64.0 + float(row_in_col) * 20.0
	return Rect2(rx, ry, half_w, 19.0)


func get_cli_course_rect(idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = 300.0
	var start_y: float = content_rect.position.y + 36.0
	return Rect2(content_rect.position.x + 12.0, start_y + float(idx) * 52.0, col_w - 12.0, 44.0)


func get_cli_cmd_ref_rect(idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = 300.0
	var start_y: float = content_rect.position.y + 264.0
	return Rect2(content_rect.position.x + 12.0, start_y + float(idx) * 26.0, col_w - 12.0, 24.0)


func get_cli_input_rect(vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = 300.0
	var right_col_x: float = content_rect.position.x + col_w + 12.0
	var right_col_w: float = right_w - col_w - 24.0
	return Rect2(right_col_x + 12.0, content_rect.position.y + content_rect.size.y - 64.0, right_col_w - 120.0, 44.0)


func get_cli_exec_btn_rect(vp: Vector2) -> Rect2:
	var input_rect := get_cli_input_rect(vp)
	return Rect2(input_rect.position.x + input_rect.size.x + 8.0, input_rect.position.y, 96.0, 44.0)


func get_music_filter_rect(idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = right_w - 360.0
	var filter_w: float = (col_w - 24.0) / 3.0
	return Rect2(content_rect.position.x + 12.0 + float(idx) * (filter_w + 6.0), content_rect.position.y + 12.0, filter_w, 40.0)


func get_music_row_rect(vis_idx: int, vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var col_w: float = right_w - 360.0
	var start_y: float = content_rect.position.y + 64.0
	return Rect2(content_rect.position.x + 12.0, start_y + float(vis_idx) * 44.0, col_w - 12.0, 40.0)


func get_music_pin_menu_rect(vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var panel_x: float = content_rect.position.x + right_w - 330.0
	return Rect2(panel_x + 16.0, content_rect.position.y + content_rect.size.y - 112.0, 298.0, 44.0)


func get_music_pin_game_rect(vp: Vector2) -> Rect2:
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var right_x := 24.0 + left_w + 24.0
	var right_w := vp.x - right_x - 24.0
	var content_rect := Rect2(right_x + 14.0, 80.0, right_w - 28.0, vp.y - 116.0)
	var panel_x: float = content_rect.position.x + right_w - 330.0
	return Rect2(panel_x + 16.0, content_rect.position.y + content_rect.size.y - 60.0, 298.0, 44.0)


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
	progress: Dictionary,
	selected_badge_idx: int,
	featured_badge_title: String,
	selected_enc_idx: int,
	enc_unlocked: Dictionary,
	enc_attempts: int,
	enc_console_lines: Array,
	enc_input_text: String,
	removed_duds: Array,
	active_cli_course: int,
	cli_course_step: int,
	cli_output_lines: Array,
	cli_input_text: String,
	editing_cli: bool,
	music_filter_idx: int,
	music_scroll_offset: int,
	selected_music_idx: int,
	pinned_menu_track: String,
	pinned_game_track: String
) -> void:
	var alpha: float = 1.0

	# 1. Background Fill & CRT Scanlines
	canvas.draw_rect(Rect2(Vector2.ZERO, vp), Color("080c14"))
	for sy in range(0, int(vp.y), 4):
		canvas.draw_line(Vector2(0.0, float(sy)), Vector2(vp.x, float(sy)), Color(0, 0, 0, 0.08), 1.0)

	# 2. Main Two-Panel Layout Boundaries (Left Fixed ID Card & Right 5-Tab Hub)
	var left_w := clampf(vp.x * 0.35, 310.0, 350.0)
	var left_x := 24.0
	var top_y := 24.0
	var panel_h := vp.y - top_y - 24.0

	var right_x := left_x + left_w + 24.0
	var right_w := vp.x - right_x - 24.0

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
		hovered_name_box,
		featured_badge_title,
		vp
	)

	# 4. Right Panel: LA BÓVEDA // 5-Tab Hub
	_draw_right_panel(
		canvas,
		right_rect,
		alpha,
		font,
		font_size,
		big_font_size,
		pulse,
		stats,
		active_tab_idx,
		hovered_tab_idx,
		progress,
		vp,
		selected_badge_idx,
		selected_enc_idx,
		enc_unlocked,
		enc_attempts,
		enc_console_lines,
		enc_input_text,
		removed_duds,
		active_cli_course,
		cli_course_step,
		cli_output_lines,
		cli_input_text,
		editing_cli,
		music_filter_idx,
		music_scroll_offset,
		selected_music_idx,
		pinned_menu_track,
		pinned_game_track
	)


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
	hovered_name_box: bool,
	featured_badge_title: String,
	vp: Vector2
) -> void:
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.90))
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.60), false, 1.5)

	var pad := 18.0
	var cur_y: float = rect.position.y + pad

	# Brand Bar & Back Button
	canvas.draw_string(font, Vector2(rect.position.x + pad, cur_y + 14.0), "VERTEX // KERNEL_LINK v4.08", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
	var btn_rect := get_back_button_rect(vp)
	canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
	canvas.draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.70), false, 1.0)
	canvas.draw_string(font, Vector2(btn_rect.position.x + 12.0, btn_rect.position.y + 27.0), "[ ← VOLVER ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.ACCENT)

	cur_y += 36.0
	canvas.draw_line(Vector2(rect.position.x + pad, cur_y), Vector2(rect.position.x + rect.size.x - pad, cur_y), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.5), 1.0)
	cur_y += 16.0

	# Operator Rank & Title
	var total_stars: int = int(stats.get("total_stars", 0))
	var rank_info := get_rank_info(total_stars)
	canvas.draw_string(font, Vector2(rect.position.x + pad, cur_y + 16.0), "ESTADO DEL OPERADOR", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)
	cur_y += 22.0
	canvas.draw_string(font, Vector2(rect.position.x + pad, cur_y + 24.0), str(rank_info["title"]), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 4, rank_info["color"])
	cur_y += 30.0
	canvas.draw_string(font, Vector2(rect.position.x + pad, cur_y + 14.0), "%s // ESTRELLAS: %d ★" % [str(rank_info["tier"]), total_stars], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.SUCCESS)

	cur_y += 24.0
	# Editable Name Box
	var name_box := get_name_box_rect(vp)
	var ncolor := BrandClass.ACCENT if editing_name else (BrandClass.SUCCESS if hovered_name_box else BrandClass.PANEL_BORDER)
	canvas.draw_rect(name_box, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	canvas.draw_rect(name_box, BrandClass.with_alpha(ncolor, 0.80), false, 1.5)
	canvas.draw_string(font, Vector2(name_box.position.x + 12.0, name_box.position.y + 26.0), player_name + ("_" if editing_name and cursor_visible else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)

	cur_y += 54.0

	# Featured Badge Banner
	if not featured_badge_title.is_empty():
		var feat_rect := Rect2(rect.position.x + pad, cur_y, rect.size.x - (pad * 2.0), 38.0)
		canvas.draw_rect(feat_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.15))
		canvas.draw_rect(feat_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.60), false, 1.0)
		canvas.draw_string(font, Vector2(feat_rect.position.x + 10.0, feat_rect.position.y + 24.0), "★ DESTACADA: %s" % featured_badge_title.left(24), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
		cur_y += 48.0

	# Telemetry Metrics Rows
	var badges_unlocked: Array = stats.get("badges", [])
	var win_rate: float = float(stats.get("win_rate", 0.0))
	var metrics: Array[String] = [
		"Niveles Superados: %d" % int(stats.get("levels_completed", 0)),
		"Tiempo de Enlace: %ds" % int(stats.get("play_time_seconds", 0)),
		"Racha Máxima: %d" % int(stats.get("best_streak", 0)),
		"Ratio de Victoria: %.1f%%" % win_rate,
		"Insignias Tácticas: %d / 24" % badges_unlocked.size()
	]

	for m in metrics:
		canvas.draw_string(font, Vector2(rect.position.x + pad, cur_y + 16.0), m, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT)
		cur_y += 26.0

	cur_y = maxf(cur_y, rect.position.y + rect.size.y - 150.0)
	canvas.draw_line(Vector2(rect.position.x + pad, cur_y), Vector2(rect.position.x + rect.size.x - pad, cur_y), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.5), 1.0)
	cur_y += 14.0

	# 3 Clickable Save Slot Buttons at bottom of left panel
	var slot_w := (rect.size.x - (pad * 2.0) - 16.0) / 3.0
	for s_idx in range(3):
		var s_rect := Rect2(rect.position.x + pad + float(s_idx) * (slot_w + 8.0), cur_y, slot_w, 40.0)
		canvas.draw_rect(s_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.80))
		canvas.draw_rect(s_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), false, 1.0)
		canvas.draw_string(font, Vector2(s_rect.position.x + 8.0, s_rect.position.y + 25.0), "SLOT 0%d" % (s_idx + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)


func _draw_right_panel(
	canvas: CanvasItem,
	rect: Rect2,
	alpha: float,
	font: Font,
	font_size: int,
	big_font_size: int,
	pulse: float,
	stats: Dictionary,
	active_tab_idx: int,
	hovered_tab_idx: int,
	progress: Dictionary,
	vp: Vector2,
	selected_badge_idx: int,
	selected_enc_idx: int,
	enc_unlocked: Dictionary,
	enc_attempts: int,
	enc_console_lines: Array,
	enc_input_text: String,
	removed_duds: Array,
	active_cli_course: int,
	cli_course_step: int,
	cli_output_lines: Array,
	cli_input_text: String,
	editing_cli: bool,
	music_filter_idx: int,
	music_scroll_offset: int,
	selected_music_idx: int,
	pinned_menu_track: String,
	pinned_game_track: String
) -> void:
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.90))
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.60), false, 1.5)

	# Draw 5 Top Tabs
	for i in range(TABS.size()):
		var t_rect := get_tab_rect(i, vp)
		var is_active: bool = (i == active_tab_idx)
		var is_hover: bool = (i == hovered_tab_idx)
		var tcolor: Color = TABS[i]["color"]

		if is_active:
			canvas.draw_rect(t_rect, BrandClass.with_alpha(tcolor, 0.25))
			canvas.draw_rect(t_rect, BrandClass.with_alpha(tcolor, 0.90), false, 2.0)
			canvas.draw_string(font, Vector2(t_rect.position.x + 10.0, t_rect.position.y + 27.0), str(TABS[i]["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, tcolor)
		elif is_hover:
			canvas.draw_rect(t_rect, BrandClass.with_alpha(tcolor, 0.12))
			canvas.draw_rect(t_rect, BrandClass.with_alpha(tcolor, 0.50), false, 1.0)
			canvas.draw_string(font, Vector2(t_rect.position.x + 10.0, t_rect.position.y + 27.0), str(TABS[i]["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT)
		else:
			canvas.draw_rect(t_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.70))
			canvas.draw_rect(t_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), false, 1.0)
			canvas.draw_string(font, Vector2(t_rect.position.x + 10.0, t_rect.position.y + 27.0), str(TABS[i]["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)

	# Module Content Area (Starts at y = 80.0, zero overlap with tabs)
	var content_rect := Rect2(rect.position.x + 14.0, 80.0, rect.size.x - 28.0, vp.y - 116.0)

	match active_tab_idx:
		0:
			_draw_tab_badges(canvas, content_rect, font, font_size, big_font_size, stats, selected_badge_idx, vp)
		1:
			_draw_tab_decodificador(canvas, content_rect, font, font_size, big_font_size, selected_enc_idx, enc_unlocked, enc_attempts, enc_console_lines, enc_input_text, removed_duds, vp)
		2:
			_draw_tab_terminal_lab(canvas, content_rect, font, font_size, big_font_size, active_cli_course, cli_course_step, cli_output_lines, cli_input_text, editing_cli, vp)
		3:
			_draw_tab_musicbox(canvas, content_rect, font, font_size, big_font_size, music_filter_idx, music_scroll_offset, selected_music_idx, pinned_menu_track, pinned_game_track, stats, vp)
		4:
			_draw_tab_cosmeticos(canvas, content_rect, font, font_size, big_font_size, pulse, vp)


func _draw_tab_badges(canvas: CanvasItem, rect: Rect2, font: Font, font_size: int, big_font_size: int, stats: Dictionary, selected_badge_idx: int, vp: Vector2) -> void:
	canvas.draw_string(font, Vector2(rect.position.x + 12.0, rect.position.y + 24.0), "INSIGNIAS TÁCTICAS Y LOGROS DE RED (24 REGISTROS)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.ACCENT)

	var unlocked_badges: Array = stats.get("badges", [])
	var cols: int = 4
	for i in range(VaultModules.BADGES.size()):
		var badge: Dictionary = VaultModules.BADGES[i]
		var cell_rect := get_badge_cell_rect(i, vp)
		var is_unlocked: bool = unlocked_badges.has(badge["id"]) or i < 4
		var is_selected: bool = (i == selected_badge_idx)

		var bcolor: Color = BrandClass.SUCCESS if is_unlocked else BrandClass.TEXT_DIM
		if is_selected:
			canvas.draw_rect(cell_rect, BrandClass.with_alpha(bcolor, 0.25))
			canvas.draw_rect(cell_rect, BrandClass.with_alpha(bcolor, 0.90), false, 2.0)
		else:
			canvas.draw_rect(cell_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.75))
			canvas.draw_rect(cell_rect, BrandClass.with_alpha(bcolor, 0.40), false, 1.0)

		var glyph: String = str(badge.get("glyph", "◈"))
		canvas.draw_string(font, Vector2(cell_rect.position.x + 10.0, cell_rect.position.y + 26.0), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 8, bcolor)
		canvas.draw_string(font, Vector2(cell_rect.position.x + 36.0, cell_rect.position.y + 22.0), str(badge.get("title", "")).left(16), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT if is_unlocked else BrandClass.TEXT_DIM)
		canvas.draw_string(font, Vector2(cell_rect.position.x + 36.0, cell_rect.position.y + 42.0), "[✓] " + str(badge.get("rarity", "COMÚN")) if is_unlocked else "[🔒] BLOQUEADA", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, bcolor)

	# Right Inspector Panel for selected badge
	var panel_w: float = 320.0
	var panel_x: float = rect.position.x + rect.size.x - panel_w
	var panel_y: float = rect.position.y + 12.0
	var panel_h: float = rect.size.y - 24.0
	var panel_rect := Rect2(panel_x, panel_y, panel_w, panel_h)

	canvas.draw_rect(panel_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	canvas.draw_rect(panel_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.60), false, 1.5)

	if selected_badge_idx >= 0 and selected_badge_idx < VaultModules.BADGES.size():
		var sel_badge: Dictionary = VaultModules.BADGES[selected_badge_idx]
		var is_unlocked: bool = unlocked_badges.has(sel_badge["id"]) or selected_badge_idx < 4
		var py: float = panel_rect.position.y + 24.0

		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "INSPECTOR DE INSIGNIA", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
		py += 32.0
		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), str(sel_badge.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, BrandClass.TEXT)
		py += 26.0
		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Rareza: " + str(sel_badge.get("rarity", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.SUCCESS if is_unlocked else BrandClass.WARNING)
		py += 30.0

		var glyph_frame := Rect2(panel_rect.position.x + 16.0, py, 64.0, 64.0)
		canvas.draw_rect(glyph_frame, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
		canvas.draw_rect(glyph_frame, BrandClass.with_alpha(BrandClass.ACCENT, 0.50), false, 1.0)
		canvas.draw_string(font, Vector2(glyph_frame.position.x + 16.0, glyph_frame.position.y + 44.0), str(sel_badge.get("glyph", "◈")), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 12, BrandClass.ACCENT)
		py += 76.0

		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Descripción:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
		py += 20.0
		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), str(sel_badge.get("desc", "")), HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 32.0), font_size - 1, BrandClass.TEXT)
		py += 50.0

		if is_unlocked:
			canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Estado: [✓ DESBLOQUEADA]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)
		else:
			canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Requisito de Desbloqueo:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.WARNING)
			py += 20.0
			canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), str(sel_badge.get("req", "")), HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 32.0), font_size - 1, BrandClass.TEXT_DIM)

		var pin_btn := get_feature_badge_btn_rect(vp)
		canvas.draw_rect(pin_btn, BrandClass.with_alpha(BrandClass.ACCENT, 0.25))
		canvas.draw_rect(pin_btn, BrandClass.with_alpha(BrandClass.ACCENT, 0.80), false, 1.5)
		canvas.draw_string(font, Vector2(pin_btn.position.x + 16.0, pin_btn.position.y + 27.0), "[ ★ DESTACAR EN CARNET ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.ACCENT)


func _draw_tab_decodificador(canvas: CanvasItem, rect: Rect2, font: Font, font_size: int, big_font_size: int, selected_enc_idx: int, enc_unlocked: Dictionary, enc_attempts: int, enc_console_lines: Array, enc_input_text: String, removed_duds: Array, vp: Vector2) -> void:
	canvas.draw_string(font, Vector2(rect.position.x + 12.0, rect.position.y + 24.0), "DECODIFICADOR DE EXPEDIENTES .ENC // VERTEX // KERNEL_LINK TERMLINK v4.0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)

	var col_w: float = 260.0
	var left_col_rect := Rect2(rect.position.x + 12.0, rect.position.y + 48.0, col_w - 12.0, rect.size.y - 64.0)

	for i in range(VaultModules.ENC_FILES.size()):
		var enc_file: Dictionary = VaultModules.ENC_FILES[i]
		var f_rect := get_enc_file_rect(i, vp)
		var is_sel: bool = (i == selected_enc_idx)
		var is_unl: bool = bool(enc_unlocked.get(enc_file["file"], false))

		var fcolor: Color = BrandClass.SUCCESS if is_unl else BrandClass.ACCENT
		if is_sel:
			canvas.draw_rect(f_rect, BrandClass.with_alpha(fcolor, 0.30))
			canvas.draw_rect(f_rect, BrandClass.with_alpha(fcolor, 0.90), false, 2.0)
		else:
			canvas.draw_rect(f_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.80))
			canvas.draw_rect(f_rect, BrandClass.with_alpha(fcolor, 0.40), false, 1.0)

		canvas.draw_string(font, Vector2(f_rect.position.x + 10.0, f_rect.position.y + 22.0), str(enc_file["file"]).left(22), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, fcolor)
		canvas.draw_string(font, Vector2(f_rect.position.x + 10.0, f_rect.position.y + 40.0), "[✓ DESENCRIPTADO]" if is_unl else "[🔒 BLOQUEADO — CLIC PARA HACKEAR]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.SUCCESS if is_unl else BrandClass.TEXT_DIM)

	var meta_rect := Rect2(left_col_rect.position.x, left_col_rect.position.y + 280.0, left_col_rect.size.x, left_col_rect.size.y - 280.0)
	canvas.draw_rect(meta_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
	canvas.draw_rect(meta_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.50), false, 1.0)
	if selected_enc_idx >= 0 and selected_enc_idx < VaultModules.ENC_FILES.size():
		var sel_enc: Dictionary = VaultModules.ENC_FILES[selected_enc_idx]
		canvas.draw_string(font, Vector2(meta_rect.position.x + 12.0, meta_rect.position.y + 22.0), "METADATOS DEL ARCHIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
		canvas.draw_string(font, Vector2(meta_rect.position.x + 12.0, meta_rect.position.y + 44.0), "Peso: " + str(sel_enc.get("weight", "32 KB")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT)
		canvas.draw_string(font, Vector2(meta_rect.position.x + 12.0, meta_rect.position.y + 66.0), "Cifrado: " + str(sel_enc.get("cipher", "AES-512")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT)
		canvas.draw_string(font, Vector2(meta_rect.position.x + 12.0, meta_rect.position.y + 88.0), "Hash: " + str(sel_enc.get("hash", "0x00..00")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
		canvas.draw_string(font, Vector2(meta_rect.position.x + 12.0, meta_rect.position.y + 110.0), "VFS: /home/operator/expedientes/", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.SUCCESS)

	var right_col_x: float = rect.position.x + col_w + 12.0
	var right_col_w: float = rect.size.x - col_w - 24.0
	var right_col_rect := Rect2(right_col_x, rect.position.y + 48.0, right_col_w, rect.size.y - 64.0)

	canvas.draw_rect(right_col_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	canvas.draw_rect(right_col_rect, BrandClass.with_alpha(BrandClass.SUCCESS, 0.50), false, 1.5)

	if selected_enc_idx >= 0 and selected_enc_idx < VaultModules.ENC_FILES.size():
		var sel_enc: Dictionary = VaultModules.ENC_FILES[selected_enc_idx]
		var is_unl: bool = bool(enc_unlocked.get(sel_enc["file"], false))

		if is_unl:
			var ry: float = right_col_rect.position.y + 24.0
			canvas.draw_string(font, Vector2(right_col_rect.position.x + 20.0, ry), "EXPEDIENTE DESENCRIPTADO // " + str(sel_enc.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)
			ry += 32.0
			canvas.draw_string(font, Vector2(right_col_rect.position.x + 20.0, ry), "Clasificación: " + str(sel_enc.get("classification", "")) + " | Afiliación: " + str(sel_enc.get("affiliation", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
			ry += 28.0
			canvas.draw_string(font, Vector2(right_col_rect.position.x + 20.0, ry), "Objetivo: " + str(sel_enc.get("target", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT)
			ry += 28.0
			canvas.draw_line(Vector2(right_col_rect.position.x + 20.0, ry), Vector2(right_col_rect.position.x + right_col_rect.size.x - 20.0, ry), BrandClass.with_alpha(BrandClass.SUCCESS, 0.4), 1.0)
			ry += 20.0

			var content_str: String = str(sel_enc.get("content", ""))
			canvas.draw_multiline_string(font, Vector2(right_col_rect.position.x + 20.0, ry), content_str, HORIZONTAL_ALIGNMENT_LEFT, right_col_rect.size.x - 40.0, font_size - 1, 14, BrandClass.TEXT)

			var reset_btn := get_enc_reset_btn_rect(vp)
			canvas.draw_rect(reset_btn, BrandClass.with_alpha(BrandClass.SUCCESS, 0.25))
			canvas.draw_rect(reset_btn, BrandClass.with_alpha(BrandClass.SUCCESS, 0.80), false, 1.5)
			canvas.draw_string(font, Vector2(reset_btn.position.x + 16.0, reset_btn.position.y + 27.0), "[ ↻ VOLVER A MATRIZ HEX ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.SUCCESS)

		else:
			var ry: float = right_col_rect.position.y + 20.0
			canvas.draw_string(font, Vector2(right_col_rect.position.x + 16.0, ry), "VERTEX // KERNEL_LINK TERMLINK // ACCESO RESTRINGIDO A ARCHIVO .ENC", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.WARNING)
			ry += 22.0
			canvas.draw_string(font, Vector2(right_col_rect.position.x + 16.0, ry), "INTENTOS RESTANTES: " + "█ ".repeat(enc_attempts).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
			ry += 22.0

			# 2-Column x 14-Row Dense Hex Dump Layout
			var hex_rows := VaultModules.build_hex_dump_rows(selected_enc_idx, removed_duds)
			for hr_idx in range(hex_rows.size()):
				var hrow: Dictionary = hex_rows[hr_idx]
				var r_box := get_hex_row_rect(hr_idx, vp)
				var t_str: String = str(hrow.get("token", ""))
				var t_type: String = str(hrow.get("token_type", ""))

				if not t_str.is_empty():
					var pill_col: Color = BrandClass.SUCCESS if t_type == "word" else BrandClass.WARNING
					canvas.draw_rect(r_box, BrandClass.with_alpha(pill_col, 0.14))
					canvas.draw_rect(r_box, BrandClass.with_alpha(pill_col, 0.60), false, 1.0)

				var addr_s: String = str(hrow["addr"])
				var raw_s: String = str(hrow["raw"])
				var row_color: Color = BrandClass.TEXT
				if not t_str.is_empty():
					row_color = BrandClass.SUCCESS if t_type == "word" else BrandClass.WARNING

				canvas.draw_string(font, Vector2(r_box.position.x, r_box.position.y + 14.0), addr_s + "  " + raw_s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, row_color)

			var log_y: float = right_col_rect.position.y + 64.0 + 14.0 * 20.0 + 16.0
			canvas.draw_string(font, Vector2(right_col_rect.position.x + 16.0, log_y), "Consola de Terminal RobCo:", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.ACCENT)
			log_y += 20.0
			for clog in enc_console_lines:
				canvas.draw_string(font, Vector2(right_col_rect.position.x + 16.0, log_y), str(clog), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.SUCCESS if "Correcto" in str(clog) or "ACCESO" in str(clog) else BrandClass.WARNING)
				log_y += 18.0


func _draw_tab_terminal_lab(canvas: CanvasItem, rect: Rect2, font: Font, font_size: int, big_font_size: int, active_cli_course: int, cli_course_step: int, cli_output_lines: Array, cli_input_text: String, editing_cli: bool, vp: Vector2) -> void:
	canvas.draw_string(font, Vector2(rect.position.x + 12.0, rect.position.y + 24.0), "ACADEMIA CLI UNIX & LABORATORIO DE COMANDOS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.WARNING)

	var col_w: float = 300.0
	var left_col_rect := Rect2(rect.position.x + 12.0, rect.position.y + 36.0, col_w - 12.0, rect.size.y - 48.0)

	canvas.draw_string(font, Vector2(left_col_rect.position.x, left_col_rect.position.y + 14.0), "SELECTOR DE CURSOS PRÁCTICOS", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)
	for i in range(VaultModules.TERMINAL_ACADEMY_LESSONS.size()):
		var course: Dictionary = VaultModules.TERMINAL_ACADEMY_LESSONS[i]
		var c_rect := get_cli_course_rect(i, vp)
		var is_sel: bool = (i == active_cli_course)

		var ccolor: Color = BrandClass.WARNING if is_sel else BrandClass.TEXT_DIM
		if is_sel:
			canvas.draw_rect(c_rect, BrandClass.with_alpha(ccolor, 0.25))
			canvas.draw_rect(c_rect, BrandClass.with_alpha(ccolor, 0.90), false, 2.0)
		else:
			canvas.draw_rect(c_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.75))
			canvas.draw_rect(c_rect, BrandClass.with_alpha(ccolor, 0.40), false, 1.0)

		canvas.draw_string(font, Vector2(c_rect.position.x + 10.0, c_rect.position.y + 26.0), "CURSO 0%d: Módulo %d" % [i + 1, i + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, ccolor)

	var ref_title_y: float = left_col_rect.position.y + 236.0
	canvas.draw_string(font, Vector2(left_col_rect.position.x, ref_title_y), "LISTA DE COMANDOS DISPONIBLES", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.SUCCESS)

	for r_idx in range(VaultModules.CLI_COMMAND_REFERENCE.size()):
		var cref: Dictionary = VaultModules.CLI_COMMAND_REFERENCE[r_idx]
		var r_rect := get_cli_cmd_ref_rect(r_idx, vp)
		canvas.draw_string(font, Vector2(r_rect.position.x + 4.0, r_rect.position.y + 16.0), str(cref["cmd"]), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.ACCENT)
		canvas.draw_string(font, Vector2(r_rect.position.x + 120.0, r_rect.position.y + 16.0), str(cref["desc"]).left(24), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.TEXT_DIM)

	var right_col_x: float = rect.position.x + col_w + 12.0
	var right_col_w: float = rect.size.x - col_w - 24.0
	var right_col_rect := Rect2(right_col_x, rect.position.y + 36.0, right_col_w, rect.size.y - 48.0)

	canvas.draw_rect(right_col_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	canvas.draw_rect(right_col_rect, BrandClass.with_alpha(BrandClass.WARNING, 0.60), false, 1.5)

	var mission_rect := Rect2(right_col_rect.position.x + 12.0, right_col_rect.position.y + 12.0, right_col_rect.size.x - 24.0, 48.0)
	canvas.draw_rect(mission_rect, BrandClass.with_alpha(BrandClass.WARNING, 0.15))
	canvas.draw_rect(mission_rect, BrandClass.with_alpha(BrandClass.WARNING, 0.50), false, 1.0)

	var active_course: Dictionary = VaultModules.TERMINAL_ACADEMY_LESSONS[active_cli_course]
	var steps: Array = active_course.get("steps", [])
	var step_text: String = ""
	if cli_course_step < steps.size():
		step_text = str(steps[cli_course_step].get("instruction", ""))
	else:
		step_text = "[✓] ¡Curso completado con éxito!"

	canvas.draw_string(font, Vector2(mission_rect.position.x + 12.0, mission_rect.position.y + 30.0), step_text, HORIZONTAL_ALIGNMENT_LEFT, int(mission_rect.size.x - 24.0), font_size - 2, BrandClass.WARNING)

	var out_y: float = mission_rect.position.y + mission_rect.size.y + 16.0
	for line_str in cli_output_lines:
		canvas.draw_string(font, Vector2(right_col_rect.position.x + 16.0, out_y), str(line_str), HORIZONTAL_ALIGNMENT_LEFT, int(right_col_rect.size.x - 32.0), font_size - 2, BrandClass.TEXT)
		out_y += 20.0

	var input_rect := get_cli_input_rect(vp)
	var exec_btn := get_cli_exec_btn_rect(vp)

	canvas.draw_rect(input_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
	canvas.draw_rect(input_rect, BrandClass.with_alpha(BrandClass.WARNING if editing_cli else BrandClass.PANEL_BORDER, 0.80), false, 1.5)
	canvas.draw_string(font, Vector2(input_rect.position.x + 12.0, input_rect.position.y + 27.0), "operator@vertex-vault:/home/operator$ " + cli_input_text + ("_" if editing_cli else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT)

	canvas.draw_rect(exec_btn, BrandClass.with_alpha(BrandClass.WARNING, 0.25))
	canvas.draw_rect(exec_btn, BrandClass.with_alpha(BrandClass.WARNING, 0.80), false, 1.5)
	canvas.draw_string(font, Vector2(exec_btn.position.x + 14.0, exec_btn.position.y + 27.0), "[ ▶ EJECUTAR ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.WARNING)


func _draw_tab_musicbox(canvas: CanvasItem, rect: Rect2, font: Font, font_size: int, big_font_size: int, music_filter_idx: int, music_scroll_offset: int, selected_music_idx: int, pinned_menu_track: String, pinned_game_track: String, stats: Dictionary, vp: Vector2) -> void:
	canvas.draw_string(font, Vector2(rect.position.x + 12.0, rect.position.y + 24.0), "MUSICBOX KERNEL // 22 PISTAS DE DAVIDKBD CON DESBLOQUEO PROGRESIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("bf5af2"))

	var col_w: float = rect.size.x - 360.0

	var filters: Array[String] = ["TODOS (22)", "PINK BLOOM (10)", "CODE INJECTION (12)"]
	for f_idx in range(filters.size()):
		var f_rect := get_music_filter_rect(f_idx, vp)
		var is_fsel: bool = (f_idx == music_filter_idx)
		var fcolor: Color = Color("bf5af2") if is_fsel else BrandClass.TEXT_DIM

		if is_fsel:
			canvas.draw_rect(f_rect, BrandClass.with_alpha(fcolor, 0.25))
			canvas.draw_rect(f_rect, BrandClass.with_alpha(fcolor, 0.90), false, 2.0)
		else:
			canvas.draw_rect(f_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.75))
			canvas.draw_rect(f_rect, BrandClass.with_alpha(fcolor, 0.40), false, 1.0)
		canvas.draw_string(font, Vector2(f_rect.position.x + 12.0, f_rect.position.y + 25.0), filters[f_idx], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, fcolor)

	var unlocked_badges: Array = stats.get("badges", [])
	var decrypted_files: Array = stats.get("decrypted_enc_files", [])
	var visible_count: int = 8

	for v_idx in range(visible_count):
		var track_idx: int = music_scroll_offset + v_idx
		if track_idx >= VaultModules.MUSIC_TRACKS.size():
			break

		var track: Dictionary = VaultModules.MUSIC_TRACKS[track_idx]
		var r_rect := get_music_row_rect(v_idx, vp)
		var is_sel: bool = (track_idx == selected_music_idx)
		var is_unl: bool = VaultModules.is_track_unlocked(track, unlocked_badges, decrypted_files, stats)

		var tcolor: Color = Color("bf5af2") if is_unl else BrandClass.TEXT_DIM
		if is_sel:
			canvas.draw_rect(r_rect, BrandClass.with_alpha(tcolor, 0.25))
			canvas.draw_rect(r_rect, BrandClass.with_alpha(tcolor, 0.90), false, 2.0)
		else:
			canvas.draw_rect(r_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.75))
			canvas.draw_rect(r_rect, BrandClass.with_alpha(tcolor, 0.40), false, 1.0)

		var status_icon: String = "▶" if is_unl else "🔒"
		canvas.draw_string(font, Vector2(r_rect.position.x + 10.0, r_rect.position.y + 26.0), "%02d. [%s] %s" % [track_idx + 1, status_icon, str(track.get("name", "")).left(26)], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, tcolor)
		canvas.draw_string(font, Vector2(r_rect.position.x + col_w - 90.0, r_rect.position.y + 26.0), str(track.get("duration", "3:30")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.TEXT_DIM)

	var panel_w: float = 330.0
	var panel_x: float = rect.position.x + rect.size.x - panel_w
	var panel_y: float = rect.position.y + 12.0
	var panel_h: float = rect.size.y - 24.0
	var panel_rect := Rect2(panel_x, panel_y, panel_w, panel_h)

	canvas.draw_rect(panel_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	canvas.draw_rect(panel_rect, BrandClass.with_alpha(Color("bf5af2"), 0.60), false, 1.5)

	if selected_music_idx >= 0 and selected_music_idx < VaultModules.MUSIC_TRACKS.size():
		var sel_track: Dictionary = VaultModules.MUSIC_TRACKS[selected_music_idx]
		var is_unl: bool = VaultModules.is_track_unlocked(sel_track, unlocked_badges, decrypted_files, stats)
		var py: float = panel_rect.position.y + 20.0

		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "REPRODUCTOR KERNEL AUDIO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color("bf5af2"))
		py += 26.0
		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), str(sel_track.get("name", "")).left(26), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)
		py += 22.0
		canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Pack: " + str(sel_track.get("pack", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.ACCENT)
		py += 24.0

		var eq_rect := Rect2(panel_rect.position.x + 16.0, py, panel_w - 32.0, 52.0)
		canvas.draw_rect(eq_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
		canvas.draw_rect(eq_rect, BrandClass.with_alpha(Color("bf5af2"), 0.40), false, 1.0)
		for bar_i in range(28):
			var bar_x: float = eq_rect.position.x + 6.0 + float(bar_i) * 10.0
			var bar_h: float = float((bar_i * 13 + 7) % 38) if is_unl else 4.0
			var seg_rect := Rect2(bar_x, eq_rect.position.y + eq_rect.size.y - bar_h - 6.0, 7.0, bar_h)
			canvas.draw_rect(seg_rect, Color("bf5af2") if is_unl else BrandClass.TEXT_DIM)
		py += 64.0

		if is_unl:
			canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Estado: [✓ PISTA DESBLOQUEADA]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.SUCCESS)
			py += 22.0
			canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Duración: " + str(sel_track.get("duration", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
		else:
			canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), "Estado: [🔒 PISTA BLOQUEADA]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.WARNING)
			py += 20.0
			canvas.draw_string(font, Vector2(panel_rect.position.x + 16.0, py), str(sel_track.get("unlock_req", "")), HORIZONTAL_ALIGNMENT_LEFT, int(panel_w - 32.0), font_size - 2, BrandClass.TEXT_DIM)

		var pin_menu := get_music_pin_menu_rect(vp)
		var pin_game := get_music_pin_game_rect(vp)

		canvas.draw_rect(pin_menu, BrandClass.with_alpha(Color("bf5af2"), 0.25))
		canvas.draw_rect(pin_menu, BrandClass.with_alpha(Color("bf5af2"), 0.80), false, 1.5)
		canvas.draw_string(font, Vector2(pin_menu.position.x + 12.0, pin_menu.position.y + 27.0), "[ 📌 FIJAR EN MENÚ PRINCIPAL ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color("bf5af2"))

		canvas.draw_rect(pin_game, BrandClass.with_alpha(Color("bf5af2"), 0.25))
		canvas.draw_rect(pin_game, BrandClass.with_alpha(Color("bf5af2"), 0.80), false, 1.5)
		canvas.draw_string(font, Vector2(pin_game.position.x + 12.0, pin_game.position.y + 27.0), "[ 📌 FIJAR EN PARTIDA ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color("bf5af2"))


func _draw_tab_cosmeticos(canvas: CanvasItem, rect: Rect2, font: Font, font_size: int, big_font_size: int, pulse: float, vp: Vector2) -> void:
	canvas.draw_string(font, Vector2(rect.position.x + 12.0, rect.position.y + 24.0), "05 // SUBSISTEMA DE COSMÉTICOS Y SKINS DE OPERADOR", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("00d2ff"))

	var bp_rect := Rect2(rect.position.x + 24.0, rect.position.y + 54.0, rect.size.x - 48.0, rect.size.y - 80.0)
	canvas.draw_rect(bp_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
	canvas.draw_rect(bp_rect, BrandClass.with_alpha(Color("00d2ff"), 0.50), false, 1.5)

	var scan_y: int = int(bp_rect.position.y + fmod(pulse * 120.0, bp_rect.size.y))
	canvas.draw_line(Vector2(bp_rect.position.x, float(scan_y)), Vector2(bp_rect.position.x + bp_rect.size.x, float(scan_y)), Color("00d2ff"), 2.0)

	var by: float = bp_rect.position.y + 40.0
	canvas.draw_string(font, Vector2(bp_rect.position.x + 32.0, by), "ESQUEMAS GEOMÉTRICOS DE NODO // FASE II", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 4, Color("00d2ff"))
	by += 36.0
	canvas.draw_string(font, Vector2(bp_rect.position.x + 32.0, by), "CALIBRACIÓN DE SKINS Y ESTELAS DE RED: EN PROCESO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)
	by += 40.0

	var warn_box := Rect2(bp_rect.position.x + 32.0, by, bp_rect.size.x - 64.0, 110.0)
	canvas.draw_rect(warn_box, BrandClass.with_alpha(BrandClass.WARNING, 0.15))
	canvas.draw_rect(warn_box, BrandClass.with_alpha(BrandClass.WARNING, 0.80), false, 1.5)
	canvas.draw_string(font, Vector2(warn_box.position.x + 20.0, warn_box.position.y + 28.0), "[ ⚠ SUBSISTEMA DE COSMÉTICOS EN MANTENIMIENTO // PRÓXIMA ACTUALIZACIÓN ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.WARNING)
	canvas.draw_string(font, Vector2(warn_box.position.x + 20.0, warn_box.position.y + 56.0), "Los protocolos de personalización estética de nodos coaxiales y estelas de red se encuentran", HORIZONTAL_ALIGNMENT_LEFT, int(warn_box.size.x - 40.0), font_size - 1, BrandClass.TEXT)
	canvas.draw_string(font, Vector2(warn_box.position.x + 20.0, warn_box.position.y + 80.0), "actualmente en fase de pruebas en La Bóveda de Sector 0. Estará disponible próximamente.", HORIZONTAL_ALIGNMENT_LEFT, int(warn_box.size.x - 40.0), font_size - 1, BrandClass.TEXT)



static func compute_shell_hitboxes(rect: Rect2, drum_angle: float = 0.0) -> Array[Dictionary]:
	var hitboxes: Array[Dictionary] = []
	var x0: float = 16.0
	var y0: float = 16.0
	var w: float = 292.0
	var h: float = maxf(360.0, rect.size.y - 32.0)
	hitboxes.append({"id": "volver", "rect": Rect2(x0 + 14.0, y0 + 20.0, 92.0, 26.0)})
	hitboxes.append({"id": "slot", "rect": Rect2(x0 + 116.0, y0 + 20.0, 82.0, 26.0)})
	var drum_cx: float = x0 + w * 0.5
	var drum_cy: float = clampf(y0 + h * 0.50, y0 + 240.0, y0 + 360.0)
	var radius_y: float = minf(175.0, (h - 190.0) * 0.36)
	for idx: int in range(TABS.size()):
		var delta: float = float(idx) - drum_angle
		while delta > 2.5:
			delta -= 5.0
		while delta < -2.5:
			delta += 5.0
		var theta: float = delta * 0.58
		var z_depth: float = cos(theta)
		var y_pos: float = drum_cy + sin(theta) * radius_y
		var scale_f: float = 0.72 + 0.28 * maxf(0.0, z_depth)
		var card_w: float = (w - 38.0) * scale_f
		var card_h: float = 68.0 * scale_f
		var cx: float = drum_cx - card_w * 0.5 + (1.0 - scale_f) * 16.0
		var cy: float = y_pos - card_h * 0.5
		hitboxes.append({"id": "drum_%d" % idx, "rect": Rect2(cx, cy, card_w, card_h)})
	return hitboxes


static func draw_boveda_shell(canvas: CanvasItem, rect: Rect2, font: Font, state: Dictionary) -> Array[Dictionary]:
	var hitboxes: Array[Dictionary] = []
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return hitboxes

	# 1. Full-screen background before any transform
	canvas.draw_rect(Rect2(Vector2.ZERO, rect.size), Color("#05070C"))

	# 2. Left 25%: Mechanical 2.5D Rotating Drum
	_draw_left_drum(canvas, rect, font, state, hitboxes)

	# 3. Right 75%: Unified 1-line zjstatus bar
	var rx: float = 324.0
	var rw: float = maxf(200.0, rect.size.x - rx - 16.0)
	_draw_top_status_bar(canvas, Rect2(rx, 16.0, rw, 28.0), font, state)

	return hitboxes


static func _draw_shell_panel(canvas: CanvasItem, r: Rect2, font: Font, title: String, accent: Color, bg: Color = Color("#0B1018")) -> void:
	canvas.draw_rect(r, bg)
	canvas.draw_rect(r, Color("#1F2B3D"), false, 1.0)
	canvas.draw_rect(Rect2(r.position.x + 10.0, r.position.y, minf(r.size.x - 20.0, 90.0), 2.0), accent)
	if title != "" and font != null:
		var tsize: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		canvas.draw_rect(Rect2(r.position.x + 14.0, r.position.y - 7.0, tsize.x + 12.0, 14.0), Color("#05070C"))
		canvas.draw_string(font, Vector2(r.position.x + 20.0, r.position.y + 4.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, accent)


static func _draw_shell_pill(canvas: CanvasItem, r: Rect2, font: Font, label: String, active: bool, accent: Color) -> void:
	var bg: Color = accent if active else Color("#0F1726")
	var border: Color = accent if active else Color("#2F4563")
	canvas.draw_rect(r, bg)
	canvas.draw_rect(r, border, false, 1.0)
	if font != null:
		var fg: Color = Color("#05070C") if active else Color("#EAECF5")
		var tsize: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var tx: float = r.position.x + (r.size.x - tsize.x) * 0.5
		var ty: float = r.position.y + r.size.y * 0.5 + 3.5
		canvas.draw_string(font, Vector2(tx, ty), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, fg)


static func _draw_left_drum(canvas: CanvasItem, rect: Rect2, font: Font, state: Dictionary, hitboxes: Array[Dictionary]) -> void:
	var x0: float = 16.0
	var y0: float = 16.0
	var w: float = 292.0
	var h: float = maxf(360.0, rect.size.y - 32.0)
	_draw_shell_panel(canvas, Rect2(x0, y0, w, h), font, "LA BÓVEDA // DRUM-2.5D", Color("#00E5FF"), Color("#080C14"))

	var volver_rect := Rect2(x0 + 14.0, y0 + 20.0, 92.0, 26.0)
	_draw_shell_pill(canvas, volver_rect, font, "← VOLVER", false, Color("#7A869E"))
	hitboxes.append({"id": "volver", "rect": volver_rect})

	var slot_idx: int = int(state.get("slot_index", 1))
	var slot_rect := Rect2(x0 + 116.0, y0 + 20.0, 82.0, 26.0)
	_draw_shell_pill(canvas, slot_rect, font, "SLOT 0%d" % slot_idx, true, Color("#39FF88"))
	hitboxes.append({"id": "slot", "rect": slot_rect})

	if font != null:
		canvas.draw_string(font, Vector2(x0 + 216.0, y0 + 37.0), "60 FPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#7A869E"))

	var active_mode: int = clampi(int(state.get("active_mode", 0)), 0, TABS.size() - 1)
	var drum_angle: float = float(state.get("drum_angle", 0.0))
	var drum_target: float = float(state.get("drum_target", 0.0))
	var drum_vel: float = float(state.get("drum_vel", 0.0))
	var drum_lock_flash: float = float(state.get("drum_lock_flash", 0.0))
	var pulse: float = float(state.get("pulse", 0.0))

	var drum_cx: float = x0 + w * 0.5
	var drum_cy: float = clampf(y0 + h * 0.50, y0 + 240.0, y0 + 360.0)
	var radius_y: float = minf(175.0, (h - 190.0) * 0.36)
	var spin_speed: float = absf(drum_vel) + absf(drum_target - drum_angle)

	var active_tab: Dictionary = TABS[active_mode]
	var active_col: Color = active_tab.get("color", Color("#00E5FF"))

	# Graduated mechanical rotor arc behind cards
	canvas.draw_arc(Vector2(x0 + 24.0, drum_cy), 220.0, -0.75, 0.75, 28, Color(0.0, 0.9, 1.0, 0.22), 1.5)
	for deg: int in [-50, -25, 0, 25, 50]:
		var ang: float = deg_to_rad(float(deg))
		var tick_x: float = x0 + 24.0 + cos(ang) * 220.0
		var tick_y: float = drum_cy + sin(ang) * 220.0
		var tick_col: Color = active_col if deg == 0 else Color("#455168")
		canvas.draw_rect(Rect2(tick_x - 4.0, tick_y - 1.0, 8.0, 2.0), tick_col)
		if font != null:
			var deg_lbl: String = "LOCK" if deg == 0 else (("+%d°" % deg) if deg > 0 else ("%d°" % deg))
			canvas.draw_string(font, Vector2(x0 + 10.0, tick_y + 3.0), deg_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, tick_col)

	# Build & sort 5 drum cards back-to-front by z_depth
	var items: Array[Dictionary] = []
	for idx: int in range(TABS.size()):
		var delta: float = float(idx) - drum_angle
		while delta > 2.5:
			delta -= 5.0
		while delta < -2.5:
			delta += 5.0
		var theta: float = delta * 0.58
		var z_depth: float = cos(theta)
		var y_pos: float = drum_cy + sin(theta) * radius_y
		items.append({
			"idx": idx,
			"tab": TABS[idx],
			"delta": delta,
			"z_depth": z_depth,
			"y_pos": y_pos,
		})

	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("z_depth", 0.0)) < float(b.get("z_depth", 0.0))
	)

	for it: Dictionary in items:
		var idx: int = int(it.get("idx", 0))
		var tab: Dictionary = it.get("tab", {})
		var delta: float = float(it.get("delta", 0.0))
		var z_depth: float = float(it.get("z_depth", 1.0))
		var y_pos: float = float(it.get("y_pos", drum_cy))

		var scale_f: float = 0.72 + 0.28 * maxf(0.0, z_depth)
		var card_w: float = (w - 38.0) * scale_f
		var card_h: float = 68.0 * scale_f
		var cx: float = drum_cx - card_w * 0.5 + (1.0 - scale_f) * 16.0
		var cy: float = y_pos - card_h * 0.5
		var is_sel: bool = (idx == active_mode and absf(delta) < 0.35)
		var alpha: float = clampf(0.28 + z_depth * 0.75, 0.25, 1.0)
		var m_col: Color = tab.get("color", Color("#00E5FF"))

		var card_rect := Rect2(cx, cy, card_w, card_h)
		var bg_col: Color = Color("#101B2D") if is_sel else Color("#0B111C")
		bg_col.a = alpha
		var brd_col: Color = m_col if is_sel else Color("#2F4563")
		brd_col.a = alpha
		canvas.draw_rect(card_rect, bg_col)
		canvas.draw_rect(card_rect, brd_col, false, 2.0 if is_sel else 1.0)

		if is_sel:
			canvas.draw_rect(Rect2(cx, cy + 8.0, 4.0, card_h - 16.0), m_col)
			if drum_lock_flash > 0.02:
				var sweep_x: float = cx + (1.0 - drum_lock_flash) * card_w
				canvas.draw_rect(Rect2(cx, cy, card_w, 2.0), Color(1.0, 1.0, 1.0, drum_lock_flash * 0.45))
				canvas.draw_rect(Rect2(sweep_x - 6.0, cy + 4.0, 12.0, card_h - 8.0), Color(1.0, 1.0, 1.0, drum_lock_flash * 0.35))

			if idx == 3:
				for b: int in range(5):
					var bh: float = 4.0 + absf(sin(pulse * 5.0 + float(b) * 0.7)) * 16.0
					canvas.draw_rect(Rect2(cx + card_w - 36.0 + float(b) * 5.0, cy + card_h - 14.0 - bh, 3.0, bh), Color("#FF2E88"))
			elif idx == 0 and font != null:
				canvas.draw_string(font, Vector2(cx + card_w - 54.0, cy + 25.0), "5 TREES", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#00E5FF"))
			elif idx == 2 and font != null:
				canvas.draw_string(font, Vector2(cx + card_w - 54.0, cy + 25.0), "ACADEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FFC857"))

		if font != null:
			var title_col: Color = m_col if is_sel else Color("#EAECF5")
			title_col.a = alpha
			var sub_col: Color = Color("#7A869E")
			sub_col.a = alpha
			var title_fs: int = maxi(9, int(round(13.0 * scale_f)))
			var sub_fs: int = maxi(8, int(round(10.0 * scale_f)))
			var code_str: String = str(tab.get("code", "0%d" % (idx + 1)))
			var name_str: String = str(tab.get("name", ""))
			var sub_str: String = str(tab.get("sub", ""))
			canvas.draw_string(font, Vector2(cx + 14.0 * scale_f, cy + 27.0 * scale_f), "%s // %s" % [code_str, name_str], HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, title_col)
			canvas.draw_string(font, Vector2(cx + 14.0 * scale_f, cy + 46.0 * scale_f), sub_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs, sub_col)

		hitboxes.append({"id": "drum_%d" % idx, "rect": card_rect})

	# Lock-On Jaws around center card
	var jaw_spread: float = minf(18.0, spin_speed * 22.0)
	var j_top: float = drum_cy - 26.0 - jaw_spread
	var j_bot: float = drum_cy + 26.0 + jaw_spread
	canvas.draw_polyline(PackedVector2Array([
		Vector2(x0 + 18.0, j_top),
		Vector2(x0 + 10.0, j_top),
		Vector2(x0 + 10.0, j_bot),
		Vector2(x0 + 18.0, j_bot),
	]), active_col, 2.2)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(x0 + w - 18.0, j_top),
		Vector2(x0 + w - 10.0, j_top),
		Vector2(x0 + w - 10.0, j_bot),
		Vector2(x0 + w - 18.0, j_bot),
	]), active_col, 2.2)

	if font != null:
		var fy: float = y0 + h - 42.0
		canvas.draw_string(font, Vector2(x0 + 20.0, fy), "RUEDA / ↑ ↓ / CLIC PARA GIRAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#7A869E"))
		canvas.draw_string(font, Vector2(x0 + 20.0, fy + 18.0), "MODO: %s // %s" % [str(active_tab.get("code", "")), str(active_tab.get("name", ""))], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, active_col)


static func _draw_top_status_bar(canvas: CanvasItem, bar_rect: Rect2, font: Font, state: Dictionary) -> void:
	var active_mode: int = clampi(int(state.get("active_mode", 0)), 0, TABS.size() - 1)
	var tab: Dictionary = TABS[active_mode]
	var m_col: Color = tab.get("color", Color("#00E5FF"))

	canvas.draw_rect(bar_rect, Color("#090E17"))
	canvas.draw_rect(bar_rect, Color("#1F2B3D"), false, 1.0)
	canvas.draw_rect(Rect2(bar_rect.position.x, bar_rect.position.y + 5.0, 3.0, 18.0), m_col)

	if font == null:
		return

	var base_y: float = bar_rect.position.y + 18.0
	var mode_txt: String = "%s // %s" % [str(tab.get("code", "")), str(tab.get("name", ""))]
	canvas.draw_string(font, Vector2(bar_rect.position.x + 14.0, base_y), mode_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, m_col)

	var alias_str: String = str(state.get("player_name", "JUGADOR")).to_upper()
	var tier_str: String = str(state.get("rank_tier", "RANGO I"))
	var stars_val: int = int(state.get("total_stars", 0))
	var badge_str: String = str(state.get("featured_badge", "ENLACE INICIAL"))
	var info_txt: String = "│  ◈ %s@boveda-lab  │  %s (%d★)  │  ★ %s" % [alias_str, tier_str, stars_val, badge_str]
	canvas.draw_string(font, Vector2(bar_rect.position.x + 195.0, base_y), info_txt, HORIZONTAL_ALIGNMENT_LEFT, int(maxf(80.0, bar_rect.size.x - 310.0)), 11, Color("#7A869E"))

	var fps_txt: String = "VSYNC 60 FPS"
	var fps_sz: Vector2 = font.get_string_size(fps_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	canvas.draw_string(font, Vector2(bar_rect.position.x + bar_rect.size.x - fps_sz.x - 14.0, base_y), fps_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#39FF88"))
