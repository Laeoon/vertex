extends Control

## StartScreen
## Pantalla de bienvenida táctica de VERTEX (Press Start) y selector de perfiles de operador.
## Maneja la selección de Save Slots 1, 2 y 3 con telemetría en tiempo real.

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
const SlotManagerClass = preload("res://juego/system/slot_manager.gd")

enum State {
	PRESS_START,
	SELECT_SLOT
}

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var title_font_size: int = 56
var _pulse: float = 0.0

var _cyber_bg := CyberBackgroundClass.new()
var _state: State = State.PRESS_START

var _slots_data: Array[Dictionary] = []
var _selected_slot_idx: int = 0
var _hovered_slot_idx: int = -1


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	title_font_size = font_size + 42

	SlotManagerClass.init_slots()
	_refresh_slots()
	_selected_slot_idx = SlotManagerClass.get_active_slot() - 1

	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()

	queue_redraw()


func _refresh_slots() -> void:
	_slots_data = SlotManagerClass.get_all_slots_summary()


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	_cyber_bg.update(delta, get_viewport_rect().size)
	queue_redraw()


func _input(event: InputEvent) -> void:
	var vp := get_viewport_rect().size

	if _state == State.PRESS_START:
		if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
			var k := event as InputEventKey
			if k.keycode in [KEY_ENTER, KEY_SPACE]:
				_advance_to_slots()
				return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_advance_to_slots()
			return

	elif _state == State.SELECT_SLOT:
		if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
			var k := event as InputEventKey
			match k.keycode:
				KEY_LEFT, KEY_A, KEY_UP, KEY_W:
					_selected_slot_idx = (_selected_slot_idx - 1 + _slots_data.size()) % _slots_data.size()
					_play_sfx("hover")
					queue_redraw()
				KEY_RIGHT, KEY_D, KEY_DOWN, KEY_S:
					_selected_slot_idx = (_selected_slot_idx + 1) % _slots_data.size()
					_play_sfx("hover")
					queue_redraw()
				KEY_ENTER, KEY_SPACE:
					_confirm_slot(_selected_slot_idx + 1)
				KEY_ESCAPE:
					_state = State.PRESS_START
					_play_sfx("click")
					queue_redraw()

		elif event is InputEventMouseMotion:
			var mpos := (event as InputEventMouseMotion).position
			var prev_h := _hovered_slot_idx
			_hovered_slot_idx = -1
			for i in range(_slots_data.size()):
				if _get_slot_rect(i, vp).has_point(mpos):
					_hovered_slot_idx = i
					_selected_slot_idx = i
					break
			if prev_h != _hovered_slot_idx:
				queue_redraw()

		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mpos := (event as InputEventMouseButton).position
			for i in range(_slots_data.size()):
				if _get_slot_rect(i, vp).has_point(mpos):
					_confirm_slot(i + 1)
					return


func _advance_to_slots() -> void:
	_state = State.SELECT_SLOT
	_play_sfx("click")
	_refresh_slots()
	queue_redraw()


func _confirm_slot(slot_id: int) -> void:
	_play_sfx("click")
	SlotManagerClass.set_active_slot(slot_id)
	var st = get_node_or_null("/root/SceneTransition")
	if st != null and st.has_method("fade_to_scene"):
		st.fade_to_scene("res://escenas/main_menu.tscn")
	elif get_tree() != null:
		get_tree().change_scene_to_file("res://escenas/main_menu.tscn")


func _play_sfx(sfx_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx(sfx_name)


func _get_slot_rect(idx: int, vp: Vector2) -> Rect2:
	var total_w: float = mini(1000, vp.x - 80.0)
	var card_gap: float = 24.0
	var card_w: float = (total_w - (card_gap * 2.0)) / 3.0
	var card_h: float = 280.0
	var start_x: float = (vp.x - total_w) * 0.5
	var card_x: float = start_x + float(idx) * (card_w + card_gap)
	var card_y: float = (vp.y - card_h) * 0.5 + 30.0
	return Rect2(card_x, card_y, card_w, card_h)


func _draw() -> void:
	var vp := get_viewport_rect().size
	_cyber_bg.draw(self, vp)

	if _state == State.PRESS_START:
		_draw_press_start_view(vp)
	else:
		_draw_select_slot_view(vp)


func _draw_press_start_view(vp: Vector2) -> void:
	# Título principal de VERTEX
	var title_text := "V E R T E X"
	var t_sz := font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, title_font_size)
	var t_pos := Vector2((vp.x - t_sz.x) * 0.5, vp.y * 0.38)

	# Brillo y sombra cian del logo
	draw_string(font, t_pos + Vector2(0, 3), title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, title_font_size, Color(0.0, 0.4, 0.7, 0.4))
	draw_string(font, t_pos, title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, title_font_size, BrandClass.ACCENT)

	var sub_text := "SIMULADOR DE CIBERSEGURIDAD // TEORÍA DE GRAFOS"
	var s_sz := font.get_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var s_pos := Vector2((vp.x - s_sz.x) * 0.5, t_pos.y + 36.0)
	draw_string(font, s_pos, sub_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, BrandClass.TEXT_DIM)

	# Indicador pulsante: Presiona Enter
	var p_glow := 0.5 + sin(_pulse * 1.5) * 0.5
	var prompt := "[ PRESIONA ENTER O HAZ CLIC PARA INICIAR ]"
	var p_sz := font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 2)
	var p_pos := Vector2((vp.x - p_sz.x) * 0.5, vp.y * 0.68)

	draw_rect(Rect2(p_pos.x - 16.0, p_pos.y - 20.0, p_sz.x + 32.0, 32.0), BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.75))
	draw_rect(Rect2(p_pos.x - 16.0, p_pos.y - 20.0, p_sz.x + 32.0, 32.0), BrandClass.with_alpha(BrandClass.ACCENT, p_glow * 0.8), false, 1.2)
	draw_string(font, p_pos, prompt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 2, BrandClass.with_alpha(BrandClass.TEXT, 0.8 + p_glow * 0.2))


func _draw_select_slot_view(vp: Vector2) -> void:
	# Encabezado
	var header_title := "SELECCIÓN DE SECUENCIA // PERFIL DE OPERADOR"
	var h_sz := font.get_string_size(header_title, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 6)
	draw_string(font, Vector2((vp.x - h_sz.x) * 0.5, 90.0), header_title, HORIZONTAL_ALIGNMENT_CENTER, -1, big_font_size - 6, BrandClass.ACCENT)

	var header_sub := "Selecciona una ranura de guardado para iniciar la sesión táctica"
	var hs_sz := font.get_string_size(header_sub, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
	draw_string(font, Vector2((vp.x - hs_sz.x) * 0.5, 114.0), header_sub, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.TEXT_DIM)

	# 3 Tarjetas de Slots
	for i in range(_slots_data.size()):
		var s: Dictionary = _slots_data[i]
		var rect := _get_slot_rect(i, vp)
		var is_selected := (i == _selected_slot_idx)
		var is_empty: bool = s.get("is_empty", true)

		var border_col: Color = BrandClass.ACCENT if is_selected else BrandClass.PANEL_BORDER
		var bg_alpha: float = 0.95 if is_selected else 0.70

		draw_rect(rect, BrandClass.with_alpha(BrandClass.PANEL_SOLID, bg_alpha))
		draw_rect(rect, BrandClass.with_alpha(border_col, 0.9 if is_selected else 0.4), false, 1.6 if is_selected else 1.0)

		# Bracket superior de selección
		if is_selected:
			var cb: float = 12.0
			draw_line(rect.position, rect.position + Vector2(cb, 0), BrandClass.ACCENT, 2.5)
			draw_line(rect.position, rect.position + Vector2(0, cb), BrandClass.ACCENT, 2.5)
			draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(rect.size.x - cb, 0), BrandClass.ACCENT, 2.5)
			draw_line(rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(rect.size.x, cb), BrandClass.ACCENT, 2.5)

		# Cabecera de la tarjeta
		var slot_header := "SLOT 0%d" % (i + 1)
		draw_string(font, Vector2(rect.position.x + 20.0, rect.position.y + 36.0), slot_header, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)

		# Nombre de operador / Estado
		var op_name: String = String(s.get("player_name", "Operador")).to_upper()
		var name_col: Color = BrandClass.TEXT if not is_empty else BrandClass.with_alpha(BrandClass.TEXT_DIM, 0.6)
		draw_string(font, Vector2(rect.position.x + 20.0, rect.position.y + 64.0), op_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, name_col)

		draw_line(Vector2(rect.position.x + 20.0, rect.position.y + 78.0), Vector2(rect.position.x + rect.size.x - 20.0, rect.position.y + 78.0), BrandClass.with_alpha(BrandClass.PANEL_BORDER, 0.4), 1.0)

		if is_empty:
			# Ranura vacía
			var empty_txt := "[ RANURA DISPONIBLE ]"
			var e_sz := font.get_string_size(empty_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, Vector2(rect.position.x + (rect.size.x - e_sz.x) * 0.5, rect.position.y + 140.0), empty_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, BrandClass.with_alpha(BrandClass.ACCENT, 0.6))

			var new_hint := "Iniciar nueva campaña"
			var nh_sz := font.get_string_size(new_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3)
			draw_string(font, Vector2(rect.position.x + (rect.size.x - nh_sz.x) * 0.5, rect.position.y + 164.0), new_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3, BrandClass.TEXT_DIM)
		else:
			# Ranura con progreso
			var stars_count: int = s.get("stars", 0)
			var lvls_count: int = s.get("levels_completed", 0)

			var cur_y := rect.position.y + 110.0
			var step_y := 32.0

			_draw_card_metric(rect.position.x + 20.0, rect.size.x - 40.0, cur_y, "ESTRELLAS", "%d ★" % stars_count, BrandClass.WARNING)
			cur_y += step_y
			_draw_card_metric(rect.position.x + 20.0, rect.size.x - 40.0, cur_y, "MISIONES", "%d" % lvls_count, BrandClass.TEXT)
			cur_y += step_y
			_draw_card_metric(rect.position.x + 20.0, rect.size.x - 40.0, cur_y, "ESTADO", "ACTIVO", BrandClass.SUCCESS)

		# Botón / Prompt inferior de confirmación
		var btn_h := 36.0
		var btn_rect := Rect2(rect.position.x + 16.0, rect.position.y + rect.size.y - btn_h - 16.0, rect.size.x - 32.0, btn_h)
		var btn_bg: Color = BrandClass.with_alpha(BrandClass.ACCENT, 0.20 if is_selected else 0.08)
		var btn_bdr: Color = BrandClass.with_alpha(BrandClass.ACCENT if is_selected else BrandClass.PANEL_BORDER, 0.8 if is_selected else 0.4)
		draw_rect(btn_rect, btn_bg)
		draw_rect(btn_rect, btn_bdr, false, 1.2)

		var action_label := "[ ENTER / CLIC ] CONTINUAR" if not is_empty else "[ ENTER / CLIC ] CREAR"
		var a_sz := font.get_string_size(action_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
		draw_string(font, Vector2(btn_rect.position.x + (btn_rect.size.x - a_sz.x) * 0.5, btn_rect.position.y + 23.0), action_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.ACCENT if is_selected else BrandClass.TEXT_DIM)

	# Footer / Teclas
	var ft_text := "[ENTER / CLIC] Seleccionar ranura    [A / D] Navegar    [ESC] Volver"
	var ft_sz := font.get_string_size(ft_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3)
	draw_string(font, Vector2((vp.x - ft_sz.x) * 0.5, vp.y - 30.0), ft_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3, BrandClass.TEXT_DIM)


func _draw_card_metric(x: float, w: float, y: float, label: String, value: String, val_col: Color) -> void:
	draw_string(font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
	var vsz := font.get_string_size(value, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1)
	draw_string(font, Vector2(x + w - vsz.x, y), value, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1, val_col)
