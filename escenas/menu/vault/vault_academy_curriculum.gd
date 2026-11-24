extends RefCounted

## Currículo, sandboxes VFS y guía de referencia para VTX-ACADEMY.
## Español neutro formal en todo texto visible; cero menciones externas.

const MODULES: Array[Dictionary] = [
	{
		"id": "M1",
		"title": "01 // Navegación y Rutas",
		"commands_preview": "pwd, ls, ls -a, cd",
		"boss_name": "El Despacho Oculto",
		"exercises": [
			{
				"ask": "Confirma la ruta absoluta del directorio donde te encuentras actualmente.",
				"hint": "Escribe \"pwd\" y presiona [Enter].",
				"optimal_cmd": "pwd",
				"goal": {"type": "cmd_prefix", "value": "pwd"},
				"tool_card": {
					"syntax": "pwd",
					"explain": "Muestra la ruta absoluta del directorio donde te encuentras.",
					"example": "pwd",
				},
				"breakdown": [
					["pwd", "Print Working Directory: imprime tu ubicación exacta en el sistema"],
				],
			},
			{
				"ask": "Lista todos los archivos de \"descargas\", incluidos los archivos ocultos.",
				"hint": "Prueba \"ls -a descargas\" (1 paso) o \"cd descargas && ls -a\".",
				"optimal_cmd": "ls -a descargas",
				"goal": {"type": "stdout_contains", "value": ".clave_wifi.txt"},
				"tool_card": {
					"syntax": "ls -a [carpeta]",
					"explain": "'ls' lista archivos; '-a' revela los ocultos que inician con punto (.).",
					"example": "ls -a descargas",
				},
				"breakdown": [
					["ls -a", "lista todo el contenido incluyendo archivos con punto (.clave_wifi.txt)"],
					["descargas", "apunta directo a la carpeta sin mover tu ubicación"],
				],
			},
			{
				"ask": "Regresa directo a tu carpeta personal (/home/operator) desde documentos/proyecto.",
				"hint": "Usa \"cd ~\" o \"cd\".",
				"optimal_cmd": "cd ~",
				"start_cwd": "/home/operator/documentos/proyecto",
				"goal": {"type": "cwd_equals", "value": "/home/operator"},
				"tool_card": {
					"syntax": "cd ~",
					"explain": "'cd' cambia de carpeta y '~' apunta siempre a tu directorio personal.",
					"example": "cd ~",
				},
				"breakdown": [
					["cd", "cambia el directorio actual de trabajo"],
					["~", "atajo universal a /home/operator desde cualquier ruta"],
				],
			},
		],
		"boss_steps": [
			{
				"title": "Revelar archivos ocultos en descargas",
				"ask": "Lista los archivos (incluidos los ocultos) dentro de \"descargas\".",
				"hint": "Usa \"ls -a descargas\".",
				"optimal_cmd": "ls -a descargas",
				"goal": {"type": "stdout_contains", "value": ".clave_wifi.txt"},
			},
			{
				"title": "Confirmar ruta actual",
				"ask": "Imprime tu ruta de trabajo actual con pwd.",
				"hint": "Usa \"pwd\".",
				"optimal_cmd": "pwd",
				"goal": {"type": "cmd_prefix", "value": "pwd"},
			},
			{
				"title": "Volver al directorio personal",
				"ask": "Regresa a /home/operator usando \"cd ~\".",
				"hint": "Usa \"cd ~\".",
				"optimal_cmd": "cd ~",
				"goal": {"type": "cwd_equals", "value": "/home/operator"},
			},
		],
	},
	{
		"id": "M2",
		"title": "02 // Gestión de Archivos",
		"commands_preview": "cat, mkdir, rm",
		"boss_name": "Orden en el Nodo",
		"exercises": [
			{
				"ask": "Lee el contenido de \"documentos/manual.txt\" sin cambiar de carpeta.",
				"hint": "Escribe \"cat documentos/manual.txt\".",
				"optimal_cmd": "cat documentos/manual.txt",
				"goal": {"type": "stdout_contains", "value": "PROTOCOLO VERTEX"},
				"tool_card": {
					"syntax": "cat <ruta/archivo>",
					"explain": "Imprime en pantalla el contenido completo de un archivo de texto.",
					"example": "cat documentos/manual.txt",
				},
				"breakdown": [
					["cat", "lee y muestra el contenido del archivo"],
					["documentos/manual.txt", "ruta relativa directa sin usar cd"],
				],
			},
			{
				"ask": "Crea dos carpetas nuevas llamadas \"respaldo\" y \"logs\".",
				"hint": "Escribe \"mkdir respaldo logs\".",
				"optimal_cmd": "mkdir respaldo logs",
				"goal": {"type": "vfs_dirs_exist", "paths": ["/home/operator/respaldo", "/home/operator/logs"]},
				"tool_card": {
					"syntax": "mkdir <dir1> [dir2]",
					"explain": "Crea una o varias carpetas nuevas en un solo paso.",
					"example": "mkdir respaldo logs",
				},
				"breakdown": [
					["mkdir", "crea directorios nuevos"],
					["respaldo logs", "crea ambos directorios en una sola línea"],
				],
			},
			{
				"ask": "Elimina el archivo temporal \"basura.tmp\" de tu carpeta personal.",
				"hint": "Escribe \"rm basura.tmp\".",
				"optimal_cmd": "rm basura.tmp",
				"goal": {"type": "vfs_not_exists", "value": "/home/operator/basura.tmp"},
				"tool_card": {
					"syntax": "rm <archivo>",
					"explain": "Borra permanentemente el archivo indicado.",
					"example": "rm basura.tmp",
				},
				"breakdown": [
					["rm", "elimina el archivo indicado"],
					["basura.tmp", "archivo objetivo a remover"],
				],
			},
		],
		"boss_steps": [
			{
				"title": "Crear respaldo y logs",
				"ask": "Crea las carpetas \"respaldo\" y \"logs\".",
				"hint": "Usa \"mkdir respaldo logs\".",
				"optimal_cmd": "mkdir respaldo logs",
				"goal": {"type": "vfs_dirs_exist", "paths": ["/home/operator/respaldo", "/home/operator/logs"]},
			},
			{
				"title": "Inspeccionar manual.txt",
				"ask": "Muestra el contenido de \"documentos/manual.txt\".",
				"hint": "Usa \"cat documentos/manual.txt\".",
				"optimal_cmd": "cat documentos/manual.txt",
				"goal": {"type": "stdout_contains", "value": "PROTOCOLO VERTEX"},
			},
			{
				"title": "Depurar basura.tmp",
				"ask": "Elimina el archivo \"basura.tmp\".",
				"hint": "Usa \"rm basura.tmp\".",
				"optimal_cmd": "rm basura.tmp",
				"goal": {"type": "vfs_not_exists", "value": "/home/operator/basura.tmp"},
			},
		],
	},
	{
		"id": "M3",
		"title": "03 // Búsqueda y Filtros",
		"commands_preview": "grep, find, tail",
		"boss_name": "Rastreo de Registros",
		"exercises": [
			{
				"ask": "Filtra la línea que contiene la palabra \"clave\" dentro de \"registro.log\".",
				"hint": "Escribe \"grep clave registro.log\".",
				"optimal_cmd": "grep clave registro.log",
				"goal": {"type": "stdout_contains", "value": "clave=VTX-904"},
				"tool_card": {
					"syntax": "grep <texto> <archivo>",
					"explain": "Busca y muestra únicamente las líneas que contienen el patrón indicado.",
					"example": "grep clave registro.log",
				},
				"breakdown": [
					["grep", "filtra líneas coincidentes dentro de un archivo"],
					["clave", "patrón de búsqueda"],
					["registro.log", "archivo analizado directamente sin cat previo"],
				],
			},
			{
				"ask": "Localiza el archivo oculto \".acceso\" dentro de las subcarpetas.",
				"hint": "Escribe \"find . -name .acceso\".",
				"optimal_cmd": "find . -name .acceso",
				"goal": {"type": "stdout_contains", "value": ".acceso"},
				"tool_card": {
					"syntax": "find <ruta> -name <archivo>",
					"explain": "Recorre subcarpetas recursivamente para localizar archivos por nombre.",
					"example": "find . -name .acceso",
				},
				"breakdown": [
					["find .", "busca a partir de la carpeta actual (.)"],
					["-name .acceso", "filtra por el nombre exacto del archivo"],
				],
			},
			{
				"ask": "Muestra únicamente las últimas 2 líneas del archivo \"eventos.log\".",
				"hint": "Escribe \"tail -n 2 eventos.log\".",
				"optimal_cmd": "tail -n 2 eventos.log",
				"goal": {"type": "cmd_prefix_and_stdout", "prefix": "tail", "value": "SESION_ACTIVA"},
				"tool_card": {
					"syntax": "tail -n <N> <archivo>",
					"explain": "Muestra las últimas N líneas de un archivo (por defecto 10).",
					"example": "tail -n 2 eventos.log",
				},
				"breakdown": [
					["tail", "lee el final de un archivo"],
					["-n 2", "limita la salida a las últimas 2 líneas"],
				],
			},
		],
		"boss_steps": [
			{
				"title": "Localizar archivo .acceso",
				"ask": "Encuentra \".acceso\" en las subcarpetas con find.",
				"hint": "Usa \"find . -name .acceso\".",
				"optimal_cmd": "find . -name .acceso",
				"goal": {"type": "stdout_contains", "value": ".acceso"},
			},
			{
				"title": "Filtrar clave en registro.log",
				"ask": "Extrae la línea con \"clave\" de \"registro.log\".",
				"hint": "Usa \"grep clave registro.log\".",
				"optimal_cmd": "grep clave registro.log",
				"goal": {"type": "stdout_contains", "value": "clave=VTX-904"},
			},
			{
				"title": "Leer últimas líneas de eventos.log",
				"ask": "Muestra las últimas 2 líneas de \"eventos.log\".",
				"hint": "Usa \"tail -n 2 eventos.log\".",
				"optimal_cmd": "tail -n 2 eventos.log",
				"goal": {"type": "cmd_prefix_and_stdout", "prefix": "tail", "value": "SESION_ACTIVA"},
			},
		],
	},
	{
		"id": "M4",
		"title": "04 // Pipes y Decodificación",
		"commands_preview": "|, >, base64 -d",
		"boss_name": "Extracción Limpia",
		"exercises": [
			{
				"ask": "Encadena cat y grep con pipe (|) para filtrar \"ALERTA\" en \"trafico.log\".",
				"hint": "Escribe \"cat trafico.log | grep ALERTA\".",
				"optimal_cmd": "cat trafico.log | grep ALERTA",
				"goal": {"type": "stdout_contains", "value": "ALERTA_PERIMETRO"},
				"tool_card": {
					"syntax": "comando1 | comando2",
					"explain": "El operador '|' envía la salida de un comando como entrada del siguiente.",
					"example": "cat trafico.log | grep ALERTA",
				},
				"breakdown": [
					["cat trafico.log", "lee el contenido completo del registro"],
					["|", "conecta la salida estándar hacia el filtro"],
					["grep ALERTA", "conserva solo las líneas con ALERTA"],
				],
			},
			{
				"ask": "Decodifica el contenido en Base64 del archivo \"token.b64\".",
				"hint": "Escribe \"base64 -d token.b64\".",
				"optimal_cmd": "base64 -d token.b64",
				"goal": {"type": "stdout_contains", "value": "LLAVE-VERTICE-42"},
				"tool_card": {
					"syntax": "base64 -d <archivo|texto>",
					"explain": "Decodifica texto o archivos codificados en formato Base64.",
					"example": "base64 -d token.b64",
				},
				"breakdown": [
					["base64 -d", "bandera -d (--decode) para revertir Base64 a texto legible"],
					["token.b64", "archivo codificado objetivo"],
				],
			},
			{
				"ask": "Guarda las líneas con \"TOKEN\" de \"trafico.log\" dentro de \"salida.txt\".",
				"hint": "Escribe \"grep TOKEN trafico.log > salida.txt\".",
				"optimal_cmd": "grep TOKEN trafico.log > salida.txt",
				"goal": {"type": "vfs_file_contains", "path": "/home/operator/salida.txt", "substr": "TOKEN-771"},
				"tool_card": {
					"syntax": "comando > archivo",
					"explain": "Redirige la salida estándar y la guarda en un archivo nuevo.",
					"example": "grep TOKEN trafico.log > salida.txt",
				},
				"breakdown": [
					["grep TOKEN trafico.log", "extrae las líneas relevantes"],
					["> salida.txt", "escribe el resultado directamente en disco virtual"],
				],
			},
		],
		"boss_steps": [
			{
				"title": "Filtrar tráfico con pipe",
				"ask": "Filtra \"ALERTA\" de \"trafico.log\" usando pipe (|).",
				"hint": "Usa \"cat trafico.log | grep ALERTA\".",
				"optimal_cmd": "cat trafico.log | grep ALERTA",
				"goal": {"type": "stdout_contains", "value": "ALERTA_PERIMETRO"},
			},
			{
				"title": "Decodificar token.b64",
				"ask": "Decodifica \"token.b64\" en pantalla.",
				"hint": "Usa \"base64 -d token.b64\".",
				"optimal_cmd": "base64 -d token.b64",
				"goal": {"type": "stdout_contains", "value": "LLAVE-VERTICE-42"},
			},
			{
				"title": "Exportar TOKEN a salida.txt",
				"ask": "Guarda la línea con \"TOKEN\" de \"trafico.log\" en \"salida.txt\".",
				"hint": "Usa \"grep TOKEN trafico.log > salida.txt\".",
				"optimal_cmd": "grep TOKEN trafico.log > salida.txt",
				"goal": {"type": "vfs_file_contains", "path": "/home/operator/salida.txt", "substr": "TOKEN-771"},
			},
		],
	},
]

const SSH_LEVELS: Array[Dictionary] = [
	{
		"id": 0,
		"node_from": "nodo0",
		"node_to": "nodo1",
		"title": "Acceso Inicial",
		"tools": "ls, cat, ssh",
		"mission": "La clave para autenticarte en nodo1 se encuentra dentro de un archivo legible en tu carpeta actual.",
		"hint": "Lista los archivos con \"ls\", lee el contenido con \"cat instrucciones.txt\" y ejecuta \"ssh nodo1 <clave>\".",
		"expected_key": "VTX-N1-ALFA",
	},
	{
		"id": 1,
		"node_from": "nodo1",
		"node_to": "nodo2",
		"title": "Archivos Ocultos",
		"tools": "ls -a, cd, cat, ssh",
		"mission": "La credencial de nodo2 está escondida dentro de un archivo oculto en la carpeta \"boveda\".",
		"hint": "Usa \"ls -a boveda\" para descubrir el archivo con punto y léelo con \"cat boveda/<archivo>\".",
		"expected_key": "VTX-N2-SOMBRA",
	},
	{
		"id": 2,
		"node_from": "nodo2",
		"node_to": "nodo3",
		"title": "Laberinto de Directorios",
		"tools": "find, ls, cat, ssh",
		"mission": "Un archivo llamado \"credencial.dat\" guarda la llave de nodo3 dentro del árbol \"sectores/\".",
		"hint": "Ejecuta \"find sectores -name credencial.dat\" para ubicar la ruta exacta sin revisar carpeta por carpeta.",
		"expected_key": "VTX-N3-RUTA",
	},
	{
		"id": 3,
		"node_from": "nodo3",
		"node_to": "nodo4",
		"title": "Aguja en el Registro",
		"tools": "grep, tail, cat, ssh",
		"mission": "El archivo \"servidor.log\" contiene decenas de eventos. Encuentra la línea etiquetada con \"ACCESO_N4\".",
		"hint": "Filtra el archivo con \"grep ACCESO_N4 servidor.log\".",
		"expected_key": "VTX-N4-FILTRO",
	},
	{
		"id": 4,
		"node_from": "nodo4",
		"node_to": "nodo5",
		"title": "Carga Codificada",
		"tools": "grep, base64 -d, |, ssh",
		"mission": "El token maestro de nodo5 está codificado en Base64 dentro de \"paquete.b64\" (y referenciado en \"traza.log\").",
		"hint": "Decodifica el archivo con \"base64 -d paquete.b64\" o \"cat paquete.b64 | base64 -d\".",
		"expected_key": "VTX-N5-KERNEL",
	},
]

const GUIDE_SECTIONS: Array[Dictionary] = [
	{
		"id": "nav",
		"title": "Navegación y Directorios",
		"desc": "Ubicarte, explorar carpetas y moverte por el sistema de archivos.",
		"entries": [
			{"cmd": "pwd", "explain": "Imprime la ruta absoluta del directorio actual.", "ex": "pwd"},
			{"cmd": "ls [-l] [-a] [ruta]", "explain": "Lista archivos. '-a' incluye ocultos (.); '-l' muestra detalles.", "ex": "ls -a descargas"},
			{"cmd": "cd <ruta|~|..>", "explain": "Cambia de directorio. '~' vuelve a /home/operator; '..' sube un nivel.", "ex": "cd ~"},
		],
	},
	{
		"id": "files",
		"title": "Archivos y Carpetas",
		"desc": "Crear, leer, copiar, mover o eliminar elementos.",
		"entries": [
			{"cmd": "cat <archivo>", "explain": "Muestra todo el contenido de un archivo de texto.", "ex": "cat documentos/manual.txt"},
			{"cmd": "mkdir <dir1> [dir2]", "explain": "Crea una o más carpetas nuevas.", "ex": "mkdir respaldo logs"},
			{"cmd": "rm <archivo>", "explain": "Elimina un archivo del sistema.", "ex": "rm basura.tmp"},
			{"cmd": "cp / mv <src> <dst>", "explain": "Copia (cp) o mueve/renombra (mv) archivos.", "ex": "cp notas.txt respaldo/"},
		],
	},
	{
		"id": "search",
		"title": "Búsqueda y Filtrado",
		"desc": "Encontrar archivos por nombre o líneas específicas dentro de logs.",
		"entries": [
			{"cmd": "grep [-i] [-n] <texto> <arch>", "explain": "Filtra líneas que coinciden con el texto buscado.", "ex": "grep ACCESO_N4 servidor.log"},
			{"cmd": "find <ruta> -name <patrón>", "explain": "Busca archivos recursivamente dentro de subcarpetas.", "ex": "find . -name .acceso"},
			{"cmd": "head / tail -n <N> <arch>", "explain": "Muestra las primeras (head) o últimas (tail) N líneas.", "ex": "tail -n 2 eventos.log"},
		],
	},
	{
		"id": "pipes",
		"title": "Pipes, Redirección y SSH",
		"desc": "Encadenar herramientas, guardar resultados y escalar entre nodos.",
		"entries": [
			{"cmd": "cmd1 | cmd2", "explain": "Conecta la salida de cmd1 como entrada de cmd2.", "ex": "cat traza.log | grep PAYLOAD"},
			{"cmd": "cmd > archivo", "explain": "Guarda la salida del comando en un archivo.", "ex": "grep TOKEN trafico.log > salida.txt"},
			{"cmd": "base64 -d <arch|txt>", "explain": "Decodifica texto codificado en Base64.", "ex": "base64 -d paquete.b64"},
			{"cmd": "ssh <nodo> <clave>", "explain": "Autentica y avanza al siguiente nodo en Escalada SSH.", "ex": "ssh nodo1 VTX-N1-ALFA"},
		],
	},
]


static func build_guided_fs(mod_idx: int) -> Dictionary:
	var fs: Dictionary = {
		"/": {"type": "dir", "root_only": false, "children": ["home"]},
		"/home": {"type": "dir", "root_only": false, "children": ["operator"]},
		"/home/operator": {
			"type": "dir",
			"root_only": false,
			"children": ["descargas", "documentos", "notas.txt", "basura.tmp"],
		},
		"/home/operator/descargas": {
			"type": "dir",
			"root_only": false,
			"children": ["archivo.txt", ".clave_wifi.txt"],
		},
		"/home/operator/descargas/archivo.txt": {
			"type": "file",
			"root_only": false,
			"content": "Descarga estándar completada.",
		},
		"/home/operator/descargas/.clave_wifi.txt": {
			"type": "file",
			"root_only": false,
			"content": "SSID: VERTEX-MESH\nCLAVE_WIFI: VTX-8840",
		},
		"/home/operator/documentos": {
			"type": "dir",
			"root_only": false,
			"children": ["manual.txt", "proyecto"],
		},
		"/home/operator/documentos/manual.txt": {
			"type": "file",
			"root_only": false,
			"content": "PROTOCOLO VERTEX // MANUAL OPERATIVO\nUsa rutas relativas para leer archivos sin cambiar de directorio.",
		},
		"/home/operator/documentos/proyecto": {
			"type": "dir",
			"root_only": false,
			"children": ["estado.txt"],
		},
		"/home/operator/documentos/proyecto/estado.txt": {
			"type": "file",
			"root_only": false,
			"content": "Estado del proyecto: NOMINAL",
		},
		"/home/operator/notas.txt": {
			"type": "file",
			"root_only": false,
			"content": "Recordatorio: revisar carpeta descargas.",
		},
		"/home/operator/basura.tmp": {
			"type": "file",
			"root_only": false,
			"content": "TMP_BUFFER_000",
		},
	}

	if mod_idx == 2:
		var op_children: Array = (fs["/home/operator"] as Dictionary)["children"]
		op_children.append("registro.log")
		op_children.append("eventos.log")
		op_children.append("archivo_oculto")
		fs["/home/operator/registro.log"] = {
			"type": "file",
			"root_only": false,
			"content": "[INFO] Arranque de servicio\n[WARN] Latencia en enlace 2\n[SEC] clave=VTX-904\n[INFO] Sincronización completada",
		}
		fs["/home/operator/eventos.log"] = {
			"type": "file",
			"root_only": false,
			"content": "08:00 INIT_KERNEL\n08:01 LOAD_VFS\n08:02 NET_READY\n08:03 AUTH_OK\n08:04 SESION_ACTIVA",
		}
		fs["/home/operator/archivo_oculto"] = {
			"type": "dir",
			"root_only": false,
			"children": [".acceso"],
		}
		fs["/home/operator/archivo_oculto/.acceso"] = {
			"type": "file",
			"root_only": false,
			"content": "TOKEN_ACCESO: OK",
		}
	elif mod_idx == 3:
		var op_children4: Array = (fs["/home/operator"] as Dictionary)["children"]
		op_children4.append("trafico.log")
		op_children4.append("token.b64")
		fs["/home/operator/trafico.log"] = {
			"type": "file",
			"root_only": false,
			"content": "[OK] Paquete ICMP 10.0.0.1\n[WARN] ALERTA_PERIMETRO en puerto 22\n[OK] Heartbeat nodo_alpha\n[DATA] TOKEN-771 verificado",
		}
		fs["/home/operator/token.b64"] = {
			"type": "file",
			"root_only": false,
			"content": "TExBVkUtVkVSVElDRS00Mg==",
		}
	return fs


static func build_ssh_fs(level_idx: int) -> Dictionary:
	var fs: Dictionary = {
		"/": {"type": "dir", "root_only": false, "children": ["home"]},
		"/home": {"type": "dir", "root_only": false, "children": ["operator"]},
		"/home/operator": {"type": "dir", "root_only": false, "children": []},
	}
	var root_children: Array = (fs["/home/operator"] as Dictionary)["children"]
	match level_idx:
		0:
			root_children.append("instrucciones.txt")
			root_children.append("notas.txt")
			fs["/home/operator/instrucciones.txt"] = {
				"type": "file",
				"root_only": false,
				"content": "=== NODO 0 // BIENVENIDA ===\nLa contraseña para avanzar a nodo1 es:\nVTX-N1-ALFA\n\nEjecuta: ssh nodo1 VTX-N1-ALFA",
			}
			fs["/home/operator/notas.txt"] = {
				"type": "file",
				"root_only": false,
				"content": "Consejo: usa 'ls' para ver archivos y 'cat <archivo>' para leerlos.",
			}
		1:
			root_children.append("boveda")
			root_children.append("pista.txt")
			fs["/home/operator/pista.txt"] = {
				"type": "file",
				"root_only": false,
				"content": "Los archivos cuyo nombre inicia con punto (.) permanecen ocultos ante 'ls' normal.",
			}
			fs["/home/operator/boveda"] = {
				"type": "dir",
				"root_only": false,
				"children": ["leeme.txt", ".llave_oculta"],
			}
			fs["/home/operator/boveda/leeme.txt"] = {
				"type": "file",
				"root_only": false,
				"content": "Aquí no está la clave. Prueba listar con -a.",
			}
			fs["/home/operator/boveda/.llave_oculta"] = {
				"type": "file",
				"root_only": false,
				"content": "CREDENCIAL NODO 2: VTX-N2-SOMBRA",
			}
		2:
			root_children.append("sectores")
			fs["/home/operator/sectores"] = {
				"type": "dir",
				"root_only": false,
				"children": ["alfa", "beta", "gamma", "delta"],
			}
			fs["/home/operator/sectores/alfa"] = {"type": "dir", "root_only": false, "children": ["vacio.txt"]}
			fs["/home/operator/sectores/alfa/vacio.txt"] = {"type": "file", "root_only": false, "content": "Sin datos."}
			fs["/home/operator/sectores/beta"] = {"type": "dir", "root_only": false, "children": ["ruido.dat"]}
			fs["/home/operator/sectores/beta/ruido.dat"] = {"type": "file", "root_only": false, "content": "0x00FF"}
			fs["/home/operator/sectores/gamma"] = {"type": "dir", "root_only": false, "children": []}
			fs["/home/operator/sectores/delta"] = {"type": "dir", "root_only": false, "children": ["sub1", "sub2"]}
			fs["/home/operator/sectores/delta/sub1"] = {"type": "dir", "root_only": false, "children": []}
			fs["/home/operator/sectores/delta/sub2"] = {"type": "dir", "root_only": false, "children": ["credencial.dat"]}
			fs["/home/operator/sectores/delta/sub2/credencial.dat"] = {
				"type": "file",
				"root_only": false,
				"content": "LLAVE NODO 3: VTX-N3-RUTA",
			}
		3:
			root_children.append("servidor.log")
			var log_lines: Array[String] = []
			for i: int in range(1, 25):
				if i == 17:
					log_lines.append("[19:17:04] [AUTH] ACCESO_N4: VTX-N4-FILTRO")
				else:
					log_lines.append("[19:%02d:12] [HEARTBEAT] Paquete rutinario nodo_%d OK" % [i, i % 5])
			fs["/home/operator/servidor.log"] = {
				"type": "file",
				"root_only": false,
				"content": "\n".join(log_lines),
			}
		4:
			root_children.append("traza.log")
			root_children.append("paquete.b64")
			fs["/home/operator/traza.log"] = {
				"type": "file",
				"root_only": false,
				"content": "[TRACE] Inicio de captura\n[TRACE] PAYLOAD_B64: VlRYLU41LUtFUk5FTA== (guardado en paquete.b64)\n[TRACE] Fin de captura",
			}
			fs["/home/operator/paquete.b64"] = {
				"type": "file",
				"root_only": false,
				"content": "VlRYLU41LUtFUk5FTA==",
			}
	return fs
