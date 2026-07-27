extends Node

## Logger — Sistema de logging estructurado para VERTEX.
## Autoload registrado en project.godot como `Logger`.
## Accesible globalmente desde cualquier script.
##
## Uso:
##   Logger.info("Pathfinder", "Ruta calculada: %s" % path)
##   Logger.error("ProgressService", "Error cargando progress: %d" % err)
##   Logger.debug("AIBlocker", "Bloqueando: %s → %s" % [from, to])
##
## Niveles de log:
##   DEBUG — información detallada para desarrollo (solo en debug builds)
##   INFO  — operación normal del sistema
##   WARN  — problemas recuperables
##   ERROR — fallos que requieren atención
##
## Formato de salida: [LEVEL] [Module] message

enum Level { DEBUG, INFO, WARN, ERROR }

## Nivel mínimo para mostrar mensajes. Por defecto DEBUG en desarrollo, INFO en release.
var current_level: int = Level.DEBUG

## Nombres legibles para cada nivel.
const _LEVEL_NAMES: Dictionary = {
	Level.DEBUG: "DEBUG",
	Level.INFO:  "INFO",
	Level.WARN:  "WARN",
	Level.ERROR: "ERROR",
}


func _ready() -> void:
	# En release builds, solo mostrar INFO y superior.
	if not OS.is_debug_build():
		current_level = Level.INFO


## Establece el nivel mínimo de log.
func set_level(level: int) -> void:
	current_level = clampi(level, Level.DEBUG, Level.ERROR)


## Log de depuración — información detallada para desarrollo.
func debug(module: String, message: String) -> void:
	_log(Level.DEBUG, module, message)


## Log informativo — operación normal del sistema.
func info(module: String, message: String) -> void:
	_log(Level.INFO, module, message)


## Log de advertencia — problemas recuperables.
func warn(module: String, message: String) -> void:
	_log(Level.WARN, module, message)


## Log de error — fallos que requieren atención.
func error(module: String, message: String) -> void:
	_log(Level.ERROR, module, message)


## Implementación interna del logging.
func _log(level: int, module: String, message: String) -> void:
	if level < current_level:
		return
	var level_name: String = _LEVEL_NAMES.get(level, "?????")
	print("[%s] [%s] %s" % [level_name, module, message])
