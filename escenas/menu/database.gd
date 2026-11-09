extends Control

## Database Controller
## Manages state machine, input routing, audio cues, and transitions for the Tactical Codex.
## Extends the tactical codex with a 4th tab: ARCHIVOS / CINEMÁTICAS, allowing operators to
## review all narrative transmissions directly inside the database.

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
const DatabaseRendererClass = preload("res://escenas/menu/database_renderer.gd")
const CinematicOverlayClass = preload("res://juego/ui/cinematic_overlay.gd")
const CinematicRegistryClass = preload("res://juego/system/cinematic_registry.gd")

enum Tab {
	CONCEPTOS = 0,
	SISTEMAS = 1,
	ARCHIVOS = 2,
	CINEMATICS = 3,
}

const TABS: Array[Dictionary] = [
	{
		"id": "conceptos",
		"title": "CONCEPTOS",
		"color": Color("00e5ff"),
		"tag": "ALGORITMOS & FUNDAMENTOS"
	},
	{
		"id": "sistemas",
		"title": "SISTEMAS",
		"color": Color("ffc857"),
		"tag": "COMPONENTES DEFENSIVOS"
	},
	{
		"id": "archivos",
		"title": "ARCHIVOS",
		"color": Color("39ff88"),
		"tag": "DOCUMENTACIÓN & PEDAGOGÍA"
	},
	{
		"id": "cinematicas",
		"title": "CINEMÁTICAS",
		"color": Color("bf5af2"),
		"tag": "HISTORIA & TRANSMISIONES"
	},
]

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var small_font_size: int = 12
var _pulse: float = 0.0

var _cyber_bg := CyberBackgroundClass.new()
var _renderer := DatabaseRendererClass.new()
var _cinematic_overlay: Control

var _active_cat_idx: int = 0
var _selected_entry_idx: int = 0
var _scroll_y: float = 0.0

var _hovered_back: bool = false
var _hovered_cat_idx: int = -1
var _hovered_entry_idx: int = -1
var _hovered_play_btn: bool = false

# Backward-compatibility / semantic aliases
var _category_idx: int:
	get: return _active_cat_idx
	set(val): _active_cat_idx = val

var _entry_idx: int:
	get: return _selected_entry_idx
	set(val): _selected_entry_idx = val

var _hovered_category_idx: int:
	get: return _hovered_cat_idx
	set(val): _hovered_cat_idx = val


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	small_font_size = maxi(10, font_size - 3)
	_cyber_bg.show_hologram = false

	_cinematic_overlay = CinematicOverlayClass.new()
	add_child(_cinematic_overlay)
	_cinematic_overlay.cinematic_finished.connect(_on_cinematic_finished)

	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()
	queue_redraw()


func _on_cinematic_finished(_cin_id: String) -> void:
	queue_redraw()


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


func _get_total_categories() -> int:
	return TABS.size()


func _get_entry_count(cat_idx: int) -> int:
	if cat_idx == Tab.CINEMATICS:
		return CinematicRegistryClass.get_all().size()
	return DatabaseRendererClass.get_entry_count(cat_idx)


func _get_entries(cat_idx: int) -> Array:
	if cat_idx == Tab.CINEMATICS:
		return CinematicRegistryClass.get_all()
	return DatabaseRendererClass.get_entries_for_category(cat_idx)


func _set_active_category(idx: int) -> void:
	var total_cats := _get_total_categories()
	if total_cats == 0:
		return
	var new_cat := clampi(idx, 0, total_cats - 1)
	if _active_cat_idx != new_cat:
		_active_cat_idx = new_cat
		_selected_entry_idx = 0
		_scroll_y = 0.0
		_play_click_sfx()
		queue_redraw()


func _select_entry(idx: int) -> void:
	var total_entries := _get_entry_count(_active_cat_idx)
	if total_entries == 0:
		return
	var new_idx := clampi(idx, 0, total_entries - 1)
	if _selected_entry_idx != new_idx:
		_selected_entry_idx = new_idx
		_scroll_y = 0.0
		_play_click_sfx()
		queue_redraw()


func _scroll_by(amount: float) -> void:
	var max_s: float = _get_max_scroll()
	var prev_s := _scroll_y
	_scroll_y = clampf(_scroll_y + amount, 0.0, max_s)
	if not is_equal_approx(_scroll_y, prev_s):
		queue_redraw()


func _get_max_scroll() -> float:
	var vp := get_viewport_rect().size
	var right_rect := _renderer.get_right_panel_rect(vp)
	var viewport_h := _renderer.get_dossier_viewport_height(right_rect)

	if _active_cat_idx == Tab.CINEMATICS:
		var entries := CinematicRegistryClass.get_all()
		if _selected_entry_idx < 0 or _selected_entry_idx >= entries.size():
			return 0.0
		var cin: Dictionary = entries[_selected_entry_idx]
		var desc: String = cin.get("description", "")
		var lines := DatabaseRendererClass.wrap_text(desc, font, font_size, right_rect.size.x - 48.0)
		var total_h := 360.0 + float(lines.size()) * 22.0
		return maxf(0.0, total_h - viewport_h)

	var entries := DatabaseRendererClass.get_entries_for_category(_active_cat_idx)
	if _selected_entry_idx < 0 or _selected_entry_idx >= entries.size():
		return 0.0
	var entry: Dictionary = entries[_selected_entry_idx]
	var content_w := right_rect.size.x - 48.0
	var total_h := DatabaseRendererClass.compute_dossier_height(entry, font, font_size, content_w)
	return maxf(0.0, total_h - viewport_h)


func _play_selected_cinematic() -> void:
	var entries := CinematicRegistryClass.get_all()
	if _selected_entry_idx >= 0 and _selected_entry_idx < entries.size() and _cinematic_overlay:
		var cin: Dictionary = entries[_selected_entry_idx]
		_play_click_sfx()
		_cinematic_overlay.play_cinematic_data(cin)


func _back_to_menu() -> void:
	_play_click_sfx()
	var vp := get_viewport_rect().size
	var back_pos := Vector2(130.0, vp.y - 32.0)
	var st = get_node_or_null("/root/SceneTransition")
	if st != null and st.has_method("dive_out_to_scene"):
		st.dive_out_to_scene("res://escenas/main_menu.tscn", back_pos)
	elif st != null and st.has_method("fade_to_scene"):
		st.fade_to_scene("res://escenas/main_menu.tscn")
	elif get_tree() != null:
		get_tree().change_scene_to_file("res://escenas/main_menu.tscn")


func get_tab_rect(cat_idx: int, vp: Vector2) -> Rect2:
	var lp := _renderer.get_left_panel_rect(vp)
	var tab_gap := 4.0
	var total_tabs := float(TABS.size())
	var tab_w := (lp.size.x - 28.0 - ((total_tabs - 1.0) * tab_gap)) / total_tabs
	var tab_x := lp.position.x + 14.0 + float(cat_idx) * (tab_w + tab_gap)
	var tab_y := lp.position.y + 44.0
	return Rect2(tab_x, tab_y, tab_w, 32.0)


func get_cinematic_row_rect(entry_idx: int, vp: Vector2) -> Rect2:
	var lp := _renderer.get_left_panel_rect(vp)
	var row_y := lp.position.y + 88.0 + float(entry_idx) * 54.0
	return Rect2(lp.position.x + 14.0, row_y, lp.size.x - 28.0, 48.0)


func get_play_button_rect(vp: Vector2) -> Rect2:
	var rp := _renderer.get_right_panel_rect(vp)
	var btn_w := 260.0
	var btn_h := 44.0
	return Rect2(rp.position.x + 24.0, rp.position.y + rp.size.y - btn_h - 24.0, btn_w, btn_h)


func _input(event: InputEvent) -> void:
	if _cinematic_overlay and _cinematic_overlay.is_playing():
		return

	var vp := get_viewport_rect().size
	var total_cats := _get_total_categories()

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_back_to_menu()
			KEY_TAB, KEY_D, KEY_RIGHT:
				_set_active_category((_active_cat_idx + 1) % total_cats)
			KEY_A, KEY_LEFT:
				_set_active_category((_active_cat_idx - 1 + total_cats) % total_cats)
			KEY_W, KEY_UP:
				_select_entry(_selected_entry_idx - 1)
			KEY_S, KEY_DOWN:
				_select_entry(_selected_entry_idx + 1)
			KEY_ENTER, KEY_SPACE:
				if _active_cat_idx == Tab.CINEMATICS:
					_play_selected_cinematic()
			KEY_PAGEUP:
				_scroll_by(-120.0)
			KEY_PAGEDOWN:
				_scroll_by(120.0)

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var prev_b := _hovered_back
		_hovered_back = _renderer.get_back_button_rect(vp).has_point(mpos)

		var prev_c := _hovered_cat_idx
		_hovered_cat_idx = -1
		for i in range(total_cats):
			if get_tab_rect(i, vp).has_point(mpos) or (i < 3 and _renderer.get_category_tab_rect(i, vp).has_point(mpos)):
				_hovered_cat_idx = i
				break

		var prev_e := _hovered_entry_idx
		_hovered_entry_idx = -1
		var num_entries := _get_entry_count(_active_cat_idx)
		for i in range(num_entries):
			var r: Rect2
			if _active_cat_idx == Tab.CINEMATICS:
				r = get_cinematic_row_rect(i, vp)
			else:
				r = _renderer.get_entry_row_rect(i, vp)
			if r.has_point(mpos):
				_hovered_entry_idx = i
				break

		var prev_play := _hovered_play_btn
		_hovered_play_btn = (_active_cat_idx == Tab.CINEMATICS and get_play_button_rect(vp).has_point(mpos))

		if prev_b != _hovered_back or prev_c != _hovered_cat_idx or prev_e != _hovered_entry_idx or prev_play != _hovered_play_btn:
			queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		var mpos := mb.position
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_scroll_by(-40.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				_scroll_by(40.0)
			MOUSE_BUTTON_LEFT:
				if _renderer.get_back_button_rect(vp).has_point(mpos):
					_back_to_menu()
					return

				for i in range(total_cats):
					if get_tab_rect(i, vp).has_point(mpos) or (i < 3 and _renderer.get_category_tab_rect(i, vp).has_point(mpos)):
						_set_active_category(i)
						return

				var num_entries := _get_entry_count(_active_cat_idx)
				for i in range(num_entries):
					var r: Rect2
					if _active_cat_idx == Tab.CINEMATICS:
						r = get_cinematic_row_rect(i, vp)
					else:
						r = _renderer.get_entry_row_rect(i, vp)
					if r.has_point(mpos):
						_select_entry(i)
						return

				if _active_cat_idx == Tab.CINEMATICS:
					if get_play_button_rect(vp).has_point(mpos):
						_play_selected_cinematic()
						return


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	_cyber_bg.update(delta, get_viewport_rect().size)
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	_cyber_bg.draw(self, vp)

	if _active_cat_idx < Tab.CINEMATICS:
		# Renderizar categorías del codex táctico (0..2)
		_renderer.draw(
			self,
			vp,
			font,
			font_size,
			big_font_size,
			_pulse,
			_active_cat_idx,
			_selected_entry_idx,
			_scroll_y,
			_hovered_back,
			_hovered_cat_idx,
			_hovered_entry_idx
		)
		# Sobredibujar las 4 pestañas para incluir de forma armónica la 4ª pestaña
		_draw_all_tabs(vp)
	else:
		# Renderizar la 4ª pestaña dedicada: Archivos y Cinemáticas
		_draw_cinematics_screen(vp)


func _draw_all_tabs(vp: Vector2) -> void:
	var lp := _renderer.get_left_panel_rect(vp)
	# Limpiar la barra de pestañas sobreescribiendo el fondo
	draw_rect(Rect2(lp.position.x + 10.0, lp.position.y + 42.0, lp.size.x - 20.0, 36.0), BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.98))

	for i in range(TABS.size()):
		var tab_data: Dictionary = TABS[i]
		var tab_rect := get_tab_rect(i, vp)
		var is_active := (i == _active_cat_idx)
		var is_hover := (i == _hovered_cat_idx)
		var col: Color = tab_data["color"]

		if is_active:
			draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
			draw_rect(tab_rect, BrandClass.with_alpha(col, 0.85), false, 1.4)
			draw_rect(Rect2(tab_rect.position.x, tab_rect.position.y + tab_rect.size.y - 2.5, tab_rect.size.x, 2.5), col)
			draw_string(font, Vector2(tab_rect.position.x + 6.0, tab_rect.position.y + 21.0), tab_data["title"], HORIZONTAL_ALIGNMENT_LEFT, tab_rect.size.x - 10.0, small_font_size - 1, col)
		elif is_hover:
			draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
			draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.45), false, 1.0)
			draw_string(font, Vector2(tab_rect.position.x + 6.0, tab_rect.position.y + 21.0), tab_data["title"], HORIZONTAL_ALIGNMENT_LEFT, tab_rect.size.x - 10.0, small_font_size - 1, BrandClass.TEXT)
		else:
			draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.50))
			draw_rect(tab_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.30), false, 1.0)
			draw_string(font, Vector2(tab_rect.position.x + 6.0, tab_rect.position.y + 21.0), tab_data["title"], HORIZONTAL_ALIGNMENT_LEFT, tab_rect.size.x - 10.0, small_font_size - 1, BrandClass.TEXT_DIM)


func _draw_cinematics_screen(vp: Vector2) -> void:
	var lp := _renderer.get_left_panel_rect(vp)
	var rp := _renderer.get_right_panel_rect(vp)

	# Encabezado principal de la base de datos
	draw_string(font, Vector2(40.0, 48.0), "BASE DE DATOS TÁCTICA // REGISTRO CLASIFICADO", HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, BrandClass.ACCENT)
	draw_string(font, Vector2(40.0, 72.0), "HISTORIAL DE MISIONES, TRANSMISIONES Y DOCTRINA DE CIBERSEGURIDAD", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)

	# 1. Panel Izquierdo: Lista de Cinemáticas
	draw_rect(lp, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.85))
	draw_rect(lp, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.60), false, 1.0)

	var h_rect := Rect2(lp.position.x, lp.position.y, lp.size.x, 34.0)
	draw_rect(h_rect, BrandClass.with_alpha(Color("bf5af2"), 0.15))
	draw_line(Vector2(lp.position.x, lp.position.y + 34.0), Vector2(lp.position.x + lp.size.x, lp.position.y + 34.0), BrandClass.with_alpha(Color("bf5af2"), 0.40), 1.0)
	draw_string(font, Vector2(lp.position.x + 14.0, lp.position.y + 23.0), "[ARCHIVOS // TRANSMISIONES]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, Color("bf5af2"))

	# Pestañas
	_draw_all_tabs(vp)

	# Filas de cinemáticas
	var cinematics := CinematicRegistryClass.get_all()
	for i in range(cinematics.size()):
		var cin: Dictionary = cinematics[i]
		var row_rect := get_cinematic_row_rect(i, vp)
		var is_sel := (i == _selected_entry_idx)
		var is_hov := (i == _hovered_entry_idx)
		var op_id: String = cin.get("operator", "ZERO")
		var op_info := CinematicRegistryClass.get_operator(op_id)
		var op_col: Color = op_info.get("color", BrandClass.ACCENT)

		if is_sel:
			draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.96))
			draw_rect(row_rect, BrandClass.with_alpha(op_col, 0.85), false, 1.4)
			draw_rect(Rect2(row_rect.position.x, row_rect.position.y, 4.0, row_rect.size.y), op_col)
			draw_string(font, Vector2(row_rect.position.x + 12.0, row_rect.position.y + 20.0), "[%s]" % op_id, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, op_col)
			draw_string(font, Vector2(row_rect.position.x + 75.0, row_rect.position.y + 20.0), cin.get("title", ""), HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 85.0, font_size - 1, BrandClass.TEXT)
			var sub := "ACTO %d // %s DIAPOSITIVAS" % [cin.get("act", 1), cin.get("slides", []).size()]
			draw_string(font, Vector2(row_rect.position.x + 12.0, row_rect.position.y + 38.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, BrandClass.TEXT_DIM)
		elif is_hov:
			draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.80))
			draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.60), false, 1.0)
			draw_string(font, Vector2(row_rect.position.x + 12.0, row_rect.position.y + 20.0), "[%s]" % op_id, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, op_col)
			draw_string(font, Vector2(row_rect.position.x + 75.0, row_rect.position.y + 20.0), cin.get("title", ""), HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 85.0, font_size - 1, BrandClass.TEXT)
			var sub := "ACTO %d // %s DIAPOSITIVAS" % [cin.get("act", 1), cin.get("slides", []).size()]
			draw_string(font, Vector2(row_rect.position.x + 12.0, row_rect.position.y + 38.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, BrandClass.TEXT_DIM)
		else:
			draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.40))
			draw_rect(row_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.20), false, 1.0)
			draw_string(font, Vector2(row_rect.position.x + 12.0, row_rect.position.y + 20.0), "[%s]" % op_id, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)
			draw_string(font, Vector2(row_rect.position.x + 75.0, row_rect.position.y + 20.0), cin.get("title", ""), HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 85.0, font_size - 1, BrandClass.TEXT_DIM)
			var sub := "ACTO %d // %s DIAPOSITIVAS" % [cin.get("act", 1), cin.get("slides", []).size()]
			draw_string(font, Vector2(row_rect.position.x + 12.0, row_rect.position.y + 38.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size - 2, Color(0.40, 0.44, 0.58))

	# 2. Panel Derecho: Dossier de la Transmisión Seleccionada
	draw_rect(rp, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.90))
	draw_rect(rp, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.60), false, 1.0)

	if _selected_entry_idx >= 0 and _selected_entry_idx < cinematics.size():
		var sel_cin: Dictionary = cinematics[_selected_entry_idx]
		var op_id: String = sel_cin.get("operator", "ZERO")
		var op_info := CinematicRegistryClass.get_operator(op_id)
		var op_col: Color = op_info.get("color", BrandClass.ACCENT)

		# Encabezado del Dossier
		var r_head := Rect2(rp.position.x, rp.position.y, rp.size.x, 34.0)
		draw_rect(r_head, BrandClass.with_alpha(op_col, 0.15))
		draw_line(Vector2(rp.position.x, rp.position.y + 34.0), Vector2(rp.position.x + rp.size.x, rp.position.y + 34.0), BrandClass.with_alpha(op_col, 0.40), 1.0)
		draw_string(font, Vector2(rp.position.x + 16.0, rp.position.y + 23.0), "[DOSSIER DE TRANSMISIÓN // %s]" % op_id, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, op_col)

		# Título y metadatos
		var dy := rp.position.y + 65.0
		draw_string(font, Vector2(rp.position.x + 24.0, dy), sel_cin.get("title", ""), HORIZONTAL_ALIGNMENT_LEFT, rp.size.x - 48.0, big_font_size - 4, BrandClass.TEXT)
		dy += 26.0

		var meta := "OPERADOR: %s  |  ACTO %d  |  MODO: %s" % [op_info.get("name", op_id), sel_cin.get("act", 1), sel_cin.get("mode", "CODEC").to_upper()]
		draw_string(font, Vector2(rp.position.x + 24.0, dy), meta, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, op_col)
		dy += 34.0

		# Descripción sinóptica
		var desc: String = sel_cin.get("description", "")
		var desc_lines := DatabaseRendererClass.wrap_text(desc, font, font_size, rp.size.x - 48.0)
		for line in desc_lines:
			draw_string(font, Vector2(rp.position.x + 24.0, dy), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT)
			dy += 22.0
		dy += 16.0

		# Transcripción del Log Interceptado
		draw_string(font, Vector2(rp.position.x + 24.0, dy), "[REGISTRO DE DIAPOSITIVAS]", HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, op_col)
		dy += 24.0

		var slides: Array = sel_cin.get("slides", [])
		for s_idx in range(slides.size()):
			var slide: Dictionary = slides[s_idx]
			var speaker: String = slide.get("speaker", op_id)
			var s_text: String = slide.get("text", "")
			var line_str := "  [%d] %s: \"%s\"" % [s_idx + 1, speaker, s_text]
			var s_lines := DatabaseRendererClass.wrap_text(line_str, font, small_font_size, rp.size.x - 60.0)
			for sl in s_lines:
				draw_string(font, Vector2(rp.position.x + 24.0, dy), sl, HORIZONTAL_ALIGNMENT_LEFT, -1, small_font_size, BrandClass.TEXT_DIM)
				dy += 18.0
			dy += 6.0

		# Botón Reproducir Transmisión
		var play_btn := get_play_button_rect(vp)
		var btn_bg := BrandClass.with_alpha(op_col, 0.25 if _hovered_play_btn else 0.12)
		var btn_border := op_col if _hovered_play_btn else BrandClass.with_alpha(op_col, 0.60)
		draw_rect(play_btn, btn_bg)
		draw_rect(play_btn, btn_border, false, 1.5)
		draw_string(font, Vector2(play_btn.position.x + 18.0, play_btn.position.y + 28.0), "[ ▶ REPRODUCIR TRANSMISIÓN ]", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, op_col)

	# Botón Volver
	var btn_rect := _renderer.get_back_button_rect(vp)
	if _hovered_back:
		draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.95))
		draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.85), false, 1.5)
		draw_string(font, Vector2(btn_rect.position.x + 16, btn_rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.ACCENT)
	else:
		draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.70))
		draw_rect(btn_rect, BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.40), false, 1.0)
		draw_string(font, Vector2(btn_rect.position.x + 16, btn_rect.position.y + 23), "[ESC] <- VOLVER", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BrandClass.TEXT_DIM)
