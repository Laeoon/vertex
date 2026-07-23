extends Control

## Selector de niveles estilo mapa de nodos (subway).
## Muestra los niveles disponibles de un mundo como nodos conectados por líneas.

var world_id: String = ""
var world_title: String = ""
var level_nodes: Array = []
var progress: Dictionary = {}
var font: Font
var font_size: int = 14
var big_font_size: int = 24
var small_font_size: int = 12
var _pulse: float = 0.0
var _selected_node: String = ""


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 10
	small_font_size = font_size - 2
	var sp = get_node_or_null("/root/SceneParams")
	if sp:
		world_id = sp.titulo_nivel
	progress = _cargar_progreso()
	_load_world_data()
	queue_redraw()


func _load_world_data() -> void:
	var LevelManagerClass = load("res://juego/system/level_manager.gd")
	var worlds: Dictionary = LevelManagerClass.get_worlds()
	if not worlds.has(world_id):
		return
	var world: Dictionary = worlds[world_id]
	world_title = world.get("title", world_id)
	level_nodes = world.get("levels", [])


func setup(p_world_id: String) -> void:
	world_id = p_world_id


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
			KEY_ENTER, KEY_SPACE:
				if _selected_node != "":
					_play_level(_selected_node)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos: Vector2 = event.position
		for i in level_nodes.size():
			var node_data: Dictionary = level_nodes[i]
			var node_pos: Vector2 = _get_node_position(node_data, i)
			if click_pos.distance_to(node_pos) < 30.0:
				var node_id: String = str(i)
				if _is_level_unlocked(i):
					_selected_node = node_id
					_play_level(node_id)
					return


func _get_node_position(node_data: Dictionary, index: int) -> Vector2:
	if node_data.has("pos"):
		var pos_arr: Array = node_data["pos"]
		return Vector2(pos_arr[0], pos_arr[1])
	var vp: Vector2 = get_viewport_rect().size
	var spacing: float = 250.0
	var start_x: float = (vp.x - (level_nodes.size() - 1) * spacing) / 2.0
	return Vector2(start_x + index * spacing, vp.y / 2.0)


func _is_level_unlocked(index: int) -> bool:
	if index == 0:
		return true
	# Usa el 'id' del JSON de nivel anterior como clave de progreso
	var prev_node: Dictionary = level_nodes[index - 1]
	var prev_json_path: String = prev_node.get("path", "")
	var file_name: String = prev_json_path.get_file().trim_suffix(".json")
	if file_name == "":
		var prev_key: String = "%s_%d" % [world_id, index - 1]
		return progress.get(prev_key, 0) > 0
	return progress.get(file_name, 0) > 0


func _play_level(node_id: String) -> void:
	var idx: int = int(node_id)
	var LevelManagerClass = load("res://juego/system/level_manager.gd")
	LevelManagerClass.launch_level(world_id, idx)


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()


func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.04, 0.04, 0.08))

	draw_string(font, Vector2(60, 50), world_title, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, Color(0.0, 1.0, 0.83))
	draw_string(font, Vector2(60, 75), "Selecciona un nivel", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.7, 0.75, 0.85))

	_draw_connections()
	_draw_nodes(vp)
	_draw_back_hint(vp)


func _draw_connections() -> void:
	for i in level_nodes.size() - 1:
		var from_data: Dictionary = level_nodes[i]
		var to_data: Dictionary = level_nodes[i + 1]
		var from_pos: Vector2 = _get_node_position(from_data, i)
		var to_pos: Vector2 = _get_node_position(to_data, i + 1)
		draw_line(from_pos, to_pos, Color(0.4, 0.45, 0.55, 0.7), 3.0)


func _draw_nodes(vp: Vector2) -> void:
	for i in level_nodes.size():
		var node_data: Dictionary = level_nodes[i]
		var pos: Vector2 = _get_node_position(node_data, i)
		var json_path: String = node_data.get("path", "")
		var level_key: String = json_path.get_file().trim_suffix(".json")
		if level_key == "":
			level_key = "%s_%d" % [world_id, i]
		var stars: int = progress.get(level_key, 0)
		var unlocked: bool = _is_level_unlocked(i)
		var is_selected: bool = str(i) == _selected_node

		var node_color: Color
		var border_color: Color
		var radius: float = 28.0

		if stars > 0:
			node_color = Color(1.0, 0.85, 0.0)
			border_color = Color(1.0, 0.95, 0.3)
		elif unlocked:
			var glow: float = 0.8 + sin(_pulse) * 0.2
			node_color = Color(0.0, 0.9, 0.6, glow)
			border_color = Color(0.0, 1.0, 0.83, glow)
		else:
			node_color = Color(0.15, 0.17, 0.22, 0.6)
			border_color = Color(0.25, 0.27, 0.32, 0.5)

		if is_selected and unlocked:
			radius += 6.0
			draw_circle(pos, radius + 8.0, Color(1.0, 0.4, 0.8, 0.3), false, 3.0)

		draw_circle(pos + Vector2(2, 3), radius, Color(0, 0, 0, 0.4))
		draw_circle(pos, radius, node_color)
		draw_circle(pos, radius, border_color, false, 3.0)

		var title: String = node_data.get("title", "Nivel %d" % (i + 1))
		var title_w: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x
		draw_rect(Rect2(pos.x - title_w / 2.0 - 6, pos.y + radius + 8, title_w + 12, 20), Color(0.04, 0.04, 0.08, 0.9))
		draw_rect(Rect2(pos.x - title_w / 2.0 - 6, pos.y + radius + 8, title_w + 12, 20), border_color, false, 1.0)
		draw_string(font, Vector2(pos.x - title_w / 2.0, pos.y + radius + 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color.WHITE if unlocked else Color(0.45, 0.45, 0.5))

		if stars > 0:
			var star_text: String = ""
			for s in range(3):
				star_text += "★" if s < stars else "☆"
			draw_string(font, Vector2(pos.x - 22, pos.y + radius + 42), star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(1.0, 0.9, 0.2))

		if not unlocked:
			draw_string(font, Vector2(pos.x - 5, pos.y + 6), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.5, 0.5, 0.55))


func _draw_back_hint(vp: Vector2) -> void:
	draw_string(font, Vector2(60, vp.y - 30), "[ESC] Volver al menú  |  [Enter] Jugar nivel seleccionado", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.45, 0.5, 0.6))


func _cargar_progreso() -> Dictionary:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load("user://progress.cfg")
	if err != OK:
		return {}
	var result: Dictionary = {}
	for k in cfg.get_section_keys("estrellas"):
		if k.ends_with("_mejor_coste"):
			continue
		result[k] = cfg.get_value("estrellas", k, 0)
	return result
