class_name GameOverOverlay
extends Control

## Capa 2 — botones reales del game over (mouse + teclado). El panel dibujado
## (título/mensaje/estrellas) sigue en GameRenderer; este overlay aporta la
## fila de botones debajo: [R] Reintentar  [N] Siguiente  [L] Niveles  [Q] Menú.
## Construido 100% por código (sin .tscn) con StyleBoxFlat + tokens de Brand.
##
## Matriz de visibilidad: [N] sólo con victoria Y nivel siguiente disponible
## (has_next ya es false en tutoriales/level_key desconocido). El teclado
## sigue entrando por InputHandler; el mouse por acá — ambos caen en los
## mismos handlers de juego_ataque.gd.

signal retry_pressed
signal next_pressed
signal select_pressed
signal menu_pressed

const BrandClass = preload("res://juego/ui/brand.gd")

const BTN_GAP := 12.0
const BTN_CONTENT_MARGIN := 14.0
## Debajo del panel dibujado por el renderer (center.y-60 .. center.y+80).
const PANEL_OFFSET_Y := 104.0

var retry_button: Button
var next_button: Button
var select_button: Button
var menu_button: Button

var _panel: PanelContainer
var _row: HBoxContainer
var _panel_style_win: StyleBoxFlat
var _panel_style_lose: StyleBoxFlat


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


## Muestra el overlay con la matriz de visibilidad y el borde según resultado.
## `defender` sólo discrimina el modo en el log (la matriz es idéntica).
func show_overlay(game_won: bool, has_next: bool, defender: bool) -> void:
	next_button.visible = game_won and has_next
	_panel.add_theme_stylebox_override(
		"panel", _panel_style_win if game_won else _panel_style_lose
	)
	visible = true
	_layout_panel()
	retry_button.grab_focus()
	GameLogger.info(
		"GameOverOverlay",
		"game over: %s%s" % ["victoria" if game_won else "derrota", " (defensor)" if defender else ""]
	)


func hide_overlay() -> void:
	visible = false


func _build() -> void:
	_panel_style_win = _make_panel_style(BrandClass.SUCCESS)
	_panel_style_lose = _make_panel_style(BrandClass.DANGER)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _panel_style_lose)
	add_child(_panel)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", BTN_GAP)
	_panel.add_child(_row)

	retry_button = _make_button("[R] Reintentar", retry_pressed)
	next_button = _make_button("[N] Siguiente", next_pressed)
	select_button = _make_button("[L] Niveles", select_pressed)
	menu_button = _make_button("[Q] Menú", menu_pressed)
	_row.add_child(retry_button)
	_row.add_child(next_button)
	_row.add_child(select_button)
	_row.add_child(menu_button)
	_wire_focus_neighbors()

	resized.connect(_layout_panel)


func _make_button(label: String, relay: Signal) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_override("font", BrandClass.font_regular())
	btn.add_theme_font_size_override("font_size", ThemeDB.fallback_font_size)
	btn.add_theme_color_override("font_color", BrandClass.TEXT)
	btn.add_theme_color_override("font_hover_color", BrandClass.ACCENT)
	btn.add_theme_color_override("font_focus_color", BrandClass.ACCENT)
	btn.add_theme_color_override("font_pressed_color", BrandClass.TEXT)
	btn.add_theme_stylebox_override("normal", _make_btn_style(BrandClass.accent_dim(0.45), Color(0.05, 0.06, 0.10, 0.92)))
	btn.add_theme_stylebox_override("hover", _make_btn_style(BrandClass.ACCENT, Color(0.08, 0.10, 0.16, 0.95)))
	btn.add_theme_stylebox_override("pressed", _make_btn_style(BrandClass.ACCENT, Color(0.10, 0.13, 0.20, 0.97)))
	btn.add_theme_stylebox_override("focus", _make_focus_style())
	btn.pressed.connect(func(): relay.emit())
	return btn


## Flechas (y Tab) navegan la fila: vecinos explícitos porque en un HBox el
## foco vertical no se autocomputa.
func _wire_focus_neighbors() -> void:
	var btns: Array[Button] = [retry_button, next_button, select_button, menu_button]
	for i in btns.size():
		var prev: Button = btns[wrapi(i - 1, 0, btns.size())]
		var next: Button = btns[wrapi(i + 1, 0, btns.size())]
		btns[i].focus_neighbor_left = btns[i].get_path_to(prev)
		btns[i].focus_neighbor_top = btns[i].get_path_to(prev)
		btns[i].focus_neighbor_right = btns[i].get_path_to(next)
		btns[i].focus_neighbor_bottom = btns[i].get_path_to(next)
		btns[i].focus_next = btns[i].get_path_to(next)
		btns[i].focus_previous = btns[i].get_path_to(prev)


func _layout_panel() -> void:
	if not is_inside_tree() or _panel == null:
		return
	var vp: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = _panel.get_minimum_size()
	_panel.position = Vector2(
		vp.x * 0.5 - panel_size.x * 0.5,
		vp.y * 0.5 + PANEL_OFFSET_Y
	)
	_panel.size = panel_size


func _make_panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BrandClass.PANEL_SOLID
	style.border_color = BrandClass.with_alpha(border, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = BTN_GAP
	style.content_margin_right = BTN_GAP
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _make_btn_style(border: Color, bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = BTN_CONTENT_MARGIN
	style.content_margin_right = BTN_CONTENT_MARGIN
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _make_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = BrandClass.ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style
