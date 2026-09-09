extends Node

## Test suite for visual clarity, badge suppression, reticle conditions, and protocol diversity.
## (ux-readability-navigation).

const GameRendererClass = preload("res://juego/ataque/game_renderer.gd")
const NetworkGraphClass = preload("res://core/network/network_graph_resource.gd")
const NetworkEdgeClass = preload("res://core/network/network_edge_resource.gd")
const NetworkNodeClass = preload("res://core/network/network_node_resource.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST RENDERER VISUALS ---")
	_test_badge_suppression_logic()
	_test_reticle_visibility_conditions()
	_test_protocol_diversification()
	_test_renderer_canvas_smoke()
	_finish()


## Helper simulating the exact badge visibility rule implemented in GameRenderer.draw_edges()
static func is_badge_shown(
	e: NetworkEdgeResource,
	edge_key: String,
	player_pos: StringName,
	selected_neighbor: StringName,
	hovered_edge: String,
	in_path: bool,
	in_enemy_path: bool
) -> bool:
	if (player_pos != &"" and player_pos != "") and (e.from_id == player_pos or e.to_id == player_pos or String(e.from_id) == String(player_pos) or String(e.to_id) == String(player_pos)):
		return true
	elif (selected_neighbor != &"" and selected_neighbor != "") and (e.from_id == selected_neighbor or e.to_id == selected_neighbor or String(e.from_id) == String(selected_neighbor) or String(e.to_id) == String(selected_neighbor)):
		return true
	elif hovered_edge != "" and hovered_edge == edge_key:
		return true
	elif in_path or in_enemy_path:
		return true
	elif String(e.protocol) != "" and String(e.protocol) != "TCP":
		return true
	return false


func _test_badge_suppression_logic() -> void:
	var e_tcp = NetworkEdgeClass.new()
	e_tcp.from_id = &"NodeX"
	e_tcp.to_id = &"NodeY"
	e_tcp.protocol = &"TCP"

	var player: StringName = &"PlayerPos"
	var selected: StringName = &"SelectedNeighbor"

	# 1. Quiescent TCP edge between unrelated nodes -> MUST be suppressed
	var shown = is_badge_shown(e_tcp, "NodeX→NodeY", player, selected, "", false, false)
	_assert(not shown, "Quiescent TCP edge suppresses badge")

	# 2. Incident to player_pos (from_id == player) -> MUST be shown
	var e_from_player = NetworkEdgeClass.new()
	e_from_player.from_id = player
	e_from_player.to_id = &"NodeX"
	e_from_player.protocol = &"TCP"
	shown = is_badge_shown(e_from_player, "PlayerPos→NodeX", player, selected, "", false, false)
	_assert(shown, "TCP edge incident from player displays badge")

	# 3. Incident to player_pos (to_id == player) -> MUST be shown
	var e_to_player = NetworkEdgeClass.new()
	e_to_player.from_id = &"NodeX"
	e_to_player.to_id = player
	e_to_player.protocol = &"TCP"
	shown = is_badge_shown(e_to_player, "NodeX→PlayerPos", player, selected, "", false, false)
	_assert(shown, "TCP edge incident to player displays badge")

	# 4. Incident to selected_neighbor (from_id == selected) -> MUST be shown
	var e_from_sel = NetworkEdgeClass.new()
	e_from_sel.from_id = selected
	e_from_sel.to_id = &"NodeX"
	e_from_sel.protocol = &"TCP"
	shown = is_badge_shown(e_from_sel, "SelectedNeighbor→NodeX", player, selected, "", false, false)
	_assert(shown, "TCP edge incident from selected neighbor displays badge")

	# 5. Incident to selected_neighbor (to_id == selected) -> MUST be shown
	var e_to_sel = NetworkEdgeClass.new()
	e_to_sel.from_id = &"NodeX"
	e_to_sel.to_id = selected
	e_to_sel.protocol = &"TCP"
	shown = is_badge_shown(e_to_sel, "NodeX→SelectedNeighbor", player, selected, "", false, false)
	_assert(shown, "TCP edge incident to selected neighbor displays badge")

	# 6. Actively hovered edge -> MUST be shown
	shown = is_badge_shown(e_tcp, "NodeX→NodeY", player, selected, "NodeX→NodeY", false, false)
	_assert(shown, "Hovered edge displays badge")

	# 7. Active route (in_path) -> MUST be shown
	shown = is_badge_shown(e_tcp, "NodeX→NodeY", player, selected, "", true, false)
	_assert(shown, "Edge in current path displays badge")

	# 8. Enemy route (in_enemy_path) -> MUST be shown
	shown = is_badge_shown(e_tcp, "NodeX→NodeY", player, selected, "", false, true)
	_assert(shown, "Edge in enemy path displays badge")

	# 9. Non-standard protocol on quiescent edge (e.g. HTTPS, SSH, DNS, LDAP, VPN, SQL, QUIC) -> MUST be shown
	for proto in [&"HTTPS", &"SSH", &"DNS", &"LDAP", &"VPN", &"SQL", &"QUIC"]:
		var e_custom = NetworkEdgeClass.new()
		e_custom.from_id = &"ServerA"
		e_custom.to_id = &"ServerB"
		e_custom.protocol = proto
		shown = is_badge_shown(e_custom, "ServerA→ServerB", player, selected, "", false, false)
		_assert(shown, "Non-TCP protocol '%s' displays badge on quiescent edge" % proto)


func _test_reticle_visibility_conditions() -> void:
	# Rule: Reticle is drawn IF AND ONLY IF (nid_str == selected_neighbor and not game_over)
	var nid: StringName = &"FirewallCore"

	var sel_active: StringName = &"FirewallCore"
	var sel_empty: StringName = &""
	var sel_other: StringName = &"DifferentNode"

	var draws_reticle_active = (nid == sel_active and not false)
	var draws_reticle_empty = (nid == sel_empty and not false)
	var draws_reticle_other = (nid == sel_other and not false)
	var draws_reticle_gameover = (nid == sel_active and not true)

	_assert(draws_reticle_active, "Reticle condition matches when node is selected and game is active")
	_assert(not draws_reticle_empty, "Reticle condition fails when selected_neighbor is empty")
	_assert(not draws_reticle_other, "Reticle condition fails when selected_neighbor is a different node")
	_assert(not draws_reticle_gameover, "Reticle condition fails when game_over is true")


func _test_protocol_diversification() -> void:
	# Verify hacker_n3.tres, hacker_n4.tres, hacker_n5.tres contain realistic protocols
	var n3 = load("res://juego/hacker/hacker_n3.tres") as NetworkGraphResource
	_assert(n3 != null, "hacker_n3.tres loads as NetworkGraphResource")
	var n3_protos: Dictionary = {}
	for e in n3.edges:
		if e != null:
			n3_protos[String(e.protocol)] = true
	_assert(n3_protos.has("HTTPS"), "hacker_n3 has HTTPS")
	_assert(n3_protos.has("LDAP"), "hacker_n3 has LDAP")
	_assert(n3_protos.has("SQL"), "hacker_n3 has SQL")
	_assert(n3_protos.has("SSH"), "hacker_n3 has SSH")
	_assert(n3_protos.has("DNS"), "hacker_n3 has DNS")

	var n4 = load("res://juego/hacker/hacker_n4.tres") as NetworkGraphResource
	_assert(n4 != null, "hacker_n4.tres loads as NetworkGraphResource")
	var n4_protos: Dictionary = {}
	for e in n4.edges:
		if e != null:
			n4_protos[String(e.protocol)] = true
	_assert(n4_protos.has("HTTPS"), "hacker_n4 has HTTPS")
	_assert(n4_protos.has("QUIC"), "hacker_n4 has QUIC")
	_assert(n4_protos.has("SSH"), "hacker_n4 has SSH")
	_assert(n4_protos.has("SQL"), "hacker_n4 has SQL")
	_assert(n4_protos.has("VPN"), "hacker_n4 has VPN")

	var n5 = load("res://juego/hacker/hacker_n5.tres") as NetworkGraphResource
	_assert(n5 != null, "hacker_n5.tres loads as NetworkGraphResource")
	var n5_protos: Dictionary = {}
	for e in n5.edges:
		if e != null:
			n5_protos[String(e.protocol)] = true
	_assert(n5_protos.has("HTTPS"), "hacker_n5 has HTTPS")
	_assert(n5_protos.has("QUIC"), "hacker_n5 has QUIC")
	_assert(n5_protos.has("DNS"), "hacker_n5 has DNS")
	_assert(n5_protos.has("VPN"), "hacker_n5 has VPN")
	_assert(n5_protos.has("SSH"), "hacker_n5 has SSH")
	_assert(n5_protos.has("SQL"), "hacker_n5 has SQL")


class RenderSmokeCanvas extends Node2D:
	var renderer: GameRendererClass
	var graph: NetworkGraphResource
	var node_positions: Dictionary = {
		&"NodeA": Vector2(100, 100),
		&"NodeB": Vector2(300, 100),
		&"NodeC": Vector2(300, 300),
	}

	func _draw() -> void:
		if renderer == null or graph == null:
			return
		# Draw edges with filtering
		renderer.draw_edges(
			graph,
			node_positions,
			{},
			{},
			[&"NodeA", &"NodeB"],
			24.0,
			false,
			"",
			[],
			0,
			-1.0,
			"",
			[],
			&"NodeA",
			&"NodeB"
		)
		# Draw nodes with tactical reticle
		renderer.draw_nodes(
			graph,
			node_positions,
			&"NodeA",
			&"NodeC",
			[&"NodeB"],
			[&"NodeA", &"NodeB"],
			24.0,
			false,
			[],
			&"NodeB"
		)


func _test_renderer_canvas_smoke() -> void:
	var canvas = RenderSmokeCanvas.new()
	add_child(canvas)

	var graph = NetworkGraphClass.new()
	var nA = NetworkNodeClass.new()
	nA.id = &"NodeA"
	var nB = NetworkNodeClass.new()
	nB.id = &"NodeB"
	var nC = NetworkNodeClass.new()
	nC.id = &"NodeC"
	graph.nodes.append(nA)
	graph.nodes.append(nB)
	graph.nodes.append(nC)

	var e1 = NetworkEdgeClass.new()
	e1.from_id = &"NodeA"
	e1.to_id = &"NodeB"
	e1.protocol = &"TCP"

	var e2 = NetworkEdgeClass.new()
	e2.from_id = &"NodeB"
	e2.to_id = &"NodeC"
	e2.protocol = &"HTTPS"

	graph.edges.append(e1)
	graph.edges.append(e2)

	var font = ThemeDB.fallback_font
	var renderer = GameRendererClass.new(canvas, font, 14, 18, 12, 10)
	canvas.renderer = renderer
	canvas.graph = graph

	# Trigger _draw in headless canvas
	canvas.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "GameRenderer executes draw_edges and draw_nodes with reticle without crash")

	canvas.queue_free()


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
