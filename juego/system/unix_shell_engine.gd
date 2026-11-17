class_name UnixShellEngine
extends RefCounted

## UnixShellEngine
## Motor de intérprete UNIX/POSIX virtual avanzado para la terminal de VERTEX.
## Soporta jerarquía VFS completa, comandos extendidos (ls, cd, pwd, cat, echo, grep, find, head, tail, wc, chmod, ps, kill, whoami, uname, ifconfig/ip, netstat, ping, nmap, traceroute, ssh, base64, sudo), pipes (|) y Academia de Terminal interactiva.

const TerminalVFSClass = preload("res://juego/ui/terminal_vfs.gd")

var vfs: TerminalVFS = null
var background_processes: Array[Dictionary] = [] # [{pid, name, status, user}]

func _init(existing_vfs: TerminalVFS = null) -> void:
	if existing_vfs != null:
		vfs = existing_vfs
	else:
		vfs = TerminalVFSClass.new()
	_init_extended_vfs()
	_init_default_processes()


func _init_extended_vfs() -> void:
	# Asegurar directorios y archivos adicionales requeridos por S4
	var extra_dirs := ["/etc/bgp", "/var/log/siem", "/srv/vault_shamir", "/proc/sector0"]
	for d in extra_dirs:
		if not vfs._fs.has(d):
			vfs._fs[d] = {"type": "dir", "root_only": false, "children": []}
	
	# Registrar hijos en directorios padre
	_add_to_parent("/", "etc")
	_add_to_parent("/etc", "bgp")
	_add_to_parent("/", "var")
	_add_to_parent("/var", "log")
	_add_to_parent("/var/log", "siem")
	_add_to_parent("/", "srv")
	_add_to_parent("/srv", "vault_shamir")
	_add_to_parent("/", "proc")
	_add_to_parent("/proc", "sector0")

	# Archivos específicos de S4
	vfs._fs["/etc/bgp/bgpd.conf"] = {
		"type": "file",
		"root_only": false,
		"content": "router bgp 65001\n bgp router-id 10.0.0.1\n neighbor 10.0.4.1 remote-as 65002\n neighbor 192.168.1.100 remote-as 65003\n network 10.0.0.0/16\n!"
	}
	_add_to_parent("/etc/bgp", "bgpd.conf")

	vfs._fs["/var/log/siem/auth.log"] = {
		"type": "file",
		"root_only": false,
		"content": "[2026-11-15 19:10:02] [SIEM] INFO: SSH login attempt from 10.0.4.1 [OK]\n[2026-11-15 19:12:44] [SIEM] WARN: Root privilege escalation test [WARN]\n[2026-11-15 19:15:10] [SIEM] ERROR: Authentication failure for user root from 192.168.1.100 [FAIL]\n[2026-11-15 19:18:22] [SIEM] INFO: Daemon heartbeat verified [OK]\n[2026-11-15 19:20:01] [SIEM] ERROR: Segment firewall breach attempt detected [FAIL]"
	}
	_add_to_parent("/var/log/siem", "auth.log")

	vfs._fs["/srv/vault_shamir/shard_manifest.b64"] = {
		"type": "file",
		"root_only": false,
		"content": "U2VjdG9yIDA6IFNoYXJkIG1hbmlmZXN0IGRlIGxhIGLDsjZkZW5hLiBDbG92ZXIgbmluZSBhdXRob3JpemVkIGZvciBrZXJuZWwgb3BlcmF0aW9uLg=="
	}
	_add_to_parent("/srv/vault_shamir", "shard_manifest.b64")

	vfs._fs["/proc/sector0/kain_trace.log"] = {
		"type": "file",
		"root_only": true,
		"content": "[KERNEL_TRACE] Kain daemon active on PID 4096.\n[GRAPH_FLOW] Minimum cut capacity: 14.8 Gbps.\n[DAEMON] Monitoring cluster integrity and vector topology."
	}
	_add_to_parent("/proc/sector0", "kain_trace.log")

	# Añadir comandos al /bin virtual si no están
	var bin_dir: Dictionary = vfs._fs.get("/bin", {"type": "dir", "children": []})
	var bin_children: Array = bin_dir.get("children", [])
	for cmd in ["sh", "ls", "cd", "pwd", "cat", "echo", "grep", "find", "head", "tail", "wc", "chmod", "ps", "kill", "whoami", "uname", "ifconfig", "ip", "netstat", "ping", "nmap", "traceroute", "ssh", "base64", "sudo", "clear", "help", "academy"]:
		if not cmd in bin_children:
			bin_children.append(cmd)
	bin_dir["children"] = bin_children


func _add_to_parent(parent_path: String, child_name: String) -> void:
	if vfs._fs.has(parent_path):
		var p: Dictionary = vfs._fs[parent_path]
		var children: Array = p.get("children", [])
		if not child_name in children:
			children.append(child_name)
			p["children"] = children


func _init_default_processes() -> void:
	background_processes = [
		{"pid": 1, "name": "systemd", "status": "Running", "user": "root"},
		{"pid": 42, "name": "vertex_core", "status": "Running", "user": "operator"},
		{"pid": 108, "name": "bgpd", "status": "Sleeping", "user": "root"},
		{"pid": 4096, "name": "kain_daemon", "status": "Active/Daemon", "user": "root"}
	]


func execute_command_line(full_line: String) -> String:
	var line := full_line.strip_edges()
	if line.is_empty():
		return ""

	# Soporte de pipes (|)
	if line.find("|") != -1:
		var parts := line.split("|", true)
		var current_output := ""
		for i in range(parts.size()):
			var sub_cmd := parts[i].strip_edges()
			if i == 0:
				var res := _execute_single(sub_cmd)
				if not res.get("success", true):
					return res.get("output", "Error en comando inicial: %s" % sub_cmd)
				current_output = res.get("output", "")
			else:
				var pipe_res := _execute_piped(sub_cmd, current_output)
				if not pipe_res.get("success", true):
					return pipe_res.get("output", "Error en pipe: %s" % sub_cmd)
				current_output = pipe_res.get("output", "")
		return current_output

	var single_res := _execute_single(line)
	return single_res.get("output", "")


func _parse_args(cmd_line: String) -> Array[String]:
	var parts: Array[String] = []
	var current := ""
	var in_quotes := false
	for i in range(cmd_line.length()):
		var c := cmd_line[i]
		if c == '"' or c == "'":
			in_quotes = not in_quotes
		elif c == " " and not in_quotes:
			if not current.is_empty():
				parts.append(current)
				current = ""
		else:
			current += c
	if not current.is_empty():
		parts.append(current)
	return parts


func _execute_single(cmd_line: String) -> Dictionary:
	var parts := _parse_args(cmd_line)
	if parts.is_empty():
		return {"success": true, "output": ""}

	var cmd: String = parts[0]
	var args: Array[String] = parts.slice(1)

	match cmd:
		"help":
			return {"success": true, "output": "Comandos UNIX/POSIX disponibles:\n  ls [-l] [-a] [ruta]  - Listar archivos\n  cd [ruta]           - Cambiar directorio\n  pwd                 - Mostrar ruta actual\n  cat [archivo]       - Mostrar contenido\n  echo [texto]        - Imprimir texto\n  grep [-i] [-n] <pat> [arch] - Filtrar texto\n  find [ruta] [-name <pat>]   - Buscar archivos\n  head / tail / wc    - Utilidades de texto\n  chmod <mod> <arch>  - Modificar permisos\n  ps [aux]            - Listar procesos\n  kill <pid>          - Terminar proceso\n  whoami / uname [-a] - Info del sistema\n  ifconfig / ip / netstat / ping / nmap / traceroute / ssh\n  base64 [-d] <txt/ar> - Codificar/decodificar base64\n  sudo <cmd>          - Ejecutar como root\n  academy             - Academia de Terminal Interactiva\n  clear / help"}
		"pwd":
			return {"success": true, "output": vfs.current_path}
		"whoami":
			return {"success": true, "output": "root" if vfs.is_root else "operator"}
		"uname":
			var extra := false
			for a in args:
				if a == "-a" or a == "a":
					extra = true
			if extra:
				return {"success": true, "output": "Linux vertex-tactical-kernel 6.8.0-vertex-generic #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux"}
			return {"success": true, "output": "Linux"}
		"clear":
			return {"success": true, "output": "__CLEAR__"}
		"echo":
			return {"success": true, "output": " ".join(args)}
		"cd":
			var target: String = str(args[0]) if args.size() > 0 else "/home/operator"
			var res := vfs.cd(target)
			if res.get("success", false):
				return {"success": true, "output": ""}
			return {"success": false, "output": res.get("error", "Error en cd")}
		"ls":
			var show_long := false
			var show_all := false
			var target_path := ""
			for a in args:
				if a.begins_with("-"):
					if a.find("l") != -1: show_long = true
					if a.find("a") != -1: show_all = true
				else:
					target_path = a
			var res := vfs.ls(target_path)
			if not res.get("success", false):
				return {"success": false, "output": res.get("error", "Error en ls")}
			var items: Array = res.get("items", [])
			if show_long:
				var lines: Array[String] = ["total %d" % items.size()]
				for it in items:
					var it_str: String = str(it)
					var is_dir: bool = it_str.ends_with("/")
					var clean_name: String = it_str.trim_suffix("/")
					var perm: String = "drwxr-xr-x" if is_dir else "-rw-r--r--"
					var owner: String = "root" if (clean_name in ["blueprint.txt", "kain_notes.txt", "kain_trace.log"]) else "operator"
					lines.append("%s 1 %s %s 4096 Nov 15 19:00 %s" % [perm, owner, owner, it_str])
				return {"success": true, "output": "\n".join(lines)}
			else:
				return {"success": true, "output": "  ".join(items)}
		"cat":
			if args.is_empty():
				return {"success": false, "output": "cat: falta operando de archivo"}
			var res := vfs.cat(args[0])
			if res.get("success", false):
				return {"success": true, "output": res.get("content", "")}
			return {"success": false, "output": res.get("error", "Error en cat")}
		"grep":
			return _handle_grep(args)
		"find":
			return _handle_find(args)
		"head":
			return _handle_head_tail(args, true)
		"tail":
			return _handle_head_tail(args, false)
		"wc":
			return _handle_wc(args)
		"chmod":
			if args.size() < 2:
				return {"success": false, "output": "chmod: modo o archivo faltante"}
			var target_file := vfs.normalize_path(args[1])
			if vfs._fs.has(target_file):
				return {"success": true, "output": "Modo de '%s' cambiado a %s exitosamente." % [args[1], args[0]]}
			return {"success": false, "output": "chmod: no existe el archivo '%s'" % args[1]}
		"ps":
			var lines: Array[String] = ["PID TTY          TIME CMD"]
			var show_aux := false
			for a in args:
				if a.find("aux") != -1 or a.find("a") != -1: show_aux = true
			for p in background_processes:
				var u: String = str(p.get("user", "operator"))
				var pid: String = str(p.get("pid", 1))
				var proc_name: String = str(p.get("name", "process"))
				if show_aux:
					lines.append("%s  %-8s 00:00:00 %s" % [u, pid, proc_name])
				else:
					lines.append("%5s tty1     00:00:00 %s" % [pid, proc_name])
			return {"success": true, "output": "\n".join(lines)}
		"kill":
			if args.is_empty():
				return {"success": false, "output": "kill: falta PID"}
			var pid_str: int = str(args[0]).to_int()
			var found_idx := -1
			for i in range(background_processes.size()):
				if int(background_processes[i].get("pid", 0)) == pid_str:
					found_idx = i
					break
			if found_idx != -1:
				background_processes.remove_at(found_idx)
				return {"success": true, "output": "[+] Proceso PID %d terminado exitosamente." % pid_str}
			return {"success": false, "output": "kill: (%d) - No such process" % pid_str}
		"base64":
			var decode := false
			var target := ""
			for a in args:
				if a == "-d" or a == "--decode":
					decode = true
				else:
					target = a
			if target.is_empty() and not decode:
				return {"success": false, "output": "base64: falta argumento"}
			if decode:
				var content_to_dec: String = target
				var resolved := vfs.normalize_path(target)
				if vfs._fs.has(resolved) and vfs._fs[resolved].get("type") == "file":
					content_to_dec = str(vfs._fs[resolved].get("content", ""))
				var b64 := Marshalls.base64_to_utf8(content_to_dec)
				return {"success": true, "output": b64 if not b64.is_empty() else "[Error decodificación base64]"}
			else:
				var b64_enc := Marshalls.utf8_to_base64(target)
				return {"success": true, "output": b64_enc}
		"sudo":
			if args.is_empty():
				return {"success": false, "output": "sudo: falta comando"}
			vfs.is_root = true
			var sub_res := _execute_single(" ".join(args))
			return sub_res
		"ping", "nmap", "traceroute", "netstat", "ifconfig", "ip":
			return _handle_network_commands(cmd, args)
		"academy":
			return {"success": true, "output": get_academy_banner()}
		_:
			return {"success": false, "output": "%s: comando no encontrado. Escribe 'help'." % cmd}


func _execute_piped(sub_cmd: String, stdin_text: String) -> Dictionary:
	var parts := _parse_args(sub_cmd)
	if parts.is_empty():
		return {"success": true, "output": stdin_text}
	var cmd: String = parts[0]
	var args: Array[String] = parts.slice(1)

	if cmd == "grep":
		var ignore_case := false
		var line_number := false
		var pattern := ""
		for a in args:
			if a == "-i": ignore_case = true
			elif a == "-n": line_number = true
			elif pattern.is_empty(): pattern = a
		
		if pattern.is_empty():
			return {"success": false, "output": "grep: patrón faltante"}
		
		var lines := stdin_text.split("\n")
		var matched_lines: Array[String] = []
		for idx in range(lines.size()):
			var l := lines[idx]
			var match_ok := false
			if ignore_case:
				match_ok = l.to_lower().find(pattern.to_lower()) != -1
			else:
				match_ok = l.find(pattern) != -1
			if match_ok:
				if line_number:
					matched_lines.append("%d:%s" % [idx + 1, l])
				else:
					matched_lines.append(l)
		return {"success": true, "output": "\n".join(matched_lines)}
	elif cmd == "wc":
		var lines := stdin_text.split("\n")
		var word_count := 0
		var char_count := stdin_text.length()
		for l in lines:
			word_count += l.split(" ", false).size()
		return {"success": true, "output": "%d %d %d" % [lines.size(), word_count, char_count]}
	elif cmd == "head":
		var lines := stdin_text.split("\n")
		var count := mini(10, lines.size())
		return {"success": true, "output": "\n".join(lines.slice(0, count))}
	elif cmd == "tail":
		var lines := stdin_text.split("\n")
		var count := mini(10, lines.size())
		var start := maxi(0, lines.size() - count)
		return {"success": true, "output": "\n".join(lines.slice(start, lines.size()))}
	else:
		return _execute_single(sub_cmd + " " + stdin_text)


func _handle_grep(args: Array[String]) -> Dictionary:
	var ignore_case := false
	var line_number := false
	var pattern := ""
	var file_path := ""

	for a in args:
		if a == "-i": ignore_case = true
		elif a == "-n": line_number = true
		elif pattern.is_empty(): pattern = a
		elif file_path.is_empty(): file_path = a

	if pattern.is_empty():
		return {"success": false, "output": "grep: falta patrón"}

	var content := ""
	if file_path.is_empty():
		return {"success": false, "output": "grep: falta archivo de entrada"}
	else:
		var resolved := vfs.normalize_path(file_path)
		var cat_res := vfs.cat(resolved)
		if not cat_res.get("success", false):
			return {"success": false, "output": cat_res.get("error", "grep: error leyendo archivo")}
		content = cat_res.get("content", "")

	var lines := content.split("\n")
	var matched: Array[String] = []
	for idx in range(lines.size()):
		var l := lines[idx]
		var ok := l.to_lower().find(pattern.to_lower()) != -1 if ignore_case else l.find(pattern) != -1
		if ok:
			if line_number:
				matched.append("%d:%s" % [idx + 1, l])
			else:
				matched.append(l)
	return {"success": true, "output": "\n".join(matched)}


func _handle_find(args: Array[String]) -> Dictionary:
	var search_dir := vfs.current_path
	var name_pat := ""
	if args.size() > 0:
		if not args[0].begins_with("-"):
			search_dir = vfs.normalize_path(args[0])
	for i in range(args.size()):
		if args[i] == "-name" and i + 1 < args.size():
			name_pat = args[i + 1]

	var results: Array[String] = []
	for path in vfs._fs.keys():
		if path.begins_with(search_dir):
			if name_pat.is_empty() or path.get_file().match(name_pat) or path.get_file().find(name_pat) != -1:
				results.append(path)
	return {"success": true, "output": "\n".join(results)}


func _handle_head_tail(args: Array[String], is_head: bool) -> Dictionary:
	if args.is_empty():
		return {"success": false, "output": "falta archivo"}
	var file_path := args[0]
	var cat_res := vfs.cat(file_path)
	if not cat_res.get("success", false):
		return {"success": false, "output": str(cat_res.get("error", "error leyendo archivo"))}
	var content_str: String = str(cat_res.get("content", ""))
	var lines: PackedStringArray = content_str.split("\n")
	var count := mini(10, lines.size())
	if is_head:
		return {"success": true, "output": "\n".join(lines.slice(0, count))}
	else:
		var start := maxi(0, lines.size() - count)
		return {"success": true, "output": "\n".join(lines.slice(start, lines.size()))}


func _handle_wc(args: Array[String]) -> Dictionary:
	if args.is_empty():
		return {"success": false, "output": "wc: falta archivo"}
	var cat_res := vfs.cat(args[0])
	if not cat_res.get("success", false):
		return {"success": false, "output": str(cat_res.get("error", "wc: error"))}
	var content: String = str(cat_res.get("content", ""))
	var lines: PackedStringArray = content.split("\n")
	var words := 0
	for l in lines:
		words += l.split(" ", false).size()
	return {"success": true, "output": "%d %d %d %s" % [lines.size(), words, content.length(), args[0]]}


func _handle_network_commands(cmd: String, args: Array[String]) -> Dictionary:
	match cmd:
		"ping":
			var target: String = args[0] if args.size() > 0 else "gateway.root"
			return {"success": true, "output": "PING %s (10.0.0.1) 56(84) bytes of data.\n64 bytes from %s: icmp_seq=1 ttl=64 time=0.412 ms\n64 bytes from %s: icmp_seq=2 ttl=64 time=0.389 ms\n--- %s ping statistics ---\n2 packets transmitted, 2 received, 0%% packet loss, time 1002ms" % [target, target, target, target]}
		"nmap":
			var target: String = args[0] if args.size() > 0 else "vertex.net"
			return {"success": true, "output": "Starting Nmap 7.94 ( https://nmap.org )\nNmap scan report for %s (192.168.1.100)\nHost is up (0.0012s latency).\nPORT     STATE SERVICE\n22/tcp   open  ssh\n80/tcp   open  http\n443/tcp  open  https\n65001/tcp open bgp\nNmap done: 1 IP address (1 host up) scanned in 0.23 seconds." % target}
		"netstat":
			return {"success": true, "output": "Active Internet connections (w/o servers)\nProto Recv-Q Send-Q Local Address           Foreign Address         State\ntcp        0      0 10.0.0.1:22             10.0.4.1:51220          ESTABLISHED\ntcp        0      0 10.0.0.1:65001          192.168.1.100:65001     ESTABLISHED"}
		"traceroute":
			return {"success": true, "output": "traceroute to 10.0.4.1, 30 hops max\n 1 gateway.root (10.0.0.1)  0.412 ms  0.389 ms\n 2 dmz.firewall.internal (10.0.4.1)  1.102 ms  1.089 ms"}
		"ifconfig", "ip":
			return {"success": true, "output": "eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST> mtu 1500\n        inet 10.0.0.1  netmask 255.255.255.0  broadcast 10.0.0.255\n        inet6 fe80::42:ff:fe00:1  prefixlen 64  scopeid 0x20<link>\n        RX packets 1420  bytes 128450 (125.4 KiB)\n        TX packets 1310  bytes 115200 (112.5 KiB)"}
		_:
			return {"success": true, "output": "Red operacional nominal."}


func get_academy_banner() -> String:
	return "=== ACADEMIA DE TERMINAL UNIX VERTEX ===\n" + \
		"Módulos disponibles:\n" + \
		"  1. Navegación: 'ls', 'cd', 'pwd', 'cat'\n" + \
		"  2. Filtrado Forense: 'grep', pipes '|'\n" + \
		"  3. Procesos y Permisos: 'ps', 'kill', 'chmod'\n" + \
		"  4. Esteganografía y Redes: 'base64 -d', 'nmap', 'ping'\n" + \
		"Escribe 'academy check <modulo>' para verificar tu progreso."


func get_academy_modules() -> Array:
	return [
		{"id": 1, "title": "Módulo 1: Navegación ls/cd/pwd/cat", "desc": "Explora el directorio /home/operator y lee readme.txt"},
		{"id": 2, "title": "Módulo 2: Filtrado Forense con grep y pipes |", "desc": "Filtra fallos en auth.log usando pipes: cat /var/log/siem/auth.log | grep FAIL"},
		{"id": 3, "title": "Módulo 3: Procesos ps/kill y Permisos chmod", "desc": "Lista procesos con ps y modifica permisos con chmod"},
		{"id": 4, "title": "Módulo 4: Esteganografía base64 y Auditoría de Red", "desc": "Decodifica el manifiesto de Shamir con base64 -d /srv/vault_shamir/shard_manifest.b64"}
	]


func check_academy_step(module_idx: int, command_str: String, _output_str: String) -> bool:
	match module_idx:
		1:
			return command_str.begins_with("ls") or command_str.begins_with("cd") or command_str.begins_with("cat")
		2:
			return command_str.find("grep") != -1 or command_str.find("|") != -1
		3:
			return command_str.find("ps") != -1 or command_str.find("chmod") != -1 or command_str.find("kill") != -1
		4:
			return command_str.find("base64") != -1 or command_str.find("nmap") != -1 or command_str.find("ping") != -1
		_:
			return false
