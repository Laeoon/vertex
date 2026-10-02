class_name CyberBackground extends RefCounted

## CyberBackground
## Centralized tactical cyberpunk background renderer for menus and UI screens.
## Features:
##   - Deep ambient vignette and color gradient
##   - Network constellation/plexus graph with floating connected nodes
##   - 3D rotating holographic cyber-sphere / gyroscope reactor
##   - Hexagonal tactical insignia badge
##   - Circuit data pulses & subtle CRT scanline sweep

const Brand = preload("res://juego/ui/brand.gd")

const PLEXUS_NODE_COUNT: int = 34
const PLEXUS_MAX_DIST: float = 125.0
const PARTICLE_COUNT: int = 24
const GRID_SPACING: float = 60.0
const SCAN_SPEED: float = 40.0

var show_hologram: bool = true
var show_plexus: bool = true
var show_grid: bool = true
var show_badge: bool = true

# Simulation pools
var _particles: Array[Dictionary] = []
var _pulses: Array[Dictionary] = []
var _plexus_nodes: Array[Dictionary] = []
var _time: float = 0.0


func _init() -> void:
	_init_particles()
	_init_pulses()
	_init_plexus()


func _init_particles() -> void:
	_particles.clear()
	for i in range(PARTICLE_COUNT):
		_particles.append({
			"pos": Vector2(randf() * 1280.0, randf() * 720.0),
			"speed": randf_range(12.0, 30.0),
			"drift": randf_range(-5.0, 5.0),
			"size": randf_range(1.0, 2.5),
			"alpha": randf_range(0.12, 0.35),
			"color_type": 0 if randf() > 0.25 else 1
		})


func _init_pulses() -> void:
	_pulses.clear()
	for i in range(4):
		_pulses.append({
			"horizontal": i % 2 == 0,
			"grid_idx": (i * 3 + 2),
			"pos": randf_range(0.0, 1000.0),
			"speed": randf_range(90.0, 160.0),
			"length": randf_range(60.0, 120.0),
			"alpha": randf_range(0.25, 0.45)
		})


func _init_plexus() -> void:
	_plexus_nodes.clear()
	for i in range(PLEXUS_NODE_COUNT):
		# Biased slightly towards center and right to complement left menus
		var px := randf_range(280.0, 1260.0)
		var py := randf_range(40.0, 680.0)
		_plexus_nodes.append({
			"pos": Vector2(px, py),
			"vel": Vector2(randf_range(-14.0, 14.0), randf_range(-12.0, 12.0)),
			"radius": randf_range(2.0, 4.0),
			"alpha": randf_range(0.2, 0.6),
			"pulse_speed": randf_range(1.5, 3.5),
			"pulse_phase": randf_range(0.0, 6.28)
		})


## Updates background simulation state.
func update(delta: float, vp_size: Vector2 = Vector2(1280.0, 720.0)) -> void:
	_time += delta

	# 1. Update floating particles
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

	# 2. Update trace pulses
	for pulse in _pulses:
		pulse.pos += pulse.speed * delta
		var max_bound := vp_size.x if pulse.horizontal else vp_size.y
		if pulse.pos - pulse.length > max_bound:
			pulse.pos = -pulse.length
			pulse.grid_idx = randi_range(1, int(max_bound / GRID_SPACING))
			pulse.speed = randf_range(90.0, 170.0)
			pulse.alpha = randf_range(0.2, 0.45)

	# 3. Update plexus network nodes
	var min_x := 100.0
	var max_x := vp_size.x - 20.0
	var min_y := 20.0
	var max_y := vp_size.y - 40.0

	for node in _plexus_nodes:
		node.pos += node.vel * delta
		if node.pos.x < min_x:
			node.pos.x = min_x
			node.vel.x = absf(node.vel.x)
		elif node.pos.x > max_x:
			node.pos.x = max_x
			node.vel.x = -absf(node.vel.x)

		if node.pos.y < min_y:
			node.pos.y = min_y
			node.vel.y = absf(node.vel.y)
		elif node.pos.y > max_y:
			node.pos.y = max_y
			node.vel.y = -absf(node.vel.y)


## Draws the full cybernetic background onto the provided canvas.
func draw(canvas: CanvasItem, vp: Vector2, delta: float = 0.0) -> void:
	if delta > 0.0:
		update(delta, vp)

	# 1. Base deep background
	canvas.draw_rect(Rect2(0, 0, vp.x, vp.y), Brand.BG)

	# 2. Tactical grid lines & intersections
	if show_grid:
		_draw_grid(canvas, vp)
		_draw_intersections(canvas, vp)
		_draw_data_pulses(canvas, vp)

	# 3. Constellation / Plexus graph network
	if show_plexus:
		_draw_plexus(canvas)

	# 4. 3D Holographic Gyro-Sphere
	if show_hologram:
		var holo_center := Vector2(vp.x * 0.80, vp.y * 0.48)
		var holo_radius := minf(vp.y * 0.28, 160.0)
		_draw_hologram(canvas, holo_center, holo_radius)

	# 5. Top-right tactical hex badge
	if show_badge:
		_draw_hex_badge(canvas, Vector2(vp.x - 65.0, 65.0), 32.0)

	# 6. Floating digital dust
	_draw_particles(canvas)

	# 7. Ambient scanline beam sweep
	_draw_scanbeam(canvas, vp)

	# 8. Subtle viewport border
	_draw_border(canvas, vp)


func _draw_grid(canvas: CanvasItem, vp: Vector2) -> void:
	var grid_color: Color = Brand.with_alpha(Brand.PANEL_BORDER, 0.16)
	var x: float = 0.0
	while x < vp.x:
		canvas.draw_line(Vector2(x, 0), Vector2(x, vp.y), grid_color, 1.0)
		x += GRID_SPACING
	var y: float = 0.0
	while y < vp.y:
		canvas.draw_line(Vector2(0, y), Vector2(vp.x, y), grid_color, 1.0)
		y += GRID_SPACING


func _draw_intersections(canvas: CanvasItem, vp: Vector2) -> void:
	var cross_size: float = 2.0
	var x: float = GRID_SPACING
	var col_idx: int = 1

	while x < vp.x:
		var y: float = GRID_SPACING
		var row_idx: int = 1
		while y < vp.y:
			var hash_val: float = sin(col_idx * 12.9898 + row_idx * 78.233) * 43758.5453
			var phase: float = fmod(absf(hash_val), 6.28)
			var pulse: float = sin(_time * 1.8 + phase)

			if pulse > 0.7:
				var intensity: float = (pulse - 0.7) / 0.3
				var cross_color: Color = Brand.with_alpha(Brand.ACCENT, intensity * 0.30)
				canvas.draw_line(Vector2(x - cross_size, y), Vector2(x + cross_size, y), cross_color, 1.0)
				canvas.draw_line(Vector2(x, y - cross_size), Vector2(x, y + cross_size), cross_color, 1.0)

			y += GRID_SPACING
			row_idx += 1
		x += GRID_SPACING
		col_idx += 1


func _draw_data_pulses(canvas: CanvasItem, vp: Vector2) -> void:
	for pulse in _pulses:
		var alpha: float = pulse.alpha * (0.8 + sin(_time * 4.0) * 0.2)
		var pcolor: Color = Brand.with_alpha(Brand.ACCENT, alpha * 0.6)
		var phead: Color = Brand.with_alpha(Color.WHITE, alpha * 0.8)

		if pulse.horizontal:
			var py: float = pulse.grid_idx * GRID_SPACING
			if py < vp.y:
				var x_start: float = clampf(pulse.pos - pulse.length, 0.0, vp.x)
				var x_end: float = clampf(pulse.pos, 0.0, vp.x)
				if x_end > x_start:
					canvas.draw_line(Vector2(x_start, py), Vector2(x_end, py), pcolor, 1.2)
					canvas.draw_circle(Vector2(x_end, py), 1.2, phead)
		else:
			var px: float = pulse.grid_idx * GRID_SPACING
			if px < vp.x:
				var y_start: float = clampf(pulse.pos - pulse.length, 0.0, vp.y)
				var y_end: float = clampf(pulse.pos, 0.0, vp.y)
				if y_end > y_start:
					canvas.draw_line(Vector2(px, y_start), Vector2(px, y_end), pcolor, 1.2)
					canvas.draw_circle(Vector2(px, y_end), 1.2, phead)


func _draw_plexus(canvas: CanvasItem) -> void:
	var n_count := _plexus_nodes.size()

	# Draw edges between nodes within threshold
	for i in range(n_count):
		var p1: Vector2 = _plexus_nodes[i].pos
		for j in range(i + 1, n_count):
			var p2: Vector2 = _plexus_nodes[j].pos
			var d_sq: float = p1.distance_squared_to(p2)
			var max_sq: float = PLEXUS_MAX_DIST * PLEXUS_MAX_DIST

			if d_sq < max_sq:
				var dist: float = sqrt(d_sq)
				var frac: float = 1.0 - (dist / PLEXUS_MAX_DIST)
				var edge_alpha: float = frac * frac * 0.28
				var edge_color: Color = Brand.with_alpha(Brand.ACCENT, edge_alpha)
				canvas.draw_line(p1, p2, edge_color, 1.0)

	# Draw nodes
	for node in _plexus_nodes:
		var p: Vector2 = node.pos
		var pulse: float = 0.5 + sin(_time * node.pulse_speed + node.pulse_phase) * 0.5
		var r: float = node.radius + pulse * 1.0
		var n_alpha: float = node.alpha * (0.6 + pulse * 0.4)

		# Outer glow
		canvas.draw_circle(p, r + 2.5, Brand.with_alpha(Brand.ACCENT, n_alpha * 0.2))
		# Core node
		canvas.draw_circle(p, r, Brand.with_alpha(Brand.ACCENT, n_alpha))
		canvas.draw_circle(p, r * 0.4, Brand.with_alpha(Color.WHITE, n_alpha * 0.9))


## Draws a 3D projected wireframe rotating holographic sphere with cylindrical rings.
func _draw_hologram(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var rot_y: float = _time * 0.45
	var rot_x: float = 0.38 + sin(_time * 0.25) * 0.12
	var base_alpha: float = 0.75 + sin(_time * 1.5) * 0.15

	# 1. Outer tactical framing ring
	var outer_r := radius * 1.18
	canvas.draw_arc(center, outer_r, 0.0, TAU, 48, Brand.with_alpha(Brand.ACCENT, base_alpha * 0.20), 1.0)

	# 4 Corner brackets on outer framing ring
	var bracket_len := 12.0
	for angle_idx in range(4):
		var b_angle := angle_idx * (PI * 0.5) + PI * 0.25 + _time * 0.08
		var bp := center + Vector2(cos(b_angle), sin(b_angle)) * outer_r
		canvas.draw_circle(bp, 2.5, Brand.with_alpha(Brand.ACCENT, base_alpha * 0.8))

	# 2. Concentric cylindrical core rings (tilted along rot_x and rotating)
	var ring_heights: Array[float] = [-0.45, -0.15, 0.15, 0.45]
	for h_ratio in ring_heights:
		var r_level := radius * cos(asin(clampf(h_ratio, -0.99, 0.99))) * 0.92
		var y_off := h_ratio * radius * 0.85
		_draw_projected_ring(canvas, center + Vector2(0, y_off), r_level, rot_x, rot_y, base_alpha)

	# 3. Sphere 3D Wireframe Longitudes (meridians rotated around Y)
	var meridian_count := 6
	for m in range(meridian_count):
		var m_angle := rot_y + (m * PI / meridian_count)
		_draw_projected_meridian(canvas, center, radius, m_angle, rot_x, base_alpha)

	# 4. Central energy core & rotating orbital point
	var core_pulse := 0.7 + sin(_time * 3.0) * 0.3
	canvas.draw_circle(center, 9.0, Brand.with_alpha(Brand.ACCENT, base_alpha * 0.35 * core_pulse))
	canvas.draw_circle(center, 4.0, Brand.with_alpha(Color.WHITE, base_alpha * 0.9))

	# Orbital satellites
	var sat_angle := _time * 1.8
	var sat_pos := center + Vector2(cos(sat_angle) * radius * 0.75, sin(sat_angle) * radius * 0.32)
	canvas.draw_circle(sat_pos, 3.0, Brand.with_alpha(Color.WHITE, 0.9))
	canvas.draw_circle(sat_pos, 6.0, Brand.with_alpha(Brand.ACCENT, 0.35))


func _draw_projected_ring(canvas: CanvasItem, center: Vector2, r: float, tilt_x: float, rot_y: float, base_alpha: float) -> void:
	var points := PackedVector2Array()
	var segments := 32
	var cos_tilt := cos(tilt_x)
	var sin_tilt := sin(tilt_x)

	for i in range(segments + 1):
		var theta := (float(i) / float(segments)) * TAU + rot_y
		var x := cos(theta) * r
		var z := sin(theta) * r
		var y := z * sin_tilt
		points.append(center + Vector2(x, y))

	var ring_col := Brand.with_alpha(Brand.ACCENT, base_alpha * 0.38)
	canvas.draw_polyline(points, ring_col, 1.2)


func _draw_projected_meridian(canvas: CanvasItem, center: Vector2, r: float, meridian_y_rot: float, tilt_x: float, base_alpha: float) -> void:
	var points := PackedVector2Array()
	var segments := 28
	var cos_tilt := cos(tilt_x)
	var sin_tilt := sin(tilt_x)
	var cos_my := cos(meridian_y_rot)
	var sin_my := sin(meridian_y_rot)

	for i in range(segments + 1):
		var phi := (float(i) / float(segments)) * TAU
		var x3 := r * cos(phi) * cos_my
		var z3 := r * cos(phi) * sin_my
		var y3 := r * sin(phi)

		# Tilt around X axis
		var y_proj := y3 * cos_tilt - z3 * sin_tilt
		var x_proj := x3
		points.append(center + Vector2(x_proj, y_proj))

	var arc_col := Brand.with_alpha(Brand.ACCENT, base_alpha * 0.22)
	canvas.draw_polyline(points, arc_col, 1.0)


## Draws the top-right tactical hexagonal badge.
func _draw_hex_badge(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var points_outer := PackedVector2Array()
	var points_inner := PackedVector2Array()

	for i in range(6):
		var angle := i * (PI / 3.0) - PI * 0.5
		points_outer.append(center + Vector2(cos(angle), sin(angle)) * radius)
		points_inner.append(center + Vector2(cos(angle), sin(angle)) * (radius * 0.72))

	points_outer.append(points_outer[0])
	points_inner.append(points_inner[0])

	# Subtle filled background
	canvas.draw_colored_polygon(points_inner, Brand.with_alpha(Brand.PANEL_SOLID, 0.75))
	# Outer border
	canvas.draw_polyline(points_outer, Brand.with_alpha(Brand.ACCENT, 0.35), 1.5)
	# Inner glowing border
	canvas.draw_polyline(points_inner, Brand.with_alpha(Brand.ACCENT, 0.65), 1.2)
	# Central glowing core node
	var pulse: float = 0.7 + sin(_time * 2.0) * 0.3
	canvas.draw_circle(center, 4.0, Brand.with_alpha(Brand.ACCENT, pulse * 0.8))
	canvas.draw_circle(center, 1.5, Color.WHITE)


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
	var beam_color := Brand.with_alpha(Brand.ACCENT, 0.05)
	var glow_color := Brand.with_alpha(Brand.ACCENT, 0.015)

	canvas.draw_rect(Rect2(0, scan_y - 6.0, vp.x, 12.0), glow_color)
	canvas.draw_rect(Rect2(0, scan_y, vp.x, 1.5), beam_color)


func _draw_border(canvas: CanvasItem, vp: Vector2) -> void:
	var border_color := Brand.with_alpha(Brand.PANEL_BORDER, 0.45)
	canvas.draw_rect(Rect2(0, 0, vp.x, 2), border_color)
	canvas.draw_rect(Rect2(0, vp.y - 2, vp.x, 2), border_color)
	canvas.draw_rect(Rect2(0, 0, 2, vp.y), border_color)
	canvas.draw_rect(Rect2(vp.x - 2, 0, 2, vp.y), border_color)
