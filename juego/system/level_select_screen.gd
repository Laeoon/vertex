extends Control

## Selector de Niveles Táctico 2.5D + Multi-Acto + Ficha Holográfica y Mini-Mapa en Vivo.
## Muestra los niveles del mundo en un carrusel interactivo 2.5D con animación stagger,
## onda de audio reactiva a lo largo del riel, conmutador de actos (I / II) y reproductor de cinemáticas.
## Basado en diseño Artboard 07 (07-level-select-3d-spine-tunnel.html).

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
const AudioSpectrumVisualizerClass = preload("res://juego/ui/audio_spectrum_visualizer.gd")
const CinematicOverlayClass = preload("res://juego/ui/cinematic_overlay.gd")
const CinematicRegistryClass = preload("res://juego/system/cinematic_registry.gd")

var world_id: String = ""
var world_title: String = ""
var level_nodes: Array = []
var progress: Dictionary = {}

var font: Font
var font_size: int = 14
var big_font_size: int = 24
var small_font_size: int = 12

var current_act: int = 1
var selected_idx: int = 0
var _carousel_offset: float = 0.0
var _entrance_anim: float = 1.0
var _pulse: float = 0.0

var _cyber_bg := CyberBackgroundClass.new()
var _spectrum_viz := AudioSpectrumVisualizerClass.new(32)
var _cinematic_overlay: Control

# Mini-map cache: json_path -> Dictionary {nodes, edges}
var _minimap_cache: Dictionary = {}

# Rects interactivos para mouse y pantalla táctil
var _back_rect: Rect2 = Rect2()
var _act1_rect: Rect2 = Rect2()
var _act2_rect: Rect2 = Rect2()
var _deploy_rect: Rect2 = Rect2()
var _lore_rect: Rect2 = Rect2()
var _card_rects: Array[Rect2] = []

var _drag_start_x: float = 0.0
var _is_dragging: bool = false
var _hovered_deploy: bool = false
var _hovered_lore: bool = false
var _hovered_back: bool = false

var _pending_launch_after_cinematic: bool = false
var _pending_launch_node_id: String = ""
var _force_autoplay_in_headless: bool = false

# Compatibilidad con código previo
var _selected_node: String:
	get: return str(_get_global_level_index(selected_idx))
	set(val):
		var g_idx := int(val)
		if g_idx >= 5:
			current_act = 2
			selected_idx = g_idx - 5
		else:
			current_act = 1
			selected_idx = g_idx


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 10
	small_font_size = maxi(10, font_size - 2)

	_cinematic_overlay = CinematicOverlayClass.new()
	add_child(_cinematic_overlay)
	_cinematic_overlay.cinematic_finished.connect(_on_cinematic_finished)

	var sp = get_node_or_null("/root/SceneParams")
	if sp and sp.titulo_nivel != "":
		world_id = sp.titulo_nivel

	progress = ProgressUtil.cargar_progreso()
	if DisplayServer.get_name() != "headless" and not ProgressUtil.is_world_unlocked(world_id, progress):
		push_warning("LevelSelectScreen: el mundo '%s' está bloqueado. Redirigiendo a menú principal." % world_id)
		var st = get_node_or_null("/root/SceneTransition")
		if st and st.has_method("dive_out_to_scene"):
			st.dive_out_to_scene("res://escenas/main_menu.tscn")
		elif get_tree():
			get_tree().change_scene_to_file("res://escenas/main_menu.tscn")
		return

	_load_world_data()

	var am = get_node_or_null("/root/AudioManager")
	if am != null:
		if am.has_method("play_world_music"):
			am.play_world_music(world_id, 0)
		elif am.has_method("play_menu_music"):
			am.play_menu_music()

	_entrance_anim = 0.0
	queue_redraw()


func setup(p_world_id: String) -> void:
	world_id = p_world_id
	_load_world_data()


func _load_world_data() -> void:
	var LevelManagerClass = load("res://juego/system/level_manager.gd")
	if LevelManagerClass:
		var worlds: Dictionary = LevelManagerClass.get_worlds()
		if worlds.has(world_id):
			var world: Dictionary = worlds[world_id]
			world_title = world.get("title", world_id)
			level_nodes = world.get("levels", [])
	if level_nodes.is_empty():
		var reg_world: Dictionary = LevelRegistry.get_world(world_id)
		world_title = reg_world.get("title", world_id)
		level_nodes = reg_world.get("levels", [])
	_entrance_anim = 0.0


func set_act(act_num: int) -> void:
	var new_act := clampi(act_num, 1, 2)
	if current_act != new_act:
		current_act = new_act
		selected_idx = 0
		_carousel_offset = 0.0
		_entrance_anim = 0.0
		_play_sfx("click")
		queue_redraw()


func get_act() -> int:
	return current_act


func _get_current_act_levels() -> Array:
	var act_levels: Array = []
	for i in level_nodes.size():
		var node_data: Dictionary = level_nodes[i]
		var node_act: int = node_data.get("act", 1 if i < 5 else 2)
		if node_act == current_act:
			act_levels.append(node_data)
	return act_levels


func _get_global_level_index(act_idx: int) -> int:
	if current_act == 1:
		return act_idx
	return act_idx + 5


func _is_level_unlocked(global_index: int) -> bool:
	if global_index == 0:
		return true
	if global_index >= level_nodes.size():
		return false
	var prev_node: Dictionary = level_nodes[global_index - 1]
	var prev_json_path: String = prev_node.get("path", "")
	var file_name: String = prev_json_path.get_file().trim_suffix(".json")
	if file_name == "":
		var prev_key: String = "%s_%d" % [world_id, global_index - 1]
		return progress.get(prev_key, 0) > 0
	return progress.get(file_name, 0) > 0


func _play_level(node_id: String) -> void:
	var idx := int(node_id)
	var node_pos := Vector2.ZERO
	if idx >= 0 and idx < level_nodes.size():
		node_pos = _get_node_position(level_nodes[idx], idx)
	var st = get_node_or_null("/root/SceneTransition")
	if st and st.has_method("set_next_dive_origin"):
		st.set_next_dive_origin(node_pos)
	var LevelManagerClass = load("res://juego/system/level_manager.gd")
	LevelManagerClass.launch_level(world_id, idx)


func _get_spine_node_position(act_index: int, vp: Vector2 = Vector2.ZERO) -> Vector2:
	if vp == Vector2.ZERO:
		vp = get_viewport_rect().size
	var spine_start := Vector2(vp.x * 0.14, vp.y * 0.54)
	var spine_end := Vector2(vp.x * 0.82, vp.y * 0.30)
	var t := float(act_index) / 4.0
	var spine_dir := (spine_end - spine_start).normalized()
	var base_pos := spine_start.lerp(spine_end, t)
	var shift := (float(act_index) - _carousel_offset) * (vp.x * 0.035)
	return base_pos + spine_dir * shift


func get_spine_node_position(act_index: int, vp: Vector2 = Vector2.ZERO) -> Vector2:
	return _get_spine_node_position(act_index, vp)


func _get_node_position(_node_data: Dictionary, index: int) -> Vector2:
	var act_idx := index if current_act == 1 else (index - 5)
	return _get_spine_node_position(act_idx)


func get_bottom_command_column_rects(vp: Vector2 = Vector2.ZERO) -> Array[Rect2]:
	if vp == Vector2.ZERO:
		vp = get_viewport_rect().size
	var col1 := Rect2(40.0, vp.y - 144.0, 230.0, 116.0)
	var col2 := Rect2(280.0, vp.y - 146.0, 220.0, 118.0)
	var cta_x := vp.x - 24.0 - 215.0 - 10.0
	var col3_w := (cta_x - 14.0) - 514.0
	var col3 := Rect2(514.0, vp.y - 144.0, col3_w, 116.0)
	var col4 := Rect2(cta_x, vp.y - 146.0, 215.0, 88.0)
	return [col1, col2, col3, col4]


func _go_back() -> void:
	_play_sfx("click")
	var sp = get_node_or_null("/root/SceneParams")
	if sp:
		sp.menu_target_state = "world_select"
	var vp: Vector2 = get_viewport_rect().size
	var back_pos := Vector2(140.0, vp.y - 31.0)
	var st = get_node_or_null("/root/SceneTransition")
	if st and st.has_method("dive_out_to_scene"):
		st.dive_out_to_scene("res://escenas/main_menu.tscn", back_pos)
	elif get_tree():
		get_tree().change_scene_to_file("res://escenas/main_menu.tscn")


func _play_sfx(sfx_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx(sfx_name)


func _on_cinematic_finished(cin_id: String) -> void:
	ProgressUtil.mark_cinematic_seen(cin_id, progress)
	if _pending_launch_after_cinematic:
		_pending_launch_after_cinematic = false
		_play_level(_pending_launch_node_id)
	queue_redraw()


func _should_autoplay_cinematic(cin_id: String) -> bool:
	if cin_id.is_empty():
		return false
	if ProgressUtil.has_seen_cinematic(cin_id, progress):
		return false
	if DisplayServer.get_name() == "headless" and not _force_autoplay_in_headless:
		return false
	return true


func _input(event: InputEvent) -> void:
	if _cinematic_overlay and _cinematic_overlay.is_playing():
		return

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_go_back()
			KEY_TAB:
				set_act(2 if current_act == 1 else 1)
			KEY_A, KEY_LEFT:
				_select_delta(-1)
			KEY_D, KEY_RIGHT:
				_select_delta(1)
			KEY_ENTER, KEY_SPACE:
				_deploy_selected()
			KEY_L, KEY_C:
				_open_selected_cinematic()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var mpos := mb.position

		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_select_delta(-1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_select_delta(1)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_start_x = mpos.x

				if _back_rect.has_point(mpos):
					_go_back()
					return
				if _act1_rect.has_point(mpos):
					set_act(1)
					return
				if _act2_rect.has_point(mpos):
					set_act(2)
					return
				if _deploy_rect.has_point(mpos):
					_deploy_selected()
					return
				if _lore_rect.has_point(mpos):
					_open_selected_cinematic()
					return

				# Selección de tarjeta en la espina 3D
				for i in range(_card_rects.size()):
					if _card_rects[i].has_point(mpos):
						if selected_idx == i:
							_deploy_selected()
						else:
							selected_idx = i
							_play_sfx("click")
							queue_redraw()
						return
			else:
				_is_dragging = false

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var prev_dep := _hovered_deploy
		var prev_lore := _hovered_lore
		var prev_back := _hovered_back
		_hovered_deploy = _deploy_rect.has_point(mpos)
		_hovered_lore = _lore_rect.has_point(mpos)
		_hovered_back = _back_rect.has_point(mpos)
		if prev_dep != _hovered_deploy or prev_lore != _hovered_lore or prev_back != _hovered_back:
			queue_redraw()

	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var tpos := st.position
		if st.pressed:
			_is_dragging = true
			_drag_start_x = tpos.x
			if _back_rect.has_point(tpos):
				_go_back()
				return
			if _act1_rect.has_point(tpos):
				set_act(1)
				return
			if _act2_rect.has_point(tpos):
				set_act(2)
				return
			if _deploy_rect.has_point(tpos):
				_deploy_selected()
				return
			if _lore_rect.has_point(tpos):
				_open_selected_cinematic()
				return
			for i in range(_card_rects.size()):
				if _card_rects[i].has_point(tpos):
					if selected_idx == i:
						_deploy_selected()
					else:
						selected_idx = i
						_play_sfx("click")
						queue_redraw()
					return
		else:
			_is_dragging = false

	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if absf(sd.relative.x) > 12.0:
			if sd.relative.x < 0:
				_select_delta(1)
			else:
				_select_delta(-1)


func _select_delta(delta_idx: int) -> void:
	var total_cards := 5
	var next_idx: int = clampi(selected_idx + delta_idx, 0, total_cards - 1)
	if next_idx != selected_idx:
		selected_idx = next_idx
		_play_sfx("click")
		queue_redraw()


func _deploy_selected() -> void:
	var g_idx := _get_global_level_index(selected_idx)
	if g_idx >= level_nodes.size() or not _is_level_unlocked(g_idx):
		_play_sfx("error")
		return

	_play_sfx("click")
	var lvl_data: Dictionary = level_nodes[g_idx]
	var path: String = lvl_data.get("path", "")
	var level_key := path.get_file().trim_suffix(".json")
	var cin := CinematicRegistryClass.get_cinematic_for_level(level_key)
	var cin_id: String = cin.get("id", "")

	if _should_autoplay_cinematic(cin_id):
		_pending_launch_after_cinematic = true
		_pending_launch_node_id = str(g_idx)
		if _cinematic_overlay:
			_cinematic_overlay.play_cinematic_data(cin)
		return

	_play_level(str(g_idx))


func _launch_selected() -> void:
	_deploy_selected()


func _open_selected_cinematic() -> void:
	var g_idx := _get_global_level_index(selected_idx)
	if g_idx >= level_nodes.size():
		return
	var lvl_data: Dictionary = level_nodes[g_idx]
	var path: String = lvl_data.get("path", "")
	var level_key := path.get_file().trim_suffix(".json")
	var cin := CinematicRegistryClass.get_cinematic_for_level(level_key)
	if not cin.is_empty() and _cinematic_overlay:
		_pending_launch_after_cinematic = false
		_play_sfx("click")
		_cinematic_overlay.play_cinematic_data(cin)


func _process(delta: float) -> void:
	_pulse += delta * 2.2
	_cyber_bg.update(delta, get_viewport_rect().size)
	_spectrum_viz.update(delta)

	_carousel_offset = lerpf(_carousel_offset, float(selected_idx), clampf(delta * 12.0, 0.0, 1.0))

	if _entrance_anim < 1.0:
		_entrance_anim = minf(1.0, _entrance_anim + delta * 2.4)

	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	var theme_col: Color = BrandClass.get_world_color(world_id)
	var bg_col: Color = BrandClass.get_world_bg_color(world_id)

	# Fondo interactivo con partículas
	_cyber_bg.draw(self, vp, 0.0, theme_col, bg_col)

	# Vanishing point perspective rings en el horizonte profundo
	_draw_horizon_perspective_rings(vp, theme_col)

	# Espina 3D diagonal abierta (80% del lienzo superior libre de barras que corten la pantalla)
	_draw_3d_spine_and_nodes(vp, theme_col)

	# Encabezado flotante superior izquierdo e isla central de Actos
	_draw_floating_header(vp, theme_col)

	# Barra inferior horizontal de comando (4 columnas estrictamente no superpuestas)
	_draw_bottom_command_strip(vp, theme_col)


func _draw_horizon_perspective_rings(vp: Vector2, theme_col: Color) -> void:
	var horizon_cx := vp.x * 0.77
	var horizon_cy := vp.y * 0.31
	var bass_energy: float = _spectrum_viz.get_bass_energy()
	var pulse_boost := bass_energy * 14.0

	var ring_configs := [
		{"rx": 90.0, "ry": 50.0, "cx_off": 0.0, "cy_off": 0.0, "alpha": 0.24, "dashed": false},
		{"rx": 190.0, "ry": 95.0, "cx_off": -115.0, "cy_off": 28.0, "alpha": 0.18, "dashed": true},
		{"rx": 320.0, "ry": 150.0, "cx_off": -250.0, "cy_off": 60.0, "alpha": 0.12, "dashed": true}
	]

	for cfg: Dictionary in ring_configs:
		var center := Vector2(horizon_cx + cfg["cx_off"], horizon_cy + cfg["cy_off"])
		var rx: float = cfg["rx"] + pulse_boost * 1.5
		var ry: float = cfg["ry"] + pulse_boost
		var col: Color = BrandClass.with_alpha(theme_col, cfg["alpha"] * (0.85 + sin(_pulse * 1.8) * 0.15))

		var pts := PackedVector2Array()
		var segs := 48
		for s in range(segs):
			var a := float(s) * TAU / float(segs)
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		pts.append(pts[0])

		if cfg["dashed"]:
			for s in range(0, segs, 2):
				var p1 := pts[s]
				var p2 := pts[s + 1]
				draw_line(p1, p2, col, 1.2)
		else:
			draw_polyline(pts, col, 1.2)


func _draw_3d_spine_and_nodes(vp: Vector2, theme_col: Color) -> void:
	var spine_start := Vector2(vp.x * 0.14, vp.y * 0.54)
	var spine_end := Vector2(vp.x * 0.82, vp.y * 0.30)
	var bass_energy: float = _spectrum_viz.get_bass_energy()

	# 1. Onda Reactiva a lo largo de la espina 3D con pases glow, bloom y core
	_spectrum_viz.draw_spine_waveform(self, spine_start, spine_end, theme_col, 55.0, 90, 0.82)

	# 2. Línea guía de la espina 3D
	draw_line(spine_start, spine_end, BrandClass.with_alpha(theme_col, 0.30), 1.5)

	# 3. Nodos de misión ordenados por profundidad (de lejano a cercano para z-ordering)
	var total_nodes := 5
	var act_levels := _get_current_act_levels()

	_card_rects.clear()
	var rect_map: Dictionary = {}

	for i in range(total_nodes - 1, -1, -1):
		var g_idx := _get_global_level_index(i)
		var is_unlocked := _is_level_unlocked(g_idx)
		var is_selected := (i == selected_idx)

		var lvl_data: Dictionary = {}
		if i < act_levels.size():
			lvl_data = act_levels[i]

		var p := _get_spine_node_position(i, vp)
		var depth_t := float(i) / 4.0
		var persp_scale := lerpf(1.10, 0.72, depth_t)
		if is_selected:
			persp_scale *= 1.25

		var outer_r := 56.0 * persp_scale
		if is_selected:
			outer_r += bass_energy * 14.0

		rect_map[i] = Rect2(p.x - outer_r, p.y - outer_r, outer_r * 2.0, outer_r * 2.0)

		_draw_spine_mission_node(p, i, g_idx, lvl_data, is_selected, is_unlocked, persp_scale, outer_r, theme_col, bass_energy)

	for i in range(total_nodes):
		_card_rects.append(rect_map.get(i, Rect2()))


func _draw_spine_mission_node(
	p: Vector2,
	act_idx: int,
	global_idx: int,
	lvl_data: Dictionary,
	is_selected: bool,
	is_unlocked: bool,
	scale_val: float,
	outer_r: float,
	theme_col: Color,
	bass_energy: float
) -> void:
	var is_boss: bool = (act_idx == 4)
	var node_col: Color = Color("ff2a6d") if is_boss else (theme_col if is_unlocked else BrandClass.TEXT_DIM)

	# Halo resplandeciente exterior pulsante con el beat musical
	if is_selected:
		draw_circle(p, outer_r, BrandClass.with_alpha(node_col, 0.08 + bass_energy * 0.14))

	# Anillo objetivo exterior segmentado/punteado gigante (r = 56px escalado)
	_draw_dashed_ring(self, p, outer_r, BrandClass.with_alpha(node_col, 0.85 if is_selected else 0.35), 14, _pulse * 0.5, 1.6 if is_selected else 1.0)

	# Núcleo regular poligonal (Hexágono para N1..N4, Octágono para Boss N5)
	var sides := 8 if is_boss else 6
	var core_r := 34.0 * scale_val
	var rot_off := PI / 6.0 if not is_boss else PI / 8.0

	_draw_regular_polygon(self, p, core_r, sides, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.94), true, 1.0, rot_off)
	_draw_regular_polygon(self, p, core_r, sides, node_col, false, 2.8 if is_selected else 1.6, rot_off)

	# Núcleo interior palpitante
	var inner_r := 8.0 * scale_val + (bass_energy * 5.0 if is_selected else 0.0)
	draw_circle(p, inner_r, node_col)
	if is_selected:
		draw_circle(p, inner_r * 0.5, Color.WHITE)

	# Pill superior limpia: "N03 // Nombre"
	var title_str: String = lvl_data.get("title", "Misión")
	if not is_unlocked:
		title_str = "[ BLOQUEADO ]"
	var pill_str := ("BOSS // %s" if is_boss else ("N%02d // %s" % [global_idx + 1, title_str]))
	var pill_font_size := maxi(8, int((small_font_size - 1) * clampf(scale_val, 0.8, 1.15)))
	var str_sz := font.get_string_size(pill_str, HORIZONTAL_ALIGNMENT_LEFT, -1, pill_font_size)
	var pill_w := str_sz.x + 16.0
	var pill_h := 20.0 * clampf(scale_val, 0.85, 1.15)
	var pill_rect := Rect2(p.x - pill_w * 0.5, p.y - core_r - pill_h - 6.0, pill_w, pill_h)

	draw_rect(pill_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.92))
	draw_rect(pill_rect, BrandClass.with_alpha(node_col, 0.70 if is_selected else 0.35), false, 1.2)
	draw_string(font, Vector2(pill_rect.position.x + 8.0, pill_rect.position.y + pill_h * 0.72), pill_str, HORIZONTAL_ALIGNMENT_LEFT, -1, pill_font_size, node_col if is_unlocked else BrandClass.TEXT_DIM)

	# Etiqueta central: "N01", "N02", ..., "BOSS"
	var lbl_text := "BOSS" if is_boss else ("N%02d" % (global_idx + 1))
	var lbl_font_sz := maxi(9, int((small_font_size + 1) * scale_val))
	var lbl_sz := font.get_string_size(lbl_text, HORIZONTAL_ALIGNMENT_CENTER, -1, lbl_font_sz)
	draw_string(font, Vector2(p.x - lbl_sz.x * 0.5, p.y + lbl_sz.y * 0.35), lbl_text, HORIZONTAL_ALIGNMENT_LEFT, -1, lbl_font_sz, node_col if is_unlocked else BrandClass.TEXT_DIM)

	# Calificación de estrellas abajo: "★ ★ ☆"
	var json_path: String = lvl_data.get("path", "")
	var level_key: String = json_path.get_file().trim_suffix(".json")
	if level_key == "":
		level_key = "%s_%d" % [world_id, global_idx]
	var stars: int = progress.get(level_key, 0)
	var stars_text := ""
	for s in range(3):
		stars_text += "★ " if s < stars else "☆ "
	var star_col := Color(1.0, 0.85, 0.2) if stars > 0 else BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.45)
	var star_font_sz := maxi(9, int(small_font_size * scale_val))
	var star_sz := font.get_string_size(stars_text.strip_edges(), HORIZONTAL_ALIGNMENT_CENTER, -1, star_font_sz)
	draw_string(font, Vector2(p.x - star_sz.x * 0.5, p.y + core_r + 20.0 * scale_val), stars_text.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, star_font_sz, star_col)


func _draw_regular_polygon(canvas: CanvasItem, center: Vector2, radius: float, sides: int, color: Color, filled: bool = false, width: float = 1.5, rot_offset: float = 0.0) -> void:
	var pts := PackedVector2Array()
	for s in range(sides):
		var a := rot_offset + float(s) * TAU / float(sides)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	if filled:
		canvas.draw_colored_polygon(pts, color)
	else:
		pts.append(pts[0])
		canvas.draw_polyline(pts, color, width)


func _draw_dashed_ring(canvas: CanvasItem, center: Vector2, radius: float, color: Color, segments: int = 14, rot_offset: float = 0.0, width: float = 1.5) -> void:
	var step := TAU / float(segments)
	for s in range(segments):
		if s % 2 == 0:
			var a1 := rot_offset + float(s) * step
			var a2 := a1 + step * 0.65
			canvas.draw_arc(center, radius, a1, a2, 8, color, width)


func _get_world_display_title() -> String:
	match world_id:
		"heist": return "HEIST // COLD STORAGE"
		"hacker": return "HACKER // DMZ & SWITCHES"
		"cybersecurity": return "CYBERSECURITY // NOC SOC"
		"secret": return "SECTOR 0 // KERNEL HYPERVISOR"
		_: return world_title.to_upper()


func _get_world_operator_subtitle() -> String:
	match world_id:
		"heist": return "OPERADORA: VEX · DAEMON EXFIL"
		"hacker": return "OPERADOR: N0X · DAEMON FUZZ"
		"cybersecurity": return "OPERADORA: AEGIS · DAEMON CORDON"
		"secret": return "ARQUITECTO: ZERO · DAEMON ROOT"
		_: return "SECTOR DE OPERACIONES // RED CONECTADA"


func _get_operator_log_prefix(op_name: String) -> String:
	match op_name.to_upper():
		"VEX": return "[VEX // LOG]:"
		"N0X": return "[N0X // LOG]:"
		"AEGIS": return "[AEGIS // SOC]:"
		"ZERO", "KAIN": return "[KAIN // TCP_GHOST]:"
		_: return "[%s // LOG]:" % op_name


func _draw_floating_header(vp: Vector2, theme_col: Color) -> void:
	# Isla Flotante Superior Izquierda (Rect2(24, 18, 380, 50))
	_back_rect = Rect2(24.0, 18.0, 380.0, 50.0)
	draw_rect(_back_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	draw_rect(_back_rect, BrandClass.with_alpha(theme_col, 0.55), false, 1.2)
	draw_rect(Rect2(_back_rect.position.x, _back_rect.position.y, 4.0, _back_rect.size.y), theme_col)

	var esc_btn_rect := Rect2(_back_rect.position.x + 12.0, _back_rect.position.y + 9.0, 68.0, 32.0)
	draw_rect(esc_btn_rect, BrandClass.with_alpha(theme_col, 0.22 if _hovered_back else 0.08))
	draw_rect(esc_btn_rect, theme_col if _hovered_back else BrandClass.with_alpha(theme_col, 0.40), false, 1.0)
	draw_string(font, Vector2(esc_btn_rect.position.x + 10, esc_btn_rect.position.y + 21), "◂ ESC", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 1, BrandClass.TEXT)

	var wt := _get_world_display_title()
	draw_string(font, Vector2(_back_rect.position.x + 92.0, _back_rect.position.y + 24.0), wt, HORIZONTAL_ALIGNMENT_LEFT, _back_rect.size.x - 100.0, small_font_size + 1, theme_col)
	var sub := _get_world_operator_subtitle()
	draw_string(font, Vector2(_back_rect.position.x + 92.0, _back_rect.position.y + 42.0), sub, HORIZONTAL_ALIGNMENT_LEFT, _back_rect.size.x - 100.0, small_font_size - 2, BrandClass.TEXT_DIM)

	# Selector Flotante Superior Central de Actos
	var total_w := 280.0
	var start_x := (vp.x - total_w) * 0.5
	var pill_w := 134.0
	var pill_h := 34.0
	_act1_rect = Rect2(start_x, 18.0, pill_w, pill_h)
	_act2_rect = Rect2(start_x + pill_w + 12.0, 18.0, pill_w, pill_h)

	_draw_act_pill(_act1_rect, "[ ACTO I (N1–N5) ]", current_act == 1, theme_col)
	_draw_act_pill(_act2_rect, "[ ACTO II (N6–N10) ]", current_act == 2, theme_col)


func _draw_act_pill(rect: Rect2, label: String, is_active: bool, theme_col: Color) -> void:
	if is_active:
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
		draw_rect(rect, theme_col, false, 2.0)
		draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - 3.0, rect.size.x, 3.0), theme_col)
		draw_string(font, Vector2(rect.position.x + 12, rect.position.y + 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, theme_col)
	else:
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.45))
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.35), false, 1.0)
		draw_string(font, Vector2(rect.position.x + 12, rect.position.y + 22), label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 1, BrandClass.TEXT_DIM)


func _draw_bottom_command_strip(vp: Vector2, theme_col: Color) -> void:
	var strip_rect := Rect2(24.0, vp.y - 154.0, vp.x - 48.0, 136.0)
	draw_rect(strip_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
	draw_rect(strip_rect, BrandClass.with_alpha(theme_col, 0.65), false, 1.2)
	_draw_corner_brackets(strip_rect, theme_col)

	var g_idx := _get_global_level_index(selected_idx)
	var is_unlocked := _is_level_unlocked(g_idx)
	var lvl_data: Dictionary = {}
	if g_idx < level_nodes.size():
		lvl_data = level_nodes[g_idx]

	var json_path: String = lvl_data.get("path", "")
	var title_str: String = lvl_data.get("title", "Misión Clasificada")
	var difficulty: int = lvl_data.get("difficulty", 1)
	var briefing_text: String = LevelRegistry.get_level_briefing(world_id, g_idx)
	var operator_id: String = LevelRegistry.get_level_operator(world_id, g_idx)
	var level_key := json_path.get_file().trim_suffix(".json")

	# Column 1 (w = 230px, x = 40)
	var tag_str := "MISIÓN %02d // ACTO %s" % [g_idx + 1, "I" if current_act == 1 else "II"]
	draw_string(font, Vector2(40.0, vp.y - 128.0), tag_str, HORIZONTAL_ALIGNMENT_LEFT, 230.0, small_font_size - 1, theme_col)
	draw_string(font, Vector2(40.0, vp.y - 104.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, 230.0, font_size + 1, BrandClass.TEXT)

	var diff_bars := ""
	for d in range(5):
		diff_bars += "///" if d < difficulty else " - "
	var deg_val := 2.2 + float(g_idx) * 0.4
	var ms_val := 8 + g_idx * 3
	var meta_str := "Dif %s · deg(G)=%.1f · %d ms" % [diff_bars, deg_val, ms_val]
	draw_string(font, Vector2(40.0, vp.y - 82.0), meta_str, HORIZONTAL_ALIGNMENT_LEFT, 230.0, small_font_size - 2, BrandClass.TEXT_DIM)

	var stars: int = progress.get(level_key, 0)
	var stars_text := ""
	for s in range(3):
		stars_text += "★ " if s < stars else "☆ "
	var star_col := Color(1.0, 0.85, 0.2) if stars > 0 else BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.4)
	draw_string(font, Vector2(40.0, vp.y - 58.0), stars_text.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, 230.0, small_font_size + 1, star_col)

	# Column 2 (w = 220px, x = 280) - Live Topology Mini-Map Box
	var minimap_rect := Rect2(280.0, vp.y - 146.0, 220.0, 118.0)
	_draw_live_minimap(minimap_rect, json_path, theme_col, is_unlocked)

	# Column 3 (flex 1, x = 514, w = (cta_x - 14) - 514) - Operator Narrative Description
	var cta_x := vp.x - 24.0 - 215.0 - 10.0
	draw_line(Vector2(506.0, vp.y - 144.0), Vector2(506.0, vp.y - 28.0), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.70), 1.5)

	var prefix := _get_operator_log_prefix(operator_id)
	var lore_text := briefing_text
	if not is_unlocked:
		lore_text = "Acceso denegado. Se requiere completar la misión anterior para desbloquear el vector de intrusión."
	var full_desc := "%s %s" % [prefix, lore_text]
	var col3_w := (cta_x - 14.0) - 514.0
	var wrapped := _wrap_text(full_desc, font, small_font_size, col3_w)
	var ly := vp.y - 124.0
	for line in wrapped:
		draw_string(font, Vector2(514.0, ly), line, HORIZONTAL_ALIGNMENT_LEFT, col3_w, small_font_size, BrandClass.TEXT)
		ly += 18.0

	# Column 4 (w = 215px, x = cta_x) - Primary and Secondary CTA Buttons
	_deploy_rect = Rect2(cta_x, vp.y - 144.0, 215.0, 44.0)
	var dep_col := BrandClass.SUCCESS if is_unlocked else BrandClass.TEXT_DIM
	var dep_bg := BrandClass.with_alpha(dep_col, 0.28 if _hovered_deploy else 0.14)
	draw_rect(_deploy_rect, dep_bg)
	draw_rect(_deploy_rect, dep_col, false, 1.5)
	draw_string(font, Vector2(_deploy_rect.position.x + 18, _deploy_rect.position.y + 27), "[ ▶ DESPLEGAR (ENTER) ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, dep_col)

	_lore_rect = Rect2(cta_x, vp.y - 92.0, 215.0, 34.0)
	var cin := CinematicRegistryClass.get_cinematic_for_level(level_key)
	var cin_id: String = cin.get("id", "")
	var is_new := (cin_id != "" and not ProgressUtil.has_seen_cinematic(cin_id, progress))

	var lore_bg := BrandClass.with_alpha(theme_col, 0.22 if _hovered_lore else 0.08)
	draw_rect(_lore_rect, lore_bg)
	draw_rect(_lore_rect, BrandClass.with_alpha(theme_col, 0.50 if not _hovered_lore else 0.90), false, 1.2)
	draw_string(font, Vector2(_lore_rect.position.x + 14, _lore_rect.position.y + 22), "[ 🎬 CODEC / LORE ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 1, theme_col)

	if is_new:
		var pip_col := BrandClass.with_alpha(BrandClass.SUCCESS, 0.6 + sin(_pulse * 3.5) * 0.4)
		draw_string(font, Vector2(_lore_rect.position.x + _lore_rect.size.x - 64, _lore_rect.position.y + 22), "● NUEVO", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, pip_col)


func _draw_live_minimap(rect: Rect2, json_path: String, theme_col: Color, is_unlocked: bool) -> void:
	draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
	draw_rect(rect, BrandClass.with_alpha(theme_col, 0.40), false, 1.0)
	draw_string(font, Vector2(rect.position.x + 10, rect.position.y + 18), "[ TOPOLOGÍA DE RED ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, theme_col)

	if not is_unlocked:
		draw_string(font, Vector2(rect.position.x + 40, rect.position.y + rect.size.y * 0.5), "[ ENCRIPTADO ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)
		return

	var map_data: Dictionary = _get_or_load_minimap(json_path)
	var nodes: Array = map_data.get("nodes", [])
	var edges: Array = map_data.get("edges", [])

	if nodes.is_empty():
		draw_string(font, Vector2(rect.position.x + 30, rect.position.y + rect.size.y * 0.5), "[ TOPOLOGÍA N/A ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)
		return

	var edge_col := BrandClass.with_alpha(theme_col, 0.35)
	for e: Vector2i in edges:
		if e.x < nodes.size() and e.y < nodes.size():
			var p1: Vector2 = _norm_to_rect(nodes[e.x]["pos"], rect)
			var p2: Vector2 = _norm_to_rect(nodes[e.y]["pos"], rect)
			draw_line(p1, p2, edge_col, 1.5)

	for i in range(nodes.size()):
		var n: Dictionary = nodes[i]
		var pt: Vector2 = _norm_to_rect(n["pos"], rect)
		var is_start: bool = n.get("is_start", false)
		var is_target: bool = n.get("is_target", false)
		var col: Color = BrandClass.ACCENT if is_start else (BrandClass.WARNING if is_target else theme_col)
		draw_circle(pt, 4.0, col)
		draw_circle(pt, 2.0, Color.WHITE)


func _get_or_load_minimap(json_path: String) -> Dictionary:
	if _minimap_cache.has(json_path):
		return _minimap_cache[json_path]

	var result := {"nodes": [], "edges": []}
	if json_path == "" or not FileAccess.file_exists(json_path):
		_minimap_cache[json_path] = result
		return result

	var lvl_data := LevelRegistry.load_level_data(json_path)
	var graph_path: String = lvl_data.get("graph_path", "")
	var start_id: String = lvl_data.get("start_node", "")
	var target_id: String = lvl_data.get("target_node", "")

	if graph_path != "" and ResourceLoader.exists(graph_path):
		var graph_res = load(graph_path) as NetworkGraphResource
		if graph_res:
			var raw_nodes: Array = graph_res.nodes
			var id_to_idx: Dictionary = {}
			var min_p := Vector2(INF, INF)
			var max_p := Vector2(-INF, -INF)

			for i in range(raw_nodes.size()):
				var n: NetworkNodeResource = raw_nodes[i]
				if n:
					id_to_idx[str(n.id)] = i
					min_p.x = minf(min_p.x, n.position.x)
					min_p.y = minf(min_p.y, n.position.y)
					max_p.x = maxf(max_p.x, n.position.x)
					max_p.y = maxf(max_p.y, n.position.y)

			var span := max_p - min_p
			if span.x < 1.0: span.x = 1.0
			if span.y < 1.0: span.y = 1.0

			var parsed_nodes: Array = []
			for i in range(raw_nodes.size()):
				var n: NetworkNodeResource = raw_nodes[i]
				if n:
					var norm_pos := Vector2(
						(n.position.x - min_p.x) / span.x,
						(n.position.y - min_p.y) / span.y
					)
					parsed_nodes.append({
						"pos": norm_pos,
						"is_start": (str(n.id) == start_id),
						"is_target": (str(n.id) == target_id)
					})
			result["nodes"] = parsed_nodes

			var parsed_edges: Array = []
			for e in graph_res.edges:
				if e and id_to_idx.has(str(e.from_id)) and id_to_idx.has(str(e.to_id)):
					parsed_edges.append(Vector2i(id_to_idx[str(e.from_id)], id_to_idx[str(e.to_id)]))
			result["edges"] = parsed_edges

	_minimap_cache[json_path] = result
	return result


func _norm_to_rect(norm_pos: Vector2, rect: Rect2) -> Vector2:
	var pad := 24.0
	var inner_w := rect.size.x - pad * 2.0
	var inner_h := rect.size.y - pad * 2.0 - 20.0
	return Vector2(
		rect.position.x + pad + norm_pos.x * inner_w,
		rect.position.y + pad + 20.0 + norm_pos.y * inner_h
	)


func _draw_corner_brackets(rect: Rect2, col: Color) -> void:
	var sz := 12.0
	var c_col := BrandClass.with_alpha(col, 0.8)
	# TL
	draw_line(rect.position, rect.position + Vector2(sz, 0), c_col, 2.0)
	draw_line(rect.position, rect.position + Vector2(0, sz), c_col, 2.0)
	# TR
	draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x - sz, rect.position.y), c_col, 2.0)
	draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + sz), c_col, 2.0)
	# BL
	draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x + sz, rect.position.y + rect.size.y), c_col, 2.0)
	draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y), Vector2(rect.position.x, rect.position.y + rect.size.y - sz), c_col, 2.0)
	# BR
	draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(sz, 0), c_col, 2.0)
	draw_line(rect.position + rect.size, rect.position + rect.size - Vector2(0, sz), c_col, 2.0)


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
