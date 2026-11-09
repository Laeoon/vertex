class_name CinematicOverlay extends Control

## Motor Híbrido de Cinemáticas y Transmisiones de VERTEX.
## Soporta modo Codec/Terminal (silueta procedural de operador + forma de onda de voz + typewriter)
## y modo Cinemática de Red Vectorial (topología viva + ondas de choque de brecha + trazas de paquetes).

signal cinematic_finished(cinematic_id: String)
signal slide_changed(slide_idx: int)

const BrandClass = preload("res://juego/ui/brand.gd")
const CinematicRegistryClass = preload("res://juego/system/cinematic_registry.gd")

var current_cinematic: Dictionary = {}
var current_slide_idx: int = 0
var is_active: bool = false

var typewriter_progress: float = 0.0
var typewriter_speed: float = 40.0 # Caracteres por segundo
var _current_full_text: String = ""

var _time: float = 0.0
var _pulse: float = 0.0
var _voice_wave: Array[float] = []
var _voice_band_count: int = 14

# Variables para el modo Red Vectorial
var _net_nodes: Array[Dictionary] = []
var _net_edges: Array[Vector2i] = []
var _shockwaves: Array[Dictionary] = []
var _packets: Array[Dictionary] = []

var font: Font
var font_size: int = 14
var big_font_size: int = 22
var small_font_size: int = 12

var _skip_rect: Rect2 = Rect2()
var _advance_rect: Rect2 = Rect2()
var _hovered_skip: bool = false


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 8
	small_font_size = maxi(10, font_size - 3)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_voice_wave.resize(_voice_band_count)
	for i in range(_voice_band_count):
		_voice_wave[i] = 0.0
	_init_network_topology()


func _init_network_topology() -> void:
	_net_nodes.clear()
	_net_edges.clear()
	_shockwaves.clear()
	_packets.clear()

	var default_positions := [
		Vector2(0.20, 0.35),
		Vector2(0.35, 0.22),
		Vector2(0.35, 0.50),
		Vector2(0.50, 0.36),
		Vector2(0.65, 0.22),
		Vector2(0.65, 0.50),
		Vector2(0.80, 0.35),
		Vector2(0.50, 0.60),
	]
	for i in range(default_positions.size()):
		_net_nodes.append({
			"rel_pos": default_positions[i],
			"pulse": randf() * TAU,
			"breached": (i == 0 or i == 3)
		})

	var default_edges := [
		Vector2i(0, 1), Vector2i(0, 2),
		Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(3, 4), Vector2i(3, 5),
		Vector2i(4, 6), Vector2i(5, 6),
		Vector2i(2, 7), Vector2i(7, 5)
	]
	_net_edges.assign(default_edges)

	for _p in range(6):
		_spawn_packet()


func _spawn_packet() -> void:
	if _net_edges.is_empty():
		return
	var edge: Vector2i = _net_edges.pick_random()
	_packets.append({
		"edge": edge,
		"t": randf(),
		"speed": randf_range(0.3, 0.7)
	})


func play(cinematic_id: String) -> void:
	var data := CinematicRegistryClass.get_cinematic(cinematic_id)
	if data.is_empty():
		push_warning("CinematicOverlay: cinemática '%s' no encontrada." % cinematic_id)
		return
	play_cinematic_data(data)


func play_cinematic_data(data: Dictionary) -> void:
	current_cinematic = data
	current_slide_idx = 0
	is_active = true
	visible = true
	_time = 0.0
	_setup_slide(0)
	queue_redraw()


func is_playing() -> bool:
	return is_active


func _setup_slide(idx: int) -> void:
	var slides: Array = current_cinematic.get("slides", [])
	if idx < 0 or idx >= slides.size():
		close()
		return
	current_slide_idx = idx
	var slide: Dictionary = slides[idx]
	_current_full_text = slide.get("text", "")
	typewriter_progress = 0.0

	var ev_type: String = slide.get("event", "")
	if ev_type == "breach":
		_shockwaves.append({"pos": Vector2(0.5, 0.36), "radius": 10.0, "alpha": 1.0})
	elif ev_type == "pulse":
		_shockwaves.append({"pos": Vector2(0.2, 0.35), "radius": 10.0, "alpha": 1.0})

	slide_changed.emit(current_slide_idx)


func advance() -> void:
	if not is_active:
		return
	# Si el typewriter sigue escribiendo, completar la línea de golpe
	if typewriter_progress < float(_current_full_text.length()):
		typewriter_progress = float(_current_full_text.length())
		_play_sfx("click")
		queue_redraw()
		return

	# Si ya terminó de escribir, avanzar de diapositiva
	var slides: Array = current_cinematic.get("slides", [])
	if current_slide_idx + 1 < slides.size():
		_play_sfx("click")
		_setup_slide(current_slide_idx + 1)
	else:
		close()


func skip() -> void:
	close()


func close() -> void:
	if not is_active:
		return
	is_active = false
	visible = false
	var cid: String = current_cinematic.get("id", "")
	cinematic_finished.emit(cid)
	queue_redraw()


func _play_sfx(sfx_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx(sfx_name)


func _process(delta: float) -> void:
	if not is_active:
		return
	_time += delta
	_pulse += delta * 2.5

	# Actualización del typewriter
	if typewriter_progress < float(_current_full_text.length()):
		typewriter_progress = minf(typewriter_progress + typewriter_speed * delta, float(_current_full_text.length()))

	# Forma de onda de voz procedural simulada
	var is_typing := typewriter_progress < float(_current_full_text.length())
	for i in range(_voice_band_count):
		var target: float = 0.0
		if is_typing:
			var w1 := sin(_time * 16.0 + float(i) * 1.2) * 0.45
			var w2 := cos(_time * 24.0 - float(i) * 2.0) * 0.35
			target = clampf(0.3 + absf(w1 + w2), 0.1, 1.0)
		else:
			target = 0.08 + sin(_time * 3.0 + float(i) * 0.5) * 0.06
		_voice_wave[i] = lerpf(_voice_wave[i], target, delta * 12.0)

	# Actualización de paquetes de red
	for p in _packets:
		p["t"] += delta * p["speed"]
		if p["t"] > 1.0:
			p["t"] = 0.0
			if not _net_edges.is_empty():
				p["edge"] = _net_edges.pick_random()

	# Actualización de ondas de choque
	for i in range(_shockwaves.size() - 1, -1, -1):
		var sw: Dictionary = _shockwaves[i]
		sw["radius"] += delta * 180.0
		sw["alpha"] = maxf(0.0, sw["alpha"] - delta * 1.2)
		if sw["alpha"] <= 0.0:
			_shockwaves.remove_at(i)

	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	_handle_input_event(event)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	_handle_input_event(event)


func _handle_input_event(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				skip()
			KEY_ENTER, KEY_SPACE:
				get_viewport().set_input_as_handled()
				advance()

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos := (event as InputEventMouseButton).position
		if _skip_rect.has_point(mpos):
			get_viewport().set_input_as_handled()
			skip()
		else:
			get_viewport().set_input_as_handled()
			advance()

	elif event is InputEventScreenTouch and event.pressed:
		var tpos := (event as InputEventScreenTouch).position
		if _skip_rect.has_point(tpos):
			get_viewport().set_input_as_handled()
			skip()
		else:
			get_viewport().set_input_as_handled()
			advance()

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var prev_hov := _hovered_skip
		_hovered_skip = _skip_rect.has_point(mpos)
		if prev_hov != _hovered_skip:
			queue_redraw()


func _draw() -> void:
	if not is_active:
		return

	var vp := get_viewport_rect().size
	var op_id: String = current_cinematic.get("operator", "ZERO")
	var op_data := CinematicRegistryClass.get_operator(op_id)
	var theme_color: Color = op_data.get("color", BrandClass.ACCENT)

	var slides: Array = current_cinematic.get("slides", [])
	var cur_slide: Dictionary = {}
	if current_slide_idx >= 0 and current_slide_idx < slides.size():
		cur_slide = slides[current_slide_idx]

	var slide_mode: String = cur_slide.get("mode", current_cinematic.get("mode", "codec"))

	# Fondo opaco estilo terminal táctica
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.05, 0.08, 0.94))

	# Scanlines sutiles
	var scan_gap := 4.0
	var scan_col := Color(theme_color.r, theme_color.g, theme_color.b, 0.025)
	var y := 0.0
	while y < vp.y:
		draw_line(Vector2(0, y), Vector2(vp.x, y), scan_col, 1.0)
		y += scan_gap

	# Encabezado superior
	_draw_header(vp, theme_color, op_data)

	# Render según modo de diapositiva
	if slide_mode == "network":
		_draw_network_mode(vp, theme_color, cur_slide, op_data)
	else:
		_draw_codec_mode(vp, theme_color, cur_slide, op_data)

	# Barra de progreso y botón de salto
	_draw_footer(vp, theme_color, slides.size())


func _draw_header(vp: Vector2, theme_col: Color, op_data: Dictionary) -> void:
	# Barra superior
	var top_rect := Rect2(30, 20, vp.x - 60, 48)
	draw_rect(top_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
	draw_rect(top_rect, BrandClass.with_alpha(theme_col, 0.50), false, 1.5)

	# Título e indicador de transmisión
	var tag := "[ TRANSMISIÓN TÁCTICA // CANAL CLASIFICADO ]"
	draw_string(font, Vector2(50, 42), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, theme_col)

	var cin_title: String = current_cinematic.get("title", "")
	draw_string(font, Vector2(50, 58), cin_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)

	# Botón Saltar (ESC)
	_skip_rect = Rect2(vp.x - 190, 26, 150, 36)
	var skip_bg := BrandClass.with_alpha(theme_col, 0.20 if _hovered_skip else 0.08)
	var skip_border := theme_col if _hovered_skip else BrandClass.with_alpha(theme_col, 0.40)
	draw_rect(_skip_rect, skip_bg)
	draw_rect(_skip_rect, skip_border, false, 1.2)
	draw_string(font, Vector2(_skip_rect.position.x + 16, _skip_rect.position.y + 23), "[ SALTAR (ESC) ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT)


func _draw_codec_mode(vp: Vector2, theme_col: Color, slide: Dictionary, op_data: Dictionary) -> void:
	var op_id: String = op_data.get("id", "ZERO")

	# 1. Panel Izquierdo: Retrato Holográfico y Forma de Onda de Voz
	var avatar_rect := Rect2(50, 90, 260, 320)
	draw_rect(avatar_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	draw_rect(avatar_rect, BrandClass.with_alpha(theme_col, 0.60), false, 1.5)

	# Línea de barrido holográfico vertical
	var scan_y := avatar_rect.position.y + fmod(_time * 80.0, avatar_rect.size.y)
	draw_line(Vector2(avatar_rect.position.x, scan_y), Vector2(avatar_rect.position.x + avatar_rect.size.x, scan_y), BrandClass.with_alpha(theme_col, 0.35), 1.5)

	# Dibujo procedural de silueta/emblema del operador
	var avatar_center := Vector2(avatar_rect.position.x + avatar_rect.size.x * 0.5, avatar_rect.position.y + 110.0)
	_draw_operator_silhouette(avatar_center, op_id, theme_col)

	# Etiqueta de Operador
	var op_name: String = op_data.get("name", op_id)
	draw_string(font, Vector2(avatar_rect.position.x + 15, avatar_rect.position.y + 215), op_name, HORIZONTAL_ALIGNMENT_LEFT, avatar_rect.size.x - 30, font_size - 1, theme_col)

	var op_title: String = op_data.get("title", "")
	draw_string(font, Vector2(avatar_rect.position.x + 15, avatar_rect.position.y + 235), op_title, HORIZONTAL_ALIGNMENT_LEFT, avatar_rect.size.x - 30, small_font_size - 1, BrandClass.TEXT_DIM)

	var op_freq: String = op_data.get("frequency", "ENCRYPTED")
	draw_string(font, Vector2(avatar_rect.position.x + 15, avatar_rect.position.y + 255), "FREC: %s" % op_freq, HORIZONTAL_ALIGNMENT_LEFT, avatar_rect.size.x - 30, small_font_size - 1, theme_col.lightened(0.2))

	# Forma de onda de voz reactiva (barras verticales)
	var wave_y := avatar_rect.position.y + 295.0
	var wave_start_x := avatar_rect.position.x + 25.0
	var wave_w := avatar_rect.size.x - 50.0
	var bar_gap := wave_w / float(_voice_band_count)
	for i in range(_voice_band_count):
		var bar_h := _voice_wave[i] * 24.0
		var bar_x := wave_start_x + float(i) * bar_gap
		var col := BrandClass.with_alpha(theme_col, 0.4 + _voice_wave[i] * 0.6)
		draw_line(Vector2(bar_x, wave_y - bar_h * 0.5), Vector2(bar_x, wave_y + bar_h * 0.5), col, 3.0)

	# 2. Panel Derecho: Terminal de Diálogo con Typewriter
	var dialog_w := vp.x - 380.0
	var dialog_rect := Rect2(330, 90, dialog_w, 320)
	draw_rect(dialog_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	draw_rect(dialog_rect, BrandClass.with_alpha(theme_col, 0.60), false, 1.5)

	# Encabezado del mensaje
	var alert_text: String = slide.get("alert", "INTERCEPCIÓN // MENSAJE DECODIFICADO")
	draw_rect(Rect2(dialog_rect.position.x, dialog_rect.position.y, dialog_rect.size.x, 32.0), BrandClass.with_alpha(theme_col, 0.15))
	draw_line(Vector2(dialog_rect.position.x, dialog_rect.position.y + 32.0), Vector2(dialog_rect.position.x + dialog_rect.size.x, dialog_rect.position.y + 32.0), BrandClass.with_alpha(theme_col, 0.40), 1.0)
	draw_string(font, Vector2(dialog_rect.position.x + 20, dialog_rect.position.y + 22), alert_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, theme_col)

	# Texto narrativo con Typewriter
	var visible_chars := int(typewriter_progress)
	var visible_text := _current_full_text.substr(0, visible_chars)
	if visible_chars < _current_full_text.length() and fmod(_time * 4.0, 1.0) < 0.5:
		visible_text += "_"

	var wrapped_lines := _wrap_text(visible_text, font, font_size + 1, dialog_rect.size.x - 40.0)
	var text_y := dialog_rect.position.y + 65.0
	for line in wrapped_lines:
		draw_string(font, Vector2(dialog_rect.position.x + 20.0, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, BrandClass.TEXT)
		text_y += 24.0

	# Prompt de continuar
	_draw_continue_prompt(Vector2(dialog_rect.position.x + dialog_rect.size.x - 220, dialog_rect.position.y + dialog_rect.size.y - 20), theme_col)


func _draw_network_mode(vp: Vector2, theme_col: Color, slide: Dictionary, op_data: Dictionary) -> void:
	# Lienzo interactivo de Red Vectorial Viva
	var net_rect := Rect2(50, 90, vp.x - 100, 250)
	draw_rect(net_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
	draw_rect(net_rect, BrandClass.with_alpha(theme_col, 0.40), false, 1.2)

	# Dibujar enlaces de red
	for edge in _net_edges:
		if edge.x < _net_nodes.size() and edge.y < _net_nodes.size():
			var p1 := _node_to_screen(_net_nodes[edge.x]["rel_pos"], net_rect)
			var p2 := _node_to_screen(_net_nodes[edge.y]["rel_pos"], net_rect)
			draw_line(p1, p2, BrandClass.with_alpha(theme_col, 0.30), 2.0)

	# Paquetes en tránsito
	for p in _packets:
		var edge: Vector2i = p["edge"]
		if edge.x < _net_nodes.size() and edge.y < _net_nodes.size():
			var p1 := _node_to_screen(_net_nodes[edge.x]["rel_pos"], net_rect)
			var p2 := _node_to_screen(_net_nodes[edge.y]["rel_pos"], net_rect)
			var packet_pos: Vector2 = p1.lerp(p2, p["t"])
			draw_circle(packet_pos, 4.0, theme_col.lightened(0.4))

	# Ondas de choque
	for sw in _shockwaves:
		var sw_center := _node_to_screen(sw["pos"], net_rect)
		draw_circle(sw_center, sw["radius"], BrandClass.with_alpha(theme_col, sw["alpha"] * 0.6), false, 2.0)

	# Nodos de red
	for i in range(_net_nodes.size()):
		var n: Dictionary = _net_nodes[i]
		var sp := _node_to_screen(n["rel_pos"], net_rect)
		var rad: float = 8.0 + sin(_time * 3.0 + n["pulse"]) * 2.5
		var col: Color = theme_col if not n["breached"] else BrandClass.WARNING
		draw_circle(sp, rad + 4.0, BrandClass.with_alpha(col, 0.25))
		draw_circle(sp, rad, col)
		draw_circle(sp, 3.0, Color.WHITE)

	# Consola inferior de texto narrativo
	var text_rect := Rect2(50, 360, vp.x - 100, 150)
	draw_rect(text_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	draw_rect(text_rect, BrandClass.with_alpha(theme_col, 0.60), false, 1.5)

	var alert_text: String = slide.get("alert", "REGISTRO VECTORIAL // ANÁLISIS DE INCIDENTE")
	draw_string(font, Vector2(text_rect.position.x + 20, text_rect.position.y + 26), alert_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, theme_col)

	var visible_chars := int(typewriter_progress)
	var visible_text := _current_full_text.substr(0, visible_chars)
	if visible_chars < _current_full_text.length() and fmod(_time * 4.0, 1.0) < 0.5:
		visible_text += "_"

	var wrapped_lines := _wrap_text(visible_text, font, font_size + 1, text_rect.size.x - 40.0)
	var text_y := text_rect.position.y + 55.0
	for line in wrapped_lines:
		draw_string(font, Vector2(text_rect.position.x + 20.0, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, BrandClass.TEXT)
		text_y += 24.0

	_draw_continue_prompt(Vector2(text_rect.position.x + text_rect.size.x - 220, text_rect.position.y + text_rect.size.y - 18), theme_col)


func _draw_footer(vp: Vector2, theme_col: Color, total_slides: int) -> void:
	var footer_y := vp.y - 25.0
	var pips_start_x := 60.0
	var pip_w := 24.0
	var pip_gap := 8.0

	for i in range(total_slides):
		var px := pips_start_x + float(i) * (pip_w + pip_gap)
		var p_rect := Rect2(px, footer_y, pip_w, 6.0)
		if i == current_slide_idx:
			draw_rect(p_rect, theme_col)
		elif i < current_slide_idx:
			draw_rect(p_rect, BrandClass.with_alpha(theme_col, 0.5))
		else:
			draw_rect(p_rect, Color(0.2, 0.25, 0.35, 0.4))


func _draw_continue_prompt(pos: Vector2, theme_col: Color) -> void:
	var pulse_alpha := 0.5 + sin(_pulse * 1.5) * 0.4
	draw_string(font, pos, "[ ▷ CONTINUAR (ENTER/CLICK) ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.with_alpha(theme_col, pulse_alpha))


func _draw_operator_silhouette(center: Vector2, op_id: String, col: Color) -> void:
	# Dibujo procedural vectorial característico para cada operador
	match op_id:
		"ZERO":
			# Núcleo Hexagonal con glifo de Anillo 0 y corona geométrica
			for i in range(6):
				var angle1 := float(i) * TAU / 6.0 + _time * 0.2
				var angle2 := float(i + 1) * TAU / 6.0 + _time * 0.2
				var v1 := center + Vector2(cos(angle1), sin(angle1)) * 48.0
				var v2 := center + Vector2(cos(angle2), sin(angle2)) * 48.0
				draw_line(v1, v2, col, 2.5)

			# Glifo interior
			draw_circle(center, 18.0, BrandClass.with_alpha(col, 0.2))
			draw_circle(center, 12.0, col)
			draw_circle(center, 5.0, Color.WHITE)

		"VEX":
			# Capucha angular con visera horizontal dual púrpura/cian
			var points := PackedVector2Array([
				center + Vector2(-36, 45),
				center + Vector2(-42, -10),
				center + Vector2(0, -52),
				center + Vector2(42, -10),
				center + Vector2(36, 45),
				center + Vector2(0, 30)
			])
			draw_polyline(points, col, 2.5)

			# Ranura de visera horizontal
			draw_line(center + Vector2(-26, -5), center + Vector2(26, -5), col.lightened(0.5), 3.5)
			draw_line(center + Vector2(-18, 5), center + Vector2(18, 5), col, 2.0)

		"N0X":
			# Máscara/Cráneo terminal con ojos de matriz y glitch
			var head_pts := PackedVector2Array([
				center + Vector2(-30, -35),
				center + Vector2(30, -35),
				center + Vector2(35, 10),
				center + Vector2(20, 42),
				center + Vector2(-20, 42),
				center + Vector2(-35, 10),
				center + Vector2(-30, -35)
			])
			draw_polyline(head_pts, col, 2.5)

			# Ojos de sensor terminal
			draw_rect(Rect2(center.x - 22, center.y - 12, 14, 10), col)
			draw_rect(Rect2(center.x + 8, center.y - 12, 14, 10), col)
			# Dientes de conector
			for t in range(4):
				var tx := center.x - 14.0 + float(t) * 9.0
				draw_line(Vector2(tx, center.y + 24), Vector2(tx, center.y + 36), col, 2.0)

		"AEGIS":
			# Escudo crestado de alta tecnología con núcleo centinela
			var shield_pts := PackedVector2Array([
				center + Vector2(0, -50),
				center + Vector2(40, -30),
				center + Vector2(32, 20),
				center + Vector2(0, 52),
				center + Vector2(-32, 20),
				center + Vector2(-40, -30),
				center + Vector2(0, -50)
			])
			draw_polyline(shield_pts, col, 2.5)

			# Cruz / Diamante centinela interior
			draw_line(center + Vector2(0, -25), center + Vector2(0, 25), col.lightened(0.3), 3.0)
			draw_line(center + Vector2(-20, 0), center + Vector2(20, 0), col.lightened(0.3), 3.0)
			draw_circle(center, 7.0, Color.WHITE)

		_:
			draw_circle(center, 35.0, col)


func _node_to_screen(rel_pos: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		rect.position.x + rel_pos.x * rect.size.x,
		rect.position.y + rel_pos.y * rect.size.y
	)


func _wrap_text(text: String, p_font: Font, p_size: int, max_w: float) -> Array[String]:
	if text.is_empty():
		return [""]
	var f := p_font
	if f == null:
		f = BrandClass.font_regular()
	var words := text.split(" ")
	var lines: Array[String] = []
	var cur := ""

	for w in words:
		var candidate := cur + (" " if not cur.is_empty() else "") + w
		if f.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, p_size).x > max_w:
			if not cur.is_empty():
				lines.append(cur)
				cur = w
			else:
				lines.append(candidate)
				cur = ""
		else:
			cur = candidate

	if not cur.is_empty():
		lines.append(cur)
	return lines
