extends Node

## Test suite for Spatial Node Navigation (ux-readability-navigation).
## Tests:
## - select_neighbor_directional() with cardinal directions
## - Angular dot-product threshold (> 0.2)
## - Isolated node (empty neighbors)
## - Sequential Tab fallback (cycle_neighbor)
## - InputHandler key mappings and mouse hover targeting

const GameLogicClass = preload("res://juego/ataque/game_logic.gd")
const InputHandlerClass = preload("res://juego/ataque/input_handler.gd")

var passed: int = 0
var failed: int = 0


class FakeRuntime extends RefCounted:
	var neighbors_map: Dictionary = {}

	func get_neighbors(from_id: StringName) -> Array:
		return neighbors_map.get(from_id, [])


class FakeGame extends Node:
	var player_pos: StringName = &"Center"
	var selected_neighbor: StringName = &""
	var node_positions: Dictionary = {}
	var hidden_nodes: Array = []
	var hacker_mode: bool = false
	var game_over: bool = false
	var defender_mode: bool = false
	var runtime: FakeRuntime = FakeRuntime.new()
	var redraw_count: int = 0
	var current_path: Array = []

	func _is_blocked(_edge_key: String) -> bool:
		return false

	func queue_redraw() -> void:
		redraw_count += 1

	func _nodo_en_posicion(pos: Vector2) -> StringName:
		for nid in node_positions.keys():
			var npos: Vector2 = node_positions[nid]
			if pos.distance_to(npos) <= 24.0:
				return nid
		return &""

	func _vecinos_jugador() -> Array:
		var res: Array[StringName] = []
		for n in runtime.get_neighbors(player_pos):
			res.append(n["to_id"])
		return res


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST SPATIAL NAVIGATION ---")
	_test_cardinal_directions()
	_test_angular_threshold()
	_test_isolated_node()
	_test_tab_fallback()
	_test_input_handler_keys()
	_test_input_handler_mouse_hover()
	_finish()


func _test_cardinal_directions() -> void:
	var game = FakeGame.new()
	var logic = GameLogicClass.new()
	logic.setup(game)

	game.player_pos = &"Center"
	game.node_positions = {
		&"Center": Vector2(200, 200),
		&"North": Vector2(200, 100),
		&"East": Vector2(300, 200),
		&"South": Vector2(200, 300),
		&"West": Vector2(100, 200),
	}
	game.runtime.neighbors_map[&"Center"] = [
		{"to_id": &"North"},
		{"to_id": &"East"},
		{"to_id": &"South"},
		{"to_id": &"West"},
	]

	# Test UP
	logic.select_neighbor_directional(Vector2.UP)
	_assert(game.selected_neighbor == &"North", "Directional UP selects North (got %s)" % game.selected_neighbor)

	# Test RIGHT
	logic.select_neighbor_directional(Vector2.RIGHT)
	_assert(game.selected_neighbor == &"East", "Directional RIGHT selects East (got %s)" % game.selected_neighbor)

	# Test DOWN
	logic.select_neighbor_directional(Vector2.DOWN)
	_assert(game.selected_neighbor == &"South", "Directional DOWN selects South (got %s)" % game.selected_neighbor)

	# Test LEFT
	logic.select_neighbor_directional(Vector2.LEFT)
	_assert(game.selected_neighbor == &"West", "Directional LEFT selects West (got %s)" % game.selected_neighbor)


func _test_angular_threshold() -> void:
	var game = FakeGame.new()
	var logic = GameLogicClass.new()
	logic.setup(game)

	game.player_pos = &"Center"
	game.node_positions = {
		&"Center": Vector2(200, 200),
		&"North": Vector2(200, 100),
	}
	game.runtime.neighbors_map[&"Center"] = [
		{"to_id": &"North"},
	]

	# Unset selection: when directional input does not match (dot <= 0.2), fallback to first neighbor
	game.selected_neighbor = &""
	logic.select_neighbor_directional(Vector2.DOWN)  # dot is -1.0 < 0.2
	_assert(game.selected_neighbor == &"North", "Unset selection falls back to first neighbor when dot <= 0.2")

	# Set selection: when directional input does not exceed threshold, selection is preserved
	game.selected_neighbor = &"North"
	logic.select_neighbor_directional(Vector2.DOWN)  # dot is -1.0 <= 0.2
	_assert(game.selected_neighbor == &"North", "Preserves existing selected_neighbor when dot <= 0.2")

	# Diagonal candidate matching (> 0.2)
	game.node_positions[&"NorthEast"] = Vector2(300, 100)
	game.runtime.neighbors_map[&"Center"].append({"to_id": &"NorthEast"})
	logic.select_neighbor_directional(Vector2.RIGHT)
	_assert(game.selected_neighbor == &"NorthEast", "Selects diagonal NorthEast for Vector2.RIGHT when dot ~0.707 > 0.2")


func _test_isolated_node() -> void:
	var game = FakeGame.new()
	var logic = GameLogicClass.new()
	logic.setup(game)

	game.player_pos = &"Isolated"
	game.node_positions = {
		&"Isolated": Vector2(100, 100),
	}
	game.runtime.neighbors_map[&"Isolated"] = []
	game.selected_neighbor = &"Stale"

	logic.select_neighbor_directional(Vector2.UP)
	_assert(game.selected_neighbor == &"", "Isolated node clears selected_neighbor to empty")


func _test_tab_fallback() -> void:
	var game = FakeGame.new()
	var logic = GameLogicClass.new()
	logic.setup(game)

	game.player_pos = &"Center"
	game.node_positions = {
		&"Center": Vector2(200, 200),
		&"N1": Vector2(200, 100),
		&"N2": Vector2(300, 200),
		&"N3": Vector2(200, 300),
	}
	game.runtime.neighbors_map[&"Center"] = [
		{"to_id": &"N1"},
		{"to_id": &"N2"},
		{"to_id": &"N3"},
	]

	# Sequential Tab cycling
	game.selected_neighbor = &"N1"
	logic.cycle_neighbor(1)
	_assert(game.selected_neighbor == &"N2", "cycle_neighbor(1) advances N1 -> N2")

	logic.cycle_neighbor(1)
	_assert(game.selected_neighbor == &"N3", "cycle_neighbor(1) advances N2 -> N3")

	logic.cycle_neighbor(1)
	_assert(game.selected_neighbor == &"N1", "cycle_neighbor(1) wraps around N3 -> N1")


func _test_input_handler_keys() -> void:
	var handler = InputHandlerClass.new()
	add_child(handler)

	var emitted_dirs: Array[Vector2] = []
	var cycle_counts: Array[int] = [0]
	handler.directional_neighbor_requested.connect(func(d: Vector2): emitted_dirs.append(d))
	handler.cycle_neighbor.connect(func(_step: int): cycle_counts[0] += 1)

	# UP / W
	var ev_up = InputEventKey.new()
	ev_up.keycode = KEY_UP
	ev_up.pressed = true
	handler._input(ev_up)

	var ev_w = InputEventKey.new()
	ev_w.keycode = KEY_W
	ev_w.pressed = true
	handler._input(ev_w)

	# DOWN / S
	var ev_down = InputEventKey.new()
	ev_down.keycode = KEY_DOWN
	ev_down.pressed = true
	handler._input(ev_down)

	var ev_s = InputEventKey.new()
	ev_s.keycode = KEY_S
	ev_s.pressed = true
	handler._input(ev_s)

	# LEFT / A
	var ev_left = InputEventKey.new()
	ev_left.keycode = KEY_LEFT
	ev_left.pressed = true
	handler._input(ev_left)

	var ev_a = InputEventKey.new()
	ev_a.keycode = KEY_A
	ev_a.pressed = true
	handler._input(ev_a)

	# RIGHT / D
	var ev_right = InputEventKey.new()
	ev_right.keycode = KEY_RIGHT
	ev_right.pressed = true
	handler._input(ev_right)

	var ev_d = InputEventKey.new()
	ev_d.keycode = KEY_D
	ev_d.pressed = true
	handler._input(ev_d)

	# TAB
	var ev_tab = InputEventKey.new()
	ev_tab.keycode = KEY_TAB
	ev_tab.pressed = true
	handler._input(ev_tab)

	_assert(emitted_dirs.size() == 8, "All 8 directional key inputs emitted directional signals (got %d)" % emitted_dirs.size())
	_assert(emitted_dirs[0] == Vector2.UP and emitted_dirs[1] == Vector2.UP, "KEY_UP and KEY_W emit Vector2.UP")
	_assert(emitted_dirs[2] == Vector2.DOWN and emitted_dirs[3] == Vector2.DOWN, "KEY_DOWN and KEY_S emit Vector2.DOWN")
	_assert(emitted_dirs[4] == Vector2.LEFT and emitted_dirs[5] == Vector2.LEFT, "KEY_LEFT and KEY_A emit Vector2.LEFT")
	_assert(emitted_dirs[6] == Vector2.RIGHT and emitted_dirs[7] == Vector2.RIGHT, "KEY_RIGHT and KEY_D emit Vector2.RIGHT")
	_assert(cycle_counts[0] == 1, "KEY_TAB emits cycle_neighbor fallback")

	handler.queue_free()


func _test_input_handler_mouse_hover() -> void:
	var game = FakeGame.new()
	game.player_pos = &"Player"
	game.node_positions = {
		&"Player": Vector2(100, 100),
		&"NeighborNode": Vector2(200, 100),
		&"DistantNode": Vector2(500, 500),
	}
	game.runtime.neighbors_map[&"Player"] = [
		{"to_id": &"NeighborNode"},
	]

	var handler = InputHandlerClass.new()
	add_child(handler)
	handler.game = game

	var hovered_nodes: Array[StringName] = []
	handler.neighbor_hovered.connect(func(nid: StringName): hovered_nodes.append(nid))

	# Hover over valid neighbor
	var ev_motion = InputEventMouseMotion.new()
	ev_motion.position = Vector2(200, 100)
	handler._input(ev_motion)

	_assert(hovered_nodes.size() == 1 and hovered_nodes[0] == &"NeighborNode", "Mouse motion over valid neighbor emits neighbor_hovered")
	_assert(handler.selected_neighbor == &"NeighborNode", "Handler updates selected_neighbor on hover")

	# Hover over distant non-neighbor node
	hovered_nodes.clear()
	ev_motion.position = Vector2(500, 500)
	handler._input(ev_motion)

	_assert(hovered_nodes.is_empty(), "Mouse motion over non-neighbor does not emit neighbor_hovered")

	handler.queue_free()


func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("PASS: %s" % msg)
		passed += 1
	else:
		print("FAIL: %s" % msg)
		failed += 1


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
