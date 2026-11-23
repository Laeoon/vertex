extends Node

## Headless verification for F2.1:
## - LevelLoaderV2 + LevelLaunchContext compiling *.level.json v2 (grid, symbolic NodeType, inline_graph)
## - Booting escena_juego.tscn cleanly from inline_graph without .tres
## - LevelSelectScreen 3-act support (ACTO I / II / III), dynamic level counts, and free_ops in LevelRegistry
## - GameRenderer.compute_edge_curve_points() curved Bézier overlay
## - [P] reveal_optimal_route() respecting runtime blocks and capping stars at 2

const LevelLoaderV2Class = preload("res://juego/system/level_loader_v2.gd")
const LevelLaunchContextClass = preload("res://juego/system/level_launch_context.gd")
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")
const LevelSelectClass = preload("res://juego/system/level_select_screen.gd")
const GameRendererClass = preload("res://juego/ataque/game_renderer.gd")
const NetworkGraphClass = preload("res://core/network/network_graph_resource.gd")
const NetworkNodeClass = preload("res://core/network/network_node_resource.gd")
const NetworkEdgeClass = preload("res://core/network/network_edge_resource.gd")
const JuegoAtaqueScene = preload("res://juego/ataque/escena_juego.tscn")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS: " + msg)
	else:
		_failed += 1
		push_error("FAIL: " + msg)


func _run_tests() -> void:
	print("--- START TEST F2.1 LOADER V2, 3 ACTS & CURVED [P] ---")

	await _test_v2_loader_and_inline_boot()
	_test_three_acts_and_free_ops()
	_test_curved_edge_and_route_penalty()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _test_v2_loader_and_inline_boot() -> void:
	var v2_raw: Dictionary = {
		"schema_version": 2,
		"id": "test_v2_dmz",
		"world": "heist",
		"act": 2,
		"order": 1,
		"meta": {
			"title": "Test V2 DMZ",
			"operator": "VEX",
			"is_golden_boss": true,
			"cinematic_intro": "act2_collision_teaser"
		},
		"rules": {
			"mode": "heist",
			"max_movement_points": 12,
			"max_turns": 10,
			"ia_predictiva": true,
			"ai_enabled": false
		},
		"layout": {"grid_cols": 5, "grid_rows": 3},
		"graph": {
			"start_node": "ENTRY",
			"target_node": "VAULT",
			"waypoints": ["BRIDGE"],
			"nodes": [
				{"id": "ENTRY", "type": "INTERNET", "grid": [0, 1], "display_name": "Gateway"},
				{"id": "BRIDGE", "type": "FIREWALL", "grid": [2, 1], "display_name": "Bridge"},
				{"id": "VAULT", "type": "DATABASE", "grid": [4, 1], "display_name": "Vault"}
			],
			"edges": [
				{"from": "ENTRY", "to": "BRIDGE", "cost": 2.0, "capacity": 2.0, "protocol": "TLS"},
				{"from": "BRIDGE", "to": "VAULT", "cost": 3.0, "capacity": 1.0, "protocol": "SSH"}
			]
		}
	}

	var ctx: LevelLaunchContextClass = LevelLoaderV2Class.build_launch_context(v2_raw)
	_assert(ctx != null and ctx.schema_version == 2, "LevelLoaderV2 construye LevelLaunchContext v2")
	_assert(ctx.is_golden_boss == true and ctx.act == 2, "LevelLaunchContext preserva is_golden_boss y act=2")
	_assert(ctx.inline_graph != null and ctx.inline_graph.validate().is_empty(), "inline_graph compilado desde v2 valida sin errores")
	_assert(ctx.inline_graph.get_node_by_id(&"ENTRY").node_type == NetworkNodeClass.NodeType.INTERNET, "Tipo simbólico 'INTERNET' resuelto correctamente")
	_assert(ctx.inline_graph.get_node_by_id(&"VAULT").node_type == NetworkNodeClass.NodeType.DATABASE, "Tipo simbólico 'DATABASE' resuelto correctamente")

	SceneParams.reset()
	SceneParams.apply_launch_context(ctx)
	var juego: Node = JuegoAtaqueScene.instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame

	_assert(juego.graph != null and juego.graph.node_count() == 3, "escena_juego bootea desde inline_graph v2 sin .tres externo")
	_assert(juego.player_pos == &"ENTRY" and juego.target_node == &"VAULT", "escena_juego inicia en ENTRY hacia VAULT")

	# Test [P] reveal_optimal_route & 2-star cap
	juego._game_logic.reveal_optimal_route()
	_assert(juego.show_optimal_overlay == true and juego.route_hint_used == true, "reveal_optimal_route activa overlay y marca route_hint_used")
	_assert(juego.optimal_overlay_path.size() == 2, "optimal_overlay_path calcula ruta al primer waypoint [ENTRY, BRIDGE]")

	var capped_stars: int = juego._progress_service.calculate_stars()
	_assert(capped_stars <= 2, "calculate_stars() topea a máximo 2★ cuando route_hint_used == true (got %d)" % capped_stars)

	# Block ENTRY->BRIDGE and verify refresh clears unreachable route
	juego._block_edge("ENTRY→BRIDGE", &"ENTRY", &"BRIDGE")
	juego._game_logic.refresh_optimal_overlay_path()
	_assert(juego.optimal_overlay_path.is_empty(), "refresh_optimal_overlay_path respeta bloqueos de runtime")

	juego.queue_free()
	SceneParams.reset()


func _test_three_acts_and_free_ops() -> void:
	_assert(LevelRegistryClass.WORLDS.has("free_ops"), "LevelRegistry.WORLDS incluye 'free_ops'")

	var ls := LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)

	var vp := Vector2(1356, 672)
	var r1: Rect2 = ls.get_act1_rect(vp)
	var r2: Rect2 = ls.get_act2_rect(vp)
	var r3: Rect2 = ls.get_act3_rect(vp)
	_assert(r1.size.x >= 175.0 and r2.size.x >= 175.0 and r3.size.x >= 175.0, "Pills ACTO I/II/III tienen ancho >= 175px")
	_assert(r2.position.x - (r1.position.x + r1.size.x) >= 16.0, "ACTO I y ACTO II separados >= 16px")
	_assert(r3.position.x - (r2.position.x + r2.size.x) >= 16.0, "ACTO II y ACTO III separados >= 16px")

	ls.set_act(3)
	_assert(ls.get_act() == 3, "set_act(3) cambia a ACTO III")

	var ev_tab := InputEventKey.new()
	ev_tab.pressed = true
	ev_tab.keycode = KEY_TAB
	ls._input(ev_tab)
	_assert(ls.get_act() == 1, "KEY_TAB cicla de ACTO III a ACTO I")

	# Dynamic act count != 5
	ls.level_nodes = [
		{"act": 1, "title": "A1-1"},
		{"act": 1, "title": "A1-2"},
		{"act": 2, "title": "A2-1"},
		{"act": 3, "title": "A3-1", "is_golden_boss": true},
	]
	ls.set_act(3)
	_assert(ls._get_current_act_levels().size() == 1, "Acto III dinámico con 1 nivel (sin techo fijo de 5)")
	_assert(ls._get_global_level_index(0) == 3, "_get_global_level_index(0) en Acto III apunta al índice global 3")
	_assert(ls.get_spine_node_pill_text(0).begins_with("BOSS // "), "is_golden_boss marca BOSS dinámicamente")

	ls.queue_free()


func _test_curved_edge_and_route_penalty() -> void:
	var renderer := GameRendererClass.new(null, null, 14, 20, 11, 10)
	var g := NetworkGraphClass.new()
	var n_a := NetworkNodeClass.new()
	n_a.id = &"A"
	var n_mid := NetworkNodeClass.new()
	n_mid.id = &"MID"
	var n_b := NetworkNodeClass.new()
	n_b.id = &"B"
	g.nodes = [n_a, n_mid, n_b]
	var e_ab := NetworkEdgeClass.new()
	e_ab.from_id = &"A"
	e_ab.to_id = &"B"
	g.edges = [e_ab]

	var positions_with_mid: Dictionary = {
		&"A": Vector2(100, 300),
		&"MID": Vector2(300, 300),
		&"B": Vector2(500, 300),
	}
	var curved_pts: PackedVector2Array = renderer.compute_edge_curve_points(&"A", &"B", positions_with_mid, 22.0, g)
	_assert(curved_pts.size() == 15, "compute_edge_curve_points genera curva Bézier de 15 puntos cuando un nodo intermedio bloquea la línea recta")

	var positions_clear: Dictionary = {
		&"A": Vector2(100, 300),
		&"B": Vector2(500, 300),
	}
	var straight_pts: PackedVector2Array = renderer.compute_edge_curve_points(&"A", &"B", positions_clear, 22.0, g)
	_assert(straight_pts.size() == 2, "compute_edge_curve_points genera segmento recto de 2 puntos cuando no hay obstáculo")
