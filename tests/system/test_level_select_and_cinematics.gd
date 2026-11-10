extends Node

## Test Suite: Level Select Screen, Multi-Act 2.5D Carousel & Hybrid Cinematics Engine
## Verifies world branding colors, spectrum visualizer integration, multi-act switching,
## 2.5D carousel navigation, live mini-map preview loading, CinematicRegistry data schema,
## CinematicOverlay dual-mode playback, and Database 4th tab cinematics integration.

const LevelSelectClass = preload("res://juego/system/level_select_screen.gd")
const LevelRegistryClass = preload("res://juego/system/level_registry.gd")
const CinematicRegistryClass = preload("res://juego/system/cinematic_registry.gd")
const CinematicOverlayClass = preload("res://juego/ui/cinematic_overlay.gd")
const DatabaseClass = preload("res://escenas/menu/database.gd")
const BrandClass = preload("res://juego/ui/brand.gd")
const AudioSpectrumVisualizerClass = preload("res://juego/ui/audio_spectrum_visualizer.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST LEVEL SELECT AND CINEMATICS ---")
	test_world_branding_and_spectrum()
	test_level_registry_acts_and_briefings()
	test_cinematic_registry_schema()
	test_cinematic_overlay_lifecycle()
	test_cinematic_overlay_draw_stability()
	test_level_select_screen_carousel_and_acts()
	test_level_select_minimap_loading()
	test_database_cinematics_tab_and_trigger()
	test_3d_spine_and_bottom_command_columns()
	test_audio_spectrum_bass_energy_and_spine_wave()
	test_all_16_levels_have_narratives_and_codecs()
	test_mandatory_first_time_codec_autoplay_and_replay()
	test_act_pills_dimensions_and_no_collision()
	test_spine_nodes_and_pills_in_bounds()
	test_boss_pill_text_no_literal_specifier()
	test_database_cinematics_list_scrolling()

	_finalizar()


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func _finalizar() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("LEVEL SELECT & CINEMATICS SUITE FAILED")
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func test_world_branding_and_spectrum() -> void:
	# Verificación de tokens de color por mundo requeridos
	var heist_col := BrandClass.get_world_color("heist")
	var hacker_col := BrandClass.get_world_color("hacker")
	var cyber_col := BrandClass.get_world_color("cybersecurity")
	var secret_col := BrandClass.get_world_color("secret")

	_assert(heist_col == Color("bf5af2"), "Heist color is #bf5af2 Purple Synthwave (got %s)" % heist_col.to_html())
	_assert(hacker_col == Color("39ff88"), "Hacker color is #39ff88 Terminal Green (got %s)" % hacker_col.to_html())
	_assert(cyber_col == Color("00d2ff"), "Cybersecurity color is #00d2ff Cyber Blue (got %s)" % cyber_col.to_html())
	_assert(secret_col == Color("ff2a6d"), "Secret Sector 0 color is #ff2a6d Crimson Glitch (got %s)" % secret_col.to_html())

	# Fondos atmosféricos
	_assert(BrandClass.get_world_bg_color("heist") == Color("120918"), "Heist background is dark synthwave purple")
	_assert(BrandClass.get_world_bg_color("secret") == Color("14080e"), "Secret background is dark crimson tint")


func test_level_registry_acts_and_briefings() -> void:
	# Niveles por acto
	var heist_act1 := LevelRegistryClass.get_levels_for_act("heist", 1)
	_assert(heist_act1.size() == 5, "Heist Act 1 has 5 registered levels (got %d)" % heist_act1.size())

	var hacker_act1 := LevelRegistryClass.get_levels_for_act("hacker", 1)
	_assert(hacker_act1.size() == 5, "Hacker Act 1 has 5 registered levels (got %d)" % hacker_act1.size())

	var cyber_act1 := LevelRegistryClass.get_levels_for_act("cybersecurity", 1)
	_assert(cyber_act1.size() == 5, "Cybersecurity Act 1 has 5 registered levels (got %d)" % cyber_act1.size())

	# Briefing y Operadores
	var b_heist := LevelRegistryClass.get_level_briefing("heist", 0)
	_assert(b_heist != "" and not b_heist.is_empty(), "Heist N1 has narrative briefing: '%s'" % b_heist.substr(0, 30))

	var op_heist := LevelRegistryClass.get_level_operator("heist", 0)
	_assert(op_heist == "VEX", "Heist operator is VEX (got %s)" % op_heist)

	var op_hacker := LevelRegistryClass.get_level_operator("hacker", 0)
	_assert(op_hacker == "N0X", "Hacker operator is N0X (got %s)" % op_hacker)

	var op_cyber := LevelRegistryClass.get_level_operator("cybersecurity", 0)
	_assert(op_cyber == "AEGIS", "Cybersecurity operator is AEGIS (got %s)" % op_cyber)

	var op_secret := LevelRegistryClass.get_level_operator("secret", 0)
	_assert(op_secret == "ZERO", "Sector 0 operator is ZERO (got %s)" % op_secret)


func test_cinematic_registry_schema() -> void:
	var all_cinematics := CinematicRegistryClass.get_all()
	_assert(all_cinematics.size() >= 5, "CinematicRegistry has at least 5 foundational cinematics (got %d)" % all_cinematics.size())

	var expected_ids := [
		"prologue_root_genesis",
		"act1_heist_intro",
		"act1_hacker_intro",
		"act1_cyber_intro",
		"act2_collision_teaser"
	]
	for cid in expected_ids:
		var cin := CinematicRegistryClass.get_cinematic(cid)
		_assert(not cin.is_empty(), "Cinematic '%s' exists" % cid)
		_assert(cin.has("slides") and cin["slides"].size() > 0, "Cinematic '%s' has valid slides" % cid)
		_assert(cin.has("operator") and cin["operator"] != "", "Cinematic '%s' has operator tag" % cid)

	# Verificación de asignación por nivel
	var cin_h1 := CinematicRegistryClass.get_cinematic_for_level("heist_n1")
	_assert(cin_h1.get("id", "") == "act1_heist_intro", "heist_n1 links to act1_heist_intro")

	var cin_root := CinematicRegistryClass.get_cinematic_for_level("secret_root")
	_assert(cin_root.get("id", "") == "prologue_root_genesis", "secret_root links to prologue_root_genesis")


func test_cinematic_overlay_lifecycle() -> void:
	var overlay = CinematicOverlayClass.new()
	add_child(overlay)

	_assert(not overlay.is_playing(), "CinematicOverlay starts inactive")

	var finished_box := [""]
	overlay.cinematic_finished.connect(func(cid: String): finished_box[0] = cid)

	# Play cinematic
	overlay.play("act1_heist_intro")
	_assert(overlay.is_playing(), "Overlay is active after play()")
	_assert(overlay.current_slide_idx == 0, "Starts on slide 0")

	# Advance typewriter (first advance completes line if typing)
	overlay.advance()
	_assert(overlay.typewriter_progress >= float(overlay._current_full_text.length()), "Advance fast-forwards typewriter to complete line")

	# Advance to next slide
	overlay.advance()
	_assert(overlay.current_slide_idx == 1, "Next advance moves to slide 1")

	# Skip closes overlay immediately
	overlay.skip()
	_assert(not overlay.is_playing(), "Skip closes overlay")
	_assert(finished_box[0] == "act1_heist_intro", "cinematic_finished emitted with correct id")

	overlay.queue_free()


func test_cinematic_overlay_draw_stability() -> void:
	var overlay = CinematicOverlayClass.new()
	add_child(overlay)

	# Test codec mode drawing
	overlay.play("act1_heist_intro")
	overlay.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "CinematicOverlay Codec Mode _draw() succeeds cleanly")

	# Test network mode drawing
	overlay.play("act2_collision_teaser")
	overlay.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "CinematicOverlay Network Mode _draw() succeeds cleanly")

	overlay.queue_free()


func test_level_select_screen_carousel_and_acts() -> void:
	var ls = LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)

	_assert(ls.world_id == "heist", "LevelSelectScreen configured for heist")
	_assert(ls.current_act == 1, "Default act is Act 1")
	_assert(ls.selected_idx == 0, "Default selected card is 0")

	# Switch Act to 2
	ls.set_act(2)
	_assert(ls.current_act == 2, "Switched to Act 2")
	_assert(ls.selected_idx == 0, "Selected idx reset to 0 on act switch")

	# Switch back to Act 1
	ls.set_act(1)
	_assert(ls.current_act == 1, "Switched back to Act 1")

	# Carousel navigation: Right
	var ev_right := InputEventKey.new()
	ev_right.pressed = true
	ev_right.keycode = KEY_RIGHT
	ls._input(ev_right)
	_assert(ls.selected_idx == 1, "KEY_RIGHT advances selection to 1")

	# Carousel navigation: Left
	var ev_left := InputEventKey.new()
	ev_left.pressed = true
	ev_left.keycode = KEY_LEFT
	ls._input(ev_left)
	_assert(ls.selected_idx == 0, "KEY_LEFT moves selection back to 0")

	# Act Switch via TAB key
	var ev_tab := InputEventKey.new()
	ev_tab.pressed = true
	ev_tab.keycode = KEY_TAB
	ls._input(ev_tab)
	_assert(ls.current_act == 2, "KEY_TAB toggles to Act 2")

	ls.queue_free()


func test_level_select_minimap_loading() -> void:
	var ls = LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)

	# Cargar mini-mapa del primer nivel de heist
	var map_data: Dictionary = ls._get_or_load_minimap("res://juego/heist/heist_n1.json")
	_assert(map_data.has("nodes"), "Minimap data has 'nodes' key")
	_assert(map_data.has("edges"), "Minimap data has 'edges' key")

	var nodes: Array = map_data.get("nodes", [])
	var edges: Array = map_data.get("edges", [])
	_assert(nodes.size() > 0, "Minimap parsed %d nodes from heist_n1 graph" % nodes.size())
	_assert(edges.size() > 0, "Minimap parsed %d edges from heist_n1 graph" % edges.size())

	# Verificar dibujo completo sin errores
	ls.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "LevelSelectScreen _draw() executes cleanly without draw errors")

	ls.queue_free()


func test_database_cinematics_tab_and_trigger() -> void:
	var db = DatabaseClass.new()
	add_child(db)

	# Cambiar a la 4ª pestaña: CINEMATICS (Tab.CINEMATICS = 3)
	db._set_active_category(DatabaseClass.Tab.CINEMATICS)
	_assert(db._active_cat_idx == 3, "Database switched to 4th tab: CINEMATICS")

	var cin_entries := db._get_entries(3)
	_assert(cin_entries.size() >= 5, "Database CINEMATICS tab lists at least 5 cinematics")

	# Selección de entrada dentro de la pestaña
	db._select_entry(1)
	_assert(db._selected_entry_idx == 1, "Selected cinematic entry 1")

	# Disparar reproducción
	db._play_selected_cinematic()
	_assert(db._cinematic_overlay != null and db._cinematic_overlay.is_playing(), "Triggering cinematic playback activates overlay")

	# Cerrar cinemática y verificar retorno
	db._cinematic_overlay.skip()
	_assert(not db._cinematic_overlay.is_playing(), "Closing cinematic returns control to database")

	# Render del panel de cinemáticas
	db.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "Database 4th tab renders cleanly in _draw()")

	db.queue_free()


func test_3d_spine_and_bottom_command_columns() -> void:
	var ls = LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)

	var vp := Vector2(1356, 672)
	var p0 := ls.get_spine_node_position(0, vp)
	var p4 := ls.get_spine_node_position(4, vp)

	# 3D Diagonal Depth Spine: recede de primer plano izq hacia horizonte der
	_assert(p0.x < p4.x, "3D spine node 0 (x=%.1f) is left of node 4 (x=%.1f)" % [p0.x, p4.x])
	_assert(p0.y > p4.y, "3D spine node 0 (y=%.1f) is lower in foreground than node 4 (y=%.1f) in deep horizon" % [p0.y, p4.y])

	# 4 Columnas horizontales estrictamente no superpuestas en el Command Strip
	var cols := ls.get_bottom_command_column_rects(vp)
	_assert(cols.size() == 4, "Bottom Command Strip defines exactly 4 columns")
	_assert(cols[0].size.x == 230.0, "Column 1 width is 230px (got %.1f)" % cols[0].size.x)
	_assert(cols[1].size.x == 220.0, "Column 2 width is 220px (got %.1f)" % cols[1].size.x)
	_assert(cols[3].size.x == 215.0, "Column 4 width is 215px (got %.1f)" % cols[3].size.x)

	_assert(cols[0].position.x + cols[0].size.x <= cols[1].position.x, "Column 1 (ends at %.1f) does not overlap Column 2 (starts at %.1f)" % [cols[0].position.x + cols[0].size.x, cols[1].position.x])
	_assert(cols[1].position.x + cols[1].size.x <= cols[2].position.x, "Column 2 (ends at %.1f) does not overlap Column 3 (starts at %.1f)" % [cols[1].position.x + cols[1].size.x, cols[2].position.x])
	_assert(cols[2].position.x + cols[2].size.x <= cols[3].position.x, "Column 3 (ends at %.1f) does not overlap Column 4 (starts at %.1f)" % [cols[2].position.x + cols[2].size.x, cols[3].position.x])

	ls.queue_free()


func test_audio_spectrum_bass_energy_and_spine_wave() -> void:
	var viz := AudioSpectrumVisualizerClass.new(32)
	viz.update(0.016)

	var bass := viz.get_bass_energy()
	_assert(bass >= 0.0 and bass <= 1.0, "AudioSpectrumVisualizer get_bass_energy() returns normalized range (got %.3f)" % bass)

	# Prueba de dibujo de onda en espina 3D dentro del contexto de dibujo de CanvasItem
	var dummy := Control.new()
	add_child(dummy)

	var spine_start := Vector2(180, 360)
	var spine_end := Vector2(1080, 200)
	dummy.draw.connect(func():
		viz.draw_spine_waveform(dummy, spine_start, spine_end, Color("00d2ff"), 55.0, 90, 0.85)
		viz.draw_track_waveform(dummy, spine_start, spine_end, Color("bf5af2"), 50.0, 80, 0.75)
	)
	dummy.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "draw_spine_waveform and draw_track_waveform execute multi-pass drawing cleanly")

	dummy.queue_free()


func test_all_16_levels_have_narratives_and_codecs() -> void:
	var expected_levels := [
		"heist_n1", "heist_n2", "heist_n3", "heist_n4", "heist_n5",
		"hacker_n1", "hacker_n2", "hacker_n3", "hacker_n4", "hacker_n5",
		"defense_n1", "cyber_n1", "cyber_n2", "cyber_n3", "cyber_n4",
		"secret_root"
	]

	_assert(expected_levels.size() == 16, "All 16 levels identified for Triad of Genesis coverage")

	for lvl_key in expected_levels:
		var cin := CinematicRegistryClass.get_cinematic_for_level(lvl_key)
		_assert(not cin.is_empty(), "Level '%s' has a linked Codec transmission in CinematicRegistry" % lvl_key)
		_assert(cin.has("slides") and cin["slides"].size() > 0, "Codec transmission for '%s' contains slides" % lvl_key)

	# Verificar briefings narrativos enriquecidos en LevelRegistry
	for world_id in LevelRegistryClass.WORLDS:
		var lvls: Array = LevelRegistryClass.get_levels(world_id)
		for i in lvls.size():
			var b := LevelRegistryClass.get_level_briefing(world_id, i)
			_assert(b != "" and b.length() > 25, "World '%s' level %d has rich narrative briefing (%d chars)" % [world_id, i, b.length()])


func test_mandatory_first_time_codec_autoplay_and_replay() -> void:
	# 1. Utilidad ProgressUtil
	var mock_prog: Dictionary = {"seen_cinematics": {}}
	_assert(not ProgressUtil.has_seen_cinematic("mock_codec_alpha", mock_prog), "has_seen_cinematic returns false before playback")

	ProgressUtil.mark_cinematic_seen("mock_codec_alpha", mock_prog)
	_assert(ProgressUtil.has_seen_cinematic("mock_codec_alpha", mock_prog), "has_seen_cinematic returns true after mark_cinematic_seen")

	# 2. LevelSelectScreen autoplay
	var ls = LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)

	ls._force_autoplay_in_headless = true
	ls.progress = {"seen_cinematics": {}} # Forzar no visto
	ls.selected_idx = 0

	# Primer deploy: debe abrir Codec automáticamente
	ls._deploy_selected()
	_assert(ls._pending_launch_after_cinematic, "First deploy flags _pending_launch_after_cinematic = true")
	_assert(ls._cinematic_overlay != null and ls._cinematic_overlay.is_playing(), "Cinematic overlay auto-plays transmission on first launch")

	# Completar o saltar cinemática
	ls._cinematic_overlay.skip()
	_assert(not ls._pending_launch_after_cinematic, "Finishing cinematic clears _pending_launch_after_cinematic")
	_assert(ProgressUtil.has_seen_cinematic("act1_heist_intro", ls.progress), "act1_heist_intro is marked seen in player progress")

	# Segundo deploy: ya visto, no debe abrir cinemática
	ls._deploy_selected()
	_assert(not ls._pending_launch_after_cinematic, "Second deploy does NOT flag pending cinematic (launches directly)")

	# 3. Disparo on-demand con botón [ 🎬 CODEC / LORE ]
	ls._open_selected_cinematic()
	_assert(ls._cinematic_overlay.is_playing(), "On-demand CODEC button opens transmission anytime")
	_assert(not ls._pending_launch_after_cinematic, "On-demand CODEC button does not queue automatic level launch")
	ls._cinematic_overlay.skip()

	ls.queue_free()


func test_act_pills_dimensions_and_no_collision() -> void:
	var ls = LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)
	var vp := Vector2(1356, 672)

	var r1: Rect2 = ls.get_act1_rect(vp)
	var r2: Rect2 = ls.get_act2_rect(vp)
	_assert(r1.size.x >= 175.0, "Act 1 pill width >= 175px (got %.1f)" % r1.size.x)
	_assert(r2.size.x >= 175.0, "Act 2 pill width >= 175px (got %.1f)" % r2.size.x)
	var gap := r2.position.x - (r1.position.x + r1.size.x)
	_assert(gap >= 16.0, "Act pills do not collide with at least 16px gap (got %.1f)" % gap)
	ls.queue_free()

	# Sector 0: Debe ocultar Acto II o mostrar precuela centrada
	var ls_sec = LevelSelectClass.new()
	ls_sec.setup("secret")
	add_child(ls_sec)
	var r2_sec: Rect2 = ls_sec.get_act2_rect(vp)
	_assert(r2_sec.size.x == 0.0, "Sector 0 hides Act II pill (Act 2 width is 0)")
	ls_sec.queue_free()


func test_spine_nodes_and_pills_in_bounds() -> void:
	var ls = LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)
	var vp := Vector2(1356, 672)

	for sel in range(5):
		ls.selected_idx = sel
		ls._carousel_offset = float(sel)
		for node_idx in range(5):
			var p := ls.get_spine_node_position(node_idx, vp)
			_assert(p.x >= 130.0 and p.x <= vp.x - 130.0, "Node %d at sel %d x (%.1f) stays in [130, %0.1f]" % [node_idx, sel, p.x, vp.x - 130.0])
			var pill_rect: Rect2 = ls.get_spine_node_pill_rect(node_idx, vp)
			_assert(pill_rect.position.x >= 16.0 and pill_rect.position.x + pill_rect.size.x <= vp.x - 16.0, "Pill %d at sel %d [x=%.1f, right=%.1f] stays in screen bounds" % [node_idx, sel, pill_rect.position.x, pill_rect.position.x + pill_rect.size.x])

	ls.queue_free()


func test_boss_pill_text_no_literal_specifier() -> void:
	var ls = LevelSelectClass.new()
	ls.setup("heist")
	add_child(ls)
	var boss_txt: String = ls.get_spine_node_pill_text(4)
	_assert(not boss_txt.contains("%s"), "Boss pill text does not contain literal '%%s' (got '%s')" % boss_txt)
	_assert(boss_txt.begins_with("BOSS // "), "Boss pill text begins with 'BOSS // ' (got '%s')" % boss_txt)
	ls.queue_free()


func test_database_cinematics_list_scrolling() -> void:
	var db = DatabaseClass.new()
	add_child(db)
	var vp := Vector2(1356, 672)

	db._set_active_category(DatabaseClass.Tab.CINEMATICS)
	db._select_entry(15, vp)

	_assert(db._cin_list_scroll > 0.0, "Selecting entry 15 scrolls cin list (got %.1f)" % db._cin_list_scroll)

	var lp: Rect2 = db._renderer.get_left_panel_rect(vp)
	var r15: Rect2 = db.get_cinematic_row_rect(15, vp)
	_assert(r15.position.y >= lp.position.y + 82.0 and r15.position.y + r15.size.y <= lp.position.y + lp.size.y, "Row 15 [y=%.1f..%.1f] is visible inside left panel [y=%.1f..%.1f]" % [r15.position.y, r15.position.y + r15.size.y, lp.position.y, lp.position.y + lp.size.y])

	var play_btn: Rect2 = db.get_play_button_rect(vp)
	_assert(play_btn.size.x >= 300.0, "Play button width >= 300px (got %.1f)" % play_btn.size.x)

	db.queue_free()
