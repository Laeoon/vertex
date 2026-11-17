class_name TerminalVFS extends RefCounted

## TerminalVFS
## Sistema de archivos virtual (VFS) táctico en memoria para la terminal de VERTEX.
## Soporta directorios, archivos del sistema, logs y permisos de root/sudo.

var current_path: String = "/home/operator"
var is_root: bool = false

var _fs: Dictionary = {
	"/": {
		"type": "dir",
		"root_only": false,
		"children": ["bin", "etc", "home", "secrets", "var"]
	},
	"/bin": {
		"type": "dir",
		"root_only": false,
		"children": ["sh", "help", "status", "netstat", "traceroute", "ping", "nmap", "scan"]
	},
	"/etc": {
		"type": "dir",
		"root_only": false,
		"children": ["motd", "hosts", "shadow"]
	},
	"/etc/motd": {
		"type": "file",
		"root_only": false,
		"content": "=== VERTEX TACTICAL OS v1.0.0 ===\nAcceso de consola seguro. Operador: operator\nKernel de Teoría de Grafos y Ciberdefensa en línea."
	},
	"/etc/hosts": {
		"type": "file",
		"root_only": false,
		"content": "127.0.0.1\tlocalhost vertex.net\n10.0.0.1\tgateway.root\n10.0.4.1\tdmz.firewall.internal\n192.168.1.100\tkain.daemon"
	},
	"/etc/shadow": {
		"type": "file",
		"root_only": true,
		"content": "root:$6$vtx$kain99:19740:0:99999:7:::\noperator:$6$vtx$cyber26:19740:0:99999:7:::"
	},
	"/home": {
		"type": "dir",
		"root_only": false,
		"children": ["operator"]
	},
	"/home/operator": {
		"type": "dir",
		"root_only": false,
		"children": ["readme.txt", "network_targets.txt"]
	},
	"/home/operator/readme.txt": {
		"type": "file",
		"root_only": false,
		"content": "GUÍA TÁCTICA DEL OPERADOR:\nUsa 'ls' para explorar, 'cd <dir>' para navegar y 'cat <file>' para leer.\nPuedes ejecutar 'ping <nodo>' y 'nmap <nodo>' para evaluar el grafo.\nUsa 'status', 'netstat' y 'traceroute' para telemetría de red.\nPara operaciones privilegiadas usa 'sudo <comando>'."
	},
	"/home/operator/network_targets.txt": {
		"type": "file",
		"root_only": false,
		"content": "NODOS DE INTERÉS DEL SECTOR:\n- Consulta los vecinos con 'status' o 'netstat'\n- Escanea vulnerabilidades con 'nmap <nodo>'\n- Diagnostica latencias con 'ping <nodo>'"
	},
	"/secrets": {
		"type": "dir",
		"root_only": true,
		"children": ["blueprint.txt", "kain_notes.txt"]
	},
	"/secrets/blueprint.txt": {
		"type": "file",
		"root_only": true,
		"content": "TOPOLOGÍA DEL KERNEL:\nSector 0: 12 nodos interconectados con corte mínimo de flujo y algoritmos de desvío."
	},
	"/secrets/kain_notes.txt": {
		"type": "file",
		"root_only": true,
		"content": "REGISTRO DE KAIN:\n'La red no puede segmentarse sin consecuencias. Cada arista eliminada redistribuye la presión de flujo.'"
	},
	"/var": {
		"type": "dir",
		"root_only": false,
		"children": ["log"]
	},
	"/var/log": {
		"type": "dir",
		"root_only": false,
		"children": ["ids.log", "auth.log"]
	},
	"/var/log/ids.log": {
		"type": "file",
		"root_only": false,
		"content": "[IDS_ALERT] Intrusión detectada en segmento perimetral.\n[IDS_ALERT] Paquete SYN anómalo registrado.\n[IDS_OK] Inspección EDR perimetral nominal."
	},
	"/var/log/auth.log": {
		"type": "file",
		"root_only": false,
		"content": "session opened for user operator by (uid=1000)\nauthentication failure for user root from /dev/tty1"
	}
}


func normalize_path(target: String) -> String:
	var path := target.strip_edges()
	if path == "~":
		return "/home/operator"
	if path.begins_with("~/"):
		path = "/home/operator/" + path.substr(2)

	var is_abs := path.begins_with("/")
	var raw_parts: PackedStringArray = path.split("/", false)
	var resolved_parts: Array[String] = []

	if not is_abs:
		for part in current_path.split("/", false):
			resolved_parts.append(part)

	for p in raw_parts:
		if p == "." or p.is_empty():
			continue
		elif p == "..":
			if resolved_parts.size() > 0:
				resolved_parts.pop_back()
		else:
			resolved_parts.append(p)

	if resolved_parts.is_empty():
		return "/"
	return "/" + "/".join(resolved_parts)


func cd(target_path: String) -> Dictionary:
	var dest := normalize_path(target_path)
	if not _fs.has(dest):
		return {"success": false, "error": "cd: no existe el directorio: '%s'" % target_path}

	var entry: Dictionary = _fs[dest]
	if entry.get("type") != "dir":
		return {"success": false, "error": "cd: no es un directorio: '%s'" % target_path}

	if entry.get("root_only", false) and not is_root:
		return {"success": false, "error": "cd: Permiso denegado. Se requiere 'sudo'."}

	current_path = dest
	return {"success": true, "path": current_path}


func ls(target_path: String = "") -> Dictionary:
	var dest := current_path if target_path.is_empty() else normalize_path(target_path)
	if not _fs.has(dest):
		return {"success": false, "error": "ls: no existe '%s'" % target_path}

	var entry: Dictionary = _fs[dest]
	if entry.get("type") == "file":
		return {"success": true, "items": [dest.get_file()]}

	if entry.get("root_only", false) and not is_root:
		return {"success": false, "error": "ls: Permiso denegado en '%s'. Se requiere 'sudo'." % dest}

	var children: Array = entry.get("children", [])
	var formatted: Array[String] = []
	for c in children:
		var full: String = dest + ("/" if dest != "/" else "") + c
		if _fs.has(full):
			var child_entry: Dictionary = _fs[full]
			if child_entry.get("type") == "dir":
				formatted.append(c + "/")
			else:
				formatted.append(c)
		else:
			formatted.append(c)

	return {"success": true, "items": formatted}


func cat(target_path: String) -> Dictionary:
	var dest := normalize_path(target_path)
	if not _fs.has(dest):
		return {"success": false, "error": "cat: no existe el archivo '%s'" % target_path}

	var entry: Dictionary = _fs[dest]
	if entry.get("type") == "dir":
		return {"success": false, "error": "cat: '%s' es un directorio" % target_path}

	if entry.get("root_only", false) and not is_root:
		return {"success": false, "error": "cat: Permiso denegado. Usa 'sudo cat %s'." % target_path}

	return {"success": true, "content": entry.get("content", "")}
