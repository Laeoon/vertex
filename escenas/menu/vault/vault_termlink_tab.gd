extends RefCounted

## Tab 02 // TERMLINK .ENC: Camouflaged RobCo Memory Dump + Positional Likeness Matrix + Dossier Viewer.
## Rendered 100% via _draw() on a single Control node for 60 FPS performance.

const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

const TERMLINK_WORDS: Array[String] = [
	"DIJKSTRA", "TOPOLOGY", "DEADLOCK", "FIREWALL",
	"BACKBONE", "HYPERVIS", "SHAMIRKY", "ZEROTRST",
	"PROTOCOL", "SYNDICAT", "MAINFRAM", "SENTINEL",
]
const TERMLINK_TRAPS: Array[String] = ["(#?$!)", "[+-=]", "{@%~^}", "<=-_!>", "(^*&)", "[~$#@]"]
const NOISE_CHARS: String = "!@#$%^&*_+-=|;:,.?/"

var p: Profile
var _canvas: Control = null
var _view_mode: String = "HEX" # "HEX" | "DOSSIER"
var _hover_char: String = ""
var _last_likeness: Dictionary = {} # { "word": String, "score": int, "mask": Array[bool] }
var _mouse_pos: Vector2 = Vector2(-1.0, -1.0)
var _hitboxes: Array[Dictionary] = []


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	var ctrl := Control.new()
	ctrl.name = "TermlinkDrawCanvas"
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.focus_mode = Control.FOCUS_CLICK
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.draw.connect(_on_draw)
	ctrl.gui_input.connect(_on_gui_input)
	container.add_child(ctrl)
	_canvas = ctrl
	p._termlink_canvas = ctrl


static func compute_likeness_mask(word_a: String, word_b: String) -> Array[bool]:
	var mask: Array[bool] = []
	var n: int = mini(word_a.length(), word_b.length())
	for i: int in range(word_b.length()):
		mask.append(i < n and word_a[i] == word_b[i])
	return mask


static func find_token_at_char(row_data: Dictionary, char_idx: int) -> Dictionary:
	var tokens: Array = row_data.get("tokens", [])
	for tok: Dictionary in tokens:
		var s: int = int(tok.get("start", -1))
		var e: int = int(tok.get("end", -1))
		if char_idx >= s and char_idx <= e:
			return tok
	return {}


static func build_camo_memory(file_idx: int, removed_duds: Array) -> Array:
	var enc_files: Array[Dictionary] = VaultModules.ENC_FILES
	var target_pass: String = "DIJKSTRA"
	if file_idx >= 0 and file_idx < enc_files.size():
		target_pass = str(enc_files[file_idx].get("pass", "DIJKSTRA"))

	var seed_val: int = 1337 + file_idx * 97
	var row_words: Array[Dictionary] = [
		{1: target_pass, 4: "HYPERVIS", 7: "BACKBONE", 10: "PROTOCOL", 13: "SENTINEL", 15: "MAINFRAM"},
		{2: "SHAMIRKY", 5: "ZEROTRST", 8: "SYNDICAT", 11: "TOPOLOGY", 14: "DEADLOCK"},
	]
	if file_idx % 2 == 1:
		row_words[0].erase(1)
		row_words[1][3] = target_pass

	var row_traps: Array[Dictionary] = [
		{2: TERMLINK_TRAPS[0], 6: TERMLINK_TRAPS[1], 12: TERMLINK_TRAPS[2]},
		{0: TERMLINK_TRAPS[3], 6: TERMLINK_TRAPS[4], 12: TERMLINK_TRAPS[5]},
	]

	var cols: Array = [[], []]
	for c: int in range(2):
		var base_addr: int = 0x7F40 if c == 0 else 0x8740
		for r: int in range(16):
			var addr: String = "0x%04X" % (base_addr + r * 8)
			var chars: Array[String] = []
			for i: int in range(16):
				seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
				chars.append(NOISE_CHARS[seed_val % NOISE_CHARS.length()])

			var tokens: Array[Dictionary] = []
			if row_words[c].has(r):
				var w: String = str(row_words[c][r])
				seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
				var start: int = seed_val % maxi(1, 16 - w.length())
				var dead: bool = removed_duds.has(w)
				for k: int in range(w.length()):
					chars[start + k] = "." if dead else w[k]
				if not dead:
					tokens.append({"start": start, "end": start + w.length() - 1, "text": w, "type": "word"})
			elif row_traps[c].has(r):
				var tr: String = str(row_traps[c][r])
				seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
				var start: int = seed_val % maxi(1, 16 - tr.length())
				var trap_key: String = "%d:%d" % [c, r]
				var dead: bool = removed_duds.has(trap_key)
				for k: int in range(tr.length()):
					chars[start + k] = "." if dead else tr[k]
				if not dead:
					tokens.append({"start": start, "end": start + tr.length() - 1, "text": tr, "type": "trap", "key": trap_key})

			cols[c].append({"addr": addr, "chars": chars, "tokens": tokens})
	return cols


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
			for i: int in range(_hitboxes.size() - 1, -1, -1):
				var hb: Dictionary = _hitboxes[i]
				var r: Rect2 = hb.get("rect", Rect2())
				if r.has_point(mb.position):
					var hid: String = str(hb.get("id", ""))
					if hid.begins_with("tl_file_"):
						_select_file(int(hid.trim_prefix("tl_file_")))
						return
					elif hid == "tl_reset":
						_reset_memory()
						return
					elif hid == "tl_view_hex":
						_view_mode = "HEX"
						p._play_click_sfx()
						if _canvas != null:
							_canvas.queue_redraw()
						return
					elif hid == "tl_view_dos":
						_view_mode = "DOSSIER"
						p._play_click_sfx()
						if _canvas != null:
							_canvas.queue_redraw()
						return
					elif hid.begins_with("tl_tok_"):
						var tok_type: String = str(hb.get("tok_type", ""))
						var tok_text: String = str(hb.get("tok_text", ""))
						var tok_key: String = str(hb.get("tok_key", ""))
						if tok_type == "word":
							_guess_word(tok_text)
						elif tok_type == "trap":
							_trigger_trap(tok_text, tok_key)
						return


func _select_file(idx: int) -> void:
	p._selected_enc_idx = clampi(idx, 0, VaultModules.ENC_FILES.size() - 1)
	_view_mode = "DOSSIER" if p._enc_unlocked.has(p._selected_enc_idx) else "HEX"
	_reset_memory()


func _reset_memory() -> void:
	p._enc_attempts = 4
	p._removed_duds.clear()
	_last_likeness.clear()
	var ef: Dictionary = VaultModules.ENC_FILES[p._selected_enc_idx]
	p._enc_console_lines = ["> MOUNTED %s" % str(ef.get("file", "")), "> ESCANEA LA MEMORIA CON EL CURSOR"]
	p._play_click_sfx()
	if _canvas != null:
		_canvas.queue_redraw()


func _guess_word(word: String) -> void:
	if p._enc_attempts <= 0 or p._enc_unlocked.has(p._selected_enc_idx):
		return
	var ef: Dictionary = VaultModules.ENC_FILES[p._selected_enc_idx]
	var target_pass: String = str(ef.get("pass", "DIJKSTRA"))
	p._play_click_sfx()

	if word == target_pass:
		p._enc_unlocked[p._selected_enc_idx] = true
		_view_mode = "DOSSIER"
		p._enc_console_lines.append("> %s" % word)
		p._enc_console_lines.append("> ACCESS GRANTED!")
		_last_likeness = {"word": word, "score": target_pass.length(), "mask": compute_likeness_mask(word, target_pass)}
		_mount_dossier_in_vfs(ef)
		p._save_profile()
	else:
		var score: int = VaultModules.compute_likeness(word, target_pass)
		var mask: Array[bool] = compute_likeness_mask(word, target_pass)
		_last_likeness = {"word": word, "score": score, "mask": mask}
		p._enc_attempts = maxi(0, p._enc_attempts - 1)
		p._enc_console_lines.append("> %s" % word)
		p._enc_console_lines.append("> ENTRY DENIED")
		p._enc_console_lines.append("> LIKENESS=%d/%d" % [score, target_pass.length()])
		if p._enc_attempts <= 0:
			p._enc_console_lines.append("> LOCKOUT! REINICIA MEMORIA.")
	if _canvas != null:
		_canvas.queue_redraw()


func _trigger_trap(tok_text: String, tok_key: String) -> void:
	p._play_click_sfx()
	p._removed_duds.append(tok_key)
	var ef: Dictionary = VaultModules.ENC_FILES[p._selected_enc_idx]
	var target_pass: String = str(ef.get("pass", "DIJKSTRA"))
	var dud: String = ""
	for w: String in TERMLINK_WORDS:
		if w != target_pass and not p._removed_duds.has(w):
			dud = w
			break
	if dud != "" and randf() > 0.3:
		p._removed_duds.append(dud)
		p._enc_console_lines.append("> %s" % tok_text)
		p._enc_console_lines.append("> DUD REMOVED: %s" % dud)
	else:
		p._enc_attempts = 4
		p._enc_console_lines.append("> %s" % tok_text)
		p._enc_console_lines.append("> ALLOWANCE REPLENISHED")
	if _canvas != null:
		_canvas.queue_redraw()


func _mount_dossier_in_vfs(ef: Dictionary) -> void:
	if p._shell_engine == null or p._shell_engine.vfs == null:
		return
	var base_name: String = str(ef.get("file", "exp.enc")).replace(".enc", ".txt")
	var vfs_path: String = "/home/operator/expedientes/" + base_name
	var full_txt: String = "CLASIFICACIÓN: %s\nOBJETIVO: %s\nAFILIACIÓN: %s\n\n%s" % [
		str(ef.get("classification", "")),
		str(ef.get("target", "")),
		str(ef.get("affiliation", "")),
		str(ef.get("content", "")),
	]
	p._shell_engine.vfs._fs[vfs_path] = {"type": "file", "content": full_txt, "perms": "-rw-r--r--"}
	if p._shell_engine.vfs._fs.has("/home/operator/expedientes"):
		var dir_node: Dictionary = p._shell_engine.vfs._fs["/home/operator/expedientes"]
		var children: Array = dir_node.get("children", [])
		if not children.has(base_name):
			children.append(base_name)


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
	var left_w: float = 258.0

	# Left panel: .ENC Files + Metadata + Reset
	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(0.0, 0.0, left_w, rh), font, "expedientes.enc", Color("#39FF88"))
	var enc_files: Array[Dictionary] = VaultModules.ENC_FILES
	for idx: int in range(enc_files.size()):
		var ef: Dictionary = enc_files[idx]
		var fy: float = 26.0 + float(idx) * 54.0
		var sel: bool = (p._selected_enc_idx == idx)
		var unlocked: bool = p._enc_unlocked.has(idx)
		var card_r := Rect2(12.0, fy, left_w - 24.0, 46.0)
		_canvas.draw_rect(card_r, Color("#102420") if sel else Color("#0B111B"))
		_canvas.draw_rect(card_r, Color("#39FF88") if sel else Color("#1F2B3D"), false, 1.0)
		if font != null:
			_canvas.draw_string(font, Vector2(20.0, fy + 18.0), str(ef.get("file", "")), HORIZONTAL_ALIGNMENT_LEFT, int(left_w - 40.0), 10, Color("#39FF88") if sel else Color("#EAECF5"))
			_canvas.draw_string(font, Vector2(20.0, fy + 35.0), "[✓ DESCIFRADO]" if unlocked else "[🔒 CIFRADO AES-512]", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#00E5FF") if unlocked else Color("#FFC857"))
		_hitboxes.append({"id": "tl_file_%d" % idx, "rect": card_r})

	var cur_file: Dictionary = enc_files[clampi(p._selected_enc_idx, 0, enc_files.size() - 1)]
	var cur_unlocked: bool = p._enc_unlocked.has(p._selected_enc_idx)
	var meta_y: float = 252.0
	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(12.0, meta_y, left_w - 24.0, 152.0), font, "METADATOS", Color("#2F4563"), Color("#080E16"))
	if font != null:
		var metas: Array = [
			["PESO :", str(cur_file.get("weight", "48.4 KB")), Color("#EAECF5")],
			["CIFR :", str(cur_file.get("cipher", "AES-512")), Color("#00E5FF")],
			["HASH :", str(cur_file.get("hash", "0x9F4A")), Color("#7A869E")],
			["CLAS :", str(cur_file.get("classification", "")), Color("#FFC857")],
			["RUTA :", "/home/operator/exp/", Color("#39FF88")],
		]
		for i: int in range(metas.size()):
			var m: Array = metas[i]
			_canvas.draw_string(font, Vector2(22.0, meta_y + 28.0 + float(i) * 22.0), str(m[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#7A869E"))
			_canvas.draw_string(font, Vector2(66.0, meta_y + 28.0 + float(i) * 22.0), str(m[1]), HORIZONTAL_ALIGNMENT_LEFT, int(left_w - 88.0), 10, m[2])

	var reset_rect := Rect2(12.0, 418.0, left_w - 24.0, 28.0)
	ProfileRendererClass._draw_shell_pill(_canvas, reset_rect, font, "↺ REINICIAR MEMORIA", false, Color("#39FF88"))
	_hitboxes.append({"id": "tl_reset", "rect": reset_rect})

	# Right panel: RobCo Termlink Memory Dump or Classified Dossier
	var hx: float = left_w + 14.0
	var hw: float = maxf(320.0, rw - hx)
	ProfileRendererClass._draw_shell_panel(_canvas, Rect2(hx, 0.0, hw, rh), font, "KERNEL_LINK v4.08 // VOLCADO DE MEMORIA", Color("#39FF88"), Color("#050B09"))

	if font != null:
		_canvas.draw_string(font, Vector2(hx + 18.0, 32.0), "TERMLINK — %s" % str(cur_file.get("file", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#39FF88"))
		var att_col: Color = Color("#FF2E88") if p._enc_attempts <= 1 else Color("#FFC857")
		_canvas.draw_string(font, Vector2(hx + 18.0, 54.0), "INTENTOS RESTANTES: %d" % p._enc_attempts, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, att_col)

	for i: int in range(4):
		var blk_col: Color = (Color("#FF2E88") if p._enc_attempts == 1 else Color("#39FF88")) if i < p._enc_attempts else Color("#13241D")
		_canvas.draw_rect(Rect2(hx + 184.0 + float(i) * 22.0, 43.0, 16.0, 13.0), blk_col)

	if cur_unlocked:
		var r_hex := Rect2(hx + hw - 266.0, 20.0, 118.0, 26.0)
		ProfileRendererClass._draw_shell_pill(_canvas, r_hex, font, "⌨ MEMORIA HEX", _view_mode == "HEX", Color("#39FF88"))
		_hitboxes.append({"id": "tl_view_hex", "rect": r_hex})
		var r_dos := Rect2(hx + hw - 140.0, 20.0, 124.0, 26.0)
		ProfileRendererClass._draw_shell_pill(_canvas, r_dos, font, "📄 EXPEDIENTE", _view_mode == "DOSSIER", Color("#00E5FF"))
		_hitboxes.append({"id": "tl_view_dos", "rect": r_dos})

	if cur_unlocked and _view_mode == "DOSSIER":
		var dy: float = 78.0
		ProfileRendererClass._draw_shell_panel(_canvas, Rect2(hx + 18.0, dy, hw - 36.0, rh - 96.0), font, "EXPEDIENTE DESCIFRADO // %s" % str(cur_file.get("classification", "")), Color("#00E5FF"), Color("#071117"))
		if font != null:
			_canvas.draw_string(font, Vector2(hx + 36.0, dy + 38.0), str(cur_file.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#39FF88"))
			_canvas.draw_string(font, Vector2(hx + 36.0, dy + 62.0), "OBJETIVO: %s  |  AFILIACIÓN: %s" % [str(cur_file.get("target", "")), str(cur_file.get("affiliation", ""))], HORIZONTAL_ALIGNMENT_LEFT, int(hw - 72.0), 11, Color("#FFC857"))
			_draw_wrapped(str(cur_file.get("content", "")), Vector2(hx + 36.0, dy + 104.0), hw - 76.0, 21.0, 12, Color("#EAECF5"), font)
		return

	# Uniform Phosphor Camouflage Hex Dump
	var mem_cols: Array = build_camo_memory(p._selected_enc_idx, p._removed_duds)
	_hover_char = ""
	var char_w: float = 9.5
	var row_h: float = minf(31.0, (rh - 115.0) / 16.0)
	var start_y: float = 92.0
	var col_step: float = minf(226.0, (hw - 200.0) * 0.5)

	for c: int in range(2):
		var col_x: float = hx + 18.0 + float(c) * col_step
		var rows: Array = mem_cols[c]
		for r: int in range(rows.size()):
			var row_data: Dictionary = rows[r]
			var y: float = start_y + float(r) * row_h
			if font != null:
				_canvas.draw_string(font, Vector2(col_x, y), str(row_data.get("addr", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#2D7A56"))

			var data_x: float = col_x + 54.0
			var chars: Array = row_data.get("chars", [])
			var hov_tok: Dictionary = {}
			var hov_single: int = -1

			if _mouse_pos.y >= y - 13.0 and _mouse_pos.y <= y + 5.0:
				var ci: int = int(floor((_mouse_pos.x - data_x) / char_w))
				if ci >= 0 and ci < chars.size():
					hov_tok = find_token_at_char(row_data, ci)
					if not hov_tok.is_empty():
						_hover_char = str(hov_tok.get("text", ""))
						var ts: int = int(hov_tok.get("start", 0))
						var te: int = int(hov_tok.get("end", 0))
						_hitboxes.append({
							"id": "tl_tok_%d_%d" % [c, r],
							"rect": Rect2(data_x + float(ts) * char_w, y - 13.0, float(te - ts + 1) * char_w, 18.0),
							"tok_type": str(hov_tok.get("type", "")),
							"tok_text": _hover_char,
							"tok_key": str(hov_tok.get("key", "")),
						})
					else:
						hov_single = ci
						_hover_char = str(chars[ci])

			if font != null:
				for i: int in range(chars.size()):
					var cx: float = data_x + float(i) * char_w
					var in_tok: bool = (not hov_tok.is_empty()) and i >= int(hov_tok.get("start", -1)) and i <= int(hov_tok.get("end", -1))
					var in_single: bool = hov_tok.is_empty() and hov_single == i
					if in_tok or in_single:
						_canvas.draw_rect(Rect2(cx - 0.5, y - 13.0, char_w + 0.5, 17.0), Color("#39FF88"))
						_canvas.draw_string(font, Vector2(cx, y), str(chars[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#05070C"))
					else:
						_canvas.draw_string(font, Vector2(cx, y), str(chars[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#39A874"))

	# Right-side RobCo Console & Positional Likeness Matrix
	var cons_x: float = hx + 18.0 + col_step * 2.0 + 10.0
	var cons_w: float = maxf(140.0, hw - (cons_x - hx) - 14.0)
	if cons_w >= 140.0:
		ProfileRendererClass._draw_shell_panel(_canvas, Rect2(cons_x, 78.0, cons_w, rh - 94.0), font, "CONSOLA", Color("#39FF88"), Color("#060B09"))
		if font != null:
			var total_lines: int = p._enc_console_lines.size()
			var start_idx: int = maxi(0, total_lines - 12)
			for idx: int in range(start_idx, total_lines):
				var ln: String = str(p._enc_console_lines[idx])
				var lcol: Color = Color("#39FF88") if ln.contains("GRANTED") else (Color("#FFC857") if ln.contains("LIKENESS") else Color("#66CDAA"))
				_canvas.draw_string(font, Vector2(cons_x + 10.0, 106.0 + float(idx - start_idx) * 21.0), ln, HORIZONTAL_ALIGNMENT_LEFT, int(cons_w - 20.0), 10, lcol)

			if not _last_likeness.is_empty():
				var lm_y: float = rh - 136.0
				var lm_word: String = str(_last_likeness.get("word", ""))
				var lm_score: int = int(_last_likeness.get("score", 0))
				var lm_mask: Array = _last_likeness.get("mask", [])
				_canvas.draw_string(font, Vector2(cons_x + 10.0, lm_y), "POSICIÓN: %s (%d/%d)" % [lm_word, lm_score, lm_word.length()], HORIZONTAL_ALIGNMENT_LEFT, int(cons_w - 20.0), 10, Color("#FFC857"))
				for i: int in range(mini(8, lm_mask.size())):
					var cell_x: float = cons_x + 10.0 + float(i) * 19.0
					var matched: bool = bool(lm_mask[i])
					_canvas.draw_rect(Rect2(cell_x, lm_y + 8.0, 16.0, 18.0), Color("#39FF88") if matched else Color("#10221A"))
					_canvas.draw_rect(Rect2(cell_x, lm_y + 8.0, 16.0, 18.0), Color("#39FF88"), false, 1.0)
					_canvas.draw_string(font, Vector2(cell_x + 4.0, lm_y + 21.0), lm_word[i] if matched else "·", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#05070C") if matched else Color("#3A6E54"))

			var blink: String = "█" if int(floor(p._pulse * 2.5)) % 2 == 0 else ""
			_canvas.draw_string(font, Vector2(cons_x + 10.0, rh - 32.0), ">%s%s" % [_hover_char, blink], HORIZONTAL_ALIGNMENT_LEFT, int(cons_w - 20.0), 12, Color("#39FF88"))


func _draw_wrapped(text: String, pos: Vector2, max_w: float, line_h: float, fsize: int, col: Color, font: Font) -> void:
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
