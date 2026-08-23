extends Node

## Test de la capa 2 — GameOverOverlay (botones reales de mouse + teclado):
##   1. Ciclo de vida en juego real: oculto mid-partida, visible tras ganar()
##      y tras perder(), oculto de nuevo tras reset_state().
##   2. Matriz de visibilidad de [N]: victoria heist_n1 → 4 botones; victoria
##      heist_n3 (último del mundo) → sin [N]; derrota → sin [N]; level_key ""
##      (tutoriales) → sin [N].
##   3. Overlay standalone: presionar cada botón emite SU señal (assert de
##      señal, no de transición real); grab_focus al mostrar; hide_overlay()
##      oculta y libera el foco.
##
## Invocación:
##     godot --headless res://tests/ataque/_test_game_over_ui.tscn

const OverlayClass = preload("res://juego/ataque/game_over_overlay.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	# ── Juego real (heist_n1, IA off para determinismo) ──
	SceneParams.reset()
	SceneParams.graph_path = "res://juego/nivel1/nivel1_red.tres"
	SceneParams.start_node = &"Inicio"
	SceneParams.target_node = &"Boveda"
	SceneParams.waypoints = []
	SceneParams.ai_enabled = false
	SceneParams.max_turns = 15
	SceneParams.max_movement_points = 12
	SceneParams.titulo_nivel = "GAME OVER UI TEST"
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

	var ov = juego._game_over_overlay

	# ── S1: ciclo de vida ──
	_af(ov != null and ov.has_method("show_overlay"), "overlay instanciado en _ready")
	_af(not ov.visible, "mid-partida: overlay oculto")

	juego._game_logic.ganar()
	await get_tree().process_frame
	_af(ov.visible, "tras ganar(): overlay visible")
	_af(_visibles(ov) == ["retry", "next", "select", "menu"],
		"victoria heist_n1: 4 botones visibles (con [N])")
	_af(ov.retry_button.has_focus(), "al mostrar: foco en el primer botón ([R])")

	juego.reset_state()
	_af(not ov.visible, "tras reset_state(): overlay oculto otra vez")

	juego._game_logic.perder("test ui")
	await get_tree().process_frame
	_af(ov.visible, "tras perder(): overlay visible")
	_af(_visibles(ov) == ["retry", "select", "menu"], "derrota: sin [N]")

	# ── S2: matriz de visibilidad de [N] ──
	juego.reset_state()
	juego.level_key = "heist_n3"
	juego._game_state._next_level_cache.clear()
	juego._game_logic.ganar()
	await get_tree().process_frame
	_af(ov.visible and not ov.next_button.visible,
		"victoria heist_n3 (último del mundo): sin [N]")
	_af(_visibles(ov) == ["retry", "select", "menu"], "heist_n3: 3 botones visibles")

	juego.reset_state()
	juego.level_key = ""
	juego._game_state._next_level_cache.clear()
	juego._game_logic.ganar()
	await get_tree().process_frame
	_af(ov.visible and not ov.next_button.visible,
		"victoria con level_key '' (tutoriales): sin [N]")

	juego.queue_free()
	await get_tree().process_frame

	# ── S3: señales de los botones (overlay standalone, sin transiciones) ──
	var solo = OverlayClass.new()
	add_child(solo)
	solo.show_overlay(true, true, false)
	_af(_visibles(solo) == ["retry", "next", "select", "menu"],
		"standalone victoria con siguiente: 4 botones")
	_af(solo.retry_button.has_focus(), "standalone: grab_focus al mostrar")

	var emitidas: Array[String] = []
	solo.retry_pressed.connect(func(): emitidas.append("retry"))
	solo.next_pressed.connect(func(): emitidas.append("next"))
	solo.select_pressed.connect(func(): emitidas.append("select"))
	solo.menu_pressed.connect(func(): emitidas.append("menu"))
	solo.retry_button.pressed.emit()
	solo.next_button.pressed.emit()
	solo.select_button.pressed.emit()
	solo.menu_button.pressed.emit()
	_af(emitidas == ["retry", "next", "select", "menu"],
		"cada botón emite su señal (retry/next/select/menu)")

	solo.hide_overlay()
	_af(not solo.visible and not solo.retry_button.has_focus(),
		"hide_overlay(): oculta y libera el foco")

	_fin()


func _visibles(ov) -> Array[String]:
	var out: Array[String] = []
	if ov.retry_button.visible:
		out.append("retry")
	if ov.next_button.visible:
		out.append("next")
	if ov.select_button.visible:
		out.append("select")
	if ov.menu_button.visible:
		out.append("menu")
	return out


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
