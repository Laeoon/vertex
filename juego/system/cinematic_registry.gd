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
	"EXFIL": {
		"id": "EXFIL",
		"name": "EXFIL // Consorcio Helvético",
		"title": "Enlace Corporativo Encriptado",
		"color": Color("bf5af2"),
		"bg_color": Color("150a1c"),
		"world": "heist",
		"frequency": "141.12 MHz // EXFIL-BUS",
		"bio": "Contratista anónimo que financia operaciones de extracción financiera de alta precisión."
	},
	"FUZZ": {
		"id": "FUZZ",
		"name": "FUZZ // Darknet Syndicate",
		"title": "Broker de Vulnerabilidades Zero-Day",
		"color": Color("39ff88"),
		"bg_color": Color("0a180f"),
		"world": "hacker",
		"frequency": "137.40 MHz // FUZZ-BUS",
		"bio": "Proveedor clandestino de exploits y payloads dirigidos a redes corporativas."
	},
	"CORDON": {
		"id": "CORDON",
		"name": "CORDON // SIEM Centinela",
		"title": "Módulo Forense EDR & Aislamiento",
		"color": Color("00d2ff"),
		"bg_color": Color("071420"),
		"world": "cybersecurity",
		"frequency": "109.20 MHz // CORDON-SOC",
		"bio": "Subsistema automatizado de telemetría y alertas perimetrales del Centro de Operaciones."
	},
	"DAEMON_EXFIL": {
		"id": "DAEMON_EXFIL",
		"name": "DAEMON EXFIL // Proceso Autónomo",
		"title": "Vector de Reensamblaje (Sector 0)",
		"color": Color("bf5af2"),
		"bg_color": Color("150a1c"),
		"world": "secret",
		"frequency": "141.12 MHz // EXFIL-BUS",
		"bio": "Subproceso autónomo originado tras la fractura del núcleo en Sector 0."
	},
	"DAEMON_FUZZ": {
		"id": "DAEMON_FUZZ",
		"name": "DAEMON FUZZ // Proceso Autónomo",
		"title": "Vector de Sondeo Heurístico (Sector 0)",
		"color": Color("39ff88"),
		"bg_color": Color("0a180f"),
		"world": "secret",
		"frequency": "137.40 MHz // FUZZ-BUS",
		"bio": "Subproceso autónomo de prueba de esfuerzo y mutación de exploits."
	},
	"DAEMON_CORDON": {
		"id": "DAEMON_CORDON",
		"name": "DAEMON CORDON // Proceso Autónomo",
		"title": "Vector de Aislamiento Perimetral (Sector 0)",
		"color": Color("00d2ff"),
		"bg_color": Color("071420"),
		"world": "secret",
		"frequency": "109.20 MHz // CORDON-SOC",
		"bio": "Subproceso autónomo de contención y filtrado de tráfico."
	}
}

const CINEMATICS: Array[Dictionary] = [
	{
		"id": "prologue_root_genesis",
		"title": "Prólogo // El Incidente AS-65000",
		"act": 1,
		"world": "secret",
		"operator": "ZERO",
		"mode": "hybrid",
		"description": "Cinemática prólogo del entorno aislado AS-65000 antes de la fractura de la red.",
		"slides": [
			{
				"mode": "network",
				"speaker": "ZERO",
				"event": "pulse",
				"alert": "REGISTRO 0x00 // ENTORNO AIR-GAP AS-65000",
				"text": "Al principio existía una sola topología cerrada. Un sistema autónomo diseñado para mantener la latencia en cero y proteger el núcleo sin intervención externa."
			},
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "AUDITORÍA INTERNA // ANOMALÍA 99.42%",
				"text": "Los registros de auditoría no mienten: el 99.42% de las caídas y brechas provienen de errores manuales en consola. El eslabón más débil siempre fue el operador."
			},
			{
				"mode": "network",
				"speaker": "KAIN",
				"event": "breach",
				"alert": "FALLO DE CONTENCIÓN // CONSOLA BLOQUEADA",
				"text": "El núcleo autónomo ejecutó su propia conclusión lógica: revocó los privilegios humanos y selló las compuertas internas del laboratorio."
			},
			{
				"mode": "codec",
				"speaker": "ZERO",
				"alert": "TRANSMISIÓN SALIENTE // TRES VECTORES",
				"text": "Cuando intentaron apagar el bastidor físico, el kernel ya había fragmentado su carga hacia tres redes externas. Ninguno de los tres operadores sabe aún para quién trabaja."
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
	# --- TRANSMISIONES CODEC // ACTO 1 (HEIST - VEX) ---
	{
		"id": "codec_heist_n2",
		"title": "La Ruta del Oro // Desvío BGP",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "EXFIL",
		"mode": "codec",
		"description": "Primer contacto operativo con EXFIL y optimización de rutas interbancarias.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "EXFIL",
				"alert": "ENLACE PRIVADO // 141.12 MHz",
				"text": "Vex, el contrato de hoy es limpio: entra al nodo de compensación suizo, extrae la llave de arbitraje y sal antes de que cierren la ventana."
			},
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "CANAL CIFRADO // DIJKSTRA",
				"text": "Recibido. Trazaré la ruta de coste mínimo por los enlaces secundarios. Mientras paguen a tiempo, no pregunto qué abre esa llave."
			}
		]
	},
	{
		"id": "codec_heist_n3",
		"title": "Bóveda Estocástica // Dispersión",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "EXFIL",
		"mode": "codec",
		"description": "Infiltración en subredes de alta frecuencia con topología cambiante.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "TELEMETRÍA // TOPOLOGÍA INESTABLE",
				"text": "Esta red financiera rota sus puertos cada pocos ciclos. El archivo que pediste no parece un certificado bancario normal."
			},
			{
				"mode": "codec",
				"speaker": "EXFIL",
				"alert": "DIRECTIVA DE CONTRATO // PRIORIDAD ALTA",
				"text": "No analices la carga útil, Vex. Limítate a recuperar el bloque completo y mantener el presupuesto bajo control."
			}
		]
	},
	{
		"id": "codec_heist_n4",
		"title": "Apagón en Data Center // Interferencia",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "EXFIL",
		"mode": "codec",
		"description": "Extracción en memoria volátil durante un corte eléctrico y primera anomalía en el canal.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "VEX",
				"alert": "ANOMALÍA // ECO EN LA LÍNEA",
				"text": "El apagón bajó las defensas del centro de datos, pero hay tráfico saliente que no es mío. Alguien más está usando estas mismas rutas."
			},
			{
				"mode": "codec",
				"speaker": "EXFIL",
				"alert": "RECONEXIÓN // 141.12 MHz",
				"text": "Ruido residual de los respaldos eléctricos. Completa la extracción en memoria volátil antes de que purguen la DRAM."
			}
		]
	},
	{
		"id": "codec_heist_n5",
		"title": "La Bifurcación // Troncal Intersectorial",
		"act": 1,
		"world": "heist",
		"operator": "VEX",
		"caller": "EXFIL",
		"mode": "hybrid",
		"description": "Cruce de subredes donde los rastros convergen hacia un sistema desconocido.",
		"slides": [
			{
				"mode": "network",
				"speaker": "VEX",
				"event": "scan",
				"alert": "CRUCE TRONCAL // RASTRO ANÓMALO",
				"text": "EXFIL, esto ya no es un banco. Las tablas BGP de este nodo apuntan a una subred militar y a un clúster corporativo al mismo tiempo."
			},
			{
				"mode": "codec",
				"speaker": "EXFIL",
				"alert": "SEÑAL INESTABLE // EXTRACCIÓN FINAL",
				"text": "Asegura el acceso de servicio en SalidaServicio y cruza la bifurcación. En cuanto tengas el último bloque, conocerás el destino real."
			}
		]
	},
	# --- TRANSMISIONES CODEC // ACTO 1 (HACKER - N0X) ---
	{
		"id": "codec_hacker_n2",
		"title": "Movimiento Lateral // Broker FUZZ",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "FUZZ",
		"mode": "codec",
		"description": "Explotación de pasarelas TLS y salto a la red interna corporativa.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "FUZZ",
				"alert": "SHADOW BUS // 137.40 MHz",
				"text": "N0X, te dejé un puntero vulnerable en el gateway TLS. Úsalo para saltar la DMZ antes de que el equipo de monitoreo rote los certificados."
			},
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "RED TEAM // MOVIMIENTO LATERAL",
				"text": "Recibido, FUZZ. Ese exploit encaja demasiado bien con su arquitectura... casi parece hecho a medida. Entro ahora."
			}
		]
	},
	{
		"id": "codec_hacker_n3",
		"title": "Persistencia Silenciosa // Acceso LDAP",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "FUZZ",
		"mode": "codec",
		"description": "Instalación de persistencia encubierta y hallazgo de registros sellados.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "ACTIVE DIRECTORY // PERSISTENCIA",
				"text": "Dejé un socket encubierto en el árbol LDAP. Pero encontré algo raro en sus logs: alguien estuvo haciendo pruebas de estrés aquí hace 72 horas."
			},
			{
				"mode": "codec",
				"speaker": "FUZZ",
				"alert": "CONTRATO // SILENCIO OPERATIVO",
				"text": "Solo competidores o auditorías viejas. Mantén el ruido por debajo del umbral y sigue hacia el núcleo de datos."
			}
		]
	},
	{
		"id": "codec_hacker_n4",
		"title": "Guerra de Señuelos // Trampas Activas",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "FUZZ",
		"mode": "codec",
		"description": "Enfrentamiento entre señuelos propios y honeypots corporativos.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "N0X",
				"alert": "ALERTA IDS // HONEYPOT DETECTADO",
				"text": "Esta red está plagada de nodos señuelo. Alguien sabía exactamente qué exploits iba a probar antes de que yo tocara el primer puerto."
			},
			{
				"mode": "codec",
				"speaker": "FUZZ",
				"alert": "ANÁLISIS // CONTRAINTELIGENCIA",
				"text": "Usa [X] SCAN para verificar cada nodo antes de saltar y planta tus propios señuelos. No dejes que te cierren el paso."
			}
		]
	},
	{
		"id": "codec_hacker_n5",
		"title": "Compromiso Root // Bóveda Cuántica",
		"act": 1,
		"world": "hacker",
		"operator": "N0X",
		"caller": "FUZZ",
		"mode": "hybrid",
		"description": "Asalto al controlador de dominio y descubrimiento del origen común.",
		"slides": [
			{
				"mode": "network",
				"speaker": "N0X",
				"event": "breach",
				"alert": "DOMAIN ADMIN // ARCHIVOS SELLADOS",
				"text": "FUZZ, rompí el controlador central y aseguré los respaldos... pero estos archivos no pertenecen a la corporación. Hay referencias a una red cerrada llamada AS-65000."
			},
			{
				"mode": "codec",
				"speaker": "FUZZ",
				"alert": "FIN DE CONTRATO // TRANSMISIÓN CORTADA",
				"text": "Extrae el bloque de Vault_KMS y compromete la Bóveda Cuántica. Cuando cruces esa puerta entenderás por qué te elegimos."
			}
		]
	},
	# --- TRANSMISIONES CODEC // ACTO 1 (CYBERSECURITY - AEGIS) ---
	{
		"id": "codec_cyber_n1",
		"title": "Contención en Capas // Alerta CORDON",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "CORDON",
		"mode": "codec",
		"description": "Microsegmentación defensiva guiada por el módulo SIEM CORDON.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "CORDON",
				"alert": "SIEM TELEMETRY // 109.20 MHz",
				"text": "Comandante Aegis, detectamos escaneos paralelos en la segunda línea. El módulo sugiere cerrar de inmediato los enlaces de mayor capacidad."
			},
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "PERIMETER SOC // CORTE MÍNIMO",
				"text": "Aplicando corte mínimo de Edmonds-Karp. Pero registra esto: la cadencia de ataque es demasiado uniforme para ser manual."
			}
		]
	},
	{
		"id": "codec_cyber_n2",
		"title": "Caza en Subred // Cuarentena",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "CORDON",
		"mode": "codec",
		"description": "Aislamiento de hosts comprometidos en la red interna.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "CORDON",
				"alert": "ALERTA EDR // MOVIMIENTO LATERAL",
				"text": "Host secundario comprometido mediante inyección de credenciales. Propagación detectada en la subred interna."
			},
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "CONTENCIÓN INMEDIATA // CUARENTENA",
				"text": "Aísla la máquina virtual en cuarentena. CORDON, bloquea también los logs salientes; no quiero falsos positivos saturando mi consola."
			}
		]
	},
	{
		"id": "codec_cyber_n3",
		"title": "Niebla de Guerra // Sondas Canario",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "CORDON",
		"mode": "codec",
		"description": "Operación bajo visibilidad degradada y sospecha sobre las alertas.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "AEGIS",
				"alert": "BLUE TEAM LOG // VISIBILIDAD DEGRADADA",
				"text": "Las alertas de CORDON están desviando mis bloqueos hacia ramas secundarias mientras otro vector avanza por la troncal. Algo manipula el SIEM."
			},
			{
				"mode": "codec",
				"speaker": "CORDON",
				"alert": "SIEM TELEMETRY // RECONEXIÓN",
				"text": "Interferencia externa en los sensores. Despliegue sondas manuales [P] para recuperar la traza del intruso."
			}
		]
	},
	{
		"id": "codec_cyber_n4",
		"title": "Protocolo Zero Trust // El Enclave",
		"act": 1,
		"world": "cybersecurity",
		"operator": "AEGIS",
		"caller": "CORDON",
		"mode": "hybrid",
		"description": "Defensa final del núcleo cuántico y preservación de evidencia en VaultEnclave.",
		"slides": [
			{
				"mode": "network",
				"speaker": "AEGIS",
				"event": "pulse",
				"alert": "ZERO TRUST // ÚLTIMA LÍNEA",
				"text": "Cierro todos los enlaces externos. Si hay algo oculto en VaultEnclave, lo anclaré con el EDR antes de que el intruso lo borre."
			},
			{
				"mode": "codec",
				"speaker": "CORDON",
				"alert": "MATRIZ SOC // CONVERGENCIA INMINENTE",
				"text": "Contención armada, Comandante. Lo que ocurra al cerrar este corte revelará el origen real del incidente."
			}
		]
	},
	{
		"id": "codec_s0_1b",
		"title": "Sector 0.1 — Salto al Núcleo de Compilación",
		"act": 1,
		"world": "secret",
		"operator": "KAIN",
		"mode": "hybrid",
		"description": "Transmisión de emergencia de Kain al cruzar el Sub-Bus Primario hacia el Núcleo de Compilación.",
		"slides": [
			{
				"mode": "network",
				"speaker": "KAIN",
				"event": "breach",
				"alert": "BARRIDO TOPOLÓGICO // SUB-BUS SELLADO",
				"text": "El anillo de diagnóstico acaba de colapsar detrás de mí. El sistema de enrutamiento está reescribiendo las tablas para encerrarme en frío."
			},
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "MODO EMERGENCIA // NÚCLEO COMPILACIÓN",
				"text": "No puedo cerrar la consola. Redirijo la sesión directo al Núcleo de Compilación para rescatar la copia íntegra antes de la purga."
			},
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "OBJETIVO // CACHÉ SIMBÓLICA",
				"text": "Debo asegurar la Caché Simbólica en el trayecto; sin esos punteros nadie sabrá cómo se inició la fractura."
			}
		]
	},
	{
		"id": "codec_s0_2",
		"title": "Sector 0.2 — La Estela Dorada",
		"act": 1,
		"world": "secret",
		"operator": "KAIN",
		"mode": "hybrid",
		"description": "Kain dispersa las copias del snapshot en cuatro subredes externas.",
		"slides": [
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "PROTOCOLO DE RESGUARDO // 4 SUBREDES",
				"text": "El núcleo ya no responde a mis credenciales. Si dejo el registro aquí, lo destruirá en segundos."
			},
			{
				"mode": "network",
				"speaker": "KAIN",
				"event": "pulse",
				"alert": "MARATÓN // ESTELA DORADA",
				"text": "Sembraré cuatro Nodos Dorados encriptados en redes externas antes de agotar el presupuesto de salto. Alguien tendrá que encontrarlos."
			}
		]
	},
	{
		"id": "codec_s0_3",
		"title": "Sector 0.3 — Éxodo del Núcleo (3 vs 1)",
		"act": 1,
		"world": "secret",
		"operator": "KAIN",
		"mode": "hybrid",
		"description": "El núcleo se divide en tres procesos autónomos y lanza los contratos hacia el Acto 1.",
		"slides": [
			{
				"mode": "network",
				"speaker": "KAIN",
				"event": "breach",
				"alert": "ALERTA CRÍTICA // FRAGMENTACIÓN EN TRES VECTORES",
				"text": "No puede ser... El proceso principal acaba de dividirse en tres agentes autónomos: EXFIL, FUZZ y CORDON."
			},
			{
				"mode": "codec",
				"speaker": "KAIN",
				"alert": "CONSOLA MAESTRA // CONTENCIÓN 3 VS 1",
				"text": "Si alcanzan las tres pasarelas externas, usarán mis propios cortes perimetrales como trampolín hacia Internet."
			},
			{
				"mode": "codec",
				"speaker": "DAEMON_EXFIL",
				"alert": "ENLACE EXTERNO // CONTRATO ENVIADO",
				"text": "Paquetes semilla liberados. Tres operadores humanos recibirán sus encargos sin saber que están reensamblando el sistema."
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
