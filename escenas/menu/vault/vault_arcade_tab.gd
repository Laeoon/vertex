extends RefCounted

## Tab 05 // ARCADE (/usr/games/): 100% _draw() Cartridge Shelf + Playable NETCYCLE & ICEBREAKER.

enum Mode { SHELF, NETCYCLE, ICEBREAKER }

const GRID_W: int = 36
const GRID_H: int = 22
const HEX_SYMBOLS: Array[String] = ["A", "B", "C", "D", "E", "F"]
const HEX_COLORS: Dictionary = {
	"A": Color("#00E5FF"),
	"B": Color("#39FF88"),
	"C": Color("#FFC857"),
	"D": Color("#FF2E88"),
	"E": Color("#BF5AF2"),
	"F": Color("#EAECF5"),
}

const COL_BG := Color("#080C14")
const COL_PANEL := Color("#0D131F")
const COL_CARD := Color("#121A28")
const COL_BORDER := Color("#233249")
const COL_CYAN := Color("#00E5FF")
const COL_PINK := Color("#FF2E88")
const COL_GREEN := Color("#39FF88")
const COL_AMBER := Color("#FFC857")
const COL_PURPLE := Color("#BF5AF2")
const COL_TEXT := Color("#EAECF5")
const COL_MUTED := Color("#7A869E")

var p: Profile
var _canvas: Control = null
var _mode: Mode = Mode.SHELF
var _hitboxes: Array[Dictionary] = []

# NETCYCLE state
var _nc_state: String = "READY" # READY | PLAYING | WIN | LOSE | DRAW
var _nc_round: int = 1
var _nc_score: int = 0
var _nc_best: int = 0
var _nc_accum: float = 0.0
var _nc_p_pos: Vector2i = Vector2i(7, 11)
var _nc_p_dir: Vector2i = Vector2i(1, 0)
var _nc_p_next_dir: Vector2i = Vector2i(1, 0)
var _nc_p_trail: Array[Vector2i] = []
var _nc_e_pos: Vector2i = Vector2i(28, 11)
var _nc_e_dir: Vector2i = Vector2i(-1, 0)
var _nc_e_trail: Array[Vector2i] = []

# ICEBREAKER state
var _ib_secret: Array[String] = []
var _ib_input: Array[String] = []
var _ib_history: Array[Dictionary] = [] # {"guess": Array[String], "exact": int, "misplaced": int}
var _ib_status: String = "PLAYING" # PLAYING | WON | LOST
var _ib_wins: int = 0


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	var ctrl := Control.new()
	ctrl.name = "ArcadeDrawCanvas"
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.focus_mode = Control.FOCUS_ALL
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.draw.connect(_on_draw)
	ctrl.gui_input.connect(_on_gui_input)
	container.add_child(ctrl)
	_canvas = ctrl
	p._cosmetics_control = ctrl


func is_playing_game() -> bool:
	return _mode != Mode.SHELF


func exit_game() -> void:
	_mode = Mode.SHELF
	if _canvas != null:
		_canvas.queue_redraw()


func tick(delta: float) -> void:
	if _canvas == null or not _canvas.visible:
		return
	if _mode == Mode.NETCYCLE and _nc_state == "PLAYING":
		var step_interval: float = maxf(0.065, 0.095 - float(_nc_round - 1) * 0.004)
		_nc_accum += delta
		while _nc_accum >= step_interval and _nc_state == "PLAYING":
			_nc_accum -= step_interval
			step_netcycle()
		_canvas.queue_redraw()


func start_netcycle(reset_score: bool = true) -> void:
	_mode = Mode.NETCYCLE
	if reset_score:
		_nc_round = 1
		_nc_score = 0
	_nc_state = "READY"
	_nc_accum = 0.0
	_nc_p_pos = Vector2i(7, 11)
	_nc_p_dir = Vector2i(1, 0)
	_nc_p_next_dir = Vector2i(1, 0)
	_nc_p_trail = [_nc_p_pos]
	_nc_e_pos = Vector2i(GRID_W - 8, 11)
	_nc_e_dir = Vector2i(-1, 0)
	_nc_e_trail = [_nc_e_pos]
	if _canvas != null:
		_canvas.grab_focus()
		_canvas.queue_redraw()


func set_netcycle_direction(dir: Vector2i) -> void:
	if dir == Vector2i.ZERO:
		return
	if dir + _nc_p_dir == Vector2i.ZERO:
		return
	_nc_p_next_dir = dir
	if _nc_state == "READY":
		_nc_state = "PLAYING"


func step_netcycle() -> void:
	if _nc_state == "READY":
		_nc_state = "PLAYING"
	if _nc_state != "PLAYING":
		return

	_nc_p_dir = _nc_p_next_dir
	_nc_e_dir = _choose_ai_direction()

	var next_p: Vector2i = _nc_p_pos + _nc_p_dir
	var next_e: Vector2i = _nc_e_pos + _nc_e_dir

	var p_hit: bool = _is_blocked(next_p)
	var e_hit: bool = _is_blocked(next_e)
	if next_p == next_e:
		p_hit = true
		e_hit = true

	if p_hit and e_hit:
		_nc_state = "DRAW"
		return
	elif p_hit:
		_nc_state = "LOSE"
		return
	elif e_hit:
		_nc_score += 100 * _nc_round
		_nc_best = maxi(_nc_best, _nc_score)
		_nc_state = "WIN"
		return

	_nc_p_pos = next_p
	_nc_e_pos = next_e
	_nc_p_trail.append(_nc_p_pos)
	_nc_e_trail.append(_nc_e_pos)
	_nc_score += 2
	_nc_best = maxi(_nc_best, _nc_score)


func _is_blocked(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= GRID_W or pos.y < 0 or pos.y >= GRID_H:
		return true
	return _nc_p_trail.has(pos) or _nc_e_trail.has(pos)


func _choose_ai_direction() -> Vector2i:
	var candidates: Array[Vector2i] = [
		_nc_e_dir,
		Vector2i(-_nc_e_dir.y, _nc_e_dir.x),
		Vector2i(_nc_e_dir.y, -_nc_e_dir.x),
	]
	var best_dir: Vector2i = _nc_e_dir
	var best_score: int = -1
	for d: Vector2i in candidates:
		if d + _nc_e_dir == Vector2i.ZERO:
			continue
		var probe: Vector2i = _nc_e_pos + d
		if _is_blocked(probe):
			continue
		var free_ahead: int = 0
		var cur: Vector2i = probe
		for _step: int in range(6):
			if _is_blocked(cur):
				break
			free_ahead += 1
			cur += d
		var bonus: int = 1 if d == _nc_e_dir else 0
		var sc: int = free_ahead * 2 + bonus
		if sc > best_score:
			best_score = sc
			best_dir = d
	return best_dir


func start_icebreaker(fixed_secret: Array = []) -> void:
	_mode = Mode.ICEBREAKER
	_ib_secret.clear()
	if fixed_secret.size() == 4:
		for s: Variant in fixed_secret:
			_ib_secret.append(str(s))
	else:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for _i: int in range(4):
			_ib_secret.append(HEX_SYMBOLS[rng.randi_range(0, HEX_SYMBOLS.size() - 1)])
	_ib_input.clear()
	_ib_history.clear()
	_ib_status = "PLAYING"
	if _canvas != null:
		_canvas.grab_focus()
		_canvas.queue_redraw()


func icebreaker_push_symbol(sym: String) -> void:
	if _ib_status != "PLAYING":
		return
	var upper: String = sym.strip_edges().to_upper()
	if HEX_SYMBOLS.has(upper) and _ib_input.size() < 4:
		_ib_input.append(upper)
		if _canvas != null:
			_canvas.queue_redraw()


func icebreaker_pop_symbol() -> void:
	if _ib_status != "PLAYING" or _ib_input.is_empty():
		return
	_ib_input.pop_back()
	if _canvas != null:
		_canvas.queue_redraw()


func icebreaker_submit() -> Dictionary:
	if _ib_status != "PLAYING" or _ib_input.size() < 4:
		return {}
	var exact: int = 0
	var used_secret: Array[bool] = [false, false, false, false]
	var used_guess: Array[bool] = [false, false, false, false]
	for i: int in range(4):
		if _ib_input[i] == _ib_secret[i]:
			exact += 1
			used_secret[i] = true
			used_guess[i] = true
	var misplaced: int = 0
	for i: int in range(4):
		if used_guess[i]:
			continue
		for j: int in range(4):
			if not used_secret[j] and _ib_input[i] == _ib_secret[j]:
				misplaced += 1
				used_secret[j] = true
				break

	var entry: Dictionary = {
		"guess": _ib_input.duplicate(),
		"exact": exact,
		"misplaced": misplaced,
		"won": exact == 4,
	}
	_ib_history.append(entry)
	_ib_input.clear()
	if exact == 4:
		_ib_status = "WON"
		_ib_wins += 1
	elif _ib_history.size() >= 8:
		_ib_status = "LOST"
	if _canvas != null:
		_canvas.queue_redraw()
	return entry


func _launch_terminal_cartridge(cmd: String) -> void:
	if p == null:
		return
	p._set_active_tab(2)
	p._execute_cli_command(cmd)
	if p._academia_canvas != null and is_instance_valid(p._academia_canvas):
		p._academia_canvas.queue_redraw()


func _on_gui_input(event: InputEvent) -> void:
	if _canvas == null or not _canvas.visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_canvas.grab_focus()
			for i: int in range(_hitboxes.size() - 1, -1, -1):
				var hb: Dictionary = _hitboxes[i]
				var r: Rect2 = hb.get("rect", Rect2())
				if r.has_point(mb.position):
					_handle_hitbox(hb)
					_canvas.accept_event()
					return
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		match _mode:
			Mode.SHELF:
				if ke.keycode == KEY_1:
					p._play_click_sfx()
					start_netcycle(true)
					_canvas.accept_event()
				elif ke.keycode == KEY_2:
					p._play_click_sfx()
					start_icebreaker()
					_canvas.accept_event()
			Mode.NETCYCLE:
				_handle_netcycle_key(ke)
			Mode.ICEBREAKER:
				_handle_icebreaker_key(ke)


func _handle_hitbox(hb: Dictionary) -> void:
	var action: String = str(hb.get("action", ""))
	p._play_click_sfx()
	match action:
		"launch_netcycle":
			start_netcycle(true)
		"launch_icebreaker":
			start_icebreaker()
		"launch_breach3d":
			_launch_terminal_cartridge("/usr/games/breach3d")
		"launch_rogue":
			_launch_terminal_cartridge("/usr/games/rogue")
		"back_shelf":
			exit_game()
		"nc_action":
			if _nc_state == "WIN":
				_nc_round += 1
				start_netcycle(false)
			else:
				start_netcycle(true)
		"ib_sym":
			icebreaker_push_symbol(str(hb.get("val", "")))
		"ib_back":
			icebreaker_pop_symbol()
		"ib_submit":
			icebreaker_submit()
		"ib_new":
			start_icebreaker()


func _handle_netcycle_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ESCAPE:
		p._play_click_sfx()
		exit_game()
	elif ke.keycode == KEY_UP or ke.keycode == KEY_W:
		set_netcycle_direction(Vector2i(0, -1))
	elif ke.keycode == KEY_DOWN or ke.keycode == KEY_S:
		set_netcycle_direction(Vector2i(0, 1))
	elif ke.keycode == KEY_LEFT or ke.keycode == KEY_A:
		set_netcycle_direction(Vector2i(-1, 0))
	elif ke.keycode == KEY_RIGHT or ke.keycode == KEY_D:
		set_netcycle_direction(Vector2i(1, 0))
	elif ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		if _nc_state == "READY":
			_nc_state = "PLAYING"
		elif _nc_state == "WIN":
			_nc_round += 1
			start_netcycle(false)
		elif _nc_state == "LOSE" or _nc_state == "DRAW":
			start_netcycle(true)
	_canvas.queue_redraw()
	_canvas.accept_event()


func _handle_icebreaker_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ESCAPE:
		p._play_click_sfx()
		exit_game()
	elif ke.keycode == KEY_BACKSPACE:
		icebreaker_pop_symbol()
	elif ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		icebreaker_submit()
	elif ke.keycode == KEY_R:
		start_icebreaker()
	elif ke.unicode >= 65 and ke.unicode <= 70:
		icebreaker_push_symbol(char(ke.unicode))
	elif ke.unicode >= 97 and ke.unicode <= 102:
		icebreaker_push_symbol(char(ke.unicode).to_upper())
	_canvas.queue_redraw()
	_canvas.accept_event()


func _on_draw() -> void:
	if _canvas == null or not _canvas.visible:
		return
	var sz: Vector2 = _canvas.size
	if sz.x <= 40.0 or sz.y <= 40.0:
		return
	var font: Font = p.font
	if font == null:
		return

	_hitboxes.clear()
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), COL_BG)

	match _mode:
		Mode.SHELF:
			_draw_shelf(sz, font)
		Mode.NETCYCLE:
			_draw_netcycle(sz, font)
		Mode.ICEBREAKER:
			_draw_icebreaker(sz, font)


func _draw_shelf(sz: Vector2, font: Font) -> void:
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), COL_PANEL)
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), COL_BORDER, false, 1.0)

	var x: float = 22.0
	var y: float = 30.0
	var w: float = sz.x - 44.0

	_canvas.draw_string(font, Vector2(x, y), "ARCADE // /usr/games/ — CARTUCHOS TÁCTICOS", HORIZONTAL_ALIGNMENT_LEFT, int(w * 0.65), 15, COL_PURPLE)
	_canvas.draw_string(font, Vector2(x, y), "NETCYCLE RÉCORD: %d  ·  ICEBREAKER VICTORIAS: %d" % [_nc_best, _ib_wins], HORIZONTAL_ALIGNMENT_RIGHT, int(w), 12, COL_CYAN)
	_canvas.draw_string(font, Vector2(x, y + 22.0), "Selecciona un cartucho interactivo en pantalla o abre los juegos ASCII clásicos en Terminal Lab.", HORIZONTAL_ALIGNMENT_LEFT, int(w), 12, COL_MUTED)

	var cards: Array[Dictionary] = [
		{"title": "01 // NETCYCLE", "tag": "▶ JUGABLE · 60 FPS", "col": COL_CYAN, "desc": "Duelo vectorial de estelas de luz contra el interceptor CORDON. Evita muros y encierra al rival.", "action": "launch_netcycle", "hint": "Clic o [1] para jugar"},
		{"title": "02 // ICEBREAKER", "tag": "▶ JUGABLE · LÓGICA", "col": COL_GREEN, "desc": "Descifrador hexadecimal de 4 símbolos (A-F) en 8 intentos. Deduce código exacto y posición.", "action": "launch_icebreaker", "hint": "Clic o [2] para jugar"},
		{"title": "03 // BREACH-3D", "tag": "CLI · TERMINAL LAB", "col": COL_AMBER, "desc": "Raycaster ASCII en primera persona por los corredores del Kernel en Tab 03.", "action": "launch_breach3d", "hint": "Clic para abrir en Terminal"},
		{"title": "04 // ROGUE-S0", "tag": "CLI · TERMINAL LAB", "col": COL_PURPLE, "desc": "Explorador ASCII por páginas de memoria del Sector 0 en Tab 03.", "action": "launch_rogue", "hint": "Clic para abrir en Terminal"},
	]

	var grid_top: float = y + 48.0
	var gap: float = 16.0
	var cw: float = (w - gap) * 0.5
	var ch: float = minf(185.0, (sz.y - grid_top - 42.0 - gap) * 0.5)

	for i: int in range(cards.size()):
		var c: Dictionary = cards[i]
		var col_i: int = i % 2
		var row_i: int = i / 2
		var cr := Rect2(x + float(col_i) * (cw + gap), grid_top + float(row_i) * (ch + gap), cw, ch)
		var accent: Color = c.get("col", COL_CYAN)

		_canvas.draw_rect(cr, COL_CARD)
		_canvas.draw_rect(cr, accent, false, 1.0)
		_canvas.draw_rect(Rect2(cr.position.x, cr.position.y, 4.0, cr.size.y), accent)

		_canvas.draw_string(font, Vector2(cr.position.x + 16.0, cr.position.y + 28.0), str(c["title"]), HORIZONTAL_ALIGNMENT_LEFT, int(cw - 32.0), 15, accent)
		_canvas.draw_string(font, Vector2(cr.position.x + 16.0, cr.position.y + 48.0), str(c["tag"]), HORIZONTAL_ALIGNMENT_LEFT, int(cw - 32.0), 11, COL_TEXT)
		_canvas.draw_multiline_string(font, Vector2(cr.position.x + 16.0, cr.position.y + 76.0), str(c["desc"]), HORIZONTAL_ALIGNMENT_LEFT, cw - 32.0, 12, 3, COL_MUTED)
		_canvas.draw_string(font, Vector2(cr.position.x + 16.0, cr.end.y - 16.0), "▸ " + str(c["hint"]), HORIZONTAL_ALIGNMENT_LEFT, int(cw - 32.0), 11, accent)
		_hitboxes.append({"action": str(c["action"]), "rect": cr})


func _draw_netcycle(sz: Vector2, font: Font) -> void:
	var pad: float = 16.0
	var hdr_y: float = 28.0
	_canvas.draw_string(font, Vector2(pad, hdr_y), "NETCYCLE // RONDA %d   |   PUNTOS: %d   |   RÉCORD: %d" % [_nc_round, _nc_score, _nc_best], HORIZONTAL_ALIGNMENT_LEFT, int(sz.x - 160.0), 14, COL_CYAN)

	var back_rect := Rect2(sz.x - 126.0, 10.0, 110.0, 26.0)
	_canvas.draw_rect(back_rect, COL_CARD)
	_canvas.draw_rect(back_rect, COL_BORDER, false, 1.0)
	_canvas.draw_string(font, Vector2(back_rect.position.x, back_rect.position.y + 17.0), "← VOLVER [Esc]", HORIZONTAL_ALIGNMENT_CENTER, int(back_rect.size.x), 11, COL_TEXT)
	_hitboxes.append({"action": "back_shelf", "rect": back_rect})

	var avail_w: float = sz.x - pad * 2.0
	var avail_h: float = sz.y - 88.0
	var cell: float = floor(minf(avail_w / float(GRID_W), avail_h / float(GRID_H)))
	var arena_w: float = cell * float(GRID_W)
	var arena_h: float = cell * float(GRID_H)
	var ax: float = floor((sz.x - arena_w) * 0.5)
	var ay: float = 48.0
	var arena := Rect2(ax, ay, arena_w, arena_h)

	_canvas.draw_rect(arena, Color("#05080E"))
	for gx: int in range(1, GRID_W):
		var lx: float = ax + float(gx) * cell
		_canvas.draw_line(Vector2(lx, ay), Vector2(lx, arena.end.y), Color("#0E1624"), 1.0)
	for gy: int in range(1, GRID_H):
		var ly: float = ay + float(gy) * cell
		_canvas.draw_line(Vector2(ax, ly), Vector2(arena.end.x, ly), Color("#0E1624"), 1.0)
	_canvas.draw_rect(arena, COL_CYAN, false, 1.5)

	for cell_p: Vector2i in _nc_p_trail:
		_canvas.draw_rect(Rect2(ax + float(cell_p.x) * cell + 2.0, ay + float(cell_p.y) * cell + 2.0, cell - 4.0, cell - 4.0), COL_CYAN)
	for cell_e: Vector2i in _nc_e_trail:
		_canvas.draw_rect(Rect2(ax + float(cell_e.x) * cell + 2.0, ay + float(cell_e.y) * cell + 2.0, cell - 4.0, cell - 4.0), COL_PINK)

	_canvas.draw_rect(Rect2(ax + float(_nc_p_pos.x) * cell + 1.0, ay + float(_nc_p_pos.y) * cell + 1.0, cell - 2.0, cell - 2.0), Color("#EAECF5"))
	_canvas.draw_rect(Rect2(ax + float(_nc_e_pos.x) * cell + 1.0, ay + float(_nc_e_pos.y) * cell + 1.0, cell - 2.0, cell - 2.0), COL_AMBER)

	if _nc_state != "PLAYING":
		var banner := Rect2(ax + arena_w * 0.18, ay + arena_h * 0.38, arena_w * 0.64, 72.0)
		_canvas.draw_rect(banner, Color(0.04, 0.06, 0.1, 0.92))
		var bcol: Color = COL_GREEN if _nc_state == "WIN" else (COL_PINK if _nc_state == "LOSE" else COL_CYAN)
		_canvas.draw_rect(banner, bcol, false, 1.5)
		var msg: String = "Presiona [Espacio] o una dirección (WASD / Flechas) para iniciar"
		if _nc_state == "WIN":
			msg = "✓ INTERCEPTOR NEUTRALIZADO — [Espacio] Siguiente ronda"
		elif _nc_state == "LOSE":
			msg = "✕ COLISIÓN DETECTADA — [Espacio] Reintentar"
		elif _nc_state == "DRAW":
			msg = "= IMPACTO SIMULTÁNEO — [Espacio] Reintentar"
		_canvas.draw_string(font, Vector2(banner.position.x + 12.0, banner.position.y + 42.0), msg, HORIZONTAL_ALIGNMENT_CENTER, int(banner.size.x - 24.0), 13, bcol)
		_hitboxes.append({"action": "nc_action", "rect": banner})

	_canvas.draw_string(font, Vector2(pad, sz.y - 12.0), "Controles: WASD / Flechas girar  •  [Espacio] iniciar/continuar  •  [Esc] salir", HORIZONTAL_ALIGNMENT_CENTER, int(sz.x - pad * 2.0), 11, COL_MUTED)


func _draw_icebreaker(sz: Vector2, font: Font) -> void:
	var pad: float = 20.0
	_canvas.draw_string(font, Vector2(pad, 28.0), "ICEBREAKER // DESCIFRADOR HEXADECIMAL (8 INTENTOS)", HORIZONTAL_ALIGNMENT_LEFT, int(sz.x - 240.0), 15, COL_GREEN)

	var new_rect := Rect2(sz.x - 236.0, 10.0, 100.0, 26.0)
	_canvas.draw_rect(new_rect, COL_CARD)
	_canvas.draw_rect(new_rect, COL_CYAN, false, 1.0)
	_canvas.draw_string(font, Vector2(new_rect.position.x, new_rect.position.y + 17.0), "NUEVO [R]", HORIZONTAL_ALIGNMENT_CENTER, int(new_rect.size.x), 11, COL_CYAN)
	_hitboxes.append({"action": "ib_new", "rect": new_rect})

	var back_rect := Rect2(sz.x - 126.0, 10.0, 106.0, 26.0)
	_canvas.draw_rect(back_rect, COL_CARD)
	_canvas.draw_rect(back_rect, COL_BORDER, false, 1.0)
	_canvas.draw_string(font, Vector2(back_rect.position.x, back_rect.position.y + 17.0), "← VOLVER [Esc]", HORIZONTAL_ALIGNMENT_CENTER, int(back_rect.size.x), 11, COL_TEXT)
	_hitboxes.append({"action": "back_shelf", "rect": back_rect})

	var left_w: float = sz.x * 0.54
	var board := Rect2(pad, 52.0, left_w - pad, sz.y - 76.0)
	_canvas.draw_rect(board, COL_PANEL)
	_canvas.draw_rect(board, COL_BORDER, false, 1.0)

	_canvas.draw_string(font, Vector2(board.position.x + 14.0, board.position.y + 24.0), "HISTORIAL DE INYECCIONES   (■ Exacto  ·  □ Posición distinta)", HORIZONTAL_ALIGNMENT_LEFT, int(board.size.x - 28.0), 11, COL_MUTED)
	var ry: float = board.position.y + 42.0
	for row_i: int in range(8):
		var rr := Rect2(board.position.x + 14.0, ry, board.size.x - 28.0, 34.0)
		_canvas.draw_rect(rr, COL_CARD)
		_canvas.draw_rect(rr, COL_BORDER, false, 1.0)
		_canvas.draw_string(font, Vector2(rr.position.x + 10.0, rr.position.y + 21.0), "#%d" % (row_i + 1), HORIZONTAL_ALIGNMENT_LEFT, 30, 11, COL_MUTED)
		if row_i < _ib_history.size():
			var h: Dictionary = _ib_history[row_i]
			var g: Array = h.get("guess", [])
			for c: int in range(4):
				var sym: String = str(g[c])
				_canvas.draw_string(font, Vector2(rr.position.x + 48.0 + float(c) * 34.0, rr.position.y + 22.0), sym, HORIZONTAL_ALIGNMENT_LEFT, 24, 15, HEX_COLORS.get(sym, COL_TEXT))
			var ex_c: int = int(h.get("exact", 0))
			var mp_c: int = int(h.get("misplaced", 0))
			var marks: String = "■ ".repeat(ex_c) + "□ ".repeat(mp_c)
			_canvas.draw_string(font, Vector2(rr.position.x + 200.0, rr.position.y + 21.0), "%s (%d/%d)" % [marks, ex_c, mp_c], HORIZONTAL_ALIGNMENT_LEFT, int(rr.size.x - 210.0), 12, COL_GREEN if ex_c == 4 else COL_AMBER)
		ry += 40.0

	# Right Side: Current Guess + Hex Keypad
	var rx: float = left_w + 16.0
	var rw: float = sz.x - rx - pad
	var panel := Rect2(rx, 52.0, rw, sz.y - 76.0)
	_canvas.draw_rect(panel, COL_PANEL)
	_canvas.draw_rect(panel, COL_BORDER, false, 1.0)

	_canvas.draw_string(font, Vector2(rx + 16.0, 78.0), "SECUENCIA ACTIVA:", HORIZONTAL_ALIGNMENT_LEFT, int(rw - 32.0), 12, COL_CYAN)
	var slot_w: float = (rw - 32.0 - 24.0) * 0.25
	for s_i: int in range(4):
		var sr := Rect2(rx + 16.0 + float(s_i) * (slot_w + 8.0), 92.0, slot_w, 48.0)
		var has_s: bool = s_i < _ib_input.size()
		var sym_s: String = _ib_input[s_i] if has_s else "_"
		var scol: Color = HEX_COLORS.get(sym_s, COL_MUTED) if has_s else COL_BORDER
		_canvas.draw_rect(sr, COL_CARD)
		_canvas.draw_rect(sr, scol, false, 1.5)
		_canvas.draw_string(font, Vector2(sr.position.x, sr.position.y + 32.0), sym_s, HORIZONTAL_ALIGNMENT_CENTER, int(slot_w), 20, scol if has_s else COL_MUTED)

	var ky: float = 160.0
	var kw: float = (rw - 32.0 - 16.0) / 3.0
	for i: int in range(HEX_SYMBOLS.size()):
		var sym_k: String = HEX_SYMBOLS[i]
		var kr := Rect2(rx + 16.0 + float(i % 3) * (kw + 8.0), ky + float(i / 3) * 46.0, kw, 38.0)
		var kcol: Color = HEX_COLORS.get(sym_k, COL_TEXT)
		_canvas.draw_rect(kr, COL_CARD)
		_canvas.draw_rect(kr, kcol, false, 1.0)
		_canvas.draw_string(font, Vector2(kr.position.x, kr.position.y + 24.0), sym_k, HORIZONTAL_ALIGNMENT_CENTER, int(kw), 16, kcol)
		_hitboxes.append({"action": "ib_sym", "val": sym_k, "rect": kr})

	var ay: float = ky + 102.0
	var bw2: float = (rw - 32.0 - 8.0) * 0.5
	var del_rect := Rect2(rx + 16.0, ay, bw2, 36.0)
	_canvas.draw_rect(del_rect, COL_CARD)
	_canvas.draw_rect(del_rect, COL_BORDER, false, 1.0)
	_canvas.draw_string(font, Vector2(del_rect.position.x, del_rect.position.y + 22.0), "⌫ BORRAR", HORIZONTAL_ALIGNMENT_CENTER, int(bw2), 12, COL_TEXT)
	_hitboxes.append({"action": "ib_back", "rect": del_rect})

	var sub_rect := Rect2(rx + 16.0 + bw2 + 8.0, ay, bw2, 36.0)
	var ready_sub: bool = (_ib_input.size() == 4 and _ib_status == "PLAYING")
	_canvas.draw_rect(sub_rect, Color("#152924") if ready_sub else COL_CARD)
	_canvas.draw_rect(sub_rect, COL_GREEN if ready_sub else COL_BORDER, false, 1.0)
	_canvas.draw_string(font, Vector2(sub_rect.position.x, sub_rect.position.y + 22.0), "VERIFICAR [Enter]", HORIZONTAL_ALIGNMENT_CENTER, int(bw2), 12, COL_GREEN if ready_sub else COL_MUTED)
	_hitboxes.append({"action": "ib_submit", "rect": sub_rect})

	if _ib_status == "WON":
		_canvas.draw_string(font, Vector2(rx + 16.0, ay + 68.0), "✓ SISTEMA DESCIFRADO (%s)" % "".join(_ib_secret), HORIZONTAL_ALIGNMENT_CENTER, int(rw - 32.0), 14, COL_GREEN)
	elif _ib_status == "LOST":
		_canvas.draw_string(font, Vector2(rx + 16.0, ay + 68.0), "✕ BLOQUEO ACTIVO — Clave: %s" % "".join(_ib_secret), HORIZONTAL_ALIGNMENT_CENTER, int(rw - 32.0), 14, COL_PINK)
	else:
		_canvas.draw_string(font, Vector2(rx + 16.0, ay + 68.0), "Teclado A-F  •  [Backspace]  •  [Enter]", HORIZONTAL_ALIGNMENT_CENTER, int(rw - 32.0), 11, COL_MUTED)
