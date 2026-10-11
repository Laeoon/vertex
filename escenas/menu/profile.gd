extends Control

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")
const ProfileRendererClass = preload("res://escenas/menu/profile_renderer.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

var _cyber_bg := CyberBackgroundClass.new()
var _renderer := ProfileRendererClass.new()

var player_name: String = "Jugador"
var _editing_name: bool = false
var _cursor_pos: int = 0
var _cursor_visible: bool = true
var _cursor_timer: float = 0.0

var _active_tab_idx: int = 0
var _hovered_tab_idx: int = -1
var _hovered_back: bool = false
var _hovered_name_box: bool = false

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
}

var world_progress: Dictionary = {
	"heist": {"stars": 0, "levels": []},
	"hacker": {"stars": 0, "levels": []},
	"cybersecurity": {"stars": 0, "levels": []},
}


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	_cyber_bg.show_hologram = false
	_load_profile()
	_load_stats()
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()
	queue_redraw()


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


func _set_active_tab(idx: int) -> void:
	if idx < 0 or idx >= ProfileRendererClass.TABS.size():
		return
	if _active_tab_idx != idx:
		_active_tab_idx = idx
		_play_click_sfx()
		_refresh_levels_detail()
		queue_redraw()


func _refresh_levels_detail() -> void:
	var active_wid: String = ProfileRendererClass.TABS[_active_tab_idx]["id"]
	stats["levels_detail"] = build_level_rows(active_wid, _progress_cfg, _stats_cfg)


func _input(event: InputEvent) -> void:
	var vp := get_viewport_rect().size

	if _editing_name:
		if event is InputEventKey and event.pressed:
			var k := event as InputEventKey
			match k.keycode:
				KEY_ENTER:
					_editing_name = false
					_save_profile()
					_play_click_sfx()
					queue_redraw()
				KEY_ESCAPE:
					_editing_name = false
					_load_profile()
					_play_click_sfx()
					queue_redraw()
				KEY_BACKSPACE:
					if _cursor_pos > 0:
						player_name = player_name.left(_cursor_pos - 1) + player_name.substr(_cursor_pos)
						_cursor_pos = maxi(0, _cursor_pos - 1)
						queue_redraw()
				KEY_DELETE:
					player_name = player_name.left(_cursor_pos) + player_name.substr(_cursor_pos + 1)
					queue_redraw()
				KEY_LEFT:
					_cursor_pos = maxi(0, _cursor_pos - 1)
					queue_redraw()
				KEY_RIGHT:
					_cursor_pos = mini(player_name.length(), _cursor_pos + 1)
					queue_redraw()
				KEY_HOME:
					_cursor_pos = 0
					queue_redraw()
				KEY_END:
					_cursor_pos = player_name.length()
					queue_redraw()
				_:
					if k.unicode > 0 and k.keycode != KEY_BACKSPACE and k.keycode != KEY_DELETE:
						var char_char: String = char(k.unicode)
						if char_char.is_valid_identifier() or char_char == " ":
							player_name = player_name.left(_cursor_pos) + char_char + player_name.substr(_cursor_pos)
							_cursor_pos += 1
							queue_redraw()
		return

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_save_profile()
				_play_click_sfx()
				var st = get_node_or_null("/root/SceneTransition")
				if st != null and st.has_method("fade_to_scene"):
					st.fade_to_scene("res://escenas/main_menu.tscn")
				elif get_tree() != null:
					get_tree().change_scene_to_file("res://escenas/main_menu.tscn")
			KEY_ENTER:
				_editing_name = true
				_cursor_pos = player_name.length()
				_cursor_timer = 0.0
				_play_click_sfx()
				queue_redraw()
			KEY_TAB, KEY_RIGHT, KEY_D:
				var total_tabs := ProfileRendererClass.TABS.size()
				_set_active_tab((_active_tab_idx + 1) % total_tabs)
			KEY_LEFT, KEY_A:
				var total_tabs := ProfileRendererClass.TABS.size()
				_set_active_tab((_active_tab_idx - 1 + total_tabs) % total_tabs)

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var prev_b := _hovered_back
		_hovered_back = _renderer.get_back_button_rect(vp).has_point(mpos)

		var prev_nb := _hovered_name_box
		_hovered_name_box = _renderer.get_name_box_rect(vp).has_point(mpos)

		var prev_ht := _hovered_tab_idx
		_hovered_tab_idx = -1
		for i in range(ProfileRendererClass.TABS.size()):
			if _renderer.get_tab_rect(i, vp).has_point(mpos):
				_hovered_tab_idx = i
				break

		if prev_b != _hovered_back or prev_nb != _hovered_name_box or prev_ht != _hovered_tab_idx:
			queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var mpos := mb.position
			if _renderer.get_back_button_rect(vp).has_point(mpos):
				_save_profile()
				_play_click_sfx()
				var st = get_node_or_null("/root/SceneTransition")
				if st != null and st.has_method("fade_to_scene"):
					st.fade_to_scene("res://escenas/main_menu.tscn")
				elif get_tree() != null:
					get_tree().change_scene_to_file("res://escenas/main_menu.tscn")
				return

			if _renderer.get_name_box_rect(vp).has_point(mpos):
				_editing_name = true
				_cursor_pos = player_name.length()
				_cursor_timer = 0.0
				_play_click_sfx()
				queue_redraw()
				return

			for i in range(ProfileRendererClass.TABS.size()):
				if _renderer.get_tab_rect(i, vp).has_point(mpos):
					_set_active_tab(i)
					return


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	_cyber_bg.update(delta, get_viewport_rect().size)
	if _editing_name:
		_cursor_timer += delta
		if _cursor_timer >= 0.45:
			_cursor_visible = not _cursor_visible
			_cursor_timer = 0.0
			queue_redraw()


func _load_profile() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://profile.cfg")
	if err == OK:
		player_name = cfg.get_value("profile", "player_name", "Jugador")
	else:
		player_name = "Jugador"


func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://profile.cfg")
	cfg.set_value("profile", "player_name", player_name)
	cfg.save("user://profile.cfg")


func _load_stats() -> void:
	stats = {
		"levels_completed": 0,
		"total_stars": 0,
		"play_time_seconds": 0,
		"best_streak": 0,
		"total_attempts": 0,
		"total_wins": 0,
		"total_losses": 0,
		"win_rate": 0.0,
		"levels_detail": [],
	}
	for wid in world_progress:
		world_progress[wid]["stars"] = 0
		world_progress[wid]["levels"] = []

	progress = ProgressUtilClass.cargar_progreso()

	_progress_cfg = ConfigFile.new()
	var err_p := _progress_cfg.load("user://progress.cfg")
	if err_p == OK:
		var total_stars: int = 0
		var completed_levels: int = 0
		var keys: PackedStringArray = _progress_cfg.get_section_keys("estrellas")

		for key in keys:
			if key.ends_with("_mejor_coste"):
				continue
			var stars: int = _progress_cfg.get_value("estrellas", key, 0)
			if stars > 0:
				completed_levels += 1
			total_stars += stars
			var best_cost: float = _progress_cfg.get_value("estrellas", key + "_mejor_coste", 0.0)

			for wid in world_progress:
				if key.begins_with(wid) or key.begins_with(wid.replace("-", "_")):
					world_progress[wid]["stars"] += stars
					world_progress[wid]["levels"].append({"id": key, "stars": stars, "best_cost": best_cost})
					break

		stats["levels_completed"] = completed_levels
		stats["total_stars"] = total_stars

	_stats_cfg = ConfigFile.new()
	if _stats_cfg.load("user://stats.cfg") == OK:
		stats["play_time_seconds"] = _stats_cfg.get_value("stats", "play_time", 0)
		stats["best_streak"] = _stats_cfg.get_value("stats", "best_streak", 0)
		stats["total_attempts"] = _stats_cfg.get_value("stats", "total_attempts", 0)
		stats["total_wins"] = _stats_cfg.get_value("stats", "total_wins", 0)
		stats["total_losses"] = _stats_cfg.get_value("stats", "total_losses", 0)
		var total: int = stats["total_wins"] + stats["total_losses"]
		stats["win_rate"] = float(stats["total_wins"]) / float(total) * 100.0 if total > 0 else 0.0

	_refresh_levels_detail()


static func build_level_rows(world_id: String, progress_cfg: ConfigFile, stats_cfg: ConfigFile) -> Array:
	var rows: Array = []
	var levels: Array = LevelRegistryClass.WORLDS.get(world_id, {}).get("levels", [])
	for cfg in levels:
		var path: String = cfg.get("path", "")
		var key: String = path.get_file().trim_suffix(".json")
		var stars: int = progress_cfg.get_value("estrellas", key, 0) if progress_cfg != null else 0
		var best_cost: float = progress_cfg.get_value("estrellas", key + "_mejor_coste", 0.0) if progress_cfg != null else 0.0
		var wins: int = stats_cfg.get_value("levels", key + "_wins", 0) if stats_cfg != null else 0
		var losses: int = stats_cfg.get_value("levels", key + "_losses", 0) if stats_cfg != null else 0
		rows.append({
			"key": key,
			"title": cfg.get("title", key),
			"stars": stars,
			"best_cost": best_cost,
			"wins": wins,
			"losses": losses,
			"attempts": wins + losses,
		})
	return rows


func loc(key: String) -> String:
	return LocUtil.loc(self, key)


func _draw() -> void:
	var vp := get_viewport_rect().size
	_cyber_bg.draw(self, vp)
	_renderer.draw(
		self,
		vp,
		font,
		font_size,
		big_font_size,
		_pulse,
		player_name,
		_editing_name,
		_cursor_pos,
		_cursor_visible,
		stats,
		world_progress,
		_active_tab_idx,
		_hovered_tab_idx,
		_hovered_back,
		_hovered_name_box,
		progress
	)
