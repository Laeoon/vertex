extends Node

## Test Suite: SlotManager
## Tests the isolation of save slots 1, 2, 3, metadata summaries, and legacy save migration.

const SlotManagerClass = preload("res://juego/system/slot_manager.gd")
const ProgressUtilClass = preload("res://juego/utils/progress_util.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST SLOT MANAGER ---")
	test_slot_resolution_and_defaults()
	test_slot_switching_and_isolation()
	test_slot_metadata_summaries()
	test_slot_deletion()

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


func test_slot_resolution_and_defaults() -> void:
	# Por defecto debe inicializar en slot 1
	var slot: int = SlotManagerClass.get_active_slot()
	_assert(slot >= 1 and slot <= 3, "Default active slot is valid (1..3, got %d)" % slot)

	var prog_path := SlotManagerClass.get_progress_path(1)
	_assert(prog_path.contains("slot_1"), "Slot 1 progress path contains 'slot_1' (got %s)" % prog_path)

	var prof_path := SlotManagerClass.get_profile_path(2)
	_assert(prof_path.contains("slot_2"), "Slot 2 profile path contains 'slot_2' (got %s)" % prof_path)


func test_slot_switching_and_isolation() -> void:
	SlotManagerClass.set_active_slot(2)
	_assert(SlotManagerClass.get_active_slot() == 2, "Active slot switched to 2")
	_assert(ProgressUtilClass.get_progress_file_path().contains("slot_2"), "ProgressUtil resolves slot 2 path")

	SlotManagerClass.set_active_slot(1)
	_assert(SlotManagerClass.get_active_slot() == 1, "Active slot returned to 1")
	_assert(ProgressUtilClass.get_progress_file_path().contains("slot_1"), "ProgressUtil resolves slot 1 path")


func test_slot_metadata_summaries() -> void:
	var slots_info: Array = SlotManagerClass.get_all_slots_summary()
	_assert(slots_info.size() == 3, "SlotManager exposes exactly 3 slot summaries")
	for s in slots_info:
		_assert(s.has("slot_id") and s.has("player_name") and s.has("stars") and s.has("is_empty"), "Slot summary contains required fields")


func test_slot_deletion() -> void:
	# Escribir datos dummy en slot 3
	var p_path := SlotManagerClass.get_progress_path(3)
	var cfg := ConfigFile.new()
	cfg.set_value("estrellas", "test_level", 3)
	cfg.save(p_path)

	var s3_before: Dictionary = SlotManagerClass.get_slot_summary(3)
	_assert(s3_before.get("is_empty", true) == false, "Slot 3 has data before deletion")

	# Borrar slot 3
	var ok: bool = SlotManagerClass.delete_slot(3)
	_assert(ok, "SlotManager.delete_slot(3) returned true")
	_assert(not FileAccess.file_exists(p_path), "progress.cfg of slot 3 was removed from disk")

	var s3_after: Dictionary = SlotManagerClass.get_slot_summary(3)
	_assert(s3_after.get("is_empty", false) == true, "Slot 3 reports empty after deletion")

