extends Node

## Pruebas de LocaleManager (core/locale/locale_manager.gd).
##
## El script llama a GameLogger en _apply_locale(), así que NO compila en
## modo `--script` — corre como escena (autoloads registrados). Se instancia
## una copia local del gestor para no mutar el LocaleManager real del
## proyecto; la copia usa el GameLogger autoload para su log, que existe.

const LocaleManagerScript = preload("res://core/locale/locale_manager.gd")

var passed: int = 0
var failed: int = 0

var _lm: Node


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_lm = Node.new()
	_lm.set_script(LocaleManagerScript)
	add_child(_lm)  # _ready() carga es.json como fallback y aplica "es"

	_afirmar(_lm.get_locale() == "es", "locale por defecto 'es' tras _ready()")
	_afirmar(_lm.get_available() == ["es", "en", "pt"],
		"idiomas disponibles = ['es', 'en', 'pt']")
	_afirmar(_lm.loc("welcome") == "Bienvenido al tutorial",
		"loc('welcome') resuelve la cadena de es.json")

	var señales: Array = []
	_lm.locale_changed.connect(func(loc): señales.append(loc))

	_lm.set_locale("en")
	_afirmar(_lm.get_locale() == "en" and señales == ["en"],
		"set_locale('en') aplica y emite locale_changed('en')")
	_afirmar(_lm.loc("welcome") != "Bienvenido al tutorial" and _lm.loc("welcome") != "",
		"tras cambiar a 'en', loc('welcome') devuelve la cadena inglesa")

	_lm.set_locale("fr")
	_afirmar(_lm.get_locale() == "en" and señales.size() == 1,
		"set_locale('fr') inválido se ignora (sin cambio ni señal)")

	_afirmar(_lm.loc("clave_que_no_existe_xyz") == "clave_que_no_existe_xyz",
		"loc() de clave desconocida devuelve la clave (fallback)")

	_lm.cycle_locale()  # en → pt
	_lm.cycle_locale()  # pt → es (wrap)
	_afirmar(_lm.get_locale() == "es" and señales == ["en", "pt", "es"],
		"cycle_locale recorre en → pt → es y envuelve al inicio")

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
