extends RefCounted

## Tab 04 // MUSICBOX: pack filters, track list, player and pins.
## Extracted from escenas/menu/profile.gd. State lives on the Profile orchestrator (`p`).

const BrandClass = preload("res://juego/ui/brand.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

var p: Profile


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	_build_tab_musicbox(container)


func _build_tab_musicbox(container: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 8)
	hbox.add_child(left_vb)

	var top_info_lbl := Label.new()
	top_info_lbl.text = "MUSICBOX KERNEL // 22 PISTAS"
	top_info_lbl.add_theme_font_size_override("font_size", 12)
	top_info_lbl.add_theme_color_override("font_color", Color("bf5af2"))
	left_vb.add_child(top_info_lbl)

	var filter_hb := HBoxContainer.new()
	filter_hb.add_theme_constant_override("separation", 6)
	left_vb.add_child(filter_hb)

	var filters: Array[String] = ["TODOS (22)", "PINK BLOOM (10)", "CODE INJECTION (12)"]
	for f_idx in range(filters.size()):
		var f_name: String = filters[f_idx]
		var f_btn := Button.new()
		f_btn.text = f_name
		f_btn.custom_minimum_size = Vector2(0, 32)
		var is_f_act: bool = (f_idx == p._music_filter_idx)
		f_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26"), Color("#1E2736") if is_f_act else Color.TRANSPARENT, Color("#B026FF") if is_f_act else Color.TRANSPARENT))
		f_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736")))
		f_btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736")))

		var captured_f: int = f_idx
		f_btn.pressed.connect(func() -> void:
			p._music_filter_idx = captured_f
			p._play_click_sfx()
			_refresh_musicbox_tracks(container)
		)
		filter_hb.add_child(f_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_child(scroll)

	var tracks_vb := VBoxContainer.new()
	tracks_vb.name = "TracksVBox"
	tracks_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tracks_vb.add_theme_constant_override("separation", 4)
	scroll.add_child(tracks_vb)

	var right_panel := PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(330, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#141C26"), Color("#1E2736")))
	hbox.add_child(right_panel)

	var r_mc := MarginContainer.new()
	r_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	r_mc.add_theme_constant_override("margin_left", 12)
	r_mc.add_theme_constant_override("margin_top", 12)
	r_mc.add_theme_constant_override("margin_right", 12)
	r_mc.add_theme_constant_override("margin_bottom", 12)
	right_panel.add_child(r_mc)

	var r_vb := VBoxContainer.new()
	r_vb.name = "MusicRightVBox"
	r_vb.add_theme_constant_override("separation", 10)
	r_mc.add_child(r_vb)

	_refresh_musicbox_tracks(container)
	_refresh_musicbox_right(container)


func _refresh_musicbox_tracks(container: Control) -> void:
	var scroll := container.find_child("TracksVBox", true, false) as VBoxContainer
	if scroll == null:
		return
	for child in scroll.get_children():
		child.queue_free()

	var unlocked_badges: Array = p.stats.get("badges", [])
	var decrypted_enc: Array = p.stats.get("decrypted_enc_files", [])
	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	for t_idx in range(tracks.size()):
		var tr: Dictionary = tracks[t_idx]
		var t_pack: String = str(tr.get("pack", ""))
		if p._music_filter_idx == 1 and t_pack != "Pink Bloom":
			continue
		if p._music_filter_idx == 2 and t_pack != "Code Injection":
			continue

		var t_name: String = str(tr.get("name", "Track"))
		var t_dur: String = str(tr.get("duration", "0:00"))
		var is_unlocked: bool = VaultModules.is_track_unlocked(tr, unlocked_badges, decrypted_enc, p.progress)
		var is_sel: bool = (t_idx == p._selected_music_idx)
		var is_pinned: bool = (p._pinned_menu_track == t_name or p._pinned_game_track == t_name)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = ""

		var left_col: Color = Color("#B026FF") if is_sel else Color.TRANSPARENT
		btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#182230") if is_sel else Color("#141C26"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))

		var row_mc := MarginContainer.new()
		row_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
		row_mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_mc.add_theme_constant_override("margin_left", 12)
		row_mc.add_theme_constant_override("margin_right", 12)
		btn.add_child(row_mc)

		var row_hb := HBoxContainer.new()
		row_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_hb.add_theme_constant_override("separation", 8)
		row_mc.add_child(row_hb)

		var name_lbl := Label.new()
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_text = true
		name_lbl.text = "%02d. %s" % [t_idx + 1, t_name]
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", BrandClass.TEXT if is_unlocked else BrandClass.TEXT_DIM)
		row_hb.add_child(name_lbl)

		var right_lbl := Label.new()
		right_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tags: String = ("[📌] " if is_pinned else "") + ("" if is_unlocked else "[🔒] ")
		right_lbl.text = tags + t_dur
		right_lbl.add_theme_font_size_override("font_size", 11)
		right_lbl.add_theme_color_override("font_color", BrandClass.ACCENT if is_pinned else BrandClass.TEXT_DIM)
		row_hb.add_child(right_lbl)

		var captured_t: int = t_idx
		var captured_unlocked: bool = is_unlocked
		var captured_path: String = str(tr.get("path", ""))
		btn.pressed.connect(func() -> void:
			p._selected_music_idx = captured_t
			p._play_click_sfx()
			if captured_unlocked and captured_path != "":
				p._music_is_playing = true
				var am = p.get_node_or_null("/root/AudioManager")
				if am != null and am.has_method("play_track"):
					am.play_track(captured_path)
			_refresh_musicbox_tracks(container)
			_refresh_musicbox_right(container)
		)
		scroll.add_child(btn)


func _refresh_musicbox_right(container: Control) -> void:
	var r_vb := container.find_child("MusicRightVBox", true, false) as VBoxContainer
	if r_vb == null:
		return
	for child in r_vb.get_children():
		child.queue_free()

	var tracks: Array[Dictionary] = VaultModules.MUSIC_TRACKS
	if p._selected_music_idx < 0 or p._selected_music_idx >= tracks.size():
		return
	var tr: Dictionary = tracks[p._selected_music_idx]
	var t_name: String = str(tr.get("name", "Pista"))
	var t_pack: String = str(tr.get("pack", "DavidKBD"))
	var t_dur: String = str(tr.get("duration", "03:42"))
	var unlocked_badges: Array = p.stats.get("badges", [])
	var decrypted_enc: Array = p.stats.get("decrypted_enc_files", [])
	var is_unlocked: bool = VaultModules.is_track_unlocked(tr, unlocked_badges, decrypted_enc, p.progress)

	var title_lbl := Label.new()
	title_lbl.text = t_name
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", BrandClass.ACCENT)
	r_vb.add_child(title_lbl)

	var pack_lbl := Label.new()
	pack_lbl.text = "Autor: DavidKBD // Pack: " + t_pack
	pack_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pack_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pack_lbl.add_theme_font_size_override("font_size", 11)
	pack_lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	r_vb.add_child(pack_lbl)

	var eq_control := Control.new()
	eq_control.custom_minimum_size = Vector2(0, 76)
	p._eq_control = eq_control
	eq_control.draw.connect(func() -> void:
		var mags: PackedFloat32Array = PackedFloat32Array()
		var am = p.get_node_or_null("/root/AudioManager")
		if am != null and am.has_method("get_spectrum_magnitudes"):
			mags = am.get_spectrum_magnitudes(28)
		ProfileRendererClass.draw_equalizer(eq_control, Rect2(Vector2.ZERO, eq_control.size), mags, p._music_is_playing and is_unlocked, p._pulse)
	)
	r_vb.add_child(eq_control)

	if not is_unlocked:
		var req_lbl := Label.new()
		req_lbl.text = "[🔒] " + str(tr.get("unlock_req", "Bloqueada"))
		req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		req_lbl.add_theme_font_size_override("font_size", 11)
		req_lbl.add_theme_color_override("font_color", BrandClass.WARNING)
		r_vb.add_child(req_lbl)

	var seek_slider := HSlider.new()
	seek_slider.value = 0.0 if not is_unlocked else 35.0
	r_vb.add_child(seek_slider)

	var timer_lbl := Label.new()
	timer_lbl.text = "00:00 / " + t_dur
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_font_size_override("font_size", 10)
	timer_lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	r_vb.add_child(timer_lbl)

	var trans_hb := HBoxContainer.new()
	trans_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	trans_hb.add_theme_constant_override("separation", 12)
	r_vb.add_child(trans_hb)

	var prev_btn := Button.new()
	prev_btn.text = " [ |< ] "
	prev_btn.pressed.connect(func() -> void:
		p._selected_music_idx = posmod(p._selected_music_idx - 1, tracks.size())
		p._play_click_sfx()
		_refresh_musicbox_tracks(container)
		_refresh_musicbox_right(container)
	)
	trans_hb.add_child(prev_btn)

	var play_btn := Button.new()
	play_btn.text = " [ ⏸ PAUSAR ] " if (p._music_is_playing and is_unlocked) else " [ ▶ REPRODUCIR ] "
	play_btn.pressed.connect(func() -> void:
		p._play_click_sfx()
		if not is_unlocked:
			return
		p._music_is_playing = not p._music_is_playing
		var am = p.get_node_or_null("/root/AudioManager")
		if am != null:
			if p._music_is_playing and am.has_method("play_track"):
				am.play_track(str(tr.get("path", "")))
			elif not p._music_is_playing and am.has_method("stop_music"):
				am.stop_music()
		_refresh_musicbox_right(container)
	)
	trans_hb.add_child(play_btn)

	var next_btn := Button.new()
	next_btn.text = " [ >| ] "
	next_btn.pressed.connect(func() -> void:
		p._selected_music_idx = posmod(p._selected_music_idx + 1, tracks.size())
		p._play_click_sfx()
		_refresh_musicbox_tracks(container)
		_refresh_musicbox_right(container)
	)
	trans_hb.add_child(next_btn)

	var vol_slider := HSlider.new()
	vol_slider.value = 80.0
	vol_slider.value_changed.connect(func(v: float) -> void:
		var idx_bus: int = AudioServer.get_bus_index("Music")
		if idx_bus >= 0:
			AudioServer.set_bus_volume_db(idx_bus, linear_to_db(clampf(v / 100.0, 0.01, 1.0)))
	)
	r_vb.add_child(vol_slider)

	var pin_hb := HBoxContainer.new()
	pin_hb.add_theme_constant_override("separation", 8)
	r_vb.add_child(pin_hb)

	var is_menu_pinned: bool = (p._pinned_menu_track == t_name)
	var pin_menu_btn := Button.new()
	pin_menu_btn.text = "[ ✓ FIJADA EN MENÚ ]" if is_menu_pinned else "[ 📌 FIJAR EN MENÚ ]"
	pin_menu_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pin_menu_btn.custom_minimum_size = Vector2(0, 44)
	pin_menu_btn.add_theme_font_size_override("font_size", 11)
	if is_menu_pinned:
		pin_menu_btn.add_theme_color_override("font_color", BrandClass.ACCENT)
		pin_menu_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#182230"), BrandClass.ACCENT))
	pin_menu_btn.pressed.connect(func() -> void:
		p._pinned_menu_track = t_name
		p._play_click_sfx()
		p._save_profile()
		_refresh_musicbox_tracks(container)
		_refresh_musicbox_right(container)
	)
	pin_hb.add_child(pin_menu_btn)

	var is_game_pinned: bool = (p._pinned_game_track == t_name)
	var pin_game_btn := Button.new()
	pin_game_btn.text = "[ ✓ FIJADA EN PARTIDA ]" if is_game_pinned else "[ 📌 FIJAR EN PARTIDA ]"
	pin_game_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pin_game_btn.custom_minimum_size = Vector2(0, 44)
	pin_game_btn.add_theme_font_size_override("font_size", 11)
	if is_game_pinned:
		pin_game_btn.add_theme_color_override("font_color", BrandClass.ACCENT)
		pin_game_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#182230"), BrandClass.ACCENT))
	pin_game_btn.pressed.connect(func() -> void:
		p._pinned_game_track = t_name
		p._play_click_sfx()
		p._save_profile()
		_refresh_musicbox_tracks(container)
		_refresh_musicbox_right(container)
	)
	pin_hb.add_child(pin_game_btn)
