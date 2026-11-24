extends RefCounted

## Tab 03 // TERMINAL & LAB: Clean 3-Panel TUI (yazi::vfs-tree + fastfetch//btop + terminal::vtx-sh).
## Rendered 100% via _draw() on a single Control node for 60 FPS performance.

const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")

const VFS_TREE: Array[Dictionary] = [
	{"txt": "▾ /home/operator", "path": "/home/operator", "col": Color("#39FF88"), "cmd": "cd /home/operator"},
	{"txt": "   ├─ readme.txt", "path": "/home/operator/readme.txt", "col": Color("#EAECF5"), "cmd": "cat /home/operator/readme.txt"},
	{"txt": "   └─ expedientes/", "path": "/home/operator/expedientes", "col": Color("#00E5FF"), "cmd": "ls /home/operator/expedientes"},
	{"txt": "▸ /usr/bin/academy*", "path": "academy", "col": Color("#39FF88"), "cmd": "academy"},
	{"txt": "▾ /usr/games", "path": "/usr/games", "col": Color("#00E5FF"), "cmd": "ls /usr/games"},
	{"txt": "   ├─ ▶ breach3d", "path": "/usr/games/breach3d", "col": Color("#FF2E88"), "cmd": "/usr/games/breach3d"},
	{"txt": "   └─ ▶ netcycle", "path": "/usr/games/netcycle", "col": Color("#FF2E88"), "cmd": "/usr/games/netcycle"},
]

var p: Profile
var _canvas: Control = null
var _cli_context: String = "USUARIO" # "USUARIO" | "VEX"
var _mouse_pos: Vector2 = Vector2(-1.0, -1.0)
var _hitboxes: Array[Dictionary] = []


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	var ctrl := Control.new()
	ctrl.name = "AcademiaDrawCanvas"
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.focus_mode = Control.FOCUS_ALL
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.draw.connect(_on_draw)
	ctrl.gui_input.connect(_on_gui_input)
	container.add_child(ctrl)
	_canvas = ctrl
	p._academia_canvas = ctrl


func _update_ui() -> void:
	if _canvas != null:
		_canvas.queue_redraw()


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
					if hid == "ctx_user":
						_cli_context = "USUARIO"
						p._sync_shell_identity()
						p._play_click_sfx()
						_update_ui()
						return
					elif hid == "ctx_vex":
						_cli_context = "VEX"
						if p._shell_engine != null:
							p._shell_engine.set_identity("vex", "sector0-node", "SECTOR 0 // VEX")
						p._play_click_sfx()
						_update_ui()
						return
					elif hid.begins_with("yazi_"):
						var cmd_str: String = str(hb.get("cmd", ""))
						p._play_click_sfx()
						_submit_command(cmd_str)
						return
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
				_submit_command(p._cli_input_text)
				p._cli_input_text = ""
				_canvas.accept_event()
			elif ke.keycode == KEY_BACKSPACE:
				if p._cli_input_text.length() > 0:
					p._cli_input_text = p._cli_input_text.substr(0, p._cli_input_text.length() - 1)
				_update_ui()
				_canvas.accept_event()
			elif ke.keycode == KEY_TAB:
				if p._shell_engine != null and p._shell_engine.has_method("autocomplete"):
					p._cli_input_text = str(p._shell_engine.autocomplete(p._cli_input_text))
				_update_ui()
				_canvas.accept_event()
			elif ke.keycode == KEY_UP:
				if not p._cli_history.is_empty():
					if p._cli_history_idx < 0:
						p._cli_history_idx = p._cli_history.size() - 1
					else:
						p._cli_history_idx = maxi(0, p._cli_history_idx - 1)
					p._cli_input_text = p._cli_history[p._cli_history_idx]
				_update_ui()
				_canvas.accept_event()
			elif ke.keycode == KEY_DOWN:
				if not p._cli_history.is_empty() and p._cli_history_idx >= 0:
					if p._cli_history_idx < p._cli_history.size() - 1:
						p._cli_history_idx += 1
						p._cli_input_text = p._cli_history[p._cli_history_idx]
					else:
						p._cli_history_idx = -1
						p._cli_input_text = ""
				_update_ui()
				_canvas.accept_event()
			elif ke.unicode >= 32 and ke.unicode < 127:
				p._cli_input_text += char(ke.unicode)
				_update_ui()
				_canvas.accept_event()


func _submit_command(cmd: String) -> void:
	var trimmed: String = cmd.strip_edges()
	if trimmed.is_empty():
		return
	p._cli_history.append(trimmed)
	p._cli_history_idx = -1
	p._execute_cli_command(trimmed)
	_update_ui()


func _on_draw() -> void:
	if _canvas == null:
		return
	var sz: Vector2 = _canvas.size
	if sz.x <= 10.0 or sz.y <= 10.0:
		return

	_hitboxes.clear()
	var font: Font = p.font
	var rw: float = sz.x
	var rh: float = sz.y
	var left_w: float = 270.0
	var right_x: float = left_w + 14.0
	var right_w: float = maxf(300.0, rw - right_x)

	# 1. Left full-height: yazi::vfs-tree + compact context switch
	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(0.0, 0.0, left_w, rh), font, "yazi::vfs-tree", Color("#FFC857"), Color("#070A10"))

	var r_usr := Rect2(12.0, 18.0, 118.0, 22.0)
	ProfileRendererClass._draw_shell_pill(_canvas, r_usr, font, "CTX: %s" % p.player_name.to_upper().left(8), _cli_context == "USUARIO", Color("#00E5FF"))
	_hitboxes.append({"id": "ctx_user", "rect": r_usr})

	var r_vex := Rect2(138.0, 18.0, 118.0, 22.0)
	ProfileRendererClass._draw_shell_pill(_canvas, r_vex, font, "CTX: VEX @ S0", _cli_context == "VEX", Color("#FF2E88"))
	_hitboxes.append({"id": "ctx_vex", "rect": r_vex})

	var ty: float = 68.0
	for idx: int in range(VFS_TREE.size()):
		var row: Dictionary = VFS_TREE[idx]
		var row_r := Rect2(8.0, ty - 14.0, left_w - 16.0, 22.0)
		if row_r.has_point(_mouse_pos):
			_canvas.draw_rect(row_r, Color("#122030"))
		if font != null:
			_canvas.draw_string(font, Vector2(14.0, ty), str(row.get("txt", "")), HORIZONTAL_ALIGNMENT_LEFT, int(left_w - 24.0), 11, row.get("col", Color("#EAECF5")))
		_hitboxes.append({"id": "yazi_%d" % idx, "rect": row_r, "cmd": str(row.get("cmd", ""))})
		ty += 34.0

	# 2. Right-Top: fastfetch // btop-monitor
	var ff_h: float = 176.0
	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(right_x, 0.0, right_w, ff_h), font, "fastfetch // btop-monitor", Color("#39FF88"), Color("#070A10"))

	# Rotating hexagonal VTX emblem
	var hex_center := Vector2(right_x + 66.0, 86.0)
	var hex_pts := PackedVector2Array()
	for k: int in range(6):
		var a: float = (PI / 3.0) * float(k) + p._pulse * 0.55
		hex_pts.append(hex_center + Vector2(cos(a), sin(a)) * 40.0)
	hex_pts.append(hex_pts[0])
	_canvas.draw_polyline(hex_pts, Color("#00E5FF"), 2.0)
	if font != null:
		var vsz: Vector2 = font.get_string_size("VTX", HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		_canvas.draw_string(font, Vector2(hex_center.x - vsz.x * 0.5, hex_center.y + 5.0), "VTX", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#39FF88"))

	var op_user: String = "vex" if _cli_context == "VEX" else (p._shell_engine.sanitize_username(p.player_name, "operador") if p._shell_engine != null else "operador")
	var op_host: String = "sector0-node" if _cli_context == "VEX" else "boveda-lab"
	var ff_x: float = right_x + 128.0
	if font != null:
		var ff_rows: Array = [
			["%s@%s" % [op_user, op_host], "", Color("#39FF88")],
			["OS    :", "VertexOS 4.7 Forward+", Color("#00E5FF")],
			["SHELL :", "vtx-sh (academy, breach3d)", Color("#EAECF5")],
			["CPU   :", "Capped < 8% (Idle Clean)", Color("#39FF88")],
		]
		for i: int in range(ff_rows.size()):
			var r: Array = ff_rows[i]
			_canvas.draw_string(font, Vector2(ff_x, 34.0 + float(i) * 21.0), str(r[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, r[2])
			if str(r[1]) != "":
				_canvas.draw_string(font, Vector2(ff_x + 54.0, 34.0 + float(i) * 21.0), str(r[1]), HORIZONTAL_ALIGNMENT_LEFT, int(maxf(80.0, right_w - 380.0)), 11, Color("#EAECF5"))

	var ansi_cols: Array[Color] = [Color("#00E5FF"), Color("#39FF88"), Color("#FFC857"), Color("#FF2E88"), Color("#BF5AF2"), Color("#EAECF5")]
	for i: int in range(ansi_cols.size()):
		_canvas.draw_rect(Rect2(ff_x + float(i) * 26.0, 130.0, 20.0, 12.0), ansi_cols[i])

	var bx: float = right_x + right_w - 196.0
	if bx > ff_x + 160.0:
		for b: int in range(14):
			var bh: float = 12.0 + absf(sin(p._pulse * 4.0 + float(b) * 0.45)) * 86.0
			_canvas.draw_rect(Rect2(bx + float(b) * 13.0, 144.0 - bh, 9.0, bh), Color("#00E5FF") if b % 2 == 0 else Color("#BF5AF2"))

	# 3. Right-Bottom: spacious terminal::vtx-sh
	var term_y: float = ff_h + 14.0
	var term_h: float = maxf(180.0, rh - term_y)
	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(right_x, term_y, right_w, term_h), font, "terminal::vtx-sh", Color("#00E5FF"), Color("#06090F"))

	if font != null:
		var flat_lines: Array[String] = []
		for entry: Variant in p._cli_output_lines:
			for sub: String in str(entry).split("\n"):
				flat_lines.append(sub)
		var max_lines: int = maxi(4, int((term_h - 86.0) / 21.0))
		var start_idx: int = maxi(0, flat_lines.size() - max_lines)
		var ly: float = term_y + 28.0
		for idx: int in range(start_idx, flat_lines.size()):
			var line_txt: String = flat_lines[idx]
			var lcol: Color = Color("#39FF88") if line_txt.contains("@") else (Color("#00E5FF") if line_txt.begins_with("OS:") or line_txt.begins_with("┌") or line_txt.begins_with("│") or line_txt.begins_with("└") else Color("#EAECF5"))
			_canvas.draw_string(font, Vector2(right_x + 16.0, ly), line_txt, HORIZONTAL_ALIGNMENT_LEFT, int(right_w - 32.0), 12, lcol)
			ly += 21.0

		_canvas.draw_string(font, Vector2(right_x + 16.0, term_y + term_h - 46.0), "hint: escribe 'academy', 'fastfetch', 'ls', 'cat readme.txt' o usa [TAB]", HORIZONTAL_ALIGNMENT_LEFT, int(right_w - 32.0), 10, Color("#7A869E"))

	_canvas.draw_rect(Rect2(right_x + 8.0, term_y + term_h - 34.0, right_w - 16.0, 28.0), Color("#0A1019"))
	if font != null:
		var prompt_str: String = p._shell_engine.get_prompt_string() if p._shell_engine != null else "operador@boveda-lab:~$ "
		var blink: String = "█" if int(floor(p._pulse * 2.5)) % 2 == 0 else ""
		_canvas.draw_string(font, Vector2(right_x + 16.0, term_y + term_h - 15.0), "%s%s%s" % [prompt_str, p._cli_input_text, blink], HORIZONTAL_ALIGNMENT_LEFT, int(right_w - 32.0), 12, Color("#39FF88"))
