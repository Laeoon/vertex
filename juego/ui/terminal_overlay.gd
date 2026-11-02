class_name TerminalOverlay extends Control

## TerminalOverlay
## Consola de comandos táctica in-game estilo UNIX/Cyberpunk para VERTEX.
## Se abre con [~], [T] o [F1] y permite ejecutar diagnósticos y telemetría de red.

signal terminal_visibility_changed(is_visible: bool)

var is_terminal_open: bool = false
var _game: Node = null
var _history: Array[String] = []
var _output_lines: Array[String] = []
var _input_text: String = ""
var _cursor_blink: float = 0.0

const MAX_LINES: int = 14
const PROMPT: String = "operator@vertex:~$ "


func _ready() -> void:
	# Permitir procesar cuando el juego esté pausado o en foco
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(game_node: Node) -> void:
	_game = game_node
	_output_lines = [
		"VERTEX TACTICAL TERMINAL v0.6.0 (TTY1)",
		"Escribe 'help' para ver la lista de comandos disponibles.",
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
	terminal_visibility_changed.emit(true)
	if _game != null:
		_game.queue_redraw()


func close() -> void:
	is_terminal_open = false
	terminal_visibility_changed.emit(false)
	if _game != null:
		_game.queue_redraw()


func handle_input(event: InputEvent) -> bool:
	if not is_terminal_open:
		return false

	if event is InputEventKey and event.pressed:
		var k: InputEventKey = event as InputEventKey
		match k.keycode:
			KEY_QUOTELEFT, KEY_ASCIITILDE:
				close()
				return true
			KEY_ESCAPE:
				close()
				return true
			KEY_ENTER, KEY_KP_ENTER:
				_execute_command(_input_text)
				_input_text = ""
				queue_redraw()
				return true
			KEY_BACKSPACE:
				if _input_text.length() > 0:
					_input_text = _input_text.substr(0, _input_text.length() - 1)
					queue_redraw()
				return true
			_:
				if k.unicode > 31 and k.unicode < 127:
					_input_text += char(k.unicode)
					queue_redraw()
					return true
	return true


func _execute_command(raw_cmd: String) -> void:
	var trimmed := raw_cmd.strip_edges()
	_output_lines.append(PROMPT + trimmed)
	if trimmed.is_empty():
		return

	var parts := trimmed.split(" ", false)
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)

	match cmd:
		"help":
			_output_lines.append("Comandos disponibles:")
			_output_lines.append("  help         - Muestra esta lista de comandos")
			_output_lines.append("  status       - Muestra el estado del nodo y turno")
			_output_lines.append("  netstat      - Muestra conexiones activas y bloqueos")
			_output_lines.append("  traceroute   - Imprime la ruta mínima hacia el objetivo")
			_output_lines.append("  matrix       - Activa secuencia visual de código")
			_output_lines.append("  whoami       - Información de identidad de sesión")
			_output_lines.append("  clear        - Limpia la pantalla de la terminal")
			_output_lines.append("  exit         - Cierra la terminal")

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
				_output_lines.append("ERR: Topología no cargada.")

		"traceroute":
			if _game != null:
				var path = _game.get("enemy_path") if _game.get("defender_mode") else _game.get("current_path")
				if path != null and path.size() > 0:
					_output_lines.append("TRACEROUTE: " + " -> ".join(path))
				else:
					_output_lines.append("TRACEROUTE: Sin ruta continua disponible (enlaces saturados).")
			else:
				_output_lines.append("ERR: No hay objetivo asignado.")

		"whoami":
			_output_lines.append("UID: 0 (root) | ROLE: Tactical Network Operator | TERMINAL: /dev/ttyS0")

		"matrix":
			_output_lines.append("01010110 01000101 01010010 01010100 01000101 01011000")
			_output_lines.append("INCURSIÓN EN PROCESO // KERNEL ACCESS GRANTED")

		"clear":
			_output_lines.clear()

		"exit", "quit":
			close()
			return

		_:
			_output_lines.append("Comando desconocido: '%s'. Escribe 'help'." % cmd)

	while _output_lines.size() > MAX_LINES:
		_output_lines.remove_at(0)


func draw_terminal(canvas: CanvasItem, vp: Vector2, font: Font, font_size: int) -> void:
	if not is_terminal_open:
		return

	_cursor_blink += 0.016
	var term_h := clampf(vp.y * 0.42, 220.0, 320.0)
	var term_rect := Rect2(20.0, 50.0, vp.x - 40.0, term_h)

	# Fondo translúcido profundo con borde cian táctico
	canvas.draw_rect(term_rect, Color(0.02, 0.04, 0.07, 0.94))
	canvas.draw_rect(term_rect, Color(0.0, 0.85, 0.7, 0.75), false, 1.5)

	# Barra de título superior
	var header_rect := Rect2(term_rect.position.x, term_rect.position.y, term_rect.size.x, 24.0)
	canvas.draw_rect(header_rect, Color(0.05, 0.12, 0.18, 0.95))
	canvas.draw_string(font, Vector2(header_rect.position.x + 12.0, header_rect.position.y + 16.0), "TERMINAL TÁCTICA // [~] o [ESC] para cerrar", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.0, 1.0, 0.83))

	# Contenido de líneas de salida
	var start_y := header_rect.position.y + 44.0
	var line_spacing := 18.0
	for line in _output_lines:
		var line_col := Color(0.75, 0.85, 0.95)
		if line.begins_with(PROMPT):
			line_col = Color(0.0, 1.0, 0.6)
		elif line.begins_with("ERR:"):
			line_col = Color(1.0, 0.35, 0.25)
		canvas.draw_string(font, Vector2(term_rect.position.x + 14.0, start_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, line_col)
		start_y += line_spacing

	# Prompt y cursor
	var prompt_str := PROMPT + _input_text
	canvas.draw_string(font, Vector2(term_rect.position.x + 14.0, term_rect.position.y + term_rect.size.y - 12.0), prompt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color("39ff88"))

	if fmod(_cursor_blink, 0.8) < 0.4:
		var pw := font.get_string_size(prompt_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2).x
		var cursor_x := term_rect.position.x + 14.0 + pw + 2.0
		var cursor_y := term_rect.position.y + term_rect.size.y - 22.0
		canvas.draw_rect(Rect2(cursor_x, cursor_y, 7.0, 14.0), Color("39ff88"))
