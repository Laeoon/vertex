extends Control

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

const BrandClass = preload("res://juego/ui/brand.gd")

const CYAN: Color = BrandClass.ACCENT
const GRIS: Color = BrandClass.TEXT_DIM
const GRIS_OSCURO: Color = BrandClass.TEXT_DIM
const BLANCO: Color = BrandClass.TEXT
const AMARILLO: Color = BrandClass.WARNING
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")

const SECTION_X := 70.0
const SECTION_W_OFFSET := 140.0

var player_name: String = "Jugador"
var _editing_name: bool = false
var _cursor_pos: int = 0
var _cursor_visible: bool = true
var _cursor_timer: float = 0.0

var stats: Dictionary = {
	"levels_completed": 0,
	"total_stars": 0,
	"play_time_seconds": 0,
	"best_streak": 0,
	"total_attempts": 0,
	"total_wins": 0,
	"total_losses": 0,
	"win_rate": 0.0,
	"levels_detail": [],  # {id, stars, best_cost, wins, losses}
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
	_load_profile()
	_load_stats()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _editing_name:
		if event is InputEventKey and event.pressed:
			var k := event as InputEventKey
			match k.keycode:
				KEY_ENTER, KEY_ESCAPE:
					_editing_name = false
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
		return  # No procesar otros inputs mientras se edita

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_save_profile()
				SceneTransition.fade_to_scene("res://escenas/main_menu.tscn")
			KEY_ENTER:
				_editing_name = true
				_cursor_pos = player_name.length()
				_cursor_timer = 0.0
				queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	if _editing_name:
		_cursor_timer += delta
		if _cursor_timer >= 0.5:
			_cursor_visible = not _cursor_visible
			_cursor_timer = 0.0
			queue_redraw()
	else:
		queue_redraw()


func _load_profile() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://profile.cfg")
	if err == OK:
		player_name = cfg.get_value("profile", "player_name", "Jugador")


func _save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "player_name", player_name)
	cfg.save("user://profile.cfg")


func _load_stats() -> void:
	# Reset stats
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

	# Load progress from progress.cfg
	var progress_cfg := ConfigFile.new()
	if progress_cfg.load("user://progress.cfg") == OK:
		var total_stars: int = 0
		var completed_levels: int = 0
		var keys: PackedStringArray = progress_cfg.get_section_keys("estrellas")

		for key in keys:
			if key.ends_with("_mejor_coste"):
				continue
			var stars: int = progress_cfg.get_value("estrellas", key, 0)
			if stars > 0:
				completed_levels += 1
			total_stars += stars
			var best_cost: float = progress_cfg.get_value("estrellas", key + "_mejor_coste", 0.0)

			# Assign to world
			for wid in world_progress:
				if key.begins_with(wid) or key.begins_with(wid.replace("-", "_")):
					world_progress[wid]["stars"] += stars
					world_progress[wid]["levels"].append({"id": key, "stars": stars, "best_cost": best_cost})
					break

		stats["levels_completed"] = completed_levels
		stats["total_stars"] = total_stars

	# Load extended stats from stats.cfg
	var stats_cfg := ConfigFile.new()
	if stats_cfg.load("user://stats.cfg") == OK:
		stats["play_time_seconds"] = stats_cfg.get_value("stats", "play_time", 0)
		stats["best_streak"] = stats_cfg.get_value("stats", "best_streak", 0)
		stats["total_attempts"] = stats_cfg.get_value("stats", "total_attempts", 0)
		stats["total_wins"] = stats_cfg.get_value("stats", "total_wins", 0)
		stats["total_losses"] = stats_cfg.get_value("stats", "total_losses", 0)
		var total: int = stats["total_wins"] + stats["total_losses"]
		stats["win_rate"] = float(stats["total_wins"]) / float(total) * 100.0 if total > 0 else 0.0

	# Desglose por nivel del mundo heist (una fila por nivel registrado).
	# build_level_rows es una función pura testeable: recibe los ConfigFile ya
	# cargados para que los tests puedan inyectar datos en memoria.
	stats["levels_detail"] = build_level_rows("heist", progress_cfg, stats_cfg)


## Construye las filas de "PROGRESO POR NIVEL" para un mundo.
##
## Función pura: itera `LevelRegistry.WORLDS[world_id]["levels"]` y, para cada
## nivel, lee estrellas/mejor_coste de `progress_cfg` (sección "estrellas") y
## victorias/derrotas de `stats_cfg` (sección "levels", claves `<key>_wins` /
## `<key>_losses`). Sin datos → fila con "—". No lee disco directo; recibe los
## ConfigFile ya cargados para que los tests inyecten datos en memoria.
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


func _format_time(seconds: int) -> String:
	var h: int = int(seconds) / 3600
	var m: int = (int(seconds) % 3600) / 60
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%dm" % m


func _stars_to_text(stars: int) -> String:
	var result: String = ""
	for i in range(3):
		result += "★" if i < stars else "☆"
	return result


func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp.x, vp.y), BrandClass.BG)

	# Title
	draw_string(font, Vector2(60, 60), loc("menu.profile"), HORIZONTAL_ALIGNMENT_LEFT, -1, big_font_size, CYAN)

	# Name (editable)
	draw_string(font, Vector2(80, 120), loc("profile.name") + ":", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, GRIS)
	var name_start_x: float = 80.0 + font.get_string_size(loc("profile.name") + ":", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x + 10.0

	var name_text: String = player_name
	var name_color: Color = BLANCO if _editing_name else GRIS
	draw_string(font, Vector2(name_start_x, 120), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, name_color)

	# Cursor (blinking)
	if _editing_name and _cursor_visible:
		var cursor_x: float = name_start_x + font.get_string_size(player_name.left(_cursor_pos), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2).x
		draw_rect(Rect2(cursor_x, 105, 2, font_size + 6), CYAN)

	if not _editing_name:
		draw_string(font, Vector2(80, 142), loc("profile.edit_name"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, GRIS_OSCURO)

	# Stats section
	var by: float = 180.0
	draw_string(font, Vector2(80, by), loc("profile.stats"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, CYAN)
	by += 30

	_draw_stat(loc("profile.levels_completed"), "%d" % stats.levels_completed, by)
	_draw_stat(loc("profile.total_stars"), "%d" % stats.total_stars, by + 25)
	_draw_stat(loc("profile.play_time"), _format_time(stats.play_time_seconds), by + 50)
	_draw_stat(loc("profile.best_streak"), "%d" % stats.best_streak, by + 75)
	_draw_stat(loc("profile.total_attempts"), "%d" % stats.total_attempts, by + 100)
	_draw_stat("Victorias/Derrotas", "%d / %d" % [stats.total_wins, stats.total_losses], by + 125)
	_draw_stat("Tasa de victoria", "%.0f%%" % stats.win_rate, by + 150)

	# World progress
	by = 360.0
	draw_string(font, Vector2(80, by), loc("profile.world_progress"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, CYAN)
	by += 30

	for wid in world_progress:
		var wp: Dictionary = world_progress[wid]
		var stars_text: String = _stars_to_text(wp.stars)
		var label: String = "%s: %s" % [wid.capitalize(), stars_text]
		draw_string(font, Vector2(100, by), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, AMARILLO if wp.stars > 0 else GRIS)
		by += 28

	# Per-level detail (mundo heist): estrellas, mejor coste e intentos.
	by += 24
	draw_string(font, Vector2(80, by), "PROGRESO POR NIVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 4, CYAN)
	by += 26

	var col_stars_x: float = 400.0
	var col_cost_x: float = 490.0
	var col_attempts_x: float = 610.0
	draw_string(font, Vector2(100, by), "NIVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, GRIS_OSCURO)
	draw_string(font, Vector2(col_stars_x, by), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, GRIS_OSCURO)
	draw_string(font, Vector2(col_cost_x, by), "MEJOR", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, GRIS_OSCURO)
	draw_string(font, Vector2(col_attempts_x, by), "V/D (INTENTOS)", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, GRIS_OSCURO)
	by += 22

	for row in stats.levels_detail:
		var has_data: bool = row.attempts > 0 or row.stars > 0
		var row_color: Color = BLANCO if has_data else GRIS_OSCURO
		var stars_row: Color = AMARILLO if row.stars > 0 else GRIS_OSCURO
		draw_string(font, Vector2(100, by), String(row.title).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, row_color)
		draw_string(font, Vector2(col_stars_x, by), _stars_to_text(row.stars), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, stars_row)
		var coste_txt: String = "%.1f" % row.best_cost if row.best_cost > 0.0 else "—"
		draw_string(font, Vector2(col_cost_x, by), coste_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, row_color)
		var attempts_txt: String = "%d/%d (%d)" % [row.wins, row.losses, row.attempts] if row.attempts > 0 else "—"
		draw_string(font, Vector2(col_attempts_x, by), attempts_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, row_color)
		by += 22

	by += 20
	draw_string(font, Vector2(60, by), loc("menu.back_hint"), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, Color(0.35, 0.38, 0.45))


func _draw_stat(label: String, value: String, y: float) -> void:
	draw_string(font, Vector2(100, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, GRIS)
	var val_x: float = 400.0
	draw_string(font, Vector2(val_x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size + 2, BLANCO)
