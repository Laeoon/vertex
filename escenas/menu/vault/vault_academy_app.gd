extends RefCounted

## Full-Screen CLI App: VTX-ACADEMY (Estética Bubbletea/Lipgloss sin bordes + UnixShellEngine real).
## Flujo: SPLASH -> HUB -> [Entrenamiento Guiado | Escalada SSH | Guía de Comandos].

const CurriculumClass = preload("res://escenas/menu/vault/vault_academy_curriculum.gd")
const UnixShellEngineClass = preload("res://juego/system/unix_shell_engine.gd")

enum Screen {
	SPLASH,
	HUB,
	MODULES_MENU,
	EXERCISE,
	RESULT,
	BOSS,
	BOSS_CLEAR,
	SSH_MENU,
	SSH_LEVEL,
	SSH_CLEAR,
	GUIDE_MENU,
	GUIDE_DETAIL,
}

const COL_BG := Color("#11151B")
const COL_TITLE := Color("#66D9EF")
const COL_ACTIVE := Color("#F6C177")
const COL_TEXT := Color("#E6EDF3")
const COL_MUTED := Color("#8A96A8")
const COL_OK := Color("#7EE787")
const COL_ERR := Color("#F7768E")
const COL_HAIRLINE := Color("#273142")
const COL_INPUT_BG := Color("#161C24")
const COL_INPUT_BORDER := Color("#3B4D66")

const SPLASH_LOGO: Array[String] = [
	"██╗   ██╗████████╗██╗  ██╗     █████╗  ██████╗ █████╗ ██████╗ ███████╗███╗   ███╗██╗   ██╗",
	"██║   ██║╚══██╔══╝╚██╗██╔╝    ██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝████╗ ████║╚██╗ ██╔╝",
	"██║   ██║   ██║    ╚███╔╝     ███████║██║     ███████║██║  ██║█████╗  ██╔████╔██║ ╚████╔╝ ",
	"╚██╗ ██╔╝   ██║    ██╔██╗     ██╔══██║██║     ██╔══██║██║  ██║██╔══╝  ██║╚██╔╝██║  ╚██╔╝  ",
	" ╚████╔╝    ██║   ██╔╝ ██╗    ██║  ██║╚██████╗██║  ██║██████╔╝███████╗██║ ╚═╝ ██║   ██║   ",
	"  ╚═══╝     ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝     ╚═╝   ╚═╝   ",
]

var p: Profile
var _canvas: Control = null
var _sandbox_shell: UnixShellEngine = UnixShellEngineClass.new()
var _screen: Screen = Screen.SPLASH

var _hub_cursor: int = 0
var _mod_cursor: int = 0
var _ssh_cursor: int = 0
var _guide_cursor: int = 0

var _mod_idx: int = 0
var _ex_idx: int = 0
var _ex_mode: String = "lesson"
var _boss_step_idx: int = 0
var _ssh_idx: int = 0
var _guide_idx: int = 0

var _shields: int = 3
var _score: int = 0
var _streak: int = 1
var _best_streak: int = 1
var _timer_start: float = 0.0
var _last_elapsed: float = 0.0
var _input_text: String = ""
var _show_hint: bool = false
var _cmd_history: Array[String] = []
var _history_pos: int = -1

var _term_lines: Array[Dictionary] = [] # {"text": String, "color": Color}
var _analysis: Dictionary = {}
var _row_hitboxes: Array[Dictionary] = []

var _lesson_done: Dictionary = {}
var _practice_done: Dictionary = {}
var _boss_cleared: Dictionary = {}
var _ssh_cleared: Dictionary = {}


func _init(profile: Profile) -> void:
	p = profile


func build(parent: Control) -> Control:
	var ctrl := Control.new()
	ctrl.name = "VtxAcademyApp"
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.focus_mode = Control.FOCUS_ALL
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.visible = false
	ctrl.draw.connect(_on_draw)
	ctrl.gui_input.connect(_on_gui_input)
	parent.add_child(ctrl)
	_canvas = ctrl
	return ctrl


func open_app() -> void:
	if _canvas == null:
		return
	_screen = Screen.SPLASH
	_input_text = ""
	_show_hint = false
	_canvas.visible = true
	_canvas.grab_focus()
	_canvas.queue_redraw()


func close_app() -> void:
	if _canvas != null:
		_canvas.visible = false


func is_open() -> bool:
	return _canvas != null and _canvas.visible


func get_screen() -> Screen:
	return _screen


func open_hub() -> void:
	_screen = Screen.HUB
	_input_text = ""
	_show_hint = false
	_redraw()


func open_modules_menu() -> void:
	_screen = Screen.MODULES_MENU
	_input_text = ""
	_show_hint = false
	_redraw()


func open_ssh_menu() -> void:
	_screen = Screen.SSH_MENU
	_input_text = ""
	_show_hint = false
	_redraw()


func open_guide_menu() -> void:
	_screen = Screen.GUIDE_MENU
	_redraw()


func open_guide_section(idx: int) -> void:
	_guide_idx = clampi(idx, 0, CurriculumClass.GUIDE_SECTIONS.size() - 1)
	_screen = Screen.GUIDE_DETAIL
	_redraw()


func select_module(idx: int) -> void:
	_mod_idx = clampi(idx, 0, CurriculumClass.MODULES.size() - 1)
	_mod_cursor = _mod_idx
	_redraw()


func start_exercise(mod_idx: int, mode: String = "lesson") -> void:
	_mod_idx = clampi(mod_idx, 0, CurriculumClass.MODULES.size() - 1)
	_ex_mode = mode
	_ex_idx = 0
	_screen = Screen.EXERCISE
	_reset_exercise_sandbox()
	_redraw()


func start_boss(mod_idx: int = 0) -> void:
	_mod_idx = clampi(mod_idx, 0, CurriculumClass.MODULES.size() - 1)
	_boss_step_idx = 0
	_shields = 3
	_screen = Screen.BOSS
	_setup_sandbox_for_fs(CurriculumClass.build_guided_fs(_mod_idx), "/home/operator", "operador", "vtx-lab")
	_redraw()


func start_ssh_level(idx: int) -> void:
	_ssh_idx = clampi(idx, 0, CurriculumClass.SSH_LEVELS.size() - 1)
	if not is_ssh_unlocked(_ssh_idx):
		return
	_screen = Screen.SSH_LEVEL
	var lv: Dictionary = CurriculumClass.SSH_LEVELS[_ssh_idx]
	var host_name: String = str(lv.get("node_from", "nodo0"))
	_setup_sandbox_for_fs(CurriculumClass.build_ssh_fs(_ssh_idx), "/home/operator", "operador", host_name)
	_redraw()


func is_ssh_unlocked(idx: int) -> bool:
	if idx <= 0:
		return true
	return bool(_ssh_cleared.get(idx - 1, false))


func advance_from_result() -> void:
	var mod: Dictionary = CurriculumClass.MODULES[_mod_idx]
	var exercises: Array = mod.get("exercises", [])
	if _ex_idx + 1 < exercises.size():
		_ex_idx += 1
		_screen = Screen.EXERCISE
		_reset_exercise_sandbox()
	else:
		_screen = Screen.MODULES_MENU
	_redraw()


func handle_escape() -> bool:
	match _screen:
		Screen.SPLASH, Screen.HUB:
			close_app()
			return true
		Screen.MODULES_MENU, Screen.SSH_MENU, Screen.GUIDE_MENU:
			open_hub()
			return false
		Screen.EXERCISE, Screen.RESULT, Screen.BOSS, Screen.BOSS_CLEAR:
			open_modules_menu()
			return false
		Screen.SSH_LEVEL, Screen.SSH_CLEAR:
			open_ssh_menu()
			return false
		Screen.GUIDE_DETAIL:
			open_guide_menu()
			return false
	close_app()
	return true


func execute_command(raw: String) -> void:
	var cmd: String = raw.strip_edges()
	if cmd.is_empty():
		return

	_cmd_history.append(cmd)
	_history_pos = _cmd_history.size()

	if cmd == "clear":
		_term_lines.clear()
		_redraw()
		return
	if cmd == "exit" or cmd == "quit":
		handle_escape()
		return

	var prompt_prefix: String = _sandbox_shell.get_prompt_string()
	_push_term_line(prompt_prefix + cmd, COL_TITLE)

	if _screen == Screen.SSH_LEVEL:
		_execute_ssh_command(cmd)
		_redraw()
		return

	var res: UnixShellEngineClass.ShellResult = _sandbox_shell.execute(cmd)
	var out: String = res.combined_output()
	if out == "__CLEAR__":
		_term_lines.clear()
		_redraw()
		return
	if not out.is_empty():
		_push_term_multiline(out, COL_TEXT if res.exit_code == 0 else COL_ERR)

	if _screen == Screen.EXERCISE:
		_evaluate_exercise_step(cmd, res)
	elif _screen == Screen.BOSS:
		_evaluate_boss_step(cmd, res)

	_redraw()


func _execute_ssh_command(cmd: String) -> void:
	var lv: Dictionary = CurriculumClass.SSH_LEVELS[_ssh_idx]
	var expected_key: String = str(lv.get("expected_key", "")).strip_edges().to_upper()
	var parts: PackedStringArray = cmd.split(" ", false)
	if parts.size() >= 1 and (parts[0] == "ssh" or parts[0] == "unlock" or parts[0] == "acceso"):
		var submitted: String = ""
		if parts.size() >= 3 and parts[0] == "ssh":
			submitted = parts[2].strip_edges().to_upper()
		elif parts.size() >= 2:
			submitted = parts[1].strip_edges().to_upper()
		if submitted == expected_key and not expected_key.is_empty():
			_ssh_cleared[_ssh_idx] = true
			_score += 400
			_last_elapsed = maxf(0.1, p._pulse - _timer_start)
			_screen = Screen.SSH_CLEAR
			return
		_push_term_line("[SSH] Acceso denegado. Verifica la clave y usa: ssh %s <clave>" % str(lv.get("node_to", "nodo1")), COL_ERR)
		return

	var res: UnixShellEngineClass.ShellResult = _sandbox_shell.execute(cmd)
	var out: String = res.combined_output()
	if out == "__CLEAR__":
		_term_lines.clear()
		return
	if not out.is_empty():
		_push_term_multiline(out, COL_TEXT if res.exit_code == 0 else COL_ERR)


func _evaluate_exercise_step(cmd: String, res: UnixShellEngineClass.ShellResult) -> void:
	var mod: Dictionary = CurriculumClass.MODULES[_mod_idx]
	var exercises: Array = mod.get("exercises", [])
	var ex: Dictionary = exercises[clampi(_ex_idx, 0, exercises.size() - 1)]
	var goal: Dictionary = ex.get("goal", {})

	if not _check_goal(goal, cmd, res):
		return

	var optimal_cmd: String = str(ex.get("optimal_cmd", ""))
	var is_optimal: bool = (cmd == optimal_cmd)
	var pts: int = (250 if is_optimal else 100) * _streak
	_score += pts
	if is_optimal:
		_streak = mini(4, _streak + 1)
		_best_streak = maxi(_best_streak, _streak)
	else:
		_streak = 1
	_last_elapsed = maxf(0.1, p._pulse - _timer_start)

	if _ex_mode == "lesson":
		_lesson_done[_mod_idx] = maxi(int(_lesson_done.get(_mod_idx, 0)), _ex_idx + 1)
	else:
		_practice_done[_mod_idx] = maxi(int(_practice_done.get(_mod_idx, 0)), _ex_idx + 1)

	_analysis = {
		"cmd": cmd,
		"optimal": optimal_cmd,
		"is_optimal": is_optimal,
		"pts": pts,
		"breakdown": ex.get("breakdown", []),
	}
	_screen = Screen.RESULT


func _evaluate_boss_step(cmd: String, res: UnixShellEngineClass.ShellResult) -> void:
	var mod: Dictionary = CurriculumClass.MODULES[_mod_idx]
	var steps: Array = mod.get("boss_steps", [])
	var st: Dictionary = steps[clampi(_boss_step_idx, 0, steps.size() - 1)]
	var goal: Dictionary = st.get("goal", {})

	if _check_goal(goal, cmd, res):
		var optimal_cmd: String = str(st.get("optimal_cmd", ""))
		var is_optimal: bool = (cmd == optimal_cmd)
		var pts: int = (250 if is_optimal else 100) * _streak
		_score += pts
		if is_optimal:
			_streak = mini(4, _streak + 1)
			_best_streak = maxi(_best_streak, _streak)
		if _boss_step_idx + 1 < steps.size():
			_boss_step_idx += 1
		else:
			_last_elapsed = maxf(0.1, p._pulse - _timer_start)
			_boss_cleared[_mod_idx] = true
			_screen = Screen.BOSS_CLEAR
		return

	if cmd == "help":
		return
	if res.exit_code != 0 or not _is_passive_exploration(cmd):
		_shields = maxi(0, _shields - 1)
		_streak = 1
		if _shields <= 0:
			_shields = 3
			_boss_step_idx = 0
			_setup_sandbox_for_fs(CurriculumClass.build_guided_fs(_mod_idx), "/home/operator", "operador", "vtx-lab")
			_push_term_line("[!] Escudos agotados: prueba reiniciada al paso 1.", COL_ERR)
		else:
			_push_term_line("[!] Ese comando no completa el objetivo (-1 escudo).", COL_ERR)


func _is_passive_exploration(cmd: String) -> bool:
	return cmd == "ls" or cmd == "pwd" or cmd.begins_with("ls ")


func _check_goal(goal: Dictionary, cmd: String, res: UnixShellEngineClass.ShellResult) -> bool:
	if res.exit_code != 0:
		return false
	var gtype: String = str(goal.get("type", ""))
	var val: String = str(goal.get("value", ""))
	match gtype:
		"cmd_prefix":
			return cmd == val or cmd.begins_with(val + " ")
		"stdout_contains":
			return res.stdout.find(val) != -1
		"cmd_prefix_and_stdout":
			var pref: String = str(goal.get("prefix", ""))
			return (cmd == pref or cmd.begins_with(pref + " ")) and res.stdout.find(val) != -1
		"cwd_equals":
			return _sandbox_shell.vfs.current_path == val
		"vfs_dirs_exist":
			var paths: Array = goal.get("paths", [])
			for p_var: Variant in paths:
				var p_str: String = str(p_var)
				if not _sandbox_shell.vfs._fs.has(p_str):
					return false
				if (_sandbox_shell.vfs._fs[p_str] as Dictionary).get("type") != "dir":
					return false
			return true
		"vfs_not_exists":
			return not _sandbox_shell.vfs._fs.has(val)
		"vfs_file_contains":
			var fpath: String = str(goal.get("path", ""))
			var sub: String = str(goal.get("substr", ""))
			if not _sandbox_shell.vfs._fs.has(fpath):
				return false
			var content: String = str((_sandbox_shell.vfs._fs[fpath] as Dictionary).get("content", ""))
			return content.find(sub) != -1
	return false


func _reset_exercise_sandbox() -> void:
	var mod: Dictionary = CurriculumClass.MODULES[_mod_idx]
	var exercises: Array = mod.get("exercises", [])
	var ex: Dictionary = exercises[clampi(_ex_idx, 0, exercises.size() - 1)]
	var start_cwd: String = str(ex.get("start_cwd", "/home/operator"))
	_setup_sandbox_for_fs(CurriculumClass.build_guided_fs(_mod_idx), start_cwd, "operador", "vtx-lab")


func _setup_sandbox_for_fs(fs_dict: Dictionary, start_cwd: String, user_str: String, host_str: String) -> void:
	_sandbox_shell.reset_to_custom_vfs(fs_dict, start_cwd, user_str, host_str)
	_input_text = ""
	_show_hint = false
	_term_lines.clear()
	_analysis.clear()
	_cmd_history.clear()
	_history_pos = -1
	_timer_start = p._pulse if p != null else 0.0


func _push_term_line(txt: String, col: Color) -> void:
	_term_lines.append({"text": txt, "color": col})
	while _term_lines.size() > 8:
		_term_lines.pop_front()


func _push_term_multiline(txt: String, col: Color) -> void:
	for line: String in txt.split("\n", false):
		_push_term_line(line, col)


func _redraw() -> void:
	if _canvas != null:
		_canvas.queue_redraw()


func _on_gui_input(event: InputEvent) -> void:
	if _canvas == null or not _canvas.visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_canvas.grab_focus()
			for hb: Dictionary in _row_hitboxes:
				var r: Rect2 = hb.get("rect", Rect2())
				if r.has_point(mb.position):
					_activate_hitbox(hb)
					_canvas.accept_event()
					return
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed or ke.echo:
			return
		match _screen:
			Screen.SPLASH:
				_handle_splash_key(ke)
			Screen.HUB:
				_handle_hub_key(ke)
			Screen.MODULES_MENU:
				_handle_modules_menu_key(ke)
			Screen.SSH_MENU:
				_handle_ssh_menu_key(ke)
			Screen.GUIDE_MENU:
				_handle_guide_menu_key(ke)
			Screen.GUIDE_DETAIL:
				_handle_guide_detail_key(ke)
			Screen.EXERCISE, Screen.BOSS, Screen.SSH_LEVEL:
				_handle_cli_key(ke)
			Screen.RESULT:
				_handle_result_key(ke)
			Screen.BOSS_CLEAR:
				_handle_boss_clear_key(ke)
			Screen.SSH_CLEAR:
				_handle_ssh_clear_key(ke)


func _activate_hitbox(hb: Dictionary) -> void:
	var action: String = str(hb.get("action", ""))
	var idx: int = int(hb.get("idx", 0))
	if p != null:
		p._play_click_sfx()
	match action:
		"hub":
			_hub_cursor = idx
			_activate_hub_cursor()
		"mod":
			_mod_cursor = idx
			if idx == CurriculumClass.MODULES.size():
				open_hub()
			else:
				start_exercise(idx, "lesson")
		"ssh":
			_ssh_cursor = idx
			if idx == CurriculumClass.SSH_LEVELS.size():
				open_hub()
			else:
				start_ssh_level(idx)
		"guide":
			_guide_cursor = idx
			if idx == CurriculumClass.GUIDE_SECTIONS.size():
				open_hub()
			else:
				open_guide_section(idx)
		"back_guide":
			open_guide_menu()


func _handle_splash_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER or ke.keycode == KEY_SPACE:
		p._play_click_sfx()
		open_hub()
	elif ke.keycode == KEY_ESCAPE or ke.keycode == KEY_Q:
		p._play_click_sfx()
		close_app()
	_canvas.accept_event()


func _handle_hub_key(ke: InputEventKey) -> void:
	var total: int = 4
	if ke.keycode == KEY_ESCAPE or ke.keycode == KEY_Q:
		p._play_click_sfx()
		close_app()
	elif ke.keycode == KEY_UP or ke.keycode == KEY_K:
		_hub_cursor = posmod(_hub_cursor - 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_DOWN or ke.keycode == KEY_J:
		_hub_cursor = posmod(_hub_cursor + 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		p._play_click_sfx()
		_activate_hub_cursor()
	_redraw()
	_canvas.accept_event()


func _activate_hub_cursor() -> void:
	match _hub_cursor:
		0:
			open_modules_menu()
		1:
			open_ssh_menu()
		2:
			open_guide_menu()
		_:
			close_app()


func _handle_modules_menu_key(ke: InputEventKey) -> void:
	var total: int = CurriculumClass.MODULES.size() + 1
	if ke.keycode == KEY_ESCAPE or ke.keycode == KEY_Q:
		p._play_click_sfx()
		open_hub()
	elif ke.keycode == KEY_UP or ke.keycode == KEY_K:
		_mod_cursor = posmod(_mod_cursor - 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_DOWN or ke.keycode == KEY_J:
		_mod_cursor = posmod(_mod_cursor + 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER or ke.keycode == KEY_L:
		p._play_click_sfx()
		if _mod_cursor == CurriculumClass.MODULES.size():
			open_hub()
		else:
			start_exercise(_mod_cursor, "lesson")
	elif ke.keycode == KEY_P and _mod_cursor < CurriculumClass.MODULES.size():
		p._play_click_sfx()
		start_exercise(_mod_cursor, "practice")
	elif ke.keycode == KEY_B and _mod_cursor < CurriculumClass.MODULES.size():
		p._play_click_sfx()
		start_boss(_mod_cursor)
	elif ke.keycode == KEY_R:
		p._play_click_sfx()
		_lesson_done.clear()
		_practice_done.clear()
		_boss_cleared.clear()
	_redraw()
	_canvas.accept_event()


func _handle_ssh_menu_key(ke: InputEventKey) -> void:
	var total: int = CurriculumClass.SSH_LEVELS.size() + 1
	if ke.keycode == KEY_ESCAPE or ke.keycode == KEY_Q:
		p._play_click_sfx()
		open_hub()
	elif ke.keycode == KEY_UP or ke.keycode == KEY_K:
		_ssh_cursor = posmod(_ssh_cursor - 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_DOWN or ke.keycode == KEY_J:
		_ssh_cursor = posmod(_ssh_cursor + 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		p._play_click_sfx()
		if _ssh_cursor == CurriculumClass.SSH_LEVELS.size():
			open_hub()
		else:
			start_ssh_level(_ssh_cursor)
	_redraw()
	_canvas.accept_event()


func _handle_guide_menu_key(ke: InputEventKey) -> void:
	var total: int = CurriculumClass.GUIDE_SECTIONS.size() + 1
	if ke.keycode == KEY_ESCAPE or ke.keycode == KEY_Q:
		p._play_click_sfx()
		open_hub()
	elif ke.keycode == KEY_UP or ke.keycode == KEY_K:
		_guide_cursor = posmod(_guide_cursor - 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_DOWN or ke.keycode == KEY_J:
		_guide_cursor = posmod(_guide_cursor + 1, total)
		p._play_click_sfx()
	elif ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		p._play_click_sfx()
		if _guide_cursor == CurriculumClass.GUIDE_SECTIONS.size():
			open_hub()
		else:
			open_guide_section(_guide_cursor)
	_redraw()
	_canvas.accept_event()


func _handle_guide_detail_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ESCAPE or ke.keycode == KEY_Q or ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		p._play_click_sfx()
		open_guide_menu()
	_canvas.accept_event()


func _handle_cli_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ESCAPE:
		p._play_click_sfx()
		handle_escape()
	elif ke.keycode == KEY_F1:
		_show_hint = not _show_hint
	elif ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		var cmd: String = _input_text
		_input_text = ""
		execute_command(cmd)
	elif ke.keycode == KEY_BACKSPACE:
		if _input_text.length() > 0:
			_input_text = _input_text.substr(0, _input_text.length() - 1)
	elif ke.keycode == KEY_TAB:
		var ac: Dictionary = _sandbox_shell.autocomplete(_input_text)
		var comp: String = str(ac.get("completed", _input_text))
		if not comp.is_empty():
			_input_text = comp
	elif ke.keycode == KEY_UP:
		if not _cmd_history.is_empty():
			_history_pos = maxi(0, _history_pos - 1)
			_input_text = _cmd_history[_history_pos]
	elif ke.keycode == KEY_DOWN:
		if _history_pos + 1 < _cmd_history.size():
			_history_pos += 1
			_input_text = _cmd_history[_history_pos]
		else:
			_history_pos = _cmd_history.size()
			_input_text = ""
	elif ke.unicode >= 32 and ke.unicode < 127:
		_input_text += char(ke.unicode)
	_redraw()
	_canvas.accept_event()


func _handle_result_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		p._play_click_sfx()
		advance_from_result()
	elif ke.keycode == KEY_R:
		p._play_click_sfx()
		_screen = Screen.EXERCISE
		_reset_exercise_sandbox()
		_redraw()
	elif ke.keycode == KEY_Q or ke.keycode == KEY_ESCAPE:
		p._play_click_sfx()
		open_modules_menu()
	_canvas.accept_event()


func _handle_boss_clear_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER or ke.keycode == KEY_Q or ke.keycode == KEY_ESCAPE:
		p._play_click_sfx()
		open_modules_menu()
	elif ke.keycode == KEY_R:
		p._play_click_sfx()
		start_boss(_mod_idx)
	_canvas.accept_event()


func _handle_ssh_clear_key(ke: InputEventKey) -> void:
	if ke.keycode == KEY_ENTER or ke.keycode == KEY_KP_ENTER:
		p._play_click_sfx()
		if _ssh_idx + 1 < CurriculumClass.SSH_LEVELS.size():
			start_ssh_level(_ssh_idx + 1)
		else:
			open_ssh_menu()
	elif ke.keycode == KEY_Q or ke.keycode == KEY_ESCAPE:
		p._play_click_sfx()
		open_ssh_menu()
	_canvas.accept_event()


func _on_draw() -> void:
	if _canvas == null or not _canvas.visible:
		return
	var sz: Vector2 = _canvas.size
	if sz.x <= 20.0 or sz.y <= 20.0:
		return

	# Full-screen borderless terminal backdrop drawn before any element
	_canvas.draw_rect(Rect2(Vector2.ZERO, sz), COL_BG)
	var font: Font = p.font
	if font == null:
		return

	_row_hitboxes.clear()
	var x: float = clampf(sz.x * 0.08, 48.0, 96.0)
	var y: float = 56.0
	var w: float = minf(sz.x - x * 2.0, 920.0)

	match _screen:
		Screen.SPLASH:
			_draw_splash(sz, font)
		Screen.HUB:
			_draw_hub(x, y, w, font)
		Screen.MODULES_MENU:
			_draw_modules_menu(x, y, w, font)
		Screen.EXERCISE:
			_draw_exercise(x, y, w, font)
		Screen.RESULT:
			_draw_result(x, y, w, font)
		Screen.BOSS:
			_draw_boss(x, y, w, font)
		Screen.BOSS_CLEAR:
			_draw_boss_clear(x, y, w, font)
		Screen.SSH_MENU:
			_draw_ssh_menu(x, y, w, font)
		Screen.SSH_LEVEL:
			_draw_ssh_level(x, y, w, font)
		Screen.SSH_CLEAR:
			_draw_ssh_clear(x, y, w, font)
		Screen.GUIDE_MENU:
			_draw_guide_menu(x, y, w, font)
		Screen.GUIDE_DETAIL:
			_draw_guide_detail(x, y, w, font)


func _draw_splash(sz: Vector2, font: Font) -> void:
	var cy: float = sz.y * 0.34
	for line: String in SPLASH_LOGO:
		_canvas.draw_string(font, Vector2(0.0, cy), line, HORIZONTAL_ALIGNMENT_CENTER, int(sz.x), 12, COL_TITLE)
		cy += 16.0
	cy += 22.0
	_canvas.draw_string(font, Vector2(0.0, cy), "Tu laboratorio de terminal UNIX, paso a paso y en tiempo real.", HORIZONTAL_ALIGNMENT_CENTER, int(sz.x), 15, COL_MUTED)
	cy += 34.0
	_canvas.draw_string(font, Vector2(0.0, cy), "Presiona [Enter] para comenzar  •  [Esc] salir", HORIZONTAL_ALIGNMENT_CENTER, int(sz.x), 13, COL_ACTIVE)


func _draw_hub(x: float, y: float, w: float, font: Font) -> void:
	_canvas.draw_string(font, Vector2(x, y), "VTX // ACADEMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, y + 28.0), "¿Qué deseas hacer?", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COL_MUTED)

	var items: Array[Array] = [
		["Entrenamiento Guiado", "Aprende cada comando paso a paso con lecciones, práctica y pruebas."],
		["Escalada SSH", "Infiltra 5 nodos reales encontrando claves ocultas en la terminal."],
		["Guía de Comandos", "Consulta sintaxis, banderas y ejemplos en cualquier momento."],
	]
	var cy: float = y + 72.0
	for i: int in range(items.size()):
		var sel: bool = (_hub_cursor == i)
		var prefix: String = "▸ " if sel else "  "
		var title_col: Color = COL_ACTIVE if sel else COL_TEXT
		_canvas.draw_string(font, Vector2(x, cy), prefix + str(items[i][0]), HORIZONTAL_ALIGNMENT_LEFT, int(w), 16, title_col)
		_canvas.draw_string(font, Vector2(x + 22.0, cy + 20.0), str(items[i][1]), HORIZONTAL_ALIGNMENT_LEFT, int(w - 22.0), 13, COL_MUTED)
		_row_hitboxes.append({"action": "hub", "idx": i, "rect": Rect2(x - 8.0, cy - 16.0, w, 44.0)})
		cy += 54.0

	_canvas.draw_line(Vector2(x, cy + 2.0), Vector2(x + 220.0, cy + 2.0), COL_HAIRLINE, 1.0)
	cy += 26.0
	var exit_sel: bool = (_hub_cursor == 3)
	_canvas.draw_string(font, Vector2(x, cy), ("▸ " if exit_sel else "  ") + "← Salir a La Bóveda", HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE if exit_sel else COL_MUTED)
	_row_hitboxes.append({"action": "hub", "idx": 3, "rect": Rect2(x - 8.0, cy - 16.0, 260.0, 26.0)})

	_canvas.draw_string(font, Vector2(x, cy + 44.0), "↑/k arriba  •  ↓/j abajo  •  [Enter] seleccionar  •  [q / Esc] salir", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_modules_menu(x: float, y: float, w: float, font: Font) -> void:
	_canvas.draw_string(font, Vector2(x, y), "Entrenamiento Guiado", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, y + 26.0), "Domina la terminal con lecciones explicadas, práctica y pruebas de campo.", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)
	var stats_line: String = "Puntaje: %d  |  Racha: x%d  |  Pruebas: %d/%d" % [_score, _streak, _boss_cleared.size(), CurriculumClass.MODULES.size()]
	_canvas.draw_string(font, Vector2(x, y + 52.0), stats_line, HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_OK)
	_canvas.draw_string(font, Vector2(x, y + 84.0), "Selecciona un módulo:", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)

	var cy: float = y + 116.0
	for i: int in range(CurriculumClass.MODULES.size()):
		var mod: Dictionary = CurriculumClass.MODULES[i]
		var sel: bool = (_mod_cursor == i)
		var l_done: int = int(_lesson_done.get(i, 0))
		var p_done: int = int(_practice_done.get(i, 0))
		var total_ex: int = (mod.get("exercises", []) as Array).size()
		var b_ok: bool = bool(_boss_cleared.get(i, false))
		var icon: String = "✓" if b_ok else "○"
		var prefix: String = "▸ " if sel else "  "
		var line: String = "%s%s %s  —  %s   [L:%d/%d · P:%d/%d]" % [
			prefix, icon, str(mod.get("title", "")), str(mod.get("commands_preview", "")),
			l_done, total_ex, p_done, total_ex
		]
		var col: Color = COL_ACTIVE if sel else (COL_OK if b_ok else COL_TEXT)
		_canvas.draw_string(font, Vector2(x, cy), line, HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, col)
		_row_hitboxes.append({"action": "mod", "idx": i, "rect": Rect2(x - 8.0, cy - 16.0, w, 28.0)})
		cy += 34.0

	_canvas.draw_line(Vector2(x, cy + 4.0), Vector2(x + 220.0, cy + 4.0), COL_HAIRLINE, 1.0)
	cy += 28.0
	var back_idx: int = CurriculumClass.MODULES.size()
	var back_sel: bool = (_mod_cursor == back_idx)
	_canvas.draw_string(font, Vector2(x, cy), ("▸ " if back_sel else "  ") + "← Volver", HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE if back_sel else COL_MUTED)
	_row_hitboxes.append({"action": "mod", "idx": back_idx, "rect": Rect2(x - 8.0, cy - 16.0, 200.0, 26.0)})

	_canvas.draw_string(font, Vector2(x, cy + 44.0), "↑/k  ↓/j  •  [Enter/l] lección  •  [p] práctica  •  [b] prueba de campo  •  [r] reiniciar  •  [q/Esc] volver", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_exercise(x: float, y: float, w: float, font: Font) -> void:
	var mod: Dictionary = CurriculumClass.MODULES[_mod_idx]
	var exercises: Array = mod.get("exercises", [])
	var ex: Dictionary = exercises[clampi(_ex_idx, 0, exercises.size() - 1)]
	var mode_lbl: String = "Lección Guiada" if _ex_mode == "lesson" else "Práctica Contrarreloj"

	_canvas.draw_string(font, Vector2(x, y), "%s: %s" % [mode_lbl, str(mod.get("title", ""))], HORIZONTAL_ALIGNMENT_LEFT, int(w), 17, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, y + 24.0), "Ejercicio %d de %d   •   Racha: x%d   •   Puntaje: %d" % [_ex_idx + 1, exercises.size(), _streak, _score], HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)

	var cy: float = y + 60.0
	_canvas.draw_string(font, Vector2(x, cy), "Misión:", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_ACTIVE)
	cy += 22.0
	_canvas.draw_string(font, Vector2(x, cy), str(ex.get("ask", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_TEXT)
	cy += 28.0

	if _ex_mode == "lesson":
		var card: Dictionary = ex.get("tool_card", {})
		_canvas.draw_string(font, Vector2(x, cy), "Herramienta: %s  —  %s" % [str(card.get("syntax", "")), str(card.get("explain", ""))], HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_OK)
		cy += 22.0
		_canvas.draw_string(font, Vector2(x, cy), "Ejemplo    : %s" % str(card.get("example", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)
		cy += 28.0
	else:
		var elapsed: float = maxf(0.0, p._pulse - _timer_start)
		_canvas.draw_string(font, Vector2(x, cy), "Tiempo: %.1fs   (sin guía — resuelve en 1 paso para +250 pts)" % elapsed, HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_TITLE)
		cy += 28.0

	cy = _draw_terminal_hairline_block(x, cy, w, font, str(ex.get("hint", "")))
	_draw_input_box(x, cy + 12.0, w, font)
	_canvas.draw_string(font, Vector2(x, cy + 88.0), "Escribe comando  •  [Enter] ejecutar  •  [Tab] completar  •  [F1] pista  •  [Esc] menú", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_result(x: float, y: float, w: float, font: Font) -> void:
	var is_opt: bool = bool(_analysis.get("is_optimal", false))
	var pts: int = int(_analysis.get("pts", 0))
	var title: String = ("⚡ Atajo óptimo (+%d pts · Racha x%d · %.1fs)" % [pts, _streak, _last_elapsed]) if is_opt else ("✓ Objetivo completado (+%d pts · %.1fs)" % [pts, _last_elapsed])
	_canvas.draw_string(font, Vector2(x, y), title, HORIZONTAL_ALIGNMENT_LEFT, int(w), 17, COL_OK if is_opt else COL_ACTIVE)

	var cy: float = y + 44.0
	_canvas.draw_string(font, Vector2(x, cy), "Tu comando     : %s" % str(_analysis.get("cmd", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_TEXT)
	cy += 24.0
	_canvas.draw_string(font, Vector2(x, cy), "Solución óptima: %s" % str(_analysis.get("optimal", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_OK)
	cy += 36.0

	_canvas.draw_line(Vector2(x, cy), Vector2(x + w, cy), COL_HAIRLINE, 1.0)
	cy += 24.0
	_canvas.draw_string(font, Vector2(x, cy), "Desglose del comando:", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_TITLE)
	cy += 24.0
	var breakdown: Array = _analysis.get("breakdown", [])
	for item: Array in breakdown:
		_canvas.draw_string(font, Vector2(x + 12.0, cy), "%s  =  %s" % [str(item[0]), str(item[1])], HORIZONTAL_ALIGNMENT_LEFT, int(w - 12.0), 14, COL_TEXT)
		cy += 22.0
	cy += 8.0
	_canvas.draw_line(Vector2(x, cy), Vector2(x + w, cy), COL_HAIRLINE, 1.0)

	_canvas.draw_string(font, Vector2(x, cy + 32.0), "[Enter] siguiente  •  [r] repetir  •  [q / Esc] módulos", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_boss(x: float, y: float, w: float, font: Font) -> void:
	var mod: Dictionary = CurriculumClass.MODULES[_mod_idx]
	var steps: Array = mod.get("boss_steps", [])
	var shields_str: String = ""
	for i: int in range(3):
		shields_str += "◈ " if i < _shields else "◇ "
	_canvas.draw_string(font, Vector2(x, y), "Prueba de Campo: %s   %s" % [str(mod.get("boss_name", "")), shields_str], HORIZONTAL_ALIGNMENT_LEFT, int(w), 17, COL_ERR)
	_canvas.draw_string(font, Vector2(x, y + 24.0), "Paso %d de %d   •   Racha: x%d   •   Puntaje: %d" % [_boss_step_idx + 1, steps.size(), _streak, _score], HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)

	var cy: float = y + 58.0
	for i: int in range(steps.size()):
		var st: Dictionary = steps[i]
		var marker: String = "✓ " if i < _boss_step_idx else ("▸ " if i == _boss_step_idx else "○ ")
		var col: Color = COL_OK if i < _boss_step_idx else (COL_ACTIVE if i == _boss_step_idx else COL_MUTED)
		var txt: String = str(st.get("ask", "")) if i == _boss_step_idx else str(st.get("title", ""))
		_canvas.draw_string(font, Vector2(x, cy), marker + txt, HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, col)
		cy += 24.0

	cy += 10.0
	var cur_st: Dictionary = steps[clampi(_boss_step_idx, 0, steps.size() - 1)]
	cy = _draw_terminal_hairline_block(x, cy, w, font, str(cur_st.get("hint", "")))
	_draw_input_box(x, cy + 12.0, w, font)
	_canvas.draw_string(font, Vector2(x, cy + 88.0), "Escribe comando  •  [Enter] ejecutar  •  [Tab] completar  •  [F1] pista  •  [Esc] módulos", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_boss_clear(x: float, y: float, w: float, font: Font) -> void:
	_canvas.draw_string(font, Vector2(x, y), "✓ Prueba de Campo Superada", HORIZONTAL_ALIGNMENT_LEFT, int(w), 18, COL_OK)
	var cy: float = y + 42.0
	_canvas.draw_string(font, Vector2(x, cy), "Puntaje acumulado : %d pts" % _score, HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE)
	_canvas.draw_string(font, Vector2(x, cy + 26.0), "Escudos intactos  : %d / 3" % _shields, HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, cy + 52.0), "Mejor racha       : x%d" % _best_streak, HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_TEXT)
	_canvas.draw_string(font, Vector2(x, cy + 96.0), "[Enter / Esc] módulos  •  [r] reintentar", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_ssh_menu(x: float, y: float, w: float, font: Font) -> void:
	_canvas.draw_string(font, Vector2(x, y), "Escalada SSH", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, y + 26.0), "Explora cada nodo libremente con comandos reales, halla la clave y salta al siguiente servidor.", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)
	_canvas.draw_string(font, Vector2(x, y + 52.0), "Nodos infiltrados: %d / %d   •   Puntaje: %d" % [_ssh_cleared.size(), CurriculumClass.SSH_LEVELS.size(), _score], HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_OK)
	_canvas.draw_string(font, Vector2(x, y + 84.0), "Selecciona un nodo:", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)

	var cy: float = y + 116.0
	for i: int in range(CurriculumClass.SSH_LEVELS.size()):
		var lv: Dictionary = CurriculumClass.SSH_LEVELS[i]
		var sel: bool = (_ssh_cursor == i)
		var unlocked: bool = is_ssh_unlocked(i)
		var cleared: bool = bool(_ssh_cleared.get(i, false))
		var icon: String = "✓" if cleared else ("○" if unlocked else "🔒")
		var prefix: String = "▸ " if sel else "  "
		var line: String = "%s%s %s → %s  —  %s   (%s)" % [
			prefix, icon, str(lv.get("node_from", "")), str(lv.get("node_to", "")),
			str(lv.get("title", "")), str(lv.get("tools", ""))
		]
		var col: Color = COL_ACTIVE if sel else (COL_OK if cleared else (COL_TEXT if unlocked else COL_MUTED))
		_canvas.draw_string(font, Vector2(x, cy), line, HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, col)
		if unlocked:
			_row_hitboxes.append({"action": "ssh", "idx": i, "rect": Rect2(x - 8.0, cy - 16.0, w, 28.0)})
		cy += 34.0

	_canvas.draw_line(Vector2(x, cy + 4.0), Vector2(x + 220.0, cy + 4.0), COL_HAIRLINE, 1.0)
	cy += 28.0
	var back_idx: int = CurriculumClass.SSH_LEVELS.size()
	var back_sel: bool = (_ssh_cursor == back_idx)
	_canvas.draw_string(font, Vector2(x, cy), ("▸ " if back_sel else "  ") + "← Volver", HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE if back_sel else COL_MUTED)
	_row_hitboxes.append({"action": "ssh", "idx": back_idx, "rect": Rect2(x - 8.0, cy - 16.0, 200.0, 26.0)})

	_canvas.draw_string(font, Vector2(x, cy + 44.0), "↑/k arriba  •  ↓/j abajo  •  [Enter] conectar  •  [q / Esc] volver", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_ssh_level(x: float, y: float, w: float, font: Font) -> void:
	var lv: Dictionary = CurriculumClass.SSH_LEVELS[_ssh_idx]
	_canvas.draw_string(font, Vector2(x, y), "Escalada SSH: %s → %s (%s)" % [str(lv.get("node_from", "")), str(lv.get("node_to", "")), str(lv.get("title", ""))], HORIZONTAL_ALIGNMENT_LEFT, int(w), 17, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, y + 24.0), "Herramientas sugeridas: %s   •   Entrega: ssh %s <clave>" % [str(lv.get("tools", "")), str(lv.get("node_to", ""))], HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_OK)

	var cy: float = y + 58.0
	_canvas.draw_string(font, Vector2(x, cy), "Misión:", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_ACTIVE)
	cy += 22.0
	_canvas.draw_string(font, Vector2(x, cy), str(lv.get("mission", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_TEXT)
	cy += 28.0

	cy = _draw_terminal_hairline_block(x, cy, w, font, str(lv.get("hint", "")))
	_draw_input_box(x, cy + 12.0, w, font)
	_canvas.draw_string(font, Vector2(x, cy + 88.0), "Explora libremente  •  [Enter] ejecutar  •  [Tab] completar  •  [F1] pista  •  [Esc] nodos", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_ssh_clear(x: float, y: float, w: float, font: Font) -> void:
	var lv: Dictionary = CurriculumClass.SSH_LEVELS[_ssh_idx]
	_canvas.draw_string(font, Vector2(x, y), "✓ Conexión establecida con %s" % str(lv.get("node_to", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 18, COL_OK)
	var cy: float = y + 40.0
	_canvas.draw_string(font, Vector2(x, cy), "Autenticación verificada en %s (%.1fs)  •  +400 pts" % [str(lv.get("title", "")), _last_elapsed], HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_TEXT)
	_canvas.draw_string(font, Vector2(x, cy + 28.0), "Puntaje total: %d pts   •   Nodos superados: %d/%d" % [_score, _ssh_cleared.size(), CurriculumClass.SSH_LEVELS.size()], HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE)
	var next_lbl: String = "[Enter] siguiente nodo" if _ssh_idx + 1 < CurriculumClass.SSH_LEVELS.size() else "[Enter] volver a nodos"
	_canvas.draw_string(font, Vector2(x, cy + 74.0), "%s  •  [q / Esc] lista de nodos" % next_lbl, HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_guide_menu(x: float, y: float, w: float, font: Font) -> void:
	_canvas.draw_string(font, Vector2(x, y), "Guía de Comandos", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, y + 26.0), "Referencia rápida de sintaxis y ejemplos reales usados en la academia.", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)

	var cy: float = y + 70.0
	for i: int in range(CurriculumClass.GUIDE_SECTIONS.size()):
		var sec: Dictionary = CurriculumClass.GUIDE_SECTIONS[i]
		var sel: bool = (_guide_cursor == i)
		_canvas.draw_string(font, Vector2(x, cy), ("▸ " if sel else "  ") + str(sec.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE if sel else COL_TEXT)
		_canvas.draw_string(font, Vector2(x + 22.0, cy + 19.0), str(sec.get("desc", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w - 22.0), 13, COL_MUTED)
		_row_hitboxes.append({"action": "guide", "idx": i, "rect": Rect2(x - 8.0, cy - 16.0, w, 40.0)})
		cy += 48.0

	_canvas.draw_line(Vector2(x, cy + 4.0), Vector2(x + 220.0, cy + 4.0), COL_HAIRLINE, 1.0)
	cy += 28.0
	var back_idx: int = CurriculumClass.GUIDE_SECTIONS.size()
	var back_sel: bool = (_guide_cursor == back_idx)
	_canvas.draw_string(font, Vector2(x, cy), ("▸ " if back_sel else "  ") + "← Volver", HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE if back_sel else COL_MUTED)
	_row_hitboxes.append({"action": "guide", "idx": back_idx, "rect": Rect2(x - 8.0, cy - 16.0, 200.0, 26.0)})
	_canvas.draw_string(font, Vector2(x, cy + 44.0), "↑/k arriba  •  ↓/j abajo  •  [Enter] leer  •  [q / Esc] volver", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_guide_detail(x: float, y: float, w: float, font: Font) -> void:
	var sec: Dictionary = CurriculumClass.GUIDE_SECTIONS[_guide_idx]
	_canvas.draw_string(font, Vector2(x, y), str(sec.get("title", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 18, COL_TITLE)
	_canvas.draw_string(font, Vector2(x, y + 26.0), str(sec.get("desc", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)

	var cy: float = y + 66.0
	_canvas.draw_line(Vector2(x, cy - 14.0), Vector2(x + w, cy - 14.0), COL_HAIRLINE, 1.0)
	var entries: Array = sec.get("entries", [])
	for e_var: Variant in entries:
		var e: Dictionary = e_var
		_canvas.draw_string(font, Vector2(x, cy), str(e.get("cmd", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE)
		_canvas.draw_string(font, Vector2(x + 16.0, cy + 20.0), str(e.get("explain", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w - 16.0), 14, COL_TEXT)
		_canvas.draw_string(font, Vector2(x + 16.0, cy + 40.0), "Ej: " + str(e.get("ex", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w - 16.0), 13, COL_OK)
		cy += 68.0
	_canvas.draw_line(Vector2(x, cy - 8.0), Vector2(x + w, cy - 8.0), COL_HAIRLINE, 1.0)

	cy += 22.0
	_canvas.draw_string(font, Vector2(x, cy), "▸ ← Volver a Guía", HORIZONTAL_ALIGNMENT_LEFT, int(w), 15, COL_ACTIVE)
	_row_hitboxes.append({"action": "back_guide", "idx": 0, "rect": Rect2(x - 8.0, cy - 16.0, 240.0, 26.0)})
	_canvas.draw_string(font, Vector2(x, cy + 36.0), "[Enter / q / Esc] volver", HORIZONTAL_ALIGNMENT_LEFT, int(w), 13, COL_MUTED)


func _draw_terminal_hairline_block(x: float, y: float, w: float, font: Font, hint_text: String) -> float:
	_canvas.draw_string(font, Vector2(x, y), "Terminal (%s):" % _sandbox_shell.vfs.current_path, HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)
	var top_y: float = y + 12.0
	_canvas.draw_line(Vector2(x, top_y), Vector2(x + w, top_y), COL_HAIRLINE, 1.0)

	var cy: float = top_y + 22.0
	if _term_lines.is_empty():
		_canvas.draw_string(font, Vector2(x + 4.0, cy), "(Escribe un comando real como 'ls', 'pwd' o 'cat' para explorar)", HORIZONTAL_ALIGNMENT_LEFT, int(w - 8.0), 14, COL_MUTED)
		cy += 22.0
	else:
		for item: Dictionary in _term_lines:
			_canvas.draw_string(font, Vector2(x + 4.0, cy), str(item.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, int(w - 8.0), 14, item.get("color", COL_TEXT))
			cy += 21.0

	if _show_hint and not hint_text.is_empty():
		_canvas.draw_string(font, Vector2(x + 4.0, cy), "Pista: " + hint_text, HORIZONTAL_ALIGNMENT_LEFT, int(w - 8.0), 14, COL_ACTIVE)
		cy += 22.0

	var bot_y: float = cy - 4.0
	_canvas.draw_line(Vector2(x, bot_y), Vector2(x + w, bot_y), COL_HAIRLINE, 1.0)
	return bot_y


func _draw_input_box(x: float, y: float, w: float, font: Font) -> void:
	_canvas.draw_string(font, Vector2(x, y + 12.0), "Tu comando:", HORIZONTAL_ALIGNMENT_LEFT, int(w), 14, COL_MUTED)
	var box := Rect2(x, y + 20.0, minf(w, 680.0), 34.0)
	_canvas.draw_rect(box, COL_INPUT_BG)
	_canvas.draw_rect(box, COL_INPUT_BORDER, false, 1.0)
	var blink: String = "█" if int(floor(p._pulse * 2.0)) % 2 == 0 else ""
	var prompt_txt: String = "%s %s%s" % [_sandbox_shell.get_prompt_string(), _input_text, blink]
	_canvas.draw_string(font, Vector2(box.position.x + 12.0, box.position.y + 22.0), prompt_txt, HORIZONTAL_ALIGNMENT_LEFT, int(box.size.x - 24.0), 14, COL_TEXT)
