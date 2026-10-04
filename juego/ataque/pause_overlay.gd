class_name PauseOverlay
extends Control

## Overlay modal de pausa dentro de la partida (Slice 1 / in-game-pause-and-ui-immersion).
## Permite reanudar, reiniciar con confirmacion, ajustar opciones de audio y esquema
## de control, y navegar al selector de niveles o menu principal sin salir forzadamente.

signal resumed
signal restart_confirmed
signal level_select_requested
signal main_menu_requested
signal input_scheme_changed(scheme: int)

const BrandClass = preload("res://juego/ui/brand.gd")

var current_view: String = "main"

# Botones vista principal
var resume_button: Button
var restart_button: Button
var options_button: Button
var level_select_button: Button
var menu_button: Button

# Vista confirmacion reinicio
var confirm_label: Label
var confirm_restart_button: Button
var cancel_restart_button: Button

# Vista opciones
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var master_val_label: Label
var music_val_label: Label
var sfx_val_label: Label
var scheme_option: OptionButton
var back_options_button: Button

var _center_container: CenterContainer
var _main_box: VBoxContainer
var _confirm_box: VBoxContainer
var _options_box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	_build_ui()
	load_options()
	resized.connect(_layout_content)


func _draw() -> void:
	if not visible:
		return
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.04, 0.07, 0.12, 0.85))


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_M, KEY_PAUSE]:
			get_viewport().set_input_as_handled()
			if current_view == "confirm" or current_view == "options":
				show_main()
			else:
				resumed.emit()


func show_overlay(sub_view: String = "main") -> void:
	visible = true
	_layout_content()
	match sub_view:
		"confirm":
			show_restart_confirm()
		"options":
			show_options()
		_:
			show_main()
	queue_redraw()


func hide_overlay() -> void:
	visible = false
	queue_redraw()


func is_overlay_visible() -> bool:
	return visible


func show_main() -> void:
	current_view = "main"
	_main_box.visible = true
	_confirm_box.visible = false
	_options_box.visible = false
	if is_inside_tree() and resume_button != null:
		resume_button.grab_focus()


func show_restart_confirm() -> void:
	current_view = "confirm"
	_main_box.visible = false
	_confirm_box.visible = true
	_options_box.visible = false
	if is_inside_tree() and cancel_restart_button != null:
		cancel_restart_button.grab_focus()


func show_options() -> void:
	current_view = "options"
	_main_box.visible = false
	_confirm_box.visible = false
	_options_box.visible = true
	if is_inside_tree() and back_options_button != null:
		back_options_button.grab_focus()


func set_input_scheme(scheme: int) -> void:
	if scheme_option != null and scheme >= 0 and scheme < scheme_option.item_count:
		scheme_option.selected = scheme
	save_options()


func get_input_scheme() -> int:
	if scheme_option != null:
		return scheme_option.selected
	return 0


func _layout_content() -> void:
	if not is_inside_tree():
		return
	var vp: Vector2 = get_viewport_rect().size
	position = Vector2.ZERO
	custom_minimum_size = vp
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _center_container != null:
		_center_container.position = Vector2.ZERO
		_center_container.custom_minimum_size = vp
		_center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ─── Construccion de UI ─────────────────────────────────────────────

func _build_ui() -> void:
	_center_container = CenterContainer.new()
	_center_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_center_container)

	var panel_container := PanelContainer.new()
	panel_container.mouse_filter = Control.MOUSE_FILTER_PASS
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = BrandClass.PANEL_SOLID
	panel_style.border_color = BrandClass.accent_dim(0.5)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 32.0
	panel_style.content_margin_right = 32.0
	panel_style.content_margin_top = 28.0
	panel_style.content_margin_bottom = 28.0
	panel_container.add_theme_stylebox_override("panel", panel_style)
	_center_container.add_child(panel_container)

	var content_root := MarginContainer.new()
	content_root.mouse_filter = Control.MOUSE_FILTER_PASS
	panel_container.add_child(content_root)

	_build_main_view(content_root)
	_build_confirm_view(content_root)
	_build_options_view(content_root)


func _build_main_view(parent: Node) -> void:
	_main_box = VBoxContainer.new()
	_main_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_main_box.add_theme_constant_override("separation", 14)
	parent.add_child(_main_box)

	var title_lbl := Label.new()
	title_lbl.text = "PAUSA"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", BrandClass.font_bold())
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", BrandClass.ACCENT)
	_main_box.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "SISTEMA EN ESPERA"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_override("font", BrandClass.font_regular())
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	_main_box.add_child(sub_lbl)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 6)
	_main_box.add_child(sep)

	resume_button = _make_button("Reanudar")
	resume_button.pressed.connect(func(): resumed.emit())
	_main_box.add_child(resume_button)

	restart_button = _make_button("Reiniciar")
	restart_button.pressed.connect(show_restart_confirm)
	_main_box.add_child(restart_button)

	options_button = _make_button("Opciones")
	options_button.pressed.connect(show_options)
	_main_box.add_child(options_button)

	level_select_button = _make_button("Selector de Niveles")
	level_select_button.pressed.connect(func(): level_select_requested.emit())
	_main_box.add_child(level_select_button)

	menu_button = _make_button("Menu Principal")
	menu_button.pressed.connect(func(): main_menu_requested.emit())
	_main_box.add_child(menu_button)


func _build_confirm_view(parent: Node) -> void:
	_confirm_box = VBoxContainer.new()
	_confirm_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_confirm_box.add_theme_constant_override("separation", 16)
	_confirm_box.visible = false
	parent.add_child(_confirm_box)

	var title_lbl := Label.new()
	title_lbl.text = "REINICIAR NIVEL"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", BrandClass.font_bold())
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", BrandClass.WARNING)
	_confirm_box.add_child(title_lbl)

	confirm_label = Label.new()
	confirm_label.text = "¿Reiniciar nivel? Todo el progreso del intento actual se perderá"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_label.custom_minimum_size = Vector2(340, 0)
	confirm_label.add_theme_font_override("font", BrandClass.font_regular())
	confirm_label.add_theme_font_size_override("font_size", 14)
	confirm_label.add_theme_color_override("font_color", BrandClass.TEXT)
	_confirm_box.add_child(confirm_label)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	_confirm_box.add_child(btn_row)

	confirm_restart_button = _make_button("Confirmar")
	confirm_restart_button.pressed.connect(func(): restart_confirmed.emit())
	btn_row.add_child(confirm_restart_button)

	cancel_restart_button = _make_button("Cancelar")
	cancel_restart_button.pressed.connect(show_main)
	btn_row.add_child(cancel_restart_button)


func _build_options_view(parent: Node) -> void:
	_options_box = VBoxContainer.new()
	_options_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_options_box.add_theme_constant_override("separation", 12)
	_options_box.visible = false
	parent.add_child(_options_box)

	var title_lbl := Label.new()
	title_lbl.text = "OPCIONES"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", BrandClass.font_bold())
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", BrandClass.ACCENT)
	_options_box.add_child(title_lbl)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	_options_box.add_child(grid)

	# Master
	var lbl_master := _make_field_label("Master:")
	grid.add_child(lbl_master)
	master_slider = _make_slider()
	grid.add_child(master_slider)
	master_val_label = _make_val_label("80%")
	grid.add_child(master_val_label)
	master_slider.value_changed.connect(func(v: float):
		_on_volume_changed("Master", v, master_val_label)
	)

	# Music
	var lbl_music := _make_field_label("Musica:")
	grid.add_child(lbl_music)
	music_slider = _make_slider()
	grid.add_child(music_slider)
	music_val_label = _make_val_label("80%")
	grid.add_child(music_val_label)
	music_slider.value_changed.connect(func(v: float):
		_on_volume_changed("Music", v, music_val_label)
	)

	# SFX
	var lbl_sfx := _make_field_label("SFX:")
	grid.add_child(lbl_sfx)
	sfx_slider = _make_slider()
	grid.add_child(sfx_slider)
	sfx_val_label = _make_val_label("80%")
	grid.add_child(sfx_val_label)
	sfx_slider.value_changed.connect(func(v: float):
		_on_volume_changed("SFX", v, sfx_val_label)
	)

	# Input Scheme
	var scheme_container := VBoxContainer.new()
	scheme_container.add_theme_constant_override("separation", 6)
	_options_box.add_child(scheme_container)

	var lbl_scheme := _make_field_label("Esquema de Control:")
	scheme_container.add_child(lbl_scheme)

	scheme_option = OptionButton.new()
	scheme_option.custom_minimum_size = Vector2(280, 32)
	scheme_option.add_theme_font_override("font", BrandClass.font_regular())
	scheme_option.add_theme_font_size_override("font_size", 13)
	scheme_option.add_item("Hibrido (Teclado + Mouse)", 0)
	scheme_option.add_item("Solo Teclado", 1)
	scheme_option.add_item("Solo Mouse", 2)
	scheme_option.item_selected.connect(_on_scheme_selected)
	scheme_container.add_child(scheme_option)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 6)
	_options_box.add_child(sep)

	back_options_button = _make_button("Volver")
	back_options_button.pressed.connect(show_main)
	_options_box.add_child(back_options_button)


func _on_volume_changed(bus_name: String, value: float, val_lbl: Label) -> void:
	val_lbl.text = "%d%%" % int(value)
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var db: float = linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(bus_idx, db)
	save_options()


func _on_scheme_selected(idx: int) -> void:
	save_options()
	input_scheme_changed.emit(idx)


func save_options() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	if master_slider != null:
		cfg.set_value("options", "volume_master", int(master_slider.value))
	if music_slider != null:
		cfg.set_value("options", "volume_music", int(music_slider.value))
	if sfx_slider != null:
		cfg.set_value("options", "volume_sfx", int(sfx_slider.value))
	if scheme_option != null:
		cfg.set_value("options", "input_scheme", scheme_option.selected)
	cfg.save("user://settings.cfg")


func load_options() -> void:
	var cfg := ConfigFile.new()
	var master_val: int = 80
	var music_val: int = 80
	var sfx_val: int = 80
	var scheme_val: int = 0

	if cfg.load("user://settings.cfg") == OK:
		master_val = int(cfg.get_value("options", "volume_master", 80))
		music_val = int(cfg.get_value("options", "volume_music", 80))
		sfx_val = int(cfg.get_value("options", "volume_sfx", 80))
		scheme_val = int(cfg.get_value("options", "input_scheme", 0))

	if master_slider != null:
		master_slider.value = master_val
		master_val_label.text = "%d%%" % master_val
	if music_slider != null:
		music_slider.value = music_val
		music_val_label.text = "%d%%" % music_val
	if sfx_slider != null:
		sfx_slider.value = sfx_val
		sfx_val_label.text = "%d%%" % sfx_val
	if scheme_option != null and scheme_val >= 0 and scheme_val < scheme_option.item_count:
		scheme_option.selected = scheme_val


# ─── Helpers de Componentes Visuales ────────────────────────────────

func _make_button(label: String) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(220, 36)
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_override("font", BrandClass.font_regular())
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", BrandClass.TEXT)
	btn.add_theme_color_override("font_hover_color", BrandClass.ACCENT)
	btn.add_theme_color_override("font_focus_color", BrandClass.ACCENT)
	btn.add_theme_color_override("font_pressed_color", BrandClass.TEXT)

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.08, 0.10, 0.16, 0.9)
	normal_sb.border_color = BrandClass.accent_dim(0.4)
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(4)
	normal_sb.content_margin_left = 12.0
	normal_sb.content_margin_right = 12.0
	normal_sb.content_margin_top = 6.0
	normal_sb.content_margin_bottom = 6.0

	var hover_sb := normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = Color(0.12, 0.15, 0.24, 0.95)
	hover_sb.border_color = BrandClass.ACCENT
	hover_sb.set_border_width_all(2)

	var focus_sb := hover_sb.duplicate() as StyleBoxFlat
	focus_sb.border_color = BrandClass.ACCENT

	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("focus", focus_sb)
	return btn


func _make_field_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", BrandClass.font_regular())
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", BrandClass.TEXT)
	return lbl


func _make_val_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(40, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.add_theme_font_override("font", BrandClass.font_regular())
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", BrandClass.TEXT_DIM)
	return lbl


func _make_slider() -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = 80.0
	slider.custom_minimum_size = Vector2(160, 24)
	slider.focus_mode = Control.FOCUS_ALL
	return slider
