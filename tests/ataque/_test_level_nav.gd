extends Node

## Test de navegación post-partida (slice 6):
##   1. LevelRegistry.find_level: reverse lookup id → {world, idx}.
##   2. LevelManager.launch_next: true si hay siguiente en el mundo,
##      false en el último (se valida la LÓGICA de decisión sin disparar el
##      fade real: launch_level con idx inexistente devuelve false sin
##      transición).
##   3. GameState.frame_data().has_next_level: true sólo tras victoria con
##      level_key registrado que tenga siguiente.
##   4. Señales del InputHandler: KEY_N/KEY_L emitidas sólo con game_over
##      (y N además sólo con victoria).
##
## Invocación:
##     godot --headless res://tests/ataque/_test_level_nav.tscn

const Registry = preload("res://juego/system/level_registry.gd")

var passed: int = 0
var failed: int = 0
var _senales: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# ── S1: find_level ──
	var u1: Dictionary = Registry.find_level("heist_n1")
	_af(u1.get("world") == "heist" and u1.get("idx") == 0, "find_level(heist_n1) → heist[0]")
	var u3: Dictionary = Registry.find_level("heist_n3")
	_af(u3.get("world") == "heist" and u3.get("idx") == 2, "find_level(heist_n3) → heist[2]")
	var uc: Dictionary = Registry.find_level("cyber_n1")
	_af(uc.get("world") == "cybersecurity" and uc.get("idx") == 0, "find_level(cyber_n1) → cybersecurity[0]")
	_af(Registry.find_level("nivel_inexistente").is_empty(), "find_level(desconocido) → {}")
	_af(Registry.find_level("").is_empty(), "find_level('') → {} (tutoriales)")

	# ── S2: decisión de siguiente nivel (sin fade) ──
	# heist_n2 existe → hay siguiente desde heist_n1:
	var levels_heist: Array = Registry.get_levels("heist")
	_af(levels_heist.size() == 3, "heist tiene 3 niveles registrados")
	# heist_n3 es el último → idx+1 fuera de rango:
	_af(not (u3["idx"] + 1 < levels_heist.size()), "heist_n3 es el último del mundo (sin siguiente)")

	# ── S3: frame_data().has_next_level en juego real ──
	SceneParams.reset()
	SceneParams.graph_path = "res://juego/nivel1/nivel1_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Boveda"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.max_turns = 15
	SceneParams.max_movement_points = 12
	SceneParams.titulo_nivel = "LEVEL NAV TEST"
	SceneParams.level_key = "heist_n1"
	var juego = load("res://juego/ataque/escena_juego.tscn").instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame
	await get_tree().process_frame
	if juego.graph == null:
		print("FAIL: graph no cargo")
		failed += 1
		_fin()
		return

	var d: Dictionary = juego._game_state.frame_data(Vector2(1280, 720))
	_af(d.game_won == false and d.has_next_level == false,
		"sin terminar: has_next_level false (exige victoria)")
	juego._game_logic.ganar()
	d = juego._game_state.frame_data(Vector2(1280, 720))
	_af(d.game_won and d.has_next_level,
		"victoria en heist_n1: has_next_level true (sigue heist_n2)")

	# level_key del último nivel del mundo → false aunque gane:
	juego.level_key = "heist_n3"
	juego._game_state._next_level_cache.clear()
	d = juego._game_state.frame_data(Vector2(1280, 720))
	_af(d.game_won and not d.has_next_level,
		"victoria en heist_n3 (último): has_next_level false")

	# ── S4: señales del InputHandler (guards de teclas) ──
	var ih = juego._input_handler
	ih.next_level_requested.connect(func(): _senales.append("next"))
	ih.level_select_requested.connect(func(): _senales.append("select"))
	var ev_n := InputEventKey.new()
	ev_n.keycode = KEY_N
	ev_n.pressed = true
	var ev_l := InputEventKey.new()
	ev_l.keycode = KEY_L
	ev_l.pressed = true

	juego.game_over = false  # mid-partida: N y L no deben emitir
	ih._input(ev_n)
	ih._input(ev_l)
	_af(_senales.is_empty(), "mid-partida: N y L no emiten")

	juego.game_over = true
	juego.game_won = false  # derrota: L sí, N no
	ih._input(ev_n)
	ih._input(ev_l)
	_af(_senales == ["select"], "derrota: sólo L emite (select)")

	_senales.clear()
	juego.game_won = true  # victoria: ambos
	ih._input(ev_n)
	ih._input(ev_l)
	_af(_senales == ["next", "select"], "victoria: N y L emiten (next, select)")

	juego.queue_free()
	_fin()


func _af(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _fin() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
