extends Node

## Equivalencia conductual: ProgressService vs lógica original de progreso/estrellas
## (slice 5).
##
## Verifica que la extracción de `_calcular_estrellas` / `_guardar_progreso` /
## `_level_key` + stats tracking en `ProgressService`
## (juego/ataque/progress_service.gd) preserva la conducta observable.
##
## Dos partes:
##   Parte A — star count idéntico para el mismo estado de juego (movement_points
##     mode + cost_ratio mode).
##   Parte B — round-trip de archivo: save → lectura directa de ConfigFile con
##     las mismas claves/valores que el original.
##
## Como en slices 3–4, la prueba instancia `escena_juego.tscn` (autoloads) y
## opera sobre el juego real. Usa claves de test únicas para no interferir con
## progreso real del usuario.
##
## Prefijo `_` + `.tscn`: misma razón que `_test_ai_blocker_equivalence` y
## `_test_pursuit_system_equivalence` — `--script` no registra autoloads.

const GRAPH_PATH := "res://juego/tutorial3/tut3_red.tres"
const TEST_KEY_PREFIX := "_slice5_equiv_"

var passed: int = 0
var failed: int = 0
var _juego: Node2D


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	SceneParams.graph_path = GRAPH_PATH
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Servidor"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_ai_blocks = 0
	SceneParams.max_turns = 20
	SceneParams.max_movement_points = 0
	SceneParams.block_duration = 99
	SceneParams.defender_mode = false
	SceneParams.hacker_mode = false
	SceneParams.tutorial_path = ""
	SceneParams.titulo_nivel = "PROGRESS EQUIV TEST"
	SceneParams.pursuer_delay = 2
	SceneParams.max_pursuers = 4
	SceneParams.pursuer_speed = 1
	SceneParams.level_key = TEST_KEY_PREFIX + "main"

	var scene := load("res://juego/ataque/escena_juego.tscn") as PackedScene
	_juego = scene.instantiate()
	get_tree().root.add_child(_juego)
	await get_tree().process_frame
	await get_tree().process_frame

	if _juego == null or not is_instance_valid(_juego) or _juego.graph == null:
		print("FAIL: escena_juego o grafo no cargaron")
		failed += 1
		_quit()
		return

	_parte_a_star_count_equivalence()
	_parte_b_save_roundtrip()

	_quit()


# ── Parte A: star count idéntico ─────────────────────────────────────

func _parte_a_star_count_equivalence() -> void:
	# Escenario 1: movement_points mode (max_movement_points > 0)
	_juego.max_movement_points = 100
	_juego.movement_points = 60  # ratio=0.6 → 3 stars
	var ps_stars_1: int = _juego._progress_service.calculate_stars()
	var orig_stars_1: int = _juego._calcular_estrellas()
	_assert_eq("A.1a stars (mp=60/100)", ps_stars_1, orig_stars_1)
	_assert_eq("A.1b value", ps_stars_1, 3)

	_juego.movement_points = 30  # ratio=0.3 → 2 stars
	var ps_stars_2: int = _juego._progress_service.calculate_stars()
	var orig_stars_2: int = _juego._calcular_estrellas()
	_assert_eq("A.2a stars (mp=30/100)", ps_stars_2, orig_stars_2)
	_assert_eq("A.2b value", ps_stars_2, 2)

	_juego.movement_points = 10  # ratio=0.1 → 1 star
	var ps_stars_3: int = _juego._progress_service.calculate_stars()
	var orig_stars_3: int = _juego._calcular_estrellas()
	_assert_eq("A.3a stars (mp=10/100)", ps_stars_3, orig_stars_3)
	_assert_eq("A.3b value", ps_stars_3, 1)

	# Escenario 2: cost_ratio mode (max_movement_points = 0)
	_juego.max_movement_points = 0
	_juego.player_total_cost = 10.0
	_juego.turn = 5
	_juego.max_turns = 20
	_juego.waypoints = []
	_juego.start_node = &"Inicio"
	_juego.target_node = &"Servidor"
	var ps_stars_4: int = _juego._progress_service.calculate_stars()
	var orig_stars_4: int = _juego._calcular_estrellas()
	_assert_eq("A.4a stars (cost mode)", ps_stars_4, orig_stars_4)
	# El valor exacto depende del coste óptimo del grafo — lo importante es
	# que ambos cálculos coincidan.


# ── Parte B: round-trip de archivo ────────────────────────────────────

func _parte_b_save_roundtrip() -> void:
	var test_key := TEST_KEY_PREFIX + "save"

	# Limpiar estado para la prueba
	_juego.max_movement_points = 0
	_juego.player_total_cost = 5.0
	_juego.turn = 3
	_juego.max_turns = 10
	_juego.level_key = test_key
	_juego.mensaje_estado = ""

	# Guardar via ProgressService
	_juego._progress_service.save(3)

	# Leer directamente del ConfigFile para verificar claves
	var cfg := ConfigFile.new()
	var err: int = cfg.load("user://progress.cfg")
	_assert_eq("B.1 load err", err, OK)

	var saved_stars: int = cfg.get_value("estrellas", test_key, 0)
	_assert_eq("B.2 stars saved", saved_stars, 3)

	var saved_cost: float = cfg.get_value("estrellas", test_key + "_mejor_coste", 0.0)
	_assert_eq("B.3 cost saved", saved_cost, 5.0)

	# Verificar stats de victoria
	var stats_cfg := ConfigFile.new()
	stats_cfg.load("user://stats.cfg")
	var level_wins: int = stats_cfg.get_value("levels", test_key + "_wins", 0)
	_assert_eq("B.4 level wins", level_wins, 1)

	# Guardar con menos estrellas — NO debe sobrescribir
	_juego.player_total_cost = 10.0
	_juego._progress_service.save(1)
	cfg = ConfigFile.new()
	cfg.load("user://progress.cfg")
	var after_lower: int = cfg.get_value("estrellas", test_key, 0)
	_assert_eq("B.5 no overwrite with lower", after_lower, 3)

	# Guardar con las mismas estrellas — NO sobrescribe (original: solo si > prev)
	_juego.player_total_cost = 3.0
	_juego._progress_service.save(3)
	cfg = ConfigFile.new()
	cfg.load("user://progress.cfg")
	var after_same: int = cfg.get_value("estrellas", test_key, 0)
	_assert_eq("B.6 no overwrite same stars", after_same, 3)
	var after_same_cost: float = cfg.get_value("estrellas", test_key + "_mejor_coste", 0.0)
	_assert_eq("B.7 cost unchanged (same stars)", after_same_cost, 5.0)

	# Verificar record_loss
	_juego._progress_service.record_loss()
	stats_cfg = ConfigFile.new()
	stats_cfg.load("user://stats.cfg")
	var level_losses: int = stats_cfg.get_value("levels", test_key + "_losses", 0)
	_assert_eq("B.8 level losses", level_losses, 1)

	# Verificar load_all (via class from preload — autoloads available in scene)
	var ps_class = preload("res://juego/ataque/progress_service.gd")
	var all_progress: Dictionary = ps_class.load_all()
	var has_key: bool = all_progress.has(test_key)
	_assert_eq("B.9 load_all has key", has_key, true)
	if has_key:
		_assert_eq("B.10 load_all value", all_progress[test_key], 3)

	# Limpiar datos de test del archivo
	_cleanup_test_data(test_key)


func _cleanup_test_data(test_key: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://progress.cfg")
	cfg.erase_section_key("estrellas", test_key)
	cfg.erase_section_key("estrellas", test_key + "_mejor_coste")
	cfg.save("user://progress.cfg")

	var stats_cfg := ConfigFile.new()
	stats_cfg.load("user://stats.cfg")
	stats_cfg.erase_section_key("levels", test_key + "_wins")
	stats_cfg.erase_section_key("levels", test_key + "_losses")
	stats_cfg.save("user://stats.cfg")


# ─── helpers ────────────────────────────────────────────────────────

func _assert_eq(label: String, got, want) -> void:
	if got == want:
		print("PASS %s" % label)
		passed += 1
	else:
		print("FAIL %s: got=%s want=%s" % [label, str(got), str(want)])
		failed += 1


func _quit() -> void:
	if _juego != null and is_instance_valid(_juego):
		_juego.queue_free()
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if failed == 0 else 1)
