extends Control

const BrandClass = preload("res://juego/ui/brand.gd")

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
		"desc": "Defensa Activa y Contramedidas",
		"is_standby": true,
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
			{"label": "Tutorial 1: Reconocimiento", "key": &"tutorial1", "desc": loc("tut1_desc")},
			{"label": "Tutorial 3: Defensa en Capas", "key": &"tutorial3", "desc": loc("tut3_desc")},
		],
		Track.HEIST: [
			{"label": "Tutorial 2: Perímetro", "key": &"tutorial2", "desc": loc("tut2_desc")},
			{"label": "Tutorial 6: Operaciones Combinadas", "key": &"tutorial6", "desc": loc("tut6_desc")},
		],
		Track.HACKER: [
			{"label": "Tutorial 4: Modo Hacker", "key": &"tutorial4", "desc": loc("tut4_desc")},
		],
		Track.DEFENDER: [],
	}

	progress = ProgressUtil.cargar_progreso()
	queue_redraw()


func _get_current_lessons() -> Array:
	return track_lessons.get(current_track, [])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
			KEY_ENTER, KEY_SPACE:
				if current_track == Track.DEFENDER:
					return
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


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()


func _launch(key: StringName) -> void:
	SceneParams.reset()
	if key == &"tutorial1":
		SceneParams.graph_path = "res://juego/tutorial1/tut1_red.tres"
		SceneParams.start_node = &"Inicio"
		SceneParams.target_node = &"Target"
		SceneParams.waypoints = []
		SceneParams.ai_enabled = false
		SceneParams.titulo_nivel = "Tutorial 1: Reconocimiento"
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
		SceneParams.titulo_nivel = "Tutorial 2: Perímetro"
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
		SceneParams.titulo_nivel = "Tutorial 3: Defensa en Capas"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut3_avanzado.json"

	elif key == &"tutorial4":
		SceneParams.graph_path = "res://juego/hacker/hacker_n1.tres"
		SceneParams.start_node = &"DMZ"
		SceneParams.target_node = &"Core"
		SceneParams.waypoints = [&"WebServer", &"AdminPanel"]
		SceneParams.ai_enabled = true
		SceneParams.ai_block_per_turn = 1
		SceneParams.max_ai_blocks = 2
		SceneParams.max_turns = 18
		SceneParams.titulo_nivel = "Tutorial 4: Modo Hacker"
		SceneParams.hacker_mode = true
		SceneParams.starting_exploits = {"bypass": 2, "escalate": 1, "persist": 1, "decoy": 1}
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut4_hacker.json"

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
		SceneParams.titulo_nivel = "Tutorial 6: Op. Combinadas"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut6_combined.json"

	SceneTransition.fade_to_scene("res://juego/ataque/escena_juego.tscn")


func loc(key: String) -> String:
	return LocUtil.loc(self, key)


func _draw() -> void:
	var vp_size := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp_size.x, vp_size.y), BrandClass.BG)

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

	# Contenido del track
	if current_track == Track.DEFENDER:
		# Vista Stand-by de Mantenimiento
		var card_rect := Rect2(60, 175, vp_size.x - 120, 200)
		draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL, 0.6))
		draw_rect(card_rect, BrandClass.with_alpha(BrandClass.WARNING, 0.4), false, 1.5)

		var glow := 0.7 + sin(_pulse) * 0.3
		draw_string(font, Vector2(85, 220), "🛡  MODO DEFENSOR — EN MANTENIMIENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.WARNING, glow))
		draw_string(font, Vector2(85, 255), "Las mecánicas de ciberdefensa perimetral y contramedidas activas", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, BrandClass.TEXT)
		draw_string(font, Vector2(85, 280), "están actualmente en fase de reestructuración técnica y rebalanceo.", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, BrandClass.TEXT)
		draw_string(font, Vector2(85, 320), "⚠ Los tutoriales de defensa se reactivarán en la próxima actualización.", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)
	else:
		# Lista de lecciones del track activo
		var lessons: Array = _get_current_lessons()
		var by: float = 190.0

		for i in lessons.size():
			var b: Dictionary = lessons[i]
			var is_sel: bool = (i == selected_idx)
			var color: Color
			var prefix: String

			if is_sel:
				var glow := 0.7 + sin(_pulse) * 0.3
				color = BrandClass.with_alpha(BrandClass.ACCENT, glow)
				prefix = "> "
				draw_rect(Rect2(50, by - 16, vp_size.x - 110, 48), BrandClass.with_alpha(BrandClass.ACCENT, 0.08))
			else:
				color = BrandClass.TEXT_DIM
				prefix = "  "

			draw_string(font, Vector2(60, by), prefix + b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 3, color)

			# Estrellas de progreso
			var lk: StringName = b.get("key", &"")
			if lk != &"":
				var level_key: String = lk
				var stars: int = progress.get(level_key, 0)
				var stars_str: String = ""
				for si in range(3):
					stars_str += "★" if si < stars else "☆"
				var star_color: Color = BrandClass.WARNING if stars > 0 else BrandClass.TEXT_DIM
				draw_string(font, Vector2(vp_size.x - 160, by), stars_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 3, star_color)

			by += 22
			draw_string(font, Vector2(78, by), b.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
			by += 36

	# Controles al pie
	var foot_y: float = vp_size.y - 45
	draw_line(Vector2(60, foot_y - 15), Vector2(vp_size.x - 60, foot_y - 15), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.4), 1.0)
	var controls_hint: String = "[← / → / A / D] Cambiar Sección   |   [↑ / ↓ / W / S] Elegir Lección   |   [Enter] Iniciar   |   [Esc] Volver"
	draw_string(font, Vector2(60, foot_y + 8), controls_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.TEXT_DIM)
