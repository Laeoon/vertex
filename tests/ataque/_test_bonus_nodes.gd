extends Node

## Nodos bonus (E3): registro de visitas, piso de 3★ y marcador visual.
##
## Regla de diseño bajo prueba: visitar TODOS los bonus declarados garantiza
## 3★ como PISO sobre el cálculo por par/legacy (max(calculado, 3)); visitar
## sólo algunos deja las estrellas normales intactas.
##
## Escenarios (grafo tut2_red dirigido: Inicio→{Puerta_A,Puerta_B}→Target):
##   S1 — Pisar un nodo bonus lo registra y emite "DATO EXTRA n/m".
##   S2 — reset_state limpia bonus_visitados (el [R] no arrastraba visitas).
##   S3 — Todos visitados + coste inflado → 3★ pese a que el cálculo da 1★
##        (forzado de estado: player_total_cost alto, rama legacy).
##   S4 — Visita parcial → estrellas normales por coste (sin piso); sin
##        bonus declarados la regla es inerte.
##   S5 — Renderer: frame_data expone bonus_nodes/bonus_visitados y smoke
##        NOTIFICATION_DRAW con un bonus pendiente y otro visitado (patrón
##        de _test_game_renderer_equivalence).
##
## Por qué `_` prefijo + `.tscn`: instancia escena_juego.tscn, cuyo script
## raíz referencia autoloads; run_all.gd (--script) no los registra. Se corre:
##     godot --headless res://tests/ataque/_test_bonus_nodes.tscn

const TUT2 := "res://juego/tutorial2/tut2_red.tres"

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _s1_registro_y_mensaje()
	await _s2_reset_limpia_visitados()
	_s3_piso_tres_estrellas()
	_s4_parcial_sin_piso()
	await _s5_renderer_y_frame_data()
	_fin()


# ── Escenarios ──────────────────────────────────────────────────────────────

## S1: pisar Puerta_A lo agrega a bonus_visitados y emite DATO EXTRA 1/2.
## El mensaje sobrevive al resto del turno (detección 0, IA off, sin alarmas).
func _s1_registro_y_mensaje() -> void:
	var j := await _lanzar([&"Puerta_A", &"Puerta_B"])
	if j == null:
		return
	j._mover_jugador(&"Puerta_A")

	_af(j.player_pos == &"Puerta_A", "S1: jugador llegó a Puerta_A")
	_af(j.bonus_visitados == [&"Puerta_A"],
		"S1: Puerta_A registrada en bonus_visitados — got=%s" % str(j.bonus_visitados))
	_af(j.mensaje_estado == "DATO EXTRA 1/2",
		"S1: mensaje DATO EXTRA 1/2 — got='%s'" % j.mensaje_estado)
	j.queue_free()
	await get_tree().process_frame


## S2: tras reset_state las visitas vuelven a cero y un nodo ya visitado
## vuelve a emitir DATO EXTRA desde 1/2 (sin duplicados ni arrastre).
func _s2_reset_limpia_visitados() -> void:
	var j := await _lanzar([&"Puerta_A", &"Puerta_B"])
	if j == null:
		return
	j._mover_jugador(&"Puerta_A")
	_af(j.bonus_visitados.size() == 1, "S2: visita previa al reset")

	j.reset_state()
	_af(j.bonus_visitados.is_empty(),
		"S2: reset_state limpia bonus_visitados — got=%s" % str(j.bonus_visitados))

	j._mover_jugador(&"Puerta_A")
	_af(j.bonus_visitados == [&"Puerta_A"], "S2: re-visita tras reset re-registra")
	_af(j.mensaje_estado == "DATO EXTRA 1/2",
		"S2: contador reiniciado (1/2, no 2/2) — got='%s'" % j.mensaje_estado)
	j.queue_free()
	await get_tree().process_frame


## S3: todos los bonus visitados → piso de 3★ aunque el cálculo base dé 1★
## (cost_ratio 5.0 contra óptimo 4.0 en la rama legacy; max_turns=0 deja
## turn_stars en 3 para aislar la dimensión coste).
func _s3_piso_tres_estrellas() -> void:
	var j := await _lanzar([])
	if j == null:
		return
	j.bonus_nodes = [&"Puerta_A", &"Puerta_B"]
	j.bonus_visitados = []
	j.player_total_cost = 20.0
	_af(j._progress_service.calculate_stars() == 1,
		"S3 setup: coste inflado sin visitas → 1★ (ratio %.1f)" % (20.0 / 4.0))
	j.bonus_visitados = [&"Puerta_A", &"Puerta_B"]
	_af(j._progress_service.calculate_stars() == 3,
		"S3: todos los bonus visitados → piso de 3★")
	j.queue_free()
	await get_tree().process_frame


## S4: visita parcial NO dispara el piso (estrellas normales por coste) y
## sin bonus declarados la regla es inerte aunque exista el array de visits.
func _s4_parcial_sin_piso() -> void:
	var j := await _lanzar([])
	if j == null:
		return
	j.bonus_nodes = [&"Puerta_A", &"Puerta_B"]
	j.bonus_visitados = [&"Puerta_A"]
	j.player_total_cost = 20.0
	_af(j._progress_service.calculate_stars() == 1,
		"S4: visita parcial (1/2) → estrellas normales por coste (1★)")

	j.bonus_nodes = []
	j.player_total_cost = 20.0
	_af(j._progress_service.calculate_stars() == 1,
		"S4: sin bonus declarados la regla es inerte (1★)")
	j.queue_free()
	await get_tree().process_frame


## S5: frame_data expone los arrays (passthrough del renderer) y un
## NOTIFICATION_DRAW con bonus pendiente+visitado corre sin crash.
func _s5_renderer_y_frame_data() -> void:
	var j := await _lanzar([&"Puerta_A", &"Puerta_B"])
	if j == null:
		return
	var d: Dictionary = j._game_state.frame_data(Vector2(1280.0, 720.0))
	_af(d.has("bonus_nodes") and d.has("bonus_visitados"),
		"S5: frame_data expone bonus_nodes/bonus_visitados")
	_af(d["bonus_nodes"] == j.bonus_nodes and d["bonus_visitados"] == j.bonus_visitados,
		"S5: passthrough idéntico al estado del juego")

	j._mover_jugador(&"Puerta_A")
	d = j._game_state.frame_data(Vector2(1280.0, 720.0))
	_af(d["bonus_visitados"] == [&"Puerta_A"],
		"S5: frame_data refleja la visita (rombo WARNING→TEXT_DIM)")

	j.notification(CanvasItem.NOTIFICATION_DRAW)
	_af(true, "S5: smoke NOTIFICATION_DRAW con bonus mixto sin crash")
	j.queue_free()
	await get_tree().process_frame


# ── Helpers ────────────────────────────────────────────────────────────────

## Instancia escena_juego real con tut2 + SceneParams.bonus_nodes (patrón
## _test_ia_predictiva). Devuelve null (y cuenta FAIL) si no cargó.
func _lanzar(bonus: Array) -> Node:
	SceneParams.reset()
	SceneParams.graph_path = TUT2
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Target"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.ai_block_per_turn = 0
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_ai_blocks = 0
	SceneParams.max_turns = 30
	SceneParams.max_movement_points = 0
	SceneParams.defender_mode = false
	SceneParams.hacker_mode = false
	SceneParams.tutorial_path = ""
	SceneParams.titulo_nivel = "BONUS NODES TEST"
	SceneParams.bonus_nodes = bonus.duplicate(true)

	var scene := load("res://juego/ataque/escena_juego.tscn") as PackedScene
	var j: Node = scene.instantiate()
	get_tree().root.add_child(j)
	await get_tree().process_frame
	await get_tree().process_frame
	if j == null or not is_instance_valid(j) or j.graph == null:
		print("FAIL: escena_juego o grafo no cargaron (%s)" % TUT2)
		failed += 1
		return null
	for n in j.graph.nodes:
		if n != null and n.metadata != null:
			n.metadata["detection_chance"] = 0.0
	return j


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
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if failed == 0 else 1)
