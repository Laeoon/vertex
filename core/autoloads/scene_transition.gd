extends CanvasLayer

## Sistema de transición fade y dive entre escenas para VERTEX.
## Expone:
##   SceneTransition.fade_to_scene(path, duration)
##   SceneTransition.dive_in_to_scene(path, origin_pos, duration)
##   SceneTransition.dive_out_to_scene(path, origin_pos, duration)

enum DiveMode { NONE, IN, OUT }

class DiveOverlay extends Control:
	var host: CanvasLayer

	func _draw() -> void:
		if host != null:
			host._draw_dive_overlay(self)


var _color_rect: ColorRect
var _dive_overlay: DiveOverlay
var _is_transitioning: bool = false

var _dive_mode: DiveMode = DiveMode.NONE
var _dive_progress: float = 0.0
var _dive_center: Vector2 = Vector2.ZERO
var _dive_target_path: String = ""
var _dive_warp_angles: PackedFloat32Array = []
var _next_dive_origin: Vector2 = Vector2.ZERO
var _force_next_dive: bool = false
var _pulse: float = 0.0


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_color_rect = ColorRect.new()
	_color_rect.color = Color.BLACK
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_rect)
	_color_rect.modulate = Color.TRANSPARENT

	_dive_overlay = DiveOverlay.new()
	_dive_overlay.host = self
	_dive_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dive_overlay)

	_dive_warp_angles = PackedFloat32Array()
	for i in range(32):
		_dive_warp_angles.append(float(i) * TAU / 32.0)

	_resize_rect()


func _process(delta: float) -> void:
	_pulse += delta * 2.0


func _resize_rect() -> void:
	var vp := get_viewport()
	if vp != null:
		var s := vp.get_visible_rect().size
		if _color_rect != null:
			_color_rect.size = s
		if _dive_overlay != null:
			_dive_overlay.size = s


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_resize_rect()
		var vp := get_viewport()
		if vp != null and not vp.size_changed.is_connected(_resize_rect):
			vp.size_changed.connect(_resize_rect)


func set_next_dive_origin(pos: Vector2) -> void:
	_next_dive_origin = pos
	_force_next_dive = true


func fade_to_scene(path: String, duration: float = 0.28) -> void:
	if _force_next_dive or _next_dive_origin != Vector2.ZERO:
		var pos := _next_dive_origin
		_next_dive_origin = Vector2.ZERO
		_force_next_dive = false
		dive_in_to_scene(path, pos, 0.38)
		return

	if _is_transitioning:
		return

	_is_transitioning = true
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_color_rect, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished

	get_tree().change_scene_to_file(path)

	await get_tree().process_frame
	var tween2: Tween = create_tween()
	tween2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween2.tween_property(_color_rect, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween2.finished

	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false


func fade_out(duration: float = 0.28) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_color_rect, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished


func fade_in(duration: float = 0.28) -> void:
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_color_rect, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	_is_transitioning = false


## Inicia la transición 3D warp tunnel hacia adelante (penetración táctica en nivel/sub-pantalla).
func dive_in_to_scene(path: String, origin_pos: Vector2 = Vector2.ZERO, duration: float = 0.38) -> void:
	if _is_transitioning:
		return
	if DisplayServer.get_name() == "headless":
		fade_to_scene(path, 0.12)
		return

	_is_transitioning = true
	_dive_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_dive_mode = DiveMode.IN
	_dive_progress = 0.0
	_dive_center = origin_pos
	_dive_target_path = path

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(val: float):
		_dive_progress = val
		_dive_overlay.queue_redraw()
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var tween2: Tween = create_tween()
	tween2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween2.tween_method(func(val: float):
		_dive_progress = val
		_dive_overlay.queue_redraw()
	, 1.0, 1.25, 0.15)
	await tween2.finished

	_dive_mode = DiveMode.NONE
	_dive_progress = 0.0
	_dive_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	_dive_overlay.queue_redraw()


## Inicia la transición 3D warp tunnel en retroceso (desenganche táctico hacia menú principal/padre).
func dive_out_to_scene(path: String, origin_pos: Vector2 = Vector2.ZERO, duration: float = 0.38) -> void:
	if _is_transitioning:
		return
	if DisplayServer.get_name() == "headless":
		fade_to_scene(path, 0.12)
		return

	_is_transitioning = true
	_dive_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_dive_mode = DiveMode.OUT
	_dive_progress = 0.0
	_dive_center = origin_pos
	_dive_target_path = path

	_dive_overlay.queue_redraw()
	await get_tree().process_frame

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(val: float):
		_dive_progress = val
		_dive_overlay.queue_redraw()
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

	_dive_mode = DiveMode.NONE
	_dive_progress = 0.0
	_dive_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	_dive_overlay.queue_redraw()


func _draw_dive_overlay(ci: CanvasItem) -> void:
	if _dive_mode == DiveMode.NONE:
		return
	var vp := ci.get_viewport_rect().size
	if _dive_mode == DiveMode.IN:
		_draw_dive_in(ci, vp)
	elif _dive_mode == DiveMode.OUT:
		_draw_dive_out(ci, vp)


func _draw_dive_in(ci: CanvasItem, vp: Vector2) -> void:
	var p := _dive_progress
	if p > 1.0:
		var flash_alpha := clampf((1.25 - p) / 0.25 * 0.95, 0.0, 0.95)
		ci.draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.85, 1.0, 1.0, flash_alpha))
		return

	var veil_alpha := clampf(p * 1.5, 0.0, 0.92)
	ci.draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.02, 0.05, 0.08, veil_alpha))

	var center := _dive_center
	if center == Vector2.ZERO:
		center = vp * 0.5

	var max_r := vp.length() * 0.9
	var warp_count := _dive_warp_angles.size()
	for i in range(warp_count):
		var ang: float = _dive_warp_angles[i] + p * 0.2
		var length_factor: float = 0.2 + fmod(float(i * 7) / float(warp_count), 0.8)
		var r_start: float = 20.0 + pow(p, 1.8) * max_r * length_factor * 0.5
		var r_end: float = r_start + (30.0 + p * 400.0 * length_factor)
		var dir := Vector2(cos(ang), sin(ang))
		var p0 := center + dir * r_start
		var p1 := center + dir * r_end
		var line_alpha: float = clampf((1.0 - p * 0.7) * 0.85, 0.0, 1.0)
		var col := Brand.with_alpha(Brand.ACCENT if (i % 3 == 0) else Brand.accent_dim(0.7), line_alpha)
		ci.draw_line(p0, p1, col, 1.5 + p * 2.0)

	for r_idx in range(4):
		var ring_p := fmod(p * 2.5 + float(r_idx) * 0.25, 1.0)
		var ring_r := pow(ring_p, 1.3) * max_r * 0.65
		var ring_alpha := (1.0 - ring_p) * 0.75 * (1.0 - p * 0.5)
		ci.draw_arc(center, ring_r, 0, TAU, 36, Brand.with_alpha(Brand.ACCENT, ring_alpha), 2.0)

	var ret_scale := 1.0 + p * 4.0
	var ret_r := 35.0 * ret_scale
	var ret_rot := _pulse * 3.0 + p * 6.0
	ci.draw_arc(center, ret_r, ret_rot, ret_rot + PI * 0.5, 12, Brand.with_alpha(Brand.ACCENT, 0.9), 2.0)
	ci.draw_arc(center, ret_r, ret_rot + PI, ret_rot + PI * 1.5, 12, Brand.with_alpha(Brand.ACCENT, 0.9), 2.0)
	ci.draw_line(center - Vector2(ret_r + 15, 0), center - Vector2(ret_r - 5, 0), Brand.ACCENT, 2.0)
	ci.draw_line(center + Vector2(ret_r - 5, 0), center + Vector2(ret_r + 15, 0), Brand.ACCENT, 2.0)
	ci.draw_line(center - Vector2(0, ret_r + 15), center - Vector2(0, ret_r - 5), Brand.ACCENT, 2.0)
	ci.draw_line(center + Vector2(0, ret_r - 5), center + Vector2(0, ret_r + 15), Brand.ACCENT, 2.0)

	var font := Brand.font_regular()
	var banner_y := vp.y * 0.50
	var title_txt := "[ BREACH PENETRATION // INITIATED ]"
	var tsize := font.get_string_size(title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	var banner_rect := Rect2(vp.x * 0.5 - tsize.x * 0.5 - 20, banner_y - 20, tsize.x + 40, 60)
	ci.draw_rect(banner_rect, Brand.with_alpha(Brand.PANEL_SOLID, 0.90))
	ci.draw_rect(banner_rect, Brand.with_alpha(Brand.ACCENT, 0.85), false, 1.5)
	ci.draw_string(font, Vector2(vp.x * 0.5 - tsize.x * 0.5, banner_y + 10), title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Brand.ACCENT)

	var target_tag := _dive_target_path if _dive_target_path != "" else "TARGET_SYSTEM"
	var sub_txt := "ESTABLISHING NEURAL LINK... 0x%08X" % (hash(target_tag) & 0xFFFFFFFF)
	var ssize := font.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	ci.draw_string(font, Vector2(vp.x * 0.5 - ssize.x * 0.5, banner_y + 32), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Brand.TEXT_DIM)

	if p > 0.65:
		var flash_alpha := ((p - 0.65) / 0.35) * 0.95
		ci.draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.85, 1.0, 1.0, flash_alpha))


func _draw_dive_out(ci: CanvasItem, vp: Vector2) -> void:
	var p := _dive_progress
	var inv_p := 1.0 - p

	var veil_alpha := clampf(inv_p * 0.92, 0.0, 0.92)
	ci.draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.02, 0.05, 0.08, veil_alpha))

	var center := _dive_center
	if center == Vector2.ZERO:
		center = vp * 0.5

	var max_r := vp.length() * 0.9
	var warp_count := _dive_warp_angles.size()

	for i in range(warp_count):
		var ang: float = _dive_warp_angles[i] - p * 0.2
		var length_factor: float = 0.2 + fmod(float(i * 7) / float(warp_count), 0.8)
		var r_start: float = 20.0 + pow(inv_p, 1.8) * max_r * length_factor * 0.5
		var r_end: float = r_start + (30.0 + inv_p * 400.0 * length_factor)
		var dir := Vector2(cos(ang), sin(ang))
		var p0 := center + dir * r_start
		var p1 := center + dir * r_end
		var line_alpha: float = clampf(inv_p * 0.85, 0.0, 1.0)
		var col := Brand.with_alpha(Brand.ACCENT if (i % 3 == 0) else Brand.accent_dim(0.7), line_alpha)
		ci.draw_line(p0, p1, col, 1.5 + inv_p * 2.0)

	for r_idx in range(4):
		var ring_p := 1.0 - fmod(p * 2.5 + float(r_idx) * 0.25, 1.0)
		var ring_r := pow(ring_p, 1.3) * max_r * 0.65
		var ring_alpha := ring_p * 0.75 * (1.0 - p * 0.3)
		ci.draw_arc(center, ring_r, 0, TAU, 36, Brand.with_alpha(Brand.ACCENT, ring_alpha), 2.0)

	var ret_scale := 3.5 - p * 2.5
	var ret_r := 35.0 * ret_scale
	var ret_rot := _pulse * 3.0 - p * 6.0
	ci.draw_arc(center, ret_r, ret_rot, ret_rot + PI * 0.5, 12, Brand.with_alpha(Brand.ACCENT, 0.9 * inv_p), 2.0)
	ci.draw_arc(center, ret_r, ret_rot + PI, ret_rot + PI * 1.5, 12, Brand.with_alpha(Brand.ACCENT, 0.9 * inv_p), 2.0)
	ci.draw_line(center - Vector2(ret_r + 15, 0), center - Vector2(ret_r - 5, 0), Brand.with_alpha(Brand.ACCENT, inv_p), 2.0)
	ci.draw_line(center + Vector2(ret_r - 5, 0), center + Vector2(ret_r + 15, 0), Brand.with_alpha(Brand.ACCENT, inv_p), 2.0)
	ci.draw_line(center - Vector2(0, ret_r + 15), center - Vector2(0, ret_r - 5), Brand.with_alpha(Brand.ACCENT, inv_p), 2.0)
	ci.draw_line(center + Vector2(0, ret_r - 5), center + Vector2(0, ret_r + 15), Brand.with_alpha(Brand.ACCENT, inv_p), 2.0)

	var font := Brand.font_regular()
	var banner_y := vp.y * 0.50
	var title_txt := "[ BREACH EGRESS // DISENGAGING ]"
	var tsize := font.get_string_size(title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
	var banner_rect := Rect2(vp.x * 0.5 - tsize.x * 0.5 - 20, banner_y - 20, tsize.x + 40, 60)
	ci.draw_rect(banner_rect, Brand.with_alpha(Brand.PANEL_SOLID, 0.90 * inv_p))
	ci.draw_rect(banner_rect, Brand.with_alpha(Brand.ACCENT, 0.85 * inv_p), false, 1.5)
	ci.draw_string(font, Vector2(vp.x * 0.5 - tsize.x * 0.5, banner_y + 10), title_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Brand.with_alpha(Brand.ACCENT, inv_p))

	var sub_txt := "DISCONNECTING NEURAL LINK... RETURNING TO SECURE BASELINE"
	var ssize := font.get_string_size(sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	ci.draw_string(font, Vector2(vp.x * 0.5 - ssize.x * 0.5, banner_y + 32), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Brand.with_alpha(Brand.TEXT_DIM, inv_p))

	if p < 0.28:
		var flash_alpha := (1.0 - (p / 0.28)) * 0.90
		ci.draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0.85, 1.0, 1.0, flash_alpha))
