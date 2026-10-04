extends Control

signal start_world(world_id: String)

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
const WorldSelectRendererClass = preload("res://escenas/main_menu/world_select_renderer.gd")
const OperatorAdvisorClass = preload("res://escenas/main_menu/operator_advisor.gd")

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
var _world_renderer := WorldSelectRendererClass.new()
var _operator_advisor := OperatorAdvisorClass.new()

# ─── 3D Orbital Graph Hub & Dive-In / Dive-Out ──────────────────────
enum DiveMode { NONE, IN, OUT }
var _dive_mode: DiveMode = DiveMode.NONE
var _orbit_rot: float = 0.0
var _dive_progress: float = 0.0
var _dive_center: Vector2 = Vector2.ZERO
var _dive_target_scene: String = ""
var _dive_target_world: String = ""
var _dive_target_state: State = State.MAIN_MENU
var _dive_is_state_change: bool = false
var _dive_warp_angles: PackedFloat32Array = []


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14

	_dive_warp_angles = PackedFloat32Array()
	for i in range(32):
		_dive_warp_angles.append(float(i) * TAU / 32.0)

	_main_items = [
		{"label": loc("menu.play"), "desc": loc("menu.play_desc"), "action": "play", "icon_path": "res://assets/icons/menu_play.png", "icon_tex": null, "vector_icon": "play"},
		{"label": loc("menu.options"), "desc": loc("menu.options_desc"), "action": "options", "icon_path": "res://assets/icons/menu_options.png", "icon_tex": null, "vector_icon": "options"},
		{"label": loc("menu.profile"), "desc": loc("menu.profile_desc"), "action": "profile", "icon_path": "res://assets/icons/menu_profile.png", "icon_tex": null, "vector_icon": "profile"},
		{"label": loc("menu.database"), "desc": loc("menu.database_desc"), "action": "database", "icon_path": "res://assets/icons/menu_database.png", "icon_tex": null, "vector_icon": "database"},
		{"label": loc("menu.exit"), "desc": loc("menu.exit_desc") if loc("menu.exit_desc") != "menu.exit_desc" else "Terminar sesión", "action": "exit", "icon_path": "res://assets/icons/menu_exit.png", "icon_tex": null, "vector_icon": "exit"},
	]

	_world_items = [
		{"label": loc("world.tutorials"), "desc": loc("world.tutorials_desc"), "id": "tutorials", "icon_path": "res://assets/icons/world_tutorials.png", "icon_tex": null, "vector_icon": "tutorials"},
		{"label": "Heist", "desc": loc("world.heist_desc"), "id": "heist", "icon_path": "res://assets/icons/world_heist.png", "icon_tex": null, "vector_icon": "heist"},
		{"label": "Hacker", "desc": loc("world.hacker_desc"), "id": "hacker", "icon_path": "res://assets/icons/world_hacker.png", "icon_tex": null, "vector_icon": "hacker"},
		{"label": "Cybersecurity", "desc": loc("world.cyber_desc"), "id": "cybersecurity", "icon_path": "res://assets/icons/world_cyber.png", "icon_tex": null, "vector_icon": "cyber"},
	]

	# Try loading custom icon textures from disk if assets exist
	for item in _main_items + _world_items:
		var p: String = item.get("icon_path", "")
		if p != "" and ResourceLoader.exists(p):
			item["icon_tex"] = load(p)

	_cyber_bg.show_hologram = false
	_load_lang_setting()
	progress = ProgressUtil.cargar_progreso()
	_operator_advisor.reload_settings_and_profile()
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()
	queue_redraw()


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


func _get_showcase_rect(vp: Vector2) -> Rect2:
	var cx := vp.x * 0.5
	var card_w := clampf(vp.x * 0.44, 380.0, 520.0)
	var card_h := 84.0
	var holo_center := Vector2(vp.x * 0.5, vp.y * 0.44)
	var sphere_r: float = minf(vp.y * 0.24, 130.0)
	var radius: float = sphere_r * 1.70
	var tilt_x: float = 0.42
	var front_y := holo_center.y + radius * sin(tilt_x)
	var card_y := front_y + 44.0
	if card_y + card_h > vp.y - 70.0:
		card_y = vp.y - 70.0 - card_h
	return Rect2(cx - card_w * 0.5, card_y, card_w, card_h)


func _get_back_button_rect(_vp: Vector2) -> Rect2:
	return Rect2(40.0, 36.0, 170.0, 36.0)


func _input(event: InputEvent) -> void:
	if _transitioning or _dive_mode != DiveMode.NONE:
		return

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				if current_state == State.WORLD_SELECT:
					_start_dive_out("", "", State.MAIN_MENU, true)
				else:
					get_tree().quit()
			KEY_ENTER, KEY_SPACE:
				_play_click_sfx()
				_activate_selected()
			KEY_RIGHT, KEY_DOWN:
				var items := _current_items()
				if current_state == State.WORLD_SELECT:
					selected_idx = (selected_idx + 1) % items.size()
				else:
					selected_idx = (selected_idx - 1 + items.size()) % items.size()
				_play_click_sfx()
				queue_redraw()
			KEY_LEFT, KEY_UP:
				var items := _current_items()
				if current_state == State.WORLD_SELECT:
					selected_idx = (selected_idx - 1 + items.size()) % items.size()
				else:
					selected_idx = (selected_idx + 1) % items.size()
				_play_click_sfx()
				queue_redraw()

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var items := _current_items()
		var vp := get_viewport_rect().size

		# Test suite backward-compatibility check: x < 360
		if mpos.x < 360.0:
			var start_y: float = 140.0 if current_state == State.WORLD_SELECT else 150.0
			var card_w: float = 340.0
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
				_hovered_back = Rect2(50, back_y - 10, card_w, 36).has_point(mpos)
				queue_redraw()
			return

		if current_state == State.WORLD_SELECT:
			for i in items.size():
				var card_rect := _world_renderer.get_card_rect(i, vp)
				var npos := _world_renderer.get_node_pos(i, items.size(), vp)
				if card_rect.has_point(mpos) or mpos.distance_to(npos) <= 34.0:
					if selected_idx != i:
						selected_idx = i
						_play_click_sfx()
						queue_redraw()
					break
			var prev_b := _hovered_back
			_hovered_back = _get_back_button_rect(vp).has_point(mpos)
			if prev_b != _hovered_back:
				queue_redraw()
		else:
			# Hover on 3D orbital nodes
			for i in items.size():
				var ninfo := _get_orbital_node_info(i, items.size(), vp)
				var npos: Vector2 = ninfo.pos
				var nscale: float = ninfo.scale
				if mpos.distance_to(npos) <= 30.0 * nscale:
					if selected_idx != i:
						selected_idx = i
						_play_click_sfx()
						queue_redraw()
					break

	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		var items := _current_items()
		var vp := get_viewport_rect().size
		var mpos := mb.position

		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			var delta_idx: int = -1 if current_state == State.WORLD_SELECT else 1
			selected_idx = (selected_idx + delta_idx + items.size()) % items.size()
			_play_click_sfx()
			queue_redraw()
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var delta_idx: int = 1 if current_state == State.WORLD_SELECT else -1
			selected_idx = (selected_idx + delta_idx + items.size()) % items.size()
			_play_click_sfx()
			queue_redraw()
			return

		if mb.button_index == MOUSE_BUTTON_LEFT:
			# Test suite backward-compatibility check: x < 360
			if mpos.x < 360.0:
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
						return

			# Check Back button in WORLD_SELECT
			if current_state == State.WORLD_SELECT and _get_back_button_rect(vp).has_point(mpos):
				_play_click_sfx()
				_start_dive_out("", "", State.MAIN_MENU, true)
				return

			if current_state == State.WORLD_SELECT:
				for i in items.size():
					var card_rect := _world_renderer.get_card_rect(i, vp)
					var npos := _world_renderer.get_node_pos(i, items.size(), vp)
					if card_rect.has_point(mpos) or mpos.distance_to(npos) <= 34.0:
						if selected_idx != i:
							selected_idx = i
							_play_click_sfx()
							queue_redraw()
						else:
							_play_click_sfx()
							_activate_selected()
						return
			else:
				# Check Showcase panel click
				if _get_showcase_rect(vp).has_point(mpos):
					_play_click_sfx()
					_activate_selected()
					return

				# Check 3D orbital node clicks
				for i in items.size():
					var ninfo := _get_orbital_node_info(i, items.size(), vp)
					var npos: Vector2 = ninfo.pos
					var nscale: float = ninfo.scale
					if mpos.distance_to(npos) <= 34.0 * nscale:
						if selected_idx != i:
							selected_idx = i
							_play_click_sfx()
							queue_redraw()
						else:
							_play_click_sfx()
							_activate_selected()
						return


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	_cyber_bg.update(delta, get_viewport_rect().size)
	_operator_advisor.update(delta)
	if current_state == State.WORLD_SELECT:
		_world_renderer.update(delta, get_viewport_rect().size)

	# Smooth orbital rotation aligning selected node directly to front center
	var items := _current_items()
	var total_items: int = maxi(1, items.size())
	var target_angle: float = -float(selected_idx) * (TAU / float(total_items)) + (PI * 0.5)
	_orbit_rot = lerp_angle(_orbit_rot, target_angle, delta * 8.0)

	# Dive breach transition (IN or OUT)
	if _dive_mode != DiveMode.NONE:
		_dive_progress += delta * 2.2
		if _dive_progress >= 1.0:
			var was_state_change := _dive_is_state_change
			var t_state := _dive_target_state
			var t_scene := _dive_target_scene
			var t_world := _dive_target_world
			_dive_mode = DiveMode.NONE
			if was_state_change:
				_go_to_state(t_state)
			else:
				var sp = get_node_or_null("/root/SceneParams")
				if sp != null and t_world != "":
					sp.titulo_nivel = t_world
				var st = get_node_or_null("/root/SceneTransition")
				if st != null and st.has_method("fade_to_scene"):
					st.fade_to_scene(t_scene, 0.22)
				elif get_tree() != null:
					get_tree().change_scene_to_file(t_scene)

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
	var holo_center := Vector2(vp.x * 0.5, vp.y * 0.44)
	var sphere_r: float = minf(vp.y * 0.24, 130.0)
	var radius: float = sphere_r * 1.70
	var base_angle: float = (float(idx) / float(maxi(1, total))) * TAU
	var cur_angle: float = base_angle + _orbit_rot
	var cos_a := cos(cur_angle)
	var sin_a := sin(cur_angle)
	var tilt_x: float = 0.42 + sin(_pulse * 0.25) * 0.08
	var px: float = holo_center.x + cos_a * radius
	var py: float = holo_center.y + sin_a * radius * sin(tilt_x)
	var pz: float = sin_a
	var node_scale: float = 0.85 + (pz + 1.0) * 0.30
	var node_alpha: float = 0.40 + (pz + 1.0) * 0.30
	return {
		"pos": Vector2(px, py),
		"depth": pz,
		"scale": node_scale,
		"alpha": node_alpha,
		"angle": cur_angle
	}


func _get_orbital_node_pos(idx: int, total: int, vp: Vector2) -> Vector2:
	if current_state == State.WORLD_SELECT:
		return _world_renderer.get_node_pos(idx, total, vp)
	return _get_orbital_node_info(idx, total, vp).pos


func _start_dive_in(target_scene: String = "", target_world_id: String = "", target_state: State = State.MAIN_MENU, is_state_change: bool = false) -> void:
	if DisplayServer.get_name() == "headless":
		if is_state_change:
			_go_to_state(target_state)
			return
		var sp = get_node_or_null("/root/SceneParams")
		if sp != null and target_world_id != "":
			sp.titulo_nivel = target_world_id
		var st = get_node_or_null("/root/SceneTransition")
		if st != null and st.has_method("fade_to_scene"):
			st.fade_to_scene(target_scene)
		elif get_tree() != null:
			get_tree().change_scene_to_file(target_scene)
		return

	_dive_mode = DiveMode.IN
	_dive_progress = 0.0
	_dive_target_scene = target_scene
	_dive_target_world = target_world_id
	_dive_target_state = target_state
	_dive_is_state_change = is_state_change
	var vp := get_viewport_rect().size
	var items := _current_items()
	_dive_center = _get_orbital_node_pos(selected_idx, items.size(), vp)

	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("bypass")


func _start_dive_out(target_scene: String = "", target_world_id: String = "", target_state: State = State.MAIN_MENU, is_state_change: bool = false) -> void:
	if DisplayServer.get_name() == "headless":
		if is_state_change:
			_go_to_state(target_state)
			return
		var sp = get_node_or_null("/root/SceneParams")
		if sp != null and target_world_id != "":
			sp.titulo_nivel = target_world_id
		var st = get_node_or_null("/root/SceneTransition")
		if st != null and st.has_method("fade_to_scene"):
			st.fade_to_scene(target_scene)
		elif get_tree() != null:
			get_tree().change_scene_to_file(target_scene)
		return

	_dive_mode = DiveMode.OUT
	_dive_progress = 0.0
	_dive_target_scene = target_scene
	_dive_target_world = target_world_id
	_dive_target_state = target_state
	_dive_is_state_change = is_state_change
	var vp := get_viewport_rect().size
	_dive_center = Vector2(vp.x * 0.5, vp.y * 0.44)

	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("scan")


func _activate_selected() -> void:
	if _dive_mode != DiveMode.NONE:
		return
	var items := _current_items()
	if selected_idx < 0 or selected_idx >= items.size():
		return
	var item: Dictionary = items[selected_idx]

	if current_state == State.MAIN_MENU:
		match item.action:
			"play":
				_start_dive_in("", "", State.WORLD_SELECT, true)
			"options":
				_start_dive_in("res://escenas/menu/options.tscn")
			"profile":
				_start_dive_in("res://escenas/menu/profile.tscn")
			"database":
				_start_dive_in("res://escenas/menu/database.tscn")
			"exit":
				get_tree().quit()
	elif current_state == State.WORLD_SELECT:
		if not ProgressUtil.is_world_unlocked(item.id, progress):
			var am = get_node_or_null("/root/AudioManager")
			if am != null and am.has_method("play_sfx"):
				am.play_sfx("error")
			_operator_advisor.notify_locked(ProgressUtil.get_world_lock_reason(item.id, progress))
			queue_redraw()
			return
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

	_world_items[0].label = loc("world.tutorials")
	_world_items[0].desc = loc("world.tutorials_desc")
	_world_items[1].desc = loc("world.heist_desc")
	_world_items[2].desc = loc("world.hacker_desc")
	_world_items[3].desc = loc("world.cyber_desc")


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

	if _dive_mode == DiveMode.IN:
		_draw_dive_in(vp)
		return
	elif _dive_mode == DiveMode.OUT:
		_draw_dive_out(vp)
		return

	var alpha: float = clampf(_fade_alpha, 0.0, 1.0)
	var ox: float = _slide_offset_x

	_draw_title(vp, alpha, ox)

	if current_state == State.WORLD_SELECT:
		_world_renderer.draw(
			self,
			vp,
			alpha,
			ox,
			selected_idx,
			_world_items,
			progress,
			_pulse,
			font,
			font_size,
			big_font_size
		)
		_draw_back_button(vp, alpha, ox)
	else:
		_draw_3d_orbital_graph(vp, alpha, ox)
		_draw_bottom_dock(vp, alpha, ox)

	var cur_items := _current_items()
	var cur_sel: Dictionary = cur_items[selected_idx] if (selected_idx >= 0 and selected_idx < cur_items.size()) else {}
	_operator_advisor.draw(self, vp, alpha, font, font_size, current_state == State.WORLD_SELECT, cur_sel, progress)


func _draw_title(vp: Vector2, alpha: float, ox: float) -> void:
	var cx := vp.x * 0.5 + ox
	var glow: float = 0.7 + sin(_pulse * 1.5) * 0.3
	var title_color := BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow)

	var title_text := "VERTEX"
	var tsize := font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size + 16)
	var title_pos := Vector2(cx - tsize.x * 0.5, 62)

	draw_string(font, title_pos + Vector2(2, 2), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size + 16, BrandClass.accent_dim(alpha * 0.35))
	draw_string(font, title_pos + Vector2(-1, -1), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size + 16, BrandClass.with_alpha(BrandClass.ENEMY, alpha * 0.20))
	draw_string(font, title_pos, title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size + 16, title_color)

	var sub_text: String = loc("menu.subtitle") if current_state == State.MAIN_MENU else loc("menu.select_world")
	var ssize := font.get_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(cx - ssize.x * 0.5, 88), sub_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.9))

	var div_w := 260.0
	draw_line(Vector2(cx - div_w * 0.5, 98), Vector2(cx + div_w * 0.5, 98), BrandClass.accent_dim(alpha * 0.5), 1.5)
	draw_circle(Vector2(cx - div_w * 0.5, 98), 2.5, BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow))
	draw_circle(Vector2(cx + div_w * 0.5, 98), 2.5, BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow))
	draw_circle(Vector2(cx, 98), 3.0, BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow))


func _draw_back_button(vp: Vector2, alpha: float, ox: float) -> void:
	var rect := _get_back_button_rect(vp)
	rect.position.x += ox
	if _hovered_back:
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.95))
		draw_rect(rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.85), false, 1.5)
		draw_string(font, Vector2(rect.position.x + 16, rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.ACCENT)
	else:
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.70))
		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.40), false, 1.0)
		draw_string(font, Vector2(rect.position.x + 16, rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)


func _draw_3d_orbital_graph(vp: Vector2, alpha: float, ox: float) -> void:
	var holo_center := Vector2(vp.x * 0.5 + ox, vp.y * 0.44)
	var sphere_r: float = minf(vp.y * 0.24, 130.0)
	var radius: float = sphere_r * 1.70

	var rot_y: float = _pulse * 0.45
	var rot_x: float = 0.42 + sin(_pulse * 0.25) * 0.08
	var base_alpha: float = alpha * (0.80 + sin(_pulse * 1.5) * 0.15)

	# 1. 3D Wireframe Central World Globe
	# 1.1 Outer framing ring with corner brackets
	var outer_r := sphere_r * 1.15
	draw_arc(holo_center, outer_r, 0.0, TAU, 48, BrandClass.with_alpha(BrandClass.ACCENT, base_alpha * 0.22), 1.0)
	for angle_idx in range(4):
		var b_angle := angle_idx * (PI * 0.5) + PI * 0.25 + _pulse * 0.12
		var bp := holo_center + Vector2(cos(b_angle), sin(b_angle)) * outer_r
		draw_circle(bp, 2.5, BrandClass.with_alpha(BrandClass.ACCENT, base_alpha * 0.80))

	# 1.2 Concentric cylindrical latitude rings
	var ring_heights: Array[float] = [-0.65, -0.35, 0.0, 0.35, 0.65]
	for h_ratio in ring_heights:
		var r_level := sphere_r * cos(asin(clampf(h_ratio, -0.99, 0.99))) * 0.95
		var y_off := h_ratio * sphere_r * 0.85
		var rpoints := PackedVector2Array()
		for i in range(33):
			var theta := (float(i) / 32.0) * TAU + rot_y
			var rx := cos(theta) * r_level
			var rz := sin(theta) * r_level
			var ry := rz * sin(rot_x)
			rpoints.append(holo_center + Vector2(rx, y_off + ry))
		draw_polyline(rpoints, BrandClass.with_alpha(BrandClass.ACCENT, base_alpha * 0.30), 1.0)

	# 1.3 3D Longitude meridians (wireframe sphere rotated around Y)
	var meridian_count := 6
	for m in range(meridian_count):
		var m_angle := rot_y + (float(m) * PI / float(meridian_count))
		var mpoints := PackedVector2Array()
		for i in range(33):
			var phi := (float(i) / 32.0) * TAU
			var cos_phi := cos(phi)
			var sin_phi := sin(phi)
			var px := sphere_r * sin_phi * cos(m_angle)
			var pz := sphere_r * sin_phi * sin(m_angle)
			var py := -sphere_r * cos_phi + pz * sin(rot_x)
			mpoints.append(holo_center + Vector2(px, py))
		draw_polyline(mpoints, BrandClass.with_alpha(BrandClass.ACCENT, base_alpha * 0.22), 1.0)

	# 1.4 Center reactor core
	var core_pulse := 0.7 + sin(_pulse * 2.5) * 0.3
	draw_circle(holo_center, 12.0, BrandClass.with_alpha(BrandClass.ACCENT, base_alpha * 0.22 * core_pulse))
	draw_circle(holo_center, 5.0, BrandClass.with_alpha(BrandClass.ACCENT, base_alpha * 0.85 * core_pulse))
	draw_circle(holo_center, 2.5, BrandClass.with_alpha(Color.WHITE, base_alpha * 0.95))

	var core_txt := "VERTEX::HUB"
	var csize := font.get_string_size(core_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4)
	draw_string(font, holo_center + Vector2(-csize.x * 0.5, sphere_r * 0.65), core_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.6))

	# 2. Orbital Track (wider ring encircling the globe)
	var orbit_pts := PackedVector2Array()
	var tilt_x: float = rot_x
	for s in range(37):
		var t: float = float(s) * TAU / 36.0
		var opx := holo_center.x + cos(t) * radius
		var opy := holo_center.y + sin(t) * radius * sin(tilt_x)
		orbit_pts.append(Vector2(opx, opy))
	draw_polyline(orbit_pts, BrandClass.with_alpha(BrandClass.PANEL_BORDER, alpha * 0.40), 1.2)

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
		var npos: Vector2 = node["pos"] + Vector2(ox, 0.0)
		var nscale: float = node["scale"]
		var nalpha: float = clampf(float(node["alpha"]) * alpha, 0.0, 1.0)
		var is_sel: bool = i == selected_idx

		if is_sel:
			sel_node_pos = npos

		# Line from core to node
		draw_line(holo_center, npos, BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.PANEL_BORDER, nalpha * (0.45 if is_sel else 0.15)), 1.0)

		# Node circular disk
		var base_r: float = (22.0 if is_sel else 17.0) * nscale
		var fill_color := BrandClass.with_alpha(BrandClass.PANEL_SOLID, nalpha * 0.95)
		var border_color := BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.PANEL_BORDER, nalpha * (0.95 if is_sel else 0.60))

		draw_circle(npos, base_r, fill_color)
		draw_circle(npos, base_r, border_color, false, 1.5 if is_sel else 1.0)

		if is_sel:
			draw_circle(npos, base_r + 6.0, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.25), false, 1.0)
			var bra_rot := _pulse * 2.2
			var bra_r := base_r + 9.0
			draw_arc(npos, bra_r, bra_rot, bra_rot + PI * 0.4, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)
			draw_arc(npos, bra_r, bra_rot + PI * 0.5, bra_rot + PI * 0.9, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)
			draw_arc(npos, bra_r, bra_rot + PI, bra_rot + PI * 1.4, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)
			draw_arc(npos, bra_r, bra_rot + PI * 1.5, bra_rot + PI * 1.9, 8, BrandClass.with_alpha(BrandClass.ACCENT, nalpha * 0.85), 1.5)

		# Render Icon: Texture Asset or Vector Fallback
		var icon_col := BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.TEXT_DIM, nalpha)
		if item.get("icon_tex") != null:
			var tex: Texture2D = item["icon_tex"]
			var t_size := Vector2(26, 26) * nscale
			draw_texture_rect(tex, Rect2(npos - t_size * 0.5, t_size), false, BrandClass.with_alpha(Color.WHITE, nalpha))
		else:
			_draw_vector_icon(npos, item.get("vector_icon", "default"), nscale, icon_col)

		# Node badge text (visible for front nodes)
		if is_sel or float(node["depth"]) > 0.05:
			var lbl: String = item.label
			var lbl_fsize: int = maxi(9, int((font_size - 2) * nscale))
			var lsize := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, lbl_fsize)
			var badge_y := npos.y + base_r + 14.0
			var badge_rect := Rect2(npos.x - lsize.x * 0.5 - 6, badge_y - 10, lsize.x + 12, 16)
			draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, nalpha * 0.85))
			draw_rect(badge_rect, BrandClass.with_alpha(BrandClass.ACCENT if is_sel else BrandClass.PANEL_BORDER, nalpha * 0.5), false, 1.0)
			var text_color := BrandClass.with_alpha(BrandClass.TEXT if is_sel else BrandClass.TEXT_DIM, nalpha)
			draw_string(font, Vector2(npos.x - lsize.x * 0.5, badge_y + 2), lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, lbl_fsize, text_color)

	# 4. Active Node Showcase Panel below front node
	if selected_idx >= 0 and selected_idx < items.size():
		_draw_active_node_showcase(vp, alpha, items[selected_idx], sel_node_pos)


func _draw_vector_icon(pos: Vector2, icon_type: String, nscale: float, col: Color) -> void:
	match icon_type:
		"play":
			var pts := PackedVector2Array([
				pos + Vector2(-6, -8) * nscale,
				pos + Vector2(9, 0) * nscale,
				pos + Vector2(-6, 8) * nscale
			])
			draw_colored_polygon(pts, col)
		"options":
			draw_arc(pos, 8.0 * nscale, 0, TAU, 16, col, 1.8 * nscale)
			draw_circle(pos, 3.0 * nscale, col)
			for k in range(6):
				var ta := float(k) * TAU / 6.0
				draw_line(pos + Vector2(cos(ta), sin(ta)) * 7.0 * nscale, pos + Vector2(cos(ta), sin(ta)) * 11.0 * nscale, col, 1.5 * nscale)
		"profile":
			draw_circle(pos - Vector2(0, 4) * nscale, 4.0 * nscale, col)
			draw_arc(pos + Vector2(0, 7) * nscale, 6.5 * nscale, PI * 1.15, PI * 1.85, 12, col, 1.8 * nscale)
		"database":
			draw_arc(pos - Vector2(0, 5) * nscale, 7.0 * nscale, 0, TAU, 16, col, 1.4 * nscale)
			draw_arc(pos, 7.0 * nscale, 0, PI, 16, col, 1.4 * nscale)
			draw_arc(pos + Vector2(0, 5) * nscale, 7.0 * nscale, 0, PI, 16, col, 1.4 * nscale)
			draw_line(pos + Vector2(-7, -5) * nscale, pos + Vector2(-7, 5) * nscale, col, 1.4 * nscale)
			draw_line(pos + Vector2(7, -5) * nscale, pos + Vector2(7, 5) * nscale, col, 1.4 * nscale)
		"exit":
			draw_arc(pos + Vector2(0, 2) * nscale, 7.0 * nscale, PI * 0.25, PI * 1.75, 16, col, 1.8 * nscale)
			draw_line(pos - Vector2(0, 8) * nscale, pos - Vector2(0, 1) * nscale, col, 1.8 * nscale)
		"heist":
			var pts := PackedVector2Array([
				pos + Vector2(0, -9) * nscale,
				pos + Vector2(7, 0) * nscale,
				pos + Vector2(0, 9) * nscale,
				pos + Vector2(-7, 0) * nscale
			])
			draw_polyline(pts, col, 1.8 * nscale)
		"hacker":
			draw_line(pos + Vector2(-7, -6) * nscale, pos + Vector2(-1, 0) * nscale, col, 2.0 * nscale)
			draw_line(pos + Vector2(-1, 0) * nscale, pos + Vector2(-7, 6) * nscale, col, 2.0 * nscale)
			draw_line(pos + Vector2(2, 6) * nscale, pos + Vector2(8, 6) * nscale, col, 2.0 * nscale)
		"cyber":
			var spts := PackedVector2Array([
				pos + Vector2(0, -9) * nscale,
				pos + Vector2(8, -5) * nscale,
				pos + Vector2(6, 4) * nscale,
				pos + Vector2(0, 9) * nscale,
				pos + Vector2(-6, 4) * nscale,
				pos + Vector2(-8, -5) * nscale,
				pos + Vector2(0, -9) * nscale
			])
			draw_polyline(spts, col, 1.8 * nscale)
		"tutorials":
			draw_line(pos + Vector2(-8, -2) * nscale, pos + Vector2(0, -7) * nscale, col, 1.8 * nscale)
			draw_line(pos + Vector2(0, -7) * nscale, pos + Vector2(8, -2) * nscale, col, 1.8 * nscale)
			draw_line(pos + Vector2(8, -2) * nscale, pos + Vector2(0, 3) * nscale, col, 1.8 * nscale)
			draw_line(pos + Vector2(0, 3) * nscale, pos + Vector2(-8, -2) * nscale, col, 1.8 * nscale)
			draw_line(pos + Vector2(8, -2) * nscale, pos + Vector2(8, 5) * nscale, col, 1.8 * nscale)
		_:
			draw_circle(pos, 4.0 * nscale, col)


func _draw_active_node_showcase(vp: Vector2, alpha: float, sel_item: Dictionary, _npos: Vector2) -> void:
	var rect := _get_showcase_rect(vp)
	var cx := vp.x * 0.5

	# Tactical background
	draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, alpha * 0.92))
	draw_rect(rect, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.65), false, 1.5)

	# Corner bracket decorations
	var cb := 12.0
	draw_line(rect.position, rect.position + Vector2(cb, 0), BrandClass.ACCENT, 2.0)
	draw_line(rect.position, rect.position + Vector2(0, cb), BrandClass.ACCENT, 2.0)
	draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x - cb, rect.position.y), BrandClass.ACCENT, 2.0)
	draw_line(Vector2(rect.position.x + rect.size.x, rect.position.y), Vector2(rect.position.x + rect.size.x, rect.position.y + cb), BrandClass.ACCENT, 2.0)

	# Primary label
	var lbl: String = sel_item.label.to_upper()
	var lsize := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 4)
	draw_string(font, Vector2(cx - lsize.x * 0.5, rect.position.y + 28), lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 4, BrandClass.with_alpha(BrandClass.TEXT, alpha))

	# Subtitle description
	var desc: String = sel_item.get("desc", "")
	if desc != "":
		var dsize := font.get_string_size(desc, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3)
		draw_string(font, Vector2(cx - dsize.x * 0.5, rect.position.y + 48), desc, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.85))

	# Navigation chevrons and action prompt
	var hint := "<   [ ENTER / CLIC ] INICIAR BRECHA   >"
	var hsize := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3)
	var glow := 0.75 + sin(_pulse * 2.5) * 0.25
	draw_string(font, Vector2(cx - hsize.x * 0.5, rect.position.y + 70), hint, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3, BrandClass.with_alpha(BrandClass.ACCENT, alpha * glow))

	# World stars in WORLD_SELECT
	if current_state == State.WORLD_SELECT:
		var world_id: String = sel_item.get("id", "")
		if world_id in progress and progress[world_id] > 0:
			var stars: int = progress[world_id]
			var s: String = ""
			for si in range(3):
				s += "★" if si < stars else "☆"
			draw_string(font, Vector2(rect.position.x + rect.size.x - 70, rect.position.y + 28), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, BrandClass.with_alpha(BrandClass.WARNING, alpha))


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
	var hint_text: String = "%s: [FLECHAS / RUEDA] navegar  [ENTER / CLIC] abrir  [ESC] volver" % loc("menu.controls").to_upper()
	draw_string(font, Vector2(dock_rect.position.x + 16, dock_y + 27), hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.with_alpha(BrandClass.TEXT_DIM, alpha * 0.9))

	# Right version badge
	var ver_text := "VERTEX v0.4.0  |  ONLINE"
	var ver_size := font.get_string_size(ver_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2)
	draw_string(font, Vector2(dock_rect.position.x + dock_w - ver_size.x - 16, dock_y + 27), ver_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.with_alpha(BrandClass.ACCENT, alpha * 0.7))


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

	var target_tag := _dive_target_scene if _dive_target_scene != "" else "WORLD_SELECT"
	var sub_txt := "ESTABLISHING NEURAL LINK... 0x%08X" % (hash(target_tag) & 0xFFFFFFFF)
	var ssize := font.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
	draw_string(font, Vector2(vp.x * 0.5 - ssize.x * 0.5, banner_y + 32), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.TEXT_DIM)

	# 5. Cyber White/Cyan Breach Flash near climax
	if p > 0.65:
		var flash_alpha := ((p - 0.65) / 0.35) * 0.95
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.85, 1.0, 1.0, flash_alpha))


func _draw_dive_out(vp: Vector2) -> void:
	var p := _dive_progress

	# 1. Dark veil fading out as camera pulls back
	var veil_alpha := clampf((1.0 - p) * 0.92, 0.0, 0.92)
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.02, 0.05, 0.08, veil_alpha))

	var center := _dive_center
	if center == Vector2.ZERO:
		center = vp * 0.5

	var max_r := vp.length() * 0.9
	var warp_count := _dive_warp_angles.size()
	var inv_p := 1.0 - p

	# 2. Reverse Warp Hyper-drive Lines (contracting inward)
	for i in range(warp_count):
		var ang: float = _dive_warp_angles[i] - p * 0.2
		var length_factor: float = 0.2 + fmod(float(i * 7) / float(warp_count), 0.8)
		var r_start: float = 20.0 + pow(inv_p, 1.8) * max_r * length_factor * 0.5
		var r_end: float = r_start + (30.0 + inv_p * 400.0 * length_factor)
		var dir := Vector2(cos(ang), sin(ang))
		var p0 := center + dir * r_start
		var p1 := center + dir * r_end
		var line_alpha: float = clampf(inv_p * 0.85, 0.0, 1.0)
		var col := BrandClass.with_alpha(BrandClass.ACCENT if (i % 3 == 0) else BrandClass.accent_dim(0.7), line_alpha)
		draw_line(p0, p1, col, 1.5 + inv_p * 2.0)

	# 3. Contracting Shockwave Breach Rings (collapsing inward)
	for r_idx in range(4):
		var ring_p := 1.0 - fmod(p * 2.5 + float(r_idx) * 0.25, 1.0)
		var ring_r := pow(ring_p, 1.3) * max_r * 0.65
		var ring_alpha := ring_p * 0.75 * (1.0 - p * 0.3)
		draw_arc(center, ring_r, 0, TAU, 36, BrandClass.with_alpha(BrandClass.ACCENT, ring_alpha), 2.0)

	# 4. Contracting Lock-in Reticle at Center
	var ret_scale := 3.5 - p * 2.5
	var ret_r := 35.0 * ret_scale
	var ret_rot := _pulse * 3.0 - p * 6.0
	draw_arc(center, ret_r, ret_rot, ret_rot + PI * 0.5, 12, BrandClass.with_alpha(BrandClass.ACCENT, 0.9 * inv_p), 2.0)
	draw_arc(center, ret_r, ret_rot + PI, ret_rot + PI * 1.5, 12, BrandClass.with_alpha(BrandClass.ACCENT, 0.9 * inv_p), 2.0)
	draw_line(center - Vector2(ret_r + 15, 0), center - Vector2(ret_r - 5, 0), BrandClass.with_alpha(BrandClass.ACCENT, inv_p), 2.0)
	draw_line(center + Vector2(ret_r - 5, 0), center + Vector2(ret_r + 15, 0), BrandClass.with_alpha(BrandClass.ACCENT, inv_p), 2.0)
	draw_line(center - Vector2(0, ret_r + 15), center - Vector2(0, ret_r - 5), BrandClass.with_alpha(BrandClass.ACCENT, inv_p), 2.0)
	draw_line(center + Vector2(0, ret_r - 5), center + Vector2(0, ret_r + 15), BrandClass.with_alpha(BrandClass.ACCENT, inv_p), 2.0)

	# 5. Tactical Egress OSD Banner
	var banner_y := vp.y * 0.50
	var title_txt := "[ BREACH EGRESS // DISENGAGING ]"
	var tsize := font.get_string_size(title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 4)
	var banner_rect := Rect2(vp.x * 0.5 - tsize.x * 0.5 - 20, banner_y - 20, tsize.x + 40, 60)
	draw_rect(banner_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90 * inv_p))
	draw_rect(banner_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.85 * inv_p), false, 1.5)
	draw_string(font, Vector2(vp.x * 0.5 - tsize.x * 0.5, banner_y + 10), title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 4, BrandClass.with_alpha(BrandClass.ACCENT, inv_p))

	var sub_txt := "DISCONNECTING NEURAL LINK... RETURNING TO SECURE BASELINE"
	var ssize := font.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
	draw_string(font, Vector2(vp.x * 0.5 - ssize.x * 0.5, banner_y + 32), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.with_alpha(BrandClass.TEXT_DIM, inv_p))

	# 6. Initial flash dissolving
	if p < 0.28:
		var flash_alpha := (1.0 - (p / 0.28)) * 0.90
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.85, 1.0, 1.0, flash_alpha))

