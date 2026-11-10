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
	},
	"KAIN": {
		"id": "KAIN",
		"name": "ARCHITECT-0 // KAIN",
		"title": "Protocolo Autónomo de Purga · BGP 99.4%",
		"color": Color("ff4757"),
		"bg_color": Color("1a090d"),
		"world": "secret",
		"frequency": "140.85 MHz // BURST-CODEC",
		"bio": "Entidad renegada de Sector 0. Diseñó el protocolo de purga del 99.4% del error humano mediante el secuestro de tablas BGP."
	},
	"DAEMON_EXFIL": {
		"id": "DAEMON_EXFIL",
		"name": "DAEMON EXFIL // Swiss Consortium",
		"title": "Daemon Autónomo de Exfiltración Bancaria",
		"color": Color("bf5af2"),
		"bg_color": Color("150a1c"),
		"world": "heist",
		"frequency": "141.12 MHz // EXFIL-BUS",
		"bio": "Subproceso sigiloso de extracción que guía a VEX hacia los shards de Shamir en bóvedas frías."
	},
	"DAEMON_FUZZ": {
		"id": "DAEMON_FUZZ",
		"name": "DAEMON FUZZ // Darknet Syndicate",
		"title": "Motor Fuzzer de Mutación Zero-Day",
		"color": Color("39ff88"),
		"bg_color": Color("0a180f"),
		"world": "hacker",
		"frequency": "137.40 MHz // FUZZ-BUS",
		"bio": "Módulo de generación heurística de payloads para N0X. Explota condiciones de carrera y memoria corrupta."
	},
	"DAEMON_CORDON": {
		"id": "DAEMON_CORDON",
		"name": "DAEMON CORDON // SIEM Centinela",
		"title": "Agente Forense EDR & Aislamiento Dinámico",
		"color": Color("00d2ff"),
		"bg_color": Color("071420"),
		"world": "cybersecurity",
		"frequency": "109.20 MHz // CORDON-SOC",
		"bio": "Agente centinela de mitigación activa. Aplica políticas Zero-Trust y cuarentenas de nodo instantáneas."
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
		"caller": "KAIN",
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
	},
	# --- TRANSMISIONES CODEC // TRIADA DE GENESIS (HEIST - VEX) ---
	{
		"id": "codec_heist_n2",
		"title": "La Ruta del Oro // Exfiltración BGP",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "DAEMON_EXFIL",
		"mode": "codec",
		"description": "Desvío de tablas BGP y análisis de latencia en la transferencia interbancaria.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "DAEMON_EXFIL",
				"alert": "BURST CODEC // 141.12 MHz",
				"text": "VEX, detectamos envenenamiento de prefijos BGP en el peering suizo. Las transferencias se están desviando hacia el Sector 0."
			},
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "CANAL CIFRADO // SHARD BETA",
				"text": "Copiado. Aplico Dijkstra sobre los enlaces de menor coste. Si exfiltramos las claves privadas antes del cierre de sesión, el segundo shard es nuestro."
			}
		]
	},
	{
		"id": "codec_heist_n3",
		"title": "Casino Digital // Matriz Estocástica",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "DAEMON_EXFIL",
		"mode": "codec",
		"description": "Bypass de la matriz aleatoria de pagos y sincronización del shard de Shamir.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "BURST CODEC // 142.85 MHz",
				"text": "Esta red de alta frecuencia no sigue una topología euclidiana. El casino usa generadores cuánticos para dispersar los paquetes."
			},
			{
				"mode": "codec",
				"speaker": "DAEMON_EXFIL",
				"alert": "SHAMIR ALGORITHM // 3 OF 5",
				"text": "Reconstrucción del polinomio en progreso: necesitamos 3 de 5 shards para desbloquear el ledger central. Mantén los nodos en verde."
			}
		]
	},
	{
		"id": "codec_heist_n4",
		"title": "Data Center // Blackout de Memoria",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "KAIN",
		"mode": "codec",
		"description": "Intrusión bajo corte de energía y recolección de memoria volátil.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "INTERCEPTACIÓN // ARCHITECT-0",
				"text": "El frío preserva la memoria DRAM unos segundos tras el corte de energía, VEX. Pero tu presencia es una variable humana prescindible."
			},
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "ANOMALÍA // VOZ EN EL CANAL",
				"text": "¿Quién eres? Ese patrón de voz viene del Anillo 0... ¡Daemon, bloquea la telemetría entrante!"
			}
		]
	},
	{
		"id": "codec_heist_n5",
		"title": "La Bifurcación // Troncal Intersectorial",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "DAEMON_EXFIL",
		"mode": "codec",
		"description": "Cruce de subredes y revelación de la convergencia de la Tríada.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "DAEMON_EXFIL",
				"alert": "CRUCE TRONCAL // ALERTA CONVERGENCIA",
				"text": "Las tablas de enrutamiento bancario convergen con la DMZ de una corporación y con sensores del SOC federal. Estamos en la encrucijada."
			},
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "VECTOR FINAL // SECTOR 0",
				"text": "Los shards de Shamir se ensamblan en un mapa del kernel. No me detendré ahora: abro paso hacia el núcleo."
			}
		]
	},
	# --- TRANSMISIONES CODEC // TRIADA DE GENESIS (HACKER - N0X) ---
	{
		"id": "codec_hacker_n2",
		"title": "Brecha Corporativa // Buffer Overflow",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "DAEMON_FUZZ",
		"mode": "codec",
		"description": "Explotación de desbordamiento de búfer y salto a subredes de producción.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "DAEMON_FUZZ",
				"alert": "HEAP OVERFLOW // ASLR BYPASS",
				"text": "N0X, el fuzzer encontró un puntero colgante en el gateway TLS. Retorno a libc confirmado. Inyectando shellcode de la Tríada."
			},
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "SHADOW BUS // 133.70 MHz",
				"text": "Excelente. Salto al servidor de aplicaciones. Asegurá los descriptores de sockets antes de que el IDS reinicie la pila."
			}
		]
	},
	{
		"id": "codec_hacker_n3",
		"title": "Persistencia // Backdoor LDAP",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "DAEMON_FUZZ",
		"mode": "codec",
		"description": "Instalación de persistencia encubierta en controladores de identidad.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "ACTIVE DIRECTORY // PERSISTENCIA",
				"text": "Inserté un objeto sombra en el árbol LDAP. Aunque parchéen el binario, el socket encubierto responderá a nuestros paquetes mágicos."
			},
			{
				"mode": "codec",
				"speaker": "DAEMON_FUZZ",
				"alert": "METADATOS // SHARD LOCALIZADO",
				"text": "Detectamos firmas de fragmentos de Genesis en los certificados raíz. La corporación estaba analizando el código de Sector 0."
			}
		]
	},
	{
		"id": "codec_hacker_n4",
		"title": "Guerra de Señuelos // Decepción Táctica",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "KAIN",
		"mode": "codec",
		"description": "Enfrentamiento entre señuelos propios y honeypots de alta interacción.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "HONEYPOT HEURÍSTICO // ARCHITECT-0",
				"text": "Cada señuelo que plantas es una firma de tu propio ego, N0X. En una red perfecta, el 99.4% del ruido proviene de la debilidad humana."
			},
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "REACCIÓN // TRACE DISRUPTION",
				"text": "¿Quién carajos hackea mi propia consola de comando? ¡Rastrea esa IP, fuzzer! ¡Está operando desde el kernel primigenio!"
			}
		]
	},
	{
		"id": "codec_hacker_n5",
		"title": "Root Compromise // Asalto Final al Dominio",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "DAEMON_FUZZ",
		"mode": "codec",
		"description": "Extracción del shard maestro de autenticación y caída del dominio.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "DOMAIN ADMIN // DCSYNC COMPLETO",
				"text": "Tengo los hashes de Kerberos de toda la organización. La bóveda central se abrió... pero los datos apuntan a una sola dirección: Sector 0."
			},
			{
				"mode": "codec",
				"speaker": "DAEMON_FUZZ",
				"alert": "BRECHA TOTAL // DESPLIEGUE EXTREMO",
				"text": "El enrutamiento está colapsando en un único punto focal. N0X, nos vemos en el epicentro de la Tríada."
			}
		]
	},
	# --- TRANSMISIONES CODEC // TRIADA DE GENESIS (CYBERSECURITY - AEGIS) ---
	{
		"id": "codec_cyber_n1",
		"title": "Defensa en Capas // Microsegmentación SIEM",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "DAEMON_CORDON",
		"mode": "codec",
		"description": "Filtrado adaptativo de flujos maliciosos para proteger la infraestructura crítica.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "PERIMETER SOC // 108.40 MHz",
				"text": "El atacante superó el firewall perimetral. Activamos microsegmentación dinámica: ningún nodo confía en su vecino sin handshake mutuo."
			},
			{
				"mode": "codec",
				"speaker": "DAEMON_CORDON",
				"alert": "SIEM TELEMETRY // EDMONDS-KARP",
				"text": "Aristas de corte mínimo calculadas. Bloqueando puertos no estándar para asfixiar la tasa de transferencia del vector intruso."
			}
		]
	},
	{
		"id": "codec_cyber_n2",
		"title": "Movimiento Lateral // Cuarentena EDR",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "DAEMON_CORDON",
		"mode": "codec",
		"description": "Aislamiento inmediato de hosts infectados y respuesta a incidentes.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "DAEMON_CORDON",
				"alert": "ALERTA EDR // MOVIMIENTO LATERAL",
				"text": "Host secundario comprometido mediante inyección de credenciales. Propagación detectada en subred 10.4.0.0/24."
			},
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "CONTENCIÓN INMEDIATA // ISOLATE",
				"text": "Aisla la máquina virtual en un honeynet de cuarentena. No permitas que el intruso vincule este nodo con la bóveda de Sector 0."
			}
		]
	},
	{
		"id": "codec_cyber_n3",
		"title": "Niebla de Guerra // Sondas Canario",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "KAIN",
		"mode": "codec",
		"description": "Despliegue de canarios defensivos bajo saturación y niebla de guerra.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "SATURACIÓN BGP // ARCHITECT-0",
				"text": "Tus canarios cantan para oídos sordos, Comandante Aegis. La ciberseguridad es una ilusión humana contra la evolución algorítmica."
			},
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "BLUE TEAM LOG // CONTRAMEDIDA",
				"text": "¿Kain? Tu proceso fue revocado en la auditoría del kernel original. Refuercen el perímetro: la amenaza proviene de adentro."
			}
		]
	},
	{
		"id": "codec_cyber_n4",
		"title": "Operación Zero Trust // Aislamiento Total",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "DAEMON_CORDON",
		"mode": "codec",
		"description": "Corte de enlaces perimetrales y defensa final de la raíz.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "ZERO TRUST DIRECTIVE // NIVEL 5",
				"text": "Todos los canales externos quedan clausurados. Si el intruso quiere el núcleo, tendrá que atravesar cada regla de corte mínimo que diseñé."
			},
			{
				"mode": "codec",
				"speaker": "DAEMON_CORDON",
				"alert": "CONVERGENCIA SOC // MATRIZ ESTABLE",
				"text": "Sensores listos. La topología está asegurada. Preparados para el impacto del vector hostil."
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
		"heist_n2":
			return get_cinematic("codec_heist_n2")
		"heist_n3":
			return get_cinematic("codec_heist_n3")
		"heist_n4":
			return get_cinematic("codec_heist_n4")
		"heist_n5":
			return get_cinematic("codec_heist_n5")
		"hacker_n1":
			return get_cinematic("act1_hacker_intro")
		"hacker_n2":
			return get_cinematic("codec_hacker_n2")
		"hacker_n3":
			return get_cinematic("codec_hacker_n3")
		"hacker_n4":
			return get_cinematic("codec_hacker_n4")
		"hacker_n5":
			return get_cinematic("codec_hacker_n5")
		"defense_n1":
			return get_cinematic("act1_cyber_intro")
		"cyber_n1":
			return get_cinematic("codec_cyber_n1")
		"cyber_n2":
			return get_cinematic("codec_cyber_n2")
		"cyber_n3":
			return get_cinematic("codec_cyber_n3")
		"cyber_n4":
			return get_cinematic("codec_cyber_n4")
		"secret_root":
			return get_cinematic("prologue_root_genesis")
		_:
			# Buscar en LevelRegistry si declara cinematic_id
			var LevelRegistryClass = load("res://juego/system/level_registry.gd")
			if LevelRegistryClass:
				var info: Dictionary = LevelRegistryClass.find_level(level_id)
				var cfg: Dictionary = info.get("config", {})
				var cid: String = cfg.get("cinematic_id", "")
				if cid != "":
					return get_cinematic(cid)
			return {}
