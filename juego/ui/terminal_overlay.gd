class_name TerminalOverlay extends Control

## TerminalOverlay
## Consola táctica de ciberseguridad in-game estilo UNIX para VERTEX.
## Soporta VFS interactivo (ls, cd, cat, echo, pwd, sudo), diagnóstico de red
## (ping, nmap, netstat, traceroute, status) y sonido de teclado táctico.

const BrandClass = preload("res://juego/ui/brand.gd")
const TerminalVFSClass = preload("res://juego/ui/terminal_vfs.gd")
const UnixShellEngineClass = preload("res://juego/system/unix_shell_engine.gd")
var _shell_engine = null

signal terminal_visibility_changed(is_visible: bool)

enum Mode { NORMAL, SUDO_PROMPT }

var is_terminal_open: bool = false
var _game: Node = null
var _history: Array[String] = []
var _output_lines: Array[String] = []
var _input_text: String = ""
var _cursor_blink: float = 0.0

var _mode: Mode = Mode.NORMAL
var _pending_sudo_cmd: String = ""
var _vfs = null

const MAX_LINES: int = 14
const SUDO_PASSWORD: String = "kain99"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_vfs()


func _init_vfs() -> void:
	if _vfs == null:
		_vfs = TerminalVFSClass.new()
	if _shell_engine == null:
		_shell_engine = UnixShellEngineClass.new(_vfs)


func setup(game_node: Node) -> void:
	_game = game_node
	_init_vfs()
	_output_lines = [
		"VERTEX TACTICAL TERMINAL v1.0.0 (TTY1)",
		"Kernel de Ciberdefensa y Grafos activo. Escribe 'help' para comandos.",
		"Explora el sistema con 'ls', 'cd', 'cat' o diagnostica la red con 'ping', 'nmap', 'status'.",
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
	if _mode == Mode.SUDO_PROMPT:
		return "[sudo] password for operator: "
	var usr := "root@vertex:" if _vfs.is_root else "operator@vertex:"
	var symbol := "# " if _vfs.is_root else "$ "
	return usr + _vfs.current_path + symbol


func get_terminal_rect(vp_size: Vector2 = Vector2.ZERO) -> Rect2:
	var vp := vp_size
	if vp == Vector2.ZERO:
		if is_inside_tree() and get_viewport() != null:
			vp = get_viewport_rect().size
		elif _game != null and _game.is_inside_tree() and _game.get_viewport() != null:
			vp = _game.get_viewport_rect().size
		else:
			vp = Vector2(1280.0, 720.0)
	var term_h := clampf(vp.y * 0.46, 260.0, 340.0)
	return Rect2(20.0, 50.0, vp.x - 40.0, term_h)


func get_close_button_rect(vp_size: Vector2 = Vector2.ZERO) -> Rect2:
	var term_rect := get_terminal_rect(vp_size)
	var btn_w := 148.0
	var btn_h := 20.0
	return Rect2(term_rect.position.x + term_rect.size.x - btn_w - 6.0, term_rect.position.y + 2.0, btn_w, btn_h)


func _play_sfx(sfx_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx(sfx_name)


func handle_input(event: InputEvent) -> bool:
	if not is_terminal_open:
		return false

	var vp_size := Vector2.ZERO
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


func _handle_enter_pressed() -> void:
	var cmd := _input_text.strip_edges()
	_input_text = ""

	match _mode:
		Mode.SUDO_PROMPT:
			_output_lines.append("[sudo] password: ********")
			if cmd == SUDO_PASSWORD or cmd == "cyber26":
				_vfs.is_root = true
				_play_sfx("win")
				_output_lines.append("[+] Autenticación exitosa como root.")
				if not _pending_sudo_cmd.is_empty():
					var to_run := _pending_sudo_cmd
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
	var trimmed := raw_cmd.strip_edges()
	_output_lines.append(get_prompt() + trimmed)
	if trimmed.is_empty():
		return

	if _shell_engine == null:
		_shell_engine = UnixShellEngineClass.new(_vfs)

	# Soporte para pipes (|) o comandos extendidos de UnixShellEngine
	if trimmed.find("|") != -1:
		var pipe_out: String = _shell_engine.execute_command_line(trimmed)
		if pipe_out == "__CLEAR__":
			_output_lines.clear()
		elif not pipe_out.is_empty():
			for line in pipe_out.split("\n"):
				_output_lines.append(line)
		_history.append(trimmed)
		_trim_lines()
		queue_redraw()
		return

	var parts := trimmed.split(" ", false)
	var cmd := parts[0]
	var args: Array[String] = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	match cmd:
		"cat":
			if args.is_empty():
				_output_lines.append("Uso: cat <archivo>")
			else:
				var res: Dictionary = _vfs.cat(args[0])
				if res.get("success", false):
					var lines = str(res.get("content", "")).split("\n")
					for l in lines:
						_output_lines.append(l)
				else:
					_output_lines.append("ERR: " + str(res.get("error", "")))

		"echo":
			_output_lines.append(" ".join(args))

		"sudo":
			if args.is_empty():
				_output_lines.append("Uso: sudo <comando>")
				return
			if _vfs.is_root:
				_execute_command(" ".join(args))
			else:
				_pending_sudo_cmd = " ".join(args)
				_mode = Mode.SUDO_PROMPT
				_output_lines.append("[!] Se requieren privilegios de superusuario (root).")

		"su":
			if _vfs.is_root:
				_output_lines.append("Ya eres root.")
			else:
				_pending_sudo_cmd = ""
				_mode = Mode.SUDO_PROMPT

		"status":
			if _game != null:
				var t = _game.get("turn")
				var ppos = _game.get("player_pos")
				var epos = _game.get("enemy_pos")
				var def_mode = _game.get("defender_mode")
				_output_lines.append("STATUS: Turno actual = %s | Modo = %s" % [str(t), "DEFENSA" if def_mode else "INCURSIÓN"])
				_output_lines.append("TELEMETRÍA: Posición local = %s | Intruso = %s" % [str(ppos), str(epos)])
			else:
				_output_lines.append("ERR: No hay sesión activa.")

		"netstat":
			if _game != null and _game.get("graph") != null:
				var g = _game.get("graph")
				var be = _game.get("blocked_edges")
				_output_lines.append("CONEXIONES: %d nodos, %d enlaces totales" % [g.nodes.size(), g.edges.size()])
				_output_lines.append("BLOQUEOS ACTIVOS: %d enlaces cortados" % (be.size() if be != null else 0))
			else:
				var net_out: String = _shell_engine.execute_command_line(trimmed)
				for line in net_out.split("\n"):
					_output_lines.append(line)

		"traceroute":
			if _game != null:
				var path = _game.get("enemy_path") if _game.get("defender_mode") else _game.get("current_path")
				if path != null and path.size() > 0:
					_output_lines.append("TRACEROUTE: " + " -> ".join(path))
				else:
					_output_lines.append("TRACEROUTE: Sin ruta continua disponible (enlaces saturados o bloqueados).")
			else:
				var tr_out: String = _shell_engine.execute_command_line(trimmed)
				for line in tr_out.split("\n"):
					_output_lines.append(line)

		"ping":
			if args.is_empty():
				_output_lines.append("Uso: ping <nodo>")
				return
			var target_node := args[0]
			_output_lines.append("PING %s (ICMP ECHO REQUEST):" % target_node)
			var base_lat := 12 + (hash(target_node) % 18)
			_output_lines.append("64 bytes from %s: icmp_seq=1 ttl=56 time=%d.2 ms" % [target_node, base_lat])
			_output_lines.append("64 bytes from %s: icmp_seq=2 ttl=56 time=%d.8 ms" % [target_node, base_lat + 2])
			_output_lines.append("64 bytes from %s: icmp_seq=3 ttl=56 time=%d.1 ms" % [target_node, base_lat - 1])
			_output_lines.append("--- %s ping statistics --- 3 packets transmitted, 3 received, 0%% packet loss" % target_node)

		"nmap", "scan":
			if args.is_empty():
				_output_lines.append("Uso: nmap <nodo> (o scan <nodo>)")
				return
			var target_node := args[0]
			_output_lines.append("Starting Nmap 7.94 ( https://vertex.net ) at %s" % Time.get_time_string_from_system())
			_output_lines.append("Nmap scan report for %s (10.0.%d.1)" % [target_node, absi(hash(target_node)) % 250 + 1])
			_output_lines.append("PORT     STATE SERVICE       REASON")
			_output_lines.append("22/tcp   open  ssh           syn-ack")
			_output_lines.append("80/tcp   open  http          syn-ack")
			_output_lines.append("443/tcp  open  https         syn-ack")
			_output_lines.append("8443/tcp open  vertex-mesh   syn-ack")
			_output_lines.append("MAC Address: 00:50:56:%02X:%02X:%02X (VMware Virtual)" % [absi(hash(target_node)) % 255, (absi(hash(target_node)) >> 8) % 255, (absi(hash(target_node)) >> 16) % 255])
			_output_lines.append("Device type: general purpose | OS: VERTEX Hardened Kernel 5.15")

		"whoami":
			var role := "root (0)" if _vfs.is_root else "operator (1000)"
			_output_lines.append("UID: %s | HOST: vertex.kernel | TTY: /dev/tty1" % role)

		"matrix":
			_output_lines.append("01010110 01000101 01010010 01010100 01000101 01011000")
			_output_lines.append("INCURSIÓN KERNEL // STREAM FOTÓNICO EN PROCESO")

		"clear":
			_output_lines.clear()

		"exit", "quit":
			close()
			return

		_:
			var output: String = _shell_engine.execute_command_line(trimmed)
			if output == "__CLEAR__":
				_output_lines.clear()
			elif not output.is_empty():
				for line in output.split("\n"):
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
	var term_rect := get_terminal_rect(vp)

	# Fondo sólido 100% opaco para eliminar cualquier sangrado visual de nodos y aristas
	canvas.draw_rect(term_rect, Color(0.04, 0.05, 0.09, 1.0))
	canvas.draw_rect(term_rect, Color(0.0, 0.85, 0.7, 0.85), false, 1.5)

	# Barra de título superior
	var header_rect := Rect2(term_rect.position.x, term_rect.position.y, term_rect.size.x, 24.0)
	canvas.draw_rect(header_rect, Color(0.06, 0.12, 0.18, 1.0))
	var title_text := "TERMINAL TÁCTICA VERTEX // %s // [~] o [ESC] para cerrar" % _vfs.current_path
	canvas.draw_string(f, Vector2(header_rect.position.x + 12.0, header_rect.position.y + 16.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 3, Color(0.0, 1.0, 0.83))

	# Botón visible [ ✕ CERRAR (ESC) ]
	var close_rect := get_close_button_rect(vp)
	canvas.draw_rect(close_rect, Color(0.8, 0.15, 0.2, 0.35))
	canvas.draw_rect(close_rect, Color(1.0, 0.35, 0.45, 0.85), false, 1.0)
	canvas.draw_string(f, Vector2(close_rect.position.x + 8.0, close_rect.position.y + 14.0), "[ ✕ CERRAR (ESC) ]", HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 4, Color(1.0, 0.8, 0.8))

	# Dock inferior dedicado para el Prompt (garantiza cero solapamiento con el historial)
	var dock_h := 28.0
	var dock_y := term_rect.position.y + term_rect.size.y - dock_h
	var dock_rect := Rect2(term_rect.position.x, dock_y, term_rect.size.x, dock_h)
	canvas.draw_rect(dock_rect, Color(0.02, 0.03, 0.06, 1.0))
	canvas.draw_line(Vector2(dock_rect.position.x, dock_y), Vector2(dock_rect.position.x + dock_rect.size.x, dock_y), Color(0.16, 0.22, 0.35, 0.9), 1.0)

	# Calcular área segura de líneas visibles entre header y dock
	var content_top := header_rect.position.y + 36.0
	var available_h := dock_y - content_top - 6.0
	var line_spacing := 17.5
	var max_visible_lines := maxi(3, int(available_h / line_spacing))

	var start_idx := maxi(0, _output_lines.size() - max_visible_lines)
	var visible_lines := _output_lines.slice(start_idx)

	var offset_x := term_rect.position.x + 14.0
	var cur_y := content_top
	for line in visible_lines:
		var line_col := Color(0.75, 0.85, 0.95)
		if line.find("@vertex:") != -1:
			line_col = Color(0.0, 1.0, 0.6)
		elif line.begins_with("ERR:") or line.find("Permiso denegado") != -1 or line.find("incorrecta") != -1:
			line_col = Color(1.0, 0.35, 0.25)
		elif line.find("exitos") != -1 or line.find("nominal") != -1 or line.find("Kernel") != -1:
			line_col = Color(0.3, 1.0, 0.6)
		canvas.draw_string(f, Vector2(offset_x, cur_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 2, line_col)
		cur_y += line_spacing

	# Prompt y cursor en el dock inferior
	var prompt_str := get_prompt() + _input_text
	canvas.draw_string(f, Vector2(dock_rect.position.x + 14.0, dock_y + 19.0), prompt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 2, Color("39ff88"))

	if fmod(_cursor_blink, 0.8) < 0.4:
		var pw := f.get_string_size(prompt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz - 2).x
		var cursor_x := dock_rect.position.x + 14.0 + pw + 2.0
		var cursor_y := dock_y + 6.0
		canvas.draw_rect(Rect2(cursor_x, cursor_y, 7.0, 15.0), Color("39ff88"))
