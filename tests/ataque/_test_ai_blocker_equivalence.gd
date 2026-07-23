extends Node

## Equivalencia conductual: AIBlocker vs lógica original de turno IA (slice 3).
##
## Verifica que la extracción de `_turno_ia` / `_no_aisla_al_jugador` en
## `AIBlocker` (juego/ataque/ai_blocker.gd) preserva la conducta observable.
## Dos partes complementarias:
##
##   Parte A — flip semántico `would_isolate` vs referencia congelada.
##   Compara bloque-a-bloque: el cuerpo VERBATIM del viejo
##   `_no_aisla_al_jugador` (congelado en la inner class `OriginalAI` de este
##   archivo) contra `AIBlocker.would_isolate`. La aserción es
##   `orig.no_aisla_al_jugador(key) == (not ai.would_isolate(key))`: la
##   extracción invierte el booleano (nombre honesto: `would_isolate == true`
##   significa SÍ aísla) y los call sites se actualizan a `not would_isolate`
##   para preservar conducta. La inner class sobrevive al borrado de
##   `_no_aisla_al_jugador` en la tarea 3.4 — es independiente del juego.
##
##   Parte B — replay determinista de 10 turnos de IA vs golden.
##   "Replays a fixed `seed(N)` 10-turn scenario against [...] AIBlocker,
##   comparing `blocked_edges`, `turn`, and `mensaje_estado`" (task 3.2).
##   A diferencia de un replay vía `_mover_jugador` (que choca con un bug
##   PRE-EXISTENTE en `_ganar` línea 710: `waypoints[-1]` OOB cuando el
##   jugador llega al objetivo sin waypoints — fuera del alcance de slice 3,
##   reportado en apply-progress), aquí se conduce SOLO la lógica de IA: se
##   fija `player_pos` a una secuencia de nodos y `turn = i` antes de cada
##   llamada, y se invoca el camino de IA activo vía `_invoke_ai()`. Eso
##   ejercita `_turno_ia`/`AIBlocker.take_turn` en sí — sin detección, sin
##   perseguidores (slice 4), sin `_ganar`. `seed(42)` fija el RNG por
##   completitud (la lógica de IA no usa randf, pero `_process_pursuers`
##   pasa por ser `pursuers` vacío sin tiradas).
##
## Golden: capturado con la lógica ORIGINAL inline (HEAD de task 3.1,
## pre-migración AIBlocker), seed(42), tut3_red con detection_chance=0. Tras
## la migración 3.3/3.4 la corrida debe reproducir idéntico el golden, y la
## Parte A debe seguir verde (la inner class no depende del juego migrado).
##
## Por qué `_` prefijo + `.tscn`: la prueba instancia `escena_juego.tscn`,
## cuyo script raíz (`juego_ataque.gd`) referencia autoloads (SceneParams,
## AudioManager, Events). En Godot 4.7, `--script` NO registra autoloads
## (slice-0 hallazgo #6), por lo que `run_all.gd` no puede ejecutarla — se
## excluye con `_` (Slice 0 convención idéntica a `juego/ataque/test_*.gd`)
## y se corre vía escena:
##     godot --headless res://tests/ataque/_test_ai_blocker_equivalence.tscn
## Única desviación del path indicado por el task (tests/ataque/, nombre
## `test_ai_blocker_equivalence.gd`): prefijo `_` para excluir del runner.
## Slice 9 (tarea 9.1) extenderá `run_all.gd` para descubrir/correr `.tscn`.
##
## Recaptura del golden: poner `CAPTURE = true`, correr la escena, copiar el
## bloque `=== CAPTURE ===` a `_golden_turnos`, devolver `CAPTURE = false` y
## re-correr para confirmar asserts verdes.

const GRAPH_PATH := "res://juego/tutorial3/tut3_red.tres"
const N_TURNOS := 10
const SEMILLA := 42

# Modo captura: true → imprime snapshots de la Parte B y NO afirma (regenerar
# golden). false → afirma contra `_golden_turnos` (Parte B) y flip (Parte A).
const CAPTURE := false

var passed: int = 0
var failed: int = 0
var _juego: Node2D

# Secuencia de posiciones del jugador para el replay de 10 turnos de IA.
# Varía entre nodos-hub del grafo (Inicio, Firewall, Router) con varias
# aristas salientes, para ejercitar distintas decisiones de `_turno_ia`.
var _posiciones: Array = [
	&"Inicio", &"Firewall", &"Router", &"Inicio", &"Firewall",
	&"Router", &"Inicio", &"Firewall", &"Router", &"Inicio",
]

# Golden capturado con lógica inline original (HEAD de task 3.1, pre-migración
# AIBlocker), seed(42), tut3_red con detection_chance=0, posiciones arriba.
# Ver encabezado para recaptura.
var _golden_turnos: Array = [
	"0|0|[\"IDS→Servidor\"]|IA bloqueo 1 arista(s) — Tu turno",
	"1|1|[\"Firewall→DMZ\", \"IDS→Servidor\"]|IA bloqueo 1 arista(s) — Tu turno",
	"2|2|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\"]|IA bloqueo 1 arista(s) — Tu turno",
	"3|3|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\", \"Router→IDS\"]|IA bloqueo 1 arista(s) — Tu turno",
	"4|4|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\", \"Router→IDS\"]|IA no pudo bloquear mas aristas — Tu turno",
	"5|5|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\", \"Router→IDS\"]|No hay ruta hacia Servidor — busca otro camino",
	"6|6|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\", \"Router→IDS\"]|IA no pudo bloquear mas aristas — Tu turno",
	"7|7|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\", \"Router→IDS\"]|IA no pudo bloquear mas aristas — Tu turno",
	"8|8|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\", \"Router→IDS\"]|No hay ruta hacia Servidor — busca otro camino",
	"9|9|[\"Firewall→DMZ\", \"IDS→Servidor\", \"Router→DMZ\", \"Router→IDS\"]|IA no pudo bloquear mas aristas — Tu turno",
]


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# SceneParams para una partida determinista de modo ataque (no defensor).
	SceneParams.graph_path = GRAPH_PATH
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Servidor"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = true
	SceneParams.ai_block_per_turn = 1
	SceneParams.ai_bloquea_al_inicio = false  # el replay dispara IA manualmente
	SceneParams.max_ai_blocks = 999
	SceneParams.max_turns = 30
	SceneParams.max_movement_points = 0
	SceneParams.block_duration = 99  # sin expiraciones dentro de los 10 turnos
	SceneParams.defender_mode = false
	SceneParams.hacker_mode = false
	SceneParams.tutorial_path = ""
	SceneParams.titulo_nivel = "EQUIV TEST"

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

	# Aislar lógica de IA: desactivar detection (perseguidores son slice 4).
	# Mutar la Resource cargada es seguro para esta prueba: ningún otro test
	# bajo tests/ o juego/ataque/ usa tut3_red (test_block_duration usa
	# tut2_red). La mutación persiste en el cache de resources durante la
	# vida del proceso Godot; al cerrar el proceso el cache se descarta.
	for n in _juego.graph.nodes:
		if n != null and n.metadata != null:
			n.metadata["detection_chance"] = 0.0

	# El initial_block de reset_state quedó deshabilitado (ai_bloquea_al_inicio
	# = false). Garantizar que empezamos sin bloqueos y con presupuesto IA
	# limpio para que el replay determine el estado desde cero.
	_juego.blocked_edges.clear()
	_juego._ai_blocks_used = 0

	seed(SEMILLA)

	_parte_a_would_isolate_flip()
	_parte_b_replay_10_turnos()

	_quit()


# ── Parte A: flip semántico would_isolate vs referencia congelada ───────

func _parte_a_would_isolate_flip() -> void:
	# Verifica en CADA arista del grafo que `AIBlocker.would_isolate(key)`
	# es la negación booleana del viejo `_no_aisla_al_jugador(key)`
	# (congelado en OriginalAI). Prueba literal "both at once" — ambos corren
	# contra el mismo `_juego` y restauran el coste al terminar, así que no
	# interfieren entre llamadas.
	var orig := OriginalAI.new()
	orig.setup(_juego)
	var ai_class := preload("res://juego/ataque/ai_blocker.gd")
	var ai := ai_class.new()
	ai.setup(_juego)

	var i := 0
	for e in _juego.graph.edges:
		if e == null:
			continue
		var key: String = "%s→%s" % [e.from_id, e.to_id]
		var orig_no_aisla: bool = orig.no_aisla_al_jugador(key)
		var ai_would_isolate: bool = ai.would_isolate(key)
		var coincide: bool = orig_no_aisla == (not ai_would_isolate)
		if coincide:
			print("PASS A.%d would_isolate flip OK: %s (orig no_aisla=%s ai would_isolate=%s)" % [i, key, str(orig_no_aisla), str(ai_would_isolate)])
			passed += 1
		else:
			print("FAIL A.%d would_isolate flip: %s (orig no_aisla=%s ai would_isolate=%s)" % [i, key, str(orig_no_aisla), str(ai_would_isolate)])
			failed += 1
		i += 1


# ── Parte B: replay determinista de 10 turnos de IA vs golden ─────────

func _parte_b_replay_10_turnos() -> void:
	var snapshots: Array = []
	for i in range(N_TURNOS):
		if _juego.game_over:
			# Aunque `_turno_ia`/`take_turn` corta temprano bajo game_over,
			# registrar el estado para que el golden capture la terminal.
			snapshots.append(_snapshot(i))
			continue
		_juego.player_pos = _posiciones[i]
		_juego.turn = i  # simular avance de turnos (afecta expires_at)
		# Camino de IA activo. Pre-migración (3.2 commit): `_turno_ia` inline.
		# Post-migración (3.3+): editar `_invoke_ai` para usar
		# `_juego._ai_blocker.take_turn()`.
		_invoke_ai()
		snapshots.append(_snapshot(i))

	if CAPTURE:
		print("=== CAPTURE START ===")
		for s in snapshots:
			print("\t\"%s\"," % s)
		print("=== CAPTURE END ===")
		print("PASS (capture B): %d snapshots impresos — copiar a _golden_turnos y poner CAPTURE=false" % snapshots.size())
		passed += 1
		return

	if snapshots.size() != _golden_turnos.size():
		print("FAIL B: snapshot count got=%d want=%d" % [snapshots.size(), _golden_turnos.size()])
		failed += 1
		return

	for i in range(snapshots.size()):
		if snapshots[i] == _golden_turnos[i]:
			print("PASS B.%d coincide" % i)
			passed += 1
		else:
			print("FAIL B.%d:\n  got =%s\n  want=%s" % [i, snapshots[i], _golden_turnos[i]])
			failed += 1


## Punto único de invocación de la IA — se edita en la task 3.3 para apuntar
## al `AIBlocker` migrado. Pre-migración llama al `_turno_ia` inline.
func _invoke_ai() -> void:
	_juego._turno_ia()


func _snapshot(idx: int) -> String:
	# Compact single-line: idx | turn | sorted blocked keys | mensaje_estado
	var keys: Array = _juego.blocked_edges.keys()
	keys.sort()
	return "%d|%d|%s|%s" % [idx, _juego.turn, str(keys), _juego.mensaje_estado]


func _quit() -> void:
	if _juego != null and is_instance_valid(_juego):
		_juego.queue_free()
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if failed == 0 else 1)


# ── Referencia congelada del viejo `_no_aisla_al_jugador` (verbatim) ─────
#
# Cuerpo copiado literalmente de `juego_ataque.gd` líneas 616–638
# (pre-migración). Es la fuente de verdad contra la que se valida el flip
# semántico de `AIBlocker.would_isolate`. Sobrevive al borrado del método
# original en la task 3.4 (es inner class local del test).

class OriginalAI extends RefCounted:
	var _game: Node

	func setup(game: Node) -> void:
		_game = game

	## Verbatim del viejo `_no_aisla_al_jugador`: true == NO aisla al
	## jugador del objetivo (semántica legada).
	func no_aisla_al_jugador(edge_key: String) -> bool:
		var parts: PackedStringArray = edge_key.split("→")
		if parts.size() != 2:
			return true
		var from_n: StringName = parts[0] as StringName
		var to_n: StringName = parts[1] as StringName
		var target: StringName = _game._target_actual()

		# Guardar coste original
		var orig: float = -1.0
		for e in _game.graph.edges:
			if e != null and e.from_id == from_n and e.to_id == to_n:
				orig = e.transit_cost
				break
		if orig < 0:
			return true

		# Simular bloqueo y verificar que el target sigue alcanzable
		_game.runtime.set_transit_cost(from_n, to_n, INF)
		var result: Dictionary = preload("res://core/agents/defensive_pathfinder.gd").find_path_with_cost(_game.graph, _game.player_pos, target, _game.runtime)
		_game.runtime.set_transit_cost(from_n, to_n, orig)

		return result["reachable"] and not result["path"].is_empty()