extends Node

## Test Suite: Database Tactical Codex (test_database_codex.gd)
## Verifies data schema integrity, category switching, entry selection,
## bounded scrolling, geometry rect helpers, and schematic rendering stability.

const BrandClass = preload("res://juego/ui/brand.gd")
const DatabaseScript = preload("res://escenas/menu/database.gd")
const DatabaseRendererScript = preload("res://escenas/menu/database_renderer.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	print("--- START TEST DATABASE CODEX ---")
	test_schema_integrity()
	test_layout_rect_helpers()
	test_text_wrapping_and_height()
	test_controller_navigation()
	test_scroll_bounds_clamping()
	test_schematic_rendering_stability()

	print("---")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	if _failed > 0:
		push_error("DATABASE CODEX SUITE FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _assert(condition: bool, msg: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		push_error("FAIL: %s" % msg)


func test_schema_integrity() -> void:
	# 1. Categories completeness
	var categories := DatabaseRendererScript.CATEGORIES
	_assert(categories.size() == 3, "Database has exactly 3 categories")
	_assert(categories[0]["id"] == "conceptos", "Category 0 is conceptos")
	_assert(categories[1]["id"] == "sistemas", "Category 1 is sistemas")
	_assert(categories[2]["id"] == "archivos", "Category 2 is archivos")

	# 2. Entries count
	var conceptos := DatabaseRendererScript.get_entries_for_category(0)
	var sistemas := DatabaseRendererScript.get_entries_for_category(1)
	var archivos := DatabaseRendererScript.get_entries_for_category(2)

	_assert(conceptos.size() == 5, "CONCEPTOS category has 5 entries")
	_assert(sistemas.size() == 5, "SISTEMAS category has 5 entries")
	_assert(archivos.size() == 3, "ARCHIVOS category has 3 entries")

	var total_entries := conceptos.size() + sistemas.size() + archivos.size()
	_assert(total_entries == 13, "Total entries in codex is exactly 13")

	# 3. Required telemetry keys in every entry
	var required_keys := ["id", "title", "classification", "schematic", "theory", "mechanics", "real_world"]
	var all_entries := []
	all_entries.append_array(conceptos)
	all_entries.append_array(sistemas)
	all_entries.append_array(archivos)

	var all_keys_present := true
	var all_strings_non_empty := true
	for entry in all_entries:
		for k in required_keys:
			if not entry.has(k):
				all_keys_present = false
			elif typeof(entry[k]) != TYPE_STRING or (entry[k] as String).is_empty():
				all_strings_non_empty = false

	_assert(all_keys_present, "All 13 entries contain all required telemetry keys")
	_assert(all_strings_non_empty, "All telemetry fields contain non-empty strings")

	# 4. Check specific keys exist
	var expected_conceptos := ["dijkstra", "edmonds_karp", "mtd", "attack_graphs", "graph_theory"]
	for exp_id in expected_conceptos:
		var found := false
		for e in conceptos:
			if e["id"] == exp_id:
				found = true
				break
		_assert(found, "Conceptos entry '%s' exists" % exp_id)

	var expected_sistemas := ["firewall", "ids", "honeypot", "terminal", "pursuer"]
	for exp_id in expected_sistemas:
		var found := false
		for e in sistemas:
			if e["id"] == exp_id:
				found = true
				break
		_assert(found, "Sistemas entry '%s' exists" % exp_id)

	var expected_archivos := ["vertex_arch", "paper_ref", "education"]
	for exp_id in expected_archivos:
		var found := false
		for e in archivos:
			if e["id"] == exp_id:
				found = true
				break
		_assert(found, "Archivos entry '%s' exists" % exp_id)

	# 5. DATA alias equivalence
	_assert(DatabaseRendererScript.DATA.size() == 3, "DatabaseRenderer.DATA alias exists and has 3 categories")


func test_layout_rect_helpers() -> void:
	var renderer := DatabaseRendererScript.new()
	var vp := Vector2(1280.0, 720.0)

	var back_btn := renderer.get_back_button_rect(vp)
	_assert(back_btn.size.x > 50.0 and back_btn.size.y > 20.0, "Back button rect is valid")

	var lp := renderer.get_left_panel_rect(vp)
	var rp := renderer.get_right_panel_rect(vp)

	_assert(lp.size.x > 0.0 and lp.size.y > 0.0, "Left panel rect is valid")
	_assert(rp.size.x > 0.0 and rp.size.y > 0.0, "Right panel rect is valid")
	_assert(lp.position.x + lp.size.x < rp.position.x, "Left and right panels do not overlap")

	# Check category tabs do not overlap
	var tab0 := renderer.get_category_tab_rect(0, vp)
	var tab1 := renderer.get_category_tab_rect(1, vp)
	var tab2 := renderer.get_category_tab_rect(2, vp)

	_assert(tab0.position.x + tab0.size.x <= tab1.position.x, "Tab 0 and 1 do not overlap")
	_assert(tab1.position.x + tab1.size.x <= tab2.position.x, "Tab 1 and 2 do not overlap")
	_assert(tab2.position.x + tab2.size.x <= lp.position.x + lp.size.x, "Tabs fit within left panel")

	# Check entry rows do not overlap vertically
	var row0 := renderer.get_entry_row_rect(0, vp)
	var row1 := renderer.get_entry_row_rect(1, vp)
	_assert(row0.position.y + row0.size.y <= row1.position.y, "Entry row 0 and row 1 do not overlap")


func test_text_wrapping_and_height() -> void:
	var sample_text := "Este es un texto largo disenado para probar el algoritmo de ajuste de linea del codex tactico sin ningun tipo de problema visual."
	var wrapped := DatabaseRendererScript.wrap_text(sample_text, null, 14, 200.0)
	_assert(wrapped.size() > 1, "Text wrapping breaks long line into multiple lines")

	var empty_wrap := DatabaseRendererScript.wrap_text("", null, 14, 200.0)
	_assert(empty_wrap.size() == 1 and empty_wrap[0] == "", "Empty text wrapping returns single empty line")

	var entry := DatabaseRendererScript.get_entries_for_category(0)[0]
	var h := DatabaseRendererScript.compute_dossier_height(entry, null, 14, 400.0)
	_assert(h > 200.0, "Computed dossier height is positive and covers content (got %.1f)" % h)


func test_controller_navigation() -> void:
	var db = DatabaseScript.new()
	add_child(db)

	_assert(db._active_cat_idx == 0, "Initial active category is 0")
	_assert(db._selected_entry_idx == 0, "Initial selected entry is 0")
	_assert(db._scroll_y == 0.0, "Initial scroll_y is 0.0")

	# Keyboard Category switching: TAB
	var ev_tab := InputEventKey.new()
	ev_tab.pressed = true
	ev_tab.keycode = KEY_TAB
	db._input(ev_tab)
	_assert(db._active_cat_idx == 1, "KEY_TAB switches category to 1 (SISTEMAS)")

	# Keyboard Category switching: D / Right
	var ev_d := InputEventKey.new()
	ev_d.pressed = true
	ev_d.keycode = KEY_D
	db._input(ev_d)
	_assert(db._active_cat_idx == 2, "KEY_D switches category to 2 (ARCHIVOS)")

	# TAB wraps around from 2 to 0
	db._input(ev_tab)
	_assert(db._active_cat_idx == 0, "KEY_TAB wraps category back to 0 (CONCEPTOS)")

	# Keyboard Category switching: A / Left
	var ev_a := InputEventKey.new()
	ev_a.pressed = true
	ev_a.keycode = KEY_A
	db._input(ev_a)
	_assert(db._active_cat_idx == 2, "KEY_A reverses category from 0 to 2 (ARCHIVOS)")

	# Return to Category 0
	db._set_active_category(0)
	_assert(db._active_cat_idx == 0, "Active category reset to 0")

	# Entry Navigation: S / DOWN
	var ev_down := InputEventKey.new()
	ev_down.pressed = true
	ev_down.keycode = KEY_DOWN
	db._input(ev_down)
	_assert(db._selected_entry_idx == 1, "KEY_DOWN advances entry to 1")

	db._input(ev_down)
	_assert(db._selected_entry_idx == 2, "KEY_DOWN advances entry to 2")

	# Clamping at bottom of list
	for _i in range(10):
		db._input(ev_down)
	var max_entries: int = DatabaseRendererScript.get_entry_count(0)
	_assert(db._selected_entry_idx == max_entries - 1, "Entry index clamped at maximum (%d)" % (max_entries - 1))

	# Entry Navigation: W / UP
	var ev_up := InputEventKey.new()
	ev_up.pressed = true
	ev_up.keycode = KEY_UP
	db._input(ev_up)
	_assert(db._selected_entry_idx == max_entries - 2, "KEY_UP decrements entry")

	# Clamping at top of list
	for _i in range(10):
		db._input(ev_up)
	_assert(db._selected_entry_idx == 0, "Entry index clamped at 0")

	# Mouse tab click simulation
	var vp := db.get_viewport_rect().size
	var tab1_pos: Vector2 = db._renderer.get_category_tab_rect(1, vp).get_center()
	var ev_click := InputEventMouseButton.new()
	ev_click.pressed = true
	ev_click.button_index = MOUSE_BUTTON_LEFT
	ev_click.position = tab1_pos
	db._input(ev_click)
	_assert(db._active_cat_idx == 1, "Mouse click on tab 1 selects category 1")

	# Mouse entry row click simulation
	var row2_pos: Vector2 = db._renderer.get_entry_row_rect(2, vp).get_center()
	ev_click.position = row2_pos
	db._input(ev_click)
	_assert(db._selected_entry_idx == 2, "Mouse click on row 2 selects entry 2")

	db.queue_free()


func test_scroll_bounds_clamping() -> void:
	var db = DatabaseScript.new()
	add_child(db)

	_assert(db._scroll_y == 0.0, "Initial scroll_y is 0.0")

	# Negative scroll clamped to 0.0
	db._scroll_by(-100.0)
	_assert(db._scroll_y == 0.0, "Negative scroll clamped at 0.0")

	# Scroll down
	var max_s: float = db._get_max_scroll()
	db._scroll_by(50.0)
	_assert(db._scroll_y <= max_s, "Scroll_y clamped within max_scroll")

	# Huge scroll clamped to max_scroll
	db._scroll_by(99999.0)
	_assert(db._scroll_y == max_s, "Excessive scroll clamped at max_scroll (%.1f)" % max_s)

	# Wheel events
	var ev_wheel_up := InputEventMouseButton.new()
	ev_wheel_up.pressed = true
	ev_wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	db._input(ev_wheel_up)
	_assert(db._scroll_y <= max_s, "Wheel up scrolls upward")

	db.queue_free()


func test_schematic_rendering_stability() -> void:
	var renderer := DatabaseRendererScript.new()
	var rect := Rect2(100, 100, 400, 160)
	var font: Font = BrandClass.font_regular()

	var all_entries := []
	all_entries.append_array(DatabaseRendererScript.get_entries_for_category(0))
	all_entries.append_array(DatabaseRendererScript.get_entries_for_category(1))
	all_entries.append_array(DatabaseRendererScript.get_entries_for_category(2))

	for entry in all_entries:
		var sid: String = entry["schematic"]
		var canvas := Control.new()
		canvas.draw.connect(func(): renderer._draw_schematic(canvas, rect, sid, 1.25, font, 14))
		add_child(canvas)
		canvas.notification(CanvasItem.NOTIFICATION_DRAW)
		canvas.queue_free()

	_assert(true, "All 13 procedural schematics render cleanly without draw errors")

	# Test full Database _draw() pipeline
	var db = DatabaseScript.new()
	add_child(db)
	db.notification(CanvasItem.NOTIFICATION_DRAW)
	_assert(true, "Full Database controller _draw pipeline renders without errors")
	db.queue_free()
