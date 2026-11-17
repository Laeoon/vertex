extends RefCounted

## Tab 02 // ARCHIVOS .ENC: Termlink hex matrix minigame + dossier viewer.
## Extracted from escenas/menu/profile.gd. State lives on the Profile orchestrator (`p`).

const BrandClass = preload("res://juego/ui/brand.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

var p: Profile


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	_build_tab_termlink(container)


func _build_tab_termlink(container: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	var left_vb := VBoxContainer.new()
	left_vb.name = "TermlinkLeft"
	left_vb.custom_minimum_size = Vector2(260, 0)
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 8)
	hbox.add_child(left_vb)

	var enc_files: Array[Dictionary] = VaultModules.ENC_FILES
	for ef_idx in range(enc_files.size()):
		var ef: Dictionary = enc_files[ef_idx]
		var fname: String = str(ef.get("file", "EXP.ENC"))
		var unlocked: bool = p._enc_unlocked.has(ef_idx)

		var btn := Button.new()
		btn.name = "EncBtn_%d" % ef_idx
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = fname + "\n" + ("[✓ DESBLOQUEADO]" if unlocked else "[🔒 CIFRADO]")
		btn.add_theme_font_size_override("font_size", 11)
		btn.clip_text = true

		var is_sel: bool = (ef_idx == p._selected_enc_idx)
		var left_col: Color = BrandClass.SUCCESS if is_sel else Color.TRANSPARENT
		btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))

		var captured_ef: int = ef_idx
		btn.pressed.connect(func() -> void:
			p._selected_enc_idx = captured_ef
			p._enc_attempts = 4
			p._removed_duds.clear()
			var sel_ef: Dictionary = enc_files[captured_ef]
			p._enc_console_lines = ["VERTEX // KERNEL_LINK TERMLINK v4.08 — " + str(sel_ef.get("file", ""))]
			p._play_click_sfx()
			_refresh_termlink_right(container)
		)
		left_vb.add_child(btn)

	var meta_panel := PanelContainer.new()
	meta_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meta_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#141C26"), Color("#1E2736")))
	left_vb.add_child(meta_panel)

	var meta_mc := MarginContainer.new()
	meta_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	meta_mc.add_theme_constant_override("margin_left", 10)
	meta_mc.add_theme_constant_override("margin_top", 10)
	meta_mc.add_theme_constant_override("margin_right", 10)
	meta_mc.add_theme_constant_override("margin_bottom", 10)
	meta_panel.add_child(meta_mc)

	var meta_lbl := Label.new()
	meta_lbl.name = "TermlinkMetaLbl"
	meta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_lbl.add_theme_font_size_override("font_size", 11)
	meta_lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	meta_mc.add_child(meta_lbl)

	var right_vb := VBoxContainer.new()
	right_vb.name = "TermlinkRight"
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 8)
	hbox.add_child(right_vb)

	_refresh_termlink_right(container)


func _refresh_termlink_right(container: Control) -> void:
	var enc_files: Array[Dictionary] = VaultModules.ENC_FILES
	if p._selected_enc_idx < 0 or p._selected_enc_idx >= enc_files.size():
		return
	var ef: Dictionary = enc_files[p._selected_enc_idx]
	var unlocked: bool = p._enc_unlocked.has(p._selected_enc_idx)

	for ef_idx in range(enc_files.size()):
		var btn := container.find_child("EncBtn_%d" % ef_idx, true, false) as Button
		if btn != null:
			var ef_item: Dictionary = enc_files[ef_idx]
			var item_unlocked: bool = p._enc_unlocked.has(ef_idx)
			btn.text = str(ef_item.get("file", "EXP.ENC")) + "\n" + ("[✓ DESBLOQUEADO]" if item_unlocked else "[🔒 CIFRADO]")
			var is_sel: bool = (ef_idx == p._selected_enc_idx)
			var left_col: Color = BrandClass.SUCCESS if is_sel else Color.TRANSPARENT
			btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#182230") if is_sel else Color("#141C26"), Color("#1E2736"), left_col))
			btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))
			btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))

	var meta_lbl := container.find_child("TermlinkMetaLbl", true, false) as Label
	if meta_lbl != null:
		meta_lbl.text = "METADATOS DEL ARCHIVO\n\nPeso: %s\nCifrado: %s\nHash: %s\nEstado: %s\nVFS: /home/operator/expedientes/" % [
			str(ef.get("weight", "48.4 KB")),
			str(ef.get("cipher", "AES-512-SHAMIR")),
			str(ef.get("hash", "0x9F4A..8E21")),
			("[DESBLOQUEADO]" if unlocked else "[CIFRADO]"),
		]

	var right_vb := container.find_child("TermlinkRight", true, false) as VBoxContainer
	if right_vb == null:
		return
	for child in right_vb.get_children():
		child.queue_free()

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	right_vb.add_child(top_bar)

	var title_lbl := Label.new()
	title_lbl.text = "TERMLINK // " + str(ef.get("file", ""))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", BrandClass.ACCENT)
	top_bar.add_child(title_lbl)

	var attempts_lbl := Label.new()
	attempts_lbl.text = "INTENTOS: " + ("▮".repeat(p._enc_attempts))
	attempts_lbl.add_theme_font_size_override("font_size", 12)
	attempts_lbl.add_theme_color_override("font_color", BrandClass.WARNING)
	top_bar.add_child(attempts_lbl)

	var sel_preview_lbl := Label.new()
	sel_preview_lbl.text = "> SELECCIÓN: ---"
	sel_preview_lbl.name = "SelPreviewLbl"
	sel_preview_lbl.add_theme_font_size_override("font_size", 12)
	sel_preview_lbl.add_theme_color_override("font_color", BrandClass.SUCCESS)
	top_bar.add_child(sel_preview_lbl)

	if not unlocked:
		var hex_grid := GridContainer.new()
		hex_grid.columns = 2
		hex_grid.add_theme_constant_override("h_separation", 8)
		hex_grid.add_theme_constant_override("v_separation", 4)
		hex_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hex_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		right_vb.add_child(hex_grid)

		var rows: Array[Dictionary] = VaultModules.build_hex_dump_rows(p._selected_enc_idx, p._removed_duds)
		var target_pass: String = str(ef.get("pass", "DIJKSTRA"))

		for r_idx in range(rows.size()):
			var row_data: Dictionary = rows[r_idx]
			var addr_str: String = str(row_data.get("addr", "0x7F40"))
			var raw_str: String = str(row_data.get("raw", ""))
			var token_str: String = str(row_data.get("token", ""))
			var token_type: String = str(row_data.get("token_type", ""))

			var row_btn := Button.new()
			row_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row_btn.custom_minimum_size = Vector2(0, 24)
			row_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row_btn.text = addr_str + "  " + raw_str
			row_btn.add_theme_font_override("font", p.font)
			row_btn.add_theme_font_size_override("font_size", 13)
			var base_col: Color = BrandClass.ACCENT if token_type == "word" else (BrandClass.WARNING if token_type == "trap" else BrandClass.TEXT_DIM)
			row_btn.add_theme_color_override("font_color", base_col)
			row_btn.add_theme_color_override("font_hover_color", Color("#06080B"))
			row_btn.add_theme_color_override("font_pressed_color", Color("#06080B"))
			row_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#0E131A")))
			row_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#00F0FF")))
			row_btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#00F0FF")))

			row_btn.mouse_entered.connect(func() -> void:
				var sp_lbl := right_vb.find_child("SelPreviewLbl", true, false) as Label
				if sp_lbl != null:
					sp_lbl.text = "> SELECCIÓN: " + (token_str if token_str != "" else addr_str)
			)

			row_btn.pressed.connect(func() -> void:
				p._play_click_sfx()
				if token_type == "word":
					if token_str == target_pass:
						p._enc_unlocked[p._selected_enc_idx] = true
						p._enc_console_lines.append("> ACCESO CONCEDIDO: " + token_str)
						if p._shell_engine != null and p._shell_engine.vfs != null:
							var base_name: String = str(ef.get("file", "exp.enc")).replace(".enc", ".txt")
							var vfs_path: String = "/home/operator/expedientes/" + base_name
							var full_txt: String = "CLASIFICACIÓN: %s\nOBJETIVO: %s\nAFILIACIÓN: %s\n\n%s" % [
								str(ef.get("classification", "")),
								str(ef.get("target", "")),
								str(ef.get("affiliation", "")),
								str(ef.get("content", ""))
							]
							p._shell_engine.vfs._fs[vfs_path] = {"type": "file", "content": full_txt, "perms": "-rw-r--r--"}
							if p._shell_engine.vfs._fs.has("/home/operator/expedientes"):
								var dir_node: Dictionary = p._shell_engine.vfs._fs["/home/operator/expedientes"]
								var children: Array = dir_node.get("children", [])
								if not children.has(base_name):
									children.append(base_name)
						p._save_profile()
						_refresh_termlink_right(container)
					else:
						var match_count: int = VaultModules.compute_likeness(token_str, target_pass)
						p._enc_attempts -= 1
						p._enc_console_lines.append("> ACCESO DENEGADO (%s): COINCIDENCIA %d/%d" % [token_str, match_count, target_pass.length()])
						if p._enc_attempts <= 0:
							p._enc_attempts = 4
							p._removed_duds.clear()
							p._enc_console_lines.append("> BLOQUEO DE TERMINAL REINICIADO.")
						_refresh_termlink_right(container)
				elif token_type == "trap":
					var decoy_to_remove: String = ""
					for check_row: Dictionary in rows:
						if str(check_row.get("token_type", "")) == "word":
							var cand: String = str(check_row.get("token", ""))
							if cand != "" and cand != target_pass and not p._removed_duds.has(cand):
								decoy_to_remove = cand
								break
					if decoy_to_remove != "" and randf() > 0.35:
						p._removed_duds.append(decoy_to_remove)
						p._enc_console_lines.append("> TRAMPA ACTIVADA: PALABRA FALSA ELIMINADA (%s)" % decoy_to_remove)
					else:
						p._enc_attempts = 4
						p._enc_console_lines.append("> TRAMPA ACTIVADA: INTENTOS RESTAURADOS A 4")
					_refresh_termlink_right(container)
				else:
					p._enc_console_lines.append("> MEMORIA NULA EN " + addr_str)
					_refresh_termlink_right(container)
			)
			hex_grid.add_child(row_btn)
	else:
		var dossier_panel := PanelContainer.new()
		dossier_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dossier_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		dossier_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#06080B"), Color("#1E2736")))
		right_vb.add_child(dossier_panel)

		var dossier_mc := MarginContainer.new()
		dossier_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
		dossier_mc.add_theme_constant_override("margin_left", 14)
		dossier_mc.add_theme_constant_override("margin_top", 12)
		dossier_mc.add_theme_constant_override("margin_right", 14)
		dossier_mc.add_theme_constant_override("margin_bottom", 12)
		dossier_panel.add_child(dossier_mc)

		var dossier_rtl := RichTextLabel.new()
		dossier_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dossier_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		dossier_rtl.bbcode_enabled = true
		var fname_txt: String = str(ef.get("file", "")).replace(".enc", ".txt")
		dossier_rtl.text = "[color=#00F0FF][b]EXPEDIENTE DESENCRIPTADO // %s[/b][/color]\n[color=#FFC857]CLASIFICACIÓN:[/color] %s   [color=#FFC857]OBJETIVO:[/color] %s\n[color=#FFC857]AFILIACIÓN:[/color] %s\n[color=#39FF14][✓ Montado en VFS: /home/operator/expedientes/%s][/color]\n\n%s" % [
			str(ef.get("title", ef.get("file", ""))),
			str(ef.get("classification", "")),
			str(ef.get("target", "")),
			str(ef.get("affiliation", "")),
			fname_txt,
			str(ef.get("content", "Sin información."))
		]
		dossier_rtl.add_theme_color_override("default_color", BrandClass.TEXT)
		dossier_mc.add_child(dossier_rtl)

		var back_mat_btn := Button.new()
		back_mat_btn.custom_minimum_size = Vector2(0, 44)
		back_mat_btn.text = "[ ↻ RE-HACKEAR SIMULACIÓN ]"
		back_mat_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26"), BrandClass.ACCENT))
		back_mat_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#1E2736"), BrandClass.ACCENT))
		back_mat_btn.add_theme_color_override("font_color", BrandClass.ACCENT)
		back_mat_btn.pressed.connect(func() -> void:
			p._enc_unlocked.erase(p._selected_enc_idx)
			p._enc_attempts = 4
			p._removed_duds.clear()
			p._enc_console_lines = ["VERTEX // KERNEL_LINK TERMLINK v4.08 — RE-SIMULACIÓN INICIADA"]
			p._play_click_sfx()
			_refresh_termlink_right(container)
		)
		right_vb.add_child(back_mat_btn)

	var log_rtl := RichTextLabel.new()
	log_rtl.custom_minimum_size = Vector2(0, 72)
	log_rtl.bbcode_enabled = true
	log_rtl.scroll_following = true
	log_rtl.text = "\n".join(p._enc_console_lines)
	log_rtl.add_theme_color_override("default_color", BrandClass.SUCCESS)
	log_rtl.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#06080B"), Color("#1E2736")))
	right_vb.add_child(log_rtl)
