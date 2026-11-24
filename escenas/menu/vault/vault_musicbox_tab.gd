extends RefCounted

## Tab 04 // MUSICBOX FFT: 100% _draw() real-time 32-band spectrum player, seek, volume & pins.
## State lives on Profile (`p`) + AudioManager autoload.

const BrandClass = preload("res://juego/ui/brand.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

const BAND_COUNT: int = 32
const COL_PANEL_BG := Color("#0B1019")
const COL_PANEL_ALT := Color("#121A28")
const COL_BORDER := Color("#233249")
const COL_PINK := Color("#FF2E88")
const COL_PURPLE := Color("#BF5AF2")
const COL_CYAN := Color("#00E5FF")
const COL_GREEN := Color("#39FF88")
const COL_AMBER := Color("#FFC857")
const COL_TEXT := Color("#EAECF5")
const COL_MUTED := Color("#7A869E")

var p: Profile
var _canvas: Control = null
var _fft_smooth: PackedFloat32Array = PackedFloat32Array()
var _fft_peaks: PackedFloat32Array = PackedFloat32Array()
var _scroll_offset: int = 0
var _visible_rows: int = 10
var _dragging_seek: bool = false
var _dragging_vol: bool = false
var _volume_pct: int = 80
var _hitboxes: Array[Dictionary] = []


func _init(profile: Profile) -> void:
	p = profile
	_fft_smooth.resize(BAND_COUNT)
	_fft_peaks.resize(BAND_COUNT)
	for i: int in range(BAND_COUNT):
		_fft_smooth[i] = 0.0
		_fft_peaks[i] = 0.0
	var am: Node = p.get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("get_bus_volume_percent"):
		_volume_pct = int(am.call("get_bus_volume_percent", "Music"))


func build(container: Control) -> void:
	var ctrl := Control.new()
	ctrl.name = "MusicboxDrawCanvas"
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.focus_mode = Control.FOCUS_ALL
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.draw.connect(_on_draw)
	ctrl.gui_input.connect(_on_gui_input)
	container.add_child(ctrl)
	_canvas = ctrl
	p._eq_control = ctrl


func tick(delta: float) -> void:
	if _canvas == null or not _canvas.visible:
		return
	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	var is_unlocked: bool = false
	if p._selected_music_idx >= 0 and p._selected_music_idx < tracks.size():
		is_unlocked = _is_track_unlocked(tracks[p._selected_music_idx])

	var active_play: bool = p._music_is_playing and is_unlocked
	var raw_mags := PackedFloat32Array()
	var has_signal: bool = false
	var am: Node = p.get_node_or_null("/root/AudioManager")
	if active_play and am != null and am.has_method("get_spectrum_magnitudes"):
		raw_mags = am.call("get_spectrum_magnitudes", BAND_COUNT, 24.0, 11050.0)
		for v: float in raw_mags:
			if v > 0.015:
				has_signal = true
				break

	for i: int in range(BAND_COUNT):
		var target: float = 0.0
		if active_play and has_signal and raw_mags.size() == BAND_COUNT:
			target = raw_mags[i]
		elif active_play:
			var t: float = float(i) / float(BAND_COUNT - 1)
			target = clampf(0.18 + 0.16 * sin(p._pulse * 4.0 + t * 8.0) + 0.08 * cos(p._pulse * 6.5 - t * 13.0), 0.04, 0.45)

		var spd: float = 22.0 if target > _fft_smooth[i] else 8.0
		_fft_smooth[i] = lerpf(_fft_smooth[i], target, clampf(spd * delta, 0.0, 1.0))
		if _fft_smooth[i] >= _fft_peaks[i]:
			_fft_peaks[i] = _fft_smooth[i]
		else:
			_fft_peaks[i] = maxf(0.0, _fft_peaks[i] - 0.55 * delta)

	_canvas.queue_redraw()


func get_filtered_track_indices() -> Array[int]:
	var out: Array[int] = []
	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	for i: int in range(tracks.size()):
		var pack: String = str(tracks[i].get("pack", ""))
		if p._music_filter_idx == 1 and pack != "Pink Bloom":
			continue
		if p._music_filter_idx == 2 and pack != "Code Injection":
			continue
		out.append(i)
	return out


func select_and_play_track(track_idx: int) -> bool:
	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	if track_idx < 0 or track_idx >= tracks.size():
		return false
	p._selected_music_idx = track_idx
	var tr: Dictionary = tracks[track_idx]
	var unlocked: bool = _is_track_unlocked(tr)
	if unlocked:
		p._music_is_playing = true
		var path: String = str(tr.get("path", ""))
		var am: Node = p.get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("play_track") and not path.is_empty():
			am.call("play_track", path)
	_ensure_selection_visible()
	if _canvas != null:
		_canvas.queue_redraw()
	return unlocked


func toggle_play_pause() -> bool:
	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	if p._selected_music_idx < 0 or p._selected_music_idx >= tracks.size():
		return false
	var tr: Dictionary = tracks[p._selected_music_idx]
	if not _is_track_unlocked(tr):
		return false

	p._music_is_playing = not p._music_is_playing
	var am: Node = p.get_node_or_null("/root/AudioManager")
	if am != null:
		var path: String = str(tr.get("path", ""))
		if p._music_is_playing:
			if am.has_method("get_current_music_path") and str(am.call("get_current_music_path")) == path and am.has_method("set_music_paused"):
				am.call("set_music_paused", false)
				if am.has_method("is_music_playing") and not bool(am.call("is_music_playing")) and am.has_method("play_track"):
					am.call("play_track", path)
			elif am.has_method("play_track"):
				am.call("play_track", path)
		else:
			if am.has_method("set_music_paused"):
				am.call("set_music_paused", true)
	if _canvas != null:
		_canvas.queue_redraw()
	return p._music_is_playing


func step_track(dir: int) -> int:
	var indices: Array[int] = get_filtered_track_indices()
	if indices.is_empty():
		return p._selected_music_idx
	var pos: int = indices.find(p._selected_music_idx)
	if pos == -1:
		pos = 0
	else:
		pos = posmod(pos + dir, indices.size())
	var next_idx: int = indices[pos]
	select_and_play_track(next_idx)
	return next_idx


func pin_selected_to_menu() -> void:
	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	if p._selected_music_idx >= 0 and p._selected_music_idx < tracks.size():
		p._pinned_menu_track = str(tracks[p._selected_music_idx].get("name", ""))
		p._save_profile()
		if _canvas != null:
			_canvas.queue_redraw()


func pin_selected_to_game() -> void:
	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	if p._selected_music_idx >= 0 and p._selected_music_idx < tracks.size():
		p._pinned_game_track = str(tracks[p._selected_music_idx].get("name", ""))
		p._save_profile()
		if _canvas != null:
			_canvas.queue_redraw()


func _is_track_unlocked(tr: Dictionary) -> bool:
	var badges: Array = p.stats.get("badges", [])
	var encs: Array = p.stats.get("decrypted_enc_files", [])
	return VaultModules.is_track_unlocked(tr, badges, encs, p.progress)


func _ensure_selection_visible() -> void:
	var indices: Array[int] = get_filtered_track_indices()
	var pos: int = indices.find(p._selected_music_idx)
	if pos == -1:
		_scroll_offset = 0
		return
	if pos < _scroll_offset:
		_scroll_offset = pos
	elif pos >= _scroll_offset + _visible_rows:
		_scroll_offset = pos - _visible_rows + 1


func _on_gui_input(event: InputEvent) -> void:
	if _canvas == null or not _canvas.visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if not mb.pressed:
				_dragging_seek = false
				_dragging_vol = false
				return
			_canvas.grab_focus()
			for i: int in range(_hitboxes.size() - 1, -1, -1):
				var hb: Dictionary = _hitboxes[i]
				var r: Rect2 = hb.get("rect", Rect2())
				if r.has_point(mb.position):
					_handle_hitbox_click(hb, mb.position)
					_canvas.accept_event()
					return
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var max_off: int = maxi(0, get_filtered_track_indices().size() - _visible_rows)
			_scroll_offset = mini(max_off, _scroll_offset + 1)
			_canvas.queue_redraw()
			_canvas.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_offset = maxi(0, _scroll_offset - 1)
			_canvas.queue_redraw()
			_canvas.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging_seek:
			_apply_seek_at_x(mm.position.x)
			_canvas.accept_event()
		elif _dragging_vol:
			_apply_vol_at_x(mm.position.x)
			_canvas.accept_event()
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_UP or ke.keycode == KEY_K:
				p._play_click_sfx()
				step_track(-1)
				_canvas.accept_event()
			elif ke.keycode == KEY_DOWN or ke.keycode == KEY_J:
				p._play_click_sfx()
				step_track(1)
				_canvas.accept_event()
			elif ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
				p._play_click_sfx()
				toggle_play_pause()
				_canvas.accept_event()


func _handle_hitbox_click(hb: Dictionary, pos: Vector2) -> void:
	var hid: String = str(hb.get("id", ""))
	if hid.begins_with("filter_"):
		p._music_filter_idx = int(hb.get("val", 0))
		_scroll_offset = 0
		p._play_click_sfx()
	elif hid.begins_with("track_"):
		p._play_click_sfx()
		select_and_play_track(int(hb.get("val", 0)))
	elif hid == "prev":
		p._play_click_sfx()
		step_track(-1)
	elif hid == "play":
		p._play_click_sfx()
		toggle_play_pause()
	elif hid == "next":
		p._play_click_sfx()
		step_track(1)
	elif hid == "pin_menu":
		p._play_click_sfx()
		pin_selected_to_menu()
	elif hid == "pin_game":
		p._play_click_sfx()
		pin_selected_to_game()
	elif hid == "seek":
		_dragging_seek = true
		_apply_seek_at_x(pos.x)
	elif hid == "vol":
		_dragging_vol = true
		_apply_vol_at_x(pos.x)
	_canvas.queue_redraw()


func _apply_seek_at_x(mx: float) -> void:
	for hb: Dictionary in _hitboxes:
		if str(hb.get("id", "")) == "seek":
			var r: Rect2 = hb.get("rect", Rect2())
			var ratio: float = clampf((mx - r.position.x) / maxf(1.0, r.size.x), 0.0, 1.0)
			var am: Node = p.get_node_or_null("/root/AudioManager")
			if am != null and am.has_method("get_music_duration") and am.has_method("seek_music"):
				var dur: float = float(am.call("get_music_duration"))
				if dur > 0.1:
					am.call("seek_music", ratio * dur)
			_canvas.queue_redraw()
			return


func _apply_vol_at_x(mx: float) -> void:
	for hb: Dictionary in _hitboxes:
		if str(hb.get("id", "")) == "vol":
			var r: Rect2 = hb.get("rect", Rect2())
			var ratio: float = clampf((mx - r.position.x) / maxf(1.0, r.size.x), 0.0, 1.0)
			_volume_pct = clampi(int(round(ratio * 100.0)), 0, 100)
			var am: Node = p.get_node_or_null("/root/AudioManager")
			if am != null and am.has_method("set_bus_volume_percent"):
				am.call("set_bus_volume_percent", "Music", _volume_pct)
			_canvas.queue_redraw()
			return


func _on_draw() -> void:
	if _canvas == null or not _canvas.visible:
		return
	var sz: Vector2 = _canvas.size
	if sz.x <= 40.0 or sz.y <= 40.0:
		return
	var font: Font = p.font
	if font == null:
		return

	_hitboxes.clear()
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color("#080C14"))

	var gap: float = 14.0
	var right_w: float = clampf(sz.x * 0.42, 320.0, 420.0)
	var left_w: float = sz.x - right_w - gap
	var left_rect := Rect2(0.0, 0.0, left_w, sz.y)
	var right_rect := Rect2(left_w + gap, 0.0, right_w, sz.y)

	_draw_left_panel(left_rect, font)
	_draw_right_panel(right_rect, font)


func _draw_left_panel(rect: Rect2, font: Font) -> void:
	_canvas.draw_rect(rect, COL_PANEL_BG)
	_canvas.draw_rect(rect, COL_BORDER, false, 1.0)

	var x: float = rect.position.x + 14.0
	var y: float = rect.position.y + 24.0
	var w: float = rect.size.x - 28.0

	var filtered: Array[int] = get_filtered_track_indices()
	var unlocked_cnt: int = 0
	for idx: int in filtered:
		if _is_track_unlocked(VaultModules.MUSIC_TRACKS[idx]):
			unlocked_cnt += 1

	_canvas.draw_string(font, Vector2(x, y), "MUSICBOX KERNEL // 22 PISTAS DAVIDKBD", HORIZONTAL_ALIGNMENT_LEFT, int(w * 0.72), 13, COL_PURPLE)
	_canvas.draw_string(font, Vector2(x, y), "%d/%d DESBLOQUEADAS" % [unlocked_cnt, filtered.size()], HORIZONTAL_ALIGNMENT_RIGHT, int(w), 11, COL_GREEN)

	# Filter chips
	var fy: float = y + 14.0
	var chip_labels: Array[String] = ["TODOS (22)", "PINK BLOOM (10)", "CODE INJECTION (12)"]
	var chip_w: float = (w - 12.0) / 3.0
	for i: int in range(chip_labels.size()):
		var cr := Rect2(x + float(i) * (chip_w + 6.0), fy, chip_w, 28.0)
		var act: bool = (p._music_filter_idx == i)
		_canvas.draw_rect(cr, Color("#182233") if act else COL_PANEL_ALT)
		_canvas.draw_rect(cr, COL_PINK if act else COL_BORDER, false, 1.0)
		_canvas.draw_string(font, Vector2(cr.position.x, cr.position.y + 18.0), chip_labels[i], HORIZONTAL_ALIGNMENT_CENTER, int(cr.size.x), 11, COL_TEXT if act else COL_MUTED)
		_hitboxes.append({"id": "filter_%d" % i, "val": i, "rect": cr})

	# Track rows
	var list_top: float = fy + 40.0
	var row_h: float = 36.0
	var list_h: float = rect.end.y - list_top - 26.0
	_visible_rows = maxi(4, int(floor(list_h / (row_h + 4.0))))
	_scroll_offset = clampi(_scroll_offset, 0, maxi(0, filtered.size() - _visible_rows))

	var ry: float = list_top
	for row_i: int in range(_scroll_offset, mini(filtered.size(), _scroll_offset + _visible_rows)):
		var t_idx: int = filtered[row_i]
		var tr: Dictionary = VaultModules.MUSIC_TRACKS[t_idx]
		var t_name: String = str(tr.get("name", ""))
		var t_dur: String = str(tr.get("duration", "0:00"))
		var unlocked: bool = _is_track_unlocked(tr)
		var sel: bool = (t_idx == p._selected_music_idx)
		var pinned: bool = (p._pinned_menu_track == t_name or p._pinned_game_track == t_name)

		var rr := Rect2(x, ry, w, row_h)
		_canvas.draw_rect(rr, Color("#172336") if sel else COL_PANEL_ALT)
		_canvas.draw_rect(rr, COL_PINK if sel else COL_BORDER, false, 1.0)
		if sel:
			_canvas.draw_rect(Rect2(rr.position.x, rr.position.y, 3.0, row_h), COL_PINK)

		var icon: String = ("♫ " if (sel and p._music_is_playing and unlocked) else ("▸ " if sel else "  "))
		var title_col: Color = COL_TEXT if unlocked else COL_MUTED
		_canvas.draw_string(font, Vector2(x + 10.0, ry + 22.0), "%s%02d. %s" % [icon, t_idx + 1, t_name], HORIZONTAL_ALIGNMENT_LEFT, int(w - 110.0), 12, title_col)

		var right_tag: String = ("[📌] " if pinned else "") + ("" if unlocked else "[🔒] ") + t_dur
		_canvas.draw_string(font, Vector2(x, ry + 22.0), right_tag, HORIZONTAL_ALIGNMENT_RIGHT, int(w - 10.0), 11, COL_CYAN if pinned else COL_MUTED)
		_hitboxes.append({"id": "track_%d" % t_idx, "val": t_idx, "rect": rr})
		ry += row_h + 4.0

	_canvas.draw_string(font, Vector2(x, rect.end.y - 8.0), "Rueda / ↑↓ navegar  •  Clic / [Espacio] reproducir", HORIZONTAL_ALIGNMENT_LEFT, int(w), 11, COL_MUTED)


func _draw_right_panel(rect: Rect2, font: Font) -> void:
	_canvas.draw_rect(rect, COL_PANEL_BG)
	_canvas.draw_rect(rect, COL_BORDER, false, 1.0)

	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	if p._selected_music_idx < 0 or p._selected_music_idx >= tracks.size():
		return
	var tr: Dictionary = tracks[p._selected_music_idx]
	var t_name: String = str(tr.get("name", "Pista"))
	var t_pack: String = str(tr.get("pack", "DavidKBD"))
	var t_dur_str: String = str(tr.get("duration", "0:00"))
	var unlocked: bool = _is_track_unlocked(tr)

	var x: float = rect.position.x + 16.0
	var y: float = rect.position.y + 28.0
	var w: float = rect.size.x - 32.0

	_canvas.draw_string(font, Vector2(x, y), t_name, HORIZONTAL_ALIGNMENT_CENTER, int(w), 16, COL_CYAN)
	_canvas.draw_string(font, Vector2(x, y + 20.0), "DavidKBD  //  Pack: " + t_pack, HORIZONTAL_ALIGNMENT_CENTER, int(w), 11, COL_MUTED)

	var status_txt: String = "▶ REPRODUCIENDO" if (p._music_is_playing and unlocked) else ("⏸ PAUSADO" if unlocked else "🔒 " + str(tr.get("unlock_req", "Bloqueada")))
	var status_col: Color = COL_GREEN if (p._music_is_playing and unlocked) else (COL_MUTED if unlocked else COL_AMBER)
	_canvas.draw_string(font, Vector2(x, y + 38.0), status_txt, HORIZONTAL_ALIGNMENT_CENTER, int(w), 11, status_col)

	# 32-Band FFT Spectrum Frame
	var fft_rect := Rect2(x, y + 52.0, w, 134.0)
	_canvas.draw_rect(fft_rect, Color("#070B12"))
	_canvas.draw_rect(fft_rect, COL_BORDER, false, 1.0)
	for g: int in range(1, 4):
		var gy: float = fft_rect.position.y + fft_rect.size.y * (float(g) / 4.0)
		_canvas.draw_line(Vector2(fft_rect.position.x + 4.0, gy), Vector2(fft_rect.end.x - 4.0, gy), Color("#131D2D"), 1.0)

	var inner_w: float = fft_rect.size.x - 16.0
	var step_w: float = inner_w / float(BAND_COUNT)
	var bar_w: float = maxf(3.0, step_w - 3.0)
	var base_y: float = fft_rect.end.y - 8.0
	var max_h: float = fft_rect.size.y - 18.0
	for b: int in range(BAND_COUNT):
		var bx: float = fft_rect.position.x + 8.0 + float(b) * step_w
		var ratio: float = float(b) / float(BAND_COUNT - 1)
		var bcol: Color = COL_PINK.lerp(COL_PURPLE, clampf(ratio * 1.6, 0.0, 1.0)) if ratio < 0.5 else COL_PURPLE.lerp(COL_CYAN, clampf((ratio - 0.5) * 2.0, 0.0, 1.0))
		var bh: float = maxf(2.0, _fft_smooth[b] * max_h)
		_canvas.draw_rect(Rect2(bx, base_y - bh, bar_w, bh), bcol)
		var ph: float = _fft_peaks[b] * max_h
		if ph > 4.0:
			_canvas.draw_rect(Rect2(bx, base_y - ph - 2.0, bar_w, 2.0), Color("#EAECF5"))

	# Seek Bar
	var cur_pos: float = 0.0
	var dur_sec: float = 0.0
	var am: Node = p.get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("get_music_playback_position") and am.has_method("get_music_duration"):
		cur_pos = float(am.call("get_music_playback_position"))
		dur_sec = float(am.call("get_music_duration"))
	var seek_ratio: float = clampf(cur_pos / dur_sec, 0.0, 1.0) if dur_sec > 0.1 else 0.0

	var sy: float = fft_rect.end.y + 18.0
	var seek_rect := Rect2(x, sy, w, 10.0)
	_canvas.draw_rect(seek_rect, Color("#151F2E"))
	_canvas.draw_rect(Rect2(x, sy, w * seek_ratio, 10.0), COL_PINK)
	_canvas.draw_rect(seek_rect, COL_BORDER, false, 1.0)
	_hitboxes.append({"id": "seek", "rect": Rect2(x, sy - 6.0, w, 22.0)})

	var time_str: String = "%s / %s" % [_fmt_sec(cur_pos), _fmt_sec(dur_sec) if dur_sec > 0.1 else t_dur_str]
	_canvas.draw_string(font, Vector2(x, sy + 26.0), time_str, HORIZONTAL_ALIGNMENT_CENTER, int(w), 11, COL_MUTED)

	# Transport Controls
	var ty: float = sy + 38.0
	var btn_w: float = (w - 16.0) / 3.0
	var trans_defs: Array[Array] = [
		["prev", "|< ANT", COL_TEXT],
		["play", ("⏸ PAUSAR" if (p._music_is_playing and unlocked) else "▶ REPRODUCIR"), COL_GREEN if unlocked else COL_MUTED],
		["next", "SIG >|", COL_TEXT],
	]
	for i: int in range(trans_defs.size()):
		var br := Rect2(x + float(i) * (btn_w + 8.0), ty, btn_w, 34.0)
		_canvas.draw_rect(br, COL_PANEL_ALT)
		_canvas.draw_rect(br, COL_CYAN if i == 1 and unlocked else COL_BORDER, false, 1.0)
		_canvas.draw_string(font, Vector2(br.position.x, br.position.y + 21.0), str(trans_defs[i][1]), HORIZONTAL_ALIGNMENT_CENTER, int(br.size.x), 11, trans_defs[i][2])
		_hitboxes.append({"id": str(trans_defs[i][0]), "rect": br})

	# Volume Slider
	var vy: float = ty + 52.0
	_canvas.draw_string(font, Vector2(x, vy), "VOLUMEN MÚSICA: %d%%" % _volume_pct, HORIZONTAL_ALIGNMENT_LEFT, int(w), 11, COL_MUTED)
	var vol_rect := Rect2(x, vy + 8.0, w, 10.0)
	_canvas.draw_rect(vol_rect, Color("#151F2E"))
	_canvas.draw_rect(Rect2(x, vy + 8.0, w * (float(_volume_pct) / 100.0), 10.0), COL_CYAN)
	_canvas.draw_rect(vol_rect, COL_BORDER, false, 1.0)
	_hitboxes.append({"id": "vol", "rect": Rect2(x, vy + 2.0, w, 22.0)})

	# Pin Controls
	var py: float = vy + 36.0
	var pin_w: float = (w - 8.0) * 0.5
	var menu_pin: bool = (p._pinned_menu_track == t_name)
	var game_pin: bool = (p._pinned_game_track == t_name)

	var pm_rect := Rect2(x, py, pin_w, 38.0)
	_canvas.draw_rect(pm_rect, Color("#182233") if menu_pin else COL_PANEL_ALT)
	_canvas.draw_rect(pm_rect, COL_CYAN if menu_pin else COL_BORDER, false, 1.0)
	_canvas.draw_string(font, Vector2(pm_rect.position.x, pm_rect.position.y + 23.0), "✓ FIJADA EN MENÚ" if menu_pin else "📌 FIJAR EN MENÚ", HORIZONTAL_ALIGNMENT_CENTER, int(pin_w), 11, COL_CYAN if menu_pin else COL_TEXT)
	_hitboxes.append({"id": "pin_menu", "rect": pm_rect})

	var pg_rect := Rect2(x + pin_w + 8.0, py, pin_w, 38.0)
	_canvas.draw_rect(pg_rect, Color("#182233") if game_pin else COL_PANEL_ALT)
	_canvas.draw_rect(pg_rect, COL_CYAN if game_pin else COL_BORDER, false, 1.0)
	_canvas.draw_string(font, Vector2(pg_rect.position.x, pg_rect.position.y + 23.0), "✓ FIJADA EN PARTIDA" if game_pin else "📌 FIJAR EN PARTIDA", HORIZONTAL_ALIGNMENT_CENTER, int(pin_w), 11, COL_CYAN if game_pin else COL_TEXT)
	_hitboxes.append({"id": "pin_game", "rect": pg_rect})


func _fmt_sec(sec: float) -> String:
	var s: int = maxi(0, int(floor(sec)))
	return "%02d:%02d" % [s / 60, s % 60]
