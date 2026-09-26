extends Control

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

const BrandClass = preload("res://juego/ui/brand.gd")

const CYAN: Color = BrandClass.ACCENT
const GRIS: Color = BrandClass.TEXT_DIM
const GRIS_OSCURO: Color = BrandClass.PANEL_BORDER
const GRIS_FONDO: Color = BrandClass.PANEL_SOLID
const VERDE: Color = BrandClass.SUCCESS
const ROJO: Color = BrandClass.DANGER
const BLANCO: Color = BrandClass.TEXT

var _sections: Array[Dictionary] = [
	{
		"id": "audio",
		"label": "AUDIO",
		"items": [
			{"id": "volume_master", "label": "options.volume_master", "type": "slider", "min": 0, "max": 100, "value": 80},
			{"id": "volume_music", "label": "options.volume_music", "type": "slider", "min": 0, "max": 100, "value": 60},
			{"id": "volume_sfx", "label": "options.volume_sfx", "type": "slider", "min": 0, "max": 100, "value": 70},
		]
	},
	{
		"id": "graphics",
		"label": "options.section_graphics",
		"items": [
			{"id": "fullscreen", "label": "options.fullscreen", "type": "toggle", "value": true},
			{"id": "vsync", "label": "options.vsync", "type": "toggle", "value": true},
		]
	},
	{
		"id": "controls",
		"label": "options.section_controls",
		"items": [
			{"id": "show_hints", "label": "options.show_hints", "type": "toggle", "value": true},
		]
	},
	{
		"id": "language",
		"label": "options.section_language",
		"items": [
			{"id": "lang", "label": "options.language_label", "type": "cycle", "options": ["ES", "EN", "PT"], "value": 0},
		]
	},
]

var _section_idx: int = 0
var _item_idx: int = 0

# Mouse & animation state
var _tab_rects: Array[Rect2] = []
var _tab_indicator_x: float = 60.0
var _tab_indicator_w: float = 60.0
var _hovered_tab: int = -1
var _hovered_back: bool = false
var _is_dragging_slider: bool = false
var _dragging_item: Dictionary = {}
var _back_btn_rect: Rect2 = Rect2()


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	_load_settings()
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()
	_recalculate_tab_rects()
	queue_redraw()


func _recalculate_tab_rects() -> void:
	_tab_rects.clear()
	var tab_x: float = 60.0
	for i in _sections.size():
		var sec: Dictionary = _sections[i]
		var label: String = loc(sec.label)
		var tw: float = 80.0
		if font != null:
			tw = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
		var tab_rect := Rect2(tab_x - 10, 80, tw + 20, 32)
		_tab_rects.append(tab_rect)
		tab_x += tw + 34.0


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_save_settings()
				_play_click_sfx()
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
			KEY_UP:
				_item_idx = maxi(0, _item_idx - 1)
				_play_click_sfx()
				queue_redraw()
			KEY_DOWN:
				var section: Dictionary = _sections[_section_idx]
				_item_idx = mini(section.items.size() - 1, _item_idx + 1)
				_play_click_sfx()
				queue_redraw()
			KEY_LEFT:
				_adjust_value(-1)
				_play_click_sfx()
				queue_redraw()
			KEY_RIGHT:
				_adjust_value(1)
				_play_click_sfx()
				queue_redraw()
			KEY_TAB:
				_next_section()
				_play_click_sfx()
				queue_redraw()

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var prev_tab := _hovered_tab
		var prev_back := _hovered_back
		_hovered_tab = -1
		_hovered_back = _back_btn_rect.has_point(mpos)

		for i in _tab_rects.size():
			if _tab_rects[i].has_point(mpos):
				_hovered_tab = i
				break

		# Dragging slider
		if _is_dragging_slider and not _dragging_item.is_empty():
			_update_slider_from_mouse(_dragging_item, mpos.x)
			queue_redraw()
			return

		# Item hover
		var section: Dictionary = _sections[_section_idx]
		var by: float = 160.0
		var vp := get_viewport_rect().size
		for i in section.items.size():
			var row_rect := Rect2(60, by - 16, vp.x - 120, 38)
			if row_rect.has_point(mpos):
				if _item_idx != i:
					_item_idx = i
					queue_redraw()
				break
			by += 44.0

		if prev_tab != _hovered_tab or prev_back != _hovered_back:
			queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos := (event as InputEventMouseButton).position
		if event.pressed:
			# Back button clicked
			if _back_btn_rect.has_point(mpos):
				_save_settings()
				_play_click_sfx()
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
				return

			# Tab clicked
			for i in _tab_rects.size():
				if _tab_rects[i].has_point(mpos):
					_section_idx = i
					_item_idx = 0
					_play_click_sfx()
					queue_redraw()
					return

			# Controls inside current section
			var section: Dictionary = _sections[_section_idx]
			var by: float = 160.0
			for i in section.items.size():
				var item: Dictionary = section.items[i]
				match item.type:
					"slider":
						var bar_rect := Rect2(320, by - 12, 180, 20)
						if bar_rect.has_point(mpos) or Rect2(60, by - 14, 460, 28).has_point(mpos):
							_item_idx = i
							_is_dragging_slider = true
							_dragging_item = item
							_update_slider_from_mouse(item, mpos.x)
							_play_click_sfx()
							queue_redraw()
							return
					"toggle":
						var toggle_rect := Rect2(320, by - 12, 60, 24)
						if toggle_rect.has_point(mpos) or Rect2(60, by - 14, 340, 28).has_point(mpos):
							_item_idx = i
							item.value = not item.value
							_apply_graphics(item.id, item.value)
							_play_click_sfx()
							queue_redraw()
							return
					"cycle":
						var prev_rect := Rect2(320, by - 12, 30, 24)
						var text_rect := Rect2(354, by - 12, 54, 24)
						var next_rect := Rect2(412, by - 12, 30, 24)
						if prev_rect.has_point(mpos):
							_item_idx = i
							_adjust_value(-1)
							_play_click_sfx()
							return
						elif next_rect.has_point(mpos) or text_rect.has_point(mpos):
							_item_idx = i
							_adjust_value(1)
							_play_click_sfx()
							return
				by += 44.0
		else:
			# Release drag
			if _is_dragging_slider:
				_is_dragging_slider = false
				_dragging_item = {}


func _process(delta: float) -> void:
	_pulse += delta * 2.0

	# Smoothly glide tab indicator
	if _section_idx < _tab_rects.size():
		var target_rect: Rect2 = _tab_rects[_section_idx]
		_tab_indicator_x = lerpf(_tab_indicator_x, target_rect.position.x, delta * 16.0)
		_tab_indicator_w = lerpf(_tab_indicator_w, target_rect.size.x, delta * 16.0)

	queue_redraw()


func _next_section() -> void:
	_section_idx = (_section_idx + 1) % _sections.size()
	_item_idx = 0


func current_section() -> Dictionary:
	return _sections[_section_idx]


func _update_slider_from_mouse(item: Dictionary, mouse_x: float) -> void:
	var bar_x: float = 320.0
	var bar_w: float = 180.0
	var frac := clampf((mouse_x - bar_x) / bar_w, 0.0, 1.0)
	var new_val := roundi(item.min + frac * (item.max - item.min))
	if new_val != item.value:
		item.value = new_val
		_apply_audio(item.id, item.value)


func _adjust_value(dir: int) -> void:
	var section: Dictionary = _sections[_section_idx]
	if _item_idx < 0 or _item_idx >= section.items.size():
		return
	var item: Dictionary = section.items[_item_idx]
	match item.type:
		"slider":
			item.value = clampi(item.value + dir * 10, item.min, item.max)
			_apply_audio(item.id, item.value)
		"toggle":
			item.value = not item.value
			_apply_graphics(item.id, item.value)
		"cycle":
			item.value = (item.value + dir) % item.options.size()
			if item.value < 0:
				item.value = item.options.size() - 1
			_apply_language(item.value)
	queue_redraw()


func _apply_audio(id: String, value: int) -> void:
	var volume_db: float = linear_to_db(value / 100.0)
	match id:
		"volume_master":
			AudioServer.set_bus_volume_db(0, volume_db)
		"volume_music":
			if AudioServer.bus_count > 1:
				AudioServer.set_bus_volume_db(1, volume_db)
		"volume_sfx":
			if AudioServer.bus_count > 2:
				AudioServer.set_bus_volume_db(2, volume_db)


func _apply_graphics(id: String, value: bool) -> void:
	match id:
		"fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"vsync":
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)


func _apply_language(idx: int) -> void:
	var _langs: Array[String] = ["es", "en", "pt"]
	var lang: String = _langs[idx]
	LocUtil.set_locale(self, lang)


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	for section in _sections:
		for item in section.items:
			cfg.set_value("options", item.id, item.value)
			if item.id == "lang" and item.value is int:
				var _langs: Array[String] = ["es", "en", "pt"]
				if item.value >= 0 and item.value < _langs.size():
					cfg.set_value("locale", "lang", _langs[item.value])
	cfg.save("user://settings.cfg")


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		for section in _sections:
			for item in section.items:
				if cfg.has_section_key("options", item.id):
					var saved_val = cfg.get_value("options", item.id, item.value)
					if typeof(saved_val) == typeof(item.value):
						item.value = saved_val
		for section in _sections:
			for item in section.items:
				match item.type:
					"slider":
						_apply_audio(item.id, item.value)
					"toggle":
						_apply_graphics(item.id, item.value)
					"cycle":
						_apply_language(item.value)


func loc(key: String) -> String:
	return LocUtil.loc(self, key)


func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp.x, vp.y), BrandClass.BG)

	# Grid background
	var grid_color: Color = BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.20)
	var spacing: float = 60.0
	var x: float = 0.0
	while x < vp.x:
		draw_line(Vector2(x, 0), Vector2(x, vp.y), grid_color, 1.0)
		x += spacing
	var gy: float = 0.0
	while gy < vp.y:
		draw_line(Vector2(0, gy), Vector2(vp.x, gy), grid_color, 1.0)
		gy += spacing

	# Header Title
	var glow: float = 0.7 + sin(_pulse * 1.5) * 0.3
	draw_string(font, Vector2(62, 52), loc("menu.options"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, BrandClass.accent_dim(0.3))
	draw_string(font, Vector2(60, 50), loc("menu.options"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, BrandClass.with_alpha(CYAN, glow))

	# Section tabs
	_tab_rects.clear()
	var tab_x: float = 60.0
	for i in _sections.size():
		var sec: Dictionary = _sections[i]
		var label: String = loc(sec.label)
		var is_sel: bool = i == _section_idx
		var is_hover: bool = i == _hovered_tab
		var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
		var tab_rect := Rect2(tab_x - 10, 80, tw + 20, 32)
		_tab_rects.append(tab_rect)

		if is_hover and not is_sel:
			draw_rect(tab_rect, BrandClass.with_alpha(CYAN, 0.08))
		elif is_sel:
			draw_rect(tab_rect, BrandClass.with_alpha(CYAN, 0.12))

		var label_color: Color = CYAN if is_sel else (BLANCO if is_hover else GRIS)
		draw_string(font, Vector2(tab_x, 102), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, label_color)
		tab_x += tw + 34.0

	# Smooth animated tab indicator line
	draw_rect(Rect2(_tab_indicator_x, 114, _tab_indicator_w, 2.5), CYAN)
	draw_rect(Rect2(_tab_indicator_x, 113, _tab_indicator_w, 4.0), BrandClass.with_alpha(CYAN, 0.25))

	# Items of current section
	var section: Dictionary = _sections[_section_idx]
	var by: float = 160.0
	for i in section.items.size():
		var item: Dictionary = section.items[i]
		var is_sel: bool = i == _item_idx
		var row_rect := Rect2(60, by - 16, vp.x - 120, 36)

		# Row selection highlight
		if is_sel:
			draw_rect(row_rect, BrandClass.with_alpha(CYAN, 0.08))
			draw_rect(Rect2(60, by - 16, 3, 36), CYAN)

		# Label
		var label_color: Color = CYAN if is_sel else GRIS
		draw_string(font, Vector2(76, by + 8), loc(item.label), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, label_color)

		# Value Control
		match item.type:
			"slider":
				_draw_slider(Vector2(320, by - 6), item, is_sel)
			"toggle":
				_draw_toggle(Vector2(320, by - 10), item, is_sel)
			"cycle":
				_draw_cycle(Vector2(320, by - 10), item, is_sel)

		by += 44.0

	# Bottom Back Button
	_back_btn_rect = Rect2(60, vp.y - 65, 170, 36)
	var back_bg := BrandClass.with_alpha(CYAN, 0.15 if _hovered_back else 0.05)
	var back_border := CYAN if _hovered_back else GRIS_OSCURO
	var back_text_color := CYAN if _hovered_back else GRIS
	draw_rect(_back_btn_rect, back_bg)
	draw_rect(_back_btn_rect, back_border, false, 1.5 if _hovered_back else 1.0)
	draw_string(font, Vector2(74, vp.y - 42), "← " + loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, back_text_color)

	# Keyboard hints
	draw_string(font, Vector2(250, vp.y - 42), loc("options.hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.35, 0.38, 0.45))


func _draw_slider(pos: Vector2, item: Dictionary, is_sel: bool) -> void:
	var bar_w: float = 180.0
	var bar_h: float = 12.0
	var fill: float = (item.value - item.min) / float(item.max - item.min)

	# Background track
	draw_rect(Rect2(pos.x, pos.y, bar_w, bar_h), GRIS_FONDO)
	draw_rect(Rect2(pos.x, pos.y, bar_w, bar_h), GRIS_OSCURO, false, 1.0)

	# Filled track
	var fill_color := CYAN if is_sel else BrandClass.accent_dim(0.7)
	draw_rect(Rect2(pos.x, pos.y, bar_w * fill, bar_h), fill_color)

	# Thumb knob
	var knob_x := pos.x + bar_w * fill
	var knob_y := pos.y + bar_h * 0.5
	draw_circle(Vector2(knob_x, knob_y), 6.5, fill_color)
	draw_circle(Vector2(knob_x, knob_y), 3.0, BrandClass.BG)

	# Value text
	draw_string(font, Vector2(pos.x + bar_w + 16, pos.y + 10), "%d%%" % item.value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BLANCO)


func _draw_toggle(pos: Vector2, item: Dictionary, _is_sel: bool) -> void:
	var sw_w: float = 58.0
	var sw_h: float = 24.0
	var is_on: bool = bool(item.value)
	var bg_col := BrandClass.with_alpha(VERDE, 0.20) if is_on else BrandClass.with_alpha(GRIS_OSCURO, 0.40)
	var border_col := VERDE if is_on else GRIS_OSCURO

	draw_rect(Rect2(pos.x, pos.y, sw_w, sw_h), bg_col)
	draw_rect(Rect2(pos.x, pos.y, sw_w, sw_h), border_col, false, 1.0)

	var knob_x := pos.x + (sw_w - 18.0) if is_on else pos.x + 4.0
	var knob_col := VERDE if is_on else GRIS
	draw_rect(Rect2(knob_x, pos.y + 4, 14, 16), knob_col)

	var status_text := loc("options.on") if is_on else loc("options.off")
	draw_string(font, Vector2(pos.x + sw_w + 14, pos.y + 17), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, knob_col)


func _draw_cycle(pos: Vector2, item: Dictionary, is_sel: bool) -> void:
	var btn_w: float = 28.0
	var btn_h: float = 24.0
	var btn_bg := BrandClass.with_alpha(CYAN, 0.12 if is_sel else 0.05)
	var border_col := CYAN if is_sel else GRIS_OSCURO

	# Left button [<]
	draw_rect(Rect2(pos.x, pos.y, btn_w, btn_h), btn_bg)
	draw_rect(Rect2(pos.x, pos.y, btn_w, btn_h), border_col, false, 1.0)
	draw_string(font, Vector2(pos.x + 9, pos.y + 17), "<", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CYAN)

	# Center text
	var current_opt: String = item.options[item.value]
	var text_rect := Rect2(pos.x + 34, pos.y, 50, btn_h)
	draw_rect(text_rect, BrandClass.PANEL_SOLID)
	draw_rect(text_rect, border_col, false, 1.0)
	draw_string(font, Vector2(pos.x + 49, pos.y + 17), current_opt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 1, BLANCO)

	# Right button [>]
	var next_x := pos.x + 90
	draw_rect(Rect2(next_x, pos.y, btn_w, btn_h), btn_bg)
	draw_rect(Rect2(next_x, pos.y, btn_w, btn_h), border_col, false, 1.0)
	draw_string(font, Vector2(next_x + 10, pos.y + 17), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, CYAN)
