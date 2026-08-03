extends Control

signal step_changed(step_index: int, step_data: Dictionary)
signal tutorial_completed(tutorial_id: String)
signal tutorial_skipped(tutorial_id: String)

var tutorial_data: Dictionary = {}
var steps: Array = []
var current_step_index: int = -1
var is_active: bool = false
var is_paused_by_tutorial: bool = false

var font: Font
var font_size: int = 14
var big_font_size: int = 18
var small_font_size: int = 12

var _auto_advance_timer: float = 0.0
var _auto_advance_target: float = 0.0
var _action_fulfilled: bool = false
var _waiting_for_action: bool = false

var _panel_color: Color = Color(0.05, 0.05, 0.1, 0.92)
var _panel_border: Color = Color(0.0, 1.0, 0.83, 0.8)
var _text_color: Color = Color.WHITE
var _accent_color: Color = Color(0.0, 1.0, 0.83)
var _warning_color: Color = Color(1.0, 0.18, 0.58)
var _btn_color: Color = Color(0.0, 0.8, 0.6)
var _btn_hover_color: Color = Color(0.0, 1.0, 0.83)

var _panel_rect: Rect2 = Rect2()
var _panel_alpha: float = 0.0
var _target_alpha: float = 0.0

var _locale: Node = null

var _btn_rect: Rect2 = Rect2()
var _btn_hovered: bool = false

# Task 3.2: Navigation
var _show_step_index: bool = false

# Task 3.3: Hints
var _hint_used: bool = false
var _attempts: int = 0
var _hint_shown: bool = false
var _hint_stuck_timer: float = 0.0
var _hint_auto_after: float = 10.0


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 4
	small_font_size = font_size - 2
	visible = false

	_locale = get_node_or_null("/root/Locale")
	if _locale == null:
		var scene: PackedScene = load("res://core/locale/locale_manager.tscn")
		if scene != null:
			_locale = scene.instantiate()
		else:
			_locale = Node.new()
			_locale.set_script(load("res://core/locale/locale_manager.gd"))
		_locale.name = "Locale"
		get_tree().root.add_child(_locale)


func t(key: String) -> String:
	if _locale != null and _locale.has_method("loc"):
		return _locale.loc(key)
	return key


func load_tutorial(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TutorialPlayer: no se pudo abrir %s" % path)
		return false

	var json_text: String = file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_error("TutorialPlayer: JSON invalido en %s" % path)
		return false

	tutorial_data = parsed
	steps = tutorial_data.get("steps", [])
	if steps.is_empty():
		push_warning("TutorialPlayer: tutorial sin steps en %s" % path)
		return false

	current_step_index = -1
	is_active = true
	visible = true
	modulate.a = 1.0
	_panel_alpha = 0.0
	_target_alpha = 1.0

	GameLogger.info("TutorialPlayer", "Tutorial cargado: %s (%d pasos)" % [tutorial_data.get("id", "?"), steps.size()])
	return true


func start() -> void:
	if not is_active or steps.is_empty():
		return
	_advance_to_step(0)


func skip() -> void:
	if not is_active:
		return
	var tid: String = tutorial_data.get("id", "")
	_finish_tutorial()
	tutorial_skipped.emit(tid)
	GameLogger.info("TutorialPlayer", "Tutorial saltado: %s" % tid)


func advance() -> void:
	if not is_active:
		return
	if _waiting_for_action and not _action_fulfilled:
		_attempts += 1
		if _attempts >= 3 and not _hint_shown and get_hint() != "":
			_hint_shown = true
		return
	if current_step_index >= steps.size() - 1:
		_finish_tutorial()
		return
	_advance_to_step(current_step_index + 1)


func previous() -> void:
	if not is_active or current_step_index <= 0:
		return
	_advance_to_step(current_step_index - 1)


func go_to_step(idx: int) -> void:
	if not is_active or idx < 0 or idx >= steps.size():
		return
	_advance_to_step(idx)


func get_steps_summary() -> Array:
	var summary: Array = []
	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		summary.append({
			"index": i,
			"id": step.get("id", ""),
			"title": step.get("title", step.get("id", "Paso " + str(i + 1)))
		})
	return summary


func get_hint() -> String:
	if current_step_index < 0 or current_step_index >= steps.size():
		return ""
	var step: Dictionary = steps[current_step_index]
	return step.get("hint", "")


func show_hint() -> void:
	if _hint_shown:
		return
	_hint_shown = true
	_hint_used = true
	GameLogger.info("TutorialPlayer", "Hint mostrado en paso %d" % (current_step_index + 1))


func notify_action(action_type: String) -> void:
	if not is_active or not _waiting_for_action:
		return
	var step: Dictionary = steps[current_step_index]
	var required = step.get("action_required", "")
	if required == null:
		required = ""
	if required == "" or required == action_type:
		_action_fulfilled = true
		if step.get("auto_advance_after", null) == null:
			advance()


func notify_moved() -> void:
	notify_action("move")


func notify_input() -> void:
	notify_action("input")


func get_highlight_nodes() -> Array:
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return []
	return steps[current_step_index].get("highlight_nodes", [])


func get_highlight_edges() -> Array:
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return []
	return steps[current_step_index].get("highlight_edges", [])


func is_game_paused() -> bool:
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return false
	if _waiting_for_action:
		return false
	return steps[current_step_index].get("pause_game", false)


func _advance_to_step(idx: int) -> void:
	if idx < 0 or idx >= steps.size():
		return

	current_step_index = idx
	_action_fulfilled = false
	_waiting_for_action = false
	_auto_advance_timer = 0.0
	_auto_advance_target = 0.0
	_show_step_index = false
	_hint_used = false
	_attempts = 0
	_hint_shown = false
	_hint_stuck_timer = 0.0

	var step: Dictionary = steps[idx]

	var ar = step.get("action_required", "")
	if ar != null and ar != "":
		_waiting_for_action = true

	if step.get("auto_advance_after", null) != null:
		_auto_advance_target = float(step["auto_advance_after"])

	_panel_alpha = 0.0
	_target_alpha = 1.0

	step_changed.emit(idx, step)
	GameLogger.info("TutorialPlayer", "Tutorial paso %d/%d: %s" % [idx + 1, steps.size(), step.get("id", "?")])


func _finish_tutorial() -> void:
	var tid: String = tutorial_data.get("id", "")
	is_active = false
	current_step_index = -1
	_target_alpha = 0.0
	_waiting_for_action = false
	_action_fulfilled = false

	if is_paused_by_tutorial:
		get_tree().paused = false
		is_paused_by_tutorial = false

	tutorial_completed.emit(tid)
	GameLogger.info("TutorialPlayer", "Tutorial completado: %s" % tid)

	await get_tree().create_timer(0.3).timeout
	visible = false


func _process(delta: float) -> void:
	if not is_active:
		return

	var vp: Vector2 = get_viewport_rect().size
	size = vp
	position = Vector2.ZERO

	_panel_alpha = move_toward(_panel_alpha, _target_alpha, delta * 5.0)

	if _auto_advance_target > 0.0:
		_auto_advance_timer += delta
		if _auto_advance_timer >= _auto_advance_target:
			advance()

	# Auto-reveal hint after being stuck
	if _waiting_for_action and not _hint_shown:
		var step_hint: String = get_hint()
		if step_hint != "":
			_hint_stuck_timer += delta
			if _hint_stuck_timer >= _hint_auto_after:
				_hint_shown = true
				_hint_used = true

	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _btn_hovered and not _waiting_for_action:
			_on_next_pressed()
			get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k: InputEventKey = event as InputEventKey
		match k.keycode:
			KEY_LEFT, KEY_BACKSPACE:
				previous()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				skip()
				get_viewport().set_input_as_handled()
			KEY_I:
				_show_step_index = not _show_step_index
				get_viewport().set_input_as_handled()
			KEY_H:
				if _waiting_for_action:
					show_hint()
					get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_SPACE:
				if not _waiting_for_action:
					_on_next_pressed()
					get_viewport().set_input_as_handled()


func _on_next_pressed() -> void:
	advance()


func _get_next_button_rect() -> Rect2:
	var vp_size: Vector2 = get_viewport_rect().size
	var btn_w: float = 130.0
	var btn_h: float = 36.0
	var margin: float = 20.0
	var btn_pos: Vector2 = Vector2(
		_panel_rect.position.x + _panel_rect.size.x - btn_w - margin,
		_panel_rect.position.y + _panel_rect.size.y + 12.0
	)
	return Rect2(btn_pos, Vector2(btn_w, btn_h))


func _draw() -> void:
	if not is_active or current_step_index < 0 or current_step_index >= steps.size():
		return
	if _panel_alpha < 0.01:
		return

	var step: Dictionary = steps[current_step_index]
	var text: String = step.get("text", "")
	var position: String = step.get("position", "center")

	_draw_floating_panel(text, position)
	_draw_next_button()
	_draw_step_indicator()
	_draw_skip_hint()
	if _hint_shown:
		_draw_hint_panel()
	if _show_step_index:
		_draw_step_index_overlay()


func _draw_floating_panel(text: String, position: String) -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var panel_w: float = min(480.0, vp_size.x - 60.0)
	var lines: PackedStringArray = text.split("\n")
	var line_h: float = 18.0
	var panel_h: float = max(80.0, lines.size() * line_h + 40.0)

	var panel_pos: Vector2
	match position:
		"top":
			panel_pos = Vector2((vp_size.x - panel_w) / 2.0, 70.0)
		"bottom":
			panel_pos = Vector2((vp_size.x - panel_w) / 2.0, vp_size.y - panel_h - 60.0)
		"left":
			panel_pos = Vector2(30.0, (vp_size.y - panel_h) / 2.0)
		"right":
			panel_pos = Vector2(vp_size.x - panel_w - 30.0, (vp_size.y - panel_h) / 2.0)
		_:
			panel_pos = Vector2((vp_size.x - panel_w) / 2.0, (vp_size.y - panel_h) / 2.0)

	_panel_rect = Rect2(panel_pos, Vector2(panel_w, panel_h))

	var bg: Color = Color(_panel_color.r, _panel_color.g, _panel_color.b, _panel_alpha * _panel_color.a)
	var border: Color = Color(_panel_border.r, _panel_border.g, _panel_border.b, _panel_alpha * _panel_border.a)

	draw_rect(_panel_rect, bg)
	draw_rect(_panel_rect, border, false, 2.0)

	var glow_corners: Array[Vector2] = [
		panel_pos,
		panel_pos + Vector2(panel_w, 0),
		panel_pos + Vector2(0, panel_h),
		panel_pos + Vector2(panel_w, panel_h)
	]
	for corner in glow_corners:
		draw_circle(corner, 3.0, Color(border.r, border.g, border.b, _panel_alpha * 0.6))

	var text_x: float = panel_pos.x + 20.0
	var text_y: float = panel_pos.y + 28.0
	var text_alpha: float = _panel_alpha

	for line in lines:
		var lcolor: Color = Color(_text_color.r, _text_color.g, _text_color.b, text_alpha)
		if line.begins_with("⚠") or line.begins_with("ALERTA"):
			lcolor = Color(_warning_color.r, _warning_color.g, _warning_color.b, text_alpha)
		draw_string(font, Vector2(text_x, text_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, lcolor)
		text_y += line_h


func _draw_next_button() -> void:
	_btn_rect = _get_next_button_rect()

	var can_advance: bool = not _waiting_for_action
	var bg: Color
	if not can_advance:
		bg = Color(0.3, 0.3, 0.3, _panel_alpha * 0.5)
	elif _btn_hovered:
		bg = Color(_btn_hover_color.r, _btn_hover_color.g, _btn_hover_color.b, _panel_alpha * 0.9)
	else:
		bg = Color(_btn_color.r, _btn_color.g, _btn_color.b, _panel_alpha * 0.8)

	var border_color: Color = Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha * (1.0 if can_advance else 0.3))

	draw_rect(_btn_rect, bg)
	draw_rect(_btn_rect, border_color, false, 2.0)

	var label: String
	if not can_advance:
		label = t("tutorial.hint_action")
	else:
		label = t("tutorial.next")
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos: Vector2 = Vector2(
		_btn_rect.position.x + (_btn_rect.size.x - text_size.x) / 2.0,
		_btn_rect.position.y + (_btn_rect.size.y + text_size.y * 0.35) / 2.0
	)
	var text_color: Color = Color.WHITE if can_advance else Color(0.7, 0.7, 0.7, 0.8)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


func _draw_step_indicator() -> void:
	if steps.is_empty():
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var total: int = steps.size()
	var dot_r: float = 5.0
	var gap: float = 16.0
	var total_w: float = total * dot_r * 2.0 + (total - 1) * gap
	var start_x: float = (vp_size.x - total_w) / 2.0
	var y: float = _panel_rect.position.y + _panel_rect.size.y + 55.0

	# Draw step title above the dots
	var current_step: Dictionary = steps[current_step_index]
	var step_title: String = current_step.get("title", current_step.get("id", ""))
	if step_title != "":
		var title_pos: Vector2 = Vector2((vp_size.x - font.get_string_size(step_title, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, y - 22.0)
		draw_string(font, title_pos, step_title, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha))

	for i in range(total):
		var cx: float = start_x + i * (dot_r * 2.0 + gap) + dot_r
		var color: Color
		if i == current_step_index:
			color = Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha)
		elif i < current_step_index:
			color = Color(0.4, 0.4, 0.4, _panel_alpha * 0.6)
		else:
			color = Color(0.3, 0.3, 0.3, _panel_alpha * 0.4)
		draw_circle(Vector2(cx, y), dot_r, color)

	var step_label: String = "%s %d %s %d: %s" % [t("tutorial.step"), current_step_index + 1, t("tutorial.of"), steps.size(), step_title]
	var label_pos: Vector2 = Vector2((vp_size.x - font.get_string_size(step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, y + 18.0)
	draw_string(font, label_pos, step_label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.6, 0.6, 0.6, _panel_alpha * 0.7))

	# Draw tutorial objective if present
	var objective: String = tutorial_data.get("objective", "")
	if objective != "":
		var obj_pos: Vector2 = Vector2((vp_size.x - font.get_string_size(objective, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, y + 34.0)
		draw_string(font, obj_pos, objective, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.5, 0.5, 0.7, _panel_alpha * 0.6))


func _draw_skip_hint() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var text: String = "[←] %s  [Enter] %s  [ESC] %s  [I] %s" % [t("tutorial.previous"), t("tutorial.next"), t("tutorial.skip"), t("tutorial.index")]
	var alpha: float = _panel_alpha * 0.5
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x
	draw_string(font, Vector2((vp_size.x - text_width) / 2.0, vp_size.y - 15.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.6, 0.6, 0.6, alpha))


func _draw_hint_panel() -> void:
	var step_hint: String = get_hint()
	if step_hint == "":
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var panel_w: float = min(440.0, vp_size.x - 80.0)
	var line_h: float = 16.0
	var margin: float = 12.0
	var hint_lines: PackedStringArray = step_hint.split("\n")
	var panel_h: float = hint_lines.size() * line_h + 32.0

	var panel_pos: Vector2 = Vector2(
		(vp_size.x - panel_w) / 2.0,
		_panel_rect.position.y + _panel_rect.size.y + 110.0
	)

	var bg: Color = Color(0.08, 0.08, 0.18, _panel_alpha * 0.9)
	var border: Color = Color(1.0, 0.84, 0.0, _panel_alpha * 0.8)
	draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), bg)
	draw_rect(Rect2(panel_pos, Vector2(panel_w, panel_h)), border, false, 1.5)

	var label: String = "💡 %s" % t("tutorial.hint_button")
	draw_string(font, Vector2(panel_pos.x + margin, panel_pos.y + line_h), label, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(1.0, 0.84, 0.0, _panel_alpha))

	for i in range(hint_lines.size()):
		draw_string(font, Vector2(panel_pos.x + margin, panel_pos.y + line_h * 2.0 + line_h * i), hint_lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.9, 0.9, 0.9, _panel_alpha))


func _draw_step_index_overlay() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var overlay_w: float = min(360.0, vp_size.x - 60.0)
	var line_h: float = 22.0
	var margin: float = 16.0
	var summary: Array = get_steps_summary()
	var overlay_h: float = summary.size() * line_h + 48.0

	var overlay_pos: Vector2 = Vector2(
		(vp_size.x - overlay_w) / 2.0,
		(vp_size.y - overlay_h) / 2.0
	)

	var bg: Color = Color(0.05, 0.05, 0.12, 0.95)
	var border: Color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.9)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), bg)
	draw_rect(Rect2(overlay_pos, Vector2(overlay_w, overlay_h)), border, false, 2.0)

	var title: String = "📋 %s" % t("tutorial.index")
	draw_string(font, Vector2(overlay_pos.x + margin, overlay_pos.y + 16.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha))

	for i in range(summary.size()):
		var item: Dictionary = summary[i]
		var is_current: bool = (i == current_step_index)
		var color: Color
		if is_current:
			color = Color(_accent_color.r, _accent_color.g, _accent_color.b, _panel_alpha)
		else:
			color = Color(0.6, 0.6, 0.6, _panel_alpha * 0.8)
		var prefix: String = "→ " if is_current else "  "
		var step_text: String = "%s%d. %s" % [prefix, i + 1, item.get("title", "")]
		draw_string(font, Vector2(overlay_pos.x + margin, overlay_pos.y + 38.0 + i * line_h), step_text, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, color)

	var close_hint: String = "[I] %s" % t("tutorial.index")
	draw_string(font, Vector2(overlay_pos.x + (overlay_w - font.get_string_size(close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size).x) / 2.0, overlay_pos.y + overlay_h - 10.0), close_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color(0.5, 0.5, 0.5, _panel_alpha * 0.7))
