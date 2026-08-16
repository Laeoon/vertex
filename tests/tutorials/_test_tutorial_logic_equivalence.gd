extends Node

## Equivalence test (golden) para juego/tutorials/tutorial_logic.gd — etapa 4
## del slice de descomposición de tutorial_player.gd. Congela el
## comportamiento PRE-migración de: load_tutorial/start/skip/
## complete_tutorial/advance/previous/go_to_step/notify_action/
## can_perform_action/is_game_paused/hints/señales.
##
## Complementa a tests/tutorials/test_tutorial_system.gd (que ya congela la
## lógica de pasos en la suite): acá se congela la SECUENCIA DE SEÑALES y el
## flujo de hints/attempts, que ningún otro test cubre.

const CAPTURE := false
const TUT1 := "res://juego/tutorials/data/tut1_movimiento.json"

var passed: int = 0
var failed: int = 0
var tp: Control
var senales: Array = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# Instanciar la RAÍZ de la escena y tomar el hijo Control (como hace
	# juego_ataque._setup_tutorial): agregar el hijo directo rompe el parent
	# y deja a tp fuera del árbol (get_tree() == null mata los awaits).
	var scene: PackedScene = load("res://juego/tutorials/tutorial_player.tscn")
	var tutorial_root = scene.instantiate()
	add_child(tutorial_root)
	tp = tutorial_root.get_node("Control")
	await get_tree().process_frame

	tp.step_changed.connect(func(i, d): senales.append("step:%d" % i))
	tp.tutorial_completed.connect(func(id): senales.append("completed:%s" % id))
	tp.tutorial_skipped.connect(func(id): senales.append("skipped:%s" % id))

	var snap: Array[String] = []

	# ── S1: carga e inicio ──
	snap.append("load|%s|%d" % [str(tp.load_tutorial(TUT1)), tp.steps.size()])
	tp.start()
	snap.append("start|%d|%s|%s" % [tp.current_step_index, str(tp.is_active), str(tp.is_game_paused())])

	# ── S2: avance informativo + previous + go_to ──
	tp.advance()
	tp.advance()
	snap.append("adv2|%d" % tp.current_step_index)
	tp.previous()
	snap.append("prev|%d" % tp.current_step_index)
	tp.go_to_step(5)
	snap.append("goto5|%d" % tp.current_step_index)
	tp.go_to_step(99)
	snap.append("goto99|%d" % tp.current_step_index)

	# ── S3: paso de acción (tut1 paso 3: move) — gating y fulfilling ──
	tp.go_to_step(3)
	snap.append("paso3|paused=%s|can_move=%s|can_scan=%s|waiting=%s" % [
		str(tp.is_game_paused()), str(tp.can_perform_action("move")),
		str(tp.can_perform_action("scan")), str(tp._waiting_for_action)])
	tp.advance()  # bloqueado (acción no cumplida)
	snap.append("adv_bloqueado|%d|fulfilled=%s" % [tp.current_step_index, str(tp._action_fulfilled)])
	tp.notify_action("scan")  # tipo incorrecto
	snap.append("notify_wrong|fulfilled=%s" % str(tp._action_fulfilled))
	tp.notify_moved()  # tipo correcto
	snap.append("notify_ok|fulfilled=%s|can_scan=%s" % [str(tp._action_fulfilled), str(tp.can_perform_action("scan"))])
	tp.advance()  # ahora sí avanza
	snap.append("adv_ok|%d" % tp.current_step_index)

	# ── S4: flujo de hints (3 intentos fallidos auto-muestran) ──
	tp.go_to_step(3)
	tp.advance(); tp.advance(); tp.advance()
	snap.append("hint_auto|shown=%s|used=%s" % [str(tp._hint_shown if "_hint_shown" in tp else "?"), str(tp.get_hint() != "")])

	# ── S5: skip ──
	tp.skip()
	snap.append("skip|%d|%s" % [tp.current_step_index, str(tp.is_active)])
	senales.append("FIN_S5")

	# ── S6: complete desde juego ──
	tp.load_tutorial(TUT1)
	tp.start()
	tp.complete_tutorial()
	await get_tree().create_timer(0.6).timeout
	snap.append("complete|%d|%s" % [tp.current_step_index, str(tp.is_active)])

	# ── S7: resumen y highlights ──
	tp.load_tutorial(TUT1)
	tp.start()
	var summary: Array = tp.get_steps_summary()
	snap.append("summary|%d|%s" % [summary.size(), str(summary[0].get("id", ""))])
	tp.go_to_step(1)
	snap.append("high|%s|%s" % [str(tp.get_highlight_nodes()), str(tp.get_highlight_edges())])

	# ── S8: señales emitidas (secuencia completa) ──
	snap.append("senales|%s" % "|".join(PackedStringArray(senales)))

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_finish()
		return

	var golden: Array[String] = [
		"load|true|8",
		"start|0|true|true",
		"adv2|2",
		"prev|1",
		"goto5|5",
		"goto99|5",
		"paso3|paused=false|can_move=true|can_scan=false|waiting=true",
		"adv_bloqueado|3|fulfilled=false",
		"notify_wrong|fulfilled=false",
		"notify_ok|fulfilled=true|can_scan=false",
		"adv_ok|4",
		"hint_auto|shown=true|used=true",
		"skip|-1|false",
		"complete|-1|false",
		"summary|8|intro",
		"high|[\"Inicio\", \"Relay\", \"Target\"]|[\"Inicio→Relay\", \"Relay→Target\"]",
		"senales|step:0|step:1|step:2|step:1|step:5|step:3|step:4|step:3|completed:tut1_movimiento|skipped:tut1_movimiento|FIN_S5|step:0|completed:tut1_movimiento|step:0|step:1",
	]

	if snap.size() != golden.size():
		print("FAIL: tamaño snapshot %d != golden %d" % [snap.size(), golden.size()])
		failed += 1
	for i in snap.size():
		if snap[i] == golden[i]:
			print("PASS: %s" % golden[i])
			passed += 1
		else:
			print("FAIL: got='%s' want='%s'" % [snap[i], golden[i]])
			failed += 1

	_finish()


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
