class_name TutorialRender
extends RefCounted

## Funciones puras de texto y layout del tutorial_player — P2 (parte 1) de la
## descomposición de tutorial_player.gd.
##
## Aporta el wrap de texto, los nombres/pistas de acciones requeridas, la
## geometría del botón "siguiente", la construcción de los hotspots de
## tooltip y el cálculo de layout (Rect2/posiciones/textos ya resueltos) de
## los paneles: panel flotante, recordatorio de acción y overlay del
## glosario. Esas funciones son puras: entran parámetros, salen valores; no
## tocan el estado del player ni el árbol de escena.
##
## P2 (parte 2) además porta el dibujado: los _draw_* reciben el canvas
## (el Control del player, solo para draw_rect/draw_string/draw_circle) y un
## diccionario `s` con el estado dibujable resuelto por el player (fuentes,
## colores, alpha, rects, flags, pasos y un Callable `t` para traducir). NO
## leen vars del nodo directamente. Los puertos que resuelven geometría del
## panel (flotante / recordatorio) escriben el resultado en s["panel_rect"]
## para que el player lo sincronice (lo consumen indicador de pasos, pista
## y hotspots de tooltip del frame siguiente).
##
## Equivalencia de las funciones puras congelada por
## tests/tutorials/_test_tutorial_render_equivalence.{gd,tscn}; los _draw_*
## se verifican por compilación + suite + test_tutorial_system (100% lógica).

var font: Font


func setup(p_font: Font) -> void:
	font = p_font


## Puerto del viejo tutorial_player._wrap_text().
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


## Puerto del viejo tutorial_player._get_action_short_name().
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


## Puerto del viejo tutorial_player._get_action_key_hint().
func _get_action_key_hint(action_type: String) -> String:
	## Pista de tecla/gesto para una acción requerida (Rail 2 del Slice 3.8 v2).
	match action_type:
		"move":
			return "Haz clic en un nodo o usa [Tab] + [Enter]"
		"scan":
			return "Presiona [X] para escanear"
		_:
			return ""


## Puerto del viejo tutorial_player._get_next_button_rect(), parametrizado
## en panel_rect en vez de leer el estado del player (el vp_size del original
## era una local muerta: nunca se usaba).
func _get_next_button_rect(panel_rect: Rect2) -> Rect2:
	var btn_w: float = 130.0
	var btn_h: float = 36.0
	var margin: float = 20.0
	var btn_pos: Vector2 = Vector2(
		panel_rect.position.x + panel_rect.size.x - btn_w - margin,
		panel_rect.position.y + panel_rect.size.y + 12.0
	)
	return Rect2(btn_pos, Vector2(btn_w, btn_h))


## Puerto del viejo tutorial_player._update_tooltip_buttons(): construye y
## devuelve los hotspots; tutorial_input los almacena y consume en
## update_hover().
func _build_tooltip_buttons(vp_size: Vector2, waiting_for_action: bool, panel_rect: Rect2) -> Array[Dictionary]:
	var buttons: Array[Dictionary] = []

	# Next button (solo en pasos informativos; en pasos de acción el avance
	# se confirma con [Enter] desde el recordatorio superior)
	if not waiting_for_action:
		var btn_rect: Rect2 = _get_next_button_rect(panel_rect)
		buttons.append({
			"rect": btn_rect,
			"text": "Avanzar al siguiente paso",
			"en": "Advance to the next step"
		})

	# Previous (←) area
	var prev_rect: Rect2 = Rect2(Vector2(15.0, vp_size.y - 30.0), Vector2(80.0, 24.0))
	buttons.append({
		"rect": prev_rect,
		"text": "Volver al paso anterior",
		"en": "Go back to the previous step"
	})

	# Skip (ESC) area
	var skip_rect: Rect2 = Rect2(Vector2(100.0, vp_size.y - 30.0), Vector2(80.0, 24.0))
	buttons.append({
		"rect": skip_rect,
		"text": "Saltar este tutorial",
		"en": "Skip this tutorial"
	})

	# Index (I) area
	var idx_rect: Rect2 = Rect2(Vector2(190.0, vp_size.y - 30.0), Vector2(80.0, 24.0))
	buttons.append({
		"rect": idx_rect,
		"text": "Ver todos los pasos",
		"en": "View all steps"
	})

	# Glossary (G) area
	var gls_rect: Rect2 = Rect2(Vector2(270.0, vp_size.y - 30.0), Vector2(65.0, 24.0))
	buttons.append({
		"rect": gls_rect,
		"text": "Abrir glosario",
		"en": "Open glossary"
	})

	# Hint (H) area
	var hint_label: String = "Mostrar pista" if waiting_for_action else "Ayuda de controles"
	var hint_rect: Rect2 = Rect2(Vector2(340.0, vp_size.y - 30.0), Vector2(100.0, 24.0))
	buttons.append({
		"rect": hint_rect,
		"text": hint_label,
		"en": "Show hint" if waiting_for_action else "Controls help"
	})

	return buttons


## Layout del panel flotante informativo (puerto de _draw_floating_panel):
## Rect2 según la posición pedida + líneas y alto de línea para el dibujado.
func _floating_panel_layout(vp_size: Vector2, text: String, position: String) -> Dictionary:
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

	return {
		"rect": Rect2(panel_pos, Vector2(panel_w, panel_h)),
		"lines": lines,
		"line_h": line_h,
	}


## Layout del recordatorio de acción (puerto de _draw_action_reminder):
## Rect2 + textos ya resueltos: header (⚠ ACCIÓN: título), detalle con
## fallback hint → pista de tecla → primera línea del texto (wrapeado) y
## etiqueta de confirmación según si la acción ya se cumplió.
func _action_reminder_layout(step: Dictionary, vp_size: Vector2, small_font_size: int, action_fulfilled: bool) -> Dictionary:
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
	if action_fulfilled:
		confirm_label = "✅ ¡Acción completada! Presiona [Enter] para continuar"

	var detail_lines: Array[String] = []
	if detail != "":
		detail_lines = _wrap_text(detail, rem_w - margin * 2.0, small_font_size)

	var rem_h: float = line_h * (2 + detail_lines.size()) + 18.0
	var rem_pos: Vector2 = Vector2((vp_size.x - rem_w) / 2.0, 10.0)

	return {
		"rect": Rect2(rem_pos, Vector2(rem_w, rem_h)),
		"header": header,
		"detail_lines": detail_lines,
		"confirm_label": confirm_label,
		"line_h": line_h,
		"margin": margin,
	}


## Layout del overlay del glosario (puerto de _draw_glossary_overlay):
## Rect2 centrado con clamps por viewport + márgenes, alto de línea y banda
## de clip vertical para el scroll de términos.
func _glossary_overlay_layout(vp_size: Vector2) -> Dictionary:
	var overlay_w: float = min(520.0, vp_size.x - 40.0)
	var overlay_h: float = min(420.0, vp_size.y - 40.0)
	var margin: float = 16.0
	var line_h: float = 22.0

	var overlay_pos: Vector2 = Vector2(
		(vp_size.x - overlay_w) / 2.0,
		(vp_size.y - overlay_h) / 2.0
	)

	return {
		"rect": Rect2(overlay_pos, Vector2(overlay_w, overlay_h)),
		"margin": margin,
		"line_h": line_h,
		"clip_top": overlay_pos.y + 42.0,
		"clip_bottom": overlay_pos.y + overlay_h - 30.0,
	}


# ─── P2 (parte 2): puertos de los _draw_* ─────────────────────────────────
# Reciben el canvas (Control) y el estado dibujable `s` que arma el player;
# no leen vars del nodo. Ver encabezado del archivo.


## Traduce una key vía el Callable `t` del estado (delegado en el locale
## del player).
func _t(s: Dictionary, key: String) -> String:
	var tr: Callable = s.t
	return tr.call(key)


## Puerto del viejo tutorial_player._draw_floating_panel().
func _draw_floating_panel(canvas: Control, s: Dictionary, text: String, position: String) -> void:
	var fnt: Font = s.font
	var panel_alpha: float = s.panel_alpha
	var layout: Dictionary = _floating_panel_layout(s.vp_size, text, position)
	var panel_rect: Rect2 = layout["rect"]
	s["panel_rect"] = panel_rect
	var lines: PackedStringArray = layout["lines"]
	var line_h: float = layout["line_h"]
	var panel_pos: Vector2 = panel_rect.position
	var panel_w: float = panel_rect.size.x
	var panel_h: float = panel_rect.size.y

	var bg: Color = Color(s.panel_color.r, s.panel_color.g, s.panel_color.b, panel_alpha * s.panel_color.a)
	var border: Color = Color(s.panel_border.r, s.panel_border.g, s.panel_border.b, panel_alpha * s.panel_border.a)

	canvas.draw_rect(panel_rect, bg)
	canvas.draw_rect(panel_rect, border, false, 2.0)

	var glow_corners: Array[Vector2] = [
		panel_pos,
		panel_pos + Vector2(panel_w, 0),
		panel_pos + Vector2(0, panel_h),
		panel_pos + Vector2(panel_w, panel_h)
	]
	for corner in glow_corners:
		canvas.draw_circle(corner, 3.0, Color(border.r, border.g, border.b, panel_alpha * 0.6))

	var text_x: float = panel_pos.x + 20.0
	var text_y: float = panel_pos.y + 28.0
	var text_alpha: float = panel_alpha

	for line in lines:
		var lcolor: Color = Color(s.text_color.r, s.text_color.g, s.text_color.b, text_alpha)
		if line.begins_with("⚠") or line.begins_with("ALERTA"):
			lcolor = Color(s.warning_color.r, s.warning_color.g, s.warning_color.b, text_alpha)
		canvas.draw_string(fnt, Vector2(text_x, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, s.font_size, lcolor)
		text_y += line_h


## Puerto del viejo tutorial_player._draw_action_reminder().
## Recordatorio compacto (Slice 3.8 v2) para pasos que piden una acción.
## Se dibuja en la parte SUPERIOR de la pantalla para NO tapar el tablero:
## muestra el nombre de la acción, cómo hacerla y la confirmación con
## [Enter]. No sustituye al juego: el jugador ejecuta la acción en el
## tablero y luego presiona [Enter] para avanzar. El layout (rect, textos,
## wrap del detalle) viene de _action_reminder_layout.
func _draw_action_reminder(canvas: Control, s: Dictionary, step: Dictionary) -> void:
	var fnt: Font = s.font
	var layout: Dictionary = _action_reminder_layout(step, s.vp_size, s.small_font_size, s.action_fulfilled)
	var panel_rect: Rect2 = layout["rect"]
	s["panel_rect"] = panel_rect
	var line_h: float = layout["line_h"]

	var alpha: float = s.panel_alpha
	var bg: Color = Color(s.panel_color.r, s.panel_color.g, s.panel_color.b, alpha * 0.95)
	var border: Color
	if s.action_fulfilled:
		border = Color(0.3, 1.0, 0.5, alpha)  # verde: acción cumplida (Rail 4)
	else:
		var pulse: float = 0.7 + sin(Time.get_ticks_msec() * 0.006) * 0.3
		border = Color(1.0, 0.84, 0.0, alpha * pulse)  # ámbar pulsante

	canvas.draw_rect(panel_rect, bg)
	canvas.draw_rect(panel_rect, border, false, 2.0)

	var text_x: float = panel_rect.position.x + layout["margin"]
	var y: float = panel_rect.position.y + 14.0
	canvas.draw_string(fnt, Vector2(text_x, y), layout["header"], HORIZONTAL_ALIGNMENT_LEFT, -1, s.font_size, Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, alpha))
	y += line_h
	for dl in layout["detail_lines"]:
		canvas.draw_string(fnt, Vector2(text_x, y), dl, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.92, 0.92, 0.92, alpha))
		y += line_h
	var confirm_color: Color = Color(0.4, 1.0, 0.6, alpha) if s.action_fulfilled else Color(0.7, 0.7, 0.7, alpha * 0.9)
	canvas.draw_string(fnt, Vector2(text_x, y), layout["confirm_label"], HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, confirm_color)


## Puerto del viejo tutorial_player._draw_next_button().
func _draw_next_button(canvas: Control, s: Dictionary) -> void:
	var fnt: Font = s.font
	var btn_rect: Rect2 = _get_next_button_rect(s.panel_rect)

	var can_advance: bool = not s.waiting_for_action
	var bg: Color
	if not can_advance:
		bg = Color(0.3, 0.3, 0.3, s.panel_alpha * 0.5)
	else:
		bg = Color(s.btn_color.r, s.btn_color.g, s.btn_color.b, s.panel_alpha * 0.8)

	var border_color: Color = Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, s.panel_alpha * (1.0 if can_advance else 0.3))

	canvas.draw_rect(btn_rect, bg)
	canvas.draw_rect(btn_rect, border_color, false, 2.0)

	var label: String
	if not can_advance:
		label = _t(s, "tutorial.hint_action")
	else:
		label = _t(s, "tutorial.next")
	var text_size: Vector2 = fnt.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, s.font_size)
	var text_pos: Vector2 = Vector2(
		btn_rect.position.x + (btn_rect.size.x - text_size.x) / 2.0,
		btn_rect.position.y + (btn_rect.size.y + text_size.y * 0.35) / 2.0
	)
	var text_color: Color = Color.WHITE if can_advance else Color(0.7, 0.7, 0.7, 0.8)
	canvas.draw_string(fnt, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, s.font_size, text_color)


## Puerto del viejo tutorial_player._draw_step_indicator().
func _draw_step_indicator(canvas: Control, s: Dictionary) -> void:
	var steps: Array = s.steps
	if steps.is_empty():
		return
	var fnt: Font = s.font
	var current_step_index: int = s.current_step_index
	var vp_size: Vector2 = s.vp_size
	var accent: Color = s.accent_color
	var panel_alpha: float = s.panel_alpha
	var total: int = steps.size()
	var dot_r: float = 5.0
	var gap: float = 16.0
	var total_w: float = total * dot_r * 2.0 + (total - 1) * gap
	var start_x: float = (vp_size.x - total_w) / 2.0
	var y: float = s.panel_rect.position.y + s.panel_rect.size.y + 55.0

	# Draw step title above the dots
	var current_step: Dictionary = steps[current_step_index]
	var step_title: String = current_step.get("title", current_step.get("id", ""))
	if step_title != "":
		var title_pos: Vector2 = Vector2((vp_size.x - fnt.get_string_size(step_title, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x) / 2.0, y - 22.0)
		canvas.draw_string(fnt, title_pos, step_title, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(accent.r, accent.g, accent.b, panel_alpha))

	for i in range(total):
		var cx: float = start_x + i * (dot_r * 2.0 + gap) + dot_r
		var color: Color
		if i == current_step_index:
			color = Color(accent.r, accent.g, accent.b, panel_alpha)
		elif i < current_step_index:
			color = Color(0.4, 0.4, 0.4, panel_alpha * 0.6)
		else:
			color = Color(0.3, 0.3, 0.3, panel_alpha * 0.4)
		canvas.draw_circle(Vector2(cx, y), dot_r, color)

	# Progress bar beneath dots
	var bar_w: float = total_w
	var bar_h: float = 4.0
	var bar_y: float = y + 12.0
	var pct: float = float(current_step_index + 1) / float(total)
	# Background bar
	canvas.draw_rect(Rect2(Vector2(start_x, bar_y), Vector2(bar_w, bar_h)), Color(0.15, 0.15, 0.15, panel_alpha * 0.6))
	# Filled bar
	if pct > 0:
		canvas.draw_rect(Rect2(Vector2(start_x, bar_y), Vector2(bar_w * pct, bar_h)), Color(accent.r, accent.g, accent.b, panel_alpha * 0.8))
	# Rounded ends
	canvas.draw_circle(Vector2(start_x + bar_w * pct, bar_y + bar_h / 2.0), bar_h / 2.0 + 1.0, Color(accent.r, accent.g, accent.b, panel_alpha * 0.8))

	# Percentage text
	var pct_text: String = "%d%%" % int(pct * 100)
	var pct_pos: Vector2 = Vector2(start_x + bar_w + 8.0, bar_y - 2.0)
	canvas.draw_string(fnt, pct_pos, pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size - 2, Color(accent.r, accent.g, accent.b, panel_alpha * 0.7))

	var step_label: String = "%s %d %s %d: %s" % [_t(s, "tutorial.step"), current_step_index + 1, _t(s, "tutorial.of"), steps.size(), step_title]
	var label_pos: Vector2 = Vector2((vp_size.x - fnt.get_string_size(step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x) / 2.0, bar_y + 18.0)
	canvas.draw_string(fnt, label_pos, step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.6, 0.6, 0.6, panel_alpha * 0.7))

	# Draw tutorial objective if present
	var objective: String = s.tutorial_data.get("objective", "")
	if objective != "":
		var obj_pos: Vector2 = Vector2((vp_size.x - fnt.get_string_size(objective, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x) / 2.0, bar_y + 34.0)
		canvas.draw_string(fnt, obj_pos, objective, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.5, 0.5, 0.7, panel_alpha * 0.6))


## Puerto del viejo tutorial_player._draw_controls_bar().
## Barra de controles siempre visible en la parte inferior de la pantalla.
func _draw_controls_bar(canvas: Control, s: Dictionary) -> void:
	var fnt: Font = s.font
	var vp_size: Vector2 = s.vp_size
	var bar_h: float = 28.0
	var bar_pos: Vector2 = Vector2(0.0, vp_size.y - bar_h)
	var alpha: float = s.panel_alpha

	# Draw semi-transparent background bar for controls
	canvas.draw_rect(Rect2(bar_pos, Vector2(vp_size.x, bar_h)), Color(0.02, 0.02, 0.06, alpha * 0.85))
	canvas.draw_rect(Rect2(bar_pos, Vector2(vp_size.x, bar_h)), Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, alpha * 0.3), false, 1.0)

	var controls_text: String
	if s.waiting_for_action:
		controls_text = "[Enter] confirmar al completar  [←] %s  [I] Índice  [G] Glosario  [H] Pista  [ESC] Saltar" % _t(s, "tutorial.previous")
	else:
		controls_text = "[Enter/Espacio] %s  [←] %s  [I] Índice  [G] Glosario  [H] Ayuda  [ESC] Saltar" % [_t(s, "tutorial.next"), _t(s, "tutorial.previous")]

	var text_w: float = fnt.get_string_size(controls_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x
	var text_x: float = (vp_size.x - text_w) / 2.0
	canvas.draw_string(fnt, Vector2(text_x, bar_pos.y + bar_h * 0.65), controls_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.8, 0.8, 0.8, alpha))


## Puerto del viejo tutorial_player._draw_hint_panel().
func _draw_hint_panel(canvas: Control, s: Dictionary, hint_text: String) -> void:
	if hint_text == "":
		return
	var fnt: Font = s.font
	var vp_size: Vector2 = s.vp_size
	var panel_w: float = min(440.0, vp_size.x - 80.0)
	var line_h: float = 16.0
	var margin: float = 12.0
	var hint_lines: PackedStringArray = hint_text.split("\n")
	var panel_h: float = hint_lines.size() * line_h + 32.0

	var panel_pos: Vector2 = Vector2(
		(vp_size.x - panel_w) / 2.0,
		s.panel_rect.position.y + s.panel_rect.size.y + (12.0 if s.waiting_for_action else 110.0)
	)

	var bg: Color = Color(0.08, 0.08, 0.18, s.panel_alpha * 0.9)
	var border: Color = Color(1.0, 0.84, 0.0, s.panel_alpha * 0.8)
	canvas.draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), bg)
	canvas.draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), border, false, 1.5)

	var label: String = "💡 %s" % _t(s, "tutorial.hint_button")
	canvas.draw_string(fnt, Vector2(panel_pos.x + margin, panel_pos.y + line_h), label, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(1.0, 0.84, 0.0, s.panel_alpha))

	for i in range(hint_lines.size()):
		canvas.draw_string(fnt, Vector2(panel_pos.x + margin, panel_pos.y + line_h * 2.0 + line_h * i), hint_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.9, 0.9, 0.9, s.panel_alpha))


## Puerto del viejo tutorial_player._draw_step_index_overlay().
func _draw_step_index_overlay(canvas: Control, s: Dictionary, summary: Array) -> void:
	var fnt: Font = s.font
	var vp_size: Vector2 = s.vp_size
	var overlay_w: float = min(360.0, vp_size.x - 60.0)
	var line_h: float = 22.0
	var margin: float = 16.0
	var overlay_h: float = summary.size() * line_h + 48.0

	var overlay_pos: Vector2 = Vector2(
		(vp_size.x - overlay_w) / 2.0,
		(vp_size.y - overlay_h) / 2.0
	)

	var bg: Color = Color(0.05, 0.05, 0.12, 0.95)
	var border: Color = Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, 0.9)
	canvas.draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), bg)
	canvas.draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), border, false, 2.0)

	var title: String = "📋 %s" % _t(s, "tutorial.index")
	canvas.draw_string(fnt, Vector2(overlay_pos.x + margin, overlay_pos.y + 16.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, s.big_font_size, Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, s.panel_alpha))

	for i in range(summary.size()):
		var item: Dictionary = summary[i]
		var is_current: bool = (i == s.current_step_index)
		var color: Color
		if is_current:
			color = Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, s.panel_alpha)
		else:
			color = Color(0.6, 0.6, 0.6, s.panel_alpha * 0.8)
		var prefix: String = "→ " if is_current else "  "
		var step_text: String = "%s%d. %s" % [prefix, i + 1, item.get("title", "")]
		canvas.draw_string(fnt, Vector2(overlay_pos.x + margin, overlay_pos.y + 38.0 + i * line_h), step_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, color)

	var close_hint: String = "[I] %s" % _t(s, "tutorial.index")
	canvas.draw_string(fnt, Vector2(overlay_pos.x + (overlay_w - fnt.get_string_size(close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x) / 2.0, overlay_pos.y + overlay_h - 10.0), close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.5, 0.5, 0.5, s.panel_alpha * 0.7))


## Puerto del viejo tutorial_player._draw_help_overlay().
## Overlay de ayuda con todos los controles del tutorial (presiona H/F1).
## Incluye el hint de cierre que el viejo _draw() dibujaba inline después.
func _draw_help_overlay(canvas: Control, s: Dictionary) -> void:
	var fnt: Font = s.font
	var vp_size: Vector2 = s.vp_size
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
	var border: Color = Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, 0.9)
	canvas.draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), bg)
	canvas.draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), border, false, 2.0)

	for i in range(help_lines.size()):
		var line_text: String = help_lines[i]
		var color: Color
		if i == 0:
			color = Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, 1.0)
		elif line_text != "":
			color = Color(0.8, 0.8, 0.8, 0.9)
		else:
			color = Color(0.5, 0.5, 0.5, 0.1)  # spacing line, nearly invisible
		canvas.draw_string(fnt, Vector2(overlay_pos.x + margin, overlay_pos.y + 18.0 + i * line_h), line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, color)

	# Show minimize hint for help overlay
	var close_hint: String = "[H / F1] Cerrar ayuda"
	var close_pos: Vector2 = Vector2((vp_size.x - fnt.get_string_size(close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x) / 2.0, vp_size.y - 8.0)
	canvas.draw_string(fnt, close_pos, close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.5, 0.5, 0.5, s.panel_alpha * 0.8))


## Puerto del viejo tutorial_player._draw_tooltip().
func _draw_tooltip(canvas: Control, s: Dictionary, tip_text: String) -> void:
	var fnt: Font = s.font
	var mouse_pos: Vector2 = s.mouse_pos
	var tip_w: float = fnt.get_string_size(tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x + 20.0
	var tip_h: float = 24.0
	var tip_pos: Vector2 = mouse_pos + Vector2(12, -tip_h - 8)

	# Keep tooltip on screen
	var vp_size: Vector2 = s.vp_size
	if tip_pos.x + tip_w > vp_size.x:
		tip_pos.x = vp_size.x - tip_w - 4.0
	if tip_pos.y < 0:
		tip_pos.y = mouse_pos.y + 16.0
	if tip_pos.x < 0:
		tip_pos.x = 4.0

	canvas.draw_rect(Rect2(tip_pos, Vector2(tip_w, tip_h)), Color(0.1, 0.1, 0.1, 0.85))
	canvas.draw_rect(Rect2(tip_pos, Vector2(tip_w, tip_h)), Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, 0.7), false, 1.0)
	canvas.draw_string(fnt, Vector2(tip_pos.x + 8.0, tip_pos.y + 16.0), tip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color.WHITE)


## Puerto del viejo tutorial_player._draw_glossary_overlay(). El estado del
## glosario (título, términos, keys ordenadas, scroll) llega resuelto en
## `glossary` porque vive en el módulo Glossary, no en el player.
func _draw_glossary_overlay(canvas: Control, s: Dictionary, glossary: Dictionary) -> void:
	var fnt: Font = s.font
	var layout: Dictionary = _glossary_overlay_layout(s.vp_size)
	var overlay: Rect2 = layout["rect"]
	var margin: float = layout["margin"]
	var line_h: float = layout["line_h"]
	var overlay_pos: Vector2 = overlay.position
	var overlay_w: float = overlay.size.x
	var overlay_h: float = overlay.size.y

	# Background
	var bg: Color = Color(0.05, 0.05, 0.12, 0.95)
	var border: Color = Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, 0.9)
	canvas.draw_rect(overlay, bg)
	canvas.draw_rect(overlay, border, false, 2.0)

	# Title
	var title: String = "📖 %s" % glossary.title
	canvas.draw_string(fnt, Vector2(overlay_pos.x + margin, overlay_pos.y + margin + 4.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, s.big_font_size, Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, 1.0))

	# Terms
	var terms: Dictionary = glossary.terms
	if terms.is_empty():
		var empty_text: String = "No hay términos definidos."
		canvas.draw_string(fnt, Vector2(overlay_pos.x + margin, overlay_pos.y + 50.0), empty_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.font_size, Color(0.7, 0.7, 0.7, 1.0))
	else:
		var sorted_keys: Array = glossary.sorted_keys

		var term_y: float = overlay_pos.y + 50.0 - glossary.scroll
		var clip_top: float = layout["clip_top"]
		var clip_bottom: float = layout["clip_bottom"]

		for term_key in sorted_keys:
			var term: Dictionary = terms[term_key]
			var definition: String = term.get("definition", "")
			var term_name: String = String(term_key).capitalize()
			var prefix: String = "▪ %s: " % term_name
			var full_text: String = prefix + definition

			# Wrap text to fit
			var max_text_w: float = overlay_w - margin * 2.0
			var wrapped_lines: Array[String] = _wrap_text(full_text, max_text_w, s.small_font_size)

			if term_y + line_h > clip_top and term_y < clip_bottom:
				canvas.draw_string(fnt, Vector2(overlay_pos.x + margin, term_y), wrapped_lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(s.accent_color.r, s.accent_color.g, s.accent_color.b, 0.95))

			term_y += line_h
			for i in range(1, wrapped_lines.size()):
				if term_y + line_h > clip_top and term_y < clip_bottom:
					canvas.draw_string(fnt, Vector2(overlay_pos.x + margin + 12.0, term_y), wrapped_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.8, 0.8, 0.8, 0.9))
				term_y += line_h

			term_y += 4.0  # Extra gap between terms

	# Close hint
	var close_text: String = "[G] Cerrar glosario  [↑↓] Desplazar"
	var close_w: float = fnt.get_string_size(close_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size).x
	canvas.draw_string(fnt, Vector2(overlay_pos.x + (overlay_w - close_w) / 2.0, overlay_pos.y + overlay_h - 10.0), close_text, HORIZONTAL_ALIGNMENT_LEFT, -1, s.small_font_size, Color(0.5, 0.5, 0.5, 0.8))
