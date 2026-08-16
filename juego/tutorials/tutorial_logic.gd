class_name TutorialLogic
extends RefCounted

## Lógica del sistema de tutoriales — etapa 4 de la descomposición de
## tutorial_player.gd.
##
## Aporta el ciclo de vida del tutorial: carga, pasos, avance/skip/completado,
## gating de acciones (can_perform_action), hints y pausa. El estado
## (tutorial_data, steps, current_step_index, flags) y las señales permanecen
## en el nodo tutorial_player (patrón setup(game) del proyecto) porque el
## juego, el input handler, el renderer y los tests los leen de ahí.
##
## Equivalencia congelada por
## tests/tutorials/_test_tutorial_logic_equivalence.{gd,tscn}.

var _p: Control


func setup(player: Control) -> void:
	_p = player


## Puerto del bootstrap de Locale del viejo tutorial_player._ready() (P5):
## garantiza el autoload Locale (lo crea si no está en el árbol).
func ensure_locale() -> Node:
	var loc: Node = _p.get_node_or_null("/root/Locale")
	if loc == null:
		var scene: PackedScene = load("res://core/locale/locale_manager.tscn")
		if scene != null:
			loc = scene.instantiate()
		else:
			loc = Node.new()
			loc.set_script(load("res://core/locale/locale_manager.gd"))
		loc.name = "Locale"
		_p.get_tree().root.add_child(loc)
	return loc


## Puerto de los timers del viejo tutorial_player._process() (P5): auto-avance
## por tiempo (sólo pasos informativos) y auto-reveal del hint al quedar
## trabado en un paso de acción.
func process_timers(delta: float) -> void:
	if not _p.is_active:
		return
	if _p._auto_advance_target > 0.0 and not _p._waiting_for_action:
		_p._auto_advance_timer += delta
		if _p._auto_advance_timer >= _p._auto_advance_target:
			advance()
	if _p._waiting_for_action and not _p._hint_shown:
		if get_hint() != "":
			_p._hint_stuck_timer += delta
			if _p._hint_stuck_timer >= _p._hint_auto_after:
				_p._hint_shown = true
				_p._hint_used = true


## Puerto del viejo tutorial_player.load_tutorial().
func load_tutorial(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("TutorialPlayer: no se pudo abrir %s" % path)
		return false

	var json_text: String = file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not parsed is Dictionary:
		push_error("TutorialPlayer: JSON invalido en %s" % path)
		return false

	_p.tutorial_data = parsed
	_p.steps = _p.tutorial_data.get("steps", [])
	if _p.steps.is_empty():
		push_warning("TutorialPlayer: tutorial sin steps en %s" % path)
		return false

	_p.current_step_index = -1
	_p.is_active = true
	_p.visible = true
	_p.modulate.a = 1.0
	_p._panel_alpha = 0.0
	_p._target_alpha = 1.0

	GameLogger.info("TutorialPlayer", "Tutorial cargado: %s (%d pasos)" % [_p.tutorial_data.get("id", "?"), _p.steps.size()])
	return true


## Puerto del viejo tutorial_player.start().
func start() -> void:
	if not _p.is_active or _p.steps.is_empty():
		return
	_advance_to_step(0)


## Puerto del viejo tutorial_player.skip().
func skip() -> void:
	if not _p.is_active:
		return
	var tid: String = _p.tutorial_data.get("id", "")
	_finish_tutorial()
	_p.tutorial_skipped.emit(tid)
	GameLogger.info("TutorialPlayer", "Tutorial saltado: %s" % tid)


## Puerto del viejo tutorial_player.complete_tutorial() (asíncrono).
func complete_tutorial() -> void:
	## Marca el tutorial como completado desde el juego (ej: al alcanzar el
	## target). Muestra un mensaje de confirmación y oculta el panel tras una
	## pausa breve.
	if not _p.is_active:
		return
	var tid: String = _p.tutorial_data.get("id", "")
	# Marcar el último paso como alcanzado para mostrar el tutorial completo
	_p.current_step_index = _p.steps.size() - 1
	_p._waiting_for_action = false
	_p._action_fulfilled = true
	_p._hint_shown = false
	_p.queue_redraw()
	# Esperar un momento breve para que el jugador vea que completó
	await _p.get_tree().create_timer(0.5).timeout
	_finish_tutorial()
	# _finish_tutorial() ya emite tutorial_completed y oculta el panel
	GameLogger.info("TutorialPlayer", "Tutorial completado desde juego: %s" % tid)


## Puerto del viejo tutorial_player.advance().
func advance() -> void:
	if not _p.is_active:
		return
	if _p._waiting_for_action and not _p._action_fulfilled:
		_p._attempts += 1
		if _p._attempts >= 3 and not _p._hint_shown and get_hint() != "":
			_p._hint_shown = true
		return
	if _p.current_step_index >= _p.steps.size() - 1:
		_finish_tutorial()
		return
	_advance_to_step(_p.current_step_index + 1)


## Puerto del viejo tutorial_player.previous().
func previous() -> void:
	if not _p.is_active or _p.current_step_index <= 0:
		return
	_advance_to_step(_p.current_step_index - 1)


## Puerto del viejo tutorial_player.go_to_step().
func go_to_step(idx: int) -> void:
	if not _p.is_active or idx < 0 or idx >= _p.steps.size():
		return
	_advance_to_step(idx)


## Puerto del viejo tutorial_player.get_steps_summary().
func get_steps_summary() -> Array:
	var summary: Array = []
	for i in range(_p.steps.size()):
		var step: Dictionary = _p.steps[i]
		summary.append({
			"index": i,
			"id": step.get("id", ""),
			"title": step.get("title", step.get("id", "Paso " + str(i + 1)))
		})
	return summary


## Puerto del viejo tutorial_player.get_hint().
func get_hint() -> String:
	if _p.current_step_index < 0 or _p.current_step_index >= _p.steps.size():
		return ""
	var step: Dictionary = _p.steps[_p.current_step_index]
	return step.get("hint", "")


## Puerto del viejo tutorial_player.show_hint().
func show_hint() -> void:
	if _p._hint_shown:
		return
	_p._hint_shown = true
	_p._hint_used = true
	GameLogger.info("TutorialPlayer", "Hint mostrado en paso %d" % (_p.current_step_index + 1))


## Puerto del viejo tutorial_player.notify_action().
func notify_action(action_type: String) -> void:
	## Marca la acción del paso actual como cumplida cuando el juego reporta
	## que el jugador la ejecutó. NO avanza automáticamente: el avance se
	## confirma con [Enter] (Slice 3.8 v2).
	if not _p.is_active or not _p._waiting_for_action:
		return
	var step: Dictionary = _p.steps[_p.current_step_index]
	var required = step.get("action_required", "")
	if required == null:
		required = ""
	if required == "" or required == action_type:
		_p._action_fulfilled = true


## Puerto del viejo tutorial_player.notify_moved().
func notify_moved() -> void:
	notify_action("move")


## Puerto del viejo tutorial_player.notify_input().
func notify_input() -> void:
	notify_action("input")


## Puerto del viejo tutorial_player.can_perform_action().
func can_perform_action(action_type: String) -> bool:
	## Devuelve si la acción `action_type` está permitida ahora mismo.
	## Durante un paso de acción SOLO se permite la acción requerida.
	if not _p.is_active or _p.current_step_index < 0 or _p.current_step_index >= _p.steps.size():
		return true
	if not _p._waiting_for_action:
		return true
	var required = _p.steps[_p.current_step_index].get("action_required", "")
	if required == null:
		required = ""
	if required == "":
		return true
	return required == action_type


## Puerto del viejo tutorial_player.step_requires_action().
func step_requires_action() -> bool:
	if not _p.is_active or _p.current_step_index < 0 or _p.current_step_index >= _p.steps.size():
		return false
	return _step_requires_action(_p.steps[_p.current_step_index])


## Puerto del viejo tutorial_player._step_requires_action().
func _step_requires_action(step: Dictionary) -> bool:
	var ar = step.get("action_required", "")
	return ar != null and str(ar) != ""


## Puerto del viejo tutorial_player.get_highlight_nodes().
func get_highlight_nodes() -> Array:
	if not _p.is_active or _p.current_step_index < 0 or _p.current_step_index >= _p.steps.size():
		return []
	return _p.steps[_p.current_step_index].get("highlight_nodes", [])


## Puerto del viejo tutorial_player.get_highlight_edges().
func get_highlight_edges() -> Array:
	if not _p.is_active or _p.current_step_index < 0 or _p.current_step_index >= _p.steps.size():
		return []
	return _p.steps[_p.current_step_index].get("highlight_edges", [])


## Puerto del viejo tutorial_player.is_game_paused().
func is_game_paused() -> bool:
	if not _p.is_active or _p.current_step_index < 0 or _p.current_step_index >= _p.steps.size():
		return false
	if _p._waiting_for_action:
		return false
	return _p.steps[_p.current_step_index].get("pause_game", false)


## Puerto del viejo tutorial_player._advance_to_step().
func _advance_to_step(idx: int) -> void:
	if idx < 0 or idx >= _p.steps.size():
		return

	_p.current_step_index = idx
	_p._action_fulfilled = false
	_p._waiting_for_action = false
	_p._auto_advance_timer = 0.0
	_p._auto_advance_target = 0.0
	_p._show_step_index = false
	_p._hint_used = false
	_p._attempts = 0
	_p._hint_shown = false
	_p._hint_stuck_timer = 0.0

	var step: Dictionary = _p.steps[idx]

	var ar = step.get("action_required", "")
	if ar != null and ar != "":
		_p._waiting_for_action = true

	if step.get("auto_advance_after", null) != null:
		_p._auto_advance_target = float(step["auto_advance_after"])

	_p._panel_alpha = 0.0
	_p._target_alpha = 1.0

	_p.step_changed.emit(idx, step)
	GameLogger.info("TutorialPlayer", "Tutorial paso %d/%d: %s" % [idx + 1, _p.steps.size(), step.get("id", "?")])


## Puerto del viejo tutorial_player._finish_tutorial() (asíncrono).
func _finish_tutorial() -> void:
	var tid: String = _p.tutorial_data.get("id", "")
	_p.is_active = false
	_p.current_step_index = -1
	_p._target_alpha = 0.0
	_p._waiting_for_action = false
	_p._action_fulfilled = false

	if _p.is_paused_by_tutorial:
		_p.get_tree().paused = false
		_p.is_paused_by_tutorial = false

	_p.tutorial_completed.emit(tid)
	GameLogger.info("TutorialPlayer", "Tutorial completado: %s" % tid)

	await _p.get_tree().create_timer(0.3).timeout
	_p.visible = false
