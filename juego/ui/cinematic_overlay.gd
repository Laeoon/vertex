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


func _input(event: InputEvent) -> void:
	if not is_active:
		return
	_handle_input_event(event)


func _gui_input(_event: InputEvent) -> void:
	pass


func _unhandled_input(_event: InputEvent) -> void:
	pass


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
	# Barra superior de frecuencia Codec
	var top_rect := Rect2(30, 14, vp.x - 60, 40)
	draw_rect(top_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.92))
	draw_rect(top_rect, BrandClass.with_alpha(theme_col, 0.45), false, 1.2)

	# Frecuencia táctica MGS Codec
	var freq: String = current_cinematic.get("frequency", op_data.get("frequency", "140.85 MHz"))
	var tag := "[ BURST CODEC // FREQ %s — ENCRYPTED CHANNEL ]" % freq
	draw_string(font, Vector2(50, 39), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, theme_col)

	# Barras de señal de radio animadas
	var sig_x := 50.0 + font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x + 16.0
	for b in range(5):
		var bar_h := 6.0 + float(b) * 3.0
		var bar_pulse := 0.4 + sin(_pulse * 2.5 + float(b) * 0.8) * 0.3
		var b_col := BrandClass.with_alpha(BrandClass.SUCCESS, bar_pulse)
		draw_rect(Rect2(sig_x + float(b) * 6.0, 39.0 - bar_h, 3.5, bar_h), b_col)

	# Botón Saltar Transmisión (ESC)
	_skip_rect = Rect2(vp.x - 225, 17, 185, 34)
	var skip_bg := BrandClass.with_alpha(theme_col, 0.20 if _hovered_skip else 0.08)
	var skip_border := theme_col if _hovered_skip else BrandClass.with_alpha(theme_col, 0.40)
	draw_rect(_skip_rect, skip_bg)
	draw_rect(_skip_rect, skip_border, false, 1.2)
	draw_string(font, Vector2(_skip_rect.position.x + 12, _skip_rect.position.y + 22), "[ ESC ] SALTAR TRANSMISIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 1, BrandClass.TEXT)


func _draw_codec_mode(vp: Vector2, theme_col: Color, slide: Dictionary, op_data: Dictionary) -> void:
	var top_y := 62.0
	var portrait_w := 210.0
	var portrait_h := 220.0

	var left_rect := Rect2(30.0, top_y, portrait_w, portrait_h)
	var right_rect := Rect2(vp.x - 30.0 - portrait_w, top_y, portrait_w, portrait_h)
	var center_x := left_rect.position.x + portrait_w + 14.0
	var center_w := right_rect.position.x - center_x - 14.0
	var center_rect := Rect2(center_x, top_y, center_w, portrait_h)

	var op_id: String = op_data.get("id", "VEX")

	# 1. Caller / Handler (Panel Izquierdo)
	var caller_id: String = slide.get("caller", current_cinematic.get("caller", ""))
	if caller_id.is_empty():
		match op_id:
			"VEX": caller_id = "EXFIL"
			"N0X": caller_id = "FUZZ"
			"AEGIS": caller_id = "CORDON"
			_: caller_id = "KAIN"

	var caller_data := CinematicRegistryClass.get_operator(caller_id)
	var caller_col: Color = caller_data.get("color", Color("ff4757"))

	var speaker_str: String = slide.get("speaker", "")
	var is_caller_speaking := (speaker_str == caller_id or speaker_str == "KAIN" or speaker_str == "ZERO" or speaker_str.begins_with("DAEMON") or speaker_str.begins_with("ARCHITECT"))
	var is_op_speaking := not is_caller_speaking

	# Marco Izquierdo (Caller / Handler)
	draw_rect(left_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	var left_border_col := caller_col if is_caller_speaking else BrandClass.with_alpha(caller_col, 0.45)
	draw_rect(left_rect, left_border_col, false, 2.2 if is_caller_speaking else 1.2)
	if is_caller_speaking:
		draw_rect(left_rect.grow(3.0), BrandClass.with_alpha(caller_col, 0.35 * (0.8 + sin(_pulse * 2.0) * 0.2)), false, 1.8)

	_draw_corner_brackets(left_rect, caller_col)

	# Banner superior izquierdo
	draw_rect(Rect2(left_rect.position.x, left_rect.position.y, left_rect.size.x, 22), BrandClass.with_alpha(caller_col, 0.18))
	draw_string(font, Vector2(left_rect.position.x + 8, left_rect.position.y + 16), "[ INCOMING // CALLER ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, caller_col)

	var left_center := Vector2(left_rect.position.x + left_rect.size.x * 0.5, left_rect.position.y + 98.0)
	if caller_id == "KAIN" or caller_id == "ZERO":
		_draw_wireframe_node_face(left_center, caller_col, is_caller_speaking)
	else:
		_draw_operator_silhouette(left_center, caller_id, caller_col)

	# Scanline vertical en el retrato izquierdo
	var l_scan_y := left_rect.position.y + fmod(_time * 70.0, left_rect.size.y)
	draw_line(Vector2(left_rect.position.x, l_scan_y), Vector2(left_rect.position.x + left_rect.size.x, l_scan_y), BrandClass.with_alpha(caller_col, 0.30), 1.2)

	# Info caller
	var c_name: String = caller_data.get("name", caller_id)
	draw_string(font, Vector2(left_rect.position.x + 8, left_rect.position.y + 185), c_name, HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x - 16, small_font_size - 1, caller_col)
	var c_title: String = caller_data.get("title", "")
	draw_string(font, Vector2(left_rect.position.x + 8, left_rect.position.y + 203), c_title, HORIZONTAL_ALIGNMENT_LEFT, left_rect.size.x - 16, small_font_size - 3, BrandClass.TEXT_DIM)

	# 2. Marco Derecho (Operador Local)
	draw_rect(right_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	var right_border_col := theme_col if is_op_speaking else BrandClass.with_alpha(theme_col, 0.45)
	draw_rect(right_rect, right_border_col, false, 2.2 if is_op_speaking else 1.2)
	if is_op_speaking:
		draw_rect(right_rect.grow(3.0), BrandClass.with_alpha(theme_col, 0.35 * (0.8 + sin(_pulse * 2.0) * 0.2)), false, 1.8)

	_draw_corner_brackets(right_rect, theme_col)

	# Banner superior derecho
	draw_rect(Rect2(right_rect.position.x, right_rect.position.y, right_rect.size.x, 22), BrandClass.with_alpha(theme_col, 0.18))
	draw_string(font, Vector2(right_rect.position.x + 8, right_rect.position.y + 16), "[ OPERADOR // LOCAL ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, theme_col)

	var right_center := Vector2(right_rect.position.x + right_rect.size.x * 0.5, right_rect.position.y + 98.0)
	_draw_operator_silhouette(right_center, op_id, theme_col)

	# Scanline vertical en el retrato derecho
	var r_scan_y := right_rect.position.y + fmod(_time * 85.0, right_rect.size.y)
	draw_line(Vector2(right_rect.position.x, r_scan_y), Vector2(right_rect.position.x + right_rect.size.x, r_scan_y), BrandClass.with_alpha(theme_col, 0.30), 1.2)

	# Info operador
	var op_name: String = op_data.get("name", op_id)
	draw_string(font, Vector2(right_rect.position.x + 8, right_rect.position.y + 185), op_name, HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 16, small_font_size - 1, theme_col)
	var op_title: String = op_data.get("title", "")
	draw_string(font, Vector2(right_rect.position.x + 8, right_rect.position.y + 203), op_title, HORIZONTAL_ALIGNMENT_LEFT, right_rect.size.x - 16, small_font_size - 3, BrandClass.TEXT_DIM)

	# 3. Monitor Táctico Central (Entre ambos retratos)
	draw_rect(center_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.93))
	draw_rect(center_rect, BrandClass.with_alpha(theme_col, 0.45), false, 1.2)
	_draw_corner_brackets(center_rect, theme_col)

	# Banner del monitor táctico
	draw_rect(Rect2(center_rect.position.x, center_rect.position.y, center_rect.size.x, 22), BrandClass.with_alpha(theme_col, 0.15))
	draw_string(font, Vector2(center_rect.position.x + 10, center_rect.position.y + 16), "[ MONITOR TÁCTICO // TELEMETRÍA FORENSE ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, theme_col)
	var live_pip_col := BrandClass.with_alpha(BrandClass.SUCCESS, 0.5 + sin(_pulse * 3.0) * 0.5)
	draw_string(font, Vector2(center_rect.position.x + center_rect.size.x - 70, center_rect.position.y + 16), "● LIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, live_pip_col)

	# Oscilador de voz central en tiempo real
	var osc_y := center_rect.position.y + 54.0
	var osc_start_x := center_rect.position.x + 18.0
	var osc_w := center_rect.size.x - 36.0
	var osc_pts := 50
	var osc_dx := osc_w / float(osc_pts - 1)
	var is_typing := typewriter_progress < float(_current_full_text.length())
	var osc_amp := 18.0 if is_typing else 4.0

	var wave_pts: PackedVector2Array = PackedVector2Array()
	for p in range(osc_pts):
		var pt_t := float(p) / float(osc_pts - 1)
		var wy := osc_y + sin(_time * 14.0 + pt_t * 18.0) * osc_amp * sin(pt_t * PI)
		if is_typing:
			wy += cos(_time * 22.0 - pt_t * 28.0) * (osc_amp * 0.45)
		wave_pts.append(Vector2(osc_start_x + float(p) * osc_dx, wy))

	var active_speaker_col := caller_col if is_caller_speaking else theme_col
	draw_polyline(wave_pts, BrandClass.with_alpha(active_speaker_col, 0.25), 4.5)
	draw_polyline(wave_pts, active_speaker_col, 1.8)

	# Mini red topológica animada en el monitor central (mitad inferior)
	var net_y_start := center_rect.position.y + 75.0
	var mini_net_rect := Rect2(center_rect.position.x + 14.0, net_y_start, center_rect.size.x * 0.60, center_rect.size.y - (net_y_start - center_rect.position.y) - 10.0)

	for edge in _net_edges:
		if edge.x < _net_nodes.size() and edge.y < _net_nodes.size():
			var p1 := _node_to_screen(_net_nodes[edge.x]["rel_pos"], mini_net_rect)
			var p2 := _node_to_screen(_net_nodes[edge.y]["rel_pos"], mini_net_rect)
			draw_line(p1, p2, BrandClass.with_alpha(theme_col, 0.25), 1.2)

	for p in _packets:
		var edge: Vector2i = p["edge"]
		if edge.x < _net_nodes.size() and edge.y < _net_nodes.size():
			var p1 := _node_to_screen(_net_nodes[edge.x]["rel_pos"], mini_net_rect)
			var p2 := _node_to_screen(_net_nodes[edge.y]["rel_pos"], mini_net_rect)
			var p_pos: Vector2 = p1.lerp(p2, p["t"])
			draw_circle(p_pos, 2.5, active_speaker_col)

	for i in range(_net_nodes.size()):
		var n: Dictionary = _net_nodes[i]
		var sp := _node_to_screen(n["rel_pos"], mini_net_rect)
		var rad: float = 4.5 + sin(_time * 2.5 + n["pulse"]) * 1.5
		draw_circle(sp, rad, BrandClass.with_alpha(theme_col, 0.35))
		draw_circle(sp, 2.0, theme_col)

	# Telemetría forense a la derecha dentro del monitor
	var tel_x := center_rect.position.x + center_rect.size.x * 0.64
	var tel_y := net_y_start + 14.0
	var tel_lines := [
		"ROUTE: BGP_PEERING_0x00",
		"CIPHER: AES-256-GCM",
		"MIN_CUT: EDMONDS_KARP",
		"PACKET_LOSS: 0.00%",
		"LATENCY: 9.4 ms",
		"TRACE: GENESIS_SHARD"
	]
	for tl in tel_lines:
		draw_string(font, Vector2(tel_x, tel_y), tl, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 3, BrandClass.TEXT_DIM)
		tel_y += 16.0

	# 4. Consola Inferior: Caja de Subtítulos Voice-Over
	var sub_y := top_y + portrait_h + 14.0
	var sub_h := maxf(120.0, vp.y - sub_y - 20.0)
	var sub_rect := Rect2(30.0, sub_y, vp.x - 60.0, sub_h)

	draw_rect(sub_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.96))
	draw_rect(sub_rect, BrandClass.with_alpha(theme_col, 0.70), false, 1.5)
	_draw_corner_brackets(sub_rect, theme_col)

	# Barra de encabezado del subtítulo
	draw_rect(Rect2(sub_rect.position.x, sub_rect.position.y, sub_rect.size.x, 26.0), BrandClass.with_alpha(theme_col, 0.16))
	draw_line(Vector2(sub_rect.position.x, sub_rect.position.y + 26.0), Vector2(sub_rect.position.x + sub_rect.size.x, sub_rect.position.y + 26.0), BrandClass.with_alpha(theme_col, 0.40), 1.0)

	var spk_label := "[ %s // LOG ]:" % (speaker_str if not speaker_str.is_empty() else op_id)
	var spk_col := caller_col if is_caller_speaking else theme_col
	draw_string(font, Vector2(sub_rect.position.x + 16, sub_rect.position.y + 18), spk_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, spk_col)

	var slides: Array = current_cinematic.get("slides", [])
	var prog_str := "[ TRANSMISIÓN %d/%d ]" % [current_slide_idx + 1, slides.size()]
	draw_string(font, Vector2(sub_rect.position.x + sub_rect.size.x - 160, sub_rect.position.y + 18), prog_str, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 1, BrandClass.TEXT_DIM)

	# Diálogo narrativo con typewriter
	var visible_chars := int(typewriter_progress)
	var visible_text := _current_full_text.substr(0, visible_chars)
	if visible_chars < _current_full_text.length() and fmod(_time * 4.0, 1.0) < 0.5:
		visible_text += "_"

	var wrapped_lines := _wrap_text(visible_text, font, font_size, sub_rect.size.x - 40.0)
	var text_y := sub_rect.position.y + 50.0
	for line in wrapped_lines:
		draw_string(font, Vector2(sub_rect.position.x + 16.0, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)
		text_y += 20.0

	# Prompts de acción en la base del subtítulo
	draw_string(font, Vector2(sub_rect.position.x + 16, sub_rect.position.y + sub_rect.size.y - 12), "[ ESC ] SALTAR TRANSMISIÓN", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, BrandClass.TEXT_DIM)
	_draw_continue_prompt(Vector2(sub_rect.position.x + sub_rect.size.x - 240, sub_rect.position.y + sub_rect.size.y - 12), theme_col)


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

		"KAIN":
			# Cara wireframe o glifo de purga de Anillo 0
			_draw_wireframe_node_face(center, col, true)

		"DAEMON_EXFIL":
			# Escudo hexagonal segmentado con barras de exfiltración
			var hex_pts := PackedVector2Array()
			for i in range(6):
				var a := float(i) * TAU / 6.0
				hex_pts.append(center + Vector2(cos(a), sin(a)) * 36.0)
			hex_pts.append(hex_pts[0])
			draw_polyline(hex_pts, col, 2.0)
			# Barras verticales interiores
			for b in range(-2, 3):
				var bx := center.x + float(b) * 8.0
				var by_len := 22.0 - absf(float(b)) * 4.0
				draw_line(Vector2(bx, center.y - by_len), Vector2(bx, center.y + by_len), col.lightened(0.3), 2.0)

		"DAEMON_FUZZ":
			# Ojo mutador con corona de dientes fuzzer
			draw_circle(center, 28.0, BrandClass.with_alpha(col, 0.15))
			draw_arc(center, 30.0, 0.0, TAU, 16, col, 2.0)
			draw_arc(center, 18.0, 0.0, TAU, 12, col.lightened(0.4), 1.5)
			# Aspas diagonales
			for d in range(4):
				var a := float(d) * TAU / 4.0 + _time * 1.5
				draw_line(center + Vector2(cos(a), sin(a)) * 12.0, center + Vector2(cos(a), sin(a)) * 38.0, col, 2.0)

		"DAEMON_CORDON":
			# Tres octágonos concéntricos y mira centinela
			draw_arc(center, 32.0, 0.0, TAU, 8, col, 2.0)
			draw_arc(center, 22.0, 0.0, TAU, 8, col.lightened(0.3), 1.5)
			draw_line(center - Vector2(36, 0), center + Vector2(36, 0), col, 1.5)
			draw_line(center - Vector2(0, 36), center + Vector2(0, 36), col, 1.5)
			draw_circle(center, 4.0, Color.WHITE)

		_:
			draw_circle(center, 35.0, col)


func _draw_wireframe_node_face(center: Vector2, col: Color, is_speaking: bool) -> void:
	var yaw: float = sin(_time * 0.9) * 0.22
	var pitch: float = cos(_time * 0.6) * 0.10
	var jitter: Vector2 = Vector2.ZERO
	if is_speaking:
		jitter = Vector2(randf_range(-1.2, 1.2), randf_range(-1.2, 1.2))

	var raw_v: Array[Vector3] = [
		Vector3(0.0, -1.3, 0.2),   # 0: barbilla
		Vector3(-0.7, -0.7, 0.3),  # 1: mandíbula izq
		Vector3(0.7, -0.7, 0.3),   # 2: mandíbula der
		Vector3(-0.85, 0.0, 0.1),  # 3: pómulo izq
		Vector3(0.85, 0.0, 0.1),   # 4: pómulo der
		Vector3(-0.45, 0.65, 0.35),# 5: ceja izq
		Vector3(0.45, 0.65, 0.35), # 6: ceja der
		Vector3(0.0, 1.1, 0.2),    # 7: frente
		Vector3(0.0, 0.0, 0.7),    # 8: punta de nariz
		Vector3(-0.35, 0.2, 0.4),  # 9: ojo izq
		Vector3(0.35, 0.2, 0.4),   # 10: ojo der
		Vector3(0.0, -0.55, 0.45), # 11: boca
	]

	var edges: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3), Vector2i(2, 4),
		Vector2i(3, 5), Vector2i(4, 6), Vector2i(5, 7), Vector2i(6, 7),
		Vector2i(0, 11), Vector2i(11, 8), Vector2i(8, 9), Vector2i(8, 10),
		Vector2i(9, 5), Vector2i(10, 6), Vector2i(9, 3), Vector2i(10, 4),
		Vector2i(1, 11), Vector2i(2, 11), Vector2i(5, 6), Vector2i(9, 10)
	]

	var proj_pts: Array[Vector2] = []
	var cos_y: float = cos(yaw)
	var sin_y: float = sin(yaw)
	var cos_x: float = cos(pitch)
	var sin_x: float = sin(pitch)

	for v: Vector3 in raw_v:
		var x1: float = v.x * cos_y + v.z * sin_y
		var z1: float = -v.x * sin_y + v.z * cos_y
		var y2: float = v.y * cos_x - z1 * sin_x
		var z2: float = v.y * sin_x + z1 * cos_x
		var scale_3d: float = 36.0 * (1.0 + z2 * 0.18)
		var pt: Vector2 = center + Vector2(x1 * scale_3d, -y2 * scale_3d) + jitter
		proj_pts.append(pt)

	var line_col: Color = BrandClass.with_alpha(col, 0.85 if is_speaking else 0.50)
	for e in edges:
		if e.x < proj_pts.size() and e.y < proj_pts.size():
			draw_line(proj_pts[e.x], proj_pts[e.y], line_col, 1.4)

	for pt in proj_pts:
		draw_circle(pt, 3.0, col)
		draw_circle(pt, 1.2, Color.WHITE)


func _draw_corner_brackets(rect: Rect2, col: Color) -> void:
	var sz := 10.0
	var c_col := BrandClass.with_alpha(col, 0.75)
	# TL
	draw_line(rect.position, rect.position + Vector2(sz, 0), c_col, 1.8)
	draw_line(rect.position, rect.position + Vector2(0, sz), c_col, 1.8)
	# TR
	draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x - sz, rect.position.y), c_col, 1.8)
	draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + sz), c_col, 1.8)
	# BL
	draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x + sz, rect.position.y + rect.size.y), c_col, 1.8)
	draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x, rect.position.y + rect.size.y - sz), c_col, 1.8)
	# BR
	draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(sz, 0), c_col, 1.8)
	draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(0, sz), c_col, 1.8)



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
