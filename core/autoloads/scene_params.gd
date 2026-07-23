extends Node

var graph_path: String = ""
var start_node: StringName = &""
var target_node: StringName = &""
var waypoints: Array = []
var ai_enabled: bool = true
var ai_block_per_turn: int = 1
var ai_bloquea_al_inicio: bool = true
var max_ai_blocks: int = 999
var max_turns: int = 0
var max_movement_points: int = 0
var titulo_nivel: String = ""
var hacker_mode: bool = false
var starting_exploits: Dictionary = {}
var mensaje_tutorial: String = ""
var tutorial_path: String = ""
var level_key: String = ""  # Identificador único del nivel para persistencia

# Defender mode
var defender_mode: bool = false
var defender_blocks_per_turn: int = 2
var defender_block_duration: int = 4
var enemy_start_node: StringName = &""
var enemy_target_node: StringName = &""
var defender_max_blocks: int = 999
var firewall_cost: int = 2

# Balance avanzado (configurable por nivel)
var block_duration: int = 3  # Duración de bloqueos temporales
var pursuer_delay: int = 2   # Turnos antes de que un perseguidor se active
var max_pursuers: int = 4    # Máximo de perseguidores simultáneos
var pursuer_speed: int = 1   # Velocidad de perseguidores (nodos por turno)


func reset() -> void:
	graph_path = ""
	start_node = &""
	target_node = &""
	waypoints = []
	ai_enabled = true
	ai_block_per_turn = 1
	ai_bloquea_al_inicio = true
	max_ai_blocks = 999
	max_turns = 0
	max_movement_points = 0
	titulo_nivel = ""
	hacker_mode = false
	starting_exploits = {}
	mensaje_tutorial = ""
	tutorial_path = ""
	level_key = ""
	defender_mode = false
	defender_blocks_per_turn = 2
	defender_block_duration = 4
	enemy_start_node = &""
	enemy_target_node = &""
	defender_max_blocks = 999
	firewall_cost = 2
	block_duration = 3
	pursuer_delay = 2
	max_pursuers = 4
	pursuer_speed = 1
