extends Control

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
var _cyber_bg := CyberBackgroundClass.new()

enum Track { GENERAL, HEIST, HACKER, DEFENDER }

const TRACK_METADATA: Dictionary = {
	Track.GENERAL: {
		"title": "GENERAL",
		"desc": "Fundamentos de Redes y Grafos",
	},
	Track.HEIST: {
		"title": "HEIST",
		"desc": "Infiltración Física y Evasión",
	},
	Track.HACKER: {
		"title": "HACKER",
		"desc": "Operaciones Cibernéticas y Exploits",
	},
	Track.DEFENDER: {
		"title": "DEFENDER",
		"desc": "Defensa Perimetral y Contramedidas Blue Team",
	},
}

var current_track: Track = Track.GENERAL
var font: Font
var font_size: int = 14
var big_font_size: int = 28
var selected_idx: int = 0
var progress: Dictionary = {}
var _pulse: float = 0.0

var track_lessons: Dictionary = {}


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14

	track_lessons = {
		Track.GENERAL: [
			{"label": "Módulo 1: Topología y Reconocimiento", "key": &"tutorial1", "desc": loc("tut1_desc")},
			{"label": "Módulo 2: Defensa en Capas y Rutas", "key": &"tutorial3", "desc": loc("tut3_desc")},
		],
		Track.HEIST: [
			{"label": "Módulo 1: Sensores y Perímetro", "key": &"tutorial2", "desc": loc("tut2_desc")},
			{"label": "Módulo 2: Presupuesto y Op. Combinadas", "key": &"tutorial6", "desc": loc("tut6_desc")},
		],
		Track.HACKER: [
			{"label": "Módulo 1: Reconocimiento e Infiltración", "key": &"tut_hacker_1", "desc": "Scan [X] y Bypass [1] con Nmap y Web Exploitation."},
			{"label": "Módulo 2: Escalada y Telemetría", "key": &"tut_hacker_2", "desc": "Escalate [2] y telemetría de red a 2 saltos."},
			{"label": "Módulo 3: Persistencia y Refugio", "key": &"tut_hacker_3", "desc": "Persist [3], 0 ruido de movimiento y doble enfriamiento."},
			{"label": "Módulo 4: Señuelos y Contramedidas", "key": &"tut_hacker_4", "desc": "Decoy [4], absorción de bloqueos de IA y desvío de patrullas."},
		],
		Track.DEFENDER: [
			{"label": "Módulo 1: Contención y Ciclo Reactivo", "key": &"tut_defensa_1", "desc": "Defensa perimetral, ciclo Ping-Pong 1:1 y rastreo forense EDR."},
			{"label": "Módulo 2: Amenazas Avanzadas y Cuarentena", "key": &"tut_defensa_2", "desc": "Gestión de exploits (Bypass), aislamiento de host [C] y victoria EDR al 100%."},
		],
	}

	# Restaurar track jugado previamente si existe
	if SceneParams.tutorial_track != "":
		match SceneParams.tutorial_track:
			"general": current_track = Track.GENERAL
			"heist": current_track = Track.HEIST
			"hacker": current_track = Track.HACKER
			"defender": current_track = Track.DEFENDER
		SceneParams.tutorial_track = ""

	progress = ProgressUtil.cargar_progreso()
	if get_node_or_null("/root/AudioManager") != null:
		AudioManager.play_menu_music()
	queue_redraw()


func _get_current_lessons() -> Array:
	return track_lessons.get(current_track, [])


func _input(event: InputEvent) -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var back_rect := Rect2(40.0, vp_size.y - 48.0, 180.0, 32.0)

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_go_back()
			KEY_ENTER, KEY_SPACE:
				var lessons := _get_current_lessons()
				if selected_idx >= 0 and selected_idx < lessons.size():
					_launch(lessons[selected_idx].key)
			KEY_LEFT, KEY_A:
				var total_tracks := Track.size()
				current_track = ((current_track - 1 + total_tracks) % total_tracks) as Track
				selected_idx = 0
				queue_redraw()
			KEY_RIGHT, KEY_D:
				var total_tracks := Track.size()
				current_track = ((current_track + 1) % total_tracks) as Track
				selected_idx = 0
				queue_redraw()
			KEY_UP, KEY_W:
				var lessons := _get_current_lessons()
				if not lessons.is_empty():
					selected_idx = maxi(0, selected_idx - 1)
					queue_redraw()
			KEY_DOWN, KEY_S:
				var lessons := _get_current_lessons()
				if not lessons.is_empty():
					selected_idx = mini(lessons.size() - 1, selected_idx + 1)
					queue_redraw()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		if back_rect.has_point(pos):
			_go_back()
			return
		# Click en pestañas
		var tab_x: float = 60.0
		var tab_y: float = 110.0
		var tab_gap: float = 24.0
		for t in Track.values():
			var meta: Dictionary = TRACK_METADATA.get(t, {})
			var t_title: String = meta.get("title", "")
			var tab_text: String = "[ %s ]" % t_title
			var tab_w: float = font.get_string_size(tab_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
			var tab_rect := Rect2(tab_x - 8, tab_y - 18, tab_w + 16, 26)
			if tab_rect.has_point(pos):
				current_track = t as Track
				selected_idx = 0
				queue_redraw()
				return
			tab_x += tab_w + tab_gap

		# Click en lecciones
		var lessons: Array = _get_current_lessons()
		var by: float = 190.0
		for i in lessons.size():
			var row_rect := Rect2(50, by - 16, get_viewport_rect().size.x - 110, 52)
			if row_rect.has_point(pos):
				selected_idx = i
				_launch(lessons[i].key)
				return
			by += 58


func _go_back() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")
	SceneParams.menu_target_state = "world_select"
	SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	_cyber_bg.update(delta, get_viewport_rect().size)
	queue_redraw()


func _launch(key: StringName) -> void:
	SceneParams.reset()
	SceneParams.level_key = String(key)
	if key == &"tutorial1":
		SceneParams.graph_path = "res://juego/tutorial1/tut1_red.tres"
		SceneParams.start_node = &"Inicio"
		SceneParams.target_node = &"Target"
		SceneParams.waypoints = []
		SceneParams.ai_enabled = false
		SceneParams.titulo_nivel = "General Módulo 1: Reconocimiento"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut1_movimiento.json"

	elif key == &"tutorial2":
		SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
		SceneParams.start_node = &"Inicio"
		SceneParams.target_node = &"Target"
		SceneParams.waypoints = []
		SceneParams.ai_enabled = true
		SceneParams.ai_block_per_turn = 1
		SceneParams.max_ai_blocks = 1
		SceneParams.ai_bloquea_al_inicio = true
		SceneParams.titulo_nivel = "Heist Módulo 1: Perímetro"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut2_perimetro.json"

	elif key == &"tutorial3":
		SceneParams.graph_path = "res://juego/tutorial3/tut3_red.tres"
		SceneParams.start_node = &"Inicio"
		SceneParams.target_node = &"Servidor"
		SceneParams.waypoints = [&"DMZ"]
		SceneParams.ai_enabled = true
		SceneParams.ai_block_per_turn = 1
		SceneParams.max_ai_blocks = 2
		SceneParams.ai_bloquea_al_inicio = true
		SceneParams.max_turns = 8
		SceneParams.titulo_nivel = "General Módulo 2: Defensa en Capas"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut3_avanzado.json"

	elif key == &"tut_hacker_1":
		SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
		SceneParams.start_node = &"DMZ"
		SceneParams.target_node = &"Core"
		SceneParams.waypoints = [&"WebServer"]
		SceneParams.ai_enabled = false
		SceneParams.titulo_nivel = "Hacker Módulo 1: Reconocimiento e Infiltración"
		SceneParams.hacker_mode = true
		SceneParams.starting_exploits = {"bypass": 2}
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut_hacker_1.json"

	elif key == &"tut_hacker_2":
		SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
		SceneParams.start_node = &"WebServer"
		SceneParams.target_node = &"Core"
		SceneParams.waypoints = [&"AppServer"]
		SceneParams.ai_enabled = false
		SceneParams.titulo_nivel = "Hacker Módulo 2: Escalada y Telemetría"
		SceneParams.hacker_mode = true
		SceneParams.starting_exploits = {"bypass": 1, "escalate": 2}
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut_hacker_2.json"

	elif key == &"tut_hacker_3":
		SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
		SceneParams.start_node = &"DMZ"
		SceneParams.target_node = &"Core"
		SceneParams.waypoints = [&"WebServer"]
		SceneParams.ai_enabled = false
		SceneParams.titulo_nivel = "Hacker Módulo 3: Persistencia y Refugio"
		SceneParams.hacker_mode = true
		SceneParams.starting_exploits = {"bypass": 1, "persist": 2}
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut_hacker_3.json"

	elif key == &"tut_hacker_4":
		SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
		SceneParams.start_node = &"WebServer"
		SceneParams.target_node = &"Core"
		SceneParams.waypoints = [&"AppServer"]
		SceneParams.ai_enabled = true
		SceneParams.ai_block_per_turn = 1
		SceneParams.max_ai_blocks = 2
		SceneParams.max_turns = 18
		SceneParams.titulo_nivel = "Hacker Módulo 4: Señuelos y Contramedidas"
		SceneParams.hacker_mode = true
		SceneParams.starting_exploits = {"bypass": 1, "decoy": 2}
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut_hacker_4.json"

	elif key == &"tutorial4":
		# Fallback de compatibilidad
		_launch(&"tut_hacker_1")
		return

	elif key == &"tut_defensa_1":
		SceneParams.graph_path = "res://juego/defense/defense_n1.tres"
		SceneParams.start_node = &"Internet"
		SceneParams.target_node = &"DataCenter"
		SceneParams.waypoints = []
		SceneParams.defender_mode = true
		SceneParams.defender_blocks_per_turn = 1
		SceneParams.defender_block_duration = 4
		SceneParams.enemy_start_node = &"Internet"
		SceneParams.enemy_target_node = &"DataCenter"
		SceneParams.titulo_nivel = "Defensa Módulo 1: Contención"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut_defensa_1.json"

	elif key == &"tut_defensa_2":
		SceneParams.graph_path = "res://juego/defense/defense_n1.tres"
		SceneParams.start_node = &"Internet"
		SceneParams.target_node = &"DataCenter"
		SceneParams.waypoints = []
		SceneParams.defender_mode = true
		SceneParams.defender_blocks_per_turn = 1
		SceneParams.defender_block_duration = 4
		SceneParams.enemy_start_node = &"Internet"
		SceneParams.enemy_target_node = &"DataCenter"
		SceneParams.titulo_nivel = "Defensa Módulo 2: Contramedidas"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut_defensa_2.json"

	elif key == &"tutorial6":
		SceneParams.graph_path = "res://juego/tutorial6/tut6_red.tres"
		SceneParams.start_node = &"Exterior"
		SceneParams.target_node = &"CentroDatos"
		SceneParams.waypoints = [&"Oficina"]
		SceneParams.ai_enabled = true
		SceneParams.ai_block_per_turn = 1
		SceneParams.max_ai_blocks = 3
		SceneParams.max_turns = 12
		SceneParams.max_movement_points = 10
		SceneParams.titulo_nivel = "Heist Módulo 2: Op. Combinadas"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut6_combined.json"

	SceneTransition.fade_to_scene("res://juego/ataque/escena_juego.tscn")


func loc(key: String) -> String:
	return LocUtil.loc(self, key)


func _draw() -> void:
	var vp_size := get_viewport_rect().size
	_cyber_bg.draw(self, vp_size)

	# Encabezado principal
	draw_string(font, Vector2(60, 50), "ACADEMIA DE ENTRENAMIENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 4, BrandClass.ACCENT)
	draw_string(font, Vector2(60, 74), "Selecciona una sección y completa las lecciones operativas", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)

	# Pestañas horizontales de categorías
	var tab_x: float = 60.0
	var tab_y: float = 110.0
	var tab_gap: float = 24.0

	for t in Track.values():
		var meta: Dictionary = TRACK_METADATA.get(t, {})
		var t_title: String = meta.get("title", "")
		var is_active: bool = (t == current_track)
		var tab_text: String = "[ %s ]" % t_title
		var text_color: Color = BrandClass.ACCENT if is_active else BrandClass.TEXT_DIM

		if is_active:
			var text_size: float = font.get_string_size(tab_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
			draw_rect(Rect2(tab_x - 8, tab_y - 18, text_size + 16, 26), BrandClass.with_alpha(BrandClass.ACCENT, 0.12))
			draw_line(Vector2(tab_x - 8, tab_y + 8), Vector2(tab_x + text_size + 8, tab_y + 8), BrandClass.ACCENT, 2.0)

		draw_string(font, Vector2(tab_x, tab_y), tab_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, text_color)
		var tab_width: float = font.get_string_size(tab_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
		tab_x += tab_width + tab_gap

	# Subtítulo del track activo
	var active_meta: Dictionary = TRACK_METADATA.get(current_track, {})
	var track_desc: String = active_meta.get("desc", "")
	draw_string(font, Vector2(60, 142), track_desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.with_alpha(BrandClass.TEXT, 0.8))

	# Lista de lecciones del track activo
	var lessons: Array = _get_current_lessons()
	var by: float = 190.0

	for i in lessons.size():
			var b: Dictionary = lessons[i]
			var is_sel: bool = (i == selected_idx)
			var color: Color
			var prefix: String

			var lk: StringName = b.get("key", &"")
			var level_key: String = String(lk)
			var stars: int = progress.get(level_key, 0)
			var is_completed: bool = stars > 0

			if is_sel:
				var glow := 0.7 + sin(_pulse) * 0.3
				color = BrandClass.with_alpha(BrandClass.ACCENT, glow)
				prefix = "> "
				draw_rect(Rect2(50, by - 16, vp_size.x - 110, 48), BrandClass.with_alpha(BrandClass.ACCENT, 0.08))
			else:
				color = BrandClass.TEXT_DIM
				prefix = "  "

			# Indicador visual de check / estado a la izquierda
			var check_x := 60.0
			var check_y := by - 12.0
			var check_size := 16.0
			var check_rect := Rect2(check_x, check_y, check_size, check_size)

			if is_completed:
				draw_rect(check_rect, BrandClass.with_alpha(BrandClass.SUCCESS, 0.20))
				draw_rect(check_rect, BrandClass.with_alpha(BrandClass.SUCCESS, 0.85), false, 1.2)
				# Checkmark vectorial
				draw_line(Vector2(check_x + 3.5, check_y + 8.5), Vector2(check_x + 6.5, check_y + 12.0), BrandClass.SUCCESS, 2.0)
				draw_line(Vector2(check_x + 6.5, check_y + 12.0), Vector2(check_x + 12.5, check_y + 4.5), BrandClass.SUCCESS, 2.0)
			else:
				draw_rect(check_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.45), false, 1.0)

			draw_string(font, Vector2(88.0, by), prefix + b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 3, color)

			# Badge táctico y estrellas a la derecha
			var badge_w := 115.0
			var badge_h := 20.0
			var badge_x := vp_size.x - 265.0
			var badge_y := by - 14.0
			var badge_rect := Rect2(badge_x, badge_y, badge_w, badge_h)

			if is_completed:
				draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.SUCCESS, 0.15))
				draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.SUCCESS, 0.60), false, 1.0)
				draw_string(font, Vector2(badge_x + 8.0, badge_y + 14.0), "[COMPLETADO]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.SUCCESS)

				var stars_str: String = ""
				for si in range(3):
					stars_str += "★" if si < stars else "☆"
				draw_string(font, Vector2(vp_size.x - 135.0, by), stars_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 3, BrandClass.WARNING)
			else:
				draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.15))
				draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), false, 1.0)
				draw_string(font, Vector2(badge_x + 14.0, badge_y + 14.0), "[PENDIENTE]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)

				draw_string(font, Vector2(vp_size.x - 135.0, by), "☆☆☆", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.40))

			by += 22
			draw_string(font, Vector2(106.0, by), b.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
			by += 36

	# Controles al pie
	var foot_y: float = vp_size.y - 48.0
	var back_rect := Rect2(40.0, foot_y, 180.0, 32.0)
	draw_rect(back_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
	draw_rect(back_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.5), false, 1.2)
	draw_string(font, Vector2(back_rect.position.x + 14.0, back_rect.position.y + 21.0), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)

	var controls_hint: String = "[Enter / Clic] Iniciar lección    [A / D] Cambiar sección"
	draw_string(font, Vector2(240.0, foot_y + 21.0), controls_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT_DIM)
