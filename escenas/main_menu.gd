extends Control

signal start_world(world_id: String)

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")

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
var _cyber_bg := CyberBackgroundClass.new()


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14

	_main_items = [
		{"label": loc("menu.play"), "desc": loc("menu.play_desc"), "action": "play", "icon": "▶"},
		{"label": loc("menu.options"), "desc": loc("menu.options_desc"), "action": "options", "icon": "⚙"},
		{"label": loc("menu.profile"), "desc": loc("menu.profile_desc"), "action": "profile", "icon": "👤"},
		{"label": loc("menu.database"), "desc": loc("menu.database_desc"), "action": "database", "icon": "🗄"},
		{"label": loc("menu.exit"), "desc": "", "action": "exit", "icon": "➔"},
	]

	_world_items = [
		{"label": "Heist", "desc": loc("world.heist_desc"), "id": "heist", "icon": "🗡"},
		{"label": "Hacker", "desc": loc("world.hacker_desc"), "id": "hacker", "icon": "💻"},
		{"label": "Cybersecurity", "desc": loc("world.cyber_desc"), "id": "cybersecurity", "icon": "🛡"},
		{"label": loc("world.tutorials"), "desc": loc("world.tutorials_desc"), "id": "tutorials", "icon": "📚"},
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
		var card_w: float = 340.0
		var prev_hover_back := _hovered_back
		_hovered_back = false
		for i in items.size():
			var item_by: float = start_y + i * 48.0
			var rect := Rect2(50, item_by - 16, card_w, 44)
			if rect.has_point(mpos):
				if selected_idx != i:
					selected_idx = i
					_play_click_sfx()
					queue_redraw()
				break
		if current_state == State.WORLD_SELECT:
			var back_y: float = start_y + items.size() * 48.0 + 10.0
			if Rect2(50, back_y - 10, card_w, 36).has_point(mpos):
				_hovered_back = true
		if prev_hover_back != _hovered_back:
			queue_redraw()

	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos := (event as InputEventMouseButton).position
		var items := _current_items()
		var start_y: float = 140.0 if current_state == State.WORLD_SELECT else 150.0
		var card_w: float = 340.0
		for i in items.size():
			var item_by: float = start_y + i * 48.0
			var rect := Rect2(50, item_by - 16, card_w, 44)
			if rect.has_point(mpos):
				selected_idx = i
				_play_click_sfx()
				_activate_selected()
				return
		if current_state == State.WORLD_SELECT:
			var back_y: float = start_y + items.size() * 48.0 + 10.0
			if Rect2(50, back_y - 10, card_w, 36).has_point(mpos):
				_go_to_state(State.MAIN_MENU)


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	_cyber_bg.update(delta, get_viewport_rect().size)

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
	_cyber_bg.draw(self, vp)

	var alpha: float = clampf(_fade_alpha, 0.0, 1.0)
	var ox: float = _slide_offset_x

	match current_state:
		State.MAIN_MENU:
			_draw_main_menu(vp, alpha, ox)
		State.WORLD_SELECT:
			_draw_world_select(vp, alpha, ox)


func _draw_main_menu(vp: Vector2, alpha: float, ox: float) -> void:
	# Glow effect on title with chromatic cyber shadow
	var glow: float = 0.7 + sin(_pulse * 1.5) * 0.3
	var title_color := BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow)

	draw_string(font, Vector2(62 + ox, 62), "VERTEX", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 14, BrandClass.accent_dim(alpha * 0.35))
	draw_string(font, Vector2(59 + ox, 59), "VERTEX", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 14, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.25))
	draw_string(font, Vector2(60 + ox, 60), "VERTEX", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 14, title_color)

	var subtitle_color := BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.9)
	draw_string(font, Vector2(62 + ox, 90), loc("menu.subtitle"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, subtitle_color)

	# Decorative circuit line under title
	draw_rect(Rect2(60 + ox, 102, 220, 2.0), BrandClass.accent_dim(alpha * 0.6))
	draw_circle(Vector2(280 + ox, 103), 2.5, BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow))

	var card_w: float = 340.0
	var card_h: float = 44.0
	var by: float = 146.0
	var sel_glow := 0.75 + sin(_pulse * 2.2) * 0.25

	for i in _main_items.size():
		var item := _main_items[i]
		var is_sel: bool = i == selected_idx
		var card_rect := Rect2(50 + ox, by - 16, card_w, card_h)

		if is_sel:
			# Highlighted card panel
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.92))
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.12))
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * sel_glow), false, 1.5)
			# Left active tab marker
			draw_rect(Rect2(card_rect.position.x, card_rect.position.y, 4, card_h), BrandClass.ACCENT)

			var icon: String = item.get("icon", "▶")
			draw_string(font, Vector2(68 + ox, by + 12), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.ACCENT, alpha * sel_glow))
			draw_string(font, Vector2(98 + ox, by + 12), item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.TEXT, alpha))

			if item.desc != "":
				draw_string(font, Vector2(98 + ox, by + 26), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.85))

			if vp.x > 800.0:
				_draw_telemetry_callout(vp, card_rect, item, alpha, ox)
		else:
			# Unselected card panel
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.60))
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.40), false, 1.0)

			var icon: String = item.get("icon", "•")
			draw_string(font, Vector2(68 + ox, by + 12), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.6))
			draw_string(font, Vector2(98 + ox, by + 12), item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.85))

			if item.desc != "":
				draw_string(font, Vector2(98 + ox, by + 26), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.45))

		by += 52.0

	_draw_bottom_dock(vp, alpha, ox)


func _draw_world_select(vp: Vector2, alpha: float, ox: float) -> void:
	var title_color := BrandClass.with_alpha(BrandClass.ACCENT, alpha)

	draw_string(font, Vector2(62 + ox, 62), loc("menu.select_world"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 4, BrandClass.accent_dim(alpha * 0.3))
	draw_string(font, Vector2(60 + ox, 60), loc("menu.select_world"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size + 4, title_color)
	draw_string(font, Vector2(60 + ox, 86), loc("menu.select_world_desc"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha))
	draw_rect(Rect2(60 + ox, 96, 200, 2.0), BrandClass.accent_dim(alpha * 0.4))

	var card_w: float = 340.0
	var card_h: float = 44.0
	var by: float = 140.0
	var sel_glow := 0.75 + sin(_pulse * 2.2) * 0.25

	for i in _world_items.size():
		var item := _world_items[i]
		var is_sel: bool = i == selected_idx
		var card_rect := Rect2(50 + ox, by - 16, card_w, card_h)

		if is_sel:
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.92))
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.12))
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * sel_glow), false, 1.5)
			draw_rect(Rect2(card_rect.position.x, card_rect.position.y, 4, card_h), BrandClass.ACCENT)

			var icon: String = item.get("icon", "▶")
			draw_string(font, Vector2(68 + ox, by + 12), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.ACCENT, alpha * sel_glow))
			draw_string(font, Vector2(98 + ox, by + 12), item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.TEXT, alpha))

			if item.desc != "":
				draw_string(font, Vector2(98 + ox, by + 26), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.85))

			if vp.x > 800.0:
				_draw_telemetry_callout(vp, card_rect, item, alpha, ox)
		else:
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.60))
			draw_rect(card_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.40), false, 1.0)

			var icon: String = item.get("icon", "•")
			draw_string(font, Vector2(68 + ox, by + 12), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.6))
			draw_string(font, Vector2(98 + ox, by + 12), item.label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.85))

			if item.desc != "":
				draw_string(font, Vector2(98 + ox, by + 26), item.desc, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.45))

		var world_id: String = item.id
		if world_id in progress and progress[world_id] > 0:
			var stars: int = progress[world_id]
			var s: String = ""
			for si in range(3):
				s += "★" if si < stars else "☆"
			draw_string(font, Vector2(card_rect.position.x + card_w - 55, by + 12), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, BrandClass.with_alpha(BrandClass.WARNING, alpha))

		by += 52.0

	# Interactive Back Button
	var back_rect := Rect2(50 + ox, by - 6, card_w, 38)
	if _hovered_back:
		draw_rect(back_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.14 * alpha))
		draw_rect(back_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.85 * alpha), false, 1.2)
		draw_string(font, Vector2(68 + ox, by + 18), "← " + loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.with_alpha(BrandClass.ACCENT, alpha))
	else:
		draw_rect(back_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.5 * alpha))
		draw_rect(back_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.35 * alpha), false, 1.0)
		draw_string(font, Vector2(68 + ox, by + 18), "← " + loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 1, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha))

	_draw_bottom_dock(vp, alpha, ox)


func _draw_telemetry_callout(vp: Vector2, card_rect: Rect2, item: Dictionary, alpha: float, ox: float) -> void:
	var tx0 := card_rect.position.x + card_rect.size.x
	var ty0 := card_rect.position.y + card_rect.size.y * 0.5
	var tx1 := tx0 + 20.0
	var tx2 := tx1 + 18.0
	var ty2 := ty0 - 6.0

	draw_line(Vector2(tx0, ty0), Vector2(tx1, ty0), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.7), 1.2)
	draw_line(Vector2(tx1, ty0), Vector2(tx2, ty2), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.7), 1.2)

	var tel_w := clampf(vp.x * 0.22, 180.0, 260.0)
	var tel_rect := Rect2(tx2, ty2 - 14.0, tel_w, 36.0)

	draw_rect(tel_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.90))
	draw_rect(tel_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.45), false, 1.0)
	draw_rect(Rect2(tel_rect.position.x, tel_rect.position.y, 2, tel_rect.size.y), BrandClass.ACCENT)

	var action: String = item.get("action", item.get("id", ""))
	var header_txt := "[SYS::%s]" % action.to_upper()
	var detail_txt := "node: 0x%08X" % (hash(action) & 0xFFFFFFFF)
	draw_string(font, Vector2(tx2 + 8, ty2), header_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 3, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.9))
	draw_string(font, Vector2(tx2 + 8, ty2 + 14), detail_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.75))


func _draw_bottom_dock(vp: Vector2, alpha: float, ox: float) -> void:
	var dock_h: float = 44.0
	var dock_y: float = vp.y - dock_h - 16.0
	var dock_w: float = vp.x - 80.0
	var dock_rect := Rect2(40.0 + ox, dock_y, dock_w, dock_h)

	# Frosted dock plate
	draw_rect(dock_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.85))
	draw_rect(dock_rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.35), false, 1.2)
	draw_line(Vector2(dock_rect.position.x + 2, dock_rect.position.y + 1), Vector2(dock_rect.position.x + dock_w - 2, dock_rect.position.y + 1), BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.5), 1.0)

	# Left localized shortcuts
	var hint_text: String = "%s: %s" % [loc("menu.controls").to_upper(), loc("menu.controls_hint")]
	draw_string(font, Vector2(dock_rect.position.x + 16, dock_y + 27), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.9))

	# Right version badge
	var ver_text := "VERTEX v0.4.0  |  ONLINE"
	var ver_size := font.get_string_size(ver_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
	draw_string(font, Vector2(dock_rect.position.x + dock_w - ver_size.x - 16, dock_y + 27), ver_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.7))
