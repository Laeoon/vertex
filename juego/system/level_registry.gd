class_name LevelRegistry

## Registro maestro de niveles por mundo.
## Define la estructura de datos de cada nivel jugable.

const WORLDS: Dictionary = {
	"heist": {
		"title": "Heist",
		"description": "Infiltración en red bancaria",
		"levels": [
			{
				"path": "res://juego/heist/heist_n1.json",
				"title": "Infiltración en la Bóveda",
				"difficulty": 1,
			},
			{
				"path": "res://juego/heist/heist_n2.json",
				"title": "La Ruta del Oro",
				"difficulty": 2,
			},
			{
				"path": "res://juego/heist/heist_n3.json",
				"title": "Escape del Casino Digital",
				"difficulty": 3,
			},
		]
	},
	"hacker": {
		"title": "Hacker",
		"description": "Movimiento lateral en red corporativa",
		"levels": [
			{
				"path": "res://juego/hacker/hacker_n1.json",
				"title": "Lateral Movement",
				"difficulty": 2,
			},
			{
				"path": "res://juego/hacker/hacker_n2.json",
				"title": "Brecha en la Red Corporativa",
				"difficulty": 3,
			},
		]
	},
	"cybersecurity": {
		"title": "Cybersecurity",
		"description": "Defensa en capas de red",
		"levels": [
			{
				"path": "res://juego/cyber/cyber_n1.json",
				"title": "Defensa en Capas",
				"difficulty": 3,
			},
			{
				"path": "res://juego/defense/defense_n1.json",
				"title": "Defensa Perimetral",
				"difficulty": 2,
			},
		]
	},
}


static func get_world(world_id: String) -> Dictionary:
	return WORLDS.get(world_id, {})


static func get_levels(world_id: String) -> Array:
	var world: Dictionary = get_world(world_id)
	return world.get("levels", [])


static func get_level_config(world_id: String, level_idx: int) -> Dictionary:
	var levels: Array = get_levels(world_id)
	if level_idx < 0 or level_idx >= levels.size():
		return {}
	return levels[level_idx]


## Reverse lookup id → ubicación (slice 6): devuelve {world, idx, config}
## del nivel cuyo JSON declara `id`, o {} si no está registrado.
static func find_level(level_id: String) -> Dictionary:
	for world_id in WORLDS:
		var levels: Array = get_levels(world_id)
		for idx in levels.size():
			var config: Dictionary = levels[idx]
			if config.get("path", "").get_file().trim_suffix(".json") == level_id:
				return {"world": world_id, "idx": idx, "config": config}
	return {}


static func load_level_data(json_path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("LevelRegistry: no se pudo abrir %s" % json_path)
		return {}
	var json_text: String = file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_error("LevelRegistry: JSON invalido en %s" % json_path)
		return {}
	return parsed
