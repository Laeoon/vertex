extends Node

## SceneParams — Configuración global de escenas del juego.
##
## Todas las propiedades numéricas tienen validación de rangos con setters.
## Los valores fuera de rango se clampan automáticamente y se loggea un warning.
## En reset() se usa acceso directo para evitar validación innecesaria.

# ──────────────────────────────────────────────────────────────────────────────
# Paths y configuración de escena
# ──────────────────────────────────────────────────────────────────────────────

var graph_path: String = "":
	set(value):
		if value.is_empty():
			GameLogger.warn("SceneParams", "graph_path no puede ser vacío — manteniendo valor anterior")
			return
		graph_path = value

var start_node: StringName = &""

var target_node: StringName = &""

var waypoints: Array = []

var titulo_nivel: String = ""

var level_key: String = "":
	set(value):
		if value.is_empty():
			GameLogger.warn("SceneParams", "level_key no puede ser vacío — manteniendo valor anterior")
			return
		level_key = value

var tutorial_path: String = ""  # Puede ser vacío (opcional)

var mensaje_tutorial: String = ""

# ──────────────────────────────────────────────────────────────────────────────
# IA y bloqueos
# ──────────────────────────────────────────────────────────────────────────────

## Rango válido: 0-10 (bloqueos por turno de IA)
var ai_block_per_turn: int = 1:
	set(value):
		var clamped := clampi(value, 0, 10)
		if clamped != value:
			GameLogger.warn("SceneParams", "ai_block_per_turn clampeado: %d → %d (rango 0-10)" % [value, clamped])
		ai_block_per_turn = clamped

var ai_enabled: bool = true

var ai_bloquea_al_inicio: bool = true

## Rango válido: 0-9999 (máximo de bloqueos de IA)
var max_ai_blocks: int = 999:
	set(value):
		var clamped := clampi(value, 0, 9999)
		if clamped != value:
			GameLogger.warn("SceneParams", "max_ai_blocks clampeado: %d → %d (rango 0-9999)" % [value, clamped])
		max_ai_blocks = clamped

## Rango válido: 0-1000 (turnos máximos, 0 = ilimitado)
var max_turns: int = 0:
	set(value):
		var clamped := clampi(value, 0, 1000)
		if clamped != value:
			GameLogger.warn("SceneParams", "max_turns clampeado: %d → %d (rango 0-1000)" % [value, clamped])
		max_turns = clamped

## Rango válido: 0-100 (puntos de movimiento, 0 = ilimitado)
var max_movement_points: int = 0:
	set(value):
		var clamped := clampi(value, 0, 100)
		if clamped != value:
			GameLogger.warn("SceneParams", "max_movement_points clampeado: %d → %d (rango 0-100)" % [value, clamped])
		max_movement_points = clamped

var hacker_mode: bool = false

var starting_exploits: Dictionary = {}

# ──────────────────────────────────────────────────────────────────────────────
# Modo defensor
# ──────────────────────────────────────────────────────────────────────────────

var defender_mode: bool = false

## Rango válido: 0-20 (bloqueos por turno del defensor)
var defender_blocks_per_turn: int = 2:
	set(value):
		var clamped := clampi(value, 0, 20)
		if clamped != value:
			GameLogger.warn("SceneParams", "defender_blocks_per_turn clampeado: %d → %d (rango 0-20)" % [value, clamped])
		defender_blocks_per_turn = clamped

## Rango válido: 1-100 (duración de bloqueos)
var defender_block_duration: int = 4:
	set(value):
		var clamped := clampi(value, 1, 100)
		if clamped != value:
			GameLogger.warn("SceneParams", "defender_block_duration clampeado: %d → %d (rango 1-100)" % [value, clamped])
		defender_block_duration = clamped

var enemy_start_node: StringName = &""

var enemy_target_node: StringName = &""

## Rango válido: 0-9999 (máximo de bloqueos del defensor)
var defender_max_blocks: int = 999:
	set(value):
		var clamped := clampi(value, 0, 9999)
		if clamped != value:
			GameLogger.warn("SceneParams", "defender_max_blocks clampeado: %d → %d (rango 0-9999)" % [value, clamped])
		defender_max_blocks = clamped

## Rango válido: 1-100 (costo de firewall)
var firewall_cost: int = 2:
	set(value):
		var clamped := clampi(value, 1, 100)
		if clamped != value:
			GameLogger.warn("SceneParams", "firewall_cost clampeado: %d → %d (rango 1-100)" % [value, clamped])
		firewall_cost = clamped

# ──────────────────────────────────────────────────────────────────────────────
# Balance avanzado (configurable por nivel)
# ──────────────────────────────────────────────────────────────────────────────

## Rango válido: 1-100 (duración de bloqueos temporales)
var block_duration: int = 3:
	set(value):
		var clamped := clampi(value, 1, 100)
		if clamped != value:
			GameLogger.warn("SceneParams", "block_duration clampeado: %d → %d (rango 1-100)" % [value, clamped])
		block_duration = clamped

## Rango válido: 0-50 (turnos antes de activar perseguidor)
var pursuer_delay: int = 2:
	set(value):
		var clamped := clampi(value, 0, 50)
		if clamped != value:
			GameLogger.warn("SceneParams", "pursuer_delay clampeado: %d → %d (rango 0-50)" % [value, clamped])
		pursuer_delay = clamped

## Rango válido: 1-20 (máximo de perseguidores simultáneos)
var max_pursuers: int = 4:
	set(value):
		var clamped := clampi(value, 1, 20)
		if clamped != value:
			GameLogger.warn("SceneParams", "max_pursuers clampeado: %d → %d (rango 1-20)" % [value, clamped])
		max_pursuers = clamped

## Rango válido: 1-10 (velocidad de perseguidores, nodos por turno)
var pursuer_speed: int = 1:
	set(value):
		var clamped := clampi(value, 1, 10)
		if clamped != value:
			GameLogger.warn("SceneParams", "pursuer_speed clampeado: %d → %d (rango 1-10)" % [value, clamped])
		pursuer_speed = clamped


# ──────────────────────────────────────────────────────────────────────────────
# Reset — usa acceso directo para evitar validación innecesaria
# ──────────────────────────────────────────────────────────────────────────────

func reset() -> void:
	# Paths y configuración de escena
	graph_path = ""
	start_node = &""
	target_node = &""
	waypoints = []
	titulo_nivel = ""
	level_key = ""
	tutorial_path = ""
	mensaje_tutorial = ""

	# IA y bloqueos
	ai_block_per_turn = 1
	ai_enabled = true
	ai_bloquea_al_inicio = true
	max_ai_blocks = 999
	max_turns = 0
	max_movement_points = 0
	hacker_mode = false
	starting_exploits = {}

	# Modo defensor
	defender_mode = false
	defender_blocks_per_turn = 2
	defender_block_duration = 4
	enemy_start_node = &""
	enemy_target_node = &""
	defender_max_blocks = 999
	firewall_cost = 2

	# Balance avanzado
	block_duration = 3
	pursuer_delay = 2
	max_pursuers = 4
	pursuer_speed = 1
