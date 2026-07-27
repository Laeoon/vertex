extends Control

signal start_world(world_id: String)

enum State { MAIN_MENU, WORLD_SELECT }

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var current_state: State = State.MAIN_MENU
var selected_idx: int = 0
var progress: Dictionary = {}

var _main_items: Array[Dictionary] = []
var _world_items: Array[Dictionary] = []
var _lang_options: Array[String] = ["es", "en", "pt"]
var _lang_idx: int = 0

var _fade_alpha: float = 1.0
var _transitioning: bool = false
var _transition_target: State = State.MAIN_MENU
var _pulse: float = 0.0


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14

	_main_items = [
		{"label": loc("menu.play"), "desc": loc("menu.play_desc"), "action": "play"},
		{"label": loc("menu.options"), "desc": loc("menu.options_desc"), "action": "options"},
		{"label": loc("menu.profile"), "desc": loc("menu.profile_desc"), "action": "profile"},
		{"label": loc("menu.database"), "desc": loc("menu.database_desc"), "action": "database"},
		{"label": loc("menu.exit"), "desc": "", "action": "exit"},
	]

	_world_items = [
		{"label": "Heist", "desc": loc("world.heist_desc"), "id": "heist"},
		{"label": "Hacker", "desc": loc("world.hacker_desc"), "id": "hacker"},
		{"label": "Cybersecurity", "desc": loc("world.cyber_desc"), "id": "cybersecurity"},
		{"label": loc("world.tutorials"), "desc": loc("world.tutorials_desc"), "id": "tutorials"},
	]

	_load_lang_setting()
	progress = ProgressUtil.cargar_progreso()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _transitioning:
		return

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				if current_state == State.WORLD_SELECT:
					_go_to_state(State.MAIN_MENU)
				else:
					get_tree().quit()
			KEY_ENTER, KEY_SPACE:
				_activate_selected()
			KEY_UP:
				selected_idx = maxi(0, selected_idx - 1)
				queue_redraw()
			KEY_DOWN:
				var items := _current_items()
				selected_idx = mini(items.size() - 1, selected_idx + 1)
				queue_redraw()
			KEY_LEFT:
				_cycle_lang(-1)
			KEY_RIGHT:
				_cycle_lang(1)


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	if _transitioning:
		_fade_alpha = move_toward(_fade_alpha, 0.0, delta * 4.0)
		if _fade_alpha <= 0.0:
			current_state = _transition_target
			selected_idx = 0
			_fade_alpha = 0.0
			_transitioning = false
	queue_redraw()


func _current_items() -> Array[Dictionary]:
	if current_state == State.WORLD_SELECT:
		return _world_items
	return _main_items


func _activate_selected() -> void:
	var items := _current_items()
	if selected_idx < 0 or selected_idx >= items.size():
		return
	var item: Dictionary = items[selected_idx]

	if current_state == State.MAIN_MENU:
		match item.action:
			"play":
				_go_to_state(State.WORLD_SELECT)
			"options":
				SceneTransition.fade_to_scene("res://escenas/menu/options.tscn")
			"profile":
				SceneTransition.fade_to_scene("res://escenas/menu/profile.tscn")
			"database":
				SceneTransition.fade_to_scene("res://escenas/menu/database.tscn")
			"exit":
				get_tree().quit()
	elif current_state == State.WORLD_SELECT:
		_launch_world(item.id)


func _go_to_state(new_state: State) -> void:
	_transitioning = true
	_transition_target = new_state
	_fade_alpha = 1.0


func _launch_world(world_id: String) -> void:
	match world_id:
		"tutorials":
			SceneTransition.fade_to_scene("res://escenas/main_menu/tutorials_menu.tscn")
		_:
			SceneParams.titulo_nivel = world_id
			SceneTransition.fade_to_scene("res://juego/system/level_select_screen.tscn")


func _cycle_lang(dir: int) -> void:
	_lang_idx = (_lang_idx + dir) % _lang_options.size()
	if _lang_idx < 0:
		_lang_idx = _lang_options.size() - 1
	LocUtil.set_locale(self, _lang_options[_lang_idx])
	_save_lang_setting()
	_refresh_texts()


func loc(key: String) -> String:
	return LocUtil.loc(self, key)


func _refresh_texts() -> void:
	_main_items[0].label = loc("menu.play")
	_main_items[0].desc = loc("menu.play_desc")
	_main_items[1].label = loc("menu.options")
	_main_items[1].desc = loc("menu.options_desc")
	_main_items[2].label = loc("menu.profile")
	_main_items[2].desc = loc("menu.profile_desc")
	_main_items[3].label = loc("menu.database")
	_main_items[3].desc = loc("menu.database_desc")
	_main_items[4].label = loc("menu.exit")

	_world_items[0].desc = loc("world.heist_desc")
	_world_items[1].desc = loc("world.hacker_desc")
	_world_items[2].desc = loc("world.cyber_desc")
	_world_items[3].label = loc("world.tutorials")
	_world_items[3].desc = loc("world.tutorials_desc")


func _load_lang_setting() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://settings.cfg")
	if err == OK:
		var saved: String = cfg.get_value("locale", "lang", "es")
		_lang_idx = _lang_options.find(saved)
		if _lang_idx < 0:
			_lang_idx = 0
		LocUtil.set_locale(self, _lang_options[_lang_idx])


func _save_lang_setting() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("locale", "lang", _lang_options[_lang_idx])
	cfg.save("user://settings.cfg")





func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.03, 0.03, 0.06))

	# Scan lines effect
	var scan_y: float = fmod(Time.get_ticks_msec() * 0.03, vp.y)
	draw_rect(Rect2(0, scan_y, vp.x, 2.0), Color(0.0, 1.0, 0.83, 0.08))
	draw_rect(Rect2(0, scan_y - vp.y, vp.x, 2.0), Color(0.0, 1.0, 0.83, 0.08))

	# Grid background
	var grid_color: Color = Color(0.08, 0.1, 0.15, 0.25)
	var spacing: float = 60.0
	var x: float = 0.0
	while x < vp.x:
		draw_line(Vector2(x, 0), Vector2(x, vp.y), grid_color, 1.0)
		x += spacing
	var gy: float = 0.0
	while gy < vp.y:
		draw_line(Vector2(0, gy), Vector2(vp.x, gy), grid_color, 1.0)
		gy += spacing

	if _transitioning and current_state == State.MAIN_MENU and _transition_target != State.MAIN_MENU:
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 1.0 - _fade_alpha))
		return

	var alpha: float = _fade_alpha if _transitioning else 1.0

	match current_state:
		State.MAIN_MENU:
			_draw_main_menu(vp, alpha)
		State.WORLD_SELECT:
			_draw_world_select(vp, alpha)

	_draw_lang_indicator(vp, alpha)


func _draw_main_menu(vp: Vector2, alpha: float) -> void:
	# Glow effect on title
	var glow: float = 0.6 + sin(_pulse * 1.5) * 0.4
	var title_color := Color(0.0, 1.0, 0.83, alpha * glow)
	draw_string(font, Vector2(62, 62), "VERTEX", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 12, Color(0.0, 0.5, 0.6, alpha * 0.3))
	draw_string(font, Vector2(60, 60), "VERTEX", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 12, title_color)

	var subtitle_color := Color(0.4, 0.6, 0.7, alpha)
	draw_string(font, Vector2(62, 90), loc("menu.subtitle"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, subtitle_color)

	# Decorative line under title
	draw_rect(Rect2(60, 100, 200, 2.0), Color(0.0, 1.0, 0.83, alpha * 0.5))

	var by: float = 150.0
	for i in _main_items.size():
		var item := _main_items[i]
		var is_sel: bool = i == selected_idx
		var text_color: Color
		var prefix: String

		if is_sel:
			var sel_glow := 0.7 + sin(_pulse * 2.0) * 0.3
			text_color = Color(0.0, 1.0, 0.83, alpha * sel_glow)
			prefix = "▶ "
			draw_rect(Rect2(50, by - 16, vp.x - 110, 32), Color(0.0, 1.0, 0.83, alpha * 0.08))
			draw_rect(Rect2(50, by - 16, 3, 32), Color(0.0, 1.0, 0.83, alpha * 0.6))
		else:
			text_color = Color(0.5, 0.55, 0.65, alpha)
			prefix = "  "

		draw_string(font, Vector2(68, by), prefix + item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 6, text_color)

		if item.desc != "":
			var desc_color := Color(0.3, 0.35, 0.42, alpha * 0.7)
			draw_string(font, Vector2(88, by + 18), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, desc_color)

		if item.get("action") == "play":
			var lk: String = "heist"
			for wk in ["heist", "hacker", "cybersecurity", "tutorials"]:
				if wk in progress and progress[wk] > 0:
					lk = wk

		by += 48

	by += 10
	draw_rect(Rect2(60, by - 5, vp.x - 120, 1.0), Color(0.0, 1.0, 0.83, alpha * 0.2))
	by += 10
	draw_string(font, Vector2(60, by), loc("menu.controls"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, Color(0.3, 0.6, 0.7, alpha))
	by += 20
	draw_string(font, Vector2(60, by), loc("menu.controls_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.3, 0.35, 0.42, alpha))


func _draw_world_select(vp: Vector2, alpha: float) -> void:
	var title_color := Color(0.0, 1.0, 0.83, alpha)
	var glow: float = 0.6 + sin(_pulse * 1.5) * 0.4

	draw_string(font, Vector2(62, 62), loc("menu.select_world"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 4, Color(0.0, 0.5, 0.6, alpha * 0.3))
	draw_string(font, Vector2(60, 60), loc("menu.select_world"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 4, title_color)
	draw_string(font, Vector2(60, 86), loc("menu.select_world_desc"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.4, 0.6, 0.7, alpha))
	draw_rect(Rect2(60, 96, 200, 2.0), Color(0.0, 1.0, 0.83, alpha * 0.4))

	var by: float = 140.0
	for i in _world_items.size():
		var item := _world_items[i]
		var is_sel: bool = i == selected_idx
		var text_color: Color
		var prefix: String

		if is_sel:
			var sel_glow := 0.7 + sin(_pulse * 2.0) * 0.3
			text_color = Color(0.0, 1.0, 0.83, alpha * sel_glow)
			prefix = "▶ "
			draw_rect(Rect2(50, by - 16, vp.x - 110, 32), Color(0.0, 1.0, 0.83, alpha * 0.08))
			draw_rect(Rect2(50, by - 16, 3, 32), Color(0.0, 1.0, 0.83, alpha * 0.6))
		else:
			text_color = Color(0.5, 0.55, 0.65, alpha)
			prefix = "  "

		draw_string(font, Vector2(68, by), prefix + item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 6, text_color)

		if item.desc != "":
			var desc_color := Color(0.3, 0.35, 0.42, alpha * 0.7)
			draw_string(font, Vector2(88, by + 18), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, desc_color)

		var world_id: String = item.id
		if world_id in progress and progress[world_id] > 0:
			var stars: int = progress[world_id]
			var s: String = ""
			for si in range(3):
				s += "★" if si < stars else "☆"
			draw_string(font, Vector2(vp.x - 160, by), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, Color(1.0, 0.9, 0.3, alpha))

		by += 48

	by += 10
	draw_rect(Rect2(60, by - 5, vp.x - 120, 1.0), Color(0.0, 1.0, 0.83, alpha * 0.2))
	by += 10
	draw_string(font, Vector2(60, by), loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.35, 0.38, 0.45, alpha))


func _draw_lang_indicator(vp: Vector2, alpha: float) -> void:
	var lang: String = _lang_options[_lang_idx].to_upper()
	var box_w: float = 80.0
	var box_h: float = 28.0
	var box_x: float = vp.x - box_w - 20.0
	var box_y: float = 20.0

	draw_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.1, 0.12, 0.18, alpha * 0.85))
	draw_rect(Rect2(box_x, box_y, box_w, box_h), Color(0.0, 1.0, 0.83, alpha * 0.3), false, 1.5)

	var text_w: float = font.get_string_size(lang, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1).x
	draw_string(font, Vector2(box_x + (box_w - text_w) / 2.0, box_y + 18), lang, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, Color(0.0, 1.0, 0.83, alpha))

	draw_string(font, Vector2(box_x - 60, box_y + 18), loc("menu.lang"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, Color(0.4, 0.45, 0.55, alpha))
