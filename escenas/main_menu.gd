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

# ─── 3D Orbital Graph Hub & Dive-In ─────────────────────────────────
var _orbit_rot: float = 0.0
var _is_diving: bool = false
var _dive_progress: float = 0.0
var _dive_center: Vector2 = Vector2.ZERO
var _dive_target_scene: String = ""
var _dive_target_world: String = ""
var _dive_warp_angles: PackedFloat32Array = []


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14

	_dive_warp_angles = PackedFloat32Array()
	for i in range(32):
		_dive_warp_angles.append(float(i) * TAU / 32.0)

	_main_items = [
		{"label": loc("menu.play"), "desc": loc("menu.play_desc"), "action": "play", "icon": "[>]"},
		{"label": loc("menu.options"), "desc": loc("menu.options_desc"), "action": "options", "icon": "[#]"},
		{"label": loc("menu.profile"), "desc": loc("menu.profile_desc"), "action": "profile", "icon": "[ID]"},
		{"label": loc("menu.database"), "desc": loc("menu.database_desc"), "action": "database", "icon": "[DB]"},
		{"label": loc("menu.exit"), "desc": "", "action": "exit", "icon": "[X]"},
	]

	_world_items = [
		{"label": "Heist", "desc": loc("world.heist_desc"), "id": "heist", "icon": "[HST]"},
		{"label": "Hacker", "desc": loc("world.hacker_desc"), "id": "hacker", "icon": "[HCK]"},
		{"label": "Cybersecurity", "desc": loc("world.cyber_desc"), "id": "cybersecurity", "icon": "[DEF]"},
		{"label": loc("world.tutorials"), "desc": loc("world.tutorials_desc"), "id": "tutorials", "icon": "[TUT]"},
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
			KEY_UP, KEY_LEFT:
				var items := _current_items()
				selected_idx = (selected_idx - 1 + items.size()) % items.size()
				_play_click_sfx()
				queue_redraw()
			KEY_DOWN, KEY_RIGHT:
				var items := _current_items()
				selected_idx = (selected_idx + 1) % items.size()
				_play_click_sfx()
				queue_redraw()

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var items := _current_items()
		var start_y: float = 140.0 if current_state == State.WORLD_SELECT else 150.0
		var card_w: float = 340.0
		var prev_hover_back := _hovered_back
		_hovered_back = false
		var hovered_any: bool = false
		for i in items.size():
			var item_by: float = start_y + i * 48.0
			var rect := Rect2(50, item_by - 16, card_w, 44)
			if rect.has_point(mpos):
				hovered_any = true
				if selected_idx != i:
					selected_idx = i
					_play_click_sfx()
					queue_redraw()
				break

		# Check 3D orbital nodes if not hovering card
		if not hovered_any:
			var vp := get_viewport_rect().size
			for i in items.size():
				var npos: Vector2 = _get_orbital_node_pos(i, items.size(), vp)
				if mpos.distance_to(npos) <= 30.0:
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

		# Check 3D orbital nodes click
		var vp := get_viewport_rect().size
		for i in items.size():
			var npos: Vector2 = _get_orbital_node_pos(i, items.size(), vp)
			if mpos.distance_to(npos) <= 30.0:
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

	# Smooth orbital rotation aligning selected node to the front
	var items := _current_items()
	var total_items: int = maxi(1, items.size())
	var target_angle: float = -float(selected_idx) * (TAU / float(total_items)) + (PI * 0.5)
	_orbit_rot = lerp_angle(_orbit_rot, target_angle, delta * 8.0)

	# Dive-in breach transition
	if _is_diving:
		_dive_progress += delta * 2.2
		if _dive_progress >= 1.0:
			_is_diving = false
			var sp = get_node_or_null("/root/SceneParams")
			if sp != null and _dive_target_world != "":
				sp.titulo_nivel = _dive_target_world
			var st = get_node_or_null("/root/SceneTransition")
			if st != null and st.has_method("fade_to_scene"):
				st.fade_to_scene(_dive_target_scene, 0.22)
			elif get_tree() != null:
				get_tree().change_scene_to_file(_dive_target_scene)

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


func _get_orbital_node_info(idx: int, total: int, vp: Vector2) -> Dictionary:
	var holo_center := Vector2(vp.x * 0.72, vp.y * 0.50)
	var radius: float = minf(vp.x, vp.y) * 0.32
	var base_angle: float = (float(idx) / float(maxi(1, total))) * TAU
	var cur_angle: float = base_angle + _orbit_rot
	var cos_a := cos(cur_angle)
	var sin_a := sin(cur_angle)
	var tilt_x: float = 0.38 + sin(_pulse * 0.25) * 0.12
	var px: float = holo_center.x + cos_a * radius
	var py: float = holo_center.y + sin_a * radius * sin(tilt_x)
	var pz: float = sin_a
	var node_scale: float = 0.82 + (pz + 1.0) * 0.24
	var node_alpha: float = 0.45 + (pz + 1.0) * 0.28
	return {
		"pos": Vector2(px, py),
		"depth": pz,
		"scale": node_scale,
		"alpha": node_alpha,
		"angle": cur_angle
	}


func _get_orbital_node_pos(idx: int, total: int, vp: Vector2) -> Vector2:
	return _get_orbital_node_info(idx, total, vp).pos


func _start_dive_in(target_scene: String, target_world_id: String = "") -> void:
	if DisplayServer.get_name() == "headless":
		var sp = get_node_or_null("/root/SceneParams")
		if sp != null and target_world_id != "":
			sp.titulo_nivel = target_world_id
		var st = get_node_or_null("/root/SceneTransition")
		if st != null and st.has_method("fade_to_scene"):
			st.fade_to_scene(target_scene)
		elif get_tree() != null:
			get_tree().change_scene_to_file(target_scene)
		return

	_is_diving = true
	_dive_progress = 0.0
	_dive_target_scene = target_scene
	_dive_target_world = target_world_id
	var vp := get_viewport_rect().size
	var items := _current_items()
	_dive_center = _get_orbital_node_pos(selected_idx, items.size(), vp)

	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("bypass")


func _activate_selected() -> void:
	if _is_diving:
		return
	var items := _current_items()
	if selected_idx < 0 or selected_idx >= items.size():
		return
	var item: Dictionary = items[selected_idx]

	if current_state == State.MAIN_MENU:
		match item.action:
			"play":
				_go_to_state(State.WORLD_SELECT)
			"options":
				_start_dive_in("res://escenas/menu/options.tscn")
			"profile":
				_start_dive_in("res://escenas/menu/profile.tscn")
			"database":
				_start_dive_in("res://escenas/menu/database.tscn")
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
			_start_dive_in("res://escenas/main_menu/tutorials_menu.tscn")
		_:
			_start_dive_in("res://juego/system/level_select_screen.tscn", world_id)


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

	if _is_diving:
		_draw_dive_in(vp)
		return

	var alpha: float = clampf(_fade_alpha, 0.0, 1.0)
	var ox: float = _slide_offset_x

	match current_state:
		State.MAIN_MENU:
			_draw_main_menu(vp, alpha, ox)
		State.WORLD_SELECT:
			_draw_world_select(vp, alpha, ox)

	_draw_3d_orbital_graph(vp, alpha, ox)


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


func _draw_3d_orbital_graph(vp: Vector2, alpha: float, ox: float) -> void:
	if vp.x < 750.0:
		return

	var holo_center := Vector2(vp.x * 0.72 + ox * 0.5, vp.y * 0.48)
	var radius: float = minf(vp.x * 0.22, vp.y * 0.32)

	# 1. Central Gyroscope Wireframe Core
	var gyro_pulse := 0.7 + sin(_pulse * 1.8) * 0.3
	draw_arc(holo_center, 42.0, 0, TAU, 32, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.4), 1.2)
	var g_angle := _pulse * 0.6
	draw_arc(holo_center, 30.0, g_angle, g_angle + PI * 0.75, 16, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.6 * gyro_pulse), 1.5)
	draw_arc(holo_center, 30.0, g_angle + PI, g_angle + PI * 1.75, 16, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.6 * gyro_pulse), 1.5)
	draw_arc(holo_center, 18.0, -g_angle * 1.3, -g_angle * 1.3 + PI * 1.2, 16, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.5), 1.2)
	draw_circle(holo_center, 4.0, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.9 * gyro_pulse))
	draw_circle(holo_center, 10.0, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.25))

	var core_txt := "VERTEX::CORE"
	var csize := font.get_string_size(core_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4)
	draw_string(font, holo_center + Vector2(-csize.x * 0.5, 56), core_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.6))

	# 2. Orbital Track
	var orbit_pts := PackedVector2Array()
	var tilt_x: float = 0.38 + sin(_pulse * 0.25) * 0.12
	for s in range(37):
		var t: float = float(s) * TAU / 36.0
		var opx := holo_center.x + cos(t) * radius
		var opy := holo_center.y + sin(t) * radius * sin(tilt_x)
		orbit_pts.append(Vector2(opx, opy))
	draw_polyline(orbit_pts, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.35), 1.0)

	# 3. Depth-sorted Orbital Nodes
	var items := _current_items()
	var total_items := items.size()
	if total_items == 0:
		return

	var node_entries: Array[Dictionary] = []
	for i in range(total_items):
		var info := _get_orbital_node_info(i, total_items, vp)
		info["idx"] = i
		info["item"] = items[i]
		node_entries.append(info)

	node_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["depth"]) < float(b["depth"])
	)

	var sel_node_pos := Vector2.ZERO

	for node in node_entries:
		var i: int = node["idx"]
		var item: Dictionary = node["item"]
		var npos: Vector2 = node["pos"] + Vector2(ox * 0.5, 0.0)
		var nscale: float = node["scale"]
		var nalpha: float = clampf(float(node["alpha"]) * alpha, 0.0, 1.0)
		var is_sel: bool = i == selected_idx

		if is_sel:
			sel_node_pos = npos

		# Line from core to node
		draw_line(holo_center, npos, BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.PANEL_BORDER, nalpha * (0.45 if is_sel else 0.15)), 1.0)

		# Node body circle
		var base_r: float = (20.0 if is_sel else 16.0) * nscale
		var fill_color := BrandClass.with_alpha(BrandClass.PANEL_SOLID, nalpha * 0.95)
		var border_color := BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.PANEL_BORDER, nalpha * (0.95 if is_sel else 0.60))

		draw_circle(npos, base_r, fill_color)
		draw_circle(npos, base_r, border_color, false, 1.5 if is_sel else 1.0)

		if is_sel:
			draw_circle(npos, base_r + 6.0, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.25), false, 1.0)
			var bra_rot := _pulse * 2.0
			var bra_r := base_r + 9.0
			draw_arc(npos, bra_r, bra_rot, bra_rot + PI * 0.4, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)
			draw_arc(npos, bra_r, bra_rot + PI * 0.5, bra_rot + PI * 0.9, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)
			draw_arc(npos, bra_r, bra_rot + PI, bra_rot + PI * 1.4, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)
			draw_arc(npos, bra_r, bra_rot + PI * 1.5, bra_rot + PI * 1.9, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)

		# Tactical ASCII icon text
		var icon: String = item.get("icon", "[*]")
		var icon_fsize: int = maxi(10, int((font_size + (2 if is_sel else 0)) * nscale))
		var isize := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_CENTER, -1, icon_fsize)
		var icon_color := BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.TEXT_DIM, nalpha)
		draw_string(font, npos + Vector2(-isize.x * 0.5, isize.y * 0.35), icon, HORIZONTAL_ALIGNMENT_CENTER, -1, icon_fsize, icon_color)

		# Label badge below node
		if is_sel or float(node["depth"]) > 0.1:
			var lbl: String = item.label
			var lbl_fsize: int = maxi(9, int((font_size - 2) * nscale))
			var lsize := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, lbl_fsize)
			var badge_y := npos.y + base_r + 14.0
			var badge_rect := Rect2(npos.x - lsize.x * 0.5 - 6, badge_y - 10, lsize.x + 12, 16)
			draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, nalpha * 0.85))
			draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.PANEL_BORDER, nalpha * 0.5), false, 1.0)
			var text_color := BrandClass.with_alpha(BrandClass.TEXT if is_sel else BrandClass.TEXT_DIM, nalpha)
			draw_string(font, Vector2(npos.x - lsize.x * 0.5, badge_y + 2), lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, lbl_fsize, text_color)

	# 4. Holographic Bridge connecting active card to 3D node
	if sel_node_pos != Vector2.ZERO:
		var start_y: float = 140.0 if current_state == State.WORLD_SELECT else 150.0
		var card_y: float = start_y + selected_idx * 48.0
		var card_edge := Vector2(50.0 + 340.0 + ox, card_y + 6.0)
		if vp.x > 800.0:
			var tel_w := clampf(vp.x * 0.22, 180.0, 260.0)
			card_edge.x = 50.0 + 340.0 + 38.0 + tel_w + ox

		var mid_x := (card_edge.x + sel_node_pos.x) * 0.5
		var p1 := Vector2(mid_x, card_edge.y)
		var p2 := Vector2(mid_x, sel_node_pos.y)

		var bridge_color := BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.40)
		draw_line(card_edge, p1, bridge_color, 1.2)
		draw_line(p1, p2, bridge_color, 1.2)
		draw_line(p2, sel_node_pos, bridge_color, 1.2)

		var t_pkt := fmod(_pulse * 2.2, 1.0)
		var pkt_pos: Vector2
		if t_pkt < 0.33:
			pkt_pos = card_edge.lerp(p1, t_pkt / 0.33)
		elif t_pkt < 0.66:
			pkt_pos = p1.lerp(p2, (t_pkt - 0.33) / 0.33)
		else:
			pkt_pos = p2.lerp(sel_node_pos, (t_pkt - 0.66) / 0.34)

		draw_circle(pkt_pos, 2.5, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.95))
		draw_circle(pkt_pos, 5.5, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.35))


func _draw_dive_in(vp: Vector2) -> void:
	var p := _dive_progress
	var veil_alpha := clampf(p * 1.5, 0.0, 0.92)
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.02, 0.05, 0.08, veil_alpha))

	var center := _dive_center
	if center == Vector2.ZERO:
		center = vp * 0.5

	# 1. Radial Warp Hyper-drive Lines
	var max_r := vp.length() * 0.9
	var warp_count := _dive_warp_angles.size()
	for i in range(warp_count):
		var ang: float = _dive_warp_angles[i] + p * 0.2
		var length_factor: float = 0.2 + fmod(float(i * 7) / float(warp_count), 0.8)
		var r_start: float = 20.0 + pow(p, 1.8) * max_r * length_factor * 0.5
		var r_end: float = r_start + (30.0 + p * 400.0 * length_factor)
		var dir := Vector2(cos(ang), sin(ang))
		var p0 := center + dir * r_start
		var p1 := center + dir * r_end
		var line_alpha: float = clampf((1.0 - p * 0.7) * 0.85, 0.0, 1.0)
		var col := BrandClass.with_alpha(BrandClass.ACCENT if (i % 3 == 0) else BrandClass.accent_dim(0.7), line_alpha)
		draw_line(p0, p1, col, 1.5 + p * 2.0)

	# 2. Concentric Shockwave Breach Rings
	for r_idx in range(4):
		var ring_p := fmod(p * 2.5 + float(r_idx) * 0.25, 1.0)
		var ring_r := pow(ring_p, 1.3) * max_r * 0.65
		var ring_alpha := (1.0 - ring_p) * 0.75 * (1.0 - p * 0.5)
		draw_arc(center, ring_r, 0, TAU, 36, BrandClass.with_alpha(BrandClass.ACCENT, ring_alpha), 2.0)

	# 3. Expanding Breach Reticle at Center
	var ret_scale := 1.0 + p * 4.0
	var ret_r := 35.0 * ret_scale
	var ret_rot := _pulse * 3.0 + p * 6.0
	draw_arc(center, ret_r, ret_rot, ret_rot + PI * 0.5, 12, BrandClass.with_alpha(BrandClass.ACCENT, 0.9), 2.0)
	draw_arc(center, ret_r, ret_rot + PI, ret_rot + PI * 1.5, 12, BrandClass.with_alpha(BrandClass.ACCENT, 0.9), 2.0)
	draw_line(center - Vector2(ret_r + 15, 0), center - Vector2(ret_r - 5, 0), BrandClass.ACCENT, 2.0)
	draw_line(center + Vector2(ret_r - 5, 0), center + Vector2(ret_r + 15, 0), BrandClass.ACCENT, 2.0)
	draw_line(center - Vector2(0, ret_r + 15), center - Vector2(0, ret_r - 5), BrandClass.ACCENT, 2.0)
	draw_line(center + Vector2(0, ret_r - 5), center + Vector2(0, ret_r + 15), BrandClass.ACCENT, 2.0)

	# 4. Tactical OSD Banner
	var banner_y := vp.y * 0.50
	var title_txt := "[ BREACH PENETRATION // INITIATED ]"
	var tsize := font.get_string_size(title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 4)
	var banner_rect := Rect2(vp.x * 0.5 - tsize.x * 0.5 - 20, banner_y - 20, tsize.x + 40, 60)
	draw_rect(banner_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
	draw_rect(banner_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.85), false, 1.5)
	draw_string(font, Vector2(vp.x * 0.5 - tsize.x * 0.5, banner_y + 10), title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 4, BrandClass.ACCENT)

	var sub_txt := "ESTABLISHING NEURAL LINK... 0x%08X" % (hash(_dive_target_scene) & 0xFFFFFFFF)
	var ssize := font.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
	draw_string(font, Vector2(vp.x * 0.5 - ssize.x * 0.5, banner_y + 32), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.TEXT_DIM)

	# 5. Cyber White/Cyan Breach Flash near climax
	if p > 0.65:
		var flash_alpha := ((p - 0.65) / 0.35) * 0.95
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.85, 1.0, 1.0, flash_alpha))

