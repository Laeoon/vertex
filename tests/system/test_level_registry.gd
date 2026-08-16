extends Node

## Pruebas de lógica pura para LevelRegistry (juego/system/).
##
## Verifica que WORLDS esté bien formado y que cada nivel apunte a archivos
## que existen de verdad en disco (el JSON se valida a fondo en
## tests/system/test_levels_data.gd; acá solo contractual: estructura + rutas).

const Registry = preload("res://juego/system/level_registry.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_afirmar(Registry.WORLDS.keys().size() == 3,
		"WORLDS define exactamente 3 mundos: %s" % str(Registry.WORLDS.keys()))

	for world_id in Registry.WORLDS:
		var world: Dictionary = Registry.WORLDS[world_id]
		_afirmar(world.get("title", "") != "" and world.get("description", "") != "",
			"mundo '%s' tiene title y description" % world_id)
		var levels: Array = world.get("levels", [])
		_afirmar(levels.size() > 0, "mundo '%s' tiene niveles" % world_id)
		for i in levels.size():
			var cfg: Dictionary = levels[i]
			var ruta: String = cfg.get("path", "")
			_afirmar(ruta.begins_with("res://") and FileAccess.file_exists(ruta),
				"nivel %s[%d] apunta a un archivo existente: %s" % [world_id, i, ruta])
			_afirmar(cfg.get("title", "") != "" and typeof(cfg.get("difficulty")) == TYPE_INT,
				"nivel %s[%d] tiene title y difficulty int" % [world_id, i])

	_afirmar(Registry.get_world("mundo_inexistente").is_empty(),
		"get_world desconocido → {} vacío")
	_afirmar(Registry.get_levels("mundo_inexistente").is_empty(),
		"get_levels desconocido → [] vacío")
	_afirmar(Registry.get_level_config("heist", 0).get("path", "") != "",
		"get_level_config('heist', 0) devuelve configuración")
	_afirmar(Registry.get_level_config("heist", -1).is_empty()
		and Registry.get_level_config("heist", 99).is_empty(),
		"get_level_config con índice fuera de rango → {} vacío")

	_afirmar(Registry.load_level_data("res://juego/heist/heist_n1.json").get("id") == "heist_n1",
		"load_level_data parsea heist_n1.json y devuelve el id")

	var data_mala: Dictionary = Registry.load_level_data("res://no_existe.json")
	_afirmar(data_mala.is_empty(), "load_level_data con ruta inexistente → {} vacío")

	var ruta_basura: String = "user://test_registry_json_invalido.json"
	var f: FileAccess = FileAccess.open(ruta_basura, FileAccess.WRITE)
	f.store_string("{json invalido,,")
	f.close()
	_afirmar(Registry.load_level_data(ruta_basura).is_empty(),
		"load_level_data con JSON inválido → {} vacío")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta_basura))

	_finalizar()


func _afirmar(condicion: bool, mensaje: String) -> void:
	if condicion:
		print("PASS: %s" % mensaje)
		passed += 1
	else:
		print("FAIL: %s" % mensaje)
		failed += 1


func _finalizar() -> void:
	print("---")
	print("Results: %d passed, %d failed" % [passed, failed])
	await get_tree().create_timer(0.05).timeout
	get_tree().quit(0 if failed == 0 else 1)
