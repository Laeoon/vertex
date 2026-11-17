extends Node

## Test Suite: Profile Ranks and Multi-World Tabs / 5-Tab Hub LA BÓVEDA
## Verifies ranks, 5 tabs, Fallout .enc likeness calculation, hex dump rows, MusicBox tracks, and Terminal Academy.

const ProfileScript = preload("res://escenas/menu/profile.gd")
const ProfileRendererScript = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST PROFILE RANKS AND TABS (5-TAB HUB) ---")
	test_rank_calculation()
	test_multi_world_level_rows()
	test_profile_tab_switching_5tabs()
	test_fallout_enc_and_hex_dump()
	test_musicbox_tracks_and_unlocks()
	test_node_cosmetics()
	test_terminal_academy()

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
	_assert(rows_cyber.size() == 5, "Cybersecurity has 5 mission rows")


func test_profile_tab_switching_5tabs() -> void:
	var profile = ProfileScript.new()
	add_child(profile)

	_assert(ProfileRendererScript.TABS.size() == 5, "Profile has exactly 5 tabs in LA BÓVEDA")
	_assert(profile._active_tab_idx == 0, "Initial active tab is 0 (Expediente)")

	# Switch tabs
	profile._set_active_tab(1)
	_assert(profile._active_tab_idx == 1, "Active tab switched to 1 (Decodificador)")

	profile._set_active_tab(2)
	_assert(profile._active_tab_idx == 2, "Active tab switched to 2 (Terminal Lab)")

	profile._set_active_tab(3)
	_assert(profile._active_tab_idx == 3, "Active tab switched to 3 (MusicBox)")

	profile._set_active_tab(4)
	_assert(profile._active_tab_idx == 4, "Active tab switched to 4 (Cosméticos)")

	# Test CLI course start & step progression
	profile.start_cli_course(0)
	_assert(profile._active_cli_course == 0 and profile._cli_course_step == 0, "CLI Course 0 started at step 0")
	profile._execute_cli_command("pwd")
	_assert(profile._cli_course_step == 1, "Running 'pwd' advances CLI course step to 1")

	# Test win_rate metric bounds (0..100)
	var win_r: float = float(profile.stats.get("win_rate", 0.0))
	_assert(win_r >= 0.0 and win_r <= 100.0, "win_rate is within 0..100 percentage range")

	profile.queue_free()


func test_fallout_enc_and_hex_dump() -> void:
	_assert(VaultModules.ENC_FILES.size() >= 4, "At least 4 .ENC dossier files available")
	_assert(VaultModules.BADGES.size() == 24, "Exactly 24 tactical badges registered")

	var hex_rows := VaultModules.build_hex_dump_rows(0)
	_assert(hex_rows.size() == 24, "Hex dump generates exactly 24 rows")
	_assert(str(hex_rows[0]["raw"]).length() == 20, "Hex dump row raw string has continuous length of 20 with zero spaces")


func test_musicbox_tracks_and_unlocks() -> void:
	_assert(VaultModules.MUSIC_TRACKS.size() == 22, "MusicBox contains exactly 22 DavidKBD tracks")
	_assert(VaultModules.MUSIC_TRACKS[0]["name"].contains("Pink Bloom"), "First track belongs to Pink Bloom pack")
	_assert(VaultModules.MUSIC_TRACKS[10]["pack"] == "Code Injection", "Track 11 belongs to Code Injection pack")

	var track_def := VaultModules.MUSIC_TRACKS[0]
	_assert(VaultModules.is_track_unlocked(track_def, [], [], {"total_stars": 0}), "Default track is unlocked by default")

	var locked_track := VaultModules.MUSIC_TRACKS[6]
	_assert(not VaultModules.is_track_unlocked(locked_track, [], [], {"total_stars": 0}), "Locked track is locked initially")
	_assert(VaultModules.is_track_unlocked(locked_track, ["heist_clear"], [], {"total_stars": 0}), "Locked track unlocks when badge condition is met")


func test_node_cosmetics() -> void:
	_assert(VaultModules.NODE_SKINS.size() == 5, "5 node skins available")
	_assert(VaultModules.NODE_SKINS[4]["id"] == "root_star", "Root Star node skin available")


func test_terminal_academy() -> void:
	_assert(VaultModules.TERMINAL_ACADEMY_LESSONS.size() == 4, "Terminal Academy has 4 modules")
	_assert(VaultModules.TERMINAL_ACADEMY_LESSONS[0]["module"] == 1, "Module 1 correctly indexed")
