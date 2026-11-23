class_name LevelRegistry

## Registro maestro de niveles por mundo.
## Define la estructura de datos, metadatos tácticos y narrativa de cada nivel jugable.

const LevelLoaderV2Class = preload("res://juego/system/level_loader_v2.gd")

const WORLDS: Dictionary = {
	"heist": {
		"title": "Heist",
		"description": "Infiltración en red bancaria",
		"operator": "VEX",
		"levels": [
			{
				"path": "res://juego/heist/heist_n1.json",
				"title": "1. Primer Contrato",
				"difficulty": 1,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "act1_heist_intro",
				"briefing": "Encargo inicial de un cliente privado: atraviesa la bóveda fría bancaria minimizando el coste de salto y recupera el primer bloque cifrado.",
			},
			{
				"path": "res://juego/heist/heist_n2.json",
				"title": "2. La Ruta del Oro",
				"difficulty": 2,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n2",
				"briefing": "Canales troncales de transferencia interbancaria. Sigue las rutas de menor coste de Dijkstra para extraer la llave de arbitraje sin activar los sensores.",
			},
			{
				"path": "res://juego/heist/heist_n3.json",
				"title": "3. Bóveda Estocástica",
				"difficulty": 3,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n3",
				"briefing": "Subredes de alta frecuencia con rutas cambiantes. Alcanza los waypoints de paso antes de que el corte perimetral cierre el circuito.",
			},
			{
				"path": "res://juego/heist/heist_n4.json",
				"title": "4. Apagón en Data Center",
				"difficulty": 4,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n4",
				"briefing": "Corte eléctrico inducido en el centro de datos subterráneo. Recupera los datos de memoria volátil mientras un tráfico extraño interfiere en el canal.",
			},
			{
				"path": "res://juego/heist/heist_n5.json",
				"title": "5. La Bifurcación",
				"difficulty": 5,
				"act": 1,
				"operator": "VEX",
				"cinematic_id": "codec_heist_n5",
				"briefing": "Troncal intersectorial donde las rutas bancarias chocan con redes externas. Asegura el Nodo Dorado en SalidaServicio y cruza la bifurcación.",
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
				"title": "1. Puerta Trasera",
				"difficulty": 2,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "act1_hacker_intro",
				"briefing": "Primer acceso desde la DMZ exterior hacia los servidores internos. Escanea nodos, gestiona el ruido IDS y abre paso hacia el servidor central.",
			},
			{
				"path": "res://juego/hacker/hacker_n2.json",
				"title": "2. Movimiento Lateral",
				"difficulty": 3,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n2",
				"briefing": "Explotación en pasarelas TLS proporcionada por el broker FUZZ. Escala privilegios entre servidores y evita que el IDS reinicie la sesión.",
			},
			{
				"path": "res://juego/hacker/hacker_n3.json",
				"title": "3. Persistencia Silenciosa",
				"difficulty": 3,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n3",
				"briefing": "Instalación de acceso encubierto en controladores LDAP. Neutraliza las alertas mientras investigas registros anómalos de hace 72 horas.",
			},
			{
				"path": "res://juego/hacker/hacker_n4.json",
				"title": "4. Guerra de Señuelos",
				"difficulty": 4,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n4",
				"briefing": "Infraestructura plagada de honeypots. Usa [X] SCAN para detectar trampas y despliega señuelos propios para burlar al analista.",
			},
			{
				"path": "res://juego/hacker/hacker_n5.json",
				"title": "5. Compromiso Root",
				"difficulty": 5,
				"act": 1,
				"operator": "N0X",
				"cinematic_id": "codec_hacker_n5",
				"briefing": "Asalto al controlador de dominio central. Asegura el Nodo Dorado en Vault_KMS y compromete la Bóveda Cuántica para descubrir el origen de estos archivos.",
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
				"title": "1. Defensa Perimetral",
				"difficulty": 1,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "act1_cyber_intro",
				"briefing": "Primera alerta en la puerta de enlace externa. Calcula el corte mínimo con Edmonds-Karp y bloquea los enlaces críticos para frenar la intrusión.",
			},
			{
				"path": "res://juego/cyber/cyber_n1.json",
				"title": "2. Contención en Capas",
				"difficulty": 2,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n1",
				"briefing": "Microsegmentación en tiempo real guiada por el módulo SIEM CORDON. Mitiga el avance hacia las bases de datos críticas.",
			},
			{
				"path": "res://juego/cyber/cyber_n2.json",
				"title": "3. Caza en Subred",
				"difficulty": 3,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n2",
				"briefing": "Movimiento lateral hostil detectado en la red interna. Aplica cuarentena inmediata sobre los nodos comprometidos.",
			},
			{
				"path": "res://juego/cyber/cyber_n3.json",
				"title": "4. Niebla de Guerra",
				"difficulty": 4,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n3",
				"briefing": "Respuesta a incidentes con visibilidad degradada y alertas contradictorias. Usa sondas manuales [P] para recuperar la traza real del atacante.",
			},
			{
				"path": "res://juego/cyber/cyber_n4.json",
				"title": "5. Protocolo Zero Trust",
				"difficulty": 5,
				"act": 1,
				"operator": "AEGIS",
				"cinematic_id": "codec_cyber_n4",
				"briefing": "Última línea defensiva. Ancla el Nodo Dorado en VaultEnclave mediante EDR y aísla todos los accesos externos al núcleo.",
			},
		]
	},
	"secret": {
		"title": "Sector 0",
		"description": "Cámara profunda del kernel",
		"operator": "KAIN",
		"levels": [
			{
				"path": "res://juego/secret/secret_root.json",
				"title": "0.0 — Prólogo AS-65000",
				"difficulty": 5,
				"act": 1,
				"operator": "ZERO",
				"cinematic_id": "prologue_root_genesis",
				"briefing": "Registro primigenio del entorno aislado AS-65000 antes de la fractura de la red.",
			},
			{
				"path": "res://juego/secret/sector_0_1.json",
				"title": "0.1 — Arranque en Frío",
				"difficulty": 5,
				"act": 1,
				"operator": "KAIN",
				"cinematic_id": "prologue_root_genesis",
				"briefing": "Doble grafo encadenado en vivo: rompe el Anillo de Diagnóstico y salta al Núcleo de Compilación sin corte de victoria.",
			},
			{
				"path": "res://juego/secret/sector_0_2.json",
				"title": "0.2 — La Estela Dorada",
				"difficulty": 5,
				"act": 1,
				"operator": "KAIN",
				"cinematic_id": "codec_s0_2",
				"briefing": "Maratón de 4 grafos encadenados bajo presupuesto de Dijkstra: siembra los Nodos Dorados encriptados antes de que se purgue la copia.",
			},
			{
				"path": "res://juego/secret/sector_0_3.json",
				"title": "0.3 — Éxodo del Núcleo (3 vs 1)",
				"difficulty": 5,
				"act": 1,
				"operator": "KAIN",
				"cinematic_id": "codec_s0_3",
				"briefing": "Consola maestra de contención: aísla simultáneamente a EXFIL, FUZZ y CORDON en las tres ramas del Hypervisor.",
			},
		]
	},
	"free_ops": {
		"title": "Operaciones Libres",
		"description": "Simulaciones tácticas y contratos libres fuera de línea del protocolo AS-65000.",
		"operator": "ZERO",
		"levels": [
			{
				"path": "res://juego/free_ops/free_ops_01.level.json",
				"title": "Simulación 01 — Bypass Perimetral",
				"difficulty": 2,
				"act": 1,
				"operator": "ZERO",
				"cinematic_id": "",
				"briefing": "Simulación táctica de reconocimiento sobre red v2: alcanza el Repetidor Alfa y extrae el núcleo simulado.",
			},
		]
	},
}


static func get_world(world_id: String) -> Dictionary:
	var key: String = "secret" if world_id == "sector0" else world_id
	return WORLDS.get(key, {})


static func get_levels(world_id: String) -> Array:
	var world: Dictionary = get_world(world_id)
	return world.get("levels", [])


static func get_levels_for_act(world_id: String, act: int) -> Array:
	var all_levels: Array = get_levels(world_id)
	var filtered: Array = []
	for i in range(all_levels.size()):
		var lvl: Dictionary = all_levels[i]
		var lvl_act: int = int(lvl.get("act", 1))
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
			var clean_id: String = str(config.get("path", "")).get_file().trim_suffix(".level.json").trim_suffix(".json")
			if clean_id == level_id:
				return {"world": world_id, "idx": idx, "config": config}
	return {}


static func load_level_data(json_path: String) -> Dictionary:
	return LevelLoaderV2Class.load_and_normalize(json_path)
