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
	var reset_pan_zoom_called: bool = false
	var zoom_in_called: bool = false
	var zoom_out_called: bool = false
	var pan_by_called: Vector2 = Vector2.ZERO

	func get_viewport_rect() -> Rect2:
		return Rect2(0, 0, 1280, 720)

	func reset_pan_zoom() -> void:
		reset_pan_zoom_called = true

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
	_test_hacker_dock_mouse_and_touch()
	_test_attacker_dock_confirm_and_camera()
	_test_defender_pills_and_contextual_menu()
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

	# Click en Pill [2] FIREWALL superior: Rect2(340, 4, 115, 38) -> centro Vector2(390, 20)
	var ev_pill_fw = InputEventMouseButton.new()
	ev_pill_fw.button_index = MOUSE_BUTTON_LEFT
	ev_pill_fw.pressed = true
	ev_pill_fw.position = Vector2(390.0, 20.0)
	handler._input(ev_pill_fw)
	_assert(fw_toggled.size() == 1, "Click en Pill [2] FIREWALL superior activa modo firewall")

	# Click en Pill [3] CUARENTENA superior: Rect2(460, 4, 135, 38) -> centro Vector2(520, 20)
	var ev_pill_q = InputEventMouseButton.new()
	ev_pill_q.button_index = MOUSE_BUTTON_LEFT
	ev_pill_q.pressed = true
	ev_pill_q.position = Vector2(520.0, 20.0)
	handler._input(ev_pill_q)
	_assert(q_toggled.size() == 1, "Click en Pill [3] CUARENTENA superior activa modo cuarentena")

	# Click en Pill [4] RADAR superior: Rect2(600, 4, 110, 38) -> centro Vector2(650, 20)
	var ev_pill_r = InputEventMouseButton.new()
	ev_pill_r.button_index = MOUSE_BUTTON_LEFT
	ev_pill_r.pressed = true
	ev_pill_r.position = Vector2(650.0, 20.0)
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
