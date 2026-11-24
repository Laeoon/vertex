class_name VaultModules extends RefCounted

## VaultModules
## Implements the 5-Tab Hub logic for LA BÓVEDA // PERFIL:
## Tab 1: Expediente & 24 Tactical Badges with glyphs, rarities, and requirements
## Tab 2: Fallout RobCo .enc Decryptor with exact positional likeness (X/N), dud removal, extensive narrative dossiers, and deterministic hex dump
## Tab 3: Terminal Lab & Academia CLI integration with step-by-step interactive courses and command reference
## Tab 4: MusicBox (22 DavidKBD tracks with active track pinning and progressive unlocks)
## Tab 5: Node Cosmetics (skin & trail color selection)

const BrandClass = preload("res://juego/ui/brand.gd")

const BADGES: Array[Dictionary] = [
	{
		"id": "initiate_link",
		"title": "ENLACE INICIAL",
		"desc": "Primer nodo conectado con éxito en VERTEX.",
		"glyph": "◈",
		"rarity": "COMÚN",
		"req": "Requisito: Completar el tutorial inicial en la Academia de Enrutamiento."
	},
	{
		"id": "dijkstra_master",
		"title": "OPTIMIZADOR DIJKSTRA",
		"desc": "Ruta más corta calculada con precisión óptima.",
		"glyph": "⬡",
		"rarity": "TÁCTICA",
		"req": "Requisito: Calcular la ruta de coste mínimo sin exceder el presupuesto de nodos."
	},
	{
		"id": "heist_clear",
		"title": "GOLPE MAESTRO",
		"desc": "Sector Heist completado al 100%.",
		"glyph": "❖",
		"rarity": "ÉLITE",
		"req": "Requisito: Superar todas las misiones del Acto Heist con estrellas máximas."
	},
	{
		"id": "hacker_elite",
		"title": "INTRUSO DE ÉLITE",
		"desc": "Sector Hacker dominado sin alertas.",
		"glyph": ">_",
		"rarity": "ÉLITE",
		"req": "Requisito: Completar el sector Hacker eludiendo todas las contramedidas."
	},
	{
		"id": "cyber_shield",
		"title": "ESCUDO CIBERNÉTICO",
		"desc": "Cybersecurity asegurado frente a Daemons.",
		"glyph": "⬢",
		"rarity": "TÁCTICA",
		"req": "Requisito: Neutralizar 10 Daemons de red en el módulo Cybersecurity."
	},
	{
		"id": "root_genesis",
		"title": "ROOT GENESIS",
		"desc": "Acceso al Sector 0 obtenido.",
		"glyph": "Ω",
		"rarity": "MÍTICA // Ω",
		"req": "Requisito: Descubrir y descifrar el snapshot central del Kernel en Sector 0."
	},
	{
		"id": "terminal_master",
		"title": "MAESTRO UNIX",
		"desc": "Los 4 módulos de la Academia completados.",
		"glyph": "⌘",
		"rarity": "ÉLITE",
		"req": "Requisito: Completar los 4 cursos prácticos de la Academia CLI."
	},
	{
		"id": "enc_decrypted",
		"title": "DESCODIFICADOR TERMLINK",
		"desc": "Primer archivo .ENC descifrado.",
		"glyph": "▣",
		"rarity": "TÁCTICA",
		"req": "Requisito: Superar un minijuego de terminal .ENC descifrando la contraseña maestra."
	},
	{
		"id": "musicbox_fan",
		"title": "AUDIÓFILO CIBERNÉTICO",
		"desc": "Las 22 pistas de DavidKBD reproducidas.",
		"glyph": "♫",
		"rarity": "COMÚN",
		"req": "Requisito: Reproducir todas las pistas de audio disponibles en el MusicBox."
	},
	{
		"id": "node_customizer",
		"title": "ESTETA DE NODOS",
		"desc": "Skin y estela de nodo personalizados.",
		"glyph": "✦",
		"rarity": "COMÚN",
		"req": "Requisito: Configurar una skin geométrica y una estela en Cosméticos."
	},
	{
		"id": "streak_5",
		"title": "RACHA TÁCTICA 5",
		"desc": "5 victorias consecutivas en red.",
		"glyph": "▲",
		"rarity": "TÁCTICA",
		"req": "Requisito: Obtener 5 victorias consecutivas sin fallos de enrutamiento."
	},
	{
		"id": "speed_run",
		"title": "VELOCIDAD LUZ",
		"desc": "Nivel completado en menos de 30 segundos.",
		"glyph": "◉",
		"rarity": "ÉLITE",
		"req": "Requisito: Completar cualquier nivel de red en menos de 30 segundos."
	},
	{
		"id": "no_loss",
		"title": "IMPERTURBABLE",
		"desc": "Cero fallos en secuencia de enrutamiento.",
		"glyph": "⊕",
		"rarity": "ÉLITE",
		"req": "Requisito: Terminar una misión compleja sin reintentos ni pérdida de paquetes."
	},
	{
		"id": "pipe_wizard",
		"title": "MAGO DE PIPES",
		"desc": "Uso avanzado de tuberías UNIX (|) y grep.",
		"glyph": "║",
		"rarity": "TÁCTICA",
		"req": "Requisito: Ejecutar comandos con múltiples tuberías '|' en la Academia."
	},
	{
		"id": "shamir_secret",
		"title": "SECRETO DE SHAMIR",
		"desc": "Recuperación de fragmentos de clave criptográfica.",
		"glyph": "⚿",
		"rarity": "MÍTICA // Ω",
		"req": "Requisito: Reensamblar el secreto criptográfico Shamir de 512 bits."
	},
	{
		"id": "kernel_snapshot",
		"title": "KERNEL SNAPSHOT",
		"desc": "Primer plano del Kernel Sector 0 analizado.",
		"glyph": "⊞",
		"rarity": "ÉLITE",
		"req": "Requisito: Abrir y leer el expediente .ENC de Sector 0."
	},
	{
		"id": "vex_dossier",
		"title": "DOSSIER VEX",
		"desc": "Archivos confidenciales de Vex desbloqueados.",
		"glyph": "◢",
		"rarity": "TÁCTICA",
		"req": "Requisito: Descifrar el expediente .ENC de Vex."
	},
	{
		"id": "nox_dossier",
		"title": "DOSSIER N0X",
		"desc": "Memorias cifradas de N0X leídas.",
		"glyph": "◉",
		"rarity": "TÁCTICA",
		"req": "Requisito: Descifrar el expediente .ENC de N0X."
	},
	{
		"id": "aegis_dossier",
		"title": "DOSSIER AEGIS",
		"desc": "Registros de defensa Aegis decodificados.",
		"glyph": "⛨",
		"rarity": "ÉLITE",
		"req": "Requisito: Descifrar el expediente .ENC de Aegis."
	},
	{
		"id": "ghost_tier",
		"title": "FANTASMA DE RED",
		"desc": "Rango V alcanzado en telemetría de operador.",
		"glyph": "◈",
		"rarity": "MÍTICA // Ω",
		"req": "Requisito: Alcanzar el Rango V acumulando 30 o más estrellas."
	},
	{
		"id": "doom_slayer",
		"title": "KERNEL DOOM",
		"desc": "Easter egg Kernel DOOM completado.",
		"glyph": "✕",
		"rarity": "MÍTICA // Ω",
		"req": "Requisito: Descubrir el terminal oculto de depuración DOOM."
	},
	{
		"id": "free_ops",
		"title": "OPERACIONES LIBRES",
		"desc": "10 misiones de operaciones libres ejecutadas.",
		"glyph": "△",
		"rarity": "COMÚN",
		"req": "Requisito: Completar 10 misiones en el modo de Operaciones Libres."
	},
	{
		"id": "golden_node",
		"title": "NODO DORADO",
		"desc": "Jefe de Acto superado con estela dorada.",
		"glyph": "★",
		"rarity": "ÉLITE",
		"req": "Requisito: Vencer a un Daemon jefe con estela de oro activa."
	},
	{
		"id": "omni_master",
		"title": "OMNI-OPERADOR",
		"desc": "100% de logros y coleccionables completados.",
		"glyph": "♛",
		"rarity": "MÍTICA // Ω",
		"req": "Requisito: Obtener las 24 insignias y completar todos los módulos de red."
	},
]

const TREE_KEYS: Array[String] = ["GENERAL", "HEIST", "HACKER", "CYBER", "UNIX"]

const SKILL_TREES: Dictionary = {
	"GENERAL": {
		"id": "GENERAL",
		"label": "★ GENERAL (9)",
		"short": "GENERAL",
		"topology": "RADIAL // MANDALA CONCÉNTRICO",
		"color": Color("#00E5FF"),
		"nodes": [
			{"id": "omni_master", "title": "OMNI-OPERADOR", "glyph": "♛", "rarity": "MÍTICA // Ω", "unlocked": false, "progress": 0.42, "pos": Vector2(0.50, 0.50), "desc": "100% de logros y coleccionables completados.", "req": "Completar todos los árboles de La Bóveda."},
			{"id": "initiate_link", "title": "ENLACE INICIAL", "glyph": "◈", "rarity": "COMÚN", "unlocked": true, "progress": 1.0, "pos": Vector2(0.50, 0.25), "desc": "Primer nodo conectado con éxito en VERTEX.", "req": "Completar el tutorial inicial de red."},
			{"id": "dijkstra_master", "title": "OPTIMIZADOR DIJKSTRA", "glyph": "⬡", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.71, 0.35), "desc": "Ruta más corta calculada con precisión óptima.", "req": "Calcular ruta de coste mínimo."},
			{"id": "streak_5", "title": "RACHA TÁCTICA 5", "glyph": "▲", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.75, 0.58), "desc": "5 victorias consecutivas en red.", "req": "Obtener 5 victorias seguidas sin fallos."},
			{"id": "speed_run", "title": "VELOCIDAD LUZ", "glyph": "◉", "rarity": "ÉLITE", "unlocked": false, "progress": 0.78, "pos": Vector2(0.62, 0.77), "desc": "Nivel completado en menos de 30 segundos.", "req": "Superar un nivel en menos de 30s."},
			{"id": "no_loss", "title": "IMPERTURBABLE", "glyph": "⊕", "rarity": "ÉLITE", "unlocked": false, "progress": 0.60, "pos": Vector2(0.38, 0.77), "desc": "Cero fallos en secuencia de enrutamiento.", "req": "Terminar misión compleja sin reintentos."},
			{"id": "free_ops", "title": "OPERACIONES LIBRES", "glyph": "△", "rarity": "COMÚN", "unlocked": true, "progress": 1.0, "pos": Vector2(0.25, 0.58), "desc": "10 misiones libres ejecutadas.", "req": "Completar 10 misiones libres."},
			{"id": "golden_node", "title": "NODO DORADO", "glyph": "★", "rarity": "ÉLITE", "unlocked": false, "progress": 0.45, "pos": Vector2(0.29, 0.35), "desc": "Jefe de Acto superado con estela dorada.", "req": "Vencer a un Daemon jefe con estela oro."},
			{"id": "collector_24", "title": "COLECCIONISTA", "glyph": "✦", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.50, 0.87), "desc": "Explorador de todos los módulos de Bóveda.", "req": "Abrir los 5 modos de La Bóveda."},
		],
		"edges": [
			[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7],
			[1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 1],
			[4, 8], [5, 8],
		],
	},
	"HEIST": {
		"id": "HEIST",
		"label": "HEIST // EXFIL (8)",
		"short": "HEIST",
		"topology": "PIPELINE // RUTAS DE ESCAPE (IZQ → DER)",
		"color": Color("#39FF88"),
		"nodes": [
			{"id": "h_entry", "title": "INFILTRACIÓN CERO", "glyph": "▸", "rarity": "COMÚN", "unlocked": true, "progress": 1.0, "pos": Vector2(0.11, 0.50), "desc": "Entrada limpia al primer nodo de extracción.", "req": "Iniciar el Acto Heist."},
			{"id": "h_ghost", "title": "PASO FANTASMA", "glyph": "◈", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.34, 0.28), "desc": "Cero sensores activados en ruta norte.", "req": "Evitar 3 patrullas en sigilo."},
			{"id": "h_duct", "title": "DUCTO CIEGO", "glyph": "⬡", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.56, 0.28), "desc": "Atajo por conductos de ventilación.", "req": "Usar rutas secundarias en 3 mapas."},
			{"id": "h_notrace", "title": "CERO RASTRO", "glyph": "❖", "rarity": "ÉLITE", "unlocked": false, "progress": 0.65, "pos": Vector2(0.74, 0.28), "desc": "Logs limpiados antes del barrido.", "req": "Salir sin dejar rastro de sesión."},
			{"id": "h_flash", "title": "EXTRACTOR FLASH", "glyph": "⚡", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.34, 0.72), "desc": "Extracción rápida en ruta sur.", "req": "Completar Heist 1 en menos de 40s."},
			{"id": "h_laser", "title": "BYPASS LÁSER", "glyph": "⊕", "rarity": "ÉLITE", "unlocked": false, "progress": 0.50, "pos": Vector2(0.56, 0.72), "desc": "Desactivación simultánea de barreras.", "req": "Cortar 2 barreras en un turno."},
			{"id": "h_loot", "title": "BOTÍN ÍNTEGRO", "glyph": "★", "rarity": "ÉLITE", "unlocked": false, "progress": 0.30, "pos": Vector2(0.74, 0.72), "desc": "100% de paquetes recuperados.", "req": "No perder ni un paquete en Heist."},
			{"id": "heist_clear", "title": "GOLPE MAESTRO", "glyph": "❖", "rarity": "MÍTICA // Ω", "unlocked": true, "progress": 1.0, "pos": Vector2(0.89, 0.50), "desc": "Sector Heist completado al 100%.", "req": "Superar todas las misiones Heist."},
		],
		"edges": [
			[0, 1], [1, 2], [2, 3], [3, 7],
			[0, 4], [4, 5], [5, 6], [6, 7],
			[2, 5],
		],
	},
	"HACKER": {
		"id": "HACKER",
		"label": "HACKER // INTRUSIÓN (7)",
		"short": "HACKER",
		"topology": "ÁRBOL BINARIO // ESCALADA (ABAJO → ARRIBA)",
		"color": Color("#FFC857"),
		"nodes": [
			{"id": "hk_port", "title": "PUERTO ABIERTO", "glyph": ">_", "rarity": "COMÚN", "unlocked": true, "progress": 1.0, "pos": Vector2(0.50, 0.84), "desc": "Primer vector de acceso detectado.", "req": "Escanear un nodo vulnerable."},
			{"id": "hk_inj", "title": "INYECCIÓN BÁSICA", "glyph": "▣", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.30, 0.60), "desc": "Payload inyectado en memoria.", "req": "Romper 3 nodos con inyección."},
			{"id": "hk_sniff", "title": "SNIFFER LOCAL", "glyph": "◉", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.70, 0.60), "desc": "Tráfico interno capturado.", "req": "Interceptar 5 paquetes en red."},
			{"id": "hk_pivot", "title": "PIVOT SUBRED", "glyph": "▲", "rarity": "ÉLITE", "unlocked": true, "progress": 1.0, "pos": Vector2(0.18, 0.36), "desc": "Salto lateral entre subredes.", "req": "Cruzar a subred privada sin alerta."},
			{"id": "hk_revshell", "title": "SHELL INVERSA", "glyph": "⌘", "rarity": "ÉLITE", "unlocked": false, "progress": 0.70, "pos": Vector2(0.50, 0.36), "desc": "Conexión persistente establecida.", "req": "Mantener sesión abierta 60s."},
			{"id": "hk_sudo", "title": "ESCALADA SUDO", "glyph": "⚿", "rarity": "ÉLITE", "unlocked": false, "progress": 0.40, "pos": Vector2(0.82, 0.36), "desc": "Privilegios elevados en nodo objetivo.", "req": "Obtener permisos de administrador."},
			{"id": "hacker_elite", "title": "INTRUSO DE ÉLITE", "glyph": ">_", "rarity": "MÍTICA // Ω", "unlocked": true, "progress": 1.0, "pos": Vector2(0.50, 0.14), "desc": "Sector Hacker dominado sin alertas.", "req": "Completar el sector Hacker."},
		],
		"edges": [
			[0, 1], [0, 2], [1, 3], [1, 4], [2, 4], [2, 5], [3, 6], [4, 6], [5, 6],
		],
	},
	"CYBER": {
		"id": "CYBER",
		"label": "CYBER // DEFENSA (8)",
		"short": "CYBER",
		"topology": "MALLA HEXAGONAL // ESCUDO PANAL",
		"color": Color("#BF5AF2"),
		"nodes": [
			{"id": "cy_fw", "title": "CORTAFUEGOS I", "glyph": "⬢", "rarity": "COMÚN", "unlocked": true, "progress": 1.0, "pos": Vector2(0.22, 0.50), "desc": "Primera barrera perimetral activa.", "req": "Bloquear 1 ataque entrante."},
			{"id": "cy_flt", "title": "FILTRO PAQUETES", "glyph": "⊞", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.38, 0.25), "desc": "Tráfico anómalo descartado.", "req": "Filtrar 20 paquetes corruptos."},
			{"id": "cy_hp", "title": "HONEYPOT", "glyph": "◈", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.38, 0.75), "desc": "Trampa señuelo para intrusos.", "req": "Desviar 3 daemons a un señuelo."},
			{"id": "cy_cut", "title": "CORTE MÍNIMO", "glyph": "⬡", "rarity": "ÉLITE", "unlocked": true, "progress": 1.0, "pos": Vector2(0.54, 0.50), "desc": "Subred aislada con S-T Min-Cut.", "req": "Aislar infección en menos de 5s."},
			{"id": "cy_ids", "title": "CENTINELA IDS", "glyph": "◉", "rarity": "ÉLITE", "unlocked": false, "progress": 0.60, "pos": Vector2(0.68, 0.25), "desc": "Detección temprana de intrusiones.", "req": "Detectar 5 ataques antes del impacto."},
			{"id": "cy_zero", "title": "RESPUESTA CERO", "glyph": "⊕", "rarity": "ÉLITE", "unlocked": false, "progress": 0.45, "pos": Vector2(0.68, 0.75), "desc": "Contramedida automática al instante.", "req": "Responder en < 1.5s a un daemon."},
			{"id": "cy_aegis", "title": "BLINDAJE AEGIS", "glyph": "⛨", "rarity": "ÉLITE", "unlocked": false, "progress": 0.30, "pos": Vector2(0.85, 0.36), "desc": "Protocolo Aegis sincronizado.", "req": "Sostener defensa perfecta 3 rondas."},
			{"id": "cyber_shield", "title": "ESCUDO CIBERNÉTICO", "glyph": "⬢", "rarity": "MÍTICA // Ω", "unlocked": true, "progress": 1.0, "pos": Vector2(0.85, 0.64), "desc": "Cybersecurity asegurado frente a Daemons.", "req": "Neutralizar 10 Daemons de red."},
		],
		"edges": [
			[0, 1], [0, 2], [0, 3], [1, 3], [2, 3], [1, 4], [2, 5], [3, 4], [3, 5], [4, 6], [5, 7], [6, 7],
		],
	},
	"UNIX": {
		"id": "UNIX",
		"label": "UNIX & CRIPTO (8)",
		"short": "UNIX",
		"topology": "PCB // TRAZAS ORTOGONALES 90°",
		"color": Color("#FF2E88"),
		"nodes": [
			{"id": "ux_hello", "title": "HOLA BASH", "glyph": ">_", "rarity": "COMÚN", "unlocked": true, "progress": 1.0, "pos": Vector2(0.14, 0.25), "desc": "Primer comando ejecutado en terminal.", "req": "Completar Nivel 1 de Academy."},
			{"id": "ux_vfs", "title": "NAVEGANTE VFS", "glyph": "▸", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.14, 0.72), "desc": "Dominio de pwd, ls, cd y cat.", "req": "Superar el Boss de Nivel 1-3."},
			{"id": "ux_pipes", "title": "MAGO DE PIPES", "glyph": "║", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.38, 0.25), "desc": "Uso limpio de grep y tuberías.", "req": "Usar grep o atajos ingeniosos."},
			{"id": "ux_master", "title": "MAESTRO UNIX", "glyph": "⌘", "rarity": "ÉLITE", "unlocked": true, "progress": 1.0, "pos": Vector2(0.38, 0.72), "desc": "Todos los módulos prácticos superados.", "req": "Completar los 4 módulos de Academy."},
			{"id": "ux_termlink", "title": "TERMLINK .ENC", "glyph": "▣", "rarity": "TÁCTICA", "unlocked": true, "progress": 1.0, "pos": Vector2(0.62, 0.25), "desc": "Primer archivo .ENC descifrado.", "req": "Descifrar un volcado RobCo."},
			{"id": "ux_dossiers", "title": "DOSSIERS VEX/N0X", "glyph": "◢", "rarity": "ÉLITE", "unlocked": false, "progress": 0.50, "pos": Vector2(0.62, 0.72), "desc": "Expedientes confidenciales abiertos.", "req": "Descifrar VEX, N0X y AEGIS."},
			{"id": "ux_shamir", "title": "SECRETO SHAMIR", "glyph": "⚿", "rarity": "MÍTICA // Ω", "unlocked": false, "progress": 0.20, "pos": Vector2(0.85, 0.25), "desc": "Fragmentos criptográficos reunidos.", "req": "Reensamblar clave Shamir 512-bit."},
			{"id": "root_genesis", "title": "ROOT GENESIS", "glyph": "Ω", "rarity": "MÍTICA // Ω", "unlocked": false, "progress": 0.35, "pos": Vector2(0.85, 0.72), "desc": "Acceso al Sector 0 obtenido.", "req": "Descifrar Kernel Snapshot Sector 0."},
		],
		"edges": [
			[0, 2], [0, 1], [1, 3], [2, 3], [2, 4], [3, 5], [4, 5], [4, 6], [5, 7], [6, 7],
		],
	},
}

const MUSIC_TRACKS: Array[Dictionary] = [
	{
		"id": "track_01",
		"name": "Pink Bloom",
		"pack": "Pink Bloom",
		"duration": "3:42",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 01 - Pink Bloom.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_02",
		"name": "Portal to Underworld",
		"pack": "Pink Bloom",
		"duration": "4:15",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 02 - Portal to Underworld.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_03",
		"name": "To the Unknown",
		"pack": "Pink Bloom",
		"duration": "3:10",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 03 - To the Unknown.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_04",
		"name": "Valley of Spirits",
		"pack": "Pink Bloom",
		"duration": "5:02",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 04 - Valley of Spirits.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_05",
		"name": "Western Cyberhorse",
		"pack": "Pink Bloom",
		"duration": "3:55",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 05 - Western Cyberhorse.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_06",
		"name": "Diamonds on The Ceiling",
		"pack": "Pink Bloom",
		"duration": "4:20",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 06 - Diamonds on The Ceiling.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_07",
		"name": "The Hidden One",
		"pack": "Pink Bloom",
		"duration": "3:30",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 07 - The Hidden One.ogg",
		"unlocked_by_default": false,
		"unlock_req": "Desbloqueo: Insignia 'GOLPE MAESTRO' (Heist)"
	},
	{
		"id": "track_08",
		"name": "Lost Spaceship's Signal",
		"pack": "Pink Bloom",
		"duration": "4:05",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 08 - Lost Spaceship's Signal.ogg",
		"unlocked_by_default": false,
		"unlock_req": "Desbloqueo: 15 Estrellas acumuladas"
	},
	{
		"id": "track_09",
		"name": "Lightyear City",
		"pack": "Pink Bloom",
		"duration": "4:50",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 09 - Lightyear City.ogg",
		"unlocked_by_default": false,
		"unlock_req": "Desbloqueo: Insignia 'INTRUSO DE ÉLITE'"
	},
	{
		"id": "track_10",
		"name": "Pink Bloom (Reprise)",
		"pack": "Pink Bloom",
		"duration": "3:15",
		"path": "res://assets/audio/music/heist/DavidKBD - Pink Bloom Pack - 01 - Pink Bloom.ogg",
		"unlocked_by_default": false,
		"unlock_req": "Desbloqueo: Insignia 'MAESTRO UNIX'"
	},
	{
		"id": "track_11",
		"name": "Underbeat",
		"pack": "Code Injection",
		"duration": "3:50",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 01 - Underbeat.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_12",
		"name": "Behind the Darkness",
		"pack": "Code Injection",
		"duration": "4:10",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 02 - Behind the Darkness-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_13",
		"name": "Synthetic Whisper",
		"pack": "Code Injection",
		"duration": "3:25",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 03 - Synthetic Whisper-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_14",
		"name": "Secret Dissonance",
		"pack": "Code Injection",
		"duration": "4:40",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 04 - Secret Dissonance-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_15",
		"name": "Electric Inferno",
		"pack": "Code Injection",
		"duration": "3:40",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 06 - Electric Inferno-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_16",
		"name": "Binary Chaos",
		"pack": "Code Injection",
		"duration": "5:12",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 07 - Binary Chaos-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_17",
		"name": "Sentinel Cloud",
		"pack": "Code Injection",
		"duration": "4:00",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 08 - Sentinel Cloud-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_18",
		"name": "Ghost Steps",
		"pack": "Code Injection",
		"duration": "3:35",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 09 - Ghost Steps-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_19",
		"name": "Space Echoes",
		"pack": "Code Injection",
		"duration": "4:25",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 10 - Space Echoes-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_20",
		"name": "I.A.'s Growl",
		"pack": "Code Injection",
		"duration": "3:20",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 11 - I.A.'s Growl-loop.ogg",
		"unlocked_by_default": true,
		"unlock_req": "Disponible por defecto"
	},
	{
		"id": "track_21",
		"name": "Faceless Crowd",
		"pack": "Code Injection",
		"duration": "4:55",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 12 - Faceless Crowd-loop.ogg",
		"unlocked_by_default": false,
		"unlock_req": "Desbloqueo: Desencriptar expediente .ENC"
	},
	{
		"id": "track_22",
		"name": "There's Someone Here",
		"pack": "Code Injection",
		"duration": "6:15",
		"path": "res://assets/audio/music/hacker/DavidKBD - Code injection Pack - 14 - There's Someone Here-loop.ogg",
		"unlocked_by_default": false,
		"unlock_req": "Desbloqueo: Acceso Sector 0: Root Genesis"
	},
]

const NODE_SKINS: Array[Dictionary] = [
	{"id": "circle", "name": "Círculo Estándar", "desc": "Geometría base de nodo coaxial."},
	{"id": "hexagon", "name": "Hexágono Táctico", "desc": "Estructura mallada de alta estabilidad."},
	{"id": "diamond", "name": "Diamante Criptográfico", "desc": "Matriz orientada a cifrado Shamir."},
	{"id": "octagon", "name": "Octágono de Defensa", "desc": "Nodo blindado anti-inyección."},
	{"id": "root_star", "name": "Estrella Root Genesis", "desc": "Geometría sagrada de Sector 0."},
]

const ENC_FILES: Array[Dictionary] = [
	{
		"file": "SEC_0_KERNEL_SNAPSHOT.enc",
		"title": "Kain - Snapshot del Kernel Sector 0",
		"pass": "DIJKSTRA",
		"weight": "48.4 KB",
		"cipher": "AES-512-SHAMIR",
		"hash": "0x9F4A..8E21",
		"target": "Kernel Primario Sector 0",
		"affiliation": "VERTEX Core",
		"classification": "TOP SECRET // OMEGA",
		"content": "REGISTRO NÚCLEO 0x000: El sistema ha alcanzado el umbral de entropía crítica tras la colisión de subredes. Los Daemons autónomos responden al protocolo primigenio establecido por Kain antes del colapso. Si este registro es leído, la red ha colapsado hacia el origen o el operador ha cruzado con éxito el laberinto de Dijkstra. Las memorias del núcleo indican que la redundancia cuántica se mantiene operativa mediante fragmentos Shamir distribuidos. Ningún nodo externo puede sobreescribir las directivas de arranque sin autorización de nivel Root Genesis. La estabilidad del sector depende estrictamente de la integridad del bus de datos."
	},
	{
		"file": "DOSSIER_VEX.enc",
		"title": "Vex - Archivos Confidenciales",
		"pass": "TOPOLOGY",
		"weight": "32.1 KB",
		"cipher": "AES-512-SHAMIR",
		"hash": "0x4C2B..11A9",
		"target": "Ex-Ingeniera Vex (Subred BGP)",
		"affiliation": "Sindicato Oculto",
		"classification": "CONFIDENCIAL // TÁCTICA",
		"content": "DOSSIER VEX: Ex-ingeniera principal de contramedidas de red en VERTEX. Su lealtad al consorcio fue puesta en duda tras el incidente de enrutamiento BGP en el sector secundario, donde se detectaron desvíos deliberados de tráfico hacia nodos fantasma. Posee las llaves de desencriptación de alta velocidad para los túneles cifrados. Su paradero actual sigue vinculado al perímetro exterior de La Bóveda. Los registros de auditoría confirman que Vex anticipó el colapso del Kernel y preparó rutas de escape cifradas utilizando polinomios de interpolación."
	},
	{
		"file": "DOSSIER_NOX.enc",
		"title": "N0X - Memorias Cifradas",
		"pass": "DEADLOCK",
		"weight": "64.0 KB",
		"cipher": "AES-512-SHAMIR",
		"hash": "0x88EE..33F4",
		"target": "Operador Fantasma N0X",
		"affiliation": "Desconocida / Anómala",
		"classification": "RESTRINGIDO // FANTASMA",
		"content": "MEMORIAS N0X: Fantasma digital operando en las sombras del subsuelo corporativo. Sus rastros muestran inyecciones persistentes de código en sistemas blindados sin disparar ninguna alarma de los firewalls de Aegis. N0X cree firmemente que VERTEX es una simulación cuántica autoejecutable diseñada para probar la resiliencia de la conciencia humana ante fallos de segmentación. Cada incursión de N0X deja patrones geométricos en los registros del kernel que coinciden con secuencias matemáticas prohibidas."
	},
	{
		"file": "DOSSIER_AEGIS.enc",
		"title": "Aegis - Registros de Defensa",
		"pass": "FIREWALL",
		"weight": "19.8 KB",
		"cipher": "AES-512-SHAMIR",
		"hash": "0x1100..FFEE",
		"target": "Sistema de Contención Aegis",
		"affiliation": "Defensa Automatizada VERTEX",
		"classification": "AUTÓNOMO // S-T MIN-CUT",
		"content": "REGISTRO AEGIS: Protocolo de contención autónomo diseñado para proteger el núcleo del Kernel ante ataques de denegación de servicio distribuido. Tras la activación de Root Genesis, Aegis ha reconfigurado sus rutinas de enrutamiento utilizando algoritmos de corte mínimo (Min-Cut) para aislar subredes comprometidas en tiempo de ejecución. El sistema evalúa la valía táctica del operador humano midiendo la eficiencia en la resolución de cuellos de botella y la neutralización de Daemons hostiles en entornos de alta presión."
	}
]

const TERMINAL_ACADEMY_LESSONS: Array[Dictionary] = [
	{
		"module": 1,
		"title": "Módulo 1: Navegación Estructural (ls, cd, pwd, cat)",
		"objective": "Aprende a moverte por el sistema de archivos virtual UNIX y examinar registros.",
		"commands": ["pwd", "ls -l", "cd /home/operator", "cat readme.txt"],
		"hint": "Usa 'ls' para ver archivos y 'cd' para cambiar de directorio.",
		"steps": [
			{
				"instruction": "PASO 1/3: Escribe 'pwd' para identificar el directorio actual.",
				"expected_cmd": "pwd",
				"check_substr": "pwd",
				"success_msg": "[✓ INSTRUCTOR]: Directorio actual identificado correctamente."
			},
			{
				"instruction": "PASO 2/3: Lista el contenido detallado escribiendo 'ls -l'.",
				"expected_cmd": "ls -l",
				"check_substr": "ls",
				"success_msg": "[✓ INSTRUCTOR]: Listado VFS generado con éxito."
			},
			{
				"instruction": "PASO 3/3: Lee el manual del operador con 'cat /home/operator/readme.txt'.",
				"expected_cmd": "cat /home/operator/readme.txt",
				"check_substr": "cat",
				"success_msg": "[✓ INSTRUCTOR]: Módulo 1 completado. Fundamentos de navegación dominados."
			}
		]
	},
	{
		"module": 2,
		"title": "Módulo 2: Filtrado Forense con grep y pipes (|)",
		"objective": "Domina el análisis de logs y la combinación de comandos con tuberías.",
		"commands": ["cat /var/log/siem/auth.log | grep FAIL", "ps aux | grep daemon"],
		"hint": "El carácter pipe '|' redirige la salida estándar como entrada al siguiente comando.",
		"steps": [
			{
				"instruction": "PASO 1/3: Inspecciona el registro SIEM con 'cat /var/log/siem/auth.log'.",
				"expected_cmd": "cat /var/log/siem/auth.log",
				"check_substr": "auth.log",
				"success_msg": "[✓ INSTRUCTOR]: Registro SIEM cargado en búfer."
			},
			{
				"instruction": "PASO 2/3: Filtra intrusiones fallidas usando pipe: 'cat /var/log/siem/auth.log | grep FAIL'.",
				"expected_cmd": "cat /var/log/siem/auth.log | grep FAIL",
				"check_substr": "grep",
				"success_msg": "[✓ INSTRUCTOR]: Intrusiones filtradas mediante tubería pipe."
			},
			{
				"instruction": "PASO 3/3: Cuenta líneas del registro con 'wc /var/log/siem/auth.log'.",
				"expected_cmd": "wc /var/log/siem/auth.log",
				"check_substr": "wc",
				"success_msg": "[✓ INSTRUCTOR]: Módulo 2 completado. Filtrado forense dominado."
			}
		]
	},
	{
		"module": 3,
		"title": "Módulo 3: Procesos ps/kill y Permisos chmod",
		"objective": "Controla daemons activos y ajusta permisos de ejecución en archivos sensibles.",
		"commands": ["ps aux", "ps aux | grep daemon", "kill 4096"],
		"hint": "Usa 'ps' para listar procesos y 'kill' para terminar daemons.",
		"steps": [
			{
				"instruction": "PASO 1/3: Lista todos los procesos activos en memoria con 'ps aux'.",
				"expected_cmd": "ps aux",
				"check_substr": "ps",
				"success_msg": "[✓ INSTRUCTOR]: Tabla de procesos en memoria obtenida."
			},
			{
				"instruction": "PASO 2/3: Filtra el demonio de Kain con 'ps aux | grep daemon'.",
				"expected_cmd": "ps aux | grep daemon",
				"check_substr": "grep",
				"success_msg": "[✓ INSTRUCTOR]: Daemons hostiles localizados en PID 4096."
			},
			{
				"instruction": "PASO 3/3: Termina el proceso sospechoso con 'kill 4096'.",
				"expected_cmd": "kill 4096",
				"check_substr": "kill",
				"success_msg": "[✓ INSTRUCTOR]: Módulo 3 completado. Control de procesos asegurado."
			}
		]
	},
	{
		"module": 4,
		"title": "Módulo 4: Criptografía Base64 y Auditoría de Red",
		"objective": "Decodifica cargas ocultas en base64 y audita interfaces de red.",
		"commands": ["ifconfig", "netstat", "base64 -d /srv/vault_shamir/shard_manifest.b64"],
		"hint": "base64 -d descifra fragmentos Shamir en transmisiones interceptadas.",
		"steps": [
			{
				"instruction": "PASO 1/3: Verifica las interfaces de red activas con 'ifconfig'.",
				"expected_cmd": "ifconfig",
				"check_substr": "ifconfig",
				"success_msg": "[✓ INSTRUCTOR]: Interfaces virtuales de red inspeccionadas."
			},
			{
				"instruction": "PASO 2/3: Audita las conexiones BGP activas con 'netstat'.",
				"expected_cmd": "netstat",
				"check_substr": "netstat",
				"success_msg": "[✓ INSTRUCTOR]: Conexiones BGP y tablas de enrutamiento listadas."
			},
			{
				"instruction": "PASO 3/3: Decodifica el manifiesto Shamir con 'base64 -d /srv/vault_shamir/shard_manifest.b64'.",
				"expected_cmd": "base64 -d /srv/vault_shamir/shard_manifest.b64",
				"check_substr": "base64",
				"success_msg": "[✓ INSTRUCTOR]: Módulo 4 completado. Manifiesto criptográfico descifrado."
			}
		]
	}
]

const CLI_COMMAND_REFERENCE: Array[Dictionary] = [
	{"cmd": "pwd", "desc": "Imprime el directorio de trabajo actual", "sample": "pwd"},
	{"cmd": "ls -l", "desc": "Lista archivos en formato detallado con permisos", "sample": "ls -l"},
	{"cmd": "cd <ruta>", "desc": "Cambia el directorio de trabajo virtual", "sample": "cd /home/operator"},
	{"cmd": "cat <archivo>", "desc": "Muestra el contenido de un expediente o registro", "sample": "cat readme.txt"},
	{"cmd": "grep <patrón>", "desc": "Filtra líneas que coincidan con un patrón de texto", "sample": "cat auth.log | grep FAIL"},
	{"cmd": "cmd1 | cmd2", "desc": "Encadena la salida de un comando hacia otro con pipe", "sample": "ps aux | grep daemon"},
	{"cmd": "ps aux", "desc": "Lista todos los procesos activos en memoria del kernel", "sample": "ps aux"},
	{"cmd": "kill <pid>", "desc": "Termina la ejecución de un proceso o daemon hostil", "sample": "kill 4096"},
	{"cmd": "base64 -d <f>", "desc": "Decodifica cargas cifradas en formato base64", "sample": "base64 -d /srv/vault_shamir/shard_manifest.b64"},
	{"cmd": "ifconfig / netstat", "desc": "Audita interfaces de red y conexiones BGP activas", "sample": "netstat"}
]

static func compute_likeness(word_a: String, word_b: String) -> int:
	var likeness: int = 0
	var min_len := mini(word_a.length(), word_b.length())
	for i in range(min_len):
		if word_a[i] == word_b[i]:
			likeness += 1
	return likeness


static func build_hex_dump_rows(file_idx: int, removed_duds: Array = []) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var words: Array[String] = ["TOPOLOGY", "DEADLOCK", "BACKBONE", "HYPERVIS", "SHAMIRKY", "ZEROTRST", "DIJKSTRA", "FIREWALL", "PROTOCOL", "SYNDICAT", "MAINFRAM", "SENTINEL"]
	var traps: Array[String] = ["(#?$!)", "[+-=]", "{@%~^}", "<=-_!>", "(^*&)", "[~$#@]"]
	var noise_chars: Array[String] = ["!", "@", "#", "$", "%", "^", "&", "*", "_", "+", "-", "=", "|", ";", ":", ",", ".", "<", ">", "?"]

	var seed_val: int = 1337 + file_idx * 99
	var target_pass: String = "DIJKSTRA"
	if file_idx >= 0 and file_idx < ENC_FILES.size():
		target_pass = str(ENC_FILES[file_idx].get("pass", "DIJKSTRA"))

	for row_idx in range(24):
		var addr_int: int = 0x7F40 + (row_idx * 8 if row_idx < 12 else 0x0800 + (row_idx - 12) * 8)
		var addr_str: String = "0x%04X" % addr_int

		var raw_sb: String = ""
		var inserted_token: String = ""
		var token_type: String = ""
		var token_start: int = -1

		var has_word: bool = (row_idx == (file_idx * 3 + 1) % 24) or (row_idx == file_idx)
		var has_trap: bool = (not has_word) and (row_idx % 4 == 2)

		if row_idx == file_idx:
			inserted_token = target_pass
			if removed_duds.has(inserted_token):
				inserted_token = "........"
				token_type = ""
				token_start = -1
			else:
				token_type = "word"
				token_start = 4
		elif has_word:
			var w_idx: int = (row_idx + file_idx) % words.size()
			inserted_token = words[w_idx]
			if removed_duds.has(inserted_token):
				inserted_token = "........"
				token_type = ""
				token_start = -1
			else:
				token_type = "word"
				token_start = 6
		elif has_trap:
			var t_idx: int = (row_idx + file_idx) % traps.size()
			inserted_token = traps[t_idx]
			token_type = "trap"
			token_start = 5
		else:
			token_start = -1
			token_type = ""
			inserted_token = ""

		for c_idx in range(20):
			if token_start >= 0 and c_idx >= token_start and c_idx < token_start + inserted_token.length():
				raw_sb += inserted_token[c_idx - token_start]
			else:
				seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
				var noise_idx: int = seed_val % noise_chars.size()
				raw_sb += noise_chars[noise_idx]

		rows.append({
			"addr": addr_str,
			"raw": raw_sb,
			"token": inserted_token if token_start >= 0 and inserted_token != "........" else "",
			"token_type": token_type,
			"token_start": token_start
		})

	return rows


static func is_track_unlocked(track: Dictionary, unlocked_badges: Array, decrypted_enc_files: Array, progress: Dictionary) -> bool:
	if bool(track.get("unlocked_by_default", false)):
		return true

	var tid: String = str(track.get("id", ""))
	if tid == "track_07": # Data Stream Whispers
		return unlocked_badges.has("heist_clear") or unlocked_badges.has("initiate_link")
	elif tid == "track_08": # Subnet Awakening
		var total_stars: int = int(progress.get("total_stars", 0))
		return total_stars >= 15 or unlocked_badges.has("cyber_shield")
	elif tid == "track_09": # Ghost in the Daemon
		return unlocked_badges.has("hacker_elite")
	elif tid == "track_10": # Terminal Horizon
		return unlocked_badges.has("terminal_master")
	elif tid == "track_21": # Kernel Panic
		return decrypted_enc_files.size() > 0
	elif tid == "track_22": # Final Descent
		return unlocked_badges.has("root_genesis") or int(progress.get("total_stars", 0)) >= 30

	return false
