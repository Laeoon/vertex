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
				"cinematic_id": "act1_heist_intro",
				"briefing": "Bypass perimetral a la red de bóvedas frías. Localizá y exfiltrá el primer fragmento criptográfico de Shamir (Shard Alpha) de la Tríada Genesis antes de que el daemon de contención bloquee los routers troncales.",
			},
			{
				"path": "res://juego/heist/heist_n2.json",
				"title": "La Ruta del Oro",
				"difficulty": 2,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n2",
				"briefing": "Canales troncales de transferencia interbancaria. Seguí las rutas de latencia mínima de Dijkstra y desviá las tablas BGP para exfiltrar el flujo de datos del consorcio financiero sin detonar las trampas del SOC.",
			},
			{
				"path": "res://juego/heist/heist_n3.json",
				"title": "Escape del Casino Digital",
				"difficulty": 3,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n3",
				"briefing": "Subredes estocásticas de apuestas en alta frecuencia. Utilizá waypoints encubiertos para burlar la heurística de dispersión y sincronizá el segundo shard de Shamir antes del corte de enlaces.",
			},
			{
				"path": "res://juego/heist/heist_n4.json",
				"title": "Blackout en el Data Center",
				"difficulty": 4,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n4",
				"briefing": "Apagón masivo inducido en el centro de datos subterráneo. Navegá en memoria volátil bajo latencia crítica; el daemon de exfiltración debe recuperar la traza de Genesis antes de la purga total.",
			},
			{
				"path": "res://juego/heist/heist_n5.json",
				"title": "La Bifurcación",
				"difficulty": 5,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n5",
				"briefing": "Troncal intersectorial donde las subredes bancarias colisionan con la DMZ. Una sola decisión errónea alertará al Centinela; asegurá el vector de escape hacia el Sector 0.",
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
				"cinematic_id": "act1_hacker_intro",
				"briefing": "Infiltración inicial desde la DMZ exterior hacia los servidores internos de aplicaciones. Desplegá fuzzing Zero-Day y señuelos tácticos para mapear los nodos de autenticación de la Tríada Genesis.",
			},
			{
				"path": "res://juego/hacker/hacker_n2.json",
				"title": "Brecha en la Red Corporativa",
				"difficulty": 3,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n2",
				"briefing": "Desbordamiento de búfer en pasarelas intermedias. Escalá privilegios en servidores web comprometidos y abrí sockets encubiertos hacia la red interna corporativa.",
			},
			{
				"path": "res://juego/hacker/hacker_n3.json",
				"title": "Persistencia en la Infraestructura",
				"difficulty": 3,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n3",
				"briefing": "Instalación de persistencia encubierta en controladores de acceso LDAP. Neutralizá las alertas del SIEM y decodificá los payloads fragmentados de la Tríada.",
			},
			{
				"path": "res://juego/hacker/hacker_n4.json",
				"title": "Guerra de Señuelos y Decepción",
				"difficulty": 4,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n4",
				"briefing": "Mapeo de la infraestructura corporativa plagada de honeypots. Desplegá señuelos propios para engañar los sensores del analista y evadí el rastreo heurístico del Centinela.",
			},
			{
				"path": "res://juego/hacker/hacker_n5.json",
				"title": "Operación Root Compromise",
				"difficulty": 5,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n5",
				"briefing": "Asalto coordinado al controlador de dominio central. Comprometé la bóveda cuántica y extraé el shard nuclear de la Tríada Genesis antes del bloqueo por cuarentena.",
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
				"cinematic_id": "act1_cyber_intro",
				"briefing": "Bloqueo defensivo perimetral ante una intrusión multifocal masiva. Calculá el corte mínimo con Edmonds-Karp y aislá los enlaces externos para contener la propagación del malware.",
			},
			{
				"path": "res://juego/cyber/cyber_n1.json",
				"title": "Defensa en Capas",
				"difficulty": 2,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n1",
				"briefing": "Microsegmentación estricta y filtrado adaptativo en tiempo real. Mitigá el avance de los paquetes maliciosos hacia los servidores de bases de datos críticas de la Tríada.",
			},
			{
				"path": "res://juego/cyber/cyber_n2.json",
				"title": "Movimiento Lateral",
				"difficulty": 3,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n2",
				"briefing": "Detección temprana de movimientos laterales hostiles en la subred de servidores. Aplicá cuarentena inmediata sobre hosts comprometidos antes de que alcancen el gateway interno.",
			},
			{
				"path": "res://juego/cyber/cyber_n3.json",
				"title": "Niebla de Guerra",
				"difficulty": 4,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n3",
				"briefing": "Operación de respuesta a incidentes bajo visibilidad degradada. Desplegá sondas de telemetría y señuelos canario para revelar las rutas de ataque encubiertas del intruso.",
			},
			{
				"path": "res://juego/cyber/cyber_n4.json",
				"title": "Operación Zero Trust",
				"difficulty": 5,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n4",
				"briefing": "Política estricta Zero Trust y reconfiguración dinámica de topología. Neutralizá la brecha terminal antes de que el exploit maestro alcance el núcleo del sistema.",
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
				"cinematic_id": "prologue_root_genesis",
				"briefing": "Cámara profunda del kernel primigenio. Estructura hiperconectada del Anillo 0 donde se gestó la purga del 99.4% del error humano mediante el protocolo autónomo BGP de Kain.",
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
