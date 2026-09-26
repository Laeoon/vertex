extends Node

## Test suite for Options menu mouse interaction, slider dragging, toggle clicking and language cycling.

const OptionsClass = preload("res://escenas/menu/options.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST OPTIONS MOUSE & QOL ---")
	_test_mouse_tab_switching()
	_test_mouse_slider_drag()
	_test_mouse_toggle_click()
	_test_mouse_cycle_click()
	_finish()


func _test_mouse_tab_switching() -> void:
	var opt = OptionsClass.new()
	add_child(opt)

	# Verify tab rects were created in _ready
	_assert(opt._tab_rects.size() == 4, "Options has 4 tab rects")

	# Click on Tab 1 (Graphics)
	var tab1_pos: Vector2 = opt._tab_rects[1].get_center()
	var ev_click = InputEventMouseButton.new()
	ev_click.button_index = MOUSE_BUTTON_LEFT
	ev_click.pressed = true
	ev_click.position = tab1_pos
	opt._input(ev_click)
	_assert(opt._section_idx == 1, "Clicking tab 1 switches section to Graphics (index 1)")

	# Click on Tab 3 (Language)
	var tab3_pos: Vector2 = opt._tab_rects[3].get_center()
	ev_click.position = tab3_pos
	opt._input(ev_click)
	_assert(opt._section_idx == 3, "Clicking tab 3 switches section to Language (index 3)")

	opt.queue_free()


func _test_mouse_slider_drag() -> void:
	var opt = OptionsClass.new()
	add_child(opt)
	opt._section_idx = 0 # Audio section
	opt._item_idx = 0    # volume_master (0-100)

	var item: Dictionary = opt._sections[0].items[0]
	# Click on middle of slider bar (x = 320 + 90 = 410, y = 160)
	var ev_click = InputEventMouseButton.new()
	ev_click.button_index = MOUSE_BUTTON_LEFT
	ev_click.pressed = true
	ev_click.position = Vector2(410, 160)
	opt._input(ev_click)

	_assert(item.value == 50, "Clicking at 50% on slider sets value to 50 (got " + str(item.value) + ")")

	# Drag slider to 80% (x = 320 + 180 * 0.8 = 464)
	var ev_drag = InputEventMouseMotion.new()
	ev_drag.position = Vector2(464, 160)
	opt._input(ev_drag)

	_assert(item.value == 80, "Dragging slider to 80% sets value to 80 (got " + str(item.value) + ")")

	# Release mouse
	var ev_release = InputEventMouseButton.new()
	ev_release.button_index = MOUSE_BUTTON_LEFT
	ev_release.pressed = false
	ev_release.position = Vector2(464, 160)
	opt._input(ev_release)

	_assert(opt._is_dragging_slider == false, "Releasing mouse stops slider drag")

	opt.queue_free()


func _test_mouse_toggle_click() -> void:
	var opt = OptionsClass.new()
	add_child(opt)
	opt._section_idx = 1 # Graphics
	opt._item_idx = 0    # Fullscreen

	var item: Dictionary = opt._sections[1].items[0]
	var initial_val: bool = bool(item.value)

	# Click on toggle rect: x = 330, y = 160
	var ev_click = InputEventMouseButton.new()
	ev_click.button_index = MOUSE_BUTTON_LEFT
	ev_click.pressed = true
	ev_click.position = Vector2(330, 160)
	opt._input(ev_click)

	_assert(bool(item.value) != initial_val, "Clicking toggle flips value (was %s, now %s)" % [initial_val, item.value])

	opt.queue_free()


func _test_mouse_cycle_click() -> void:
	var opt = OptionsClass.new()
	add_child(opt)
	opt._section_idx = 3 # Language
	opt._item_idx = 0    # lang cycle

	var item: Dictionary = opt._sections[3].items[0]
	item.value = 0 # ES

	# Click next button [>] (pos.x around 422, y = 160)
	var ev_click = InputEventMouseButton.new()
	ev_click.button_index = MOUSE_BUTTON_LEFT
	ev_click.pressed = true
	ev_click.position = Vector2(422, 160)
	opt._input(ev_click)

	_assert(item.value == 1, "Clicking [>] advances language cycle from 0 to 1 (EN)")

	# Click prev button [<] (pos.x around 332, y = 160)
	ev_click.position = Vector2(332, 160)
	opt._input(ev_click)

	_assert(item.value == 0, "Clicking [<] reverses language cycle from 1 back to 0 (ES)")

	opt.queue_free()


func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("PASS: %s" % msg)
		passed += 1
	else:
		print("FAIL: %s" % msg)
		failed += 1


func _finish() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
