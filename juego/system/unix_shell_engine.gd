class_name UnixShellEngine
extends RefCounted

## UnixShellEngine
## Motor de intérprete UNIX/POSIX virtual compartido para la terminal de VERTEX.
## Soporta ShellResult tipado, pipes (|), redirecciones (> / >>), operaciones VFS RW,
## autocompletado [TAB], telemetría táctica sobre el grafo vivo (sin penalizar
## estrellas) y cartuchos retro interactivos en /usr/games/.

const TerminalVFSClass = preload("res://juego/ui/terminal_vfs.gd")
const DefensivePathfinderClass = preload("res://core/agents/defensive_pathfinder.gd")
const VaultStoreClass = preload("res://juego/system/vault_store.gd")
const VaultModulesClass = preload("res://juego/ui/vault_modules.gd")
const BadgeRegistryClass = preload("res://juego/system/badge_registry.gd")

const ALL_COMMANDS: Array[String] = [
	"academy", "badges", "base64", "breach3d", "cat", "cd", "chmod", "clear",
	"cp", "decrypt", "echo", "find", "games", "grep", "head", "help", "history",
	"icebreaker", "ifconfig", "ip", "kill", "ls", "mkdir", "mv", "netcycle",
	"netstat", "nmap", "ping", "play", "ps", "pwd", "rm", "rogue", "scan",
	"ssh", "status", "su", "sudo", "tail", "touch", "traceroute", "uname",
	"unlock", "wc", "whoami"
]

const PROTOCOL_PORT_MAP: Dictionary = {
	"SSH": "22/tcp   open  ssh",
	"DNS": "53/udp   open  dns",
	"HTTP": "80/tcp   open  http",
	"BGP": "179/tcp  open  bgp",
	"LDAP": "389/tcp  open  ldap",
	"HTTPS": "443/tcp  open  https",
	"QUIC": "443/udp  open  quic",
	"VPN": "1194/udp open  openvpn",
	"SQL": "3306/tcp open  mysql",
	"INTERNAL": "8443/tcp open  vertex-mesh",
	"TCP": "8080/tcp open  tcp-relay",
	"TLS": "8443/tcp open  tls-tunnel",
}


class ShellResult extends RefCounted:
	var stdout: String = ""
	var stderr: String = ""
	var exit_code: int = 0
	var cwd: String = "/home/operator"
	var side_effects: Dictionary = {}

	func combined_output() -> String:
		if stderr.is_empty():
			return stdout
		if stdout.is_empty():
			return stderr
		return stdout + "\n" + stderr


var vfs: TerminalVFS = null
var background_processes: Array[Dictionary] = []
var command_history: Array[String] = []
var context_name: StringName = &"shell"
var operator_user: String = "operator"
var host_name: String = "vertex-os"
var terminal_title: String = "VERTEX OS // TACTICAL SHELL"
var active_cartridge: String = ""
var cartridge_state: Dictionary = {}
var _game_context: Object = null


func _init(existing_vfs: TerminalVFS = null) -> void:
	if existing_vfs != null:
		vfs = existing_vfs
	else:
		vfs = TerminalVFSClass.new()
	_init_extended_vfs()
	_init_default_processes()


static func sanitize_username(raw_name: String, fallback: String = "operator") -> String:
	var clean: String = raw_name.strip_edges().to_lower().replace(" ", "_")
	var out: String = ""
	for i in range(clean.length()):
		var c: String = clean[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_" or c == "-":
			out += c
	return out if not out.is_empty() else fallback


func set_identity(user_str: String, host_str: String = "vertex-os", title_str: String = "") -> void:
	operator_user = sanitize_username(user_str, "operator")
	host_name = host_str if not host_str.is_empty() else "vertex-os"
	if not title_str.is_empty():
		terminal_title = title_str


func get_active_user() -> String:
	return "root" if (vfs != null and vfs.is_root) else operator_user


func get_prompt_string() -> String:
	var cwd: String = vfs.current_path if vfs != null else "/home/operator"
	var sym: String = "# " if (vfs != null and vfs.is_root) else "$ "
	return "%s@%s:%s%s" % [get_active_user(), host_name, cwd, sym]


func set_game_context(game_node: Object) -> void:
	_game_context = game_node
	if game_node == null:
		return
	var lvl_key: String = str(game_node.get("level_key")).to_lower() if game_node.get("level_key") != null else ""
	var ml: MainLoop = Engine.get_main_loop()
	var world_id: String = ""
	if ml is SceneTree:
		var sp: Node = (ml as SceneTree).root.get_node_or_null("SceneParams")
		if sp != null:
			if lvl_key.is_empty() and sp.get("level_key") != null:
				lvl_key = str(sp.get("level_key")).to_lower()
			if sp.get("world_id") != null:
				world_id = str(sp.get("world_id")).to_lower()
	if lvl_key.begins_with("secret") or lvl_key.begins_with("sector_0") or world_id == "secret":
		set_identity("kain", "genesis-s0", "AS-65000 // KAIN KERNEL TTY0")
	elif bool(game_node.get("defender_mode")) or world_id == "cybersecurity" or lvl_key.begins_with("cyber") or lvl_key.begins_with("defense"):
		set_identity("aegis", "cordon-soc", "CORDON-SOC // AEGIS DEFENSE SHELL")
	elif bool(game_node.get("hacker_mode")) or world_id == "hacker" or lvl_key.begins_with("hacker"):
		set_identity("n0x", "fuzz-rig", "FUZZ-RIG // N0X EXPLOIT SHELL")
	elif world_id == "free_ops" or lvl_key.begins_with("free_ops"):
		set_identity("zero", "sandbox-net", "VERTEX-SIM // ZERO TACTICAL SHELL")
	else:
		set_identity("vex", "exfil-deck", "EXFIL-DECK // VEX INCURSION SHELL")


func _init_extended_vfs() -> void:
	var extra_dirs: Array[String] = ["/etc/bgp", "/var/log/siem", "/srv/vault_shamir", "/proc/sector0"]
	for d in extra_dirs:
		if not vfs._fs.has(d):
			vfs._fs[d] = {"type": "dir", "root_only": false, "children": []}
	if vfs._fs.has("/proc"):
		(vfs._fs["/proc"] as Dictionary)["readonly"] = true

	_add_to_parent("/", "etc")
	_add_to_parent("/etc", "bgp")
	_add_to_parent("/", "var")
	_add_to_parent("/var", "log")
	_add_to_parent("/var/log", "siem")
	_add_to_parent("/", "srv")
	_add_to_parent("/srv", "vault_shamir")
	_add_to_parent("/", "proc")
	_add_to_parent("/proc", "sector0")

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
		"readonly": true,
		"content": "[KERNEL_TRACE] Kain daemon active on PID 4096.\n[GRAPH_FLOW] Minimum cut capacity: 14.8 Gbps.\n[DAEMON] Monitoring cluster integrity and vector topology."
	}
	_add_to_parent("/proc/sector0", "kain_trace.log")

	var bin_dir: Dictionary = vfs._fs.get("/bin", {"type": "dir", "children": []})
	var bin_children: Array = bin_dir.get("children", [])
	for cmd in ALL_COMMANDS:
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
	return execute(full_line).combined_output()


func execute(full_line: String) -> ShellResult:
	var result := ShellResult.new()
	result.cwd = vfs.current_path

	var line: String = full_line.strip_edges()
	if line.is_empty():
		return result

	command_history.append(line)

	if not active_cartridge.is_empty():
		var cart_res: Dictionary = _step_cartridge(line)
		result.stdout = str(cart_res.get("output", ""))
		result.exit_code = 0 if bool(cart_res.get("success", true)) else 1
		result.side_effects = {"cartridge": active_cartridge}
		result.cwd = vfs.current_path
		_emit_cli_event(active_cartridge, result.exit_code)
		return result

	if line.find(" && ") != -1:
		var segments: PackedStringArray = line.split(" && ", false)
		var out_parts: Array[String] = []
		var last_res: ShellResult = result
		for seg_raw: String in segments:
			var seg: String = seg_raw.strip_edges()
			if seg.is_empty():
				continue
			last_res = _execute_line_unit(seg)
			if not last_res.stdout.is_empty():
				out_parts.append(last_res.stdout)
			if last_res.exit_code != 0:
				last_res.stdout = "\n".join(out_parts)
				return last_res
		last_res.stdout = "\n".join(out_parts)
		return last_res

	return _execute_line_unit(line)


func _execute_line_unit(line: String) -> ShellResult:
	var result := ShellResult.new()
	result.cwd = vfs.current_path

	var redir_split: Dictionary = _split_redirection(line)
	var pipeline_str: String = str(redir_split.get("command", line)).strip_edges()
	var redir_mode: String = str(redir_split.get("mode", ""))
	var redir_target: String = str(redir_split.get("target", ""))

	var exec_res: Dictionary = {}
	if pipeline_str.find("|") != -1:
		exec_res = _execute_pipeline(pipeline_str)
	else:
		exec_res = _execute_single(pipeline_str)

	var ok: bool = bool(exec_res.get("success", true))
	var out_text: String = str(exec_res.get("output", ""))
	result.side_effects = exec_res.get("side_effects", {}) if exec_res.get("side_effects") is Dictionary else {}

	if ok and not redir_mode.is_empty():
		if redir_target.is_empty():
			ok = false
			out_text = "bash: error de sintaxis cerca de redirección"
		else:
			var w_res: Dictionary = vfs.append_file(redir_target, out_text) if redir_mode == ">>" else vfs.write_file(redir_target, out_text)
			if bool(w_res.get("success", false)):
				result.side_effects["redirected_to"] = str(w_res.get("path", redir_target))
				out_text = ""
			else:
				ok = false
				out_text = str(w_res.get("error", "Error escribiendo redirección"))

	if ok:
		result.stdout = out_text
		result.exit_code = 0
	else:
		result.stderr = out_text
		result.exit_code = 1
	result.cwd = vfs.current_path

	var parts: Array[String] = _parse_args(pipeline_str)
	var cmd_name: String = parts[0] if parts.size() > 0 else ""
	_emit_cli_event(cmd_name, result.exit_code)
	return result


func autocomplete(partial_line: String) -> Dictionary:
	var has_trailing_space: bool = partial_line.ends_with(" ")
	var stripped: String = partial_line.strip_edges(true, false)
	if stripped.is_empty():
		return {"completed": partial_line, "matches": []}

	var raw_parts: PackedStringArray = stripped.split(" ", false)
	var parts: Array[String] = []
	for p in raw_parts:
		parts.append(p)

	if parts.size() == 1 and not has_trailing_space:
		var prefix: String = parts[0]
		var matches: Array[String] = []
		for cmd in ALL_COMMANDS:
			if cmd.begins_with(prefix):
				matches.append(cmd)
		if prefix.begins_with("/"):
			matches.append_array(_match_vfs_paths(prefix))
		matches.sort()
		var completed: String = partial_line
		if matches.size() == 1:
			completed = matches[0]
		elif matches.size() > 1:
			completed = _longest_common_prefix(matches)
		return {"completed": completed, "matches": matches}

	var cmd_tok: String = parts[0]
	var arg_prefix: String = "" if has_trailing_space else parts[parts.size() - 1]
	var base_parts: Array[String] = parts.duplicate() if has_trailing_space else parts.slice(0, parts.size() - 1)
	var matches_arg: Array[String] = []

	if cmd_tok in ["nmap", "scan", "ping", "traceroute"] and _game_context != null and _game_context.get("graph") != null:
		var graph: Variant = _game_context.get("graph")
		if graph != null and "nodes" in graph:
			for n in graph.nodes:
				if n == null:
					continue
				var nid: String = str(n.id)
				if arg_prefix.is_empty() or nid.to_lower().begins_with(arg_prefix.to_lower()):
					matches_arg.append(nid)

	for vp in _match_vfs_paths(arg_prefix):
		if not matches_arg.has(vp):
			matches_arg.append(vp)

	matches_arg.sort()
	var completed_arg: String = partial_line
	if matches_arg.size() == 1:
		completed_arg = " ".join(base_parts) + " " + matches_arg[0]
	elif matches_arg.size() > 1:
		var lcp: String = _longest_common_prefix(matches_arg)
		if lcp.length() > arg_prefix.length():
			completed_arg = " ".join(base_parts) + " " + lcp
	return {"completed": completed_arg, "matches": matches_arg}


func _match_vfs_paths(prefix: String) -> Array[String]:
	var matches: Array[String] = []
	var search_dir: String = vfs.current_path
	var leaf_prefix: String = prefix
	var display_dir: String = ""

	if prefix.contains("/"):
		var slash_idx: int = prefix.rfind("/")
		display_dir = prefix.substr(0, slash_idx + 1)
		leaf_prefix = prefix.substr(slash_idx + 1)
		var dir_part: String = "/" if display_dir == "/" else display_dir.trim_suffix("/")
		search_dir = vfs.normalize_path(dir_part)

	if not vfs._fs.has(search_dir):
		return matches
	var dir_entry: Dictionary = vfs._fs[search_dir]
	if dir_entry.get("type") != "dir":
		return matches
	if bool(dir_entry.get("root_only", false)) and not vfs.is_root:
		return matches

	for ch in dir_entry.get("children", []):
		var ch_str: String = str(ch)
		if leaf_prefix.is_empty() or ch_str.begins_with(leaf_prefix):
			var full: String = search_dir + ("/" if search_dir != "/" else "") + ch_str
			var suffix: String = "/" if (vfs._fs.has(full) and (vfs._fs[full] as Dictionary).get("type") == "dir") else ""
			matches.append(display_dir + ch_str + suffix)
	return matches


func _longest_common_prefix(items: Array[String]) -> String:
	if items.is_empty():
		return ""
	var prefix: String = items[0]
	for i in range(1, items.size()):
		var cur: String = items[i]
		while not cur.begins_with(prefix) and not prefix.is_empty():
			prefix = prefix.substr(0, prefix.length() - 1)
	return prefix


func _split_redirection(line: String) -> Dictionary:
	var in_quotes: bool = false
	var quote_char: String = ""
	for i in range(line.length()):
		var c: String = line[i]
		if (c == '"' or c == "'") and (quote_char.is_empty() or quote_char == c):
			in_quotes = not in_quotes
			quote_char = c if in_quotes else ""
		elif c == ">" and not in_quotes:
			var is_append: bool = (i + 1 < line.length() and line[i + 1] == ">")
			var cmd_part: String = line.substr(0, i).strip_edges()
			var target_part: String = line.substr(i + (2 if is_append else 1)).strip_edges()
			return {
				"command": cmd_part,
				"mode": ">>" if is_append else ">",
				"target": target_part,
			}
	return {"command": line, "mode": "", "target": ""}


func _execute_pipeline(line: String) -> Dictionary:
	var parts: PackedStringArray = line.split("|", true)
	var current_output: String = ""
	var merged_effects: Dictionary = {}
	for i in range(parts.size()):
		var sub_cmd: String = parts[i].strip_edges()
		var step_res: Dictionary = _execute_single(sub_cmd) if i == 0 else _execute_piped(sub_cmd, current_output)
		if not bool(step_res.get("success", true)):
			return step_res
		current_output = str(step_res.get("output", ""))
		if step_res.has("side_effects") and step_res["side_effects"] is Dictionary:
			merged_effects.merge(step_res["side_effects"] as Dictionary, true)
	return {"success": true, "output": current_output, "side_effects": merged_effects}


func _parse_args(cmd_line: String) -> Array[String]:
	var parts: Array[String] = []
	var current: String = ""
	var in_quotes: bool = false
	for i in range(cmd_line.length()):
		var c: String = cmd_line[i]
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
	var parts: Array[String] = _parse_args(cmd_line)
	if parts.is_empty():
		return {"success": true, "output": ""}

	var cmd: String = parts[0]
	var args: Array[String] = parts.slice(1)

	if cmd.begins_with("/usr/games/"):
		var cid: String = cmd.get_file()
		return _start_cartridge(cid)

	match cmd:
		"help":
			return {"success": true, "output": "Comandos UNIX/POSIX disponibles:\n  ls [-l] [-a] [ruta] | cd [ruta] | pwd | cat <arch> | echo <txt>\n  mkdir [-p] <dir> | touch <arch> | cp <src> <dst> | mv <src> <dst> | rm [-rf] <ruta>\n  grep [-i] [-n] <pat> <arch> | find [ruta] [-name <pat>] | head / tail / wc\n  ps [aux] | kill <pid> | chmod <mod> <arch> | base64 [-d] | history\n  Tácticos: status | traceroute [nodo] | nmap <nodo> | netstat | ping <nodo>\n  Secretos & Bóveda: sudo <cmd> | ssh <host> | decrypt --list | unlock <token> | badges\n  Cartuchos Retro: games | play <breach3d|netcycle|rogue|icebreaker>\n  Redirecciones: > , >>  |  Pipes: |  |  Autocompletado: [TAB]"}
		"pwd":
			return {"success": true, "output": vfs.current_path}
		"whoami":
			return {"success": true, "output": get_active_user()}
		"uname":
			var extra: bool = "-a" in args or "a" in args
			if extra:
				return {"success": true, "output": "Linux vertex-tactical-kernel 6.8.0-vertex-generic #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux"}
			return {"success": true, "output": "Linux"}
		"clear":
			return {"success": true, "output": "__CLEAR__"}
		"echo":
			return {"success": true, "output": " ".join(args)}
		"history":
			var h_lines: Array[String] = []
			for idx in range(command_history.size()):
				h_lines.append("%4d  %s" % [idx + 1, command_history[idx]])
			return {"success": true, "output": "\n".join(h_lines)}
		"cd":
			var target: String = str(args[0]) if args.size() > 0 else "/home/operator"
			var res: Dictionary = vfs.cd(target)
			if bool(res.get("success", false)):
				return {"success": true, "output": ""}
			return {"success": false, "output": str(res.get("error", "Error en cd"))}
		"ls":
			var show_long: bool = false
			var show_all: bool = false
			var target_path: String = ""
			for a in args:
				if a.begins_with("-"):
					if a.find("l") != -1:
						show_long = true
					if a.find("a") != -1:
						show_all = true
				else:
					target_path = a
			var res: Dictionary = vfs.ls(target_path)
			if not bool(res.get("success", false)):
				return {"success": false, "output": str(res.get("error", "Error en ls"))}
			var raw_items: Array = res.get("items", [])
			var items: Array = []
			for it in raw_items:
				var it_name: String = str(it).trim_suffix("/")
				if not show_all and it_name.begins_with("."):
					continue
				items.append(it)
			if show_long:
				var lines: Array[String] = ["total %d" % items.size()]
				for it in items:
					var it_str: String = str(it)
					var is_dir: bool = it_str.ends_with("/")
					var clean_name: String = it_str.trim_suffix("/")
					var perm: String = "drwxr-xr-x" if is_dir else "-rw-r--r--"
					var owner: String = "root" if (clean_name in ["blueprint.txt", "kain_notes.txt", "kain_trace.log", "vex_hr_purged.dat", "aegis_biometric.sha", "dossier_unlock.tok"]) else "operator"
					lines.append("%s 1 %s %s 4096 Nov 22 21:00 %s" % [perm, owner, owner, it_str])
				return {"success": true, "output": "\n".join(lines)}
			return {"success": true, "output": "  ".join(items)}
		"cat":
			if args.is_empty():
				return {"success": false, "output": "cat: falta operando de archivo"}
			var res: Dictionary = vfs.cat(args[0])
			if bool(res.get("success", false)):
				return {"success": true, "output": str(res.get("content", ""))}
			return {"success": false, "output": str(res.get("error", "Error en cat"))}
		"mkdir":
			if args.is_empty():
				return {"success": false, "output": "mkdir: falta operando"}
			var make_p: bool = false
			var targets: Array[String] = []
			for a in args:
				if a == "-p":
					make_p = true
				else:
					targets.append(a)
			for t in targets:
				var mres: Dictionary = vfs.mkdir(t, make_p)
				if not bool(mres.get("success", false)):
					return {"success": false, "output": str(mres.get("error", "Error en mkdir"))}
			return {"success": true, "output": ""}
		"touch":
			if args.is_empty():
				return {"success": false, "output": "touch: falta operando de archivo"}
			for t in args:
				var tres: Dictionary = vfs.touch(t)
				if not bool(tres.get("success", false)):
					return {"success": false, "output": str(tres.get("error", "Error en touch"))}
			return {"success": true, "output": ""}
		"cp":
			if args.size() < 2:
				return {"success": false, "output": "cp: faltan operandos <origen> <destino>"}
			var cres: Dictionary = vfs.copy_node(args[0], args[1])
			if bool(cres.get("success", false)):
				return {"success": true, "output": ""}
			return {"success": false, "output": str(cres.get("error", "Error en cp"))}
		"mv":
			if args.size() < 2:
				return {"success": false, "output": "mv: faltan operandos <origen> <destino>"}
			var mvres: Dictionary = vfs.move_node(args[0], args[1])
			if bool(mvres.get("success", false)):
				return {"success": true, "output": ""}
			return {"success": false, "output": str(mvres.get("error", "Error en mv"))}
		"rm":
			if args.is_empty():
				return {"success": false, "output": "rm: falta operando"}
			var rec: bool = false
			var force: bool = false
			var rm_targets: Array[String] = []
			for a in args:
				if a.begins_with("-"):
					if a.contains("r") or a.contains("R"):
						rec = true
					if a.contains("f"):
						force = true
				else:
					rm_targets.append(a)
			for t in rm_targets:
				var rres: Dictionary = vfs.remove_node(t, rec, force)
				if not bool(rres.get("success", false)):
					return {"success": false, "output": str(rres.get("error", "Error en rm"))}
			return {"success": true, "output": ""}
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
			var target_file: String = vfs.normalize_path(args[1])
			if vfs._fs.has(target_file):
				return {"success": true, "output": "Modo de '%s' cambiado a %s exitosamente." % [args[1], args[0]]}
			return {"success": false, "output": "chmod: no existe el archivo '%s'" % args[1]}
		"ps":
			var lines: Array[String] = ["PID TTY          TIME CMD"]
			var show_aux: bool = false
			for a in args:
				if a.find("aux") != -1 or a.find("a") != -1:
					show_aux = true
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
			var found_idx: int = -1
			for i in range(background_processes.size()):
				if int(background_processes[i].get("pid", 0)) == pid_str:
					found_idx = i
					break
			if found_idx != -1:
				background_processes.remove_at(found_idx)
				return {"success": true, "output": "[+] Proceso PID %d terminado exitosamente." % pid_str}
			return {"success": false, "output": "kill: (%d) - No such process" % pid_str}
		"base64":
			return _handle_base64(args)
		"sudo":
			if args.is_empty():
				return {"success": false, "output": "sudo: falta comando"}
			if args[0] == "-k":
				vfs.is_root = false
				return {"success": true, "output": "Credenciales root revocadas."}
			if args[0] == "-p" and args.size() >= 3:
				var pw: String = args[1]
				if not (pw in ["as65000-root", "kain99", "cyber26"]):
					return {"success": false, "output": "sudo: contraseña incorrecta"}
				vfs.is_root = true
				return _execute_single(" ".join(args.slice(2)))
			vfs.is_root = true
			return _execute_single(" ".join(args))
		"su":
			if args.size() > 0 and args[0] in ["as65000-root", "kain99", "cyber26"]:
				vfs.is_root = true
				return {"success": true, "output": "[+] Sesión elevada a root (UID=0)."}
			return {"success": false, "output": "su: usa 'su <password>' o 'sudo <comando>'"}
		"ssh":
			return _handle_ssh(args)
		"decrypt":
			return _handle_decrypt(args)
		"unlock":
			return _handle_unlock(args)
		"badges":
			return _handle_badges()
		"status", "ping", "nmap", "scan", "traceroute", "netstat", "ifconfig", "ip":
			return _handle_network_commands(cmd, args)
		"games":
			return {"success": true, "output": "=== CARTUCHOS /usr/games/ ===\n  /usr/games/breach3d   - Raycaster 3D ASCII por corredores del Kernel\n  /usr/games/netcycle   - Duelo de estelas de luz contra CORDON\n  /usr/games/rogue      - Roguelike ASCII de Sector 0\n  /usr/games/icebreaker - Cracker hexadecimal Mastermind\nEjecuta cualquiera por nombre (ej. 'breach3d' o 'play rogue')."}
		"play":
			if args.is_empty():
				return {"success": false, "output": "Uso: play <breach3d|netcycle|rogue|icebreaker>"}
			return _start_cartridge(args[0])
		"breach3d", "netcycle", "rogue", "icebreaker":
			return _start_cartridge(cmd)
		"academy":
			return {"success": true, "output": get_academy_banner()}
		_:
			return {"success": false, "output": "%s: comando no encontrado. Escribe 'help'." % cmd}


func _execute_piped(sub_cmd: String, stdin_text: String) -> Dictionary:
	var parts: Array[String] = _parse_args(sub_cmd)
	if parts.is_empty():
		return {"success": true, "output": stdin_text}
	var cmd: String = parts[0]
	var args: Array[String] = parts.slice(1)

	if cmd == "grep":
		var ignore_case: bool = false
		var line_number: bool = false
		var pattern: String = ""
		for a in args:
			if a == "-i":
				ignore_case = true
			elif a == "-n":
				line_number = true
			elif pattern.is_empty():
				pattern = a
		if pattern.is_empty():
			return {"success": false, "output": "grep: patrón faltante"}
		var lines: PackedStringArray = stdin_text.split("\n")
		var matched_lines: Array[String] = []
		for idx in range(lines.size()):
			var l: String = lines[idx]
			var match_ok: bool = l.to_lower().find(pattern.to_lower()) != -1 if ignore_case else l.find(pattern) != -1
			if match_ok:
				matched_lines.append("%d:%s" % [idx + 1, l] if line_number else l)
		return {"success": true, "output": "\n".join(matched_lines)}
	elif cmd == "wc":
		var lines: PackedStringArray = stdin_text.split("\n")
		var word_count: int = 0
		for l in lines:
			word_count += l.split(" ", false).size()
		return {"success": true, "output": "%d %d %d" % [lines.size(), word_count, stdin_text.length()]}
	elif cmd == "head":
		var lines: PackedStringArray = stdin_text.split("\n")
		var count: int = _parse_line_count_arg(args, 10)
		return {"success": true, "output": "\n".join(lines.slice(0, mini(count, lines.size())))}
	elif cmd == "tail":
		var lines: PackedStringArray = stdin_text.split("\n")
		var count: int = _parse_line_count_arg(args, 10)
		var start: int = maxi(0, lines.size() - mini(count, lines.size()))
		return {"success": true, "output": "\n".join(lines.slice(start, lines.size()))}
	elif cmd == "base64":
		var decode: bool = ("-d" in args) or ("--decode" in args)
		var clean_in: String = stdin_text.strip_edges()
		if decode:
			var b64: String = Marshalls.base64_to_utf8(clean_in)
			return {"success": true, "output": b64 if not b64.is_empty() else "[Error decodificación base64]"}
		return {"success": true, "output": Marshalls.utf8_to_base64(clean_in)}
	return _execute_single(sub_cmd + " " + stdin_text)


func _handle_base64(args: Array[String]) -> Dictionary:
	var decode: bool = false
	var target: String = ""
	for a in args:
		if a == "-d" or a == "--decode":
			decode = true
		else:
			target = a
	if target.is_empty():
		return {"success": false, "output": "base64: falta argumento"}
	if decode:
		var content_to_dec: String = target
		var resolved: String = vfs.normalize_path(target)
		if vfs._fs.has(resolved) and (vfs._fs[resolved] as Dictionary).get("type") == "file":
			content_to_dec = str((vfs._fs[resolved] as Dictionary).get("content", ""))
		var b64: String = Marshalls.base64_to_utf8(content_to_dec.strip_edges())
		return {"success": true, "output": b64 if not b64.is_empty() else "[Error decodificación base64]"}
	return {"success": true, "output": Marshalls.utf8_to_base64(target)}


func _handle_grep(args: Array[String]) -> Dictionary:
	var ignore_case: bool = false
	var line_number: bool = false
	var pattern: String = ""
	var file_path: String = ""
	for a in args:
		if a == "-i":
			ignore_case = true
		elif a == "-n":
			line_number = true
		elif pattern.is_empty():
			pattern = a
		elif file_path.is_empty():
			file_path = a
	if pattern.is_empty():
		return {"success": false, "output": "grep: falta patrón"}
	if file_path.is_empty():
		return {"success": false, "output": "grep: falta archivo de entrada"}
	var cat_res: Dictionary = vfs.cat(vfs.normalize_path(file_path))
	if not bool(cat_res.get("success", false)):
		return {"success": false, "output": str(cat_res.get("error", "grep: error leyendo archivo"))}
	var lines: PackedStringArray = str(cat_res.get("content", "")).split("\n")
	var matched: Array[String] = []
	for idx in range(lines.size()):
		var l: String = lines[idx]
		var ok: bool = l.to_lower().find(pattern.to_lower()) != -1 if ignore_case else l.find(pattern) != -1
		if ok:
			matched.append("%d:%s" % [idx + 1, l] if line_number else l)
	return {"success": true, "output": "\n".join(matched)}


func _handle_find(args: Array[String]) -> Dictionary:
	var search_dir: String = vfs.current_path
	var name_pat: String = ""
	if args.size() > 0 and not args[0].begins_with("-"):
		search_dir = vfs.normalize_path(args[0])
	for i in range(args.size()):
		if args[i] == "-name" and i + 1 < args.size():
			name_pat = args[i + 1]
	var results: Array[String] = []
	for path_var in vfs._fs.keys():
		var path: String = str(path_var)
		if path.begins_with(search_dir):
			if name_pat.is_empty() or path.get_file().match(name_pat) or path.get_file().find(name_pat) != -1:
				results.append(path)
	results.sort()
	return {"success": true, "output": "\n".join(results)}


func _parse_line_count_arg(args: Array[String], default_val: int = 10) -> int:
	for i in range(args.size()):
		if args[i] == "-n" and i + 1 < args.size():
			return maxi(1, args[i + 1].to_int())
		elif args[i].begins_with("-") and args[i].length() > 1 and args[i].substr(1).is_valid_int():
			return maxi(1, args[i].substr(1).to_int())
	return default_val


func _handle_head_tail(args: Array[String], is_head: bool) -> Dictionary:
	if args.is_empty():
		return {"success": false, "output": "falta archivo"}
	var count_arg: int = _parse_line_count_arg(args, 10)
	var file_arg: String = ""
	var skip_next: bool = false
	for i in range(args.size()):
		if skip_next:
			skip_next = false
			continue
		if args[i] == "-n":
			skip_next = true
			continue
		if args[i].begins_with("-") and args[i].substr(1).is_valid_int():
			continue
		file_arg = args[i]
		break
	if file_arg.is_empty():
		return {"success": false, "output": "falta archivo"}
	var cat_res: Dictionary = vfs.cat(file_arg)
	if not bool(cat_res.get("success", false)):
		return {"success": false, "output": str(cat_res.get("error", "error leyendo archivo"))}
	var lines: PackedStringArray = str(cat_res.get("content", "")).split("\n")
	var count: int = mini(count_arg, lines.size())
	if is_head:
		return {"success": true, "output": "\n".join(lines.slice(0, count))}
	var start: int = maxi(0, lines.size() - count)
	return {"success": true, "output": "\n".join(lines.slice(start, lines.size()))}


func reset_to_custom_vfs(custom_fs: Dictionary, start_cwd: String = "/home/operator", user_str: String = "operador", host_str: String = "vtx-lab") -> void:
	vfs._fs = custom_fs.duplicate(true)
	vfs.current_path = start_cwd
	vfs.is_root = false
	command_history.clear()
	active_cartridge = ""
	cartridge_state.clear()
	set_identity(user_str, host_str, "VTX // ACADEMY")


func _handle_wc(args: Array[String]) -> Dictionary:
	if args.is_empty():
		return {"success": false, "output": "wc: falta archivo"}
	var cat_res: Dictionary = vfs.cat(args[0])
	if not bool(cat_res.get("success", false)):
		return {"success": false, "output": str(cat_res.get("error", "wc: error"))}
	var content: String = str(cat_res.get("content", ""))
	var lines: PackedStringArray = content.split("\n")
	var words: int = 0
	for l in lines:
		words += l.split(" ", false).size()
	return {"success": true, "output": "%d %d %d %s" % [lines.size(), words, content.length(), args[0]]}


func _handle_ssh(args: Array[String]) -> Dictionary:
	if args.is_empty():
		return {"success": false, "output": "Uso: ssh <usuario@host> (ver /etc/hosts)"}
	var target: String = args[0]
	if target.contains("192.168.1.100") or target.contains("kain"):
		return {
			"success": true,
			"output": "[SSH] Túnel cifrado abierto hacia kain.daemon (192.168.1.100)\n[KAIN-NODE]: 'Si estás leyendo esto, revisa /etc/sudoers.d/vertex_root y /secrets/.'\n[KAIN-NODE]: 'Los cartuchos de entrenamiento táctico viven en /usr/games/.'",
			"side_effects": {"ssh_host": "kain.daemon"}
		}
	if target.contains("10.0.0.1") or target.contains("gateway"):
		return {
			"success": true,
			"output": "[SSH] Conexión a gateway.root (AS-65000)\nBGP Neighbors: 10.0.4.1 (ESTABLISHED), 192.168.1.100 (ACTIVE/DAEMON).",
			"side_effects": {"ssh_host": "gateway.root"}
		}
	if target.contains("10.0.4.1") or target.contains("dmz"):
		return {
			"success": true,
			"output": "[SSH] dmz.firewall.internal // Reglas CORDON activas. Tráfico monitorizado.",
			"side_effects": {"ssh_host": "dmz.firewall.internal"}
		}
	return {"success": false, "output": "ssh: Could not resolve hostname '%s': Name or service not known" % target}


func _handle_decrypt(args: Array[String]) -> Dictionary:
	var vault_state: Dictionary = VaultStoreClass.load_vault()
	var unlocked: Dictionary = vault_state.get("enc_unlocked", {})
	var lines: Array[String] = ["=== ARCHIVOS .ENC EN LA BÓVEDA ==="]
	for idx in range(VaultModulesClass.ENC_FILES.size()):
		var f: Dictionary = VaultModulesClass.ENC_FILES[idx]
		var state_lbl: String = "[DESCIFRADO]" if bool(unlocked.get(idx, false)) else "[CIFRADO]"
		lines.append("  %d. %-22s %s" % [idx + 1, str(f.get("file", "")), state_lbl])
	if args.has("--list") or args.is_empty():
		return {"success": true, "output": "\n".join(lines)}
	return {"success": true, "output": "\n".join(lines) + "\nUsa La Bóveda -> Termlink .ENC o 'unlock <token>'."}


func _handle_unlock(args: Array[String]) -> Dictionary:
	if args.is_empty():
		return {"success": false, "output": "Uso: unlock <TOKEN>"}
	var token: String = args[0].strip_edges().to_upper()
	var token_map: Dictionary = {
		"TOKEN-AS65000-OMEGA": 0,
		"SHAMIR-CLOVER-9": 1,
		"KAIN-GENESIS-0": 2,
	}
	if not token_map.has(token):
		return {"success": false, "output": "unlock: token '%s' inválido o expirado." % token}
	var file_idx: int = int(token_map[token])
	var vault_state: Dictionary = VaultStoreClass.load_vault()
	var unlocked: Dictionary = (vault_state.get("enc_unlocked", {}) as Dictionary).duplicate()
	unlocked[file_idx] = true
	VaultStoreClass.save_vault(
		unlocked,
		str(vault_state.get("pinned_menu_track", VaultStoreClass.DEFAULT_PINNED_MENU_TRACK)),
		str(vault_state.get("pinned_game_track", VaultStoreClass.DEFAULT_PINNED_GAME_TRACK))
	)
	var fname: String = str(VaultModulesClass.ENC_FILES[file_idx].get("file", ""))
	return {
		"success": true,
		"output": "[+] TOKEN VERIFICADO: %s desbloqueado en La Bóveda (Termlink)." % fname,
		"side_effects": {"unlocked_token": token, "unlocked_file": fname}
	}


func _handle_badges() -> Dictionary:
	var unlocked_count: int = 0
	var lines: Array[String] = ["=== INSIGNIAS REGISTRADAS (%d) ===" % BadgeRegistryClass.BADGES.size()]
	for b in BadgeRegistryClass.BADGES:
		lines.append("  - %s: %s" % [str(b.get("title", "")), str(b.get("description", ""))])
		unlocked_count += 1
	return {"success": true, "output": "\n".join(lines), "side_effects": {"badge_catalog_count": unlocked_count}}


func _handle_network_commands(cmd: String, args: Array[String]) -> Dictionary:
	var has_live_graph: bool = _game_context != null and _game_context.get("graph") != null
	match cmd:
		"status":
			if _game_context != null:
				var t: Variant = _game_context.get("turn")
				var ppos: Variant = _game_context.get("player_pos")
				var epos: Variant = _game_context.get("enemy_pos")
				var def_mode: bool = bool(_game_context.get("defender_mode"))
				var mp: Variant = _game_context.get("movement_points")
				var max_mp: Variant = _game_context.get("max_movement_points")
				var be: Variant = _game_context.get("blocked_edges")
				var blk_cnt: int = (be as Dictionary).size() if (be is Dictionary) else ((be as Array).size() if (be is Array) else 0)
				return {
					"success": true,
					"output": "STATUS: Turno=%s | Modo=%s | Pos=%s | Intruso=%s\nPRESUPUESTO=%s/%s | BLOQUEOS=%d" % [
						str(t),
						"DEFENSA" if def_mode else ("HACKER" if bool(_game_context.get("hacker_mode")) else "INCURSIÓN"),
						str(ppos), str(epos), str(mp), str(max_mp), blk_cnt
					]
				}
			return {"success": false, "output": "ERR: No hay sesión táctica activa."}
		"traceroute":
			if has_live_graph:
				return _live_traceroute(args)
			return {"success": true, "output": "traceroute to 10.0.4.1, 30 hops max\n 1 gateway.root (10.0.0.1)  0.412 ms  0.389 ms\n 2 dmz.firewall.internal (10.0.4.1)  1.102 ms  1.089 ms"}
		"nmap", "scan":
			if args.is_empty():
				return {"success": false, "output": "Uso: %s <nodo>" % cmd}
			if has_live_graph:
				var live_nmap: Dictionary = _live_nmap(args[0])
				if not live_nmap.is_empty():
					return live_nmap
			var target: String = args[0]
			return {"success": true, "output": "Starting Nmap 7.94 ( https://nmap.org )\nNmap scan report for %s (192.168.1.100)\nHost is up (0.0012s latency).\nPORT     STATE SERVICE\n22/tcp   open  ssh\n80/tcp   open  http\n443/tcp  open  https\n65001/tcp open bgp\nNmap done: 1 IP address (1 host up) scanned in 0.23 seconds." % target}
		"netstat":
			if has_live_graph:
				return _live_netstat()
			return {"success": true, "output": "Active Internet connections (w/o servers)\nProto Recv-Q Send-Q Local Address           Foreign Address         State\ntcp        0      0 10.0.0.1:22             10.0.4.1:51220          ESTABLISHED\ntcp        0      0 10.0.0.1:65001          192.168.1.100:65001     ESTABLISHED"}
		"ping":
			var target: String = args[0] if args.size() > 0 else "gateway.root"
			if has_live_graph and args.size() > 0:
				var live_ping: Dictionary = _live_ping(target)
				if not live_ping.is_empty():
					return live_ping
			return {"success": true, "output": "PING %s (10.0.0.1) 56(84) bytes of data.\n64 bytes from %s: icmp_seq=1 ttl=64 time=0.412 ms\n64 bytes from %s: icmp_seq=2 ttl=64 time=0.389 ms\n--- %s ping statistics ---\n2 packets transmitted, 2 received, 0%% packet loss, time 1002ms" % [target, target, target, target]}
		"ifconfig", "ip":
			return {"success": true, "output": "eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST> mtu 1500\n        inet 10.0.0.1  netmask 255.255.255.0  broadcast 10.0.0.255\n        inet6 fe80::42:ff:fe00:1  prefixlen 64  scopeid 0x20<link>\n        RX packets 1420  bytes 128450 (125.4 KiB)\n        TX packets 1310  bytes 115200 (112.5 KiB)"}
		_:
			return {"success": true, "output": "Red operacional nominal."}


func _live_traceroute(args: Array[String]) -> Dictionary:
	var graph: Variant = _game_context.get("graph")
	var runtime: Variant = _game_context.get("runtime")
	var player_pos: StringName = StringName(str(_game_context.get("player_pos")))
	var chain: Array[StringName] = [player_pos]
	if args.size() > 0:
		chain.append(StringName(args[0]))
	else:
		var wps: Variant = _game_context.get("waypoints")
		var wp_idx: int = int(_game_context.get("current_waypoint_idx"))
		if wps is Array:
			for i in range(maxi(0, wp_idx), (wps as Array).size()):
				chain.append(StringName(str((wps as Array)[i])))
		chain.append(StringName(str(_game_context.get("target_node"))))

	var full_nodes: Array[StringName] = []
	var total_cost: float = 0.0
	var hop_lines: Array[String] = ["TRACEROUTE TÁCTICO (sin penalización de estrellas):"]
	var hop_num: int = 1
	for i in range(chain.size() - 1):
		var seg: Dictionary = DefensivePathfinderClass.find_path_with_cost(graph, chain[i], chain[i + 1], runtime)
		if not bool(seg.get("reachable", false)):
			return {"success": false, "output": "TRACEROUTE: Sin ruta continua hacia %s (enlaces bloqueados o nodo inexistente)." % str(chain[i + 1])}
		var p: Array = seg.get("path", [])
		total_cost += float(seg.get("cost", 0.0))
		for k in range(p.size()):
			if full_nodes.is_empty() or full_nodes[full_nodes.size() - 1] != p[k]:
				full_nodes.append(p[k])
			if k < p.size() - 1:
				var e_info: Dictionary = _find_edge_info(graph, p[k], p[k + 1])
				hop_lines.append("  %2d  %s -> %s  [cost=%.1f | %s]" % [
					hop_num, str(p[k]), str(p[k + 1]),
					float(e_info.get("cost", 1.0)), str(e_info.get("protocol", "TCP"))
				])
				hop_num += 1

	var max_mp: int = int(_game_context.get("max_movement_points"))
	var cur_mp: int = int(_game_context.get("movement_points"))
	var budget_str: String = "%d/%d" % [cur_mp, max_mp] if max_mp > 0 else "ILIMITADO"
	var status_str: String = "VIABLE" if (max_mp <= 0 or total_cost <= float(cur_mp)) else "ALERTA: PRESUPUESTO INSUFICIENTE"
	hop_lines.append("COSTE TOTAL ESTIMADO: %.1f | SALTOS: %d | PRESUPUESTO: %s | ESTADO: %s" % [
		total_cost, maxi(0, full_nodes.size() - 1), budget_str, status_str
	])
	return {"success": true, "output": "\n".join(hop_lines), "side_effects": {"traceroute_cost": total_cost}}


func _live_nmap(node_arg: String) -> Dictionary:
	var graph: Variant = _game_context.get("graph")
	var nid: StringName = StringName(node_arg)
	var node_res: Variant = graph.get_node_by_id(nid) if graph.has_method("get_node_by_id") else null
	if node_res == null:
		return {}

	var det: float = float(node_res.metadata.get("detection_chance", 0.0))
	var has_fw: bool = bool(node_res.metadata.get("has_firewall", false))
	var is_decoy: bool = bool(node_res.metadata.get("is_decoy", false))
	var lines: Array[String] = [
		"Nmap Tactical Scan for %s (%s)" % [str(nid), str(node_res.display_name)],
		"RIESGO DETECCIÓN: %d%% | FIREWALL: %s | TRAMPA/DECOY: %s" % [
			int(round(det * 100.0)), "SÍ" if has_fw else "NO", "ALERTA" if is_decoy else "NO"
		],
		"PORT     STATE SERVICE       EDGE"
	]

	var runtime: Variant = _game_context.get("runtime")
	for e in graph.edges:
		if e == null:
			continue
		if e.from_id == nid or e.to_id == nid:
			var proto: String = str(e.protocol).to_upper()
			var port_desc: String = str(PROTOCOL_PORT_MAP.get(proto, "9000/tcp open  custom"))
			var blocked: bool = false
			if runtime != null and runtime.has_method("get_transit_cost"):
				blocked = is_inf(float(runtime.get_transit_cost(e.from_id, e.to_id)))
			lines.append("%s  (%s -> %s cost=%.1f %s)" % [
				port_desc, str(e.from_id), str(e.to_id), e.transit_cost, "BLOCKED" if blocked else "OPEN"
			])

	var effects: Dictionary = {}
	if bool(_game_context.get("hacker_mode")) and _game_context.get("hacker_state") is Dictionary:
		var hs: Dictionary = _game_context.get("hacker_state")
		if hs.has("scanned_nodes") and hs["scanned_nodes"] is Dictionary:
			(hs["scanned_nodes"] as Dictionary)[str(nid)] = true
			effects["tactical_scan"] = str(nid)
			lines.append("[+] Telemetría Hacker registrada en %s (0 ruido generado)." % str(nid))

	return {"success": true, "output": "\n".join(lines), "side_effects": effects}


func _live_netstat() -> Dictionary:
	var graph: Variant = _game_context.get("graph")
	var be: Variant = _game_context.get("blocked_edges")
	var blk_cnt: int = (be as Dictionary).size() if (be is Dictionary) else ((be as Array).size() if (be is Array) else 0)
	var lines: Array[String] = [
		"CONEXIONES: %d nodos, %d enlaces totales | BLOQUEOS ACTIVOS: %d" % [graph.nodes.size(), graph.edges.size(), blk_cnt]
	]
	var player_pos: StringName = StringName(str(_game_context.get("player_pos")))
	var runtime: Variant = _game_context.get("runtime")
	for e in graph.edges:
		if e != null and e.from_id == player_pos:
			var blocked: bool = runtime != null and is_inf(float(runtime.get_transit_cost(e.from_id, e.to_id)))
			lines.append("  %s -> %s  [cost=%.1f cap=%.1f %s] %s" % [
				str(e.from_id), str(e.to_id), e.transit_cost, e.mitigation_capacity,
				str(e.protocol), "BLOCKED" if blocked else "ESTABLISHED"
			])
	return {"success": true, "output": "\n".join(lines)}


func _live_ping(node_arg: String) -> Dictionary:
	var graph: Variant = _game_context.get("graph")
	var nid: StringName = StringName(node_arg)
	if not graph.has_method("get_node_by_id") or graph.get_node_by_id(nid) == null:
		return {}
	var player_pos: StringName = StringName(str(_game_context.get("player_pos")))
	var runtime: Variant = _game_context.get("runtime")
	var res: Dictionary = DefensivePathfinderClass.find_path_with_cost(graph, player_pos, nid, runtime)
	if not bool(res.get("reachable", false)):
		return {"success": false, "output": "PING %s: 100%% packet loss (Destination Host Unreachable from %s)" % [node_arg, str(player_pos)]}
	var hops: int = maxi(0, (res["path"] as Array).size() - 1)
	var cost: float = float(res.get("cost", 0.0))
	return {"success": true, "output": "PING %s desde %s: ALCANZABLE (%d saltos, coste=%.1f, 0%% packet loss)" % [node_arg, str(player_pos), hops, cost]}


func _find_edge_info(graph: Variant, from_id: StringName, to_id: StringName) -> Dictionary:
	for e in graph.edges:
		if e != null and e.from_id == from_id and e.to_id == to_id:
			return {"cost": e.transit_cost, "protocol": str(e.protocol)}
	return {"cost": 1.0, "protocol": "TCP"}


# ─── Cartuchos Retro (/usr/games/) ─────────────────────────────────────

func _start_cartridge(cid: String) -> Dictionary:
	match cid:
		"breach3d":
			active_cartridge = "breach3d"
			cartridge_state = {"hp": 100, "ammo": 8, "depth": 1, "ice_hp": 2, "yaw": 0}
			return {"success": true, "output": _render_breach3d("Iniciado. Controles: [w/forward] [a/left] [d/right] [f/fire] [q/quit]")}
		"netcycle":
			active_cartridge = "netcycle"
			cartridge_state = {"px": 2, "py": 3, "ex": 9, "ey": 3, "score": 0, "trail": [[2, 3]]}
			return {"success": true, "output": _render_netcycle("Iniciado. Controles: [w/a/s/d/right/left/up/down] [q/quit]")}
		"rogue":
			active_cartridge = "rogue"
			cartridge_state = {"px": 1, "py": 1, "shards": 0, "hp": 10}
			return {"success": true, "output": _render_rogue("Iniciado. Controles: [w/a/s/d] [hack] [q/quit]")}
		"icebreaker":
			active_cartridge = "icebreaker"
			cartridge_state = {"secret": "A7F3", "attempts": 6, "history": []}
			return {"success": true, "output": _render_icebreaker("Iniciado. Adivina el PIN hex de 4 dígitos (0-9A-F), 'hint' o 'q' para salir.")}
		_:
			return {"success": false, "output": "Cartucho desconocido: %s" % cid}


func _step_cartridge(input_line: String) -> Dictionary:
	var act: String = input_line.strip_edges().to_lower()
	if act in ["q", "quit", "exit"]:
		var prev: String = active_cartridge
		active_cartridge = ""
		cartridge_state.clear()
		return {"success": true, "output": "[CARTUCHO '%s' CERRADO] Volviendo a shell POSIX." % prev}

	match active_cartridge:
		"breach3d":
			var msg: String = ""
			if act in ["w", "forward"]:
				cartridge_state["depth"] = int(cartridge_state["depth"]) + 1
				msg = "Avanzas al sector de memoria #%d." % int(cartridge_state["depth"])
			elif act in ["a", "left"]:
				cartridge_state["yaw"] = (int(cartridge_state["yaw"]) - 15) % 360
				msg = "Giras a la izquierda (%d°)." % int(cartridge_state["yaw"])
			elif act in ["d", "right"]:
				cartridge_state["yaw"] = (int(cartridge_state["yaw"]) + 15) % 360
				msg = "Giras a la derecha (%d°)." % int(cartridge_state["yaw"])
			elif act in ["f", "fire"]:
				if int(cartridge_state["ammo"]) > 0:
					cartridge_state["ammo"] = int(cartridge_state["ammo"]) - 1
					cartridge_state["ice_hp"] = maxi(0, int(cartridge_state["ice_hp"]) - 1)
					msg = "¡Disparo de pulso! ICE HP=%d" % int(cartridge_state["ice_hp"])
				else:
					msg = "Sin munición de pulso."
			else:
				msg = "Comando breach3d: w/a/d/f/q"
			return {"success": true, "output": _render_breach3d(msg)}

		"netcycle":
			var px: int = int(cartridge_state["px"])
			var py: int = int(cartridge_state["py"])
			if act in ["d", "right"]: px = mini(11, px + 1)
			elif act in ["a", "left"]: px = maxi(0, px - 1)
			elif act in ["w", "up"]: py = maxi(0, py - 1)
			elif act in ["s", "down"]: py = mini(5, py + 1)
			cartridge_state["px"] = px
			cartridge_state["py"] = py
			cartridge_state["score"] = int(cartridge_state["score"]) + 10
			return {"success": true, "output": _render_netcycle("Posición=(%d,%d) Score=%d" % [px, py, int(cartridge_state["score"])])}

		"rogue":
			var px: int = int(cartridge_state["px"])
			var py: int = int(cartridge_state["py"])
			if act == "d": px = mini(8, px + 1)
			elif act == "a": px = maxi(1, px - 1)
			elif act == "s": py = mini(4, py + 1)
			elif act == "w": py = maxi(1, py - 1)
			elif act == "hack": cartridge_state["shards"] = int(cartridge_state["shards"]) + 1
			cartridge_state["px"] = px
			cartridge_state["py"] = py
			return {"success": true, "output": _render_rogue("HP=%d Shards=%d Pos=(%d,%d)" % [int(cartridge_state["hp"]), int(cartridge_state["shards"]), px, py])}

		"icebreaker":
			if act == "hint":
				return {"success": true, "output": _render_icebreaker("PISTA: El primer símbolo hex es 'A' y el último es '3'.")}
			var guess: String = act.to_upper()
			if guess.length() != 4:
				return {"success": false, "output": "Ingresa exactamente 4 dígitos hex (ej. A7F3), 'hint' o 'q'."}
			var secret: String = str(cartridge_state["secret"])
			if guess == secret:
				active_cartridge = ""
				return {"success": true, "output": "[+] ICEBREAKER: PIN %s DESCIFRADO! Núcleo de entrenamiento liberado." % secret}
			var exact: int = 0
			for i in range(4):
				if guess[i] == secret[i]:
					exact += 1
			cartridge_state["attempts"] = maxi(0, int(cartridge_state["attempts"]) - 1)
			return {"success": true, "output": _render_icebreaker("Intento %s -> EXACTOS=%d/4 | Intentos restantes=%d" % [guess, exact, int(cartridge_state["attempts"])])}

	return {"success": false, "output": "Cartucho no activo."}


func _render_breach3d(status_msg: String) -> String:
	var ice_sym: String = " [<>] " if int(cartridge_state.get("ice_hp", 0)) > 0 else "  ..  "
	return "=== BREACH-3D // DEPTH %d ===\n#########\n#  | |  #\n# %s#\n#__| |__|#\nHP:%d AMMO:%d | %s" % [
		int(cartridge_state.get("depth", 1)), ice_sym, int(cartridge_state.get("hp", 100)), int(cartridge_state.get("ammo", 8)), status_msg
	]


func _render_netcycle(status_msg: String) -> String:
	var px: int = int(cartridge_state.get("px", 2))
	var py: int = int(cartridge_state.get("py", 3))
	var rows: Array[String] = ["=== NETCYCLE // TRON-GRID ==="]
	for y in range(6):
		var line: String = "|"
		for x in range(12):
			if x == px and y == py:
				line += "@"
			elif x == int(cartridge_state.get("ex", 9)) and y == int(cartridge_state.get("ey", 3)):
				line += "X"
			else:
				line += "."
		rows.append(line + "|")
	rows.append(status_msg)
	return "\n".join(rows)


func _render_rogue(status_msg: String) -> String:
	var px: int = int(cartridge_state.get("px", 1))
	var py: int = int(cartridge_state.get("py", 1))
	var rows: Array[String] = ["=== ROGUE-S0 // SECTOR 0 MEMORY ==="]
	for y in range(6):
		var line: String = ""
		for x in range(10):
			if y == 0 or y == 5 or x == 0 or x == 9:
				line += "#"
			elif x == px and y == py:
				line += "@"
			elif x == 7 and y == 4:
				line += ">"
			elif x == 5 and y == 2:
				line += "$"
			else:
				line += "."
		rows.append(line)
	rows.append(status_msg)
	return "\n".join(rows)


func _render_icebreaker(status_msg: String) -> String:
	return "=== ICEBREAKER // HEX CRACKER ===\n[ _ _ _ _ ]  %s" % status_msg


func _emit_cli_event(cmd_name: String, exit_code: int) -> void:
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		var ev_node: Node = (ml as SceneTree).root.get_node_or_null("Events")
		if ev_node != null and ev_node.has_signal("cli_command_executed"):
			ev_node.emit_signal("cli_command_executed", cmd_name, exit_code, context_name)


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
