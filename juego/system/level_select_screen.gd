extends Control

## Selector de Niveles Táctico 2.5D + Multi-Acto + Ficha Holográfica y Mini-Mapa en Vivo.
## Muestra los niveles del mundo en un carrusel interactivo 2.5D con animación stagger,
## onda de audio reactiva a lo largo del riel, conmutador de actos (I / II) y reproductor de cinemáticas.

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
	if not ProgressUtil.is_world_unlocked(world_id, progress):
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
	var worlds: Dictionary = LevelManagerClass.get_worlds()
	if not worlds.has(world_id):
		return
	var world: Dictionary = worlds[world_id]
	world_title = world.get("title", world_id)
	level_nodes = world.get("levels", [])
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


func _get_node_position(node_data: Dictionary, index: int) -> Vector2:
	if node_data.has("pos"):
		var pos_arr: Array = node_data["pos"]
		return Vector2(pos_arr[0], pos_arr[1])
	var vp: Vector2 = get_viewport_rect().size
	var spacing: float = 240.0
	var act_idx := index if current_act == 1 else (index - 5)
	var count := 5
	var start_x: float = (vp.x - (count - 1) * spacing) / 2.0
	return Vector2(start_x + act_idx * spacing, vp.y * 0.32)


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


func _on_cinematic_finished(_cin_id: String) -> void:
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _cinematic_overlay and _cinematic_overlay.is_playing():
		return

	var vp := get_viewport_rect().size

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

				# Selección de tarjeta en carrusel
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
	var total_cards := 5 # Cada acto tiene 5 misiones
	var next_idx: int = clampi(selected_idx + delta_idx, 0, total_cards - 1)
	if next_idx != selected_idx:
		selected_idx = next_idx
		_play_sfx("click")
		queue_redraw()


func _deploy_selected() -> void:
	var g_idx := _get_global_level_index(selected_idx)
	if g_idx < level_nodes.size() and _is_level_unlocked(g_idx):
		_play_sfx("click")
		_play_level(str(g_idx))
	else:
		_play_sfx("error")


func _open_selected_cinematic() -> void:
	var g_idx := _get_global_level_index(selected_idx)
	if g_idx >= level_nodes.size():
		return
	var lvl_data: Dictionary = level_nodes[g_idx]
	var path: String = lvl_data.get("path", "")
	var level_key := path.get_file().trim_suffix(".json")
	var cin := CinematicRegistryClass.get_cinematic_for_level(level_key)
	if not cin.is_empty() and _cinematic_overlay:
		_play_sfx("click")
		_cinematic_overlay.play_cinematic_data(cin)


func _process(delta: float) -> void:
	_pulse += delta * 2.2
	_cyber_bg.update(delta, get_viewport_rect().size)
	_spectrum_viz.update(delta)

	# Suavizado de offset del carrusel 2.5D
	_carousel_offset = lerpf(_carousel_offset, float(selected_idx), clampf(delta * 12.0, 0.0, 1.0))

	# Animación stagger de entrada
	if _entrance_anim < 1.0:
		_entrance_anim = minf(1.0, _entrance_anim + delta * 2.4)

	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	var theme_col: Color = BrandClass.get_world_color(world_id)
	var bg_col: Color = BrandClass.get_world_bg_color(world_id)

	# Fondo interactivo con partículas
	_cyber_bg.draw(self, vp, 0.0, theme_col, bg_col)

	# Barra superior: Título de mundo y selector de Actos
	_draw_header(vp, theme_col)

	# Carrusel 2.5D + Riel de audio reactivo
	_draw_carousel(vp, theme_col)

	# Ficha táctica holográfica del nivel seleccionado (con mini-mapa en vivo)
	_draw_briefing_card(vp, theme_col)

	# Botón Volver
	_draw_back_button(vp, theme_col)


func _draw_header(vp: Vector2, theme_col: Color) -> void:
	# Título de mundo y subtítulo táctico
	draw_string(font, Vector2(50, 42), world_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, theme_col)
	var subtitle := "SECTOR DE OPERACIONES // RED CONECTADA"
	draw_string(font, Vector2(50, 64), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.65, 0.72, 0.85))

	# Selector de Actos estilo Pill Bar en la parte superior central
	var pill_w := 120.0
	var pill_h := 32.0
	var pill_gap := 12.0
	var total_w := pill_w * 2.0 + pill_gap
	var start_x := (vp.x - total_w) * 0.5
	var pill_y := 26.0

	_act1_rect = Rect2(start_x, pill_y, pill_w, pill_h)
	_act2_rect = Rect2(start_x + pill_w + pill_gap, pill_y, pill_w, pill_h)

	_draw_act_pill(_act1_rect, "[ ACTO I ]", current_act == 1, theme_col)
	_draw_act_pill(_act2_rect, "[ ACTO II ]", current_act == 2, theme_col)


func _draw_act_pill(rect: Rect2, label: String, is_active: bool, theme_col: Color) -> void:
	if is_active:
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
		draw_rect(rect, theme_col, false, 2.0)
		draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y - 3.0, rect.size.x, 3.0), theme_col)
		draw_string(font, Vector2(rect.position.x + 18, rect.position.y + 21), label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size + 1, theme_col)
	else:
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.45))
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.35), false, 1.0)
		draw_string(font, Vector2(rect.position.x + 18, rect.position.y + 21), label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)


func _draw_carousel(vp: Vector2, theme_col: Color) -> void:
	var total_cards := 5
	var act_levels := _get_current_act_levels()
	var rail_y := vp.y * 0.28
	var center_x := vp.x * 0.5
	var card_spacing := 230.0

	# 1. Riel con Onda Reactiva de Audio detrás de las tarjetas
	var p_left := Vector2(center_x - 2.5 * card_spacing, rail_y)
	var p_right := Vector2(center_x + 2.5 * card_spacing, rail_y)
	_spectrum_viz.draw_track_waveform(self, p_left, p_right, theme_col, 55.0, 90, 0.75)

	# Línea de riel central
	draw_line(p_left, p_right, BrandClass.with_alpha(theme_col, 0.35), 2.0)

	_card_rects.clear()

	# 2. Dibujo de Tarjetas con perspectiva 2.5D (de afuera hacia adentro para z-ordering)
	var sorted_indices: Array[int] = []
	for i in range(total_cards):
		sorted_indices.append(i)
	sorted_indices.sort_custom(func(a: int, b: int) -> bool:
		return absf(float(a) - _carousel_offset) > absf(float(b) - _carousel_offset)
	)

	var card_rect_map: Dictionary = {}

	for i in sorted_indices:
		var rel_idx := float(i) - _carousel_offset
		var dist := absf(rel_idx)
		var scale_val := clampf(1.0 - dist * 0.18, 0.55, 1.15)
		var depth_alpha := clampf(1.0 - dist * 0.28, 0.25, 1.0)

		# Stagger entrance
		var stagger_delay := float(i) * 0.08
		var card_stagger := clampf((_entrance_anim - stagger_delay) / 0.45, 0.0, 1.0)
		var card_x := center_x + rel_idx * (card_spacing * (0.85 + scale_val * 0.15))
		var card_y := rail_y + (1.0 - card_stagger) * 40.0 + sin(rel_idx * 0.3) * 12.0

		var base_w := 170.0 * scale_val
		var base_h := 115.0 * scale_val
		var c_rect := Rect2(card_x - base_w * 0.5, card_y - base_h * 0.5, base_w, base_h)
		card_rect_map[i] = c_rect

		var g_idx := _get_global_level_index(i)
		var is_unlocked := _is_level_unlocked(g_idx)
		var is_selected := (i == selected_idx)

		var lvl_data: Dictionary = {}
		if i < act_levels.size():
			lvl_data = act_levels[i]

		_draw_carousel_card(c_rect, i, g_idx, lvl_data, is_selected, is_unlocked, scale_val, depth_alpha, theme_col)

	for i in range(total_cards):
		_card_rects.append(card_rect_map.get(i, Rect2()))


func _draw_carousel_card(
	rect: Rect2,
	act_idx: int,
	global_idx: int,
	lvl_data: Dictionary,
	is_selected: bool,
	is_unlocked: bool,
	card_scale: float,
	card_alpha: float,
	theme_col: Color
) -> void:
	# Fondo de la tarjeta
	var bg_color := BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90 * card_alpha)
	var border_color := BrandClass.with_alpha(theme_col, (0.95 if is_selected else 0.40) * card_alpha)

	if is_selected:
		# Resplandor exterior
		draw_rect(rect.grow(4.0), BrandClass.with_alpha(theme_col, 0.25 * (0.8 + sin(_pulse) * 0.2)), false, 2.5)

	draw_rect(rect, bg_color)
	draw_rect(rect, border_color, false, 1.8 if is_selected else 1.0)

	# Número de misión / Nivel
	var mission_num_str := "%02d" % (global_idx + 1)
	var num_col := (theme_col if is_unlocked else BrandClass.TEXT_DIM)
	draw_string(font, Vector2(rect.position.x + 10, rect.position.y + 22 * card_scale), "N-%s" % mission_num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(9, int(small_font_size * card_scale)), num_col)

	# Título del nivel
	var title_str: String = lvl_data.get("title", "CLASIFICADO")
	if not is_unlocked:
		title_str = "[ BLOQUEADO ]"
	draw_string(font, Vector2(rect.position.x + 10, rect.position.y + 44 * card_scale), title_str, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, maxi(9, int(font_size * card_scale)), BrandClass.TEXT if is_unlocked else BrandClass.TEXT_DIM)

	# Estrellas de progreso
	var json_path: String = lvl_data.get("path", "")
	var level_key: String = json_path.get_file().trim_suffix(".json")
	if level_key == "":
		level_key = "%s_%d" % [world_id, global_idx]
	var stars: int = progress.get(level_key, 0)

	var stars_text := ""
	for s in range(3):
		stars_text += "★ " if s < stars else "☆ "
	var star_col := Color(1.0, 0.85, 0.2) if stars > 0 else BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.5)
	draw_string(font, Vector2(rect.position.x + 10, rect.position.y + 72 * card_scale), stars_text.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(9, int(small_font_size * card_scale)), star_col)

	# Tag de estado
	var status_text := "LISTO" if is_unlocked else "LOCK"
	var status_col := BrandClass.SUCCESS if is_unlocked else BrandClass.DANGER
	draw_string(font, Vector2(rect.position.x + rect.size.x - 45 * card_scale, rect.position.y + 22 * card_scale), status_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, maxi(8, int((small_font_size - 2) * card_scale)), status_col)


func _draw_briefing_card(vp: Vector2, theme_col: Color) -> void:
	var card_w := minf(860.0, vp.x - 80.0)
	var card_h := 240.0
	var card_x := (vp.x - card_w) * 0.5
	var card_y := vp.y - card_h - 60.0
	var briefing_rect := Rect2(card_x, card_y, card_w, card_h)

	# Placa holográfica principal
	draw_rect(briefing_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.96))
	draw_rect(briefing_rect, BrandClass.with_alpha(theme_col, 0.70), false, 1.5)

	# Esquinas holográficas decorativas
	_draw_corner_brackets(briefing_rect, theme_col)

	var g_idx := _get_global_level_index(selected_idx)
	var is_unlocked := _is_level_unlocked(g_idx)
	var lvl_data: Dictionary = {}
	if g_idx < level_nodes.size():
		lvl_data = level_nodes[g_idx]

	var json_path: String = lvl_data.get("path", "")
	var title_str: String = lvl_data.get("title", "Operación Clasificada")
	var difficulty: int = lvl_data.get("difficulty", 1)
	var briefing_text: String = LevelRegistry.get_level_briefing(world_id, g_idx)
	var operator_id: String = LevelRegistry.get_level_operator(world_id, g_idx)

	# 1. Mini-Mapa Vectorial en vivo (Lado Izquierdo)
	var map_rect := Rect2(card_x + 20.0, card_y + 20.0, 220.0, card_h - 40.0)
	_draw_live_minimap(map_rect, json_path, theme_col, is_unlocked)

	# 2. Información Táctica y Narrativa (Centro)
	var text_x := card_x + 260.0
	var text_w := card_w - 280.0

	# Tag de Operador e ID de Misión
	var op_badge := "[ OP: %s // ACTO %s ]" % [operator_id, "I" if current_act == 1 else "II"]
	draw_string(font, Vector2(text_x, card_y + 36.0), op_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, theme_col)

	# Título de Nivel
	draw_string(font, Vector2(text_x, card_y + 60.0), title_str, HORIZONTAL_ALIGNMENT_LEFT, text_w - 180.0, font_size + 2, BrandClass.TEXT)

	# Calificación de Dificultad
	var diff_bars := ""
	for d in range(5):
		diff_bars += "///" if d < difficulty else " - "
	var diff_label := "DIFICULTAD: %s" % diff_bars
	draw_string(font, Vector2(text_x, card_y + 82.0), diff_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 1, BrandClass.WARNING)

	# Texto narrativo del Briefing
	if not is_unlocked:
		briefing_text = "Acceso denegado. Se requiere completar la misión anterior para desbloquear el vector de intrusión correspondiente a esta subred."

	var wrapped := _wrap_text(briefing_text, font, small_font_size, text_w - 200.0)
	var by := card_y + 110.0
	for line in wrapped:
		draw_string(font, Vector2(text_x, by), line, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)
		by += 18.0

	# 3. Botones de Acción (Lado Derecho / Inferior)
	var btn_w := 170.0
	var btn_h := 40.0
	var btn_x := card_x + card_w - btn_w - 20.0

	# Botón Iniciar Operación / Desplegar
	_deploy_rect = Rect2(btn_x, card_y + card_h - btn_h - 20.0, btn_w, btn_h)
	var dep_col := BrandClass.SUCCESS if is_unlocked else BrandClass.TEXT_DIM
	var dep_bg := BrandClass.with_alpha(dep_col, 0.25 if _hovered_deploy else 0.12)
	draw_rect(_deploy_rect, dep_bg)
	draw_rect(_deploy_rect, dep_col, false, 1.5)
	draw_string(font, Vector2(_deploy_rect.position.x + 14, _deploy_rect.position.y + 25), "[ ▶ INICIAR ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, dep_col)

	# Botón Transmisión / Lore (si hay cinemática disponible)
	var level_key := json_path.get_file().trim_suffix(".json")
	var cin := CinematicRegistryClass.get_cinematic_for_level(level_key)
	if not cin.is_empty():
		_lore_rect = Rect2(btn_x, card_y + card_h - btn_h * 2.0 - 30.0, btn_w, btn_h)
		var lore_bg := BrandClass.with_alpha(theme_col, 0.25 if _hovered_lore else 0.12)
		draw_rect(_lore_rect, lore_bg)
		draw_rect(_lore_rect, theme_col, false, 1.2)
		draw_string(font, Vector2(_lore_rect.position.x + 14, _lore_rect.position.y + 25), "[ 🎬 LORE ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, theme_col)
	else:
		_lore_rect = Rect2()


func _draw_live_minimap(rect: Rect2, json_path: String, theme_col: Color, is_unlocked: bool) -> void:
	# Marco del mini-mapa
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

	# Dibujar aristas normalizadas
	var edge_col := BrandClass.with_alpha(theme_col, 0.35)
	for e in edges:
		if e.x < nodes.size() and e.y < nodes.size():
			var p1: Vector2 = _norm_to_rect(nodes[e.x]["pos"], rect)
			var p2: Vector2 = _norm_to_rect(nodes[e.y]["pos"], rect)
			draw_line(p1, p2, edge_col, 1.5)

	# Dibujar vértices
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


func _draw_back_button(vp: Vector2, theme_col: Color) -> void:
	_back_rect = Rect2(40.0, vp.y - 48.0, 180.0, 34.0)
	var bg_col := BrandClass.with_alpha(theme_col, 0.18 if _hovered_back else 0.08)
	var border_col := theme_col if _hovered_back else BrandClass.with_alpha(theme_col, 0.35)
	draw_rect(_back_rect, bg_col)
	draw_rect(_back_rect, border_col, false, 1.2)
	draw_string(font, Vector2(_back_rect.position.x + 18, _back_rect.position.y + 22), "[ < VOLVER (ESC) ]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT)


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
