extends RefCounted

## Tab 01 // INSIGNIAS: fastfetch::operator-dossier + 5 Topological Skill-Trees + Holo-Chip 2.5D Inspector.
## Rendered 100% via _draw() on a single Control node for 60 FPS performance.

const BrandClass = preload("res://juego/ui/brand.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

const RARITY_COLORS: Dictionary = {
	"COMÚN": Color("#00E5FF"),
	"TÁCTICA": Color("#39FF88"),
	"ÉLITE": Color("#FFC857"),
	"MÍTICA // Ω": Color("#FF2E88"),
}

var p: Profile
var _canvas: Control = null
var _active_tree: String = "GENERAL"
var _selected_node_idx: int = 0
var _hover_node_idx: int = -1
var _tree_transition: float = 1.0
var _editing_alias: bool = false
var _mouse_pos: Vector2 = Vector2(-1.0, -1.0)
var _hitboxes: Array[Dictionary] = []
var _last_draw_time: float = 0.0


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	var ctrl := Control.new()
	ctrl.name = "BadgesDrawCanvas"
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.focus_mode = Control.FOCUS_CLICK
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.draw.connect(_on_draw)
	ctrl.gui_input.connect(_on_gui_input)
	container.add_child(ctrl)
	_canvas = ctrl
	p._badges_canvas = ctrl


func select_tree(tree_key: String) -> void:
	if not VaultModules.SKILL_TREES.has(tree_key):
		return
	if _active_tree != tree_key:
		_active_tree = tree_key
		_selected_node_idx = 0
		_tree_transition = 0.0
	if _canvas != null:
		_canvas.queue_redraw()


func select_node(idx: int) -> void:
	var tree: Dictionary = VaultModules.SKILL_TREES.get(_active_tree, {})
	var nodes: Array = tree.get("nodes", [])
	if nodes.is_empty():
		return
	_selected_node_idx = clampi(idx, 0, nodes.size() - 1)
	if _canvas != null:
		_canvas.queue_redraw()


func equip_selected() -> bool:
	var tree: Dictionary = VaultModules.SKILL_TREES.get(_active_tree, {})
	var nodes: Array = tree.get("nodes", [])
	if _selected_node_idx < 0 or _selected_node_idx >= nodes.size():
		return false
	var node: Dictionary = nodes[_selected_node_idx]
	if not bool(node.get("unlocked", false)):
		return false
	p._featured_badge_title = str(node.get("title", "ENLACE INICIAL"))
	p._save_profile()
	p.update_featured_badge_label()
	if _canvas != null:
		_canvas.queue_redraw()
	return true


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_mouse_pos = mm.position
		if _canvas != null:
			_canvas.queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_mouse_pos = mb.position
			if _canvas != null:
				_canvas.grab_focus()
			for i: int in range(_hitboxes.size() - 1, -1, -1):
				var hb: Dictionary = _hitboxes[i]
				var r: Rect2 = hb.get("rect", Rect2())
				if r.has_point(mb.position):
					var hid: String = str(hb.get("id", ""))
					if hid == "edit_alias":
						_editing_alias = not _editing_alias
						if not _editing_alias:
							p._save_profile()
						p._play_click_sfx()
						if _canvas != null:
							_canvas.queue_redraw()
						return
					elif hid.begins_with("tree_"):
						select_tree(hid.trim_prefix("tree_"))
						p._play_click_sfx()
						return
					elif hid.begins_with("tnode_"):
						select_node(int(hid.trim_prefix("tnode_")))
						p._play_click_sfx()
						return
					elif hid == "equip_badge":
						if equip_selected():
							p._play_click_sfx()
						return
	elif event is InputEventKey and _editing_alias:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER or ke.keycode == KEY_ESCAPE:
				_editing_alias = false
				p._save_profile()
			elif ke.keycode == KEY_BACKSPACE:
				if p.player_name.length() > 0:
					p.player_name = p.player_name.substr(0, p.player_name.length() - 1)
					p._sync_shell_identity()
					p.queue_redraw()
			elif ke.unicode >= 32 and ke.unicode < 127 and p.player_name.length() < 14:
				p.player_name += char(ke.unicode).to_upper()
				p._sync_shell_identity()
				p.queue_redraw()
			if _canvas != null:
				_canvas.queue_redraw()
			_canvas.accept_event()


func _on_draw() -> void:
	if _canvas == null:
		return
	var sz: Vector2 = _canvas.size
	if sz.x <= 10.0 or sz.y <= 10.0:
		return

	var now_t: float = p._pulse
	var dt: float = clampf(now_t - _last_draw_time, 0.0, 0.05)
	_last_draw_time = now_t
	_tree_transition = minf(1.0, _tree_transition + dt * 5.0)

	_hitboxes.clear()
	var font: Font = p.font
	var rw: float = sz.x
	var rh: float = sz.y

	# 1. Top: fastfetch::operator-dossier
	var top_h: float = 148.0
	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(0.0, 0.0, rw, top_h), font, "fastfetch::operator-dossier", Color("#00E5FF"))
	_draw_holo_3d(Vector2(80.0, 78.0), 42.0, Color("#00E5FF"), 0.4, true)

	var sx: float = 152.0
	if font != null:
		_canvas.draw_string(font, Vector2(sx, 30.0), "%s@vertex-os" % p.player_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#00E5FF"))

	var alias_rect := Rect2(sx + 178.0, 14.0, 134.0, 22.0)
	var alias_lbl: String = ("ALIAS: %s_" % p.player_name) if _editing_alias else "✎ EDITAR ALIAS"
	ProfileRendererClass._draw_shell_pill(_canvas, alias_rect, font, alias_lbl, _editing_alias, Color("#39FF88") if _editing_alias else Color("#2F4563"))
	_hitboxes.append({"id": "edit_alias", "rect": alias_rect})

	var total_nodes: int = 0
	var unlocked_nodes: int = 0
	for k: String in VaultModules.TREE_KEYS:
		var tr_dict: Dictionary = VaultModules.SKILL_TREES.get(k, {})
		var tr_nodes: Array = tr_dict.get("nodes", [])
		total_nodes += tr_nodes.size()
		for nd: Dictionary in tr_nodes:
			if bool(nd.get("unlocked", false)):
				unlocked_nodes += 1

	if font != null:
		var specs: Array = [
			["LOGROS :", "%d/%d EN 5 ÁRBOLES" % [unlocked_nodes, total_nodes], Color("#39FF88")],
			["EQUIP  :", p._featured_badge_title, Color("#FFC857")],
			["KERNEL :", "VertexOS 4.7 Forward+", Color("#7A869E")],
		]
		for i: int in range(specs.size()):
			var sp: Array = specs[i]
			_canvas.draw_string(font, Vector2(sx, 54.0 + float(i) * 20.0), str(sp[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#7A869E"))
			_canvas.draw_string(font, Vector2(sx + 68.0, 54.0 + float(i) * 20.0), str(sp[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, sp[2])

	var ansi_cols: Array[Color] = [Color("#00E5FF"), Color("#39FF88"), Color("#FFC857"), Color("#FF2E88"), Color("#BF5AF2"), Color("#EAECF5")]
	for i: int in range(ansi_cols.size()):
		_canvas.draw_rect(Rect2(sx + float(i) * 26.0, 120.0, 20.0, 12.0), ansi_cols[i])

	# Right side of fastfetch: btop::skill-trees progress bars
	var bx: float = minf(rw - 370.0, 512.0)
	if bx > 320.0 and font != null:
		_canvas.draw_string(font, Vector2(bx, 24.0), "btop::skill-trees", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#EAECF5"))
		var bar_w: float = maxf(100.0, rw - bx - 120.0)
		for idx: int in range(VaultModules.TREE_KEYS.size()):
			var k: String = VaultModules.TREE_KEYS[idx]
			var tr: Dictionary = VaultModules.SKILL_TREES.get(k, {})
			var tr_nodes: Array = tr.get("nodes", [])
			var done: int = 0
			for nd: Dictionary in tr_nodes:
				if bool(nd.get("unlocked", false)):
					done += 1
			var by: float = 36.0 + float(idx) * 21.0
			var t_col: Color = tr.get("color", Color("#00E5FF"))
			_canvas.draw_string(font, Vector2(bx, by + 10.0), str(tr.get("short", k)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, t_col)
			_draw_bar(Rect2(bx + 66.0, by + 2.0, bar_w, 8.0), float(done) / float(maxi(1, tr_nodes.size())), t_col)
			_canvas.draw_string(font, Vector2(bx + 74.0 + bar_w, by + 10.0), "%d/%d" % [done, tr_nodes.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#EAECF5"))

	# 2. Bottom split: Left Multi-Tree Canvas (58%), Right Holo Inspector (42%)
	var bot_y: float = top_h + 14.0
	var bot_h: float = maxf(240.0, rh - bot_y)
	var left_w: float = floor(rw * 0.58)
	var right_w: float = rw - left_w - 14.0
	var tree: Dictionary = VaultModules.SKILL_TREES.get(_active_tree, {})
	var tree_col: Color = tree.get("color", Color("#00E5FF"))

	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(0.0, bot_y, left_w, bot_h), font, "ÁRBOL ACTIVO // %s" % str(tree.get("topology", "")), tree_col, Color("#070B12"))

	var fx: float = 12.0
	var fy: float = bot_y + 18.0
	for k: String in VaultModules.TREE_KEYS:
		var tr: Dictionary = VaultModules.SKILL_TREES.get(k, {})
		var lbl: String = str(tr.get("label", k))
		var cw: float = (font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 12.0) if font != null else 88.0
		var pill_r := Rect2(fx, fy, cw, 22.0)
		ProfileRendererClass._draw_shell_pill(_canvas, pill_r, font, lbl, _active_tree == k, tr.get("color", Color("#00E5FF")))
		_hitboxes.append({"id": "tree_%s" % k, "rect": pill_r})
		fx += cw + 5.0

	_draw_skill_tree_graph(Rect2(14.0, bot_y + 46.0, left_w - 28.0, bot_h - 60.0), tree, font)
	_draw_holo_inspector(Rect2(left_w + 14.0, bot_y, right_w, bot_h), tree, font)


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


func _draw_skill_tree_graph(graph_rect: Rect2, tree: Dictionary, font: Font) -> void:
	var ease_f: float = minf(1.0, _tree_transition)
	var gx: float = graph_rect.position.x
	var gy: float = graph_rect.position.y
	var gw: float = graph_rect.size.x
	var gh: float = graph_rect.size.y
	var cx: float = gx + gw * 0.5
	var cy: float = gy + gh * 0.5
	var tree_id: String = str(tree.get("id", "GENERAL"))
	var tree_col: Color = tree.get("color", Color("#00E5FF"))

	# Topology-specific background guides
	if tree_id == "GENERAL":
		for rad: float in [62.0, 126.0, 182.0]:
			_canvas.draw_arc(Vector2(cx, cy), rad * ease_f, 0.0, TAU, 40, Color(0.0, 0.9, 1.0, 0.14), 1.0)
	elif tree_id == "HEIST":
		_canvas.draw_dashed_line(Vector2(gx + 16.0, gy + gh * 0.28), Vector2(gx + gw - 16.0, gy + gh * 0.28), Color(0.22, 1.0, 0.53, 0.14), 1.0, 6.0)
		_canvas.draw_dashed_line(Vector2(gx + 16.0, gy + gh * 0.72), Vector2(gx + gw - 16.0, gy + gh * 0.72), Color(0.22, 1.0, 0.53, 0.14), 1.0, 6.0)
	elif tree_id == "HACKER":
		for y_pct: float in [0.36, 0.60, 0.84]:
			_canvas.draw_line(Vector2(gx + 16.0, gy + gh * y_pct), Vector2(gx + gw - 16.0, gy + gh * y_pct), Color(1.0, 0.78, 0.34, 0.12), 1.0)
	elif tree_id == "UNIX":
		var grid_x: float = gx
		while grid_x <= gx + gw:
			_canvas.draw_line(Vector2(grid_x, gy), Vector2(grid_x, gy + gh), Color(1.0, 0.18, 0.53, 0.07), 1.0)
			grid_x += 36.0

	var nodes: Array = tree.get("nodes", [])
	var edges: Array = tree.get("edges", [])
	var px_pts: Array[Vector2] = []
	for nd: Dictionary in nodes:
		var np: Vector2 = nd.get("pos", Vector2(0.5, 0.5))
		var target_pt := Vector2(gx + np.x * gw, gy + np.y * gh)
		px_pts.append(Vector2(cx, cy).lerp(target_pt, ease_f))

	# Distinct edge drawing per topology
	for e_idx: int in range(edges.size()):
		var edge: Array = edges[e_idx]
		var a: int = int(edge[0])
		var b: int = int(edge[1])
		if a >= px_pts.size() or b >= px_pts.size():
			continue
		var pa: Vector2 = px_pts[a]
		var pb: Vector2 = px_pts[b]
		var na: Dictionary = nodes[a]
		var nb: Dictionary = nodes[b]
		var active: bool = bool(na.get("unlocked", false)) and bool(nb.get("unlocked", false))
		var edge_col: Color = Color(tree_col.r, tree_col.g, tree_col.b, 0.65) if active else Color("#1C283B")
		var lw: float = 2.0 if active else 1.0

		var edge_pts := PackedVector2Array()
		if tree_id == "UNIX":
			var mid_x: float = (pa.x + pb.x) * 0.5
			edge_pts = PackedVector2Array([pa, Vector2(mid_x, pa.y), Vector2(mid_x, pb.y), pb])
			_canvas.draw_polyline(edge_pts, edge_col, lw)
			var pad_col: Color = tree_col if active else Color("#28364D")
			_canvas.draw_circle(Vector2(mid_x, pa.y), 2.2, pad_col)
			_canvas.draw_circle(Vector2(mid_x, pb.y), 2.2, pad_col)
		elif tree_id == "HEIST":
			var mid_pt: Vector2 = (pa + pb) * 0.5
			var c1 := Vector2(mid_pt.x, pa.y)
			var c2 := Vector2(mid_pt.x, pb.y)
			for s_i: int in range(13):
				var t: float = float(s_i) / 12.0
				var omt: float = 1.0 - t
				var bp: Vector2 = omt * omt * omt * pa + 3.0 * omt * omt * t * c1 + 3.0 * omt * t * t * c2 + t * t * t * pb
				edge_pts.append(bp)
			_canvas.draw_polyline(edge_pts, edge_col, lw)
		elif tree_id == "HACKER":
			var mid_y: float = (pa.y + pb.y) * 0.5
			edge_pts = PackedVector2Array([pa, Vector2(pa.x, mid_y), pb])
			_canvas.draw_polyline(edge_pts, edge_col, lw)
		else:
			edge_pts = PackedVector2Array([pa, pb])
			_canvas.draw_line(pa, pb, edge_col, lw)

		if active:
			var pkt_t: float = fmod(p._pulse * 0.75 + float(e_idx) * 0.22, 1.0)
			_canvas.draw_circle(sample_polyline(edge_pts, pkt_t), 2.3, Color.WHITE)

	_hover_node_idx = -1
	for idx: int in range(px_pts.size()):
		var pt: Vector2 = px_pts[idx]
		var nd: Dictionary = nodes[idx]
		var is_sel: bool = (_selected_node_idx == idx)
		var r: float = 14.0 if is_sel else (12.0 if str(nd.get("rarity", "")) == "MÍTICA // Ω" else 10.0)
		if _mouse_pos.distance_to(pt) <= r + 6.0:
			_hover_node_idx = idx
		_draw_tree_node_shape(pt, r, nd, tree_id, is_sel, font)
		if p._featured_badge_title == str(nd.get("title", "")) and font != null:
			_canvas.draw_string(font, Vector2(pt.x - 4.0, pt.y - r - 4.0), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FFC857"))
		_hitboxes.append({"id": "tnode_%d" % idx, "rect": Rect2(pt.x - 16.0, pt.y - 16.0, 32.0, 32.0)})

	if _hover_node_idx >= 0 and _hover_node_idx < px_pts.size() and font != null:
		var hn: Dictionary = nodes[_hover_node_idx]
		var hp: Vector2 = px_pts[_hover_node_idx]
		var label: String = "%s %s" % [str(hn.get("glyph", "◈")), str(hn.get("title", ""))]
		var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 16.0
		var tx: float = clampf(hp.x - tw * 0.5, gx + 4.0, gx + gw - tw - 4.0)
		var ty: float = maxf(gy + 4.0, hp.y - 36.0)
		var tip_r := Rect2(tx, ty, tw, 22.0)
		_canvas.draw_rect(tip_r, Color("#09111D"))
		_canvas.draw_rect(tip_r, RARITY_COLORS.get(str(hn.get("rarity", "COMÚN")), Color("#00E5FF")), false, 1.2)
		_canvas.draw_string(font, Vector2(tx + 8.0, ty + 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#EAECF5"))


func _draw_tree_node_shape(pt: Vector2, r: float, nd: Dictionary, tree_id: String, is_sel: bool, font: Font) -> void:
	var rarity: String = str(nd.get("rarity", "COMÚN"))
	var base_col: Color = RARITY_COLORS.get(rarity, Color("#00E5FF"))
	var unlocked: bool = bool(nd.get("unlocked", false))
	var col: Color = Color.WHITE if is_sel else (base_col if unlocked else Color("#455168"))
	var fill_col: Color = Color("#0E192B") if unlocked else Color("#080C14")
	var lw: float = 2.6 if is_sel else (1.8 if unlocked else 1.1)

	if rarity == "MÍTICA // Ω":
		var pulse_r: float = 3.0 + sin(p._pulse * 3.5) * 2.0
		_canvas.draw_arc(pt, r + pulse_r + 3.0, 0.0, TAU, 24, Color(1.0, 0.18, 0.53, 0.55), 1.2)

	if tree_id == "GENERAL":
		var poly := PackedVector2Array([
			Vector2(pt.x, pt.y - r * 1.15),
			Vector2(pt.x + r * 1.15, pt.y),
			Vector2(pt.x, pt.y + r * 1.15),
			Vector2(pt.x - r * 1.15, pt.y),
		])
		_canvas.draw_colored_polygon(poly, fill_col)
		poly.append(poly[0])
		_canvas.draw_polyline(poly, col, lw)
	elif tree_id == "CYBER":
		var poly := PackedVector2Array()
		for i: int in range(6):
			var a: float = (PI / 3.0) * float(i) - PI / 6.0
			poly.append(pt + Vector2(cos(a), sin(a)) * (r * 1.05))
		_canvas.draw_colored_polygon(poly, fill_col)
		poly.append(poly[0])
		_canvas.draw_polyline(poly, col, lw)
	elif tree_id == "UNIX" or tree_id == "HEIST":
		var sq := Rect2(pt.x - r * 0.95, pt.y - r * 0.95, r * 1.9, r * 1.9)
		_canvas.draw_rect(sq, fill_col)
		_canvas.draw_rect(sq, col, false, lw)
	else:
		_canvas.draw_circle(pt, r, fill_col)
		_canvas.draw_arc(pt, r, 0.0, TAU, 24, col, lw)

	if font != null:
		var gl: String = str(nd.get("glyph", "◈"))
		var gsize: int = 12 if rarity == "MÍTICA // Ω" else 10
		var tsz: Vector2 = font.get_string_size(gl, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize)
		_canvas.draw_string(font, Vector2(pt.x - tsz.x * 0.5, pt.y + 4.0), gl, HORIZONTAL_ALIGNMENT_LEFT, -1, gsize, base_col if unlocked else Color("#7A869E"))


func _draw_holo_inspector(rect: Rect2, tree: Dictionary, font: Font) -> void:
	var nodes: Array = tree.get("nodes", [])
	if nodes.is_empty():
		return
	var idx: int = clampi(_selected_node_idx, 0, nodes.size() - 1)
	var nd: Dictionary = nodes[idx]
	var rarity: String = str(nd.get("rarity", "COMÚN"))
	var col: Color = RARITY_COLORS.get(rarity, Color("#00E5FF"))
	var unlocked: bool = bool(nd.get("unlocked", false))

	ProfileRendererClass._draw_shell_panel(_canvas, rect, font, "HOLO-CHIP 2.5D // INSPECTOR", col)

	var ix: float = rect.position.x
	var iy: float = rect.position.y
	var iw: float = rect.size.x
	var ih: float = rect.size.y

	_draw_holo_3d(Vector2(ix + iw * 0.5, iy + 96.0), 54.0, col, float(idx) * 0.7, unlocked)

	if font != null:
		var gl: String = str(nd.get("glyph", "◈"))
		var gsz: Vector2 = font.get_string_size(gl, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		_canvas.draw_string(font, Vector2(ix + iw * 0.5 - gsz.x * 0.5, iy + 104.0), gl, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE if unlocked else Color("#7A869E"))
		_canvas.draw_string(font, Vector2(ix + 18.0, iy + 188.0), str(nd.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, int(iw - 36.0), 14, col)
		var status_txt: String = "%s  |  %s  |  %s" % [str(tree.get("short", "")), rarity, ("✓ DESBLOQUEADA" if unlocked else "🔒 BLOQUEADA")]
		_canvas.draw_string(font, Vector2(ix + 18.0, iy + 208.0), status_txt, HORIZONTAL_ALIGNMENT_LEFT, int(iw - 36.0), 10, Color("#39FF88") if unlocked else Color("#FFC857"))

		var body_txt: String = str(nd.get("desc", "")) if unlocked else ("Requisito: " + str(nd.get("req", "")))
		_draw_wrapped_text(body_txt, Vector2(ix + 18.0, iy + 234.0), iw - 36.0, 17.0, 11, Color("#EAECF5"), font)

		var py: float = iy + ih - 94.0
		var prog: float = float(nd.get("progress", 0.0))
		_canvas.draw_string(font, Vector2(ix + 18.0, py), "PROGRESO: %d%%" % int(round(prog * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#7A869E"))
		_draw_bar(Rect2(ix + 18.0, py + 10.0, iw - 36.0, 10.0), prog, col)

	var btn_rect := Rect2(ix + 18.0, iy + ih - 52.0, iw - 36.0, 32.0)
	var is_eq: bool = (p._featured_badge_title == str(nd.get("title", "")))
	var lbl: String = "BLOQUEADA — COMPLETA REQUISITO" if not unlocked else ("★ EQUIPADA EN PERFIL" if is_eq else "★ EQUIPAR EN PERFIL")
	var btn_col: Color = (Color("#FFC857") if is_eq else Color("#39FF88")) if unlocked else Color("#455168")
	ProfileRendererClass._draw_shell_pill(_canvas, btn_rect, font, lbl, unlocked, btn_col)
	if unlocked:
		_hitboxes.append({"id": "equip_badge", "rect": btn_rect})


func _draw_holo_3d(center: Vector2, radius: float, col: Color, seed_offset: float, unlocked: bool) -> void:
	var t: float = p._pulse * 1.15 + seed_offset
	var cos_y: float = cos(t)
	var sin_y: float = sin(t)
	var cos_x: float = cos(t * 0.55)
	var sin_x: float = sin(t * 0.55)

	var pts3: Array[Vector3] = [
		Vector3(0.0, -1.15, 0.0),
		Vector3(0.95, 0.0, 0.0),
		Vector3(0.0, 0.0, 0.95),
		Vector3(-0.95, 0.0, 0.0),
		Vector3(0.0, 0.0, -0.95),
		Vector3(0.0, 1.15, 0.0),
	]
	var edges: Array = [
		[0, 1], [0, 2], [0, 3], [0, 4],
		[5, 1], [5, 2], [5, 3], [5, 4],
		[1, 2], [2, 3], [3, 4], [4, 1],
	]
	var proj: Array[Vector2] = []
	for v: Vector3 in pts3:
		var rx: float = v.x * cos_y - v.z * sin_y
		var rz: float = v.x * sin_y + v.z * cos_y
		var ry: float = v.y * cos_x - rz * sin_x
		var fz: float = v.y * sin_x + rz * cos_x
		var sc: float = radius / (2.6 - fz * 0.55)
		proj.append(center + Vector2(rx * sc, ry * sc))

	var halo_col: Color = Color(col.r, col.g, col.b, 0.12 if unlocked else 0.05)
	_canvas.draw_circle(center, radius * 0.95, halo_col)

	var wire_col: Color = col if unlocked else Color("#7A869E")
	var lw: float = 1.8 if unlocked else 1.1
	for e: Array in edges:
		_canvas.draw_line(proj[int(e[0])], proj[int(e[1])], wire_col, lw)

	if unlocked:
		for i: int in range(6):
			var ang: float = t * 1.6 + float(i) * (PI / 3.0)
			var orb_pt := center + Vector2(cos(ang) * radius * 0.85, sin(ang * 1.3) * radius * 0.42)
			_canvas.draw_circle(orb_pt, 2.0, col if i % 2 == 0 else Color.WHITE)


func _draw_bar(r: Rect2, pct: float, col: Color) -> void:
	_canvas.draw_rect(r, Color("#111A29"))
	var fw: float = clampf(pct, 0.0, 1.0) * r.size.x
	if fw > 0.0:
		_canvas.draw_rect(Rect2(r.position, Vector2(fw, r.size.y)), col)


func _draw_wrapped_text(text: String, pos: Vector2, max_w: float, line_h: float, fsize: int, col: Color, font: Font) -> void:
	var words: PackedStringArray = text.split(" ")
	var line: String = ""
	var cy: float = pos.y
	for w: String in words:
		var test: String = w if line == "" else ("%s %s" % [line, w])
		if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > max_w:
			_canvas.draw_string(font, Vector2(pos.x, cy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
			line = w
			cy += line_h
		else:
			line = test
	if line != "":
		_canvas.draw_string(font, Vector2(pos.x, cy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
