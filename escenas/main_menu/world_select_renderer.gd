class_name WorldSelectRenderer extends RefCounted

## WorldSelectRenderer
## Dedicated renderer for the World Selection screen in VERTEX.
## Provides a distinct vertical neural data highway / cyber reactor spire aesthetic.

const BrandClass = preload("res://juego/ui/brand.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")

var _vertical_pulses: Array[Dictionary] = []
var _time: float = 0.0


func _init() -> void:
	_init_vertical_pulses()


func _init_vertical_pulses() -> void:
	_vertical_pulses.clear()
	for i in range(18):
		_vertical_pulses.append({
			"col_x": randf_range(80.0, 1200.0),
			"y": randf_range(0.0, 720.0),
			"speed": randf_range(90.0, 220.0),
			"length": randf_range(25.0, 80.0),
			"alpha": randf_range(0.18, 0.45)
		})


func update(delta: float, vp: Vector2) -> void:
	_time += delta
	for p in _vertical_pulses:
		p.y += p.speed * delta
		if p.y - p.length > vp.y:
			p.y = -p.length
			p.col_x = randf_range(80.0, vp.x - 80.0)
			p.speed = randf_range(90.0, 220.0)


func get_node_pos(idx: int, total: int, vp: Vector2) -> Vector2:
	var cx := vp.x * 0.5
	var start_y := 170.0
	var step_y := 110.0
	return Vector2(cx, start_y + float(idx) * step_y)


func get_card_rect(idx: int, vp: Vector2) -> Rect2:
	var pos := get_node_pos(idx, 4, vp)
	var wing_w: float = clampf(vp.x * 0.22, 250.0, 320.0)
	var card_w: float = (wing_w + 38.0) * 2.0
	var card_h := 74.0
	return Rect2(pos.x - card_w * 0.5, pos.y - card_h * 0.5, card_w, card_h)


func get_world_color(world_id: String) -> Color:
	match world_id:
		"heist":
			return BrandClass.SUCCESS
		"hacker":
			return BrandClass.ACCENT
		"cybersecurity":
			return BrandClass.WARNING
		"tutorials":
			return Color("64b5f6")
		_:
			return BrandClass.ACCENT


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
	big_font_size: int
) -> void:
	var cx := vp.x * 0.5 + ox
	var total_items := items.size()
	if total_items == 0:
		return

	var sel_item := items[selected_idx] if (selected_idx >= 0 and selected_idx < total_items) else items[0]
	var active_color := get_world_color(sel_item.get("id", ""))

	# 1. Ambient Vertical Matrix Code Pulses
	_draw_matrix_pulses(canvas, vp, alpha)

	# 2. Sector Telemetry Badges (Top Right & Left Overlays)
	_draw_sector_telemetry(canvas, vp, alpha, ox, font, font_size, active_color)

	# 3. Central Vertical Cyber Spire & Bus Lines
	_draw_central_spire(canvas, vp, alpha, cx, pulse, active_color)

	# 4. Vertical World Nodes & Lateral Information Wings
	for i in range(total_items):
		var item := items[i]
		var npos := get_node_pos(i, total_items, vp) + Vector2(ox, 0.0)
		var is_sel: bool = i == selected_idx
		var world_col := get_world_color(item.get("id", ""))
		_draw_world_node(
			canvas,
			vp,
			npos,
			i,
			is_sel,
			item,
			world_col,
			alpha,
			progress,
			pulse,
			font,
			font_size,
			big_font_size
		)


func _draw_matrix_pulses(canvas: CanvasItem, _vp: Vector2, alpha: float) -> void:
	for p in _vertical_pulses:
		var x: float = p.col_x
		var y_top: float = p.y - p.length
		var y_bot: float = p.y
		var col := BrandClass.with_alpha(BrandClass.ACCENT, p.alpha * alpha * 0.35)
		canvas.draw_line(Vector2(x, y_top), Vector2(x, y_bot), col, 1.0)
		canvas.draw_circle(Vector2(x, y_bot), 1.2, BrandClass.with_alpha(Color.WHITE, p.alpha * alpha * 0.70))


func _draw_sector_telemetry(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	ox: float,
	font: Font,
	font_size: int,
	active_col: Color
) -> void:
	# Top Right Sector HUD Box
	var tr_w := 240.0
	var tr_x := vp.x - tr_w - 30.0 + ox
	var tr_y := 34.0
	var tr_rect := Rect2(tr_x, tr_y, tr_w, 48.0)

	canvas.draw_rect(tr_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.85))
	canvas.draw_rect(tr_rect, BrandClass.with_alpha(active_col, alpha * 0.45), false, 1.0)
	canvas.draw_rect(Rect2(tr_rect.position.x + tr_w - 3, tr_rect.position.y, 3, tr_rect.size.y), active_col)

	var hud_t1 := "[SECTOR::DOMAINS]"
	var hud_t2 := "NODES: 04  |  INTEGRITY: 99.8%"
	canvas.draw_string(font, Vector2(tr_x + 10, tr_y + 18), hud_t1, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(active_col, alpha * 0.90))
	canvas.draw_string(font, Vector2(tr_x + 10, tr_y + 36), hud_t2, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.75))


func _draw_central_spire(
	canvas: CanvasItem,
	vp: Vector2,
	alpha: float,
	cx: float,
	pulse: float,
	theme_col: Color
) -> void:
	var top_y := 125.0
	var bot_y := vp.y - 120.0
	var bus_w := 28.0

	# Twin vertical data bus columns
	var bus_col := BrandClass.with_alpha(theme_col, alpha * 0.35)
	canvas.draw_line(Vector2(cx - bus_w, top_y), Vector2(cx - bus_w, bot_y), bus_col, 1.5)
	canvas.draw_line(Vector2(cx + bus_w, top_y), Vector2(cx + bus_w, bot_y), bus_col, 1.5)

	# Cross bus connectors
	var step := 45.0
	var cur_y := top_y + 10.0
	while cur_y < bot_y:
		canvas.draw_line(Vector2(cx - bus_w, cur_y), Vector2(cx + bus_w, cur_y), BrandClass.with_alpha(theme_col, alpha * 0.15), 1.0)
		cur_y += step

	# Flowing energy pulse packet travelling vertically down the spine
	var t_bus := fmod(pulse * 1.8, 1.0)
	var pkt_y := lerpf(top_y, bot_y, t_bus)
	canvas.draw_circle(Vector2(cx - bus_w, pkt_y), 3.0, BrandClass.with_alpha(theme_col, alpha * 0.90))
	canvas.draw_circle(Vector2(cx + bus_w, pkt_y), 3.0, BrandClass.with_alpha(theme_col, alpha * 0.90))
	canvas.draw_line(Vector2(cx - bus_w, pkt_y), Vector2(cx + bus_w, pkt_y), BrandClass.with_alpha(Color.WHITE, alpha * 0.75), 1.5)

	# Stacked cylindrical holographic energy rings in the background
	var ring_y_offsets := [170.0, 280.0, 390.0, 500.0]
	for ry in ring_y_offsets:
		var ring_pts := PackedVector2Array()
		var rw: float = 38.0 + sin(pulse * 2.0 + ry * 0.05) * 4.0
		var rh: float = 14.0
		for s in range(25):
			var a := float(s) * TAU / 24.0
			ring_pts.append(Vector2(cx + cos(a) * rw, ry + sin(a) * rh))
		canvas.draw_polyline(ring_pts, BrandClass.with_alpha(theme_col, alpha * 0.20), 1.0)


func _draw_world_node(
	canvas: CanvasItem,
	_vp: Vector2,
	npos: Vector2,
	idx: int,
	is_sel: bool,
	item: Dictionary,
	world_col: Color,
	alpha: float,
	progress: Dictionary,
	pulse: float,
	font: Font,
	font_size: int,
	big_font_size: int
) -> void:
	var is_unlocked: bool = ProgressUtilClass.is_world_unlocked(item.id, progress)
	var lock_reason: String = ProgressUtilClass.get_world_lock_reason(item.id, progress) if not is_unlocked else ""

	var base_r: float = 28.0 if is_sel else 22.0
	var node_fill := BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95)
	var effective_color := world_col if is_unlocked else BrandClass.with_alpha(BrandClass.WARNING, 0.70)
	var node_border := BrandClass.with_alpha(effective_color if is_sel else BrandClass.PANEL_BORDER, alpha * (0.95 if is_sel else 0.55))

	# Left & Right Wing Card dimensions
	var wing_w: float = clampf(_vp.x * 0.22, 250.0, 320.0)
	var wing_h: float = 62.0 if is_sel else 52.0

	var left_card := Rect2(npos.x - 38.0 - wing_w, npos.y - wing_h * 0.5, wing_w, wing_h)
	var right_card := Rect2(npos.x + 38.0, npos.y - wing_h * 0.5, wing_w, wing_h)

	# 1. Connecting bridge lines from central node to wings
	var bridge_col := BrandClass.with_alpha(effective_color if is_sel else BrandClass.PANEL_BORDER, alpha * (0.60 if is_sel else 0.25))
	canvas.draw_line(Vector2(left_card.position.x + wing_w, npos.y), Vector2(npos.x - base_r, npos.y), bridge_col, 1.5)
	canvas.draw_line(Vector2(npos.x + base_r, npos.y), Vector2(right_card.position.x, npos.y), bridge_col, 1.5)

	# 2. Left Card: World Title & Description
	canvas.draw_rect(left_card, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * (0.92 if is_sel else 0.70)))
	canvas.draw_rect(left_card, BrandClass.with_alpha(effective_color if is_sel else BrandClass.PANEL_BORDER, alpha * (0.80 if is_sel else 0.35)), false, 1.2)
	if is_sel:
		canvas.draw_rect(Rect2(left_card.position.x, left_card.position.y, 4, wing_h), effective_color)

	var title_txt: String = item.label.to_upper()
	var tsize := font.get_string_size(title_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size - 6 if is_sel else font_size + 2)
	canvas.draw_string(
		font,
		Vector2(left_card.position.x + 14, left_card.position.y + 24),
		title_txt,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		big_font_size - 6 if is_sel else font_size + 2,
		BrandClass.with_alpha(BrandClass.TEXT if is_sel else BrandClass.TEXT_DIM, alpha)
	)

	if not is_unlocked:
		var lock_tag := "[BLOQUEADO]"
		canvas.draw_string(
			font,
			Vector2(left_card.position.x + 18 + tsize.x, left_card.position.y + 24),
			lock_tag,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size - 3,
			BrandClass.with_alpha(BrandClass.ENEMY, alpha * (0.95 if is_sel else 0.70))
		)

	# Truncate description gracefully so it never overflows wing boundaries
	var desc_txt: String = item.get("desc", "")
	if desc_txt != "":
		var max_desc_w: float = wing_w - 28.0
		if font.get_string_size(desc_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x > max_desc_w:
			while desc_txt.length() > 1 and font.get_string_size(desc_txt + "...", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3).x > max_desc_w:
				desc_txt = desc_txt.left(desc_txt.length() - 1)
			desc_txt += "..."
		canvas.draw_string(
			font,
			Vector2(left_card.position.x + 14, left_card.position.y + 44),
			desc_txt,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size - 3,
			BrandClass.with_alpha(BrandClass.TEXT if is_sel else BrandClass.TEXT_DIM, alpha * (0.95 if is_sel else 0.85))
		)

	# 3. Right Card: Telemetry & Stars Rating
	canvas.draw_rect(right_card, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * (0.92 if is_sel else 0.70)))
	canvas.draw_rect(right_card, BrandClass.with_alpha(effective_color if is_sel else BrandClass.PANEL_BORDER, alpha * (0.80 if is_sel else 0.35)), false, 1.2)
	if is_sel:
		canvas.draw_rect(Rect2(right_card.position.x + wing_w - 4, right_card.position.y, 4, wing_h), effective_color)

	var sec_txt: String = lock_reason if not is_unlocked else ("NODE: 0x%04X" % (hash(item.id) & 0xFFFF))
	canvas.draw_string(
		font,
		Vector2(right_card.position.x + 14, right_card.position.y + 22),
		sec_txt,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size - 3,
		BrandClass.with_alpha(BrandClass.WARNING if not is_unlocked else effective_color, alpha * 0.85)
	)

	# Star Rating
	var world_id: String = item.id
	var stars: int = progress.get(world_id, 0)
	var s_str := ""
	for si in range(3):
		s_str += "★" if si < stars else "☆"
	canvas.draw_string(
		font,
		Vector2(right_card.position.x + 14, right_card.position.y + 44),
		s_str,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size + 1,
		BrandClass.with_alpha(BrandClass.WARNING if stars > 0 else BrandClass.TEXT_DIM, alpha * 0.9)
	)

	# Interactive Prompt on Selected Right Card
	if is_sel:
		var prompt_txt: String = "< [ BLOQUEADO ] >" if not is_unlocked else "< [ ENTER / CLIC ] >"
		var psize := font.get_string_size(prompt_txt, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 4)
		var glow := 0.75 + sin(pulse * 3.0) * 0.25
		var prompt_col := BrandClass.ENEMY if not is_unlocked else effective_color
		canvas.draw_string(
			font,
			Vector2(right_card.position.x + wing_w - psize.x - 12, right_card.position.y + 36),
			prompt_txt,
			HORIZONTAL_ALIGNMENT_RIGHT,
			-1,
			font_size - 4,
			BrandClass.with_alpha(prompt_col, alpha * glow)
		)

	# 4. Central Node Disk
	canvas.draw_circle(npos, base_r, node_fill)
	canvas.draw_circle(npos, base_r, node_border, false, 2.0 if is_sel else 1.2)

	if is_sel:
		# Rotating tactical targeting reticle brackets
		canvas.draw_circle(npos, base_r + 6.0, BrandClass.with_alpha(effective_color, alpha * 0.25), false, 1.0)
		var bra_rot := pulse * 2.2
		var bra_r := base_r + 9.0
		canvas.draw_arc(npos, bra_r, bra_rot, bra_rot + PI * 0.4, 8, BrandClass.with_alpha(effective_color, alpha * 0.9), 1.8)
		canvas.draw_arc(npos, bra_r, bra_rot + PI * 0.5, bra_rot + PI * 0.9, 8, BrandClass.with_alpha(effective_color, alpha * 0.9), 1.8)
		canvas.draw_arc(npos, bra_r, bra_rot + PI, bra_rot + PI * 1.4, 8, BrandClass.with_alpha(effective_color, alpha * 0.9), 1.8)
		canvas.draw_arc(npos, bra_r, bra_rot + PI * 1.5, bra_rot + PI * 1.9, 8, BrandClass.with_alpha(effective_color, alpha * 0.9), 1.8)

	# Render Node Icon: Texture, Padlock, or Vector
	if not is_unlocked:
		_draw_vector_icon(canvas, npos, "lock", 1.2 if is_sel else 0.95, BrandClass.with_alpha(BrandClass.WARNING if is_sel else BrandClass.TEXT_DIM, alpha))
	elif item.get("icon_tex") != null:
		var tex: Texture2D = item["icon_tex"]
		var t_size := Vector2(28, 28) if is_sel else Vector2(22, 22)
		canvas.draw_texture_rect(tex, Rect2(npos - t_size * 0.5, t_size), false, BrandClass.with_alpha(Color.WHITE, alpha))
	else:
		_draw_vector_icon(canvas, npos, item.get("vector_icon", "default"), 1.2 if is_sel else 0.95, BrandClass.with_alpha(effective_color if is_sel else BrandClass.TEXT_DIM, alpha))


func _draw_vector_icon(canvas: CanvasItem, pos: Vector2, icon_type: String, nscale: float, col: Color) -> void:
	match icon_type:
		"lock":
			var rw := 14.0 * nscale
			var rh := 11.0 * nscale
			canvas.draw_rect(Rect2(pos.x - rw * 0.5, pos.y - rh * 0.5 + 2.5 * nscale, rw, rh), col, false, 1.6 * nscale)
			var sh_r := 4.5 * nscale
			canvas.draw_arc(Vector2(pos.x, pos.y - rh * 0.5 + 2.5 * nscale), sh_r, PI, TAU, 14, col, 1.6 * nscale)
			canvas.draw_circle(Vector2(pos.x, pos.y + 2.0 * nscale), 1.8 * nscale, col)
		"heist":
			var pts := PackedVector2Array([
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
			var spts := PackedVector2Array([
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
		_:
			canvas.draw_circle(pos, 4.0 * nscale, col)
