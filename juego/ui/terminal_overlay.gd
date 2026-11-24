class_name TerminalOverlay extends Control

## TerminalOverlay
## Consola táctica de ciberseguridad in-game estilo UNIX para VERTEX.
## Delega la ejecución de comandos, autocompletado [TAB], historial y
## telemetría sobre el grafo vivo al núcleo compartido UnixShellEngine + TerminalVFS.

const BrandClass = preload("res://juego/ui/brand.gd")
const TerminalVFSClass = preload("res://juego/ui/terminal_vfs.gd")
const UnixShellEngineClass = preload("res://juego/system/unix_shell_engine.gd")

signal terminal_visibility_changed(is_visible: bool)

enum Mode { NORMAL, SUDO_PROMPT }

var is_terminal_open: bool = false
var _game: Node = null
var _history: Array[String] = []
var _history_idx: int = -1
var _output_lines: Array[String] = []
var _input_text: String = ""
var _cursor_blink: float = 0.0

var _mode: Mode = Mode.NORMAL
var _pending_sudo_cmd: String = ""
var _vfs: TerminalVFS = null
var _shell_engine: UnixShellEngine = null

const MAX_LINES: int = 28
const SUDO_PASSWORD: String = "as65000-root"
const LEGACY_SUDO_PASSWORDS: Array[String] = ["as65000-root", "kain99", "cyber26"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_vfs()


func _init_vfs() -> void:
	if _vfs == null:
		_vfs = TerminalVFSClass.new()
	if _shell_engine == null:
		_shell_engine = UnixShellEngineClass.new(_vfs)
		_shell_engine.context_name = &"overlay"
	if _game != null:
		_shell_engine.set_game_context(_game)


func setup(game_node: Node) -> void:
	_game = game_node
	_init_vfs()
	_shell_engine.set_game_context(_game)
	_output_lines = [
		"%s (TTY1)" % _shell_engine.terminal_title,
		"Operador activo: %s | Kernel de Ciberdefensa y Grafos en línea." % _shell_engine.operator_user,
		"Analiza rutas con 'traceroute', escanea con 'nmap <nodo>' o juega en '/usr/games/'.",
		""
	]


func toggle() -> void:
	if is_terminal_open:
		close()
	else:
		open()


func open() -> void:
	is_terminal_open = true
	_input_text = ""
	_history_idx = -1
	_play_sfx("click")
	terminal_visibility_changed.emit(true)
	if _game != null and _game.has_method("queue_redraw"):
		_game.queue_redraw()


func close() -> void:
	is_terminal_open = false
	terminal_visibility_changed.emit(false)
	if _game != null and _game.has_method("queue_redraw"):
		_game.queue_redraw()


func get_prompt() -> String:
	_init_vfs()
	if _mode == Mode.SUDO_PROMPT:
		return "[sudo] password for %s: " % _shell_engine.operator_user
	return _shell_engine.get_prompt_string()


func get_terminal_rect(vp_size: Vector2 = Vector2.ZERO) -> Rect2:
	var vp: Vector2 = vp_size
	if vp == Vector2.ZERO:
		if is_inside_tree() and get_viewport() != null:
			vp = get_viewport_rect().size
		elif _game != null and _game.is_inside_tree() and _game.get_viewport() != null:
			vp = _game.get_viewport_rect().size
		else:
			vp = Vector2(1280.0, 720.0)
	var term_h: float = clampf(vp.y * 0.46, 260.0, 340.0)
	return Rect2(20.0, 50.0, vp.x - 40.0, term_h)


func get_close_button_rect(vp_size: Vector2 = Vector2.ZERO) -> Rect2:
	var term_rect: Rect2 = get_terminal_rect(vp_size)
	var btn_w: float = 148.0
	var btn_h: float = 20.0
	return Rect2(term_rect.position.x + term_rect.size.x - btn_w - 6.0, term_rect.position.y + 2.0, btn_w, btn_h)


func _play_sfx(sfx_name: String) -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx(sfx_name)


func handle_input(event: InputEvent) -> bool:
	if not is_terminal_open:
		return false

	var vp_size: Vector2 = Vector2.ZERO
	if is_inside_tree() and get_viewport() != null:
		vp_size = get_viewport_rect().size
	elif _game != null and _game.is_inside_tree() and _game.get_viewport() != null:
		vp_size = _game.get_viewport_rect().size
	else:
		vp_size = Vector2(1280.0, 720.0)

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if get_close_button_rect(vp_size).has_point(mb.position) or not get_terminal_rect(vp_size).has_point(mb.position):
				close()
				return true
			if get_terminal_rect(vp_size).has_point(mb.position):
				return true
		return false

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if get_close_button_rect(vp_size).has_point(st.position) or not get_terminal_rect(vp_size).has_point(st.position):
				close()
				return true
			if get_terminal_rect(vp_size).has_point(st.position):
				return true
		return false

	if event is InputEventMouseMotion:
		return false

	if event is InputEventKey:
		var k: InputEventKey = event as InputEventKey
		if k.pressed:
			match k.keycode:
				KEY_QUOTELEFT, KEY_ASCIITILDE:
					close()
					return true
				KEY_ESCAPE:
					if _mode != Mode.NORMAL:
						_mode = Mode.NORMAL
						_output_lines.append("[!] Operación cancelada.")
						_trim_lines()
						queue_redraw()
						return true
					close()
					return true
				KEY_TAB:
					_handle_tab_autocomplete()
					queue_redraw()
					return true
				KEY_UP:
					if _history.size() > 0:
						if _history_idx == -1:
							_history_idx = _history.size() - 1
						elif _history_idx > 0:
							_history_idx -= 1
						_input_text = _history[_history_idx]
					queue_redraw()
					return true
				KEY_DOWN:
					if _history_idx != -1:
						if _history_idx < _history.size() - 1:
							_history_idx += 1
							_input_text = _history[_history_idx]
						else:
							_history_idx = -1
							_input_text = ""
					queue_redraw()
					return true
				KEY_ENTER, KEY_KP_ENTER:
					_play_sfx("click")
					_handle_enter_pressed()
					queue_redraw()
					return true
				KEY_BACKSPACE:
					if _input_text.length() > 0:
						_input_text = _input_text.substr(0, _input_text.length() - 1)
						_play_sfx("click")
						queue_redraw()
					return true
				_:
					if k.unicode > 31 and k.unicode < 127:
						_input_text += char(k.unicode)
						_play_sfx("click")
						queue_redraw()
						return true
		return true

	return false


func _handle_tab_autocomplete() -> void:
	_init_vfs()
	var ac: Dictionary = _shell_engine.autocomplete(_input_text)
	var completed: String = str(ac.get("completed", _input_text))
	var matches: Array = ac.get("matches", [])
	if completed != _input_text:
		_input_text = completed
	elif matches.size() > 1:
		var preview: Array[String] = []
		for m in matches:
			preview.append(str(m))
		_output_lines.append("  ".join(preview))
		_trim_lines()


func _handle_enter_pressed() -> void:
	var cmd: String = _input_text.strip_edges()
	_input_text = ""
	_history_idx = -1

	match _mode:
		Mode.SUDO_PROMPT:
			_output_lines.append("[sudo] password: ********")
			if cmd in LEGACY_SUDO_PASSWORDS:
				_vfs.is_root = true
				_play_sfx("win")
				_output_lines.append("[+] Autenticación exitosa como root.")
				if not _pending_sudo_cmd.is_empty():
					var to_run: String = _pending_sudo_cmd
					_pending_sudo_cmd = ""
					_mode = Mode.NORMAL
					_execute_command(to_run)
					return
			else:
				_play_sfx("error")
				_output_lines.append("[-] Contraseña incorrecta. Intento registrado en /var/log/auth.log")
			_pending_sudo_cmd = ""
			_mode = Mode.NORMAL
			_trim_lines()
		_:
			_execute_command(cmd)


func _execute_command(raw_cmd: String) -> void:
	var trimmed: String = raw_cmd.strip_edges()
	_output_lines.append(get_prompt() + trimmed)
	if trimmed.is_empty():
		return

	_init_vfs()

	if _shell_engine.active_cartridge.is_empty():
		var parts: PackedStringArray = trimmed.split(" ", false)
		var cmd: String = parts[0] if parts.size() > 0 else ""

		if cmd == "exit" or cmd == "quit":
			close()
			return
		if cmd == "matrix":
			_output_lines.append("01010110 01000101 01010010 01010100 01000101 01011000")
			_output_lines.append("INCURSIÓN KERNEL // STREAM FOTÓNICO EN PROCESO")
			_history.append(trimmed)
			_trim_lines()
			queue_redraw()
			return
		if cmd == "sudo" and not _vfs.is_root and parts.size() > 1 and parts[1] != "-k" and parts[1] != "-p":
			var sub_args: PackedStringArray = parts.slice(1)
			_pending_sudo_cmd = " ".join(sub_args)
			_mode = Mode.SUDO_PROMPT
			_output_lines.append("[!] Se requieren privilegios de superusuario (root).")
			_history.append(trimmed)
			_trim_lines()
			queue_redraw()
			return
		if cmd == "su" and parts.size() == 1:
			if _vfs.is_root:
				_output_lines.append("Ya eres root.")
			else:
				_pending_sudo_cmd = ""
				_mode = Mode.SUDO_PROMPT
			_history.append(trimmed)
			_trim_lines()
			queue_redraw()
			return

	var res: UnixShellEngineClass.ShellResult = _shell_engine.execute(trimmed)
	var out_str: String = res.combined_output()
	if out_str == "__CLEAR__":
		_output_lines.clear()
	elif not out_str.is_empty():
		for line in out_str.split("\n"):
			_output_lines.append(line)

	_history.append(trimmed)
	_trim_lines()
	queue_redraw()


func _trim_lines() -> void:
	while _output_lines.size() > MAX_LINES:
		_output_lines.remove_at(0)


func draw_terminal(canvas: CanvasItem, vp: Vector2, font: Font, font_size: int) -> void:
	if not is_terminal_open:
		return

	var f: Font = font if font != null else BrandClass.font_regular()
	var f_sz: int = font_size if font_size > 0 else 14

	_cursor_blink += 0.016
	var term_rect: Rect2 = get_terminal_rect(vp)

	canvas.draw_rect(term_rect, Color(0.04, 0.05, 0.09, 1.0))
	canvas.draw_rect(term_rect, Color(0.0, 0.85, 0.7, 0.85), false, 1.5)

	var header_rect: Rect2 = Rect2(term_rect.position.x, term_rect.position.y, term_rect.size.x, 24.0)
	canvas.draw_rect(header_rect, Color(0.06, 0.12, 0.18, 1.0))
	var title_text: String = "%s // %s@%s:%s // [~] o [ESC] cerrar" % [_shell_engine.terminal_title, _shell_engine.get_active_user(), _shell_engine.host_name, _vfs.current_path]
	canvas.draw_string(f, Vector2(header_rect.position.x + 12.0, header_rect.position.y + 16.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 3, Color(0.0, 1.0, 0.83))

	var close_rect: Rect2 = get_close_button_rect(vp)
	canvas.draw_rect(close_rect, Color(0.8, 0.15, 0.2, 0.35))
	canvas.draw_rect(close_rect, Color(1.0, 0.35, 0.45, 0.85), false, 1.0)
	canvas.draw_string(f, Vector2(close_rect.position.x + 8.0, close_rect.position.y + 14.0), "[ ✕ CERRAR (ESC) ]", HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 4, Color(1.0, 0.8, 0.8))

	var dock_h: float = 28.0
	var dock_y: float = term_rect.position.y + term_rect.size.y - dock_h
	var dock_rect: Rect2 = Rect2(term_rect.position.x, dock_y, term_rect.size.x, dock_h)
	canvas.draw_rect(dock_rect, Color(0.02, 0.03, 0.06, 1.0))
	canvas.draw_line(Vector2(dock_rect.position.x, dock_y), Vector2(dock_rect.position.x + dock_rect.size.x, dock_y), Color(0.16, 0.22, 0.35, 0.9), 1.0)

	var content_top: float = header_rect.position.y + 36.0
	var available_h: float = dock_y - content_top - 6.0
	var line_spacing: float = 17.5
	var max_visible_lines: int = maxi(3, int(available_h / line_spacing))

	var start_idx: int = maxi(0, _output_lines.size() - max_visible_lines)
	var visible_lines: Array[String] = _output_lines.slice(start_idx)

	var offset_x: float = term_rect.position.x + 14.0
	var cur_y: float = content_top
	for line in visible_lines:
		var line_col: Color = Color(0.75, 0.85, 0.95)
		if line.find("@" + _shell_engine.host_name + ":") != -1 or line.find("@vertex") != -1:
			line_col = Color(0.0, 1.0, 0.6)
		elif line.begins_with("ERR:") or line.find("Permiso denegado") != -1 or line.find("incorrecta") != -1 or line.find("KERNEL PANIC") != -1:
			line_col = Color(1.0, 0.35, 0.25)
		elif line.find("exitos") != -1 or line.find("nominal") != -1 or line.find("Kernel") != -1 or line.find("VIABLE") != -1:
			line_col = Color(0.3, 1.0, 0.6)
		canvas.draw_string(f, Vector2(offset_x, cur_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 2, line_col)
		cur_y += line_spacing

	var prompt_str: String = get_prompt() + _input_text
	canvas.draw_string(f, Vector2(dock_rect.position.x + 14.0, dock_y + 19.0), prompt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 2, Color("39ff88"))

	if fmod(_cursor_blink, 0.8) < 0.4:
		var pw: float = f.get_string_size(prompt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 2).x
		var cursor_x: float = dock_rect.position.x + 14.0 + pw + 2.0
		var cursor_y: float = dock_y + 6.0
		canvas.draw_rect(Rect2(cursor_x, cursor_y, 7.0, 15.0), Color("39ff88"))
