extends Node

## IA predictiva (E3): selección de objetivo a 2-3 pasos en AIBlocker.
##
## Verifica el modo `ia_predictiva` de `AIBlocker.take_turn()` (E3): con el
## flag encendido la IA apunta a la arista de la ruta del jugador ubicada
## 2-3 pasos adelante (índices 2..3 contando desde la posición) en lugar de
## recorrer río abajo; con el flag apagado la conducta es idéntica al legacy
## (golden de _test_ai_blocker_equivalence intacto).
##
## Escenarios (cada uno instancia `escena_juego.tscn` fresca vía SceneParams):
##   S1 — Flag OFF, tut3 pristine: réplica del golden turno 0 del replay de
##        equivalencia (seed 42, detección 0) → bloquea "IDS→Servidor".
##   S2 — Flag ON, tut3 con costes mutados (proceso local): la ruta óptima pasa
##        a ser Inicio→Router→IDS→DMZ→Servidor (5 nodos); el predictivo elige
##        el índice 2 (IDS→DMZ), no la última eslabón (DMZ→Servidor).
##   S3 — Flag OFF con los mismos costes mutados: sigue eligiendo río abajo
##        (DMZ→Servidor) → la diferencia viene sólo del flag.
##   S4 — Flag ON, tut2 (ruta corta, 3 nodos): sin candidato a distancia 2-3 →
##        fallback legacy sin crash (bloquea Puerta_A→Target).
##   S5 — Flag ON con IDS→DMZ convertido en puente (pre-bloqueos que matan
##        todas las rutas alternativas): would_isolate se respeta en modo
##        predictivo — no bloquea aunque el candidato predictivo existe.
##
## Mutación de recursos: igual que _test_ai_blocker_equivalence muta
## detection_chance, este test muta transit_cost de tut3_red DESPUÉS de S1.
## La mutación vive en el cache de resources del proceso (corrida headless
## dedicada) y muere al cerrar el proceso; ningún otro test usa tut3 con
## esos costes.
##
## Por qué `_` prefijo + `.tscn`: instancia `escena_juego.tscn`, cuyo script
## raíz referencia autoloads; `run_all.gd` (`--script`) no registra autoloads
## en Godot 4.7. Se corre vía escena:
##     godot --headless res://tests/ataque/_test_ia_predictiva.tscn

const TUT3 := "res://juego/tutorial3/tut3_red.tres"
const TUT2 := "res://juego/tutorial2/tut2_red.tres"
const SEMILLA := 42

var passed: int = 0
var failed: int = 0
var _g_mutado = null


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _s1_flag_off_replica_golden()
	_mutar_costes_tut3()
	await _s2_flag_on_elige_a_distancia_2()
	await _s3_flag_off_con_mismos_costes()
	await _s4_flag_on_ruta_corta_fallback()
	await _s5_would_isolate_en_predictivo()
	_fin()


# ── Escenarios ──────────────────────────────────────────────────────────────

## S1: flag OFF sobre tut3 pristine replica el golden turno 0 de la prueba de
## equivalencia (mismas condiciones: seed 42, detección 0, Inicio, turno 0).
func _s1_flag_off_replica_golden() -> void:
	var j := await _lanzar(TUT3, &"Servidor", false)
	if j == null:
		return
	_anular_deteccion(j)
	j.blocked_edges.clear()
	j._ai_blocks_used = 0
	seed(SEMILLA)
	j.player_pos = &"Inicio"
	j.turn = 0
	j._ai_blocker.take_turn()

	_af(j.ia_predictiva == false, "S1: transporte del flag (ia_predictiva=false)")
	_af(j.blocked_edges.keys() == ["IDS→Servidor"],
		"S1: flag OFF réplica golden → IDS→Servidor (río abajo, no adyacente)")
	_af(j.mensaje_estado == "IA bloqueo 1 arista(s) — Tu turno",
		"S1: mensaje idéntico al legacy")
	j.queue_free()
	await get_tree().process_frame


## S2: flag ON — con costes mutados la ruta óptima es de 5 nodos y el
## predictivo apunta al índice 2 (IDS→DMZ) en vez del cierre de la ruta.
func _s2_flag_on_elige_a_distancia_2() -> void:
	var j := await _lanzar(TUT3, &"Servidor", true)
	if j == null:
		return
	_anular_deteccion(j)
	j.blocked_edges.clear()
	j._ai_blocks_used = 0
	seed(SEMILLA)
	j.player_pos = &"Inicio"
	j.turn = 0
	j._ai_blocker.take_turn()

	_af(j.ia_predictiva == true, "S2: transporte del flag (ia_predictiva=true)")
	_af(j.blocked_edges.keys() == ["IDS→DMZ"],
		"S2: flag ON bloquea índice 2 de la ruta (IDS→DMZ, a 2 pasos) — got=%s" % str(j.blocked_edges.keys()))
	_af(not j.blocked_edges.has("DMZ→Servidor"),
		"S2: NO bloquea el cierre de la ruta (pick legacy descartado)")
	_af(j.mensaje_estado == "IA bloqueo 1 arista(s) — Tu turno",
		"S2: mensaje de bloqueo exitoso")
	j.queue_free()
	await get_tree().process_frame


## S3: flag OFF bajo los mismos costes mutados — el legacy sigue intacto y
## elige río abajo, probando que S2 dependió sólo del flag.
func _s3_flag_off_con_mismos_costes() -> void:
	var j := await _lanzar(TUT3, &"Servidor", false)
	if j == null:
		return
	_anular_deteccion(j)
	j.blocked_edges.clear()
	j._ai_blocks_used = 0
	seed(SEMILLA)
	j.player_pos = &"Inicio"
	j.turn = 0
	j._ai_blocker.take_turn()

	_af(j.blocked_edges.keys() == ["DMZ→Servidor"],
		"S3: flag OFF mismo grafo mutado → legacy río abajo (DMZ→Servidor) — got=%s" % str(j.blocked_edges.keys()))
	j.queue_free()
	await get_tree().process_frame


## S4: flag ON sobre tut2 — ruta de 3 nodos, sin arista a distancia 2-3 →
## fallback legacy sin crash.
func _s4_flag_on_ruta_corta_fallback() -> void:
	var j := await _lanzar(TUT2, &"Target", true)
	if j == null:
		return
	j.blocked_edges.clear()
	j._ai_blocks_used = 0
	seed(SEMILLA)
	j.player_pos = &"Inicio"
	j.turn = 0
	j._ai_blocker.take_turn()

	_af(j.blocked_edges.keys() == ["Puerta_A→Target"],
		"S4: ruta corta cae al legacy sin crash (Puerta_A→Target)")
	_af(not j.game_over and j.mensaje_estado == "IA bloqueo 1 arista(s) — Tu turno",
		"S4: partida viva y mensaje legacy tras el fallback")
	j.queue_free()
	await get_tree().process_frame


## S5: would_isolate respetado en modo predictivo — con IDS→Servidor,
## Router→DMZ, Firewall→DMZ y Firewall→IDS fuera de servicio, la única ruta
## es Inicio→Router→IDS→DMZ→Servidor y cada arista es un puente: cortar el
## candidato predictivo IDS→DMZ (índice 2) aísla al jugador, así que no debe
## bloquearse nada (ni por el camino predictivo ni por el fallback legacy).
func _s5_would_isolate_en_predictivo() -> void:
	var j := await _lanzar(TUT3, &"Servidor", true)
	if j == null:
		return
	_anular_deteccion(j)
	j.blocked_edges.clear()
	j._ai_blocks_used = 0
	_prebloquear(j, "IDS→Servidor")
	_prebloquear(j, "Router→DMZ")
	_prebloquear(j, "Firewall→DMZ")
	_prebloquear(j, "Firewall→IDS")
	var antes: Array = j.blocked_edges.keys()
	seed(SEMILLA)
	j.player_pos = &"Inicio"
	j.turn = 0
	j._ai_blocker.take_turn()

	_af(not j.blocked_edges.has("IDS→DMZ"),
		"S5: candidato predictivo puente (IDS→DMZ) NO bloqueado")
	_af(j.blocked_edges.keys() == antes,
		"S5: ninguna arista nueva bloqueada (sólo las del setup) — got=%s" % str(j.blocked_edges.keys()))
	_af(j.mensaje_estado == "IA no pudo bloquear mas aristas — Tu turno",
		"S5: mensaje de turno sin bloqueo (fallback legacy también respeta el guard)")
	j.queue_free()
	await get_tree().process_frame


# ── Helpers ────────────────────────────────────────────────────────────────

## Instancia escena_juego real con SceneParams (patrón _test_level_nav /
## _test_ai_blocker_equivalence). Devuelve null (y cuenta un FAIL) si el grafo
## no cargó.
func _lanzar(graph_path: String, target: StringName, predictivo: bool) -> Node:
	SceneParams.reset()
	SceneParams.graph_path = graph_path
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = target
	SceneParams.waypoints = []
	SceneParams.ai_enabled = true
	SceneParams.ai_block_per_turn = 1
	SceneParams.ai_bloquea_al_inicio = false
	SceneParams.max_ai_blocks = 999
	SceneParams.max_turns = 30
	SceneParams.max_movement_points = 0
	SceneParams.block_duration = 99
	SceneParams.defender_mode = false
	SceneParams.hacker_mode = false
	SceneParams.tutorial_path = ""
	SceneParams.titulo_nivel = "IA PREDICTIVA TEST"
	SceneParams.ia_predictiva = predictivo

	var scene := load("res://juego/ataque/escena_juego.tscn") as PackedScene
	var j: Node = scene.instantiate()
	get_tree().root.add_child(j)
	await get_tree().process_frame
	await get_tree().process_frame
	if j == null or not is_instance_valid(j) or j.graph == null:
		print("FAIL: escena_juego o grafo no cargaron (%s)" % graph_path)
		failed += 1
		return null
	return j


## Igual que la prueba de equivalencia: sin detección no aparecen perseguidores
## y el replay de IA queda determinista.
func _anular_deteccion(j: Node) -> void:
	for n in j.graph.nodes:
		if n != null and n.metadata != null:
			n.metadata["detection_chance"] = 0.0


## Bloqueo de setup (persistente durante el escenario): misma puerta que usa
## el juego, sin pasar por presupuesto de turnos de IA.
func _prebloquear(j: Node, edge_key: String) -> void:
	var parts: PackedStringArray = edge_key.split("→")
	j._block_edge(edge_key, parts[0] as StringName, parts[1] as StringName)


## Encarece los atajos de tut3 para que la ruta óptima desde Inicio sea
## Inicio→Router→IDS→DMZ→Servidor (coste 10) manteniendo TODAS las aristas
## vivas como desvíos caros (condición para que cortar IDS→DMZ no aísle).
##
## GOTCHA: el ResourceCache de Godot 4 es DÉBIL — si nadie retiene la carga,
## la instancia muere y el próximo load() recarga el .tres con costes
## prístinos. Por eso se guarda en `_g_mutado`: mientras viva, todos los
## load(TUT3) posteriores (los de escena_juego incluidos) devuelven ESTA
## instancia ya mutada. Sólo afecta al proceso de este test.
func _mutar_costes_tut3() -> void:
	var subidas: Array = [
		[&"IDS", &"Servidor", 50.0],   # era 2.0
		[&"Firewall", &"DMZ", 20.0],   # era 4.0
		[&"Router", &"DMZ", 30.0],     # era 2.0
	]
	var g = load(TUT3)
	for e in g.edges:
		if e == null:
			continue
		for s in subidas:
			if e.from_id == s[0] and e.to_id == s[1]:
				e.transit_cost = s[2]
	_g_mutado = g


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
