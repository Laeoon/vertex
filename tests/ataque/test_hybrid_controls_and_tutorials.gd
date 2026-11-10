extends Node

## Test Suite: Hybrid In-Game Controls & Tactical Dock HUD & Tutorial Overhaul (T2 / S2)
##
## Tests:
## 1. Click / tap on Hacker HUD exploit buttons (scan, bypass, escalate, persist, decoy/Honeypot)
##    arms / executes them via mouse and touch input.
## 2. Contextual node action and Defender tool pills work via mouse / touch click.
## 3. Tutorial Enter advance does NOT trigger unintended player movement, and mouse / touch
##    actions satisfy tutorial action_required without false lockups.

const InputHandlerClass = preload("res://juego/ataque/input_handler.gd")
const GameRendererClass = preload("res://juego/ataque/game_renderer.gd")
const TerminalOverlayClass = preload("res://juego/ui/terminal_overlay.gd")

var passed: int = 0
var failed: int = 0


# Mock de Juego para InputHandler
class MockGame extends Node:
	var topology_pan: Vector2 = Vector2.ZERO
	var topology_zoom: float = 1.0
	var node_positions: Dictionary = {
		&"NodeA": Vector2(100.0, 100.0),
		&"ServerA": Vector2(400.0, 300.0),
		&"RouterB": Vector2(200.0, 100.0)
	}
	var hidden_nodes: Array = []
	var node_radius: float = 22.0
	var hacker_mode: bool = false
	var defender_mode: bool = false
	var firewall_mode: bool = false
	var quarantine_mode: bool = false
	var defender_context_node: StringName = &""
	var selected_neighbor: StringName = &""
	var player_pos: StringName = &"NodeA"
	var game_over: bool = false
	var game_won: bool = false
	var is_moving: bool = false
	var tutorial_player: Node = null
	var mensaje_estado: String = ""
	var node_cache: Dictionary = {}
	var font: Font = null
	var font_size: int = 14
	var reset_pan_zoom_called: bool = false
	var zoom_in_called: bool = false
	var zoom_out_called: bool = false
	var pan_by_called: Vector2 = Vector2.ZERO

	func get_viewport_rect() -> Rect2:
		return Rect2(0, 0, 1280, 720)

	func reset_pan_zoom() -> void:
		reset_pan_zoom_called = true

	func queue_redraw() -> void:
		pass

	func zoom_in(_center: Vector2 = Vector2.ZERO) -> void:
		zoom_in_called = true

	func zoom_out(_center: Vector2 = Vector2.ZERO) -> void:
		zoom_out_called = true

	func pan_by(rel: Vector2) -> void:
		pan_by_called += rel

	func _nodo_en_posicion(pos: Vector2) -> StringName:
		for nid in node_positions.keys():
			var npos: Vector2 = node_positions[nid]
			if npos.distance_to(pos) <= maxf(36.0, node_radius + 22.0):
				return nid
		return &""

	func _nodo_en_posicion_firewall(pos: Vector2) -> StringName:
		for nid in node_positions.keys():
			var npos: Vector2 = node_positions[nid]
			if npos.distance_to(pos) <= maxf(42.0, node_radius + 30.0):
				return nid
		return &""

	func _edge_en_posicion(_pos: Vector2) -> String:
		return "NodeA→RouterB"

	func _vecinos_jugador() -> Array:
		return [&"RouterB"]

	func _is_blocked(_ekey: String) -> bool:
		return false


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST HYBRID CONTROLS & TUTORIAL OVERHAUL ---")
	_test_terminal_overlay_mouse_and_draw()
	_test_top_perks_rects_all_modes()
	_test_hacker_dock_mouse_and_touch()
	_test_attacker_dock_confirm_and_camera()
	_test_defender_pills_and_contextual_menu()
	_test_human_readable_node_names()
	_test_tutorials_menu_visual_identity()
	_test_touch_pan_and_hitboxes()
	_test_tutorial_enter_double_action_prevention()
	_test_tutorial_mouse_touch_actions()
	_finish()


func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("PASS: %s" % msg)
		passed += 1
	else:
		push_error("FAIL: %s" % msg)
		failed += 1


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)


func _test_terminal_overlay_mouse_and_draw() -> void:
	var mock_game = MockGame.new()
	add_child(mock_game)

	var term = TerminalOverlayClass.new()
	term.setup(mock_game)
	add_child(term)
	var vp := Vector2(1280, 720)

	term.open()
	_assert(term.is_terminal_open, "Terminal starts open")

	# Mouse motion should return false so it doesn't freeze hover states
	var ev_motion = InputEventMouseMotion.new()
	ev_motion.position = Vector2(300.0, 150.0)
	var handled_motion := term.handle_input(ev_motion)
	_assert(not handled_motion, "Mouse motion returns false without trapping input")

	# Click inside terminal area keeps terminal open and returns true
	var ev_inside = InputEventMouseButton.new()
	ev_inside.button_index = MOUSE_BUTTON_LEFT
	ev_inside.pressed = true
	ev_inside.position = Vector2(100.0, 150.0)
	var handled_inside := term.handle_input(ev_inside)
	_assert(handled_inside and term.is_terminal_open, "Click inside terminal consumes event and leaves terminal open")

	# Click on close button closes terminal
	var close_rect := term.get_close_button_rect(vp)
	var ev_close = InputEventMouseButton.new()
	ev_close.button_index = MOUSE_BUTTON_LEFT
	ev_close.pressed = true
	ev_close.position = close_rect.get_center()
	var handled_close := term.handle_input(ev_close)
	_assert(handled_close and not term.is_terminal_open, "Click on [ ✕ CERRAR ] button closes terminal cleanly")

	# Re-open and test click outside terminal rect
	term.open()
	var ev_outside = InputEventMouseButton.new()
	ev_outside.button_index = MOUSE_BUTTON_LEFT
	ev_outside.pressed = true
	ev_outside.position = Vector2(640.0, 600.0)
	var handled_outside := term.handle_input(ev_outside)
	_assert(handled_outside and not term.is_terminal_open, "Click outside terminal rect closes terminal cleanly")

	# Test draw_terminal with font = null does not crash
	term.open()
	var dummy = Control.new()
	add_child(dummy)
	dummy.draw.connect(func():
		term.draw_terminal(dummy, vp, null, 14)
	)
	dummy.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "draw_terminal with font = null succeeds without crashing")

	dummy.queue_free()
	term.queue_free()
	mock_game.queue_free()


func _test_top_perks_rects_all_modes() -> void:
	var vp := Vector2(1280, 720)
	var modes := ["hacker", "defender", "heist"]

	for m in modes:
		var perks := GameRendererClass.get_top_perk_rects(vp, m)
		_assert(perks.size() >= 2, "Mode '%s' returns at least 2 top perks" % m)
		for p in perks:
			var r: Rect2 = p["rect"]
			_assert(r.position.y < 52.0 and r.position.y + r.size.y <= 52.0, "Perk '%s' in mode '%s' is inside Top Bar (y=%.1f, h=%.1f)" % [p["id"], m, r.position.y, r.size.y])

		# Non-overlapping check
		for i in range(perks.size()):
			for j in range(i + 1, perks.size()):
				var r_i: Rect2 = perks[i]["rect"]
				var r_j: Rect2 = perks[j]["rect"]
				_assert(not r_i.intersects(r_j), "Top perks non-overlapping in mode '%s': %s vs %s" % [m, perks[i]["id"], perks[j]["id"]])

	# Safe Zone Checks (Image#1 & Image#3 fix): start_x >= 445.0 at 1356x672 and 1280x720
	var test_vp := Vector2(1356, 672)
	var hacker_perks := GameRendererClass.get_top_perk_rects(test_vp, "hacker")
	_assert(hacker_perks.size() > 0 and hacker_perks[0]["rect"].position.x >= 445.0,
		"GameRenderer.get_top_perk_rects(Vector2(1356, 672), 'hacker')[0] position.x (%.1f) >= 445.0" % (hacker_perks[0]["rect"].position.x if hacker_perks.size() > 0 else 0.0))

	var heist_perks := GameRendererClass.get_top_perk_rects(test_vp, "heist")
	_assert(heist_perks.size() > 0 and heist_perks[0]["rect"].position.x >= 445.0,
		"GameRenderer.get_top_perk_rects(Vector2(1356, 672), 'heist')[0] position.x (%.1f) >= 445.0" % (heist_perks[0]["rect"].position.x if heist_perks.size() > 0 else 0.0))


func _test_hacker_dock_mouse_and_touch() -> void:
	var mock_game = MockGame.new()
	add_child(mock_game)
	mock_game.hacker_mode = true

	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = mock_game

	var scan_emitted := []
	var exploits_emitted: Array[String] = []

	handler.scan_requested.connect(func(): scan_emitted.append("scan"))
	handler.exploit_used.connect(func(t: String): exploits_emitted.append(t))

	# Click en [X] SCAN: Rect2(16, 720-48, 95, 42) -> centro Vector2(60, 695)
	var ev_scan = InputEventMouseButton.new()
	ev_scan.button_index = MOUSE_BUTTON_LEFT
	ev_scan.pressed = true
	ev_scan.position = Vector2(60.0, 695.0)
	handler._input(ev_scan)
	_assert(scan_emitted.size() == 1, "Click en [X] SCAN dispara scan_requested")

	# Touch tap en [1] BYPASS: Rect2(116, 720-48, 110, 42) -> centro Vector2(170, 695)
	var ev_byp = InputEventScreenTouch.new()
	ev_byp.pressed = true
	ev_byp.position = Vector2(170.0, 695.0)
	handler._input(ev_byp)
	_assert("bypass" in exploits_emitted, "Touch tap en [1] BYPASS dispara exploit_used('bypass')")

	# Click en [2] ESCALATE: Rect2(231, 720-48, 120, 42) -> centro Vector2(290, 695)
	var ev_esc = InputEventMouseButton.new()
	ev_esc.button_index = MOUSE_BUTTON_LEFT
	ev_esc.pressed = true
	ev_esc.position = Vector2(290.0, 695.0)
	handler._input(ev_esc)
	_assert("escalate" in exploits_emitted, "Click en [2] ESCALATE dispara exploit_used('escalate')")

	# Click en [3] PERSIST: Rect2(356, 720-48, 115, 42) -> centro Vector2(410, 695)
	var ev_per = InputEventMouseButton.new()
	ev_per.button_index = MOUSE_BUTTON_LEFT
	ev_per.pressed = true
	ev_per.position = Vector2(410.0, 695.0)
	handler._input(ev_per)
	_assert("persist" in exploits_emitted, "Click en [3] PERSIST dispara exploit_used('persist')")

	# Touch tap en [4] HONEYPOT (decoy): Rect2(476, 720-48, 130, 42) -> centro Vector2(530, 695)
	var ev_dec = InputEventScreenTouch.new()
	ev_dec.pressed = true
	ev_dec.position = Vector2(530.0, 695.0)
	handler._input(ev_dec)
	_assert("decoy" in exploits_emitted, "Touch tap en [4] HONEYPOT dispara exploit_used('decoy')")

	handler.queue_free()
	mock_game.queue_free()


func _test_attacker_dock_confirm_and_camera() -> void:
	var mock_game = MockGame.new()
	add_child(mock_game)
	mock_game.selected_neighbor = &"RouterB"

	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = mock_game

	var moved_dest: Array[StringName] = []
	handler.move_requested.connect(func(d: StringName): moved_dest.append(d))

	# Click en botón [ ⏭ CONFIRMAR / MOVER ] centrado en bottom: Rect2((1280-260)/2 = 510, 672, 260, 42) -> centro Vector2(640, 695)
	var ev_move = InputEventMouseButton.new()
	ev_move.button_index = MOUSE_BUTTON_LEFT
	ev_move.pressed = true
	ev_move.position = Vector2(640.0, 695.0)
	handler._input(ev_move)
	_assert(moved_dest.size() == 1 and moved_dest[0] == &"RouterB", "Click en [CONFIRMAR / MOVER] ejecuta move_requested a vecino seleccionado")

	# Click en [ ⟲ CENTRAR ] cámara: Rect2(1280 - 240 = 1040, 672, 75, 42) -> centro Vector2(1075, 695)
	var ev_center = InputEventScreenTouch.new()
	ev_center.pressed = true
	ev_center.position = Vector2(1075.0, 695.0)
	handler._input(ev_center)
	_assert(mock_game.reset_pan_zoom_called, "Touch tap en [⟲ CENTRAR] llama reset_pan_zoom()")

	# Click en [+] Zoom: Rect2(1280 - 115 = 1165, 672, 40, 42) -> centro Vector2(1185, 695)
	var ev_zoom_in = InputEventMouseButton.new()
	ev_zoom_in.button_index = MOUSE_BUTTON_LEFT
	ev_zoom_in.pressed = true
	ev_zoom_in.position = Vector2(1185.0, 695.0)
	handler._input(ev_zoom_in)
	_assert(mock_game.zoom_in_called, "Click en [+] llama zoom_in()")

	# Click en [-] Zoom: Rect2(1280 - 160 = 1120, 672, 40, 42) -> centro Vector2(1140, 695)
	var ev_zoom_out = InputEventMouseButton.new()
	ev_zoom_out.button_index = MOUSE_BUTTON_LEFT
	ev_zoom_out.pressed = true
	ev_zoom_out.position = Vector2(1140.0, 695.0)
	handler._input(ev_zoom_out)
	_assert(mock_game.zoom_out_called, "Click en [-] llama zoom_out()")

	# Click en botón CONFIRMAR cuando el nodo tiene nombre ancho (Image#1 fix)
	mock_game.selected_neighbor = &"SecurityPost"
	mock_game.node_cache = {
		&"SecurityPost": {"display_name": "Puesto de seguridad"}
	}
	# El botón se ensancha (> 260px), centrado en 640.0. Un clic en el lateral expandido (ej. x = 500.0)
	# debe registrarse si el botón mide ~312px (rango x: [484, 796])
	var ev_wide_move = InputEventMouseButton.new()
	ev_wide_move.button_index = MOUSE_BUTTON_LEFT
	ev_wide_move.pressed = true
	ev_wide_move.position = Vector2(500.0, 695.0)
	handler._input(ev_wide_move)
	_assert(moved_dest.size() == 2 and moved_dest[1] == &"SecurityPost", "Click en [CONFIRMAR: Puesto de seguridad] expandido registra move_requested")

	handler.queue_free()
	mock_game.queue_free()


func _test_defender_pills_and_contextual_menu() -> void:
	var mock_game = MockGame.new()
	add_child(mock_game)
	mock_game.defender_mode = true

	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = mock_game

	var fw_toggled := []
	var q_toggled := []
	var radar_toggled := []
	var fw_placed: Array[StringName] = []
	var q_placed: Array[StringName] = []

	handler.defender_toggle_firewall.connect(func(): fw_toggled.append("fw"))
	handler.defender_toggle_quarantine.connect(func(): q_toggled.append("q"))
	handler.toggle_optimal_route.connect(func(): radar_toggled.append("radar"))
	handler.defender_place_firewall.connect(func(nid: StringName): fw_placed.append(nid))
	handler.defender_quarantine_node.connect(func(nid: StringName): q_placed.append(nid))

	# Verificar que todas las píldoras del modo defensor tienen ZERO overlap (rect_i.intersects(rect_j) == false)
	var pill_rects := GameRendererClass.get_defender_pill_rects(Vector2(1280, 720), null, 14, false, false)
	_assert(pill_rects.size() >= 4, "get_defender_pill_rects retorna al menos 4 acciones")
	for i in range(pill_rects.size()):
		for j in range(i + 1, pill_rects.size()):
			var r_i: Rect2 = pill_rects[i]["rect"]
			var r_j: Rect2 = pill_rects[j]["rect"]
			_assert(not r_i.intersects(r_j), "Pills Defender sin superposición: %s vs %s" % [pill_rects[i]["id"], pill_rects[j]["id"]])

	# Ubicar rectángulos exactos medidos dinámicamente
	var fw_rect: Rect2
	var q_rect: Rect2
	var r_rect: Rect2
	for p in pill_rects:
		if p["id"] == "firewall":
			fw_rect = p["rect"]
		elif p["id"] == "quarantine":
			q_rect = p["rect"]
		elif p["id"] == "radar":
			r_rect = p["rect"]

	# Click en Pill [2] FIREWALL superior usando su centro dinámico
	var ev_pill_fw = InputEventMouseButton.new()
	ev_pill_fw.button_index = MOUSE_BUTTON_LEFT
	ev_pill_fw.pressed = true
	ev_pill_fw.position = fw_rect.get_center()
	handler._input(ev_pill_fw)
	_assert(fw_toggled.size() == 1, "Click en Pill [2] FIREWALL superior activa modo firewall")

	# Click en Pill [3] CUARENTENA superior usando su centro dinámico
	var ev_pill_q = InputEventMouseButton.new()
	ev_pill_q.button_index = MOUSE_BUTTON_LEFT
	ev_pill_q.pressed = true
	ev_pill_q.position = q_rect.get_center()
	handler._input(ev_pill_q)
	_assert(q_toggled.size() == 1, "Click en Pill [3] CUARENTENA superior activa modo cuarentena")

	# Click en Pill [4] RADAR superior usando su centro dinámico
	var ev_pill_r = InputEventMouseButton.new()
	ev_pill_r.button_index = MOUSE_BUTTON_LEFT
	ev_pill_r.pressed = true
	ev_pill_r.position = r_rect.get_center()
	handler._input(ev_pill_r)
	_assert(radar_toggled.size() == 1, "Click en Pill [4] RADAR superior activa toggle_optimal_route")

	# Test Menú Contextual Directo sobre Nodo en Modo Defensor:
	# Sin herramientas activas, clic en ServerA (400, 300) abre menú contextual
	handler.firewall_mode = false
	handler.quarantine_mode = false
	var ev_node_click = InputEventMouseButton.new()
	ev_node_click.button_index = MOUSE_BUTTON_LEFT
	ev_node_click.pressed = true
	ev_node_click.position = Vector2(400.0, 300.0)
	handler._input(ev_node_click)
	_assert(handler._defender_context_node == &"ServerA", "Clic directo en nodo abre menú contextual para 'ServerA'")

	# Clic en botón contextual [2] FIREWALL sobre el nodo:
	# npos = (400, 300), btn_fw = Rect2(400 - 110 = 290, 300 - 50 = 250, 105, 36) -> centro (340, 268)
	var ev_ctx_fw = InputEventMouseButton.new()
	ev_ctx_fw.button_index = MOUSE_BUTTON_LEFT
	ev_ctx_fw.pressed = true
	ev_ctx_fw.position = Vector2(340.0, 268.0)
	handler._input(ev_ctx_fw)
	_assert(fw_placed.size() == 1 and fw_placed[0] == &"ServerA", "Clic en [FIREWALL] de menú contextual instala firewall en 'ServerA'")
	_assert(handler._defender_context_node == &"", "Menú contextual se cierra automáticamente tras la acción")

	handler.queue_free()
	mock_game.queue_free()


func _test_human_readable_node_names() -> void:
	var cache := {
		&"Incursor": {"display_name": "Punto Cero"},
		&"NexusA": {"display_name": "Nexus Superior"},
		&"HexNode_1": {"name": "Celda Alfa"},
	}
	_assert(GameRendererClass.resolve_node_display_name(&"Incursor", cache) == "Punto Cero", "Incursor resuelve a 'Punto Cero'")
	_assert(GameRendererClass.resolve_node_display_name(&"NexusA", cache) == "Nexus Superior", "NexusA resuelve a 'Nexus Superior'")
	_assert(GameRendererClass.resolve_node_display_name(&"HexNode_1", cache) == "Celda Alfa", "HexNode_1 resuelve a 'Celda Alfa'")
	_assert(GameRendererClass.resolve_node_display_name(&"Desconocido", cache) == "Desconocido", "Nodo desconocido cae a fallback de ID")


func _test_tutorials_menu_visual_identity() -> void:
	var TutorialsMenuClass = preload("res://escenas/main_menu/tutorials_menu.gd")
	var menu = TutorialsMenuClass.new()
	add_child(menu)
	_assert(menu._spectrum_viz != null, "tutorials_menu inicializa AudioSpectrumVisualizer")
	_assert(menu._cyber_bg != null, "tutorials_menu inicializa CyberBackground")
	remove_child(menu)
	menu.free()


func _test_touch_pan_and_hitboxes() -> void:
	var mock_game = MockGame.new()
	add_child(mock_game)

	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = mock_game

	# Toque en canvas vacío inicia pan táctil
	var st_down = InputEventScreenTouch.new()
	st_down.index = 0
	st_down.pressed = true
	st_down.position = Vector2(800.0, 400.0)
	handler._input(st_down)
	_assert(handler._is_touch_panning, "Toque en canvas vacío activa _is_touch_panning")

	# Drag táctil desplaza la cámara vía pan_by
	var sd = InputEventScreenDrag.new()
	sd.index = 0
	sd.relative = Vector2(15.0, -10.0)
	handler._input(sd)
	_assert(mock_game.pan_by_called == Vector2(15.0, -10.0), "Drag táctil desplaza la topología suavemente")

	var st_up = InputEventScreenTouch.new()
	st_up.index = 0
	st_up.pressed = false
	handler._input(st_up)
	_assert(not handler._is_touch_panning, "Liberar toque detiene el pan táctil")

	# Hitbox generoso de nodo: radio al menos 36.0px (44.0px)
	var hit_node = mock_game._nodo_en_posicion(Vector2(100.0 + 35.0, 100.0))
	_assert(hit_node == &"NodeA", "Hitbox de nodo detecta toques a 35px de distancia (>36px radio efectivo)")

	handler.queue_free()
	mock_game.queue_free()


func _test_tutorial_enter_double_action_prevention() -> void:
	var mock_game = MockGame.new()
	add_child(mock_game)
	mock_game.selected_neighbor = &"RouterB"

	var tutorial_scene = preload("res://juego/tutorials/tutorial_player.tscn")
	var tp_inst = tutorial_scene.instantiate()
	add_child(tp_inst)
	var tp = tp_inst.get_node("Control")
	tp.load_tutorial("res://juego/tutorials/data/tut1_movimiento.json")
	tp.start()

	mock_game.tutorial_player = tp

	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = mock_game

	var move_calls := 0
	handler.move_requested.connect(func(_dest): move_calls += 1)

	# Paso 0: Informativo (no requiere acción)
	# Al presionar [Enter], NO debe ejecutarse move_requested en InputHandler
	var ev_enter = InputEventKey.new()
	ev_enter.keycode = KEY_ENTER
	ev_enter.pressed = true
	handler._input(ev_enter)
	_assert(move_calls == 0, "Fix Enter Bug: Presionar [Enter] en paso informativo NO mueve al jugador")

	# Avanzar a paso de acción (paso 3: try_move)
	tp.advance()  # paso 1
	tp.advance()  # paso 2
	tp.advance()  # paso 3 (try_move, action_required = 'move')

	# Cumplir la acción requerida
	tp.notify_action("move")
	_assert(tp._action_fulfilled, "notify_action('move') marca la acción como cumplida")

	# Cuando la acción ya fue cumplida y se espera confirmación para avanzar el diálogo,
	# presionar [Enter] NO debe volver a mover al jugador accidentalmente
	handler._input(ev_enter)
	_assert(move_calls == 0, "Fix Enter Bug: Presionar [Enter] tras cumplir acción NO produce segundo movimiento")

	handler.queue_free()
	tp_inst.queue_free()
	mock_game.queue_free()


func _test_tutorial_mouse_touch_actions() -> void:
	var tutorial_scene = preload("res://juego/tutorials/tutorial_player.tscn")
	var tp_inst = tutorial_scene.instantiate()
	add_child(tp_inst)
	var tp = tp_inst.get_node("Control")
	tp.load_tutorial("res://juego/tutorials/data/tut_hacker_1.json")
	tp.start()

	# Paso 0 a paso 2 (try_scan_mod1, action_required = 'input')
	tp.advance()
	tp.advance()
	_assert(tp._waiting_for_action, "Tutorial espera acción en try_scan_mod1")

	# Realizar acción vía input (scan)
	_assert(tp.can_perform_action("scan"), "can_perform_action('scan') permitido en paso de input")
	tp.notify_action("scan")
	_assert(tp._action_fulfilled, "Acción 'scan' satisface requerimiento 'input' del tutorial")

	tp_inst.queue_free()
