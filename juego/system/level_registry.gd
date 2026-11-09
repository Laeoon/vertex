class_name LevelRegistry

## Registro maestro de niveles por mundo.
## Define la estructura de datos, metadatos tácticos y narrativa de cada nivel jugable.

const WORLDS: Dictionary = {
	"heist": {
		"title": "Heist",
		"description": "Infiltración en red bancaria",
		"operator": "VEX",
		"levels": [
			{
				"path": "res://juego/heist/heist_n1.json",
				"title": "Infiltración en la Bóveda",
				"difficulty": 1,
				"act": 1,
				"operator": "VEX",
				"briefing": "Acceso perimetral a la red de sucursales. Navega por caminos mínimos de Dijkstra evitando la contención.",
			},
			{
				"path": "res://juego/heist/heist_n2.json",
				"title": "La Ruta del Oro",
				"difficulty": 2,
				"act": 1,
				"operator": "VEX",
				"briefing": "Canales de transferencia interbancaria. Sigue el flujo de capital hacia los servidores de compensación.",
			},
			{
				"path": "res://juego/heist/heist_n3.json",
				"title": "Escape del Casino Digital",
				"difficulty": 3,
				"act": 1,
				"operator": "VEX",
				"briefing": "Subredes de apuestas en tiempo real. Utiliza desvíos lógicos y waypoints para eludir el rastreo de seguridad.",
			},
			{
				"path": "res://juego/heist/heist_n4.json",
				"title": "Blackout en el Data Center",
				"difficulty": 4,
				"act": 1,
				"operator": "VEX",
				"briefing": "Caída de generadores auxiliares en el data center. La visibilidad disminuye y la latencia crítica aumenta.",
			},
			{
				"path": "res://juego/heist/heist_n5.json",
				"title": "La Bifurcación",
				"difficulty": 5,
				"act": 1,
				"operator": "VEX",
				"briefing": "Encrucijada troncal del sistema financiero. Una sola decisión errónea alertará a la seguridad federal.",
			},
		]
	},
	"hacker": {
		"title": "Hacker",
		"description": "Movimiento lateral en red corporativa",
		"operator": "N0X",
		"levels": [
			{
				"path": "res://juego/hacker/hacker_n1.json",
				"title": "Lateral Movement",
				"difficulty": 2,
				"act": 1,
				"operator": "N0X",
				"briefing": "Infiltración desde la DMZ exterior hacia los servidores internos de aplicaciones mediante bypass y escaneo.",
			},
			{
				"path": "res://juego/hacker/hacker_n2.json",
				"title": "Brecha en la Red Corporativa",
				"difficulty": 3,
				"act": 1,
				"operator": "N0X",
				"briefing": "Escalada de credenciales a través de servidores web comprometidos y bases de datos intermedias.",
			},
			{
				"path": "res://juego/hacker/hacker_n3.json",
				"title": "Persistencia en la Infraestructura",
				"difficulty": 3,
				"act": 1,
				"operator": "N0X",
				"briefing": "Instalación de sockets encubiertos en servidores de autenticación LDAP para resistir reinicios.",
			},
			{
				"path": "res://juego/hacker/hacker_n4.json",
				"title": "Guerra de Señuelos y Decepción",
				"difficulty": 4,
				"act": 1,
				"operator": "N0X",
				"briefing": "Detección de honeypots corporativos mientras se despliegan señuelos propios para engañar al analista de seguridad.",
			},
			{
				"path": "res://juego/hacker/hacker_n5.json",
				"title": "Operación Root Compromise",
				"difficulty": 5,
				"act": 1,
				"operator": "N0X",
				"briefing": "Asalto final al controlador de dominio y bóveda cuántica central del conglomerado corporativo.",
			},
		]
	},
	"cybersecurity": {
		"title": "Cybersecurity",
		"description": "Defensa en capas y operaciones Blue Team",
		"operator": "AEGIS",
		"levels": [
			{
				"path": "res://juego/defense/defense_n1.json",
				"title": "Defensa Perimetral",
				"difficulty": 1,
				"act": 1,
				"operator": "AEGIS",
				"briefing": "Contención perimetral de paquetes hostiles entrantes desde la interfaz externa aplicando bloqueo en tiempo real.",
			},
			{
				"path": "res://juego/cyber/cyber_n1.json",
				"title": "Defensa en Capas",
				"difficulty": 2,
				"act": 1,
				"operator": "AEGIS",
				"briefing": "Microsegmentación y filtrado dinámico para mitigar el avance del atacante hacia la base de datos.",
			},
			{
				"path": "res://juego/cyber/cyber_n2.json",
				"title": "Movimiento Lateral",
				"difficulty": 3,
				"act": 1,
				"operator": "AEGIS",
				"briefing": "Detección temprana y aislamiento de nodos comprometidos en el segmento interno de servidores.",
			},
			{
				"path": "res://juego/cyber/cyber_n3.json",
				"title": "Niebla de Guerra",
				"difficulty": 4,
				"act": 1,
				"operator": "AEGIS",
				"briefing": "Operación defensiva bajo telemetría parcial. Despliega canarios, sondeos e intercepción para revelar rutas.",
			},
			{
				"path": "res://juego/cyber/cyber_n4.json",
				"title": "Operación Zero Trust",
				"difficulty": 5,
				"act": 1,
				"operator": "AEGIS",
				"briefing": "Validación continua de privilegios y cálculo de corte mínimo ante una intrusión multifocal masiva.",
			},
		]
	},
	"secret": {
		"title": "Sector 0",
		"description": "Cámara profunda del kernel",
		"operator": "ZERO",
		"levels": [
			{
				"path": "res://juego/secret/secret_root.json",
				"title": "Sector 0 — Root Genesis",
				"difficulty": 5,
				"act": 1,
				"operator": "ZERO",
				"briefing": "Cámara profunda del kernel primigenio. Estructura de panal hiperconectada donde la IA predice cada movimiento.",
			},
		]
	},
}


static func get_world(world_id: String) -> Dictionary:
	return WORLDS.get(world_id, {})


static func get_levels(world_id: String) -> Array:
	var world: Dictionary = get_world(world_id)
	return world.get("levels", [])


static func get_levels_for_act(world_id: String, act: int) -> Array:
	var all_levels: Array = get_levels(world_id)
	var filtered: Array = []
	for i in all_levels.size():
		var lvl: Dictionary = all_levels[i]
		var lvl_act: int = lvl.get("act", 1 if i < 5 else 2)
		if lvl_act == act:
			filtered.append(lvl)
	return filtered


static func get_level_config(world_id: String, level_idx: int) -> Dictionary:
	var levels: Array = get_levels(world_id)
	if level_idx < 0 or level_idx >= levels.size():
		return {}
	return levels[level_idx]


static func get_level_briefing(world_id: String, level_idx: int) -> String:
	var cfg := get_level_config(world_id, level_idx)
	if cfg.has("briefing"):
		return cfg["briefing"]
	var world := get_world(world_id)
	return world.get("description", "Operación táctica de red.")


static func get_level_operator(world_id: String, level_idx: int) -> String:
	var cfg := get_level_config(world_id, level_idx)
	if cfg.has("operator"):
		return cfg["operator"]
	var world := get_world(world_id)
	return world.get("operator", "UNKNOWN")


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
