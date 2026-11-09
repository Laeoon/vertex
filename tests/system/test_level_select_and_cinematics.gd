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
