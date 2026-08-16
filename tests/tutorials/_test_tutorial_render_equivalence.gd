extends Node

## Equivalence test (golden) para juego/tutorials/tutorial_render.gd — P2
## (parte 1) de la descomposición de tutorial_player.gd.
##
## Congela a nivel DATOS (sin render) las funciones puras movidas:
##   - _wrap_text: entradas representativas y límites de ancho (palabra que
##     no entra sola, ancho 0, cadena vacía, texto sin espacios).
##   - _get_action_short_name / _get_action_key_hint: action types existentes
##     (move/scan/input) + desconocido + vacío.
##   - _get_next_button_rect / _build_tooltip_buttons: rects con estados
##     típicos (esperando acción o no) y el hotspot "next" anclado al panel.
##   - Layouts: _floating_panel_layout (posiciones top/bottom/left/right/
##     center, alto mínimo y clamp de ancho), _action_reminder_layout
##     (fallbacks de detalle hint → tecla → texto, confirmación pendiente /
##     cumplida) y _glossary_overlay_layout (tamaño normal y clamp en
##     viewport chico, banda de clip).
##
## Usa ThemeDB.fallback_font (la misma que cablea tutorial_player en _ready)
## y small_font_size = fallback_font_size - 2 (el que calcula _ready), así el
## wrap y las alturas dependen solo de métricas estables del binario.
##
## Invocación:
##     godot --headless res://tests/tutorials/_test_tutorial_render_equivalence.tscn

const CAPTURE := false

const TutorialRenderClass = preload("res://juego/tutorials/tutorial_render.gd")

const VP := Vector2(800.0, 600.0)
const VP_CHICO := Vector2(400.0, 300.0)
const PANEL := Rect2(160.0, 240.0, 480.0, 120.0)

var passed: int = 0
var failed: int = 0
var r


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	r = TutorialRenderClass.new()
	r.setup(ThemeDB.fallback_font)
	var small_fs: int = ThemeDB.fallback_font_size - 2

	var snap: Array[String] = []

	# ── S1: _wrap_text ──
	var w_lines: Array[String] = _wrap_snap("El firewall detecta movimientos no autorizados en la red", 200.0, 14)
	snap.append("wrap|largo200|n=%d|l0=%s|lN=%s" % [w_lines.size(), w_lines[0], w_lines[w_lines.size() - 1]])
	snap.append("wrap|corta500|%s" % "|".join(PackedStringArray(_wrap_snap("Hola mundo", 500.0, 14))))
	snap.append("wrap|cero|n=%d|%s" % [r._wrap_text("a b c", 0.0, 14).size(), "|".join(PackedStringArray(r._wrap_text("a b c", 0.0, 14)))])
	snap.append("wrap|vacio|n=%d" % r._wrap_text("", 200.0, 14).size())
	snap.append("wrap|sin_espacios|n=%d" % r._wrap_text("supercalifragilistico", 50.0, 14).size())

	# ── S2: nombres y pistas de acciones ──
	for a in ["move", "scan", "input", "deploy", ""]:
		snap.append("short|%s=%s" % [a if a != "" else "vacío", r._get_action_short_name(a)])
	for a in ["move", "scan", "input", "deploy"]:
		snap.append("keyhint|%s=%s" % [a, r._get_action_key_hint(a)])

	# ── S3: rect del botón siguiente ──
	snap.append("btn|%s" % _rect_s(r._get_next_button_rect(PANEL)))

	# ── S4: hotspots de tooltip ──
	var btns: Array[Dictionary] = r._build_tooltip_buttons(VP, false, PANEL)
	snap.append("tt|info|n=%d|first=%s|%s" % [btns.size(), btns[0]["en"], _rect_s(btns[0]["rect"])])
	snap.append("tt|info|last=%s|%s" % [btns[btns.size() - 1]["en"], _rect_s(btns[btns.size() - 1]["rect"])])
	btns = r._build_tooltip_buttons(VP, true, PANEL)
	snap.append("tt|accion|n=%d|first=%s" % [btns.size(), btns[0]["en"]])
	snap.append("tt|accion|last=%s|%s" % [btns[btns.size() - 1]["en"], btns[btns.size() - 1]["text"]])

	# ── S5: layout del panel flotante ──
	var lay: Dictionary = r._floating_panel_layout(VP, "Línea uno\nLínea dos", "center")
	snap.append("fp|center|%s|n=%d|lh=%s" % [_rect_s(lay["rect"]), PackedStringArray(lay["lines"]).size(), str(lay["line_h"])])
	for pos in ["top", "bottom", "left", "right"]:
		lay = r._floating_panel_layout(VP, "Texto", pos)
		snap.append("fp|%s|%s" % [pos, _rect_s(lay["rect"])])
	lay = r._floating_panel_layout(VP, "", "center")
	snap.append("fp|min_h|%s" % _rect_s(lay["rect"]))
	lay = r._floating_panel_layout(VP_CHICO, "Texto", "center")
	snap.append("fp|clamp_w|%s" % _rect_s(lay["rect"]))

	# ── S6: layout del recordatorio de acción ──
	var step_move: Dictionary = {"action_required": "move", "title": "Mover", "hint": "Usa las flechas para desplazarte", "text": "ignorado\nsi hay hint"}
	lay = r._action_reminder_layout(step_move, VP, small_fs, false)
	snap.append("rem|hint|%s|%s" % [_rect_s(lay["rect"]), lay["header"]])
	snap.append("rem|hint|det=%d|%s" % [(lay["detail_lines"] as Array).size(), "|".join(PackedStringArray(lay["detail_lines"]))])
	snap.append("rem|hint|conf=%s" % lay["confirm_label"])

	var step_scan: Dictionary = {"action_required": "scan", "title": "Escanear", "text": "Primera línea\nSegunda línea"}
	lay = r._action_reminder_layout(step_scan, VP, small_fs, false)
	snap.append("rem|tecla|det=%s" % "|".join(PackedStringArray(lay["detail_lines"])))
	lay = r._action_reminder_layout(step_scan, VP, small_fs, true)
	snap.append("rem|ok|conf=%s" % lay["confirm_label"])

	var step_custom: Dictionary = {"action_required": "deploy", "title": "Desplegar", "text": "\n   \nCae por la primera línea no vacía"}
	lay = r._action_reminder_layout(step_custom, VP_CHICO, small_fs, false)
	snap.append("rem|texto|%s|det=%s" % [_rect_s(lay["rect"]), lay["detail_lines"][0]])

	# ── S7: layout del overlay del glosario ──
	lay = r._glossary_overlay_layout(VP)
	snap.append("gls|normal|%s|clip=%.1f..%.1f|lh=%s" % [_rect_s(lay["rect"]), lay["clip_top"], lay["clip_bottom"], str(lay["line_h"])])
	lay = r._glossary_overlay_layout(VP_CHICO)
	snap.append("gls|chico|%s|clip=%.1f..%.1f" % [_rect_s(lay["rect"]), lay["clip_top"], lay["clip_bottom"]])

	if CAPTURE:
		for linea in snap:
			print("GOLDEN\t%s" % linea)
		_finish()
		return

	var golden: Array[String] = [
		"wrap|largo200|n=3|l0=El firewall detecta|lN=en la red",
		"wrap|corta500|Hola mundo",
		"wrap|cero|n=3|a|b|c",
		"wrap|vacio|n=1",
		"wrap|sin_espacios|n=1",
		"short|move=MOVERSE",
		"short|scan=ESCANEAR",
		"short|input=ACCIÓN",
		"short|deploy=DEPLOY",
		"short|vacío=",
		"keyhint|move=Haz clic en un nodo o usa [Tab] + [Enter]",
		"keyhint|scan=Presiona [X] para escanear",
		"keyhint|input=",
		"keyhint|deploy=",
		"btn|490.0,372.0 130.0x36.0",
		"tt|info|n=6|first=Advance to the next step|490.0,372.0 130.0x36.0",
		"tt|info|last=Controls help|340.0,570.0 100.0x24.0",
		"tt|accion|n=5|first=Go back to the previous step",
		"tt|accion|last=Show hint|Mostrar pista",
		"fp|center|160.0,260.0 480.0x80.0|n=2|lh=18.0",
		"fp|top|160.0,70.0 480.0x80.0",
		"fp|bottom|160.0,460.0 480.0x80.0",
		"fp|left|30.0,260.0 480.0x80.0",
		"fp|right|290.0,260.0 480.0x80.0",
		"fp|min_h|160.0,260.0 480.0x80.0",
		"fp|clamp_w|30.0,110.0 340.0x80.0",
		"rem|hint|110.0,10.0 580.0x72.0|⚠ MOVERSE: Mover",
		"rem|hint|det=1|Usa las flechas para desplazarte",
		"rem|hint|conf=Presiona [Enter] cuando completes la acción",
		"rem|tecla|det=Presiona [X] para escanear",
		"rem|ok|conf=✅ ¡Acción completada! Presiona [Enter] para continuar",
		"rem|texto|12.0,10.0 376.0x72.0|det=Cae por la primera línea no vacía",
		"gls|normal|140.0,90.0 520.0x420.0|clip=132.0..480.0|lh=22.0",
		"gls|chico|20.0,20.0 360.0x260.0|clip=62.0..250.0",
	]

	if snap.size() != golden.size():
		print("FAIL: tamaño snapshot %d != golden %d" % [snap.size(), golden.size()])
		failed += 1
	for i in snap.size():
		if i < golden.size() and snap[i] == golden[i]:
			print("PASS: %s" % golden[i])
			passed += 1
		else:
			print("FAIL: got='%s' want='%s'" % [snap[i], golden[i] if i < golden.size() else "<none>"])
			failed += 1

	_finish()


func _wrap_snap(text: String, max_width: float, fsize: int) -> Array:
	var lines: Array[String] = r._wrap_text(text, max_width, fsize)
	return lines


func _rect_s(rect: Rect2) -> String:
	return "%.1f,%.1f %.1fx%.1f" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
