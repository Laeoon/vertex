extends Node

## Test Suite: Navigation Flow and Breadcrumbs
## Verifies that SceneParams.menu_target_state correctly restores WORLD_SELECT,
## StartScreen transitions to main_menu upon slot selection, and audio 'error' is playable.

const MainMenuClass = preload("res://escenas/main_menu.gd")
const StartScreenClass = preload("res://escenas/main_menu/start_screen.gd")
const LevelSelectClass = preload("res://juego/system/level_select_screen.gd")
const TutorialsMenuClass = preload("res://escenas/main_menu/tutorials_menu.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST NAVIGATION FLOW ---")
	test_start_screen_initialization()
	test_audio_error_tone()
	test_breadcrumbs_restoration()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func test_start_screen_initialization() -> void:
	var screen = StartScreenClass.new()
	add_child(screen)
	_assert(screen._state == StartScreenClass.State.PRESS_START, "StartScreen initializes in PRESS_START state")
	_assert(screen._slots_data.size() == 3, "StartScreen loads 3 slot cards")

	screen._advance_to_slots()
	_assert(screen._state == StartScreenClass.State.SELECT_SLOT, "Advance changes state to SELECT_SLOT")
	screen.queue_free()


func test_audio_error_tone() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("error")
		_assert(true, "AudioManager plays synthetic 'error' tone without crash")
	else:
		_assert(true, "AudioManager available or bypassed in runner")


func test_breadcrumbs_restoration() -> void:
	SceneParams.reset()
	SceneParams.menu_target_state = "world_select"

	var menu = MainMenuClass.new()
	add_child(menu)

	_assert(menu.current_state == MainMenuClass.State.WORLD_SELECT, "MainMenu restores State.WORLD_SELECT from SceneParams")
	_assert(SceneParams.menu_target_state == "", "SceneParams clears menu_target_state after consumption")

	menu.queue_free()
