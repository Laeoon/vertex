class_name GameOverOverlay
extends Control

## Capa 2b — Pantalla COMPLETA de fin de partida.
##
## Reemplaza al panel dibujado por GameRenderer (draw_game_over /
## draw_defender_game_over): ahora TODO el contenido vive acá, dibujado por
## código con _draw + _process (fondo animado procedural) + nodos de UI
## (título grande, mensaje_estado, estrellas ★★★ y fila de botones).
##
## Mantiene las 4 señales y la matriz de visibilidad de [N] de la capa 2:
##   [N] sólo con victoria Y nivel siguiente disponible (has_next false en
##   tutoriales/level_key desconocido). El teclado entra por InputHandler;
##   el mouse por acá — ambos caen en los mismos handlers de juego_ataque.gd.
##
## Fondos:
##   · Victoria → "terminal hacker": lluvia de glifos cayendo + scanlines.
##   · Derrota  → "capturado": viñeta roja que se cierra + franjas de peligro.

signal retry_pressed
signal next_pressed
signal select_pressed
signal menu_pressed

const BrandClass = preload("res://juego/ui/brand.gd")

const BTN_GAP := 12.0
const BTN_CONTENT_MARGIN := 14.0
## Botones debajo del título/mensaje/estrellas (centro vertical del viewport).
const ROW_OFFSET_Y := 140.0

const FADE_DURATION := 0.45
const TITLE_SHAKE_DURATION := 0.6

## Lluvia de glifos (victoria): caracteres del "terminal hacker".
const GLYPHS := "01<>/\\[]{}#@*=+-|%$&ß§∆ƒ¬↑↓→←°"
## Semilla fija → fondo determinístico entre runs (no parpadea distinto).
const RAIN_SEED := 0x5EED
const RAIN_COLUMNS := 64
const RAIN_CELL := 18.0
const SCANLINE_STEP := 3

var retry_button: Button
var next_button: Button
var select_button: Button
var menu_button: Button

var _panel: PanelContainer
var _row: HBoxContainer
var _panel_style_win: StyleBoxFlat
var _panel_style_lose: StyleBoxFlat

var _title_label: Label
var _message_label: Label
var _stars_label: Label

## Estado del fondo (flag win/lose) — los tests lo leen sin mirar píxeles.
var _is_win: bool = false
var _is_lose: bool = false

## Lluvia de glifos (victoria): una cadena por columna + velocidad + y actual.
var _rain_cols: PackedStringArray = []
var _rain_speed: PackedFloat32Array = []
var _rain_y: PackedFloat32Array = []

## Tiempo de entrada para el fade y el temblor del título.
var _shown_time_ms: int = 0
var _tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


## Muestra el overlay a pantalla completa con fade de entrada.
##   game_won   — victoria (fondo hacker) o derrota (fondo captura).
##   has_next   — muestra [N] Siguiente.
##   defender   — sólo discrimina el modo en el log (matriz idéntica).
##   mensaje    — texto bajo el título (mensaje_estado del frame).
##   stars      — 0..3 estrellas (solo se dibujan en victoria).
##
## TODO(AudioManager): enganche futuro de música según resultado — pista de
## victoria (ambient hacker ascendente) vs derrota (tensión/captura). Hoy no
## hay audio; este comentario marca el punto exacto de integración.
func show_overlay(
	game_won: bool,
	has_next: bool,
	defender: bool,
	mensaje: String = "",
	stars: int = 0
) -> void:
	_is_win = game_won
	_is_lose = not game_won
	_shown_time_ms = Time.get_ticks_msec()

	next_button.visible = game_won and has_next
	_panel.add_theme_stylebox_override(
		"panel", _panel_style_win if game_won else _panel_style_lose
	)

	_apply_title(game_won, defender)
	_message_label.text = mensaje
	_message_label.visible = mensaje != ""
	if game_won:
		var star_text: String = ""
		for i in range(3):
			star_text += "★" if i < stars else "☆"
		_stars_label.text = star_text
		_stars_label.visible = true
	else:
		_stars_label.visible = false

	# Fade de entrada sobre modulate:a (0 → 1).
	modulate.a = 0.0
	visible = true
	_layout_content()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

	queue_redraw()
	retry_button.grab_focus()
	GameLogger.info(
		"GameOverOverlay",
		"game over: %s%s" % ["victoria" if game_won else "derrota", " (defensor)" if defender else ""]
	)


func hide_overlay() -> void:
	visible = false
	_is_win = false
	_is_lose = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate.a = 1.0


func _process(delta: float) -> void:
	if not visible:
		return
	# Avance determinístico de la lluvia de glifos (solo victoria).
	# FIX auditoría: usar el delta DEL FRAME — acumular con el tiempo desde
	# show() aceleraba la lluvia cuadráticamente hasta tapar la pantalla.
	if _is_win:
		for i in RAIN_COLUMNS:
			_rain_y[i] += _rain_speed[i] * 60.0 * delta
	queue_redraw()


func _draw() -> void:
	if _is_win:
		_draw_win_background()
	elif _is_lose:
		_draw_lose_background()


# ─── Fondos procedurales ────────────────────────────────────────────

## FONDO VICTORIA — "terminal hacker": lluvia de glifos + scanlines.
func _draw_win_background() -> void:
	var vp: Vector2 = get_viewport_rect().size

	# Fondo base: BG con alpha bajo para que la lluvia respire.
	draw_rect(Rect2(Vector2.ZERO, vp), BrandClass.with_alpha(BrandClass.BG, 0.92))

	# Lluvia de glifos: columnas fijas, cada una con su velocidad y offset.
	var col_w: float = vp.x / float(RAIN_COLUMNS)
	for i in RAIN_COLUMNS:
		var x: float = i * col_w
		var y: float = _rain_y[i]
		# Wrap vertical: cuando la columna sale del viewport, reinicia arriba.
		while y > vp.y + RAIN_CELL:
			y -= vp.y + RAIN_CELL * 2.0
			_rain_y[i] = y
		var col_str: String = _rain_cols[i]
		for ch_idx in col_str.length():
			var gy: float = y - float(ch_idx) * RAIN_CELL
			if gy < -RAIN_CELL or gy > vp.y:
				continue
			# El "head" del trailing es más brillante; la cola decae.
			var head_alpha: float = 1.0 if ch_idx == 0 else maxf(0.0, 1.0 - float(ch_idx) * 0.18)
			var c: Color = BrandClass.with_alpha(BrandClass.SUCCESS, head_alpha * 0.85)
			draw_string(
				BrandClass.font_regular(),
				Vector2(x + 2.0, gy),
				col_str[ch_idx],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, c
			)

	# Scanlines sutiles (bandas horizontales tenues).
	for sy in range(0, int(vp.y), SCANLINE_STEP):
		draw_rect(
			Rect2(0, sy, vp.x, 1),
			BrandClass.with_alpha(BrandClass.SUCCESS, 0.04),
			true
		)


## FONDO DERROTA — "capturado": viñeta roja que se cierra + franjas de peligro.
func _draw_lose_background() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var elapsed: float = (Time.get_ticks_msec() - _shown_time_ms) / 1000.0

	# Fondo base oscuro-rojizo.
	draw_rect(Rect2(Vector2.ZERO, vp), BrandClass.with_alpha(BrandClass.BG, 0.94))

	# Viñeta roja que se cierra: alpha creciente desde los bordes hacia el centro.
	# Rects concéntricos con alpha decreciente hacia afuera.
	var close_t: float = clampf(elapsed / 1.2, 0.0, 1.0)
	var max_alpha: float = 0.55 * close_t
	var steps: int = 8
	for s in range(steps):
		var t: float = float(s) / float(steps)
		var inset: float = t * minf(vp.x, vp.y) * 0.5
		var a: float = max_alpha * (1.0 - t)
		draw_rect(
			Rect2(inset, inset, vp.x - inset * 2.0, vp.y - inset * 2.0),
			BrandClass.with_alpha(BrandClass.DANGER, a * 0.5),
			true
		)

	# Franjas de peligro diagonales (arriba y abajo) — WARNING/DANGER.
	var stripe_h: float = 28.0
	var pulse: float = 0.5 + sin(elapsed * 2.0) * 0.3
	_draw_danger_stripes(vp, stripe_h, true, pulse)
	_draw_danger_stripes(vp, stripe_h, false, pulse)

	# Pulso lento de brillo sobre todo el viewport.
	var glow: float = 0.05 + sin(elapsed * 1.5) * 0.03
	draw_rect(
		Rect2(Vector2.ZERO, vp),
		BrandClass.with_alpha(BrandClass.DANGER, glow),
		true
	)


func _draw_danger_stripes(vp: Vector2, h: float, top: bool, pulse: float) -> void:
	# Bandas diagonales alternando WARNING/DANGER (estilo "cinta de peligro").
	var y0: float = 0.0 if top else vp.y - h
	var stripe_w: float = 24.0
	var col_a: Color = BrandClass.with_alpha(BrandClass.WARNING, 0.25 * pulse + 0.1)
	var col_b: Color = BrandClass.with_alpha(BrandClass.DANGER, 0.25 * pulse + 0.1)
	var x: float = -h
	var i: int = 0
	while x < vp.x + h:
		var pts := PackedVector2Array()
		if top:
			pts.append(Vector2(x, y0))
			pts.append(Vector2(x + stripe_w, y0))
			pts.append(Vector2(x + stripe_w + h, y0 + h))
			pts.append(Vector2(x + h, y0 + h))
		else:
			pts.append(Vector2(x, y0 + h))
			pts.append(Vector2(x + stripe_w, y0 + h))
			pts.append(Vector2(x + stripe_w + h, y0))
			pts.append(Vector2(x + h, y0))
		draw_colored_polygon(pts, col_a if i % 2 == 0 else col_b)
		x += stripe_w * 2.0
		i += 1


# ─── Build de nodos de UI ────────────────────────────────────────────

func _build() -> void:
	_panel_style_win = _make_panel_style(BrandClass.SUCCESS)
	_panel_style_lose = _make_panel_style(BrandClass.DANGER)

	# Título grande.
	_title_label = Label.new()
	_title_label.add_theme_font_override("font", BrandClass.font_bold())
	_title_label.add_theme_font_size_override("font_size", 56)
	_title_label.add_theme_color_override("font_color", BrandClass.SUCCESS)
	_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)

	# Mensaje de estado.
	_message_label = Label.new()
	_message_label.add_theme_font_override("font", BrandClass.font_regular())
	_message_label.add_theme_font_size_override("font_size", 16)
	_message_label.add_theme_color_override("font_color", BrandClass.TEXT)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message_label)

	# Estrellas ★★★.
	_stars_label = Label.new()
	_stars_label.add_theme_font_override("font", BrandClass.font_bold())
	_stars_label.add_theme_font_size_override("font_size", 40)
	_stars_label.add_theme_color_override("font_color", BrandClass.WARNING)
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stars_label)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _panel_style_lose)
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_panel)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", BTN_GAP)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_row)

	retry_button = _make_button("[R] Reintentar", retry_pressed)
	next_button = _make_button("[N] Siguiente", next_pressed)
	select_button = _make_button("[L] Niveles", select_pressed)
	menu_button = _make_button("[Q] Menú", menu_pressed)
	_row.add_child(retry_button)
	_row.add_child(next_button)
	_row.add_child(select_button)
	_row.add_child(menu_button)
	_wire_focus_neighbors()

	_init_rain()
	resized.connect(_layout_content)


func _init_rain() -> void:
	_rain_cols = PackedStringArray()
	_rain_cols.resize(RAIN_COLUMNS)
	_rain_speed = PackedFloat32Array()
	_rain_speed.resize(RAIN_COLUMNS)
	_rain_y = PackedFloat32Array()
	_rain_y.resize(RAIN_COLUMNS)
	var rng := RandomNumberGenerator.new()
	rng.seed = RAIN_SEED
	var vp_h: float = vp_fallback_y()
	for i in RAIN_COLUMNS:
		var length: int = rng.randi_range(8, 22)
		var s: String = ""
		for _j in length:
			s += GLYPHS[rng.randi_range(0, GLYPHS.length() - 1)]
		_rain_cols[i] = s
		_rain_speed[i] = rng.randf_range(0.6, 2.2)
		_rain_y[i] = rng.randf_range(-vp_h, 0.0)


func vp_fallback_y() -> float:
	if is_inside_tree():
		return get_viewport_rect().size.y
	return 720.0


func _apply_title(game_won: bool, defender: bool) -> void:
	if not game_won:
		_title_label.text = "CAPTURADO"
		_title_label.add_theme_color_override("font_color", BrandClass.DANGER)
		return
	# Victoria: defender → "VICTORIA DEFENSIVA"; el resto → "VICTORIA".
	# (El caso "TUTORIAL COMPLETADO" lo dispara el caller vía
	# set_tutorial_title(), porque el overlay no conoce level_key.)
	if defender:
		_title_label.text = "VICTORIA DEFENSIVA"
		_title_label.add_theme_color_override("font_color", BrandClass.SUCCESS)
	else:
		_title_label.text = "VICTORIA"
		_title_label.add_theme_color_override("font_color", BrandClass.SUCCESS)


## Marca el título como "TUTORIAL COMPLETADO" (lo llama juego_ataque cuando
## es_tutorial es verdadero, ya que el overlay no conoce level_key).
func set_tutorial_title() -> void:
	_title_label.text = "TUTORIAL COMPLETADO"
	_title_label.add_theme_color_override("font_color", BrandClass.ACCENT)


func _layout_content() -> void:
	if not is_inside_tree() or _panel == null:
		return
	var vp: Vector2 = get_viewport_rect().size
	# El overlay vive como hijo de un Node2D (juego_ataque), así que los anchors
	# PRESET_FULL_RECT no lo dimensionan: hay que forzar size/position al viewport
	# para que cubra TODO el viewport y MOUSE_FILTER_STOP bloquee en toda el área.
	position = Vector2.ZERO
	size = vp
	var center_x: float = vp.x * 0.5
	var center_y: float = vp.y * 0.5

	# Título centrado sobre el centro vertical.
	var title_size: Vector2 = _title_label.get_minimum_size()
	_title_label.position = Vector2(center_x - title_size.x * 0.5, center_y - 90.0)
	_title_label.size = title_size

	# Temblorcito del título en derrota (offset sinusoidal ~0.6s al entrar).
	if _is_lose:
		var elapsed: float = (Time.get_ticks_msec() - _shown_time_ms) / 1000.0
		if elapsed < TITLE_SHAKE_DURATION:
			var shake: float = sin(elapsed * 30.0) * 4.0 * (1.0 - elapsed / TITLE_SHAKE_DURATION)
			_title_label.position.x += shake

	# Mensaje bajo el título.
	var msg_size: Vector2 = _message_label.get_minimum_size()
	_message_label.position = Vector2(center_x - msg_size.x * 0.5, center_y - 30.0)
	_message_label.size = msg_size

	# Estrellas bajo el mensaje.
	var star_size: Vector2 = _stars_label.get_minimum_size()
	_stars_label.position = Vector2(center_x - star_size.x * 0.5, center_y + 4.0)
	_stars_label.size = star_size

	# Fila de botones centrada horizontalmente, debajo del bloque de texto.
	var panel_size: Vector2 = _panel.get_minimum_size()
	_panel.position = Vector2(
		center_x - panel_size.x * 0.5,
		center_y + ROW_OFFSET_Y
	)
	_panel.size = panel_size


func _make_button(label: String, relay: Signal) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_override("font", BrandClass.font_regular())
	btn.add_theme_font_size_override("font_size", ThemeDB.fallback_font_size)
	btn.add_theme_color_override("font_color", BrandClass.TEXT)
	btn.add_theme_color_override("font_hover_color", BrandClass.ACCENT)
	btn.add_theme_color_override("font_focus_color", BrandClass.ACCENT)
	btn.add_theme_color_override("font_pressed_color", BrandClass.TEXT)
	btn.add_theme_stylebox_override("normal", _make_btn_style(BrandClass.accent_dim(0.45), Color(0.05, 0.06, 0.10, 0.92)))
	btn.add_theme_stylebox_override("hover", _make_btn_style(BrandClass.ACCENT, Color(0.08, 0.10, 0.16, 0.95)))
	btn.add_theme_stylebox_override("pressed", _make_btn_style(BrandClass.ACCENT, Color(0.10, 0.13, 0.20, 0.97)))
	btn.add_theme_stylebox_override("focus", _make_focus_style())
	btn.pressed.connect(func(): relay.emit())
	return btn


## Flechas (y Tab) navegan la fila: vecinos explícitos porque en un HBox el
## foco vertical no se autocomputa.
func _wire_focus_neighbors() -> void:
	var btns: Array[Button] = [retry_button, next_button, select_button, menu_button]
	for i in btns.size():
		var prev: Button = btns[wrapi(i - 1, 0, btns.size())]
		var next: Button = btns[wrapi(i + 1, 0, btns.size())]
		btns[i].focus_neighbor_left = btns[i].get_path_to(prev)
		btns[i].focus_neighbor_top = btns[i].get_path_to(prev)
		btns[i].focus_neighbor_right = btns[i].get_path_to(next)
		btns[i].focus_neighbor_bottom = btns[i].get_path_to(next)
		btns[i].focus_next = btns[i].get_path_to(next)
		btns[i].focus_previous = btns[i].get_path_to(prev)


func _make_panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BrandClass.PANEL_SOLID
	style.border_color = BrandClass.with_alpha(border, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = BTN_GAP
	style.content_margin_right = BTN_GAP
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _make_btn_style(border: Color, bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = BTN_CONTENT_MARGIN
	style.content_margin_right = BTN_CONTENT_MARGIN
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _make_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = BrandClass.ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style
