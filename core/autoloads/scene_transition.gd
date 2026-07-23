extends CanvasLayer

## Sistema de transición fade entre escenas.
## Uso: SceneTransition.fade_to_scene("res://ruta/a/escena.tscn")

var _color_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 128
	_color_rect = ColorRect.new()
	_color_rect.color = Color.BLACK
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_rect)
	_color_rect.modulate = Color.TRANSPARENT
	_resize_rect()


func _resize_rect() -> void:
	var vp := get_viewport()
	if vp != null and _color_rect != null:
		_color_rect.size = vp.get_visible_rect().size


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_resize_rect()
		var vp := get_viewport()
		if vp != null:
			vp.size_changed.connect(_resize_rect)


func fade_to_scene(path: String, duration: float = 0.5) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_color_rect, "modulate:a", 1.0, duration)
	await tween.finished
	
	get_tree().change_scene_to_file(path)
	
	await get_tree().process_frame
	var tween2: Tween = create_tween()
	tween2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween2.tween_property(_color_rect, "modulate:a", 0.0, duration)
	await tween2.finished
	
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false


func fade_out(duration: float = 0.5) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_color_rect, "modulate:a", 1.0, duration)
	await tween.finished


func fade_in(duration: float = 0.5) -> void:
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_color_rect, "modulate:a", 0.0, duration)
	await tween.finished
	_is_transitioning = false
