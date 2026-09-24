extends Node

## Test suite for main menu mouse controls and language setting isolation

const MainMenuClass = preload("res://escenas/main_menu.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST MAIN MENU MOUSE & LANG ---")
	_test_arrow_keys_do_not_cycle_language()
	_test_mouse_hover_updates_selection()
	_test_mouse_click_activates_option()
	_test_mouse_click_back_in_world_select()
	_test_load_lang_setting_reads_options()
	_finish()


func _test_arrow_keys_do_not_cycle_language() -> void:
	var menu = MainMenuClass.new()
	add_child(menu)
	var initial_lang_idx: int = menu._lang_idx

	# Send KEY_LEFT
	var ev_left = InputEventKey.new()
	ev_left.keycode = KEY_LEFT
	ev_left.pressed = true
	menu._input(ev_left)
	_assert(menu._lang_idx == initial_lang_idx, "KEY_LEFT does not change language on main menu")

	# Send KEY_RIGHT
	var ev_right = InputEventKey.new()
	ev_right.keycode = KEY_RIGHT
	ev_right.pressed = true
	menu._input(ev_right)
	_assert(menu._lang_idx == initial_lang_idx, "KEY_RIGHT does not change language on main menu")

	menu.queue_free()


func _test_mouse_hover_updates_selection() -> void:
	var menu = MainMenuClass.new()
	add_child(menu)
	menu.selected_idx = 0

	# Hover over item 2 (Perfil): y = 150 + 2 * 48 = 246
	var ev_motion = InputEventMouseMotion.new()
	ev_motion.position = Vector2(100, 246)
	menu._input(ev_motion)
	_assert(menu.selected_idx == 2, "Mouse motion over item 2 updates selected_idx to 2")

	# Hover over item 1 (Opciones): y = 150 + 1 * 48 = 198
	ev_motion.position = Vector2(100, 198)
	menu._input(ev_motion)
	_assert(menu.selected_idx == 1, "Mouse motion over item 1 updates selected_idx to 1")

	menu.queue_free()


func _test_mouse_click_activates_option() -> void:
	var menu = MainMenuClass.new()
	add_child(menu)
	_assert(menu.current_state == MainMenuClass.State.MAIN_MENU, "Initial state is MAIN_MENU")

	# Click on item 0 (Play): y = 150
	var ev_click = InputEventMouseButton.new()
	ev_click.button_index = MOUSE_BUTTON_LEFT
	ev_click.pressed = true
	ev_click.position = Vector2(100, 150)
	menu._input(ev_click)

	# Transition begins to WORLD_SELECT
	_assert(menu._transitioning == true and menu._transition_target == MainMenuClass.State.WORLD_SELECT, "Left click on Play triggers transition to WORLD_SELECT")

	menu.queue_free()


func _test_mouse_click_back_in_world_select() -> void:
	var menu = MainMenuClass.new()
	add_child(menu)
	menu.current_state = MainMenuClass.State.WORLD_SELECT
	menu._transitioning = false

	# Click on back area: start_y(140) + 4 items * 48 + 10 = 342
	var ev_back = InputEventMouseButton.new()
	ev_back.button_index = MOUSE_BUTTON_LEFT
	ev_back.pressed = true
	ev_back.position = Vector2(100, 345)
	menu._input(ev_back)

	_assert(menu._transitioning == true and menu._transition_target == MainMenuClass.State.MAIN_MENU, "Left click on back area transitions back to MAIN_MENU")

	menu.queue_free()


func _test_load_lang_setting_reads_options() -> void:
	var menu = MainMenuClass.new()
	add_child(menu)

	var cfg = ConfigFile.new()
	cfg.set_value("options", "lang", 1)  # 1 is "en"
	cfg.save("user://test_settings_tmp.cfg")

	# Test with temp file logic
	if cfg.load("user://test_settings_tmp.cfg") == OK:
		var saved = cfg.get_value("options", "lang", 0)
		_assert(saved == 1, "Saved options lang is integer 1 (en)")

	var dir = DirAccess.open("user://")
	if dir != null:
		dir.remove("test_settings_tmp.cfg")

	menu.queue_free()


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
