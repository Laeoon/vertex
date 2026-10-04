extends Node

## Test Suite: World Progression Lock
## Verifies that campaign worlds are locked until general and mode-specific tutorials are completed.

const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST WORLD PROGRESSION LOCK ---")
	test_tutorials_always_unlocked()
	test_campaign_worlds_locked_initially()
	test_general_tutorials_unlock_cybersecurity_only()
	test_heist_world_unlock()
	test_hacker_world_unlock()

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


func test_tutorials_always_unlocked() -> void:
	var empty_prog := {}
	_assert(ProgressUtilClass.is_world_unlocked("tutorials", empty_prog), "Tutorials world is always unlocked with 0 progress")
	_assert(ProgressUtilClass.get_world_lock_reason("tutorials", empty_prog) == "", "Tutorials lock reason is empty")


func test_campaign_worlds_locked_initially() -> void:
	var empty_prog := {}
	_assert(not ProgressUtilClass.is_world_unlocked("heist", empty_prog), "Heist world is locked on fresh profile")
	_assert(not ProgressUtilClass.is_world_unlocked("hacker", empty_prog), "Hacker world is locked on fresh profile")
	_assert(not ProgressUtilClass.is_world_unlocked("cybersecurity", empty_prog), "Cybersecurity world is locked on fresh profile")

	var reason := ProgressUtilClass.get_world_lock_reason("heist", empty_prog)
	_assert(reason.contains("GENERAL"), "Lock reason requires general tutorials: %s" % reason)


func test_general_tutorials_unlock_cybersecurity_only() -> void:
	var prog := {
		"tutorial1": 3,
		"tutorial3": 3
	}
	_assert(ProgressUtilClass.is_world_unlocked("cybersecurity", prog), "Cybersecurity unlocks after general tutorials (Defender in standby)")
	_assert(not ProgressUtilClass.is_world_unlocked("heist", prog), "Heist remains locked without heist tutorials")
	_assert(not ProgressUtilClass.is_world_unlocked("hacker", prog), "Hacker remains locked without hacker tutorials")

	var reason_heist := ProgressUtilClass.get_world_lock_reason("heist", prog)
	_assert(reason_heist.contains("HEIST"), "Heist lock reason requires heist tutorials: %s" % reason_heist)

	var reason_hacker := ProgressUtilClass.get_world_lock_reason("hacker", prog)
	_assert(reason_hacker.contains("HACKER"), "Hacker lock reason requires hacker tutorials: %s" % reason_hacker)


func test_heist_world_unlock() -> void:
	var prog := {
		"tutorial1": 3,
		"tutorial3": 3,
		"tutorial2": 3,
		"tutorial6": 3
	}
	_assert(ProgressUtilClass.is_world_unlocked("heist", prog), "Heist unlocks when general and heist tutorials are completed")
	_assert(ProgressUtilClass.get_world_lock_reason("heist", prog) == "", "Heist lock reason is empty when unlocked")
	_assert(not ProgressUtilClass.is_world_unlocked("hacker", prog), "Hacker remains locked when only heist is completed")


func test_hacker_world_unlock() -> void:
	var prog := {
		"tutorial1": 3,
		"tutorial3": 3,
		"tut_hacker_1": 3,
		"tut_hacker_2": 3,
		"tut_hacker_3": 3,
		"tut_hacker_4": 3
	}
	_assert(ProgressUtilClass.is_world_unlocked("hacker", prog), "Hacker unlocks when general and hacker tutorials are completed")
	_assert(ProgressUtilClass.get_world_lock_reason("hacker", prog) == "", "Hacker lock reason is empty when unlocked")
	_assert(not ProgressUtilClass.is_world_unlocked("heist", prog), "Heist remains locked when only hacker is completed")
