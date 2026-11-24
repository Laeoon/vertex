extends RefCounted

## Tab 03 // ACADEMIA CLI: Guía paso a paso + Terminal BÓVEDA // KERNEL LAB sin parpadeo.
## Construye la interfaz una sola vez y actualiza en sitio para evitar lag/rebuilds.

const BrandClass = preload("res://juego/ui/brand.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

var p: Profile
var _root_container: Control
var _course_btns: Array[Button] = []
var _step_card_lbl: Label
var _checklist_lbl: RichTextLabel
var _syntax_lbl: Label
var _tty_lbl: Label
var _cwd_lbl: Label
var _out_rtl: RichTextLabel
var _quick_hbox: HBoxContainer
var _prompt_lbl: Label
var _cmd_input: LineEdit


func _init(profile: Profile) -> void:
	p = profile


func build(container: Control) -> void:
	_root_container = container
	_build_tab_academia(container)
	_update_ui()


func _build_tab_academia(container: Control) -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	container.add_child(hbox)

	# ── Columna Izquierda: Módulos + Guía en 3 tarjetas ──────────────────
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(320, 0)
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 8)
	hbox.add_child(left_vb)

	var lessons: Array[Dictionary] = VaultModules.TERMINAL_ACADEMY_LESSONS
	_course_btns.clear()
	for c_idx in range(lessons.size()):
		var lesson: Dictionary = lessons[c_idx]
		var btn := Button.new()
		btn.name = "CliCourseBtn_%d" % c_idx
		btn.custom_minimum_size = Vector2(0, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_text = true
		btn.text = "0%d // %s" % [c_idx + 1, str(lesson.get("title", "Módulo %d" % (c_idx + 1)))]
		btn.add_theme_font_size_override("font_size", 11)
		var captured_c: int = c_idx
		btn.pressed.connect(func() -> void:
			p.start_cli_course(captured_c)
			p._play_click_sfx()
			_update_ui()
		)
		left_vb.add_child(btn)
		_course_btns.append(btn)

	# Tarjeta 1: Paso Activo destacado
	var active_panel := PanelContainer.new()
	active_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#0D1824"), BrandClass.ACCENT, BrandClass.ACCENT))
	left_vb.add_child(active_panel)

	var active_mc := MarginContainer.new()
	active_mc.add_theme_constant_override("margin_left", 10)
	active_mc.add_theme_constant_override("margin_top", 8)
	active_mc.add_theme_constant_override("margin_right", 10)
	active_mc.add_theme_constant_override("margin_bottom", 8)
	active_panel.add_child(active_mc)

	_step_card_lbl = Label.new()
	_step_card_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_step_card_lbl.add_theme_font_size_override("font_size", 12)
	_step_card_lbl.add_theme_color_override("font_color", BrandClass.TEXT)
	active_mc.add_child(_step_card_lbl)

	# Tarjeta 2: Hoja de Ruta (Checklist)
	var guide_panel := PanelContainer.new()
	guide_panel.name = "GuidePanel"
	guide_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guide_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#121923"), Color("#1E2736")))
	left_vb.add_child(guide_panel)

	var guide_mc := MarginContainer.new()
	guide_mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	guide_mc.add_theme_constant_override("margin_left", 10)
	guide_mc.add_theme_constant_override("margin_top", 8)
	guide_mc.add_theme_constant_override("margin_right", 10)
	guide_mc.add_theme_constant_override("margin_bottom", 8)
	guide_panel.add_child(guide_mc)

	var guide_vb := VBoxContainer.new()
	guide_vb.add_theme_constant_override("separation", 8)
	guide_mc.add_child(guide_vb)

	_checklist_lbl = RichTextLabel.new()
	_checklist_lbl.bbcode_enabled = true
	_checklist_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_checklist_lbl.add_theme_font_size_override("normal_font_size", 12)
	guide_vb.add_child(_checklist_lbl)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color("#1E2736"))
	guide_vb.add_child(sep)

	_syntax_lbl = Label.new()
	_syntax_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_syntax_lbl.add_theme_font_size_override("font_size", 11)
	_syntax_lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	guide_vb.add_child(_syntax_lbl)

	# ── Columna Derecha: Consola BÓVEDA // KERNEL LAB ────────────────────
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#06080B"), Color("#1E2736")))
	hbox.add_child(right_panel)

	var right_vb := VBoxContainer.new()
	right_vb.name = "AcademiaRightVBox"
	right_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_vb.add_theme_constant_override("separation", 0)
	right_panel.add_child(right_vb)

	# Header bar
	var status_bar := PanelContainer.new()
	status_bar.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#101722")))
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

	_tty_lbl = Label.new()
	_tty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tty_lbl.add_theme_font_size_override("font_size", 12)
	_tty_lbl.add_theme_color_override("font_color", BrandClass.ACCENT)
	status_hb.add_child(_tty_lbl)

	_cwd_lbl = Label.new()
	_cwd_lbl.add_theme_font_size_override("font_size", 11)
	_cwd_lbl.add_theme_color_override("font_color", BrandClass.SUCCESS)
	status_hb.add_child(_cwd_lbl)

	var clear_btn := Button.new()
	clear_btn.text = "[ LIMPIAR ]"
	clear_btn.add_theme_font_size_override("font_size", 11)
	clear_btn.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	clear_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26")))
	clear_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), BrandClass.ACCENT))
	clear_btn.pressed.connect(func() -> void:
		p._cli_output_lines.clear()
		p._play_click_sfx()
		_update_ui()
	)
	status_hb.add_child(clear_btn)

	var reset_btn := Button.new()
	reset_btn.text = "[ ↻ REINICIAR LAB ]"
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.add_theme_color_override("font_color", BrandClass.WARNING)
	reset_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26")))
	reset_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), BrandClass.WARNING))
	reset_btn.pressed.connect(func() -> void:
		if p._shell_engine != null and p._shell_engine.vfs != null:
			p._shell_engine.vfs.current_path = "/home/operator"
			p._shell_engine.vfs.is_root = false
		p.start_cli_course(p._active_cli_course)
		p._play_click_sfx()
		_update_ui()
	)
	status_hb.add_child(reset_btn)

	# Output terminal
	var out_mc := MarginContainer.new()
	out_mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	out_mc.add_theme_constant_override("margin_left", 10)
	out_mc.add_theme_constant_override("margin_top", 8)
	out_mc.add_theme_constant_override("margin_right", 10)
	out_mc.add_theme_constant_override("margin_bottom", 6)
	right_vb.add_child(out_mc)

	_out_rtl = RichTextLabel.new()
	_out_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_out_rtl.bbcode_enabled = true
	_out_rtl.scroll_following = true
	_out_rtl.add_theme_color_override("default_color", Color("#D2E3EC"))
	_out_rtl.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#06080B")))
	out_mc.add_child(_out_rtl)

	# Barra de Chips de Acceso Rápido
	var quick_panel := PanelContainer.new()
	quick_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#0A0F17")))
	right_vb.add_child(quick_panel)

	var quick_mc := MarginContainer.new()
	quick_mc.add_theme_constant_override("margin_left", 10)
	quick_mc.add_theme_constant_override("margin_top", 4)
	quick_mc.add_theme_constant_override("margin_right", 10)
	quick_mc.add_theme_constant_override("margin_bottom", 4)
	quick_panel.add_child(quick_mc)

	_quick_hbox = HBoxContainer.new()
	_quick_hbox.add_theme_constant_override("separation", 6)
	quick_mc.add_child(_quick_hbox)

	# Dock inferior del Prompt
	var prompt_panel := PanelContainer.new()
	var prompt_style := ProfileRendererClass.make_surface_style(Color("#0D141E"))
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

	_prompt_lbl = Label.new()
	_prompt_lbl.add_theme_font_size_override("font_size", 12)
	_prompt_lbl.add_theme_color_override("font_color", Color("#39FF14"))
	prompt_hb.add_child(_prompt_lbl)

	_cmd_input = LineEdit.new()
	_cmd_input.name = "CliLineEdit"
	_cmd_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cmd_input.placeholder_text = "Escribe comando o usa [TAB] para autocompletar..."
	_cmd_input.add_theme_color_override("font_color", Color("#39FF14"))
	_cmd_input.add_theme_color_override("font_placeholder_color", Color("#4B5B6E"))
	_cmd_input.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#0D141E")))
	_cmd_input.add_theme_stylebox_override("focus", ProfileRendererClass.make_surface_style(Color("#0D141E")))

	_cmd_input.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventKey and ev.pressed:
			var kev := ev as InputEventKey
			if kev.keycode == KEY_UP and p._cli_history.size() > 0:
				if p._cli_history_idx == -1:
					p._cli_history_idx = p._cli_history.size() - 1
				elif p._cli_history_idx > 0:
					p._cli_history_idx -= 1
				_cmd_input.text = p._cli_history[p._cli_history_idx]
				_cmd_input.caret_column = _cmd_input.text.length()
				_cmd_input.accept_event()
			elif kev.keycode == KEY_DOWN and p._cli_history_idx != -1:
				if p._cli_history_idx < p._cli_history.size() - 1:
					p._cli_history_idx += 1
					_cmd_input.text = p._cli_history[p._cli_history_idx]
				else:
					p._cli_history_idx = -1
					_cmd_input.text = ""
				_cmd_input.caret_column = _cmd_input.text.length()
				_cmd_input.accept_event()
			elif kev.keycode == KEY_TAB and p._shell_engine != null:
				var ac: Dictionary = p._shell_engine.autocomplete(_cmd_input.text)
				var comp: String = str(ac.get("completed", _cmd_input.text))
				var matches: Array = ac.get("matches", [])
				if comp != _cmd_input.text:
					_cmd_input.text = comp
					_cmd_input.caret_column = _cmd_input.text.length()
				elif matches.size() > 1:
					var m_strs: Array[String] = []
					for m in matches:
						m_strs.append(str(m))
					p._cli_output_lines.append("  ".join(m_strs))
					_update_output_only()
				_cmd_input.accept_event()
	)

	_cmd_input.text_submitted.connect(func(text: String) -> void:
		_submit_command(text)
	)
	prompt_hb.add_child(_cmd_input)


func _submit_command(text: String) -> void:
	p._play_click_sfx()
	var trimmed: String = text.strip_edges()
	if not trimmed.is_empty():
		p._cli_history.append(trimmed)
	p._cli_history_idx = -1
	_cmd_input.text = ""
	if trimmed == "clear":
		p._cli_output_lines.clear()
	elif not trimmed.is_empty():
		p._execute_cli_command(trimmed)
	_update_ui()
	if _cmd_input.is_inside_tree():
		_cmd_input.grab_focus()


func _update_ui() -> void:
	p._sync_shell_identity()
	var lessons: Array[Dictionary] = VaultModules.TERMINAL_ACADEMY_LESSONS
	var active_idx: int = clampi(p._active_cli_course, 0, lessons.size() - 1)
	for c_idx in range(_course_btns.size()):
		var btn: Button = _course_btns[c_idx]
		var lesson_i: Dictionary = lessons[c_idx]
		var is_act: bool = (c_idx == active_idx)
		var is_done: bool = p._courses_completed.get(c_idx, false)
		var mark: String = "[✓]" if is_done else ("[●]" if is_act else "[○]")
		btn.text = "%s 0%d // %s" % [mark, c_idx + 1, str(lesson_i.get("title", ""))]
		var left_col: Color = BrandClass.SUCCESS if is_done else (BrandClass.ACCENT if is_act else Color.TRANSPARENT)
		btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#182230") if is_act else Color("#121923"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))
		btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#182230"), Color("#1E2736"), left_col))

	var lesson: Dictionary = lessons[active_idx]
	var steps: Array = lesson.get("steps", [])
	var step_cmd: String = ""
	if p._cli_course_step < steps.size():
		var st: Dictionary = steps[p._cli_course_step]
		step_cmd = str(st.get("expected_cmd", ""))
		_step_card_lbl.text = "PASO %d/%d // ACTIVO\n%s\nSugerido: %s" % [
			p._cli_course_step + 1, steps.size(), str(st.get("instruction", "")), step_cmd
		]
	else:
		_step_card_lbl.text = "MÓDULO COMPLETADO [✓]\nPuedes seguir explorando o pasar al siguiente módulo."

	var chk_lines: Array[String] = ["[color=#00E5FF][b]HOJA DE RUTA DEL MÓDULO[/b][/color]"]
	for s_idx in range(steps.size()):
		var st_dict: Dictionary = steps[s_idx]
		var e_cmd: String = str(st_dict.get("expected_cmd", ""))
		if s_idx < p._cli_course_step:
			chk_lines.append("[color=#39FF88]✓ Paso %d: %s[/color]" % [s_idx + 1, e_cmd])
		elif s_idx == p._cli_course_step:
			chk_lines.append("[color=#00E5FF]▶ Paso %d: %s[/color]" % [s_idx + 1, e_cmd])
		else:
			chk_lines.append("[color=#6E7B8B]○ Paso %d: %s[/color]" % [s_idx + 1, e_cmd])
	_checklist_lbl.text = "\n".join(chk_lines)
	_syntax_lbl.text = "SINTAXIS: %s\nTip: %s" % [str(lesson.get("commands", "")), str(lesson.get("hint", ""))]

	var cur_cwd: String = p._shell_engine.vfs.current_path if (p._shell_engine != null and p._shell_engine.vfs != null) else "/home/operator"
	var op_name: String = p._shell_engine.get_active_user().to_upper() if p._shell_engine != null else "OPERADOR"
	_tty_lbl.text = "● BÓVEDA // KERNEL LAB — OPERADOR: %s" % op_name
	_cwd_lbl.text = "[ CWD: %s ]" % cur_cwd
	_prompt_lbl.text = p._shell_engine.get_prompt_string() if p._shell_engine != null else "operador@boveda-lab:~$ "

	_rebuild_quick_chips(step_cmd)
	_update_output_only()


func _rebuild_quick_chips(step_cmd: String) -> void:
	for ch in _quick_hbox.get_children():
		ch.queue_free()
	var chips: Array[String] = []
	if not step_cmd.is_empty():
		chips.append(step_cmd)
	for base_c in ["ls -la", "pwd", "help", "games"]:
		if not chips.has(base_c):
			chips.append(base_c)

	for i in range(chips.size()):
		var cmd_val: String = chips[i]
		var is_step_chip: bool = (i == 0 and not step_cmd.is_empty())
		var chip_btn := Button.new()
		chip_btn.text = ("[ ⚡ " + cmd_val + " ]") if is_step_chip else ("[ " + cmd_val + " ]")
		chip_btn.add_theme_font_size_override("font_size", 11)
		chip_btn.add_theme_color_override("font_color", BrandClass.ACCENT if is_step_chip else BrandClass.TEXT_DIM)
		chip_btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#122030") if is_step_chip else Color("#121923"), BrandClass.ACCENT if is_step_chip else Color("#1E2736")))
		chip_btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#1A2D42"), BrandClass.ACCENT))
		var captured_cmd: String = cmd_val
		chip_btn.pressed.connect(func() -> void:
			_submit_command(captured_cmd)
		)
		_quick_hbox.add_child(chip_btn)


func _update_output_only() -> void:
	var formatted_lines: Array[String] = []
	for raw_l in p._cli_output_lines:
		formatted_lines.append(_format_cli_line_bbcode(str(raw_l)))
	_out_rtl.text = "\n".join(formatted_lines)


func _format_cli_line_bbcode(line: String) -> String:
	var safe: String = line.replace("[", "[lb]")
	if safe.contains("@boveda-lab:") or safe.begins_with("operator@vertex-vault:"):
		return "[color=#39FF14]" + safe + "[/color]"
	if safe.contains("Error") or safe.contains("FAIL") or safe.contains("no encontrado") or safe.contains("Permiso denegado") or safe.contains("KERNEL PANIC"):
		return "[color=#FF4D4D]" + safe + "[/color]"
	if safe.contains("[✓") or safe.contains("completado") or safe.contains("OK"):
		return "[color=#39FF14]" + safe + "[/color]"
	if safe.contains(".enc") or safe.contains(".txt") or safe.contains(".b64"):
		return "[color=#FFB000]" + safe + "[/color]"
	if safe.contains("/home/") or safe.contains("/etc/") or safe.contains("/var/") or safe.contains("/srv/") or safe.contains("/proc/") or safe.contains("/usr/"):
		return "[color=#00F0FF]" + safe + "[/color]"
	return safe
