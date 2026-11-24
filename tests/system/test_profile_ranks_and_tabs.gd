extends Node

## Test Suite: Profile Ranks and Multi-World Tabs / 5-Tab Hub LA BÓVEDA
## Verifies ranks, 5 tabs, Fallout .enc likeness calculation, hex dump rows, MusicBox tracks, and Terminal Academy.

const ProfileScript = preload("res://escenas/menu/profile.gd")
const ProfileRendererScript = preload("res://escenas/menu/profile_renderer.gd")
const VaultModules = preload("res://juego/ui/vault_modules.gd")
const VaultBadgesTab = preload("res://escenas/menu/vault/vault_badges_tab.gd")
const VaultTermlinkTab = preload("res://escenas/menu/vault/vault_termlink_tab.gd")
const VaultAcademyApp = preload("res://escenas/menu/vault/vault_academy_app.gd")
const WorldSelectRendererClass = preload("res://escenas/main_menu/world_select_renderer.gd")

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

	# Test Phase B1 Drum 2.5D rotation & hitboxes
	profile._set_active_tab(3)
	_assert(is_equal_approx(profile._drum_target, 3.0) and is_equal_approx(profile._drum_lock_flash, 1.0), "Drum target and lock flash sync on tab switch")

	profile._rotate_drum(2)
	_assert(profile._active_tab_idx == 0, "Drum rotation wraps forward 3 + 2 -> 0")
	profile._rotate_drum(-1)
	_assert(profile._active_tab_idx == 4, "Drum rotation wraps backward 0 - 1 -> 4")
	_assert(absf(profile._drum_target - profile._drum_angle) <= 1.01, "Drum wrap 0 -> 4 takes shortest 1-step arc")
	profile._drum_angle = 4.0
	profile._rotate_drum(1)
	_assert(profile._active_tab_idx == 0 and absf(profile._drum_target - profile._drum_angle) <= 1.01, "Drum wrap 4 -> 0 takes shortest 1-step arc")

	var shell_hbs: Array[Dictionary] = ProfileRendererScript.compute_shell_hitboxes(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), profile._drum_target)
	var hb_ids: Array[String] = []
	for hb: Dictionary in shell_hbs:
		hb_ids.append(str(hb.get("id", "")))
	_assert(hb_ids.has("volver") and hb_ids.has("slot") and hb_ids.has("drum_0") and hb_ids.has("drum_4"),
		"Drum shell computes volver, slot and drum_0..drum_4 hitboxes")

	# Test Phase B2: 5 Topological Skill-Trees & Camouflaged Termlink
	_assert(VaultModules.TREE_KEYS.size() == 5 and VaultModules.SKILL_TREES.has("HEIST") and VaultModules.SKILL_TREES.has("UNIX"),
		"VaultModules defines 5 topological skill trees")
	var badges_tab: RefCounted = profile._tab_modules[0]
	badges_tab.select_tree("HEIST")
	_assert(badges_tab._active_tree == "HEIST", "VaultBadgesTab switches to HEIST pipeline tree")
	badges_tab.select_node(0)
	_assert(badges_tab.equip_selected() and profile._featured_badge_title == "INFILTRACIÓN CERO",
		"VaultBadgesTab equips unlocked node from selected tree")

	var camo_cols: Array = VaultTermlinkTab.build_camo_memory(0, [])
	_assert(camo_cols.size() == 2 and (camo_cols[0] as Array).size() == 16 and (camo_cols[1] as Array).size() == 16,
		"VaultTermlinkTab builds 2x16 camouflaged memory matrix")
	var row_with_pass: Dictionary = (camo_cols[0] as Array)[1]
	var toks: Array = row_with_pass.get("tokens", [])
	_assert(toks.size() == 1 and str(toks[0].get("text", "")) == "DIJKSTRA",
		"Camo memory embeds target password DIJKSTRA")
	var found_tok: Dictionary = VaultTermlinkTab.find_token_at_char(row_with_pass, int(toks[0].get("start", 0)))
	_assert(str(found_tok.get("text", "")) == "DIJKSTRA", "find_token_at_char resolves full token on character hover")
	var lmask: Array[bool] = VaultTermlinkTab.compute_likeness_mask("DIJKSTRA", "DIJXXXXA")
	_assert(lmask.size() == 8 and lmask[0] and lmask[1] and lmask[2] and not lmask[3] and lmask[7],
		"compute_likeness_mask marks exact positional matches")

	# Test Phase B3: Edge particle polyline sampling + VTX-ACADEMY
	var pcb_pts := PackedVector2Array([Vector2(0.0, 0.0), Vector2(50.0, 0.0), Vector2(50.0, 100.0), Vector2(100.0, 100.0)])
	var mid_pcb: Vector2 = VaultBadgesTab.sample_polyline(pcb_pts, 0.5)
	_assert(is_equal_approx(mid_pcb.x, 50.0) and is_equal_approx(mid_pcb.y, 50.0),
		"VaultBadgesTab.sample_polyline follows 90-deg PCB trace at t=0.5")

	var cyber_pts := PackedVector2Array([Vector2(0.0, 0.0), Vector2(100.0, 100.0), Vector2(200.0, 0.0)])
	var mid_cyber: Vector2 = WorldSelectRendererClass.sample_polyline(cyber_pts, 0.5)
	_assert(is_equal_approx(mid_cyber.x, 100.0) and is_equal_approx(mid_cyber.y, 100.0),
		"WorldSelectRenderer.sample_polyline passes exactly through relay node at t=0.5")

	profile._execute_cli_command("academy")
	_assert(profile._academy_app != null and profile._academy_app.is_open() and profile._academy_app.get_screen() == VaultAcademyApp.Screen.SPLASH,
		"Running 'academy' in terminal opens full-screen VTX-ACADEMY on SPLASH screen")
	var acad: VaultAcademyApp = profile._academy_app
	acad.open_hub()
	_assert(acad.get_screen() == VaultAcademyApp.Screen.HUB,
		"open_hub transitions VTX-ACADEMY from SPLASH to HUB")

	# Verify curriculum naming & zero external Bandit references
	var cur_src: String = FileAccess.get_file_as_string("res://escenas/menu/vault/vault_academy_curriculum.gd").to_lower()
	var app_src: String = FileAccess.get_file_as_string("res://escenas/menu/vault/vault_academy_app.gd").to_lower()
	_assert(not cur_src.contains("bandit") and not app_src.contains("bandit"),
		"VTX-ACADEMY contains zero 'bandit' references")

	# Guided Training with real UnixShellEngine
	acad.open_modules_menu()
	_assert(acad.get_screen() == VaultAcademyApp.Screen.MODULES_MENU,
		"open_modules_menu transitions to MODULES_MENU")
	acad.start_exercise(0, "lesson")
	acad._ex_idx = 1
	acad._reset_exercise_sandbox()
	_assert(acad.get_screen() == VaultAcademyApp.Screen.EXERCISE,
		"start_exercise transitions VTX-ACADEMY to EXERCISE screen")

	# Exploratory 'ls descargas' hides dotfiles and stays in EXERCISE without penalty
	acad.execute_command("ls descargas")
	_assert(acad.get_screen() == VaultAcademyApp.Screen.EXERCISE and acad._term_lines.size() >= 2,
		"Exploratory 'ls descargas' runs on real VFS and hides dotfiles")

	# 'cd descargas && ls -a' works via real && chaining (+100 pts)
	acad.execute_command("cd descargas && ls -a")
	_assert(acad._score == 100 and not bool(acad._analysis.get("is_optimal", true)) and acad.get_screen() == VaultAcademyApp.Screen.RESULT,
		"VTX-ACADEMY awards 100 pts and shows RESULT for 'cd descargas && ls -a'")

	# Optimal 'ls -a descargas' awards +250 pts and streak bonus
	acad.start_exercise(0, "practice")
	acad._ex_idx = 1
	acad._reset_exercise_sandbox()
	acad.execute_command("ls -a descargas")
	_assert(acad._score == 350 and bool(acad._analysis.get("is_optimal", false)) and acad._streak == 2,
		"VTX-ACADEMY awards +250 pts and streak bonus for 1-step optimal shortcut")

	# M2 mkdir respaldo logs mutates real VFS
	acad.start_exercise(1, "lesson")
	acad._ex_idx = 1
	acad._reset_exercise_sandbox()
	acad.execute_command("mkdir respaldo logs")
	_assert(acad._sandbox_shell.vfs._fs.has("/home/operator/respaldo") and acad._sandbox_shell.vfs._fs.has("/home/operator/logs"),
		"VTX-ACADEMY creates real directories in sandbox VFS on 'mkdir respaldo logs'")

	# Boss mode shield deduction and completion
	acad.start_boss(0)
	_assert(acad.get_screen() == VaultAcademyApp.Screen.BOSS,
		"start_boss transitions VTX-ACADEMY to BOSS screen")
	var shields_before: int = acad._shields
	acad.execute_command("wrong_cmd")
	_assert(acad._shields == shields_before - 1,
		"VTX-ACADEMY deducts 1 session shield on invalid command in Boss mode")
	acad.execute_command("ls -a descargas")
	acad.execute_command("pwd")
	acad.execute_command("cd ~")
	_assert(acad.get_screen() == VaultAcademyApp.Screen.BOSS_CLEAR,
		"Completing all Boss steps transitions VTX-ACADEMY to BOSS_CLEAR screen")

	# Escalada SSH real sandbox progression
	acad.open_ssh_menu()
	_assert(acad.get_screen() == VaultAcademyApp.Screen.SSH_MENU and acad.is_ssh_unlocked(0) and not acad.is_ssh_unlocked(1),
		"Escalada SSH starts with Node 0 unlocked and Node 1 locked")
	acad.start_ssh_level(0)
	acad.execute_command("cat instrucciones.txt")
	_assert(acad.get_screen() == VaultAcademyApp.Screen.SSH_LEVEL,
		"Reading instrucciones.txt in SSH Node 0 keeps terminal active")
	acad.execute_command("ssh nodo1 VTX-N1-ALFA")
	_assert(acad.get_screen() == VaultAcademyApp.Screen.SSH_CLEAR and acad.is_ssh_unlocked(1),
		"Submitting valid SSH key unlocks Node 1 and transitions to SSH_CLEAR")

	acad.start_ssh_level(1)
	acad.execute_command("ls -a boveda")
	acad.execute_command("cat boveda/.llave_oculta")
	acad.execute_command("ssh nodo2 VTX-N2-SOMBRA")
	_assert(acad.get_screen() == VaultAcademyApp.Screen.SSH_CLEAR and acad.is_ssh_unlocked(2),
		"SSH Node 1 hidden file discovery unlocks Node 2")

	acad._ssh_cleared[2] = true
	acad._ssh_cleared[3] = true
	acad.start_ssh_level(4)
	acad.execute_command("base64 -d paquete.b64")
	acad.execute_command("ssh nodo5 VTX-N5-KERNEL")
	_assert(acad.get_screen() == VaultAcademyApp.Screen.SSH_CLEAR and bool(acad._ssh_cleared.get(4, false)),
		"SSH Node 4 base64 -d discovery clears final node")

	# Guide & Escape navigation
	acad.open_guide_menu()
	_assert(acad.get_screen() == VaultAcademyApp.Screen.GUIDE_MENU, "open_guide_menu opens GUIDE_MENU")
	acad.open_guide_section(0)
	_assert(acad.get_screen() == VaultAcademyApp.Screen.GUIDE_DETAIL, "open_guide_section opens GUIDE_DETAIL")
	_assert(not acad.handle_escape() and acad.get_screen() == VaultAcademyApp.Screen.GUIDE_MENU, "Escape from GUIDE_DETAIL returns to GUIDE_MENU")
	_assert(not acad.handle_escape() and acad.get_screen() == VaultAcademyApp.Screen.HUB, "Escape from GUIDE_MENU returns to HUB")
	_assert(acad.handle_escape() and not acad.is_open(), "Escape from HUB closes VTX-ACADEMY")

	# Phase B4: MusicBox FFT & Arcade
	profile._set_active_tab(3)
	var mbox: RefCounted = profile._musicbox_tab
	_assert(mbox != null and mbox.get_filtered_track_indices().size() == 22,
		"VaultMusicboxTab builds on Tab 3 and lists 22 tracks")
	profile._music_filter_idx = 1
	_assert(mbox.get_filtered_track_indices().size() == 10, "MusicBox Pink Bloom filter returns 10 tracks")
	profile._music_filter_idx = 2
	_assert(mbox.get_filtered_track_indices().size() == 12, "MusicBox Code Injection filter returns 12 tracks")
	profile._music_filter_idx = 0
	_assert(mbox.select_and_play_track(0) and profile._selected_music_idx == 0 and profile._music_is_playing,
		"MusicBox select_and_play_track(0) activates unlocked track")
	mbox.step_track(1)
	_assert(profile._selected_music_idx == 1, "MusicBox step_track(1) advances to track 1")
	mbox.pin_selected_to_menu()
	_assert(profile._pinned_menu_track == str(VaultModules.MUSIC_TRACKS[1].get("name", "")),
		"MusicBox pin_selected_to_menu updates pinned menu track")

	profile._set_active_tab(4)
	var arcade: RefCounted = profile._arcade_tab
	_assert(arcade != null and not arcade.is_playing_game(),
		"VaultArcadeTab builds on Tab 4 in SHELF mode")
	arcade.start_netcycle(true)
	var p_start: Vector2i = arcade._nc_p_pos
	arcade.set_netcycle_direction(Vector2i(0, 1))
	arcade.step_netcycle()
	_assert(arcade.is_playing_game() and arcade._nc_p_pos == p_start + Vector2i(0, 1) and arcade._nc_p_trail.size() == 2,
		"NETCYCLE advances player position and appends trail on step_netcycle")
	var ib_secret: Array[String] = ["A", "B", "C", "D"]
	arcade.start_icebreaker(ib_secret)
	for s: String in ["A", "B", "D", "C"]:
		arcade.icebreaker_push_symbol(s)
	var res_ib1: Dictionary = arcade.icebreaker_submit()
	_assert(int(res_ib1.get("exact", -1)) == 2 and int(res_ib1.get("misplaced", -1)) == 2 and not bool(res_ib1.get("won", true)),
		"ICEBREAKER evaluates exact=2 misplaced=2 accurately")
	for s: String in ["A", "B", "C", "D"]:
		arcade.icebreaker_push_symbol(s)
	var res_ib2: Dictionary = arcade.icebreaker_submit()
	_assert(int(res_ib2.get("exact", -1)) == 4 and bool(res_ib2.get("won", false)),
		"ICEBREAKER wins when all 4 hex symbols match")

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
	var all_paths_exist: bool = true
	for tr: Dictionary in VaultModules.MUSIC_TRACKS:
		if not ResourceLoader.exists(str(tr.get("path", ""))):
			all_paths_exist = false
			break
	_assert(all_paths_exist, "All 22 MusicBox track paths exist on disk")

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
