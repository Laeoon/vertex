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
var _confirm_delete_slot: int = 0 # 0 = inactivo, 1..3 = confirmando borrado
var _confirm_import_data: Dictionary = {} # {} = inactivo; {slot_id, bak_path, options, selected, slot_empty}
var _confirm_restore_slot: int = 0 # 0 = inactivo, 1..3 = confirmando restauración de snapshot

const MAX_IMPORT_LIST_ROWS: int = 4
const TOAST_DURATION: float = 3.5
const TOAST_FADE_TIME: float = 0.5

var _toast_message: String = ""
var _toast_color: Color = BrandClass.ACCENT
var _toast_timer: float = 0.0


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
	if _toast_timer > 0.0:
		_toast_timer = maxf(0.0, _toast_timer - delta)
		if _toast_timer <= 0.0:
			_toast_message = ""
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
		if _confirm_delete_slot > 0:
			if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
				var k := event as InputEventKey
				if k.keycode in [KEY_Y, KEY_ENTER]:
					_execute_delete_slot(_confirm_delete_slot)
				elif k.keycode in [KEY_N, KEY_ESCAPE]:
					_confirm_delete_slot = 0
					_play_sfx("click")
					queue_redraw()
			elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				# Clic fuera cancela
				_confirm_delete_slot = 0
				_play_sfx("click")
				queue_redraw()
			return

		if not _confirm_import_data.is_empty():
			_handle_import_modal_input(event, vp)
			return

		if _confirm_restore_slot > 0:
			if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
				var rk := event as InputEventKey
				if rk.keycode in [KEY_Y, KEY_ENTER]:
					_execute_restore_snapshot(_confirm_restore_slot)
				elif rk.keycode in [KEY_N, KEY_ESCAPE]:
					_confirm_restore_slot = 0
					_play_sfx("click")
					queue_redraw()
			elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_confirm_restore_slot = 0
				_play_sfx("click")
				queue_redraw()
			return

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
				KEY_DELETE, KEY_BACKSPACE:
					var slot_id := _selected_slot_idx + 1
					var s_data: Dictionary = _slots_data[_selected_slot_idx]
					if not s_data.get("is_empty", true):
						_confirm_delete_slot = slot_id
						_play_sfx("alert")
						queue_redraw()
				KEY_E:
					_request_export(_selected_slot_idx + 1)
				KEY_I:
					_request_import(_selected_slot_idx + 1)
				KEY_R:
					_request_restore(_selected_slot_idx + 1)
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
				var card_rect := _get_slot_rect(i, vp)
				if not card_rect.has_point(mpos):
					continue
				var quick_actions := _get_quick_actions(i)
				for a in range(quick_actions.size()):
					if _get_quick_button_rect(card_rect, a, quick_actions.size()).has_point(mpos):
						_selected_slot_idx = i
						_run_quick_action(quick_actions[a]["id"], i + 1)
						return
				_confirm_slot(i + 1)
				return


# ---------------------------------------------------------------------------
# Backup & Restore (exportar / importar .bak / restaurar snapshot)
# ---------------------------------------------------------------------------

func _show_toast(message: String, color: Color) -> void:
	_toast_message = message
	_toast_color = color
	_toast_timer = TOAST_DURATION
	queue_redraw()


func _get_quick_actions(idx: int) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var is_empty: bool = _slots_data[idx].get("is_empty", true)
	if not is_empty:
		actions.append({"id": "export", "label": "[E] Exportar"})
	actions.append({"id": "import", "label": "[I] Importar"})
	if not is_empty:
		actions.append({"id": "restore", "label": "[R] Restaurar"})
	return actions


func _get_quick_button_rect(card_rect: Rect2, button_idx: int, count: int) -> Rect2:
	var gap := 6.0
	var inner_w := card_rect.size.x - 32.0
	var bw := (inner_w - gap * float(count - 1)) / float(count)
	return Rect2(card_rect.position.x + 16.0 + float(button_idx) * (bw + gap), card_rect.position.y + 190.0, bw, 26.0)


func _run_quick_action(action_id: String, slot_id: int) -> void:
	match action_id:
		"export":
			_request_export(slot_id)
		"import":
			_request_import(slot_id)
		"restore":
			_request_restore(slot_id)


func _request_export(slot_id: int) -> void:
	var s_data: Dictionary = _slots_data[slot_id - 1]
	if s_data.get("is_empty", true):
		_show_toast("[!] LA RANURA ESTÁ VACÍA (NADA QUE EXPORTAR)", BrandClass.WARNING)
		_play_sfx("alert")
		return
	var result: Dictionary = SlotManagerClass.export_slot_to_bak(slot_id)
	if result.get("success", false):
		var path: String = result.get("path", "")
		_show_toast("[OK] EXPORTADO: %s" % path.get_file(), BrandClass.SUCCESS)
		_play_sfx("reset")
	else:
		var error_msg: String = str(result.get("message", result.get("error", "ERROR DESCONOCIDO")))
		_show_toast("[ERROR] NO SE PUDO EXPORTAR: %s" % error_msg, BrandClass.DANGER)
		_play_sfx("alert")


## Lista los .bak de user://backups/ del más reciente al más antiguo.
func _find_bak_files() -> Array[String]:
	var entries: Array[Dictionary] = []
	for f in DirAccess.get_files_at(SlotManagerClass.DEFAULT_BACKUPS_DIR):
		if f.to_lower().ends_with(".bak"):
			var full := "%s/%s" % [SlotManagerClass.DEFAULT_BACKUPS_DIR, f]
			entries.append({"path": full, "mtime": FileAccess.get_modified_time(full)})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["mtime"] != b["mtime"]:
			return a["mtime"] > b["mtime"]
		return String(a["path"]) > String(b["path"]))
	var result: Array[String] = []
	for e in entries:
		result.append(e["path"])
	return result


func _request_import(slot_id: int) -> void:
	var bak_files := _find_bak_files()
	if bak_files.is_empty():
		_show_toast("[!] NO SE ENCONTRARON ARCHIVOS .BAK EN user://backups/", BrandClass.WARNING)
		_play_sfx("alert")
		return
	var slot_empty: bool = _slots_data[slot_id - 1].get("is_empty", true)
	if slot_empty and bak_files.size() == 1:
		# Nada que sobrescribir y sin elección posible: importar directamente.
		_execute_import(bak_files[0], slot_id)
		return
	_confirm_import_data = {
		"slot_id": slot_id,
		"bak_path": bak_files[0],
		"options": bak_files,
		"selected": 0,
		"slot_empty": slot_empty,
	}
	_play_sfx("alert")
	queue_redraw()


func _handle_import_modal_input(event: InputEvent, vp: Vector2) -> void:
	var options: Array = _confirm_import_data.get("options", [])
	var selected: int = _confirm_import_data.get("selected", 0)
	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k := event as InputEventKey
		if k.keycode in [KEY_Y, KEY_ENTER]:
			var bak_path: String = _confirm_import_data.get("bak_path", "")
			var slot_id: int = _confirm_import_data.get("slot_id", 0)
			_confirm_import_data = {}
			_execute_import(bak_path, slot_id)
		elif k.keycode in [KEY_N, KEY_ESCAPE]:
			_confirm_import_data = {}
			_play_sfx("click")
			queue_redraw()
		elif k.keycode in [KEY_UP, KEY_W, KEY_LEFT, KEY_A] and options.size() > 1:
			_select_import_option((selected - 1 + options.size()) % options.size())
		elif k.keycode in [KEY_DOWN, KEY_S, KEY_RIGHT, KEY_D] and options.size() > 1:
			_select_import_option((selected + 1) % options.size())
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos := (event as InputEventMouseButton).position
		var row_hit := -1
		for r in range(mini(options.size(), MAX_IMPORT_LIST_ROWS)):
			if _get_import_row_rect(vp, r).has_point(mpos):
				row_hit = r
				break
		if row_hit >= 0:
			_select_import_option(_get_import_scroll_offset() + row_hit)
		else:
			# Clic fuera de la lista cancela
			_confirm_import_data = {}
			_play_sfx("click")
			queue_redraw()


func _select_import_option(new_idx: int) -> void:
	var options: Array = _confirm_import_data.get("options", [])
	_confirm_import_data["selected"] = new_idx
	_confirm_import_data["bak_path"] = options[new_idx]
	_play_sfx("hover")
	queue_redraw()


func _get_import_scroll_offset() -> int:
	var options: Array = _confirm_import_data.get("options", [])
	var selected: int = _confirm_import_data.get("selected", 0)
	if options.size() <= MAX_IMPORT_LIST_ROWS:
		return 0
	return clampi(selected - MAX_IMPORT_LIST_ROWS + 1, 0, options.size() - MAX_IMPORT_LIST_ROWS)


func _get_import_modal_rect(vp: Vector2) -> Rect2:
	var options: Array = _confirm_import_data.get("options", [])
	var rows := mini(options.size(), MAX_IMPORT_LIST_ROWS)
	var modal_w := 560.0
	var modal_h := 170.0 + float(rows) * 24.0
	return Rect2((vp.x - modal_w) * 0.5, (vp.y - modal_h) * 0.5, modal_w, modal_h)


func _get_import_row_rect(vp: Vector2, row: int) -> Rect2:
	var m_rect := _get_import_modal_rect(vp)
	return Rect2(m_rect.position.x + 20.0, m_rect.position.y + 100.0 + float(row) * 24.0, m_rect.size.x - 40.0, 22.0)


func _execute_import(bak_path: String, slot_id: int) -> void:
	var result: Dictionary = SlotManagerClass.import_bak_to_slot(bak_path, slot_id)
	if result.get("success", false):
		_refresh_slots()
		_show_toast("[OK] PARTIDA IMPORTADA CON ÉXITO", BrandClass.SUCCESS)
		_play_sfx("reset")
	else:
		_show_toast("[ERROR] FALLO DE IMPORTACIÓN: CHECKSUM O ARCHIVO INVÁLIDO", BrandClass.DANGER)
		_play_sfx("alert")
	queue_redraw()


func _request_restore(slot_id: int) -> void:
	var snapshots: Array[String] = SlotManagerClass.get_slot_snapshots(slot_id)
	if snapshots.is_empty():
		_show_toast("[!] NO HAY SNAPSHOTS PREVENTIVOS EN ESTE SLOT", BrandClass.WARNING)
		_play_sfx("alert")
		return
	_confirm_restore_slot = slot_id
	_play_sfx("alert")
	queue_redraw()


func _execute_restore_snapshot(slot_id: int) -> void:
	_confirm_restore_slot = 0
	var result: Dictionary = SlotManagerClass.restore_slot_snapshot(slot_id)
	if result.get("success", false):
		_refresh_slots()
		_show_toast("[OK] SNAPSHOT RESTAURADO", BrandClass.SUCCESS)
		_play_sfx("reset")
	else:
		var error_msg: String = str(result.get("message", result.get("error", "ERROR DESCONOCIDO")))
		_show_toast("[ERROR] NO SE PUDO RESTAURAR: %s" % error_msg, BrandClass.DANGER)
		_play_sfx("alert")
	queue_redraw()


func _execute_delete_slot(slot_id: int) -> void:
	SlotManagerClass.delete_slot(slot_id)
	_confirm_delete_slot = 0
	_play_sfx("reset")
	_refresh_slots()
	queue_redraw()


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

	_draw_toast(vp)


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

		# Accesos rápidos de Backup & Restore (clicables)
		var quick_actions := _get_quick_actions(i)
		for a in range(quick_actions.size()):
			var q_rect := _get_quick_button_rect(rect, a, quick_actions.size())
			var q_hover := q_rect.has_point(get_local_mouse_position())
			draw_rect(q_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.18 if q_hover else 0.06))
			draw_rect(q_rect, BrandClass.with_alpha(BrandClass.ACCENT if is_selected else BrandClass.PANEL_BORDER, 0.7 if is_selected else 0.35), false, 1.0)
			var q_label: String = quick_actions[a]["label"]
			var q_sz := font.get_string_size(q_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4)
			draw_string(font, Vector2(q_rect.position.x + (q_rect.size.x - q_sz.x) * 0.5, q_rect.position.y + 17.0), q_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4, BrandClass.ACCENT if is_selected else BrandClass.TEXT_DIM)

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

		# Pista de borrado si la ranura está ocupada
		if not is_empty and is_selected:
			var del_hint := "[SUPR / BACKSPACE] Borrar partida"
			var dh_sz := font.get_string_size(del_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4)
			draw_string(font, Vector2(rect.position.x + (rect.size.x - dh_sz.x) * 0.5, rect.position.y + rect.size.y + 16.0), del_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 4, Color(1.0, 0.4, 0.3, 0.85))

	# Modal de confirmación de borrado
	if _confirm_delete_slot > 0:
		var modal_w := 460.0
		var modal_h := 160.0
		var m_rect := Rect2((vp.x - modal_w) * 0.5, (vp.y - modal_h) * 0.5, modal_w, modal_h)
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.0, 0.0, 0.0, 0.7)) # Backdrop
		draw_rect(m_rect, BrandClass.PANEL_SOLID)
		draw_rect(m_rect, Color(1.0, 0.25, 0.2, 0.9), false, 1.8)

		var warn_title := "¿ELIMINAR PERFIL DE RANURA 0%d?" % _confirm_delete_slot
		var wt_sz := font.get_string_size(warn_title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 1)
		draw_string(font, Vector2(m_rect.position.x + (modal_w - wt_sz.x) * 0.5, m_rect.position.y + 38.0), warn_title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 1, Color(1.0, 0.35, 0.3))

		var warn_desc := "Esta acción destruirá todo el progreso, estrellas y registros de este slot de forma permanente."
		var wd_sz := font.get_string_size(warn_desc, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3)
		draw_string(font, Vector2(m_rect.position.x + 20.0, m_rect.position.y + 70.0), warn_desc, HORIZONTAL_ALIGNMENT_LEFT, modal_w - 40.0, font_size - 3, BrandClass.TEXT_DIM)

		var prompt_btn := "[ Y / ENTER ] Confirmar eliminación        [ N / ESC ] Cancelar"
		var pb_sz := font.get_string_size(prompt_btn, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
		draw_string(font, Vector2(m_rect.position.x + (modal_w - pb_sz.x) * 0.5, m_rect.position.y + 125.0), prompt_btn, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.TEXT)

	if not _confirm_import_data.is_empty():
		_draw_import_modal(vp)

	if _confirm_restore_slot > 0:
		_draw_restore_modal(vp)

	# Footer / Teclas
	var ft_text := "[ENTER/CLIC] Seleccionar    [A/D] Navegar    [E] Exportar .bak    [I] Importar .bak    [R] Restaurar    [SUPR] Borrar    [ESC] Volver"
	var ft_sz := font.get_string_size(ft_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3)
	draw_string(font, Vector2((vp.x - ft_sz.x) * 0.5, vp.y - 25.0), ft_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 3, BrandClass.TEXT_DIM)


func _draw_import_modal(vp: Vector2) -> void:
	var m_rect := _get_import_modal_rect(vp)
	var modal_w := m_rect.size.x
	var slot_id: int = _confirm_import_data.get("slot_id", 0)
	var slot_empty: bool = _confirm_import_data.get("slot_empty", true)
	var options: Array = _confirm_import_data.get("options", [])
	var selected: int = _confirm_import_data.get("selected", 0)
	var border_col: Color = BrandClass.ACCENT if slot_empty else Color(1.0, 0.7, 0.2, 0.9)

	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.0, 0.0, 0.0, 0.7)) # Backdrop
	draw_rect(m_rect, BrandClass.PANEL_SOLID)
	draw_rect(m_rect, border_col, false, 1.8)

	var title := "¿IMPORTAR BACKUP EN RANURA 0%d?" % slot_id
	var t_sz := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 1)
	draw_string(font, Vector2(m_rect.position.x + (modal_w - t_sz.x) * 0.5, m_rect.position.y + 38.0), title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 1, border_col)

	var desc := "La ranura está vacía." if slot_empty else "Se sobrescribirá el progreso actual (snapshot preventivo automático)"
	draw_string(font, Vector2(m_rect.position.x + 20.0, m_rect.position.y + 66.0), desc, HORIZONTAL_ALIGNMENT_LEFT, modal_w - 40.0, font_size - 3, BrandClass.TEXT_DIM)

	var offset := _get_import_scroll_offset()
	for r in range(mini(options.size(), MAX_IMPORT_LIST_ROWS)):
		var opt_idx := offset + r
		var row_rect := _get_import_row_rect(vp, r)
		var is_sel := (opt_idx == selected)
		if is_sel:
			draw_rect(row_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.18))
			draw_rect(row_rect, BrandClass.with_alpha(BrandClass.ACCENT, 0.8), false, 1.0)
		var row_label := String(options[opt_idx]).get_file()
		draw_string(font, Vector2(row_rect.position.x + 8.0, row_rect.position.y + 16.0), row_label, HORIZONTAL_ALIGNMENT_LEFT, row_rect.size.x - 16.0, font_size - 3, BrandClass.TEXT if is_sel else BrandClass.TEXT_DIM)

	var prompt_btn := "[ Y / ENTER ] Importar    [ W / S ] Elegir archivo    [ N / ESC ] Cancelar"
	var pb_sz := font.get_string_size(prompt_btn, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
	draw_string(font, Vector2(m_rect.position.x + (modal_w - pb_sz.x) * 0.5, m_rect.position.y + m_rect.size.y - 20.0), prompt_btn, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.TEXT)


func _draw_restore_modal(vp: Vector2) -> void:
	var modal_w := 460.0
	var modal_h := 160.0
	var m_rect := Rect2((vp.x - modal_w) * 0.5, (vp.y - modal_h) * 0.5, modal_w, modal_h)
	var border_col := Color(1.0, 0.7, 0.2, 0.9)
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.0, 0.0, 0.0, 0.7)) # Backdrop
	draw_rect(m_rect, BrandClass.PANEL_SOLID)
	draw_rect(m_rect, border_col, false, 1.8)

	var title := "¿RESTAURAR ÚLTIMO SNAPSHOT EN RANURA 0%d?" % _confirm_restore_slot
	var t_sz := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 1)
	draw_string(font, Vector2(m_rect.position.x + (modal_w - t_sz.x) * 0.5, m_rect.position.y + 38.0), title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size + 1, border_col)

	var desc := "Se recuperarán los datos previos"
	draw_string(font, Vector2(m_rect.position.x + 20.0, m_rect.position.y + 70.0), desc, HORIZONTAL_ALIGNMENT_LEFT, modal_w - 40.0, font_size - 3, BrandClass.TEXT_DIM)

	var prompt_btn := "[ Y / ENTER ] Confirmar restauración        [ N / ESC ] Cancelar"
	var pb_sz := font.get_string_size(prompt_btn, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2)
	draw_string(font, Vector2(m_rect.position.x + (modal_w - pb_sz.x) * 0.5, m_rect.position.y + 125.0), prompt_btn, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size - 2, BrandClass.TEXT)


func _draw_toast(vp: Vector2) -> void:
	if _toast_timer <= 0.0 or _toast_message.is_empty():
		return
	var alpha := clampf(_toast_timer / TOAST_FADE_TIME, 0.0, 1.0)
	var t_size := font_size - 1
	var t_sz := font.get_string_size(_toast_message, HORIZONTAL_ALIGNMENT_CENTER, -1, t_size)
	var box_w := minf(t_sz.x + 40.0, vp.x - 40.0)
	var box := Rect2((vp.x - box_w) * 0.5, 24.0, box_w, 36.0)
	draw_rect(box, BrandClass.with_alpha(BrandClass.PANEL_SOLID, 0.88 * alpha))
	draw_rect(box, BrandClass.with_alpha(_toast_color, 0.95 * alpha), false, 1.6)
	draw_rect(Rect2(box.position.x, box.position.y, 4.0, box.size.y), BrandClass.with_alpha(_toast_color, alpha))
	draw_string(font, Vector2(box.position.x + 20.0, box.position.y + 23.0), _toast_message, HORIZONTAL_ALIGNMENT_LEFT, box_w - 30.0, t_size, BrandClass.with_alpha(_toast_color, alpha))


func _draw_card_metric(x: float, w: float, y: float, label: String, value: String, val_col: Color) -> void:
	draw_string(font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, BrandClass.TEXT_DIM)
	var vsz := font.get_string_size(value, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1)
	draw_string(font, Vector2(x + w - vsz.x, y), value, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size - 1, val_col)
