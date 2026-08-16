extends Control

## Orquestador del tutorial (slice 3 / P5): estado y señales (los leen el
## juego, el input, el renderer y los tests) + wiring; el comportamiento
## vive en tutorial_logic.gd (ciclo de vida/pasos/hints), glossary.gd
## (glosario [G]), tutorial_render.gd (layout/dibujado) y tutorial_input.gd
## (teclado/hover/tooltips). Equivalencias:
## tests/tutorials/_test_{tutorial_logic,glossary,tutorial_render}_equivalence

signal step_changed(step_index: int, step_data: Dictionary)
signal tutorial_completed(tutorial_id: String)
signal tutorial_skipped(tutorial_id: String)

var tutorial_data: Dictionary = {}
var steps: Array = []
var current_step_index: int = -1
var is_active: bool = false
var is_paused_by_tutorial: bool = false

var font: Font
var font_size: int = 14
var big_font_size: int = 18
var small_font_size: int = 12

var _auto_advance_timer: float = 0.0
var _auto_advance_target: float = 0.0
var _action_fulfilled: bool = false
var _waiting_for_action: bool = false

var _panel_color: Color = Color(0.05, 0.05, 0.1, 0.92)
var _panel_border: Color = Color(0.0, 1.0, 0.83, 0.8)
var _text_color: Color = Color.WHITE
var _accent_color: Color = Color(0.0, 1.0, 0.83)
var _warning_color: Color = Color(1.0, 0.18, 0.58)
var _btn_color: Color = Color(0.0, 0.8, 0.6)

var _panel_rect: Rect2 = Rect2()
var _panel_alpha: float = 0.0
var _target_alpha: float = 0.0

var _locale: Node = null

var _show_step_index: bool = false  # [I] navegación
var _hint_used: bool = false
var _attempts: int = 0
var _hint_shown: bool = false
var _hint_stuck_timer: float = 0.0
var _hint_auto_after: float = 10.0
var _show_help_overlay: bool = false  # QoL: overlay de ayuda

# Módulos (const por preload: evita resolución de class_name en CLI headless).
const TutorialLogicClass = preload("res://juego/tutorials/tutorial_logic.gd")
var _logic
const GlossaryClass = preload("res://juego/tutorials/glossary.gd")
var _glossary
const TutorialRenderClass = preload("res://juego/tutorials/tutorial_render.gd")
var _render
const TutorialInputClass = preload("res://juego/tutorials/tutorial_input.gd")
var _input_handler


func _ready() -> void:
	font = ThemeDB.fallback_font
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 4
	small_font_size = font_size - 2
	visible = false

	_logic = TutorialLogicClass.new()
	_logic.setup(self)
	_locale = _logic.ensure_locale()

	_glossary = GlossaryClass.new()
	_glossary.setup(self)

	_render = TutorialRenderClass.new()
	_render.setup(font)

	_input_handler = TutorialInputClass.new()
	add_child(_input_handler)
	_input_handler.setup(self, _render)
	_input_handler.previous_requested.connect(previous)
	_input_handler.skip_requested.connect(skip)
	_input_handler.toggle_step_index_requested.connect(_on_toggle_step_index)
	_input_handler.toggle_glossary_requested.connect(toggle_glossary)
	_input_handler.hint_requested.connect(show_hint)
	_input_handler.help_toggled.connect(_on_help_toggled)
	_input_handler.next_requested.connect(_on_next_pressed)

	_load_glossary()


func t(key: String) -> String:
	if _locale != null and _locale.has_method("loc"):
		return _locale.loc(key)
	return key


# ─── Delegates (comportamiento en los módulos) ─────────────────────

func _load_glossary() -> void: _glossary._load_glossary()
func load_tutorial(path: String) -> bool: return _logic.load_tutorial(path)
func start() -> void: _logic.start()
func skip() -> void: _logic.skip()
func complete_tutorial() -> void: _logic.complete_tutorial()
func advance() -> void: _logic.advance()
func previous() -> void: _logic.previous()
func go_to_step(idx: int) -> void: _logic.go_to_step(idx)
func get_steps_summary() -> Array: return _logic.get_steps_summary()
func get_hint() -> String: return _logic.get_hint()
func show_hint() -> void: _logic.show_hint()
func toggle_glossary() -> void: _glossary.toggle_glossary()
func notify_action(action_type: String) -> void: _logic.notify_action(action_type)
func notify_moved() -> void: _logic.notify_moved()
func notify_input() -> void: _logic.notify_input()
func can_perform_action(action_type: String) -> bool: return _logic.can_perform_action(action_type)
func step_requires_action() -> bool: return _logic.step_requires_action()
func _step_requires_action(step: Dictionary) -> bool: return _logic._step_requires_action(step)
func get_highlight_nodes() -> Array: return _logic.get_highlight_nodes()
func get_highlight_edges() -> Array: return _logic.get_highlight_edges()
func is_game_paused() -> bool: return _logic.is_game_paused()
func _advance_to_step(idx: int) -> void: _logic._advance_to_step(idx)
func _finish_tutorial() -> void: _logic._finish_tutorial()


func _process(delta: float) -> void:
	if not is_active and not _glossary.is_open():
		return

	var vp: Vector2 = get_viewport_rect().size
	size = vp
	position = Vector2.ZERO

	if is_active:
		_panel_alpha = move_toward(_panel_alpha, _target_alpha, delta * 5.0)
		_logic.process_timers(delta)
		# Tooltip (hotspots + hover viven en el input handler)
		_input_handler.update_hover(delta)

	if _glossary.is_open():
		_glossary.process_scroll(vp.y)

	queue_redraw()


## Estado dibujable que consumen los _draw_* del renderer: colores, fuentes,
## alpha, rects, flags y datos del paso actual. Incluye un Callable `t` para
## traducir sin que el renderer lea vars del nodo.
func _draw_state() -> Dictionary:
	return {
		"font": font,
		"font_size": font_size,
		"big_font_size": big_font_size,
		"small_font_size": small_font_size,
		"vp_size": get_viewport_rect().size,
		"mouse_pos": get_viewport().get_mouse_position(),
		"t": Callable(self, "t"),
		"panel_color": _panel_color,
		"panel_border": _panel_border,
		"text_color": _text_color,
		"accent_color": _accent_color,
		"warning_color": _warning_color,
		"btn_color": _btn_color,
		"panel_alpha": _panel_alpha,
		"panel_rect": _panel_rect,
		"waiting_for_action": _waiting_for_action,
		"action_fulfilled": _action_fulfilled,
		"steps": steps,
		"current_step_index": current_step_index,
		"tutorial_data": tutorial_data,
	}


func _draw() -> void:
	if is_active and current_step_index >= 0 and current_step_index < steps.size() and _panel_alpha >= 0.01:
		var step: Dictionary = steps[current_step_index]
		var text: String = step.get("text", "")
		var position: String = step.get("position", "center")
		var requires_action: bool = _step_requires_action(step)

		# Slice 3.8 v2 — dos modos de render:
		#   - Paso informativo → panel grande centrado (explicación).
		#   - Paso de acción   → recordatorio compacto ARRIBA, sin tapar la
		#     vista del tablero; la acción se juega en el juego y se confirma
		#     con [Enter].
		var s: Dictionary = _draw_state()
		if requires_action:
			_render._draw_action_reminder(self, s, step)
		else:
			_render._draw_floating_panel(self, s, text, position)
			_render._draw_next_button(self, s)
			_render._draw_step_indicator(self, s)
		_render._draw_controls_bar(self, s)
		if _hint_shown:
			_render._draw_hint_panel(self, s, get_hint())
		if _show_step_index:
			_render._draw_step_index_overlay(self, s, get_steps_summary())
		if _show_help_overlay:
			_render._draw_help_overlay(self, s)
		if _input_handler.tooltip_text != "":
			_render._draw_tooltip(self, s, _input_handler.tooltip_text)
		# El rect del panel lo resuelve el renderer al dibujar; se sincroniza
		# porque _process lo usa para los hotspots del frame siguiente.
		_panel_rect = s["panel_rect"]

	if _glossary.is_open():
		_render._draw_glossary_overlay(self, _draw_state(), _glossary.draw_pack())


func _on_toggle_step_index() -> void: _show_step_index = not _show_step_index
func _on_help_toggled() -> void: _show_help_overlay = not _show_help_overlay
func _on_next_pressed() -> void: advance()
