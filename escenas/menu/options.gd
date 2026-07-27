extends Control

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

const CYAN: Color = Color(0.0, 1.0, 0.83)
const GRIS: Color = Color(0.5, 0.55, 0.65)
const GRIS_OSCURO: Color = Color(0.3, 0.33, 0.4)
const GRIS_FONDO: Color = Color(0.12, 0.14, 0.18)
const VERDE: Color = Color(0.0, 0.8, 0.4)
const ROJO: Color = Color(0.9, 0.2, 0.2)
const BLANCO: Color = Color.WHITE

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


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	_load_settings()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_save_settings()
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
			KEY_UP:
				_item_idx = maxi(0, _item_idx - 1)
				queue_redraw()
			KEY_DOWN:
				var section: Dictionary = _sections[_section_idx]
				_item_idx = mini(section.items.size() - 1, _item_idx + 1)
				queue_redraw()
			KEY_LEFT:
				_adjust_value(-1)
				queue_redraw()
			KEY_RIGHT:
				_adjust_value(1)
				queue_redraw()
			KEY_TAB:
				_next_section()
				queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()


func _next_section() -> void:
	_section_idx = (_section_idx + 1) % _sections.size()
	_item_idx = 0


func current_section() -> Dictionary:
	return _sections[_section_idx]


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


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	for section in _sections:
		for item in section.items:
			cfg.set_value("options", item.id, item.value)
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
		# Apply loaded settings
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
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.06, 0.06, 0.1))

	# Title
	draw_string(font, Vector2(60, 60), loc("menu.options"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, CYAN)

	# Section tabs (horizontal)
	var tab_x: float = 80.0
	for i in _sections.size():
		var sec: Dictionary = _sections[i]
		var label: String = loc(sec.label)
		var is_sel: bool = i == _section_idx
		var color: Color = CYAN if is_sel else GRIS
		var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4).x
		draw_string(font, Vector2(tab_x, 100), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, color)
		if is_sel:
			draw_rect(Rect2(tab_x, 105, tw, 2), CYAN)
		tab_x += tw + 30

	# Items of current section
	var section: Dictionary = _sections[_section_idx]
	var by: float = 150.0
	for i in section.items.size():
		var item: Dictionary = section.items[i]
		var is_sel: bool = i == _item_idx

		# Label
		var label_color: Color = CYAN if is_sel else GRIS
		draw_string(font, Vector2(80, by), loc(item.label), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, label_color)

		# Value
		match item.type:
			"slider":
				_draw_slider(Vector2(320, by - 10), item)
			"toggle":
				_draw_toggle(Vector2(320, by), item)
			"cycle":
				_draw_cycle(Vector2(320, by), item)
		by += 40

	# Hint
	by += 20
	draw_string(font, Vector2(60, by), loc("options.hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.35, 0.38, 0.45))
	by += 20
	draw_string(font, Vector2(60, by), loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.35, 0.38, 0.45))


func _draw_slider(pos: Vector2, item: Dictionary) -> void:
	var bar_w: float = 150.0
	var fill: float = (item.value - item.min) / float(item.max - item.min)
	# Background bar
	draw_rect(Rect2(pos.x, pos.y, bar_w, 10), GRIS_FONDO)
	# Fill bar
	draw_rect(Rect2(pos.x, pos.y, bar_w * fill, 10), CYAN)
	# Border
	draw_rect(Rect2(pos.x, pos.y, bar_w, 10), GRIS_OSCURO, false, 1.0)
	# Value text
	draw_string(font, Vector2(pos.x + bar_w + 12, pos.y + 10), str(item.value), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BLANCO)


func _draw_toggle(pos: Vector2, item: Dictionary) -> void:
	var text: String = loc("options.on") if item.value else loc("options.off")
	var color: Color = VERDE if item.value else ROJO
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, color)


func _draw_cycle(pos: Vector2, item: Dictionary) -> void:
	var text: String = "< %s >" % item.options[item.value]
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, CYAN)
