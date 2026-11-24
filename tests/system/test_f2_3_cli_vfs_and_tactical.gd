extends Node

## Test Suite F2.3: Shared CLI/VFS Core, Live Graph Tactical Commands,
## Autocomplete [TAB], Diegetic Secrets & /usr/games/ Retro Cartridges.

const TerminalVFSClass = preload("res://juego/ui/terminal_vfs.gd")
const UnixShellEngineClass = preload("res://juego/system/unix_shell_engine.gd")
const TerminalOverlayClass = preload("res://juego/ui/terminal_overlay.gd")
const NetworkRuntimeClass = preload("res://core/network/network_runtime.gd")
const VaultStoreClass = preload("res://juego/system/vault_store.gd")
const SlotManagerClass = preload("res://juego/system/slot_manager.gd")
const ProfileClass = preload("res://escenas/menu/profile.gd")

var _passed: int = 0
var _failed: int = 0


class MockGameContext extends Node:
	var graph: NetworkGraphResource = null
	var runtime: NetworkRuntime = null
	var player_pos: StringName = &"Inicio"
	var target_node: StringName = &"Boveda"
	var waypoints: Array = [&"Seguridad", &"Cajas"]
	var current_waypoint_idx: int = 0
	var movement_points: int = 12
	var max_movement_points: int = 12
	var turn: int = 1
	var defender_mode: bool = false
	var hacker_mode: bool = false
	var hacker_state: Dictionary = {"scanned_nodes": {}, "noise": 0}
	var blocked_edges: Dictionary = {}
	var route_hint_used: bool = false
	var enemy_pos: StringName = &""


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_vfs_rw_and_permissions()
	_test_rm_rf_root_guard()
	_test_clone_snapshot_isolation()
	_test_shell_result_pipes_and_redirections()
	_test_live_graph_tactical_commands()
	_test_autocomplete_secrets_overlay_and_cartridges()
	_test_dynamic_identity_and_lazy_vault_tabs()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s" % msg)


func _test_vfs_rw_and_permissions() -> void:
	var vfs := TerminalVFSClass.new()
	_assert(bool(vfs.mkdir("/home/operator/ops_lab").get("success", false)), "mkdir crea /home/operator/ops_lab")
	_assert(bool(vfs.touch("/home/operator/ops_lab/note.txt").get("success", false)), "touch crea note.txt")
	_assert(bool(vfs.write_file("/home/operator/ops_lab/note.txt", "alpha").get("success", false)), "write_file escribe contenido")
	_assert(bool(vfs.append_file("/home/operator/ops_lab/note.txt", "beta").get("success", false)), "append_file agrega linea")
	var cat_note: Dictionary = vfs.cat("/home/operator/ops_lab/note.txt")
	_assert(str(cat_note.get("content", "")) == "alpha\nbeta", "cat lee alpha\\nbeta tras write+append")

	_assert(bool(vfs.copy_node("/home/operator/ops_lab/note.txt", "/home/operator/note_copy.txt").get("success", false)), "cp copia archivo")
	_assert(bool(vfs.move_node("/home/operator/note_copy.txt", "/home/operator/note_moved.txt").get("success", false)), "mv mueve archivo")
	_assert(not vfs._fs.has("/home/operator/note_copy.txt") and vfs._fs.has("/home/operator/note_moved.txt"), "mv elimina origen y crea destino")
	_assert(bool(vfs.remove_node("/home/operator/note_moved.txt").get("success", false)), "rm elimina archivo de usuario")

	_assert(not bool(vfs.write_file("/bin/hack", "x").get("success", true)), "bloquea escritura en /bin sin root")
	_assert(not bool(vfs.write_file("/proc/sector0/fake", "x").get("success", true)), "bloquea escritura en /proc")

	var denied_sec: Dictionary = vfs.cat("/secrets/vex_hr_purged.dat")
	_assert(not bool(denied_sec.get("success", true)), "cat /secrets/vex_hr_purged.dat denegado sin root")
	vfs.is_root = true
	var allowed_sec: Dictionary = vfs.cat("/secrets/vex_hr_purged.dat")
	_assert(bool(allowed_sec.get("success", false)) and str(allowed_sec.get("content", "")).contains("AS-65000"),
		"cat /secrets/vex_hr_purged.dat accesible con root")


func _test_rm_rf_root_guard() -> void:
	var engine := UnixShellEngineClass.new()
	engine.vfs.is_root = true
	var res: UnixShellEngineClass.ShellResult = engine.execute("rm -rf /")
	_assert(res.exit_code != 0, "rm -rf / retorna exit_code != 0")
	_assert(res.stderr.contains("KERNEL PANIC BLOCKED"), "rm -rf / activa guardia CORDON-GUARD")
	_assert(engine.vfs._fs.has("/") and engine.vfs._fs.has("/home/operator"), "rm -rf / deja VFS intacto")


func _test_clone_snapshot_isolation() -> void:
	var orig := TerminalVFSClass.new()
	var sandbox: TerminalVFS = orig.clone_snapshot()
	sandbox.write_file("/home/operator/sandbox_only.txt", "temp")
	sandbox.remove_node("/home/operator/readme.txt")
	_assert(orig._fs.has("/home/operator/readme.txt") and not orig._fs.has("/home/operator/sandbox_only.txt"),
		"clone_snapshot aisla mutaciones del VFS original")


func _test_shell_result_pipes_and_redirections() -> void:
	var engine := UnixShellEngineClass.new()
	var r1: UnixShellEngineClass.ShellResult = engine.execute("echo \"linea1\" > /home/operator/log_test.txt")
	var r2: UnixShellEngineClass.ShellResult = engine.execute("echo \"linea2\" >> /home/operator/log_test.txt")
	_assert(r1.exit_code == 0 and r2.exit_code == 0, "redirecciones > y >> retornan exit_code 0")

	var r3: UnixShellEngineClass.ShellResult = engine.execute("cat /home/operator/log_test.txt | grep linea2 | wc")
	_assert(r3.exit_code == 0 and r3.stdout.begins_with("1 1 "), "pipe encadenado cat | grep | wc funciona: %s" % r3.stdout)


func _test_live_graph_tactical_commands() -> void:
	var g := load("res://juego/nivel1/nivel1_red.tres") as NetworkGraphResource
	var ctx := MockGameContext.new()
	ctx.graph = g
	ctx.runtime = NetworkRuntimeClass.new(g)
	ctx.hacker_mode = true

	var engine := UnixShellEngineClass.new()
	engine.set_game_context(ctx)

	var tr_res: UnixShellEngineClass.ShellResult = engine.execute("traceroute")
	_assert(tr_res.exit_code == 0 and tr_res.stdout.contains("COSTE TOTAL ESTIMADO: 9.0"),
		"traceroute calcula ruta optima real multi-waypoint (cost=9.0)")
	_assert(ctx.route_hint_used == false, "traceroute en consola NO activa penalizacion route_hint_used")

	var nm_res: UnixShellEngineClass.ShellResult = engine.execute("nmap Puerta")
	_assert(nm_res.exit_code == 0 and nm_res.stdout.contains("RIESGO DETECCIÓN: 8%") and nm_res.stdout.contains("FIREWALL: SÍ"),
		"nmap Puerta reporta metadata real de grafo vivo")
	_assert(bool(ctx.hacker_state["scanned_nodes"].get("Puerta", false)) and int(ctx.hacker_state["noise"]) == 0,
		"nmap en hacker_mode registra escaneo tactico con 0 ruido")

	var ns_res: UnixShellEngineClass.ShellResult = engine.execute("netstat")
	_assert(ns_res.exit_code == 0 and ns_res.stdout.contains("Inicio -> Puerta"), "netstat lista enlaces salientes desde player_pos")

	var pg_res: UnixShellEngineClass.ShellResult = engine.execute("ping Seguridad")
	_assert(pg_res.exit_code == 0 and pg_res.stdout.contains("ALCANZABLE"), "ping Seguridad confirma alcanzabilidad en grafo")

	ctx.free()


func _test_autocomplete_secrets_overlay_and_cartridges() -> void:
	var g := load("res://juego/nivel1/nivel1_red.tres") as NetworkGraphResource
	var ctx := MockGameContext.new()
	ctx.graph = g
	ctx.runtime = NetworkRuntimeClass.new(g)

	var engine := UnixShellEngineClass.new()
	engine.set_game_context(ctx)

	var ac_cmd: Dictionary = engine.autocomplete("trac")
	_assert(str(ac_cmd.get("completed", "")) == "traceroute", "autocomplete('trac') -> 'traceroute'")

	var ac_node: Dictionary = engine.autocomplete("nmap Seg")
	_assert(str(ac_node.get("completed", "")) == "nmap Seguridad", "autocomplete('nmap Seg') -> 'nmap Seguridad'")

	var ac_file: Dictionary = engine.autocomplete("cat read")
	_assert(str(ac_file.get("completed", "")) == "cat readme.txt", "autocomplete('cat read') -> 'cat readme.txt'")

	# SSH & Secret unlock (save/restore vault slot state)
	var prev_vault: Dictionary = VaultStoreClass.load_vault()
	var ssh_res: UnixShellEngineClass.ShellResult = engine.execute("ssh kain@192.168.1.100")
	_assert(ssh_res.exit_code == 0 and ssh_res.stdout.contains("vertex_root"), "ssh kain@192.168.1.100 revela pista de sudoers")

	var unl_res: UnixShellEngineClass.ShellResult = engine.execute("unlock TOKEN-AS65000-OMEGA")
	_assert(unl_res.exit_code == 0 and unl_res.stdout.contains("desbloqueado"), "unlock TOKEN-AS65000-OMEGA desbloquea dossier")
	VaultStoreClass.save_vault(
		prev_vault.get("enc_unlocked", {}),
		str(prev_vault.get("pinned_menu_track", VaultStoreClass.DEFAULT_PINNED_MENU_TRACK)),
		str(prev_vault.get("pinned_game_track", VaultStoreClass.DEFAULT_PINNED_GAME_TRACK))
	)
	SlotManagerClass.invalidate_cache()

	# TerminalOverlay TAB, UP history, and as65000-root sudo password
	var term := TerminalOverlayClass.new()
	add_child(term)
	term.setup(ctx)
	term.open()
	term._input_text = "trac"
	var ev_tab := InputEventKey.new()
	ev_tab.pressed = true
	ev_tab.keycode = KEY_TAB
	term.handle_input(ev_tab)
	_assert(term._input_text == "traceroute", "TerminalOverlay KEY_TAB autocompleta a 'traceroute'")

	term._input_text = "sudo whoami"
	term._handle_enter_pressed()
	_assert(term._mode == TerminalOverlayClass.Mode.SUDO_PROMPT, "TerminalOverlay entra en SUDO_PROMPT")
	term._input_text = "as65000-root"
	term._handle_enter_pressed()
	_assert(term._vfs.is_root and term._output_lines[term._output_lines.size() - 1] == "root",
		"TerminalOverlay autentica sudo con clave 'as65000-root'")

	var ev_up := InputEventKey.new()
	ev_up.pressed = true
	ev_up.keycode = KEY_UP
	term.handle_input(ev_up)
	var first_up: String = term._input_text
	term.handle_input(ev_up)
	_assert(first_up == "whoami" and term._input_text == "sudo whoami",
		"TerminalOverlay KEY_UP navega historial ('whoami' -> 'sudo whoami')")
	term.close()
	term.queue_free()

	# Retro cartridges in /usr/games/
	for cart_pair in [
		["/usr/games/breach3d", "fire"],
		["/usr/games/netcycle", "right"],
		["/usr/games/rogue", "d"],
		["/usr/games/icebreaker", "hint"],
	]:
		var launch_r: UnixShellEngineClass.ShellResult = engine.execute(cart_pair[0])
		var step_r: UnixShellEngineClass.ShellResult = engine.execute(cart_pair[1])
		var quit_r: UnixShellEngineClass.ShellResult = engine.execute("q")
		_assert(launch_r.exit_code == 0 and step_r.exit_code == 0 and quit_r.exit_code == 0 and engine.active_cartridge.is_empty(),
			"cartucho %s inicia, ejecuta '%s' y sale limpiamente" % [cart_pair[0], cart_pair[1]])

	ctx.free()


func _test_dynamic_identity_and_lazy_vault_tabs() -> void:
	var engine := UnixShellEngineClass.new()
	var ctx_heist := MockGameContext.new()
	engine.set_game_context(ctx_heist)
	_assert(engine.operator_user == "vex" and engine.execute("whoami").stdout == "vex",
		"identidad dinamica Heist -> 'vex'")

	ctx_heist.hacker_mode = true
	engine.set_game_context(ctx_heist)
	_assert(engine.operator_user == "n0x" and engine.execute("whoami").stdout == "n0x",
		"identidad dinamica Hacker -> 'n0x'")

	ctx_heist.hacker_mode = false
	ctx_heist.defender_mode = true
	engine.set_game_context(ctx_heist)
	_assert(engine.operator_user == "aegis" and engine.execute("whoami").stdout == "aegis",
		"identidad dinamica Defensa -> 'aegis'")

	SceneParams.level_key = "sector_0_1"
	engine.set_game_context(ctx_heist)
	_assert(engine.operator_user == "kain", "identidad dinamica Sector 0 -> 'kain'")
	SceneParams.reset()
	ctx_heist.free()

	var prof := ProfileClass.new()
	add_child(prof)
	prof.player_name = "Laeoon Ops"
	prof._sync_shell_identity()
	_assert(prof._shell_engine.operator_user == "laeoon_ops" and prof._shell_engine.get_prompt_string().begins_with("laeoon_ops@boveda-lab:"),
		"Academia CLI usa alias sanitizado del jugador ('laeoon_ops@boveda-lab:')")
	_assert(prof._tab_built[0] == true and not prof._tab_built[1] and not prof._tab_built[2] and not prof._tab_built[3] and not prof._tab_built[4],
		"Profile construye solo pestaña 0 al iniciar (lazy tabs)")
	prof._set_active_tab(2)
	_assert(prof._tab_built[2] == true, "Profile construye pestaña 2 al seleccionarla")
	prof.queue_free()
