extends Control

## CreditsScreen
## Expediente desclasificado de créditos, agradecimientos y autoría de VERTEX.

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

const CREDITS_DATA: Array[Dictionary] = [
	{
		"category": "DIRECTOR & ARQUITECTURA",
		"items": [
			{"role": "Diseño de Juego & Ingeniería de Software", "name": "Laeoon"},
			{"role": "Modelado de Algoritmos & Teoría de Grafos", "name": "Laeoon"},
			{"role": "Concepto Original & Producción", "name": "VERTEX Initiative"}
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
	},
	{
		"category": "AGRADECIMIENTOS ESPECIALES",
		"items": [
			{"role": "Cátedra de Arquitectura de Software", "name": "Revisión Académica & UML 2.5"},
			{"role": "Comunidad Open Source de Godot", "name": "Herramientas y soporte continuo"},
			{"role": "Operador", "name": "A ti, por defender y auditar la red"}
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
	_scroll_y += delta * 22.0
	_cyber_bg.update(delta, get_viewport_rect().size)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		if k.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
			_go_back()
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var vp := get_viewport_rect().size
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
	SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")


func _draw() -> void:
	var vp := get_viewport_rect().size
	_cyber_bg.draw(self, vp, 0.0, BrandClass.ACCENT, BrandClass.BG)

	# Encabezado fijo
	var header_rect := Rect2(0, 0, vp.x, 88.0)
	draw_rect(header_rect, Color(0.02, 0.03, 0.07, 0.90))
	draw_line(Vector2(0, 88.0), Vector2(vp.x, 88.0), BrandClass.with_alpha(BrandClass.ACCENT, 0.4), 1.5)

	# Botón Volver
	var back_rect := Rect2(40.0, 36.0, 170.0, 36.0)
	draw_rect(back_rect, BrandClass.PANEL_SOLID)
	draw_rect(back_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.7), false, 1.2)
	draw_string(font, Vector2(56.0, 60.0), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.ACCENT)

	# Título principal
	draw_string(font, Vector2(vp.x * 0.5 - 120.0, 58.0), "EXPEDIENTE DE CRÉDITOS", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, BrandClass.ACCENT)

	# Contenido con scroll
	var content_y := 120.0 - _scroll_y
	var center_x := vp.x * 0.5

	for section in CREDITS_DATA:
		var cat_title: String = section["category"]
		draw_string(font, Vector2(center_x - 220.0, content_y), "--- " + cat_title + " ---", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.SUCCESS)
		content_y += 30.0

		for item in section["items"]:
			var role: String = item["role"]
			var name_str: String = item["name"]

			draw_string(font, Vector2(center_x - 220.0, content_y), role, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)
			draw_string(font, Vector2(center_x + 20.0, content_y), name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
			content_y += 24.0

		content_y += 28.0

	# Bucle automático de scroll al terminar
	if content_y < 100.0:
		_scroll_y = 0.0
