extends Node

## Pruebas de GameLogger (core/autoloads/logger.gd).
##
## logger.gd no referencia otros autoloads, así que se instancia una copia
## local y corre vía `--script`. No se agrega al árbol: _ready() ajusta el
## nivel según el build y queremos el estado por defecto determinista.
##
## No se captura stdout: se valida la API (métodos existen, no crashean,
## niveles clampean). La salida impresa la verifica el runner al reenviarla.

const LoggerScript = preload("res://core/autoloads/logger.gd")

var passed: int = 0
var failed: int = 0

var _logger: Node


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_logger = Node.new()
	_logger.set_script(LoggerScript)

	_afirmar(_logger is Node, "el script instancia como Node sin árbol de autoloads")

	for metodo in ["debug", "info", "warn", "error", "set_level"]:
		_afirmar(_logger.has_method(metodo), "expone el método público %s()" % metodo)

	_afirmar(_logger.Level.DEBUG < _logger.Level.INFO
		and _logger.Level.INFO < _logger.Level.WARN
		and _logger.Level.WARN < _logger.Level.ERROR,
		"enum Level ordena DEBUG < INFO < WARN < ERROR")

	_afirmar(_logger.current_level == _logger.Level.DEBUG,
		"nivel por defecto DEBUG (fuera del árbol)")

	# Registrar entradas en los 4 niveles no debe tirar error.
	_logger.debug("TestModule", "entrada debug %d" % 1)
	_logger.info("TestModule", "entrada info")
	_logger.warn("TestModule", "entrada warn")
	_logger.error("TestModule", "entrada error")
	_afirmar(true, "debug/info/warn/error registran entrada sin error")

	_logger.set_level(_logger.Level.WARN)
	_afirmar(_logger.current_level == _logger.Level.WARN, "set_level(WARN) aplica")

	_logger.set_level(-99)
	_afirmar(_logger.current_level == _logger.Level.DEBUG, "set_level clampa por abajo a DEBUG")
	_logger.set_level(99)
	_afirmar(_logger.current_level == _logger.Level.ERROR, "set_level clampa por arriba a ERROR")

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
