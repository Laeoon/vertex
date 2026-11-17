class_name Profile
extends Control

## Profile Controller
## Implements full interactivity for LA BÓVEDA // 5-Tab Hub using native Control containers.

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")
const UnixShellEngine = preload("res://juego/system/unix_shell_engine.gd")
const VaultIdCard = preload("res://escenas/menu/vault/vault_id_card.gd")
const VaultBadgesTab = preload("res://escenas/menu/vault/vault_badges_tab.gd")
const VaultTermlinkTab = preload("res://escenas/menu/vault/vault_termlink_tab.gd")
const VaultAcademiaTab = preload("res://escenas/menu/vault/vault_academia_tab.gd")
const VaultMusicboxTab = preload("res://escenas/menu/vault/vault_musicbox_tab.gd")

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

var _cyber_bg := CyberBackgroundClass.new()
var _shell_engine: UnixShellEngine = UnixShellEngine.new()

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
	"play_time_seconds": 142,
	"best_streak": 8,
	"total_attempts": 24,
	"total_wins": 20,
	"total_losses": 4,
	"win_rate": 83.3,
	"levels_detail": [],
	"badges": ["initiate_link", "dijkstra_master", "heist_clear", "hacker_elite"],
	"decrypted_enc_files": []
}

var world_progress: Dictionary = {
	"heist": {"stars": 0, "levels": []},
	"hacker": {"stars": 0, "levels": []},
	"cybersecurity": {"stars": 0, "levels": []},
}

# UI Container references
var _root_margin: MarginContainer
var _main_hbox: HBoxContainer
var _left_card: PanelContainer
var _right_vbox: VBoxContainer
var _tab_bar_hbox: HBoxContainer
var _content_panel: PanelContainer
var _tab_containers: Array[Control] = []
var _id_card: VaultIdCard
# Tab modules are kept alive here so their signal lambdas stay valid.
var _tab_modules: Array[RefCounted] = []


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	_load_profile()
	_load_stats()
	start_cli_course(0)
	
	_build_ui()
	
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


func _set_active_tab(idx: int) -> void:
	_active_tab_idx = clampi(idx, 0, _tab_containers.size() - 1)
	_play_click_sfx()
	for i in range(_tab_containers.size()):
		_tab_containers[i].visible = (i == _active_tab_idx)
		if i < _tab_bar_hbox.get_child_count():
			var btn := _tab_bar_hbox.get_child(i) as Button
			if btn != null:
				var tcolor: Color = ProfileRendererClass.TABS[i].get("color", BrandClass.ACCENT)
				if i == _active_tab_idx:
					btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#141C26"), Color.TRANSPARENT, Color.TRANSPARENT, tcolor))
					btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#141C26"), Color.TRANSPARENT, Color.TRANSPARENT, tcolor))
					btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#141C26"), Color.TRANSPARENT, Color.TRANSPARENT, tcolor))
				else:
					btn.add_theme_stylebox_override("normal", ProfileRendererClass.make_surface_style(Color("#0E131A")))
					btn.add_theme_stylebox_override("hover", ProfileRendererClass.make_surface_style(Color("#141C26")))
					btn.add_theme_stylebox_override("pressed", ProfileRendererClass.make_surface_style(Color("#141C26")))
	if _active_tab_idx == 2:
		var cli_input := find_child("CliLineEdit", true, false) as LineEdit
		if cli_input != null and cli_input.is_inside_tree():
			cli_input.grab_focus()
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
	var lesson: Dictionary = VaultModules.TERMINAL_ACADEMY_LESSONS[course_idx]
	_cli_output_lines.append("╔══════════════════════════════════════════════════════╗")
	_cli_output_lines.append("║ VERTEX // BASH LAB tty1 — " + str(lesson.get("title", "")))
	_cli_output_lines.append("╚══════════════════════════════════════════════════════╝")
	_cli_output_lines.append("Objetivo: " + str(lesson.get("objective", "")))
	var steps: Array = lesson.get("steps", [])
	if steps.size() > 0:
		_cli_output_lines.append(str(steps[0].get("instruction", "")))
	if _shell_engine != null:
		_cli_output_lines.append("operator@vertex-vault:" + _shell_engine.vfs.current_path + "$ ls")
		var ls_out: String = _shell_engine.execute_command_line("ls")
		if ls_out != "":
			_cli_output_lines.append(ls_out)


func _execute_cli_command(cmd: String) -> void:
	_cli_output_lines.append("operator@vertex-vault:~$ " + cmd)
	var lesson: Dictionary = VaultModules.TERMINAL_ACADEMY_LESSONS[_active_cli_course]
	var steps: Array = lesson.get("steps", [])
	if _cli_course_step < steps.size():
		var expected: Dictionary = steps[_cli_course_step]
		var check_sub: String = str(expected.get("check_substr", ""))
		if check_sub == "" or cmd.contains(check_sub):
			_cli_course_step += 1
			_cli_output_lines.append(str(expected.get("success_msg", "[✓ OK]")))
			if _cli_course_step < steps.size():
				_cli_output_lines.append(str(steps[_cli_course_step].get("instruction", "")))
			else:
				_cli_output_lines.append("[✓] ¡Módulo de Academia completado!")
		else:
			_cli_output_lines.append("[!] Comando no esperado para este paso.")


static func build_level_rows(world_id: String, _progress_cfg: ConfigFile, _stats_cfg: ConfigFile) -> Array:
	var rows: Array = []
	for i in range(5):
		rows.append({
			"level_id": "%s_%02d" % [world_id, i + 1],
			"title": "Misión %s 0%d" % [world_id.capitalize(), i + 1],
			"stars": 3,
			"completed": true
		})
	return rows


func _load_profile() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://profile.cfg")
	if err == OK:
		player_name = str(cfg.get_value("profile", "player_name", "Jugador"))
		_featured_badge_title = str(cfg.get_value("profile", "featured_badge", "ENLACE INICIAL"))


func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "player_name", player_name)
	cfg.set_value("profile", "featured_badge", _featured_badge_title)
	cfg.save("user://profile.cfg")


func _load_stats() -> void:
	progress = ProgressUtilClass.cargar_progreso()
	_progress_cfg = ConfigFile.new()
	if _progress_cfg.load(ProgressUtilClass.get_progress_file_path()) == OK:
		var total_stars: int = 0
		var completed_levels: int = 0
		for key: String in _progress_cfg.get_section_keys("estrellas"):
			if key.ends_with("_mejor_coste"):
				continue
			var st_cnt: int = int(_progress_cfg.get_value("estrellas", key, 0))
			if st_cnt > 0:
				completed_levels += 1
			total_stars += st_cnt
		stats["levels_completed"] = completed_levels
		stats["total_stars"] = total_stars
	var sm = get_node_or_null("/root/SlotManager")
	if sm != null and sm.has_method("get_stats_path"):
		_stats_cfg = ConfigFile.new()
		if _stats_cfg.load(str(sm.call("get_stats_path"))) == OK:
			stats["play_time_seconds"] = int(_stats_cfg.get_value("stats", "play_time", 142))
			stats["best_streak"] = int(_stats_cfg.get_value("stats", "best_streak", 8))
			stats["total_wins"] = int(_stats_cfg.get_value("stats", "total_wins", 20))
			stats["total_losses"] = int(_stats_cfg.get_value("stats", "total_losses", 4))
			var tot: int = int(stats["total_wins"]) + int(stats["total_losses"])
			stats["win_rate"] = (float(stats["total_wins"]) / float(tot)) * 100.0 if tot > 0 else 83.3


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("#090C10")
	add_child(bg)
	
	_root_margin = MarginContainer.new()
	_root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_margin.add_theme_constant_override("margin_left", 16)
	_root_margin.add_theme_constant_override("margin_right", 16)
	_root_margin.add_theme_constant_override("margin_top", 16)
	_root_margin.add_theme_constant_override("margin_bottom", 16)
	add_child(_root_margin)
	
	_main_hbox = HBoxContainer.new()
	_main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_hbox.add_theme_constant_override("separation", 14)
	_root_margin.add_child(_main_hbox)
	
	_id_card = VaultIdCard.new(self)
	_left_card = _id_card.build(_main_hbox)
	
	
	_right_vbox = VBoxContainer.new()
	_right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_vbox.add_theme_constant_override("separation", 10)
	_main_hbox.add_child(_right_vbox)
	
	_tab_bar_hbox = HBoxContainer.new()
	_tab_bar_hbox.custom_minimum_size = Vector2(0, 44)
	_tab_bar_hbox.add_theme_constant_override("separation", 4)
	_right_vbox.add_child(_tab_bar_hbox)
	
	for tab_i in range(ProfileRendererClass.TABS.size()):
		var tdict: Dictionary = ProfileRendererClass.TABS[tab_i]
		var tbtn := Button.new()
		tbtn.text = str(tdict.get("label", ""))
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtn.custom_minimum_size = Vector2(0, 44)
		tbtn.add_theme_font_size_override("font_size", 12)
		tbtn.pressed.connect(func() -> void: _set_active_tab(tab_i))
		_tab_bar_hbox.add_child(tbtn)
	
	_content_panel = PanelContainer.new()
	_content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_panel.add_theme_stylebox_override("panel", ProfileRendererClass.make_surface_style(Color("#0E131A"), Color("#1E2736")))
	_right_vbox.add_child(_content_panel)
	
	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 12)
	content_margin.add_theme_constant_override("margin_top", 12)
	content_margin.add_theme_constant_override("margin_right", 12)
	content_margin.add_theme_constant_override("margin_bottom", 12)
	_content_panel.add_child(content_margin)
	
	for tab_i in range(5):
		var tc := Control.new()
		tc.set_anchors_preset(Control.PRESET_FULL_RECT)
		tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tc.visible = (tab_i == 0)
		content_margin.add_child(tc)
		_tab_containers.append(tc)
		_build_tab_content(tab_i, tc)
	
	add_child(ProfileRendererClass.create_crt_overlay())



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
			_tab_modules.append(musicbox_tab)
			musicbox_tab.build(container)
		4:
			_build_tab_cosmeticos(container)


func update_featured_badge_label() -> void:
	if _id_card != null:
		_id_card.refresh_featured()

func _build_tab_cosmeticos(container: Control) -> void:
	var ctrl := Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.draw.connect(func() -> void:
		ProfileRendererClass.draw_cosmetics_maintenance(ctrl, Rect2(Vector2.ZERO, ctrl.size), font, font_size, big_font_size, _pulse)
	)
	container.add_child(ctrl)
