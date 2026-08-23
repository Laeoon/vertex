extends Control

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

const BrandClass = preload("res://juego/ui/brand.gd")

const CYAN: Color = BrandClass.ACCENT
const GRIS: Color = BrandClass.TEXT_DIM
const GRIS_OSCURO: Color = BrandClass.TEXT_DIM
const BLANCO: Color = BrandClass.TEXT
const AMARILLO: Color = BrandClass.WARNING

enum Tab { MISSIONS, CONCEPTS, LORE }

var _tab_idx: int = 0
var _scroll_y: float = 0.0

var missions: Array[Dictionary] = [
	{"id": "heist_n1", "world": "world.heist", "name": "database.heist_n1_name", "difficulty": 1, "completed": false, "stars": 0},
	{"id": "heist_n2", "world": "world.heist", "name": "database.heist_n2_name", "difficulty": 2, "completed": false, "stars": 0},
	{"id": "hacker_n1", "world": "world.hacker", "name": "database.hacker_n1_name", "difficulty": 2, "completed": false, "stars": 0},
	{"id": "cyber_n1", "world": "world.cyber", "name": "database.cyber_n1_name", "difficulty": 3, "completed": false, "stars": 0},
	{"id": "defense_n1", "world": "world.cyber", "name": "database.defense_n1_name", "difficulty": 2, "completed": false, "stars": 0},
]

var concepts: Array[Dictionary] = [
	{"id": "graph_theory", "title": "concept.graph_theory", "description": "concept.graph_theory_desc"},
	{"id": "dijkstra", "title": "concept.dijkstra", "description": "concept.dijkstra_desc"},
	{"id": "edmonds_karp", "title": "concept.edmonds_karp", "description": "concept.edmonds_karp_desc"},
	{"id": "mtd", "title": "concept.mtd", "description": "concept.mtd_desc"},
	{"id": "attack_graphs", "title": "concept.attack_graphs", "description": "concept.attack_graphs_desc"},
]

var lore_entries: Array[Dictionary] = [
	{"id": "about_vertex", "title": "lore.about_vertex", "text": "lore.about_vertex_text"},
	{"id": "objective", "title": "lore.objective", "description": "lore.objective_text"},
	{"id": "reference", "title": "lore.reference", "description": "lore.reference_text"},
]


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	ProgressUtil.cargar_misiones(missions)
	queue_redraw()


func loc(key: String) -> String:
	return LocUtil.loc(self, key)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
			KEY_LEFT:
				_tab_idx = maxi(0, _tab_idx - 1)
				_scroll_y = 0.0
				queue_redraw()
			KEY_RIGHT:
				_tab_idx = mini(2, _tab_idx + 1)
				_scroll_y = 0.0
				queue_redraw()
			KEY_UP:
				_scroll_y = maxf(0.0, _scroll_y - 30.0)
				queue_redraw()
			KEY_DOWN:
				var max_scroll: float = _get_max_scroll()
				_scroll_y = minf(max_scroll, _scroll_y + 30.0)
				queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()


func _get_max_scroll() -> float:
	match _tab_idx:
		0:
			return maxf(0.0, missions.size() * 40.0 - 300.0)
		1:
			return maxf(0.0, concepts.size() * 70.0 - 300.0)
		2:
			var total: float = 0.0
			for entry in lore_entries:
				var text: String = loc(entry.get("text", ""))
				if text == "":
					text = loc(entry.get("description", ""))
				var lines: Array = text.split("\n")
				total += 40.0 + lines.size() * 20.0
			return maxf(0.0, total - 300.0)
	return 0.0



func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp.x, vp.y), BrandClass.BG)

	# Title
	draw_string(font, Vector2(60, 60), loc("menu.database"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, CYAN)

	# Tabs
	var tabs: Array[String] = [
		loc("database.tab_missions"),
		loc("database.tab_concepts"),
		loc("database.tab_lore"),
	]
	var tab_x: float = 80.0
	for i in tabs.size():
		var is_sel: bool = i == _tab_idx
		var color: Color = CYAN if is_sel else GRIS
		var tw: float = font.get_string_size(tabs[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4).x
		draw_string(font, Vector2(tab_x, 100), tabs[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, color)
		if is_sel:
			draw_rect(Rect2(tab_x, 105, tw, 2), CYAN)
		tab_x += tw + 40

	# Content according to tab
	match _tab_idx:
		0:
			_draw_missions()
		1:
			_draw_concepts()
		2:
			_draw_lore()

	# Back hint
	var vp_hint: float = vp.y - 20
	draw_string(font, Vector2(60, vp_hint), loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.35, 0.38, 0.45))


func _draw_missions() -> void:
	var by: float = 150.0 - _scroll_y
	for mission in missions:
		var world_name: String = loc(mission.world)
		var mission_name: String = loc(mission.name)
		var completed: bool = mission.stars > 0
		var color: Color = AMARILLO if completed else GRIS

		# Status icon
		if completed:
			draw_string(font, Vector2(80, by), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, AMARILLO)
		else:
			draw_string(font, Vector2(80, by), "○", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, GRIS_OSCURO)

		# World — Name
		var text: String = "%s — %s" % [world_name, mission_name]
		draw_string(font, Vector2(105, by), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, color)

		# Difficulty
		var diff_text: String = loc("database.difficulty") + ": %d" % mission.difficulty
		draw_string(font, Vector2(450, by), diff_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, GRIS_OSCURO)

		# Stars
		if completed:
			var star_text: String = ""
			for s in range(3):
				star_text += "★" if s < mission.stars else "☆"
			draw_string(font, Vector2(560, by), star_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, AMARILLO)

		by += 38


func _draw_concepts() -> void:
	var by: float = 150.0 - _scroll_y
	for concept in concepts:
		var title: String = loc(concept.title)
		var desc: String = loc(concept.description)

		# Title
		draw_string(font, Vector2(80, by), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, CYAN)
		by += 24

		# Description (word-wrap manually)
		var max_w: float = 600.0
		var words: PackedStringArray = desc.split(" ")
		var line: String = ""
		for word in words:
			var test_line: String = (line + " " + word).strip_edges()
			var tw: float = font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1).x
			if tw > max_w and line.length() > 0:
				draw_string(font, Vector2(100, by), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, GRIS)
				by += 20
				line = word
			else:
				line = test_line
		if line.length() > 0:
			draw_string(font, Vector2(100, by), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, GRIS)
			by += 20

		by += 16


func _draw_lore() -> void:
	var by: float = 150.0 - _scroll_y
	for entry in lore_entries:
		var title: String = loc(entry.title)
		# Get text - it can be either "text" or "description"
		var text_key: String = entry.get("text", "")
		if text_key == "":
			text_key = entry.get("description", "")
		var text: String = loc(text_key)

		# Title
		draw_string(font, Vector2(80, by), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, CYAN)
		by += 24

		# Multiline text
		var paragraphs: PackedStringArray = text.split("\n")
		for para in paragraphs:
			if para.strip_edges().length() == 0:
				by += 10
				continue
			# Word wrap
			var max_w: float = 580.0
			var words: PackedStringArray = para.split(" ")
			var line: String = ""
			for word in words:
				var test_line: String = (line + " " + word).strip_edges()
				var tw: float = font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1).x
				if tw > max_w and line.length() > 0:
					draw_string(font, Vector2(100, by), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, GRIS)
					by += 20
					line = word
				else:
					line = test_line
			if line.length() > 0:
				draw_string(font, Vector2(100, by), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, GRIS)
				by += 20
			by += 8

		by += 16
