extends Control

## Database Controller
## Manages state machine, input routing, audio cues, and transitions for the Tactical Codex.
## Delegates pure layout and rendering to DatabaseRenderer.

const BrandClass = preload("res://juego/ui/brand.gd")
const CyberBackgroundClass = preload("res://juego/ui/cyber_background.gd")
const DatabaseRendererClass = preload("res://escenas/menu/database_renderer.gd")

var font: Font
var font_size: int = 14
var big_font_size: int = 28
var _pulse: float = 0.0

var _cyber_bg := CyberBackgroundClass.new()
var _renderer := DatabaseRendererClass.new()

var _active_cat_idx: int = 0
var _selected_entry_idx: int = 0
var _scroll_y: float = 0.0

var _hovered_back: bool = false
var _hovered_cat_idx: int = -1
var _hovered_entry_idx: int = -1

# Backward-compatibility / semantic aliases
var _category_idx: int:
	get: return _active_cat_idx
	set(val): _active_cat_idx = val

var _entry_idx: int:
	get: return _selected_entry_idx
	set(val): _selected_entry_idx = val

var _hovered_category_idx: int:
	get: return _hovered_cat_idx
	set(val): _hovered_cat_idx = val


func _ready() -> void:
	font = BrandClass.font_regular()
	font_size = ThemeDB.fallback_font_size
	big_font_size = font_size + 14
	_cyber_bg.show_hologram = false
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_menu_music"):
		am.play_menu_music()
	queue_redraw()


func _play_click_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")


func _set_active_category(idx: int) -> void:
	var total_cats := DatabaseRendererClass.CATEGORIES.size()
	if total_cats == 0:
		return
	var new_cat := clampi(idx, 0, total_cats - 1)
	if _active_cat_idx != new_cat:
		_active_cat_idx = new_cat
		_selected_entry_idx = 0
		_scroll_y = 0.0
		_play_click_sfx()
		queue_redraw()


func _select_entry(idx: int) -> void:
	var entries := DatabaseRendererClass.get_entries_for_category(_active_cat_idx)
	if entries.is_empty():
		return
	var new_idx := clampi(idx, 0, entries.size() - 1)
	if _selected_entry_idx != new_idx:
		_selected_entry_idx = new_idx
		_scroll_y = 0.0
		_play_click_sfx()
		queue_redraw()


func _scroll_by(amount: float) -> void:
	var max_s: float = _get_max_scroll()
	var prev_s := _scroll_y
	_scroll_y = clampf(_scroll_y + amount, 0.0, max_s)
	if not is_equal_approx(_scroll_y, prev_s):
		queue_redraw()


func _get_max_scroll() -> float:
	var vp := get_viewport_rect().size
	var right_rect := _renderer.get_right_panel_rect(vp)
	var viewport_h := _renderer.get_dossier_viewport_height(right_rect)
	var entries := DatabaseRendererClass.get_entries_for_category(_active_cat_idx)
	if _selected_entry_idx < 0 or _selected_entry_idx >= entries.size():
		return 0.0
	var entry: Dictionary = entries[_selected_entry_idx]
	var content_w := right_rect.size.x - 48.0
	var total_h := DatabaseRendererClass.compute_dossier_height(entry, font, font_size, content_w)
	return maxf(0.0, total_h - viewport_h)


func _back_to_menu() -> void:
	_play_click_sfx()
	var st = get_node_or_null("/root/SceneTransition")
	if st != null and st.has_method("fade_to_scene"):
		st.fade_to_scene("res://escenas/main_menu.tscn")
	elif get_tree() != null:
		get_tree().change_scene_to_file("res://escenas/main_menu.tscn")


func _input(event: InputEvent) -> void:
	var vp := get_viewport_rect().size

	if event is InputEventKey and event.pressed:
		var k := event as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				_back_to_menu()
			KEY_TAB:
				var total_cats := DatabaseRendererClass.CATEGORIES.size()
				_set_active_category((_active_cat_idx + 1) % total_cats)
			KEY_D, KEY_RIGHT:
				var total_cats := DatabaseRendererClass.CATEGORIES.size()
				_set_active_category((_active_cat_idx + 1) % total_cats)
			KEY_A, KEY_LEFT:
				var total_cats := DatabaseRendererClass.CATEGORIES.size()
				_set_active_category((_active_cat_idx - 1 + total_cats) % total_cats)
			KEY_W, KEY_UP:
				_select_entry(_selected_entry_idx - 1)
			KEY_S, KEY_DOWN:
				_select_entry(_selected_entry_idx + 1)
			KEY_PAGEUP:
				_scroll_by(-120.0)
			KEY_PAGEDOWN:
				_scroll_by(120.0)

	elif event is InputEventMouseMotion:
		var mpos := (event as InputEventMouseMotion).position
		var prev_b := _hovered_back
		_hovered_back = _renderer.get_back_button_rect(vp).has_point(mpos)

		var prev_c := _hovered_cat_idx
		_hovered_cat_idx = -1
		for i in range(DatabaseRendererClass.CATEGORIES.size()):
			if _renderer.get_category_tab_rect(i, vp).has_point(mpos):
				_hovered_cat_idx = i
				break

		var prev_e := _hovered_entry_idx
		_hovered_entry_idx = -1
		var num_entries := DatabaseRendererClass.get_entry_count(_active_cat_idx)
		for i in range(num_entries):
			if _renderer.get_entry_row_rect(i, vp).has_point(mpos):
				_hovered_entry_idx = i
				break

		if prev_b != _hovered_back or prev_c != _hovered_cat_idx or prev_e != _hovered_entry_idx:
			queue_redraw()

	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		var mpos := mb.position
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_scroll_by(-40.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				_scroll_by(40.0)
			MOUSE_BUTTON_LEFT:
				if _renderer.get_back_button_rect(vp).has_point(mpos):
					_back_to_menu()
					return

				for i in range(DatabaseRendererClass.CATEGORIES.size()):
					if _renderer.get_category_tab_rect(i, vp).has_point(mpos):
						_set_active_category(i)
						return

				var num_entries := DatabaseRendererClass.get_entry_count(_active_cat_idx)
				for i in range(num_entries):
					if _renderer.get_entry_row_rect(i, vp).has_point(mpos):
						_select_entry(i)
						return


func _process(delta: float) -> void:
	_pulse += delta * 2.0
	_cyber_bg.update(delta, get_viewport_rect().size)
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	_cyber_bg.draw(self, vp)
	_renderer.draw(
		self,
		vp,
		font,
		font_size,
		big_font_size,
		_pulse,
		_active_cat_idx,
		_selected_entry_idx,
		_scroll_y,
		_hovered_back,
		_hovered_cat_idx,
		_hovered_entry_idx
	)
