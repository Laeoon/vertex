extends Node

## Test Suite: Tactical Terminal VFS & UnixShellEngine Features
## Tests UnixShellEngine pipes (|), grep, ps, chmod, base64 -d, find, and Terminal Academy.

const TerminalVFSClass = preload("res://juego/ui/terminal_vfs.gd")
const TerminalOverlayClass = preload("res://juego/ui/terminal_overlay.gd")
const UnixShellEngineClass = preload("res://juego/system/unix_shell_engine.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST UNIX SHELL ENGINE & TERMINAL ACADEMY ---")
	_test_vfs_navigation_and_permissions()
	_test_unix_shell_engine_features()
	_test_terminal_overlay_integration()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("TEST FAILED")
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func _test_vfs_navigation_and_permissions() -> void:
	var vfs := TerminalVFSClass.new()
	_assert(vfs.current_path == "/home/operator", "Ruta inicial es /home/operator")

	var res_ls := vfs.ls()
	_assert(res_ls.get("success", false), "ls() en directorio inicial exitoso")
	var items: Array = res_ls.get("items", [])
	_assert("readme.txt" in items, "readme.txt visible en /home/operator")

	var res_cat := vfs.cat("readme.txt")
	_assert(res_cat.get("success", false) and res_cat.get("content", "").find("GUÍA") != -1, "cat readme.txt lee contenido correcto")

	vfs.is_root = true
	var res_cd_sec := vfs.cd("/secrets")
	_assert(res_cd_sec.get("success", false) and vfs.current_path == "/secrets", "cd /secrets permitido con root")


func _test_unix_shell_engine_features() -> void:
	var engine := UnixShellEngineClass.new()

	# 1. Pipe test: cat auth.log | grep FAIL
	var pipe_out := engine.execute_command_line("cat /var/log/siem/auth.log | grep FAIL")
	_assert(pipe_out.find("ERROR") != -1 and pipe_out.find("FAIL") != -1, "Pipe cat | grep FAIL filtra registros de error correctamente (got: %s)" % pipe_out)

	# 2. Grep con -i y -n
	var grep_out := engine.execute_command_line("grep -i -n breach /var/log/siem/auth.log")
	_assert(grep_out.find("5:") != -1 or grep_out.find("breach") != -1, "grep -i -n encuentra coincidencias con número de línea (got: %s)" % grep_out)

	# 3. Base64 decode test
	var b64_out := engine.execute_command_line("base64 -d /srv/vault_shamir/shard_manifest.b64")
	_assert(b64_out.find("Sector 0") != -1, "base64 -d decodifica lore de Shamir correctamente (got: %s)" % b64_out)

	# 4. Ps y Kill test
	var ps_out := engine.execute_command_line("ps aux")
	_assert(ps_out.find("kain_daemon") != -1, "ps aux lista procesos del sistema incluyendo kain_daemon")

	var kill_out := engine.execute_command_line("kill 108")
	_assert(kill_out.find("terminado") != -1, "kill termina proceso PID 108 exitosamente")

	# 5. Chmod test
	var chmod_out := engine.execute_command_line("chmod 755 /etc/bgp/bgpd.conf")
	_assert(chmod_out.find("cambiado") != -1, "chmod modifica permisos correctamente")

	# 6. Terminal Academy modules test
	var modules := engine.get_academy_modules()
	_assert(modules.size() == 4, "Terminal Academy expone exactamente 4 módulos de práctica")
	var step_ok := engine.check_academy_step(2, "cat /var/log/siem/auth.log | grep FAIL", pipe_out)
	_assert(step_ok, "Validación de paso de Academia de Terminal funciona correctamente")


func _test_terminal_overlay_integration() -> void:
	var term := TerminalOverlayClass.new()
	add_child(term)
	term.open()
	_assert(term.is_terminal_open, "Terminal overlay abre correctamente")

	term._input_text = "pwd"
	term._handle_enter_pressed()
	var last_line: String = term._output_lines[term._output_lines.size() - 1]
	_assert(last_line == "/home/operator", "pwd imprime /home/operator en overlay")

	term.close()
	term.queue_free()
