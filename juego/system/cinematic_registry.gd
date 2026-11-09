class_name CinematicRegistry extends RefCounted

## Registro maestro de cinemáticas, transmisiones y lore táctico de VERTEX.
## Provee datos estructurados para el motor de cinemáticas dual (Codec y Red Vectorial).
## Cada entrada contiene metadatos de operador, modo, acto y diapositivas narrativas.

const OPERATORS: Dictionary = {
	"ZERO": {
		"id": "ZERO",
		"name": "ZERO // Origin Architect",
		"title": "Arquitecto Primigenio del Kernel",
		"color": Color("ff2a6d"),
		"bg_color": Color("18080f"),
		"world": "secret",
		"frequency": "0x0000 // ROOT-CH",
		"bio": "Entidad fundacional atrapada en la cámara profunda de Sector 0. Creador de la topología original."
	},
	"VEX": {
		"id": "VEX",
		"name": "VEX // Phantom Infiltrator",
		"title": "Especialista en Infiltración & Exfiltración",
		"color": Color("bf5af2"),
		"bg_color": Color("150a1c"),
		"world": "heist",
		"frequency": "142.85 MHz // GHOST-NET",
		"bio": "Operador independiente que navega rutas críticas bancarias mediante caminos mínimos de Dijkstra."
	},
	"N0X": {
		"id": "N0X",
		"name": "N0X // Red Team Lead",
		"title": "Especialista en Escalada & Movimiento Lateral",
		"color": Color("39ff88"),
		"bg_color": Color("0a180f"),
		"world": "hacker",
		"frequency": "133.70 MHz // SHADOW-BUS",
		"bio": "Auditor ofensivo de brechas. Domina el movimiento lateral, señuelos tácticos y grafos de ataque."
	},
	"AEGIS": {
		"id": "AEGIS",
		"name": "AEGIS // Blue Team Commander",
		"title": "Director de Defensa Perimetral & EDR",
		"color": Color("00d2ff"),
		"bg_color": Color("071420"),
		"world": "cybersecurity",
		"frequency": "108.40 MHz // PERIMETER-SOC",
		"bio": "Comandante de operaciones del SOC. Implementa cortes mínimos, cuarentenas de red y Moving Target Defense."
	}
}

const CINEMATICS: Array[Dictionary] = [
	{
		"id": "prologue_root_genesis",
		"title": "Sector 0 // Génesis del Kernel",
		"act": 1,
		"world": "secret",
		"operator": "ZERO",
		"mode": "hybrid",
		"description": "El registro primigenio del Anillo 0 antes de la fragmentación de la infraestructura en tres sectores aislados.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "ZERO",
				"alert": "ALERTA // LOG PRIMIGENIO 0x00",
				"text": "Antes de los firewalls y los señuelos... el kernel era uno solo. Una topología sin límites ni fronteras."
			},
			{
				"mode": "network",
				"speaker": "ZERO",
				"event": "breach",
				"alert": "CONVERGENCIA // DESVÍO DE FLUJO",
				"text": "Inyectaron la primera anomalía en el Anillo 0. Para contenerla, dividieron la red en tres sectores: Bóveda, DMZ y Perímetro."
			},
			{
				"mode": "codec",
				"speaker": "ZERO",
				"alert": "ORIGEN // ADVERTENCIA",
				"text": "Operador, si estás leyendo este bloque de memoria... los tres sectores están convergiendo de nuevo hacia la raíz."
			}
		]
	},
	{
		"id": "act1_heist_intro",
		"title": "Operación Vault Zero // Infiltración Heist",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"mode": "codec",
		"description": "Briefing táctico de VEX sobre la intrusión sigilosa en la red bancaria central mediante caminos mínimos.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "CANAL CIFRADO // 128-BIT",
				"text": "Aquí VEX. Estoy monitorizando la red bancaria exterior. El camino más corto no siempre es el más seguro."
			},
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "TELEMETRÍA // DIJKSTRA ACTIVO",
				"text": "La IA de contención tiene sensores en cada caja de seguridad. Minimiza la latencia y mantén el sigilo en cada salto."
			},
			{
				"mode": "network",
				"speaker": "VEX",
				"event": "scan",
				"alert": "VECTOR // EXTRACCIÓN CRÍTICA",
				"text": "Alcanza los waypoints antes de que el corte perimetral nos deje atrapados. Nos vemos en el nodo de extracción."
			}
		]
	},
	{
		"id": "act1_hacker_intro",
		"title": "Movimiento Lateral // Protocolo N0X",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"mode": "codec",
		"description": "Transmisión interceptada de N0X escalando privilegios a través de la DMZ y burlando contramedidas de red.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "TERMINAL ROOT // ESCALADA",
				"text": "N0X al habla. La DMZ corporativa es un colador si sabes qué puertos escuchar y qué servicios explotar."
			},
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "EXPLOIT // BYPASS & DECOY",
				"text": "Despliega señuelos tácticos para desviar al analista de seguridad. Cada exploit genera ruido térmico que alertará a la IA."
			},
			{
				"mode": "network",
				"speaker": "N0X",
				"event": "breach",
				"alert": "OBJETIVO // ACTIVE DIRECTORY",
				"text": "El controlador de dominio caerá en cuanto comprometamos el servidor de autenticación central. No dejes rastro."
			}
		]
	},
	{
		"id": "act1_cyber_intro",
		"title": "Directiva Centinela // Despliegue Blue Team",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"mode": "codec",
		"description": "Instrucciones de comando de AEGIS para la defensa en capas, análisis de corte mínimo y contención EDR.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "COMANDO DEFENSIVO // SOC AZUL",
				"text": "Atención operadores de perímetro. Múltiples firmas no autorizadas detectadas en la puerta de enlace externa."
			},
			{
				"mode": "network",
				"speaker": "AEGIS",
				"event": "pulse",
				"alert": "EDMONDS-KARP // CORTE MÍNIMO",
				"text": "Calculando aristas críticas de corte mínimo. Si saturamos el flujo entrante, el atacante quedará aislado sin escape."
			},
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "EDR // RASTREO FORENSE",
				"text": "Aislen los nodos en cuarentena antes de que la intrusión alcance el núcleo. Mantendremos la resiliencia a toda costa."
			}
		]
	},
	{
		"id": "act2_collision_teaser",
		"title": "Falla de Convergencia // Alerta Acto II",
		"act": 2,
		"world": "heist",
		"operator": "ZERO",
		"mode": "network",
		"description": "Transmisión de emergencia que anticipa la colisión de los tres vectores en el troncal intersectorial.",
		"slides": [
			{
				"mode": "network",
				"speaker": "ZERO",
				"event": "breach",
				"alert": "FALLA CRÍTICA // CONVERGENCIA DETECTADA",
				"text": "ANOMALÍA MAYOR: Los vectores de Heist, Hacker y Centinela están colisionando en el mismo router troncal."
			},
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "INTERFERENCIA // FRECUENCIA SUPERPUESTA",
				"text": "¿Quién diablos está transmitiendo en esta banda? Hay un proceso fantasma bloqueando mis rutas hacia la bóveda."
			},
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "ALERTA SOC // CONTENCIÓN MULTI-SECTOR",
				"text": "No es un atacante aislado. Son múltiples agentes convergiendo hacia el Sector 0. Activen el protocolo de emergencia."
			}
		]
	}
]


static func get_all() -> Array[Dictionary]:
	return CINEMATICS


static func get_cinematic(id: String) -> Dictionary:
	for c in CINEMATICS:
		if c.get("id", "") == id:
			return c
	return {}


static func get_cinematics_for_world(world_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in CINEMATICS:
		if c.get("world", "") == world_id:
			result.append(c)
	return result


static func get_cinematics_for_act(act: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for c in CINEMATICS:
		if c.get("act", 1) == act:
			result.append(c)
	return result


static func get_operator(op_id: String) -> Dictionary:
	return OPERATORS.get(op_id, {})


static func get_cinematic_for_level(level_id: String) -> Dictionary:
	match level_id:
		"heist_n1":
			return get_cinematic("act1_heist_intro")
		"hacker_n1":
			return get_cinematic("act1_hacker_intro")
		"defense_n1", "cyber_n1":
			return get_cinematic("act1_cyber_intro")
		"secret_root":
			return get_cinematic("prologue_root_genesis")
		"heist_n5":
			return get_cinematic("act2_collision_teaser")
		_:
			return {}
