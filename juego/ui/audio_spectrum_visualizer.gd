class_name AudioSpectrumVisualizer extends RefCounted

## AudioSpectrumVisualizer
## Renderizador vectorial táctico de telemetría y espectro de audio reactivo para VERTEX.
## Diseñado para alinearse a lo largo del riel de conexión de niveles (onda simétrica horizontal).
## Lee directamente de AudioServer (Music/Master) con conversión decibélica de alta sensibilidad.

const BrandClass = preload("res://juego/ui/brand.gd")

var band_count: int = 32
var min_freq: float = 24.0
var max_freq: float = 11050.0
var smooth_speed: float = 18.0
var peak_decay_speed: float = 0.65
var idle_wave_enabled: bool = true

var _current_mags: PackedFloat32Array = PackedFloat32Array()
var _peak_mags: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0
var _bass_energy: float = 0.0
var _mid_energy: float = 0.0
var _high_energy: float = 0.0


func _init(p_band_count: int = 32) -> void:
	band_count = maxi(8, p_band_count)
	_current_mags.resize(band_count)
	_peak_mags.resize(band_count)
	for i in range(band_count):
		_current_mags[i] = 0.0
		_peak_mags[i] = 0.0


func update(delta: float) -> void:
	_time += delta

	var raw_mags := _fetch_magnitudes_from_audio_server()
	var has_audio := false
	for v in raw_mags:
		if v > 0.02:
			has_audio = true
			break

	for i in range(band_count):
		var target_val: float = 0.0
		var t := float(i) / float(band_count - 1)

		if has_audio and raw_mags.size() == band_count:
			# Escalar y dar cuerpo al espectro en vivo
			target_val = raw_mags[i]
		elif idle_wave_enabled:
			# Onda orgánica multicapa viajera para que siempre esté viva y en movimiento
			var w1 := sin(_time * 2.8 + t * 9.0) * 0.16
			var w2 := cos(_time * 1.6 - t * 14.0) * 0.10
			var w3 := sin(_time * 4.2 + t * 24.0) * 0.06
			target_val = clampf(0.12 + w1 + w2 + w3, 0.03, 0.40)

		# Interpolar suavemente
		var spd := smooth_speed * (2.5 if target_val > _current_mags[i] else 1.2)
		_current_mags[i] = lerpf(_current_mags[i], target_val, clampf(spd * delta, 0.0, 1.0))

		# Picos balísticos
		if _current_mags[i] >= _peak_mags[i]:
			_peak_mags[i] = _current_mags[i]
		else:
			_peak_mags[i] = maxf(0.0, _peak_mags[i] - peak_decay_speed * delta)

	# Actualizar métricas acumuladas de bandas
	var n_mags := _current_mags.size()
	if n_mags > 0:
		var b_tot: float = 0.0
		var m_tot: float = 0.0
		var h_tot: float = 0.0
		var q1 := maxi(1, n_mags / 4)
		var q2 := maxi(q1 + 1, (n_mags * 3) / 4)
		for b in range(n_mags):
			var v := _current_mags[b]
			if b < q1:
				b_tot += v
			elif b < q2:
				m_tot += v
			else:
				h_tot += v
		_bass_energy = b_tot / float(q1)
		_mid_energy = m_tot / float(maxi(1, q2 - q1))
		_high_energy = h_tot / float(maxi(1, n_mags - q2))


## Devuelve la energía actual del rango de bajos (0.0..1.0) para pulsos reactivos.
func get_bass_energy() -> float:
	return _bass_energy


func _fetch_magnitudes_from_audio_server() -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(band_count)

	# Buscar analizador en Music o Master directamente en AudioServer
	for bus_name in ["Music", "Master"]:
		var b_idx := AudioServer.get_bus_index(bus_name)
		if b_idx == -1:
			continue
		for i in range(AudioServer.get_bus_effect_count(b_idx)):
			if AudioServer.get_bus_effect(b_idx, i) is AudioEffectSpectrumAnalyzer:
				var inst = AudioServer.get_bus_effect_instance(b_idx, i)
				if inst != null:
					var f_min := maxf(20.0, min_freq)
					var f_max := maxf(f_min + 10.0, max_freq)
					for b in range(band_count):
						var f_low := f_min * pow(f_max / f_min, float(b) / float(band_count))
						var f_high := f_min * pow(f_max / f_min, float(b + 1) / float(band_count))
						var mag_vec: Vector2 = inst.get_magnitude_for_frequency_range(f_low, f_high)
						var l := mag_vec.length()
						if l < 0.00004:
							result[b] = 0.0
						else:
							var db := linear_to_db(l)
							# Rango dinámico sensible de -52 dB a 0 dB
							result[b] = clampf((db + 52.0) / 52.0, 0.0, 1.0)
					return result
	return result


## Dibuja la onda simétrica centrada a lo largo del riel horizontal de nodos (estilo pizarra).
func draw_track_waveform(
	canvas: CanvasItem,
	from_pos: Vector2,
	to_pos: Vector2,
	theme_color: Color = Color("00e5ff"),
	max_amplitude: float = 85.0,
	slice_count: int = 110,
	alpha_mult: float = 1.0
) -> void:
	var center_y := (from_pos.y + to_pos.y) * 0.5
	var padding_x := 80.0
	var start_x := minf(from_pos.x, to_pos.x) - padding_x
	var end_x := maxf(from_pos.x, to_pos.x) + padding_x
	var total_span := maxf(10.0, end_x - start_x)

	var top_pts: PackedVector2Array = PackedVector2Array()
	var bot_pts: PackedVector2Array = PackedVector2Array()
	var inner_top_pts: PackedVector2Array = PackedVector2Array()
	var inner_bot_pts: PackedVector2Array = PackedVector2Array()

	var dx := total_span / float(slice_count - 1)

	# Calcular métricas globales de energía del audio para propagación homogénea
	var total_energy: float = 0.0
	var bass_energy: float = 0.0
	var mid_energy: float = 0.0
	var high_energy: float = 0.0

	var n_mags := _current_mags.size()
	if n_mags > 0:
		for b in range(n_mags):
			var v := _current_mags[b]
			total_energy += v
			if b < n_mags / 4:
				bass_energy += v
			elif b < (n_mags * 3) / 4:
				mid_energy += v
			else:
				high_energy += v

		total_energy /= float(n_mags)
		bass_energy /= maxf(1.0, float(n_mags / 4))
		mid_energy /= maxf(1.0, float(n_mags / 2))
		high_energy /= maxf(1.0, float(n_mags / 4))

	# 1. Dibujar barras verticales simétricas densas
	for i in range(slice_count):
		var t := float(i) / float(slice_count - 1)
		var x := start_x + float(i) * dx

		# Distribución homogénea: envolvente simétrica con centro en 0.5 (distancia al centro)
		var dist_to_center := absf(t - 0.5) * 2.0  # 0.0 en el centro, 1.0 en los bordes

		# Muestrear el espectro de frecuencias con espejado simétrico desde el centro
		# para que ambos lados del riel respiren con la misma armonía
		var sym_t := 1.0 - dist_to_center
		var band_f := sym_t * float(band_count - 1)
		var b_idx0 := clampi(int(floor(band_f)), 0, band_count - 1)
		var b_idx1 := clampi(b_idx0 + 1, 0, band_count - 1)
		var frac := band_f - float(b_idx0)

		var m0 := _current_mags[b_idx0] if b_idx0 < n_mags else 0.0
		var m1 := _current_mags[b_idx1] if b_idx1 < n_mags else 0.0
		var local_spec := lerpf(m0, m1, frac)

		# Fusión homogénea:
		# 40% espectro local simétrico + 35% bajo envolvente general + 25% medios/altos
		var audio_envelope := local_spec * 0.40 + bass_energy * 0.35 + (mid_energy + high_energy) * 0.25

		# Armónicos tácticos viajeros continuos para vibración homogénea sin saltos
		var ripple := sin(_time * 3.2 + t * 18.0) * 0.07 + cos(_time * 2.1 - t * 26.0) * 0.05
		var pulse_wave := sin(_time * 4.5 + t * 32.0) * (0.04 + high_energy * 0.08)

		var energy := clampf(audio_envelope + ripple + pulse_wave, 0.05, 1.0)

		# Suavizar caída en los extremos izquierdo y derecho
		var edge_fade := sin(t * PI)
		edge_fade = pow(edge_fade, 0.55) # Transición natural en bordes
		var h := energy * max_amplitude * edge_fade
		h = maxf(h, 2.0)

		var top_y := center_y - h
		var bot_y := center_y + h

		# Guardar contornos
		top_pts.append(Vector2(x, top_y))
		bot_pts.append(Vector2(x, bot_y))
		inner_top_pts.append(Vector2(x, center_y - h * 0.45))
		inner_bot_pts.append(Vector2(x, center_y + h * 0.45))

		# Líneas verticales del ecualizador
		var bar_alpha := clampf((0.18 + energy * 0.58) * alpha_mult * edge_fade, 0.05, 0.88)
		var bar_col := BrandClass.with_alpha(theme_color, bar_alpha)
		canvas.draw_line(Vector2(x, top_y), Vector2(x, bot_y), bar_col, 1.6)

	# 2. Contorno superior e inferior brillante multi-pase (glow ancho, bloom medio y núcleo brillante)
	var glow_wide_col := BrandClass.with_alpha(theme_color, 0.20 * alpha_mult)
	var bloom_med_col := BrandClass.with_alpha(theme_color.lightened(0.25), 0.45 * alpha_mult)
	var core_bright_col := BrandClass.with_alpha(theme_color.lightened(0.60), 0.95 * alpha_mult)
	var inner_col := BrandClass.with_alpha(theme_color, 0.35 * alpha_mult)

	# Pase 1: Resplandor amplio suave (width = 8.0, alpha = 0.20)
	for j in range(top_pts.size() - 1):
		canvas.draw_line(top_pts[j], top_pts[j + 1], glow_wide_col, 8.0)
		canvas.draw_line(bot_pts[j], bot_pts[j + 1], glow_wide_col, 8.0)

	# Pase 2: Bloom medio (width = 4.0, alpha = 0.45)
	for j in range(top_pts.size() - 1):
		canvas.draw_line(top_pts[j], top_pts[j + 1], bloom_med_col, 4.0)
		canvas.draw_line(bot_pts[j], bot_pts[j + 1], bloom_med_col, 4.0)

	# Pase 3: Núcleo brillante concentrado (width = 2.5, alpha = 0.95)
	for j in range(top_pts.size() - 1):
		canvas.draw_line(top_pts[j], top_pts[j + 1], core_bright_col, 2.5)
		canvas.draw_line(bot_pts[j], bot_pts[j + 1], core_bright_col, 2.5)
		canvas.draw_line(inner_top_pts[j], inner_top_pts[j + 1], inner_col, 1.0)
		canvas.draw_line(inner_bot_pts[j], inner_bot_pts[j + 1], inner_col, 1.0)


## Dibuja la onda reactiva a lo largo de una espina diagonal 3D con perspectiva de profundidad.
func draw_spine_waveform(
	canvas: CanvasItem,
	from_pos: Vector2,
	to_pos: Vector2,
	theme_color: Color = Color("00e5ff"),
	max_amplitude: float = 60.0,
	slice_count: int = 90,
	alpha_mult: float = 1.0
) -> void:
	if slice_count < 4:
		return

	var spine_vec := to_pos - from_pos
	var spine_len := spine_vec.length()
	if spine_len < 10.0:
		return

	var spine_dir := spine_vec / spine_len
	# Vector perpendicular normalizado en 2D (arriba a la izquierda relativo a la espina)
	var perp := Vector2(-spine_dir.y, spine_dir.x)

	var top_pts: PackedVector2Array = PackedVector2Array()
	var bot_pts: PackedVector2Array = PackedVector2Array()
	var inner_top_pts: PackedVector2Array = PackedVector2Array()
	var inner_bot_pts: PackedVector2Array = PackedVector2Array()

	var n_mags := _current_mags.size()

	for i in range(slice_count):
		var t := float(i) / float(slice_count - 1)
		# Escala de perspectiva: mayor en primer plano (t=0), menor en el horizonte profundo (t=1)
		var persp_scale := lerpf(1.15, 0.42, t)

		var base_p := from_pos.lerp(to_pos, t)

		# Muestreo simétrico
		var dist_to_center := absf(t - 0.45) * 2.0
		var sym_t := clampf(1.0 - dist_to_center, 0.0, 1.0)
		var band_f := sym_t * float(band_count - 1)
		var b_idx0 := clampi(int(floor(band_f)), 0, band_count - 1)
		var b_idx1 := clampi(b_idx0 + 1, 0, band_count - 1)
		var frac := band_f - float(b_idx0)

		var m0 := _current_mags[b_idx0] if b_idx0 < n_mags else 0.0
		var m1 := _current_mags[b_idx1] if b_idx1 < n_mags else 0.0
		var local_spec := lerpf(m0, m1, frac)

		var audio_env := local_spec * 0.45 + _bass_energy * 0.35 + (_mid_energy + _high_energy) * 0.20
		var ripple := sin(_time * 3.4 + t * 16.0) * 0.06
		var energy := clampf(audio_env + ripple, 0.04, 1.0)

		var edge_fade := sin(t * PI)
		edge_fade = pow(edge_fade, 0.45)

		var h := energy * max_amplitude * persp_scale * edge_fade
		h = maxf(h, 2.0 * persp_scale)

		var p_top := base_p - perp * h
		var p_bot := base_p + perp * h

		top_pts.append(p_top)
		bot_pts.append(p_bot)
		inner_top_pts.append(base_p - perp * (h * 0.45))
		inner_bot_pts.append(base_p + perp * (h * 0.45))

		# Barras verticales/perpendiculares del espectro
		var bar_alpha := clampf((0.15 + energy * 0.55) * alpha_mult * edge_fade, 0.04, 0.85)
		var bar_col := BrandClass.with_alpha(theme_color, bar_alpha)
		canvas.draw_line(p_top, p_bot, bar_col, maxf(1.0, 2.2 * persp_scale))

	# Contornos multi-pase a lo largo de la espina
	var glow_wide_col := BrandClass.with_alpha(theme_color, 0.20 * alpha_mult)
	var bloom_med_col := BrandClass.with_alpha(theme_color.lightened(0.25), 0.45 * alpha_mult)
	var core_bright_col := BrandClass.with_alpha(theme_color.lightened(0.60), 0.95 * alpha_mult)
	var inner_col := BrandClass.with_alpha(theme_color, 0.35 * alpha_mult)

	# Pase 1: Resplandor amplio (width = 8.0)
	for j in range(top_pts.size() - 1):
		canvas.draw_line(top_pts[j], top_pts[j + 1], glow_wide_col, 8.0)
		canvas.draw_line(bot_pts[j], bot_pts[j + 1], glow_wide_col, 8.0)

	# Pase 2: Bloom medio (width = 4.0)
	for j in range(top_pts.size() - 1):
		canvas.draw_line(top_pts[j], top_pts[j + 1], bloom_med_col, 4.0)
		canvas.draw_line(bot_pts[j], bot_pts[j + 1], bloom_med_col, 4.0)

	# Pase 3: Núcleo brillante (width = 2.5)
	for j in range(top_pts.size() - 1):
		canvas.draw_line(top_pts[j], top_pts[j + 1], core_bright_col, 2.5)
		canvas.draw_line(bot_pts[j], bot_pts[j + 1], core_bright_col, 2.5)
		canvas.draw_line(inner_top_pts[j], inner_top_pts[j + 1], inner_col, 1.0)
		canvas.draw_line(inner_bot_pts[j], inner_bot_pts[j + 1], inner_col, 1.0)


## Dibuja el espectro en un rectángulo de menú (para WorldSelectRenderer)
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

	var center_y := rect.position.y + rect.size.y * 0.5
	var start_pos := Vector2(rect.position.x, center_y)
	var end_pos := Vector2(rect.position.x + rect.size.x, center_y)
	draw_track_waveform(canvas, start_pos, end_pos, theme_color, rect.size.y * 0.45, 80, alpha_mult)

	if show_labels and font != null:
		var telemetry_text := "SPECTRUM // FFT_1024 // 24Hz-11kHz"
		canvas.draw_string(font, Vector2(rect.position.x + 8.0, rect.position.y + 12.0), telemetry_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.65 * alpha_mult))


func get_magnitudes() -> PackedFloat32Array:
	return _current_mags.duplicate()


func get_peaks() -> PackedFloat32Array:
	return _peak_mags.duplicate()
