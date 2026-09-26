extends Control

signal start_world(world_id: String)

const BrandClass = preload("res://juego/ui/brand.gd")

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
var _transition_stage: int = 0
var _slide_offset_x: float = 0.0
var _smooth_selected_y: float = 150.0
var _hovered_back: bool = false
var _pulse: float = 0.0


func _ready() -> void:
	font = BrandClass.font_regular()
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
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()
	queue_redraw()


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


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
				_play_click_sfx()
				_activate_selected()
			KEY_UP:
				selected_idx = maxi(0, selected_idx - 1)
				_play_click_sfx()
				queue_redraw()
			KEY_DOWN:
				var items := _current_items()
				selected_idx = mini(items.size() - 1, selected_idx + 1)
				_play_click_sfx()
				queue_redraw()

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var items := _current_items()
		var start_y: float = 140.0 if current_state == State.WORLD_SELECT else 150.0
		var vp := get_viewport_rect().size
		var prev_hover_back := _hovered_back
		_hovered_back = false
		for i in items.size():
			var item_by: float = start_y + i * 48.0
			var rect := Rect2(50, item_by - 16, vp.x - 110, 42)
			if rect.has_point(mpos):
				if selected_idx != i:
					selected_idx = i
					_play_click_sfx()
					queue_redraw()
				break
		if current_state == State.WORLD_SELECT:
			var back_y: float = start_y + items.size() * 48.0 + 10.0
			if Rect2(50, back_y - 10, 200, 36).has_point(mpos):
				_hovered_back = true
		if prev_hover_back != _hovered_back:
			queue_redraw()

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos := (event as InputEventMouseButton).position
		var items := _current_items()
		var start_y: float = 140.0 if current_state == State.WORLD_SELECT else 150.0
		var vp := get_viewport_rect().size
		for i in items.size():
			var item_by: float = start_y + i * 48.0
			var rect := Rect2(50, item_by - 16, vp.x - 110, 42)
			if rect.has_point(mpos):
				selected_idx = i
				_play_click_sfx()
				_activate_selected()
				return
		if current_state == State.WORLD_SELECT:
			var back_y: float = start_y + items.size() * 48.0 + 10.0
			if Rect2(50, back_y - 10, 200, 36).has_point(mpos):
				_go_to_state(State.MAIN_MENU)


func _process(delta: float) -> void:
	_pulse += delta * 2.0

	var target_start_y: float = 140.0 if current_state == State.WORLD_SELECT else 150.0
	var target_y: float = target_start_y + selected_idx * 48.0
	_smooth_selected_y = lerpf(_smooth_selected_y, target_y, delta * 20.0)

	if _transitioning:
		if _transition_stage == 1:
			_fade_alpha = move_toward(_fade_alpha, 0.0, delta * 8.0)
			_slide_offset_x = lerpf(_slide_offset_x, -30.0 if _transition_target == State.WORLD_SELECT else 30.0, delta * 16.0)
			if _fade_alpha <= 0.0:
				current_state = _transition_target
				selected_idx = 0
				_smooth_selected_y = 140.0 if current_state == State.WORLD_SELECT else 150.0
				_slide_offset_x = 30.0 if current_state == State.WORLD_SELECT else -30.0
				_transition_stage = 2
		elif _transition_stage == 2:
			_fade_alpha = move_toward(_fade_alpha, 1.0, delta * 8.0)
			_slide_offset_x = lerpf(_slide_offset_x, 0.0, delta * 16.0)
			if _fade_alpha >= 1.0 and absf(_slide_offset_x) < 0.5:
				_fade_alpha = 1.0
				_slide_offset_x = 0.0
				_transition_stage = 0
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
	if current_state == new_state and not _transitioning:
		return
	_transitioning = true
	_transition_target = new_state
	_transition_stage = 1
	_fade_alpha = 1.0
	_play_click_sfx()


func _launch_world(world_id: String) -> void:
	match world_id:
		"tutorials":
			SceneTransition.fade_to_scene("res://escenas/main_menu/tutorials_menu.tscn")
		_:
			SceneParams.titulo_nivel = world_id
			SceneTransition.fade_to_scene("res://juego/system/level_select_screen.tscn")


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
		if cfg.has_section_key("options", "lang"):
			var saved = cfg.get_value("options", "lang", 0)
			if saved is int and saved >= 0 and saved < _lang_options.size():
				_lang_idx = saved
			elif saved is String:
				var idx := _lang_options.find(saved.to_lower())
				if idx >= 0:
					_lang_idx = idx
		elif cfg.has_section_key("locale", "lang"):
			var saved_str: String = cfg.get_value("locale", "lang", "es")
			_lang_idx = _lang_options.find(saved_str)
			if _lang_idx < 0:
				_lang_idx = 0
		LocUtil.set_locale(self, _lang_options[_lang_idx])
		_refresh_texts()


func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp.x, vp.y), BrandClass.BG)

	# Scan lines effect
	var scan_y: float = fmod(Time.get_ticks_msec() * 0.03, vp.y)
	draw_rect(Rect2(0, scan_y, vp.x, 2.0), BrandClass.with_alpha(BrandClass.ACCENT, 0.08))
	draw_rect(Rect2(0, scan_y - vp.y, vp.x, 2.0), BrandClass.with_alpha(BrandClass.ACCENT, 0.08))

	# Grid background
	var grid_color: Color = BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.25)
	var spacing: float = 60.0
	var x: float = 0.0
	while x < vp.x:
		draw_line(Vector2(x, 0), Vector2(x, vp.y), grid_color, 1.0)
		x += spacing
	var gy: float = 0.0
	while gy < vp.y:
		draw_line(Vector2(0, gy), Vector2(vp.x, gy), grid_color, 1.0)
		gy += spacing

	var alpha: float = clampf(_fade_alpha, 0.0, 1.0)
	var ox: float = _slide_offset_x

	match current_state:
		State.MAIN_MENU:
			_draw_main_menu(vp, alpha, ox)
		State.WORLD_SELECT:
			_draw_world_select(vp, alpha, ox)


func _draw_main_menu(vp: Vector2, alpha: float, ox: float) -> void:
	# Glow effect on title
	var glow: float = 0.6 + sin(_pulse * 1.5) * 0.4
	var title_color := BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow)
	draw_string(font, Vector2(62 + ox, 62), "VERTEX", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 12, BrandClass.accent_dim(alpha * 0.3))
	draw_string(font, Vector2(60 + ox, 60), "VERTEX", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 12, title_color)

	var subtitle_color := BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha)
	draw_string(font, Vector2(62 + ox, 90), loc("menu.subtitle"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, subtitle_color)

	# Decorative line under title
	draw_rect(Rect2(60 + ox, 100, 200, 2.0), BrandClass.accent_dim(alpha * 0.5))

	# Smooth sliding selection pill
	var sel_glow := 0.7 + sin(_pulse * 2.0) * 0.3
	draw_rect(Rect2(50 + ox, _smooth_selected_y - 16, vp.x - 110, 32), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.08))
	draw_rect(Rect2(50 + ox, _smooth_selected_y - 16, 3, 32), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.7 * sel_glow))

	var by: float = 150.0
	for i in _main_items.size():
		var item := _main_items[i]
		var is_sel: bool = i == selected_idx
		var text_color: Color
		var prefix: String

		if is_sel:
			text_color = BrandClass.with_alpha(BrandClass.ACCENT, alpha * sel_glow)
			prefix = "▶ "
		else:
			text_color = BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha)
			prefix = "  "

		draw_string(font, Vector2(68 + ox, by), prefix + item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 6, text_color)

		if item.desc != "":
			var desc_color := BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.7)
			draw_string(font, Vector2(88 + ox, by + 18), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, desc_color)

		if item.get("action") == "play":
			var lk: String = "heist"
			for wk in ["heist", "hacker", "cybersecurity", "tutorials"]:
				if wk in progress and progress[wk] > 0:
					lk = wk

		by += 48.0

	by += 10.0
	draw_rect(Rect2(60 + ox, by - 5, vp.x - 120, 1.0), BrandClass.accent_dim(alpha * 0.2))
	by += 10.0
	draw_string(font, Vector2(60 + ox, by), loc("menu.controls"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha))
	by += 20.0
	draw_string(font, Vector2(60 + ox, by), loc("menu.controls_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha))


func _draw_world_select(vp: Vector2, alpha: float, ox: float) -> void:
	var title_color := BrandClass.with_alpha(BrandClass.ACCENT, alpha)

	draw_string(font, Vector2(62 + ox, 62), loc("menu.select_world"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 4, BrandClass.accent_dim(alpha * 0.3))
	draw_string(font, Vector2(60 + ox, 60), loc("menu.select_world"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 4, title_color)
	draw_string(font, Vector2(60 + ox, 86), loc("menu.select_world_desc"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha))
	draw_rect(Rect2(60 + ox, 96, 200, 2.0), BrandClass.accent_dim(alpha * 0.4))

	# Smooth sliding selection pill
	var sel_glow := 0.7 + sin(_pulse * 2.0) * 0.3
	draw_rect(Rect2(50 + ox, _smooth_selected_y - 16, vp.x - 110, 32), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.08))
	draw_rect(Rect2(50 + ox, _smooth_selected_y - 16, 3, 32), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.7 * sel_glow))

	var by: float = 140.0
	for i in _world_items.size():
		var item := _world_items[i]
		var is_sel: bool = i == selected_idx
		var text_color: Color
		var prefix: String

		if is_sel:
			text_color = BrandClass.with_alpha(BrandClass.ACCENT, alpha * sel_glow)
			prefix = "▶ "
		else:
			text_color = BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha)
			prefix = "  "

		draw_string(font, Vector2(68 + ox, by), prefix + item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 6, text_color)

		if item.desc != "":
			var desc_color := BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.7)
			draw_string(font, Vector2(88 + ox, by + 18), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, desc_color)

		var world_id: String = item.id
		if world_id in progress and progress[world_id] > 0:
			var stars: int = progress[world_id]
			var s: String = ""
			for si in range(3):
				s += "★" if si < stars else "☆"
				draw_string(font, Vector2(vp.x - 160 + ox, by), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.WARNING, alpha))

		by += 48.0

	by += 10.0
	draw_rect(Rect2(60 + ox, by - 5, vp.x - 120, 1.0), BrandClass.accent_dim(alpha * 0.2))
	by += 10.0

	# Interactive Back Button
	var back_rect := Rect2(50 + ox, by - 10, 200, 36)
	if _hovered_back:
		draw_rect(back_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.12 * alpha))
		draw_rect(back_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.8 * alpha), false, 1.2)
		draw_string(font, Vector2(68 + ox, by + 14), "← " + loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.with_alpha(BrandClass.ACCENT, alpha))
	else:
		draw_rect(back_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.25 * alpha), false, 1.0)
		draw_string(font, Vector2(68 + ox, by + 14), "← " + loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha))
