extends Control

const BrandClass = preload("res://juego/ui/brand.gd")

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var buttons: Array[Dictionary] = []
var selected_idx: int = 0
var progress: Dictionary = {}
var _pulse: float = 0.0


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14

	buttons = [
		{"label": "Tutorial 1: Reconocimiento", "key": &"tutorial1",
			"desc": loc("tut1_desc")},
		{"label": "Tutorial 2: Perimetro", "key": &"tutorial2",
			"desc": loc("tut2_desc")},
		{"label": "Tutorial 3: Defensa en Capas", "key": &"tutorial3",
			"desc": loc("tut3_desc")},
		{"label": "Tutorial 4: Modo Hacker", "key": &"tutorial4",
			"desc": loc("tut4_desc")},
		{"label": "Tutorial 5: Defensa Perimetral", "key": &"tutorial5",
			"desc": loc("tut5_desc")},
		{"label": "Tutorial 6: Operaciones Combinadas", "key": &"tutorial6",
			"desc": loc("tut6_desc")},
		{"label": "Tutorial 7: Fundamentos de Defensa", "key": &"tutorial7",
			"desc": loc("tut7_desc")},
	]

	progress = ProgressUtil.cargar_progreso()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
			KEY_ENTER, KEY_SPACE:
				_launch(buttons[selected_idx].key)
			KEY_UP:
				selected_idx = maxi(0, selected_idx - 1)
				queue_redraw()
			KEY_DOWN:
				selected_idx = mini(buttons.size() - 1, selected_idx + 1)
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
		SceneParams.titulo_nivel = "Tutorial 2: Perimetro"
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
		SceneParams.starting_exploits = {"bypass": 2, "escalate": 1, "persist": 1}
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut4_hacker.json"

	elif key == &"tutorial5":
		SceneParams.graph_path = "res://juego/defense/defense_n1.tres"
		SceneParams.start_node = &"Internet"
		SceneParams.target_node = &"DataCenter"
		SceneParams.ai_enabled = false
		SceneParams.max_turns = 12
		SceneParams.titulo_nivel = "Tutorial 5: Defensa Perimetral"
		SceneParams.defender_mode = true
		SceneParams.defender_blocks_per_turn = 2
		SceneParams.defender_block_duration = 4
		SceneParams.enemy_start_node = &"Internet"
		SceneParams.enemy_target_node = &"DataCenter"
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut5_defense.json"

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

	elif key == &"tutorial7":
		SceneParams.graph_path = "res://juego/tutorial4/tut4_red.tres"
		SceneParams.start_node = &"Internet"
		SceneParams.target_node = &"DataCenter"
		SceneParams.waypoints = []
		SceneParams.ai_enabled = false
		SceneParams.max_turns = 12
		SceneParams.titulo_nivel = "Tutorial 7: Fundamentos de Defensa"
		SceneParams.defender_mode = true
		SceneParams.defender_blocks_per_turn = 2
		SceneParams.defender_block_duration = 5
		SceneParams.enemy_start_node = &"Internet"
		SceneParams.enemy_target_node = &"DataCenter"
		SceneParams.max_ai_blocks = 10
		SceneParams.mensaje_tutorial = ""
		SceneParams.tutorial_path = "res://juego/tutorials/data/tut4_defensa.json"

	SceneTransition.fade_to_scene("res://juego/ataque/escena_juego.tscn")


func loc(key: String) -> String:
	return LocUtil.loc(self, key)


func _draw() -> void:
	var vp_size := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp_size.x, vp_size.y), BrandClass.BG)

	draw_string(font, Vector2(60, 60), loc("menu.select_world"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 8, BrandClass.ACCENT)
	draw_string(font, Vector2(60, 88), loc("menu.select_world_desc"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, BrandClass.TEXT_DIM)

	var by: float = 150.0
	for i in buttons.size():
		var b := buttons[i]
		var is_sel: bool = i == selected_idx
		var color: Color
		var prefix: String

		if is_sel:
			var glow := 0.7 + sin(_pulse) * 0.3
			color = BrandClass.with_alpha(BrandClass.ACCENT, glow)
			prefix = "> "
			draw_rect(Rect2(50, by - 16, vp_size.x - 110, 30), BrandClass.with_alpha(BrandClass.ACCENT, 0.06))
		else:
			color = BrandClass.TEXT_DIM
			prefix = "  "

		draw_string(font, Vector2(60, by), prefix + b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, color)

		var lk: StringName = b.get("key", &"")
		if lk != &"":
			var level_key: String = lk
			var stars: int = progress.get(level_key, 0)
			if stars > 0:
				var s: String = ""
				for si in range(3):
					s += "★" if si < stars else "☆"
				draw_string(font, Vector2(vp_size.x - 160, by), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.WARNING)

		by += 24
		draw_string(font, Vector2(78, by), b.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
		by += 40

	by += 10
	draw_string(font, Vector2(60, by), loc("menu.controls"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)
	by += 22
	draw_string(font, Vector2(60, by), loc("menu.controls_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
	by += 22
	draw_string(font, Vector2(60, by), loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
