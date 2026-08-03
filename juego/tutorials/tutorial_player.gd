extends Control

signal step_changed(step_index: int, step_data: Dictionary)
signal tutorial_completed(tutorial_id: String)
signal tutorial_skipped(tutorial_id: String)

var tutorial_data: Dictionary = {}
var steps: Array = []
var current_step_index: int = -1
var is_active: bool = false
var is_paused_by_tutorial: bool = false

var font: Font
var font_size: int = 14
var big_font_size: int = 18
var small_font_size: int = 12

var _auto_advance_timer: float = 0.0
var _auto_advance_target: float = 0.0
var _action_fulfilled: bool = false
var _waiting_for_action: bool = false

var _panel_color: Color = Color(0.05, 0.05, 0.1, 0.92)
var _panel_border: Color = Color(0.0, 1.0, 0.83, 0.8)
var _text_color: Color = Color.WHITE
var _accent_color: Color = Color(0.0, 1.0, 0.83)
var _warning_color: Color = Color(1.0, 0.18, 0.58)
var _btn_color: Color = Color(0.0, 0.8, 0.6)
var _btn_hover_color: Color = Color(0.0, 1.0, 0.83)

var _panel_rect: Rect2 = Rect2()
var _panel_alpha: float = 0.0
var _target_alpha: float = 0.0

var _locale: Node = null

var _btn_rect: Rect2 = Rect2()
var _btn_hovered: bool = false

# Task 3.2: Navigation
var _show_step_index: bool = false

# Task 3.3: Hints
var _hint_used: bool = false
var _attempts: int = 0
var _hint_shown: bool = false
var _hint_stuck_timer: float = 0.0
var _hint_auto_after: float = 10.0

# Glossary
var _show_glossary: bool = false
var _glossary_data: Dictionary = {}
var _glossary_scroll: float = 0.0

# Tooltips
var _tooltip_text: String = ""
var _tooltip_target: String = ""
var _tooltip_timer: float = 0.0
var _tooltip_delay: float = 0.5
var _tooltip_buttons: Array[Dictionary] = []

# QoL: First-load help overlay
var _show_help_overlay: bool = false


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 4
	small_font_size = font_size - 2
	visible = false

	_locale = get_node_or_null("/root/Locale")
	if _locale == null:
		var scene: PackedScene = load("res://core/locale/locale_manager.tscn")
		if scene != null:
			_locale = scene.instantiate()
		else:
			_locale = Node.new()
			_locale.set_script(load("res://core/locale/locale_manager.gd"))
		_locale.name = "Locale"
		get_tree().root.add_child(_locale)

	_load_glossary()


func t(key: String) -> String:
	if _locale != null and _locale.has_method("loc"):
		return _locale.loc(key)
	return key


func _load_glossary() -> void:
	var file: FileAccess = FileAccess.open("res://juego/tutorials/glossary.json", FileAccess.READ)
	if file == null:
		push_warning("TutorialPlayer: no se pudo cargar glossary.json")
		return
	var json_text: String = file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed != null and parsed is Dictionary:
		_glossary_data = parsed
		GameLogger.info("TutorialPlayer", "Glosario cargado: %d términos" % parsed.get("terms", {}).size())


func load_tutorial(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TutorialPlayer: no se pudo abrir %s" % path)
		return false

	var json_text: String = file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_error("TutorialPlayer: JSON invalido en %s" % path)
		return false

	tutorial_data = parsed
	steps = tutorial_data.get("steps", [])
	if steps.is_empty():
		push_warning("TutorialPlayer: tutorial sin steps en %s" % path)
		return false

	current_step_index = -1
	is_active = true
	visible = true
	modulate.a = 1.0
	_panel_alpha = 0.0
	_target_alpha = 1.0

	GameLogger.info("TutorialPlayer", "Tutorial cargado: %s (%d pasos)" % [tutorial_data.get("id", "?"), steps.size()])
	return true


func start() -> void:
	if not is_active or steps.is_empty():
		return
	_advance_to_step(0)


func skip() -> void:
	if not is_active:
		return
	var tid: String = tutorial_data.get("id", "")
	_finish_tutorial()
	tutorial_skipped.emit(tid)
	GameLogger.info("TutorialPlayer", "Tutorial saltado: %s" % tid)


func complete_tutorial() -> void:
	"""Marca el tutorial como completado desde el juego (ej: al alcanzar el target).
	Muestra un mensaje de confirmación y oculta el panel tras una pausa breve."""
	if not is_active:
		return
	var tid: String = tutorial_data.get("id", "")
	# Marcar el último paso como alcanzado para mostrar el tutorial completo
	current_step_index = steps.size() - 1
	_waiting_for_action = false
	_action_fulfilled = true
	_hint_shown = false
	queue_redraw()
	# Esperar un momento breve para que el jugador vea que completó
	await get_tree().create_timer(0.5).timeout
	_finish_tutorial()
	# _finish_tutorial() ya emite tutorial_completed y oculta el panel
	GameLogger.info("TutorialPlayer", "Tutorial completado desde juego: %s" % tid)


func advance() -> void:
	if not is_active:
		return
	if _waiting_for_action and not _action_fulfilled:
		_attempts += 1
		if _attempts >= 3 and not _hint_shown and get_hint() != "":
			_hint_shown = true
		return
	if current_step_index >= steps.size() - 1:
		_finish_tutorial()
		return
	_advance_to_step(current_step_index + 1)


func previous() -> void:
	if not is_active or current_step_index <= 0:
		return
	_advance_to_step(current_step_index - 1)


func go_to_step(idx: int) -> void:
	if not is_active or idx < 0 or idx >= steps.size():
		return
	_advance_to_step(idx)


func get_steps_summary() -> Array:
	var summary: Array = []
	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		summary.append({
			"index": i,
			"id": step.get("id", ""),
			"title": step.get("title", step.get("id", "Paso " + str(i + 1)))
		})
	return summary


func get_hint() -> String:
	if current_step_index < 0 or current_step_index >= steps.size():
		return ""
	var step: Dictionary = steps[current_step_index]
	return step.get("hint", "")


func show_hint() -> void:
	if _hint_shown:
		return
	_hint_shown = true
	_hint_used = true
	GameLogger.info("TutorialPlayer", "Hint mostrado en paso %d" % (current_step_index + 1))


func toggle_glossary() -> void:
	_show_glossary = not _show_glossary
	_glossary_scroll = 0.0
	if _show_glossary:
		GameLogger.info("TutorialPlayer", "Glosario abierto")


func notify_action(action_type: String) -> void:
	## Marca la acción del paso actual como cumplida cuando el juego reporta
	## que el jugador la ejecutó (mover, escanear, explotar, bloquear...).
	## NO avanza automáticamente: el avance se confirma con [Enter] para dar
	## control al jugador y evitar saltos accidentales (Slice 3.8 v2).
	if not is_active or not _waiting_for_action:
		return
	var step: Dictionary = steps[current_step_index]
	var required = step.get("action_required", "")
	if required == null:
		required = ""
	if required == "" or required == action_type:
		_action_fulfilled = true


func notify_moved() -> void:
	notify_action("move")


func notify_input() -> void:
	notify_action("input")


func can_perform_action(action_type: String) -> bool:
	## Devuelve si la acción `action_type` está permitida ahora mismo.
	## Durante un paso de acción (action_required != "") SOLO se permite la
	## acción requerida; cualquier otra se bloquea (evita Tab+Enter / X /
	## exploits accidentales que desvían al jugador por el camino incorrecto).
	## Fuera del tutorial, de pasos informativos o sin acción pendiente,
	## siempre devuelve true.
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return true
	if not _waiting_for_action:
		return true
	var required = steps[current_step_index].get("action_required", "")
	if required == null:
		required = ""
	if required == "":
		return true
	return required == action_type


func step_requires_action() -> bool:
	## True si el paso actual pide una acción (action_required no vacío).
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return false
	return _step_requires_action(steps[current_step_index])


func _step_requires_action(step: Dictionary) -> bool:
	var ar = step.get("action_required", "")
	return ar != null and str(ar) != ""


func get_highlight_nodes() -> Array:
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return []
	return steps[current_step_index].get("highlight_nodes", [])


func get_highlight_edges() -> Array:
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return []
	return steps[current_step_index].get("highlight_edges", [])


func is_game_paused() -> bool:
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return false
	if _waiting_for_action:
		return false
	return steps[current_step_index].get("pause_game", false)


func _advance_to_step(idx: int) -> void:
	if idx < 0 or idx >= steps.size():
		return

	current_step_index = idx
	_action_fulfilled = false
	_waiting_for_action = false
	_auto_advance_timer = 0.0
	_auto_advance_target = 0.0
	_show_step_index = false
	_hint_used = false
	_attempts = 0
	_hint_shown = false
	_hint_stuck_timer = 0.0

	var step: Dictionary = steps[idx]

	var ar = step.get("action_required", "")
	if ar != null and ar != "":
		_waiting_for_action = true

	if step.get("auto_advance_after", null) != null:
		_auto_advance_target = float(step["auto_advance_after"])

	_panel_alpha = 0.0
	_target_alpha = 1.0

	step_changed.emit(idx, step)
	GameLogger.info("TutorialPlayer", "Tutorial paso %d/%d: %s" % [idx + 1, steps.size(), step.get("id", "?")])


func _finish_tutorial() -> void:
	var tid: String = tutorial_data.get("id", "")
	is_active = false
	current_step_index = -1
	_target_alpha = 0.0
	_waiting_for_action = false
	_action_fulfilled = false

	if is_paused_by_tutorial:
		get_tree().paused = false
		is_paused_by_tutorial = false

	tutorial_completed.emit(tid)
	GameLogger.info("TutorialPlayer", "Tutorial completado: %s" % tid)

	await get_tree().create_timer(0.3).timeout
	visible = false


func _process(delta: float) -> void:
	if not is_active and not _show_glossary:
		return

	var vp: Vector2 = get_viewport_rect().size
	size = vp
	position = Vector2.ZERO

	if is_active:
		_panel_alpha = move_toward(_panel_alpha, _target_alpha, delta * 5.0)

		if _auto_advance_target > 0.0 and not _waiting_for_action:
			# El auto-avance por tiempo solo aplica a pasos informativos; un
			# paso de acción NUNCA avanza solo (requiere la acción + [Enter]).
			_auto_advance_timer += delta
			if _auto_advance_timer >= _auto_advance_target:
				advance()

		# Auto-reveal hint after being stuck
		if _waiting_for_action and not _hint_shown:
			var step_hint: String = get_hint()
			if step_hint != "":
				_hint_stuck_timer += delta
				if _hint_stuck_timer >= _hint_auto_after:
					_hint_shown = true
					_hint_used = true

		# Tooltip detection
		_update_tooltip_buttons()
		_check_tooltip_hover(delta)

	# Glossary scroll with mouse wheel
	if _show_glossary:
		var terms_count: int = _glossary_data.get("terms", {}).size()
		if terms_count > 0:
			var max_scroll: float = max(0.0, float(terms_count) * 40.0 - vp.y * 0.6)
			if Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_page_down"):
				_glossary_scroll += 40.0
			if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_page_up"):
				_glossary_scroll -= 40.0
			_glossary_scroll = clamp(_glossary_scroll, 0.0, max_scroll)

	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _btn_hovered and not _waiting_for_action:
			_on_next_pressed()
			get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k: InputEventKey = event as InputEventKey
		match k.keycode:
			KEY_LEFT, KEY_BACKSPACE:
				previous()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				skip()
				get_viewport().set_input_as_handled()
			KEY_I:
				_show_step_index = not _show_step_index
				_tooltip_text = ""
				get_viewport().set_input_as_handled()
			KEY_G:
				toggle_glossary()
				_tooltip_text = ""
				get_viewport().set_input_as_handled()
			KEY_H:
				if _waiting_for_action:
					show_hint()
				else:
					_show_help_overlay = not _show_help_overlay
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_SPACE:
				# Slice 3.8 v2 — [Enter] confirma. En pasos de acción solo avanza
				# si la acción YA se cumplió; si no, el evento se deja pasar sin
				# consumir para que el juego pueda procesarlo (mover, resolver
				# turno del defensor, etc.) y el jugador complete la acción.
				if _waiting_for_action:
					if _action_fulfilled:
						_on_next_pressed()
						get_viewport().set_input_as_handled()
				else:
					_on_next_pressed()
					get_viewport().set_input_as_handled()


func _on_next_pressed() -> void:
	advance()


func _update_tooltip_buttons() -> void:
	_tooltip_buttons.clear()
	var vp_size: Vector2 = get_viewport_rect().size

	# Next button (solo en pasos informativos; en pasos de acción el avance
	# se confirma con [Enter] desde el recordatorio superior)
	if not _waiting_for_action:
		var btn_rect: Rect2 = _get_next_button_rect()
		_tooltip_buttons.append({
			"rect": btn_rect,
			"text": "Avanzar al siguiente paso",
			"en": "Advance to the next step"
		})

	# Previous (←) area
	var prev_rect: Rect2 = Rect2(Vector2(15.0, vp_size.y - 30.0), Vector2(80.0, 24.0))
	_tooltip_buttons.append({
		"rect": prev_rect,
		"text": "Volver al paso anterior",
		"en": "Go back to the previous step"
	})

	# Skip (ESC) area
	var skip_rect: Rect2 = Rect2(Vector2(100.0, vp_size.y - 30.0), Vector2(80.0, 24.0))
	_tooltip_buttons.append({
		"rect": skip_rect,
		"text": "Saltar este tutorial",
		"en": "Skip this tutorial"
	})

	# Index (I) area
	var idx_rect: Rect2 = Rect2(Vector2(190.0, vp_size.y - 30.0), Vector2(80.0, 24.0))
	_tooltip_buttons.append({
		"rect": idx_rect,
		"text": "Ver todos los pasos",
		"en": "View all steps"
	})

	# Glossary (G) area
	var gls_rect: Rect2 = Rect2(Vector2(270.0, vp_size.y - 30.0), Vector2(65.0, 24.0))
	_tooltip_buttons.append({
		"rect": gls_rect,
		"text": "Abrir glosario",
		"en": "Open glossary"
	})

	# Hint (H) area
	var hint_label: String = "Mostrar pista" if _waiting_for_action else "Ayuda de controles"
	var hint_rect: Rect2 = Rect2(Vector2(340.0, vp_size.y - 30.0), Vector2(100.0, 24.0))
	_tooltip_buttons.append({
		"rect": hint_rect,
		"text": hint_label,
		"en": "Show hint" if _waiting_for_action else "Controls help"
	})


func _check_tooltip_hover(delta: float) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var found: String = ""
	for btn in _tooltip_buttons:
		var r: Rect2 = btn["rect"]
		if r.has_point(mouse_pos):
			found = btn["text"]
			break

	if found != _tooltip_target:
		_tooltip_target = found
		_tooltip_timer = 0.0
		_tooltip_text = ""

	if _tooltip_target != "":
		_tooltip_timer += delta
		if _tooltip_timer >= _tooltip_delay:
			_tooltip_text = _tooltip_target
	else:
		_tooltip_text = ""
		_tooltip_target = ""


func _get_next_button_rect() -> Rect2:
	var vp_size: Vector2 = get_viewport_rect().size
	var btn_w: float = 130.0
	var btn_h: float = 36.0
	var margin: float = 20.0
	var btn_pos: Vector2 = Vector2(
		_panel_rect.position.x + _panel_rect.size.x - btn_w - margin,
		_panel_rect.position.y + _panel_rect.size.y + 12.0
	)
	return Rect2(btn_pos, Vector2(btn_w, btn_h))


func _draw() -> void:
	if is_active and current_step_index >= 0 and current_step_index < steps.size() and _panel_alpha >= 0.01:
		var step: Dictionary = steps[current_step_index]
		var text: String = step.get("text", "")
		var position: String = step.get("position", "center")
		var requires_action: bool = _step_requires_action(step)

		# Slice 3.8 v2 — dos modos de render:
		#   - Paso informativo → panel grande centrado (explicación).
		#   - Paso de acción   → recordatorio compacto ARRIBA, sin tapar la
		#     vista del tablero; la acción se juega en el juego y se confirma
		#     con [Enter].
		if requires_action:
			_draw_action_reminder(step)
		else:
			_draw_floating_panel(text, position)
			_draw_next_button()
			_draw_step_indicator()
		_draw_controls_bar()
		if _hint_shown:
			_draw_hint_panel()
		if _show_step_index:
			_draw_step_index_overlay()
		if _show_help_overlay:
			_draw_help_overlay()
			# Show minimize hint for help overlay
			var vp_size: Vector2 = get_viewport_rect().size
			var close_hint: String = "[H / F1] Cerrar ayuda"
			var close_pos: Vector2 = Vector2((vp_size.x - font.get_string_size(close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, vp_size.y - 8.0)
			draw_string(font, close_pos, close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.5, 0.5, 0.5, _panel_alpha * 0.8))

		# Draw tooltip
		if _tooltip_text != "":
			_draw_tooltip(_tooltip_text)

	if _show_glossary:
		_draw_glossary_overlay()


func _draw_floating_panel(text: String, position: String) -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var panel_w: float = min(480.0, vp_size.x - 60.0)
	var lines: PackedStringArray = text.split("\n")
	var line_h: float = 18.0
	var panel_h: float = max(80.0, lines.size() * line_h + 40.0)

	var panel_pos: Vector2
	match position:
		"top":
			panel_pos = Vector2((vp_size.x - panel_w) / 2.0, 70.0)
		"bottom":
			panel_pos = Vector2((vp_size.x - panel_w) / 2.0, vp_size.y - panel_h - 60.0)
		"left":
			panel_pos = Vector2(30.0, (vp_size.y - panel_h) / 2.0)
		"right":
			panel_pos = Vector2(vp_size.x - panel_w - 30.0, (vp_size.y - panel_h) / 2.0)
		_:
			panel_pos = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)

	_panel_rect = Rect2(panel_pos, Vector2(panel_w, panel_h))

	var bg: Color = Color(_panel_color.r, _panel_color.g, _panel_color.b, _panel_alpha * _panel_color.a)
	var border: Color = Color(_panel_border.r, _panel_border.g, _panel_border.b, _panel_alpha * _panel_border.a)

	draw_rect(_panel_rect, bg)
	draw_rect(_panel_rect, border, false, 2.0)

	var glow_corners: Array[Vector2] = [
		panel_pos,
		panel_pos + Vector2(panel_w, 0),
		panel_pos + Vector2(0, panel_h),
		panel_pos + Vector2(panel_w, panel_h)
	]
	for corner in glow_corners:
		draw_circle(corner, 3.0, Color(border.r, border.g, border.b, _panel_alpha * 0.6))

	var text_x: float = panel_pos.x + 20.0
	var text_y: float = panel_pos.y + 28.0
	var text_alpha: float = _panel_alpha

	for line in lines:
		var lcolor: Color = Color(_text_color.r, _text_color.g, _text_color.b, text_alpha)
		if line.begins_with("⚠") or line.begins_with("ALERTA"):
			lcolor = Color(_warning_color.r, _warning_color.g, _warning_color.b, text_alpha)
		draw_string(font, Vector2(text_x, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, lcolor)
		text_y += line_h


func _get_action_short_name(action_type: String) -> String:
	## Nombre corto y legible de una acción requerida (Rail 2 del Slice 3.8 v2).
	match action_type:
		"move":
			return "MOVERSE"
		"scan":
			return "ESCANEAR"
		"input":
			return "ACCIÓN"
		_:
			return action_type.to_upper()


func _get_action_key_hint(action_type: String) -> String:
	## Pista de tecla/gesto para una acción requerida (Rail 2 del Slice 3.8 v2).
	match action_type:
		"move":
			return "Haz clic en un nodo o usa [Tab] + [Enter]"
		"scan":
			return "Presiona [X] para escanear"
		_:
			return ""


func _draw_action_reminder(step: Dictionary) -> void:
	## Recordatorio compacto (Slice 3.8 v2) para pasos que piden una acción.
	## Se dibuja en la parte SUPERIOR de la pantalla para NO tapar el tablero:
	## muestra el nombre de la acción, cómo hacerla y la confirmación con
	## [Enter]. No sustituye al juego: el jugador ejecuta la acción en el
	## tablero y luego presiona [Enter] para avanzar.
	var vp_size: Vector2 = get_viewport_rect().size
	var action_type: String = str(step.get("action_required", ""))
	var short_name: String = _get_action_short_name(action_type)
	var title: String = step.get("title", "")

	var rem_w: float = min(580.0, vp_size.x - 24.0)
	var line_h: float = 18.0
	var margin: float = 14.0

	# Línea de detalle: hint del paso → pista de tecla → primera línea del texto.
	var detail: String = step.get("hint", "")
	if detail == "":
		detail = _get_action_key_hint(action_type)
	if detail == "":
		for l in String(step.get("text", "")).split("\n"):
			if l.strip_edges() != "":
				detail = l.strip_edges()
				break

	var header: String = "⚠ %s: %s" % [short_name, title]
	var confirm_label: String = "Presiona [Enter] cuando completes la acción"
	if _action_fulfilled:
		confirm_label = "✅ ¡Acción completada! Presiona [Enter] para continuar"

	var detail_lines: Array[String] = []
	if detail != "":
		detail_lines = _wrap_text(detail, rem_w - margin * 2.0, small_font_size)

	var rem_h: float = line_h * (2 + detail_lines.size()) + 18.0
	var rem_pos: Vector2 = Vector2((vp_size.x - rem_w) / 2.0, 10.0)
	_panel_rect = Rect2(rem_pos, Vector2(rem_w, rem_h))

	var alpha: float = _panel_alpha
	var bg: Color = Color(_panel_color.r, _panel_color.g, _panel_color.b, alpha * 0.95)
	var border: Color
	if _action_fulfilled:
		border = Color(0.3, 1.0, 0.5, alpha)  # verde: acción cumplida (Rail 4)
	else:
		var pulse: float = 0.7 + sin(Time.get_ticks_msec() * 0.006) * 0.3
		border = Color(1.0, 0.84, 0.0, alpha * pulse)  # ámbar pulsante

	draw_rect(_panel_rect, bg)
	draw_rect(_panel_rect, border, false, 2.0)

	var text_x: float = rem_pos.x + margin
	var y: float = rem_pos.y + 14.0
	draw_string(font, Vector2(text_x, y), header, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(_accent_color.r, _accent_color.g, _accent_color.b, alpha))
	y += line_h
	for dl in detail_lines:
		draw_string(font, Vector2(text_x, y), dl, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.92, 0.92, 0.92, alpha))
		y += line_h
	var confirm_color: Color = Color(0.4, 1.0, 0.6, alpha) if _action_fulfilled else Color(0.7, 0.7, 0.7, alpha * 0.9)
	draw_string(font, Vector2(text_x, y), confirm_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, confirm_color)


func _draw_next_button() -> void:
	_btn_rect = _get_next_button_rect()

	var can_advance: bool = not _waiting_for_action
	var bg: Color
	if not can_advance:
		bg = Color(0.3, 0.3, 0.3, _panel_alpha * 0.5)
	elif _btn_hovered:
		bg = Color(_btn_hover_color.r, _btn_hover_color.g, _btn_hover_color.b, _panel_alpha * 0.9)
	else:
		bg = Color(_btn_color.r, _btn_color.g, _btn_color.b, _panel_alpha * 0.8)

	var border_color: Color = Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha * (1.0 if can_advance else 0.3))

	draw_rect(_btn_rect, bg)
	draw_rect(_btn_rect, border_color, false, 2.0)

	var label: String
	if not can_advance:
		label = t("tutorial.hint_action")
	else:
		label = t("tutorial.next")
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos: Vector2 = Vector2(
		_btn_rect.position.x + (_btn_rect.size.x - text_size.x) / 2.0,
		_btn_rect.position.y + (_btn_rect.size.y + text_size.y * 0.35) / 2.0
	)
	var text_color: Color = Color.WHITE if can_advance else Color(0.7, 0.7, 0.7, 0.8)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


func _draw_step_indicator() -> void:
	if steps.is_empty():
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var total: int = steps.size()
	var dot_r: float = 5.0
	var gap: float = 16.0
	var total_w: float = total * dot_r * 2.0 + (total - 1) * gap
	var start_x: float = (vp_size.x - total_w) / 2.0
	var y: float = _panel_rect.position.y + _panel_rect.size.y + 55.0

	# Draw step title above the dots
	var current_step: Dictionary = steps[current_step_index]
	var step_title: String = current_step.get("title", current_step.get("id", ""))
	if step_title != "":
		var title_pos: Vector2 = Vector2((vp_size.x - font.get_string_size(step_title, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, y - 22.0)
		draw_string(font, title_pos, step_title, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha))

	for i in range(total):
		var cx: float = start_x + i * (dot_r * 2.0 + gap) + dot_r
		var color: Color
		if i == current_step_index:
			color = Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha)
		elif i < current_step_index:
			color = Color(0.4, 0.4, 0.4, _panel_alpha * 0.6)
		else:
			color = Color(0.3, 0.3, 0.3, _panel_alpha * 0.4)
		draw_circle(Vector2(cx, y), dot_r, color)

	# Progress bar beneath dots
	var bar_w: float = total_w
	var bar_h: float = 4.0
	var bar_y: float = y + 12.0
	var pct: float = float(current_step_index + 1) / float(total)
	# Background bar
	draw_rect(Rect2(Vector2(start_x, bar_y), Vector2(bar_w, bar_h)), Color(0.15, 0.15, 0.15, _panel_alpha * 0.6))
	# Filled bar
	if pct > 0:
		draw_rect(Rect2(Vector2(start_x, bar_y), Vector2(bar_w * pct, bar_h)), Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha * 0.8))
	# Rounded ends
	draw_circle(Vector2(start_x + bar_w * pct, bar_y + bar_h / 2.0), bar_h / 2.0 + 1.0, Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha * 0.8))

	# Percentage text
	var pct_text: String = "%d%%" % int(pct * 100)
	var pct_pos: Vector2 = Vector2(start_x + bar_w + 8.0, bar_y - 2.0)
	draw_string(font, pct_pos, pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha * 0.7))

	var step_label: String = "%s %d %s %d: %s" % [t("tutorial.step"), current_step_index + 1, t("tutorial.of"), steps.size(), step_title]
	var label_pos: Vector2 = Vector2((vp_size.x - font.get_string_size(step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, bar_y + 18.0)
	draw_string(font, label_pos, step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.6, 0.6, 0.6, _panel_alpha * 0.7))

	# Draw tutorial objective if present
	var objective: String = tutorial_data.get("objective", "")
	if objective != "":
		var obj_pos: Vector2 = Vector2((vp_size.x - font.get_string_size(objective, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, bar_y + 34.0)
		draw_string(font, obj_pos, objective, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.5, 0.5, 0.7, _panel_alpha * 0.6))


func _draw_controls_bar() -> void:
	"""Barra de controles siempre visible en la parte inferior de la pantalla."""
	var vp_size: Vector2 = get_viewport_rect().size
	var bar_h: float = 28.0
	var bar_pos: Vector2 = Vector2(0.0, vp_size.y - bar_h)
	var alpha: float = _panel_alpha

	# Draw semi-transparent background bar for controls
	draw_rect(Rect2(bar_pos, Vector2(vp_size.x, bar_h)), Color(0.02, 0.02, 0.06, alpha * 0.85))
	draw_rect(Rect2(bar_pos, Vector2(vp_size.x, bar_h)), Color(_accent_color.r, _accent_color.g, _accent_color.b, alpha * 0.3), false, 1.0)

	var controls_text: String
	if _waiting_for_action:
		controls_text = "[Enter] confirmar al completar  [←] %s  [I] Índice  [G] Glosario  [H] Pista  [ESC] Saltar" % t("tutorial.previous")
	else:
		controls_text = "[Enter/Espacio] %s  [←] %s  [I] Índice  [G] Glosario  [H] Ayuda  [ESC] Saltar" % [t("tutorial.next"), t("tutorial.previous")]

	var text_w: float = font.get_string_size(controls_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x
	var text_x: float = (vp_size.x - text_w) / 2.0
	draw_string(font, Vector2(text_x, bar_pos.y + bar_h * 0.65), controls_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.8, 0.8, 0.8, alpha))


func _draw_hint_panel() -> void:
	var step_hint: String = get_hint()
	if step_hint == "":
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var panel_w: float = min(440.0, vp_size.x - 80.0)
	var line_h: float = 16.0
	var margin: float = 12.0
	var hint_lines: PackedStringArray = step_hint.split("\n")
	var panel_h: float = hint_lines.size() * line_h + 32.0

	var panel_pos: Vector2 = Vector2(
		(vp_size.x - panel_w) / 2.0,
		_panel_rect.position.y + _panel_rect.size.y + (12.0 if _waiting_for_action else 110.0)
	)

	var bg: Color = Color(0.08, 0.08, 0.18, _panel_alpha * 0.9)
	var border: Color = Color(1.0, 0.84, 0.0, _panel_alpha * 0.8)
	draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), bg)
	draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), border, false, 1.5)

	var label: String = "💡 %s" % t("tutorial.hint_button")
	draw_string(font, Vector2(panel_pos.x + margin, panel_pos.y + line_h), label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(1.0, 0.84, 0.0, _panel_alpha))

	for i in range(hint_lines.size()):
		draw_string(font, Vector2(panel_pos.x + margin, panel_pos.y + line_h * 2.0 + line_h * i), hint_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.9, 0.9, 0.9, _panel_alpha))


func _draw_step_index_overlay() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var overlay_w: float = min(360.0, vp_size.x - 60.0)
	var line_h: float = 22.0
	var margin: float = 16.0
	var summary: Array = get_steps_summary()
	var overlay_h: float = summary.size() * line_h + 48.0

	var overlay_pos: Vector2 = Vector2(
		(vp_size.x - overlay_w) / 2.0,
		(vp_size.y - overlay_h) / 2.0
	)

	var bg: Color = Color(0.05, 0.05, 0.12, 0.95)
	var border: Color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.9)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), bg)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), border, false, 2.0)

	var title: String = "📋 %s" % t("tutorial.index")
	draw_string(font, Vector2(overlay_pos.x + margin, overlay_pos.y + 16.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha))

	for i in range(summary.size()):
		var item: Dictionary = summary[i]
		var is_current: bool = (i == current_step_index)
		var color: Color
		if is_current:
			color = Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha)
		else:
			color = Color(0.6, 0.6, 0.6, _panel_alpha * 0.8)
		var prefix: String = "→ " if is_current else "  "
		var step_text: String = "%s%d. %s" % [prefix, i + 1, item.get("title", "")]
		draw_string(font, Vector2(overlay_pos.x + margin, overlay_pos.y + 38.0 + i * line_h), step_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, color)

	var close_hint: String = "[I] %s" % t("tutorial.index")
	draw_string(font, Vector2(overlay_pos.x + (overlay_w - font.get_string_size(close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, overlay_pos.y + overlay_h - 10.0), close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.5, 0.5, 0.5, _panel_alpha * 0.7))


func _draw_help_overlay() -> void:
	"""Overlay de ayuda con todos los controles del tutorial (presiona H/F1)."""
	var vp_size: Vector2 = get_viewport_rect().size
	var overlay_w: float = min(420.0, vp_size.x - 40.0)
	var line_h: float = 18.0
	var margin: float = 16.0

	var help_lines: Array[String] = [
		"CONTROLES DEL TUTORIAL",
		"",
		"Enter / Espacio  — Avanzar al siguiente paso",
		"← (flecha izq)  — Volver al paso anterior",
		"Backspace         — Volver al paso anterior",
		"I                  — Mostrar índice de pasos",
		"G                 — Abrir glosario de términos",
		"H                 — Mostrar/ocultar esta ayuda",
		"ESC               — Saltar tutorial",
		"",
		"DURANTE UNA ACCIÓN:",
		"H                 — Mostrar pista",
		"",
		"Presiona [H] para cerrar esta ayuda."
	]

	var overlay_h: float = help_lines.size() * line_h + 48.0
	var overlay_pos: Vector2 = Vector2(
		(vp_size.x - overlay_w) / 2.0,
		(vp_size.y - overlay_h) / 2.0
	)

	var bg: Color = Color(0.05, 0.05, 0.12, 0.95)
	var border: Color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.9)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), bg)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), border, false, 2.0)

	for i in range(help_lines.size()):
		var line_text: String = help_lines[i]
		var color: Color
		if i == 0:
			color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 1.0)
		elif line_text != "":
			color = Color(0.8, 0.8, 0.8, 0.9)
		else:
			color = Color(0.5, 0.5, 0.5, 0.1)  # spacing line, nearly invisible
		draw_string(font, Vector2(overlay_pos.x + margin, overlay_pos.y + 18.0 + i * line_h), line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, color)


func _draw_tooltip(tip_text: String) -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var tip_w: float = font.get_string_size(tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x + 20.0
	var tip_h: float = 24.0
	var tip_pos: Vector2 = mouse_pos + Vector2(12, -tip_h - 8)

	# Keep tooltip on screen
	var vp_size: Vector2 = get_viewport_rect().size
	if tip_pos.x + tip_w > vp_size.x:
		tip_pos.x = vp_size.x - tip_w - 4.0
	if tip_pos.y < 0:
		tip_pos.y = mouse_pos.y + 16.0
	if tip_pos.x < 0:
		tip_pos.x = 4.0

	draw_rect(Rect2(tip_pos, Vector2(tip_w, tip_h)), Color(0.1, 0.1, 0.1, 0.85))
	draw_rect(Rect2(tip_pos, Vector2(tip_w, tip_h)), Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.7), false, 1.0)
	draw_string(font, Vector2(tip_pos.x + 8.0, tip_pos.y + 16.0), tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color.WHITE)


func _draw_glossary_overlay() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var overlay_w: float = min(520.0, vp_size.x - 40.0)
	var overlay_h: float = min(420.0, vp_size.y - 40.0)
	var margin: float = 16.0
	var line_h: float = 22.0

	var overlay_pos: Vector2 = Vector2(
		(vp_size.x - overlay_w) / 2.0,
		(vp_size.y - overlay_h) / 2.0
	)

	# Background
	var bg: Color = Color(0.05, 0.05, 0.12, 0.95)
	var border: Color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.9)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), bg)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), border, false, 2.0)

	# Title
	var title: String = "📖 %s" % _glossary_data.get("title", "Glosario")
	draw_string(font, Vector2(overlay_pos.x + margin, overlay_pos.y + margin + 4.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, Color(_accent_color.r, _accent_color.g, _accent_color.b, 1.0))

	# Terms
	var terms: Dictionary = _glossary_data.get("terms", {})
	if terms.is_empty():
		var empty_text: String = "No hay términos definidos."
		draw_string(font, Vector2(overlay_pos.x + margin, overlay_pos.y + 50.0), empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.7, 0.7, 0.7, 1.0))
	else:
		var sorted_keys: Array = []
		for k in terms.keys():
			sorted_keys.append(k)
		sorted_keys.sort()

		var term_y: float = overlay_pos.y + 50.0 - _glossary_scroll
		var clip_top: float = overlay_pos.y + 42.0
		var clip_bottom: float = overlay_pos.y + overlay_h - 30.0

		for term_key in sorted_keys:
			var term: Dictionary = terms[term_key]
			var definition: String = term.get("definition", "")
			var term_name: String = String(term_key).capitalize()
			var prefix: String = "▪ %s: " % term_name
			var full_text: String = prefix + definition

			# Wrap text to fit
			var max_text_w: float = overlay_w - margin * 2.0
			var wrapped_lines: Array[String] = _wrap_text(full_text, max_text_w, small_font_size)

			if term_y + line_h > clip_top and term_y < clip_bottom:
				draw_string(font, Vector2(overlay_pos.x + margin, term_y), wrapped_lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.95))

			term_y += line_h
			for i in range(1, wrapped_lines.size()):
				if term_y + line_h > clip_top and term_y < clip_bottom:
					draw_string(font, Vector2(overlay_pos.x + margin + 12.0, term_y), wrapped_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.8, 0.8, 0.8, 0.9))
				term_y += line_h

			term_y += 4.0  # Extra gap between terms

	# Close hint
	var close_text: String = "[G] Cerrar glosario  [↑↓] Desplazar"
	var close_w: float = font.get_string_size(close_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x
	draw_string(font, Vector2(overlay_pos.x + (overlay_w - close_w) / 2.0, overlay_pos.y + overlay_h - 10.0), close_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.5, 0.5, 0.5, 0.8))


func _wrap_text(text: String, max_width: float, fsize: int) -> Array[String]:
	var words: PackedStringArray = text.split(" ")
	var lines: Array[String] = []
	var current_line: String = ""

	for word in words:
		var test_line: String = current_line + (" " if current_line != "" else "") + word
		var test_w: float = font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		if test_w > max_width and current_line != "":
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_line

	if current_line != "":
		lines.append(current_line)

	if lines.is_empty():
		lines.append(text)

	return lines
