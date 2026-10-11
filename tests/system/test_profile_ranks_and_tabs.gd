extends Node

## Test Suite: Profile Ranks and Multi-World Tabs
## Verifies that operator rank tier calculation in Spanish and multi-world tabs work as expected.

const ProfileScript = preload("res://escenas/menu/profile.gd")
const ProfileRendererScript = preload("res://escenas/menu/profile_renderer.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST PROFILE RANKS AND TABS ---")
	test_rank_calculation()
	test_multi_world_level_rows()
	test_profile_tab_switching()

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


func test_rank_calculation() -> void:
	var r0 := ProfileRendererScript.get_rank_info(0)
	_assert(r0["title"] == "INICIADO" and r0["tier"] == "RANGO I", "0 stars gives INICIADO RANGO I")

	var r1 := ProfileRendererScript.get_rank_info(6)
	_assert(r1["title"] == "OPERADOR DE RED" and r1["tier"] == "RANGO II", "6 stars gives OPERADOR DE RED RANGO II")

	var r2 := ProfileRendererScript.get_rank_info(15)
	_assert(r2["title"] == "ESPECIALISTA EN INTRUSIÓN" and r2["tier"] == "RANGO III", "15 stars gives ESPECIALISTA EN INTRUSIÓN RANGO III")

	var r3 := ProfileRendererScript.get_rank_info(22)
	_assert(r3["title"] == "ÉLITE CIBERNÉTICA" and r3["tier"] == "RANGO IV", "22 stars gives ÉLITE CIBERNÉTICA RANGO IV")

	var r4 := ProfileRendererScript.get_rank_info(35)
	_assert(r4["title"] == "FANTASMA DE RED" and r4["tier"] == "RANGO V", "35 stars gives FANTASMA DE RED RANGO V")


func test_multi_world_level_rows() -> void:
	var rows_heist := ProfileScript.build_level_rows("heist", null, null)
	_assert(rows_heist.size() == 5, "Heist has 5 mission rows")

	var rows_hacker := ProfileScript.build_level_rows("hacker", null, null)
	_assert(rows_hacker.size() == 5, "Hacker has 5 mission rows")

	var rows_cyber := ProfileScript.build_level_rows("cybersecurity", null, null)
	_assert(rows_cyber.size() == 2, "Cybersecurity has 2 mission rows")


func test_profile_tab_switching() -> void:
	var profile = ProfileScript.new()
	add_child(profile)

	_assert(profile._active_tab_idx == 0, "Initial active tab is 0 (Heist)")
	_assert(profile.stats["levels_detail"].size() == 5, "Initial details correspond to Heist (5 rows)")

	# Switch to Hacker (tab 1)
	profile._set_active_tab(1)
	_assert(profile._active_tab_idx == 1, "Active tab switched to 1 (Hacker)")
	_assert(profile.stats["levels_detail"].size() == 5, "Hacker details loaded (5 rows)")

	# Switch to Cybersecurity (tab 2)
	profile._set_active_tab(2)
	_assert(profile._active_tab_idx == 2, "Active tab switched to 2 (Cybersecurity)")
	_assert(profile.stats["levels_detail"].size() == 2, "Cybersecurity details loaded (2 rows)")

	# Switch to Badges (tab 3)
	profile._set_active_tab(3)
	_assert(profile._active_tab_idx == 3, "Active tab switched to 3 (Badges)")
	_assert(profile.stats["levels_detail"].size() == 0, "Badges tab levels_detail is empty (0 rows)")
	_assert(profile.stats.has("badges") and profile.stats["badges"].size() == 10, "Badges tab contains 10 evaluated badges")

	profile.queue_free()
