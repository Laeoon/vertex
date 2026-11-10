class_name TutorialInput
extends Node

## Input del tutorial — P3 de la descomposición de tutorial_player.gd,
## al estilo de juego/ataque/input_handler.gd.
##
## Traduce el teclado y el hover del mouse a acciones semánticas del
## tutorial y emite señales; el nodo tutorial_player las conecta a sus
## delegates del logic/glossary. También posee el estado de tooltips
## (texto, objetivo, timer y hotspots): update_hover(delta) lo actualiza
## (lo llama el player desde _process) y el renderer lee tooltip_text para
## dibujar el globito. Nada externo consumía las viejas vars _tooltip_*.
##
## El player se referencia sin tipo (patrón const preload + var sin tipo
## del proyecto). Verificación: compilación + suite + test_tutorial_system.

signal previous_requested()
signal skip_requested()
signal toggle_step_index_requested()
signal toggle_glossary_requested()
signal hint_requested()
signal help_toggled()
signal next_requested()

var player = null
var render = null

# Estado de tooltips porte de tutorial_player.gd
var tooltip_text: String = ""
var _tooltip_target: String = ""
var _tooltip_timer: float = 0.0
var _tooltip_delay: float = 0.5
var _tooltip_buttons: Array[Dictionary] = []


func setup(p_player, p_render) -> void:
	player = p_player
	render = p_render


## Puerto del viejo tutorial_player._input() (solo teclado).
func _input(event: InputEvent) -> void:
	if player == null or not player.is_active:
		return

	if event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k: InputEventKey = event as InputEventKey
		match k.keycode:
			KEY_LEFT, KEY_BACKSPACE:
				previous_requested.emit()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				skip_requested.emit()
				get_viewport().set_input_as_handled()
			KEY_I:
				toggle_step_index_requested.emit()
				_tooltip_reset()
				get_viewport().set_input_as_handled()
			KEY_G:
				toggle_glossary_requested.emit()
				_tooltip_reset()
				get_viewport().set_input_as_handled()
			KEY_H:
				if player._waiting_for_action:
					hint_requested.emit()
				else:
					help_toggled.emit()
				get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_SPACE:
				# Slice 3.8 v2 — [Enter] confirma. En pasos de acción solo avanza
				# si la acción YA se cumplió; si no, el evento se deja pasar sin
				# consumir para que el juego pueda procesarlo (mover, resolver
				# turno del defensor, etc.) y el jugador complete la acción.
				if player._waiting_for_action:
					if player._action_fulfilled:
						next_requested.emit()
						get_viewport().set_input_as_handled()
				else:
					next_requested.emit()
					get_viewport().set_input_as_handled()

	# Clic con mouse o Tap táctil en botones del tutorial
	var is_click := false
	var click_pos := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_click = true
		click_pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		is_click = true
		click_pos = event.position

	if is_click:
		var vp_size: Vector2 = player.get_viewport_rect().size

		# 1. Botón siguiente (en pasos informativos)
		if not player._waiting_for_action:
			var btn_rect: Rect2 = render._get_next_button_rect(player._panel_rect, vp_size)
			if btn_rect.grow(10.0).has_point(click_pos):
				next_requested.emit()
				get_viewport().set_input_as_handled()
				return
		else:
			# En pasos de acción, si ya se cumplió, clic en el panel o botón continuar avanza
			if player._action_fulfilled:
				var panel_r: Rect2 = player._panel_rect
				if panel_r.grow(12.0).has_point(click_pos):
					next_requested.emit()
					get_viewport().set_input_as_handled()
					return

		# 2. Botones de barra inferior (Anterior, Saltar, Índice, Glosario, Pista)
		var pill_rects: Array = []
		if render != null and render.has_method("get_controls_pill_rects"):
			pill_rects = render.get_controls_pill_rects(vp_size)
		for p in pill_rects:
			var r: Rect2 = p["rect"]
			if r.grow(4.0).has_point(click_pos):
				match p["id"]:
					"previous":
						previous_requested.emit()
						get_viewport().set_input_as_handled()
						return
					"skip":
						skip_requested.emit()
						get_viewport().set_input_as_handled()
						return
					"index":
						toggle_step_index_requested.emit()
						get_viewport().set_input_as_handled()
						return
					"glossary":
						toggle_glossary_requested.emit()
						get_viewport().set_input_as_handled()
						return
					"hint":
						if player._waiting_for_action:
							hint_requested.emit()
						else:
							help_toggled.emit()
						get_viewport().set_input_as_handled()
						return


## Puerto de los viejos tutorial_player._update_tooltip_buttons() y
## _check_tooltip_hover(): reconstruye los hotspots (geometría del render) y
## actualiza el texto del tooltip según el hover del mouse.
func update_hover(delta: float) -> void:
	if player == null or render == null:
		return
	_tooltip_buttons = render._build_tooltip_buttons(player.get_viewport_rect().size, player._waiting_for_action, player._panel_rect)

	var mouse_pos: Vector2 = player.get_viewport().get_mouse_position()
	var found: String = ""
	for btn in _tooltip_buttons:
		var r: Rect2 = btn["rect"]
		if r.has_point(mouse_pos):
			found = btn["text"]
			break

	if found != _tooltip_target:
		_tooltip_target = found
		_tooltip_timer = 0.0
		tooltip_text = ""

	if _tooltip_target != "":
		_tooltip_timer += delta
		if _tooltip_timer >= _tooltip_delay:
			tooltip_text = _tooltip_target
	else:
		tooltip_text = ""
		_tooltip_target = ""


func _tooltip_reset() -> void:
	tooltip_text = ""
