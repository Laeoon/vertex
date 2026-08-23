extends Node

## Test de la capa 2b — GameOverOverlay (pantalla completa de fin de partida).
##
## Capa 2 (matriz de botones + señales, sigue verde):
##   1. Ciclo de vida en juego real: oculto mid-partida, visible tras ganar()
##      y tras perder(), oculto de nuevo tras reset_state().
##   2. Matriz de visibilidad de [N]: victoria heist_n1 → 4 botones; victoria
##      heist_n3 (último del mundo) → sin [N]; derrota → sin [N]; level_key ""
##      (tutoriales) → sin [N].
##   3. Overlay standalone: presionar cada botón emite SU señal (assert de
##      señal, no de transición real); grab_focus al mostrar; hide_overlay()
##      oculta y libera el foco.
##
## Capa 2b (pantalla completa + fondos procedurales):
##   4. Overlay cubre el viewport completo tras mostrar (size == vp) y su
##      mouse_filter bloquea (MOUSE_FILTER_STOP).
##   5. Fade: modulate.a < 1 inmediatamente tras show_overlay y == 1 tras el
##      tween (await un frame extra).
##   6. Título correcto por caso: VICTORIA / CAPTURADO (derrota) /
##      VICTORIA DEFENSIVA (defensor ganado) / TUTORIAL COMPLETADO.
##   7. Estado interno del fondo correcto por resultado (flag win/lose, no
##      píxeles).
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

	# ── S4: pantalla completa — cubre el viewport y bloquea el mouse ──
	# El overlay vive como hijo de un Node2D: PRESET_FULL_RECT no lo dimensiona
	# solo; _layout_content() fuerza size == vp. Lo probamos en el juego real
	# (ov ya está en el árbol con un viewport de 1280x720).
	solo.show_overlay(true, true, false, "msg", 2)
	var vp_real: Vector2 = solo.get_viewport_rect().size
	_af(solo.size == vp_real, "overlay size == viewport tras show (pantalla completa)")
	_af(solo.mouse_filter == Control.MOUSE_FILTER_STOP,
		"overlay mouse_filter == STOP (bloquea clicks del nivel)")

	# ── S5: fade de entrada (0 → 1 sobre modulate:a) ──
	solo.hide_overlay()
	solo.show_overlay(true, true, false, "msg", 2)
	_af(solo.modulate.a < 1.0, "fade: modulate.a < 1 inmediatamente tras show_overlay")
	# El tween dura FADE_DURATION (0.45s); esperamos lo suficiente para que termine.
	await get_tree().create_timer(0.6).timeout
	_af(is_equal_approx(solo.modulate.a, 1.0), "fade: modulate.a == 1 tras el tween")

	# ── S6: título correcto por caso ──
	# Victoria (no defensor, no tutorial) → VICTORIA
	solo.hide_overlay()
	solo.show_overlay(true, true, false, "v", 3)
	_af(solo._title_label.text == "VICTORIA", "título victoria: VICTORIA")
	# Derrota → CAPTURADO
	solo.hide_overlay()
	solo.show_overlay(false, false, false, "d", 0)
	_af(solo._title_label.text == "CAPTURADO", "título derrota: CAPTURADO")
	# Victoria defensora → VICTORIA DEFENSIVA
	solo.hide_overlay()
	solo.show_overlay(true, true, true, "dv", 3)
	_af(solo._title_label.text == "VICTORIA DEFENSIVA", "título defensor ganado: VICTORIA DEFENSIVA")
	# Tutorial completado (set_tutorial_title) → TUTORIAL COMPLETADO
	solo.hide_overlay()
	solo.show_overlay(true, true, false, "tut", 3)
	solo.set_tutorial_title()
	_af(solo._title_label.text == "TUTORIAL COMPLETADO", "título tutorial: TUTORIAL COMPLETADO")

	# ── S7: estado interno del fondo correcto por resultado ──
	# Victoria → _is_win true, _is_lose false
	solo.hide_overlay()
	solo.show_overlay(true, true, false, "w", 2)
	_af(solo._is_win and not solo._is_lose, "estado fondo victoria: _is_win=true, _is_lose=false")
	# Derrota → _is_win false, _is_lose true
	solo.hide_overlay()
	solo.show_overlay(false, false, false, "l", 0)
	_af(not solo._is_win and solo._is_lose, "estado fondo derrota: _is_win=false, _is_lose=true")
	# hide_overlay resetea el estado del fondo
	solo.hide_overlay()
	_af(not solo._is_win and not solo._is_lose, "hide_overlay: estado del fondo reseteado")

	solo.queue_free()

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
