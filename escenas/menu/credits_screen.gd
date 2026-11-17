extends Control

## CreditsScreen
## Expediente desclasificado de créditos institucionales, académicos y de autoría UPTA.

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")

var font: Font
var font_size: int = 14
var big_font_size: int = 24
var small_font_size: int = 12
var title_font_size: int = 36

var _cyber_bg := CyberBackgroundClass.new()
var _scroll_y: float = 0.0
var _pulse: float = 0.0
var _paused: bool = false
var _scroll_speed: float = 24.0

const CREDITS_DATA_ES: Array[Dictionary] = [
	{
		"category": "INSTITUCIÓN & TUTORÍA ACADÉMICA",
		"items": [
			{"role": "Universidad", "name": "Universidad Politécnica Territorial del Estado Aragua 'Federico Brito Figueroa'"},
			{"role": "Programa", "name": "PNF en Informática — Proyecto Socio-Tecnológico II"},
			{"role": "Coordinación Docente", "name": "Prof. Ing. Elizabet C. Duarte P."},
			{"role": "Tutor Académico", "name": "Prof. Ing. Miguel Mejias"}
		]
	},
	{
		"category": "EQUIPO DE DESARROLLO & INGENIERÍA",
		"items": [
			{"role": "Director, Arquitectura de Software, Algoritmos & Gameplay", "name": "Leonardo Angulo (C.I. 29.771.631)"},
			{"role": "Co-Desarrollo, Documentación de Ingeniería (UML 2.5 / E-P-S) & QA", "name": "Juan Parilli (C.I. 31.931.218)"},
			{"role": "Co-Desarrollo, Documentación de Ingeniería & QA", "name": "Ana Borges (C.I. 32.318.803)"}
		]
	},
	{
		"category": "BASE MATEMÁTICA & INVESTIGACIÓN",
		"items": [
			{"role": "Camino Mínimo (Shortest Path)", "name": "Edsger W. Dijkstra (1956)"},
			{"role": "Flujo Máximo & Corte Mínimo", "name": "Jack Edmonds & Richard M. Karp (1972)"},
			{"role": "Modelado de Amenazas & MTD", "name": "Paper: Shivakumar & Mamatha (2022)"}
		]
	},
	{
		"category": "BANDA SONORA & AUDIO",
		"items": [
			{"role": "Música Original 'Code Injection Pack'", "name": "DavidKBD (CC-BY 4.0)"},
			{"role": "Música Original 'Pink Bloom Synth Pack'", "name": "DavidKBD (CC-BY 4.0)"},
			{"role": "Síntesis Táctica de SFX", "name": "Motor Procedural VERTEX Audio"}
		]
	},
	{
		"category": "MOTOR & TECNOLOGÍA",
		"items": [
			{"role": "Motor de Videojuegos", "name": "Godot Engine 4.7.2 (MIT License)"},
			{"role": "Tipografía de Interfaz", "name": "JetBrains Mono (OFL License)"},
			{"role": "Física y Simulación", "name": "Jolt Physics & Forward+ Renderer"}
		]
	}
]

const CREDITS_DATA_EN: Array[Dictionary] = [
	{
		"category": "INSTITUTION & ACADEMIC TUTORSHIP",
		"items": [
			{"role": "University", "name": "Territorial Polytechnic University of Aragua State 'Federico Brito Figueroa'"},
			{"role": "Program", "name": "National Training Program in Informatics — Socio-Technological Project II"},
			{"role": "Teaching Coordination", "name": "Prof. Eng. Elizabet C. Duarte P."},
			{"role": "Academic Tutor", "name": "Prof. Eng. Miguel Mejias"}
		]
	},
	{
		"category": "DEVELOPMENT & ENGINEERING TEAM",
		"items": [
			{"role": "Director, Software Architecture, Algorithms & Gameplay", "name": "Leonardo Angulo (ID 29.771.631)"},
			{"role": "Co-Development, Engineering Documentation (UML 2.5 / E-P-S) & QA", "name": "Juan Parilli (ID 31.931.218)"},
			{"role": "Co-Development, Engineering Documentation & QA", "name": "Ana Borges (ID 32.318.803)"}
		]
	},
	{
		"category": "MATHEMATICAL BASE & RESEARCH",
		"items": [
			{"role": "Shortest Path", "name": "Edsger W. Dijkstra (1956)"},
			{"role": "Max Flow & Min Cut", "name": "Jack Edmonds & Richard M. Karp (1972)"},
			{"role": "Threat Modeling & MTD", "name": "Paper: Shivakumar & Mamatha (2022)"}
		]
	},
	{
		"category": "SOUNDTRACK & AUDIO",
		"items": [
			{"role": "Original Music 'Code Injection Pack'", "name": "DavidKBD (CC-BY 4.0)"},
			{"role": "Original Music 'Pink Bloom Synth Pack'", "name": "DavidKBD (CC-BY 4.0)"},
			{"role": "Tactical SFX Synthesis", "name": "VERTEX Procedural Audio Engine"}
		]
	},
	{
		"category": "ENGINE & TECHNOLOGY",
		"items": [
			{"role": "Game Engine", "name": "Godot Engine 4.7.2 (MIT License)"},
			{"role": "Interface Typography", "name": "JetBrains Mono (OFL License)"},
			{"role": "Physics & Simulation", "name": "Jolt Physics & Forward+ Renderer"}
		]
	}
]

const CREDITS_DATA_PT: Array[Dictionary] = [
	{
		"category": "INSTITUIÇÃO & TUTORIA ACADÊMICA",
		"items": [
			{"role": "Universidade", "name": "Universidad Politécnica Territorial del Estado Aragua 'Federico Brito Figueroa'"},
			{"role": "Programa", "name": "PNF em Informática — Projeto Sócio-Tecnológico II"},
			{"role": "Coordenação Docente", "name": "Prof. Eng. Elizabet C. Duarte P."},
			{"role": "Tutor Acadêmico", "name": "Prof. Eng. Miguel Mejias"}
		]
	},
	{
		"category": "EQUIPE DE DESENVOLVIMENTO & ENGENHARIA",
		"items": [
			{"role": "Diretor, Arquitetura de Software, Algoritmos & Gameplay", "name": "Leonardo Angulo (C.I. 29.771.631)"},
			{"role": "Co-Desenvolvimento, Documentação de Engenharia (UML 2.5 / E-P-S) & QA", "name": "Juan Parilli (C.I. 31.931.218)"},
			{"role": "Co-Desenvolvimento, Documentação de Engenharia & QA", "name": "Ana Borges (C.I. 32.318.803)"}
		]
	},
	{
		"category": "BASE MATEMÁTICA & PESQUISA",
		"items": [
			{"role": "Caminho Mínimo (Shortest Path)", "name": "Edsger W. Dijkstra (1956)"},
			{"role": "Fluxo Máximo & Corte Mínimo", "name": "Jack Edmonds & Richard M. Karp (1972)"},
			{"role": "Modelagem de Ameaças & MTD", "name": "Paper: Shivakumar & Mamatha (2022)"}
		]
	},
	{
		"category": "TRILHA SONORA & ÁUDIO",
		"items": [
			{"role": "Música Original 'Code Injection Pack'", "name": "DavidKBD (CC-BY 4.0)"},
			{"role": "Música Original 'Pink Bloom Synth Pack'", "name": "DavidKBD (CC-BY 4.0)"},
			{"role": "Síntese Tática de SFX", "name": "Motor Procedural VERTEX Audio"}
		]
	},
	{
		"category": "MOTOR & TECNOLOGIA",
		"items": [
			{"role": "Motor de Jogos", "name": "Godot Engine 4.7.2 (MIT License)"},
			{"role": "Tipografia de Interface", "name": "JetBrains Mono (OFL License)"},
			{"role": "Física e Simulação", "name": "Jolt Physics & Forward+ Renderer"}
		]
	}
]


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 10
	small_font_size = font_size - 2
	title_font_size = font_size + 22

	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music(-14.0)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	if not _paused:
		_scroll_y += delta * _scroll_speed
	_cyber_bg.update(delta, get_viewport_rect().size)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		if k.keycode in [KEY_ESCAPE, KEY_ENTER]:
			_go_back()
		elif k.keycode == KEY_SPACE:
			_paused = not _paused
		elif k.keycode in [KEY_UP, KEY_W]:
			_scroll_speed = maxf(5.0, _scroll_speed - 10.0)
		elif k.keycode in [KEY_DOWN, KEY_S]:
			_scroll_speed = minf(120.0, _scroll_speed + 10.0)
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var back_rect := Rect2(40.0, 36.0, 170.0, 36.0)
			if back_rect.has_point(mb.position):
				_go_back()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_y = maxf(0.0, _scroll_y - 45.0)
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_y += 45.0
			queue_redraw()


func _go_back() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")
	var back_pos := Vector2(130.0, 44.0)
	SceneTransition.dive_out_to_scene("res://escenas/main_menu.tscn", back_pos)


func _draw() -> void:
	var vp := get_viewport_rect().size
	_cyber_bg.draw(self, vp, 0.0, BrandClass.ACCENT, BrandClass.BG)

	# Encabezado fijo
	var header_rect := Rect2(0, 0, vp.x, 88.0)
	draw_rect(header_rect, Color(0.02, 0.03, 0.07, 0.92))
	draw_line(Vector2(0, 88.0), Vector2(vp.x, 88.0), BrandClass.with_alpha(BrandClass.ACCENT, 0.4), 1.5)

	# Botón Volver
	var back_rect := Rect2(40.0, 36.0, 170.0, 36.0)
	draw_rect(back_rect, BrandClass.PANEL_SOLID)
	draw_rect(back_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.7), false, 1.2)
	draw_string(font, Vector2(56.0, 60.0), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)

	# Título principal y controles de velocidad / pausa
	var lang := "es"
	var lm = get_node_or_null("/root/LocaleManager")
	if lm != null and lm.has_method("get_current_locale"):
		lang = lm.get_current_locale()

	var title_text := "EXPEDIENTE DE CRÉDITOS UPTA"
	if lang == "en":
		title_text = "UPTA OFFICIAL CREDITS DOSSIER"
	elif lang == "pt":
		title_text = "EXPEDIENTE DE CRÉDITOS UPTA"

	draw_string(font, Vector2(vp.x * 0.5 - 200.0, 58.0), title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, BrandClass.ACCENT)
	
	var controls_hint := "[SPACE] Pausa | [W/S] Velocidad: %d%%" % int(_scroll_speed / 24.0 * 100.0)
	draw_string(font, Vector2(vp.x - 320.0, 58.0), controls_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)

	# Contenido con scroll
	var content_y := 130.0 - _scroll_y
	var center_x := vp.x * 0.5

	var active_data := CREDITS_DATA_ES
	if lang == "en":
		active_data = CREDITS_DATA_EN
	elif lang == "pt":
		active_data = CREDITS_DATA_PT

	for section in active_data:
		var cat_title: String = section["category"]
		draw_string(font, Vector2(center_x - 300.0, content_y), "--- " + cat_title + " ---", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)
		content_y += 32.0

		for item in section["items"]:
			var role: String = item["role"]
			var name_str: String = item["name"]

			draw_string(font, Vector2(center_x - 300.0, content_y), role, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)
			draw_string(font, Vector2(center_x + 20.0, content_y), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
			content_y += 26.0

		content_y += 32.0

	# Bucle automático de scroll al terminar
	if content_y < -200.0:
		_scroll_y = 0.0
