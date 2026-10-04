extends Node

## Unit tests for PauseOverlay lifecycle, view switching, audio sliders, and pause integration.

const PauseOverlayClass = preload("res://juego/ataque/pause_overlay.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST PAUSE OVERLAY ---")
	_test_instantiation_and_defaults()
	_test_view_switching()
	_test_signals()
	_test_audio_sliders()
	_test_tree_pausing()
	_finish()


func _test_instantiation_and_defaults() -> void:
	var overlay = PauseOverlayClass.new()
	add_child(overlay)

	_assert(overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "PauseOverlay process_mode is PROCESS_MODE_ALWAYS")
	_assert(not overlay.visible, "PauseOverlay is hidden by default")
	_assert(not overlay.is_overlay_visible(), "is_overlay_visible() reports false")
	_assert(overlay.current_view == "main", "Default current_view is 'main'")
	_assert(overlay.resume_button != null, "Resume button exists")
	_assert(overlay.restart_button != null, "Restart button exists")
	_assert(overlay.options_button != null, "Options button exists")
	_assert(overlay.level_select_button != null, "Level select button exists")
	_assert(overlay.menu_button != null, "Main menu button exists")

	overlay.queue_free()


func _test_view_switching() -> void:
	var overlay = PauseOverlayClass.new()
	add_child(overlay)

	overlay.show_overlay("main")
	_assert(overlay.visible, "show_overlay('main') makes overlay visible")
	_assert(overlay.current_view == "main", "current_view is 'main'")
	_assert(overlay._main_box.visible, "Main box is visible")
	_assert(not overlay._confirm_box.visible, "Confirm box is hidden")
	_assert(not overlay._options_box.visible, "Options box is hidden")

	overlay.show_restart_confirm()
	_assert(overlay.current_view == "confirm", "show_restart_confirm() switches to 'confirm'")
	_assert(not overlay._main_box.visible, "Main box hidden in confirm view")
	_assert(overlay._confirm_box.visible, "Confirm box visible in confirm view")
	_assert(overlay.confirm_label.text.contains("Reiniciar"), "Confirm prompt text is set")

	overlay.show_options()
	_assert(overlay.current_view == "options", "show_options() switches to 'options'")
	_assert(not overlay._main_box.visible, "Main box hidden in options view")
	_assert(not overlay._confirm_box.visible, "Confirm box hidden in options view")
	_assert(overlay._options_box.visible, "Options box visible in options view")

	overlay.hide_overlay()
	_assert(not overlay.visible, "hide_overlay() hides overlay")
	_assert(not overlay.is_overlay_visible(), "is_overlay_visible() returns false")

	overlay.queue_free()


func _test_signals() -> void:
	var overlay = PauseOverlayClass.new()
	add_child(overlay)

	var emitted: Array[String] = []

	overlay.resumed.connect(func(): emitted.append("resumed"))
	overlay.restart_confirmed.connect(func(): emitted.append("restart"))
	overlay.level_select_requested.connect(func(): emitted.append("level_select"))
	overlay.main_menu_requested.connect(func(): emitted.append("menu"))

	overlay.resume_button.pressed.emit()
	_assert("resumed" in emitted, "resume_button emits resumed signal")

	overlay.confirm_restart_button.pressed.emit()
	_assert("restart" in emitted, "confirm_restart_button emits restart_confirmed signal")

	overlay.level_select_button.pressed.emit()
	_assert("level_select" in emitted, "level_select_button emits level_select_requested signal")

	overlay.menu_button.pressed.emit()
	_assert("menu" in emitted, "menu_button emits main_menu_requested signal")

	overlay.queue_free()


func _test_audio_sliders() -> void:
	var overlay = PauseOverlayClass.new()
	add_child(overlay)

	var master_idx: int = AudioServer.get_bus_index("Master")
	var music_idx: int = AudioServer.get_bus_index("Music")
	var sfx_idx: int = AudioServer.get_bus_index("SFX")

	if master_idx >= 0:
		overlay.master_slider.value = 50.0
		var expected_db: float = linear_to_db(0.5)
		var actual_db: float = AudioServer.get_bus_volume_db(master_idx)
		_assert(absf(actual_db - expected_db) < 0.05, "Master slider updates AudioServer Master bus volume")
		_assert(overlay.master_val_label.text == "50%", "Master value label displays 50%")

	if music_idx >= 0:
		overlay.music_slider.value = 25.0
		var expected_db: float = linear_to_db(0.25)
		var actual_db: float = AudioServer.get_bus_volume_db(music_idx)
		_assert(absf(actual_db - expected_db) < 0.05, "Music slider updates AudioServer Music bus volume")
		_assert(overlay.music_val_label.text == "25%", "Music value label displays 25%")

	if sfx_idx >= 0:
		overlay.sfx_slider.value = 75.0
		var expected_db: float = linear_to_db(0.75)
		var actual_db: float = AudioServer.get_bus_volume_db(sfx_idx)
		_assert(absf(actual_db - expected_db) < 0.05, "SFX slider updates AudioServer SFX bus volume")
		_assert(overlay.sfx_val_label.text == "75%", "SFX value label displays 75%")

	overlay.queue_free()


func _test_tree_pausing() -> void:
	var overlay = PauseOverlayClass.new()
	add_child(overlay)

	get_tree().paused = false
	overlay.show_overlay("main")
	get_tree().paused = true
	_assert(get_tree().paused, "Tree can be paused while overlay is active")
	_assert(overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "PauseOverlay has PROCESS_MODE_ALWAYS")

	# Simulating unpause on resume
	overlay.resumed.connect(func(): get_tree().paused = false)
	overlay.resume_button.pressed.emit()
	_assert(not get_tree().paused, "Emitting resume signal unpauses the tree")

	get_tree().paused = false
	overlay.queue_free()


func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("PASS: %s" % msg)
		passed += 1
	else:
		print("FAIL: %s" % msg)
		failed += 1


func _finish() -> void:
	get_tree().paused = false
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
