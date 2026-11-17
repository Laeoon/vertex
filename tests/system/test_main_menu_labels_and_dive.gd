extends Node

## Test determinista de etiquetas de menú principal e i18n
## y verificación de transiciones dive_in / dive_out universales en SceneTransition.

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- START TEST MAIN MENU LABELS & DIVE ---")
	_test_scene_transition_api()
	await _test_main_menu_labels()
	await _test_world_tabs_verification()
	_finalizar()


func _test_world_tabs_verification() -> void:
	var menu_scene = load("res://escenas/main_menu.tscn")
	var menu = menu_scene.instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame

	_afirmar(menu.get("_world_tab_idx") == 0, "Initial world_tab_idx is 0")
	var t0_items: Array = menu.get("_world_tab_0_items")
	_afirmar(t0_items.size() == 4, "Tab 0 has exactly 4 core worlds")
	var expected_tab0_ids := ["tutorials", "heist", "hacker", "cybersecurity"]
	for i in range(expected_tab0_ids.size()):
		_afirmar(t0_items[i].get("id") == expected_tab0_ids[i], "Tab 0 world[%d] id is '%s'" % [i, expected_tab0_ids[i]])

	menu._world_tab_idx = 1
	menu._world_items = menu._world_tab_1_items
	var t1_items: Array = menu.get("_world_tab_1_items")
	_afirmar(t1_items.size() == 2, "Tab 1 has exactly 2 expansion worlds")
	var expected_tab1_ids := ["sector0", "free_ops"]
	var expected_tab1_icons := ["omega", "network"]
	for i in range(expected_tab1_ids.size()):
		_afirmar(t1_items[i].get("id") == expected_tab1_ids[i], "Tab 1 world[%d] id is '%s'" % [i, expected_tab1_ids[i]])
		_afirmar(t1_items[i].get("vector_icon") == expected_tab1_icons[i], "Tab 1 world[%d] vector_icon is '%s'" % [i, expected_tab1_icons[i]])

	menu.queue_free()


func _test_scene_transition_api() -> void:
	var st = get_node_or_null("/root/SceneTransition")
	_afirmar(st != null, "SceneTransition singleton disponible")
	if st == null:
		return

	_afirmar(st.has_method("fade_to_scene"), "SceneTransition expone fade_to_scene")
	_afirmar(st.has_method("dive_in_to_scene"), "SceneTransition expone dive_in_to_scene")
	_afirmar(st.has_method("dive_out_to_scene"), "SceneTransition expone dive_out_to_scene")
	_afirmar(st.get("_dive_overlay") != null, "SceneTransition tiene overlay de dibujo dive")
	_afirmar(st.get("_dive_mode") == 0, "SceneTransition inicia con dive_mode NONE")


func _test_main_menu_labels() -> void:
	var menu_scene = load("res://escenas/main_menu.tscn")
	var menu = menu_scene.instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame

	var items: Array = menu.get("_main_items")
	_afirmar(items != null and items.size() == 6, "menu._main_items contiene exactamente 6 elementos")
	if items == null or items.size() != 6:
		menu.queue_free()
		return

	var expected_actions := ["play", "options", "credits", "database", "exit", "profile"]
	for i in range(expected_actions.size()):
		_afirmar(items[i].get("action") == expected_actions[i], "item[%d] action == '%s' (got '%s')" % [i, expected_actions[i], items[i].get("action")])

	var test_locales := {
		"es": {
			"play": "Jugar",
			"options": "Opciones",
			"credits": "Créditos",
			"database": "Database",
			"exit": "Salir",
			"profile": "BÓVEDA // PERFIL",
		},
		"en": {
			"play": "Play",
			"options": "Options",
			"credits": "Credits",
			"database": "Database",
			"exit": "Exit",
			"profile": "VAULT // PROFILE",
		},
		"pt": {
			"play": "Jogar",
			"options": "Opções",
			"credits": "Créditos",
			"database": "Database",
			"exit": "Sair",
			"profile": "COFRE // PERFIL",
		},
	}

	for lang in ["es", "en", "pt"]:
		LocUtil.set_locale(menu, lang)
		menu._refresh_texts()

		var action_map: Dictionary = {}
		for item in menu.get("_main_items"):
			action_map[item.get("action")] = item

		# Verificación crítica: database NUNCA debe decir "Salir" / "Exit" / "Sair"
		var db_item: Dictionary = action_map.get("database", {})
		_afirmar(db_item.get("label") != "Salir" and db_item.get("label") != "Exit" and db_item.get("label") != "Sair",
			"[%s] database nunca muestra texto de salida (got: '%s')" % [lang, db_item.get("label")])

		var expected_for_lang: Dictionary = test_locales[lang]
		for act in expected_actions:
			var it: Dictionary = action_map.get(act, {})
			var exp_label: String = expected_for_lang[act]
			_afirmar(it.get("label") == exp_label,
				"[%s] accion '%s' tiene label '%s' (got: '%s')" % [lang, act, exp_label, it.get("label")])
			_afirmar(it.get("desc") != "" and it.get("desc") != ("menu.%s_desc" % act),
				"[%s] accion '%s' tiene descripcion valida y localizada" % [lang, act])

	# Restaurar es
	LocUtil.set_locale(menu, "es")
	menu.queue_free()


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		push_error("FAIL: %s" % mensaje)
		failed += 1


func _finalizar() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
