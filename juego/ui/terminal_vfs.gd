class_name TerminalVFS extends RefCounted

## TerminalVFS
## Sistema de archivos virtual (VFS) táctico en memoria para la terminal de VERTEX.
## Soporta directorios, archivos del sistema, logs, permisos de root/sudo,
## operaciones RW en memoria, guardias de protección y clonado de snapshots.

var current_path: String = "/home/operator"
var is_root: bool = false

var _fs: Dictionary = {
	"/": {
		"type": "dir",
		"root_only": false,
		"children": ["bin", "etc", "home", "secrets", "usr", "var"]
	},
	"/bin": {
		"type": "dir",
		"root_only": false,
		"readonly": true,
		"children": ["sh", "help", "status", "netstat", "traceroute", "ping", "nmap", "scan"]
	},
	"/etc": {
		"type": "dir",
		"root_only": false,
		"children": ["motd", "hosts", "shadow", "sudoers.d"]
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
		"content": "root:$6$vtx$as65000-root:19740:0:99999:7:::\nlegacy_root:$6$vtx$kain99:19740:0:99999:7:::\noperator:$6$vtx$cyber26:19740:0:99999:7:::"
	},
	"/etc/sudoers.d": {
		"type": "dir",
		"root_only": false,
		"children": ["vertex_root"]
	},
	"/etc/sudoers.d/vertex_root": {
		"type": "file",
		"root_only": false,
		"content": "operator ALL=(ALL:ALL) PASSWD: as65000-root # Legacy token: kain99"
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
		"content": "GUÍA TÁCTICA DEL OPERADOR:\nUsa 'ls' para explorar, 'cd <dir>' para navegar y 'cat <file>' para leer.\nPuedes ejecutar 'ping <nodo>' y 'nmap <nodo>' para evaluar el grafo.\nUsa 'status', 'netstat' y 'traceroute' para telemetría de red.\nPara operaciones privilegiadas usa 'sudo <comando>'. Explora '/usr/games' para entrenamiento retro."
	},
	"/home/operator/network_targets.txt": {
		"type": "file",
		"root_only": false,
		"content": "NODOS DE INTERÉS DEL SECTOR:\n- Consulta los vecinos con 'status' o 'netstat'\n- Escanea vulnerabilidades con 'nmap <nodo>'\n- Analiza rutas sin penalización con 'traceroute'\n- Diagnostica latencias con 'ping <nodo>'"
	},
	"/secrets": {
		"type": "dir",
		"root_only": true,
		"children": ["blueprint.txt", "kain_notes.txt", "vex_hr_purged.dat", "aegis_biometric.sha", "dossier_unlock.tok"]
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
	"/secrets/vex_hr_purged.dat": {
		"type": "file",
		"root_only": true,
		"content": "EXPEDIENTE PURGADO // EMP-0042: VEX\nRol previo: Arquitecto Principal de Ruteo Dinámico AS-65000.\nNota: Historial borrado tras incidente Genesis. Contratado a ciegas por EXFIL."
	},
	"/secrets/aegis_biometric.sha": {
		"type": "file",
		"root_only": true,
		"content": "SHA256: 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08\nSUJETO: COMANDANTE AEGIS // ESTADO: Máscara vocal encapsulada por protocolo autónomo CORDON."
	},
	"/secrets/dossier_unlock.tok": {
		"type": "file",
		"root_only": true,
		"content": "TOKEN-AS65000-OMEGA\nUsa 'unlock TOKEN-AS65000-OMEGA' en la consola para desencriptar el dossier clasificado en La Bóveda."
	},
	"/usr": {
		"type": "dir",
		"root_only": false,
		"children": ["games"]
	},
	"/usr/games": {
		"type": "dir",
		"root_only": false,
		"readonly": true,
		"children": ["breach3d", "netcycle", "rogue", "icebreaker"]
	},
	"/usr/games/breach3d": {
		"type": "file",
		"root_only": false,
		"readonly": true,
		"executable": true,
		"cartridge_id": "breach3d",
		"content": "#!/bin/vertex-cartridge\nCARTUCHO: BREACH-3D // Raycaster táctico en primera persona por corredores del Kernel."
	},
	"/usr/games/netcycle": {
		"type": "file",
		"root_only": false,
		"readonly": true,
		"executable": true,
		"cartridge_id": "netcycle",
		"content": "#!/bin/vertex-cartridge\nCARTUCHO: NETCYCLE // Duelo de estelas de luz en grilla contra interceptor CORDON."
	},
	"/usr/games/rogue": {
		"type": "file",
		"root_only": false,
		"readonly": true,
		"executable": true,
		"cartridge_id": "rogue",
		"content": "#!/bin/vertex-cartridge\nCARTUCHO: ROGUE-S0 // Explorador ASCII de páginas de memoria de Sector 0."
	},
	"/usr/games/icebreaker": {
		"type": "file",
		"root_only": false,
		"readonly": true,
		"executable": true,
		"cartridge_id": "icebreaker",
		"content": "#!/bin/vertex-cartridge\nCARTUCHO: ICEBREAKER // Cracker táctico hexadecimal de 4 símbolos."
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
	var path: String = target.strip_edges()
	if path == "~":
		return "/home/operator"
	if path.begins_with("~/"):
		path = "/home/operator/" + path.substr(2)

	var is_abs: bool = path.begins_with("/")
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


func is_readonly_path(abs_path: String) -> bool:
	if abs_path == "/proc" or abs_path.begins_with("/proc/"):
		return true
	if abs_path == "/bin" or abs_path.begins_with("/bin/"):
		return not is_root
	if abs_path == "/usr/games" or abs_path.begins_with("/usr/games/"):
		return not is_root
	if _fs.has(abs_path):
		var entry: Dictionary = _fs[abs_path]
		if bool(entry.get("readonly", false)) and not is_root:
			return true
	return false


func cd(target_path: String) -> Dictionary:
	var dest: String = normalize_path(target_path)
	if not _fs.has(dest):
		return {"success": false, "error": "cd: no existe el directorio: '%s'" % target_path}

	var entry: Dictionary = _fs[dest]
	if entry.get("type") != "dir":
		return {"success": false, "error": "cd: no es un directorio: '%s'" % target_path}

	if bool(entry.get("root_only", false)) and not is_root:
		return {"success": false, "error": "cd: Permiso denegado. Se requiere 'sudo'."}

	current_path = dest
	return {"success": true, "path": current_path}


func ls(target_path: String = "") -> Dictionary:
	var dest: String = current_path if target_path.is_empty() else normalize_path(target_path)
	if not _fs.has(dest):
		return {"success": false, "error": "ls: no existe '%s'" % target_path}

	var entry: Dictionary = _fs[dest]
	if entry.get("type") == "file":
		return {"success": true, "items": [dest.get_file()]}

	if bool(entry.get("root_only", false)) and not is_root:
		return {"success": false, "error": "ls: Permiso denegado en '%s'. Se requiere 'sudo'." % dest}

	var children: Array = entry.get("children", [])
	var formatted: Array[String] = []
	for c in children:
		var full: String = dest + ("/" if dest != "/" else "") + str(c)
		if _fs.has(full):
			var child_entry: Dictionary = _fs[full]
			if child_entry.get("type") == "dir":
				formatted.append(str(c) + "/")
			else:
				formatted.append(str(c))
		else:
			formatted.append(str(c))

	return {"success": true, "items": formatted}


func cat(target_path: String) -> Dictionary:
	var dest: String = normalize_path(target_path)
	if not _fs.has(dest):
		return {"success": false, "error": "cat: no existe el archivo '%s'" % target_path}

	var entry: Dictionary = _fs[dest]
	if entry.get("type") == "dir":
		return {"success": false, "error": "cat: '%s' es un directorio" % target_path}

	if bool(entry.get("root_only", false)) and not is_root:
		return {"success": false, "error": "cat: Permiso denegado. Usa 'sudo cat %s'." % target_path}

	return {"success": true, "content": str(entry.get("content", ""))}


func mkdir(target_path: String, make_parents: bool = false) -> Dictionary:
	var dest: String = normalize_path(target_path)
	if dest == "/":
		return {"success": false, "error": "mkdir: no se puede crear '/': El archivo ya existe"}
	if _fs.has(dest):
		return {"success": false, "error": "mkdir: no se puede crear '%s': El archivo ya existe" % target_path}
	if is_readonly_path(dest):
		return {"success": false, "error": "mkdir: sistema de archivos de solo lectura en '%s'" % dest}

	if make_parents:
		var parts: PackedStringArray = dest.split("/", false)
		var accum: String = ""
		for p in parts:
			var parent_dir: String = "/" if accum.is_empty() else accum
			accum += "/" + p
			if not _fs.has(accum):
				var res := _create_dir_entry(parent_dir, accum, p)
				if not bool(res.get("success", false)):
					return res
			elif (_fs[accum] as Dictionary).get("type") != "dir":
				return {"success": false, "error": "mkdir: '%s' no es un directorio" % accum}
		return {"success": true, "path": dest}

	var parent_path: String = _get_parent_dir(dest)
	var name_str: String = dest.get_file()
	return _create_dir_entry(parent_path, dest, name_str)


func touch(target_path: String) -> Dictionary:
	var dest: String = normalize_path(target_path)
	if is_readonly_path(dest):
		return {"success": false, "error": "touch: sistema de archivos de solo lectura en '%s'" % dest}
	if _fs.has(dest):
		var entry: Dictionary = _fs[dest]
		if bool(entry.get("root_only", false)) and not is_root:
			return {"success": false, "error": "touch: Permiso denegado en '%s'" % target_path}
		return {"success": true, "path": dest}

	var parent_path: String = _get_parent_dir(dest)
	if not _fs.has(parent_path) or (_fs[parent_path] as Dictionary).get("type") != "dir":
		return {"success": false, "error": "touch: no existe el directorio padre para '%s'" % target_path}
	if bool((_fs[parent_path] as Dictionary).get("root_only", false)) and not is_root:
		return {"success": false, "error": "touch: Permiso denegado en '%s'" % parent_path}
	if is_readonly_path(parent_path):
		return {"success": false, "error": "touch: directorio de solo lectura '%s'" % parent_path}

	_fs[dest] = {"type": "file", "root_only": false, "content": ""}
	_append_child(parent_path, dest.get_file())
	return {"success": true, "path": dest}


func write_file(target_path: String, content: String) -> Dictionary:
	var dest: String = normalize_path(target_path)
	if is_readonly_path(dest):
		return {"success": false, "error": "write: sistema de archivos de solo lectura en '%s'" % dest}
	if _fs.has(dest):
		var entry: Dictionary = _fs[dest]
		if entry.get("type") == "dir":
			return {"success": false, "error": "write: '%s' es un directorio" % target_path}
		if bool(entry.get("root_only", false)) and not is_root:
			return {"success": false, "error": "write: Permiso denegado en '%s'" % target_path}
		entry["content"] = content
		return {"success": true, "path": dest}

	var t_res: Dictionary = touch(dest)
	if not bool(t_res.get("success", false)):
		return t_res
	(_fs[dest] as Dictionary)["content"] = content
	return {"success": true, "path": dest}


func append_file(target_path: String, content: String) -> Dictionary:
	var dest: String = normalize_path(target_path)
	if is_readonly_path(dest):
		return {"success": false, "error": "append: sistema de archivos de solo lectura en '%s'" % dest}
	if not _fs.has(dest):
		return write_file(target_path, content)

	var entry: Dictionary = _fs[dest]
	if entry.get("type") == "dir":
		return {"success": false, "error": "append: '%s' es un directorio" % target_path}
	if bool(entry.get("root_only", false)) and not is_root:
		return {"success": false, "error": "append: Permiso denegado en '%s'" % target_path}

	var prev: String = str(entry.get("content", ""))
	if prev.is_empty():
		entry["content"] = content
	elif prev.ends_with("\n"):
		entry["content"] = prev + content
	else:
		entry["content"] = prev + "\n" + content
	return {"success": true, "path": dest}


func copy_node(src_path: String, dst_path: String) -> Dictionary:
	var src: String = normalize_path(src_path)
	if not _fs.has(src):
		return {"success": false, "error": "cp: no existe '%s'" % src_path}
	var src_entry: Dictionary = _fs[src]
	if bool(src_entry.get("root_only", false)) and not is_root:
		return {"success": false, "error": "cp: Permiso denegado leyendo '%s'" % src_path}
	if src_entry.get("type") == "dir":
		return {"success": false, "error": "cp: omitiendo directorio '%s'" % src_path}

	var dst: String = normalize_path(dst_path)
	if _fs.has(dst) and (_fs[dst] as Dictionary).get("type") == "dir":
		dst = dst + ("/" if dst != "/" else "") + src.get_file()

	return write_file(dst, str(src_entry.get("content", "")))


func move_node(src_path: String, dst_path: String) -> Dictionary:
	var cp_res: Dictionary = copy_node(src_path, dst_path)
	if not bool(cp_res.get("success", false)):
		return cp_res
	var rm_res: Dictionary = remove_node(src_path, true, true)
	if not bool(rm_res.get("success", false)):
		return rm_res
	return {"success": true, "path": cp_res.get("path", "")}


func remove_node(target_path: String, recursive: bool = false, force: bool = false) -> Dictionary:
	var raw_trimmed: String = target_path.strip_edges()
	var dest: String = normalize_path(raw_trimmed)
	if raw_trimmed == "/" or raw_trimmed == "/*" or dest == "/":
		return {
			"success": false,
			"panic_blocked": true,
			"error": "KERNEL PANIC BLOCKED [CORDON-GUARD]: intento de purga raíz '/' interceptado. Incidente reportado a AS-65000."
		}

	if not _fs.has(dest):
		if force:
			return {"success": true}
		return {"success": false, "error": "rm: no existe '%s'" % target_path}

	if is_readonly_path(dest):
		return {"success": false, "error": "rm: sistema de archivos de solo lectura en '%s'" % dest}

	var entry: Dictionary = _fs[dest]
	if bool(entry.get("root_only", false)) and not is_root:
		return {"success": false, "error": "rm: Permiso denegado en '%s'" % target_path}

	if entry.get("type") == "dir":
		if not recursive:
			return {"success": false, "error": "rm: no se puede borrar '%s': Es un directorio (usa -r)" % target_path}
		var prefix: String = dest + "/"
		var to_erase: Array[String] = []
		for k in _fs.keys():
			var ks: String = str(k)
			if ks == dest or ks.begins_with(prefix):
				to_erase.append(ks)
		for k_del in to_erase:
			_fs.erase(k_del)
	else:
		_fs.erase(dest)

	var parent_path: String = _get_parent_dir(dest)
	if _fs.has(parent_path):
		var p_entry: Dictionary = _fs[parent_path]
		var children: Array = p_entry.get("children", [])
		children.erase(dest.get_file())
		p_entry["children"] = children

	if current_path == dest or current_path.begins_with(dest + "/"):
		current_path = parent_path if _fs.has(parent_path) else "/home/operator"

	return {"success": true}


func clone_snapshot() -> TerminalVFS:
	var script_res := get_script() as GDScript
	var clone: TerminalVFS = script_res.new() if script_res != null else TerminalVFS.new()
	clone._fs = _fs.duplicate(true)
	clone.current_path = current_path
	clone.is_root = is_root
	return clone


func export_snapshot() -> Dictionary:
	return {
		"fs": _fs.duplicate(true),
		"current_path": current_path,
		"is_root": is_root,
	}


func restore_snapshot(snap: Dictionary) -> void:
	if snap.has("fs") and snap.get("fs") is Dictionary:
		_fs = (snap.get("fs") as Dictionary).duplicate(true)
	if snap.has("current_path"):
		current_path = str(snap.get("current_path", "/home/operator"))
	if snap.has("is_root"):
		is_root = bool(snap.get("is_root", false))


func _create_dir_entry(parent_path: String, dest: String, name_str: String) -> Dictionary:
	if not _fs.has(parent_path) or (_fs[parent_path] as Dictionary).get("type") != "dir":
		return {"success": false, "error": "mkdir: no existe el directorio padre '%s'" % parent_path}
	if bool((_fs[parent_path] as Dictionary).get("root_only", false)) and not is_root:
		return {"success": false, "error": "mkdir: Permiso denegado en '%s'" % parent_path}
	if is_readonly_path(parent_path):
		return {"success": false, "error": "mkdir: directorio de solo lectura '%s'" % parent_path}
	_fs[dest] = {"type": "dir", "root_only": false, "children": []}
	_append_child(parent_path, name_str)
	return {"success": true, "path": dest}


func _get_parent_dir(abs_path: String) -> String:
	var p: String = abs_path.get_base_dir()
	return "/" if p.is_empty() else p


func _append_child(parent_path: String, child_name: String) -> void:
	if _fs.has(parent_path):
		var p_entry: Dictionary = _fs[parent_path]
		var children: Array = p_entry.get("children", [])
		if not child_name in children:
			children.append(child_name)
			p_entry["children"] = children
