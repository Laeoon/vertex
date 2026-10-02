class_name CyberBackground extends RefCounted

## CyberBackground
## Centralized tactical cyberpunk background renderer for menus and UI screens.
## Provides an animated cybernetic grid, travelling data pulses, floating digital dust,
## and a CRT-style ambient scanline sweep without impacting framerate.

const Brand = preload("res://juego/ui/brand.gd")

const PARTICLE_COUNT: int = 28
const GRID_SPACING: float = 60.0
const SCAN_SPEED: float = 40.0

# Preallocated particle pool for zero runtime allocations
var _particles: Array[Dictionary] = []
var _pulses: Array[Dictionary] = []
var _time: float = 0.0
var _initialized: bool = false


func _init() -> void:
	_init_particles()
	_init_pulses()


func _init_particles() -> void:
	_particles.clear()
	for i in range(PARTICLE_COUNT):
		_particles.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"speed": randf_range(12.0, 32.0),
			"drift": randf_range(-6.0, 6.0),
			"size": randf_range(1.0, 2.5),
			"alpha": randf_range(0.12, 0.38),
			"color_type": 0 if randf() > 0.25 else 1 # 0 = accent (cyan), 1 = warning/enemy (amber/pink)
		})


func _init_pulses() -> void:
	_pulses.clear()
	# 4 horizontal / vertical trace pulses travelling along grid lines
	for i in range(4):
		_pulses.append({
			"horizontal": i % 2 == 0,
			"grid_idx": (i * 3 + 2),
			"pos": randf_range(0.0, 1000.0),
			"speed": randf_range(90.0, 160.0),
			"length": randf_range(60.0, 120.0),
			"alpha": randf_range(0.25, 0.45)
		})


## Updates background simulation state (particles, data pulses, scanlines).
func update(delta: float, vp_size: Vector2 = Vector2(1280.0, 720.0)) -> void:
	_time += delta

	# Update floating particles
	for p in _particles:
		p.pos.y -= p.speed * delta
		p.pos.x += p.drift * delta
		if p.pos.y < -10.0:
			p.pos.y = vp_size.y + randf_range(2.0, 20.0)
			p.pos.x = randf() * vp_size.x
		if p.pos.x < 0.0:
			p.pos.x = vp_size.x
		elif p.pos.x > vp_size.x:
			p.pos.x = 0.0

	# Update trace pulses
	for pulse in _pulses:
		pulse.pos += pulse.speed * delta
		var max_bound := vp_size.x if pulse.horizontal else vp_size.y
		if pulse.pos - pulse.length > max_bound:
			pulse.pos = -pulse.length
			pulse.grid_idx = randi_range(1, int(max_bound / GRID_SPACING))
			pulse.speed = randf_range(90.0, 170.0)
			pulse.alpha = randf_range(0.2, 0.45)


## Draws the full cybernetic background onto the provided canvas.
func draw(canvas: CanvasItem, vp: Vector2, delta: float = 0.0) -> void:
	if delta > 0.0:
		update(delta, vp)

	# 1. Base background
	canvas.draw_rect(Rect2(0, 0, vp.x, vp.y), Brand.BG)

	# 2. Vignette corners (deep gradient darkening at edges)
	_draw_vignette(canvas, vp)

	# 3. Tactical grid lines
	var grid_color: Color = Brand.with_alpha(Brand.PANEL_BORDER, 0.22)
	var x: float = 0.0
	while x < vp.x:
		canvas.draw_line(Vector2(x, 0), Vector2(x, vp.y), grid_color, 1.0)
		x += GRID_SPACING
	var y: float = 0.0
	while y < vp.y:
		canvas.draw_line(Vector2(0, y), Vector2(vp.x, y), grid_color, 1.0)
		y += GRID_SPACING

	# 4. Grid intersections & pulsing cyber crosses
	_draw_intersections(canvas, vp)

	# 5. Circuit data pulses travelling on lines
	_draw_data_pulses(canvas, vp)

	# 6. Floating digital dust / code packets
	_draw_particles(canvas)

	# 7. Ambient scanline beam sweep
	_draw_scanbeam(canvas, vp)


func _draw_vignette(canvas: CanvasItem, vp: Vector2) -> void:
	# Corner depth shading
	var corner_w: float = vp.x * 0.4
	var corner_h: float = vp.y * 0.4
	var dark_color: Color = Color(0.02, 0.02, 0.05, 0.35)

	# Subtle edge borders to ground the viewport
	canvas.draw_rect(Rect2(0, 0, vp.x, 2), Brand.with_alpha(Brand.PANEL_BORDER, 0.5))
	canvas.draw_rect(Rect2(0, vp.y - 2, vp.x, 2), Brand.with_alpha(Brand.PANEL_BORDER, 0.5))
	canvas.draw_rect(Rect2(0, 0, 2, vp.y), Brand.with_alpha(Brand.PANEL_BORDER, 0.5))
	canvas.draw_rect(Rect2(vp.x - 2, 0, 2, vp.y), Brand.with_alpha(Brand.PANEL_BORDER, 0.5))


func _draw_intersections(canvas: CanvasItem, vp: Vector2) -> void:
	var cross_size: float = 2.5
	var x: float = GRID_SPACING
	var col_idx: int = 1

	while x < vp.x:
		var y: float = GRID_SPACING
		var row_idx: int = 1
		while y < vp.y:
			# Deterministic pseudo-random pulse per intersection
			var hash_val: float = sin(col_idx * 12.9898 + row_idx * 78.233) * 43758.5453
			var phase: float = fmod(absf(hash_val), 6.28)
			var pulse: float = sin(_time * 1.8 + phase)

			if pulse > 0.6:
				# Highlighted pulsing cyber cross
				var intensity: float = (pulse - 0.6) / 0.4
				var cross_color: Color = Brand.with_alpha(Brand.ACCENT, intensity * 0.35)
				canvas.draw_line(Vector2(x - cross_size, y), Vector2(x + cross_size, y), cross_color, 1.0)
				canvas.draw_line(Vector2(x, y - cross_size), Vector2(x, y + cross_size), cross_color, 1.0)
			else:
				# Subtle dim dot
				var dot_color: Color = Brand.with_alpha(Brand.PANEL_BORDER, 0.35)
				canvas.draw_rect(Rect2(x - 0.5, y - 0.5, 1.0, 1.0), dot_color)

			y += GRID_SPACING
			row_idx += 1
		x += GRID_SPACING
		col_idx += 1


func _draw_data_pulses(canvas: CanvasItem, vp: Vector2) -> void:
	for pulse in _pulses:
		var alpha: float = pulse.alpha * (0.8 + sin(_time * 4.0) * 0.2)
		var pcolor: Color = Brand.with_alpha(Brand.ACCENT, alpha)
		var phead: Color = Brand.with_alpha(Color.WHITE, alpha * 1.2)

		if pulse.horizontal:
			var py: float = pulse.grid_idx * GRID_SPACING
			if py < vp.y:
				var x_start: float = clampf(pulse.pos - pulse.length, 0.0, vp.x)
				var x_end: float = clampf(pulse.pos, 0.0, vp.x)
				if x_end > x_start:
					canvas.draw_line(Vector2(x_start, py), Vector2(x_end, py), pcolor, 1.5)
					# Brighter leading edge
					canvas.draw_circle(Vector2(x_end, py), 1.5, phead)
		else:
			var px: float = pulse.grid_idx * GRID_SPACING
			if px < vp.x:
				var y_start: float = clampf(pulse.pos - pulse.length, 0.0, vp.y)
				var y_end: float = clampf(pulse.pos, 0.0, vp.y)
				if y_end > y_start:
					canvas.draw_line(Vector2(px, y_start), Vector2(px, y_end), pcolor, 1.5)
					canvas.draw_circle(Vector2(px, y_end), 1.5, phead)


func _draw_particles(canvas: CanvasItem) -> void:
	for p in _particles:
		var color: Color
		if p.color_type == 0:
			color = Brand.with_alpha(Brand.ACCENT, p.alpha)
		else:
			color = Brand.with_alpha(Brand.WARNING, p.alpha * 0.8)

		var sz: float = p.size
		canvas.draw_rect(Rect2(p.pos.x, p.pos.y, sz, sz), color)


func _draw_scanbeam(canvas: CanvasItem, vp: Vector2) -> void:
	var scan_y: float = fmod(_time * SCAN_SPEED, vp.y)

	# Faint scanning beam with soft halo
	var beam_color := Brand.with_alpha(Brand.ACCENT, 0.06)
	var glow_color := Brand.with_alpha(Brand.ACCENT, 0.02)

	# Soft halo
	canvas.draw_rect(Rect2(0, scan_y - 6.0, vp.x, 12.0), glow_color)
	# Core beam line
	canvas.draw_rect(Rect2(0, scan_y, vp.x, 1.5), beam_color)
