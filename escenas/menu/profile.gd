class_name Profile
extends Control

## Profile Controller
## Implements full interactivity for LA BÓVEDA // 5-Tab Hub using native Control containers.

const BrandClass = preload("res://juego/ui/brand.gd")
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")
const VaultStoreClass = preload("res://juego/system/vault_store.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")
const UnixShellEngine = preload("res://juego/system/unix_shell_engine.gd")
const SlotManagerClass = preload("res://juego/system/slot_manager.gd")
const VaultBadgesTab = preload("res://escenas/menu/vault/vault_badges_tab.gd")
const VaultTermlinkTab = preload("res://escenas/menu/vault/vault_termlink_tab.gd")
const VaultAcademiaTab = preload("res://escenas/menu/vault/vault_academia_tab.gd")
const VaultAcademyApp = preload("res://escenas/menu/vault/vault_academy_app.gd")
const VaultMusicboxTab = preload("res://escenas/menu/vault/vault_musicbox_tab.gd")
const VaultArcadeTab = preload("res://escenas/menu/vault/vault_arcade_tab.gd")

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

var _shell_engine: UnixShellEngine = UnixShellEngine.new()
var _tab_built: Array[bool] = [false, false, false, false, false]
var _badges_canvas: Control = null
var _termlink_canvas: Control = null
var _academia_canvas: Control = null
var _academy_app: VaultAcademyApp = null
var _academy_overlay: Control = null
var _eq_control: Control = null
var _cosmetics_control: Control = null
var _musicbox_tab: VaultMusicboxTab = null
var _arcade_tab: VaultArcadeTab = null
var _courses_completed: Dictionary = {}

var player_name: String = "Jugador"
var _active_tab_idx: int = 0

var _selected_badge_idx: int = 0
var _featured_badge_title: String = "ENLACE INICIAL"
var _selected_enc_idx: int = 0
var _enc_unlocked: Dictionary = {}
var _enc_attempts: int = 4
var _enc_console_lines: Array = ["VERTEX // KERNEL_LINK TERMLINK v4.08 Initialized.", "Type password or click hex candidate."]
var _enc_input_text: String = ""
var _removed_duds: Array = []

var _active_cli_course: int = 0
var _cli_course_step: int = 0
var _cli_output_lines: Array = ["VERTEX TERMINAL LAB v4.08", "Type 'help' or select course from left panel."]
var _cli_input_text: String = ""
var _cli_history: Array[String] = []
var _cli_history_idx: int = -1

var _music_filter_idx: int = 0
var _music_scroll_offset: int = 0
var _selected_music_idx: int = 0
var _pinned_menu_track: String = "Pink Bloom"
var _pinned_game_track: String = "Neon Subroutines"
var _music_is_playing: bool = true

var progress: Dictionary = {}
var _progress_cfg: ConfigFile = null
var _stats_cfg: ConfigFile = null

var stats: Dictionary = {
	"levels_completed": 0,
	"total_stars": 0,
	"play_time_seconds": 0,
	"best_streak": 0,
	"total_attempts": 0,
	"total_wins": 0,
	"total_losses": 0,
	"win_rate": 0.0,
	"levels_detail": [],
	"badges": [],
	"decrypted_enc_files": []
}

var world_progress: Dictionary = {
	"heist": {"stars": 0, "levels": []},
	"hacker": {"stars": 0, "levels": []},
	"cybersecurity": {"stars": 0, "levels": []},
}

# 2.5D Drum & _draw() Shell state (Phase B1)
var _drum_angle: float = 0.0
var _drum_target: float = 0.0
var _drum_vel: float = 0.0
var _drum_lock_flash: float = 1.0
var _active_slot: int = 1
var _hitboxes: Array[Dictionary] = []
var _idle_blink_accum: float = 0.0

# UI Container references
var _content_panel: PanelContainer
var _tab_containers: Array[Control] = []
# Tab modules are kept alive here so their signal lambdas stay valid.
var _tab_modules: Array[RefCounted] = []


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	_active_slot = SlotManagerClass.get_active_slot()
	_load_profile()
	_sync_shell_identity()
	_load_stats()
	start_cli_course(0)
	
	_build_ui()
	
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()


func _process(delta: float) -> void:
	_pulse += delta
	var diff: float = _drum_target - _drum_angle
	var force: float = diff * 180.0
	_drum_vel = (_drum_vel + force * delta) * exp(-13.0 * delta)
	_drum_angle += _drum_vel * delta
	_drum_lock_flash = maxf(0.0, _drum_lock_flash - delta * 2.4)

	if absf(diff) > 0.002 or absf(_drum_vel) > 0.002 or _drum_lock_flash > 0.01 or _active_tab_idx == 3:
		queue_redraw()

	_idle_blink_accum += delta
	if _academy_overlay != null and is_instance_valid(_academy_overlay) and _academy_overlay.visible:
		var scr: int = _academy_app.get_screen() if _academy_app != null else -1
		if scr == VaultAcademyApp.Screen.EXERCISE or scr == VaultAcademyApp.Screen.BOSS or scr == VaultAcademyApp.Screen.SSH_LEVEL:
			if _idle_blink_accum >= 0.5:
				_idle_blink_accum = 0.0
				_academy_overlay.queue_redraw()
	elif _active_tab_idx == 0 and _badges_canvas != null and is_instance_valid(_badges_canvas):
		_badges_canvas.queue_redraw()
	elif _active_tab_idx == 1 and _termlink_canvas != null and is_instance_valid(_termlink_canvas):
		if _idle_blink_accum >= 0.35:
			_idle_blink_accum = 0.0
			_termlink_canvas.queue_redraw()
	elif _active_tab_idx == 2 and _academia_canvas != null and is_instance_valid(_academia_canvas):
		if _idle_blink_accum >= 0.15:
			_idle_blink_accum = 0.0
			_academia_canvas.queue_redraw()
	elif _active_tab_idx == 3 and _musicbox_tab != null:
		_musicbox_tab.tick(delta)
	elif _active_tab_idx == 4 and _arcade_tab != null:
		_arcade_tab.tick(delta)


func _draw() -> void:
	var rank_info: Dictionary = ProfileRendererClass.get_rank_info(int(stats.get("total_stars", 0)))
	var shell_state: Dictionary = {
		"active_mode": _active_tab_idx,
		"drum_angle": _drum_angle,
		"drum_target": _drum_target,
		"drum_vel": _drum_vel,
		"drum_lock_flash": _drum_lock_flash,
		"slot_index": _active_slot,
		"player_name": player_name,
		"rank_tier": str(rank_info.get("tier", "RANGO I")),
		"total_stars": int(stats.get("total_stars", 0)),
		"featured_badge": _featured_badge_title,
		"pulse": _pulse,
	}
	_hitboxes = ProfileRendererClass.draw_boveda_shell(self, Rect2(Vector2.ZERO, size), font, shell_state)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			for hb: Dictionary in _hitboxes:
				var r: Rect2 = hb.get("rect", Rect2())
				if r.has_point(mb.position):
					var hid: String = str(hb.get("id", ""))
					if hid == "volver":
						_back_to_menu()
						accept_event()
						return
					elif hid == "slot":
						_cycle_slot()
						accept_event()
						return
					elif hid.begins_with("drum_"):
						var idx_val: int = int(hid.trim_prefix("drum_"))
						_set_active_tab(idx_val)
						accept_event()
						return
		elif mb.pressed and mb.position.x <= 316.0:
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_rotate_drum(1)
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_rotate_drum(-1)
				accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if _academy_app != null and _academy_app.is_open():
				if ke.keycode == KEY_ESCAPE:
					if _academy_app.handle_escape():
						close_academy_app()
					accept_event()
				return
			if _active_tab_idx == 4 and _arcade_tab != null and _arcade_tab.is_playing_game():
				if ke.keycode == KEY_ESCAPE:
					_arcade_tab.exit_game()
					accept_event()
				return
			if _active_tab_idx == 3 and _eq_control != null and is_instance_valid(_eq_control) and _eq_control.has_focus():
				return
			var focus_owner: Control = get_viewport().gui_get_focus_owner() if get_viewport() != null else null
			if focus_owner is LineEdit:
				return
			if ke.keycode == KEY_UP:
				_rotate_drum(-1)
				accept_event()
			elif ke.keycode == KEY_DOWN:
				_rotate_drum(1)
				accept_event()


func open_academy_app() -> void:
	if _academy_app != null:
		_academy_app.open_app()


func close_academy_app() -> void:
	if _academy_app != null:
		_academy_app.close_app()
	if _academia_canvas != null and is_instance_valid(_academia_canvas):
		_academia_canvas.grab_focus()
		_academia_canvas.queue_redraw()


func _rotate_drum(step: int) -> void:
	var count: int = ProfileRendererClass.TABS.size()
	if count <= 0:
		return
	var next_idx: int = posmod(_active_tab_idx + step, count)
	_set_active_tab(next_idx)


func _cycle_slot() -> void:
	_save_profile()
	_active_slot = (_active_slot % 3) + 1
	SlotManagerClass.set_active_slot(_active_slot)
	_load_profile()
	_sync_shell_identity()
	_load_stats()
	_play_click_sfx()
	queue_redraw()


func _sync_shell_identity() -> void:
	if _shell_engine == null:
		return
	var alias: String = _shell_engine.sanitize_username(player_name, "operador")
	_shell_engine.set_identity(alias, "boveda-lab", "BÓVEDA // KERNEL LAB — " + player_name.to_upper())


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


func _set_active_tab(idx: int) -> void:
	_active_tab_idx = clampi(idx, 0, _tab_containers.size() - 1)
	_drum_target = float(_active_tab_idx)
	var span: float = float(ProfileRendererClass.TABS.size())
	if span > 0.0:
		while _drum_target - _drum_angle > span * 0.5:
			_drum_angle += span
		while _drum_target - _drum_angle < -span * 0.5:
			_drum_angle -= span
	_drum_lock_flash = 1.0
	_ensure_tab_built(_active_tab_idx)
	_play_click_sfx()
	for i in range(_tab_containers.size()):
		_tab_containers[i].visible = (i == _active_tab_idx)
	if _active_tab_idx == 2 and _academia_canvas != null and is_instance_valid(_academia_canvas):
		_academia_canvas.grab_focus()
	elif _active_tab_idx == 3 and _eq_control != null and is_instance_valid(_eq_control):
		_eq_control.grab_focus()
	elif _active_tab_idx == 4 and _cosmetics_control != null and is_instance_valid(_cosmetics_control):
		_cosmetics_control.grab_focus()
	queue_redraw()


func _back_to_menu() -> void:
	_save_profile()
	_play_click_sfx()
	var st = get_node_or_null("/root/SceneTransition")
	if st != null and st.has_method("dive_out_to_scene"):
		st.dive_out_to_scene("res://escenas/main_menu.tscn", Vector2(230.0, 54.0))
	elif st != null and st.has_method("fade_to_scene"):
		st.fade_to_scene("res://escenas/main_menu.tscn")
	elif get_tree() != null:
		get_tree().change_scene_to_file("res://escenas/main_menu.tscn")


func start_cli_course(course_idx: int) -> void:
	if course_idx < 0 or course_idx >= VaultModules.TERMINAL_ACADEMY_LESSONS.size():
		return
	_active_cli_course = course_idx
	_cli_course_step = 0
	_cli_output_lines.clear()
	_sync_shell_identity()
	var lesson: Dictionary = VaultModules.TERMINAL_ACADEMY_LESSONS[course_idx]
	_cli_output_lines.append("┌──────────────────────────────────────────────────────┐")
	_cli_output_lines.append("│ BÓVEDA // KERNEL LAB — " + str(lesson.get("title", "")))
	_cli_output_lines.append("└──────────────────────────────────────────────────────┘")
	_cli_output_lines.append("Objetivo: " + str(lesson.get("objective", "")))
	var steps: Array = lesson.get("steps", [])
	if steps.size() > 0:
		_cli_output_lines.append("Paso 1: " + str(steps[0].get("instruction", "")))
	if _shell_engine != null:
		_cli_output_lines.append(_shell_engine.get_prompt_string() + "ls")
		var ls_out: String = _shell_engine.execute_command_line("ls")
		if ls_out != "":
			_cli_output_lines.append(ls_out)


func _execute_cli_command(cmd: String) -> void:
	_sync_shell_identity()
	var trimmed: String = cmd.strip_edges()
	_cli_output_lines.append(_shell_engine.get_prompt_string() + trimmed)
	if trimmed == "academy":
		_cli_output_lines.append(">> ABRIENDO APP CLI: VTX-ACADEMY (PANTALLA COMPLETA)...")
		open_academy_app()
		return
	elif trimmed == "fastfetch":
		_cli_output_lines.append("OS: VertexOS 4.7 | Host: boveda-lab | User: %s | 60 FPS" % player_name)
		return
	var shell_out: String = _shell_engine.execute_command_line(trimmed)
	if shell_out == "__CLEAR__":
		_cli_output_lines.clear()
		return
	if not shell_out.is_empty():
		_cli_output_lines.append(shell_out)

	var lesson: Dictionary = VaultModules.TERMINAL_ACADEMY_LESSONS[_active_cli_course]
	var steps: Array = lesson.get("steps", [])
	if _cli_course_step < steps.size():
		var expected: Dictionary = steps[_cli_course_step]
		var check_sub: String = str(expected.get("check_substr", ""))
		if check_sub == "" or trimmed.contains(check_sub):
			_cli_course_step += 1
			_cli_output_lines.append(str(expected.get("success_msg", "[✓ OK]")))
			if _cli_course_step < steps.size():
				_cli_output_lines.append(str(steps[_cli_course_step].get("instruction", "")))
			else:
				_courses_completed[_active_cli_course] = true
				_cli_output_lines.append("[✓] ¡Módulo de Academia completado!")
		else:
			_cli_output_lines.append("[!] Tip: prueba '%s' para avanzar al siguiente paso." % str(expected.get("expected_cmd", check_sub)))


static func build_level_rows(world_id: String, progress_cfg: ConfigFile, stats_cfg: ConfigFile) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var world_data: Dictionary = LevelRegistryClass.WORLDS.get(world_id, {})
	var levels: Array = world_data.get("levels", [])
	for entry_variant in levels:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var level_path: String = str(entry.get("path", ""))
		var level_id: String = level_path.get_file().trim_suffix(".json")
		if level_id.is_empty():
			continue
		var stars: int = 0
		var best_cost: float = 0.0
		if progress_cfg != null and progress_cfg.has_section("estrellas"):
			stars = maxi(0, int(progress_cfg.get_value("estrellas", level_id, 0)))
			best_cost = float(progress_cfg.get_value("estrellas", level_id + "_mejor_coste", 0.0))
		var attempts: int = 0
		if stats_cfg != null and stats_cfg.has_section("levels"):
			var wins: int = int(stats_cfg.get_value("levels", level_id + "_wins", 0))
			var losses: int = int(stats_cfg.get_value("levels", level_id + "_losses", 0))
			attempts = wins + losses
		rows.append({
			"level_id": level_id,
			"title": str(entry.get("title", level_id)),
			"stars": stars,
			"completed": stars > 0,
			"best_cost": best_cost,
			"attempts": attempts,
		})
	return rows


func _load_profile() -> void:
	var profile_data: Dictionary = VaultStoreClass.load_profile()
	player_name = str(profile_data.get("player_name", VaultStoreClass.DEFAULT_PLAYER_NAME))
	_featured_badge_title = str(profile_data.get("featured_badge", VaultStoreClass.DEFAULT_FEATURED_BADGE))

	var vault_data: Dictionary = VaultStoreClass.load_vault()
	var loaded_enc: Variant = vault_data.get("enc_unlocked", {})
	_enc_unlocked = loaded_enc.duplicate() if (loaded_enc is Dictionary) else {}
	stats["decrypted_enc_files"] = VaultStoreClass.resolve_decrypted_enc_files(_enc_unlocked)
	_pinned_menu_track = str(vault_data.get("pinned_menu_track", VaultStoreClass.DEFAULT_PINNED_MENU_TRACK))
	_pinned_game_track = str(vault_data.get("pinned_game_track", VaultStoreClass.DEFAULT_PINNED_GAME_TRACK))


func _save_profile() -> void:
	VaultStoreClass.save_profile(player_name, _featured_badge_title)
	VaultStoreClass.save_vault(_enc_unlocked, _pinned_menu_track, _pinned_game_track)
	stats["decrypted_enc_files"] = VaultStoreClass.resolve_decrypted_enc_files(_enc_unlocked)


func _load_stats() -> void:
	progress = ProgressUtilClass.cargar_progreso()
	_progress_cfg = ConfigFile.new()
	var completed_levels: int = 0
	var total_stars: int = int(progress.get("total_stars", 0))
	if _progress_cfg.load(ProgressUtilClass.get_progress_file_path()) == OK and _progress_cfg.has_section("estrellas"):
		for key: String in _progress_cfg.get_section_keys("estrellas"):
			if key.ends_with("_mejor_coste") or key == "total_stars":
				continue
			if int(_progress_cfg.get_value("estrellas", key, 0)) > 0:
				completed_levels += 1
	stats["levels_completed"] = completed_levels
	stats["total_stars"] = total_stars

	_stats_cfg = VaultStoreClass.load_stats_cfg()
	var summary: Dictionary = VaultStoreClass.load_stats_summary()
	stats["play_time_seconds"] = int(summary.get("play_time_seconds", 0))
	stats["best_streak"] = int(summary.get("best_streak", 0))
	stats["total_attempts"] = int(summary.get("total_attempts", 0))
	stats["total_wins"] = int(summary.get("total_wins", 0))
	stats["total_losses"] = int(summary.get("total_losses", 0))
	stats["win_rate"] = float(summary.get("win_rate", 0.0))

	for world_id: String in world_progress.keys():
		var rows: Array[Dictionary] = build_level_rows(world_id, _progress_cfg, _stats_cfg)
		var world_stars: int = 0
		for row: Dictionary in rows:
			world_stars += int(row.get("stars", 0))
		world_progress[world_id] = {"stars": world_stars, "levels": rows}


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_content_panel = PanelContainer.new()
	_content_panel.anchor_left = 0.0
	_content_panel.anchor_top = 0.0
	_content_panel.anchor_right = 1.0
	_content_panel.anchor_bottom = 1.0
	_content_panel.offset_left = 324.0
	_content_panel.offset_top = 54.0
	_content_panel.offset_right = -16.0
	_content_panel.offset_bottom = -16.0
	_content_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_content_panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 0)
	content_margin.add_theme_constant_override("margin_top", 0)
	content_margin.add_theme_constant_override("margin_right", 0)
	content_margin.add_theme_constant_override("margin_bottom", 0)
	_content_panel.add_child(content_margin)

	for tab_i in range(5):
		var tc := Control.new()
		tc.set_anchors_preset(Control.PRESET_FULL_RECT)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tc.visible = (tab_i == 0)
		content_margin.add_child(tc)
		_tab_containers.append(tc)
	_ensure_tab_built(0)
	_academy_app = VaultAcademyApp.new(self)
	_academy_overlay = _academy_app.build(self)
	queue_redraw()


func _ensure_tab_built(tab_idx: int) -> void:
	if tab_idx < 0 or tab_idx >= _tab_containers.size():
		return
	if _tab_built[tab_idx]:
		return
	_tab_built[tab_idx] = true
	_build_tab_content(tab_idx, _tab_containers[tab_idx])



func _build_tab_content(tab_idx: int, container: Control) -> void:
	match tab_idx:
		0:
			var badges_tab := VaultBadgesTab.new(self)
			_tab_modules.append(badges_tab)
			badges_tab.build(container)
		1:
			var termlink_tab := VaultTermlinkTab.new(self)
			_tab_modules.append(termlink_tab)
			termlink_tab.build(container)
		2:
			var academia_tab := VaultAcademiaTab.new(self)
			_tab_modules.append(academia_tab)
			academia_tab.build(container)
		3:
			var musicbox_tab := VaultMusicboxTab.new(self)
			_musicbox_tab = musicbox_tab
			_tab_modules.append(musicbox_tab)
			musicbox_tab.build(container)
		4:
			var arcade_tab := VaultArcadeTab.new(self)
			_arcade_tab = arcade_tab
			_tab_modules.append(arcade_tab)
			arcade_tab.build(container)


func update_featured_badge_label() -> void:
	queue_redraw()

func _build_tab_cosmeticos(container: Control) -> void:
	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.draw.connect(func() -> void:
		ProfileRendererClass.draw_cosmetics_maintenance(ctrl, Rect2(Vector2.ZERO, ctrl.size), font, font_size, big_font_size, _pulse)
	)
	_cosmetics_control = ctrl
	container.add_child(ctrl)
