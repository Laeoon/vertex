extends Node

## Equivalence test (golden) del circuito de render por datos (slice 4):
## GameState.frame_data() → GameRenderer.draw_frame().
##
## Congela:
##   1. Golden data-level de frame_data() en modo atacante (claves elegidas:
##      objetivo, vecinos, bloqueos, defaults de brain_*, estrellas, ruta) y
##      su delta al bloquear una arista (blocked_keys).
##   2. Golden data-level de frame_data() en modo defensor (valores brain_*
##      tomados del DefenderBrain tras bloquear 1 arista).
##   3. Smoke de draw_frame() vía notification(NOTIFICATION_DRAW) — en
##      headless _draw no se dispara solo; la notificación es la vía legal
##      para ejecutar los draw_* sin "Drawing is only allowed inside _draw()".
##      Cubre: base, overlay [P], game_over (atacante) y HUD defensor + win.
##
## Corre como escena (autoloads: SceneParams, Events, GameLogger). Patrón de
## los demás equivalence: CAPTURE=true para capturar el golden, luego false.
##
## Invocación:
##     godot --headless res://tests/ataque/_test_game_renderer_equivalence.tscn

const CAPTURE := false
const VP := Vector2(1280.0, 720.0)

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# ── Modo atacante (tut2_red, IA off, determinista) ──
	SceneParams.graph_path = "res://juego/tutorial2/tut2_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = [&"Puerta_A"]
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.max_ai_blocks = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_turns = 0
	SceneParams.max_movement_points = 0
	SceneParams.titulo_nivel = "RENDERER GOLDEN"

	var ja = load("res://juego/ataque/escena_juego.tscn").instantiate()
	get_tree().root.add_child(ja)
	await get_tree().process_frame
	await get_tree().process_frame
	if ja.graph == null:
		print("FAIL: graph no cargo (atacante)")
		failed += 1
		_fin()
		return

	var snap: Array[String] = []
	var d: Dictionary = ja._game_state.frame_data(VP)
	snap.append("atk|def=%s|pos=%s|target=%s|vecinos=%s|ruta=%s" % [
		str(d.defender_mode), d.player_pos, d.target, str(d.neighbors), str(d.current_path)])
	snap.append("atk|sel=%s|bloq=%d|stars=%d|overlay=%s|tut=%s" % [
		d.selected_neighbor, d.blocked_keys.size(), d.stars,
		str(d.show_optimal_overlay), str(d.tutorial_player)])
	snap.append("atk|brain_defaults=%s/%s/%s/%s/%s" % [
		d.brain_blocks_placed, d.brain_blocks_per_turn, d.brain_enemy_pos,
		d.brain_enemy_target, d.brain_firewall_mode])

	# Bloquear una arista real → blocked_keys la refleja
	ja._block_edge("Inicio→Puerta_A", &"Inicio", &"Puerta_A")
	var d2: Dictionary = ja._game_state.frame_data(VP)
	snap.append("atk_bloq|bloq=%d|tiene=%s|blocked_edges=%d" % [
		d2.blocked_keys.size(), str(d2.blocked_keys.has("Inicio→Puerta_A")),
		d2.blocked_edges.size()])

	# Smoke draw_frame: base, overlay [P], game_over con panel de info activo
	ja.notification(CanvasItem.NOTIFICATION_DRAW)
	ja._on_toggle_optimal_route()
	ja.notification(CanvasItem.NOTIFICATION_DRAW)
	snap.append("atk_smoke|overlay=%s" % str(ja.show_optimal_overlay))
	ja._game_logic.perder("renderer golden")
	ja.notification(CanvasItem.NOTIFICATION_DRAW)
	snap.append("atk_smoke|over=%s|won=%s" % [str(ja.game_over), str(ja.game_won)])
	ja.queue_free()
	await get_tree().process_frame

	# ── Modo defensor (defense_n1) ──
	SceneParams.graph_path = "res://juego/defense/defense_n1.tres"
	SceneParams.start_node = &"Internet"
	SceneParams.target_node = &"DataCenter"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.max_turns = 12
	SceneParams.titulo_nivel = "RENDERER GOLDEN DEF"
	SceneParams.defender_mode = true
	SceneParams.defender_blocks_per_turn = 2
	SceneParams.defender_block_duration = 4
	SceneParams.enemy_start_node = &"Internet"
	SceneParams.enemy_target_node = &"DataCenter"

	var jd = load("res://juego/ataque/escena_juego.tscn").instantiate()
	get_tree().root.add_child(jd)
	await get_tree().process_frame
	await get_tree().process_frame
	if not jd.defender_mode or jd._defender_brain == null:
		print("FAIL: no booteó en modo defensor")
		failed += 1
		_fin()
		return

	jd._on_defender_block_edge("Internet→Proxy")
	jd._on_defender_resolve_turn()
	var dd: Dictionary = jd._game_state.frame_data(VP)
	snap.append("def|def=%s|placed=%d|enemy=%s|target=%s|bloq=%d" % [
		str(dd.defender_mode), dd.brain_blocks_placed, dd.brain_enemy_pos,
		dd.brain_enemy_target, dd.blocked_keys.size()])
	snap.append("def|enemy_path_len=%d|fw_mode=%s|min_cut=%s|stars=%s" % [
		dd.brain_enemy_path.size(), str(dd.brain_firewall_mode),
		str(dd.brain_min_cut.is_empty()), str(dd.stars)])
	jd.notification(CanvasItem.NOTIFICATION_DRAW)
	jd._on_brain_defender_won("golden", 3)
	jd.notification(CanvasItem.NOTIFICATION_DRAW)
	snap.append("def_smoke|over=%s|won=%s" % [str(jd.game_over), str(jd.game_won)])
	jd.queue_free()

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_fin()
		return

	var golden: Array[String] = [
		"atk|def=false|pos=Inicio|target=Puerta_A|vecinos=[&\"Puerta_A\", &\"Puerta_B\"]|ruta=[&\"Inicio\", &\"Puerta_A\"]",
		"atk|sel=Puerta_A|bloq=0|stars=3|overlay=false|tut=<null>",
		"atk|brain_defaults=0/0///false",
		"atk_bloq|bloq=1|tiene=true|blocked_edges=1",
		"atk_smoke|overlay=true",
		"atk_smoke|over=true|won=false",
		"def|def=true|placed=0|enemy=FirewallExt|target=DataCenter|bloq=1",
		"def|enemy_path_len=4|fw_mode=false|min_cut=false|stars=3",
		"def_smoke|over=true|won=true",
	]

	if snap.size() != golden.size():
		print("FAIL: tamaño snapshot %d != golden %d" % [snap.size(), golden.size()])
		failed += 1
	for i in snap.size():
		if i < golden.size() and snap[i] == golden[i]:
			print("PASS: %s" % golden[i])
			passed += 1
		else:
			print("FAIL: got='%s' want='%s'" % [snap[i], golden[i] if i < golden.size() else "?"])
			failed += 1

	_fin()


func _fin() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
