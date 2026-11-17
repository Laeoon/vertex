extends RefCounted

## Tab 03 // ACADEMIA CLI: lab guide + bash terminal (history, TAB completion).
## Extracted from escenas/menu/profile.gd. State lives on the Profile orchestrator (`p`).

const BrandClass = preload("res://juego/ui/brand.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

var p: Profile


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	_build_tab_academia(container)


func _build_tab_academia(container: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(300, 0)
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 8)
	hbox.add_child(left_vb)

	var lessons: Array[Dictionary] = VaultModules.TERMINAL_ACADEMY_LESSONS
	for c_idx in range(lessons.size()):
		var lesson: Dictionary = lessons[c_idx]
		var c_name: String = str(lesson.get("title", "Módulo %d" % (c_idx + 1)))
		var btn := Button.new()
		btn.name = "CliCourseBtn_%d" % c_idx
		btn.custom_minimum_size = Vector2(0, 44)
		btn.text = c_name
		btn.clip_text = true
		btn.add_theme_font_size_override("font_size", 11)
		var is_act: bool = (c_idx == p._active_cli_course)
		var left_col: Color = BrandClass.WARNING if is_act else Color.TRANSPARENT
		btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))

		var captured_c: int = c_idx
		btn.pressed.connect(func() -> void:
			p.start_cli_course(captured_c)
			p._play_click_sfx()
			_refresh_academia_right(container)
		)
		left_vb.add_child(btn)

	var guide_panel := PanelContainer.new()
	guide_panel.name = "GuidePanel"
	guide_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guide_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#141C26"), Color("#1E2736")))
	left_vb.add_child(guide_panel)

	var guide_mc := MarginContainer.new()
	guide_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide_mc.add_theme_constant_override("margin_left", 10)
	guide_mc.add_theme_constant_override("margin_top", 10)
	guide_mc.add_theme_constant_override("margin_right", 10)
	guide_mc.add_theme_constant_override("margin_bottom", 10)
	guide_panel.add_child(guide_mc)

	var guide_vb := VBoxContainer.new()
	guide_vb.name = "GuideVBox"
	guide_vb.add_theme_constant_override("separation", 6)
	guide_mc.add_child(guide_vb)

	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#06080B"), Color("#1E2736")))
	hbox.add_child(right_panel)

	var right_mc := MarginContainer.new()
	right_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_mc.add_theme_constant_override("margin_left", 0)
	right_mc.add_theme_constant_override("margin_top", 0)
	right_mc.add_theme_constant_override("margin_right", 0)
	right_mc.add_theme_constant_override("margin_bottom", 0)
	right_panel.add_child(right_mc)

	var right_vb := VBoxContainer.new()
	right_vb.name = "AcademiaRightVBox"
	right_vb.add_theme_constant_override("separation", 0)
	right_mc.add_child(right_vb)

	_refresh_academia_right(container)


func _format_cli_line_bbcode(line: String) -> String:
	var safe: String = line.replace("[", "[lb]")
	if safe.begins_with("operator@vertex-vault:"):
		return "[color=#39FF14]" + safe + "[/color]"
	if safe.contains("Error") or safe.contains("FAIL") or safe.contains("no encontrado") or safe.contains("permiso denegado") or safe.contains("Unknown"):
		return "[color=#FF4D4D]" + safe + "[/color]"
	if safe.contains("[✓") or safe.contains("completado") or safe.contains("OK"):
		return "[color=#39FF14]" + safe + "[/color]"
	if safe.contains(".enc") or safe.contains(".txt") or safe.contains(".b64"):
		return "[color=#FFB000]" + safe + "[/color]"
	if safe.contains("/home/") or safe.contains("/etc/") or safe.contains("/var/") or safe.contains("/srv/") or safe.contains("/proc/") or safe.begins_with("d"):
		return "[color=#00F0FF]" + safe + "[/color]"
	return safe


func _refresh_academia_right(container: Control) -> void:
	var lessons: Array[Dictionary] = VaultModules.TERMINAL_ACADEMY_LESSONS
	for c_idx in range(lessons.size()):
		var c_btn := container.find_child("CliCourseBtn_%d" % c_idx, true, false) as Button
		if c_btn != null:
			var is_act: bool = (c_idx == p._active_cli_course)
			var left_col: Color = BrandClass.WARNING if is_act else Color.TRANSPARENT
			c_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#182230") if is_act else Color("#141C26"), Color("#1E2736"), left_col))
			c_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))
			c_btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))

	var lesson: Dictionary = lessons[clampi(p._active_cli_course, 0, lessons.size() - 1)]
	var steps: Array = lesson.get("steps", [])

	var guide_panel := container.find_child("GuidePanel", true, false) as PanelContainer
	if guide_panel != null:
		var guide_vb := guide_panel.find_child("GuideVBox", true, false) as VBoxContainer
		if guide_vb != null:
			for child in guide_vb.get_children():
				child.queue_free()

			var obj_lbl := Label.new()
			var cur_step_txt: String = str(steps[p._cli_course_step].get("instruction", "Módulo completado")) if p._cli_course_step < steps.size() else "Módulo completado"
			obj_lbl.text = "OBJETIVO:\n%s\n\n%s" % [str(lesson.get("objective", "")), cur_step_txt]
			obj_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			obj_lbl.add_theme_font_size_override("font_size", 12)
			obj_lbl.add_theme_color_override("font_color", BrandClass.WARNING)
			guide_vb.add_child(obj_lbl)

			var cheat_lbl := Label.new()
			cheat_lbl.text = "SINTAXIS:\n%s\nTip: %s" % [str(lesson.get("commands", "")), str(lesson.get("hint", ""))]
			cheat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cheat_lbl.add_theme_font_size_override("font_size", 12)
			cheat_lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
			guide_vb.add_child(cheat_lbl)

			var check_lines: Array[String] = ["CHECKLIST:"]
			for s_idx in range(steps.size()):
				var st_dict: Dictionary = steps[s_idx]
				var mark: String = "[✓]" if s_idx < p._cli_course_step else "[ ]"
				check_lines.append("%s Paso %d: %s" % [mark, s_idx + 1, str(st_dict.get("expected_cmd", ""))])
			var steps_lbl := Label.new()
			steps_lbl.text = "\n".join(check_lines)
			steps_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			steps_lbl.add_theme_font_size_override("font_size", 12)
			steps_lbl.add_theme_color_override("font_color", BrandClass.SUCCESS)
			guide_vb.add_child(steps_lbl)

	var right_vb := container.find_child("AcademiaRightVBox", true, false) as VBoxContainer
	if right_vb != null:
		for child in right_vb.get_children():
			child.queue_free()

		var status_bar := PanelContainer.new()
		status_bar.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#111822")))
		right_vb.add_child(status_bar)

		var status_mc := MarginContainer.new()
		status_mc.add_theme_constant_override("margin_left", 10)
		status_mc.add_theme_constant_override("margin_top", 6)
		status_mc.add_theme_constant_override("margin_right", 10)
		status_mc.add_theme_constant_override("margin_bottom", 6)
		status_bar.add_child(status_mc)

		var status_hb := HBoxContainer.new()
		status_hb.add_theme_constant_override("separation", 8)
		status_mc.add_child(status_hb)

		var tty_lbl := Label.new()
		tty_lbl.text = "● TERMINAL BASH // tty1 (VFS ACTIVO)"
		tty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tty_lbl.add_theme_font_size_override("font_size", 12)
		tty_lbl.add_theme_color_override("font_color", BrandClass.ACCENT)
		status_hb.add_child(tty_lbl)

		var clear_btn := Button.new()
		clear_btn.text = "[ LIMPIAR (clear) ]"
		clear_btn.add_theme_font_size_override("font_size", 11)
		clear_btn.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
		clear_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26")))
		clear_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), BrandClass.ACCENT))
		clear_btn.pressed.connect(func() -> void:
			p._cli_output_lines.clear()
			p._play_click_sfx()
			_refresh_academia_right(container)
		)
		status_hb.add_child(clear_btn)

		var reset_btn := Button.new()
		reset_btn.text = "[ REINICIAR MÓDULO ]"
		reset_btn.add_theme_font_size_override("font_size", 11)
		reset_btn.add_theme_color_override("font_color", BrandClass.WARNING)
		reset_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26")))
		reset_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), BrandClass.WARNING))
		reset_btn.pressed.connect(func() -> void:
			p.start_cli_course(p._active_cli_course)
			p._play_click_sfx()
			_refresh_academia_right(container)
		)
		status_hb.add_child(reset_btn)

		var out_mc := MarginContainer.new()
		out_mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		out_mc.add_theme_constant_override("margin_left", 10)
		out_mc.add_theme_constant_override("margin_top", 8)
		out_mc.add_theme_constant_override("margin_right", 10)
		out_mc.add_theme_constant_override("margin_bottom", 8)
		right_vb.add_child(out_mc)

		var out_rtl := RichTextLabel.new()
		out_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		out_rtl.bbcode_enabled = true
		out_rtl.scroll_following = true
		var formatted_lines: Array[String] = []
		for raw_l in p._cli_output_lines:
			formatted_lines.append(_format_cli_line_bbcode(str(raw_l)))
		out_rtl.text = "\n".join(formatted_lines)
		out_rtl.add_theme_color_override("default_color", Color("#D2E3EC"))
		out_rtl.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#06080B")))
		out_mc.add_child(out_rtl)

		var prompt_panel := PanelContainer.new()
		var prompt_style: StyleBoxFlat = ProfileRendererClass.make_surface_style(Color("#0D141E"))
		prompt_style.border_width_top = 1
		prompt_style.border_color = BrandClass.ACCENT
		prompt_panel.add_theme_stylebox_override("panel", prompt_style)
		right_vb.add_child(prompt_panel)

		var prompt_mc := MarginContainer.new()
		prompt_mc.add_theme_constant_override("margin_left", 10)
		prompt_mc.add_theme_constant_override("margin_top", 6)
		prompt_mc.add_theme_constant_override("margin_right", 10)
		prompt_mc.add_theme_constant_override("margin_bottom", 6)
		prompt_panel.add_child(prompt_mc)

		var prompt_hb := HBoxContainer.new()
		prompt_hb.add_theme_constant_override("separation", 6)
		prompt_mc.add_child(prompt_hb)

		var cur_cwd: String = p._shell_engine.vfs.current_path if (p._shell_engine != null and p._shell_engine.vfs != null) else "/home/operator"
		var prompt_lbl := Label.new()
		prompt_lbl.text = "operator@vertex-vault:%s$ " % cur_cwd
		prompt_lbl.add_theme_font_size_override("font_size", 12)
		prompt_lbl.add_theme_color_override("font_color", Color("#39FF14"))
		prompt_hb.add_child(prompt_lbl)

		var cmd_input := LineEdit.new()
		cmd_input.name = "CliLineEdit"
		cmd_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cmd_input.text = p._cli_input_text
		cmd_input.placeholder_text = "Escribe un comando aquí (ej. pwd, ls, help)..."
		cmd_input.add_theme_color_override("font_color", Color("#39FF14"))
		cmd_input.add_theme_color_override("font_placeholder_color", Color("#4B5B6E"))
		cmd_input.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#0D141E")))
		cmd_input.add_theme_stylebox_override("focus", ProfileRendererClass.make_surface_style(Color("#0D141E")))

		cmd_input.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventKey and ev.pressed:
				var kev := ev as InputEventKey
				if kev.keycode == KEY_UP and p._cli_history.size() > 0:
					if p._cli_history_idx == -1:
						p._cli_history_idx = p._cli_history.size() - 1
					elif p._cli_history_idx > 0:
						p._cli_history_idx -= 1
					cmd_input.text = p._cli_history[p._cli_history_idx]
					cmd_input.caret_column = cmd_input.text.length()
					cmd_input.accept_event()
				elif kev.keycode == KEY_DOWN and p._cli_history_idx != -1:
					if p._cli_history_idx < p._cli_history.size() - 1:
						p._cli_history_idx += 1
						cmd_input.text = p._cli_history[p._cli_history_idx]
					else:
						p._cli_history_idx = -1
						cmd_input.text = ""
					cmd_input.caret_column = cmd_input.text.length()
					cmd_input.accept_event()
				elif kev.keycode == KEY_TAB:
					var prefix: String = cmd_input.text.strip_edges()
					var parts: PackedStringArray = prefix.split(" ", false)
					var last_tok: String = parts[parts.size() - 1] if parts.size() > 0 else ""
					if last_tok != "" and p._shell_engine != null and p._shell_engine.vfs != null:
						var dir_node: Dictionary = p._shell_engine.vfs._fs.get(cur_cwd, {})
						var children: Array = dir_node.get("children", [])
						for ch in children:
							var ch_str: String = str(ch)
							if ch_str.begins_with(last_tok):
								parts[parts.size() - 1] = ch_str
								cmd_input.text = " ".join(parts)
								cmd_input.caret_column = cmd_input.text.length()
								break
					cmd_input.accept_event()
		)

		cmd_input.text_submitted.connect(func(text: String) -> void:
			p._play_click_sfx()
			var trimmed: String = text.strip_edges()
			if trimmed != "":
				p._cli_history.append(trimmed)
			p._cli_history_idx = -1
			if trimmed == "clear":
				p._cli_output_lines.clear()
			else:
				p._cli_output_lines.append("operator@vertex-vault:%s$ %s" % [cur_cwd, text])
				var shell_res: String = p._shell_engine.execute_command_line(text)
				if shell_res != "":
					p._cli_output_lines.append(shell_res)
				if p._cli_course_step < steps.size():
					var expected: Dictionary = steps[p._cli_course_step]
					var check_sub: String = str(expected.get("check_substr", ""))
					if check_sub == "" or trimmed.contains(check_sub):
						p._cli_course_step += 1
						p._cli_output_lines.append(str(expected.get("success_msg", "[✓ OK]")))
						if p._cli_course_step < steps.size():
							p._cli_output_lines.append(str(steps[p._cli_course_step].get("instruction", "")))
						else:
							p._cli_output_lines.append("[✓] ¡Módulo de Academia completado!")
			p._cli_input_text = ""
			_refresh_academia_right(container)
			var next_input := container.find_child("CliLineEdit", true, false) as LineEdit
			if next_input != null and next_input.is_inside_tree():
				next_input.grab_focus()
		)
		prompt_hb.add_child(cmd_input)
