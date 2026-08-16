extends Node

## Pruebas para LevelManager (juego/system/).
##
## LevelManager referencia SceneParams y SceneTransition (autoloads) en los
## cuerpos de launch_level/launch_tutorial, así que NO compila en modo
## `--script` — este test corre como escena (ver test_level_manager.tscn,
## el runner lo detecta y ejecuta en modo proyecto con autoloads).
##
## Se prueban los caminos que NO disparan transición de escena (mundo/índice
## inválido, tutorial inexistente) más las consultas puras. NO se llama al
## launch_level exitoso porque SceneTransition.fade_to_scene cambiaría la
## escena activa a mitad de test; esa integración la cubren los smoke tests
## por modo (tests/ataque/test_*_sanity.gd) que bootean escena_juego.tscn
## directamente con los mismos parámetros.

const LevelManager = preload("res://juego/system/level_manager.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var worlds: Dictionary = LevelManager.get_worlds()
	_afirmar(worlds.has("heist") and worlds.has("hacker") and worlds.has("cybersecurity"),
		"get_worlds() expone los 3 mundos del registry")

	_afirmar(LevelManager.get_world_title("heist") == "Heist",
		"get_world_title('heist') = 'Heist'")
	_afirmar(LevelManager.get_world_title("desconocido") == "desconocido",
		"get_world_title desconocido → devuelve el id como fallback")

	_afirmar(LevelManager.launch_level("mundo_inexistente", 0) == false,
		"launch_level con mundo inválido → false (sin transición)")
	_afirmar(LevelManager.launch_level("heist", 99) == false,
		"launch_level con índice fuera de rango → false")

	_afirmar(LevelManager.launch_tutorial("res://tutorials/no_existe.json") == false,
		"launch_tutorial con ruta inexistente → false")

	# Side-effect verificable sin transición: el arranque fallido resetea
	# SceneParams (launch_level llama reset() antes de validar).
	SceneParams.titulo_nivel = "BASURA_PRE_LAUNCH"
	LevelManager.launch_level("mundo_inexistente", 0)
	_afirmar(SceneParams.titulo_nivel != "BASURA_PRE_LAUNCH",
		"launch_level resetea SceneParams aunque el nivel no exista")

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
