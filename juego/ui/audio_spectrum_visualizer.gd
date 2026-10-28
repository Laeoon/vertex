class_name AudioSpectrumVisualizer extends RefCounted

## AudioSpectrumVisualizer
## Renderizador vectorial táctico de telemetría y espectro de audio reactivo para VERTEX.
## Muestra barras de ecualización cibernética, picos de atenuación balística y ondas continuas.
## Seguro para entornos headless y fallback a onda orgánica sutil cuando no hay audio activo.

const BrandClass = preload("res://juego/ui/brand.gd")

var band_count: int = 24
var min_freq: float = 24.0
var max_freq: float = 11050.0
var smooth_speed: float = 14.0
var peak_decay_speed: float = 0.75
var idle_wave_enabled: bool = true

var _current_mags: PackedFloat32Array = PackedFloat32Array()
var _peak_mags: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0


func _init(p_band_count: int = 24) -> void:
	band_count = maxi(8, p_band_count)
	_current_mags.resize(band_count)
	_peak_mags.resize(band_count)
	for i in range(band_count):
		_current_mags[i] = 0.0
		_peak_mags[i] = 0.0


func update(delta: float) -> void:
	_time += delta

	var raw_mags := PackedFloat32Array()
	var am = Engine.get_main_loop().root.get_node_or_null("/root/AudioManager") if Engine.get_main_loop() else null
	if am != null and am.has_method("get_spectrum_magnitudes"):
		raw_mags = am.get_spectrum_magnitudes(band_count, min_freq, max_freq)

	var has_audio := false
	if raw_mags.size() == band_count:
		for v in raw_mags:
			if v > 0.005:
				has_audio = true
				break

	for i in range(band_count):
		var target_val: float = 0.0
		if has_audio and raw_mags.size() == band_count:
			target_val = raw_mags[i]
		elif idle_wave_enabled:
			# Onda orgánica sutil de standby cuando no hay música o en headless
			var phase := float(i) / float(band_count) * PI * 2.0
			var sine_1 := sin(_time * 2.0 + phase) * 0.07
			var sine_2 := cos(_time * 1.2 - phase * 1.5) * 0.04
			target_val = clampf(0.08 + sine_1 + sine_2, 0.02, 0.22)

		# Suavizado de ataque y decaimiento
		var spd := smooth_speed * (2.2 if target_val > _current_mags[i] else 1.0)
		_current_mags[i] = lerpf(_current_mags[i], target_val, clampf(spd * delta, 0.0, 1.0))

		# Picos balísticos
		if _current_mags[i] >= _peak_mags[i]:
			_peak_mags[i] = _current_mags[i]
		else:
			_peak_mags[i] = maxf(0.0, _peak_mags[i] - peak_decay_speed * delta)


## Dibuja el espectro táctico en el CanvasItem dado dentro del Rect2 especificado.
func draw(
	canvas: CanvasItem,
	rect: Rect2,
	theme_color: Color = BrandClass.ACCENT,
	font: Font = null,
	show_labels: bool = true,
	alpha_mult: float = 1.0
) -> void:
	if rect.size.x <= 10.0 or rect.size.y <= 10.0:
		return

	var gap := 4.0
	var total_gaps := gap * float(band_count - 1)
	var bar_w := maxf(2.0, (rect.size.x - total_gaps) / float(band_count))
	var base_y := rect.position.y + rect.size.y
	var max_h := rect.size.y - (20.0 if show_labels else 4.0)

	# 1. Fondo sutil de contención
	canvas.draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.25 * alpha_mult))
	canvas.draw_line(Vector2(rect.position.x, base_y), Vector2(rect.position.x + rect.size.x, base_y), BrandClass.with_alpha(theme_color, 0.35 * alpha_mult), 1.0)

	# 2. Puntos para la curva de onda continua superior
	var wave_pts: PackedVector2Array = PackedVector2Array()

	for i in range(band_count):
		var bx := rect.position.x + float(i) * (bar_w + gap)
		var val := _current_mags[i] if i < _current_mags.size() else 0.0
		var peak := _peak_mags[i] if i < _peak_mags.size() else 0.0

		var bar_h := clampf(val * max_h, 3.0, max_h)
		var bar_rect := Rect2(bx, base_y - bar_h, bar_w, bar_h)

		# Barra con gradiente conceptual (cuerpo con opacidad modulada)
		var b_col := BrandClass.with_alpha(theme_color, (0.25 + val * 0.55) * alpha_mult)
		canvas.draw_rect(bar_rect, b_col)
		canvas.draw_rect(bar_rect, BrandClass.with_alpha(theme_color, 0.7 * alpha_mult), false, 1.0)

		# Cap de pico flotante
		var peak_y := base_y - clampf(peak * max_h, 3.0, max_h)
		var peak_col := BrandClass.with_alpha(Color.WHITE if val > 0.6 else theme_color, 0.9 * alpha_mult)
		canvas.draw_line(Vector2(bx, peak_y), Vector2(bx + bar_w, peak_y), peak_col, 1.8)

		# Acumulación de punto de onda
		wave_pts.append(Vector2(bx + bar_w * 0.5, peak_y))

	# 3. Trazo continuo de onda táctica sobre los picos
	if wave_pts.size() >= 2:
		for j in range(wave_pts.size() - 1):
			canvas.draw_line(wave_pts[j], wave_pts[j + 1], BrandClass.with_alpha(theme_color, 0.5 * alpha_mult), 1.2)

	# 4. Etiqueta táctica de telemetría
	if show_labels and font != null:
		var telemetry_text := "AUDIO FFT // 24 BANDS // %dHz - %dkHz" % [int(min_freq), int(max_freq / 1000.0)]
		var f_sz := 9
		canvas.draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 14.0), telemetry_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sz, BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.7 * alpha_mult))


func get_magnitudes() -> PackedFloat32Array:
	return _current_mags.duplicate()


func get_peaks() -> PackedFloat32Array:
	return _peak_mags.duplicate()
