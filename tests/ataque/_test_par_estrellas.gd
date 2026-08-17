extends Node

## Test del sistema de par por nivel (slice 5): ProgressService.calculate_stars
## con par_turnos/par_coste en el JSON del nivel (estilo golf: en par = 3★;
## coste ≤1.5×par o turnos ≤1.25×par = 2★; más allá 1★) y fallback a la
## lógica legacy cuando el nivel no define par.
##
## Corre como escena (autoloads). Nivel: heist_n1 (par_turnos=6, par_coste=9).
##
## Invocación:
##     godot --headless res://tests/ataque/_test_par_estrellas.tscn

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	seed(42)
	SceneParams.reset()
	SceneParams.graph_path = "res://juego/nivel1/nivel1_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Boveda"
	SceneParams.waypoints = [&"Seguridad", &"Cajas"]
	SceneParams.ai_enabled = false
	SceneParams.max_turns = 15
	SceneParams.max_movement_points = 12
	SceneParams.titulo_nivel = "PAR TEST"
	SceneParams.level_key = "heist_n1"  # par_turnos=6, par_coste=9.0

	var juego = load("res://juego/ataque/escena_juego.tscn").instantiate()
	get_tree().root.add_child(juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if juego.graph == null:
		print("FAIL: graph no cargo")
		failed += 1
		_fin()
		return

	# ── En par exacto → 3★ ──
	juego.turn = 6
	juego.player_total_cost = 9.0
	_af(juego._progress_service.calculate_stars() == 3, "en par (6t/9c) → 3★")

	# ── Mejor que el par → 3★ ──
	juego.turn = 5
	juego.player_total_cost = 7.0
	_af(juego._progress_service.calculate_stars() == 3, "mejor que par (5t/7c) → 3★")

	# ── Coste por encima (1.44×) con turnos en par → 2★ ──
	juego.turn = 6
	juego.player_total_cost = 13.0
	_af(juego._progress_service.calculate_stars() == 2, "coste 1.44×par → 2★")

	# ── Coste 1.56× (>1.5) → 1★ ──
	juego.player_total_cost = 14.0
	_af(juego._progress_service.calculate_stars() == 1, "coste 1.56×par → 1★")

	# ── Turnos 1.17× (≤1.25) con coste en par → 2★ ──
	juego.turn = 7
	juego.player_total_cost = 9.0
	_af(juego._progress_service.calculate_stars() == 2, "turnos 1.17×par → 2★")

	# ── Turnos 1.33× (>1.25) → 1★ ──
	juego.turn = 8
	_af(juego._progress_service.calculate_stars() == 1, "turnos 1.33×par → 1★")

	# ── El presupuesto ya no define estrellas (sólo supervivencia) ──
	# movement_points bajísimo (0.01×) con turnos/coste en par sigue 3★:
	juego.turn = 6
	juego.player_total_cost = 9.0
	juego.movement_points = 0
	juego.max_movement_points = 12
	_af(juego._progress_service.calculate_stars() == 3,
		"presupuesto agotado no baja estrellas cuando el par se cumple")

	# ── Fallback: level_key sin par → lógica legacy (ratio de presupuesto) ──
	juego.level_key = "nivel_inexistente_sin_par"
	juego.movement_points = 12
	juego.max_movement_points = 12
	_af(juego._progress_service.calculate_stars() == 3,
		"sin par: legacy presupuesto (12/12 ≥ 0.5) → 3★")
	juego.movement_points = 2
	_af(juego._progress_service.calculate_stars() == 1,
		"sin par: legacy presupuesto (2/12 < 0.25) → 1★")

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
